# CODEX-ART-32 결과 보고 — Frey D32 이동 시트 재구축

## 완료 범위

### Part 1 — 우선 동작

- `spike_followup` 4프레임, `descent` 6프레임, `tumble` 4프레임을 행 단위로 다시 제작했다.
- 캐릭터 몸과 장비는 body 원본, 참격·먼지·광택은 FX 원본으로 각각 별도 생성했다.
- 기존 `spike_followup`의 프레임별 0.70~0.93배 머리 크기와 `descent`의 0.70~0.83배 크기 편차를 새 시트에서 모두 1.000으로 맞췄다.

### Part 2 — 나머지 동작

- `attack_up`, `attack_down`, `attack_air_side`, `dash_strike`, `rising_cleave`를 같은 파이프라인으로 다시 제작했다.
- `attack_up`, `attack_down`, `attack_air_side`는 1차 결과의 검/팔다리 폭이 셀에 불리해 2차 body 생성을 채택했다.
- 나머지 다섯 행은 body 1차 결과를 채택했다. 모든 행의 FX는 별도 1차 결과를 채택했다.
- 어느 자산도 최대 3회 제한에 도달하지 않았다.

### Part 3 — 합성, 검사, 재사용 파이프라인

- body/FX/composite 3개 768x1024 시트와 35개 머리 상자를 기록한 JSON을 만들었다.
- 128x128 셀마다 바깥 1픽셀을 완전 투명하게 정리했다.
- `jotunheim_rune_golem_sheet.png`(576x384)의 r2c1 위쪽 경계에 닿던 불투명 픽셀 5개를 한 칸 안으로 이동해 규칙 1을 만족시켰다.
- `test_sprite_frames.gd`를 확장해 전투기 기본 시트, 이동 시트, 몬스터 시트의 1픽셀 경계와 모든 `*_heads.json`의 크기/범위를 검사한다.
- 다른 캐릭터에서도 경로와 캐릭터 ID를 받을 수 있도록 빌더를 구성했다. 캐릭터별 머리 기준 상자, 행 정의, 접지 플래그와 FX 앵커는 별도 설정이 필요하다.

## 산출물

| 파일 | 크기 / 역할 |
|---|---|
| `assets/art/frey/frey_moves_body_sheet.png` | 768x1024, 캐릭터와 장비만 |
| `assets/art/frey/frey_moves_fx_sheet.png` | 768x1024, 이펙트만 |
| `assets/art/frey/frey_moves_sheet.png` | 768x1024, 게임 사용 합성본 |
| `assets/art/frey/frey_moves_heads.json` | idle 기준과 35개 프레임 머리 상자 |
| `assets/art/frey/frey_moves_README.md` | D32 규격과 재실행 방법 |
| `assets/art/monsters/jotunheim_rune_golem_sheet.png` | 576x384, r2c1 경계 수정 |
| `tests/art_preview/frey_redo_32/` | 생성 원본, 빌더, 독립 감사, 1x/3x 비교 자료 |

런타임 행 이름·순서·프레임 수는 기존과 동일하다. 게임은 이미 `frey_moves_sheet.png`를 같은 계약으로 읽으므로 `Frey.gd` 또는 다른 제품 코드는 수정하지 않았다.

## 머리 기준과 독립 감사

idle 기준 상자는 `(x=62, y=27, w=28, h=32)`이다. 머리카락·얼굴·투구를 포함하고, 각도에 따라 실루엣이 크게 바뀌는 흰 투구 날개는 제외했다.

아래 값은 JSON을 읽지 않는 `head_audit.gd`의 결과다. 기준 머리 템플릿을 0.70~1.40 범위에서 0.025 간격으로 탐색하고, 좌우 반전 및 tumble의 90도 회전 후보도 검사했다.

| 행 | 기존 프레임별 배율 | 새 프레임별 배율 |
|---|---|---|
| attack_up | 0.775, 1.025, 0.775, 1.050 | 1.000, 1.000, 1.000, 1.000 |
| attack_down | 0.700, 1.050, 0.775, 0.900 | 1.000, 1.000, 1.000, 1.000 |
| attack_air_side | 0.775, 0.700, 0.725, 1.150 | 1.000, 1.000, 1.000, 1.000 |
| dash_strike | 0.775, 0.850, 0.800, 0.750 | 1.000, 1.000, 1.000, 1.000 |
| rising_cleave | 0.750, 1.275, 0.725, 0.725, 0.775 | 1.000, 1.000, 1.000, 1.000, 1.000 |
| spike_followup | 0.850, 0.925, 0.700, 0.850 | 1.000, 1.000, 1.000, 1.000 |
| descent | 0.775, 0.775, 0.825, 0.775, 0.700, 0.825 | 1.000, 1.000, 1.000, 1.000, 1.000, 1.000 |
| tumble | 0.725, 0.750, 0.775, 0.700 | 1.000, 1.000, 1.000, 1.000 |

