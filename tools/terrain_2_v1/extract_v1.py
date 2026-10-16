"""Terrain 2 V1: source-image segmentation and orthographic silhouette constraints.

Real user-supplied AI image pixels are REQUIRED. No procedural terrain generation,
triangulation, metric height estimates, or claim of original 3D recovery.
"""
import argparse
import hashlib
import json
from pathlib import Path
import cv2
import numpy as np
from scipy.ndimage import median_filter

SOURCES = {
    'top_mask':'top_flat_semantic.jpg',
    'top_mesh':'top_sparse_mesh.jpg',
    'top_render':'top_render.png',
    'front':'front_render.png',
    'back':'back_render.png',
    'left':'left_render.png',
    'right':'right_render.png',
}
HORIZON_ROW = 465


def load(path):
    path=Path(path)
    raw=path.read_bytes()
    bgr=cv2.imdecode(np.frombuffer(raw,dtype=np.uint8),cv2.IMREAD_COLOR)
    if bgr is None:
        raise ValueError(f'Cannot decode source raster {path}')
    return bgr, hashlib.sha256(raw).hexdigest()


def connected_parts(binary,min_area=80):
    count,ids,stats,_=cv2.connectedComponentsWithStats(binary.astype(np.uint8),8)
    keep=[]
    for i in range(1,count):
        if stats[i,cv2.CC_STAT_AREA]>=min_area:
            keep.append((int(stats[i,cv2.CC_STAT_AREA]),i))
    keep.sort(reverse=True)
    return ids,[(area,i) for area,i in keep]


def segment_plan_mask(image):
    hsv=cv2.cvtColor(image,cv2.COLOR_BGR2HSV)
    # Source-specific color observation: land H<45, ocean/background blue H~100.
    rough=(hsv[:,:,0]<45)&(hsv[:,:,2]>65)&(hsv[:,:,1]<150)
    rough=cv2.morphologyEx(rough.astype(np.uint8),cv2.MORPH_CLOSE,np.ones((5,5),np.uint8))>0
    ids,parts=connected_parts(rough,150)
    if not parts:raise ValueError('No land detected in original flat reference')
    largest=ids==parts[0][1]
    all_land=np.zeros_like(largest)
    for area,label in parts:
        all_land|=ids==label
    sand=(hsv[:,:,0]<45)&(hsv[:,:,2]>155)&(hsv[:,:,1]<145)
    sand&=all_land
    sea=(hsv[:,:,0]>=75)&(hsv[:,:,0]<=130)&(hsv[:,:,1]>=75)
    contours,_=cv2.findContours(largest.astype(np.uint8),cv2.RETR_EXTERNAL,
                                  cv2.CHAIN_APPROX_NONE)
    external=max(contours,key=cv2.contourArea)[:,0,:]
    return {'land':all_land,'mainland':largest,'sand':sand,'sea':sea,
            'shoreline':external,'parts':parts}


def trace_inland_channel(image,features,guide=None):
    """Observed beige pixels inside a coarse, declared corridor; NOT proven water."""
    h,w=image.shape[:2]
    if guide is None:
        guide=np.array([(580,145),(590,220),(610,300),(652,370),
                        (718,430),(770,488),(715,535),(660,558)],float)
        guide[:,0]*=w/1264
        guide[:,1]*=h/842
    line=np.zeros((h,w),np.uint8)
    cv2.polylines(line,[np.rint(guide).astype(np.int32)],False,255,max(10,int(w*.083)))
    candidate=features['sand']&(line>0)
    return candidate,guide,line>0


def side_silhouette(image,samples=129,horizon=HORIZON_ROW):
    h,w=image.shape[:2]
    if (h,w)!=(1151,2048):
        raise ValueError(f'Expect original ortho image 2048x1151, got {w}x{h}')
    x0,x1=50,w-50
    y0,y1=190,min(horizon+1,h)
    gray=cv2.cvtColor(image,cv2.COLOR_BGR2GRAY)
    bright=gray[y0:y1,x0:x1]>=119
    bright=cv2.morphologyEx(bright.astype(np.uint8),cv2.MORPH_OPEN,
                            np.ones((2,2),np.uint8))>0
    roof=np.full(x1-x0,horizon,dtype=float)
    for j in range(x1-x0):
        found=np.flatnonzero(bright[:,j])
        if len(found):roof[j]=y0+float(found[0])
    roof=median_filter(roof,size=7,mode='nearest')
    xs=np.linspace(x0,x1-1,samples)
    ys=np.interp(xs,np.arange(x0,x1),roof)
    return xs,ys,np.maximum(0.,horizon-ys)


def scaled_profile_diff(a,b):
    aa=np.asarray(a,dtype=float)
    bb=np.asarray(b,dtype=float)[::-1]
    return float(np.sqrt(np.mean((aa-bb)**2)))


