# CODEX-VFX-11 · 리오 키트 v3 이펙트 후보

**완료:** 카드 순서의 이펙트 전 항목 A/B, 아이콘 5개. 미도달 항목 없음.
이펙트 12개 PNG 스트립(총 62프레임)과 아이콘 5개, 각각의 JSON을 만들었다.
후보만 작성했으며 `smash-nine-prototype/`는 수정하지 않았다. 커밋도 실행하지 않았다.

- [전체 비교 보드](board.png): A 왼쪽, B 오른쪽. 어두운/밝은 배경에 실제 시트를 합성했다.
- [재생기](preview.html): 파일을 브라우저에서 열기. 외부 연결·서버·패키지 설치 불필요. 정속/느리게, 정지/프레임 이동, 남·여 리오, 배경, 앵커 확인.
- [아이콘 1×/4×](icons-board.png), [원본 스트립 전체](strips-board.png).
- 각 `<이름>-<a|b>-board.png`는 모든 프레임을 1×/4×로 보여 준다. 마검은 `-flying-`, 대기는 `-body-`/`-wall-`/`-air-` 보드로 나눴다.

## 후보의 차이와 제작 방법

| 카드 순서 | A | B | 방법 |
|---|---|---|---|
| 마검 · 비행/대기 | 가는 은색 날과 직선 잔상, 작은 룬 맥동 | 넓은 결정 날과 두 갈래 가드, 쐐기 잔상과 교대 불빛 | Pillow로 원래 해상도에서 직접 그림 |
| 급소 X | 짧고 대칭인 교차 베기 | 비대칭 교차 베기와 양옆 조각 | Pillow로 직접 그림 |
| 그림자 이동 | 안으로 말려 닫히는 그림자 리본 | 바깥으로 찢어지는 각진 그림자 조각 | 내장 image_gen, 참조 파일 3개 직접 전달 |
| 받아치기 | 육각선 아래 흐르는 낮은 그림자 불꽃 | 육각 꼭짓점 결정의 순환 불빛 | image_gen + 고정 1픽셀 육각선 보완 |
| 분신 폭발 | 가는 유리 조각과 얇은 청록 고리 | 굵은 유리 쐐기와 끊어진 청록 고리 | 내장 image_gen |
| 아이콘 J/K/L/U/I | 관통 / 던진 검과 순간이동 / 그림자 반격 / 분신 교환 / 안쪽을 향한 검 6개 | 한 세트 | Pillow, 40×40 직접 그림 |

생성 원화는 `art/raw/vfx-11/`의 6개 PNG다(커밋 제외). 정확한 프롬프트·참조 경로·생성 전후 시각은 [prompts.txt](prompts.txt), [generation_log.json](generation_log.json)에 있다.
원화 512×512 셀을 프레임마다 같은 좌표 변환으로 **축소만** 했다. 프레임별 크기 맞춤은 하지 않았다. 최근접 샘플링, 알파 임계값 128, 리오 10색 팔레트를 적용했다. 받아치기의 흐린 육각선은 축소 후 고정 선으로 보완했다. 상세 좌표는 [normalization.json](normalization.json).

## 측정한 결과

| 파일 이름 공통부 | 셀 / 프레임 | 전체 PNG | fps / 한 주기 | 앵커 | 반복 / 합성 |
|---|---|---|---|---|---|
| `rio_mana_sword` | 96×32 / 4 | 384×32 | 20 / 0.200초 | 48,16 | 반복 / normal |
| `rio_mana_sword_stuck` | 96×32 / 4 | 384×32 | 8 / 0.500초 | 48,16 | 반복 / normal |
| `rio_backstab` | 96×96 / 5 | 480×96 | 36 / 0.139초 | 48,48 | 단발 / additive |
| `rio_shadow_blink` | 128×160 / 6 | 768×160 | 30 / 0.200초 | 64,144 | 단발 / normal |
| `rio_counter_stance` | 192×192 / 6 | 1152×192 | 15 / 0.400초 | 96,152 | 반복 / normal |
| `rio_decoy_burst` | 160×160 / 6 | 960×160 | 30 / 0.200초 | 80,80 | 단발 / additive |
| `rio_j/k/l/u/i` | 40×40 / 1 | 40×40 | 정지 | 20,20 | 반복 안 함 / normal |

- 17개 파일 모두 RGBA, 알파 값 `{0,255}`, 모든 프레임의 1픽셀 테두리 불투명 픽셀 **0개**. JSON 규격 검사 통과.
- 비행·대기 마검의 같은 프레임에서 검 본체 픽셀은 **4/4 동일**(A/B 각각). 바뀌는 것은 잔상과 룬이다.
- 급소 X의 모든 그림을 합친 범위는 A **37×29**, B **59×29**. 프레이 얼굴 검사 사각형과의 겹침 **0픽셀**, 각각 5/5. 다른 인물의 모든 동작까지 검사했다는 뜻은 아니다.
- 받아치기 보완 육각선의 꼭짓점 범위 **84×96**, 중심 **(96,102)**. 발 앵커보다 50px 위다. 주변 불꽃/결정은 이보다 넓다.
- 분신 폭발 전체 프레임의 불투명 픽셀 중 몸 중심보다 위에 있는 비율: A **91.3%**, B **93.3%**. 이는 그림의 분포이며 타격 판정이나 파편 속도 측정이 아니다.
- 색·프레임별 범위·픽셀 수·해시는 [measurements.json](measurements.json), 검사 결과는 [validation.txt](validation.txt).
- 재생기 JavaScript 구문 검사와 `commit.ps1`의 PowerShell 구문 검사는 통과했다. 로컬 Chrome 자동 캡처는 45초 제한으로 끝났으므로 브라우저 조작 검증은 완료하지 못했다([preview-check.json](preview-check.json)).

