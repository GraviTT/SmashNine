# Realm hazard effect art

Godot 4.7용 투명 RGBA 픽셀 아트입니다. 신규 ART-17 자산은 **아트 1 px = 화면 1 px** 기준이며, 필터·밉맵 없이 최근접 샘플링과 정수 좌표로 사용합니다. 원화 생성본을 `tests/art_preview/hazard_art_17/build_assets.gd`에서 Godot `Image` API로 크롭·팔레트/알파 정리·타일 경계 보정했습니다.

## 신규 ART-17 파일

| 파일 | 크기 / 프레임 | 권장 재생 | 앵커와 반복 |
|---|---:|---:|---|
| `quake_warning.png` | 384×16, 96×16 4프레임 | 8 fps 반복 | 프레임 좌상단. 플랫폼 상단을 따라 전체 96 px 단위로 수평 반복. 좌우 경계가 일치합니다. |
| `quake_impact.png` | 768×64, 128×64 6프레임 | 12 fps 1회 | 각 프레임 하단 중앙 `(64, 63)`. 플랫폼 충돌점마다 배치합니다. |
| `vine_bridge.png` | 96×24, 정적 | 정적 | 좌상단. 전체 96 px 단위를 수평 반복할 수 있고 좌우 경계가 일치합니다. 밝은 황록색 보행면 림을 유지합니다. |
| `light_beam_base.png` | 96×64 | 정적 | 바닥 충돌점 하단 중앙 `(48, 63)`. |
| `light_beam_mid.png` | 576×128, 96×128 6프레임 | 10 fps 반복 | 프레임 좌상단. 필요한 높이까지 **세로 반복/마지막 타일 크롭**. 각 프레임 위·아래 4행이 정확히 같습니다. |
| `light_beam_top.png` | 96×64 | 정적 | 중간부와 맞닿는 하단 중앙 `(48, 63)`. 하늘 쪽 끝에 1회 배치합니다. |
| `fire_pillar_base.png` | 96×64 | 정적 | 바닥 충돌점 하단 중앙 `(48, 63)`. |
| `fire_pillar_mid.png` | 576×128, 96×128 6프레임 | 12 fps 반복 | 프레임 좌상단. 필요한 높이까지 **세로 반복/마지막 타일 크롭**. 각 프레임 위·아래 4행이 정확히 같습니다. |
| `fire_pillar_top.png` | 96×64 | 정적 | 중간부와 맞닿는 하단 중앙 `(48, 63)`. 불꽃 끝에 1회 배치합니다. |

`light_beam_mid.png`와 `fire_pillar_mid.png`는 가로 6프레임 시트입니다. 프레임 선택을 먼저 한 뒤 선택한 96×128 영역만 세로로 반복해야 하며, 시트 전체를 늘리면 안 됩니다.

## 기존 fallback 파일

| 파일 | 크기 | 용도 |
|---|---:|---|
| `light_beam.png` | 64×128 | 이전 단일 세로 타일. 신규 3부품 연동 전 fallback. |
| `fire_pillar.png` | 64×128 | 이전 단일 세로 타일. 신규 3부품 연동 전 fallback. |
| `vent_glyph.png` | 80×16 | 경고 열 아래 플랫폼 룬. 아스가르드는 금색 계열로 틴트 가능. |

## 생성 및 검증

- 생성 원화: `reports/codex-art-17/source/`
- 결정적 빌드: `tests/art_preview/hazard_art_17/build_assets.gd`
- 크기·타일 경계 수치: `reports/codex-art-17/verification.txt`
- 2배 확대 프레임/반복 확인: `reports/codex-art-17/hazards_after_2x.png`, `seam_checks_2x.png`

## ART-17 Round 2 타일 경계 수정

- `light_beam_mid.png`와 `fire_pillar_mid.png`의 모든 96×128 프레임은 128개 행 전체에 유효 픽셀이 있으며, 빈 행과 셀 폭의 1/3(32 px) 미만인 행이 없습니다.
- 두 mid 시트의 모든 프레임은 상단 4행과 하단 4행이 서로 완전히 같습니다. 따라서 `1→2→3→4→5→6`뿐 아니라 `6→1`을 포함한 임의 프레임 연결에도 투명 틈이 생기지 않습니다.
- 프레임 속도와 사용법은 그대로입니다: 광선 10 fps loop, 불기둥 12 fps loop, 각 96×128 셀을 세로 반복합니다.
- `quake_impact.png`는 두 번째 burst가 아니라 하나의 burst-and-settle로 읽히도록 기존 프레임을 `old4, old1, old3, old2, old5, old6` 순으로 재배열했습니다. 크기 128×64 × 6, 하단 중앙 앵커 `(64,63)`, 12 fps one-shot은 그대로입니다.
- 결정적 수정·검증 스크립트: `tests/art_preview/hazard_art_17/round2_fix.gd`
- 수치 기록과 2배 연결 프리뷰: `reports/codex-art-17/round2-verification.txt`, `round2_tile_sequence_2x.png`
