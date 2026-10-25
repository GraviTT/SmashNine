"""Read-only asset/scope verification, writes only this report's verification.json."""
from pathlib import Path
from PIL import Image
import datetime, hashlib, json, re, subprocess

ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/'reports/codex-sart-04'
ART=ROOT/'art/bakeoff/story'
expected={
 'map_path_tile':([1,2],(32,12),1),
 'map_marker_next':([1,2],(288,48),6),
 'map_seal_clear':([1,2,3],(40,40),1),
 'map_seal_locked':([1,2,3],(40,40),1),
 'shadow_dissolve':([1,2],(1152,192),6),
}
checks={}; files=[]
for base,(versions,size,frames) in expected.items():
 for v in versions:
  stem=f'{base}-v{v}'
  png=ART/(stem+'.png'); meta=ART/(stem+'.json')
  data=json.loads(meta.read_text(encoding='utf-8')); im=Image.open(png)
  checks[stem+' dimensions']=im.size==size and data['canvas_size']==list(size)
  checks[stem+' metadata']=data['frames']==frames and bool(data['note_ko']) and bool(data['method'])
  checks[stem+' hash']=data['sha256']==hashlib.sha256(png.read_bytes()).hexdigest()
  if base=='map_marker_next':checks[stem+' timing']=data['fps']==8 and data['loop'] is True
  if base=='shadow_dissolve':checks[stem+' timing/pivot']=data['fps']==12 and data['loop'] is False and data['pivot']==[96,152]
  files.extend([str(png.relative_to(ROOT)).replace('\\','/'),str(meta.relative_to(ROOT)).replace('\\','/')])

for name,total,frames,loop in [('map_marker_next.gif',750,6,0),('shadow_dissolve.gif',500,6,None)]:
 im=Image.open(REPORT/name); initial=dict(im.info);durations=[]
 for i in range(im.n_frames):im.seek(i);durations.append(im.info['duration'])
 checks[name+' timing']=sum(durations)==total and im.n_frames==frames and initial.get('loop')==loop

measurements=json.loads((REPORT/'measurements.json').read_text(encoding='utf-8'))
checks['automatic 74/74']=sum(len(r['checks']) for r in measurements)==74 and all(r['automatic_pass'] for r in measurements)
checks['all review evidence']=all((REPORT/n).exists() for n in [
 'contact.png','recommended.png','mock-map-recommended.png','README.md','spec-checklist.md',
 'seals-v3-4x.png','commit.ps1','commit-message.txt','metadata-errata.json'])
checks['all twelve shadow frame reviews']=all((REPORT/f'shadow-v{v}-f{i}-4x.png').exists() for v in [1,2] for i in range(1,7))
checks['coauthor trailer']=(REPORT/'commit-message.txt').read_text(encoding='utf-8').rstrip().endswith('Co-Authored-By: Codex <noreply@openai.com>')

def git(*args):
 p=subprocess.run(['git','-C',str(ROOT),*args],capture_output=True,text=True,encoding='utf-8')
 if p.returncode:raise RuntimeError(p.stderr)
 return p.stdout

checks['branch']=git('branch','--show-current').strip()=='codex/sart-04'
tracked=git('diff','--name-only','HEAD').splitlines()
untracked=git('ls-files','--others','--exclude-standard').splitlines()
changed=sorted(set(tracked+untracked))
allowed=re.compile(r'^(art/bakeoff/story/(map_[^/]+|shadow_dissolve[^/]+)\.(png|json)|reports/codex-sart-04/[^/]+\.(md|json|py|png|gif|ps1|txt))$')
outside=[s for s in changed if not allowed.fullmatch(s)]
checks['only permitted paths']=not outside
checks['no product diff']=not git('diff','HEAD','--','smash-nine-prototype/').strip()
checks['no staged modifications']=not git('diff','--cached','--name-only').strip()
raws=['art/raw/story/shadow_dissolve-v1_raw.png','art/raw/story/shadow_dissolve-v2_raw.png']
checks['raws ignored']=set(git('check-ignore',*raws).splitlines())==set(raws)
result={'verified_at':datetime.datetime.now().astimezone().isoformat(),
        'checks':checks,'passed':sum(checks.values()),'total':len(checks),
        'outside_scope':outside,'candidate_files':files,
        'git_changed_files':changed,'committed':False,'godot_run':False,
        'note_ko':'자동 파일/인계 검사이며 육안 판정은 spec-checklist.md를 따른다.'}
(REPORT/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f"Delivery verification: {sum(checks.values())}/{len(checks)} PASS")
for name,ok in checks.items():
 if not ok: print('FAIL',name)
if outside:print('OUTSIDE',outside)
raise SystemExit(0 if all(checks.values()) else 1)
