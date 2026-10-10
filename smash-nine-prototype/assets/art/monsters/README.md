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
