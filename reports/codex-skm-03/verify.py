"""Read-only artifact verification adapted from ART-72; never executes commit.ps1.

Writes only this report's audit.json and generation-ledger.json.
"""
import os,sys,json,hashlib,re,subprocess
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
from PIL import Image
root=Path('reports/codex-skm-03')
rows=json.loads((root/'selection.json').read_text(encoding='utf-8'))
checks=[]
def check(ok,label):
 checks.append({'check':label,'passed':bool(ok)})
 if not ok:raise AssertionError(label)
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
branch=subprocess.run(['git','branch','--show-current'],capture_output=True,text=True,check=True).stdout.strip()
check(branch=='codex/skm-03','branch is codex/skm-03')
diff=subprocess.run(['git','diff','--name-only','HEAD','--','smash-nine-prototype/'],capture_output=True,text=True,check=True).stdout.strip()
check(not diff,'no tracked product folder changes')
check(len(rows)==2 and sum(r['accepted'] for r in rows)==1,'two rows reviewed, one candidate delivered')
for r in rows:
 row=r['row'];base=root/'frey'/row/f'attempt-{r["attempt"]}'
 m=json.loads((base/'metrics.json').read_text());s=m['summary']
 f=json.loads((base/'face-proposed.json').read_text());measured=[v for v in f['frames'] if v['frame'] in r['face_frames']]
 check(s['resample']=='lanczos' and s['sharpen_percent']==60 and s['despill']=='auto' and s['palette']=='none',row+' prescribed pipeline settings')
 check(s['frame_count']==6 and s['common_scale']==r['factor'] and 0<r['factor']<1,row+' six frames / one downscale factor')
 check(s['common_offset_x']==0 and m['normalization']['cell']==192 and m['normalization']['feet_y']==152,row+' 192px cells / centre x96 / feet reference y152')
 check(all(bg['color']==[0,255,0] for bg in m['input']['backgrounds']),row+' chroma green key')
 ex=json.loads((base/'extraction.json').read_text())
 check(len(ex['boxes'])==6 and 'no fixed-width' in ex['method'],row+' connected silhouettes extracted, no fixed-width slicing')
 check(all(0<b[0]<b[2]<ex['size'][0] and 0<b[1]<b[3]<ex['size'][1] for b in ex['boxes']),row+' whole raw silhouettes with clear source borders')
 check(r['reviewed_frames']==[1,2,3,4,5,6],row+' all six final frames visually reviewed at 4x')
 im=Image.open(base/f'frey-{row}.png').convert('RGBA')
 check(im.size==(1152,192),row+' strip dimensions')
 for i in range(6):
  frame=im.crop((192*i,0,192*(i+1),192));b=frame.getbbox();fm=m['frames'][i]
  check(b is not None and list(b)==fm['bbox'],row+f' F{i+1} bbox matches')
  check(set(frame.getchannel('A').get_flattened_data())<={0,255},row+f' F{i+1} binary alpha')
  check(min(b[0],b[1],192-b[2],192-b[3])>=4,row+f' F{i+1} empty border and 4px margin')
  check(n.spill_pixel_count(frame)==0,row+f' F{i+1} spill zero')
  check(n.interior_detail(frame)==fm['interior_detail'] and fm['interior_detail']>=79,row+f' F{i+1} detail at least 79')
  check((b[3]-1==152) if row=='whirl_spin' else (b[3]-1<152),row+f' F{i+1} ground/air placement')
 if row=='wing_hover':
  bottoms=[v['bottom'] for v in m['frames']]
  check(1<=bottoms[3]-bottoms[2]<=2 and 1<=bottoms[5]-bottoms[4]<=2,'hover F3/F5 bob 1-2px higher than F4/F6')
  check((base/'handoff4x.png').exists(),'hover F6 versus current dash F3 board')
  check(all(.95<=v[k]<=1.06 for v in measured for k in ['eye_ratio','face_width_ratio']),'hover all measured face ratios within delivery range')
  check(r['face_verified'] and r['pose_ok'] and r['costume_ok'],'hover manual visual checks recorded')
  p=Path(f'art/bakeoff/frey/frey-{row}-v1.png');meta=json.loads(p.with_suffix('.json').read_text(encoding='utf-8'))
  check(sha(p)==sha(base/f'frey-{row}.png'),'candidate byte-identical to normalization output')
  check(meta['frames']==6 and meta['fps']==20 and meta['cell']==192 and meta['feet']==[96,152] and meta['loop'] is False and meta['factor']==r['factor'],'candidate timing/placement metadata')
  check('1.057' in meta['note'] and meta['for']=='발키리의 날개 정지','candidate Korean purpose and out-of-target face ratio disclosed')
 else:
  check(not r['accepted'] and not r['face_verified'],'spin held for unverified/out-of-range face width')
  check(any(v['face_width_ratio']<.95 for v in measured),'spin actual measured rejection retained')
  check(r['face_frames']==[1,3,4,5,6] and '2' in r['excluded_faces'],'rear-view F2 excluded, visible F1 included')
  check(not list(Path('art/bakeoff/frey').glob('frey-whirl_spin-v*.*')),'held spin not published to candidates')
 board=Image.open(root/f'frey-{row}.png')
 check(board.size==(2048,3072 if row=='wing_hover' else 2304),row+' exact 4x board page geometry')
 check((root/f'{row}-checks.json').is_file() and (root/f'{row}-faces4x.png').is_file(),row+' curated evidence present')
