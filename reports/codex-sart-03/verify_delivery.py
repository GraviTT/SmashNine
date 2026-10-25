"""Validate actual deliverables and unchanged source assets. No game execution."""
from pathlib import Path
import hashlib
import io
import json
from datetime import datetime
import subprocess
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
SRC=ROOT/'smash-nine-prototype/assets/art/story';DEST=ROOT/'art/bakeoff/story'
checks=[]
def check(name, passed, detail=None):
    checks.append({'check':name,'pass':bool(passed),'detail':detail})
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

audit=json.loads((OUT/'audit-v1.json').read_text(encoding='utf-8'))
for name,data in audit['sources'].items():check('unchanged ART-70 '+name,sha(SRC/name)==data['sha256'])
source=np.array(Image.open(SRC/'cg_root.png').convert('RGB'),dtype=np.int16)
for v in [2,3,4,5]:
    p=DEST/f'cg_root-v{v}.png';im=Image.open(p)
    check(f'cg_root-v{v} size/mode',im.size==(1600,900) and im.mode=='RGB')
    meta=json.loads(p.with_suffix('.json').read_text(encoding='utf-8'))
    check(f'cg_root-v{v} raw preserved',sha(ROOT/meta['raw'])==meta['raw_sha256'])
    a=np.array(im,dtype=np.int16);mask=np.array(Image.open(ROOT/meta['mask']))>0
    outside=np.abs(a-source)[~mask]
    check(f'cg_root-v{v} outside mask identical',outside.max()==0,{'mae':float(outside.mean()),'pixels':int((~mask).sum())})
    check(f'cg_root-v{v} bottom quarter identical',np.array_equal(a[675:],source[675:]))
    check(f'cg_root-v{v} Korean metadata',bool(meta.get('note_ko')) and meta['status']=='candidate')

f=Image.open(DEST/'start_card_frame-v1.png').convert('RGBA');a=np.array(f);m=24
check('start frame exact size',f.size==(480,300))
check('start frame transparent centre',not np.any(a[m:-m,m:-m,3]))
check('start frame binary alpha',set(np.unique(a[:,:,3]).tolist())=={0,255})
palette={(243,205,124),(168,116,44),(61,123,217),(159,210,255),(16,24,39)}
colors=set(map(tuple,a[a[:,:,3]>0,:3].tolist()))
check('start frame exact five-color palette',colors==palette)
check('start frame horizontal top repeats',np.all(a[:m,m:-m]==a[:m,m:m+1]))
check('start frame horizontal bottom repeats',np.all(a[-m:,m:-m]==a[-m:,m:m+1]))
check('start frame vertical left repeats',np.all(a[m:-m,:m]==a[m:m+1,:m]))
check('start frame vertical right repeats',np.all(a[m:-m,-m:]==a[m:m+1,-m:]))
check('start frame canvas corners transparent',all(a[y,x,3]==0 for x,y in [(0,0),(479,0),(0,299),(479,299)]))
meta=json.loads((DEST/'start_card_frame-v1.json').read_text(encoding='utf-8'))
check('start frame raw preserved',sha(ROOT/meta['raw'])==meta['raw_sha256'])

reference=io.BytesIO();Image.new('RGB',(8,8)).save(reference,'JPEG',quality=90,subsampling=0)
reference.seek(0);qt=Image.open(reference).quantization
sheets=[]
for p in sorted(OUT.glob('*.jpg')):
    im=Image.open(p);n=p.stat().st_size
    check('JPEG <=2 MB '+p.name,n<=2_000_000,n)
    check('JPEG quality 90 '+p.name,im.quantization==qt)
    sheets.append({'path':p.relative_to(ROOT).as_posix(),'bytes':n,'dimensions':list(im.size)})

result=subprocess.run(['git','status','--porcelain','--','smash-nine-prototype'],cwd=ROOT,capture_output=True,text=True,check=True)
check('smash-nine-prototype git status clean',not result.stdout.strip(),result.stdout.strip())
branch=subprocess.run(['git','branch','--show-current'],cwd=ROOT,capture_output=True,text=True,check=True).stdout.strip()
check('branch codex/sart-03',branch=='codex/sart-03',branch)
check('coauthor footer exact',(OUT/'commit-message.txt').read_text(encoding='utf-8').rstrip().endswith('Co-Authored-By: Codex <noreply@openai.com>'))
check('commit script exists',(OUT/'commit.ps1').is_file())

data={'timestamp_local':datetime.now().isoformat(timespec='seconds'),'passed':sum(c['pass'] for c in checks),'total':len(checks),
      'checks':checks,'sheets':sheets,'note_ko':'픽셀·파일 규격 검증이다. 미적 판정·부적의 문자 유사성·Godot 실행 검증을 자동 증명하지 않는다.'}
p=OUT/'verification-v1.json';assert not p.exists(),p
p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'passed':data['passed'],'total':data['total'],'failures':[c for c in checks if not c['pass']],'sheet_count':len(sheets),'largest_sheet_bytes':max(s['bytes'] for s in sheets)},indent=2))
if data['passed']!=data['total']:raise SystemExit(1)
