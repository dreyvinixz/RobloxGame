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
from .terrain_v3 import read_image,save_obj,predict_profile
from .isometric_v3 import silhouette_fit


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


def _preserve_cardinal_profiles(candidate, baseline):
    """Keep every sampled north/south/east/west skyline maximum unchanged."""
    row_max = np.maximum(baseline, 0).max(axis=1)
    col_max = np.maximum(baseline, 0).max(axis=0)
    bounded = np.minimum(candidate, np.minimum(row_max[:, None], col_max[None, :]))
    positive = np.maximum(baseline, 0)
    row_peak = positive.argmax(axis=1)
    col_peak = positive.argmax(axis=0)
    rows = np.arange(len(row_peak))
    cols = np.arange(len(col_peak))
    bounded[rows, row_peak] = baseline[rows, row_peak]
    bounded[col_peak, cols] = baseline[col_peak, cols]
    return bounded.astype(np.float32)


def refine_rock(field,render,classes,profiles,fit_image=None,land_grid=None):
    texture,region=rock_residual(render,field,classes)
    base_profiles=orthographic_metrics(field,profiles)
    base_mean=float(np.mean([m["rmse_px_equivalent"] for m in base_profiles.values()]))
    base_fit=(float(silhouette_fit(fit_image,field,land_grid)["normalized_rmse"])
              if fit_image is not None and land_grid is not None else None)
    candidates=[]
    positive=np.maximum(field,0)
    candidates.append({"candidate":field.copy(),"texture_amplitude_relative":0,
                        "smoothing_sigma_grid":0.,"smoothing_blend":0.,
                        "cardinal_profiles_unchanged":True})
    for sigma in (1.,1.5,2.):
        smoothed=gaussian_filter(positive,sigma)
        for blend in (.25,.5,1.):
            geometry=np.where(field>0,(1-blend)*positive+blend*smoothed,field)
            for amplitude in (0,2,4,6):
                candidate=_preserve_cardinal_profiles(geometry+amplitude*texture,field)
                metrics=orthographic_metrics(candidate,profiles)
                residual=float(np.mean([m["rmse_px_equivalent"] for m in metrics.values()]))
                gradient=np.hypot(*np.gradient(candidate))
                fit=(float(silhouette_fit(fit_image,candidate,land_grid)["normalized_rmse"])
                     if fit_image is not None and land_grid is not None else None)
                unchanged=all(np.allclose(predict_profile(candidate,k),predict_profile(field,k),
                                          rtol=0,atol=1e-6)
                              for k in ("front","back","left","right"))
                candidates.append({"candidate":candidate,
                    "texture_amplitude_relative":amplitude,
                    "smoothing_sigma_grid":sigma,"smoothing_blend":blend,
                    "mean_silhouette_rmse":residual,
                    "fit_isometric_1_normalized_rmse":fit,
                    "cardinal_profiles_unchanged":unchanged,
                    "mean_rock_gradient":float(np.mean(gradient[region])) if region.any() else 0.})
    baseline_candidate=candidates[0]
    baseline_candidate["mean_silhouette_rmse"]=base_mean
    if base_fit is not None:
        baseline_candidate["fit_isometric_1_normalized_rmse"]=base_fit
        baseline_candidate["mean_silhouette_rmse"]=base_mean
        baseline_candidate["cardinal_profiles_unchanged"]=True
    acceptable=[c for c in candidates if c["cardinal_profiles_unchanged"]]
    if base_fit is None:
        selected=baseline_candidate
        selection_rule="no_isometric_fit_supplied_choose_baseline"
    else:
        best_fit=min(c["fit_isometric_1_normalized_rmse"] for c in acceptable)
        near_best=[c for c in acceptable if
                   c["fit_isometric_1_normalized_rmse"]<=best_fit+5e-4]
        selected=max(near_best,key=lambda x:(x["texture_amplitude_relative"],
            x["smoothing_blend"],x["smoothing_sigma_grid"]))
        if best_fit >= base_fit-1e-7:
            selected=baseline_candidate
        selection_rule="fit_isometric_1_with_0.0005_tolerance_then_prefer_source_ridge_detail"
    chosen=selected["candidate"].astype(np.float32)
    public_candidates=[{k:v for k,v in c.items() if k!="candidate"} for c in candidates]
    public_selected={k:v for k,v in selected.items() if k!="candidate"}
    return chosen,{
        "base_mean_rmse":base_mean,"candidates":public_candidates,"chosen":public_selected,
        "base_fit_isometric_1_normalized_rmse":base_fit,
        "selection_rule":selection_rule,
        "held_out_isometric_2_used_for_selection":False,
        "fit_selection_tolerance_normalized_rmse":5e-4,
        "image_derived_detail_only":True,
        "geometry_smoothing_is_visual_regularization_not_source_measured":True}


