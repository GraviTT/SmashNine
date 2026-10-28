"""Read-only final artifact checks. Game execution is intentionally out of scope."""
import os,sys,json,hashlib,re
from pathlib import Path
import numpy as np
from PIL import Image
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
root=Path('reports/codex-skm-02');states=json.loads((root/'progress.json').read_text(encoding='utf-8'));checks=[];manifest=[]
def check(label,ok):
 checks.append({'check':label,'pass':bool(ok)})
 if not ok:print('FAIL',label)
for s in states:
 stem,row=s['stem'],s['row'];key=f'{stem}-{row}';base=root/stem/row/f'attempt-{s["attempt"]}'
 check(key+' 4x board',(root/f'{key}.png').exists())
 raws=sorted(Path('art/raw/skm-02').glob(f'{key}-[12].png'));check(key+' generation limit',1<=len(raws)<=2)
 for raw in raws:
  ex=json.loads((raw.with_suffix('')/'extraction.json').read_text(encoding='utf-8')) if (raw.with_suffix('')/'extraction.json').exists() else None
  # extract.py stores beside frames, within the generation-specific directory.
  check(raw.name+' extraction trace',ex is not None and len(ex['frames'])==6)
  manifest.append({'row':key,'raw':raw.as_posix(),'sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'reference':f'art/bakeoff/{stem.split("_")[0]}/{stem}-idle-v2.png'})
 if not s['delivered']:continue
 dst=Path('art/bakeoff')/stem.split('_')[0]/f'{key}-v1.png';meta=json.loads(dst.with_suffix('.json').read_text(encoding='utf-8'));m=json.loads((base/'metrics.json').read_text(encoding='utf-8'));f=json.loads((base/'face-measured.json').read_text(encoding='utf-8'));im=Image.open(dst).convert('RGBA')
 check(key+' size',im.size==(1152,192));check(key+' exact normalized bytes',dst.read_bytes()==(base/f'{key}.png').read_bytes())
 check(key+' metadata',all(k in meta for k in ['note','for','frames','fps','cell','feet','loop','factor']) and meta['frames']==6 and meta['cell']==192 and meta['feet']==[96,152] and meta['loop'] is False)
 check(key+' common downscale',0<meta['factor']<=1 and meta['factor']==m['summary']['common_scale'])
 check(key+' settings',m['summary']['resample']=='lanczos' and m['summary']['sharpen_percent']==60 and m['summary']['despill']=='auto' and m['summary']['palette']=='none')
 for i in range(6):
  fr=im.crop((192*i,0,192*(i+1),192));ar=np.array(fr);box=fr.getbbox();marg=min(box[0],box[1],192-box[2],192-box[3])
  check(key+f' F{i+1} alpha',set(np.unique(ar[:,:,3]))<={0,255});check(key+f' F{i+1} margin4',marg>=4);check(key+f' F{i+1} spill0',n.spill_pixel_count(fr)==0);check(key+f' F{i+1} detail79',n.interior_detail(fr)>=79)
 widths=[x['face_width_ratio'] for x in f['frames'] if x.get('face_width_ratio') is not None];check(key+' reviewed face widths',bool(widths) and min(widths)>=.96 and max(widths)<=1.04)
script=(root/'commit.ps1').read_text(encoding='utf-8-sig');stagepaths=re.findall(r"^    '([^']+)'$",script,re.M)
check('commit explicit files exist',all(Path(p).is_file() for p in stagepaths));check('commit no force','git add -f' not in script)
check('commit forbidden files',all(not p.startswith('art/raw/') and '__pycache__' not in p and not p.endswith('run.log') and not p.startswith('smash-nine-prototype/') for p in stagepaths))
check('commit coauthor','Co-Authored-By: Codex <noreply@openai.com>' in script)
check('commit only this unit',all(p=='design/tasks/CODEX-SKM-02.md' or p.startswith('reports/codex-skm-02/') or re.fullmatch(r'art/bakeoff/(rio/rio_(male|female)-(dimension_link|pogo_bounce)|nova/nova_(male|female)-zero_gravity)-v1\.(png|json)',p) for p in stagepaths))
(root/'generation-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
(root/'audit.json').write_text(json.dumps({'passed':sum(c['pass'] for c in checks),'failed':sum(not c['pass'] for c in checks),'candidate_rows':sum(s['delivered'] for s in states),'game_run':False,'checks':checks},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'passed':sum(c['pass'] for c in checks),'failed':sum(not c['pass'] for c in checks),'candidates':sum(s['delivered'] for s in states)}))
sys.exit(0 if all(c['pass'] for c in checks) else 1)
