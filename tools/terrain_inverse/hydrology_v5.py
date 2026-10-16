"""Source-pixel constrained lake -> river -> harbor hydrology for the V5 terrain.

AI concept art has no surveyed levels; all water levels remain *relative*.
The river waypoints are auditable annotations of the source top-view pixels,
not a procedurally generated river or recovered hydraulic simulation.
"""
from pathlib import Path
import json
import cv2
import numpy as np
from scipy.ndimage import distance_transform_edt
from skimage.graph import route_through_array


def blue_evidence(bgr):
    b, g, r = [channel.astype(np.float32) for channel in cv2.split(bgr)]
    return np.clip((np.minimum(b-r, g-r)-3.0)/28.0, 0.0, 1.0)


def labeled_lake(blue, lake_seed, minimum_area=45):
    mask = (blue > .48).astype(np.uint8)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    _, labels, stats, _ = cv2.connectedComponentsWithStats(mask, 8)
    x, y = map(int, lake_seed)
    if not (0 <= y < mask.shape[0] and 0 <= x < mask.shape[1]):
        raise ValueError('Lake seed outside original reference')
    if labels[y, x] == 0:
        y0, x0 = max(0,y-7), max(0,x-7)
        yy, xx = np.where(mask[y0:y+8, x0:x+8] > 0)
        if not len(xx):
            raise ValueError('Lake seed not supported by blue reference pixels')
        nearest = np.argmin((xx+x0-x)**2 + (yy+y0-y)**2)
        x, y = int(xx[nearest]+x0), int(yy[nearest]+y0)
    label = int(labels[y, x])
    if not label or stats[label, cv2.CC_STAT_AREA] < minimum_area:
        raise ValueError('Missing identifiable reference lake')
    return labels == label


def trace_river(top, waypoints, radius=22):
    """Find paths constrained to short source-image waypoint corridors."""
    h, w = top.shape[:2]
    points = np.asarray(waypoints, dtype=float)
    if points.ndim != 2 or points.shape[1] != 2 or len(points) < 3:
        raise ValueError('At least 3 source river waypoints [x,y] required')
    if (points < 0).any() or (points[:, 0] >= w).any() or (points[:, 1] >= h).any():
        raise ValueError('River waypoint outside original reference')
    color = blue_evidence(top)
    complete = []
    for a, b in zip(points[:-1], points[1:]):
        x0 = max(0, int(np.floor(min(a[0], b[0]))) - radius)
        y0 = max(0, int(np.floor(min(a[1], b[1]))) - radius)
        x1 = min(w, int(np.ceil(max(a[0], b[0]))) + radius + 1)
        y1 = min(h, int(np.ceil(max(a[1], b[1]))) + radius + 1)
        a0 = np.rint(a - [x0,y0]).astype(int)
        b0 = np.rint(b - [x0,y0]).astype(int)
        guide = np.ones((y1-y0, x1-x0), np.uint8)
        cv2.line(guide, tuple(a0), tuple(b0), 0, 1)
        distance = distance_transform_edt(guide)
        cost = 1.0 + 5.0*(1.0-color[y0:y1,x0:x1])**2 + .055*distance**2
        pixel_path, _ = route_through_array(
            cost.astype(np.float64), tuple(a0[::-1]), tuple(b0[::-1]),
            fully_connected=True, geometric=True)
        segment = [[int(px+x0), int(py+y0)] for py,px in pixel_path]
        complete.extend(segment[1:] if len(complete) else segment)
    return np.asarray(complete, dtype=np.int32), color