def export(inputs,output):
    src=Path(inputs);out=Path(output);out.mkdir(parents=True,exist_ok=True)
    images={};hashes={}
    for key,filename in SOURCES.items():
        im,sha=load(src/filename)
        images[key]=im;hashes[key]=sha
    mask=images['top_mask'];height,width=mask.shape[:2]
    land=segment_plan_mask(mask)
    river,guide,guide_zone=trace_inland_channel(mask,land)
    labeled,parts=connected_parts(land['land'],80)
    contours,_=cv2.findContours(land['mainland'].astype(np.uint8),cv2.RETR_EXTERNAL,
                                 cv2.CHAIN_APPROX_SIMPLE)
    shore=max(contours,key=cv2.contourArea)[:,0,:]
    approx=cv2.approxPolyDP(shore.reshape(-1,1,2),2.0,True)[:,0,:]
    coastline={'coordinate_space':'top_flat_semantic.jpg image pixels',
      'width':width,'height':height,'shoreline_points_xy':shore.tolist(),
      'simplified_shoreline_xy':approx.tolist(),
      'components':[{'area_px2':a} for a,_ in parts],
      'status':'source_pixel_coastline_estimate'}
    (out/'coastline_pixels.json').write_text(json.dumps(coastline,ensure_ascii=False))
    (out/'river_corridor_guide.json').write_text(json.dumps({
      'status':'manual_coarse_guide_plus_observed_beige_pixels_NOT_verified_water',
      'guide_xy':np.rint(guide).astype(int).tolist(),
      'candidate_pixel_count':int(river.sum())},indent=2))
    def write(name,binary):
        if not cv2.imwrite(str(out/name),(binary.astype(np.uint8)*255)):
            raise OSError('Could not write '+name)
    write('land_all_mask.png',land['land']);write('mainland_mask.png',land['mainland'])
    write('beige_observed_mask.png',land['sand']);write('ocean_observed_mask.png',land['sea'])
    write('river_corridor_candidates.png',river)
    overlay=mask.copy()
    cv2.polylines(overlay,[shore.reshape(-1,1,2)],True,(0,245,230),2)
    overlay[river]=(130,0,245)
    cv2.polylines(overlay,[np.rint(guide).astype(np.int32)],False,(80,220,40),1)
    cv2.imwrite(str(out/'reference_segmentation_overlay.png'),overlay)
    top_mesh=images['top_mesh']
    registration={'status':'same_dimensions_only_not_verified',
                  'warning':'AI images may redraw topology; do not assume matching vertices'}
    if top_mesh.shape==mask.shape:
        registration['status']='matching_raster_dimensions_not_calibrated'
    profiles={};overlays=[]
    directions={'front':'West->East','back':'East->West',
                'right':'South->North','left':'North->South'}
    for key in ('front','back','left','right'):
        frame=images[key].copy()
        xs,ys,z=side_silhouette(frame)
        points=np.stack([np.rint(xs),np.rint(ys)],axis=1).astype(np.int32)
        cv2.polylines(frame,[points],False,(0,250,255),3,cv2.LINE_AA)
        cv2.imwrite(str(out/f'{key}_observed_silhouette.png'),frame)
        profiles[key]={'direction':directions[key],
                       'sample_screen_x_px':np.round(xs,1).tolist(),
                       'highest_visible_terrain_y_px':np.round(ys,2).tolist(),
                       'apparent_height_above_sea_px':np.round(z,2).tolist(),
                       'maximum_apparent_height_px':float(z.max()),
                       'image_dimensions':[2048,1151]}
        overlays.append(cv2.resize(frame,(720,405)))
    (out/'orthographic_profiles.json').write_text(json.dumps(profiles,indent=2))
    comparison=np.vstack([np.hstack(overlays[:2]),np.hstack(overlays[2:])])
    cv2.imwrite(str(out/'four_views_silhouettes.jpg'),comparison)
    report={'status':'V1_SOURCE_PIXEL_2D_FEATURES_ONLY','source_sha256':hashes,
      'mask_resolution':[width,height],
      'land_cover_pixels':int(land['land'].sum()),
      'mainland_cover_pixels':int(land['mainland'].sum()),
      'distinct_land_components_min_150px':len(land['parts']),
      'shoreline_vertices_screen':len(shore),
      'simplified_shoreline_vertices_screen':len(approx),
      'beige_candidate_pixels':int(land['sand'].sum()),
      'river_corridor_beige_pixels':int(river.sum()),
      'profile_opposition_rmse_apparent_px':{
        'front_vs_mirrored_back':scaled_profile_diff(
            profiles['front']['apparent_height_above_sea_px'],
            profiles['back']['apparent_height_above_sea_px']),
        'left_vs_mirrored_right':scaled_profile_diff(
            profiles['left']['apparent_height_above_sea_px'],
            profiles['right']['apparent_height_above_sea_px'])},
      'register':registration,
      'limits':['Images created by AI may be mutually inconsistent.',
        'Only raw screen-space image masks and silhouette constraints; no 3D mesh.',
        'Contour edges and beige channel are heuristic pixel labels, not manually verified.',
        'Sea baseline comes from diagram y=465; pixel height is not metric altitude.',
        'The guide for river corridor is manual and needs review before hydrology.',
        'No old procedural terrain is imported, used or evaluated.']}
    (out/'v1_report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
    dashboard_top=np.hstack([cv2.resize(mask,(760,506)),cv2.resize(overlay,(760,506))])
    dashboard_bottom=cv2.resize(comparison,(1520,855))
    cv2.imwrite(str(out/'v1_contact_sheet.jpg'),np.vstack([dashboard_top,dashboard_bottom]))
    return report


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--sources',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    a=p.parse_args()
    r=export(a.sources,a.output)
    print(json.dumps({k:r[k] for k in ('status','shoreline_vertices_screen',
        'river_corridor_beige_pixels','profile_opposition_rmse_apparent_px')},indent=2))


if __name__=='__main__':main()
