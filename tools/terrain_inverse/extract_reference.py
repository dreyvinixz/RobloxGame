"""Digitize relative side-view silhouettes from AI atlas; not calibrated elevations.

Segmentation relies on reference atlas dark-blue sky versus neutral/green terrain.
Coordinates are image-specific; assertions and confidence flags avoid false precision.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import median_filter

# Screen coordinates in user-provided orthographic atlas (1536 x 1024).
PANELS = {
    'north': [625, 34, 1119, 160, 92],
    'south': [625, 168, 1119, 296, 93],
    'east': [625, 302, 1119, 417, 90],
    'west': [625, 422, 1119, 517, 90],
}


def digitize(atlas, samples=33):
    rgb = np.asarray(atlas.convert('RGB'), dtype=np.int16)
    if rgb.shape[:2] != (1024, 1536):
        raise ValueError('Expected the full 1536 x 1024 reference atlas, unscaled')
    profiles = {}
    for name, (x0, y0, x1, y1, horizon) in PANELS.items():
        crop = rgb[y0:y1, x0:x1]
        # B-R and G-R separate terrain shades from blue-gradient sky.
        mask = (crop[:, :, 2] - crop[:, :, 0] < 42) & (crop[:, :, 1] - crop[:, :, 0] < 43)
        mask[:37, :] = False  # headings and dark upper sky are not land
        mask[horizon:, :] = False  # blue water is not land
        mask = median_filter(mask.astype(np.uint8), size=3).astype(bool)
        left, right = 18, crop.shape[1]-18
        top = np.empty(right-left)
        for col in range(left, right):
            hits = np.flatnonzero(mask[:, col])
            top[col-left] = hits[0] if hits.size else horizon
        top = median_filter(top, size=9)
        top = median_filter(top, size=17) # suppress narrow coordinate-gizmo spike
        centers = np.linspace(left+5, right-6, samples)
        y = np.interp(centers, np.arange(left, right), top)
        apparent = np.clip((horizon-y)/58., 0., 1.)
        profiles[name] = np.round(apparent, 4).tolist()
    return {
        'source':'vistasortograficas.png (user-supplied AI image)',
        'source_size':[1536,1024],
        'method':'blue-sky chromatic difference threshold; column-wise skyline; median denoise',
        'calibration':'unknown; normalized image-profile height is NOT metric height',
        'samples':samples,'view_profiles':profiles,
        'horizontal_directions':{'north':'west to east','south':'west to east',
                                 'east':'north to south','west':'south to north'},
        'notes':['Labels and scene objects may contaminate silhouettes.',
                 'Multiple AI-generated views may not depict the same shape.',
                 'Profiles are algorithmic pixel observations, not geological measurements.']
    }


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--atlas',type=Path,required=True)
    parser.add_argument('--output',type=Path,default=Path('reference_constraints.json'))
    args=parser.parse_args()
    result=digitize(Image.open(args.atlas))
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print('Digitized',len(result['view_profiles']),'side profiles into',args.output)


if __name__=='__main__':
    main()
