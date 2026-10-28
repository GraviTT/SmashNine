# ART-91 모션 목록과 누락 우선순위

작성: 2026-10-28T14:46:43.413274+09:00 · 브랜치 codex/art-91 · 정적 조사

## 확인한 사실
- 전투원 8형태·몬스터 18종. bakeoff PNG 554개 전수 확인: 버전 파일 539개, 기타 15개. JSON에는 모든 경로·크기·채택 값·PNG 해시를 보존했다.
- `채택`은 JSON adopted 값이 있는 기록이다. 최신 버전이라는 이유만으로 채택되었다고 판단하지 않는다. 게임 행은 실제 게임 시트 크기와 로더 테이블로 별도 확인했다.
- 현재 몬스터 18종 게임 시트는 모두 576×384로 idle/walk/attack/hurt 4행이다. 6행 후보와 ART_ROWS_SIX 지원 코드가 존재해도 현재 게임 시트와 같지는 않다.
- 전투원 OPTIONAL_MOTION_ROWS는 jump/fall/hurt/land/victory를 지원하지만 이 클론의 해당 전용 PNG 유무와 로더 규격 검사를 아래에 따로 기록한다.
- 행 FPS는 MotionSpeeds 값이 있으면 반영했다. 기술의 실제 타격 타이밍은 pose clock으로 제어되므로 단순 fps만으로 재생 시간을 단정하지 않는다.
- 별도 표시 없는 우선순위·fps·동작 필요성은 제작 제안이며 기존 게임 규칙이나 플레이 검증 결과가 아니다.

## 누락 일반 동작 우선순위(제안)
전투원은 8형태 전체, 몬스터는 18종 전체를 각각 대조했다. 크기·발선은 셀 규격이며 몸 크기는 해당 형태 idle에 맞춘다. 공중/벽 동작의 feet는 정렬 기준이지 모든 프레임 접지를 뜻하지 않는다.

|대상|동작|우선|누락 수|셀/발|프레임/fps/반복|참조|담당·이유|
|---|---|---:|---:|---|---|---|---|
|fighter|dodge_roll|1|8|192/152|6/12/False|idle + tumble|ART-92 진행 중(카드 지정; 다른 클론 결과 미확인) · 회피의 시작·끝과 자세를 읽기 쉽게 구분|
|fighter|stun|1|8|128/120|6/8/True|idle + hurt|ART-92 진행 중(카드 지정; 다른 클론 결과 미확인) · 피격 반동과 지속 기절 상태를 구분|
|fighter|run_start|1|8|128/120|6/12/False|idle + walk|ART-92 진행 중(카드 지정; 다른 클론 결과 미확인) · 대기에서 이동으로 체중 이동을 연결|
|fighter|run_stop|1|8|128/120|6/12/False|idle + walk|후속 후보 · 이동 정지의 감속과 자세 회복|
|fighter|air_recovery|1|8|192/152|6/12/False|idle + tumble|후속 후보 · 날아감에서 자세 회복을 구분; 기술 복귀기와 별개|
|fighter|guard_break|2|8|192/152|6/10/False|idle + shield|후속 후보 · 방어가 무너지는 반응; 규칙 도입 여부는 별도|
|fighter|portal_enter|2|8|128/120|6/10/False|idle + idle|후속 후보 · 렐름 이동 직전의 몸 동작|
|fighter|portal_exit|2|8|128/120|6/10/False|idle + land|후속 후보 · 렐름 이동 직후 자세 회복|
|fighter|crouch|2|8|128/120|6/8/True|idle + idle|ART-92 진행 중(카드 지정; 다른 클론 결과 미확인) · 낮은 대기 자세; 앉기 규칙은 별도|
|fighter|taunt|2|8|192/152|6/8/False|idle + victory|ART-92 진행 중(카드 지정; 다른 클론 결과 미확인) · 캐릭터 성격과 도발 표현|
|fighter|grab|3|8|192/152|6/10/False|idle + shield|후속 후보 · 잡기 시스템 결정이 먼저 필요|
|fighter|throw|3|8|192/152|6/12/False|idle + attack|후속 후보 · 잡기/던지기 규칙·방향 확정 필요|
|fighter|wall_cling|3|8|192/152|6/8/True|idle + fall|후속 후보 · 벽 상호작용 규칙 확정 필요|
|fighter|wall_jump|3|8|192/152|6/12/False|idle + jump|후속 후보 · 벽 점프 규칙 확정 필요|
|fighter|ledge_grab|3|8|192/152|6/8/True|idle + fall|후속 후보 · 매달리기 규칙 확정 필요|
|fighter|ledge_climb|3|8|192/152|6/10/False|idle + land|후속 후보 · 턱 오르기 규칙 확정 필요|
|fighter|surprise|3|8|128/120|6/8/False|idle + idle|후속 후보 · 스토리 몸 연기 확장|
|fighter|laugh|3|8|192/152|6/8/True|idle + victory|후속 후보 · 스토리 몸 연기 확장|
|monster|appear|1|18|96/72|6/10/False|idle + windup|ART-91: appear 전 종 → rage 전 종 → 여유 시 sleep/flee · 스폰 순간부터 준비 자세까지 몸 동작으로 식별|
|monster|rage|2|18|96/72|6/10/False|idle + windup|ART-91: appear 전 종 → rage 전 종 → 여유 시 sleep/flee · 공격과 구분되는 분노 예고; 분노 규칙은 미확정|
|monster|sleep|3|18|96/72|6/6/True|idle + defeat|ART-91: appear 전 종 → rage 전 종 → 여유 시 sleep/flee · 비전투 생태 표현; 수면 규칙은 미확정|
|monster|flee|3|18|96/72|6/10/True|idle + walk|ART-91: appear 전 종 → rage 전 종 → 여유 시 sleep/flee · 퇴각 상태 표현; 도주 규칙은 미확정|

## 중복 제작 제외·기술 세션 경계
- ART-92: dodge_roll, taunt, stun, crouch, run_start. 이 클론에는 아직 후보가 없으며 다른 클론의 진행 결과는 확인하지 않았다.
- 기술 세션: 아래 각 형태의 MOVE_SHEET_ROWS 중 tumble을 제외한 모든 공격/J·K·L·I 행과 해당 *_moves_README.md의 행. 몬스터 special_attack도 일반 모션 제작에서 제외하며 행동·판정 확정 후 별도 기술 작업으로 넘긴다.
- `tumble`은 기술 시트에 저장되어도 피격 일반 동작이다. 이미 있으므로 새 회피와 혼동하지 않는다.
- Frey attack_chain은 frey-attack 후보, Luna star_side는 luna-attack 후보를 쓰는 별칭이다. 별칭 후보 파일명이 없다는 이유로 미제작으로 세지 않았다.
- 후보가 이미 있는 land/victory/defeat와 다프레임 jump/fall/hurt는 새 그림 누락이 아니라 채택·통합 검토 대상이다.
- 문서의 Nova 핵 재입력/발사, Rio 반격, 공중 방향 파생 등은 기존 동작 재사용 또는 독립 행 부재가 있을 수 있다. 이를 새 일반 동작으로 만들지 않는다. 스킬 재설계안의 Rio 차원 연결·Yuki 연결선도 기술 세션 소유이며, 제안 문서를 구현 확정으로 읽지 않는다.
- design/SKILLS.md에 없는 Rio 추가 점프 전용 이펙트는 몸 모션 누락과 별개다. 문서 검색 근거는 inventory.json의 design_mentions에 보존했다.

