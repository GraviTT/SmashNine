"""Read-only artifact audit. Never executes commit.ps1."""
import hashlib,json,re,subprocess,sys
from pathlib import Path
from PIL import Image

root=Path('reports/codex-art-72');summary=json.loads((root/'summary.json').read_text(encoding='utf-8'));selection=json.loads((root/'selection.json').read_text(encoding='utf-8'))
checks=[]
def check(ok,label):
 checks.append({'check':label,'passed':bool(ok)})
 if not ok:raise AssertionError(label)
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
branch=subprocess.run(['git','branch','--show-current'],capture_output=True,text=True,check=True).stdout.strip();check(branch=='codex/art-72','branch codex/art-72')
diff=subprocess.run(['git','diff','--name-only','--','smash-nine-prototype/'],capture_output=True,text=True,check=True).stdout.strip();check(not diff,'no tracked game-folder changes')
for r,item in zip(summary,selection):
 label=r['stem']+'/'+r['row'];check((r['stem'],r['row'])==(item['stem'],item['row']),label+' order')
 base=root/r['stem']/r['row']/f'attempt-{r["attempt"]}';m=json.loads((base/'metrics.json').read_text());s=m['summary']
 check(s['resample']=='lanczos' and s['sharpen_percent']==60 and s['despill']=='auto' and s['palette']=='none',label+' pipeline settings')
 check(s['frame_count']==r['frames'] and m['input']['backgrounds'],label+' source frames')
 check((root/f'{r["stem"]}-{r["row"]}.png').exists(),label+' 4x board')
 if not r['accepted']:continue
 p=Path(r['candidate']);meta=json.loads(p.with_suffix('.json').read_text(encoding='utf-8'));im=Image.open(p).convert('RGBA');cell=192 if r['row']=='victory' else 128;feet=152 if cell==192 else 120
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
 check(all(.96<=f['eye_ratio']<=1.04 and .96<=f['face_width_ratio']<=1.04 for f in r['face']['frames']),label+' face range')
ledger=json.loads((root/'generation-ledger.json').read_text(encoding='utf-8'));groups={}
for e in ledger:
 groups[e['stem']+'/'+e['row']]=groups.get(e['stem']+'/'+e['row'],0)+1
 check(Path(e['raw']).is_file(),e['key']+' raw preserved')
check(all(n<=3 for n in groups.values()),'at most three generations per row')
for stem in ['frey','luna','luna_brave']:check(Path(f'art/raw/motions-72/{stem}-anchor-4x.png').exists(),stem+' reference preserved')
files=json.loads((root/'files-to-stage.json').read_text(encoding='utf-8'))
for f in files:
 check(bool(re.match(r'^(art/bakeoff/(frey|luna)/|reports/codex-art-72/)',f)) and not f.startswith('art/raw/') and '__pycache__' not in f,'stage scope '+f)
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
