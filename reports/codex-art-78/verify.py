"""Read-only artifact audit. Never executes commit.ps1."""
import hashlib,json,re,subprocess,sys
from pathlib import Path
import numpy as np
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as normalizer
from pathlib import Path
from PIL import Image

root=Path('reports/codex-art-78');summary=json.loads((root/'summary.json').read_text(encoding='utf-8'));selection=json.loads((root/'selection.json').read_text(encoding='utf-8'))
checks=[]
def check(ok,label):
 checks.append({'check':label,'passed':bool(ok)})
 if not ok:raise AssertionError(label)
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
branch=subprocess.run(['git','branch','--show-current'],capture_output=True,text=True,check=True).stdout.strip();check(branch=='codex/art-78','branch codex/art-78')
diff=subprocess.run(['git','diff','--name-only','--','smash-nine-prototype/'],capture_output=True,text=True,check=True).stdout.strip();check(not diff,'no tracked game-folder changes')
for r,item in zip(summary,selection):
 label=r['stem']+'/'+r['row'];check((r['stem'],r['row'])==(item['stem'],item['row']),label+' order')
 base=root/'best'/r['stem']/r['row'];m=json.loads((base/'metrics.json').read_text());s=m['summary']
 check(s['resample']=='lanczos' and s['sharpen_percent']==60 and s['despill']=='auto' and s['palette']=='none',label+' pipeline settings')
 check(s['frame_count']==r['frames'] and m['input']['backgrounds'],label+' source frames')
 check((root/f'{r["stem"]}-{r["row"]}.png').exists(),label+' 4x board')
 best=Image.open(base/'best-attempt.png').convert('RGBA');cell=best.height;feet=152 if cell==192 else 120
 check(best.size==(6*cell,cell),label+' best dimensions')
 check(sha(base/'best-attempt.png')==r['sheet_sha256'],label+' best SHA256')
 check(bool(np.isin(np.array(best.getchannel('A')),[0,255]).all()),label+' best binary alpha')
 for i in range(6):
  f=best.crop((i*cell,0,(i+1)*cell,cell));box=f.getbbox()
  if i>=r['frames']:
   check(box is None,label+f' best padding F{i+1}');continue
  check(box is not None,label+f' best visible F{i+1}')
  check(min(box[0],box[1],cell-box[2],cell-box[3])>=4,label+f' best margin F{i+1}')
  check((box[3]-1==feet) if r['row'] in ['hurt','victory'] else box[3]-1<feet,label+f' best feet/air F{i+1}')
  fm=normalizer.frame_metrics(f)
  check(fm['remaining_spill_pixels']==0 and fm['interior_detail']>=79,label+f' recomputed spill/detail F{i+1}')
  check(abs(fm['interior_detail']-m['frames'][i]['interior_detail'])<0.01,label+f' stored detail matches PNG F{i+1}')
 check(item['reviewed_frames']==list(range(1,r['frames']+1)),label+' every best frame visually reviewed at 4x')
 if not r['accepted']:continue
 p=Path(r['candidate']);meta=json.loads(p.with_suffix('.json').read_text(encoding='utf-8'));im=Image.open(p).convert('RGBA');cell=192 if r['row']=='victory' else 128;feet=152 if cell==192 else 120
 check(im.size==(cell*6,cell),label+' six-column dimensions')
 check(meta['frames']==r['frames'] and meta['fps']==r['fps'],label+' metadata timing')
 check(meta['cell']==cell and meta['feet']==feet and meta['factor']==r['factor'],label+' metadata cell/feet/factor')
 old=Path('reports/codex-art-72/best')/r['stem']/r['row']/'best-attempt.png'
 check(sha(p)==sha(old),label+' exact ART-72 best reused')
 check(str(r['face_eye_range'][0]) in meta['note'] and str(r['face_eye_range'][1]) in meta['note'],label+' measured exceptions noted')
 check(sha(p)==sha(base/'best-attempt.png')==r['sheet_sha256'],label+' unmodified normaliser output')
 check(bool(np.isin(np.array(im.getchannel('A')),[0,255]).all()),label+' binary alpha')
 for i in range(6):
  f=im.crop((i*cell,0,(i+1)*cell,cell));box=f.getbbox()
  if i>=r['frames']:check(box is None,label+f' empty padding F{i+1}');continue
  check(box is not None,label+f' visible F{i+1}');check(min(box[0],box[1],cell-box[2],cell-box[3])>=4,label+f' margin F{i+1}')
  check((box[3]-1==feet) if r['row'] in ['hurt','land','victory'] else (box[3]-1<feet),label+f' feet/air F{i+1}')
 check(not any(s['remaining_spill_pixels']) and min(f['interior_detail'] for f in m['frames'])>=79,label+' spill/detail')
 check(item['face_verified'] and item['pose_ok'] and item['costume_ok'] and item['reviewed_frames']==list(range(1,r['frames']+1)),label+' manual review recorded')
 check(all(.95<=f['eye_ratio']<=1.06 and .95<=f['face_width_ratio']<=1.06 for f in r['face']['frames']),label+' face range')