## frey (fighter)
게임 시트: `smash-nine-prototype/assets/art/frey/frey_sheet.png` · [768, 1024]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|6|6.3|True|128/120|
|walk|8|11.31|True|128/120|
|jump|1|1.0|False|128/120|
|fall|1|1.0|False|128/120|
|attack|6|17.85|False|128/120|
|shield|6|9.0|False|128/120|
|hurt|1|1.0|False|128/120|
|attack_up|6|16.8|False|192/152|
|attack_down|6|17.85|False|192/152|
|attack_air_side|6|18.9|False|192/152|
|dash_strike|6|17.85|False|192/152|
|rising_cleave|6|15.12|False|192/152|
|spike_followup|6|15.75|False|192/152|
|descent|6|9.8|False|192/152|
|tumble|6|18.9|True|192/152|
|attack_chain|6|14.7|False|192/152|

선택 행 파일: jump=없음 또는 규격 부적합, fall=없음 또는 규격 부적합, hurt=없음 또는 규격 부적합, land=없음 또는 규격 부적합, victory=없음 또는 규격 부적합

|후보 행|버전·채택 상태|
|---|---|
|attack|[v3](../../art/bakeoff/frey/retired/frey-attack-v3.png) 미채택 표시; [v4](../../art/bakeoff/frey/frey-attack-v4.png) 채택 2026-10-14; [v5](../../art/bakeoff/frey/frey-attack-v5.png) 미채택 표시|
|attack_air_side|[v1](../../art/bakeoff/frey/frey-attack_air_side-v1.png) 채택 2026-10-14|
|attack_down|[v1](../../art/bakeoff/frey/frey-attack_down-v1.png) 채택 2026-10-14|
|attack_up|[v1](../../art/bakeoff/frey/frey-attack_up-v1.png) 채택 2026-10-14|
|dash_strike|[v1](../../art/bakeoff/frey/frey-dash_strike-v1.png) 채택 2026-10-14|
|defeat|[v1](../../art/bakeoff/frey/frey-defeat-v1.png) 미채택 표시|
|descent|[v2](../../art/bakeoff/frey/retired/frey-descent-v2.png) 미채택 표시; [v3](../../art/bakeoff/frey/retired/frey-descent-v3.png) 미채택 표시; [v4](../../art/bakeoff/frey/frey-descent-v4.png) 채택 2026-10-14|
|fall|[v1](../../art/bakeoff/frey/frey-fall-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/frey/frey-fall-v2.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/frey/frey-hurt-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/frey/frey-hurt-v2.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/frey/retired/frey-idle-v1.png) 미채택 표시; [v2](../../art/bakeoff/frey/frey-idle-v2.png) 채택 2026-10-14|
|jump|[v1](../../art/bakeoff/frey/frey-jump-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/frey/frey-jump-v2.png) 미채택 표시; [v3](../../art/bakeoff/frey/frey-jump-v3.png) 미채택 표시|
|land|[v1](../../art/bakeoff/frey/frey-land-v1.png) 미채택 표시|
|rising_cleave|[v1](../../art/bakeoff/frey/retired/frey-rising_cleave-v1.png) 미채택 표시; [v2](../../art/bakeoff/frey/frey-rising_cleave-v2.png) 채택 2026-10-14|
|shield|[v1](../../art/bakeoff/frey/frey-shield-v1.png) 채택 2026-10-14|
|spike_followup|[v2](../../art/bakeoff/frey/retired/frey-spike_followup-v2.png) 미채택 표시; [v3](../../art/bakeoff/frey/frey-spike_followup-v3.png) 채택 2026-10-14|
|tumble|[v2](../../art/bakeoff/frey/retired/frey-tumble-v2.png) 미채택 표시; [v3](../../art/bakeoff/frey/frey-tumble-v3.png) 채택 2026-10-14|
|victory|[v1](../../art/bakeoff/frey/frey-victory-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/frey/retired/frey-walk-v1.png) 미채택 표시; [v2](../../art/bakeoff/frey/frey-walk-v2.png) 채택 2026-10-14; [v3](../../art/bakeoff/frey/retired/frey-walk-v3.png) 미채택 표시; [v4](../../art/bakeoff/frey/retired/frey-walk-v4.png) 미채택 표시; [v5](../../art/bakeoff/frey/retired/frey-walk-v5.png) 미채택 표시; [v6](../../art/bakeoff/frey/frey-walk-v6.png) 채택 2026-10-15|

누락 일반 동작: dodge_roll, stun, run_start, run_stop, air_recovery, guard_break, portal_enter, portal_exit, crouch, taunt, grab, throw, wall_cling, wall_jump, ledge_grab, ledge_climb, surprise, laugh

기준 idle: `art/bakeoff/frey/frey-idle-v2.png`

## luna (fighter)
게임 시트: `smash-nine-prototype/assets/art/luna/luna_sheet.png` · [768, 1024]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|6|6.3|True|128/120|
|walk|8|11.31|True|128/120|
|jump|1|1.0|False|128/120|
|fall|1|1.0|False|128/120|
|attack|6|17.85|False|128/120|
|shield|6|9.6|False|128/120|
|hurt|1|1.0|False|128/120|
|star_up|6|19.95|False|192/152|
|star_down|6|17.85|False|192/152|
|star_comet|6|16.8|False|192/152|
|moon_ring|6|13.44|False|192/152|
|transform|12|7.8|False|192/152|
|tumble|6|24.15|True|192/152|
|star_side|6|17.85|False|192/152|

