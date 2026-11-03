"""Verify actual SKM-05 files and scope; never run Godot or commit.ps1."""
import os, sys, json, re, hashlib, subprocess
from pathlib import Path
import numpy as np
from PIL import Image
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
root=Path('reports/codex-skm-05')
rows=json.loads((root/'selection.json').read_text(encoding='utf-8'))
ledger=json.loads((root/'generation-ledger.json').read_text(encoding='utf-8'))
checks=[]
def check(ok,label):
    checks.append({'check':label,'passed':bool(ok)})
    if not ok: raise AssertionError(label)
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def git(*args):return subprocess.run(['git',*args],capture_output=True,text=True,check=True).stdout.strip()
check(git('branch','--show-current')=='codex/skm-05','correct branch')
check(not git('diff','--name-only','HEAD','--','smash-nine-prototype/'),'no tracked game changes')
check(not git('diff','--name-only','HEAD'),'no existing tracked files changed')
def writable(p):
    return p.startswith(('reports/codex-skm-05/','art/raw/skm-05/')) or bool(re.fullmatch(r'art/bakeoff/nova/nova_(male|female)-(gravity_beam|orb_throw|field_fly)-v[^/]+\.[^/]+',p))
baseline=set((root/'baseline-status.txt').read_text(encoding='utf-8-sig').splitlines())
current=set(git('status','--short','--untracked-files=all').splitlines())
outside=[line for line in baseline.symmetric_difference(current) if not writable(line[3:])]
check(not outside,'no status changes outside writable paths relative to baseline: '+str(outside))
check(len(rows)<=6,'at most six row decisions')
if '--final' in sys.argv:check(len(rows)==6,'all six rows reached')
for r in rows:
    stem,row=r['stem'],r['row'];key=stem+'-'+row;base=root/stem/row/f'attempt-{r["attempt"]}'
    m=json.loads((base/'metrics.json').read_text());s=m['summary']
    cp=json.loads((root/(key+'-checks.json')).read_text(encoding='utf-8'))
    check(cp['selection']==r,key+' current curated selection')
    check(cp['metrics']==m,key+' current curated metrics')
    check(r['fps']=={'gravity_beam':18,'orb_throw':16,'field_fly':10}[row] and r['loop']==(row=='field_fly'),key+' timing')
    check(s['resample']=='lanczos' and s['sharpen_percent']==60 and s['despill']=='auto' and s['palette']=='none',key+' settings')
    check(s['frame_count']==6 and s['common_scale']==r['factor'] and 0<r['factor']<=1,key+' one row factor, no upscale')
    check(m['normalization']['cell']==192 and m['normalization']['feet_y']==152 and s['common_offset_x']==0 and s['ground_all'],key+' placement')
    check(all(b['color']==[0,255,0] for b in m['input']['backgrounds']),key+' green key')
    ex=cp['extraction'];check(len(ex['boxes'])==6 and 'no fixed-width' in ex['method'],key+' blob extraction')
    check(all(0<b[0]<b[2]<ex['size'][0] and 0<b[1]<b[3]<ex['size'][1] for b in ex['boxes']),key+' source borders')
    check(r['reviewed_frames']==[1,2,3,4,5,6],key+' all six frames visually reviewed')
    im=Image.open(base/(key+'.png')).convert('RGBA');check(im.size==(1152,192),key+' sheet dimensions')
    for i in range(6):
        frame=im.crop((i*192,0,(i+1)*192,192));b=frame.getbbox();fm=m['frames'][i]
        check(list(b)==fm['bbox'],key+f' F{i+1} bbox')
        check(set(np.unique(np.array(frame)[...,3]))<={0,255},key+f' F{i+1} binary alpha')
        check(min(b[0],b[1],192-b[2],192-b[3])>=4,key+f' F{i+1} clear border and margin')
        check(b[3]-1==152,key+f' F{i+1} feet y152')
        check(n.spill_pixel_count(frame)==0,key+f' F{i+1} spill zero')
        check(n.interior_detail(frame)==fm['interior_detail'] and fm['interior_detail']>=79,key+f' F{i+1} detail')
    check(cp['sheet_sha256']==sha(base/(key+'.png')),key+' selected hash')
    face=cp['face'];measured=[x for x in face['frames'] if x['frame'] in r['face_frames']]
    check(all(x['eye_ratio'] is None for x in measured),key+' occluded eye not claimed as passed')
    target=Path('art/bakeoff/nova')/(key+'-v1.png')
    if r['accepted']:
        check(r['face_verified'] and r['costume_ok'] and r['pose_ok'],key+' visual gates')
        check(face['sheet_sha256']==sha(base/(key+'.png')) and all(v.get('review') for v in measured),key+' face review matches final image')
        check(measured and all(.95<=x['face_width_ratio']<=1.06 for x in measured),key+' face range')
        check(sha(target)==sha(base/(key+'.png')),key+' published bytes')
        meta=json.loads(target.with_suffix('.json').read_text(encoding='utf-8'))
        check(all(meta[k]==r[k] for k in ['note','for','fps','loop','factor']) and meta['frames']==6 and meta['cell']==192 and meta['feet']==[96,152],key+' metadata')
        check(meta['for']=={'orb_throw':'K 중력 구체 던지기','field_fly':'L 중력 필드 안 비행','gravity_beam':'U 중력 광선 조준·끌어당기기'}[row],key+' exact skill label')
    else:
        check(not target.exists() and not target.with_suffix('.json').exists(),key+' held not published')
        check(not all(r[k] for k in ['face_verified','costume_ok','pose_ok']),key+' held reason')
    check(Image.open(root/(key+'.png')).size==(2048,3072 if row=='field_fly' else 2304),key+' exact 4x board')
    if row=='field_fly':check((base/'handoff4x.png').exists(),key+' F6 to F1 board')
    for k in ['for','note','attempt_notes','human_review']:check(bool(re.search('[가-힣]',r[k])) and '??' not in r[k],key+' Korean '+k)
