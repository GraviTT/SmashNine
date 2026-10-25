"""Read-only independent delivery checks; JSON on stdout only."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/bakeoff/monsters';REPORT=ROOT/'reports/codex-art-85'
SPECS=[('svartalfheim_cog_drone-projectile-v2',8,48,48,'none'),('niflheim_frost_owl-projectile-v2',4,48,48,'right'),('yggdrasil_root_guardian-shockwave-v1',4,64,48,'right')]
summary=[]
for stem,n,w,h,aim in SPECS:
    im=Image.open(OUT/(stem+'.png'));assert im.mode=='RGBA' and im.size==(n*w,h)
    j=json.loads((OUT/(stem+'.json')).read_text(encoding='utf-8'))
    assert j['frames']==n and j['fps']==12 and j['cell']==(48 if w==48 else [w,h]) and j['aim']==aim
    assert j['note'] and (ROOT/j['replaces']).is_file()
    cells=[];hashes=[];margins=[];greens=[]
    for k in range(n):
        f=im.crop((k*w,0,(k+1)*w,h));a=np.array(f);b=f.getbbox();assert b
        margin=min(b[0],b[1],w-b[2],h-b[3]);assert margin>=2
        assert not np.any(a[:2,:,3]) and not np.any(a[-2:,:,3]) and not np.any(a[:,:2,3]) and not np.any(a[:,-2:,3])
        assert not np.any(a[:,:,:3][a[:,:,3]==0]);assert a[:,:,3].max()==255 and a[:,:,3].min()==0
        green=(a[:,:,3]>=24)&(a[:,:,0]<=40)&(a[:,:,1]>=215)&(a[:,:,2]<=40);assert not green.any()
        hashes.append(hashlib.sha256(a.tobytes()).hexdigest());margins.append(margin);cells.append(a)
        if w==64:assert b[3]==44 and j['floor']==44
    assert len(set(hashes))==n
    if stem.startswith('niflheim'):
        for a in cells:assert np.array_equal(a[:,23:],cells[0][:,23:]) and np.array_equal(a[:,:,3],cells[0][:,:,3])
    if stem.startswith('svartalfheim'):assert j['processing']['rotation_degrees_clockwise']==list(range(0,360,45))
    summary.append({'file':stem+'.png','frames':n,'cell':[w,h],'minimum_margin':min(margins),'distinct_frames':len(set(hashes))})
sources=json.loads((REPORT/'sources.json').read_text(encoding='utf-8'))
for r in sources['references']:
    assert hashlib.sha256((ROOT/r['original']).read_bytes()).hexdigest()==r['sha256']
    assert hashlib.sha256((ROOT/r['copy']).read_bytes()).hexdigest()==r['sha256']
for p in REPORT.iterdir():
    if p.suffix in ['.md','.json','.py','.txt','.ps1']:assert b'\r\n' not in p.read_bytes(),p
print(json.dumps({'result':'PASS','candidates':summary,'unchanged_reference_files':len(sources['references']),'godot_executed':False},ensure_ascii=False,indent=2))