선택 행 파일: jump=없음 또는 규격 부적합, fall=없음 또는 규격 부적합, hurt=없음 또는 규격 부적합, land=없음 또는 규격 부적합, victory=없음 또는 규격 부적합

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/luna/retired/luna-attack-v1.png) 미채택 표시; [v2](../../art/bakeoff/luna/luna-attack-v2.png) 채택 2026-10-14|
|defeat|[v1](../../art/bakeoff/luna/luna-defeat-v1.png) 미채택 표시|
|fall|[v1](../../art/bakeoff/luna/retired/luna-fall-v1.png) 미채택 표시; [v2](../../art/bakeoff/luna/luna-fall-v2.png) 채택 2026-10-14; [v3](../../art/bakeoff/luna/luna-fall-v3.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/luna/luna-hurt-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/luna/luna-hurt-v2.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/luna/retired/luna-idle-v1.png) 미채택 표시; [v2](../../art/bakeoff/luna/retired/luna-idle-v2.png) 미채택 표시; [v3](../../art/bakeoff/luna/luna-idle-v3.png) 채택 2026-10-14|
|jump|[v1](../../art/bakeoff/luna/retired/luna-jump-v1.png) 미채택 표시; [v2](../../art/bakeoff/luna/luna-jump-v2.png) 채택 2026-10-14; [v3](../../art/bakeoff/luna/luna-jump-v3.png) 미채택 표시; [v4](../../art/bakeoff/luna/luna-jump-v4.png) 미채택 표시|
|land|[v1](../../art/bakeoff/luna/luna-land-v1.png) 미채택 표시|
|moon_ring|[v1](../../art/bakeoff/luna/luna-moon_ring-v1.png) 채택 2026-10-14|
|shield|[v1](../../art/bakeoff/luna/luna-shield-v1.png) 채택 2026-10-14|
|star_comet|[v1](../../art/bakeoff/luna/luna-star_comet-v1.png) 채택 2026-10-14|
|star_down|[v1](../../art/bakeoff/luna/luna-star_down-v1.png) 채택 2026-10-14|
|star_up|[v1](../../art/bakeoff/luna/luna-star_up-v1.png) 채택 2026-10-14|
|transform|[v2](../../art/bakeoff/luna/retired/luna-transform-v2.png) 미채택 표시; [v3](../../art/bakeoff/luna/luna-transform-v3.png) 채택 2026-10-14|
|tumble|[v1](../../art/bakeoff/luna/luna-tumble-v1.png) 채택 2026-10-14|
|victory|[v1](../../art/bakeoff/luna/luna-victory-v1.png) 미채택 표시; [v2](../../art/bakeoff/luna/luna-victory-v2.png) 미채택 표시; [v3](../../art/bakeoff/luna/luna-victory-v3.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/luna/luna-walk-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/luna/retired/luna-walk-v2.png) 미채택 표시; [v3](../../art/bakeoff/luna/retired/luna-walk-v3.png) 미채택 표시; [v4](../../art/bakeoff/luna/retired/luna-walk-v4.png) 미채택 표시; [v5](../../art/bakeoff/luna/luna-walk-v5.png) 채택 2026-10-15|

누락 일반 동작: dodge_roll, stun, run_start, run_stop, air_recovery, guard_break, portal_enter, portal_exit, crouch, taunt, grab, throw, wall_cling, wall_jump, ledge_grab, ledge_climb, surprise, laugh

기준 idle: `art/bakeoff/luna/luna-idle-v3.png`

## luna_brave (fighter)
게임 시트: `smash-nine-prototype/assets/art/luna/luna_brave_sheet.png` · [768, 1024]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|6|5.36|True|128/120|
|walk|8|11.97|True|128/120|
|jump|1|1.0|False|128/120|
|fall|1|1.0|False|128/120|
|attack|6|16.8|False|128/120|
|shield|6|10.8|False|128/120|
|hurt|1|1.0|False|128/120|
|brave_combo|6|12.8|False|192/152|
|brave_upper|6|20.4|False|192/152|
|brave_low|6|18.0|False|192/152|
|brave_air_side|6|19.2|False|192/152|
|brave_dive|6|18.0|False|192/152|
|comet_drive|6|19.2|False|192/152|
|luna_breaker|6|12.8|False|192/152|
|heart_laser|6|10.2|False|192/152|
|tumble|6|26.25|True|192/152|

선택 행 파일: jump=없음 또는 규격 부적합, fall=없음 또는 규격 부적합, hurt=없음 또는 규격 부적합, land=없음 또는 규격 부적합, victory=없음 또는 규격 부적합

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/luna/retired/luna_brave-attack-v1.png) 미채택 표시; [v2](../../art/bakeoff/luna/luna_brave-attack-v2.png) 채택 2026-10-14|
|brave_air_side|[v1](../../art/bakeoff/luna/luna_brave-brave_air_side-v1.png) 채택 2026-10-14|
|brave_combo|[v1](../../art/bakeoff/luna/luna_brave-brave_combo-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/luna/retired/luna_brave-brave_combo-v2.png) 미채택 표시|
|brave_dive|[v1](../../art/bakeoff/luna/luna_brave-brave_dive-v1.png) 채택 2026-10-14|
|brave_low|[v1](../../art/bakeoff/luna/luna_brave-brave_low-v1.png) 채택 2026-10-14|
|brave_upper|[v1](../../art/bakeoff/luna/luna_brave-brave_upper-v1.png) 채택 2026-10-14|
|comet_drive|[v1](../../art/bakeoff/luna/luna_brave-comet_drive-v1.png) 채택 2026-10-14|
|defeat|[v1](../../art/bakeoff/luna/luna_brave-defeat-v1.png) 미채택 표시|
|fall|[v1](../../art/bakeoff/luna/retired/luna_brave-fall-v1.png) 미채택 표시; [v2](../../art/bakeoff/luna/luna_brave-fall-v2.png) 채택 2026-10-14; [v3](../../art/bakeoff/luna/luna_brave-fall-v3.png) 미채택 표시|
|heart_laser|[v1](../../art/bakeoff/luna/luna_brave-heart_laser-v1.png) 채택 2026-10-14|
|hurt|[v1](../../art/bakeoff/luna/luna_brave-hurt-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/luna/luna_brave-hurt-v2.png) 미채택 표시; [v3](../../art/bakeoff/luna/luna_brave-hurt-v3.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/luna/retired/luna_brave-idle-v1.png) 미채택 표시; [v2](../../art/bakeoff/luna/retired/luna_brave-idle-v2.png) 미채택 표시; [v3](../../art/bakeoff/luna/retired/luna_brave-idle-v3.png) 미채택 표시; [v4](../../art/bakeoff/luna/luna_brave-idle-v4.png) 채택 2026-10-14; [v5](../../art/bakeoff/luna/retired/luna_brave-idle-v5.png) 미채택 표시|
|jump|[v1](../../art/bakeoff/luna/luna_brave-jump-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/luna/luna_brave-jump-v2.png) 미채택 표시|
|land|[v1](../../art/bakeoff/luna/luna_brave-land-v1.png) 미채택 표시|
|luna_breaker|[v1](../../art/bakeoff/luna/luna_brave-luna_breaker-v1.png) 채택 2026-10-14|
|shield|[v1](../../art/bakeoff/luna/luna_brave-shield-v1.png) 채택 2026-10-14|
|tumble|[v1](../../art/bakeoff/luna/luna_brave-tumble-v1.png) 채택 2026-10-14|
|victory|[v1](../../art/bakeoff/luna/luna_brave-victory-v1.png) 미채택 표시; [v2](../../art/bakeoff/luna/luna_brave-victory-v2.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/luna/luna_brave-walk-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/luna/luna_brave-walk-v2.png) 채택 2026-10-15|

