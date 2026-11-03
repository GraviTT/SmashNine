"""Validate the task card's PNG/JSON contract without touching Godot files."""
from pathlib import Path
import ast
import hashlib
import json
import math
import subprocess
import numpy as np
from PIL import Image
from build_effects import SPECS

ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/'reports/codex-vfx-05'
errors=[]
rows=[]


def check(ok,message):
    if not bool(ok): errors.append(message)


def validate(path,size,count,fps,anchor,loop,replaces,kind):
    check(path.exists(),f'Missing {path}')
    if not path.exists():return
    img=Image.open(path)
    check(img.mode=='RGBA',f'RGBA: {path.name}')
    check(img.size==(size[0]*count,size[1]),f'Size: {path.name}')
    a=np.array(img.convert('RGBA'))
    check(set(np.unique(a[:,:,3])).issubset({0,255}),f'Alpha: {path.name}')
    check(np.all(a[a[:,:,3]==0]==0),f'Invisible RGB: {path.name}')
    meta=json.loads(path.with_suffix('.json').read_text(encoding='utf-8'))
    for key,expected in [('frames',count),('fps',fps),('anchor',anchor),('loop',loop),('replaces',replaces)]:
        check(meta.get(key)==expected,f'{path.name} {key}: {meta.get(key)} != {expected}')
    check(bool(meta.get('note')),f'Note: {path.name}')
    frames=[];bounds=[];borders=[]
    for n in range(count):
        f=a[:,n*size[0]:(n+1)*size[0]]
        check(f[:,:,3].any(),f'Empty frame {path.name}/{n}')
        border=int(np.count_nonzero(f[[0,-1],:,3]))
        if kind!='tile':border+=int(np.count_nonzero(f[:,[0,-1],3]))
        check(border==0,f'Border {path.name}/{n}: {border}')
        borders.append(border);frames.append(f)
        bounds.append(list(Image.fromarray(f[:,:,3]).getbbox()))
    row=dict(file=str(path.relative_to(ROOT)).replace('\\','/'),frame_size=list(size),frames=count,fps=fps,anchor=anchor,
             loop=loop,binary_alpha=True,border_pixels=borders,bounds=bounds,sha256=hashlib.sha256(path.read_bytes()).hexdigest())
    if count>1:
        differences=[]
        for n in range(count):
            f=frames[n][:,:,:3].astype(float);g=frames[(n+1)%count][:,:,:3].astype(float)
            differences.append(float(np.abs(f-g).mean()))
        row['frame_rgb_mae']=differences
        row['closing_step_to_mean']=differences[-1]/max(float(np.mean(differences)),1e-9)
        row['loop_seconds']=count/fps
        check(np.mean(differences)>0,f'Static loop: {path.name}')
        check(row['closing_step_to_mean']<=1.75,f'Loop wrap outlier: {path.name}')
    if kind=='tile':
        row['seam_max_channel_difference']=int(np.abs(a[:,0].astype(int)-a[:,-1].astype(int)).max())
        check(row['seam_max_channel_difference']==0,f'Tile seam: {path.name}')
        row['continuous_core_rows']=[y for y in range(size[1]) if np.all(a[y,:,3]>0)]
        check(bool(row['continuous_core_rows']),f'Tile disconnected core: {path.name}')
    if kind=='field':
        y,x=np.mgrid[:640,:640];r=np.hypot(x-320,y-320)
        f=frames[0]
        row['interior_max_rgb']=int(f[:,:,:3][r<280].max())
        check(row['interior_max_rgb']<=16,f'Field interior too bright: {path.name}')
        # Scan strongest pixels near the intended gameplay boundary at every angle.
        angle=np.linspace(-math.pi,math.pi,360,endpoint=False)
        radii=np.arange(296,304.01,.5)
        xs=np.rint(320+np.cos(angle[:,None])*radii).astype(int)
        ys=np.rint(320+np.sin(angle[:,None])*radii).astype(int)
        pix=f[ys,xs];lum=pix[:,:,:3].max(axis=2)*(pix[:,:,3]>0)
        peaks=radii[lum.argmax(axis=1)]
        row['rim_peak_radius_p05_p50_p95']=[float(v) for v in np.quantile(peaks,[.05,.5,.95])]
        row['rim_ray_coverage']=float((lum.max(axis=1)>35).mean())
        check(row['rim_ray_coverage']>=.98,f'Field rim gaps: {path.name}')
        check(abs(float(np.median(peaks))-300)<=1.5,f'Field radius: {path.name}')
        check(float(np.quantile(np.abs(peaks-300),.95))<=3,f'Field radius spread: {path.name}')
    if kind=='sphere':
        y,x=np.mgrid[:320,:320];r=np.hypot(x-160,y-160)
        check(all(np.all(f[r<=55,3]==255) and np.all(f[r<=55,:3]<=8) for f in frames),f'Black core: {path.name}')
        check(all(not np.any(f[r>150,3]) for f in frames),f'Sphere outer radius: {path.name}')
        row['opaque_black_core_diameter']=110
        row['outer_radius_limit']=150
    rows.append(row)


