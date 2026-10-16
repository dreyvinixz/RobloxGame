"""Terrain 2 V4: source-derived ridge detail + two-sea channel mouth connectivity.

An image-driven REFINEMENT of the nonunique V3 2.5D hypothesis. No new
procedural mountains, surveyed depths, metric camera or Studio playtest.
"""
import argparse
import json
from pathlib import Path
import cv2
import numpy as np
from scipy.ndimage import distance_transform_edt, gaussian_filter
from PIL import Image
from .terrain_v3 import read_image,save_obj,predict_profile,graphics
from .isometric_v3 import silhouette_fit,evaluate


def source_shas(root, report):
    report=json.loads(Path(report).read_text())
    images={}
    for filename,digest in report["source_sha256"].items():
        image,sha=read_image(Path(root)/filename)
        if sha!=digest:
            raise ValueError(f"V3 source SHA-256 mismatch: {filename}")
        images[filename]=image
    return images,report


def orthographic_metrics(field, profiles):
    result={}
    for name in ("front","back","left","right"):
        observed=np.asarray(profiles["profiles"][name]["apparent_height_px"])
        predicted=predict_profile(field,name)
        result[name]={"rmse_px_equivalent":float(
            np.sqrt(np.mean((predicted-observed)**2)))}
    return result


def rock_residual(render,field,classes):
    h,w=field.shape
    gray=cv2.cvtColor(render,cv2.COLOR_BGR2GRAY).astype(np.float32)
    detail=gray-gaussian_filter(gray,7)
    detail=cv2.resize(detail,(w,h),interpolation=cv2.INTER_AREA)
    detail=gaussian_filter(detail,.5)
    strength=float(np.percentile(np.abs(detail),90))
    detail=np.clip(detail/max(1,strength),-1,1)
    highland=(classes>=5)&(field>15)
    confidence=gaussian_filter(highland.astype(float),1.2)
    return detail*confidence,highland


def refine_rock(field,render,classes,profiles):
    texture,region=rock_residual(render,field,classes)
    base_mean=float(np.mean([
        m["rmse_px_equivalent"] for m in orthographic_metrics(field,profiles).values()]))
    candidates=[]
    for amplitude in (0,2,4,6):
        candidate=field+amplitude*texture
        residual=float(np.mean([m["rmse_px_equivalent"]
               for m in orthographic_metrics(candidate,profiles).values()]))
        gradient=np.hypot(*np.gradient(candidate))
        candidates.append({"texture_amplitude_relative":amplitude,
                           "mean_silhouette_rmse":residual,
                           "mean_rock_gradient":float(np.mean(gradient[region])) if region.any() else 0.})
    acceptable=[c for c in candidates if c["mean_silhouette_rmse"]<=base_mean*1.03]
    selected=max(acceptable,key=lambda x:x["texture_amplitude_relative"]) if acceptable else candidates[0]
    return field+selected["texture_amplitude_relative"]*texture,{
        "base_mean_rmse":base_mean,"candidates":candidates,"chosen":selected,
        "image_derived_detail_only":True}


