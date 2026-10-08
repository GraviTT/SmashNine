# Asgard original realm art

Godot 4.7용 `Asgard / Realm of the gods` 원본 배경·플랫폼 세트다. 내장 `image_gen`으로 원본을 만들고 `tests/art_preview/realms_a/build_assets.gd`의 Godot `Image` API로 640×360 픽셀 그리드 축소, 제한 팔레트 매핑, 2배 최근접 확대를 적용했다.

## 파일 규격

| 파일 | 크기 | 3-슬라이스 |
|---|---:|---|
| `bg_far.png` | 1280×720 | 불투명 |
| `bg_mid.png` | 1280×720 | 투명 중경 |
| `platform_main.png` | 232×52 | 왼쪽 52px / 중앙 128px / 오른쪽 52px |
| `platform_sub.png` | 160×32 | 왼쪽 32px / 중앙 96px / 오른쪽 32px |

## 팔레트

`#07101B #0D1928 #142438 #1D3045 #263B51 #314B62 #45627A #59758B #71899B #8DA9B8 #A9B8BF #D1D5CF #805B2E #A87534 #C88D3D #D69A42 #E3AD55 #F0C06C`

## 이미지 생성 프롬프트

- `bg_far`: accepted center-realm pixel scale and quiet combat band; Asgard celestial citadel above cloud seas, distant mountains and monumental valkyrie gate, cool navy/slate with restrained gold; exact 16:9, y=150..650 low-detail; opaque; no platforms, characters, UI, text, logo or watermark.
- `bg_mid`: genuinely transparent edge-only broken sky-temple columns, banner fragments and bottom-corner cloud wisps; large empty center; navy/slate with sparse gold.
- `platform_main`: one transparent orthographic blue-gray celestial stone strip, flat top, symmetric winged caps, restrained gold inlay; readable at 52px.
- `platform_sub`: one thinner transparent celestial slab, flat top, small symmetric caps and sparse gold rune pixels; readable at 32px.

The attached concept art was used only for broad world identity; the accepted center-realm contact sheet was the pixel scale, layer-separation and palette-discipline reference.

## 1.5배 렐름 배경 갱신 (CODEX-ART-15)

- `bg_far.png` / `bg_mid.png`: 1920×1080, 960×540 논리 픽셀을 2배 최근접 확대, 좌상단 `(0, 0)` 기준.
- 원경 프롬프트: 기존 아스가르드를 카메라 1.5배 줌아웃한 16:9 확장 장면. 발키리 관문·공중 성채·설산·구름 바다를 새 외곽까지 확장하고 전투 띠는 저대비로 유지.
- 중경: 기존 투명 신전 기둥·구름 프레임을 새 논리 격자에서 재구성하고 알파를 0/0.5/1로 정리했다.
