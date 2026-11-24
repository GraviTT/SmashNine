"""Read-only asset audit; writes report JSON only, with explicit missing-icon results."""
import hashlib
import json
import math
from pathlib import Path
import sys
sys.dont_write_bytecode = True
import numpy as np
from PIL import Image
from build_assets import ROOT, REPORT, SPECS, output_path, save_json

results=[]
for name,spec in SPECS.items():
    w,h,n,fps,anchor,loop,replaces=spec
    for variant in 'ab':
        p=output_path(name,variant)
        if not p.exists():
            results.append(dict(file=str(p.relative_to(ROOT)).replace('\\','/'),status='NOT_REACHED'))
            continue
        im=Image.open(p); a=np.array(im); meta=json.loads(p.with_suffix('.json').read_text(encoding='utf-8'))
        frames=[a[:,k*w:(k+1)*w] for k in range(n)]
        counts=[int((f[:,:,3]>0).sum()) for f in frames]
        boxes=[]
        for f in frames:
            yy,xx=np.where(f[:,:,3]>0)
            boxes.append([int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)])
        checks={
            'size':im.size==(w*n,h), 'rgba':im.mode=='RGBA',
            'alpha_0_255':set(np.unique(a[:,:,3])).issubset({0,255}),
            'empty_1px_border':all(not (f[0,:,3].any() or f[-1,:,3].any() or f[:,0,3].any() or f[:,-1,3].any()) for f in frames),
            'nonempty_frames':all(counts),
            'distinct_frames':len({hashlib.sha256(f.tobytes()).hexdigest() for f in frames})==n,
            'metadata':meta['frames']==n and meta['fps']==fps and tuple(meta['anchor'])==anchor and meta['loop']==loop and meta['replaces']==replaces,
            'no_upscale':all(0<s<=1 for ex in meta.get('extraction',[]) for s in ex['scale']),
            'boards':all((REPORT/f'{name}-{variant}-{scale}x.png').exists() for scale in ([1,4] if name in ('xion_blast','xion_recoil_blast','xion_point_blank','xion_reload') else [1])),
        }
        metrics=dict(frame_size=[w,h],strip_size=list(im.size),frames=n,fps=fps,anchor=list(anchor),loop=loop,
                     duration_seconds=n/fps,opaque_pixels=counts,bboxes=boxes)
        if name=='xion_blast':
            metrics['max_reach_from_anchor_px']=max(b[2]-1-anchor[0] for b in boxes)
            angles=[]
            for f in frames:
                yy,xx=np.where((f[:,:,3]>0)&(f[:,:,1]>140)&(np.indices(f.shape[:2])[1]>48))
                angles.append(None if not len(xx) else round(float(np.max(np.abs(np.degrees(np.arctan2(yy-anchor[1],xx-anchor[0]))))),2))
            metrics['bright_outer_pixel_angles_deg']=angles
            checks['bright_pixels_within_14deg_beyond_x48']=all(a is None or a<=14 for a in angles)
        if name=='xion_recoil_blast':
            metrics['max_depth_from_anchor_px']=max(b[3]-1-anchor[1] for b in boxes)
            metrics['max_halfwidth_px']=max(max(anchor[0]-b[0],b[2]-1-anchor[0]) for b in boxes)
        if name=='xion_point_blank':
            checks['duration_under_150ms']=n/fps<.15
            metrics['max_occupied_size']=[max(b[2]-b[0] for b in boxes),max(b[3]-b[1] for b in boxes)]
            # Conservative face zone: all pixels at least 30 px above the target body centre.
            checks['clear_above_body_minus30']=not any(f[:anchor[1]-30,:,3].any() for f in frames)
        if name=='xion_reload':
            ring_counts=[]
            yy,xx=np.indices((h,w)); radial=np.hypot(xx-12,yy-12)>=7.5
            for f in frames:
                ring_counts.append(int((radial&(f[:,:,0]>200)&(f[:,:,1]<150)&(f[:,:,3]>0)).sum()))
            metrics['filled_ring_pixels']=ring_counts
            checks['progress_increases']=all(a<b for a,b in zip(ring_counts,ring_counts[1:]))
        if name=='xion_dive_trail':
            checks['erases_from_start']=all(a[0]<b[0] for a,b in zip(boxes,boxes[1:]))
        results.append(dict(file=str(p.relative_to(ROOT)).replace('\\','/'),status='PASS' if all(checks.values()) else 'FAIL',
                            checks=checks,metrics=metrics,sha256=hashlib.sha256(p.read_bytes()).hexdigest()))

for key in 'jklui':
    p=output_path('xion_'+key)
    results.append(dict(file=str(p.relative_to(ROOT)).replace('\\','/'),status='NOT_REACHED' if not p.exists() else 'UNREVIEWED'))

report=dict(status='partial-hard-stop',
            start_kst='2026-11-24T07:18:45+09:00',deadline_kst='2026-11-24T09:38:45+09:00',
            clock_gap=dict(last_before_kst='2026-11-24T07:25:37+09:00',first_after_kst='2026-11-24T14:34:16+09:00',cause='unknown'),
            schedule='FAIL: the already submitted batch continued after deadline; no more assets after this was observed',
            product_code_changed=False,live_godot_test=False,results=results)
save_json(REPORT/'validation.json',report)
for r in results:
    print(r['status'],r['file'],[k for k,v in r.get('checks',{}).items() if not v])
print('SUMMARY',len([r for r in results if r['status']=='PASS']),'PASS;',len([r for r in results if r['status']=='FAIL']),'FAIL;',len([r for r in results if r['status']=='NOT_REACHED']),'NOT_REACHED')