누락 일반 동작: dodge_roll, stun, run_start, run_stop, air_recovery, guard_break, portal_enter, portal_exit, crouch, taunt, grab, throw, wall_cling, wall_jump, ledge_grab, ledge_climb, surprise, laugh

기준 idle: `art/bakeoff/luna/retired/luna_brave-idle-v5.png`

## nova_male (fighter)
게임 시트: `smash-nine-prototype/assets/art/nova/nova_male_sheet.png` · [768, 1024]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|6|6.3|True|128/120|
|walk|8|10.64|True|128/120|
|jump|1|1.0|False|128/120|
|fall|1|1.0|False|128/120|
|attack|6|26.44|False|128/120|
|shield|6|10.2|False|128/120|
|hurt|1|1.0|False|128/120|
|vector_side|6|26.44|False|192/152|
|vector_upper|6|23.1|False|192/152|
|compression_stomp|6|19.58|False|192/152|
|air_side|6|30.0|False|192/152|
|meteor_kick|6|22.5|False|192/152|
|vector_shift|6|17.75|False|192/152|
|gravity_brake|6|10.73|False|192/152|
|slingshot_start|6|9.1|False|192/152|
|tumble|6|17.85|True|192/152|

선택 행 파일: jump=없음 또는 규격 부적합, fall=없음 또는 규격 부적합, hurt=없음 또는 규격 부적합, land=없음 또는 규격 부적합, victory=없음 또는 규격 부적합

|후보 행|버전·채택 상태|
|---|---|
|air_side|[v1](../../art/bakeoff/nova/nova_male-air_side-v1.png) 채택 2026-10-14|
|attack|[v1](../../art/bakeoff/nova/nova_male-attack-v1.png) 채택 2026-10-14|
|compression_stomp|[v1](../../art/bakeoff/nova/nova_male-compression_stomp-v1.png) 채택 2026-10-14|
|defeat|[v1](../../art/bakeoff/nova/nova_male-defeat-v1.png) 미채택 표시|
|fall|[v1](../../art/bakeoff/nova/nova_male-fall-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/nova/nova_male-fall-v2.png) 미채택 표시; [v2](../../art/bakeoff/nova/retired/nova_male-fall-v2.png) 미채택 표시|
|gravity_brake|[v1](../../art/bakeoff/nova/nova_male-gravity_brake-v1.png) 채택 2026-10-14|
|hurt|[v1](../../art/bakeoff/nova/nova_male-hurt-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/nova/nova_male-hurt-v2.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/nova/retired/nova_male-idle-v1.png) 미채택 표시; [v2](../../art/bakeoff/nova/nova_male-idle-v2.png) 채택 2026-10-14|
|jump|[v1](../../art/bakeoff/nova/nova_male-jump-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/nova/nova_male-jump-v2.png) 미채택 표시; [v2](../../art/bakeoff/nova/retired/nova_male-jump-v2.png) 미채택 표시|
|land|[v1](../../art/bakeoff/nova/nova_male-land-v1.png) 미채택 표시|
|meteor_kick|[v1](../../art/bakeoff/nova/nova_male-meteor_kick-v1.png) 채택 2026-10-14|
|shield|[v1](../../art/bakeoff/nova/nova_male-shield-v1.png) 채택 2026-10-14; [v1](../../art/bakeoff/nova/retired/nova_male-shield-v1.png) 미채택 표시|
|slingshot_start|[v1](../../art/bakeoff/nova/nova_male-slingshot_start-v1.png) 채택 2026-10-14|
|tumble|[v1](../../art/bakeoff/nova/nova_male-tumble-v1.png) 채택 2026-10-14|
|vector_shift|[v1](../../art/bakeoff/nova/nova_male-vector_shift-v1.png) 채택 2026-10-14|
|vector_side|[v1](../../art/bakeoff/nova/nova_male-vector_side-v1.png) 채택 2026-10-14; [v1](../../art/bakeoff/nova/retired/nova_male-vector_side-v1.png) 미채택 표시|
|vector_upper|[v1](../../art/bakeoff/nova/nova_male-vector_upper-v1.png) 채택 2026-10-14|
|victory|[v1](../../art/bakeoff/nova/nova_male-victory-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/nova/nova_male-walk-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/nova/nova_male-walk-v2.png) 채택 2026-10-15; [v3](../../art/bakeoff/nova/nova_male-walk-v3.png) 미채택 표시|

누락 일반 동작: dodge_roll, stun, run_start, run_stop, air_recovery, guard_break, portal_enter, portal_exit, crouch, taunt, grab, throw, wall_cling, wall_jump, ledge_grab, ledge_climb, surprise, laugh

기준 idle: `art/bakeoff/nova/nova_male-idle-v2.png`

## nova_female (fighter)
게임 시트: `smash-nine-prototype/assets/art/nova/nova_female_sheet.png` · [768, 1024]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|6|6.3|True|128/120|
|walk|8|10.64|True|128/120|
|jump|1|1.0|False|128/120|
|fall|1|1.0|False|128/120|
|attack|6|24.67|False|128/120|
|shield|6|9.0|False|128/120|
|hurt|1|1.0|False|128/120|
|vector_side|6|28.2|False|192/152|
|vector_upper|6|24.75|False|192/152|
|compression_stomp|6|19.58|False|192/152|
|air_side|6|26.0|False|192/152|
|meteor_kick|6|22.5|False|192/152|
|vector_shift|6|17.75|False|192/152|
|gravity_brake|6|10.01|False|192/152|
|slingshot_start|6|10.5|False|192/152|
|tumble|6|21.0|True|192/152|

선택 행 파일: jump=없음 또는 규격 부적합, fall=없음 또는 규격 부적합, hurt=없음 또는 규격 부적합, land=없음 또는 규격 부적합, victory=없음 또는 규격 부적합