for g in ledger:
    key=g['stem']+'-'+g['row']
    check(sha(g['raw'])==g['sha256']==sha(g['original']),key+' preserved raw '+str(g['attempt']))
    check(1<=g['attempt']<=2 and len([v for v in ledger if v['stem']==g['stem'] and v['row']==g['row']])<=2,key+' generation cap')
    expected=[Path(f'art/bakeoff/nova/{g["stem"]}-idle-v2.png').resolve(),Path(f'smash-nine-prototype/assets/art/nova/{g["stem"]}_moves_sheet.png').resolve()]
    check([Path(v).resolve() for v in g['references']]==expected,key+' matching reference pair')
    check(bool(g['prompt']),key+' prompt retained')
files=json.loads((root/'files-to-stage.json').read_text());script=(root/'commit.ps1').read_text(encoding='utf-8')
check(sorted(files)==sorted(re.findall(r"^    '([^']+)'$",script,re.M)),'manifest matches script')
for p in files:
    allowed=p=='design/tasks/CODEX-SKM-05.md' or p.startswith('reports/codex-skm-05/') or re.fullmatch(r'art/bakeoff/nova/nova_(male|female)-(gravity_beam|orb_throw|field_fly)-v1\.(png|json)',p)
    check(bool(allowed),'stage scope '+p)
    check(not any(x in p for x in ['art/raw/','attempt-','sweeps/','__pycache__','run.log','baseline-status']),'no intermediate '+p)
    check(Path(p).is_file(),'exists '+p)
    if Path(p).suffix in ['.py','.json','.md','.ps1','.txt']:
        value=Path(p).read_text(encoding='utf-8-sig');check(not any(line.rstrip()!=line for line in value.splitlines()),'no trailing whitespace '+p)
check('git add -f' not in script,'no force add')
msg=re.search(r"\$message = @'\n(.*?)\n'@",script,re.S).group(1)
check(msg.endswith('Co-Authored-By: Codex <noreply@openai.com>'),'Co-Authored-By trailer')
path=str((root/'commit.ps1').resolve()).replace("'","''")
cmd="$tokens=$null; $errors=$null; [System.Management.Automation.Language.Parser]::ParseFile('"+path+"',[ref]$tokens,[ref]$errors) > $null; if($errors.Count){ $errors | ForEach-Object { $_.Message }; exit 1 }"
p=subprocess.run(['powershell','-NoProfile','-NonInteractive','-Command',cmd],capture_output=True,text=True)
check(p.returncode==0,'PowerShell parsed; commit not executed')
sizes={v:sum(p.stat().st_size for p in Path(v).rglob('*') if p.is_file()) for v in ['reports/codex-skm-05','art/raw/skm-05']}
size_root='\\\\?\\'+str(Path.cwd()) if os.name=='nt' else str(Path.cwd())
workspace_bytes=sum(os.stat(os.path.join(directory,name)).st_size for directory,dirs,names in os.walk(size_root) for name in names)
audit={'passed':True,'checks':checks,'delivered':[r['stem']+'-'+r['row'] for r in rows if r['accepted']],'held':[r['stem']+'-'+r['row'] for r in rows if not r['accepted']],'generation_count':len(ledger),'folder_bytes':sizes,'workspace_bytes':workspace_bytes,'commit_script_executed':False,'godot_run':False}
(root/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'passed':True,'check_count':len(checks),'folder_bytes':sizes,'workspace_bytes':workspace_bytes},ensure_ascii=False))
