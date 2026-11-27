"""Read-only product audit; outputs only this task's report. Does not run Git writes."""
import os, sys, json, hashlib, subprocess, re
from pathlib import Path
from datetime import datetime, timezone
from collections import Counter
from PIL import Image
import numpy as np
from config import ROOT, ROWS, ORDER
sys.path.insert(0, str(Path('tools/sprite_pipeline').resolve()))
import normalize as n

START = datetime(2026, 11, 26, 15, 8, 25, tzinfo=timezone.utc)
DEADLINE = datetime(2026, 11, 26, 17, 38, 25, tzinfo=timezone.utc)
errors = []
def check(ok, message):
    if not ok: errors.append(message)
def read(p): return json.loads(Path(p).read_text(encoding='utf-8'))
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def git(*args):
    return subprocess.run(['git', *args], check=True, capture_output=True, text=True, encoding='utf-8').stdout
rows = read(ROOT/'selection.json')
check([(r['stem'],r['row']) for r in rows] == ORDER[:len(rows)], 'Delivery order')
results=[]
for r in rows:
    key=r['stem']+'-'+r['row']; p=Path('art/bakeoff/rio')/(key+'-v1.png')
    c=read(ROOT/(key+'-checks.json'));m=c['metrics'];face=c['face']; b=ROOT/r['stem']/r['row']/f'attempt-{r["attempt"]}'
    check(len(c['extraction']['boxes'])==6,key+': six silhouette extractions')
    check('no fixed-width' in c['extraction']['method'],key+': variable silhouette crops')
    if not r['accepted']:
        check(not p.exists() and not p.with_suffix('.json').exists(),key+': held file exported')
        results.append({'row':key,'status':'held','reason':r['note']})
        continue
    check(p.exists(),key+': missing PNG')
    im=Image.open(p);check(im.mode=='RGBA' and im.size==(1152,192),key+': dimensions/mode')
    meta=read(p.with_suffix('.json'));fps,loop,label=ROWS[r['row']]
    for field,value in {'frames':6,'fps':fps,'loop':loop,'cell':192,'feet':[96,152],'for':label,'factor':m['summary']['common_scale']}.items():
        check(meta.get(field)==value,key+': metadata '+field)
    check(bool(re.search('[가-힣]',meta['note'])),key+': Korean note')
    check(sha(p)==c['sheet_sha256']==face.get('sheet_sha256'),key+': measured-sheet hash')
    check(p.read_bytes()==(b/(key+'.png')).read_bytes(),key+': source differs')
    ratios=[f['face_width_ratio'] for f in face['frames'] if f['frame'] in r['face_frames']]
    check(r['face_verified'] and ratios and all(v is not None and .95<=v<=1.06 for v in ratios),key+': face width range')
    check(all(f['eye_ratio'] is None and f.get('eye_excluded') for f in face['frames']),key+': hidden-eye limitation recorded')
    check(m['summary']['resample']=='lanczos' and m['summary']['sharpen_percent']==60 and m['summary']['despill']=='auto' and m['summary']['palette']=='none',key+': pipeline settings')
    anchor=Image.open(f'art/bakeoff/rio/{r["stem"]}-idle-v2.png').convert('RGBA').crop((0,0,128,128))
    reference=n.interior_detail(anchor); fs=[]
    for j in range(6):
        f=im.crop((j*192,0,(j+1)*192,192)); a=np.asarray(f)[:,:,3]; box=f.getbbox()
        check(box is not None,key+f': F{j+1} empty')
        margin=min(box[0],box[1],192-box[2],192-box[3]); bottom=box[3]-1
        spill=n.spill_pixel_count(f); detail=n.interior_detail(f)/reference
        check(set(np.unique(a)).issubset({0,255}),key+f': F{j+1} alpha')
        check(margin>=4,key+f': F{j+1} border/margin')
        check(spill==0,key+f': F{j+1} green spill')
        check(detail>=.9,key+f': F{j+1} detail')
        lift=152-bottom
        check(0<=lift<=12 if r['row']=='decoy_step' else lift==0,key+f': F{j+1} foot position')
        fs.append({'frame':j+1,'margin':margin,'bottom':bottom,'lift':lift,'spill':spill,'detail_ratio':round(detail,4)})
    results.append({'row':key,'status':'delivered','face_ratios':ratios,'sha256':sha(p),'frames':fs})