|후보 행|버전·채택 상태|
|---|---|
|air_side|[v1](../../art/bakeoff/nova/nova_female-air_side-v1.png) 채택 2026-10-14|
|attack|[v1](../../art/bakeoff/nova/nova_female-attack-v1.png) 채택 2026-10-14|
|compression_stomp|[v1](../../art/bakeoff/nova/nova_female-compression_stomp-v1.png) 채택 2026-10-14|
|defeat|[v1](../../art/bakeoff/nova/nova_female-defeat-v1.png) 미채택 표시|
|fall|[v1](../../art/bakeoff/nova/nova_female-fall-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/nova/nova_female-fall-v2.png) 미채택 표시|
|gravity_brake|[v1](../../art/bakeoff/nova/nova_female-gravity_brake-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/nova/nova_female-gravity_brake-v2.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/nova/nova_female-hurt-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/nova/nova_female-hurt-v2.png) 미채택 표시; [v3](../../art/bakeoff/nova/nova_female-hurt-v3.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/nova/retired/nova_female-idle-v1.png) 미채택 표시; [v2](../../art/bakeoff/nova/nova_female-idle-v2.png) 채택 2026-10-14|
|jump|[v1](../../art/bakeoff/nova/nova_female-jump-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/nova/nova_female-jump-v2.png) 미채택 표시|
|land|[v1](../../art/bakeoff/nova/nova_female-land-v1.png) 미채택 표시|
|meteor_kick|[v1](../../art/bakeoff/nova/nova_female-meteor_kick-v1.png) 채택 2026-10-14|
|shield|[v1](../../art/bakeoff/nova/nova_female-shield-v1.png) 채택 2026-10-14|
|slingshot_start|[v1](../../art/bakeoff/nova/nova_female-slingshot_start-v1.png) 채택 2026-10-14|
|tumble|[v1](../../art/bakeoff/nova/nova_female-tumble-v1.png) 채택 2026-10-14|
|vector_shift|[v1](../../art/bakeoff/nova/nova_female-vector_shift-v1.png) 채택 2026-10-14|
|vector_side|[v2](../../art/bakeoff/nova/retired/nova_female-vector_side-v2.png) 미채택 표시; [v3](../../art/bakeoff/nova/nova_female-vector_side-v3.png) 채택 2026-10-14|
|vector_upper|[v1](../../art/bakeoff/nova/nova_female-vector_upper-v1.png) 채택 2026-10-14|
|victory|[v1](../../art/bakeoff/nova/nova_female-victory-v1.png) 미채택 표시; [v2](../../art/bakeoff/nova/nova_female-victory-v2.png) 미채택 표시; [v3](../../art/bakeoff/nova/nova_female-victory-v3.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/nova/nova_female-walk-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/nova/nova_female-walk-v2.png) 채택 2026-10-15|

누락 일반 동작: dodge_roll, stun, run_start, run_stop, air_recovery, guard_break, portal_enter, portal_exit, crouch, taunt, grab, throw, wall_cling, wall_jump, ledge_grab, ledge_climb, surprise, laugh

기준 idle: `art/bakeoff/nova/nova_female-idle-v2.png`

## rio_male (fighter)
게임 시트: `smash-nine-prototype/assets/art/rio/rio_male_sheet.png` · [768, 1024]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|6|6.3|True|128/120|
|walk|8|9.31|True|128/120|
|jump|1|1.0|False|128/120|
|fall|1|1.0|False|128/120|
|attack|6|14.7|False|128/120|
|shield|6|9.6|False|128/120|
|hurt|1|1.0|False|128/120|
|mana_combo|6|13.5|False|192/152|
|rising_slash|6|19.5|False|192/152|
|low_sweep|6|19.5|False|192/152|
|air_slash|6|26.0|False|192/152|
|plunge|6|9.0|False|192/152|
|dimension_slash|6|14.95|False|192/152|
|rune_shield|6|8.4|False|192/152|
|infinity_overdrive|6|7.15|False|192/152|
|tumble|6|21.0|True|192/152|

선택 행 파일: jump=없음 또는 규격 부적합, fall=없음 또는 규격 부적합, hurt=없음 또는 규격 부적합, land=없음 또는 규격 부적합, victory=없음 또는 규격 부적합

|후보 행|버전·채택 상태|
|---|---|
|air_slash|[v1](../../art/bakeoff/rio/rio_male-air_slash-v1.png) 채택 2026-10-15|
|attack|[v1](../../art/bakeoff/rio/rio_male-attack-v1.png) 채택 2026-10-15; [v2](../../art/bakeoff/rio/rio_male-attack-v2.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/rio/rio_male-defeat-v1.png) 미채택 표시|
|dimension_slash|[v1](../../art/bakeoff/rio/rio_male-dimension_slash-v1.png) 채택 2026-10-15|
|fall|[v1](../../art/bakeoff/rio/rio_male-fall-v1.png) 채택 2026-10-15; [v2](../../art/bakeoff/rio/rio_male-fall-v2.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/rio/rio_male-hurt-v1.png) 채택 2026-10-15; [v2](../../art/bakeoff/rio/rio_male-hurt-v2.png) 미채택 표시|
|idle|[v2](../../art/bakeoff/rio/rio_male-idle-v2.png) 채택 2026-10-15|
|infinity_overdrive|[v1](../../art/bakeoff/rio/rio_male-infinity_overdrive-v1.png) 채택 2026-10-15|
|jump|[v1](../../art/bakeoff/rio/rio_male-jump-v1.png) 채택 2026-10-15; [v2](../../art/bakeoff/rio/rio_male-jump-v2.png) 미채택 표시|
|land|[v1](../../art/bakeoff/rio/rio_male-land-v1.png) 미채택 표시|
|low_sweep|[v1](../../art/bakeoff/rio/rio_male-low_sweep-v1.png) 채택 2026-10-15|
|mana_combo|[v1](../../art/bakeoff/rio/rio_male-mana_combo-v1.png) 채택 2026-10-15|
|plunge|[v1](../../art/bakeoff/rio/rio_male-plunge-v1.png) 채택 2026-10-15|
|rising_slash|[v1](../../art/bakeoff/rio/rio_male-rising_slash-v1.png) 채택 2026-10-15|
|rune_shield|[v1](../../art/bakeoff/rio/rio_male-rune_shield-v1.png) 채택 2026-10-15|
|shield|[v1](../../art/bakeoff/rio/rio_male-shield-v1.png) 채택 2026-10-15|
|tumble|[v1](../../art/bakeoff/rio/rio_male-tumble-v1.png) 채택 2026-10-15|
|victory|[v1](../../art/bakeoff/rio/rio_male-victory-v1.png) 미채택 표시; [v2](../../art/bakeoff/rio/rio_male-victory-v2.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/rio/rio_male-walk-v1.png) 채택 2026-10-15; [v2](../../art/bakeoff/rio/rio_male-walk-v2.png) 미채택 표시|

누락 일반 동작: dodge_roll, stun, run_start, run_stop, air_recovery, guard_break, portal_enter, portal_exit, crouch, taunt, grab, throw, wall_cling, wall_jump, ledge_grab, ledge_climb, surprise, laugh

기준 idle: `art/bakeoff/rio/rio_male-idle-v2.png`

