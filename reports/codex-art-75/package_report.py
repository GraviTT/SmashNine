"""Write Korean report, source/composition ledger and an explicit, unexecuted commit script."""
import json,hashlib,subprocess,sys
from pathlib import Path
from PIL import Image
root=Path('reports/codex-art-75')
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2),encoding='utf-8')
summary=json.loads((root/'summary.json').read_text(encoding='utf-8'));sel=json.loads((root/'selection.json').read_text(encoding='utf-8'))
counts={'jump':3,'fall':2,'hurt':3,'land':2,'victory':6}
for r in sel:
 r['reviewed_frames']=list(range(1,counts[r['row']]+1));r['face_verified']=r['accepted'];r['visual_review']='선택된 최종 15행 48프레임 전부 정확한 최근접 4배 qa4x 판에서 직접 확인. 수치와 육안 판단을 구분.'
 r['face_scope']='upright visible frames only; tilted hurt F1/F2 visual-only; Nova anchor eye spacing unavailable'
write(root/'selection.json',sel)
# Verify that only the requested cell changed in each generated single-frame replacement.
compositions=[]
for stem,row,base,nxt,frame in [('yuki','fall',2,3,1),('yuki','hurt',1,2,1),('yuki','hurt',2,3,2),('yuki','victory',2,3,1),('nova_male','hurt',1,2,2),('nova_male','victory',1,2,4),('nova_male','victory',2,3,4),('nova_female','jump',1,2,2),('nova_female','jump',2,3,2),('nova_female','hurt',1,2,2),('nova_female','hurt',2,3,2)]:
 raw=Path('art/raw/motions-75');p=raw/f'{stem}-{row}-{base}.png';q=raw/f'{stem}-{row}-{nxt}.png';a=Image.open(p).convert('RGB');b=Image.open(q).convert('RGB');cols=3 if row=='victory' else counts[row];rows=2 if row=='victory' else 1;w,h=a.width//cols,a.height//rows;unchanged=[]
 for i in range(counts[row]):
  if i==frame-1:continue
  box=(i%cols*w,i//cols*h,(i%cols+1)*w,(i//cols+1)*h);assert a.crop(box).tobytes()==b.crop(box).tobytes();unchanged.append(i+1)
 gen=Image.open(raw/f'{stem}-{row}-{nxt}-f{frame}.png');compositions.append({'stem':stem,'row':row,'source_attempt':base,'new_attempt':nxt,'replaced_frame':frame,'unchanged_frames_verified':unchanged,'raw_cell':[w,h],'generator_canvas':list(gen.size),'canvas_resolution_ratio':max(w,h)/gen.width,'feature_drawing_by_code':False,'normalisation':'Only canvas resolution/padding converted. Final shared row factor in summary.'})
write(root/'composition-ledger.json',compositions)
failures=[]
for at in [1,3]:
 cmd=[sys.executable,str(root/'process.py'),'nova_female','victory',str(at),'0.217'];p=subprocess.run(cmd,capture_output=True,text=True)
 assert p.returncode!=0 and 'source cell subject touches its bottom border' in p.stderr
 failures.append({'stem':'nova_female','row':'victory','attempt':at,'expected_failure':True,'message':p.stderr.splitlines()[0],'generation_raw':f'art/raw/motions-75/nova_female-victory-{at}.png','interpretation':'하단 행 F4의 올린 주먹이 상단 행 셀 경계를 침범한다. 잘라 숨기지 않고 해당 시도를 실패로 보존.'})
write(root/'source-failures.json',failures)
def rng(v):return f'{min(v):.3f}–{max(v):.3f}' if len(set(v))>1 else f'{v[0]:.3f}'
def face_text(r):
 f=r['face']['frames'];e=[x['eye_ratio'] for x in f if x['eye_ratio'] is not None];w=[x['face_width_ratio'] for x in f];frames='F'+','.join(str(x['frame']) for x in f)
 return (rng(e) if e else '측정 불가')+' / '+rng(w)+' ('+frames+')'
lines=['# ART-75 캐릭터 동작 2차 묶음','', '**완료: 후보 12/15행, 34프레임.** 유키 → 노바 남성 → 노바 여성 순서로 제작했다. 내장 ImageGen 30회, 각 행 최대 3회다. 최종 선택 15행 48프레임을 정확한 최근접 4배 판에서 직접 검수했다. 게임·도구 폴더는 수정하지 않았고 Godot은 실행하지 않았다.','', '## 행별 결과','', '얼굴은 **눈 사이 거리 / 눈높이 얼굴 폭**의 앵커 대비 비율이다. Nova 앵커는 반대 눈이 가려져 눈 간격을 측정할 수 없다. 피격 F1·2는 뒤로 기울어진 얼굴이므로 카드의 바로 선 얼굴 수치 판정에서 제외하고, 머리·표정·의상을 4배 육안 비교했다. **이 제외 프레임을 수치 통과로 취급하지 않았다.** 모든 피격의 정량 얼굴 비교는 복귀 F3에 한정된다.','']
for stem,title in [('yuki','유키'),('nova_male','노바 남성'),('nova_female','노바 여성')]:
 lines += ['### '+title,'','| 행 | 프레임 / fps | 공통 배율 | 얼굴 눈 / 폭 (측정 프레임) | 최소 여백 | 디테일 | 전달 |','|---|---:|---:|---|---:|---:|---|']
 for r in summary:
  if r['stem']!=stem:continue
  lines.append(f'| [{r["row"]}]({stem}-{r["row"]}.png) | {r["frames"]} / {r["fps"]} | {r["factor"]:g} | {face_text(r)} | {r["margin"]}px | {r["detail"][0]:.2f}–{r["detail"][1]:.2f} | '+('완료' if r['accepted'] else '**미전달**')+' |')
 lines.append('')
lines += ['## 측정과 육안 판단','', '- **측정:** ART-72의 `process.py`, `face_check.py`, `verify.py`를 복사·수정했다. 기존 정규화기의 LANCZOS / 선명화 60 / despill auto / palette none / 초록 배경을 그대로 썼다. 행마다 배율 하나, 128px 기본 셀·발 y=120, 승리 192px·발 y=152다. 머리를 붙이거나 특징을 코드로 그리지 않았다.', '- **자동 머리 검사:** 기존 `head_scale.py` 알고리즘을 호출했다. Yuki의 흰 소매와 밝은 얼굴 때문에 얼굴 찾기의 피부 임계값만 복사 스크립트에서 넓혔다. 도구 원본은 수정하지 않았다. 신뢰도 0.6 미만은 머리 크기 수치 판정에 쓰지 않았고, 얼굴이 최종 기준이다.', '- **얼굴 표식:** `best/<폼>/<행>/face-proposed.json`은 자동 제안, `face-measured.json`은 검수한 유효 프레임과 제외 사유다. `face-measured-4x.png`에 최종 표식을 남겼다. 노바 남성 승리 F4는 자동 오른쪽 표식이 y88의 코 옆으로 벗어났다. 좌표판·실제 픽셀 경계를 보고 같은 눈 아래 선 y89의 x92.5–106.5로 교정했으며 폭 비율은 0.966이다. 다른 프레임이나 그림 픽셀은 바꾸지 않았다.', '- **육안:** 선택 48프레임의 한 얼굴, 손·부츠·장비, 의상, 효과 없음, 도약/낙하/피격/착지/승리 의미를 직접 확인했다. 기울어진 피격 얼굴의 수치 비교에는 한계가 있으므로 최종 채택은 모션 뷰어에서 판단해야 한다.', '- **재시도:** 한 프레임 재생성은 원본 정사각형 참조 캔버스의 해상도만 되돌린 후 해당 셀 하나를 넣었다. `composition-ledger.json`은 나머지 셀의 픽셀 불변을 확인한다. 프레임별 머리·몸 배율 맞춤은 하지 않았다. 행 전체 배율 시험은 `*-factor-probes.json`에 있으며 추가 이미지 생성 횟수와 구분한다.','', '## ART-72 교훈 확인','', '| 교훈 | 이번 확인 |','|---|---|','| 피격은 실제 타격으로 읽힐 것 | 세 폼 모두 F1 머리·어깨가 뒤로 밀리고 F2 몸이 더 젖혀진 뒤 F3에서 복귀한다. 표정만 바뀌는 대기가 아니다. 육안 판정이다. |','| 상승과 정점을 구분 | 세 폼 모두 F2의 깊은 무릎 접기와 F3의 다리 풀기·팔 벌리기가 다르다. |','| 승리는 연속 동작·소품 손 유지 | 남성 Nova는 어깨 풀기→열린 반대 손바닥에 주먹→주먹 앞으로 유지. Yuki는 3차에서 부적/부채 손 교환을 고쳤으나 얼굴 폭으로 미전달. 여성 Nova는 아래 결함으로 미전달. |','| 얼굴은 머리 전체보다 우선 | 잘못 잡힌 소매·머리카락·코 옆 표식은 그대로 통과시키지 않았다. 가림·기울어짐은 측정 불가/제외로 명시했다. |','', '## 아직 잘못된 점 / 남은 작업','', '- **Yuki fall:** 3차 F1 눈 비율 0.995는 맞지만 얼굴 폭 0.917이 하한 0.95 밖이다. 공통 배율 조정으로 F1 폭을 키우면 F2 눈 간격이 커진다. 3회 생성 종료, 최선 시도만 `best/yuki/fall/`에 보존했다.', '- **Yuki victory:** 3차에서 소품 손 교환과 한 번만 여는 부채 동작은 고쳤다. 그러나 F2·4·6 얼굴 폭 1.083이 후보 상한 1.06을 넘는다. 미전달이다.', '- **Nova female victory:** 1·3차는 올린 주먹의 셀 경계 침범으로 정규화가 실패했다. 정상 추출 가능한 2차는 두 잽이 같은 팔이며 얼굴 폭도 0.931–1.069다. 미전달이다. 경계 침범을 잘라서 숨기지 않았다.', '- **전달 후보의 제한:** 피격 초반 F1·2는 기울어져 정량 얼굴 비율을 확정하지 못했다. 노바는 기준 반대 눈이 가려져 눈 간격을 정량 확인할 수 없다. 남성 Nova 승리의 어깨 풀기 폭은 작다. 모두 실제 재생 박자와 자연스러움은 모션 뷰어에서 확인해야 한다.','', '## 확인 및 다음 권장 단계','', '`verify.py`는 PNG/JSON, 한 공통 배율, 원본 정규화 결과와의 바이트 일치, 테두리·여백·번짐·디테일·발선·프레임 수·fps·유효 얼굴 범위, 생성 상한, 셀 교체 불변, 파일 경로와 커밋 스크립트를 검사한다. 결과는 `audit.json`에 남긴다. PowerShell은 구문만 검사하며 `commit.ps1`을 실행하지 않는다. 게임 플레이·Godot·모션 뷰어 재생 검증은 수행하지 않았다.','', '다음 권장 단계는 전달 12행의 모션 뷰어 채택 검수와 위 미전달 3행의 후속 재제작이다. `commit.ps1`은 이 작업의 명시 파일만 추가하며 raw·캐시·run.log를 포함하지 않는다. 다른 작업의 파일은 추가하지 않는다.','', '## 시각적 확인','', '![노바 남성 승리의 손바닥 타격](qa4x/nova_male-victory-4.png)','', '왼쪽은 기준 대기, 오른쪽은 주먹을 반대 손바닥에 대는 승리 F4다. 그림 픽셀을 최근접 4배로 표시했다.','', '![노바 여성 도약과 상승](qa4x/nova_female-jump-1.png)','', '왼쪽 기준과 오른쪽 F1·2를 같은 4배 배율로 비교했다. 정점 F3까지의 전체 판은 `nova_female-jump.png`에 있다.','']
(root/'README.md').write_text('\n'.join(lines),encoding='utf-8')
# Explicit allowlist; omit duplicated intermediate review sheets and all scratch logs.
files=[]
for r in summary:
 if r['accepted']:files += [r['candidate'],str(Path(r['candidate']).with_suffix('.json')).replace('\\','/')]
# Root files intentionally selected, including future audit and script themselves.
for p in root.iterdir():
 if not p.is_file():continue
 if p.suffix in ['.py','.json','.txt'] and p.name not in ['run.log'] or p.name=='README.md':files.append(p.as_posix())
for p in (root/'best').rglob('*'):
 if p.is_file() and p.name not in ['review4x.png','faces4x.png']:files.append(p.as_posix())
for p in (root/'qa4x').glob('*.png'):files.append(p.as_posix())
for r in summary:files.append((root/f'{r["stem"]}-{r["row"]}.png').as_posix())
for rel in ['best/nova_male/victory/manual-pair-f4.png','best/yuki/fall/manual-pair-f1.png']:
 import shutil
 s=Path(rel).parts;stem,row=s[1],s[2];a=next(r['attempt'] for r in summary if r['stem']==stem and r['row']==row);src=root/stem/row/f'attempt-{a}'/s[3];dst=root/rel;shutil.copy2(src,dst);files.append(dst.as_posix())
files += [(root/x).as_posix() for x in ['commit.ps1','audit.json','files-to-stage.json']]
files=sorted(set(files));assert all(not f.startswith('art/raw/') and '__pycache__' not in f and not f.endswith('run.log') for f in files)
write(root/'files-to-stage.json',files)
script="$ErrorActionPreference = 'Stop'\nSet-StrictMode -Version Latest\n$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\\..'))\n$branch = (& git -C $repo branch --show-current).Trim()\nif ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-75') { throw 'Expected codex/art-75 in this clone.' }\n$files = @(\n"+'\n'.join("    '"+f.replace("'","''")+"'" for f in files)+"\n)\n$staged = @(& git -C $repo diff --cached --name-only)\nif ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged files.' }\nforeach ($path in $staged) { if ($path -and $path -notin $files) { throw \"Unrelated staged file: $path\" } }\nforeach ($path in $files) { if (-not (Test-Path -LiteralPath (Join-Path $repo $path) -PathType Leaf)) { throw \"Missing file: $path\" } }\n& git -C $repo add -- $files\nif ($LASTEXITCODE -ne 0) { throw 'git add failed.' }\n$message = @'\nAdd ART-75 motion candidates for Yuki and Nova bodies\n\nDeliver 12 rows (34 frames) and document three held rows with measurements.\n\nCo-Authored-By: Codex <noreply@openai.com>\n'@\n& git -C $repo commit -m $message\nif ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }\n"
(root/'commit.ps1').write_text(script,encoding='utf-8');print(len(files),'explicit stage paths; commit script NOT executed')
