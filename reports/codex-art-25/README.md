# CODEX-ART-25 결과 보고

## 완료 범위

- **Part 1 완료:** 7개 렐름 전용 몬스터(근접 4 / 원거리 3), 전용 투사체 3종, 렐름별 스킨 선택·범용 외형 폴백, 회귀 테스트.
- **Part 2 완료:** 렐름 엠블럼 9종, 상태 아이콘 6종, 9-slice 프레임 5종, 1920×1080 타이틀 배경, 미니맵·궁극기 컷인 연결.
- **Part 3 미수행:** 필수 Part 1·2를 완성하고 전체 비소크 테스트를 검증하는 데 우선순위를 두었습니다.

내장 ImageGen을 사용했고 모든 자산은 1회 생성본을 채택했습니다(자산당 허용 3회 중 1회). 외부 다운로드나 패키지 설치는 없었습니다. 생성본은 `*_source.png`로 보존했고 Godot `Image` API가 최근접 축소, 정확한 캔버스, 투명 배경과 시트 분할을 적용했습니다. 업스케일은 하지 않았습니다.

## Part 1 — 렐름 몬스터

| 렐름 | 최종 파일 | 종류 | 규격 |
|---|---|---|---|
| Asgard | `asgard_aegis_ram_sheet.png` | melee | 576×384, 96×96 셀 |
| Niflheim | `niflheim_frost_owl_sheet.png` | ranged | 576×384 + 24×24 투사체 |
| Alfheim | `alfheim_moon_moth_sheet.png` | ranged | 576×384 + 24×24 투사체 |
| Svartalfheim | `svartalfheim_gear_beetle_sheet.png` | melee | 576×384, 96×96 셀 |
| Vanaheim | `vanaheim_vine_hound_sheet.png` | melee | 576×384, 96×96 셀 |
| Jotunheim | `jotunheim_rune_golem_sheet.png` | melee | 576×384, 96×96 셀 |
| Yggdrasil Heart | `yggdrasil_root_oracle_sheet.png` | ranged | 576×384 + 24×24 투사체 |

행은 idle 4 / walk 6 / attack 4 / hurt 1 프레임이며 나머지 셀은 완전 투명입니다. 발 기준은 셀 내부 y=72입니다. Niflheim, Alfheim, Yggdrasil 투사체의 실제 불투명 내용은 각각 22×17, 22×17, 22×15 안에 들어갑니다.

### 코드 연결

- `RealmCatalog.build_maps`: 9개 렐름에 `monster.skin` / `monster.kind` 데이터 추가. Midgard는 mossling, Muspelheim은 ember imp를 유지합니다.
- `RealmMonsterSpawner._spawn_missing_for_realm`, `_skin_for_realm_kind`: 기존 2 melee / 2 ranged 교대 수를 유지하면서 종류가 일치하는 슬롯 하나만 렐름 스킨으로 대체합니다.
- `RealmMonster.setup`, `_build_art_sprite`, `_spawn_projectile`: 외형 ID를 행동 타입과 분리하고 전용 시트·투사체가 없으면 기존 mossling/ember imp 자산으로 폴백합니다.
- 피해량, 히트박스, 시간값, 입력, 매치 규칙, 봇 코드는 변경하지 않았습니다.

## Part 2 — UI

- `assets/art/ui/realm_emblems/`: 32×32 엠블럼 9종.
- `assets/art/ui/status/`: 24×24 상태 아이콘 6종.
- `assets/art/ui/frames/`: skill slot 72×72(10 px), HP bar 320×32(8 px), card panel 240×112(14 px), result panel 960×520(18 px), menu button 360×56(10 px). 괄호는 9-slice 권장 여백입니다.
- `assets/art/ui/title_bg.png`: 1920×1080. 1672×941 생성 원본을 확대하지 않고 짙은 남청 캔버스 중앙에 1:1 배치했습니다.

`MatchHud.rebuild_minimap`은 원본 아트 모드에서 9개 엠블럼을 표시하고, 자산이 없거나 프로토타입 모드이면 기존 색상 박스를 유지합니다. `_build_cutin`은 기존 `ult_cutin_band.png`를 사용하며, `show_ultimate_cutin`은 종전처럼 파이터 색을 입힙니다. 텍스처가 없으면 기존 `ColorRect`로 폴백합니다.

## 측정값

팔레트 RMS는 모든 불투명 픽셀과 렐름 강조색 사이 RGB 거리의 RMS입니다. 어두운 외곽선도 포함하므로 품질 점수가 아니라 상대 비교값입니다.