## rio_female (fighter)
게임 시트: `smash-nine-prototype/assets/art/rio/rio_female_sheet.png` · [768, 1024]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|6|6.3|True|128/120|
|walk|8|9.31|True|128/120|
|jump|1|1.0|False|128/120|
|fall|1|1.0|False|128/120|
|attack|6|13.65|False|128/120|
|shield|6|9.0|False|128/120|
|hurt|1|1.0|False|128/120|
|mana_combo|6|12.6|False|192/152|
|rising_slash|6|21.0|False|192/152|
|low_sweep|6|18.0|False|192/152|
|air_slash|6|26.0|False|192/152|
|plunge|6|8.4|False|192/152|
|dimension_slash|6|14.95|False|192/152|
|rune_shield|6|7.8|False|192/152|
|infinity_overdrive|6|8.25|False|192/152|
|tumble|6|21.0|True|192/152|

선택 행 파일: jump=없음 또는 규격 부적합, fall=없음 또는 규격 부적합, hurt=없음 또는 규격 부적합, land=없음 또는 규격 부적합, victory=없음 또는 규격 부적합

|후보 행|버전·채택 상태|
|---|---|
|air_slash|[v2](../../art/bakeoff/rio/retired/rio_female-air_slash-v2.png) 미채택 표시; [v3](../../art/bakeoff/rio/rio_female-air_slash-v3.png) 채택 2026-10-15|
|attack|[v1](../../art/bakeoff/rio/rio_female-attack-v1.png) 채택 2026-10-15; [v2](../../art/bakeoff/rio/rio_female-attack-v2.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/rio/rio_female-defeat-v1.png) 미채택 표시|
|dimension_slash|[v1](../../art/bakeoff/rio/rio_female-dimension_slash-v1.png) 채택 2026-10-15; [v2](../../art/bakeoff/rio/rio_female-dimension_slash-v2.png) 미채택 표시|
|fall|[v1](../../art/bakeoff/rio/rio_female-fall-v1.png) 채택 2026-10-15; [v2](../../art/bakeoff/rio/rio_female-fall-v2.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/rio/rio_female-hurt-v1.png) 채택 2026-10-15; [v2](../../art/bakeoff/rio/rio_female-hurt-v2.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/rio/retired/rio_female-idle-v1.png) 미채택 표시; [v2](../../art/bakeoff/rio/rio_female-idle-v2.png) 채택 2026-10-15|
|infinity_overdrive|[v1](../../art/bakeoff/rio/rio_female-infinity_overdrive-v1.png) 채택 2026-10-15|
|jump|[v1](../../art/bakeoff/rio/rio_female-jump-v1.png) 채택 2026-10-15; [v2](../../art/bakeoff/rio/rio_female-jump-v2.png) 미채택 표시|
|land|[v1](../../art/bakeoff/rio/rio_female-land-v1.png) 미채택 표시|
|low_sweep|[v1](../../art/bakeoff/rio/rio_female-low_sweep-v1.png) 채택 2026-10-15; [v2](../../art/bakeoff/rio/rio_female-low_sweep-v2.png) 미채택 표시|
|mana_combo|[v1](../../art/bakeoff/rio/rio_female-mana_combo-v1.png) 채택 2026-10-15; [v2](../../art/bakeoff/rio/rio_female-mana_combo-v2.png) 미채택 표시|
|plunge|[v2](../../art/bakeoff/rio/retired/rio_female-plunge-v2.png) 미채택 표시; [v3](../../art/bakeoff/rio/rio_female-plunge-v3.png) 채택 2026-10-15|
|rising_slash|[v1](../../art/bakeoff/rio/rio_female-rising_slash-v1.png) 채택 2026-10-15|
|rune_shield|[v1](../../art/bakeoff/rio/rio_female-rune_shield-v1.png) 채택 2026-10-15|
|shield|[v1](../../art/bakeoff/rio/rio_female-shield-v1.png) 채택 2026-10-15|
|tumble|[v1](../../art/bakeoff/rio/rio_female-tumble-v1.png) 채택 2026-10-15|
|victory|[v1](../../art/bakeoff/rio/rio_female-victory-v1.png) 미채택 표시; [v2](../../art/bakeoff/rio/rio_female-victory-v2.png) 미채택 표시|
|walk|[v2](../../art/bakeoff/rio/retired/rio_female-walk-v2.png) 미채택 표시; [v3](../../art/bakeoff/rio/rio_female-walk-v3.png) 채택 2026-10-15; [v4](../../art/bakeoff/rio/rio_female-walk-v4.png) 미채택 표시|

누락 일반 동작: dodge_roll, stun, run_start, run_stop, air_recovery, guard_break, portal_enter, portal_exit, crouch, taunt, grab, throw, wall_cling, wall_jump, ledge_grab, ledge_climb, surprise, laugh

기준 idle: `art/bakeoff/rio/rio_female-idle-v2.png`

## yuki (fighter)
게임 시트: `smash-nine-prototype/assets/art/yuki/yuki_sheet.png` · [768, 1024]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|6|6.3|True|128/120|
|walk|8|9.98|True|128/120|
|jump|1|1.0|False|128/120|
|fall|1|1.0|False|128/120|
|attack|6|21.38|False|128/120|
|shield|6|9.6|False|128/120|
|hurt|1|1.0|False|128/120|
|talisman_side|6|19.95|False|192/152|
|talisman_up|6|17.5|False|192/152|
|ground_ward|6|17.33|False|192/152|
|talisman_air_side|6|23.31|False|192/152|
|talisman_air_down|6|16.65|False|192/152|
|seal_place|6|14.02|False|192/152|
|seal_activate|6|12.48|False|192/152|
|grand_ward|6|6.31|False|192/152|
|tumble|6|21.0|True|192/152|

