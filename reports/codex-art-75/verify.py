"""Read-only artifact audit. Never executes commit.ps1."""
import ast,datetime,hashlib,json,re,subprocess,sys
from pathlib import Path
from PIL import Image

root=Path('reports/codex-art-75');summary=json.loads((root/'summary.json').read_text(encoding='utf-8'));selection=json.loads((root/'selection.json').read_text(encoding='utf-8'))
checks=[]
def check(ok,label):
 checks.append({'check':label,'passed':bool(ok)})
 if not ok:raise AssertionError(label)
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
branch=subprocess.run(['git','branch','--show-current'],capture_output=True,text=True,check=True).stdout.strip();check(branch=='codex/art-75','branch codex/art-75')
diff=subprocess.run(['git','diff','--name-only','--','smash-nine-prototype/','tools/'],capture_output=True,text=True,check=True).stdout.strip();check(not diff,'no tracked game/tool changes')
counts={'jump':3,'fall':2,'hurt':3,'land':2,'victory':6};speeds={'jump':10,'fall':8,'hurt':12,'land':12,'victory':8}
check(len(summary)==len(selection)==15,'15 rows')
check([(r['stem'],r['row']) for r in summary]==[(s,row) for s in ['yuki','nova_male','nova_female'] for row in counts],'card form/row order')
for r,item in zip(summary,selection):
 label=r['stem']+'/'+r['row'];check((r['stem'],r['row'])==(item['stem'],item['row']),label+' order')
 base=root/r['stem']/r['row']/f'attempt-{r["attempt"]}';m=json.loads((base/'metrics.json').read_text());s=m['summary']
 check(s['resample']=='lanczos' and s['sharpen_percent']==60 and s['despill']=='auto' and s['palette']=='none',label+' pipeline settings')
 check(s['frame_count']==r['frames'] and m['input']['backgrounds'],label+' source frames')
 check((root/f'{r["stem"]}-{r["row"]}.png').exists(),label+' 4x board')
 check(s['common_scale']==r['factor'] and s['scale_by']==f'fixed:{r["factor"]}',label+' one shared row factor')
 check(r['frames']==counts[r['row']] and r['fps']==speeds[r['row']],label+' card timing')
 check(item['reviewed_frames']==list(range(1,r['frames']+1)),label+' all selected final frames reviewed')
 check([f['frame'] for f in r['face']['excluded_frames']]==([1,2] if r['row']=='hurt' else []),label+' tilted-face exclusions explicit')
 if r['stem'].startswith('nova'):check(r['face']['reference_eye_distance'] is None and r['face']['eye_limitation'] and all(f['eye_ratio'] is None for f in r['face']['frames']),label+' hidden far eye not measured')
 for i in range(1,r['frames']+1,1 if r['cell']==192 else 2):check((root/'qa4x'/f'{r["stem"]}-{r["row"]}-{i}.png').exists(),label+f' exact 4x page F{i}')
 if not r['accepted']:
  folder='yuki' if r['stem']=='yuki' else 'nova';v=2 if r['row']=='fall' else 1
  check(not Path(f'art/bakeoff/{folder}/{r["stem"]}-{r["row"]}-v{v}.png').exists(),label+' held row not published')
  continue
 p=Path(r['candidate']);meta=json.loads(p.with_suffix('.json').read_text(encoding='utf-8'));im=Image.open(p).convert('RGBA');cell=192 if r['row']=='victory' else 128;feet=152 if cell==192 else 120
 check(im.size==(cell*6,cell),label+' six-column dimensions')
 check(meta['frames']==r['frames'] and meta['fps']==r['fps'] and meta['factor']==r['factor'] and meta['cell']==cell and meta['feet']==feet and meta['note'],label+' metadata timing/scale/cell')
 check(sha(p)==sha(base/f'{r["stem"]}-{r["row"]}.png')==r['sheet_sha256'],label+' unmodified normaliser output')
 check(set(im.getchannel('A').tobytes())<={0,255},label+' binary alpha')
 for i in range(6):
  f=im.crop((i*cell,0,(i+1)*cell,cell));box=f.getbbox()
  if i>=r['frames']:check(box is None,label+f' empty padding F{i+1}');continue
  check(box is not None,label+f' visible F{i+1}');check(min(box[0],box[1],cell-box[2],cell-box[3])>=4,label+f' margin F{i+1}')
  check((box[3]-1==feet) if r['row'] in ['hurt','land','victory'] else (box[3]-1<feet),label+f' feet/air F{i+1}')
 check(not any(s['remaining_spill_pixels']) and min(f['interior_detail'] for f in m['frames'])>=79,label+' spill/detail')
 check(item['face_verified'] and item['pose_ok'] and item['costume_ok'] and item['reviewed_frames']==list(range(1,r['frames']+1)),label+' manual review recorded')
 values=[v for f in r['face']['frames'] for v in [f['eye_ratio'],f['face_width_ratio']] if v is not None]
 check(values and all(.95<=v<=1.06 for v in values),label+' valid upright face range')
 if any(not(.96<=v<=1.04) for v in values):check(all(str(v) in meta['note'] for v in values),label+' outside-target ratios disclosed')
 if r['row']=='hurt':check('F1' in meta['note'] and 'F3' in meta['note'] and '제외' in meta['note'],label+' tilt limitation in candidate')
 if r['stem'].startswith('nova'):check('측정 불가' in meta['note'],label+' eye limitation in candidate')
 if r['stem']=='nova_male' and r['row']=='victory':
  f=next(f for f in r['face']['frames'] if f['frame']==4);check(f['manual_correction'] and f['proposed_face_width_ratio']==.931 and f['face_width_ratio']==.966,label+' contour correction traceable')
