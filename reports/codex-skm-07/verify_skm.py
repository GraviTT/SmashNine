"""Verify delivered images and scope; never executes commit.ps1 or Godot."""
import sys, os, re, json, hashlib, subprocess, ast
from pathlib import Path
from datetime import datetime, timezone
sys.dont_write_bytecode=True
from PIL import Image
import numpy as np
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
from finalize import ROOT,SPECS,face_box,boots
from prepare_handoff import FILES

checks=[]
def check(ok,label):
    checks.append({'check':label,'passed':bool(ok)})
    if not ok: raise AssertionError(label)
def git(*args): return subprocess.check_output(['git',*args]).decode('utf-8')
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def allowed(p):
    return p.startswith(('reports/codex-skm-07/','art/raw/skm-07/')) or bool(re.fullmatch(r'art/bakeoff/xion/b/xion-shot_air_down-v[23]\.[^/]+',p))

check(git('branch','--show-current').strip()=='codex/skm-07','branch')
check(not git('diff','--name-only','HEAD','--','smash-nine-prototype/').strip(),'product tracked files unchanged')
check(all(allowed(p) for p in git('diff','--name-only','HEAD').splitlines()),'tracked changes in scope')
baseline=set((ROOT/'baseline-status.txt').read_text(encoding='utf-8-sig').splitlines())
current=set(git('status','--porcelain','-uall').splitlines())
outside=[p for p in baseline.symmetric_difference(current) if not allowed(p[3:])]
check(not outside,'status changes inside card paths: '+str(outside))

for spec in SPECS:
    v=spec['version'];base=ROOT/'xion'/'shot_air_down'/f'attempt-{spec["take"]}'
    c=json.loads((ROOT/f'xion-shot_air_down-{v}-checks.json').read_text(encoding='utf-8'))
    target=Path(c['target']);im=Image.open(target).convert('RGBA');original=Image.open(c['source']).convert('RGBA')
    meta=json.loads(target.with_suffix('.json').read_text(encoding='utf-8'))
    check(im.size==(1152,192),v+' dimensions')
    check(c['sheet_sha256']==sha(target) and c['source_sha256']==sha(c['source']),v+' measured pixels hash')
    check((meta['frames'],meta['fps'],meta['cell'],meta['feet'],meta['loop'],meta['factor'])==(6,30,192,[96,152],False,spec['factor']),v+' metadata')
    check(meta['for']=='공중 J 아래 사격' and '??' not in meta['note'],v+' Korean metadata')
    s=c['original_metrics']['summary']
    check((s['common_scale'],s['resample'],s['sharpen_percent'],s['despill'],s['palette'],s['ground_all'])==(spec['factor'],'lanczos',60,'auto','none',False),v+' pipeline, single factor, no grounding')
    ex=json.loads((base/'extraction.json').read_text(encoding='utf-8'))
    check(len(ex['boxes'])==6 and 'no fixed-width' in ex['method'],v+' blob extraction')
    check(all(0<b[0]<b[2]<ex['size'][0] and 0<b[1]<b[3]<ex['size'][1] for b in ex['boxes']),v+' raw edge clear')
    check(.96<=c['head_scale']['median']<=1.04,v+' automated head median')
    for i,m in enumerate(c['frames']):
        f=im.crop((i*192,0,(i+1)*192,192));o=original.crop((i*192,0,(i+1)*192,192));box=f.getbbox();tag=v+f' F{i+1}'
        check(list(box)==m['bbox'],tag+' bbox')
        check(set(np.unique(np.array(f)[...,3]))<={0,255},tag+' binary alpha')
        check(n.margins(box,192)['minimum']>=4,tag+' clear border and 4px margin')
        check(n.spill_pixel_count(f)==0,tag+' spill 0')
        check(n.interior_detail(f)==m['interior_detail'] and m['detail_ratio']>=.9,tag+' detail >=90%')
        check(.96<=m['face_width_ratio']<=1.04,tag+' reviewed face ratio')
        check((m['face_landmarks'][3]['x']-m['face_landmarks'][2]['x'])/10==m['face_width_ratio'],tag+' face width arithmetic')
        check(face_box(f,m['face_landmarks'])==m['face_box'],tag+' face bbox reproduced')
        check(boots(o,spec['boot_roi'][i])+spec['dy'][i]==m['boot_y']==spec['expected_boots'][i],tag+' boot reproduced')
        check(f.crop(box).tobytes()==o.crop(o.getbbox()).tobytes(),tag+' whole-frame translation only')
        check(m['shift']==[96-spec['belt_x'][i],spec['dy'][i]],tag+' recorded placement')
    check(c['rise_head']==c['frames'][1]['head_top']-c['frames'][2]['head_top'] and 3<=c['rise_head']<=5,v+' head rise')
    check(c['rise_face_box']==c['frames'][1]['face_box'][1]-c['frames'][2]['face_box'][1] and 3<=c['rise_face_box']<=5,v+' face-box rise')
    check(abs(c['frames'][3]['head_top']-c['frames'][2]['head_top'])<=2,v+' F4 head hold')
    check(all(f['eye_ratio'] is None for f in c['original_face_review']['frames']),v+' far eye not declared measured')
    check(Image.open(ROOT/f'xion-shot_air_down-{v}.png').size==(2560,2400),v+' 4x board')

