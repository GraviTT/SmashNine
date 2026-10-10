# Smash Nine Realms effect art

Godot 4.7용 1x 픽셀 이펙트 세트다. 모든 PNG는 RGBA, 투명 배경, 최근접 픽셀 그리드이며 2026-10-08의 2배 전투 스케일에서 보이는 크기 자체로 다시 제작했다. 런타임에서 예전 저해상도 파일을 확대하지 않는다.

## 파일 계약

| 파일 | 전체 크기 | 프레임 | 앵커(px) | 용도 |
|---|---:|---:|---:|---|
| `hit_spark.png` | 384×96 | 4 × 96×96 | (48,48), 중앙 | 흰색-금색 피격 스파크. 왼쪽부터 접촉광, 큰 폭발, 분리 광선, 잔광이다. |
| `yuki_talisman.png` | 128×64 | 1 | (64,32), 중앙 | 오른쪽으로 비행하는 상아색·주홍색 부적. |
| `luna_star.png` | 96×96 | 1 | (48,48), 중앙 | 분홍·노랑 중심과 청록 잔광을 가진 오른쪽 진행 별 탄환. |
| `rio_mana_wave.png` | 48×112 | 1 | (24,56), 중앙 | 오른쪽으로 휘어진 세로형 청색 마력 검기. 기존 24×54 히트박스의 2배 표시를 감싼다. |
| `rio_gem_sword.png` | 96×32 | 1 | (48,16), 중앙 | 오른쪽을 향한 회색 보석 검. 런타임에서 여섯 색으로 틴트한다. |
| `nova_gravity_orb.png` | 32×32 | 1 | (16,16), 중앙 | 이번 카드 범위 밖의 기존 중력 구체. |
| `parry_flash.png` | 768×128 | 6 × 128×128 | (64,64), 중앙 | 패리 성공용 금백색 링 충격파와 4방향 섬광. 0.15초, additive. |
| `landing_dust.png` | 480×32 | 5 × 96×32 | (48,31), 아래 중앙 | 공중 공격 착지 때 좌우로 굴러 나가는 따뜻한 회색 먼지. 0.12초, normal. |
| `hit_streak.png` | 640×24 | 4 × 160×24 | (80,12), 중앙 | 피격점의 양끝이 뾰족한 금백색 횡베기 선. 코드가 x축 69–138px로 조절, 0.08초, additive. |
| `yuki_seal_break.png` | 480×96 | 5 × 96×96 | (48,48), 중앙 | 대기 중인 유키 부적이 4–6개 조각과 연청색 불꽃으로 찢어지는 효과. 0.15초, normal. |

## 팔레트와 그리기

- 공통 외곽은 캐릭터 시트와 같은 짙은 남청 계열이며, 작은 캔버스에서 1픽셀 실루엣이 유지되게 했다.
- 유키는 상아·주홍·금색, 루나는 분홍·연청·노랑, 리오는 남청·전기 청록, 노바는 남청·청록·금색을 사용한다.
- `rio_gem_sword.png`만 무채색 7단계로 제한해 `modulate` 틴트의 명도 정보가 유지되게 했다.
- 반투명 경계는 사용하지 않고 알파를 0/1로 정리했다. 필터는 `NEAREST`, 밉맵은 끄는 것이 의도한 결과다.

## 이미지 생성 프롬프트

도구: 내장 ImageGen. 모든 프롬프트에 `transparent background`, `crisp hand-clustered pixel art`, `no text/logo/watermark`, 최종 크기에서의 판독성을 공통 제약으로 넣었다.

- Hit spark: `four-frame white-gold hit spark strip; contact flash -> sharp starburst -> broken rays -> fading motes; identical centres; dark navy accents`.
- Yuki: `single ivory Japanese paper talisman flying right; vermilion seal marks; folded trailing corner; two gold sparks`.
- Luna: `single compact five-point magical star bolt; white-yellow core; pink-violet points; pale-cyan trailing sparkle`.
- Rio wave: `single tall narrow blue mana crescent bowed right; cyan leading edge; deep-blue body; squared trailing fragments`.
- Rio sword: `single slim greyscale throwing gem sword pointing right; crystal diamond guard; no hue colours`.
- Nova: `single compact gravity orb; dark-indigo core; broken teal-to-gold orbital arcs; square gravity motes`.
- Parry flash: `six-frame perfect-block clang; gold-white ring shockwave and sharp four-point glint; contact -> ring -> full clang -> broken rays -> motes -> almost faded; clearly distinct from hit spark`.
- Landing dust: `five-frame pair of compact warm-grey dust puffs rolling left and right along the ground; compressed contact -> billows -> scattered clumps -> almost faded`.
- Hit streak: `four-frame sharp horizontal white-gold slash line; needle-point ends, brightest middle; ignition -> brilliant line -> split taper and sparks -> almost faded; never a flat rectangle`.
- Yuki seal break: `five-frame ivory paper talisman with vermilion marks tearing into 4–6 fragments and light-blue sparks; intact crack -> torn centre -> separating fragments -> outward fall -> almost faded; match yuki_seal_idle`.