선택 행 파일: jump=없음 또는 규격 부적합, fall=없음 또는 규격 부적합, hurt=없음 또는 규격 부적합, land=없음 또는 규격 부적합, victory=없음 또는 규격 부적합

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/yuki/yuki-attack-v1.png) 채택 2026-10-14|
|defeat|[v1](../../art/bakeoff/yuki/yuki-defeat-v1.png) 미채택 표시|
|fall|[v1](../../art/bakeoff/yuki/yuki-fall-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/yuki/yuki-fall-v2.png) 미채택 표시; [v3](../../art/bakeoff/yuki/yuki-fall-v3.png) 미채택 표시|
|grand_ward|[v1](../../art/bakeoff/yuki/yuki-grand_ward-v1.png) 채택 2026-10-14|
|ground_ward|[v1](../../art/bakeoff/yuki/retired/yuki-ground_ward-v1.png) 미채택 표시; [v2](../../art/bakeoff/yuki/yuki-ground_ward-v2.png) 채택 2026-10-14|
|hurt|[v1](../../art/bakeoff/yuki/yuki-hurt-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/yuki/yuki-hurt-v2.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/yuki/retired/yuki-idle-v1.png) 미채택 표시; [v2](../../art/bakeoff/yuki/yuki-idle-v2.png) 채택 2026-10-14|
|jump|[v1](../../art/bakeoff/yuki/yuki-jump-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/yuki/yuki-jump-v2.png) 미채택 표시|
|land|[v1](../../art/bakeoff/yuki/yuki-land-v1.png) 미채택 표시|
|seal_activate|[v1](../../art/bakeoff/yuki/yuki-seal_activate-v1.png) 채택 2026-10-14|
|seal_place|[v1](../../art/bakeoff/yuki/yuki-seal_place-v1.png) 채택 2026-10-14|
|shield|[v1](../../art/bakeoff/yuki/yuki-shield-v1.png) 채택 2026-10-14|
|talisman_air_down|[v1](../../art/bakeoff/yuki/retired/yuki-talisman_air_down-v1.png) 미채택 표시; [v2](../../art/bakeoff/yuki/yuki-talisman_air_down-v2.png) 채택 2026-10-14|
|talisman_air_side|[v1](../../art/bakeoff/yuki/yuki-talisman_air_side-v1.png) 채택 2026-10-14|
|talisman_side|[v2](../../art/bakeoff/yuki/retired/yuki-talisman_side-v2.png) 미채택 표시; [v3](../../art/bakeoff/yuki/yuki-talisman_side-v3.png) 채택 2026-10-14|
|talisman_up|[v1](../../art/bakeoff/yuki/yuki-talisman_up-v1.png) 채택 2026-10-14|
|tumble|[v1](../../art/bakeoff/yuki/retired/yuki-tumble-v1.png) 미채택 표시; [v2](../../art/bakeoff/yuki/yuki-tumble-v2.png) 채택 2026-10-14|
|victory|[v1](../../art/bakeoff/yuki/yuki-victory-v1.png) 미채택 표시; [v2](../../art/bakeoff/yuki/yuki-victory-v2.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/yuki/yuki-walk-v1.png) 채택 2026-10-14; [v2](../../art/bakeoff/yuki/yuki-walk-v2.png) 채택 2026-10-15|

누락 일반 동작: dodge_roll, stun, run_start, run_stop, air_recovery, guard_break, portal_enter, portal_exit, crouch, taunt, grab, throw, wall_cling, wall_jump, ledge_grab, ledge_climb, surprise, laugh

기준 idle: `art/bakeoff/yuki/yuki-idle-v2.png`

## alfheim_moon_moth (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/alfheim_moon_moth_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/alfheim_moon_moth-attack-v1.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/alfheim_moon_moth-defeat-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/alfheim_moon_moth-defeat-v2.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/alfheim_moon_moth-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/alfheim_moon_moth-idle-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/alfheim_moon_moth-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/alfheim_moon_moth-windup-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/alfheim_moon_moth-windup-v2.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/alfheim_moon_moth-idle-v1.png`

## alfheim_moon_stag (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/alfheim_moon_stag_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/alfheim_moon_stag-attack-v1.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/alfheim_moon_stag-defeat-v1.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/alfheim_moon_stag-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/alfheim_moon_stag-idle-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/alfheim_moon_stag-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/alfheim_moon_stag-windup-v1.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/alfheim_moon_stag-idle-v1.png`

## asgard_aegis_ram (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/asgard_aegis_ram_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/asgard_aegis_ram-attack-v1.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/asgard_aegis_ram-defeat-v1.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/asgard_aegis_ram-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/asgard_aegis_ram-idle-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/asgard_aegis_ram-idle-v2.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/asgard_aegis_ram-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/asgard_aegis_ram-windup-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/asgard_aegis_ram-windup-v2.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/asgard_aegis_ram-idle-v2.png`

## asgard_runic_raven (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/asgard_runic_raven_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/asgard_runic_raven-attack-v1.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/asgard_runic_raven-defeat-v1.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/asgard_runic_raven-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/asgard_runic_raven-idle-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/asgard_runic_raven-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/asgard_runic_raven-windup-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/asgard_runic_raven-windup-v2.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/asgard_runic_raven-idle-v1.png`