def join_both_oceans(source,source_path,observed_water,field):
    h,w=source.shape[:2]
    n=field.shape[0]
    hsv=cv2.cvtColor(source,cv2.COLOR_BGR2HSV)
    sea=(hsv[:,:,0]>=75)&(hsv[:,:,0]<=130)&(hsv[:,:,1]>=75)
    distances,nearest=distance_transform_edt(~sea,return_indices=True)
    extra=np.zeros((n,n),np.uint8)
    annotations=[]
    scale=np.array([(n-1)/(w-1),(n-1)/(h-1)])
    for index in (0,-1):
        x,y=np.rint(source_path[index]).astype(int)
        length=float(distances[y,x])
        if length>35:
            raise ValueError(f"Original sea more than 35px from channel end: {length:.2f}")
        beach=np.array([nearest[1,y,x],nearest[0,y,x]])
        origin=np.rint(np.array([x,y])*scale).astype(int)
        target=np.rint(beach*scale).astype(int)
        cv2.line(extra,tuple(origin),tuple(target),255,1)
        annotations.append({
            "endpoint_source_xy":[int(x),int(y)],
            "nearest_original_ocean_xy":beach.tolist(),
            "distance_to_ocean_source_px":length,
            "status":"IMAGE_SUPPORTED_SHORT_GAP_BRIDGE_NOT_ORIGINAL_3D"})
    extended=observed_water|(extra>0)
    _,components=cv2.connectedComponents(extended.astype(np.uint8),8)
    a=np.rint(np.asarray(source_path[0])*scale).astype(int)
    b=np.rint(np.asarray(source_path[-1])*scale).astype(int)
    connected=bool(components[a[1],a[0]] and components[a[1],a[0]]==components[b[1],b[0]])
    if not connected:
        raise ValueError("Refined north-to-south tidal channel disconnected")
    improved=field.astype(np.float32).copy()
    improved[extra>0]=np.minimum(improved[extra>0],-1.5)
    report={"north_south_connected":connected,
            "ocean_endpoints":annotations,
            "new_grid_water_pixels":int((extra>0).sum()),
            "actual_ocean_source_pixels_examined":True}
    return improved,extra>0,extended,report


def view_uncertainty(classes,profiles,n):
    p=profiles["profiles"]
    def vec(k):
        return np.asarray(p[k]["apparent_height_px"],float)
    x=np.abs(vec("front")-vec("back")[::-1])
    y=np.abs(vec("left")-vec("right")[::-1])
    x=np.interp(np.linspace(0,128,n),np.arange(129),x)
    y=np.interp(np.linspace(0,128,n),np.arange(129),y)
    uncertainty=.3*x[None,:]+.45*y[:,None]
    return np.where(classes>=2,uncertainty+
              np.where(classes==7,6,3),0).astype(np.float32)


