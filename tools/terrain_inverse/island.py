"""Reference-constrained island terrain experiment (not original 3D recovery).
Coordinates: x east, y north, h up; xy normalized [0, 1].
Coast digitized from top-view AI atlas panel at x14:618, y33:518.
"""
import argparse
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import distance_transform_edt, gaussian_filter

COAST = [
(.096,.759),(.073,.715),(.068,.637),(.050,.571),(.057,.487),
(.036,.450),(.030,.403),(.030,.295),(.042,.260),(.058,.258),
(.092,.192),(.113,.175),(.124,.147),(.154,.146),(.166,.091),
(.185,.089),(.217,.066),(.246,.080),(.286,.080),(.307,.140),
(.352,.136),(.365,.157),(.419,.157),(.452,.082),(.464,.080),
(.425,.175),(.434,.272),(.528,.283),(.554,.266),(.565,.229),
(.619,.198),(.616,.136),(.584,.136),(.546,.161),(.543,.149),
(.657,.062),(.673,.043),(.711,.029),(.733,.066),(.775,.064),
(.783,.113),(.803,.116),(.836,.144),(.841,.204),(.906,.214),
(.927,.245),(.948,.284),(.963,.334),(.980,.371),(.977,.427),
(.982,.487),(.964,.524),(.964,.623),(.937,.662),(.937,.734),
(.907,.769),(.875,.802),(.858,.854),(.833,.862),(.787,.905),
(.767,.969),(.743,.967),(.740,.942),(.709,.920),(.634,.911),
(.600,.902),(.552,.889),(.506,.875),(.457,.866),(.415,.864),
(.365,.875),(.309,.903),(.290,.928),(.263,.889),(.212,.880),
(.174,.856),(.147,.823),(.118,.788),(.109,.765),
]
# x, y, peak amplitude, major spread, minor spread, rotation (radians).
# Relative profile assumptions; NOT measured geographic elevations.
RIDGES = [
(.115,.75,205,.190,.052,1.85),
(.105,.51,162,.230,.060,1.65),
(.155,.29,136,.160,.060,1.95),
(.265,.71,106,.125,.040,2.35),
(.28,.21,94,.120,.050,2.30),
(.84,.63,183,.210,.065,1.20),
(.88,.43,141,.160,.052,1.43),
(.80,.24,122,.130,.054,1.20),
(.74,.82,102,.105,.041,1.90),
(.59,.80,60,.065,.037,.30),
(.44,.67,57,.055,.035,1.20),
(.59,.33,52,.052,.032,2.00),
]
RIVER = [(.398,.29),(.400,.36),(.383,.407),(.416,.456),(.467,.505),(.518,.534),(.567,.549),(.587,.549)]
UPSTREAM = [(.350,.71),(.42,.655),(.50,.643),(.565,.585),(.587,.557)]
LAKE = (.616,.553,.066,.058)
ALTITUDE_MIN, ALTITUDE_MAX = -24.0, 260.0

def rasterize_coast(n, polygon=COAST):
    """Rasterize reference outline; rows go north to south."""
    image = Image.new('L',(n,n),0)
    ImageDraw.Draw(image).polygon([(round(x*(n-1)),round((1-y)*(n-1))) for x,y in polygon],fill=255)
    return np.asarray(image,dtype=np.uint8)>0

def signed_distance(mask):
    n=mask.shape[0]
    return (distance_transform_edt(mask)-distance_transform_edt(~mask))/(n-1)

def gaussian_ridge(x,y,c):
    cx,cy,amp,major,minor,theta=c
    dx=x-cx;dy=y-cy
    a=np.cos(theta);b=np.sin(theta)
    u=a*dx+b*dy;v=-b*dx+a*dy
    return amp*np.exp(-.5*((u/major)**2+(v/minor)**2))

def line_distance(x,y,points):
    """Closest polyline distance and normalized fractional path progress."""
    d2=np.full_like(x,np.inf,dtype=np.float64)
    along=np.zeros_like(x,dtype=np.float64)
    pts=np.asarray(points,dtype=float)
    lengths=np.linalg.norm(np.diff(pts,axis=0),axis=1)
    total=np.sum(lengths)
    progress=0.
    for (x0,y0),(x1,y1),length in zip(pts[:-1],pts[1:],lengths):
        t=np.clip(((x-x0)*(x1-x0)+(y-y0)*(y1-y0))/(length*length),0,1)
        dd=(x-(x0+t*(x1-x0)))**2+(y-(y0+t*(y1-y0)))**2
        better=dd<d2
        along=np.where(better,(progress+t*length)/total,along)
        d2=np.minimum(d2,dd)
        progress+=length
    return np.sqrt(d2),along

