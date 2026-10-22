"""Prepare reviewed ART-72 evidence and, only with --publish, new candidate files."""
import hashlib,json,shutil,sys
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont

root=Path('reports/codex-art-72');publish='--publish' in sys.argv
rows=json.loads((root/'selection.json').read_text(encoding='utf-8'))
counts={'jump':3,'fall':2,'hurt':3,'land':2,'victory':6};fps={'jump':10,'fall':8,'hurt':12,'land':12,'victory':8}
staged=[];summary=[];pending=[]
def register(p):
 p=Path(p);staged.append(p.as_posix());return p
def digest(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
for item in rows:
 stem,row,att=item['stem'],item['row'],item['attempt'];base=root/stem/row/f'attempt-{att}';n=counts[row]
 m=json.loads((base/'metrics.json').read_text());cell=m['normalization']['cell'];s=m['summary']
 hp=json.loads((base/'head-scale.json').read_text());facepath=base/'face-manual.json' if (base/'face-manual.json').exists() else base/'face-proposed.json'
 face=json.loads(facepath.read_text()) if facepath.exists() else None
 source=base/f'{stem}-{row}.png';sheet=Image.open(source).convert('RGBA');frames=[sheet.crop((i*cell,0,(i+1)*cell,cell)) for i in range(n)]
 folder='frey' if stem=='frey' else 'luna';av={'frey':2,'luna':3,'luna_brave':4}[stem]
 anchor=Image.open(f'art/bakeoff/{folder}/{stem}-idle-v{av}.png').convert('RGBA').crop((0,0,128,128))
 review=register(root/f'{stem}-{row}.png');shutil.copyfile(base/'review4x.png',review)
 evidence=root/'best'/stem/row;evidence.mkdir(parents=True,exist_ok=True)
 for src,name in [(source,'best-attempt.png'),(base/'metrics.json','metrics.json'),(base/'head-scale.json','head-scale.json')]:shutil.copyfile(src,register(evidence/name))
 if face:
  annotated=dict(face);annotated['excluded_frames']=item.get('unreliable_frames',[]);annotated['review_passed']=item['face_verified'];annotated['review_note']=item['reason']
  register(evidence/'face-measured.json').write_text(json.dumps(annotated,ensure_ascii=False,indent=2),encoding='utf-8')
  fb=base/'face-landmarks-manual.png' if (base/'face-landmarks-manual.png').exists() else base/'face-landmarks-proposed.png'
  shutil.copyfile(fb,register(evidence/'face-landmarks.png'))
 # Exact 4x pages at <=2048 pixels wide, with an anchor on every page.
 qa=root/'qa4x'/stem/row;qa.mkdir(parents=True,exist_ok=True);step=2 if cell==192 else 3
 for start in range(0,n,step):
  group=frames[start:start+step];width=(128+cell*len(group))*4;canvas=Image.new('RGB',(width,cell*4),(31,38,55));draw=ImageDraw.Draw(canvas)
  x=0
  for k,f in enumerate([anchor]+group):
   y=(cell//2+56-120)*4 if k==0 else 0;t=f.resize((f.width*4,f.height*4),Image.Resampling.NEAREST);canvas.paste(t,(x,y),t)
   draw.text((x+4,y+4),'ANCHOR' if k==0 else f'F{start+k}',fill='white');x+=t.width
  canvas.save(qa/f'{start+1:02d}-{min(n,start+step):02d}.png')
 margin=min(f['margin']['minimum'] for f in m['frames']);detail=[round(min(f['interior_detail'] for f in m['frames']),2),round(max(f['interior_detail'] for f in m['frames']),2)]
 rr={'stem':stem,'row':row,'attempt':att,'frames':n,'fps':fps[row],'factor':s['common_scale'],'margin':margin,'detail':detail,'head':hp,'face':face,'accepted':item['accepted'],'reason':item['reason'],'sheet_sha256':digest(source),'candidate':None}
 if item['accepted']:
  assert item['reviewed_frames']==list(range(1,n+1)),(stem,row,'4x review incomplete')
  assert item['face_verified'] and item['pose_ok'] and item['costume_ok'],(stem,row,'review incomplete')
  assert s['borders_clear'] and s['all_have_4px_margin'] and s['alpha_binary'] and not any(s['remaining_spill_pixels']) and detail[0]>=79,(stem,row,'cleanup failed')
  assert face and facepath.stat().st_mtime_ns >= (base/'metrics.json').stat().st_mtime_ns,(stem,row,'stale face measurement')
  assert len(face['frames'])==n and all(.96<=f['eye_ratio']<=1.04 and .96<=f['face_width_ratio']<=1.04 for f in face['frames']),(stem,row,'face check failed')
  assert sheet.size==(cell*6,cell),(stem,row,'sheet dimensions')
  v=3 if stem=='luna' and row in ['jump','fall'] else 3 if stem=='luna_brave' and row=='fall' else 1 if row in ['land','victory'] else 2
  dst=Path(f'art/bakeoff/{folder}/{stem}-{row}-v{v}.png')
  assert not dst.exists() and not dst.with_suffix('.json').exists(),f'never overwrite {dst}'
  meta={'note':item['reason']+f' 행 공통 배율 {s["common_scale"]}. 얼굴 눈 사이 거리와 눈높이 얼굴 폭을 4배 표식으로 확인. ART-72 후보이며 게임 미연결.','fps':fps[row],'frames':n,'loop':row=='fall','hold_last':row in ['jump','hurt','victory'],'factor':s['common_scale']}
  if cell==192:meta.update(cell=192,feet=152)
  pending.append((source,dst,meta));rr['candidate']=dst.as_posix();register(dst);register(dst.with_suffix('.json'))
 valid=[f for f in face['frames'] if f['frame'] not in item.get('unreliable_frames',[])] if face else []
 rr['face_valid_frames']=[f['frame'] for f in valid]
 rr['face_eye_range']=[min(f['eye_ratio'] for f in valid),max(f['eye_ratio'] for f in valid)] if valid else None
 rr['face_width_range']=[min(f['face_width_ratio'] for f in valid),max(f['face_width_ratio'] for f in valid)] if valid else None
 summary.append(rr)

if publish:
 for source,dst,meta in pending:
  with dst.open('xb') as f:f.write(source.read_bytes())
  with dst.with_suffix('.json').open('x',encoding='utf-8',newline='\n') as f:json.dump(meta,f,ensure_ascii=False,indent=2);f.write('\n')
  assert digest(source)==digest(dst)

register(root/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
def span(a):return '—' if a is None else f'{a[0]:.2f}–{a[1]:.2f}'
lines=['# ART-72 캐릭터 동작 1차 묶음','',f'후보 전달 {sum(r["accepted"] for r in summary)}/15행. Frey → Luna → Brave Luna 순서로 제작했다. 게임 폴더는 변경하지 않았다. 내장 ImageGen만 사용했고, 원본과 참조는 `art/raw/motions-72/`에 보존했다.','', '## 행별 결과','', '얼굴 칸은 **눈 사이 거리 / 눈높이 얼굴 폭**의 기준 대비 비율이다. F는 1부터 센다. 미전달 행의 자동 표식이 잘못 잡혔거나 감은 눈을 측정하지 못한 경우는 아래 이유에 적었으며, 그 수치를 통과로 취급하지 않았다.']
for stem in ['frey','luna','luna_brave']:
 lines+=['',f'### {stem}','','| 행 | 프레임·fps | 공통 배율 | 얼굴 눈/폭 (전 프레임) | 최소 여백 | 디테일 | 전달 |','|---|---:|---:|---|---:|---:|---|']
 for r in [q for q in summary if q['stem']==stem]:
  fl=f'F1–{r["frames"]}' if len(r['face_valid_frames'])==r['frames'] else 'F'+','.join(map(str,r['face_valid_frames']))
  lines.append(f'| {r["row"]} | {r["frames"]} · {r["fps"]} | {r["factor"]} | {span(r["face_eye_range"])} / {span(r["face_width_range"])} ({fl}) | {r["margin"]}px | {span(r["detail"])} | {"완료" if r["accepted"] else "미전달"} |')
lines+=['','## 측정과 육안 판단','','- **측정:** 기존 정규화 도구의 LANCZOS·선명화 60·디스필 auto·팔레트 없음·초록 배경 설정을 사용했다. 프레임별 배율 조정이나 머리 붙이기는 하지 않았다. 메트릭과 자동 머리 값은 `best/<폼>/<행>/`에 있다.','- **얼굴 측정:** 기준 얼굴의 눈 중심과 머리카락을 제외한 눈높이 얼굴 경계 표식을 4배 최근접 확대에서 정합했다. 머리 전체 정합은 초기 위치만 잡는다. 눈과 얼굴 경계 표식은 별도로 측정한다. 소수 자릿수는 계산 출력 정밀도이며 실제 측정 오차가 그만큼 작다는 뜻은 아니다.','- **육안 판단:** 전 프레임의 얼굴·손·부츠·무기·의상과 동작 의미를 4배 판에서 확인했다. 실제 게임 실행이나 플레이어 체감 검사는 하지 않았다.','- **4배 자료:** `<폼>-<행>.png`는 기준과 전 프레임 판, `qa4x/`는 화면에서 축소되지 않도록 나눈 최대 2048px 폭의 4배 검토 페이지다.','- **전달 조건:** 여백·번짐·디테일뿐 아니라 전 프레임의 얼굴 두 지표가 모두 0.96–1.04이고 표식과 동작을 직접 확인한 행만 후보 폴더에 내보냈다.','','## 아직 잘못된 점 / 남은 작업','']
for r in summary:lines.append(f'- **{r["stem"]} {r["row"]} ({"전달" if r["accepted"] else "미전달"}, 최선 {r["attempt"]}차): {r["reason"]}')
lines+=['','원본 경계 실패는 해당 행의 `source-check-*.txt` 또는 `process-*.log`에 남긴다. 생성 3회가 끝난 행은 추가 생성하지 않았다. 미전달 행은 후보 폴더에 넣지 않고 `best/`의 그림과 4배 판만 남겼다.','','## 확인 및 커밋','','`commit.ps1`은 명시한 파일만 추가하며 raw와 캐시를 포함하지 않는다. 이 스크립트는 실행하지 않았다. 전달 후보는 사용자가 모션 뷰어에서 고른 뒤 별도 카드에서 게임에 연결해야 한다.']
register(root/'README.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
ledger=root/'generation-ledger.json'
prompt_text='\n\n'.join(e['key']+'\n'+e['prompt'] for e in json.loads(ledger.read_text(encoding='utf-8'))) if ledger.exists() else '\n\n'.join(p.stem+'\n'+p.read_text(encoding='utf-8') for p in sorted((root/'prompts').glob('*.txt')))
register(root/'prompts.txt').write_text(prompt_text+'\n',encoding='utf-8')
for p in [root/'selection.json',root/'package.py',root/'process.py',root/'face_check.py',root/'finalize.py',root/'verify.py',root/'audit.json']:register(p)
if ledger.exists():register(ledger)
for p in root.rglob('source-check-*.txt'):register(p)
for p in root.rglob('process-*.log'):register(p)
for p in (root/'qa4x').rglob('*.png'):register(p)
register(root/'commit.ps1');register(root/'files-to-stage.json')
files=sorted(set(staged));assert all(not p.startswith('art/raw/') and '__pycache__' not in p for p in files)
(root/'files-to-stage.json').write_text(json.dumps(files,ensure_ascii=False,indent=2),encoding='utf-8')
filelines='\n'.join("    '"+p.replace("'","''")+"'" for p in files)
script="""$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\\..'))
$branch = (& git -C $repo branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-72') { throw 'Expected codex/art-72 in this clone.' }
$files = @(
"""+filelines+"""
)
foreach ($file in $files) {
    if ($file -notmatch '^(art/bakeoff/(frey|luna)/|reports/codex-art-72/)' -or $file -match '(^art/raw/|__pycache__)') { throw "Disallowed path: $file" }
    if (-not (Test-Path -LiteralPath (Join-Path $repo $file) -PathType Leaf)) { throw "Missing file: $file" }
}
$before = @(& git -C $repo diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect index.' }
foreach ($file in $before) { if ($file -and $file -notin $files) { throw "Unrelated staged file: $file" } }
& git -C $repo add -- $files
if ($LASTEXITCODE -ne 0) { throw 'Staging failed.' }
$after = @(& git -C $repo diff --cached --name-only)
foreach ($file in $after) { if ($file -and $file -notin $files) { throw "Unexpected staged file: $file" } }
$message = @'
Add reviewed Frey and Luna motion candidates and ART-72 evidence

Co-Authored-By: Codex <noreply@openai.com>
'@
& git -C $repo commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
"""
(root/'commit.ps1').write_text(script,encoding='utf-8',newline='\n')
print(json.dumps({'published':publish,'accepted':sum(r['accepted'] for r in summary),'rows':len(summary),'staged_files':len(files)},ensure_ascii=False))
