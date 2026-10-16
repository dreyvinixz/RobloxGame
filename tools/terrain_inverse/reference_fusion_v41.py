"""V4.1: align AI-cleaned illustration to ORIGINAL screenshot and trace evidence-backed 2D grid.
Original source pixels are authoritative. AI-clean image is a weak corroborator.
No camera, 3D heights, polygon topology or fabricated inpainted edges are inferred.
"""
import argparse, hashlib, json
from pathlib import Path
import cv2
import numpy as np
from scipy.spatial import cKDTree
from skimage.morphology import skeletonize

def read(path):
    raw=Path(path).read_bytes()
    image=cv2.imdecode(np.frombuffer(raw,np.uint8),cv2.IMREAD_COLOR)
    if image is None: raise ValueError('Invalid input image: '+str(path))
    return image,hashlib.sha256(raw).hexdigest()

def align(original,clean):
    a=cv2.cvtColor(original,cv2.COLOR_BGR2GRAY)
    b=cv2.cvtColor(clean,cv2.COLOR_BGR2GRAY)
    orb=cv2.ORB_create(nfeatures=4500,fastThreshold=9)
    ka,da=orb.detectAndCompute(a,None)
    kb,db=orb.detectAndCompute(b,None)
    if da is None or db is None:
        return original,{'status':'rejected','reason':'no descriptors'},False
    pairs=cv2.BFMatcher(cv2.NORM_HAMMING).knnMatch(db,da,k=2)
    good=[m for m,n in pairs if m.distance<.77*n.distance]
    if len(good)<22:
        return original,{'status':'rejected','reason':'too few matches','matches':len(good)},False
    src=np.float32([kb[m.queryIdx].pt for m in good])
    dst=np.float32([ka[m.trainIdx].pt for m in good])
    H,inliers=cv2.findHomography(src,dst,cv2.RANSAC,4.)
    if H is None or not np.isfinite(H).all():
        return original,{'status':'rejected','reason':'homography failure'},False
    chosen=inliers.ravel().astype(bool)
    residual=np.linalg.norm(cv2.perspectiveTransform(src[chosen][None],H)[0]-dst[chosen],axis=1)
    n=int(chosen.sum());med=float(np.median(residual)) if n else float('inf')
    accept=n>=35 and med<=2.9 and n/len(good)>=.33
    report={'status':'accepted' if accept else 'rejected','good_matches':len(good),
            'inliers':n,'inlier_fraction':round(n/len(good),4),
            'median_reprojection_error_px':round(med,3),
            'homography_aux_to_original':H.round(8).tolist() if accept else None}
    h,w=original.shape[:2]
    return (cv2.warpPerspective(clean,H,(w,h)) if accept else original),report,accept

def masks(original,clean):
    b,g,r=cv2.split(original)
    water=(b.astype('int16')>r.astype('int16')+15)&(b.astype('int16')>g.astype('int16')+6)&(b>90)
    gray=cv2.cvtColor(clean,cv2.COLOR_BGR2GRAY)
    h,w=gray.shape
    allowed=~water
    allowed[:100,:230]=False # coordinate gizmo, not terrain
    y=np.indices((h,w))[0]
    bright=allowed&(gray>=139)&(y>=165)
    cliff=allowed&(gray>=52)&(gray<139)&(y>=180)
    unknown=allowed&~(bright|cliff)
    return water,bright,cliff,unknown

def dark_lines(image,zone,threshold):
    gray=cv2.cvtColor(image,cv2.COLOR_BGR2GRAY)
    a=cv2.morphologyEx(gray,cv2.MORPH_BLACKHAT,cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(9,9)))
    b=cv2.morphologyEx(gray,cv2.MORPH_BLACKHAT,cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(17,17)))
    strength=np.maximum(a.astype('float32'),b.astype('float32')*.7)
    candidate=(strength>threshold)&zone
    n,ids,stat,_=cv2.connectedComponentsWithStats(candidate.astype(np.uint8),8)
    keep=stat[:,cv2.CC_STAT_AREA]>=5;keep[0]=False
    return keep[ids],strength

