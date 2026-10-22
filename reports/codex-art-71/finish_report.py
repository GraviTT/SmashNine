import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, statistics, subprocess
from pathlib import Path
from PIL import Image
import process as p

IDS=['mossling','ember_imp','asgard_aegis_ram','asgard_runic_raven','alfheim_moon_stag','alfheim_moon_moth']
attack={'mossling':'앞으로 짧게 뻗으며 턱을 여닫는 물기. 전진 폭은 작음.','ember_imp':'손을 뒤로 당겼다가 앞으로 내미는 직사 시전. 빛은 손에 붙어 있고 투사체는 없음.','asgard_aegis_ram':'몸을 앞으로 낮춘 달리기 돌진 반복. 후반 세 장에 체공 구간이 있음.','asgard_runic_raven':'날개를 뒤로 접고 오른쪽 아래로 향하는 급강하 반복.','alfheim_moon_stag':'웅크림 → 이륙 → 공중 정점 → 하강 → 앞발 착지 → 착지 압축.','alfheim_moon_moth':'몸 축소 → 작은 몸 → 몸이 된 반짝임 묶음 → 재형성. 알파 페이드 없이 그린 동작.'}
for mid in IDS:
    for row in p.ROWS:
        path=p.BAKE/f'{mid}-{row}-v1.json';m=json.loads(path.read_text('utf-8'))
        if row=='idle':m['note']=('두 번째 생성안을 기준으로 고른 대기. 큰 구형 머리와 짧은 날개 비율을 유지.' if mid=='alfheim_moon_moth' else '첫 생성안을 기준으로 고른 대기. 원본의 색·주요 특징을 유지.')
        elif row=='attack':m['note']=attack[mid]
        elif row=='windup':m['note']=f'새 준비 행. {p.WINDUP[mid]:g}초 동안 네 장을 재생하고 마지막 자세 유지.'
        elif row=='walk':m['note']='날갯짓 이동 반복.' if mid in ['asgard_runic_raven','alfheim_moon_moth'] else '여섯 장 보행 반복. 좌우 발 교대의 선명도는 비교판에서 확인 필요.'
        elif row=='hurt':m['note']='충격 반동과 낮은 회복 자세 두 장.'
        else:m['note']='새 쓰러짐 행. 네 번째 그림은 바닥에 누운 자세.'
        path.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n','utf-8')
        mp=p.REPORT/mid/row/'metrics.json';metrics=json.loads(mp.read_text('utf-8'))
        raw=p.ROOT/f'art/raw/monsters-71/{mid}-{row}.png'
        metrics['source_dimensions']=list(Image.open(raw).size)
        metrics['generation_attempts']=len(list(raw.parent.glob(f'{mid}-{row}*.png')))
        mp.write_text(json.dumps(metrics,ensure_ascii=False,indent=2),'utf-8')

