// SYS-05 sound contract. Run from the repository root; no sound assets are created.
const fs = require('fs');
const rows = [];
function add(group,id,when,hook,fallback='',cap=3) { rows.push({group,id,when,hook,fallback,cap,world: (['Fighters','Skills','Monsters','Realms','Fallback'].includes(group) && id !== 'collapse_warning')}); }
const player='characters/common/PlayerBase.gd:';
for (const [id,when,hook,fallback] of [
 ['swing_light','기본 공격 시작: neutral/side/air_side', 'basic_attack','swing'],
 ['swing_heavy','기본 공격 시작: up/down/air_up/air_down', 'basic_attack','swing'],
 ['hit_light','막히지 않은 일반 적중, 최종 피해 < 10', 'apply_hit / _finish_absorbed_hit',''],
 ['hit_heavy','막히지 않은 일반 적중, 최종 피해 >= 10', 'apply_hit / _finish_absorbed_hit','hit_light'],
 ['hit_launch','강제 발사 또는 비흡수·비가드 넉백 >= 480 적중', 'apply_hit / apply_forced_launch_hit','hit_heavy'],
 ['hurt','비가드 적중·환경 피해', 'apply_hit / apply_forced_launch_hit / apply_environment_damage',''],
 ['guard','가드 적중(가드 버튼 입력 아님)', 'apply_hit / apply_forced_launch_hit',''],
 ['parry','패링 성공', '_perform_parry','guard'],
 ['jump','실제 지상/공중 점프 시작', '_restart_jump_motion',''],
 ['land','접지 false → true; 매 프레임 요청하지 않음', '_handle_landing_state',''],
 ['dash','Frey/Nova/Rio K 기술 시작; 공통 대시 입력 없음. 준비 동작부터 재생', 'skill_one','swing'],
 ['tumble','강한 넉백의 tumble 모션 진입', '_play_launch_hit_sprite','hurt'],
 ['ko','HP 0 영구 탈락; 링아웃만으로는 KO 아님', '_defeat',''],
 ['respawn','링아웃 또는 더미 부활', '_respawn','portal'],
]) add('Fighters',id,when,player+hook,fallback);
for (const ch of ['frey','luna','luna_brave','yuki','nova','rio']) {
 for (const slot of ['1','2']) add('Skills',`skill_${ch}_${slot}`,`${ch} 기술 ${slot}: 공통 래퍼에서 실행 후 공격 잠금/serial 증가 확인`,player+`skill_${slot==='1'?'one':'two'}`,'skill_cast');
 add('Skills',`ult_${ch}`, ch==='luna_brave'?'변신 중 실제 하트 레이저 후속 시전 성공':'궁극기 시작(후속 단계 중복 요청 없음)',player+'ultimate','ult_start',2);
}
add('Monsters','monster_windup','공격 예고 시작','scripts/RealmMonster.gd:_begin_windup','monster_attack');
for(const type of ['bite','charge','leap','slam','shell','bolt','lob','swoop','blink','homing']) add('Monsters','monster_'+type,`${type} 원형 공격 실행`,'scripts/RealmMonster.gd:_execute_action','monster_attack');
add('Monsters','monster_hurt','살아 있는 몬스터 적중','scripts/RealmMonster.gd:apply_hit','hurt');
add('Monsters','monster_defeat','몬스터 사망 확정','scripts/RealmMonster.gd:_die','ko');
add('Monsters','elite_appear','BR 정예 스폰 완료; story 직접 스폰은 미연결','scripts/RealmMonsterSpawner.gd:_try_spawn_elite','',1);
for(const [id,when,hook,fallback] of [
 ['hazard_warning','시간제 기믹 예고 시작','scripts/realms/RealmHazards.gd:_start_warning',''],
 ['eruption','분출 활성화','scripts/realms/RealmHazards.gd:_start_active',''],
 ['quake','지진 활성화','scripts/realms/RealmHazards.gd:_start_active',''],
 ['beam','빛줄기 활성화','scripts/realms/RealmHazards.gd:_start_active',''],
 ['vines','덩굴 다리 활성화','scripts/realms/RealmHazards.gd:_start_active',''],
 ['belt_reverse','벨트 방향 반전','scripts/realms/RealmHazards.gd:_start_active',''],
 ['gate_open','달빛 문 활성화','scripts/realms/RealmHazards.gd:_start_active','portal'],
 ['gate_travel','달빛 문 통과 완료','scripts/realms/RealmHazards.gd:_carry_through_gates','portal'],
 ['bush_rustle','수풀 은신 상태 변화; 이동 중 지속 소리 아님','characters/common/PlayerBase.gd:set_concealed',''],
 ['collapse_warning','현재 관찰 렐름 붕괴 배너 숨김 → 표시','scripts/ui/MatchHud.gd:set_warning_banner','hazard_warning'],
 ['portal','BR 포털 통과 완료; story exit는 story-session hook 필요','scripts/Main.gd:_move_through_portal',''],
]) add('Realms',id,when,hook,fallback,2);
for(const [id,when,hook] of [
 ['soul_pickup','사람 플레이어 소울 실제 증가(is_human; 수정·몬스터·스토리 보상 공통)','characters/common/PlayerBase.gd:add_souls'],
 ['card_offer','사람 카드 패널 첫 표시','scripts/ui/MatchHud.gd:show_card_offer'],
 ['card_pick','사람 플레이어 카드 실제 적용(is_human; 봇 재생 제외)','characters/common/PlayerBase.gd:apply_upgrade'],
 ['match_start','BR 또는 스토리 스테이지 시작','scripts/Main.gd:_start_match / _start_story'],
 ['results','BR 결과 표시; story result는 전용 hook 필요','scripts/ui/FrontendMenu.gd:show_results'],
 ['victory','유효한 BR 우승자 결과 표시','scripts/ui/FrontendMenu.gd:show_results'],
]) add('Progress',id,when,hook,'',2);
add('Menus/story','ui_move','사용자의 키/마우스 탐색으로 focus 변경(화면 초기 focus 제외)','scripts/ui/FrontendMenu.gd:_focus_from_navigation','ui_select',2);
add('Menus/story','ui_select','공통 메뉴 활성화·캐릭터 선택 확정','scripts/ui/FrontendMenu.gd:_activate / _input','',2);
add('Menus/story','ui_cancel','공통 Esc / 뒤로 버튼','scripts/ui/FrontendMenu.gd:_activate / _input','',2);
for(const id of ['story_text','story_advance']) add('Menus/story',id,'미연결: 대사 표시/진행은 허용 파일에 이벤트가 없음','needs a story-session hook','',1);
for(const [id,when,hook,fallback] of [
 ['music_title','타이틀 진입','scripts/ui/FrontendMenu.gd:show_title',''],
 ['music_select','선택창 진입(스토리 영웅 선택도 super 경유)','scripts/ui/FrontendMenu.gd:show_select','music_battle'],
 ['music_battle','BR 시작','scripts/Main.gd:_start_match',''],
 ['music_story','스토리 스테이지 시작; 대사별 전환은 전용 hook 필요','scripts/Main.gd:_start_story','music_battle'],
 ['music_results','BR 결과 화면','scripts/ui/FrontendMenu.gd:show_results','music_battle'],
]) add('Music',id,when,hook,fallback,1);
for(const [id,fallback] of [['swing',''],['skill_cast','swing'],['ult_start','skill_cast'],['monster_attack','swing']]) add('Fallback',id,'폴백 전용: 게임 이벤트에서 직접 요청하지 않음','scripts/audio/AudioManager.gd:_resolve',fallback,3);
fs.mkdirSync('smash-nine-prototype/scripts/audio',{recursive:true});
fs.writeFileSync('design/AUDIO.md',`# 사운드 연결 계약 · SYS-05\n\n음원은 아직 없다. 채택 파일은 효과음 \`assets/audio/sfx/<id>.ogg|wav\`, 음악 \`assets/audio/music/<id>.ogg|wav\`에 배치한다. AUD-01a의 12개 id는 그대로 유지하며 swing_light/heavy는 swing으로 폴백한다.\n\n매니저는 Main._ready에서 SceneTree 루트에 1회 생성한다(autoload 아님). 장면 재시작과 옵션/타이틀 전환을 넘어 유지된다. 버스 레이아웃 파일 없이 Master 아래 Music/SFX를 코드로 생성한다. 모든 효과음은 요청 id 및 최종 폴백 id 기준 동시 제한, 40ms 간격, 전역 24 voice 풀을 적용한다. 음악은 정상 상태 1 player, 0.5초 전환 동안만 이전 player를 겹친다.\n\n| 그룹 | id | 재생 시점·변경 이유 | 훅 (file:function) | fallback id | max voices | world |\n|---|---|---|---|---|---:|---|\n`+rows.map(r=>`| ${r.group} | \`${r.id}\` | ${r.when} | \`${r.hook}\` | ${r.fallback?'`'+r.fallback+'`':'—'} | ${r.cap} | ${r.world} |`).join('\n')+'\n\nworld=true는 source.realm_index 또는 명시적 options.realm이 Main.current_map_index와 같은 경우에만 재생한다. Main이 자신의 get.bind("current_map_index") callable을 넘겨 관전·스토리 맵 변경도 요청 시점에 반영한다. 렐름 미지정은 재생을 허용하고 probe의 no_realm에 센다. 필터는 요청 ID 기준이므로 전역 collapse_warning은 월드 ID로 폴백해도 전역이다. 메뉴·음악·진행은 필터하지 않으며 card_pick/soul_pickup은 기존 is_human으로 사람에게만 재생한다.\n\nstory_text/story_advance는 예약 id이며 미연결이다. StoryScreens/StoryDialogue/StorySession 변경 권한이 없으므로 대사·스토리 전용 결과·출구·정예의 정확한 훅은 후속 세션에서 추가한다. 공통 스토리 메뉴 버튼만 공통 훅을 상속한다.\n');
fs.writeFileSync('smash-nine-prototype/scripts/audio/AudioCatalog.gd','extends RefCounted\n## Runtime half of design/AUDIO.md (generated by reports/codex-sys-05/build_catalog.cjs).\nconst SOUNDS := {\n'+rows.map(r=>`\t"${r.id}": {"fallback": "${r.fallback}", "voices": ${r.cap}, "group": "${r.group}", "world": ${r.world}},`).join('\n')+'\n}\n');
console.log(`${rows.length} ids written`);