def support(mask,p,q):
    a,b=np.asarray(p,float),np.asarray(q,float)
    t=np.linspace(0,1,max(3,int(np.linalg.norm(b-a)*1.4)))
    pts=a[None,:]*(1-t[:,None])+b[None,:]*t[:,None]
    x=np.rint(pts[:,0]).astype(int);y=np.rint(pts[:,1]).astype(int)
    h,w=mask.shape
    valid=(x>=0)&(x<w)&(y>=0)&(y<h)
    return float(mask[y[valid],x[valid]].mean()) if valid.sum()>=2 else 0.

def trace(binary,original_evidence,zone,max_lines=10000):
    skeleton=skeletonize(binary)
    raw=cv2.HoughLinesP(skeleton.astype(np.uint8)*255,1,np.pi/360,
                        threshold=8,minLineLength=9,maxLineGap=4)
    if raw is None:return []
    records=[]
    for x0,y0,x1,y1 in raw[:,0]:
        p=[int(x0),int(y0)];q=[int(x1),int(y1)]
        length=float(np.hypot(x1-x0,y1-y0))
        if length<11:continue
        observed=support(original_evidence,p,q)
        if observed<.42:continue
        records.append({'p0':p,'p1':q,'length_px':round(length,2),
                        'angle_rad':float(np.arctan2(y1-y0,x1-x0)%np.pi),
                        'original_pixel_support':round(observed,3),'zone':zone})
    return sorted(records,key=lambda item:-item['length_px'])[:max_lines]

def connect(lines,original_evidence,clean_support,water):
    lines=list(lines)
    if not lines:return [],{'observed_segments':0,'gap_bridge_candidates':0,'family_axes_rad':[]}
    vectors=np.float32([[np.cos(2*ln['angle_rad']),np.sin(2*ln['angle_rad'])] for ln in lines])
    cv2.setRNGSeed(7)
    _,groups,centers=cv2.kmeans(vectors,2,None,
        (cv2.TERM_CRITERIA_EPS+cv2.TERM_CRITERIA_MAX_ITER,30,.001),6,cv2.KMEANS_PP_CENTERS)
    for ln,group in zip(lines,groups.ravel()):ln['family']=int(group)
    pts=np.array([p for line in lines for p in (line['p0'],line['p1'])],float)
    bridges=[];visited=set()
    h,w=water.shape
    for i,j in cKDTree(pts).query_pairs(10.):
        a,b=i//2,j//2
        if a==b or lines[a]['family']!=lines[b]['family']:continue
        aa,bb=lines[a],lines[b]
        diff=abs(aa['angle_rad']-bb['angle_rad'])
        if min(diff,np.pi-diff)>.16:continue
        p,q=pts[i],pts[j];d=np.linalg.norm(q-p)
        if not 3<=d<=10:continue
        direction=np.array([np.cos(aa['angle_rad']),np.sin(aa['angle_rad'])])
        if abs(direction[0]*(q-p)[1]-direction[1]*(q-p)[0])/d>.38:continue
        xy=np.rint([p,q]).astype(int)
        if water[np.clip(xy[:,1],0,h-1),np.clip(xy[:,0],0,w-1)].any():continue
        s=support(original_evidence,p,q)
        c=support(clean_support,p,q)
        if not (s>=.23 or (s>=.08 and c>=.50)):continue
        key=tuple(sorted((a,b)))
        if key in visited:continue
        visited.add(key)
        bridges.append({'p0':p.astype(int).tolist(),'p1':q.astype(int).tolist(),
                        'zone':aa['zone'],'family':int(aa['family']),
                        'type':'gap_bridge','confidence':'weak_hypothesis' if s<.23 else 'observed',
                        'original_pixel_support':round(s,3),
                        'auxiliary_support':round(c,3)})
    axes=(.5*np.arctan2(centers[:,1],centers[:,0])%np.pi).tolist()
    return lines+bridges,{'observed_segments':len(lines),
                         'gap_bridge_candidates':len(bridges),
                         'family_axes_rad':[round(float(v),4) for v in axes]}

