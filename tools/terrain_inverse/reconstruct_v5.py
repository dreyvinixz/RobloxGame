"""V5 image-anchored 2.5D *hypothesis*, not original mesh reconstruction.

Inputs are MANDATORY: original wireframe, AI-cleaned oblique, AI top-view atlas,
and editable manually annotated cross-view landmarks.
The former V1/V2 Gaussian island generator is NEVER imported.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy.interpolate import RBFInterpolator
from scipy.ndimage import distance_transform_edt, gaussian_filter


def read(path):
    raw = Path(path).read_bytes()
    image = cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError(f"Missing or invalid source raster: {path}")
    return image, hashlib.sha256(raw).hexdigest()


def top_panel(atlas, crop):
    x0,y0,x1,y1 = crop
    return cv2.resize(atlas[y0:y1,x0:x1], (906,726), interpolation=cv2.INTER_AREA)


def land_mask_from_pixels(top):
    hsv = cv2.cvtColor(top, cv2.COLOR_BGR2HSV)
    blue, green, red = cv2.split(top)
    # Avoid misclassifying bluish shaded cliffs: require BLUE + saturation.
    water = ((blue.astype(np.int16) > red.astype(np.int16)+24) &
             (blue.astype(np.int16) > green.astype(np.int16)+1) &
             (blue>60) & (hsv[:,:,0]>88) & (hsv[:,:,0]<129) &
             (hsv[:,:,1]>158))
    water = cv2.morphologyEx(water.astype(np.uint8),cv2.MORPH_CLOSE,
                             np.ones((3,3),np.uint8))>0
    possible_land=(~water).astype(np.uint8)
    n, labels, stats, _ = cv2.connectedComponentsWithStats(possible_land,8)
    if n < 2: raise ValueError("Top-view water/land segmentation failed")
    sizes=stats[:,cv2.CC_STAT_AREA].copy()
    sizes[0]=0
    selected=labels==int(np.argmax(sizes))
    selected=cv2.morphologyEx(selected.astype(np.uint8),cv2.MORPH_CLOSE,
                              np.ones((5,5),np.uint8))>0
    return selected,water


def estimate_plane_camera(landmarks):
    ties=landmarks["coast"]
    if len(ties)<5: raise ValueError("Need at least five coast correspondences")
    a=np.asarray([t["top"] for t in ties],np.float32)
    b=np.asarray([t["oblique"] for t in ties],np.float32)
    cv2.setRNGSeed(17)
    affine,inlier=cv2.estimateAffine2D(a,b,ransacReprojThreshold=55,
              maxIters=3000,confidence=.99,refineIters=10)
    if affine is None or inlier is None or int(inlier.sum())<5:
        raise ValueError("Failed to register sea-level landmark projections")
    reproj=cv2.transform(a[None],affine)[0]
    residual=np.linalg.norm(reproj-b,axis=1)
    good=inlier.ravel().astype(bool)
    report={"status":"APPROXIMATE_AFFINE_SEA_PLANE_ONLY",
        "intrinsics_extrinsics":"UNKNOWN",
        "model":affine.tolist(),"landmark_count":len(ties),
        "inlier_count":int(good.sum()),
        "median_inlier_error_px":float(np.median(residual[good])),
        "median_all_error_px":float(np.median(residual)),
        "rejected_landmarks":[t["id"] for t,ok in zip(ties,good) if not ok],
        "vertical_displacement_scale_px_per_relative_unit":1.0,
        "warning":"AI generated views can have inconsistent 3D geometry; no calibrated camera"}
    return affine,report


def estimate_peak_heights(landmarks,affine,max_horizontal_error=75):
    accepted,rejected=[],[]
    for peak in landmarks["peaks"]:
        ground=np.asarray(peak["top"],float)
        observed=np.asarray(peak["oblique"],float)
        flat=affine[:,:2]@ground+affine[:,2]
        dx,dy=flat-observed
        z=float(dy) # arbitrary px-equivalent relative units, not meters
        reason = ("horizontal_mismatch" if abs(dx)>max_horizontal_error else
                  "negative_or_tiny_altitude" if z<8 else
                  "out_of_height_limit" if z>200 else None)
        if reason:
            rejected.append({"id":peak["id"],"reason":reason,
                             "horizontal_error_px":float(dx),"vertical_offset_px":z})
        else:
            accepted.append({"id":peak["id"],"top_xy":ground.tolist(),
                 "oblique_xy":observed.tolist(),"estimated_altitude_relative":z,
                 "horizontal_error_px":float(dx),"status":"UNVERIFIED_MATCH"})
    if len(accepted)<5: raise ValueError("Too few self-consistent mountain peak matches")
    return accepted,rejected


def derive_heightfield(top,land,peaks,grid=257):
    if grid<33 or grid>513: raise ValueError("Grid out of supported 33..513 range")
    h,w=land.shape
    island=cv2.resize(land.astype(np.uint8),(grid,grid),
                      interpolation=cv2.INTER_NEAREST)>0
    contours,_=cv2.findContours(land.astype(np.uint8),
                                 cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE)
    coastline=max(contours,key=cv2.contourArea)[:,0,:].astype(float)
    # Digitized shoreline gives 90 ZERO-height points, directly from pixels.
    edge=coastline[np.linspace(0,len(coastline)-1,90,dtype=int)]
    hill=np.asarray([p["top_xy"] for p in peaks])
    alt=np.asarray([p["estimated_altitude_relative"] for p in peaks])
    # Declared low-relief anchors are editable hypotheses on reference top view.
    plain=np.asarray([[550,322],[460,302],[475,430],[415,455],
                      [590,460],[420,190]],float)
    low=np.asarray([2,8,8,4,6,12],float)
    coord=np.concatenate([edge,hill,plain])
    elevation=np.concatenate([np.zeros(len(edge)),alt,low])
    points=np.stack(np.meshgrid(np.linspace(0,w-1,grid),
                                np.linspace(0,h-1,grid)),axis=-1).reshape(-1,2)
    model=RBFInterpolator(coord,elevation,kernel="thin_plate_spline",
                          smoothing=30,neighbors=36)
    field=np.clip(model(points).reshape(grid,grid),0,205)
    # High frequency is only a weak cue FROM THE COLORED TOP IMAGE, never noise.
    gray=cv2.cvtColor(top,cv2.COLOR_BGR2GRAY).astype(float)
    local=gray-gaussian_filter(gray,8)
    texture=cv2.resize(local.astype("float32"),(grid,grid))
    texture=gaussian_filter(texture,1.)
    rock_factor=np.clip((field-25)/55,0,1)
    field+=np.clip(-texture,-16,16)*.16*rock_factor
    hsv=cv2.cvtColor(top,cv2.COLOR_BGR2HSV)
    rock=(((hsv[:,:,0]<34)|(hsv[:,:,1]<65))&
          (hsv[:,:,2]<184)&land)
    rock=cv2.GaussianBlur(rock.astype(np.float32),(0,0),sigmaX=7.)
    rock=cv2.resize(rock,(grid,grid),interpolation=cv2.INTER_AREA)
    field+=rock*np.clip((field-12)/75,0,1)*16.
    field=np.maximum(0,field)*np.clip(distance_transform_edt(island)/3.5,0,1)
    return np.where(island,field,-8.).astype(np.float32),island


def save_obj(path,field):
    n=field.shape[0]
    with Path(path).open("w",encoding="utf-8") as stream:
        stream.write("# USER IMAGE-CONSTRAINED APPROXIMATION; NOT ORIGINAL 3D MESH\n")
        for row in range(n):
            for col in range(n):
                stream.write(f"v {col/(n-1)*1000:.5f} {field[row,col]:.5f} {(1-row/(n-1))*1000:.5f}\n")
        for row in range(n-1):
            for col in range(n-1):
                a=row*n+col+1
                stream.write(f"f {a} {a+n} {a+1}\nf {a+1} {a+n} {a+n+1}\n")


def overlay_coast_camera(clean,top,land,camera,landmarks,peaks,out):
    trace=clean.copy()
    contours,_=cv2.findContours(land.astype(np.uint8),
                                 cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_SIMPLE)
    coast=max(contours,key=cv2.contourArea)[:,0,:].astype(np.float32)
    projected=cv2.transform(coast[None],camera)[0].astype(np.int32)
    cv2.polylines(trace,[projected],True,(30,240,240),2)
    for tie in landmarks["coast"]:
        truth=tuple(tie["oblique"])
        predicted=np.rint(camera[:,:2]@np.asarray(tie["top"])+camera[:,2]).astype(int)
        cv2.circle(trace,truth,4,(0,0,255),-1)
        cv2.line(trace,tuple(predicted),truth,(0,130,255),1)
    for peak in peaks:
        cv2.circle(trace,tuple(np.rint(peak["oblique_xy"]).astype(int)),4,(255,30,250),-1)
    cv2.imwrite(str(out/"camera_registration_overlay.png"),trace)
    top_annotated=top.copy()
    cv2.polylines(top_annotated,[np.rint(coast).astype(int)],True,(40,40,245),2)
    for peak in peaks:
        cv2.circle(top_annotated,tuple(np.rint(peak["top_xy"]).astype(int)),5,(20,40,245),-1)
    cv2.imwrite(str(out/"topview_annotated.png"),top_annotated)


def render_wireframe_candidate(original,field,camera,out):
    """Sparse regular-grid candidate, NOT topology inherited from V4.2."""
    h,w=original.shape[:2]
    n=field.shape[0]
    step=max(1,(n-1)//35)
    raster=np.zeros((h,w),np.uint8)
    def screen(row,col):
        top=np.array([col/(n-1)*905,row/(n-1)*725],float)
        p=camera[:,:2]@top+camera[:,2]
        p[1]-=field[row,col] # Vertical projection is an explicit assumption.
        return tuple(np.rint(p).astype(int))
    for row in range(0,n,step):
        for col in range(0,n-1,step):
            cv2.line(raster,screen(row,col),screen(row,min(n-1,col+step)),255,1)
    for col in range(0,n,step):
        for row in range(0,n-1,step):
            cv2.line(raster,screen(row,col),screen(min(n-1,row+step),col),255,1)
    overlay=original.copy()
    overlay[raster>0]=(10,235,255)
    cv2.imwrite(str(out/"wireframe_reprojection_candidate.png"),overlay)
    cv2.imwrite(str(out/"reprojected_wireframe_line_mask.png"),raster)
    canny=cv2.Canny(cv2.cvtColor(original,cv2.COLOR_BGR2GRAY),65,135)
    distance=cv2.distanceTransform((canny==0).astype(np.uint8),cv2.DIST_L2,3)
    pixels=raster>0
    return {"pixel_count":int(pixels.sum()),
       "nearest_original_canny_edge_mean_px":
           float(distance[pixels].mean()) if pixels.any() else None,
       "warning":"Not an independently validated 3D reprojection metric; Canny includes terrain texture, trees and UI grid"}


def run(top_atlas,clean_oblique,original_wireframe,landmarks,output,grid=257,viewer=True):
    atlas,sha_atlas=read(top_atlas)
    clean,sha_clean=read(clean_oblique)
    original,sha_original=read(original_wireframe)
    if atlas.shape[:2]!=(1024,1536) or clean.shape[:2]!=(971,1619) or original.shape[:2]!=(971,1619):
        raise ValueError("Reference shape mismatch: atlas 1536x1024, oblique/wireframe 1619x971")
    ties=json.loads(Path(landmarks).read_text(encoding="utf-8"))
    top=top_panel(atlas,ties["atlas_top_crop_xyxy"])
    land,water=land_mask_from_pixels(top)
    camera,camera_report=estimate_plane_camera(ties)
    peaks,rejected=estimate_peak_heights(ties,camera)
    field,mask=derive_heightfield(top,land,peaks,grid)
    out=Path(output)
    out.mkdir(parents=True,exist_ok=True)
    np.save(out/"height_relative.npy",field)
    Image.fromarray(np.rint(np.clip((field+8)/213,0,1)*65535).astype(np.uint16)).save(out/"heightmap_16bit.png")
    cv2.imwrite(str(out/"top_water_source_segmentation.png"),water.astype(np.uint8)*255)
    cv2.imwrite(str(out/"top_land_source_segmentation.png"),land.astype(np.uint8)*255)
    cv2.imwrite(str(out/"terrain_mask.png"),mask.astype(np.uint8)*255)
    color=cv2.normalize(field,None,0,255,cv2.NORM_MINMAX).astype(np.uint8)
    cv2.imwrite(str(out/"height_preview.png"),cv2.applyColorMap(color,cv2.COLORMAP_JET))
    save_obj(out/"terrain_hypothesis.obj",field)
    overlay_coast_camera(clean,top,land,camera,ties,peaks,out)
    reprojection=render_wireframe_candidate(original,field,camera,out)
    if viewer:
        import plotly.graph_objects as go
        step=max(1,grid//105)
        fig=go.Figure(go.Surface(x=np.linspace(0,1000,grid)[::step],
                    y=np.linspace(1000,0,grid)[::step],
                    z=field[::step,::step],colorscale="Earth",showscale=False))
        fig.update_layout(title="V5 relative-height HYPOTHESIS (not original 3D mesh)",
                          scene=dict(aspectratio=dict(x=1,y=1,z=.28)),
                          margin=dict(l=0,r=0,b=0,t=35))
        fig.write_html(out/"terrain_v5.html",include_plotlyjs=True)
    report={
       "status":"EXPERIMENTAL_2_5D_HYPOTHESIS_NOT_VALIDATED",
       "inputs_sha256":{"top_atlas":sha_atlas,"clean_oblique":sha_clean,
                        "original_wireframe":sha_original},
       "method":"Raw top-view RGB segmentation + manually marked cross-view shore/peak correspondences + robust affine sea-level registration + image-anchored RBF height interpolation",
       "camera":camera_report,"peak_anchors_accepted":peaks,
       "peak_anchors_rejected":rejected,"reprojection_debug":reprojection,
       "grid":grid,"vertices":grid*grid,"triangles":2*(grid-1)*(grid-1),
       "height_min":float(field.min()),"height_max":float(field.max()),
       "land_fraction":float(mask.mean()),
       "limitations":[
          "All source images were AI-generated and may depict inconsistent geometry",
          "No real camera calibration: sea-plane affine alignment only",
          "Altitude is arbitrary; screen vertical offset interpreted as relative height",
          "Manual peak matches require independent verification",
          "This is regular-grid mesh, not recovered true wireframe triangle topology",
          "V4.2 candidate graph is NOT yet incorporated into 3D topology",
          "Color segmentation may misclassify sea or dark rocks",
          "Not ready for Roblox Studio terrain replacement or production"]
    }
    (out/"v5_report.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    (out/"camera.json").write_text(json.dumps(camera_report,indent=2)+"\n",encoding="utf-8")
    return report


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--top-atlas",type=Path,required=True)
    parser.add_argument("--clean-oblique",type=Path,required=True)
    parser.add_argument("--original-wireframe",type=Path,required=True)
    parser.add_argument("--landmarks",type=Path,default=Path(__file__).with_name("v5_landmarks.json"))
    parser.add_argument("--output",type=Path,required=True)
    parser.add_argument("--grid",type=int,default=257)
    parser.add_argument("--no-viewer",action="store_true")
    args=parser.parse_args()
    result=run(args.top_atlas,args.clean_oblique,args.original_wireframe,
               args.landmarks,args.output,args.grid,not args.no_viewer)
    print(json.dumps({"status":result["status"],"grid":result["grid"],
                      "camera":result["camera"],"height_max":result["height_max"]},indent=2))


if __name__=="__main__":
    main()
