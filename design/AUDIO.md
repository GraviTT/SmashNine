# 사운드 연결 계약 · SYS-05

음원은 아직 없다. 채택 파일은 효과음 `assets/audio/sfx/<id>.ogg|wav`, 음악 `assets/audio/music/<id>.ogg|wav`에 배치한다. AUD-01a의 12개 id는 그대로 유지하며 swing_light/heavy는 swing으로 폴백한다.

매니저는 Main._ready에서 SceneTree 루트에 1회 생성한다(autoload 아님). 장면 재시작과 옵션/타이틀 전환을 넘어 유지된다. 버스 레이아웃 파일 없이 Master 아래 Music/SFX를 코드로 생성한다. 모든 효과음은 요청 id 및 최종 폴백 id 기준 동시 제한, 카탈로그의 ID별 `gap_ms`(생략하면 40ms) 간격, 전역 24 voice 풀을 적용한다. 음악은 정상 상태 1 player, 0.5초 전환 동안만 이전 player를 겹친다.

| 그룹 | id | 재생 시점·변경 이유 | 훅 (file:function) | fallback id | max voices | gap_ms | world |
|---|---|---|---|---|---:|---:|---|
| Fighters | `swing_light` | 기본 공격 시작: neutral/side/air_side | `characters/common/PlayerBase.gd:basic_attack` | `swing` | 3 | 60 | true |
| Fighters | `swing_heavy` | 기본 공격 시작: up/down/air_up/air_down | `characters/common/PlayerBase.gd:basic_attack` | `swing` | 3 | 60 | true |
| Fighters | `hit_light` | 막히지 않은 일반 적중, 최종 피해 < 10 | `characters/common/PlayerBase.gd:apply_hit / _finish_absorbed_hit` | — | 3 | 50 | true |
| Fighters | `hit_heavy` | 막히지 않은 일반 적중, 최종 피해 >= 10 | `characters/common/PlayerBase.gd:apply_hit / _finish_absorbed_hit` | `hit_light` | 3 | 60 | true |
| Fighters | `hit_launch` | 강제 발사 또는 비흡수·비가드 넉백 >= 480 적중 | `characters/common/PlayerBase.gd:apply_hit / apply_forced_launch_hit` | `hit_heavy` | 3 | 40 | true |
| Fighters | `hurt` | 비가드 적중·환경 피해 | `characters/common/PlayerBase.gd:apply_hit / apply_forced_launch_hit / apply_environment_damage` | — | 3 | 70 | true |
| Fighters | `guard` | 가드 적중(가드 버튼 입력 아님) | `characters/common/PlayerBase.gd:apply_hit / apply_forced_launch_hit` | — | 3 | 40 | true |
| Fighters | `parry` | 패링 성공 | `characters/common/PlayerBase.gd:_perform_parry` | `guard` | 3 | 40 | true |
| Fighters | `jump` | 실제 지상/공중 점프 시작 | `characters/common/PlayerBase.gd:_restart_jump_motion` | — | 3 | 40 | true |
| Fighters | `land` | 접지 false → true 중 공중 시간이 0.12초 이상일 때만; 선수별 시간은 AudioManager가 물리 delta로 추적 | `characters/common/PlayerBase.gd:_handle_landing_state` | — | 3 | 150 | true |
| Fighters | `dash` | Frey/Nova/Rio K 기술 시작; 공통 대시 입력 없음. 준비 동작부터 재생 | `characters/common/PlayerBase.gd:skill_one` | `swing` | 3 | 40 | true |
| Fighters | `tumble` | 강한 넉백의 tumble 모션 진입 | `characters/common/PlayerBase.gd:_play_launch_hit_sprite` | `hurt` | 3 | 120 | true |
| Fighters | `ko` | HP 0 영구 탈락; 링아웃만으로는 KO 아님 | `characters/common/PlayerBase.gd:_defeat` | — | 3 | 40 | true |
| Fighters | `respawn` | 링아웃 또는 더미 부활 | `characters/common/PlayerBase.gd:_respawn` | `portal` | 3 | 40 | true |
| Skills | `skill_frey_1` | frey 기술 1: 공통 래퍼에서 실행 후 공격 잠금/serial 증가 확인 | `characters/common/PlayerBase.gd:skill_one` | `skill_cast` | 3 | 40 | true |
| Skills | `skill_frey_2` | frey 기술 2: 공통 래퍼에서 실행 후 공격 잠금/serial 증가 확인 | `characters/common/PlayerBase.gd:skill_two` | `skill_cast` | 3 | 40 | true |
| Skills | `ult_frey` | 궁극기 시작(후속 단계 중복 요청 없음) | `characters/common/PlayerBase.gd:ultimate` | `ult_start` | 2 | 40 | true |
| Skills | `skill_luna_1` | luna 기술 1: 공통 래퍼에서 실행 후 공격 잠금/serial 증가 확인 | `characters/common/PlayerBase.gd:skill_one` | `skill_cast` | 3 | 40 | true |
| Skills | `skill_luna_2` | luna 기술 2: 공통 래퍼에서 실행 후 공격 잠금/serial 증가 확인 | `characters/common/PlayerBase.gd:skill_two` | `skill_cast` | 3 | 40 | true |
| Skills | `ult_luna` | 궁극기 시작(후속 단계 중복 요청 없음) | `characters/common/PlayerBase.gd:ultimate` | `ult_start` | 2 | 40 | true |
| Skills | `skill_luna_brave_1` | luna_brave 기술 1: 공통 래퍼에서 실행 후 공격 잠금/serial 증가 확인 | `characters/common/PlayerBase.gd:skill_one` | `skill_cast` | 3 | 40 | true |
| Skills | `skill_luna_brave_2` | luna_brave 기술 2: 공통 래퍼에서 실행 후 공격 잠금/serial 증가 확인 | `characters/common/PlayerBase.gd:skill_two` | `skill_cast` | 3 | 40 | true |
| Skills | `ult_luna_brave` | 변신 중 실제 하트 레이저 후속 시전 성공 | `characters/common/PlayerBase.gd:ultimate` | `ult_start` | 2 | 40 | true |
| Skills | `skill_yuki_1` | yuki 기술 1: 공통 래퍼에서 실행 후 공격 잠금/serial 증가 확인 | `characters/common/PlayerBase.gd:skill_one` | `skill_cast` | 3 | 40 | true |
| Skills | `skill_yuki_2` | yuki 기술 2: 공통 래퍼에서 실행 후 공격 잠금/serial 증가 확인 | `characters/common/PlayerBase.gd:skill_two` | `skill_cast` | 3 | 40 | true |
| Skills | `ult_yuki` | 궁극기 시작(후속 단계 중복 요청 없음) | `characters/common/PlayerBase.gd:ultimate` | `ult_start` | 2 | 40 | true |
| Skills | `skill_nova_1` | nova 기술 1: 공통 래퍼에서 실행 후 공격 잠금/serial 증가 확인 | `characters/common/PlayerBase.gd:skill_one` | `skill_cast` | 3 | 40 | true |
| Skills | `skill_nova_2` | nova 기술 2: 공통 래퍼에서 실행 후 공격 잠금/serial 증가 확인 | `characters/common/PlayerBase.gd:skill_two` | `skill_cast` | 3 | 40 | true |
| Skills | `ult_nova` | 궁극기 시작(후속 단계 중복 요청 없음) | `characters/common/PlayerBase.gd:ultimate` | `ult_start` | 2 | 40 | true |
| Skills | `skill_rio_1` | rio 기술 1: 공통 래퍼에서 실행 후 공격 잠금/serial 증가 확인 | `characters/common/PlayerBase.gd:skill_one` | `skill_cast` | 3 | 40 | true |
| Skills | `skill_rio_2` | rio 기술 2: 공통 래퍼에서 실행 후 공격 잠금/serial 증가 확인 | `characters/common/PlayerBase.gd:skill_two` | `skill_cast` | 3 | 40 | true |
| Skills | `ult_rio` | 궁극기 시작(후속 단계 중복 요청 없음) | `characters/common/PlayerBase.gd:ultimate` | `ult_start` | 2 | 40 | true |
| Monsters | `monster_windup` | 공격 예고 시작 | `scripts/RealmMonster.gd:_begin_windup` | `monster_attack` | 3 | 40 | true |
| Monsters | `monster_bite` | bite 원형 공격 실행 | `scripts/RealmMonster.gd:_execute_action` | `monster_attack` | 3 | 40 | true |
| Monsters | `monster_charge` | charge 원형 공격 실행 | `scripts/RealmMonster.gd:_execute_action` | `monster_attack` | 3 | 40 | true |
| Monsters | `monster_leap` | leap 원형 공격 실행 | `scripts/RealmMonster.gd:_execute_action` | `monster_attack` | 3 | 40 | true |
| Monsters | `monster_slam` | slam 원형 공격 실행 | `scripts/RealmMonster.gd:_execute_action` | `monster_attack` | 3 | 40 | true |
| Monsters | `monster_shell` | shell 원형 공격 실행 | `scripts/RealmMonster.gd:_execute_action` | `monster_attack` | 3 | 40 | true |
| Monsters | `monster_bolt` | bolt 원형 공격 실행 | `scripts/RealmMonster.gd:_execute_action` | `monster_attack` | 3 | 40 | true |
| Monsters | `monster_lob` | lob 원형 공격 실행 | `scripts/RealmMonster.gd:_execute_action` | `monster_attack` | 3 | 40 | true |
| Monsters | `monster_swoop` | swoop 원형 공격 실행 | `scripts/RealmMonster.gd:_execute_action` | `monster_attack` | 3 | 40 | true |
| Monsters | `monster_blink` | blink 원형 공격 실행 | `scripts/RealmMonster.gd:_execute_action` | `monster_attack` | 3 | 40 | true |
| Monsters | `monster_homing` | homing 원형 공격 실행 | `scripts/RealmMonster.gd:_execute_action` | `monster_attack` | 3 | 40 | true |
| Monsters | `monster_hurt` | 살아 있는 몬스터 적중 | `scripts/RealmMonster.gd:apply_hit` | `hurt` | 3 | 70 | true |
| Monsters | `monster_defeat` | 몬스터 사망 확정 | `scripts/RealmMonster.gd:_die` | `ko` | 3 | 40 | true |
| Monsters | `elite_appear` | BR 정예 스폰 완료; story 직접 스폰은 미연결 | `scripts/RealmMonsterSpawner.gd:_try_spawn_elite` | — | 1 | 40 | true |
| Realms | `hazard_warning` | 시간제 기믹 예고 시작 | `scripts/realms/RealmHazards.gd:_start_warning` | — | 2 | 40 | true |
| Realms | `eruption` | 분출 활성화 | `scripts/realms/RealmHazards.gd:_start_active` | — | 2 | 40 | true |
| Realms | `quake` | 지진 활성화 | `scripts/realms/RealmHazards.gd:_start_active` | — | 2 | 40 | true |
| Realms | `beam` | 빛줄기 활성화 | `scripts/realms/RealmHazards.gd:_start_active` | — | 2 | 40 | true |
| Realms | `vines` | 덩굴 다리 활성화 | `scripts/realms/RealmHazards.gd:_start_active` | — | 2 | 40 | true |
| Realms | `belt_reverse` | 벨트 방향 반전 | `scripts/realms/RealmHazards.gd:_start_active` | — | 2 | 40 | true |
| Realms | `gate_open` | 달빛 문 활성화 | `scripts/realms/RealmHazards.gd:_start_active` | `portal` | 2 | 40 | true |
| Realms | `gate_travel` | 달빛 문 통과 완료 | `scripts/realms/RealmHazards.gd:_carry_through_gates` | `portal` | 2 | 40 | true |
| Realms | `bush_rustle` | 수풀 은신 상태 변화; 이동 중 지속 소리 아님 | `characters/common/PlayerBase.gd:set_concealed` | — | 2 | 40 | true |
| Realms | `collapse_warning` | 현재 관찰 렐름 붕괴 배너 숨김 → 표시 | `scripts/ui/MatchHud.gd:set_warning_banner` | `hazard_warning` | 2 | 40 | false |
| Realms | `portal` | BR 포털 통과 완료 또는 스토리 출구 Q 수락(카드 선택 대기는 제외) | `scripts/Main.gd:_move_through_portal / scripts/story/StorySession.gd:use_portal` | — | 2 | 40 | true |
| Progress | `soul_pickup` | 사람 플레이어 소울 실제 증가(is_human; 수정·몬스터·스토리 보상 공통) | `characters/common/PlayerBase.gd:add_souls` | — | 2 | 40 | false |
| Progress | `card_offer` | 사람 카드 패널 첫 표시 | `scripts/ui/MatchHud.gd:show_card_offer` | — | 2 | 40 | false |
| Progress | `card_pick` | 사람 플레이어 카드 실제 적용(is_human; 봇 재생 제외) | `characters/common/PlayerBase.gd:apply_upgrade` | — | 2 | 40 | false |
| Progress | `match_start` | BR 또는 스토리 스테이지 시작 | `scripts/Main.gd:_start_match / _start_story` | — | 2 | 40 | false |
| Progress | `results` | BR 결과 또는 스토리 성공·실패 결과 표시 | `scripts/ui/FrontendMenu.gd:show_results / scripts/ui/StoryScreens.gd:show_story_result` | — | 2 | 40 | false |
| Progress | `victory` | 유효한 BR 우승자 결과, 스토리 성공 결과 또는 엔딩 표시 | `scripts/ui/FrontendMenu.gd:show_results / scripts/ui/StoryScreens.gd:show_story_result / show_story_ending` | — | 2 | 40 | false |
| Menus/story | `ui_move` | 사용자의 키/마우스 탐색으로 focus 변경(화면 초기 focus 제외) | `scripts/ui/FrontendMenu.gd:_focus_from_navigation` | `ui_select` | 2 | 40 | false |
| Menus/story | `ui_select` | 공통 메뉴 활성화·캐릭터 선택 확정 | `scripts/ui/FrontendMenu.gd:_activate / _input` | — | 2 | 40 | false |
| Menus/story | `ui_cancel` | 공통 Esc / 뒤로 버튼 | `scripts/ui/FrontendMenu.gd:_activate / _input` | — | 2 | 40 | false |
| Menus/story | `story_text` | 실제 대사 한 줄 표시 시 1회(글자마다 반복하지 않음) | `scripts/ui/StoryDialogue.gd:_show_line` | — | 1 | 40 | false |
| Menus/story | `story_advance` | 플레이어 Next/Skip 수락 시 1회; 타이핑 즉시 표시도 포함 | `scripts/ui/StoryDialogue.gd:_activate` | — | 1 | 40 | false |
| Music | `music_title` | 타이틀 진입 | `scripts/ui/FrontendMenu.gd:show_title` | — | 1 | 40 | false |
| Music | `music_select` | 선택창 진입(스토리 영웅 선택도 super 경유) | `scripts/ui/FrontendMenu.gd:show_select` | `music_battle` | 1 | 40 | false |
| Music | `music_battle` | BR 시작 | `scripts/Main.gd:_start_match` | — | 1 | 40 | false |
| Music | `music_story` | 스토리 스테이지 시작; 대화·전투 중 유지 | `scripts/Main.gd:_start_story` | `music_battle` | 1 | 40 | false |
| Music | `music_results` | BR 결과, 스토리 성공·실패 결과 또는 엔딩 화면 | `scripts/ui/FrontendMenu.gd:show_results / scripts/ui/StoryScreens.gd:show_story_result / show_story_ending` | `music_battle` | 1 | 40 | false |
| Fallback | `swing` | 폴백 전용: 게임 이벤트에서 직접 요청하지 않음 | `scripts/audio/AudioManager.gd:_resolve` | — | 3 | 40 | true |
| Fallback | `skill_cast` | 폴백 전용: 게임 이벤트에서 직접 요청하지 않음 | `scripts/audio/AudioManager.gd:_resolve` | `swing` | 3 | 40 | true |
| Fallback | `ult_start` | 폴백 전용: 게임 이벤트에서 직접 요청하지 않음 | `scripts/audio/AudioManager.gd:_resolve` | `skill_cast` | 3 | 40 | true |
| Fallback | `monster_attack` | 폴백 전용: 게임 이벤트에서 직접 요청하지 않음 | `scripts/audio/AudioManager.gd:_resolve` | `swing` | 3 | 40 | true |

