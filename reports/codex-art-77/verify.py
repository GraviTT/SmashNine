"""Read-only artifact audit. Never executes commit.ps1."""
import hashlib,json,re,subprocess,sys
from pathlib import Path
from PIL import Image

root=Path('reports/codex-art-77');summary=json.loads((root/'summary.json').read_text(encoding='utf-8'));selection=json.loads((root/'selection.json').read_text(encoding='utf-8'))
checks=[]
def check(ok,label):
 checks.append({'check':label,'passed':bool(ok)})
 if not ok:raise AssertionError(label)
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
branch=subprocess.run(['git','branch','--show-current'],capture_output=True,text=True,check=True).stdout.strip();check(branch=='codex/art-77','branch codex/art-77')
diff=subprocess.run(['git','diff','--name-only','--','smash-nine-prototype/'],capture_output=True,text=True,check=True).stdout.strip();check(not diff,'no tracked game-folder changes')
check(len(summary)==len(selection),'summary and selection lengths match')
all_tracked_diff=subprocess.run(['git','diff','--name-only','HEAD'],capture_output=True,text=True,check=True).stdout.strip();check(not all_tracked_diff,'no changes to any pre-existing tracked files')
for r,item in zip(summary,selection):
 label=r['stem']+'/'+r['row'];check((r['stem'],r['row'])==(item['stem'],item['row']),label+' order')
 base=root/'best'/r['stem']/r['row'];m=json.loads((base/'metrics.json').read_text());s=m['summary']
 check(s['resample']=='lanczos' and s['sharpen_percent']==60 and s['despill']=='auto' and s['palette']=='none',label+' pipeline settings')
 check(s['frame_count']==r['frames'] and m['input']['backgrounds'],label+' source frames')
 check((root/f'{r["stem"]}-{r["row"]}.png').exists(),label+' 4x board')
 if not r['accepted']:
  check(item['reviewed_frames']==list(range(1,r['frames']+1)) and item['pose_ok'] and item['costume_ok'],label+' held row visually reviewed')
  check(any(f.get('face_width_ratio') is not None and not .95<=f['face_width_ratio']<=1.06 for f in r['face']['frames']),label+' held row has recorded face-range failure')
  check(not Path(f'art/bakeoff/rio/{r["stem"]}-{r["row"]}-v1.png').exists(),label+' held row absent from candidate folder')
  check(s['all_have_4px_margin'] and not any(s['remaining_spill_pixels']) and min(s['interior_detail_range'])>=79,label+' held row passes geometry/spill/detail')
  continue
 p=Path(r['candidate']);meta=json.loads(p.with_suffix('.json').read_text(encoding='utf-8'));im=Image.open(p).convert('RGBA');cell=192 if r['row']=='victory' else 128;feet=152 if cell==192 else 120
 tracked=subprocess.run(['git','ls-files','--',p.as_posix()],capture_output=True,text=True,check=True).stdout.strip();check(not tracked,label+' new candidate; no tracked asset overwritten')
 check(im.size==(cell*6,cell),label+' six-column dimensions')
 check(meta['frames']==r['frames'] and meta['fps']==r['fps'],label+' metadata timing')
 check(sha(p)==sha(base/f'{r["stem"]}-{r["row"]}.png')==r['sheet_sha256'],label+' unmodified normaliser output')
 check(set(im.getchannel('A').getdata())<={0,255},label+' binary alpha')
 for i in range(6):
  f=im.crop((i*cell,0,(i+1)*cell,cell));box=f.getbbox()
  if i>=r['frames']:check(box is None,label+f' empty padding F{i+1}');continue
  check(box is not None,label+f' visible F{i+1}');check(min(box[0],box[1],cell-box[2],cell-box[3])>=4,label+f' margin F{i+1}')
  check((box[3]-1==feet) if r['row'] in ['hurt','land','victory'] else (box[3]-1<feet),label+f' feet/air F{i+1}')
 check(not any(s['remaining_spill_pixels']) and min(f['interior_detail'] for f in m['frames'])>=79,label+' spill/detail')
 check(item['face_verified'] and item['pose_ok'] and item['costume_ok'] and item['reviewed_frames']==list(range(1,r['frames']+1)),label+' manual review recorded')
 measured=[f for f in r['face']['frames'] if f.get('face_width_ratio') is not None]
 check([f['frame'] for f in r['face']['frames'] if f.get('face_width_ratio') is None]==item['unreliable_frames'],label+' excluded face frames explicitly recorded')
 check(bool(measured),label+' measured face frames available')
 check(all(.95<=f['face_width_ratio']<=1.06 for f in measured),label+' measured face width range')
 check(all(f.get('eye_ratio') is None for f in r['face']['frames']) and '눈 간 거리' in meta['note'],label+' hidden far eye disclosed; no invented eye spacing')
 for f in measured:
  left,right,y=f['points'];check(abs((right-left)/r['face']['reference_face_width']-f['face_width_ratio'])<.0002,label+f" face width coordinate ratio F{f['frame']}")
 if any(f['face_width_ratio']<.96 or f['face_width_ratio']>1.04 for f in measured):check('0.96' in meta['note'],label+' outside-target ratio disclosed')
 check(meta['factor']==r['factor'] and meta['cell']==cell and meta['feet']==feet,label+' factor/cell/feet metadata')