ledger=read(ROOT/'generation-ledger.json'); counts=Counter((g['stem'],g['row']) for g in ledger)
check(all(v<=2 for v in counts.values()),'Generation limit exceeded')
refs=[str((Path.cwd()/p).resolve()).replace('\\','/') for p in ['art/bakeoff/rio/rio_male-idle-v2.png','art/bakeoff/rio/rio_female-idle-v2.png','smash-nine-prototype/assets/art/rio/rio_male_moves_sheet.png']]
for g in ledger:
    before=datetime.strptime(g['before']['current_time'],'%Y-%m-%d %H:%M:%S UTC').replace(tzinfo=timezone.utc)
    after=datetime.strptime(g['after']['current_time'],'%Y-%m-%d %H:%M:%S UTC').replace(tzinfo=timezone.utc)
    check(START<=before<=after<=DEADLINE,g['raw']+': generation clocks')
    check(g['references']==refs,g['raw']+': references')
    check(sha(g['raw'])==g['sha256'],g['raw']+': raw hash')
    check(g['prompt'] in (ROOT/'prompts.txt').read_text(encoding='utf-8'),g['raw']+': prompt missing')
baseline=(ROOT/'baseline-diff.txt').read_text(encoding='utf-8').splitlines()
tracked=git('diff','--name-only').splitlines();check(tracked==baseline,'Tracked file changes beyond baseline')
check(not git('diff','--name-only','--','smash-nine-prototype/').strip(),'Product changes')
check(not git('diff','--cached','--name-only').strip(),'Unexpected staged changes')
stage=read(ROOT/'files-to-stage.json')
for name in ['README.md','audit.json','audit.py','overview.png','overview.py','commit.ps1','generation-ledger.json','prompts.txt','selection.json','publish.py']:
    check((ROOT/name).as_posix() in stage,'Required handoff file missing from stage list: '+name)
for r in rows:
    if r['accepted']:
        for ext in ['png','json']:
            check(f'art/bakeoff/rio/{r["stem"]}-{r["row"]}-v1.{ext}' in stage,'Delivered file missing from stage list')
for s in stage:
    p=Path(s)
    check(p.exists(),'Missing stage path: '+s)
    check(s=='design/tasks/CODEX-SKM-08.md' or s.startswith('reports/codex-skm-08/') or bool(re.fullmatch(r'art/bakeoff/rio/rio_(male|female)-(sword_throw|counter_stance|pierce|decoy_step|flurry_cut)-v\d+\.(png|json)',s)),'Out-of-scope stage path: '+s)
    check(not any(t in s for t in ['art/raw/','/attempt-','__pycache__','run.log']),'Forbidden stage path: '+s)
    if p.suffix in {'.py','.ps1','.md','.json','.txt'}:
        data=p.read_bytes(); text=data.decode('utf-8')
        check(not any(line.endswith((' ','\t')) for line in text.splitlines()),s+': trailing whitespace')
        if s!='design/tasks/CODEX-SKM-08.md':check(b'\r' not in data,s+': non-LF line endings')
        if p.suffix=='.py':
            try: compile(text,str(p),'exec')
            except SyntaxError as e: errors.append(s+': '+str(e))
ps=subprocess.run(['powershell','-NoProfile','-Command',"$tokens=$null; $parseErrors=$null; [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path 'reports/codex-skm-08/commit.ps1'),[ref]$tokens,[ref]$parseErrors) > $null; if ($parseErrors.Count) { $parseErrors | Out-String; exit 1 }; Write-Output 'parse OK'"],capture_output=True,text=True)
check(ps.returncode==0,'commit.ps1 parse failed: '+ps.stdout+ps.stderr)
def size(folder):
    total=0
    for d,dirs,files in os.walk(folder):
        for f in files:
            try:total+=(Path(d)/f).stat().st_size
            except OSError:pass
    return total
workspace=size(Path.cwd()); task=size(ROOT)+size(Path('art/raw/skm-08'))+sum(Path(s).stat().st_size for s in stage if s.startswith('art/bakeoff/'))
now=datetime.now(timezone.utc)
check(now<=DEADLINE,'Audit exceeded hard stop')
out={'status':'PASS' if not errors else 'FAIL','checked_at_utc':now.isoformat(),'elapsed_minutes':round((now-START).total_seconds()/60,2),'start_utc':START.isoformat(),'hard_stop_utc':DEADLINE.isoformat(),'delivered':sum(r['accepted'] for r in rows),'held':sum(not r['accepted'] for r in rows),'not_reached':[s+'-'+r for s,r in ORDER if (s,r) not in [(v['stem'],v['row']) for v in rows]],'generation_count':len(ledger),'generation_counts':{s+'-'+r:v for (s,r),v in counts.items()},'stage_file_count':len(stage),'tracked_diff':tracked,'product_unchanged':not git('diff','--name-only','--','smash-nine-prototype/').strip(),'commit_script':'syntax parsed only; not executed','workspace_path':str(Path.cwd()),'workspace_gb':round(workspace/1e9,3),'task_mb':round(task/1e6,3),'results':results,'errors':errors}
(ROOT/'audit.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({k:out[k] for k in ['status','delivered','held','generation_count','elapsed_minutes','workspace_gb','task_mb','errors']},ensure_ascii=True))
sys.exit(0 if not errors else 1)
