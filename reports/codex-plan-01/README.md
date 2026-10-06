# CODEX-PLAN-01 결과 — 로드맵 초안 검토 (Codex 분석 유닛, 2026-10-06)

원문 그대로 보관. 링크는 Codex 클론 경로 기준.

검증 표시는 다음과 같습니다.

- **검증**: 문서·코드·콘셉트 원화에서 직접 확인했습니다.
- **제안/가설**: 아직 플레이테스트가 필요한 수치·판단입니다.
- 지시대로 파일 수정, Godot 실행, 서버·브라우저 실행은 하지 않았습니다. 기존 “헤드리스 테스트 4개 통과”는 초안의 보고이며 이번 세션에서 재실행하지 않았습니다.

## 1. D1–D12 판단

| 결정 | 판단 | 독립 의견과 구체안 | 근거 |
|---|---|---|---|
| **D1 탈락** | **수정 동의** | HP 0은 영구 탈락, 링아웃은 같은 렐름 리스폰에 동의합니다. 단, 렐름 붕괴는 곧바로 영구 탈락시키지 말고 **30 고정 피해 → 생존 시 인접 안전 렐름 강제 이동 + 1초 보호**로 분리해야 합니다. 링아웃 피해 제안값은 단계별 **20/25/30/40 HP**입니다. | 최신 목표는 HP 0 탈락·링아웃 피해를 명시합니다([FINAL_GAME_GOAL.md:79](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/FINAL_GAME_GOAL.md:79)). 현재는 HP 0 후 3초 리스폰합니다([PlayerBase.gd:1036](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/characters/common/PlayerBase.gd:1036), [PlayerBase.gd:1048](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/characters/common/PlayerBase.gd:1048)). 붕괴 시 안전 렐름으로 먼저 옮긴 뒤 HP 0 처리하는 현재 동작도 확인했습니다([Main.gd:467](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/Main.gd:467)). |
| **D2 중앙 개방** | **수정** | 중앙은 **3:30**, 즉 2차 붕괴 자체가 아니라 **2차 경고 시작과 동시에** 개방하는 것이 맞습니다. 그래야 가장자리 중앙 4개 렐름에서 중앙으로 30초간 탈출할 수 있습니다. | 중앙 후반 개방은 최신 목표와 일치합니다([FINAL_GAME_GOAL.md:73](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/FINAL_GAME_GOAL.md:73)). 초안 D2의 “2차 붕괴와 맞춤”과 D3의 3:30 개방은 서로 다릅니다([ROADMAP_DRAFT.md:31](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/design/ROADMAP_DRAFT.md:31), [ROADMAP_DRAFT.md:32](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/design/ROADMAP_DRAFT.md:32)). |
| **D3 붕괴 일정** | **수정** | **2:00 네 모서리 경고 → 2:30 붕괴 → 3:30 중앙 개방 및 변 중앙 4개 경고 → 4:00 붕괴 → 6:00 서든데스 → 7:00 디버그용 강제 판정**을 권합니다. 4:30 2차 붕괴는 원안보다 30초 늦습니다. 붕괴 그룹은 랜덤보다 연결성이 보장되는 고정 토폴로지가 우선입니다. | 구 GDD는 모서리 4개를 Phase 2, 중앙에 인접한 변 4개를 Phase 3으로 지정합니다([GAME_DESIGN_DOCUMENT.md:23](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine/GAME_DESIGN_DOCUMENT.md:23), [GAME_DESIGN_DOCUMENT.md:31](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine/GAME_DESIGN_DOCUMENT.md:31)). 타임라인도 4분부터 중앙 집결입니다([GAME_DESIGN_DOCUMENT.md:200](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine/GAME_DESIGN_DOCUMENT.md:200)). 콘셉트 1의 6번 패널도 2/4/6/7분 구조입니다. |
| **D4 성장** | **동의, M1로 당김** | EXP/Lv.10을 제거하고 누적 소울 **25/50/75**에서 3회 선택하는 방향에 동의합니다. M1에서는 풀 랜덤 풀 대신 `공격 +12%`, `최대 HP +15 및 15 회복`, `이동속도 +8%` 세 카드만 사용하고 **5초 후 자동 선택**, 봇은 시드 기반 선택이면 충분합니다. | 최신 목표가 3회 성장 선택을 핵심 차별점으로 둡니다([FINAL_GAME_GOAL.md:113](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/FINAL_GAME_GOAL.md:113), [FINAL_GAME_GOAL.md:122](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/FINAL_GAME_GOAL.md:122)). 현재는 몬스터 EXP와 자동 레벨 성장입니다([PlayerBase.gd:1148](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/characters/common/PlayerBase.gd:1148)). 수치는 **검증 전 제안값**입니다. |
| **D5 이름/테마** | **수정 동의** | 8개 외곽은 북유럽 세계 이름을 사용하되, 중앙은 **‘이그드라실의 심장’ 또는 ‘Realm Nexus’**로 명시해야 합니다. “정통 북유럽 9세계”라고 부르면 중앙과 헬하임 처리 때문에 모순이 생깁니다. 헬하임은 후속 대체 맵으로 보류합니다. | 콘셉트 1 지도는 중앙을 포함해 실제로 10칸을 보여 줍니다. 반면 GDD는 헬하임을 제외한 외곽 8개+중앙으로 9칸을 정의합니다([GAME_DESIGN_DOCUMENT.md:17](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine/GAME_DESIGN_DOCUMENT.md:17)). |
| **D6 렐름 크기** | **반대** | `2560×1440`도 외곽 렐름당 약 2명에는 큽니다. M1 가설은 **외곽 1280×720 1화면, 중앙 1920×1080 1.5화면**입니다. 먼저 이 크기로 만남 빈도를 검증한 뒤 확대해야 합니다. | 현재는 1280×720 레이아웃을 3×3 반복해 3840×2160을 만듭니다([Main.gd:22](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/Main.gd:22), [Main.gd:256](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/Main.gd:256)). 최신 목표는 “fast, dense”를 요구합니다([FINAL_GAME_GOAL.md:20](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/FINAL_GAME_GOAL.md:20)). 제안 크기는 **플레이테스트 가설**입니다. |
| **D7 인원** | **수정 동의** | M1 8명은 적절하지만, **모서리 4개 렐름에 2명씩** 스폰해야 합니다. 16명 단계에서는 외곽 8개에 2명씩입니다. 현재 방식으로 8명을 넣으면 8개 외곽에 한 명씩 갈라져 초기 PvP가 사라집니다. | 현재 스폰은 중앙을 뺀 렐름을 섞고 플레이어마다 다른 렐름을 사용합니다([Main.gd:840](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/Main.gd:840)). 코드 상한도 4명이며([Main.gd:1000](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/Main.gd:1000)), 4개 캐릭터 ID를 `ids[i]`로 직접 참조해 단순히 8로 바꾸면 실패합니다([Main.gd:845](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/Main.gd:845)). |
| **D8 기믹** | **동의** | M1 고유 기믹 0개가 맞습니다. 단, 공통 붕괴 경고·포털 탈출·강제 이동은 핵심 루프이므로 반드시 완성해야 합니다. | 고유 기믹은 최종 목표이지만([FINAL_GAME_GOAL.md:65](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/FINAL_GAME_GOAL.md:65)), M1에서 9개를 만들면 AI 대응과 가독성 검증 비용까지 함께 생깁니다. |
| **D9 유령/팀/온라인** | **동의** | 모두 보류해야 합니다. 특히 유령 장난은 탈락자 유지에는 좋지만 생존자에게 불공정 변수를 추가하므로 솔로 규칙 이후가 맞습니다. | 최신 목표가 솔로 안정화 뒤 팀·온라인 확장을 명시합니다([FINAL_GAME_GOAL.md:368](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/FINAL_GAME_GOAL.md:368)). |
| **D10 공격 타이머** | **조건부 동의** | M1에서는 공격 `await`를 유지합니다. 다만 “연출 패스”가 아니라 **온라인·리플레이·슬로모션 전에** 프레임/상태 기반 스케줄러로 바꿔야 합니다. 매치 타임라인은 지금부터 `delta` 주입식 상태 머신으로 분리해야 합니다. | 런타임 `create_timer`는 총 12곳이고, 그중 공격 순서용 `await`는 9곳입니다. 공통 공격 시작도 타이머 기반입니다([PlayerBase.gd:653](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/characters/common/PlayerBase.gd:653)). |
| **D11 렌더러** | **수정** | Compatibility 방향에는 동의하지만 M1 핵심 선행 작업은 아닙니다. 설정 변경만 하지 말고 **Compatibility PC 실행 + Web export smoke**를 같은 완료 조건으로 묶어야 합니다. | `project.godot`에는 렌더링 방식이 명시돼 있지 않아 “현행 Forward+”는 기본값에 근거한 **추론**입니다([project.godot:15](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/project.godot:15)). |
| **D12 아트** | **반대** | M1에서는 AI 배경·카드 이미지를 만들지 않는 편이 낫습니다. 라이선스가 기록된 임시 캐릭터와 절차형 배경을 유지하고, 전투 크기와 카메라가 확정된 뒤 **중앙 렐름 1개만** 아트 버티컬 슬라이스로 제작해야 합니다. | 현재 임시 아트는 출처와 라이선스가 문서화돼 있습니다([THIRD_PARTY_ASSETS.md:3](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/assets/THIRD_PARTY_ASSETS.md:3)). 최종 아트 기준도 화려함보다 전투 가독성을 우선합니다([FINAL_GAME_GOAL.md:380](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/FINAL_GAME_GOAL.md:380)). |