tables=(p.REPORT/'tables.md').read_text('utf-8')
readme='''# CODEX-ART-71 — 몬스터 1차 6종 후보

36개 행·168프레임, 576×576 조립 시트 6장을 전달한다. **후보 전달이며 사용자 채택·게임 적용은 아니다.** `smash-nine-prototype/`은 변경하지 않았다. 생성은 내장 ImageGen만 사용했고 패키지 설치·다운로드·Godot 실행은 하지 않았다.

## 시각적 확인

![기존/후보 및 준비 자세](overview.png)

각 열 위쪽은 기존/후보 대기를 같은 1배로 비교한다. 아래쪽은 새 준비 행 두 번째 그림을 1.5배로 보여준다. 전체 동작은 `<id>.png`(1배+4배), `<id>-1x.png`, `<id>-4x.png`에 있다. 각 행 폴더의 `anchor-4x.png`는 선택한 대기 첫 장과 그 행을 정확히 4배로 나란히 보여준다.

## 선택한 기준 대기 — 육안 판단

| 몬스터 | 선택 | 이유 |
|---|---|---|
| mossling | 첫 안 | 낮은 나무 몸·잎·새싹·눈과 차가운 테두리가 유지되고 나무결이 읽힘 |
| ember_imp | 첫 안 | 붉은 몸·뿔·꼬리·보라 음영이 유지됨. 원본보다 얼굴이 둥글고 어린 용 느낌은 남음 |
| asgard_aegis_ram | 첫 안 | 남색 털·금색 말린 뿔·어깨 룬이 선명함 |
| asgard_runic_raven | 첫 안 | 금색 부리·어깨 원판과 청색 깃털 층이 잘 분리됨 |
| alfheim_moon_stag | 첫 안 | 초승달 뿔·옆구리 달무늬·푸른 털 정체성을 유지함 |
| alfheim_moon_moth | 두 번째 안 | 첫 안은 날개에 비해 머리가 작았음. 두 번째 안의 큰 무표정 구형 머리와 짧은 날개 비율을 선택 |

## 작업 방법과 크기 판단

- 카드 순서대로 한 종의 대기를 고른 뒤 나머지 행을 생성했다. 대기 생성에는 현재 시트를 정체성 참조로, Frey 대기는 밀도 참조로 전달했다. 나머지 행에는 선택한 대기가 Image 1, 현재 시트가 Image 2다.
- 동작마다 한 장 생성, 행 전체 공통 배율, 기존 `normalize.py`의 LANCZOS·선명화 60·despill auto·팔레트 없음·초록 키를 사용했다. 몸 조각 붙이기·프레임별 확대/축소·팔레트 교체는 하지 않았다. 실제 원본 크기는 요청한 512칸에서 벗어나는 경우가 있어 각 `metrics.json`의 `source_dimensions`에 남겼다.
- 비행형은 발 대신 기존 몸통의 안정된 특징(까마귀 어깨 원판, 나방 구형 머리)을 기준으로 **프레임 전체만 평행 이동**했다. 원판 중심은 (49,50), 나방 머리 중심은 (62,50) 부근이다. 배율은 여전히 행당 하나다. 이동량은 `body_alignment`에 기록했다.
- 사슴 도약의 지상 접촉 그림 1·5·6번만 통째로 내려 발 y=72에 맞췄다. 공중 3·4번은 발끝 y=52·53을 유지한다. `ground_contacts`에 이동량을 기록했다.
- 머리/몸통 크기는 4배 비교판의 육안 판단으로 배율을 골랐다. 나방은 밝은 머리 영역도 직접 측정했다(`orb_measurement`: R>190, G>170, B>210의 가장 큰 연결 성분). 대기 밝은 머리 폭 16.56–17.28px, 이동 16.73–17.48px, 준비 중앙값 약 17.09px, 순간이동 정상 크기 첫/끝 17.01·17.20px다. 준비 두 번째는 15.47px로 조금 작다. 나머지 종에 자동 머리 비율 검사를 했다고 주장하지 않는다.
- 생성은 총 41회. Mossling 공격, 까마귀 이동/공격, 나방 대기/준비는 두 번 생성했고 그 밖은 한 번이다. 행당 최대 3회 상한 안이다. 제외한 첫 안도 `art/raw/monsters-71/`에 보존했다. 원본은 커밋 대상에서 제외한다.

## 측정 결과

최종 36행 전부: 테두리 비움, 최소 여백 3px 이상, 초록 번짐 0, 알파 0/255만 사용, 사용하지 않는 셀 투명, 중복 프레임 없음. 조립 시트 각 행은 납품 행과 픽셀 단위로 같다. 걸어 다니는 종의 지상 접촉 발선과 마지막 쓰러짐은 y=72다. 세부 근거는 `verification.json` 및 각 행 `metrics.json`의 **`final_summary`·`audit96`**다. 정규화 최초 `summary`는 평행 이동 전 수치일 수 있다.

디테일은 ART-61과 같은 내부 명암 라플라시안 지표다. 참조 Frey 대기 평균은 **96.31**이다. 수치는 형태에 따라 달라지며 보기 좋은지 자체를 증명하지 않는다. Imp와 숫양의 낮은 행은 그대로 공개한다.

{tables}

## 뷰어와 확인

`tools/motion_viewer/build.mjs`에 몬스터 행별 후보와 신규 `windup`·`defeat`를 추가했다. 표시 순서는 idle→walk→windup→attack→hurt→defeat이며 기존 시트의 실제 행 번호는 유지한다. 후보 메타데이터의 loop를 출력 뷰어에 전달해 숫양 돌진·까마귀 급강하 후보만 반복 재생할 수 있게 했다. 카드에서 쓰기 허용한 build.mjs만 수정했으며 index.html 템플릿은 수정하지 않았다.

- `verify.py`: 6종·36행·168프레임, failures=[].
- `node tools/motion_viewer/build.mjs`: 빌드 성공. 전체 기존 후보를 포함해 49개, 이번 몬스터 후보는 36개.
- `node reports/codex-art-71/verify_viewer.mjs`: 후보 36개, 새 행 12개, 기존 인덱스 유지, 반복 설정, 모든 복사 파일 존재 확인.
- `git diff --quiet -- smash-nine-prototype`: 제품 추적 파일 차이 없음.
- 실제 Godot 실행·브라우저 재생·외부 Artifact 재게시 검증은 하지 않았다. 로컬 dist는 git-ignored다.

첫 일괄 검사에서 나방 쓰러짐의 공통 x 이동 뒤 조립본이 예전 그림인 점을 검출했고 다시 조립했다. 최종 검사는 그 수정 후 통과한 결과다.

## 아직 잘못되거나 약한 점 — 육안 판단과 측정 구분

- **디테일:** Imp 대기 72.40–76.21, 숫양 대기 71.53–76.37은 Frey 평균 96.31보다 낮다(측정). 두 종은 넓은 색 면이 남아 다른 네 종보다 덜 촘촘하게 보인다(판단). 새 캐릭터와 완전히 같은 밀도에 도달했다고 보고하지 않는다.
- **보행:** 특히 Imp와 Mossling은 발을 드는 차이는 있으나 좌우 교대가 강하게 읽히지 않는다(판단). 기존 ART-59의 8장 사람 걷기 검사를 이 6장 몬스터 행에 통과했다고 주장하지 않는다.
- **물기:** Mossling은 턱 여닫기는 분명하지만 앞으로 뻗는 폭이 작다(판단).
- **숫양 돌진:** 뒤 세 장의 발끝이 y=63·66·65로 떠 있다(측정). 반복 접점에서 착지가 튀는지 뷰어 재생으로 확인할 부분이다(판단).
- **나방:** 대기·이동 일부 자세는 한쪽 촉수 끝 보석이 약하게 읽힌다(판단). 준비 두 번째 머리는 기준 대비 약 10% 작다(측정 기준은 밝은 영역 폭). 순간이동의 작은 몸과 반짝임은 카드가 요청한 의도적인 크기 변화다.

## 남은 작업과 인계

이 카드에서 미착수한 몬스터/행은 없다. 다만 위 시각 품질 보완, 사용자 후보 선택, 실제 모션 재생 판단이 남는다. 게임 행 추가·연결 및 Artifact 재게시는 후속 담당 범위다. `commit.ps1`은 작성만 했고 **실행·스테이징·커밋하지 않았다**. 이 스크립트는 `delivery-files.txt`의 이번 파일만 대상으로 하며 raw·제품 파일·기존 run.log·캐시를 포함하지 않는다. 정확한 생성 프롬프트 41개는 `prompts.txt`에 있다.
'''.replace('{tables}',tables)
(p.REPORT/'README.md').write_text(readme,'utf-8')