world=true는 source.realm_index 또는 명시적 options.realm이 Main.current_map_index와 같은 경우에만 재생한다. Main이 자신의 get.bind("current_map_index") callable을 넘겨 관전·스토리 맵 변경도 요청 시점에 반영한다. 렐름 미지정은 재생을 허용하고 probe의 no_realm에 센다. 필터는 요청 ID 기준이므로 전역 collapse_warning은 월드 ID로 폴백해도 전역이다. 메뉴·음악·진행은 필터하지 않으며 card_pick/soul_pickup은 기존 is_human으로 사람에게만 재생한다.

SYS-08: 대화·스토리 결과·엔딩·출구는 각 소유 함수의 한 줄 AudioManager 훅으로 연결한다. 성공·실패 결과는 results → (성공 시 victory) → music_results, 엔딩은 victory → music_results 순서다. 스토리 정예 직접 스폰의 elite_appear는 이 카드 범위 밖으로 기존 계약을 유지한다. 공통 스토리 메뉴 버튼은 기존 공통 훅을 상속한다.

SYS-08 간격은 카드의 시작값을 그대로 사용한다: land 150ms, hurt/monster_hurt 70ms, hit_light 50ms, hit_heavy/swing_light/swing_heavy 60ms, tumble 120ms. 나머지는 기본 40ms다. 요청 ID와 최종 폴백 ID 각각의 간격을 모두 충족해야 하며, 누락 음원·거부 요청은 마지막 재생 시각을 갱신하지 않는다. 간격은 실제 시간(Time.get_ticks_usec), 공중 시간은 기존 착지 훅이 호출된 물리 delta 기준이라 게임 이동·점프·애니메이션 타이밍을 바꾸지 않는다. 선수 노드가 트리에서 나가면 착지 추적 상태를 지운다.