## 2. M1 계획 검토

결론은 **현재 M1은 “끝나는 기술 데모”에는 가깝지만 “재미를 판단할 수 있는 한 판”에는 부족합니다.** 전체 `Main.gd` 분할과 프론트엔드가 앞에 있고, 반대로 만남 밀도·봇 신뢰성·최소 성장 선택은 M2로 밀려 있습니다.

권장 M1 흐름은 다음과 같습니다.

```text
0:00       2:00  2:30       3:30  4:00             6:00       7:00
탐색/2인전 ─ 경고 ─ 모서리 붕괴 ─ 중앙 개방+경고 ─ 변 4개 붕괴/중앙전 ─ 서든데스 ─ 안전장치
 8개 중       4개                  중앙 탈출로 개방                         축소·고정 피해
 모서리 4개 사용
```

위 타임라인은 모서리 → 중앙 인접 렐름 → 중앙으로 이동 경로가 항상 존재하도록 만든 구조입니다.

### M1에 반드시 있어야 하는 것

- 영구 탈락, 생존자 집계, 승자 1명, 결과 상태, 재시작.
- 위 타임라인을 소유하는 독립 `MatchDirector`.
- 8명 스폰 밀도와 작은 그레이박스 렐름.
- 붕괴 시 포털 탈출과 강제 이전의 명확한 규칙.
- 봇의 붕괴 회피·포털 이동·궁극기 사용 규칙.
- 25/50/75 최소 소울 선택 세로 슬라이스.
- 시드·탈락 원인·첫 PvP 시간·렐름 인원·소울 선택을 기록하는 매치 텔레메트리.
- 매치 전체를 실제로 끝까지 돌리는 자동 소크 테스트.

