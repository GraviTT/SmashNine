"""Check saved ART-96a assets, source preservation and workspace scope."""
from pathlib import Path
import hashlib
import json
import subprocess
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
R = ROOT/'reports/codex-art-96a'
A = ROOT/'art/bakeoff/xion/b'

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def git(*args):
    return subprocess.check_output(['git',*args],cwd=ROOT,text=True,encoding='utf-8').strip()

checks = {}
baseline = json.loads((R/'source-hashes.json').read_text(encoding='utf-8'))
checks['original_source_files_unchanged'] = all(sha(ROOT/p)==h for p,h in baseline.items())
checks['branch'] = git('branch','--show-current')
assert checks['branch'] == 'codex/xion-96a'
checks['product_tracked_diff_empty'] = git('diff','--name-only','--','smash-nine-prototype/') == ''
checks['staging_empty'] = git('diff','--cached','--name-only') == ''
metrics = json.loads((R/'metrics.json').read_text(encoding='utf-8'))
for file,key in [('xion_illustration-b2.png','final'),('xion_double-b2-colour.png','colour')]:
    im = Image.open(A/file)
    arr = np.array(im); rgb=arr[:,:,:3].astype(int); alpha=arr[:,:,3]
    border = np.r_[alpha[0],alpha[-1],alpha[1:-1,0],alpha[1:-1,-1]]
    fringe=(alpha>0)&(rgb[:,:,1]>np.maximum(rgb[:,:,0],rgb[:,:,2])+20)&(rgb[:,:,1]>80)
    record={'size':list(im.size),'mode':im.mode,'bytes':(A/file).stat().st_size,'sha256':sha(A/file),
        'border_nonzero':int(np.count_nonzero(border)),
        'hidden_rgb_nonzero':int(np.sum((alpha==0)&np.any(rgb!=0,axis=2))),
        'green_fringe':int(fringe.sum())}
    assert im.size == (1024,1536) and im.mode=='RGBA'
    assert record['border_nonzero']==record['hidden_rgb_nonzero']==record['green_fringe']==0
    checks[file]=record

front=np.array(Image.open(R/'foreground-layer.png'))
holo=np.array(Image.open(R/'hologram-layer.png'))
colour=np.array(Image.open(R/'double-colour-layer.png'))
final=np.array(Image.open(A/'xion_illustration-b2.png'))
x0,y0,x1,y1=metrics['main']['head_region_xyxy']
head_mask=front[y0:y1,x0:x1,3]>0
checks['head_pixel_mismatch']=int(np.sum(np.any(front[y0:y1,x0:x1]!=final[y0:y1,x0:x1],axis=2)&head_mask))
checks['head_pixels_compared']=int(head_mask.sum())
assert checks['head_pixel_mismatch']==0

# Measure saved pixels, including scanline cycle and the brightest sweep row.
scan=[]
for y in range(570,576):
    xs=np.flatnonzero(colour[y,:,3]==255)
    assert len(xs)>0
    x=int(xs[len(xs)//2])
    expected=87 if y%6<4 else 158
    actual=int(holo[y,x,3]); assert actual==expected
    scan.append({'xy':[x,y],'source_alpha':255,'hologram_alpha':actual})
checks['six_row_alpha_samples']=scan
y=602
xs=np.flatnonzero(colour[y,:,3]==255); x=int(xs[len(xs)//2])
source=colour[y,x,:3].astype(float)/255
lum=float(source @ np.array([0.299,0.587,0.114]))
expected=np.rint(np.clip(np.array([.96,.24,.34])*(.42+.85*lum)*1.6,0,1)*255).astype(int)
actual=holo[y,x,:3].astype(int)
checks['band_colour_sample']={'xy':[x,y],'source_rgb':colour[y,x,:3].tolist(),'luminance':lum,
    'expected_rgb':expected.tolist(),'actual_rgb':actual.tolist(),'max_error':int(np.max(np.abs(expected-actual)))}
assert checks['band_colour_sample']['max_error']<=1

# The full colour source's support must fit after placement, despite negative x.
box=Image.open(A/'xion_double-b2-colour.png').getbbox()
scaled_size=(round(1024*.83),round(1536*.83))
transformed=[box[0]*scaled_size[0]/1024-110,box[1]*scaled_size[1]/1536+60,
             box[2]*scaled_size[0]/1024-110,box[3]*scaled_size[1]/1536+60]
checks['double_transformed_support_inside_canvas']=transformed[0]>0 and transformed[1]>0 and transformed[2]<1024 and transformed[3]<1536

before=set((R/'baseline-status.txt').read_text(encoding='utf-8-sig').splitlines())
after=set(git('status','--porcelain=v1','--untracked-files=all').splitlines())
new=sorted(after-before)
allowed=lambda p: p.startswith('reports/codex-art-96a/') or p in {
    'art/bakeoff/xion/b/xion_illustration-b2.png','art/bakeoff/xion/b/xion_double-b2-colour.png'}
unexpected=[line for line in new if not allowed(line[3:].strip('"'))]
checks['new_or_changed_out_of_scope']=unexpected
assert not unexpected,unexpected
checks['utf8_text_files']=[]
for p in R.iterdir():
    if p.suffix.lower() in {'.md','.txt','.py','.ps1','.json'}:
        p.read_text(encoding='utf-8-sig')
        checks['utf8_text_files'].append(p.name)
checks['task_folder_bytes']={str(p.relative_to(ROOT)):sum(f.stat().st_size for f in p.rglob('*') if f.is_file())
    for p in [R,ROOT/'art/raw/xion-96a']}
assert checks['original_source_files_unchanged']
assert checks['product_tracked_diff_empty'] and checks['staging_empty']
assert checks['double_transformed_support_inside_canvas']
checks['all_checks_passed']=True
(R/'verification.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(checks,ensure_ascii=False,indent=2))
