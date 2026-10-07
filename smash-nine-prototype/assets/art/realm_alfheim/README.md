# Alfheim original realm art

Godot 4.7용 `Alfheim / Realm of the light elves` 원본 배경·플랫폼 세트다. 내장 `image_gen` 원본을 Godot `Image` API로 640×360 픽셀 그리드 축소, 제한 팔레트 매핑, 2배 최근접 확대했다.

## 파일 규격

| 파일 | 크기 | 3-슬라이스 |
|---|---:|---|
| `bg_far.png` | 1280×720 | 불투명 |
| `bg_mid.png` | 1280×720 | 투명 중경 |
| `platform_main.png` | 220×46 | 왼쪽 46px / 중앙 128px / 오른쪽 46px |
| `platform_sub.png` | 160×32 | 왼쪽 32px / 중앙 96px / 오른쪽 32px |

## 팔레트

`#090C22 #0F132D #151A3B #1E2448 #292D57 #353B67 #414A76 #53608B #66749D #7185AE #879BC0 #9EADD0 #B8C9DD #D2DDEC #594C82 #7562A1 #9B83C6 #B29DD5`

## 이미지 생성 프롬프트

- `bg_far`: blue-hour elven valley, distant white-stone moon bridges, crystal spires, silver-leaf groves and restrained crescent moon; open horizontal vistas and dark low-detail combat band; opaque.
- `bg_mid`: genuinely transparent edge-only slender arches, silver-leaf boughs, crystal ornaments and low violet corner mist; clear center sightlines.
- `platform_main`: one transparent indigo-silver bridge slab with perfectly flat top, symmetric crescent caps and sparse lavender seams; readable at 46px.
- `platform_sub`: one thin transparent moon-bridge slab with flat top, small crescent caps and sparse lavender pixels; readable at 32px.

The indigo/lavender dominant hue is intentionally distinct from Niflheim's teal/cyan ice palette.