## 합성 보드의 기준과 확인 한계

실제 `rio_male_sheet.png`, `rio_female_sheet.png`, `frey_sheet.png`의 첫 idle을 1:1로 썼다. 발은 128셀의 `(64,120)`이다. 마검 비행은 기존 임시 K 자세인 `rio_male_moves_sheet.png`의 `dimension_slash` 3번째 그림, 발 `(96,152)`를 썼다. 기존 검의 앞에서 이미 날아가는 순간을 표시한다.
받아치기 몸 틴트는 `(0.45,0.52,1.0)`, 분신은 `(0.5,0.78,1.0,0.62)`다. 급소·분신·적 몸에 꽂힌 검의 몸 중심은 현재 `GameScale.BODY_CENTRE`대로 발 위 32px다. 받아치기 아트 중심만 카드대로 발 위 50px다.

보드와 재생기는 **Pillow/Canvas 합성**이며 Godot 실행 캡처가 아니다. additive는 색을 더하는 방식으로 재현했다. 실제 엔진의 밝기, 효과 종료/루프, 좌향 반전·회전, 이동 중 부착, 스킬 타이밍은 게임 통합 후 확인해야 한다. 그림에서 계산한 재생 길이를 실제 게임에서 검증한 것으로 취급하지 않는다.

## 사람이 판단할 것 · 아직 채택하지 않음

1. 1× 정속에서 A/B 중 리오의 기존 참격·마력 색과 어울리는 것. 특히 받아치기 A의 어두움과 B의 결정 밝기.
2. 급소 X가 짧은 순간에 읽히는지, 든 검과 겹쳐 묻히지 않는지.
3. 그림자 이동이 출발·도착 양쪽에서 자연스러운지, B의 각진 조각이 너무 넓지 않은지.
4. 3초 대기하는 검의 맥동과 받아치기 루프 연결이 거슬리지 않는지.
5. 분신 폭발이 위로 띄우는 유리 파열로 읽히는지, HUD 1×에서 다섯 아이콘을 구분할 수 있는지.

위 내용은 취향·가독성·게임 맥락의 판단 사항이며 자동 측정으로 합격을 선언하지 않았다. 다음 단계는 시안 월드컵에서 선택한 뒤 리드가 게임에 연결하는 것이다.

## 재현과 커밋

```powershell
python -X utf8 reports/codex-vfx-11/build.py small
python -X utf8 reports/codex-vfx-11/build.py generated
python -X utf8 reports/codex-vfx-11/build.py icons
python -X utf8 reports/codex-vfx-11/qa.py all
python -X utf8 reports/codex-vfx-11/preview.py
powershell -ExecutionPolicy Bypass -File reports/codex-vfx-11/commit.ps1
```

`generated` 재현에는 git-ignored 원화 6개가 필요하다. 최종 PNG·보드·재생기는 원화 없이 볼 수 있다. 제작 명령은 카드의 150분 종료 시각을 지나면 새 생성을 막으므로, 추후 재제작은 새 작업 시간 계약으로 진행한다.

**커밋 스크립트:** [commit.ps1](commit.ps1). `delivered_files.json`의 명시적 경로와 작업 카드만 stage한다. 다른 staged 변경이 있거나 다른 브랜치이면 중단한다. 원화·다른 작업의 파일은 제외했다. UTF-8로 저장했고 텍스트 줄 끝 공백을 검사했다.

임시 브라우저 프로필과 초안 정리 명령은 자동 승인 검토가 `blocked by policy`로 차단했다. `art/raw/vfx-11/qa-browser-profile/`, `draft-contact.png`, `reference-cells.png`, `smoke_preview.py`는 정리하지 못했으며 커밋 목록에서 제외했다. 최종 보드는 `board.png`와 `*-board.png`다.

작업 시작: 2026-11-27 00:08:26 KST. 강제 종료 시각: 02:38:26 KST. 실제 생성 호출 6회는 모두 제한 내에 완료했다.

마지막 납품 감사: 68개 명시적 파일 경로·UTF-8·줄 끝 공백·Python 구문 검사 통과. tracked 변경과 staged 변경은 모두 0개였다. 커밋 대상은 약 2.0MiB, 원화와 남은 임시 프로필은 약 14.8MiB다. 작업 클론 전체는 기존 파일을 포함해 **3.25GiB**(`C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-b/SmashNine`).