def graph(lines,snap=3.):
    pts=np.asarray([p for e in lines for p in (e['p0'],e['p1'])],float).reshape(-1,2)
    if not len(pts):return [],{'components':0,'vertices':0,'edges':0,'largest_component_endpoints':0}
    par=np.arange(len(pts))
    def find(i):
        while par[i]!=i:
            par[i]=par[par[i]];i=par[i]
        return i
    for i,j in cKDTree(pts).query_pairs(snap):par[find(i)]=find(j)
    roots=np.array([find(i) for i in range(len(pts))]);members=sorted(set(roots))
    dictionary={r:k for k,r in enumerate(members)}
    vertices=[{'id':dictionary[r],'xy_image_px':pts[roots==r].mean(axis=0).round(2).tolist(),
               'world_xyz':None} for r in members]
    for k,line in enumerate(lines):
        line['vertex_ids']=[dictionary[roots[2*k]],dictionary[roots[2*k+1]]]
    cluster_parent=np.arange(len(vertices))
    def root(i):
        while cluster_parent[i]!=i:
            cluster_parent[i]=cluster_parent[cluster_parent[i]];i=cluster_parent[i]
        return i
    for line in lines:
        a,b=line['vertex_ids']
        cluster_parent[root(a)]=root(b)
    sizes={}
    for i in range(len(vertices)):
        r=root(i);sizes[r]=sizes.get(r,0)+1
    return vertices,{'components':len(sizes),'vertices':len(vertices),
                     'edges':len(lines),'largest_component_vertices':max(sizes.values(),default=0)}