`tests/art_preview/fx_1x_b/build_fx.gd`가 새 생성 원화와 보존된 고해상도 생성 원본을 불러 알파 컷오프, 불투명 영역 크롭, 최종 밀도 샘플링, 제한 팔레트 매핑, 지정 캔버스 정렬을 수행한다. `verify_fx.gd`는 크기·프레임·RGBA8·이진 알파·최소 3px 여백을 검증한다.

CODEX-ART-20의 네 짧은 효과는 `tests/art_preview/flash_art_20/build_effects.gd`가 ImageGen 원화에서 잘라낸 뒤 최근접 축소, 제한 팔레트 매핑, 이진 알파와 앵커 정렬을 수행한다. 각 결과는 두 렐름 배경색에서 1x/4x 접촉 시트로 확인했다.

## 리드 통합 메모

제품 코드는 새 원본 픽셀 크기에 맞춰 기존 표시 배율을 내려야 한다. 유키 부적·루나 별은 4x→1x, 리오 검기·보석검은 2x→1x가 같은 화면 크기다. 이동 방향이 왼쪽이면 텍스처를 수평 반전하고, `rio_gem_sword.png`에는 기존 `GEM_COLORS`를 `modulate`로 적용한다. `hit_spark.png`는 96×96 AtlasTexture 4장으로 자르고 기존 표시 크기별 스케일을 절반으로 조정한다. 물리 히트박스는 바꾸지 않는다.

짧은 효과 네 장은 모두 1 art px = 1 screen px다. `parry_flash`(6프레임/0.15초)와 `hit_streak`(4프레임/0.08초)은 additive, `landing_dust`(5프레임/0.12초)와 `yuki_seal_break`(5프레임/0.15초)은 normal로 재생한다. 위 표의 앵커를 그대로 사용하고, 마지막 프레임 뒤 one-shot으로 해제한다.

## 스킬·렐름 효과 추가 (CODEX-ART-24)

모든 최종 스트립은 RGBA8, alpha `{0,255}`, 최근접 픽셀 그리드다. 내장 ImageGen으로 캐릭터별 원화 아틀라스를 한 번씩 만들고 `tests/art_preview/skill_fx_24/build_assets.gd`가 행 분리, 불투명 영역 크롭, **확대 없는** 최근접 축소, 제한 팔레트 매핑, 이진 알파와 앵커 정렬을 수행했다. 큰 유키 결계는 생성 원화의 링·부적 구성을 따라 Godot `Image`의 1px 원과 부적 픽셀로 640px 셀에 다시 조립했다. 원화는 같은 폴더의 `*_source.png`에 보존했다.

### Part 1 — 스킬 효과 계약