### M1에서 잘라낼 것

- 완성형 타이틀/캐릭터 선택 화면. 디버그용 캐릭터 파라미터와 간단한 결과 오버레이면 충분합니다.
- `Main.gd`의 6개 모듈 일괄 분리. 우선 `MatchDirector`, `RealmCatalog/Geometry`, `SpawnDirector` 세 경계만 추출하는 편이 안전합니다.
- 9개 고유 기믹, 완성 배경, 카드 일러스트, 사운드, 패드, 팀전, 온라인.
- 9개 렐름의 완성형 고유 레이아웃. M1은 크기·밀도 검증용 그레이박스면 됩니다.
- 렌더러·README 정리는 핵심 루프 이후 별도 유지보수 묶음으로 처리합니다.

### 숨은 비용

- 렐름 크기는 `Main.gd`만의 상수가 아닙니다. AI에도 3840×2160과 720행이 하드코딩돼 있습니다([EnemyAI.gd:44](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/EnemyAI.gd:44), [EnemyAI.gd:251](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/EnemyAI.gd:251)). 크기 변경은 공통 `RealmGeometry`가 소유해야 합니다.
- EXP 제거는 `PlayerBase`, 몬스터 보상, HUD, 캐릭터 교체 상태 복사까지 영향을 줍니다.
- 재시작은 남아 있는 `SceneTreeTimer`, 투사체, 트윈이 이전 매치에 콜백하지 않도록 매치 세션 ID 또는 취소 토큰이 필요합니다.
- 기존 테스트 4개는 캐릭터·애니메이션 중심입니다. 예를 들어 캐릭터 아키텍처 테스트는 4캐릭터와 일부 기술만 검사합니다([test_character_architecture.gd:13](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/tests/test_character_architecture.gd:13)). 매치 종료·붕괴·승자 테스트와 통합 `tests/run_all`은 현재 없습니다.

