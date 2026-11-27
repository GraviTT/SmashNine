"""Read-only asset/scope validation; writes only this report's validation.json."""
from pathlib import Path
from PIL import Image
import numpy as np
import json, hashlib, os, subprocess, datetime

ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/'reports/codex-art-100b'
OUT=ROOT/'art/bakeoff/jupi'
metrics=json.loads((REPORT/'metrics.json').read_text(encoding='utf-8'))
feet=json.loads((REPORT/'feet.json').read_text(encoding='utf-8'))
checks=[]
def check(ok, label):
    checks.append({'check':label,'passed':bool(ok)})
    if not ok: raise AssertionError(label)
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
specs={'walk':(8,13.3,True),'jump':(3,10,False),'fall':(2,8,True),'land':(2,12,False)}
asset_hashes={}
for row,(count,fps,loop) in specs.items():
    path=OUT/f'jupi-{row}-v1.png';im=Image.open(path).convert('RGBA')
    meta=json.loads(path.with_suffix('.json').read_text(encoding='utf-8'))
    check(im.size==(128*count,128),f'{row}: exact strip dimensions')
    check(meta['frames']==count and meta['fps']==fps and meta['loop'] is loop and bool(meta['note']),f'{row}: metadata')
    a=np.asarray(im)
    check(set(np.unique(a[...,3]))<={0,255},f'{row}: binary alpha')
    data=metrics['rows'][row]
    check(data['min_margin']>=4 and data['border_pixels']==0 and data['spill_pixels']==0,f'{row}: margin/border/spill')
    check(data['detail_min_percent']>=90,f'{row}: every frame detail >= 90%')
    check(data['head_scale']['trusted']>=2 and .96<=data['head_scale']['median']<=1.04,f'{row}: head median and confidence')
    check(sha(path)==sha(REPORT/data['source']),f'{row}: packaged pixels equal reviewed source')
    asset_hashes[path.relative_to(ROOT).as_posix()]=sha(path)
    if row in ('jump','fall'):
        check(all(frame['bottom']<=112 for frame in data['frames']),f'{row}: whole figure above foot line')
check(not (OUT/'jupi-hurt-v1.png').exists() and not (OUT/'jupi-hurt-v1.json').exists(),'hurt: held row absent from candidates')
check(metrics['rows']['hurt']['max_planted_boot_dx']==7,'hurt: 7px failure recorded')
check(metrics['rows']['land']['max_planted_boot_dx']<=3,'land: common-anchor boot motion <= 3px')
check(feet['max_move_2d']<=25,'walk: anatomical foot motion including loop <= 25px')
for passing in feet['passing']:
    check(abs(passing['error'])<=6 and 6<=passing['lift_above_feet_line']<=12,f"walk F{passing['frame']}: midpoint and raised toe")
    pts=feet['frames'][passing['frame']-1]
    check(sum(p['y']>=116 for p in pts.values())==1,f"walk F{passing['frame']}: exactly one planted boot (staff excluded)")
bob=feet['bob']
check(max(abs(x) for x in bob['shifts'])<=3 and bob['after']==bob['target'],'walk: bob shift and target')
before=np.asarray(Image.open(REPORT/'walk-before-bob.png'))
after=np.asarray(Image.open(REPORT/'walk-after-bob.png'))
check(np.array_equal(before[115:],after[115:]),'walk: foot rows unchanged by bob')
provenance=json.loads((REPORT/'provenance.json').read_text(encoding='utf-8'))
check(len(provenance['generations'])==18,'18 generation calls recorded')
raw_hashes={}
for item in provenance['generations']:
    raw=ROOT/item['local_raw_path'];source=Path(item['source'])
    check(raw.exists() and sha(raw)==sha(source),f"{item['id']}: copied raw equals tool output")
    raw_hashes[item['local_raw_path']]=sha(raw)
prefixes=('reports/codex-art-100b/','art/raw/jupi-100b/')
allowed_stems=tuple(f'art/bakeoff/jupi/jupi-{row}-v1.' for row in ('walk','jump','fall','hurt','land'))
def outside(lines):
    return {line for line in lines if not line[3:].replace('\\','/').startswith(prefixes+allowed_stems)}
env=dict(os.environ,GIT_OPTIONAL_LOCKS='0')
initial=(REPORT/'initial-status.txt').read_text(encoding='utf-8').splitlines()
current=subprocess.check_output(['git','status','--porcelain','-uall'],cwd=ROOT,env=env,text=True,encoding='utf-8').splitlines()
new_outside=sorted(outside(current)-outside(initial));lost_outside=sorted(outside(initial)-outside(current))
check(not new_outside and not lost_outside,'outside-scope Git status unchanged from start')
branch=subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,env=env,text=True).strip()
check(branch=='codex/jupi-100b','expected branch')
text_count=0
for path in REPORT.rglob('*'):
    if path.is_file() and path.suffix in ('.py','.md','.txt','.json','.ps1'):
        text=path.read_bytes().decode('utf-8-sig');check('\x00' not in text,f'UTF-8: {path.relative_to(REPORT).as_posix()}');text_count+=1
def directory_size(path):
    total=0;files=0;skipped=[]
    for here,dirs,names in os.walk(path,followlinks=False):
        keep=[]
        for name in dirs:
            p=Path(here)/name
            try:
                if p.stat().st_file_attributes & 0x400: skipped.append(str(p));continue
                keep.append(name)
            except OSError as exc: skipped.append(str(p)+': '+str(exc))
        dirs[:]=keep
        for name in names:
            p=Path(here)/name
            try: total+=p.stat().st_size;files+=1
            except OSError as exc: skipped.append(str(p)+': '+str(exc))
    return {'path':str(path),'bytes':total,'gib':round(total/1024**3,3),'files':files,'skipped':skipped}
sizes={key:directory_size(path) for key,path in [('workspace',ROOT),('report',REPORT),('raw',ROOT/'art/raw/jupi-100b')]}
result={'verified_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'passed':True,'checks':checks,'asset_sha256':asset_hashes,'raw_sha256':raw_hashes,'outside_scope_status_added':new_outside,'outside_scope_status_removed':lost_outside,'branch':branch,'utf8_text_files':text_count,'sizes':sizes,'limitations':['No Godot import/playback or in-game inspection','GIF files created, real-time playback not observed','Scope check compares Git status, not a full initial content-hash snapshot','Foot ROIs and near/far identities chosen by eye; coordinates measured from pixels']}
(REPORT/'validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'passed':True,'checks':len(checks),'sizes':{k:{'gib':v['gib'],'bytes':v['bytes'],'skipped':len(v['skipped'])} for k,v in sizes.items()}},ensure_ascii=False))