ledger=[]
generated=Path('C:/Users/TH/.codex/generated_images/01a19d09-9dec-76e3-87fb-783b90c31420')
originals={
 'wing_hover':['exec-33bdef1d-e7ad-4b14-8ec4-89e6a4341621.png','exec-c6956c4a-de1a-4a26-a452-5a1b9ec20023.png','exec-a80f5f29-9600-4040-bf1e-6e299254159b.png'],
 'whirl_spin':['exec-4bdcaa02-d1d9-4579-af26-a148272a8002.png','exec-0a4eb088-9a2a-456d-ad45-a6b19193d36e.png','exec-076ca280-4a5d-492c-b855-4d5a73d29ec8.png']}
for row in ['wing_hover','whirl_spin']:
 raws=sorted(Path('art/raw/skm-03').glob(f'frey-{row}-*.png'))
 check(len(raws)==3,row+' generation count is three, within cap')
 for i,p in enumerate(raws,1):
  original=generated/originals[row][i-1]
  check(sha(p)==sha(original),p.name+' byte-identical to built-in generated original')
  refs=['art/bakeoff/frey/frey-idle-v2.png','smash-nine-prototype/assets/art/frey/frey_moves_sheet.png']
  if (row=='whirl_spin' and i>=2) or (row=='wing_hover' and i==3):refs.append(f'art/raw/skm-03/frey-{row}-1.png')
  ledger.append({'row':row,'attempt':i,'tool':'built-in image_gen','raw':p.as_posix(),'size':Image.open(p).size,'sha256':sha(p),'references':refs,'original':str(original)})
(root/'generation-ledger.json').write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
files=json.loads((root/'files-to-stage.json').read_text(encoding='utf-8'))
script=(root/'commit.ps1').read_text(encoding='utf-8')
script_files=re.findall(r"^    '([^']+)'$",script,re.M)
check(sorted(files)==sorted(script_files),'stage manifest exactly matches commit script')
for p in files:
 check(p=='design/tasks/CODEX-SKM-03.md' or p.startswith('reports/codex-skm-03/') or bool(re.fullmatch(r'art/bakeoff/frey/frey-wing_hover-v1\.(png|json)',p)),'stage scope '+p)
 check(not any(s in p for s in ['art/raw/','attempt-','__pycache__','run.log']),'no raw/attempt/cache/log in stage '+p)
 check(Path(p).is_file() or p=='reports/codex-skm-03/audit.json','stage file exists '+p)
check(not re.search(r'\badd\s+(?:-f|--force)\b',script),'no force add')
message=re.search(r"\$message = @'\n(.*?)\n'@",script,re.S).group(1)
check(message.rstrip().endswith('Co-Authored-By: Codex <noreply@openai.com>'),'commit message co-author trailer')
pspath=str((root/'commit.ps1').resolve()).replace("'","''")
cmd="$t=$null; $e=$null; [System.Management.Automation.Language.Parser]::ParseFile('"+pspath+"',[ref]$t,[ref]$e) > $null; if($e.Count){ $e | ForEach-Object { $_.Message }; exit 1 }"
ps=subprocess.run(['powershell','-NoProfile','-NonInteractive','-Command',cmd],capture_output=True,text=True)
check(ps.returncode==0,'commit.ps1 parsed only; never executed')
sizes={p:sum(f.stat().st_size for f in Path(p).rglob('*') if f.is_file()) for p in ['reports/codex-skm-03','art/raw/skm-03']}
audit={'passed':True,'checks':checks,'published':['wing_hover'],'held':['whirl_spin'],'generation_count':6,'godot_run':False,'commit_script_executed':False,'tracked_game_diff':diff,'folder_bytes':sizes}
(root/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'passed':True,'checks':len(checks),'published':['wing_hover'],'held':['whirl_spin'],'folder_bytes':sizes},ensure_ascii=False))
