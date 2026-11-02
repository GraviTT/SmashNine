"""Independent checks against CODEX-VFX-04, plus non-gating motion diagnostics."""
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'reports/codex-vfx-04'
EXPECTED=[]
for v in 'ab':
    EXPECTED.extend([(f'effects/luna/luna_barrier-{v}',256,6,10,True),
                     (f'effects/luna/luna_barrier_break-{v}',256,6,24,False)])
for stem,size,fps,loop in [('luna_cyclone',192,20,True),('luna_warp',256,24,False)]:
    EXPECTED.extend([(f'effects/luna/{stem}-{v}',size,6,fps,loop) for v in 'ab'])
EXPECTED += [('effects/luna/luna_star_shot',48,4,16,True),
             ('effects/luna/luna_star_big',96,4,16,True),
             ('ui/status/luna_star_mark',24,1,0,False)]
EXPECTED += [(f'skill_icons/luna/{name}',40,1,0,False) for name in
             ['luna_j','luna_k','luna_l','luna_brave_k','luna_brave_l']]


def run():
    result=[]
    failures=[]
    for stem,size,count,fps,loop in EXPECTED:
        path=ROOT/'art/bakeoff'/(stem+'-v1.png')
        im=Image.open(path)
        a=np.array(im)
        meta=json.loads(path.with_suffix('.json').read_text(encoding='utf-8'))
        checks=dict(rgba=im.mode=='RGBA',dimensions=im.size==(size*count,size),
                    binary_alpha=set(np.unique(a[:,:,3]))=={0,255},
                    metadata=(meta['frames']==count and meta['fps']==fps and
                              meta['anchor']==[size//2,size//2] and meta['loop']==loop),
                    transparent_rgb_zero=bool(np.all(a[a[:,:,3]==0,:3]==0)))
        fs=[a[:,i*size:(i+1)*size] for i in range(count)]
        checks['clear_1px_border']=all(not np.any(np.concatenate((f[0,:,3],f[-1,:,3],f[:,0,3],f[:,-1,3]))) for f in fs)
        checks['all_frames_nonempty']=all(np.any(f[:,:,3]) for f in fs)
        boxes=[]
        radii=[]
        for f in fs:
            yy,xx=np.where(f[:,:,3]>0)
            boxes.append([int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)])
            radii.append(round(float(np.median(np.hypot(xx-size/2,yy-size/2))),3))
        item=dict(path=str(path.relative_to(ROOT)).replace('\\','/'),
                  sha256=hashlib.sha256(path.read_bytes()).hexdigest(),checks=checks,
                  frame_bboxes=boxes,opaque_counts=[int(np.count_nonzero(f[:,:,3])) for f in fs],
                  median_opaque_radius=radii)
        if loop:
            # Alpha-weighted image difference, including the actual last -> first seam.
            diffs=[float(np.mean(np.abs(fs[(i+1)%count].astype(float)-f.astype(float)))) for i,f in enumerate(fs)]
            item['loop_diagnostics']=dict(adjacent_rgba_mae=[round(x,4) for x in diffs],
                last_to_first_over_internal_median=round(diffs[-1]/max(.001,float(np.median(diffs[:-1]))),4),
                meaning='Diagnostic only. Pixel differences do not prove perceptual smoothness.')
        if not all(checks.values()):
            failures.append(stem)
        result.append(item)
    fit=json.loads((OUT/'fit-audit.json').read_text())
    fit_check=dict(no_upscale=all(max(x['scale'])<=1 for x in fit),
                   no_cropped_pixels=all(x['cropped_pixels']==0 for x in fit),
                   maximum_source_scale=max(max(x['scale']) for x in fit),
                   processed_frames=len(fit))
    for v in 'ab':
        base=Image.open(ROOT/f'art/bakeoff/effects/luna/luna_barrier-{v}-v1.png').crop((0,0,256,256))
        broken=Image.open(ROOT/f'art/bakeoff/effects/luna/luna_barrier_break-{v}-v1.png').crop((0,0,256,256))
        fit_check[f'barrier_{v}_break_first_identical']=np.array_equal(np.array(base),np.array(broken))
    if not all(value for key,value in fit_check.items() if key not in ['maximum_source_scale','processed_frames']):
        failures.append('source-fit')
    text_issues=[]
    for p in [*(OUT.glob('*.py')),*(OUT.glob('*.md')),*(OUT.glob('*.txt')),*(OUT.glob('*.ps1')),*(OUT.glob('*.json'))]:
        for i,line in enumerate(p.read_text(encoding='utf-8-sig').splitlines(),1):
            if line.rstrip(' \t')!=line:
                text_issues.append([p.name,i])
    payload=dict(passed=not failures and not text_issues,asset_count=len(result),
                 frame_count=sum(x[2] for x in EXPECTED),failures=failures,
                 trailing_whitespace=text_issues,source_fit=fit_check,assets=result,
                 scope='Static art contract and processing only; no Godot run, no product files changed.')
    (OUT/'validation.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in payload.items() if k!='assets'},ensure_ascii=False,indent=2))
    print('LOOP SEAMS',[(Path(x['path']).stem,x['loop_diagnostics']['last_to_first_over_internal_median']) for x in result if 'loop_diagnostics' in x])
    if not payload['passed']:
        raise SystemExit(1)


if __name__=='__main__':
    run()
