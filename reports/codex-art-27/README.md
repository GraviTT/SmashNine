# CODEX-ART-27 결과 보고

## 완료 범위

- **Part 1 완료:** 타이틀 배경의 남색 여백 제거 및 960×540 기준 2배 nearest 최종화, Jotunheim 룬 골렘 대형 실루엣 재작화.
- **Part 2 완료:** ART-25의 5종 HUD 프레임을 `NinePatchRect`로 실제 연결하고, 원본 아트가 꺼지거나 파일이 없으면 `ColorRect`로 복귀하도록 구현.
- **Part 3 미수행:** 필수 Part 1·2의 구현·회귀 검증을 우선해 두 번째 몬스터 쌍은 추가하지 않음.

이미지는 내장 ImageGen을 사용해 각 자산 1회 생성본을 채택했습니다. 외부 다운로드나 패키지 설치는 하지 않았습니다.

## Part 1 — 리드 리뷰 항목

### 타이틀/결과 배경

| 파일 | 규격 | 처리 |
|---|---:|---|
| `assets/art/ui/title_bg_source.png` | 1672×941 | ImageGen 원본 보존 |
| `assets/art/ui/title_bg.png` | 1920×1080 | 중앙 16:9 크롭 → 960×540 nearest 축소 → 정수 2배 nearest |

- 네 변 전체에 실제 장면이 이어지며 기존 단색 남색 여백은 없습니다.
- 가장자리에서 기존 채움색 `#06152f`과 동일한 픽셀 수를 측정한 결과 `0`입니다.
- 상단 중앙은 별이 있는 어두운 하늘로 두어 기존 `title_logo.png`가 올라갈 공간을 확보했습니다.
- `MatchHud._build_overlay`, `show_start_screen`, `show_results`에서 시작/결과 화면 배경으로 연결했습니다. 프로토타입 모드에서는 기존 overlay 색만 남습니다.

### Jotunheim 룬 골렘

| 파일 | 규격 | 처리 |
|---|---:|---|
| `assets/art/monsters/jotunheim_rune_golem_source.png` | 1536×1024 | ImageGen 원본 보존, 6×4 소스 그리드 |
| `assets/art/monsters/jotunheim_rune_golem_sheet.png` | 576×384 | 96×96 셀, idle 4 / walk 6 / attack 4 / hurt 1 |

- Godot `Image` API로 반투명 생성 배경을 제거하고 행별 공통 배율로 nearest 축소했습니다.
- 사용 프레임의 발 기준은 y=80이며, `RealmMonster._build_art_sprite`에서 이 스킨에만 시각 피벗을 보정했습니다. 충돌체·피해·타이밍·행동은 변경하지 않았습니다.
- 전체 시트 불투명 비율은 `0.226`, mossling은 `0.253`입니다. ART-25 보고의 Jotunheim `0.129`보다 커졌고 1× 접촉 시트에서도 두 실루엣의 무게가 가까워졌습니다.

## Part 2 — HUD 프레임 연결

`scripts/ui/MatchHud.gd`의 다음 부분을 변경했습니다.

- `_hud_frame`: `frames/<id>.png`가 있으면 마진 규격에 맞춘 `NinePatchRect`, 없으면 같은 크기의 `ColorRect`를 반환합니다.
- `_build_skill_bar`, `update_skill_bar`: 4개 슬롯에 `skill_slot.png`를 연결하고 궁극기 준비 pulse를 프레임에 적용합니다. 기존 테스트가 읽는 `style` 상태도 호환 유지했습니다.
- `_build_hp_bar`, `set_status`: `hp_bar.png`와 실제 HP 비율/저·중·고 HP 색 채움을 추가했습니다.
- `_build_card_panel`: 3개 카드 배경에 `card_panel.png`를 연결했습니다.
- `_build_overlay`, `show_start_screen`, `show_results`: `title_bg.png`, `result_panel.png`를 시작/결과 화면에 연결했습니다.
- `_build_menu_frames`: 캐릭터 선택 행과 B/F2 메뉴 행 뒤에 `menu_button.png`를 연결했습니다. 텍스트와 입력 처리는 기존 코드가 그대로 소유합니다.
- `_set_match_hud_visible`: 새 HP 바도 시작/결과 화면 뒤로 함께 숨깁니다.

추가 테스트 `tests/test_hud_frames.gd`는 원본 모드의 9-slice 11개(스킬 4, HP 1, 카드 3, 결과 1, 메뉴 2)와 프로토타입 모드의 `ColorRect` 11개, 타이틀 배경 로딩/비로딩을 검사합니다. 이 검사는 ART-27 이전 코드에서는 필요한 노드와 연결이 없어 실패합니다.