for kind,(name,size,count,fps,anchor,replaces,additive) in SPECS.items():
    for v in 'ab':validate(ROOT/f'art/bakeoff/effects/nova/{name}-{v}-v1.png',size,count,fps,anchor,count>1,replaces,kind)
for v in 'ab':
    for s in (1,2,3):validate(ROOT/f'art/bakeoff/ui/status/nova_gravity_{s}-{v}-v1.png',(24,24),1,0,[12,12],False,f'assets/art/ui/status/nova_gravity_{s}.png','mark')
for k in 'jklui':validate(ROOT/f'art/bakeoff/skill_icons/nova/nova_{k}-v1.png',(40,40),1,0,[20,20],False,f'assets/art/skill_icons/nova_{k}.png','icon')

processing=json.loads((REPORT/'processing.json').read_text(encoding='utf-8'))
for key,e in processing.items():
    check(min(e['scale_source_per_output'])>=1,'Upscaled '+key)
    raw=ROOT/e['source']
    e['raw_present_in_this_clone']=raw.exists()
    if raw.exists():e['raw_sha256']=hashlib.sha256(raw.read_bytes()).hexdigest()

for p in REPORT.glob('*.py'):
    ast.parse(p.read_text(encoding='utf-8'),filename=p.name)
for p in REPORT.glob('*'):
    if p.suffix in {'.py','.ps1','.md','.txt','.json','.html'}:
        for n,line in enumerate(p.read_text(encoding='utf-8-sig').splitlines(),1):
            check(line==line.rstrip(),f'Trailing whitespace: {p.name}:{n}')
check(not list(REPORT.rglob('__pycache__')),'Unexpected __pycache__')
check(len(rows)==23,'Expected 23 candidate PNGs')
check(sum(r['frames'] for r in rows)==65,'Expected 65 frames')
product_diff=subprocess.check_output(['git','diff','--name-only','--','smash-nine-prototype/'],cwd=ROOT,text=True).strip()
check(not product_diff,'Product tracked files changed: '+product_diff)
baseline_path=REPORT/'baseline-status.txt'
baseline=baseline_path.read_text(encoding='utf-8').splitlines() if baseline_path.exists() else []
current=subprocess.check_output(['git','status','--short','--','smash-nine-prototype/'],cwd=ROOT,text=True).splitlines()
baseline_product=[x for x in baseline if 'smash-nine-prototype/' in x]
if baseline_path.exists():check(current==baseline_product,'Product status differs from starting state')
result=dict(passed=not errors,candidate_pngs=len(rows),total_frames=sum(r['frames'] for r in rows),errors=errors,
            product_tracked_changes=product_diff,product_status_unchanged=(current==baseline_product if baseline_path.exists() else 'No local baseline'),items=rows,processing=processing,
            browser_preview='Browser access host unavailable; interactive playback not verified in browser.',
            engine_execution='Not run: candidates only, no Godot project modifications.')
(REPORT/'measurements.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:result[k] for k in ('passed','candidate_pngs','total_frames','errors','product_status_unchanged')},ensure_ascii=False,indent=2))
for r in rows:
    print(Path(r['file']).name, 'loop_ratio='+str(round(r.get('closing_step_to_mean',0),3)), 'rim='+str(r.get('rim_peak_radius_p05_p50_p95','')), 'seam='+str(r.get('seam_max_channel_difference','')))
raise SystemExit(1 if errors else 0)