ledger=json.loads((root/'generation-ledger.json').read_text(encoding='utf-8'));groups={}
for e in ledger:
 groups[e['stem']+'/'+e['row']]=groups.get(e['stem']+'/'+e['row'],0)+1
 check(Path(e['raw']).is_file(),e['key']+' raw preserved')
 check(Path(e['generated_raw']).is_file(),e['key']+' generated original preserved')
 check(sha(e['generated_raw'])==e['generated_sha256'],e['key']+' original generation hash')
 check(all(Path(p).is_file() for p in e['references']),e['key']+' every used reference preserved')
 check(sha(e['raw'])==e['raw_sha256'],e['key']+' raw provenance hash')
 if e['replaced_frames']:
  prev=Image.open(f'art/raw/motions-78/{e["stem"]}-{e["row"]}-{e["attempt"]-1}.png').convert('RGBA')
  generated=Image.open(e['generated_raw']).convert('RGBA');assembled=Image.open(e['raw']).convert('RGBA')
  check(prev.size==generated.size==assembled.size,e['key']+' source canvases same size')
  cols,rows=(3,2) if e['row']=='victory' else (3,1)
  for k in range(cols*rows):
   x,y=k%cols,k//cols;box=(round(x*assembled.width/cols),round(y*assembled.height/rows),round((x+1)*assembled.width/cols),round((y+1)*assembled.height/rows))
   expected=generated if k+1 in e['replaced_frames'] else prev
   check(np.array_equal(np.array(assembled.crop(box)),np.array(expected.crop(box))),e['key']+f' full-cell retry provenance F{k+1}')
check(all(n<=3 for n in groups.values()),'at most three generations per row')
check(len(ledger)==15 and len(groups)==5 and all(n==3 for n in groups.values()),'five retry rows, exactly three generations each')
review=json.loads((root/'visual-review.json').read_text(encoding='utf-8'))
check(review['normalized_frames']==62 and review['new_normalized_frames']==57 and review['failed_source_frame_count']==15,'4x review coverage: 62 normalized + 15 rejected source frames')
for entry in review['normalized_attempts']:
 check(entry['reviewed_frames']==list(range(1,entry['frames']+1)) and entry['scale']==4 and bool(entry['pages']),entry['attempt']+' normalized review recorded')
for entry in review['failed_source_frames']:
 check(entry['reviewed'] and entry['scale']==4 and all(Path(p).is_file() for p in entry['pages']),entry['key']+f' source F{entry["frame"]} review recorded')
for stem in ['frey','luna','luna_brave']:check(Path(f'art/raw/motions-78/{stem}-anchor4x.png').exists(),stem+' reference preserved')
files=json.loads((root/'files-to-stage.json').read_text(encoding='utf-8'))
check(len(files)==len(set(files)),'manifest contains no duplicate paths')
check(all(not ('/attempt-' in f or '/landmark-pages/' in f) for f in files),'commit contains curated best evidence only')
for f in files:
 check(bool(re.match(r'^(art/bakeoff/(frey|luna)/|reports/codex-art-78/)',f)) and not f.startswith('art/raw/') and '__pycache__' not in f and Path(f).name!='run.log','stage scope '+f)
 if f!=str(root/'audit.json').replace('\\','/'):check(Path(f).is_file(),'stage file exists '+f)
script=(root/'commit.ps1').read_text(encoding='utf-8');check(not re.search(r'\badd\s+(?:-f|--force)\b',script),'commit script has no force-add')
message=re.search(r"\$message = @'\n(.*?)\n'@",script,re.S).group(1)
check(message.rstrip().endswith('Co-Authored-By: Codex <noreply@openai.com>'),'commit message co-author trailer')
tracked=subprocess.run(['git','diff','--name-only'],capture_output=True,text=True,check=True).stdout.strip()
check(not tracked,'no tracked product, tool, anchor, or existing report edits')
status=subprocess.run(['git','status','--short','--untracked-files=all'],capture_output=True,text=True,check=True).stdout.splitlines()
check(all(line[3:].startswith(('reports/codex-art-78/','art/bakeoff/frey/frey-jump-v2.','art/bakeoff/luna/luna_brave-fall-v3.')) for line in status),'all worktree additions stay within this card')
for f in files:
 if Path(f).suffix in ['.py','.ps1','.md','.json','.txt'] and Path(f).exists():check(b'\r\n' not in Path(f).read_bytes(),'LF text '+f)
pspath=str((root/'commit.ps1').resolve()).replace("'","''")
code="$parseTokens=$null; $parseIssues=$null; [System.Management.Automation.Language.Parser]::ParseFile('"+pspath+"',[ref]$parseTokens,[ref]$parseIssues) > $null; if($parseIssues.Count){ $parseIssues | ForEach-Object { $_.Message }; exit 1 }"
ps=subprocess.run(['powershell','-NoProfile','-NonInteractive','-Command',code],capture_output=True,text=True)
check(ps.returncode==0,'commit.ps1 syntax only; not executed')
audit={'passed':True,'published_rows':sum(r['accepted'] for r in summary),'reviewed_rows':len(summary),'generations':len(ledger),'checks':checks,'game_folder_diff':diff,'commit_script_executed':False,'godot_run':False}
(root/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n');print(json.dumps({k:v for k,v in audit.items() if k!='checks'},ensure_ascii=False));print(len(checks),'checks passed')