def build_hydrology(top, field, annotations):
    """Produce a gap-free riverbed, lake bathymetry and a monotone water line."""
    source_h, source_w = top.shape[:2]
    rows, cols = field.shape
    if rows != cols or rows < 33:
        raise ValueError('Expected square heightmap grid >= 33')
    route, blue = trace_river(top, annotations['lake_to_port_waypoints_px'],
                              radius=int(annotations.get('routing_corridor_px', 22)))
    lake = labeled_lake(blue, annotations['lake_seed_px'])
    scale = np.asarray([(cols-1)/(source_w-1), (rows-1)/(source_h-1)])
    grid_path = np.rint(route * scale).astype(np.int32)
    center = np.zeros((rows,cols), np.uint8)
    progress = np.full((rows,cols), np.nan, np.float32)
    lengths = np.r_[0, np.cumsum(np.linalg.norm(np.diff(route.astype(float),axis=0),axis=1))]
    total = max(1., float(lengths[-1]))
    for i in range(len(grid_path)-1):
        a, b = tuple(grid_path[i]), tuple(grid_path[i+1])
        cv2.line(center, a, b, 255, 1)
        cv2.line(progress, a, b, float((lengths[i]+lengths[i+1])/(2*total)), 1)
    distance, indices = distance_transform_edt(center == 0, return_indices=True)
    t = np.nan_to_num(progress[indices[0],indices[1]],nan=0.)
    lake_grid = cv2.resize(lake.astype(np.uint8), (cols,rows),
                           interpolation=cv2.INTER_NEAREST)>0
    core_radius = max(1., float(annotations.get('river_half_width_px',5))*scale[0])
    river_core = distance <= core_radius
    blend = max(1.5, float(annotations.get('bank_blend_px',14))*scale[0])
    upstream = float(annotations.get('lake_surface_relative',12.))
    downstream = float(annotations.get('port_surface_relative',0.))
    if upstream < downstream:
        raise ValueError('River must descend or stay level toward the port')
    depth = float(annotations.get('water_depth_relative',2.5))
    if depth <= 0: raise ValueError('Water depth must be positive')
    surface = upstream + (downstream-upstream)*np.clip(t,0,1)
    bed = surface-depth
    updated = field.astype(np.float32).copy()
    updated[lake_grid] = upstream-depth
    updated[river_core] = bed[river_core]
    rise = float(annotations.get('bank_rise_relative',4.5))
    banks = (distance <= core_radius+blend) & ~river_core & ~lake_grid
    edge_height = bed+rise*np.clip((distance-core_radius)/blend,0,1)
    updated[banks] = np.minimum(updated[banks],edge_height[banks])
    lake_dist = distance_transform_edt(~lake_grid)
    lake_banks = (lake_dist>0) & (lake_dist<=blend)
    updated[lake_banks] = np.minimum(updated[lake_banks],
        (upstream-depth+rise*np.clip(lake_dist/blend,0,1))[lake_banks])
    combined = river_core | lake_grid
    labels = cv2.connectedComponents(combined.astype(np.uint8),8)[1]
    lake_grid_seed = np.rint(np.asarray(annotations['lake_seed_px'])*scale).astype(int)
    outlet = grid_path[-1]
    connected = bool(labels[lake_grid_seed[1],lake_grid_seed[0]] and
                     labels[lake_grid_seed[1],lake_grid_seed[0]] ==
                     labels[outlet[1],outlet[0]])
    if not connected:
        raise ValueError('Lake and harbor not connected on terrain grid')
    water_line = upstream+(downstream-upstream)*(lengths/total)
    if np.any(np.diff(water_line)>1e-6):
        raise ValueError('Nonmonotone downstream water surface')
    report = {
        'status':'CONNECTED_HYDROLOGY_DESIGN_HYPOTHESIS',
        'lake_to_harbor_connected':connected,
        'top_source_route_pixels':len(route),
        'river_core_grid_pixels':int(river_core.sum()),
        'lake_grid_pixels':int(lake_grid.sum()),
        'modified_height_pixels':int((abs(updated-field)>1e-4).sum()),
        'source_blue_support_at_route':float(np.mean(blue[route[:,1],route[:,0]]>.20)),
        'monotone_surface_downstream':True,
        'river_start_surface':upstream,
        'river_end_surface':downstream,
        'cross_section':'Relative modeling units, not measured elevations',
        'limitations':[
            'Source waypoint tracing is manually annotated, not surveyed watercourse data.',
            'AI images can contain conflicting lake/outlet/harbor geometry.',
            'Independent water surface OBJ requires Roblox Studio water/material integration.'
        ]
    }
    return {'height':updated,'river_mask':river_core,'lake_mask':lake_grid,
            'water_mask':combined,'path_xy':route,'river_level':water_line,
            'source_blue':blue,'report':report}


def write_water_ribbon(path, route, levels, source_size, half_width=5.):
    """Independent surface OBJ to inspect continuous water in Blender/Roblox."""
    h,w = source_size
    stride = max(1,len(route)//350)
    positions = route[::stride].astype(float)
    source_index = np.arange(0,len(route),stride)
    z = levels[source_index]
    with Path(path).open('w',encoding='utf-8') as file:
        file.write('# Source-anchored water surface, arbitrary relative height\n')
        for i,p in enumerate(positions):
            delta = positions[min(i+1,len(positions)-1)]-positions[max(i-1,0)]
            if np.linalg.norm(delta)<1e-6: delta=np.array([1.,0.])
            normal=np.array([-delta[1],delta[0]])/np.linalg.norm(delta)
            for sign in (-1,1):
                x,y=p+sign*half_width*normal
                file.write(f'v {x/(w-1)*1000:.5f} {z[i]:.5f} {(1-y/(h-1))*1000:.5f}\n')
        for i in range(len(positions)-1):
            a=2*i+1
            file.write(f'f {a} {a+2} {a+1}\nf {a+1} {a+2} {a+3}\n')


def save_hydrology(out, top, data, annotations):
    out=Path(out)
    out.mkdir(parents=True,exist_ok=True)
    overlay=top.copy()
    cv2.polylines(overlay,[data['path_xy'].reshape(-1,1,2)],False,(35,235,245),2)
    for x,y in annotations['lake_to_port_waypoints_px']:
        cv2.circle(overlay,(int(x),int(y)),3,(255,30,255),-1)
    cv2.imwrite(str(out/'river_reference_overlay.png'),overlay)
    for filename,key in [('river_mask_grid.png','river_mask'),
                         ('lake_mask_grid.png','lake_mask'),
                         ('water_connected_grid.png','water_mask')]:
        cv2.imwrite(str(out/filename),data[key].astype(np.uint8)*255)
    write_water_ribbon(out/'river_water_surface.obj',data['path_xy'],data['river_level'],
        top.shape[:2],half_width=float(annotations.get('river_half_width_px',5)))
    (out/'hydrology_report.json').write_text(
        json.dumps(data['report'],indent=2)+'\n',encoding='utf8')
