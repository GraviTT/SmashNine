"""Write the Korean handoff and an explicit, nonexecuted commit script."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, subprocess
from pathlib import Path
import review as r

FIX=r.FIX
data=json.loads((FIX/'sizes.json').read_text('utf-8'))
v=json.loads((FIX/'verification.json').read_text('utf-8'))
changed=[x for rows in data.values() for x in rows if x['changed']]
NOTES={
('mossling','walk'):'6장 확인. 잎·새싹·얼굴·뿌리 발 잘림 없음. 발 교대는 여전히 약하고, F3은 앞발이 앞으로 모여 보임.',
('ember_imp','defeat'):'4장 확인. 뿔·꼬리와 쓰러지는 실루엣 보존. 마지막 접지 y72. 넓은 붉은 면과 어린 용 같은 얼굴은 남음.',
('asgard_aegis_ram','idle'):'6장 확인. 뿔·등 가시·룬 보존. 주뿔 기준은 맞지만 몸통의 길이·털 비율까지 다른 행과 동일해진 것은 아님.',
('asgard_aegis_ram','attack'):'6장 확인. 후반 3장의 가장 낮은 발을 y72로 내림. 달리기 중 들린 나머지 발은 유지. 실제 반복의 자연스러움은 재생 미확인.',
('asgard_aegis_ram','hurt'):'2장 확인. 반동과 회복 자세 유지, 뿔 잘림 없음. F1은 몸을 세워 같은 높이로 보이지 않는 자세임.',
('asgard_runic_raven','windup'):'4장 확인. 날개 끝과 어깨 원판 보존. F2는 커진 날개 위쪽 여백을 확보하려 프레임 전체를 4px 내림. 중심 높이 편차는 남음.',
('asgard_runic_raven','attack'):'6장 확인. 급강하 실루엣과 부리·발 보존. 마지막에서 첫 장으로 이어지는 재생은 미확인.',
('asgard_runic_raven','hurt'):'2장 확인. 아래로 편 날개와 어깨 원판 보존. F1의 날개 끝이 발보다 낮은 것은 원래 자세임.',
('alfheim_moon_stag','windup'):'4장 확인. 뿔·귀·달무늬와 준비 자세 보존. 몸통 축 길이를 기준으로 줄였으며 머리·목 비율 차이는 남음.',
('alfheim_moon_stag','defeat'):'4장 확인. 뿔·발 잘림 없이 접지 y72. 쓰러지며 목이 접히는 원본 자세와 체형 변화는 유지.',
('alfheim_moon_moth','attack'):'6장 확인. 정상 크기 → 축소 → 반짝임 → 재형성 유지. 크기 검사는 F1·F6만 사용. 촉수 끝 보석의 약한 가독성은 남음.',
}
review=[]
for x in changed:
 review.append(dict(monster=x['monster'],row=x['row'],frames=r.COUNTS[x['row']],scale=4,method='nearest-neighbour 4x PNG, every changed frame visually inspected by Codex',board=f"{x['monster']}-{x['row']}-after-all-4x.png",judgment=NOTES[x['monster'],x['row']]))
(FIX/'visual-review.json').write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n','utf-8')
table=['| 몬스터 | 행(F) | 측정 부위 | 전 px | 전/idle | 후 px | 후/idle | factor 전 → 후 |','|---|---|---|---:|---:|---:|---:|---|']
for mid,items in data.items():
 for x in items:
  table.append(f"| {mid} | {x['row']} F{x['frame']} | {x['part']} | {x['before']['size']:.2f} | {x['before_ratio']:.3f} | {x['after']['size']:.2f} | {x['after_ratio']:.3f} | {x['before_factor']:.8g} → {x['after_factor']:.8g} |")
  if 'last_frame' in x:
   a=x['last_frame'];table.append(f"| {mid} | attack F6 | {x['part']} | {a['before']['size']:.2f} | {a['before_ratio']:.3f} | {a['after']['size']:.2f} | {a['after_ratio']:.3f} | 동일 행 배율 |")
(FIX/'size-table.md').write_text('\n'.join(table)+'\n','utf-8')
body='''# CODEX-ART-71 fix-1 — 몬스터 1차 행 크기 맞춤

## 완료 / 현재 상태

6종 36행을 측정하고 **11행(배율 변경 10행 + 숫양 돌진 접지 1행)**과 조립 시트 6장을 갱신했다. 변경한 모든 행은 채택 당시 raw에서 다시 만들었다. 후보만 변경했으며 게임 적용·사용자 채택은 아니다. 원본 누락 0행.

표에 지정한 대표 프레임의 안정 부위는 최종 idle 대비 **0.957–1.050**이다. 나방 attack은 F1·F6만 측정했고 0.973·0.982다. **이 범위는 지정된 대표 부위의 명목 측정값이며, 모든 프레임의 해부학적 크기를 보장하지 않는다.** 행 내부 편차와 수동 경계의 한계는 아래에 공개한다.

## 방법 — 측정과 판단 구분

- ART-74의 `fix_pass.py`와 `review_evidence.py` 방식을 재사용했다. 한 행에 배율 하나, 기존 normalizer의 LANCZOS + 선명화 60 + despill auto + 팔레트 없음. 도구 파일은 읽기만 했다. 프레임별 배율·조각 붙이기·추가 생성·설치·다운로드 없음.
- Mossling 윗얼굴 폭, Imp 두개골 폭, 사슴 몸통의 엉덩이–어깨 중심 거리는 4배 눈금판에서 **수동 경계/기준점**을 지정했다. 수동 위치 불확실성은 약 ±1px이다. 후 값은 같은 경계/점을 원본의 행 배율과 실제 출력 bbox 이동으로 추적한 값이며 독립된 자동 해부학 측정이 아니다. 사슴은 자세에 따라 돌아가는 머리 대신 몸통 축을 썼다. 사슴 attack은 측면 몸통이 읽히는 F6, hurt는 F1을 썼고, 다른 두 종의 hurt는 F2다.
- 숫양은 금색 주뿔 연결 영역의 높이, 까마귀는 어깨 금색 원판 연결 영역의 폭을 출력 픽셀에서 전후 다시 측정했다. 금색 조건은 `R>110, G>65, R>1.6B, G>1.4B`다. 자세·조명·무늬 때문에 실제 해부학 경계와 차이가 있을 수 있다.
- 나방은 기존 밝은 머리 조건 `R>190, G>170, B>210`의 가장 큰 4-연결 성분을 사용했다. 16/17px 같은 1px 폭 계단을 피하려 ART-74의 후드 측정처럼 **√면적**을 등가 선형크기로 썼다. 실제 머리 지름이라는 뜻은 아니다. 순간이동의 F2–F5는 크기 판정에서 제외했다.
- 256px 작업 캔버스에서 raw를 줄이고 그림 전체만 96px 셀에 옮겼다. 불투명 픽셀 수 보존을 검사해 잘라 넣지 않았음을 확인했다. raw 해시, factor, 전체 이동량은 `baseline-hashes.json`·`sizes.json`에 있다.
- 숫양 돌진을 idle의 예전 뿔 높이 18px까지 키우면 후반 그림이 90px 가용 폭을 넘는다. 따라서 **idle factor 0.19 → 0.17, 주뿔 18 → 16px**로 기준을 낮췄고, 다른 행을 그 기준에 맞췄다. 변경하지 않은 walk/windup/defeat도 새 idle 대비 비율은 0.889 → 1.000이다.

## 측정표

전 비율은 예전 idle, 후 비율은 최종 idle에 각각 나눈 값이다. 전후 경계·기준점과 소수 원값은 [sizes.json](sizes.json)에 있다.

'''+ '\n'.join(table)+'''

## 숫양 발

돌진 발끝은 **[72,72,72,63,66,65] → [72,72,72,72,72,72]**다. 배율 0.21은 유지하고 행의 접지 옵션을 사용해 프레임 전체를 [0,0,0,+9,+6,+7]px 아래로 옮겼다. 발/몸의 조각 수정은 하지 않았다. 가장 낮은 발을 기준선에 놓은 것이며, 달리기에서 들어 올린 나머지 발은 그대로다.

![숫양 돌진 접지 전후 4배](ram-feet-before-after-4x.png)

위는 이전, 아래는 수정 후 F4–F6이다. 붉은 가로선은 y72이며, 후반 발끝이 이 선에 닿는다.

## 시각적 확인

변경 11행 **50프레임 전부**를 최근접 4배로 직접 확인했다. 각 행의 변경 전/후 모든 프레임은 `<id>-<row>-{before,after}-all-4x.png`에 있다. [visual-review.json](visual-review.json)은 행마다 확인한 내용과 남은 판단을 구분한다. 실제 모션 재생은 하지 않았다.

'''
for mid in r.IDS:
 body+=f'### {mid}\n\n![행 크기 전후 4배]({mid}-size-before-after-4x.png)\n\n각 세 열에서 위가 전, 아래가 후다. 분홍 상자/선은 같은 측정 부위이며, 캡션은 크기와 해당 idle 대비 비율이다.\n\n'
body+='''## 확인 및 테스트 — 측정 결과

- `review.py verify`: **6종·36행·168프레임**, 규격 실패 0. 변경한 11행의 모든 프레임 4배 육안 검토 기록을 별도로 남겼다.
- 최종 행 576×96, 조립본 576×576, 최소 여백 3px 이상, alpha 0/255, 초록 번짐 0, 빈 셀 투명, 동일 행 중복 프레임 0, 조립본과 행 PNG 픽셀 일치.
- 지정 대표 크기 36행 + 나방 끝 프레임의 ±5% 검사 통과. 배율은 행마다 하나. fps·loop·프레임 수 등 재생 메타데이터 보존. 변경하지 않은 25행 PNG/JSON은 이전과 해시 일치.
- raw 36개 해시 보존. 제품/도구 추적 파일 변경 0, 스테이징 0. Python은 지정 런타임과 `-B`, `PYTHONDONTWRITEBYTECODE=1`을 썼다. Godot 실행, 뷰어 빌드/재게시, 커밋 스크립트 실행은 하지 않았다.

## 남은 작업 / 약한 점

**측정 한계:** 표의 수동 부위는 약 ±1px 경계 불확실성이 있다. 몸통 축·두개골·금색 무늬라는 부위별 지표가 같아졌다고 전체 체형까지 같아진 것은 아니다. 표의 36행 통과는 대표 프레임 기준이다.

**추가 측정:** 나방 windup F2의 밝은 머리 √면적 비율은 최종 idle F1 대비 **0.896**이다. 같은 행 F1은 1.009라서 행 공통 배율만으로 두 장을 모두 ±5% 안에 넣을 수 없다(필요 배율 구간이 겹치지 않음). 나방 defeat F2/F3/F4의 같은 밝은 면적 지표는 **0.948/0.891/0.915**이며, 쓰러지면서 밝은 면의 모양/가림도 변한다. 이들을 프레임별 확대하거나 새로 그리지 않았다. 이 편차까지 고치는 것은 후속 원본 재작화 대상이다.

**육안 판단:** Mossling·Imp 발 교대는 약하고 Mossling 물기의 전진 폭도 작다. Imp·숫양은 넓은 색 면이 남는다. 사슴은 같은 몸통 길이여도 머리/목의 비율 차이가 남는다. 나방 촉수 보석 가독성과 행 내부 머리 편차도 남는다. 까마귀 windup F2는 위쪽 날개 여백 때문에 전체를 4px 내려서 몸 중심 높이가 다른 장과 조금 다르다. 이 편차와 숫양의 실제 달리기 반복 접점은 재생 확인이 필요하다.

## 다음 권장 단계 / 인계

QA-22가 다른 클론에서 게임을 확인하고, 사용자가 모션 뷰어에서 행 전환·반복을 판단한다. 행 내부 체형 보완이 필요하면 해당 raw를 다시 그리는 별도 작업으로 진행한다. 이 카드에서 게임·tools 변경은 하지 않았다.

[commit.ps1](commit.ps1)은 **작성만 했으며 실행하지 않았다.** [delivery-files.txt](delivery-files.txt)의 이번 파일만 대상으로 하고, raw·기존 run.log·캐시·제품·tools는 제외한다. 작업 전부터 있던 빈 `run.log`는 손대지 않았다. 이미 다른 파일이 스테이징돼 있으면 스크립트가 멈추게 했다.

재현: 지정 Python에 `-B`를 붙여 `review.py rebuild`, `review.py evidence`, `review.py verify`, `report.py` 순서로 실행한다. `before/`는 수정 전 자료이며 덮어쓰지 않는다.
'''
(FIX/'README.md').write_text(body,'utf-8')

# Only explicitly named new evidence goes into the manifest. Intermediate probes,
# preexisting logs, raw inputs and unrelated report files never get staged.
files=[]
for x in changed:
 for ext in ['png','json']:files.append(r.BAKE/f"{x['monster']}-{x['row']}-v1.{ext}")
 for side in ['before','after']:files.append(FIX/f"{x['monster']}-{x['row']}-{side}-all-4x.png")
for mid in r.IDS:
 files.extend([r.BAKE/f'{mid}_sheet-v1.png',FIX/f'{mid}-size-before-after-4x.png'])
files.extend(sorted(r.OLD.glob('*')))
files.extend(FIX/name for name in ['review.py','report.py','README.md','size-table.md','sizes.json','baseline-hashes.json','verification.json','visual-review.json','handoff-check.json','ram-feet-before-after-4x.png','overview-2x.png','commit.ps1','delivery-files.txt'])
paths=sorted(set(p.relative_to(r.ROOT).as_posix() for p in files))
(FIX/'delivery-files.txt').write_text('\n'.join(paths)+'\n','utf-8')
(FIX/'commit.ps1').write_text(r'''# Written by Codex; deliberately not executed.
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
Set-Location -LiteralPath $repoRoot
if ((git branch --show-current) -ne 'codex/art-71-fix-1') { throw 'Wrong branch' }
$paths = @(Get-Content -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'delivery-files.txt'))
foreach ($path in $paths) {
    if ($path -match '(^|/)(art/raw|__pycache__)(/|$)|(^|/)run\.log$|(^|/)\.\.?(/|$)') { throw "Excluded path: $path" }
    $candidate = $path -match '^art/bakeoff/monsters/(mossling|ember_imp|asgard_aegis_ram|asgard_runic_raven|alfheim_moon_stag|alfheim_moon_moth)(-.*-v1\.(png|json)|_sheet-v1\.png)$'
    $report = $path.StartsWith('reports/codex-art-71/fix-1/')
    if (-not ($candidate -or $report)) { throw "Outside card: $path" }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing file: $path" }
}
$staged = @(git diff --cached --name-only)
if ($staged.Count -gt 0) { throw 'Index is not empty; review it first. No staging was done.' }
for ($i = 0; $i -lt $paths.Count; $i += 40) {
    $last = [Math]::Min($i + 39, $paths.Count - 1)
    git add -- $paths[$i..$last]
    if ($LASTEXITCODE -ne 0) { throw 'git add failed (no force add was used)' }
}
git commit -m 'art: align batch-1 monster row sizes and ram charge feet' -m 'Co-Authored-By: Codex <noreply@openai.com>'
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
''','utf-8')

diff=subprocess.check_output(['git','diff','--name-only'],cwd=r.ROOT,text=True).splitlines()
staged=subprocess.check_output(['git','diff','--cached','--name-only'],cwd=r.ROOT,text=True).splitlines()
assert all(x in paths for x in diff),diff
assert not staged,staged
assert all('art/raw/' not in p and '__pycache__' not in p and not p.endswith('/run.log') for p in paths)
assert all((r.ROOT/p).is_file() for p in paths if not p.endswith('/handoff-check.json'))
ignored=subprocess.run(['git','check-ignore','--stdin'],input='\n'.join(paths)+'\n',cwd=r.ROOT,text=True,capture_output=True)
assert ignored.returncode in [0,1] and not ignored.stdout,ignored.stdout
check=dict(branch=subprocess.check_output(['git','branch','--show-current'],cwd=r.ROOT,text=True).strip(),tracked_changes=diff,staged_files=staged,manifest_files=len(paths),ignored_manifest_files=[],outside_card_changes=[],product_or_tools_changes=[],raw_not_in_manifest=True,preexisting_run_log_excluded=True,commit_script_executed=False)
(FIX/'handoff-check.json').write_text(json.dumps(check,indent=2)+'\n','utf-8')
print('REPORT / MANIFEST',len(paths),'files;',len(diff),'tracked candidate changes; index empty')