ledger=json.loads((ROOT/'generation-ledger.json').read_text(encoding='utf-8'))
check(len(ledger)==3,'3 generation limit')
times=json.loads((ROOT/'time-limit.json').read_text(encoding='utf-8'));deadline=datetime.fromisoformat(times['deadline_utc'])
for item in ledger:
    check(len(item['references'])==3,'all 3 reference paths recorded')
    check(sha(item['raw'])==item['sha256']==sha(item['original']),'raw preserved')
    for key in ('before_utc','after_utc'):
        stamp=datetime.strptime(item[key],'%Y-%m-%d %H:%M:%S UTC').replace(tzinfo=timezone.utc)
        check(stamp<deadline,'generation clock before deadline')
    check(item['prompt'] in (ROOT/'prompts.txt').read_text(encoding='utf-8'),'exact prompt stored')

script=(ROOT/'commit.ps1').read_text(encoding='utf-8')
check(re.findall(r"^    '([^']+)'$",script,re.M)==FILES,'literal commit allowlist')
for path in FILES:
    p=Path(path);check(p.is_file(),'exists: '+path)
    check(path=='design/tasks/CODEX-SKM-07.md' or allowed(path),'stage scope: '+path)
    check(not any(s in path for s in ('attempt-','art/raw/','__pycache__','run.log')),'no intermediate: '+path)
    if p.suffix in ('.md','.py','.json','.ps1','.txt'):
        txt=p.read_text(encoding='utf-8-sig');check(all(line==line.rstrip() for line in txt.splitlines()),'no trailing whitespace: '+path)
        if p.suffix=='.py': ast.parse(txt,filename=path)
check('git add -f' not in script and '& git add -- $files' in script,'no force/broad staging')
command="$t=$null; $e=$null; [System.Management.Automation.Language.Parser]::ParseFile('"+str((ROOT/'commit.ps1').resolve()).replace("'","''")+"',[ref]$t,[ref]$e)>$null; if($e.Count){$e;exit 1}"
r=subprocess.run(['powershell','-NoProfile','-NonInteractive','-Command',command],capture_output=True)
check(r.returncode==0,'PowerShell parsed only')
sizes={p:sum(f.stat().st_size for f in Path(p).rglob('*') if f.is_file()) for p in ('reports/codex-skm-07','art/raw/skm-07')}
longroot='\\\\?\\'+str(Path.cwd()) if os.name=='nt' else str(Path.cwd())
workspace=sum(os.stat(os.path.join(d,f)).st_size for d,ds,fs in os.walk(longroot) for f in fs)
audit=dict(passed=True,checks=checks,delivered=['v2','v3'],held=[1],folder_bytes=sizes,workspace_bytes=workspace,commit_executed=False,game_run=False)
(ROOT/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(passed=True,checks=len(checks),folder_bytes=sizes,workspace_bytes=workspace)))