def git(*args):
    result=subprocess.run(['git',*args],cwd=p.ROOT,capture_output=True,text=True,encoding='utf-8')
    return dict(exit_code=result.returncode,output=result.stdout.strip(),stderr=result.stderr.strip())
checks=dict(branch=git('branch','--show-current'),tracked_changes=git('diff','--name-only'),product_changes=git('diff','--name-only','--','smash-nine-prototype'),staged_changes=git('diff','--cached','--name-only'),whitespace=git('diff','--check'),raw_ignored=git('check-ignore','art/raw/monsters-71/mossling-idle.png'),dist_ignored=git('check-ignore','tools/motion_viewer/dist/index.html'))
assert checks['branch']['output']=='codex/art-71'
assert checks['product_changes']['output']=='' and checks['staged_changes']['output']==''
assert checks['tracked_changes']['output']=='tools/motion_viewer/build.mjs'
assert checks['whitespace']['exit_code']==0 and checks['raw_ignored']['exit_code']==0 and checks['dist_ignored']['exit_code']==0
prompts=(p.REPORT/'prompts.txt').read_text('utf-8')
assert prompts.count('=== ')==41 and '${p}' not in prompts and len(prompts)>60000
checks.update(prompt_count=41,raw_png_count=len(list((p.ROOT/'art/raw/monsters-71').glob('*.png'))),commit_script_executed=False)
(p.REPORT/'handoff-checks.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2),'utf-8')

files=['tools/motion_viewer/build.mjs']
for mid in IDS:
    for row in p.ROWS:
        for ext in ['png','json']:files.append(f'art/bakeoff/monsters/{mid}-{row}-v1.{ext}')
    files.append(f'art/bakeoff/monsters/{mid}_sheet-v1.png')
for file in p.REPORT.rglob('*'):
    if file.is_file() and file.name!='run.log' and '__pycache__' not in file.parts:files.append(file.relative_to(p.ROOT).as_posix())
files.append('reports/codex-art-71/delivery-files.txt')
files=sorted(set(files))
(p.REPORT/'delivery-files.txt').write_text('\n'.join(files)+'\n','utf-8')
print('Report and explicit delivery manifest:',len(files),'files')
