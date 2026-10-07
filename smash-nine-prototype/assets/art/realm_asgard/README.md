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

