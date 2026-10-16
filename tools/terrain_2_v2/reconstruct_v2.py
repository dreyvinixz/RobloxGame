"""Terrain 2 V2: source-pixel-constrained central channel, rugged relief evidence,
and cross-checked orthographic screen-space profiles. NO synthetic 3D terrain.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from scipy.ndimage import distance_transform_edt, gaussian_filter
from skimage.graph import route_through_array

from tools.terrain_2_v1.extract_v1 import segment_plan_mask, side_silhouette, SOURCES

# Anchors digitized from the user's flat-color reference (1264×842).
# Source pixels, not reconstructed vertices, nor physics-grounded river bed.
CHANNEL_GUIDE = [(580,146),(580,192),(591,243),(608,295),(637,345),
                 (674,391),(722,429),(761,476),(765,496),(736,516),(699,535),(670,542)]


def read_bgr(path):
    p=Path(path); raw=p.read_bytes()
    img=cv2.imdecode(np.frombuffer(raw,np.uint8),cv2.IMREAD_COLOR)
    if img is None: raise ValueError(f'Invalid original image {p}')
    return img,hashlib.sha256(raw).hexdigest()


def channel_from_beige(bgr,anchors=CHANNEL_GUIDE):
    """Pixel-evidence weighted geodesics; tiny unsupported gaps remain flagged."""
    h,w=bgr.shape[:2]
    ref=np.asarray(anchors,float).reshape(-1,2)
    points=np.column_stack((ref[:,0]*w/1264,ref[:,1]*h/842))
    if len(points)<3 or (points<0).any() or (points[:,0]>=w).any() or (points[:,1]>=h).any():
        raise ValueError('Invalid source-guided river anchors')
    hsv=cv2.cvtColor(bgr,cv2.COLOR_BGR2HSV)
    evidence=((hsv[:,:,0]>=6)&(hsv[:,:,0]<=32)&(hsv[:,:,2]>=151)&
              (hsv[:,:,1]>=12)&(hsv[:,:,1]<=127))
    # Graded confidence of original beige pixel; never use filled-in pixels as truth.
    dist=distance_transform_edt(~evidence)
    routes=[]
    radius=max(17,int(w*.056))
    for p,q in zip(points[:-1],points[1:]):
        x0=max(0,int(min(p[0],q[0]))-radius);x1=min(w,int(max(p[0],q[0]))+radius+1)
        y0=max(0,int(min(p[1],q[1]))-radius);y1=min(h,int(max(p[1],q[1]))+radius+1)
        shift=np.array([x0,y0])
        a=np.rint(p-shift).astype(int);b=np.rint(q-shift).astype(int)
        guide=np.ones((y1-y0,x1-x0),np.uint8)
        cv2.line(guide,tuple(a),tuple(b),0,1)
        dg=distance_transform_edt(guide)
        cost=1+1.6*np.minimum(dist[y0:y1,x0:x1],9)**2+ .016*dg**2
        path,_=route_through_array(cost,(int(a[1]),int(a[0])),
                                  (int(b[1]),int(b[0])),fully_connected=True,geometric=True)
        seg=np.asarray([[x+x0,y+y0] for y,x in path],np.int32)
        if len(routes):seg=seg[1:]
        routes.extend(seg.tolist())
    line=np.asarray(routes,dtype=np.int32)
    if len(line)<5:raise ValueError('No river path traced from source pixels')
    trace=np.zeros((h,w),np.uint8)
    cv2.polylines(trace,[line.reshape(-1,1,2)],False,255,1)
    seen=(trace>0)
    near=distance_transform_edt(~seen)
    raster_width=evidence & (near<max(13,int(w*.026)))
    pixel_supported=float(evidence[line[:,1],line[:,0]].mean())
    dist_to_source=float(dist[line[:,1],line[:,0]].mean())
    return {'centerline':line,'thin_mask':seen,'corridor':raster_width,
            'beige_mask':evidence,'mean_distance_to_beige_px':dist_to_source,
            'centerline_beige_support':pixel_supported,'annotations':points.round(1).tolist(),
            'unsupported_line_pixels':(~evidence & seen)}


def color_ground_render(render):
    """Conservative color-only foreground on source top-render viewpoint."""
    hsv=cv2.cvtColor(render,cv2.COLOR_BGR2HSV)
    b,g,r=[x.astype(np.int16) for x in cv2.split(render)]
    marine=(b>g+9)&(b>r+22)&(hsv[:,:,0]>75)&(hsv[:,:,0]<134)
    land=(~marine)&(hsv[:,:,2]>61)&(hsv[:,:,1]<110)
    land[:int(.05*len(land)),:]=False
    n,ids,stats,_=cv2.connectedComponentsWithStats(land.astype(np.uint8),8)
    if n<2:raise ValueError('Cannot segment land from top-render image')
    keep=np.zeros(n,bool)
    keep[1:]=stats[1:,cv2.CC_STAT_AREA]>max(70,int(render.shape[0]*render.shape[1]*.0002))
    return keep[ids],marine


def rock_evidence(render,land):
    """Apparent craggy-slope texture, not an actual altitude map."""
    gray=cv2.cvtColor(render,cv2.COLOR_BGR2GRAY).astype(np.float32)
    local_mean=gaussian_filter(gray,6)
    variance=np.maximum(0,gaussian_filter(gray**2,6)-local_mean**2)
    local_std=np.sqrt(variance)
    likelihood=np.clip((155-local_mean)/64,0,1)*np.clip((local_std-9)/28,0,1)
    likelihood*=land
    candidate=(likelihood>.23)&land
    candidate=cv2.morphologyEx(candidate.astype(np.uint8),cv2.MORPH_CLOSE,np.ones((9,9),np.uint8))>0
    n,labels,stats,_=cv2.connectedComponentsWithStats(candidate.astype(np.uint8),8)
    large=np.zeros(n,bool);large[1:]=stats[1:,cv2.CC_STAT_AREA]>=120
    candidate=large[labels]
    return likelihood,candidate,local_std


def transform_ground_to_flat(render_land,flat_land):
    """Scale-only spatial check, deliberately not labeled 3D camera calibration."""
    h,w=flat_land.shape
    aligned=cv2.resize(render_land.astype(np.uint8),(w,h),interpolation=cv2.INTER_NEAREST)>0
    kernel=np.ones((11,11),np.uint8)
    expanded=cv2.dilate(flat_land.astype(np.uint8),kernel)>0
    intersection=np.logical_and(aligned,expanded).sum()
    union=np.logical_or(aligned,expanded).sum()
    iou=float(intersection/max(1,union))
    return aligned,iou


def compare_profiles(samples):
    """Use fixed viewing-direction metadata, no forced profile agreement."""
    front=np.asarray(samples['front']['apparent_height_px'])
    back=np.asarray(samples['back']['apparent_height_px'])
    left=np.asarray(samples['left']['apparent_height_px'])
    right=np.asarray(samples['right']['apparent_height_px'])
    return {'front_back_rmse_px':float(np.sqrt(np.mean((front-back[::-1])**2))),
            'left_right_rmse_px':float(np.sqrt(np.mean((left-right[::-1])**2))),
            'front_back_max_abs_difference_px':float(np.max(abs(front-back[::-1]))),
            'left_right_max_abs_difference_px':float(np.max(abs(left-right[::-1]))),
            'profile_error_units':'SCREEN_PIXELS_NOT_WORLD_ALTITUDE',
            'no_forced_agreement':True}


def process(sources,output,v1_report=None):
    inputs=Path(sources);out=Path(output);out.mkdir(parents=True,exist_ok=True)
    top,sha_flat=read_bgr(inputs/'top_flat_semantic.jpg')
    render,sha_render=read_bgr(inputs/'top_render.png')
    if v1_report:
        prior=json.loads(Path(v1_report).read_text())
        if prior['source_sha256']['top_mask']!=sha_flat or prior['source_sha256']['top_render']!=sha_render:
            raise ValueError('V1/V2 original source SHA-256 mismatch')
    flat=segment_plan_mask(top)
    channel=channel_from_beige(top)
    render_land,render_ocean=color_ground_render(render)
    rock_score,rock_mask,local_std=rock_evidence(render,render_land)
    shoreline_distance=distance_transform_edt(~render_ocean)
    rock_interior=rock_mask & (shoreline_distance>=16)
    rock_shore_uncertain=rock_mask & ~rock_interior
    rock_aligned,scale_iou=transform_ground_to_flat(render_land,flat['land'])
    h,w=top.shape[:2]
    rock_on_flat=cv2.resize(rock_score,(w,h),interpolation=cv2.INTER_AREA)
    profiles={};frames=[];hashes={'top_flat_semantic.jpg':sha_flat,'top_render.png':sha_render}
    for key in ('front','back','left','right'):
        im,sha=read_bgr(inputs/SOURCES[key]);hashes[SOURCES[key]]=sha
        xs,ys,alt=side_silhouette(im)
        wireframe,wire_sha=read_bgr(inputs/f'{key}_wireframe.png')
        hashes[f'{key}_wireframe.png']=wire_sha
        wx,wy,walt=side_silhouette(wireframe)
        profiles[key]={'apparent_height_px':np.round(alt,2).tolist(),
          'source_image':SOURCES[key],
          'source_wireframe':f'{key}_wireframe.png',
          'wireframe_apparent_height_px':np.round(walt,2).tolist(),
          'render_vs_wireframe_rmse_px':float(np.sqrt(np.mean((alt-walt)**2))),
          'scan_left_to_right':{'front':'WEST_TO_EAST','back':'EAST_TO_WEST',
             'left':'NORTH_TO_SOUTH','right':'SOUTH_TO_NORTH'}[key],
          'z0_raster_y_px':465,'pixel_height_max':float(alt.max())}
        draw=im.copy()
        cv2.polylines(draw,[np.round(np.column_stack([wx,wy])).astype(np.int32)],
                      False,(30,245,50),2,cv2.LINE_AA)
        cv2.polylines(draw,[np.round(np.column_stack([xs,ys])).astype(np.int32)],
                      False,(0,245,255),3,cv2.LINE_AA)
        frames.append(cv2.resize(draw,(640,360)))
    comparison=compare_profiles(profiles)
    n,labels,stats,_=cv2.connectedComponentsWithStats(flat['land'].astype(np.uint8),8)
    components=[]
    for i in range(1,n):
        area=int(stats[i,cv2.CC_STAT_AREA])
        if area>=150:components.append({'component':i,'area_pixels':area})
    annotated=top.copy()
    annotated[channel['corridor']]=(0,50,235)
    cv2.polylines(annotated,[channel['centerline'].reshape(-1,1,2)],False,(0,255,255),2)
    for px,py in channel['annotations']:
        cv2.circle(annotated,(int(round(px)),int(round(py))),3,(255,40,40),-1)
    mountain_overlay=render.copy()
    mountain_overlay[rock_interior]=(mountain_overlay[rock_interior]*.55+np.array([40,255,40])*.45).astype(np.uint8)
    mountain_overlay[rock_shore_uncertain]=(mountain_overlay[rock_shore_uncertain]*.55+np.array([0,190,255])*.45).astype(np.uint8)
    def imwrite(name,img):
        if not cv2.imwrite(str(out/name),img):raise OSError('Cannot write '+name)
    def mask(name,arr): imwrite(name,arr.astype(np.uint8)*255)
    mask('land_all_components.png',flat['land'])
    mask('channel_beige_source.png',channel['beige_mask'])
    mask('channel_corridor_observed.png',channel['corridor'])
    mask('channel_centerline_1px.png',channel['thin_mask'])
    mask('channel_unsupported_pixels.png',channel['unsupported_line_pixels'])
    mask('rock_regions_candidate_render.png',rock_mask)
    mask('rock_interior_candidate_render.png',rock_interior)
    mask('rock_coastal_uncertain_render.png',rock_shore_uncertain)
    mask('render_land_candidate.png',render_land)
    mask('registered_render_land.png',rock_aligned)
    imwrite('channel_evidence_overlay.png',annotated)
    imwrite('rock_evidence_overlay.png',mountain_overlay)
    imwrite('rock_likelihood.png',np.rint(rock_score*255).astype(np.uint8))
    imwrite('rock_likelihood_on_flat_uncertain.png',np.rint(rock_on_flat*255).astype(np.uint8))
    imwrite('silhouette_views.png',np.vstack([np.hstack(frames[:2]),np.hstack(frames[2:])]))
    row=np.hstack([cv2.resize(top,(640,426)),cv2.resize(annotated,(640,426)),
                    cv2.resize(mountain_overlay,(640,426))])
    sheet=np.vstack([row,cv2.resize(np.vstack([np.hstack(frames[:2]),np.hstack(frames[2:])]),(1920,1080))])
    imwrite('v2_contact_sheet.jpg',sheet)
    (out/'channel_polyline_source_pixels.json').write_text(json.dumps({
      'coordinate_space':'top_flat_semantic.jpg raster pixels',
      'guide_points':channel['annotations'],
      'centerline_xy':channel['centerline'].tolist(),
      'confidence':'hypothesis_evidence_weighted_from_AI_source',
      'gap_pixels':int(channel['unsupported_line_pixels'].sum())},indent=2))
    (out/'orthographic_profile_constraints.json').write_text(json.dumps({
      'profiles':profiles,'cross_view_diagnostics':comparison},indent=2))
    (out/'land_components.json').write_text(json.dumps(components,indent=2))
    report={'status':'V2_2D_CONSTRAINTS_ONLY','source_sha256':hashes,
        'channel_connected_raster':bool(cv2.connectedComponents(channel['thin_mask'].astype(np.uint8),8)[0]==2),
        'channel_source_waypoints':len(channel['annotations']),
        'channel_centerline_pixel_steps':int(len(channel['centerline'])),
        'channel_centerline_beige_support_fraction':channel['centerline_beige_support'],
        'channel_mean_distance_to_beige_px':channel['mean_distance_to_beige_px'],
        'channel_visible_corridor_area_pixels':int(channel['corridor'].sum()),
        'channel_unsupported_line_pixels':int(channel['unsupported_line_pixels'].sum()),
        'land_components_min_150px':components,
        'render_rock_candidate_pixels':int(rock_mask.sum()),
        'rock_interior_candidate_pixels':int(rock_interior.sum()),
        'rock_coastal_uncertain_pixels':int(rock_shore_uncertain.sum()),
        'top_render_to_flat_scale_only_land_iou':scale_iou,
        'profile_comparison':comparison,
        'render_wireframe_rmse_px_by_direction':{
           key:profiles[key]['render_vs_wireframe_rmse_px'] for key in profiles},
        'next_gate':'human-review the channel overlay and calibrate planar map/camera before 3D heights',
        'limitations':['The beige route is AI-painted sand or corridor, not authenticated physical water.',
           'Manual waypoints guide path; any unsupported spans are exposed.',
           'Mountain mask indicates source-image rough rock texture, not measured height.',
           'Shoreline and offshore crags marked uncertain; some real coastal cliffs may be excluded.',
           'Top render and flat mask may depict inconsistent geometry; simple scale alignment is uncalibrated.',
           'Orthographic diagrams may disagree; RMSE computed only in screen pixels.',
           'No 3D coordinates, no heightmap, no physically calibrated camera, no Roblox terrain changes.']}
    (out/'v2_report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
    return report


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--sources',required=True,type=Path)
    p.add_argument('--output',required=True,type=Path)
    p.add_argument('--v1-report',type=Path)
    a=p.parse_args()
    print(json.dumps(process(a.sources,a.output,a.v1_report),indent=2))

if __name__=='__main__': main()
