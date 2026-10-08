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

`tests/art_preview/fx_1x_b/build_fx.gd`가 새 생성 원화와 보존된 고해상도 생성 원본을 불러 알파 컷오프, 불투명 영역 크롭, 최종 밀도 샘플링, 제한 팔레트 매핑, 지정 캔버스 정렬을 수행한다. `verify_fx.gd`는 크기·프레임·RGBA8·이진 알파·최소 3px 여백을 검증한다.

## 리드 통합 메모

제품 코드는 새 원본 픽셀 크기에 맞춰 기존 표시 배율을 내려야 한다. 유키 부적·루나 별은 4x→1x, 리오 검기·보석검은 2x→1x가 같은 화면 크기다. 이동 방향이 왼쪽이면 텍스처를 수평 반전하고, `rio_gem_sword.png`에는 기존 `GEM_COLORS`를 `modulate`로 적용한다. `hit_spark.png`는 96×96 AtlasTexture 4장으로 자르고 기존 표시 크기별 스케일을 절반으로 조정한다. 물리 히트박스는 바꾸지 않는다.
