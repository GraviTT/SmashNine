# Midgard original realm art

Godot 4.7용 `Midgard / World of humans` 원본 배경·플랫폼·수풀 세트다. 내장 `image_gen` 원본을 Godot `Image` API로 640×360 픽셀 그리드 축소, 제한 팔레트 매핑, 2배 최근접 확대했다.

## 파일 규격

| 파일 | 크기 | 3-슬라이스 |
|---|---:|---|
| `bg_far.png` | 1280×720 | 불투명 |
| `bg_mid.png` | 1280×720 | 투명 중경 |
| `platform_main.png` | 220×46 | 왼쪽 46px / 중앙 128px / 오른쪽 46px |
| `platform_sub.png` | 160×32 | 왼쪽 32px / 중앙 96px / 오른쪽 32px |
| `bush.png` | 160×72 | 투명 전경 수풀 |

## 팔레트

`#140F0B #211611 #2A1D16 #38261D #493126 #5D3A2B #744638 #91583B #AD6D3D #C78447 #D99B52 #E3AD62 #34444A #4D6065 #687A80 #89979A #102016 #1B3421 #2D4A2C #45633A #658052 #B19A55`

## 이미지 생성 프롬프트

- `bg_far`: warm Nordic river town at amber dusk, asymmetric timber-and-stone market skyline, copper roofs, far clocktower and hills; y=150..650 dark and low-detail; opaque; no gameplay platforms or characters.
- `bg_mid`: genuinely transparent edge-only timber facades, tiled eaves, shop-sign silhouettes and chimneys; very large empty center.
- `platform_main`: one transparent flat terracotta-capped stone-and-timber street ledge with symmetric masonry ends and sparse iron braces; readable at 46px.
- `platform_sub`: one thin transparent timber beam and shallow terracotta ledge with a flat walkable top; readable at 32px.
- `bush`: one transparent dense waist-high hedge, blocky muted-green foliage, opaque middle and flat base; intended to hide a fighter's lower body at 160×72.

The bush is generated and post-processed as an integration candidate; product code placement and occlusion order remain the lead's responsibility.