def run(original_path,clean_path,output,baseline_report=None):
    original,original_sha=read(original_path)
    clean,clean_sha=read(clean_path)
    if original.shape!=clean.shape:raise ValueError('Original and clean images must share dimensions')
    aligned,registration,accepted=align(original,clean)
    water,bright,cliff,unknown=masks(original,aligned)
    gray=cv2.cvtColor(original,cv2.COLOR_BGR2GRAY)
    cg=cv2.cvtColor(aligned,cv2.COLOR_BGR2GRAY)
    changed=(cv2.absdiff(gray,cg)>29)&~water if accepted else np.zeros_like(water)
    light_orig,one=dark_lines(original,bright,5.)
    cliff_orig,two=dark_lines(original,cliff,8.)
    original_strokes=light_orig|cliff_orig
    light_clean,_=dark_lines(aligned,bright,5.)
    cliff_clean,_=dark_lines(aligned,cliff,8.)
    clean_strokes=(light_clean|cliff_clean) if accepted else np.zeros_like(original_strokes)
    clean_near=cv2.dilate(clean_strokes.astype(np.uint8),np.ones((5,5),np.uint8))>0
    retained_original=original_strokes&(~changed|clean_near)
    rejected_object_strokes=original_strokes&~retained_original
    original_weak=(np.maximum(one,two)>3.)|(cv2.Canny(gray,35,110)>0)
    weak_near=cv2.dilate(original_weak.astype(np.uint8),np.ones((3,3),np.uint8))>0
    auxiliary=clean_strokes&weak_near&~water&~changed
    fused=retained_original|auxiliary
    light=trace(fused&bright,original_weak,'light')
    cliffs=trace(fused&cliff,original_weak,'cliff')
    nearclean=cv2.dilate(clean_strokes.astype(np.uint8),np.ones((5,5),np.uint8))>0
    lines,info=connect(light+cliffs,original_weak,nearclean,water)
    vertices,stats=graph(lines)
    for line in lines:
        if line.get('type')!='gap_bridge':
            line['confidence']='corroborated_2d_stroke' if support(nearclean,line['p0'],line['p1'])>=.3 else 'original_only_2d_stroke'
    out=Path(output);out.mkdir(parents=True,exist_ok=True)
    def image(name,arr):
        if arr.dtype==bool:arr=arr.astype(np.uint8)*255
        if not cv2.imwrite(str(out/name),arr):raise OSError('Cannot save '+name)
    image('water_mask.png',water)
    image('terrain_confident_mask.png',bright)
    image('cliff_candidate_mask.png',cliff)
    image('uncertain_mask.png',unknown|changed)
    image('changed_content_mask.png',changed)
    image('original_observed_strokes.png',original_strokes)
    image('original_withheld_strokes.png',rejected_object_strokes)
    image('fused_stroke_mask.png',fused)
    image('normalized_observation.png',cv2.createCLAHE(clipLimit=2,tileGridSize=(12,12)).apply(gray))
    overlay=original.copy()
    predicted=np.zeros(original_strokes.shape,np.uint8)
    for ln in lines:
        color=(0,165,255) if ln.get('type')=='gap_bridge' else ((255,100,45) if ln['zone']=='cliff' else (40,235,240))
        cv2.line(overlay,tuple(ln['p0']),tuple(ln['p1']),color,1,cv2.LINE_AA)
        cv2.line(predicted,tuple(ln['p0']),tuple(ln['p1']),255,1)
    image('v41_topology_overlay.png',overlay)
    for zone, color in [('light',(40,235,240)),('cliff',(255,100,45))]:
        layer=original.copy()
        for line in lines:
            if line['zone']==zone:
                cv2.line(layer,tuple(line['p0']),tuple(line['p1']),color,1,cv2.LINE_AA)
        image('grid_'+zone+'_overlay.png',layer)
    triple=np.concatenate([original,aligned,overlay],axis=1)
    image('comparison_original_clean_v41.png',cv2.resize(triple,(int(triple.shape[1]*.5),int(triple.shape[0]*.5))))
    baseline={}
    if baseline_report:
        old=json.loads(Path(baseline_report).read_text())
        baseline={'v4_components_not_comparable':old['segment_graph']['components']}
        prior=Path(baseline_report).parent/'segment_graph.json'
        if prior.exists():
            pg=json.loads(prior.read_text())
            earlier=np.zeros_like(predicted)
            coords=[v['xy_image_px'] for v in pg['vertices']]
            for e in pg['edges']:
                p,q=(tuple(np.rint(coords[i]).astype(int)) for i in e['vertex_ids'])
                cv2.line(earlier,p,q,255,1)
            expanded=cv2.dilate(earlier,np.ones((5,5),np.uint8))>0
            baseline['v4_coverage_on_same_original_mask_2px']=round(float((expanded&original_strokes).sum()/max(1,original_strokes.sum())),5)
    expanded=cv2.dilate(predicted,np.ones((5,5),np.uint8))>0
    coverage=round(float((expanded&original_strokes).sum()/max(1,original_strokes.sum())),5)
    metrics={**info,**stats,'light_segments':len(light),'cliff_segments':len(cliffs),
             'v41_coverage_on_same_original_mask_2px':coverage,
             'withheld_original_pixels':int(rejected_object_strokes.sum())}
    report={'source_original_sha256':original_sha,'source_clean_sha256':clean_sha,
            'image_size_px':[original.shape[1],original.shape[0]],
            'registration':registration,'auxiliary_used':accepted,
            'pixel_zones':{'water':int(water.sum()),'bright_candidate':int(bright.sum()),
                           'cliff_candidate':int(cliff.sum()),'changed':int(changed.sum()),
                           'uncertain':int((unknown|changed).sum())},
            'v41':metrics,'baseline':baseline,
            'status':'2D_LINE_HYPOTHESES_ONLY',
            'limitations':['No triangle faces, 3D reconstruction or camera calibration.',
                           'AI-clean rendering may modify the original wireframe; it is auxiliary only.',
                           'More segments may raise component count; topology continuity is not validated.',
                           'Masks and image-space coverage are heuristic, not ground-truth precision.']}
    for zone in ('light','cliff'):
        (out/f'grid_families_{zone}.json').write_text(json.dumps([v for v in lines if v['zone']==zone],indent=2)+'\n')
    for name,obj in [('v41_edges.json',lines),('v41_vertices.json',vertices),
                     ('v41_faces_candidates.json',[]),('v41_report.json',report)]:
        (out/name).write_text(json.dumps(obj,indent=2)+'\n')
    return report

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--original',type=Path,required=True)
    p.add_argument('--clean',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--baseline-report',type=Path)
    a=p.parse_args()
    print(json.dumps(run(a.original,a.clean,a.output,a.baseline_report),indent=2))

if __name__=='__main__':main()
