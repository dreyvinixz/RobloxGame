"""Terrain 2 V3: source-image multiview constrained relative 2.5D.

MANDATORY original AI imagery + V2 source-pixel artifacts. No Gaussian island
generator, no surveyed altitudes or verified camera calibration.
"""
import argparse
import hashlib
import json
from pathlib import Path
import cv2
import numpy as np
from scipy.ndimage import distance_transform_edt, gaussian_filter
from PIL import Image
from .river_v3 import model_river, export_water_surface

VIEWS = ["front", "back", "left", "right"]


def read_image(path):
    raw = Path(path).read_bytes()
    image = cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError(f"Invalid original reference {path}")
    return image, hashlib.sha256(raw).hexdigest()


def source_context(src, v2):
    src, v2 = Path(src), Path(v2)
    previous = json.loads((v2 / "v2_report.json").read_text())
    required = ["top_flat_semantic.jpg", "top_render.png",
                "oblique_wireframe_1.jpg", "oblique_wireframe_2.jpg",
                "oblique_side_render.jpg"]
    images, hashes = {}, {}
    for name in required:
        images[name], hashes[name] = read_image(src / name)
    for name in ("top_flat_semantic.jpg", "top_render.png"):
        if previous["source_sha256"][name] != hashes[name]:
            raise ValueError(f"V2 SHA-256 mismatch: {name}")
    for view in VIEWS:
        name = f"{view}_render.png"
        _, digest = read_image(src / name)
        if previous["source_sha256"][name] != digest:
            raise ValueError(f"V2 orthographic source mismatch: {name}")
        hashes[name] = digest
    channel = json.loads((v2 / "channel_polyline_source_pixels.json").read_text())
    profiles = json.loads((v2 / "orthographic_profile_constraints.json").read_text())
    land = cv2.imread(str(v2 / "land_all_components.png"), cv2.IMREAD_GRAYSCALE)
    rock = cv2.imread(str(v2 / "rock_likelihood.png"), cv2.IMREAD_GRAYSCALE)
    if land is None or rock is None:
        raise ValueError("V2 source-observation masks missing")
    if land.shape != images["top_flat_semantic.jpg"].shape[:2]:
        raise ValueError("V2 source and land-mask dimensions mismatch")
    return images, hashes, channel, profiles, land > 0, rock / 255.


def observed_profiles(profiles, dim):
    p = {k: np.asarray(profiles["profiles"][k]["apparent_height_px"], float)
         for k in VIEWS}
    # Mirror opposite diagrams so X=East and Y=South agree in source pixel space.
    x = (p["front"] + p["back"][::-1]) / 2
    y = (p["left"] + p["right"][::-1]) / 2
    x = np.interp(np.linspace(0, 128, dim), np.arange(129), x)
    y = np.interp(np.linspace(0, 128, dim), np.arange(129), y)
    # Every 2.5D surface has a shared global maximum along both projection axes.
    peak = .5 * (max(x) + max(y))
    x *= peak / max(max(x), 1)
    y *= peak / max(max(y), 1)
    return x, y, {
        "combined_target_max_px": float(peak),
        "front_back_max_px": [float(p["front"].max()), float(p["back"].max())],
        "left_right_max_px": [float(p["left"].max()), float(p["right"].max())],
        "incompatible_views_regularized": True,
        "scale": "screen pixels interpreted as arbitrary relative height units"
    }


def rock_prior(rock, land, dim):
    rock = cv2.resize(rock.astype(np.float32), (dim, dim), interpolation=cv2.INTER_AREA)
    rock = gaussian_filter(rock, 2.4)
    if rock.max() > 0:
        rock /= float(rock.max())
    mask = cv2.resize(land.astype(np.uint8), (dim, dim),
                      interpolation=cv2.INTER_NEAREST) > 0
    shore = np.clip(distance_transform_edt(mask) / 4., 0, 1)
    textured = gaussian_filter(rock * mask, 4)
    weight = np.clip(.14 + .86 * (.5*rock+.5*textured), .05, 1)
    return weight * shore, mask