def v4_graphics(out, baseline, refined, images, profiles, fit_report, heldout_report):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    out=Path(out)
    fig,axes=plt.subplots(2,2,figsize=(13,7),constrained_layout=True)
    for ax,view in zip(axes.ravel(),("front","back","left","right")):
        observed=np.asarray(profiles["profiles"][view]["apparent_height_px"],float)
        x=np.linspace(0,1,len(observed))
        old=predict_profile(baseline,view);new=predict_profile(refined,view)
        ax.plot(x,observed,label="Referência",linewidth=1.7,color="#222222")
        ax.plot(x,old,label="V3",linewidth=1.1,color="#e28b31")
        ax.plot(x,new,label="V4",linewidth=1.2,color="#277da1",linestyle="--")
        rmse=float(np.sqrt(np.mean((new-observed)**2)))
        ax.set_title(f"{view.title()} — V4 RMSE {rmse:.2f} px-equivalente")
        ax.set_xlabel("posição horizontal normalizada")
        ax.set_ylabel("altura aparente (unidades relativas)")
        ax.legend(fontsize=8)
    fig.savefig(out/"multiview_comparison_v4.png",dpi=150)
    plt.close(fig)

    fig,axes=plt.subplots(2,1,figsize=(10,6),constrained_layout=True)
    for ax,key,role,metric in (
        (axes[0],"oblique_wireframe_1.jpg","referência de ajuste",fit_report),
        (axes[1],"oblique_wireframe_2.jpg","referência reservada",heldout_report)):
        ax.plot(metric["observed"],label="Referência normalizada",color="#222222")
        ax.plot(metric["v3_predicted"],label="V3",color="#e28b31")
        ax.plot(metric["v4_predicted"],label="V4",color="#277da1",linestyle="--")
        ax.set_title(f"{key} — {role}; ajuste não calibrado, RMSE V4 {metric['v4_rmse']:.3f}")
        ax.set_xlabel("posição horizontal relativa")
        ax.set_ylabel("silhueta normalizada, sem escala física")
        ax.legend(fontsize=8)
    fig.savefig(out/"isometric_comparison_v4.png",dpi=145)
    plt.close(fig)

    fig=plt.figure(figsize=(9,7));ax=fig.add_subplot(111,projection="3d")
    n=refined.shape[0];step=max(1,n//110)
    r,c=np.mgrid[0:n:step,0:n:step]
    ax.plot_surface(c,r,refined[::step,::step],rstride=1,cstride=1,
                    linewidth=0,antialiased=False,cmap="terrain")
    ax.set_zlim(-8,160);ax.view_init(elev=31,azim=-64)
    ax.set_title("Terreno 2 V4 — vista aproximada (sem câmera calibrada)")
    ax.set_xlabel("Leste");ax.set_ylabel("Sul");ax.set_zlabel("altura relativa")
    fig.savefig(out/"render_isometric_v4.png",dpi=140,bbox_inches="tight");plt.close(fig)
    model=cv2.imread(str(out/"render_isometric_v4.png"))
    ref=images["oblique_wireframe_1.jpg"]
    cv2.imwrite(str(out/"isometric_reference_vs_model_v4.jpg"),
                np.hstack([cv2.resize(ref,(900,540)),cv2.resize(model,(900,540))]))

    import plotly.graph_objects as go
    idx=max(1,n//110)
    fig=go.Figure(go.Surface(x=np.linspace(0,1024,n)[::idx],
        y=np.linspace(1024,0,n)[::idx],z=refined[::idx,::idx],
        colorscale="Earth",showscale=False))
    fig.update_layout(title="Terreno 2 V4: heightmap relativo não calibrado",
        scene=dict(aspectratio=dict(x=1,y=1,z=.25)),margin=dict(l=0,r=0,t=40,b=0))
    fig.write_html(out/"terrain_v4.html",include_plotlyjs=True)


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
    land_grid=cv2.resize((land>0).astype(np.uint8),(n,n),
                         interpolation=cv2.INTER_NEAREST)>0
    refined,roughness=refine_rock(baseline,images["top_render.png"],classes,
        profiles,images["oblique_wireframe_1.jpg"],land_grid)
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
    keys=("oblique_wireframe_1.jpg","oblique_wireframe_2.jpg")
    iso={}
    fit_graph=None;heldout_graph=None
    for key in keys:
        before_fit=silhouette_fit(images[key],baseline,land_grid)
        after_fit=silhouette_fit(images[key],refined,land_grid)
        iso[key]={
            "v3_normalized_rmse":float(before_fit["normalized_rmse"]),
            "v4_normalized_rmse":float(after_fit["normalized_rmse"]),
            "role":"fit_reference" if key==keys[0] else "held_out",
            "uncalibrated_shape_diagnostic_only":True}
        if key==keys[0]:
            fit_graph={"v3_predicted":before_fit["predicted"],
                "v4_predicted":after_fit["predicted"],"observed":after_fit["observed"],
                "v4_rmse":float(after_fit["normalized_rmse"])}
        else:
            heldout_graph={"v3_predicted":before_fit["predicted"],
                "v4_predicted":after_fit["predicted"],"observed":after_fit["observed"],
                "v4_rmse":float(after_fit["normalized_rmse"])}
    v4_graphics(out,baseline,refined,images,profiles,fit_graph,heldout_graph)
    # Model assumptions about depth and relative volume must remain unchanged.
    for name in ("river_width_profile_v3.json","river_depth_profile_v3.json",
                 "river_volume_report_v3.json"):
        (out/name).write_bytes((Path(v3_dir)/name).read_bytes())
    report={
        "status":"V4_IMAGE_CONSTRAINED_2_5D_NO_GO_VISUAL_FIDELITY",
        "source_sha256":v3_report["source_sha256"],
        "same_source_and_branch_as_v3":True,
        "grid":n,"vertices":n*n,"triangles":2*(n-1)**2,
        "river_ocean":connectivity,"terrain_detail":roughness,
        "profile_rmse_before":before,"profile_rmse_after":after,
        "isometric_before_after_normalized_rmse":iso,
        "max_model_uncertainty_relative":float(uncertainty.max()),
        "uncertainty_semantics":"heuristic incompatible-view magnitude, not a probability or physical bound",
        "not_recovered_geometry":True,
        "limitations":[
            "No measured underwater depth, no physical 3D camera and no original 3D mesh.",
            "Ocean mouth extensions are short manually connected pixel hypotheses.",
            "Ridges are extracted from the original illustrated shadows, not measured.",
            "Cardinal profile invariance and first-isometric fit are image-space constraints, not independent 3D recovery.",
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