ledger=json.loads((root/'generation-ledger.json').read_text(encoding='utf-8'));groups={}
for e in ledger:
 groups[e['stem']+'/'+e['row']]=groups.get(e['stem']+'/'+e['row'],0)+1
 check(Path(e['raw']).is_file() and sha(e['raw'])==e['raw_sha256'],e['key']+' raw preserved')
 check(sha(e['prompt'])==e['prompt_sha256'],e['key']+' prompt preserved')
check(len(ledger)==30 and all(n<=3 for n in groups.values()),'30 generations; at most three per row')
for stem in ['yuki','nova_male','nova_female']:check(Path(f'art/raw/motions-75/{stem}-anchor-4x.png').exists(),stem+' reference preserved')
comps=json.loads((root/'composition-ledger.json').read_text(encoding='utf-8'));check(len(comps)==11,'eleven single-frame replacement assemblies')
for c in comps:
 stem,row,base,nxt,frame=[c[k] for k in ['stem','row','source_attempt','new_attempt','replaced_frame']];raw=Path('art/raw/motions-75');a=Image.open(raw/f'{stem}-{row}-{base}.png').convert('RGB');b=Image.open(raw/f'{stem}-{row}-{nxt}.png').convert('RGB');cols=3 if row=='victory' else counts[row];w,h=a.width//cols,a.height//(2 if row=='victory' else 1)
 for i in range(counts[row]):
  if i==frame-1:continue
  box=(i%cols*w,i//cols*h,(i%cols+1)*w,(i//cols+1)*h);check(a.crop(box).tobytes()==b.crop(box).tobytes(),f'{stem}/{row} A{nxt} unchanged F{i+1}')
fails=json.loads((root/'source-failures.json').read_text(encoding='utf-8'));check(len(fails)==2 and all(f['expected_failure'] and 'source cell subject touches its bottom border' in f['message'] for f in fails),'two failed source grids recorded')
for p in root.glob('*.py'):ast.parse(p.read_text(encoding='utf-8'));check(True,'Python syntax '+p.name)
check(not list(root.rglob('__pycache__')),'no report bytecode cache')
files=json.loads((root/'files-to-stage.json').read_text(encoding='utf-8'))
for f in files:
 check(bool(re.match(r'^(art/bakeoff/(yuki|nova)/|reports/codex-art-75/)',f)) and not f.startswith('art/raw/') and '__pycache__' not in f and not f.endswith('run.log'),'stage scope '+f)
 if f!=str(root/'audit.json').replace('\\','/'):check(Path(f).is_file(),'stage file exists '+f)
script=(root/'commit.ps1').read_text(encoding='utf-8');check(not re.search(r'\badd\s+(?:-f|--force)\b',script),'commit script has no force-add')
check(re.findall(r"^    '([^']+)'$",script,re.M)==files,'commit exact manifest paths')
check('git -C $repo add -- $files' in script and 'Unrelated staged file' in script,'explicit stage list; unrelated index guarded')
message=re.search(r"\$message = @'\n(.*?)\n'@",script,re.S).group(1)
check(message.rstrip().endswith('Co-Authored-By: Codex <noreply@openai.com>'),'commit message co-author trailer')
pspath=str((root/'commit.ps1').resolve()).replace("'","''")
code="$parseTokens=$null; $parseIssues=$null; [System.Management.Automation.Language.Parser]::ParseFile('"+pspath+"',[ref]$parseTokens,[ref]$parseIssues) > $null; if($parseIssues.Count){ $parseIssues | ForEach-Object { $_.Message }; exit 1 }"
ps=subprocess.run(['powershell','-NoProfile','-NonInteractive','-Command',code],capture_output=True,text=True)
check(ps.returncode==0,'commit.ps1 syntax only; not executed')
now=datetime.datetime.now(datetime.timezone.utc);work=json.loads((root/'work-log.json').read_text(encoding='utf-8'));check(now<datetime.datetime.fromisoformat(work['hard_stop_utc']),'within 150-minute hard stop');work['finished_utc']=now.isoformat();(root/'work-log.json').write_text(json.dumps(work,indent=2),encoding='utf-8')
audit={'passed':True,'published_rows':sum(r['accepted'] for r in summary),'published_frames':sum(r['frames'] for r in summary if r['accepted']),'reviewed_rows':len(summary),'reviewed_final_frames':48,'generations':len(ledger),'checks':checks,'game_tool_folder_diff':diff,'commit_script_executed':False,'godot_run':False,'verified_utc':now.isoformat(),'face_scope':'Upright visible frames only; tilted hurt F1/F2 visual-only; Nova anchor eye distance unavailable.'}
(root/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps({k:v for k,v in audit.items() if k!='checks'},ensure_ascii=False));print(len(checks),'checks passed')