## ember_imp (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/ember_imp_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/ember_imp-attack-v1.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/ember_imp-defeat-v1.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/ember_imp-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/ember_imp-idle-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/ember_imp-idle-v2.png) 미채택 표시|
|projectile|[v1](../../art/bakeoff/monsters/ember_imp-projectile-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/ember_imp-walk-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/ember_imp-walk-v2.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/ember_imp-windup-v1.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/ember_imp-idle-v2.png`

## jotunheim_rune_golem (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/jotunheim_rune_golem_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/jotunheim_rune_golem-attack-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/jotunheim_rune_golem-attack-v2.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/jotunheim_rune_golem-defeat-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/jotunheim_rune_golem-defeat-v2.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/jotunheim_rune_golem-hurt-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/jotunheim_rune_golem-hurt-v2.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/jotunheim_rune_golem-idle-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/jotunheim_rune_golem-walk-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/jotunheim_rune_golem-walk-v2.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/jotunheim_rune_golem-windup-v1.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/jotunheim_rune_golem-idle-v1.png`

## jotunheim_storm_wisp (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/jotunheim_storm_wisp_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/jotunheim_storm_wisp-attack-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/jotunheim_storm_wisp-attack-v2.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/jotunheim_storm_wisp-defeat-v1.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/jotunheim_storm_wisp-hurt-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/jotunheim_storm_wisp-hurt-v2.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/jotunheim_storm_wisp-idle-v1.png) 미채택 표시|
|projectile|[v1](../../art/bakeoff/monsters/jotunheim_storm_wisp-projectile-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/jotunheim_storm_wisp-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/jotunheim_storm_wisp-windup-v1.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/jotunheim_storm_wisp-idle-v1.png`

## midgard_rooftop_slinger (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/midgard_rooftop_slinger_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/midgard_rooftop_slinger-attack-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/midgard_rooftop_slinger-attack-v2.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/midgard_rooftop_slinger-defeat-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/midgard_rooftop_slinger-defeat-v2.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/midgard_rooftop_slinger-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/midgard_rooftop_slinger-idle-v1.png) 미채택 표시|
|projectile|[v1](../../art/bakeoff/monsters/midgard_rooftop_slinger-projectile-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/midgard_rooftop_slinger-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/midgard_rooftop_slinger-windup-v1.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/midgard_rooftop_slinger-idle-v1.png`

## mossling (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/mossling_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/mossling-attack-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/mossling-attack-v2.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/mossling-defeat-v1.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/mossling-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/mossling-idle-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/mossling-walk-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/mossling-walk-v2.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/mossling-windup-v1.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/mossling-idle-v1.png`

## muspelheim_magma_boar (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/muspelheim_magma_boar_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/muspelheim_magma_boar-attack-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/muspelheim_magma_boar-attack-v2.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/muspelheim_magma_boar-defeat-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/muspelheim_magma_boar-defeat-v2.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/muspelheim_magma_boar-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/muspelheim_magma_boar-idle-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/muspelheim_magma_boar-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/muspelheim_magma_boar-windup-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/muspelheim_magma_boar-windup-v2.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/muspelheim_magma_boar-idle-v1.png`

## niflheim_frost_owl (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/niflheim_frost_owl_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/niflheim_frost_owl-attack-v1.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/niflheim_frost_owl-defeat-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/niflheim_frost_owl-defeat-v2.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/niflheim_frost_owl-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/niflheim_frost_owl-idle-v1.png) 미채택 표시|
|projectile|[v1](../../art/bakeoff/monsters/niflheim_frost_owl-projectile-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/niflheim_frost_owl-projectile-v2.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/niflheim_frost_owl-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/niflheim_frost_owl-windup-v1.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/niflheim_frost_owl-idle-v1.png`

## niflheim_glacier_wolf (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/niflheim_glacier_wolf_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/niflheim_glacier_wolf-attack-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/niflheim_glacier_wolf-attack-v2.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/niflheim_glacier_wolf-defeat-v1.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/niflheim_glacier_wolf-hurt-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/niflheim_glacier_wolf-hurt-v2.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/niflheim_glacier_wolf-idle-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/niflheim_glacier_wolf-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/niflheim_glacier_wolf-windup-v1.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/niflheim_glacier_wolf-idle-v1.png`

## svartalfheim_cog_drone (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/svartalfheim_cog_drone_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/svartalfheim_cog_drone-attack-v1.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/svartalfheim_cog_drone-defeat-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/svartalfheim_cog_drone-defeat-v2.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/svartalfheim_cog_drone-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/svartalfheim_cog_drone-idle-v1.png) 미채택 표시|
|projectile|[v1](../../art/bakeoff/monsters/svartalfheim_cog_drone-projectile-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/svartalfheim_cog_drone-projectile-v2.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/svartalfheim_cog_drone-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/svartalfheim_cog_drone-windup-v1.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/svartalfheim_cog_drone-idle-v1.png`

## svartalfheim_gear_beetle (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/svartalfheim_gear_beetle_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/svartalfheim_gear_beetle-attack-v1.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/svartalfheim_gear_beetle-defeat-v1.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/svartalfheim_gear_beetle-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/svartalfheim_gear_beetle-idle-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/svartalfheim_gear_beetle-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/svartalfheim_gear_beetle-windup-v1.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/svartalfheim_gear_beetle-idle-v1.png`

## vanaheim_seed_sprite (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/vanaheim_seed_sprite_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/vanaheim_seed_sprite-attack-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/vanaheim_seed_sprite-attack-v2.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/vanaheim_seed_sprite-defeat-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/vanaheim_seed_sprite-defeat-v2.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/vanaheim_seed_sprite-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/vanaheim_seed_sprite-idle-v1.png) 미채택 표시|
|projectile|[v1](../../art/bakeoff/monsters/vanaheim_seed_sprite-projectile-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/vanaheim_seed_sprite-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/vanaheim_seed_sprite-windup-v1.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/vanaheim_seed_sprite-idle-v1.png`

## vanaheim_vine_hound (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/vanaheim_vine_hound_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/vanaheim_vine_hound-attack-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/vanaheim_vine_hound-attack-v2.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/vanaheim_vine_hound-defeat-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/vanaheim_vine_hound-defeat-v2.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/vanaheim_vine_hound-hurt-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/vanaheim_vine_hound-hurt-v2.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/vanaheim_vine_hound-idle-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/vanaheim_vine_hound-idle-v2.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/vanaheim_vine_hound-walk-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/vanaheim_vine_hound-walk-v2.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/vanaheim_vine_hound-windup-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/vanaheim_vine_hound-windup-v2.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/vanaheim_vine_hound-idle-v2.png`

## yggdrasil_root_guardian (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/yggdrasil_root_guardian_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/yggdrasil_root_guardian-attack-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/yggdrasil_root_guardian-attack-v2.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/yggdrasil_root_guardian-defeat-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/yggdrasil_root_guardian-defeat-v2.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/yggdrasil_root_guardian-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/yggdrasil_root_guardian-idle-v1.png) 미채택 표시|
|shockwave|[v1](../../art/bakeoff/monsters/yggdrasil_root_guardian-shockwave-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/yggdrasil_root_guardian-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/yggdrasil_root_guardian-windup-v1.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/yggdrasil_root_guardian-idle-v1.png`

## yggdrasil_root_oracle (monster)
게임 시트: `smash-nine-prototype/assets/art/monsters/yggdrasil_root_oracle_sheet.png` · [576, 384]

|게임 행|프레임|FPS|반복|셀/발|
|---|---:|---:|---|---|
|idle|4|6.0|True|96/72|
|walk|6|10.0|True|96/72|
|attack|4|12.0|False|96/72|
|hurt|1|1.0|False|96/72|

|후보 행|버전·채택 상태|
|---|---|
|attack|[v1](../../art/bakeoff/monsters/yggdrasil_root_oracle-attack-v1.png) 미채택 표시|
|defeat|[v1](../../art/bakeoff/monsters/yggdrasil_root_oracle-defeat-v1.png) 미채택 표시|
|hurt|[v1](../../art/bakeoff/monsters/yggdrasil_root_oracle-hurt-v1.png) 미채택 표시|
|idle|[v1](../../art/bakeoff/monsters/yggdrasil_root_oracle-idle-v1.png) 미채택 표시|
|projectile|[v1](../../art/bakeoff/monsters/yggdrasil_root_oracle-projectile-v1.png) 미채택 표시|
|walk|[v1](../../art/bakeoff/monsters/yggdrasil_root_oracle-walk-v1.png) 미채택 표시|
|windup|[v1](../../art/bakeoff/monsters/yggdrasil_root_oracle-windup-v1.png) 미채택 표시; [v2](../../art/bakeoff/monsters/yggdrasil_root_oracle-windup-v2.png) 미채택 표시|

누락 일반 동작: appear, rage, sleep, flee

기준 idle: `art/bakeoff/monsters/yggdrasil_root_oracle-idle-v1.png`

## 부가 후보와 조사 범위
초상화 표정·이펙트·투사체·조립 시트는 몸 모션과 분리했다. 전수 경로는 inventory.json의 other_versioned_candidates / other_pngs에 있다. 파일만 조사했으며 실제 게임 재생, 채택 UI의 원격 DB, 다른 클론의 진행은 확인하지 않았다.

JSON 읽기 오류: []

재실행은 기존 결과를 덮어쓰지 않도록 실패한다. 소스: inventory_scan.py.
