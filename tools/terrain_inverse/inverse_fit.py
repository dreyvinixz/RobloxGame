"""CPU multiview silhouette inverse-design for AI-generated island concept art.

No camera calibration, depth-from-pixels or exact photogrammetry is claimed.
Opposing side views are inconsistent; fit their common silhouette in
normalized image units and report irreducible disagreement explicitly.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from scipy.optimize import least_squares

from . import island

SILHOUETTE_SCALE = 230.0  # nominal modeling scale, NOT measured meter scale
MAX_GRID = 257  # bounded CPU workload for fitting


def load_reference(path=None):
    if path is None:
        path = Path(__file__).with_name('reference_constraints.json')
    data = json.loads(Path(path).read_text(encoding='utf8'))
    arr = {k:np.asarray(v,dtype=np.float64) for k,v in data['view_profiles'].items()}
    if set(arr) != {'north','south','east','west'}:
        raise ValueError('expected the four cardinal profiles')
    if not all(v.ndim==1 and v.size>=17 and np.isfinite(v).all() and
               ((0<=v)&(v<=1)).all() for v in arr.values()):
        raise ValueError('invalid profile samples')
    if len(set(len(v) for v in arr.values()))!=1:
        raise ValueError('profile lengths differ')
    return arr


def consensus(profiles):
    return np.r_[.5*(profiles['north']+profiles['south']),
                 .5*(profiles['east']+profiles['west'][::-1])]


def opposite_conflicts(profiles):
    """Nonzero gaps quantify contradictory AI views under orthographic assumptions."""
    return {
        'north_vs_south_rmse':float(np.sqrt(np.mean((profiles['north']-profiles['south'])**2))),
        'east_vs_west_reversed_rmse':float(np.sqrt(np.mean((profiles['east']-profiles['west'][::-1])**2)))
    }


def projected_profiles(z,land,samples):
    """Ideal orthographic skylines; reference images are approximations only."""
    a=np.maximum(np.where(land,z,0.),0.)
    n=a.shape[0]
    coords=np.linspace(0,1,n)
    sample_coords=np.linspace(0,1,samples)
    ns=np.interp(sample_coords,coords,a.max(axis=0))/SILHOUETTE_SCALE
    ew=np.interp(sample_coords,coords,a.max(axis=1))/SILHOUETTE_SCALE
    return np.r_[ns,ew]


def model_components(base):
    """Local ridge/basin correction basis; coastline and waterways remain anchored."""
    z=base['height'].astype(np.float64)
    # Ensure original generator's mountain peaks do not saturate the 16-bit export.
    z=np.where(z>0,z*.72,z)
    xx,yy=base['x'],base['y']
    coast=np.clip(base['distance']/.03,0,1)
    protected=(base['material']==4)|(base['material']==5)
    port=np.where(base['material']==6,.20,1.)
    taper=coast*port*np.where(protected,.05,1.)*base['land']
    basis=[]
    for ridge in island.RIDGES:
        cx,cy,_,major,minor,theta=ridge
        basis.append(island.gaussian_ridge(xx,yy,(cx,cy,1.,major,minor,theta))*taper)
    for cx,cy,wx,wy in ((.50,.52,.24,.20),(.42,.76,.16,.12),(.61,.33,.16,.13)):
        basis.append(np.exp(-.5*(((xx-cx)/wx)**2+((yy-cy)/wy)**2))*taper)
    return z,np.asarray(basis)


def fit(reference=None,grid=129,seed=20261015,max_nfev=65):
    if grid<33 or grid>MAX_GRID:
        raise ValueError('fit grid must be 33..257')
    ref=load_reference(reference)
    baseline=island.generate(grid,seed)
    source,basis=model_components(baseline)
    target=consensus(ref)
    samples=len(ref['north'])
    keep=np.arange(samples)%2==0
    train=np.r_[keep,keep]
    holdout=~train

    def projected(params):
        h=source+np.tensordot(params,basis,axes=(0,0))
        h=np.where(baseline['land'],np.clip(h,0,255),source)
        return projected_profiles(h,baseline['land'],samples)

    def residual(params):
        err=projected(params)[train]-target[train]
        # Penalize large edits and avoid making the terrain entirely unlike base.
        return np.r_[err,(params/65)*.065]

    initial=np.zeros(len(basis),dtype=np.float64)
    solution=least_squares(residual,initial,bounds=(-68,68),max_nfev=max_nfev,method='trf',
                           diff_step=2e-3,xtol=2e-5,ftol=2e-5,gtol=2e-5)
    before=projected(initial)
    after=projected(solution.x)
    fitted=source+np.tensordot(solution.x,basis,axes=(0,0))
    fitted=np.where(baseline['land'],np.clip(fitted,0,255),source).astype(np.float32)
    output=dict(baseline)
    output['height']=fitted

    def score(p,index):
        return float(np.sqrt(np.mean((p[index]-target[index])**2)))

    report={
        'method':'CPU bounded least-squares, Gaussian terrain basis and orthographic silhouettes',
        'views':'Four AI-generated side panels; only two mathematically distinct silhouette axes',
        'metric':'RMSE in normalized apparent skyline height; scale not calibrated',
        'source':'User-supplied atlas, stored as digitized 33-point reference profiles',
        'side_view_conflicts':opposite_conflicts(ref),
        'baseline':{'train_rmse':score(before,train),'holdout_rmse':score(before,holdout)},
        'optimized':{'train_rmse':score(after,train),'holdout_rmse':score(after,holdout)},
        'optimization':{'success':bool(solution.success),'message':str(solution.message),
                        'evaluations':int(solution.nfev),'amplitude_corrections':solution.x.tolist()},
        'known_limits':[
            'No identifiable original 3D mesh from AI art.',
            'Opposite rendered vistas conflict; do not claim exact multiview fit.',
            'Side views assume orthographic camera without verified intrinsic/extrinsic calibration.',
            'Not a differentiable renderer or learned-depth inference.',
            'Holdout uses odd skyline samples from the same image, not independent 3D truth.'
        ]
    }
    return output,report,ref,before,after


def plot_fit(out,ref,before,after):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    fig,axes=plt.subplots(2,2,figsize=(14,7),layout='constrained')
    samples=len(ref['north'])
    axis=np.linspace(0,1,samples)
    panels=[
        ('North/South: west to east',before[:samples],('north','south')),
        ('East/West: north to south',before[samples:],('east','west')),
        ('North/South after inverse fit',after[:samples],('north','south')),
        ('East/West after inverse fit',after[samples:],('east','west'))
    ]
    for ax,(title,prediction,views) in zip(axes.flat,panels):
        for view in views:
            observed=ref[view][::-1] if view=='west' else ref[view]
            ax.plot(axis,observed,lw=1,alpha=.62,label=f'AI {view} observed')
        ax.plot(axis,prediction,lw=2,label='Model projected silhouette')
        ax.set_ylim(-.04,1.2)
        ax.set_title(title)
        ax.set_xlabel('Normalized horizontal coordinate')
        ax.set_ylabel('Apparent normalized height')
        ax.legend(fontsize=8)
        ax.grid(alpha=.18)
    fig.savefig(out/'silhouette_comparison.png',dpi=135)
    plt.close(fig)


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--grid',type=int,default=129)
    ap.add_argument('--seed',type=int,default=20261015)
    ap.add_argument('--export-grid',type=int,default=257)
    ap.add_argument('--output',type=Path,default=Path('terrain-output'))
    ap.add_argument('--reference',type=Path)
    ap.add_argument('--max-nfev',type=int,default=65)
    ap.add_argument('--no-interactive',action='store_true')
    args=ap.parse_args()
    result,report,ref,before,after=fit(args.reference,args.grid,args.seed,args.max_nfev)
    if args.export_grid != args.grid:
        if not 33<=args.export_grid<=1025:
            raise ValueError('export-grid must be 33..1025')
        hi=island.generate(args.export_grid,args.seed)
        source,basis=model_components(hi)
        params=np.asarray(report['optimization']['amplitude_corrections'])
        hi['height']=np.where(hi['land'],
            np.clip(source+np.tensordot(params,basis,axes=(0,0)),0,255),
            source).astype(np.float32)
        result=hi
    out=args.output
    out.mkdir(exist_ok=True,parents=True)
    base=island.save(result,out,interactive=not args.no_interactive)
    plot_fit(out,ref,before,after)
    (out/'inverse_fit_report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
    print(json.dumps({'terrain':base,'inverse_fit':report},indent=2))


if __name__=='__main__':
    main()
