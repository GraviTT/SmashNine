"""Verify SKM-06 artifacts and scope; no generation, game run or commit."""
import os, sys, json, re, hashlib, subprocess
from pathlib import Path
import numpy as np
from PIL import Image
from config import ROOT as root, ROWS, REFS
sys.path.insert(0, str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
rows=json.loads((root/'selection.json').read_text(encoding='utf-8'))
ledger=json.loads((root/'generation-ledger.json').read_text(encoding='utf-8'))
checks=[]
def check(ok,label):
    checks.append({'check':label,'passed':bool(ok)})
    if not ok: raise AssertionError(label)
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def git(*args): return subprocess.run(['git',*args],capture_output=True,text=True,check=True).stdout
def writable(p):
    return p.startswith(('reports/codex-skm-06/','art/raw/skm-06/')) or bool(re.fullmatch(r'art/bakeoff/xion/b/xion-('+'|'.join(ROWS)+r')-v[^/]+\.[^/]+',p))
check(git('branch','--show-current').strip()=='codex/skm-06c','correct branch')
check(all(writable(p) for p in git('diff','--name-only','HEAD').splitlines()),'tracked changes stay in scope')
baseline=set((root/'baseline-status.txt').read_text(encoding='utf-8-sig').splitlines())
current=set(git('status','--porcelain','-uall').splitlines())
outside=[s for s in baseline.symmetric_difference(current) if not writable(s[3:])]
check(not outside,'no changes outside writable paths: '+str(outside))
check([r['row'] for r in rows]==list(ROWS)[:len(rows)],'rows decided in card order')
for r in rows:
    row=r['row'];key='xion-'+row;base=root/'xion'/row/f"attempt-{r['attempt']}"
    c=json.loads((root/(key+'-checks.json')).read_text(encoding='utf-8'))
    m=c['metrics'];s=m['summary'];face=c['face'];source=base/(key+'.png')
    check(c['selection']==r,key+' selection current')
    check(c['sheet_sha256']==sha(source),key+' source hash')
    check(r['reviewed_frames']==[1,2,3,4,5,6],key+' all frames reviewed')
    fps,loop,label=ROWS[row]
    check((r['fps'],r['loop'],r['for'])==(fps,loop,label),key+' card timing/label')
    check(s['resample']=='lanczos' and s['sharpen_percent']==60 and s['despill']=='auto' and s['palette']=='none',key+' pipeline settings')
    check(s['common_scale']==r['factor'] and 0<r['factor']<=1,key+' one factor')
    check(m['normalization']['cell']==192 and m['normalization']['feet_y']==152 and s['common_offset_x']==0,key+' cell/anchor')
    check(all(b['color']==[0,255,0] for b in m['input']['backgrounds']),key+' chroma key')
    ex=c['extraction']
    check(len(ex['boxes'])==6 and 'no fixed-width' in ex['method'],key+' blob extraction')
    check(all(0<b[0]<b[2]<ex['size'][0] and 0<b[1]<b[3]<ex['size'][1] for b in ex['boxes']),key+' source edge clear')
    im=Image.open(source).convert('RGBA');check(im.size==(1152,192),key+' dimensions')
    for i in range(6):
        f=im.crop((i*192,0,(i+1)*192,192));b=f.getbbox();fm=m['frames'][i]
        check(list(b)==fm['bbox'],key+f' F{i+1} bbox')
        check(set(np.unique(np.array(f)[...,3]))<={0,255},key+f' F{i+1} binary alpha')
        check(min(b[0],b[1],192-b[2],192-b[3])>=4,key+f' F{i+1} margin')
        check((128<=b[3]-1<=152 if row=='recoil_jump' else 90<=b[3]-1<=152 if row=='dive' else b[3]-1==152),key+f' F{i+1} feet or permitted lift')
        check(n.spill_pixel_count(f)==0,key+f' F{i+1} spill zero')
        check(n.interior_detail(f)==fm['interior_detail'] and fm['interior_detail_ratio_to_reference_mean']>=.9,key+f' F{i+1} detail >=90 percent')
    target=Path('art/bakeoff/xion/b')/(key+'-v1.png')
    check(all(f['eye_ratio'] is None for f in face['frames']),key+' unavailable eye spacing honestly recorded')
    if r['accepted']:
        check(all(r[k] for k in ['face_verified','costume_ok','pose_ok']),key+' visual gates')
        check(all(.95<=f['face_width_ratio']<=1.06 for f in face['frames'] if f['frame'] in r['face_frames']),key+' face range')
        check(face['sheet_sha256']==sha(source),key+' measured face tied to selected image')
        check(sha(target)==sha(source),key+' delivered bytes')
        meta=json.loads(target.with_suffix('.json').read_text(encoding='utf-8'))
        check(all(meta[k]==r[k] for k in ['note','for','fps','loop','factor']) and meta['frames']==6 and meta['cell']==192 and meta['feet']==[96,152],key+' metadata')
    else:
        check(not target.exists() and not target.with_suffix('.json').exists(),key+' held not published')
    check(Image.open(root/(key+'.png')).size==(2048,3072 if loop else 2304),key+' 4x board')
    for k in ['note','for','attempt_notes','human_review']:
        check(bool(re.search('[\uac00-\ud7a3]',r[k])) and '??' not in r[k],key+' Korean '+k)
for g in ledger:
    key=g['row']+' attempt '+str(g['attempt'])
    check(sha(g['raw'])==g['sha256']==sha(g['original']),key+' raw preserved')
    check(len(g['references'])==2 and g['references'][0].replace('\\','/')==REFS[0].replace('\\','/') and g['references'][1].replace('\\','/').endswith(('xion_illustration-b2.png','xion-shot-v1.png')),key+' actual reference paths retained')
    check(1<=g['attempt']<=(4 if g['row']=='shot_alt' else 2) and len([v for v in ledger if v['row']==g['row']])<=(4 if g['row']=='shot_alt' else 2),key+' generation cap')
    check(bool(g['prompt']),key+' exact prompt retained')
files=json.loads((root/'files-to-stage.json').read_text())
script=(root/'commit.ps1').read_text(encoding='utf-8')
legacy_candidates=['art/bakeoff/xion/b/xion-'+r+'-v1'+ext for r in ['shot','shot_alt'] for ext in ['.png','.json']]
check(not any(p in files for p in legacy_candidates),'previously merged shot rows excluded from stage list')
check(not git('diff','--name-only','HEAD','--',*legacy_candidates).strip(),'previously merged shot rows unchanged')
check(not git('diff','--name-only','HEAD','--','smash-nine-prototype/').strip(),'product source unchanged')
check(Image.open(root/'continuation-preview.png').size==(1152,624),'static delivered preview dimensions')
check(sorted(files)==sorted(re.findall(r"^    '([^']+)'$",script,re.M)),'manifest matches commit script')
for p in files:
    check(p=='design/tasks/CODEX-SKM-06.md' or writable(p),'stage scope '+p)
    check(not any(s in p for s in ['art/raw/','attempt-','__pycache__','run.log','baseline-status']),'no intermediates '+p)
    check(Path(p).is_file(),'exists '+p)
    if Path(p).suffix in ['.py','.json','.md','.ps1','.txt']:
        text=Path(p).read_text(encoding='utf-8-sig')
        check(not any(line.rstrip()!=line for line in text.splitlines()),'no trailing whitespace '+p)
        if Path(p).name=='README.md':check('??' not in text,'README UTF-8 Korean intact')
check('git add -f' not in script,'no force add')
check('Co-Authored-By: Codex <noreply@openai.com>' in script,'coauthor trailer')
p=str((root/'commit.ps1').resolve()).replace("'","''")
cmd="$tokens=$null; $errors=$null; [System.Management.Automation.Language.Parser]::ParseFile('"+p+"',[ref]$tokens,[ref]$errors)>$null; if($errors.Count){$errors;exit 1}"
result=subprocess.run(['powershell','-NoProfile','-NonInteractive','-Command',cmd],capture_output=True,text=True)
check(result.returncode==0,'commit script parsed only, not executed')
sizes={v:sum(p.stat().st_size for p in Path(v).rglob('*') if p.is_file()) for v in ['reports/codex-skm-06','art/raw/skm-06']}
size_root='\\\\?\\'+str(Path.cwd()) if os.name=='nt' else str(Path.cwd())
total=sum(os.stat(os.path.join(d,f)).st_size for d,ds,fs in os.walk(size_root) for f in fs)
audit=dict(passed=True,checks=checks,delivered=[r['row'] for r in rows if r['accepted']],held=[r['row'] for r in rows if not r['accepted']],not_reached=list(ROWS)[len(rows):],generation_count=len(ledger),folder_bytes=sizes,workspace_bytes=total,commit_script_executed=False,godot_run=False)
(root/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(passed=True,checks=len(checks),folder_bytes=sizes,workspace_bytes=total)))
