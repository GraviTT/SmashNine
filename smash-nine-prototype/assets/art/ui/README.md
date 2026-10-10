# Soul card icons

`scripts/match/SoulCards.gd`의 여섯 소울 성장 카드를 위한 48×48 RGBA 픽셀 아이콘이다. 카드 패널에서는 1배로 그리며 최근접 필터를 사용한다.

| 파일 | 의미 | 상징 |
|---|---|---|
| `card_power.png` | 공격력 +12% | 교차 검·도끼와 주황 충격 룬 |
| `card_vitality.png` | 최대 HP +15, 회복 15 | 잎으로 감싼 붉은 심장 |
| `card_swiftness.png` | 이동 속도 +8% | 청록 잔상을 남기는 날개 장화 |
| `card_anchor.png` | 받는 넉백 -15% | 중력 고리가 겹친 강철 닻 |
| `card_sky_step.png` | 공중 점프 +1 | 구름에서 솟는 날개 화살 |
| `card_last_stand.png` | 링아웃 피해 -30% | 금이 갔지만 선 방패와 보라 소울 불꽃 |

## 이미지 생성 프롬프트와 팔레트

도구: 내장 ImageGen. 각 아이콘은 `single centered 48x48-ready fantasy pixel emblem; strong dark-navy outline; transparent background; no card frame/text/character/UI/watermark`를 공통 프롬프트로 사용했다. 개별 주제는 위 표의 상징을 그대로 지정했다.

팔레트는 공통 남청 외곽에 카드 의미별 강조색을 더했다: Power=강철·주황, Vitality=진홍·초록, Swiftness=은색·청록, Anchor=강철·남보라, Sky Step=하늘색·흰색, Last Stand=강철·자홍. Godot 후처리에서 각 아이콘을 42×42 이내로 맞춰 3픽셀 이상의 투명 여백과 통일된 시각 무게를 확보했다.

리드가 카드 UI를 연결할 때 `res://assets/art/ui/card_<id>.png`를 `SoulCards.gd`의 `id`와 동일한 이름으로 불러오면 된다.

## ART-25 렐름 및 HUD 세트

- `realm_emblems/`: 미니맵용 32×32 투명 엠블럼 9종.
- `status/`: 슈퍼 아머, 기절, Luna 별 충전, Frey 추적 표식, 실드 파괴, 낮은 HP용 24×24 투명 아이콘 6종.
- `title_bg.png`: 1920×1080 타이틀 배경. 생성된 1672×941 그림은 확대하지 않고 짙은 배경 캔버스 중앙에 원본 배율로 배치했습니다.
- `frames/`: 중앙이 투명한 9-slice 프레임. 권장 패치 여백은 아래와 같습니다.

| 프레임 | 정확한 크기 | 9-slice 여백 (L/T/R/B) |
|---|---:|---:|
| `skill_slot.png` | 72×72 | 10 px |
| `hp_bar.png` | 320×32 | 8 px |
| `card_panel.png` | 240×112 | 14 px |
| `result_panel.png` | 960×520 | 18 px |
| `menu_button.png` | 360×56 | 10 px |

모든 `*_source.png`는 보관한 내장 ImageGen 원본입니다. 최종 PNG는 `tests/art_preview/monsters_ui_25/build_assets.gd`가 Godot `Image` API로 정확한 캔버스, 투명 중앙, 최근접 축소만 적용해 생성합니다.
