# Niflheim original realm art

Godot 4.7용 `Niflheim / Land of ice` 원본 배경·플랫폼 세트다. 내장 `image_gen` 원본을 Godot `Image` API로 640×360 픽셀 그리드 축소, 제한 팔레트 매핑, 2배 최근접 확대했다.

## 파일 규격

| 파일 | 크기 | 3-슬라이스 |
|---|---:|---|
| `bg_far.png` | 1280×720 | 불투명 |
| `bg_mid.png` | 1280×720 | 투명 중경 |
| `platform_main.png` | 216×44 | 왼쪽 44px / 중앙 128px / 오른쪽 44px |
| `platform_sub.png` | 160×32 | 왼쪽 32px / 중앙 96px / 오른쪽 32px |

## 팔레트

`#06131A #081D27 #0C2733 #123442 #174052 #205268 #2F6577 #417B8B #5793A1 #6FA8B4 #89BAC2 #A9CDD2 #C6E1E2 #296C70 #3B8B82 #55A999 #77C7B8`

## 이미지 생성 프롬프트

- `bg_far`: polar-night frozen fjord, stepped glaciers, ice needles, distant waterfalls and restrained turquoise aurora; center gameplay band dark and calm; opaque.
- `bg_mid`: genuinely transparent edge-only jagged ice cliffs, frozen waterfall tongues and bottom-corner frost; very large empty center.
- `platform_main`: one transparent dark glacier-rock shelf with straight ice top, symmetric chipped caps and muted blue strata; readable at 44px.
- `platform_sub`: one thin transparent dark glacier slab with straight ice top, small chipped caps and short frost teeth; readable at 32px.

Platforms intentionally avoid white bloom so the runtime frost sheen and cyan accent edge can remain readable on top.

## 1.5배 렐름 배경 갱신 (CODEX-ART-15)

- `bg_far.png` / `bg_mid.png`: 1920×1080, 960×540 논리 픽셀을 2배 최근접 확대, 좌상단 `(0, 0)` 기준.
- 원경 프롬프트: 기존 니플하임을 카메라 1.5배 줌아웃한 16:9 확장 장면. 오로라·빙하 계단·얼음 폭포·고대 교량을 확장하며 청록 얼음 정체성을 유지.
- 중경: 기존 투명 빙벽 프레임을 새 논리 격자에서 재구성하고 알파를 0/0.5/1로 정리했다.