def fit_heightfield(rock, land, profiles, dim=257, iterations=55):
    if not 33 <= dim <= 513:
        raise ValueError("Height grid must have 33..513 points per axis")
    xx, yy, metrics = observed_profiles(profiles, dim)
    prior, land_grid = rock_prior(rock, land, dim)
    shoreline = np.clip(distance_transform_edt(land_grid) / 4.3, 0, 1)
    ceiling = np.maximum(0, np.minimum(xx[None, :], yy[:, None])) * shoreline
    field = np.minimum(ceiling, (4. + 105.*prior**1.5)*shoreline)
    for _ in range(iterations):
        missing_x = np.maximum(0, xx-field.max(axis=0))
        for j in range(dim):
            if missing_x[j] < .2:
                continue
            scores = (prior[:, j]**2.3 * shoreline[:, j] *
                      np.clip(ceiling[:, j] / max(1., xx[j]), 0, 1)**2)
            i = int(np.argmax(scores))
            a, b = max(0, i-4), min(dim, i+5)
            shape = np.exp(-.5*((np.arange(a, b)-i)/1.8)**2)
            field[a:b, j] = np.maximum(field[a:b, j], field[i, j]+missing_x[j]*shape)
        missing_y = np.maximum(0, yy-field.max(axis=1))
        for i in range(dim):
            if missing_y[i] < .2:
                continue
            scores = (prior[i, :]**2.3 * shoreline[i, :] *
                      np.clip(ceiling[i, :] / max(1., yy[i]), 0, 1)**2)
            j = int(np.argmax(scores))
            a, b = max(0, j-4), min(dim, j+5)
            shape = np.exp(-.5*((np.arange(a, b)-j)/1.8)**2)
            field[i, a:b] = np.maximum(field[i, a:b], field[i, j]+missing_y[i]*shape)
        field = np.minimum(field, ceiling)
        field = .90*field + .10*gaussian_filter(field, 1.15)
        field[shoreline < .15] = 0
        field = np.clip(field, 0, None)
    return np.where(land_grid, field, -8.).astype(np.float32), land_grid, metrics


def predict_profile(field, direction, count=129):
    land = np.maximum(field, 0)
    x, y = land.max(axis=0), land.max(axis=1)
    options = {"front": x, "back": x[::-1],
               "left": y, "right": y[::-1]}
    if direction not in options:
        raise ValueError(direction)
    arr = options[direction]
    return np.interp(np.linspace(0, len(arr)-1, count), np.arange(len(arr)), arr)


def save_obj(height, path, cell_size=4):
    n = height.shape[0]
    with Path(path).open("w") as out:
        out.write("# Terrain 2 estimated relative 2.5D. NOT original source mesh.\n")
        for r in range(n):
            for c in range(n):
                out.write(f"v {c*cell_size:.4f} {height[r,c]:.4f} {(n-1-r)*cell_size:.4f}\n")
        for r in range(n-1):
            for c in range(n-1):
                a = r*n+c+1
                out.write(f"f {a} {a+n} {a+1}\nf {a+1} {a+n} {a+n+1}\n")