## 3. Red-team 결과

| 심각도 | 실패 시나리오와 근거 | 소유 컴포넌트 | 올바른 수정인가 |
|---|---|---|---|
| **P0** | HP 0이 3초 후 되살아나므로 승자가 나올 수 없습니다. | `PlayerBase` 생명주기 + `MatchDirector` | **정식 수정**: 링아웃 리스폰과 HP 0 탈락을 별도 상태로 분리. |
| **P0** | 현재 붕괴는 플레이어를 안전 렐름으로 옮긴 직후 HP 0으로 만듭니다. D1을 단순 적용하면 경고를 놓친 전원이 영구 탈락합니다. | `MatchDirector`의 붕괴 정책 | **정식 수정**: `collapse_penalty`와 `eliminate`를 분리. 경고 연장만은 우회책입니다. |
| **P0** | 8명 설정은 아직 구현되지 않았습니다. 상한은 4이고 4개 캐릭터 ID를 인덱스로 직접 사용합니다. | `Roster/SpawnDirector` | **정식 수정**: ID 순환·명시적 로스터·4개 렐름 2명 배치. |
| **P0** | 봇은 궁극기를 전혀 선택하지 않지만 인간은 별도 자원이나 쿨다운 없이 반복 사용 가능합니다([EnemyAI.gd:228](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/EnemyAI.gd:228), [PlayerBase.gd:277](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/characters/common/PlayerBase.gd:277)). 봇전 승률이 밸런스 자료가 되지 않습니다. | 공유 `ActionAvailability` + `EnemyAI` | **정식 수정**: M1 공통 궁극기 쿨다운 30초와 봇 사용 규칙. 봇 스탯 보정은 우회책입니다. |
| **P1** | 오프스크린 AI는 0.25초마다 호출되지만 실제 호출에는 한 프레임 `delta`만 전달합니다([Main.gd:1046](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/Main.gd:1046)). 60fps 가정 시 1.4~4.5초 판단 타이머가 약 **21~67.5초**로 느려집니다. | `Main` AI 스케줄러/`EnemyAI` 시간 계약 | **정식 수정**: 누적 경과시간 또는 고정 0.25초를 전달. 확률 증가만은 우회책입니다. |
| **P1** | 8명을 외곽 8개에 한 명씩 보내면 몬스터만 사냥하고 사람을 만나지 않을 가능성이 큽니다. AI는 같은 렐름 대상만 유효하게 봅니다([EnemyAI.gd:583](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/EnemyAI.gd:583)). | `SpawnDirector` | **정식 수정**: 2명씩 모서리 4개에 배치. AI 순간이동은 우회책입니다. |
| **P1** | 초기 몬스터는 렐름당 18마리, 중앙이 잠겼으므로 실제 초기 최대는 **144마리**입니다. 모두 물리 처리를 가집니다([RealmMonsterSpawner.gd:4](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/RealmMonsterSpawner.gd:4), [RealmMonster.gd:125](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/RealmMonster.gd:125)). 성능과 소울 농사 모두 왜곡될 수 있습니다. | `RealmMonsterSpawner` + `SoulEconomy` | **정식 수정**: M1은 외곽당 4마리, 초기 총 32마리 상한. 단순 렌더러 하향은 우회책입니다. |
| **P1** | 현재 월드는 상태 변경 때 9개 렐름 전체를 폐기·재생성합니다([Main.gd:482](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/Main.gd:482)). 코드 계산상 포털 전에도 정적 발판 **657개**, 스폰 마커 **648개**입니다. | `WorldBuilder/RealmInstance` | **정식 수정**: 변경 렐름만 상태 갱신·제거. 그래픽 품질을 낮추는 것은 우회책입니다. |
| **P1** | 투사체 타이머는 `_ready()`에서 기본 lifetime으로 시작되고 실제 lifetime 설정은 그 뒤입니다([Projectile.gd:15](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/Projectile.gd:15), [Projectile.gd:22](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/Projectile.gd:22)). 요청한 수명이 적용되지 않을 수 있으며, 콜백 안에서 `monitoring`을 즉시 바꾸는 오류도 있습니다([Projectile.gd:54](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/Projectile.gd:54)). | `Projectile` | **정식 수정**: configure 후 타이머 시작, 모니터링은 deferred 변경. |
| **P1** | 소울을 몬스터 처치 중심으로 그대로 옮기면 강한 캐릭터가 더 빨리 성장해 추가 처치를 독점합니다. 현재 몬스터는 7초 후 다시 찹니다([RealmMonsterSpawner.gd:67](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/RealmMonsterSpawner.gd:67)). | `SoulEconomy` | **정식 수정**: 보상 원천별 텔레메트리·75 상한·리스폰 20초부터 검증. 몬스터 HP만 올리는 것은 우회책입니다. |
| **P1** | `EnemyAI`가 `Main`의 비공개 `_get_realm_state`를 직접 호출합니다([EnemyAI.gd:737](C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine/smash-nine-prototype/scripts/EnemyAI.gd:737)). 리팩터 중 이름만 바뀌어도 붕괴 회피가 조용히 깨질 수 있습니다. | 아키텍처 경계 | **정식 수정**: 공개 `RealmStateProvider` 계약 또는 Callable 주입. 호환용 빈 메서드 복제는 우회책입니다. |
| **P2** | 프론트엔드·아트·렌더러를 M1에 함께 넣으면 “한 판이 끝나는가” 실패 원인을 분리하기 어렵습니다. | 마일스톤 관리 | 기능 결함이 아니라 **범위 조정** 대상입니다. |