| 파일 | 전체 크기 | 프레임 셀 | FPS / 반복 | 앵커 | blend |
|---|---:|---:|---:|---:|---|
| `skill/luna_star_bloom.png` | 1536×256 | 6 × 256×256 | 37.5 / 아니오 | (128,128) | additive |
| `skill/luna_moon_ring.png` | 1920×320 | 6 × 320×320 | 25 / 아니오 | (160,160) | additive |
| `skill/luna_brave_aura.png` | 768×128 | 6 × 128×128 | 10 / 예 | (64,64) | additive |
| `skill/luna_comet_trail.png` | 192×48 | 4 × 48×48 | 40 / 아니오 | (24,24) | additive |
| `skill/luna_comet_burst.png` | 1344×224 | 6 × 224×224 | 42.857 / 아니오 | (112,112) | additive |
| `skill/nova_gravity_burst.png` | 3072×512 | 6 × 512×512 | 42.857 / 아니오 | (256,256) | normal |
| `skill/nova_momentum_trail.png` | 256×32 | 4 × 64×32 | 40 / 아니오 | (32,16) | additive |
| `skill/nova_vector_streak.png` | 768×48 | 4 × 192×48 | 33.333 / 아니오 | (96,24) | additive |
| `skill/nova_shift_dash.png` | 384×40 | 4 × 96×40 | 18.182 / 아니오 | (48,20) | additive |
| `skill/nova_shift_ready.png` | 640×128 | 5 × 128×128 | 35.714 / 아니오 | (64,64) | additive |
| `skill/nova_impact_star.png` | 3072×512 | 6 × 512×512 | 40 / 아니오 | (256,256) | additive |
| `skill/nova_launch_flash.png` | 1280×64 | 5 × 256×64 | 31.25 / 아니오 | (128,32) | additive |
| `skill/rio_rune_guard.png` | 768×128 | 6 × 128×128 | 12 / 예 | (64,64) | additive |
| `skill/rio_rune_burst.png` | 1920×320 | 6 × 320×320 | 37.5 / 아니오 | (160,160) | additive |
| `skill/rio_blink_trail.png` | 1280×64 | 5 × 256×64 | 31.25 / 아니오 | (128,32) | additive |
| `skill/yuki_grand_ward.png` | 5120×640 | 8 × 640×640 | 12 / 예 | (320,320) | normal |
| `skill/guard_bubble.png` | 384×128 | 3 × 128×128 | 코드가 idle/block/parry 프레임 선택 | (64,64) | normal |
| `skill/attack_afterimage.png` | 640×64 | 4 × 160×64 | 57.143 / 아니오 | (80,32) | additive |

### Part 2 — 렐름 마커 계약

| 파일 | 전체 크기 | 프레임 셀 | FPS / 반복 | 앵커 | blend |
|---|---:|---:|---:|---:|---|
| `../realm_center/portal_anim.png` | 576×96 | 6 × 96×96 | 8 / 예 | (48,48) | normal |
| `realm/seal_barrier.png` | 1536×256 | 6 × 256×256 | 6 / 예 | (128,128) | normal |
| `realm/collapse_cracks.png` | 1920×128 | 6 × 320×128 | 5 / 예 | (160,64) | normal |
| `realm/warning_edge.png` | 1920×48 | 6 × 320×48 | 8 / 예 | (160,24) | additive |

### 기존 도형에서 크기를 도출한 기준

- Luna bloom: 코드의 `radius × COMBAT`, 시작 0.35→끝 1.25배와 0.10–0.24초를 유지했다. moon ring은 `90 × COMBAT`, 0.72→1.08배, 0.24초를 기준으로 했다. Brave aura는 바깥 별 반지름 48, 안쪽 원 34를 128px 셀에 담았다.
- Luna comet: trail은 `10 × COMBAT` 바깥 반지름과 0.10초, burst는 `42 × COMBAT`, 1.75배 끝 크기와 0.14초에서 48/224px 셀을 정했다.
- Nova burst/impact: 전달되는 실제 반지름을 호출부 scale로 맞추고 512px 셀에 여백을 뒀다. momentum은 48×16 도형·0.10초, vector는 가변 길이와 5–12px 폭·0.12초, shift는 52px·0.22초, ready는 반지름 34→1.5배·0.14초, launch는 180×18px·0.16초를 유지했다.
- Rio: rune guard는 중심 `(0,-34)`·반지름 48의 육각형, burst는 `40 × COMBAT`가 2.4배까지 커지는 0.16초, blink는 최대 200px·10→1px·0.16초를 기준으로 했다. 보석검은 기존 `rio_gem_sword.png`를 사용한다.
- Yuki: `FIELD_RADIUS = 205 × COMBAT = 307.5px`를 640px 셀에 1:1로 담고 네 부적을 반지름 안쪽에 배치했다.
- 공통 guard는 기존 140도 호, 가로 36·세로 42 반지름을 128px 셀에 담았고 `guard_parry_timer`, block 때의 1.35배 pulse, 평상 상태로 세 프레임을 선택한다. attack afterimage는 실제 `visual.size`를 150×56 기준 셀에 비례시킨다.
- 렐름은 포털의 기존 96×96 표시 크기, 256px 봉인 타일, 320×128 붕괴 균열 타일, 320×48 가장자리 타일을 사용한다. 포털 틴트와 코드 텍스트는 그대로 남는다.

최종 불투명 픽셀은 모두 지정 팔레트의 정확한 색이므로 최종 팔레트 거리(최근접 RGB 제곱거리)는 0이다. 원본 모드에서만 아트를 그리고 파일 누락/F2 프로토타입 모드에서는 기존 `Line2D`·`Polygon2D`·`ColorRect`가 그대로 동작한다.