def run(sources,v2_dir,v3_dir,output):
    out=Path(output);out.mkdir(parents=True,exist_ok=True)
    images,v3_report=source_shas(sources,Path(v3_dir)/"v3_report.json")
    baseline=np.load(Path(v3_dir)/"height_relative_v3.npy")
    n=baseline.shape[0]
    if baseline.ndim!=2 or baseline.shape[0]!=baseline.shape[1]:
        raise ValueError("Invalid V3 heightfield")
    for filename in ("land_all_components.png","rock_likelihood.png"):
        if not (Path(v2_dir)/filename).is_file():
            raise ValueError(f"Missing V2 source observation: {filename}")
    land=cv2.imread(str(Path(v2_dir)/"land_all_components.png"),cv2.IMREAD_GRAYSCALE)
    rock=cv2.imread(str(Path(v2_dir)/"rock_likelihood.png"),cv2.IMREAD_GRAYSCALE)
    if land is None or rock is None:
        raise ValueError("Invalid original V2 masks")
    likelihood=cv2.resize(rock.astype(np.float32)/255,(n,n))
    classes=np.where((baseline>15)&(likelihood>.1),5,4).astype(np.uint8)
    classes[baseline<0]=0
    classes[(np.hypot(*np.gradient(np.maximum(baseline,0)))>5)&(baseline>15)]=7
    profiles=json.loads((Path(v2_dir)/"orthographic_profile_constraints.json").read_text())
    refined,roughness=refine_rock(baseline,images["top_render.png"],classes,profiles)
    channel=json.loads((Path(v3_dir)/"river_centerline_v3.json").read_text())
    water=cv2.imread(str(Path(v3_dir)/"river_mask_v3.png"),cv2.IMREAD_GRAYSCALE)
    if water is None or water.shape!=baseline.shape:
        raise ValueError("Missing V3 water mask")
    refined,additions,water,connectivity=join_both_oceans(
        images["top_flat_semantic.jpg"],channel["centerline_xy"],water>0,refined)
    classes[water]=1
    uncertainty=view_uncertainty(classes,profiles,n)
    np.save(out/"height_refined_v4.npy",refined)
    Image.fromarray(np.clip(np.rint((refined+10)/160*65535),0,65535).astype(np.uint16)).save(out/"heightmap_refined_v4.png")
    save_obj(refined,out/"mesh_refined_v4.obj")
    def save_png(name,image):
        if not cv2.imwrite(str(out/name),image):
            raise OSError(f"Failed to export {name}")
    save_png("uncertainty_v4.png",np.clip(uncertainty/55*255,0,255).astype(np.uint8))
    save_png("river_ocean_join_v4.png",water.astype(np.uint8)*255)
    save_png("ocean_extension_uncertain_v4.png",additions.astype(np.uint8)*255)
    save_png("height_refined_preview_v4.png",cv2.applyColorMap(
        cv2.normalize(refined,None,0,255,cv2.NORM_MINMAX).astype(np.uint8),
        cv2.COLORMAP_TURBO))
    before=orthographic_metrics(baseline,profiles)
    after=orthographic_metrics(refined,profiles)
    land_grid=cv2.resize((land>0).astype(np.uint8),(n,n),
                         interpolation=cv2.INTER_NEAREST)>0
    keys=("oblique_wireframe_1.jpg","oblique_wireframe_2.jpg")
    iso_before={key:float(silhouette_fit(images[key],baseline,land_grid)["normalized_rmse"])
                for key in keys}
    iso_after=evaluate(images,refined,land_grid,out)
    graphics(out,refined,{"centerline_xy":np.asarray(channel["centerline_xy"],float),
        "surface_levels":np.zeros(len(channel["centerline_xy"]))},images,profiles)
    for old,new in [("multiview_profiles_v3.png","multiview_comparison_v4.png"),
                    ("terrain_v3.html","terrain_v4.html"),
                    ("render_isometric_v3.png","render_isometric_v4.png"),
                    ("isometric_reference_vs_model_v3.jpg","isometric_reference_vs_model_v4.jpg")]:
        (out/old).rename(out/new)
    # Model assumptions about depth and relative volume must remain unchanged.
    for name in ("river_width_profile_v3.json","river_depth_profile_v3.json",
                 "river_volume_report_v3.json"):
        (out/name).write_bytes((Path(v3_dir)/name).read_bytes())
    report={
        "status":"V4_REFINED_RELATIVE_2_5D_NOT_VALIDATED",
        "source_sha256":v3_report["source_sha256"],
        "same_source_and_branch_as_v3":True,
        "grid":n,"vertices":n*n,"triangles":2*(n-1)**2,
        "river_ocean":connectivity,"terrain_detail":roughness,
        "profile_rmse_before":before,"profile_rmse_after":after,
        "isometric_before_normalized_rmse":iso_before,
        "isometric_normalized_diagnostics":iso_after,
        "max_model_uncertainty_relative":float(uncertainty.max()),
        "uncertainty_semantics":"heuristic incompatible-view magnitude, not a probability or physical bound",
        "not_recovered_geometry":True,
        "limitations":[
            "No measured underwater depth, no physical 3D camera and no original 3D mesh.",
            "Ocean mouth extensions are short manually connected pixel hypotheses.",
            "Ridges are extracted from the original illustrated shadows, not measured.",
            "No Roblox Studio testing; keep PR draft and target dev."
        ]
    }
    (out/"final_report_v4.json").write_text(json.dumps(report,indent=2)+"\n")
    return report


def main():
    p=argparse.ArgumentParser(description=__doc__)
    for key in ("sources","v2","v3","output"):
        p.add_argument("--"+key,required=True,type=Path)
    a=p.parse_args()
    print(json.dumps(run(a.sources,a.v2,a.v3,a.output),indent=2))


if __name__=="__main__":
    main()