## 시각 자료

- `tests/art_preview/monsters_ui_27/contact_part1.png` — 여백 없는 배경+로고 안전 영역, mossling/골렘 1× 비교, Jotunheim 배경 위 골렘 확인.
- `tests/art_preview/monsters_ui_27/contact_hud.png` — 결과/카드/스킬/HP/메뉴 프레임을 최종 PNG 1×로 배치한 접촉 시트.

`contact_part1.png`에서 왼쪽 위는 최종 타이틀 구성, 아래 두 줄은 mossling과 새 골렘의 동일 96px 셀 비교, 오른쪽은 Jotunheim 배경 위 골렘입니다. `contact_hud.png`는 실제 연결된 다섯 프레임 계열의 외곽과 아이콘 대비를 보여 줍니다.

## 검증 결과

| 검증 | 결과 |
|---|---|
| `build_assets.gd` | 통과: title 1920×1080, golem 576×384 |
| `build_previews.gd` | 통과: 접촉 시트 2개 1280×720 |
| `test_realm_monsters.gd` | 통과: 기존 7 스킨, 범용 짝, 누락 파일 fallback |
| `test_hud_frames.gd` | 통과: NinePatch/ColorRect 양 모드 및 타이틀 배경 |
| 기존 `run_all.ps1 -SkipSoak`의 25개 테스트 | 고유 `--log-file`로 동일 목록 개별 실행, 25/25 통과 |
| 신규 테스트 포함 합계 | 27/27 통과 |
| `git diff --check` | 통과 |

기본 `run_all.ps1 -SkipSoak`는 병렬 빌더가 공유하는 기본 Godot 로그 잠금으로 출력 없이 대기해 중단했습니다. 카드 지시에 따라 같은 테스트 목록을 각각 고유 로그로 다시 실행했습니다. 모든 실행에서 샌드박스 고유의 `Failed to read the root certificate store` 한 줄만 별도 제외했고, 다른 `ERROR`, `SCRIPT ERROR`, `Parse Error`는 없었습니다.

`--headless --import`는 PNG 스캔을 수행했지만 샌드박스 밖 `AppData/Local/Godot` 편집기 캐시를 만들 수 없어 카드가 성공으로 간주하지 말라고 한 비인증서 `ERROR`를 출력했습니다. 교체 파일은 기존 경로의 `.import` 메타데이터를 그대로 사용했고, 런타임 테스트에서 모두 정상 로드됐습니다.

## 사람이 판단할 부분

- 새 배경은 기존보다 밝고 정보량이 많습니다. 현재 코드의 어두운 modulate/scrim 뒤에서 제목·결과 텍스트가 충분히 읽히는지 실제 창에서 확인이 필요합니다.
- 새 골렘의 수치상 면적은 mossling에 근접했지만 체형이 낮고 길어서 체감 무게는 취향 판단이 필요합니다.
- 메뉴 프레임은 기존 단일 `Label` 줄 간격에 맞춰 배치했습니다. 실제 폰트/창 비율에서 각 줄과 중심이 자연스러운지 확인이 필요합니다.
- result panel의 가는 장식 테두리가 전투 결과 표에 충분한 존재감을 주는지는 UI 취향 영역입니다.

## ImageGen 프롬프트 요약

- 배경: 기존 타이틀과 Concept1/2를 참조해 16:9 전체 가장자리까지 9개 렐름을 채우고, 상단 중앙 로고 안전 영역을 둔 고밀도 판타지 픽셀 아트. 텍스트·로고·테두리·여백 금지.
- 골렘: 기존 룬 골렘과 mossling/접촉 시트를 참조해 6×4 투명 스프라이트 시트, 동일 캐릭터 정체성, 더 큰 바위 실루엣, 공통 기준선. 텍스트·격자선·배경·효과 금지.

최종 생성 원본은 각각 `assets/art/ui/title_bg_source.png`, `assets/art/monsters/jotunheim_rune_golem_source.png`에 저장했습니다.

## 남은 작업 / 다음 권장 단계

- **남은 작업:** Part 3의 두 번째 몬스터는 9개 렐름 모두 미수행입니다.
- **다음 권장 단계:** 리드가 실제 창 시작/결과 화면을 한 번 확인한 뒤, 카드 순서대로 Asgard ranged부터 두 번째 몬스터 쌍을 별도 작업으로 진행하는 것이 안전합니다.