## 4. 제안 M1 작업 목록과 자동 완료 기준

| 순서 | 작업 | 헤드리스/봇 완료 기준 |
|---:|---|---|
| 1 | `tests/run_all`과 시드 기반 매치 기록기 작성 | 기존 4개 테스트가 한 명령에서 exit code 0. 로그에 seed, 시간, 렐름 인원, 피해, 링아웃, 소울, 탈락 원인이 남음. |
| 2 | 투사체·일시 오브젝트 수명 오류부터 안정화 | 서로 다른 lifetime 0.2/1.0/1.35초가 오차 1 physics frame 이내. 고아 투사체 100개 정리 시 오류 0건. |
| 3 | `MatchDirector`와 설정 데이터 추출 | 가상 시간 주입 테스트에서 전이가 정확히 `120/150/210/240/360/420초`에 각각 한 번만 발생. `Main.gd` 프레임률과 무관. |
| 4 | 링아웃·탈락·승리 규칙 구현 | 링아웃 후 HP>0이면 같은 렐름 복귀, HP 0이면 10초 이후에도 부활하지 않음. 생존자가 1명이 되는 프레임에 승자 신호가 정확히 1회 발생. |
| 5 | 렐름 토폴로지·크기·스폰 밀도 적용 | 외곽 1280×720, 중앙 1920×1080. 8명은 모서리 4곳에 정확히 2명씩. 경고 렐름마다 안정 렐름으로 향하는 경로가 최소 1개 존재. |
| 6 | 붕괴 이동과 봇 시간 계약 수정 | 경고 후 봇 탈출 판단이 0.7초 안에 시작. 붕괴 1초 뒤 무너진 렐름 생존자 0명. 실패자는 30 피해 후 안전 렐름에 존재하거나 HP 0으로 탈락. |
| 7 | 봇 행동 동등성 확보 | 기본/스킬1/스킬2/궁극기를 모두 호출 가능. 인간과 봇 모두 궁극기 30초 공통 쿨다운. 100회 시뮬레이션에서 쿨다운 위반 0건. |
| 8 | 최소 소울 선택 구현 | 누적 25/50/75에서 정확히 3번만 선택. 5초 미선택 시 자동 선택. 같은 seed의 봇은 같은 카드를 선택. 네 번째 선택은 발생하지 않음. |
| 9 | 부분 렐름 갱신·최소 결과/재시작 | 경고 시 안정 렐름 노드 ID와 노드 수가 변하지 않음. 결과 → 재시작 10회 후 플레이어·몬스터·투사체 수가 기준값으로 복귀하고 이전 매치 콜백 0건. |
| 10 | 100-seed 8봇 소크 게이트 | 100/100 매치가 420초 이내 종료하고 승자 1명. P10 매치 길이 ≥240초, 중앙 진입 매치 ≥95%, 첫 PvP 적중 중앙값 ≤20초, 엔진 오류 0건. 고정 벤치마크 PC에서 physics frame P95 ≤16.7ms. |

