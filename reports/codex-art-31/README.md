# CODEX-ART-31 결과 보고

## 완료 범위

카드의 전체 범위를 완료했습니다. 9개 렐름에 빠져 있던 반대 행동형 스킨을 하나씩 추가해 모든 렐름이 근접/원거리 전용 한 쌍을 갖게 했고, 카탈로그·스포너·회귀 테스트를 새 쌍 구조에 맞게 연결했습니다. 피해량, 히트박스, 타이밍, 입력, 매치 규칙, 봇은 변경하지 않았습니다.

## 단계 1 — 신규 몬스터 아트

내장 ImageGen으로 기존 렐름 배경, 기존 렐름 몬스터, mossling/ember imp 시트, ART-25 접촉 시트를 참조했습니다. 9종 모두 1회 생성본을 채택했습니다(자산당 허용 3회 중 1회). 생성 원본은 1536×1024이며 Godot `Image` API로만 투명 배경 정리, 가장 큰 연결 실루엣 선택, 최근접 축소, 셀 배치와 투사체 분리를 수행했습니다. 업스케일은 하지 않았습니다.

| 렐름 | 신규 스킨 | 행동형 | 최종 파일 |
|---|---|---|---|
| Asgard | runic raven | ranged | `asgard_runic_raven_sheet.png` + 24×24 projectile |
| Niflheim | glacier wolf | melee | `niflheim_glacier_wolf_sheet.png` |
| Alfheim | moon stag | melee | `alfheim_moon_stag_sheet.png` |
| Svartalfheim | cog drone | ranged | `svartalfheim_cog_drone_sheet.png` + 24×24 projectile |
| Vanaheim | seed sprite | ranged | `vanaheim_seed_sprite_sheet.png` + 24×24 projectile |
| Jotunheim | storm wisp | ranged | `jotunheim_storm_wisp_sheet.png` + 24×24 projectile |
| Yggdrasil Heart | root guardian | melee | `yggdrasil_root_guardian_sheet.png` |
| Midgard | rooftop slinger | ranged | `midgard_rooftop_slinger_sheet.png` + 24×24 projectile |
| Muspelheim | magma boar | melee | `muspelheim_magma_boar_sheet.png` |

모든 시트는 576×384, 96×96 셀, idle 4 / walk 6 / attack 4 / hurt 1이며 미사용 셀은 투명합니다. 발 기준은 y=72입니다. 신규 시트 불투명 비율은 0.138–0.205입니다.

## 단계 2 — 코드 연결

- `RealmCatalog.build_maps`: 기존 단일 `monster` 항목을 `monsters.melee` / `monsters.ranged` 한 쌍으로 확장했습니다.
- `RealmMonsterSpawner._skin_for_realm_kind`: 행동형별 렐름 스킨을 선택하고, 항목이 없으면 종전 `mossling` / `ember_imp`로 폴백합니다.
- `RealmMonster.gd`: 기존의 외형 ID 로딩과 시트/투사체 폴백이 새 이름을 그대로 처리하므로 변경하지 않았습니다.
- `test_realm_monsters.gd`: 9개 카탈로그 쌍, 렐름당 2 melee + 2 ranged 스폰, 행동형 불변, 누락 파일 폴백을 검사하도록 확장했습니다.

## 단계 3 — 시각 자료와 검증

- `tests/art_preview/monsters_31/contact_pairs.png`: 1280×1152. 각 렐름 배경 위에 근접형, 원거리형, 24px 투사체, 128px Frey를 1배율로 배치했습니다.
- `build_assets.gd`: 9개 시트와 5개 투사체 생성 통과. 인증서 잡음 외 엔진 오류 없음.
- `build_preview.gd`: 접촉 시트 생성 통과. `Image.load_from_file`의 export 비권장 경고만 있으며 테스트용 스크립트입니다.
- `test_realm_monsters.gd`: 통과.
- 기본 `run_all.ps1 -SkipSoak`: 공유 기본 Godot 로그에서 출력 없이 대기해 중단.
- 동일 테스트 목록을 테스트별 고유 `--log-file`로 실행: 29/29 통과, 인증서 잡음 외 `ERROR` / `SCRIPT ERROR` / `Parse Error` 없음.
- `--headless --import`: 신규 PNG와 `.import` 생성은 완료했으나, 샌드박스 밖 `AppData/Local/Godot` 편집기 캐시를 만들거나 저장하지 못했다는 비인증서 오류가 있어 깨끗한 성공으로 판정하지 않습니다.

## 사람이 판단할 부분

- Midgard slinger는 다른 몬스터보다 인간형·세로형이라 mossling과의 체급 차이가 의도한 대비로 보이는지 확인이 필요합니다.
- Alfheim stag의 큰 초승달 뿔은 식별성이 좋지만 96px 셀에서 몸통이 상대적으로 작아 보일 수 있습니다.
- Jotunheim storm wisp는 룬 돌과 발광 코어가 선명하지만 원거리 공격 주체라는 인상이 충분한지는 취향 판단입니다.
- 투사체는 기존 24px 계약 안에서 실제 불투명 내용이 작습니다. 빠른 전투에서 더 큰 발광 림이 필요한지는 실제 창 모드 확인이 필요합니다.

## ImageGen 프롬프트 요약

각 렐름의 배경/기존 몬스터 팔레트를 유지하고, 기존 근접 또는 원거리 시트의 행동 리듬을 참조해 6×4 투명 스프라이트 시트를 생성했습니다. 공통 제약은 오른쪽 보기, 동일 개체/비율, 공통 기준선, 굵은 어두운 외곽선과 반대 색온도 림, 텍스트·격자·워터마크·크롭 금지였습니다. 최종 원본은 `assets/art/monsters/*_source.png`에 보존했습니다.

## 남은 작업 / 다음 권장 단계

코드·헤드리스 검증 기준의 남은 작업은 없습니다. 리드가 창 모드 실제 매치에서 신규 5종 투사체의 가독성과 Midgard/Alfheim/Jotunheim의 체급·실루엣을 최종 취향 검수하면 됩니다.