def generate(n=257,seed=20261015):
    if n<33 or n>1025:raise ValueError('grid must be 33..1025')
    rng=np.random.default_rng(seed)
    xs=np.linspace(0,1,n);ys=np.linspace(1,0,n)
    x,y=np.meshgrid(xs,ys)
    land=rasterize_coast(n)
    distance=signed_distance(land)
    ridge=np.zeros_like(x)
    for landmark in RIDGES:ridge+=gaussian_ridge(x,y,landmark)
    rough=np.zeros_like(x)
    for sigma,weight in [(n*.045,9),(n*.019,5),(n*.007,2)]:
        f=gaussian_filter(rng.standard_normal((n,n)),sigma=max(1.,sigma))
        f=f/(np.std(f)+1e-12)
        rough+=np.clip(f,-2.5,2.5)*weight
    mountain=np.clip(ridge/125,0,1)
    base=21+ridge+rough*(.24+.76*mountain)
    basin=np.exp(-.5*(((x-.49)/.22)**2+((y-.53)/.19)**2))
    base=base*(1-.50*basin)+7*basin
    edge=np.clip(distance/.023,0,1)
    base=2+np.maximum(0,base-2)*edge
    north_beach=np.exp(-((y-.91)/.10)**2)*np.exp(-((x-.47)/.24)**6)
    base=2+(base-2)*(1-.92*north_beach)
    port=np.exp(-.5*(((x-.49)/.16)**4+((y-.26)/.075)**4))
    base=base*(1-.76*port)+6*port
    lx,ly,rx,ry=LAKE
    irregular=1+.075*np.sin(16*np.arctan2((y-ly)/ry,(x-lx)/rx))
    lake=(((x-lx)/rx)**2+((y-ly)/ry)**2)<irregular**2
    dr,t=line_distance(x,y,RIVER)
    du,tu=line_distance(x,y,UPSTREAM)
    river=(dr<.0068)|(du<.004)
    riverbed=2+10*t
    streambed=13+9*(1-tu)
    base=np.minimum(base,riverbed+np.maximum(0,dr-.005)*1650)
    base=np.minimum(base,streambed+np.maximum(0,du-.003)*1200)
    base=np.where(lake,np.minimum(base,9.),base)
    seabed=-12.-7.*np.clip(-distance/.10,0,1)
    z=np.where(land,np.maximum(-2,base),seabed).astype(np.float32)
    material=np.zeros((n,n),dtype=np.uint8)
    material[land]=2
    material[land & (ridge>115) & (base>70)]=3
    material[land & ((north_beach>.5) | ((distance<.014)&(base<18)))]=1
    material[land & (port>.65)]=6
    material[land & river]=4
    material[land & lake]=5
    return {'height':z,'land':land,'material':material,'distance':distance.astype(np.float32),
            'x':x,'y':y,'seed':seed,'n':n}

def write_obj(path,z):
    """OBJ uses X east, Y altitude, Z north; nominal horizontal width=1000."""
    n=z.shape[0]
    with open(path,'w',encoding='utf-8') as f:
        f.write('# Experimental terrain; 1000 horizontal units, Y-up, Z-north\n')
        for row in range(n):
            for col in range(n):
                f.write(f'v {1000*col/(n-1):.4f} {z[row,col]:.4f} {1000*(1-row/(n-1)):.4f}\n')
        for row in range(n-1):
            for col in range(n-1):
                a=row*n+col+1;b=a+1;c=a+n;d=c+1
                f.write(f'f {a} {c} {b}\nf {b} {c} {d}\n')

