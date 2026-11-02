"""Read-only verification of SKM-04 deliverables and held evidence. Writes audit.json only."""
import os,sys,json,hashlib,re,subprocess
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
from PIL import Image
root=Path('reports/codex-skm-04');rows=json.loads((root/'selection.json').read_text(encoding='utf-8'))
checks=[]
def check(ok,label):
 checks.append({'check':label,'passed':bool(ok)})
 if not ok:raise AssertionError(label)
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
branch=subprocess.run(['git','branch','--show-current'],capture_output=True,text=True,check=True).stdout.strip()
check(branch=='codex/skm-04','correct branch')
diff=subprocess.run(['git','diff','--name-only','HEAD','--','smash-nine-prototype/'],capture_output=True,text=True,check=True).stdout.strip()
check(not diff,'no tracked product changes')
check(len(rows)==3,'all three rows reviewed')
for r in rows:
 row=r['row'];stem=r['stem'];base=root/stem/row/f'attempt-{r["attempt"]}'
 check(all('??' not in r[k] and re.search('[가-힣]',r[k]) for k in ['for','note','attempt_notes','human_review']),row+' Korean report text intact')
 m=json.loads((base/'metrics.json').read_text());s=m['summary'];f=json.loads((base/'face-proposed.json').read_text());measured=[v for v in f['frames'] if v['frame'] in r['face_frames']]
 check(s['resample']=='lanczos' and s['sharpen_percent']==60 and s['despill']=='auto' and s['palette']=='none',row+' prescribed settings')
 check(s['frame_count']==6 and s['common_scale']==r['factor'] and 0<r['factor']<1,row+' six frames one downscale factor')
 check(s['common_offset_x']==0 and m['normalization']['cell']==192 and m['normalization']['feet_y']==152,row+' cell and anchor coordinates')
 check(all(bg['color']==[0,255,0] for bg in m['input']['backgrounds']),row+' green key')
 ex=json.loads((base/'extraction.json').read_text())
 check(len(ex['boxes'])==6 and 'no fixed-width' in ex['method'],row+' connected extraction')
 check(all(0<b[0]<b[2]<ex['size'][0] and 0<b[1]<b[3]<ex['size'][1] for b in ex['boxes']),row+' raw borders clear')
 check(r['reviewed_frames']==[1,2,3,4,5,6],row+' all final frames reviewed')
 im=Image.open(base/f'{stem}-{row}.png').convert('RGBA');check(im.size==(1152,192),row+' strip size')
 for i in range(6):
  frame=im.crop((i*192,0,(i+1)*192,192));b=frame.getbbox();fm=m['frames'][i]
  check(list(b)==fm['bbox'],row+f' F{i+1} bbox matches')
  check(set(frame.getchannel('A').get_flattened_data())<={0,255},row+f' F{i+1} binary alpha')
  check(min(b[0],b[1],192-b[2],192-b[3])>=4,row+f' F{i+1} 4px margin and border')
  check(b[3]-1==152,row+f' F{i+1} feet y152')
  check(n.spill_pixel_count(frame)==0,row+f' F{i+1} zero spill')
  check(n.interior_detail(frame)==fm['interior_detail'] and fm['interior_detail']>=79,row+f' F{i+1} detail >=79')
 p=Path(f'art/bakeoff/luna/{stem}-{row}-v1.png')
 if r['accepted']:
  check(all(.95<=v[k]<=1.06 for v in measured for k in ['eye_ratio','face_width_ratio']),row+' measured face ranges')
  check(r['face_verified'] and r['pose_ok'] and r['costume_ok'],row+' visual gates')
  check(sha(p)==sha(base/f'{stem}-{row}.png'),row+' published byte equality')
  meta=json.loads(p.with_suffix('.json').read_text(encoding='utf-8'))
  check(meta['frames']==6 and meta['fps']==r['fps'] and meta['cell']==192 and meta['feet']==[96,152] and meta['loop']==r['loop'] and meta['factor']==r['factor'],row+' metadata')
 else:
  check(not p.exists() and not p.with_suffix('.json').exists(),row+' held row not published')
  check(not r['face_verified'] or not r['pose_ok'] or not r['costume_ok'],row+' rejection retained')
 b=Image.open(root/f'{stem}-{row}.png');check(b.size==(2048,3072 if row=='brave_cyclone' else 2304),row+' exact 4x QA board')
 cp=json.loads((root/f'{row}-checks.json').read_text(encoding='utf-8'))
 check(cp['sheet_sha256']==sha(base/f'{stem}-{row}.png'),row+' curated evidence hash')
 if row=='brave_cyclone':check((base/'handoff4x.png').exists(),'F6-to-F1 loop board')
ledger=json.loads((root/'generation-ledger.json').read_text(encoding='utf-8'))
check(len(ledger)==9,'nine total generations')
for row in ['brave_cyclone','brave_grab','star_warp']:
 check(len([v for v in ledger if v['row']==row])==3,row+' three-generation cap')
for v in ledger:
 check(sha(v['raw'])==v['sha256']==sha(v['original']),v['raw']+' original preserved')
 check(len(v['references'])==2 and all(Path(p).exists() for p in v['references']),v['raw']+' correct two references present')
files=json.loads((root/'files-to-stage.json').read_text(encoding='utf-8'));script=(root/'commit.ps1').read_text(encoding='utf-8')
check(sorted(files)==sorted(re.findall(r"^    '([^']+)'$",script,re.M)),'stage manifest equals script')
for p in files:
 check(p=='design/tasks/CODEX-SKM-04.md' or p.startswith('reports/codex-skm-04/') or bool(re.fullmatch(r'art/bakeoff/luna/luna(?:_brave)?-(?:brave_cyclone|brave_grab|star_warp)-v1\.(?:png|json)',p)),'stage scope '+p)
 check(not any(v in p for v in ['art/raw/','attempt-','sweeps/','__pycache__','run.log']),'no intermediate files '+p)
 check(Path(p).is_file(),'exists '+p)
 if Path(p).suffix in ['.py','.json','.md','.ps1','.txt']:
  text=Path(p).read_text(encoding='utf-8-sig');check(not any(v.rstrip()!=v for v in text.splitlines()),'no trailing whitespace '+p)
check('git add -f' not in script and 'git add --force' not in script,'no force add')
msg=re.search(r"\$message = @'\n(.*?)\n'@",script,re.S).group(1)
check(msg.endswith('Co-Authored-By: Codex <noreply@openai.com>'),'coauthor trailer')
pspath=str((root/'commit.ps1').resolve()).replace("'","''")
cmd="$t=$null; $e=$null; [System.Management.Automation.Language.Parser]::ParseFile('"+pspath+"',[ref]$t,[ref]$e) > $null; if($e.Count){ $e | ForEach-Object { $_.Message }; exit 1 }"
ps=subprocess.run(['powershell','-NoProfile','-NonInteractive','-Command',cmd],capture_output=True,text=True)
check(ps.returncode==0,'PowerShell syntax parsed; commit NOT executed')
sizes={p:sum(v.stat().st_size for v in Path(p).rglob('*') if v.is_file()) for p in ['reports/codex-skm-04','art/raw/skm-04']}
audit={'passed':True,'checks':checks,'published':[r['row'] for r in rows if r['accepted']],'held':[r['row'] for r in rows if not r['accepted']],'generation_count':9,'commit_script_executed':False,'godot_run':False,'folder_bytes':sizes,'tracked_product_diff':diff}
(root/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'passed':True,'check_count':len(checks),'published':audit['published'],'held':audit['held'],'folder_bytes':sizes},ensure_ascii=False))