| 스킨 | 불투명 비율 | 팔레트 RMS |
|---|---:|---:|
| Asgard ram | 0.188 | 1.016 |
| Niflheim owl | 0.201 | 0.948 |
| Alfheim moth | 0.177 | 0.882 |
| Svartalfheim beetle | 0.181 | 0.907 |
| Vanaheim hound | 0.184 | 0.873 |
| Jotunheim golem | 0.129 | 0.881 |
| Yggdrasil oracle | 0.167 | 1.132 |

UI 불투명 픽셀 수는 32×32 엠블럼 202–491 px, 24×24 상태 아이콘 107–248 px 범위입니다. 두 미리보기는 각각 341 KB, 492 KB로 15 MB 제한 안입니다.

## 검증

| 검증 | 결과 |
|---|---|
| 신규 회귀 테스트를 수정 전 코드에서 실행 | 의도대로 실패: 7개 catalog 항목 부재 + 3인자 `setup` |
| `test_realm_monsters.gd` 수정 후 | 통과: 7개 스킨, 범용 쌍 유지, 누락 파일 폴백 |
| HUD 전용 스모크 | 통과: 엠블럼 9개, 프로토타입 박스 폴백, authored cut-in band |
| `run_all.ps1 -SkipSoak`의 24개 기존 테스트 + 신규 테스트 | 고유 로그 경로로 동일 25개를 실행, 비인증서 엔진 오류 0, 25/25 통과 |
| `git diff --check` | 통과 |

표준 `run_all.ps1 -SkipSoak` 자체는 동시 빌더들이 공유하는 기본 Godot 로그 잠금 때문에 첫 실행이 종료 대기 상태가 되어 중단했습니다. 같은 목록 전부를 테스트별 고유 `--log-file`로 다시 실행해 통과를 확인했습니다. `--headless --import`는 44개 신규/갱신 PNG를 임포트하고 `.import` 파일을 만들었지만, 샌드박스 밖의 `AppData/Local/Godot`에 에디터 캐시를 쓰지 못했다는 비인증서 `ERROR`가 있어 카드 기준으로는 깨끗한 성공으로 판정하지 않습니다. 런타임 테스트에는 영향이 없었습니다.

모든 실행의 `Failed to read the root certificate store`는 가이드에 명시된 샌드박스 잡음으로 따로 분리했습니다.

## 사람이 판단할 부분

- Jotunheim golem은 불투명 비율이 0.129로 가장 작아, 실제 전투 화면에서 체급이 약하게 느껴지는지 판단이 필요합니다.
- Yggdrasil oracle은 청록·남보라·검은 외곽의 비중 때문에 강조색 RMS가 1.132로 가장 큽니다. 렐름 정체성으로 충분한지는 취향 판단입니다.
- Niflheim owl과 Alfheim moth는 모두 차가운 청색 계열이지만 실루엣은 새/나방으로 분리됩니다. 빠른 화면에서 색 구분이 충분한지 확인이 필요합니다.
- 타이틀 배경의 원본 바깥에는 업스케일 금지 조건 때문에 남청 여백이 생깁니다. 로고 안전영역으로 쓸지, 추후 1920×1080 네이티브 원화를 다시 만들지는 사용자 결정입니다.
- result panel은 18 px 테두리만 남겨 1배율에서 절제되어 보입니다. 더 화려한 장식이 필요한지는 UI 취향 판단입니다.

실제 headless HUD 스크린샷은 dummy renderer가 Viewport 텍스처를 제공하지 않아 만들지 못했습니다. 대신 최종 파일을 1배율로 합성한 contact sheet와 HUD 노드 스모크 테스트를 제공했습니다.

## 시각 자료

- `smash-nine-prototype/tests/art_preview/monsters_ui_25/contact_monsters.png`: 각 렐름 배경 위에 전용 몬스터, 기존 2종, 128 px Frey를 같은 배율로 비교.
- `smash-nine-prototype/tests/art_preview/monsters_ui_25/contact_ui.png`: 타이틀, 엠블럼 9종, 상태 6종, 프레임, 기존 컷인 밴드를 게임 HUD 색 위에서 1배율 확인.

## 다음 단계

리드가 창 모드 실제 매치에서 미니맵 32 px 식별성, 컷인 텍스트 대비, Jotunheim 체급을 확인하면 됩니다. Part 3의 렐름별 두 번째 스킨은 수행하지 않았습니다.