def save(result,out,interactive=True):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    z=result['height'];mat=result['material'];land=result['land'];n=result['n']
    np.save(out/'height_m.npy',z)
    np.save(out/'material_classes.npy',mat)
    scaled=np.rint(np.clip((z-ALTITUDE_MIN)/(ALTITUDE_MAX-ALTITUDE_MIN),0,1)*65535).astype(np.uint16)
    Image.fromarray(scaled).save(out/'heightmap_16bit.png')
    Image.fromarray((land*255).astype('uint8')).save(out/'land_mask.png')
    colors=np.array([(12,85,139),(231,210,161),(107,143,78),(102,101,97),
                     (28,113,175),(23,119,183),(143,144,135)],dtype=np.uint8)
    Image.fromarray(colors[mat],'RGB').save(out/'material_colormap.png')
    gy,gx=np.gradient(z)
    normals=np.dstack((-gx*2,-gy*2,np.ones_like(z)*.65))
    normals/=np.linalg.norm(normals,axis=2,keepdims=True)
    illum=np.clip(np.sum(normals*np.array([.35,-.28,.89]),axis=2),.36,1)
    shade=(colors[mat].astype(float)*illum[:,:,None]).clip(0,255).astype('uint8')
    Image.fromarray(shade,'RGB').save(out/'topographic_preview.png')
    write_obj(out/'terrain.obj',z)
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    fig,axes=plt.subplots(2,2,figsize=(12,8),layout='constrained')
    axes[0,0].imshow(shade,extent=[0,1,0,1]);axes[0,0].set_title('Synthetic terrain (north up)')
    axes[0,1].imshow(land,extent=[0,1,0,1],cmap='gray')
    coast=np.asarray(COAST);axes[0,1].plot(coast[:,0],coast[:,1],lw=.8,c='red')
    axes[0,1].set_title('Digitized coastline constraint')
    axes[1,0].plot(np.linspace(0,1,n),z[int(.5*(n-1))])
    axes[1,0].set_title('West-east section, y=0.50')
    axes[1,1].plot(np.linspace(0,1,n),z[:,int(.5*(n-1))][::-1])
    axes[1,1].set_title('South-north section, x=0.50')
    for ax in axes.flat:ax.grid(alpha=.2)
    fig.savefig(out/'diagnostics.png',dpi=150)
    plt.close(fig)
    if interactive:
        import plotly.graph_objects as go
        stride=max(1,n//110)
        zz=z[::stride,::stride];mm=mat[::stride,::stride]
        xx,yy=np.meshgrid(np.linspace(0,1000,n)[::stride],np.linspace(1000,0,n)[::stride])
        fig=go.Figure(go.Surface(x=xx,y=yy,z=zz,surfacecolor=mm,
                                colorscale=[[0,'#0c558b'],[.15,'#e7d2a1'],[.34,'#6b8f4e'],[.5,'#666561'],[.68,'#1c71af'],[.84,'#1777b7'],[1,'#8f9087']],
                                cmin=0,cmax=6,showscale=False))
        fig.update_layout(title='AI island inverse-terrain: NOT an original 3D mesh',
                          scene=dict(xaxis_title='East',yaxis_title='North',zaxis_title='Relative altitude',
                                     aspectratio=dict(x=1,y=1,z=.27)),margin=dict(l=0,r=0,t=45,b=0))
        fig.write_html(out/'terrain_3d.html',include_plotlyjs=True)
    metrics={'reference_kind':'AI-generated multiview; not calibrated photogrammetry',
             'grid':n,'seed':result['seed'],'land_fraction':float(land.mean()),
             'height_min':float(z.min()),'height_max':float(z.max()),
             'reference_polygon_vertices':len(COAST),'absolute_height_accuracy':'unknown',
             'source_image':'vistasortograficas.png; top crop (14,33)-(618,518); manually reviewed trace',
             'heightmap_encoding':'16-bit grayscale linear: -24 => 0, 260 => 65535',
             'material_ids':{'0':'ocean','1':'beach','2':'grass','3':'rock','4':'river','5':'lake','6':'harbor'}}
    (out/'report.json').write_text(json.dumps(metrics,indent=2)+'\n',encoding='utf8')
    return metrics

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--grid',type=int,default=257)
    ap.add_argument('--seed',type=int,default=20261015)
    ap.add_argument('--output',default='terrain-output')
    ap.add_argument('--no-interactive',action='store_true')
    args=ap.parse_args()
    print(json.dumps(save(generate(args.grid,args.seed),args.output,not args.no_interactive),indent=2))

if __name__=='__main__':main()