강제 420초 판정은 프로토타입이 영원히 멈추지 않게 하는 **디버그 안전장치**입니다. 실제 출시 규칙으로 채택할지는 사람 플레이테스트 후 결정해야 합니다.

## 5. 사람만 판단할 수 있는 것

자동 테스트는 규칙 준수와 빈도를 측정할 수 있지만 다음은 직접 플레이해야 합니다.

- 프레이의 입력→동작→타격→넉백이 실제로 묵직하고 읽히는가.
- 외곽 2인전과 중앙 4~8인전이 “밀도 높음”인지, 단순한 화면 혼란인지.
- 30초 붕괴 경고와 포털 이동이 긴장감인지 이동 노동인지.
- 강제 이동 30 피해가 납득 가능한 벌인지 억울한 탈락인지.
- 25/50/75 선택이 전술을 바꾸는지, 숫자만 커지는지.
- 조기 탈락이 배틀로얄 긴장으로 느껴지는지, 5분 동안 관전해야 하는 좌절인지.
- 콘셉트 원화의 다크 코스믹 배경이 작은 픽셀 캐릭터와 공격 예고를 가리지 않는지.

첫 인간 검증은 6판이면 충분합니다. 4캐릭터를 최소 한 번씩 사용하고 `조작 반응`, `타격 명료성`, `첫 전투까지의 시간`, `붕괴 공정성`, `성장 선택의 의미`, `중앙전 가독성`을 5점 척도로 기록해야 합니다. 이 중 핵심 네 항목의 중앙값이 4 미만이면 아트나 추가 콘텐츠보다 전투·밀도·붕괴 규칙을 먼저 재조정하는 것이 맞습니다.