def graphics(out, height, hydro_geometry, sources, profiles):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    out = Path(out)
    n = height.shape[0]
    fig, axes = plt.subplots(2, 2, figsize=(13, 6.8), constrained_layout=True)
    errors = {}
    for ax, view in zip(axes.ravel(), VIEWS):
        observed = np.asarray(profiles["profiles"][view]["apparent_height_px"], float)
        projected = predict_profile(height, view)
        difference = projected-observed
        errors[view] = {
            "rmse_px_equivalent": float(np.sqrt(np.mean(difference**2))),
            "mae_px_equivalent": float(np.mean(np.abs(difference))),
            "maximum_absolute_error": float(np.max(np.abs(difference)))
        }
        ax.plot(np.linspace(0,1,129), observed, label="Referência AI", linewidth=1.8)
        ax.plot(np.linspace(0,1,129), projected, label="V3", linewidth=1.3)
        ax.set_title(f"{view.title()} — RMSE {errors[view]['rmse_px_equivalent']:.1f} px")
        ax.set_ylim(0,160)
        ax.set_xlabel("posição horizontal normalizada")
        ax.set_ylabel("altura relativa")
        ax.legend(fontsize=8)
    fig.savefig(out / "multiview_profiles_v3.png", dpi=150)
    plt.close(fig)
    fig = plt.figure(figsize=(9, 7))
    ax = fig.add_subplot(111, projection="3d")
    step = max(1, n//110)
    r, c = np.mgrid[0:n:step,0:n:step]
    ax.plot_surface(c,r,height[::step,::step],rstride=1,cstride=1,
                    linewidth=0,antialiased=False,cmap="terrain")
    ax.set_zlim(-8,160)
    ax.view_init(elev=31,azim=-64)
    ax.set_title("Terreno 2 V3 — isométrica aproximada (sem câmera calibrada)")
    ax.set_xlabel("Leste")
    ax.set_ylabel("Sul")
    ax.set_zlabel("altura relativa")
    fig.savefig(out / "render_isometric_v3.png", dpi=140, bbox_inches="tight")
    plt.close(fig)
    ref = sources["oblique_wireframe_1.jpg"]
    model = cv2.imread(str(out / "render_isometric_v3.png"))
    cv2.imwrite(str(out / "isometric_reference_vs_model_v3.jpg"),
        np.hstack([cv2.resize(ref,(900,540)),cv2.resize(model,(900,540))]))
    import plotly.graph_objects as go
    idx = max(1,n//110)
    fig = go.Figure(go.Surface(x=np.linspace(0,1024,n)[::idx],
          y=np.linspace(1024,0,n)[::idx], z=height[::idx,::idx],
          colorscale="Earth", showscale=False))
    path = hydro_geometry["centerline_xy"]
    width,height_px = sources["top_flat_semantic.jpg"].shape[1],sources["top_flat_semantic.jpg"].shape[0]
    xy = path*np.array([(n-1)/(width-1),(n-1)/(height_px-1)])
    river_surface = hydro_geometry["surface_levels"]
    fig.add_trace(go.Scatter3d(x=xy[:,0]/(n-1)*1024,
        y=(1-xy[:,1]/(n-1))*1024,z=river_surface+.4,
        mode="lines",line=dict(color="deepskyblue",width=7),name="Canal"))
    fig.update_layout(title="Terreno 2 V3: heightmap não calibrado",
        scene=dict(aspectratio=dict(x=1,y=1,z=.25)),
        margin=dict(l=0,r=0,t=40,b=0))
    fig.write_html(out / "terrain_v3.html", include_plotlyjs=True)
    return errors


def run(sources, v2, output, grid=257):
    from .isometric_v3 import silhouette_fit, evaluate
    images, hashes, channel, profiles, land, rock = source_context(sources, v2)
    out = Path(output)
    out.mkdir(parents=True, exist_ok=True)
    elevation, land_grid, weighting = fit_heightfield(rock,land,profiles,grid)
    # Weak explicit joint objective includes source-isometric profile shape.
    # The second independent isometric view is held out until validation.
    candidates = []
    for factor in (.90, 1.0, 1.10):
        trial = np.where(land_grid,np.maximum(elevation,0)*factor,-8.).astype(np.float32)
        iso = silhouette_fit(images["oblique_wireframe_1.jpg"],trial,land_grid)
        rmse = float(np.mean([
            np.sqrt(np.mean((predict_profile(trial,view) -
                np.asarray(profiles["profiles"][view]["apparent_height_px"]))**2))
            for view in VIEWS]))
        candidates.append({"vertical_multiplier":factor,
           "ortho_rmse_mean":rmse,
           "isometric_shape_nrmse":iso["normalized_rmse"],
           "joint_objective":rmse/120 + .23*iso["normalized_rmse"]})
    selected = min(candidates,key=lambda entry: entry["joint_objective"])
    elevation = np.where(land_grid,np.maximum(elevation,0)*selected["vertical_multiplier"],-8.).astype(np.float32)
    weighting["isometric_plus_orthographic_joint_vertical_amplitude"] = {
        "candidates":candidates,
        "selected_vertical_multiplier":selected["vertical_multiplier"],
        "fit_isometric":"oblique_wireframe_1.jpg",
        "holdout_isometric":"oblique_wireframe_2.jpg",
        "warning":"Only relative silhouette shape and amplitude, NOT calibrated camera"}
    final, river, geo = model_river(images["top_flat_semantic.jpg"],elevation,channel)
    np.save(out/"height_relative_v3.npy",final)
    np.save(out/"height_land_before_river_v3.npy",elevation)
    minimum, maximum = -10.,max(150.,float(final.max()))
    Image.fromarray(np.clip(np.rint((final-minimum)/(maximum-minimum)*65535),0,65535).astype(np.uint16)).save(out/"heightmap_relative_v3_16bit.png")
    save_obj(final,out/"mesh_v3.obj")
    export_water_surface(out/"river_water_surface_v3.obj",geo,
        images["top_flat_semantic.jpg"].shape[:2],grid)
    land_mask = cv2.resize(land.astype(np.uint8),(grid,grid),interpolation=cv2.INTER_NEAREST)>0
    cliff = cv2.resize(rock.astype(np.float32),(grid,grid))
    distance = distance_transform_edt(land_mask)
    gradient = np.hypot(*np.gradient(np.maximum(final,0)))
    classes = np.zeros((grid,grid),np.uint8)
    classes[land_mask] = 4
    classes[land_mask & (distance<=3)] = 2
    classes[land_mask & (final>22)] = 5
    classes[land_mask & (final>65) & (cliff>.15)] = 6
    classes[land_mask & (gradient>11) & (final>18)] = 7
    classes[geo["river_bank_mask"]] = 3
    classes[geo["river_water_mask"]] = 1
    palette = np.array([[24,75,115],[193,107,52],[183,197,214],
                        [88,155,181],[160,166,132],[123,112,95],
                        [97,81,70],[69,64,65]],np.uint8)
    cv2.imwrite(str(out/"terrain_classes_v3.png"),palette[classes])
    cv2.imwrite(str(out/"river_mask_v3.png"),geo["river_water_mask"].astype(np.uint8)*255)
    cv2.imwrite(str(out/"river_bank_v3.png"),geo["river_bank_mask"].astype(np.uint8)*255)
    cv2.imwrite(str(out/"river_bed_depth_v3.png"),
                np.rint(np.clip(geo["depth_grid"]/12,0,1)*255).astype(np.uint8))
    cv2.imwrite(str(out/"height_preview_v3.png"),cv2.applyColorMap(
        cv2.normalize(final,None,0,255,cv2.NORM_MINMAX).astype(np.uint8),cv2.COLORMAP_TURBO))
    def save_json(name,obj):
        (out/name).write_text(json.dumps(obj,indent=2,ensure_ascii=False)+"\n")
    save_json("river_geometry_v3.json",river)
    save_json("river_centerline_v3.json",{
        "coordinate_space":"original flat reference pixels",
        "centerline_xy":geo["centerline_xy"].round(2).tolist(),
        "status":"V2 source-image path assisted by manually annotated waypoints"})
    save_json("river_width_profile_v3.json",{
        "w_source_pixels":river["width_profile_px"],"s_source_pixels":river["distance_s_px"],
        "statistics":river["width_statistics"],
        "method":"cross-sections through source beige pixels"})
    save_json("river_depth_profile_v3.json",{
        "d_relative_assumed":river["assumed_depth_profile_relative"],
        "s_source_pixels":river["distance_s_px"],
        "method":"unverified parametric bathymetry"})
    save_json("river_volume_report_v3.json",river["summary"])
    save_json("shore_river_transition_v3.json",{
        "classes":{"0":"ocean/unclassified","1":"water hypothesis","2":"coast/beach",
                   "3":"river margin","4":"plain","5":"slope","6":"peak","7":"cliff"},
        "fraction_by_class":{str(i):float(np.mean(classes==i)) for i in range(8)},
        "disclaimer":"Pixel-derived classification mixed with assumed bathymetry"})
    save_json("terrain_constraints_v3.json",{
        "orthographic_views":VIEWS,"isometric_fit":"oblique_wireframe_1.jpg",
        "isometric_validation":"oblique_wireframe_2.jpg",
        "camera_calibration":"UNAVAILABLE","river_depth":"MODEL_ASSUMPTION"})
    orthographic = graphics(out,final,geo,images,profiles)
    iso = evaluate(images,final,land_grid,out)
    report = {"status":"V3_IMAGE_CONSTRAINED_2_5D_HYPOTHESIS",
        "source_sha256":hashes,"grid_resolution":grid,"vertices":grid*grid,
        "triangles":2*(grid-1)**2,"relative_height_min":float(final.min()),
        "relative_height_max":float(final.max()),"profile_weighting":weighting,
        "orthographic_profile_error":orthographic,"river":river["summary"],
        "isometric":{
            "images_used":["oblique_wireframe_1.jpg","oblique_wireframe_2.jpg",
                           "oblique_side_render.jpg"],
            "status":"UNCALIBRATED_ISOMETRIC_SHAPE_ONLY",
            "skyline_shape_diagnostics":iso,
            "comparison_image":"isometric_reference_vs_model_v3.jpg",
            "no_pixelwise_reprojection_claim":True},
        "heightmap_encoding":{"dtype":"uint16","min_relative":minimum,
                              "max_relative":maximum},
        "limitations":[
            "AI generated views may have incompatible geometry.",
            "Elevations and river volumes are relative design quantities, not physical measurements.",
            "Isometric silhouettes are normalized; this does not calibrate a camera.",
            "Peaks are placed using rendered texture and silhouettes, not true 3D vertices.",
            "Width is inferred from beige source pixels, but bathymetry is a modeled scenario.",
            "Original raster sources are NOT checked into the GitHub repository.",
            "No Studio visual or water-physics validation has been performed."]}
    save_json("v3_report.json",report)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sources",type=Path,required=True)
    parser.add_argument("--v2",type=Path,required=True)
    parser.add_argument("--output",type=Path,required=True)
    parser.add_argument("--grid",type=int,default=257)
    args = parser.parse_args()
    print(json.dumps(run(args.sources,args.v2,args.output,args.grid),indent=2))


if __name__ == "__main__":
    main()
