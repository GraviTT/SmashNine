"""Publish only reviewed new candidate rows and build a lean review handoff."""
import json,hashlib,shutil
from pathlib import Path
from PIL import Image,ImageDraw
root=Path('reports/codex-art-77')
selection=json.loads((root/'selection.json').read_text(encoding='utf-8'))
counts={'jump':3,'fall':2,'hurt':3,'land':2,'victory':6};fps={'jump':10,'fall':8,'hurt':12,'land':12,'victory':8}
versions={'jump':2,'fall':2,'hurt':2,'land':1,'victory':1}
summary=[];stage=[]
def savejson(path,obj):path.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for item in selection:
 stem,row=item['stem'],item['row'];base=root/stem/row/f'attempt-{item["attempt"]}';best=root/'best'/stem/row;best.mkdir(parents=True,exist_ok=True)
 for name in [f'{stem}-{row}.png','metrics.json','head-scale.json','face-measured.json','face-measured.png','faces4x.png']:
  p=base/name
  if p.exists():shutil.copyfile(p,best/name);stage.append((best/name).as_posix())
 m=json.loads((base/'metrics.json').read_text(encoding='utf-8'));s=m['summary'];face=json.loads((base/'face-measured.json').read_text(encoding='utf-8'))
 cell=192 if row=='victory' else 128;feet=cell//2+56
 board=base/'review4x.png';shutil.copyfile(board,root/f'{stem}-{row}.png');stage.append((root/f'{stem}-{row}.png').as_posix())
 # True 4x review pages: anchor and up to two frames, at most 1600px wide.
 sh=Image.open(base/f'{stem}-{row}.png').convert('RGBA');anchor=Image.open(f'art/bakeoff/rio/{stem}-idle-v2.png').convert('RGBA').crop((0,0,128,128))
 frames=[sh.crop((i*cell,0,(i+1)*cell,cell)) for i in range(counts[row])]
 pages=root/'qa4x';pages.mkdir(exist_ok=True)
 for start in range(0,len(frames),2):
  group=frames[start:start+2];width=(128+len(group)*cell)*4;h=cell*4+36;out=Image.new('RGB',(width,h),(31,38,55));d=ImageDraw.Draw(out)
  aa=anchor.resize((512,512),Image.Resampling.NEAREST);y=(feet-120)*4+36;out.paste(aa,(0,y),aa);d.text((8,8),'ANCHOR',fill='white')
  for k,f in enumerate(group):
   xx=512+k*cell*4;cr=f.resize((cell*4,cell*4),Image.Resampling.NEAREST);out.paste(cr,(xx,36),cr);d.text((xx+8,8),f'F{start+k+1}',fill='white')
  d.line((0,feet*4+36,width,feet*4+36),fill=(255,85,100),width=2)
  path=pages/f'{stem}-{row}-{start//2+1}.png';out.save(path);stage.append(path.as_posix())
 r={'stem':stem,'row':row,'attempt':item['attempt'],'frames':counts[row],'fps':fps[row],'factor':s['common_scale'],'offset_x':s['common_offset_x'],'lift_scale':s['lift_scale'],'lift_range':s['lift_range'],'margin':min(f['margin']['minimum'] for f in m['frames']),'detail':s['interior_detail_range'],'head':json.loads((base/'head-scale.json').read_text()),'face':face,'accepted':item['accepted'],'reason':item['reason'],'candidate':None,'sheet_sha256':hashlib.sha256((base/f'{stem}-{row}.png').read_bytes()).hexdigest()}
 if item['accepted']:
  dest=Path(f'art/bakeoff/rio/{stem}-{row}-v{versions[row]}.png');meta=dest.with_suffix('.json')
  if dest.exists() and dest.read_bytes()!=(base/f'{stem}-{row}.png').read_bytes():raise RuntimeError('Refuse overwrite existing candidate '+str(dest))
  if not dest.exists():shutil.copyfile(base/f'{stem}-{row}.png',dest)
  note=item['reason']+' 기준부터 반대 눈이 가려져 눈 간 거리 검증은 하지 못함. 수동 얼굴 폭 측정은 픽셀 경계 판단으로 약 1px 오차 가능.'
  vals=[f['face_width_ratio'] for f in face['frames'] if f.get('face_width_ratio') is not None]
  if vals and (min(vals)<.96 or max(vals)>1.04):note+=f' 얼굴 폭 비율 {min(vals):.3f}–{max(vals):.3f}: 목표 0.96–1.04 밖이나 후보 허용 0.95–1.06 안.'
  metadata={'note':note,'frames':counts[row],'fps':fps[row],'cell':cell,'feet':feet,'factor':s['common_scale']}
  if meta.exists() and json.loads(meta.read_text(encoding='utf-8'))!=metadata:raise RuntimeError('Refuse overwrite metadata '+str(meta))
  if not meta.exists():savejson(meta,metadata)
  r['candidate']=dest.as_posix();stage.extend([dest.as_posix(),meta.as_posix()])
 summary.append(r)
savejson(root/'summary.json',summary)
fixed=['README.md','prompts.txt','process.py','face_check.py','verify.py','manual_faces.py','grid_faces.py','finalize.py','report.py','frame_retry.py','frame-retry.json','source_review.py','rejected_review.py','selection.json','summary.json','generation-ledger.json','files-to-stage.json','commit.ps1','audit.json']
stage.extend((root/name).as_posix() for name in fixed)
stage.extend(p.as_posix() for p in root.glob('*-face-points.json'))
stage.extend(p.as_posix() for p in (root/'source-check').glob('*') if p.is_file())
stage.extend(p.as_posix() for p in (root/'rejected').rglob('*') if p.is_file())
stage=sorted(set(stage));savejson(root/'files-to-stage.json',stage)
msg='Add Rio male and female motion candidates (ART-77)\n\nCo-Authored-By: Codex <noreply@openai.com>'
script="$ErrorActionPreference = 'Stop'\nSet-Location -LiteralPath (Join-Path $PSScriptRoot '../..')\n$files = @(\n"+'\n'.join("    '"+p+"'" for p in stage)+"\n)\nforeach ($file in $files) {\n    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw \"Missing: $file\" }\n}\n& git add -- $files\nif ($LASTEXITCODE -ne 0) { throw 'git add failed' }\n$message = @'\n"+msg+"\n'@\n& git commit --only -m $message -- $files\nif ($LASTEXITCODE -ne 0) { throw 'git commit failed' }\n"
(root/'commit.ps1').write_text(script,encoding='utf-8')
print('Rows',len(summary),'published',sum(r['accepted'] for r in summary),'stage files',len(stage))
