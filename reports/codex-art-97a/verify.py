from pathlib import Path
import json,subprocess,sys,hashlib
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];REPORT=ROOT/'reports/codex-art-97a'
metrics=json.loads((REPORT/'metrics.json').read_text(encoding='utf-8'));checks=[];errors=[]
def check(name,value):
    checks.append({'name':name,'pass':bool(value)})
    if not value:errors.append(name)
hashes={}
for row in ('attack','shield','victory'):
    m=metrics['rows'][row];p=ROOT/m['candidate'];im=Image.open(p);a=np.asarray(im);meta=json.loads(p.with_suffix('.json').read_text(encoding='utf-8'))
    check(row+' dimensions',im.size==(m['cell']*6,m['cell']))
    check(row+' RGBA',im.mode=='RGBA')
    check(row+' metadata',meta['frames']==6 and meta['fps']==m['fps'] and meta['loop'] is False and bool(meta['note']))
    check(row+' binary alpha',set(np.unique(a[:,:,3]))=={0,255})
    check(row+' metrics geometry',m['border_clear'] and m['minimum_margin_px']>=4 and sum(m['spill'])==0)
    check(row+' detail',min(m['detail']['per_frame_ratios'])>=.9)
    check(row+' head',m['head_scale']['used']>=2 and .96<=m['head_scale']['median']<=1.04)
    check(row+' review board',(REPORT/(row+'.png')).exists())
    hashes[row]=hashlib.sha256(p.read_bytes()).hexdigest()
check('no defeat candidate',not (ROOT/'art/bakeoff/xion/b/xion-defeat-b2.png').exists() and not (ROOT/'art/bakeoff/xion/b/xion-defeat-b2.json').exists())
if (REPORT/'validation.json').exists():
    previous=json.loads((REPORT/'validation.json').read_text(encoding='utf-8'))
    check('candidate hashes unchanged since previous validation',hashes==previous['candidate_sha256'])
text_paths=[p for p in REPORT.rglob('*') if p.is_file() and p.suffix in ('.py','.ps1','.md','.json','.txt')]
for p in text_paths:
    try:p.read_bytes().decode('utf-8-sig')
    except UnicodeDecodeError:errors.append('UTF-8 '+p.name)
check('UTF-8 text',not any(e.startswith('UTF-8 ') for e in errors))
failures=[]
for row,attempt,cell,factor in [('attack',2,128,.235),('defeat',1,192,.27),('defeat',2,192,.30)]:
    cmd=[sys.executable,'tools/sprite_pipeline/normalize.py','--sheet',f'art/raw/xion-97a/{row}-{attempt}.png','--grid','6x1','--bg','#00ff00','--cell',str(cell),'--scale-by',f'fixed:{factor}','--resample','lanczos','--sharpen','60','--despill','auto','--palette','none','--ground-all','--out-dir',f'reports/codex-art-97a/{row}-failed-gate','--name',row]
    r=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
    msg=(r.stdout+r.stderr).strip();passed=r.returncode!=0 and 'source cell subject touches' in msg
    check(f'{row} {attempt} expected source rejection',passed)
    failures.append({'row':row,'attempt':attempt,'returncode':r.returncode,'output':msg,'command':cmd[1:]})
(REPORT/'failed-gates.json').write_text(json.dumps(failures,ensure_ascii=False,indent=2),encoding='utf-8')
branch=subprocess.check_output(['git','branch','--show-current'],cwd=ROOT).decode().strip();check('branch',branch=='codex/xion-97a')
baseline=set((REPORT/'baseline-status.txt').read_text(encoding='utf-8').splitlines())
status=subprocess.check_output(['git','status','--porcelain=v1','-uall'],cwd=ROOT).decode('utf-8').splitlines()
new=[line for line in status if line not in baseline]
def allowed(line):
    path=line[3:]
    return path.startswith('reports/codex-art-97a/') or any(path.startswith(f'art/bakeoff/xion/b/xion-{row}-b2.') for row in ('attack','shield','victory','defeat'))
outside=[line for line in new if not allowed(line)];check('changed paths in card scope',not outside)
product=subprocess.check_output(['git','diff','--name-only','--','smash-nine-prototype'],cwd=ROOT).decode().strip();check('no tracked product changes',not product)
result={'checks':checks,'passed':not errors,'errors':errors,'outside_scope':outside,'candidate_sha256':hashes,'branch':branch,'art_verdicts':{k:v['status'] for k,v in metrics['rows'].items()},'runtime_tested':False}
(REPORT/'validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'passed':not errors,'checks':len(checks),'errors':errors,'art_verdicts':result['art_verdicts']}))
raise SystemExit(1 if errors else 0)
