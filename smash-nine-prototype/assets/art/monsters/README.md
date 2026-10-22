# Monster pixel art

투명 RGBA 몬스터 스프라이트입니다. 모든 프레임은 오른쪽을 바라보며, 왼쪽 방향은 런타임 수평 반전을 전제로 합니다. 필터·밉맵 없이 최근접 샘플링을 사용합니다.

## 시트 규격

- `mossling_sheet.png` — **576×384**, 96×96 셀의 6열×4행.
- `ember_imp_sheet.png` — 같은 규격과 프레임 위치.
- 행 순서: idle 4프레임 / walk 6프레임 / attack 4프레임 / hurt 1프레임. 사용하지 않는 셀은 투명합니다.
- 기존 애니메이션의 프레임 위치와 실루엣은 보존했습니다.
- 셀 로컬 기준 중심 `x=48`, 발 하단 `y=72`를 유지합니다. 중앙 피벗 Sprite2D라면 발 원점 정렬 오프셋은 `y=-24`입니다.
- `ember_fireball.png`는 24×24 오른쪽 진행 단일 투사체이며 이번 작업에서 변경하지 않았습니다.

## ART-17 가독성 림

자기 렐름 배경에 묻히던 문제를 줄이기 위해 각 사용 프레임의 바깥쪽에 1–2 px 반대 색온도 림을 추가했습니다.

- Mossling: 청록 외곽 + 크림색 상단 하이라이트. Vanaheim의 녹색 수풀과 실루엣을 분리합니다.
- Ember Imp: 보라 외곽 + 옅은 금색 상단 하이라이트. Muspelheim의 적색/주황 배경과 분리합니다.
- 림은 각 96×96 셀 안에서만 계산해 이웃 프레임으로 번지지 않습니다.

배경 합성 확대 미리보기는 `reports/codex-art-17/mossling_vanaheim_2x.png`, `ember_imp_muspelheim_2x.png`에서 확인할 수 있습니다. 후처리 코드는 `tests/art_preview/hazard_art_17/build_assets.gd`에 있습니다.

## ART-25 렐름 전용 스킨

신규 7종은 기존과 같은 576×384 시트와 96×96 셀 규격을 사용합니다. 외형만 바뀌며, 근접형은 mossling 행동을, 원거리형은 ember imp 행동을 그대로 사용합니다.

| 렐름 | 스킨 | 종류 | 투사체 |
|---|---|---|---|
| Asgard | `asgard_aegis_ram` | melee | — |
| Niflheim | `niflheim_frost_owl` | ranged | `niflheim_frost_owl_projectile.png` |
| Alfheim | `alfheim_moon_moth` | ranged | `alfheim_moon_moth_projectile.png` |
| Svartalfheim | `svartalfheim_gear_beetle` | melee | — |
| Vanaheim | `vanaheim_vine_hound` | melee | — |
| Jotunheim | `jotunheim_rune_golem` | melee | — |
| Yggdrasil Heart | `yggdrasil_root_oracle` | ranged | `yggdrasil_root_oracle_projectile.png` |

`*_source.png`는 내장 ImageGen 원본입니다. `tests/art_preview/monsters_ui_25/build_assets.gd`가 Godot `Image` API로 최근접 축소만 수행하고, 정확한 셀 크기·미사용 셀 투명화·발 기준 y=72를 적용해 최종 파일을 만듭니다.

## ART-31 렐름별 두 번째 스킨

각 렐름은 이제 근접/원거리 한 쌍을 가집니다. 신규 원거리형은 같은 이름의 `*_projectile.png`(24×24)를 사용합니다.

| 렐름 | 신규 스킨 | 종류 |
|---|---|---|
| Asgard | `asgard_runic_raven` | ranged |
| Niflheim | `niflheim_glacier_wolf` | melee |
| Alfheim | `alfheim_moon_stag` | melee |
| Svartalfheim | `svartalfheim_cog_drone` | ranged |
| Vanaheim | `vanaheim_seed_sprite` | ranged |
| Jotunheim | `jotunheim_storm_wisp` | ranged |
| Yggdrasil Heart | `yggdrasil_root_guardian` | melee |
| Midgard | `midgard_rooftop_slinger` | ranged |
| Muspelheim | `muspelheim_magma_boar` | melee |

`tests/art_preview/monsters_31/build_assets.gd`가 생성 원본을 최근접 축소해 576×384 시트로 만들고, 원거리 5종의 고유 모티프를 24×24 투사체로 분리합니다.

## SYS-07 투사체·충격파 채택 규약

사용자가 모션 뷰어에서 고른 뒤 리드가 아래 PNG만 복사합니다. 이 연결 작업에서는 후보를 복사하지 않았습니다. 일반 경로의 기준은 프로젝트 루트(`smash-nine-prototype/`)이며 후보는 저장소 루트에 있습니다.

| 후보 | 복사할 게임 경로 |
|---|---|
| `art/bakeoff/monsters/<id>-projectile-v1.png` (192×48, 4프레임) | `assets/art/monsters/<id>_projectile.png` (기존 정지 그림 교체) |
| `art/bakeoff/monsters/ember_imp-projectile-v1.png` | `assets/art/monsters/ember_fireball.png` (Ember 예외 경로) |
| `art/bakeoff/monsters/slam_shockwave-v1.png` (256×48, 4프레임, 바닥 y=44) | `assets/art/monsters/slam_shockwave.png` (새 파일) |

일반 `<id>`는 `niflheim_frost_owl`, `jotunheim_storm_wisp`, `midgard_rooftop_slinger`, `vanaheim_seed_sprite`, `svartalfheim_cog_drone`, `yggdrasil_root_oracle`입니다. 복사 후 Godot 임포트만 하면 됩니다. JSON은 게임에 필요하지 않습니다.

- 일반 몬스터 그림은 폭이 높이의 정수 배(2배 이상)일 때 정사각형 프레임 스트립으로 인식하고 **12fps 반복**합니다. 정사각형·그 외 비율은 기존 정지 그림 경로를 사용합니다. ART-79의 후보별 제안 fps와 달리 이 연결은 SYS-07의 공통 12fps를 따릅니다.
- 각 프레임의 화면 폭은 기존처럼 `36 × WORLD`, 현재 **54px**입니다. 일반 48×48 프레임의 배율은 1.125입니다. 투명 여백까지 포함한 셀 크기이며 실제 유색 영역 크기는 다릅니다.
- `bolt`만 비행 방향을 따라 회전합니다. `lob`·`bomb`·`homing`은 회전하지 않고 수평 방향에 따라 좌우 반전합니다. 기존 정지 그림에도 같은 종류별 방향 규칙이 적용됩니다.
- 충격파는 64×48 프레임 4장을 12fps로 반복합니다. 셀 표시 크기는 54×40.5px이며 y=44 바닥선을 몬스터 지면에 맞춥니다. 왼쪽 파동은 수평 반전합니다. 파일이 없거나 규격이 맞지 않으면 기존 `Line2D` 마루를 유지합니다. Prototype 스타일도 기존 마루를 사용합니다.
- 캐릭터 투사체의 `set_art()`와 전투 판정·속도·피해·수명·AI는 그대로입니다.