결과: 새 35프레임 전부 idle 기준 ±5% 안이다.

## 생성 프롬프트와 채택 라운드

모든 body 생성은 `frey_sheet.png`와 `frey_illustration.png`를 참조했다. 공통 지시는 같은 Frey, 지정된 행의 정확한 포즈 수를 한 수평 스트립에 배치, 동일한 머리/몸 비율, 얼굴 또는 측면 얼굴 노출, 오른쪽 방향, 단단한 픽셀 가장자리, 투명 배경, 이펙트와 글자 없음이었다. 2차 생성 세 행에는 검 각도와 팔다리를 더 조밀하게 모아 셀 안에 들어오도록 하는 조건을 추가했다.

모든 FX 생성은 해당 채택 body 스트립과 정식 색상 참조를 사용했다. 공통 지시는 캐릭터·얼굴·검·방패를 그리지 않고, 같은 프레임 간격으로 참격·먼지·광택만 배치하며, 투명 배경과 단단한 픽셀 가장자리를 유지하는 것이었다.

- body 1차 채택: `dash_strike`, `rising_cleave`, `spike_followup`, `descent`, `tumble`
- body 2차 채택: `attack_up`, `attack_down`, `attack_air_side`
- FX 1차 채택: 8개 행 모두
- 보존 위치: `tests/art_preview/frey_redo_32/*_source.png`. 채택하지 않은 1차 body 3장은 미리보기 폴더를 약 15MB 아래로 유지하기 위해 복사본에서 제외했다.

## 재실행

`smash-nine-prototype/`에서 실행한다.

```powershell
& $godot --headless --path . -s tests/art_preview/frey_redo_32/build_frey_redo.gd -- `
  --character=frey `
  --base=res://assets/art/frey/frey_sheet.png `
  --old=res://tests/art_preview/frey_redo_32/before_sheet.png `
  --source-dir=res://tests/art_preview/frey_redo_32 `
  --asset-dir=res://assets/art/frey `
  --preview-dir=res://tests/art_preview/frey_redo_32

& $godot --headless --path . -s tests/art_preview/frey_redo_32/head_audit.gd
```

## 시각 자료

- `spike_followup_before_after_3x.png`: 위는 기존, 아래는 새 결과이며 idle과 측정 배율을 함께 표시한다.
- `descent_layers_3x.png`: 왼쪽부터 body, FX, composite를 나란히 보여준다.
- `head_boxes_3x.png`: 합성본의 35개 머리 상자를 확인한다.
- 각 행의 `*_before_after_1x.png`, `*_before_after_3x.png`: 실제 픽셀과 확대 상태를 모두 확인한다.

## 자동 확인 결과

- `--headless --import`: 완료. 허용된 임시 `APPDATA`/`LOCALAPPDATA`를 사용했으며 알려진 인증서 오류 외 오류 없음
- 독립 머리 감사: 35/35 프레임이 기준의 ±5% 안, 실제 일치 배율은 전부 1.000
- `test_sprite_frames.gd`: 통과 — 기본 시트 8개/184프레임, 이동 시트 8개, 몬스터 시트 18개 경계 정상, head JSON 1개 정상
- `test_moves_sheet.gd`: 통과 — Frey/Luna/Brave Luna/Nova/Yuki/Rio 행 및 누락 시트 fallback 정상
- `test_frey_kit.gd`: 통과
- `test_sprite_pose.gd`: 통과
- `run_all.ps1 -SkipSoak`: 29개 항목이 모두 exit 0이며 28개 자동 테스트가 명시적 통과 문구를 출력했다. `visual_preview`도 exit 0이다. 다만 러너는 각 프로세스의 알려진 인증서 저장소 `ERROR`를 엄격히 감지해 최종 표시는 `FAILED`로 냈다. 인증서 줄을 제외하면 `SCRIPT ERROR`, `Parse Error`, 그 밖의 `ERROR`는 없다.

개별 테스트와 전체 러너의 원문은 이 보고서 폴더의 `*.log`에 보존했다.

## 사람이 판단할 항목

- 한 행을 실제 FPS로 재생했을 때 동작 전환과 무게감이 자연스러운가
- 공격 방향과 검 궤적이 입력/판정 의도와 즉시 읽히는가
- 별도 FX의 크기와 밝기가 전투 가독성을 해치지 않는가
- quarter-turn으로 만든 tumble의 얼굴과 투구 방향이 회전 동작으로 자연스러운가
- 머리 기준을 엄격히 통일한 대신 포즈의 원근감이 과하게 평평해 보이지 않는가

위 항목은 측정 통과와 별개인 미감 판단이며 사용자가 결정해야 한다.