ledger=json.loads((root/'generation-ledger.json').read_text(encoding='utf-8'));groups={}
prompts=(root/'prompts.txt').read_text(encoding='utf-8')
for e in ledger:
 groups[e['stem']+'/'+e['row']]=groups.get(e['stem']+'/'+e['row'],0)+1
 check(Path(e['raw']).is_file(),e['key']+' raw preserved')
 original_path=Path(re.search(r' as (.*?) by default',e['output_hint'],re.S).group(1))
 check(sha(e['raw'])==sha(original_path),e['key']+' raw matches original built-in image output')
 check(e['prompt'] in prompts,e['key']+' exact prompt preserved')
 if e.get('assembled'):check(Path(e['assembled']).is_file(),e['key']+' assembled retry source preserved')
check(all(n<=3 for n in groups.values()),'at most three generations per row')
for r in summary:
 check(any(e['stem']==r['stem'] and e['row']==r['row'] and e['attempt']==r['attempt'] for e in ledger),r['stem']+'/'+r['row']+' selected generation recorded')
check(not list(root.rglob('__pycache__')) and not list(Path('art/raw/motions-77').rglob('__pycache__')),'no Python cache directories generated')
original=Image.open('art/raw/motions-77/rio_female-hurt-1.png').convert('RGBA');retry=Image.open('art/raw/motions-77/rio_female-hurt-3.png').convert('RGBA');w=original.width//3
check(original.size==retry.size,'single-frame retry preserves source canvas')
for i in [1,2]:check(original.crop((i*w,0,(i+1)*w,original.height)).tobytes()==retry.crop((i*w,0,(i+1)*w,retry.height)).tobytes(),f'female hurt retry leaves F{i+1} pixel-identical')
check(not subprocess.run(['git','diff','--name-only','--','tools/'],capture_output=True,text=True,check=True).stdout.strip(),'no tracked tools-folder changes')
for stem in ['rio_male','rio_female']:
 reference=Image.open(f'art/raw/motions-77/{stem}-anchor-4x.png').convert('RGBA');expected=Image.open(f'art/bakeoff/rio/{stem}-idle-v2.png').convert('RGBA').crop((0,0,128,128)).resize((512,512),Image.Resampling.NEAREST)
 check(reference.tobytes()==expected.tobytes(),stem+' accepted idle reference preserved exactly at 4x')
files=json.loads((root/'files-to-stage.json').read_text(encoding='utf-8'))
for f in files:
 check(bool(re.match(r'^(art/bakeoff/rio/|reports/codex-art-77/)',f)) and not f.startswith('art/raw/') and '__pycache__' not in f and not f.endswith('run.log'),'stage scope '+f)
 if f!=str(root/'audit.json').replace('\\','/'):check(Path(f).is_file(),'stage file exists '+f)
script=(root/'commit.ps1').read_text(encoding='utf-8');check(not re.search(r'\badd\s+(?:-f|--force)\b',script),'commit script has no force-add')
message=re.search(r"\$message = @'\n(.*?)\n'@",script,re.S).group(1)
check(message.rstrip().endswith('Co-Authored-By: Codex <noreply@openai.com>'),'commit message co-author trailer')
pspath=str((root/'commit.ps1').resolve()).replace("'","''")
code="$parseTokens=$null; $parseIssues=$null; [System.Management.Automation.Language.Parser]::ParseFile('"+pspath+"',[ref]$parseTokens,[ref]$parseIssues) > $null; if($parseIssues.Count){ $parseIssues | ForEach-Object { $_.Message }; exit 1 }"
ps=subprocess.run(['powershell','-NoProfile','-NonInteractive','-Command',code],capture_output=True,text=True)
check(ps.returncode==0,'commit.ps1 syntax only; not executed')
audit={'passed':True,'published_rows':sum(r['accepted'] for r in summary),'reviewed_rows':len(summary),'generations':len(ledger),'checks':checks,'game_folder_diff':diff,'commit_script_executed':False,'godot_run':False}
(root/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps({k:v for k,v in audit.items() if k!='checks'},ensure_ascii=False));print(len(checks),'checks passed')
