# 캐릭터 기술과 이펙트 기준

이 문서는 2026-10-15 현재 실행 코드가 실제로 만드는 기술, 판정, 동작 줄과 이펙트를 정리한다. 캐릭터 설명 문서와 코드가 다르면 코드를 따른다.

## 읽는 법

- 피해와 넉백은 캐릭터 공격력, 방어력, 매치 피해 배율이 적용되기 전의 기술 기본값이다.
- 공격 크기와 공격 지점은 대부분 `GameScale.COMBAT = 1.5`가 적용된다. 아래의 `42×34` 같은 표기는 코드에 적힌 기본 판정이며, 실제 화면 판정은 보통 각 축이 1.5배다.
- 이동 기술의 거리는 `GameScale.WORLD = 1.5`, 달리기와 노바의 속도 기준은 `GameScale.MOVE = 1.2`, 점프 속도는 `GameScale.JUMP_SPEED = 1.3416`을 따른다.
- 동작 프레임은 사람이 읽기 쉽게 1부터 센다. 예를 들어 코드의 `Vector2i(0, 1)`은 여기서 1~2프레임이다.
- 동작 줄의 재생 속도는 사용자가 모션 뷰어에서 채택한 값이다(2026-10-15, `characters/common/MotionSpeeds.gd`, D39). 기술 줄은 D38 그림 시계로 재생되어 타격 그림이 판정 순간(선딜 끝)에 오고, 그 뒤 그림만 채택 속도보다 빨리 넘어가지 않는다. 그래서 채택 속도로 보이게 하려고 타격 전 그림을 늦추려면 선딜을 바꿔야 한다. 이는 밸런스 변경이고, 필요한 값은 `reports/motion-speeds-2026-10-15.md`에 있고, 2026-10-15 스킬 세션에서 그 값대로 늘렸다(아래 "선딜" 절).
- 이펙트를 그리는 공통 규칙(Codex와 함께 한 스프라이트 점검, 2026-10-16, D40):
  - 공용 J 궤적(`<id>_slash`)의 두께는 길이의 0.62배다(`PlayerBase.ATTACK_ART_THICKNESS`). 길이는 판정 끝까지 간다.
  - 땅에서 아래로 향한 궤적은 최대 15°로 눕혀 보인다(`GROUND_TRAIL_MAX_DROP`). 판정 방향은 그대로다.
  - 전용 이펙트가 있는 공격은 공용 궤적을 그리지 않는다(`attack_art_enabled = false`): Rio 룬 반격, Nova 벡터 타격·어퍼컷.
  - Luna·Brave의 별꽃은 캐릭터 뒤(z 0)에 그린다.
  - 화면을 채우는 궁극기 섬광(Luna 변신, Nova 붕괴, Yuki 마지막 폭발)은 알파 0.7이다(`Vfx.ULTIMATE_FLASH_ALPHA`).
  - 방어 호는 몸 앞, 중심 (24,-58)이다(`GUARD_ART_CENTRE`, `GUARD_ART_FORWARD`).
- 이펙트 상태는 전용 파일이 있으면 **그림**, 코드 도형만 있으면 **도형**, 몸 동작 외 표시가 없으면 **없음**, 여러 캐릭터가 같은 파일을 쓰면 **공용**이다. 원본 아트 모드가 아니거나 파일이 없으면 대부분 `ColorRect`, `Line2D`, `Polygon2D` 도형으로 대체된다.
- `assets/art/` 아래 경로는 표에서 짧게 쓸 수 있다. 예를 들어 `attack_vfx/frey_k.png`는 `assets/art/attack_vfx/frey_k.png`, `skill/luna_star_bloom.png`는 `assets/art/effects/skill/luna_star_bloom.png`다.
- `Attack.gd` 판정과 `source.on_attack_landed`를 부르는 투사체가 적중하면 공격자별 `assets/art/effects/hit/<id>_hit.png`, 공용 `hit_streak.png`가 나온다. 공중 공격 착지에는 공용 `landing_dust.png`가 나올 수 있다. 맞은 쪽의 `apply_hit`도 공격자의 `hit/<id>_hit.png`를 몸 위치에 그리므로, 모든 적중(투사체 포함)에 공격자 색의 불꽃이 나온다. Rio의 일반 마력 검기는 `on_attack_landed`를 부르지 않아 `hit_streak`과 공격자 경직만 없다.

## 공용 조작

`PlayerBase._get_basic_attack_type`은 지상과 공중, 입력 방향을 조합해 `neutral`, `side`, `up`, `down`, `air_side`, `air_up`, `air_down`으로 나눈다. `basic_attack`, `skill_one`, `skill_two`, `ultimate`이 각 캐릭터의 `perform_*` 함수로 넘긴다. 독립된 공용 대시 입력은 없으며, 코드에서 대시는 Frey K, Brave Luna K, Nova K, Rio K처럼 각 캐릭터 기술의 `skill_dash_velocity`로 구현된다.

방어는 전 캐릭터 공통이다. 지상에서 Guard를 누르면 입력 방향의 140도 범위를 막는다. 처음 0.1초는 패리이며 `[GUARD_PARRY_WINDOW]`, 일반 막기의 피해 감소율은 처음 75%에서 5초 동안 30%까지 내려간다 `[GUARD_START_REDUCTION]`, `[GUARD_MIN_REDUCTION]`, `[GUARD_DECAY_TIME]`. 놓은 뒤 회복은 0.26초다 `[GUARD_RECOVERY]`. 동작은 `shield` 줄 전체이며, 이펙트는 공용 `assets/art/effects/skill/guard_bubble.png`의 평상/피격/패리 프레임과 패리 성공 시 `parry_flash.png`다. 그림이 없으면 `PlayerBase._update_guard_visual`의 `Line2D` 호와 `_play_parry_effect`의 `ColorRect`가 대신한다.

## Frey

역할과 방식: 검으로 근거리를 차지하고, 날개로 공중에 멈춰 어느 방향에서든 파고드는 발키리 브루저다. 2026-11-03 사용자 변경안으로 K·L·I·패시브를 바꿨다(D44).

| 입력 | 기술 | 하는 일 | 주요 수치 | 몸 동작 | 이펙트와 그리기 | 상태 | 이펙트가 따라야 할 값 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `J` 1타 | 발키리 검 연계 1 | 앞으로 조금 나가며 빠르게 벤다. 적중하면 다음 타의 후딜을 바로 끊는다. | 피해 8, 판정 42×34, 이동점 14→58→100, 넉백 235, 활성 0.085초; 선딜/후딜 0.07/0.16초 | `attack_chain` 1~2 | `frey_slash`를 `PlayerBase._draw_attack_art`가 궤적 길이에 맞춰 그림 | 그림 | 판정 크기, 세 이동점, 진행 방향, 0.085초, Frey 금색 |
| `J` 2타 | 발키리 검 연계 2 | 더 멀리 전진해 두 번째 검격을 잇는다. 적중하면 3타로 바로 이어진다. | 피해 9, 44×36, 12→62→108, 넉백 275, 활성 0.095초; 0.08/0.18초 | `attack_chain` 3~4 | `frey_slash`; `_draw_attack_art` | 그림 | 판정과 궤적, 0.095초, 진행 방향 |
| `J` 3타 | 발키리 검 연계 마무리 | 흰빛으로 예고한 뒤 넓게 베어 강하게 날린다. | 피해 13, 52×42, 18→70→118, 넉백 430, 활성 0.12초; 0.11/0.26초 | `attack_chain` 5~6 | `frey_slash`; `_play_finisher_glint`가 몸을 흰색으로 번쩍임 | 그림 | 가장 큰 판정·사거리, 0.12초, 마무리의 밝기 |
| `↑J` | 대공 베기 | 몸 앞에서 머리 위로 벤다. | 피해 10, 40×44, 끝점 y=-114, 넉백 310, 활성 0.105초; 자신 y속도 최대 `-120×JUMP_SPEED` | `attack_up` 2~4 | `frey_slash` | 그림 | 위쪽 궤적, 판정 |
| `공중 ↑J` | 공중 대공 베기 | 지상 대공 베기와 같은 판정으로 공중에서 위를 벤다. | `↑J`와 동일 | `attack_up` 2~4 | `frey_slash` | 그림 | `↑J`와 동일, 공중 방향 |
| `↓J` | 내려 베기 | 앞으로 내려가며 낮은 위치를 벤다. | 피해 12, 44×40, 끝점 (54,38), 넉백 380, 활성 0.115초; y속도 +130 | `attack_down` 3~4 | `frey_slash` | 그림 | 아래쪽 궤적, 판정과 0.115초 |
| `공중 ↓J` | 공중 내려 베기 | 공중에서 같은 내려 베기를 쓴다. | `↓J`와 동일 | `attack_down` 3~4 | `frey_slash` | 그림 | `↓J`와 동일, 낙하 방향 |
| `공중 J` | 공중 옆 베기 | 낙하 속도를 줄이고 전방을 빠르게 벤다. | 피해 8, 40×32, 끝점 x=104, 넉백 260, 활성 0.095초; x속도 +120, y속도 ×0.82 | `attack_air_side` 2~3 | `frey_slash` | 그림 | 104 기본 px 궤적, 진행 방향, 0.095초 |
| `K` | 회오리 검기 | 한 바퀴 돌며 전방으로 검기를 날린다. 맞은 적은 2초 동안 느려진다. 위·아래 방향키로 검기가 조금 위·아래로 기운다. 공중에서도 쓴다. | 선딜/후딜 0.16/0.26초; 검기 피해 10, 기본 30×64, 넉백 300, 속도 `640×COMBAT` `[WAVE_SPEED]`, 수명 0.36초 `[WAVE_LIFETIME]`(약 346 화면 px), 기울기 ±0.3 `[WAVE_TILT]`; 슬로우 2초 `[WAVE_SLOW_TIME]`(이동 ×0.55, `apply_slow`) | 임시: `spike_followup` 전체(회전 동작 줄이 생길 때까지) | 임시: `frey_slash`의 2번째 프레임(금빛 초승달)을 검기 그림으로 씀; `_dress_wave`. 그림이 없으면 색 사각형 | 임시 | 진행 방향·기울기, 30×64 판정(화면 45×96), 수명 0.36초, 금빛; 슬로우 표시 |
| `L` | 비상 베기 | 검을 올려치며 뛰어올라 전방의 적을 Frey보다 높이 띄운다. 맞든 안 맞든 L 재입력 창이 열린다. 공중에서도 쓴다. | 피해 15, 58×58, 끝점 (62,-136), 넉백 510, 활성 0.16초; 강제 발사 (105,-760), 경직 0.32초; 재입력 0.45초 `[RISING_FOLLOWUP_WINDOW]` | `rising_cleave` 2~4 | `attack_vfx/frey_l.png`; 재입력 신호 `frey_spike_ring.png` | 그림 | 위쪽 판정 136, 발사 방향, 재입력 창 0.45초 |
| `L` 재입력 | 발할라 일격 | 비상 베기 뒤 다시 누르면 후딜을 끊고 공중에서 전방을 크게 베어 적들을 날려 버린다. 그 뒤 땅에 닿을 때까지 무방비(다른 행동 잠금)다. | 피해 18, 76×48, 끝점 150, 넉백 700, 활성 0.14초; 선딜 0.127초 `[SPIKE_STARTUP]` | `spike_followup` 3~4 | `frey_slash`; 창이 열린 동안 `frey_spike_ring.png` | 그림 | 0.45초 입력 창, 전방 150 판정, 큰 넉백과 붉은 금색 |
| `I` 지상 | 발키리 강림 | 주위에 빛을 펼쳐 빛에 닿은 적을 자신에게 끌어들인 뒤, 바닥을 내려찍어 좌우 충격파를 내고 0.28초 뒤 여진으로 띄운다. 빛에 아무도 없어도 내려찍는다. 방어 중인 적은 끌려오지 않는다. | 빛 0.45초 `[ULTIMATE_LIGHT_TIME]`, 기본 반경 220 `[ULTIMATE_LIGHT_RADIUS]`(화면 330), 끌어당김 900px/s `[ULTIMATE_PULL_SPEED]`(`apply_grab_pull`, 방어 중이면 안 끌림); 첫 파 피해 26 `[ULTIMATE_WAVE_DAMAGE]`, 기본 도달 240 `[ULTIMATE_WAVE_REACH]`, 76×54, 넉백 420, 활성 0.24초, 기절 2초; 여진 지연 0.28초 `[ULTIMATE_AFTERSHOCK_DELAY]`, 피해 10 `[ULTIMATE_AFTERSHOCK_DAMAGE]`, 84×70, 강제 발사 (±260,-720) | `descent` 전체(빛 0.45초 동안 모으고, 내려찍는 그림이 충격과 함께) | 빛: 임시 코드 원(`_show_light`, 금빛 원판·테두리) + `vfx/frey_ult_charge.png`; 충격파 `vfx/frey_ult_wave.png`; `_ultimate_impact` | 임시(빛), 그림(충격파) | 빛 반경 330 화면 px·0.45초, 좌우 240 기본 도달과 1.5배 전투 배율, 첫 파/여진 간격, 금빛 |
| `공중 I` | 공중 발키리 강림 | 공중에서 빛을 펼쳐 끌어들인 뒤, 아래 바닥까지 수직으로 내려와 지상판과 같은 충격파를 낸다. 끌린 적은 내려찍을 때까지 계속 끌려온다. | 빛은 지상과 같음; 급강하 속도 1050, 최대 1.2초; 착지 뒤 수치는 지상 I와 동일 | `descent` 전체 | 빛(임시) 뒤 급강하 중 `frey_ult_charge`, 착지 `frey_ult_wave` | 임시(빛), 그림 | 수직 방향, 착지점, 충격파 수치와 타이밍 |
| 자동 | 발키리의 날개 | 공중에서 점프를 꾹 누르면 잠시 멈췄다가, 그때 누른 8방향 중 하나로 짧게 돌진하며 벤다. 아무 방향도 누르지 않으면 그냥 떨어진다. 2단 점프와 횟수를 공유하고, 돌진 뒤 착지 전까지 점프·공격이 막힌다. 맞아 날아가는 중에는 못 쓴다. 짧게 누르면 그대로 2단 점프(뗄 때 뜀). 사람만(봇은 쓰지 않음). | 꾹 누름 0.15초 `[WING_HOLD_TIME]`, 정지 0.3초 `[WING_HOVER_TIME]`, 돌진 `760×WORLD` `[WING_DASH_SPEED]` 0.12초 `[WING_DASH_TIME]`; 피해 12, 54×40, 끝 124 `[WING_DASH_REACH]`, 넉백 420; 넉백 속도 120px/s 이상이면 못 씀 `[WING_KNOCKBACK_LIMIT]` | 정지 `dash_strike` 1~2, 돌진 3~6 | 날개: 임시로 `vfx/frey_ult_charge.png`를 0.75배로; 돌진 `attack_vfx/frey_k.png`; 공용 훅 `PlayerBase.character_defers_air_jump`, `_perform_air_jump` | 임시(날개), 그림(돌진) | 정지 위치·0.3초, 돌진 방향과 끝 124, 금빛 날개 |
| Guard | 공용 방어/패리 | 입력 방향을 막고 시작 0.1초에는 패리한다. | 공용 조작 절 참고 | `shield` 전체 | `guard_bubble.png`, `parry_flash.png`; `PlayerBase` | 공용 | 방향, 140도 범위, 0.1초 패리, 감소율 |

특수 상태: 발할라 일격 고리는 공격 판정이 아니라 0.45초 재입력 가능 신호다. 날개 정지는 공중 점프 1회를 쓰고, 돌진 뒤에는 남은 공중 점프가 0이 된다. 회오리 검기의 슬로우는 투사체의 `hit_slow_time`이 적중 때 `apply_slow`를 부른다.

## Luna

역할과 방식: 평상시에는 별 탄으로 표식을 남기고 순간이동과 방어막으로 거리를 다루는 마법소녀다. 궁극기 동안 Brave Luna가 되어 돌진 연타, 붙잡아 던지기, 회오리로 몰아붙이고 별의 광선으로 끝낸다. 2026-11-03 사용자 컨셉안으로 J·K·L·I·패시브를 모두 바꿨다(D45). 예전 별빛 메아리(J), 별 혜성(K), 달고리(L), 별빛 충전(패시브), Brave 혜성 돌진(K), Luna Breaker(L)는 없앴다.

| 입력 | 기술 | 하는 일 | 주요 수치 | 몸 동작 | 이펙트와 그리기 | 상태 | 이펙트가 따라야 할 값 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `J` 1~3번째 | 별빛 연사·작은 별 | 누를 때마다 별을 하나씩 쏜다. 맞은 적에게 별 표식(10초)을 남긴다. 0.6초 안에 다시 누르면 다음 별이다. | 피해 3, 기본 22×22(화면 33×33), 넉백 120, 속도 `700×COMBAT`, 수명 0.3초(약 315 화면 px); 선딜/후딜 0.1/0.2초; 이어 누르기 0.6초 `[STAR_VOLLEY_RESET_TIME]` | `star_side` 전체 | 임시: `effects/luna_star.png`(예전 혜성 별)을 1배로; `LunaStar` | 임시 | 진행 방향, 33×33 판정 |
| `J` 4번째 | 별빛 연사·큰 별 | 큰 별이 맞은 자리나 비행 끝에서 폭발한다. 폭발에 맞아도 표식이 남는다. | 별 피해 2, 기본 40×40(화면 60×60), 속도 `620×COMBAT`, 수명 0.36초; 폭발 피해 8, 기본 120×120(화면 180×180), 넉백 420; 선딜/후딜 0.14/0.3초 | `star_side` 전체 | 별: `luna_star.png` 2배(임시). 폭발: `skill/luna_comet_burst.png` 1.25배; `star_burst_at` | 임시(별), 그림(폭발) | 폭발 180×180, 비행 끝 위치 |
| 방향 `J` | 별빛 연사 | ↑J와 공중 ↑J는 위 60°로, 공중 ↓J는 아래 60°로, 지상 ↓J는 낮게 앞으로 쏜다. 순서(작은 별 3, 큰 별 1)는 같다. | 위와 같음 | `star_up`, `star_down` | 위와 같음 | 임시 | 비스듬한 진행 방향 |
| `K` | 반짝 도약 | 누른 방향(없으면 앞)으로 순간이동하고, 나타난 자리에서 주변을 친다. 땅과 벽은 못 뚫는다. 공중에서는 착지 전에 한 번만 쓴다. | 선딜/후딜 0.14/0.24초(선딜 동안 제자리), 거리 `170×WORLD`(255 화면 px) `[WARP_DISTANCE]`; 폭발은 좌우 반쪽 각 65×110(합쳐 화면 195×165), 피해 9, 넉백 360, 바깥쪽으로 | `star_comet` 전체(임시) | 임시: 떠난 자리와 나타난 자리에 `luna_star_bloom` | 임시 | 거리 255, 폭발 195×165 |
| `L` | 별의 방어막 | 몸 둘레에 5초 동안 원형 방어막을 두른다. 다른 사람의 투사체를 막고, 자신을 향한 공격을 대신 맞는다(피해 30을 받으면 깨짐). 닿은 적은 작은 피해와 함께 밀려난다. 움직이고 공격할 수 있다. | 반경 `70×COMBAT`(105 화면 px) `[BARRIER_RADIUS]`, 5초 `[BARRIER_TIME]`, 내구 30 `[BARRIER_HP]`, 접촉 피해 3·넉백 280(같은 적에게 0.6초마다) `[BARRIER_CONTACT_*]`, 쿨다운 8초 `[BARRIER_COOLDOWN]`(스킬 바에 표시); 선딜/후딜 0.12/0.2초 | `moon_ring` 전체 | 임시: 코드 원(테두리, 옅은 막, 도는 별 5개; `LunaBarrier`), 생길 때와 깨질 때 `luna_moon_ring`, 막을 때 작은 `luna_star_bloom` | 임시 | 반경 105, 5초, 마지막 1초 깜박임 |
| `I` | 브레이브 변신 | 12프레임 변신 뒤 9번째 프레임에 주변을 띄우고 6초간 Brave가 된다(그대로). 같은 순간, 이 Luna가 남긴 별 표식을 같은 렐름에서 거리와 상관없이 모두 터뜨려 피해를 주고 3초 기절시킨다. | 변신 값은 그대로(폭발 피해 14, 240×192, 강제 발사 (0,-560), 지속 6초); 표식 폭발 피해 10, 넉백 140, 기절 3초 `[MARK_BURST_*]` | `transform` 1~12 | `vfx/luna_ult_transform.png`, `luna_star_bloom`, 이후 `luna_brave_aura.png`; 표식 자리에 `luna_comet_burst` | 그림 | 9번째 프레임 폭발, 표식 위치 |
| 자동 | 별의 마법 | 별 표식이 있는 적은 누구에게 맞든 피해를 10% 더 받는다. 표식은 10초이고, 다시 맞으면 새로 10초다. | `PlayerBase.STAR_MARK_DAMAGE_SCALE` 1.1, 10초 `[STAR_MARK_TIME]`; 쓰러지거나 부활하면 지워짐 | 없음 | 머리 위 별(마지막 2초 깜박임), 임시로 `ui/status/luna_star_charge.png`. 기절·아머 표시가 있으면 오른쪽 22px 옆 | 임시 | 24×24, 머리 위 |
| Brave `J` | 브레이브 러시 | 앞으로 짧게 돌진하다가 적을 만나면(앞 72px 안) 그 앞에 멈춰 바로 친다. 잽, 보디 킥, 회전 킥 순서이고 회전 킥이 날려 버린다. 처음부터 가까우면 돌진 없이 친다. | 돌진 `620×WORLD` 최대 0.14초, 타격은 빨라도 0.05초 뒤 `[BRAVE_RUSH_*]`; 적 앞 50px에 선다; 잽 피해 5·넉백 150, 보디 킥 6·205(둘 다 맞으면 후딜을 끊음), 회전 킥 피해 10·강제 발사 (±560,-480)·경직 0.32초; 후딜 0.10/0.11/0.18초 | `brave_combo` 1~2, 3~4, 5~6 | `luna_brave_slash`, `luna_star_bloom` | 그림 | 돌진 거리, 적 앞 50px |
| Brave 방향 `J` | 그대로 | 별빛 어퍼컷(↑J, 공중 ↑J), 낮은 다리 후리기(↓J), 급강하 킥(공중 ↓J), 비행 발차기(공중 J). | 예전 값 그대로 | `brave_upper`, `brave_low`, `brave_dive`, `brave_air_side` | `luna_brave_slash`, `luna_star_bloom` | 그림 | 예전과 같음 |
| 자동(Brave) | 별의 정화 | Brave K·L로 적에게 피해를 준 뒤 3초 안에 J(옆·공중 옆 포함)를 누르면 그 적 앞(560px 안)으로 순간이동해 러시를 친다. 한 번 쓰면 사라진다. | 3초 `[PURIFY_WINDOW]`, 560 화면 px `[PURIFY_RANGE]`, 오던 쪽에 선다, 땅·벽은 못 뚫음 | `brave_combo` | 떠난 자리와 도착한 자리에 `luna_star_bloom` | 임시 | 도착 위치 |
| Brave `K` | 혜성 붙잡기 | 누른 방향으로 돌진해 처음 닿은 적을 붙잡고 0.3초 들고 있다가 던진다. 위를 누르고 있으면 위로, 좌·우를 누르면 그쪽으로, 없으면 앞으로 던진다. 방어 중인 적도 잡힌다. 몬스터는 잡지 못하고 친다. | 선딜 0.08초, 돌진 `760×WORLD` 0.18초, 잡는 거리 64(몸 중심 사이) `[GRAB_*]`; 던지기 피해 12, 옆 (±820,-420)·위 (±60,-1050), 경직 0.5초 `[THROW_*]`; 헛치면 후딜 0.28초; 잡힌 쪽은 `PlayerBase.apply_grab_hold` | 돌진 `comet_drive`, 잡기 `luna_breaker` 1~2, 던지기 3~6(임시) | `luna_star_bloom` | 임시 | 잡는 거리, 던지는 방향 |
| Brave `L` | 별의 회오리 | 최대 3초 동안 회오리 속에서 돈다. 다른 사람의 투사체를 막고 걸어 다닐 수 있다(공격·점프 불가). L을 다시 누르거나 3초가 끝나면 회오리를 앞으로 쏜다. 맞은 적은 2초 기절한 뒤 위로 날아간다. | 반경 `80×COMBAT` `[CYCLONE_RADIUS]`, 3초 `[CYCLONE_TIME]`; 회오리 탄 기본 70×100(화면 105×150), 속도 `520×COMBAT`, 수명 0.6초, 관통; 피해 6 + 기절 2초, 이어서 피해 6·강제 발사 (0,-900) | 선딜 `luna_breaker` 1~2, 회전 `tumble` 반복(임시, `brave_cyclone` 줄이 생기면 그것), 발사 `luna_breaker` 4~6 | 임시: 코드 호 3개(`LunaBarrier` 회오리 모양, `LunaCyclone`) | 임시 | 반경 120, 탄 105×150 |
| Brave `I` | 별의 광선 | 3초 동안 앞으로 광선을 쏜다. 맞은 적은 경직된 채 조금씩 밀리고, 끝에 강한 피해와 함께 날아간다. 끝나면 노말 루나로 돌아간다. Brave 6초가 끝날 때까지 안 쓰면 그냥 돌아간다. | 3초 `[BEAM_TIME]`, 0.15초마다 피해 2.2·넉백 70, 경직 유지 0.2초, 마지막 피해 14·넉백 760 `[BEAM_*]`; 길이·높이는 예전 Heart Laser와 같음(화면 840×168) | `heart_laser` 전체 | `vfx/luna_ult_laser.png` 반복 + `luna_ult_laser_head.png`(하트 광선 그림 그대로), 끝에 `luna_comet_burst`; `LunaHeartLaser` | 그림(하트) | 3초, 끝 폭발 |
| Guard | 공용 방어/패리 | 공용 지상 방어다. | 공용 조작 절 참고 | 현재 형태의 `shield` 전체 | `guard_bubble.png`, `parry_flash.png` | 공용 | 방향, 패리 창, 감소율 |

특수 상태: 투사체를 막는 것은 `projectile_barriers` 무리다(`scripts/ProjectileBarriers.gd`). `Projectile`과 Yuki 부적은 날아가는 매 걸음마다 묻고, 막히면 사라진다(Rio 검기·궁극기 검, Frey 검기, 몬스터 탄, Yuki 부적). 자기 Luna의 탄은 막지 않는다. 방어막은 Luna가 맞는 피해를 대신 받는다(`character_hit_absorption` 0, 받은 피해는 `PlayerBase.last_incoming_damage`). 회오리는 막기만 하고 피해를 대신 받지 않는다. 변신은 폭발 시점부터 6초이고 마지막 1초에는 몸과 오라가 빠르게 깜박인다. 별의 광선이 시작되면 남은 변신 시간은 0이 된다.

## Yuki

역할과 방식: 부적을 먼저 놓고 상대의 이동·착지 경로를 결계로 묶는 음양사 컨트롤러다.

| 입력 | 기술 | 하는 일 | 주요 수치 | 몸 동작 | 이펙트와 그리기 | 상태 | 이펙트가 따라야 할 값 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `J` | 설화부·직선 | 전방으로 빠른 부적을 보내 견제한다. | 피해 6, 기본 30×16, 넉백 190, 속도 `660×COMBAT`, 수명 0.95초 | `talisman_side` 전체 | `assets/art/effects/yuki_talisman.png`; `YukiTalisman.configure` | 그림 | 투사체 방향, 30×16 판정, 속도·0.95초 수명 |
| `↑J` | 설화부·대공 | 위로 부적을 보내 0.18초 뒤 82×74 범위로 펼친다. | 피해 7, 비행 22×30, 넉백 225, 속도 `520×COMBAT`, 수명 0.52초; 폭발 기본 82×74, 0.16초 | `talisman_up` 전체 | `yuki_talisman.png`, 폭발 `attack_vfx/yuki_l.png`; `YukiTalisman._begin_burst` | 그림 | 위 방향, 0.18초 전개, 82×74 폭발 |
| `공중 ↑J` | 공중 설화부·대공 | 공중에서 같은 위 부적을 쓴다. | `↑J`와 동일 | `talisman_up` 전체 | `yuki_talisman.png`, `yuki_l.png` | 그림 | `↑J`와 동일 |
| `↓J` | 지상 퇴마 파동 | 발밑 앞을 짧게 쓸어 근접 적을 밀어낸다. | 피해 7, 54×46, 끝 (76,8), 넉백 285, 0.13초 | `ground_ward` 전체 | `attack_vfx/yuki_slash.png`; `_ground_ward` | 그림 | 낮은 전방 궤적, 판정과 0.13초 |
| `공중 J` | 공중 설화부·직선 | 입력 방향으로 작고 빠른 부적을 발사한다. | 피해 6, 28×14, 넉백 175, 속도 `720×COMBAT`, 수명 0.78초 | `talisman_air_side` 전체 | `yuki_talisman.png` | 그림 | 공중 입력 방향, 속도·수명 |
| `공중 ↓J` | 낙하부 | 아래로 부적을 떨어뜨리고 적이나 발판에 닿으면 넓게 펼친다. | 피해 8, 비행 24×28, 넉백 295, 속도 `610×COMBAT`, 수명 1초; 폭발 기본 94×50, 0.16초 | `talisman_air_down` 전체 | `yuki_talisman.png`, 폭발 `yuki_l.png` | 그림 | 아래 방향, 충돌 지점, 94×50 폭발 |
| `K` | 결박 부적 설치 | 입력을 상하좌우로 고정해 145px 떨어진 곳에 봉인부를 둔다. 지상 아래 입력은 발밑에 둔다. 최대 2개이며 5초 뒤 사라지고 공격 한 번에 찢어진다. | 최대 2개, 기본 거리 145, 유지 5초; 물체 판정 30×42 | `seal_place` 전체 | 설치 `attack_vfx/yuki_k.png`, 대기 `yuki_seal_idle.png`, 파괴 `yuki_seal_break.png`; `YukiSeal` | 그림 | 설치 방향·위치, 5초 잔여 알파, 대기 4프레임, 파괴 5프레임 |
| `L` (봉인부 있음) | 결계 해방 | 모든 봉인부를 0.58초 활성화해 주변을 끌고, 끝에 폭발시킨다. 같은 발동의 중복 폭발 피해는 한 번만 받는다. | 흡입 반경 `135×COMBAT` `[PULL_RADIUS]`, 힘 520; 폭발 반경 `148×COMBAT` `[BURST_RADIUS]`, 피해 11, 넉백 315; 활성 0.58초 `[ACTIVE_TIME]` | `seal_activate` 전체 | 대기 부적이 밝아지고 폭발 `attack_vfx/yuki_l.png`; `_play_burst_effect` | 그림 | 두 반경, 0.58초 흡입, 발동 ID별 1회 피해 |
| `L` (봉인부 없음) | 즉석 결계 | 좌우에 짧은 결계를 내 근접 적을 밀어낸다. | 각 피해 6, 58×62, 끝 x=±92, 넉백 260, 0.12초 | `seal_activate` 전체 | `attack_vfx/yuki_slash.png`; `_emergency_ward` | 그림 | 좌우 대칭 판정, 0.12초, 옅은 청색 |
| `I` | 사방봉진 | 입력 방향 `220×COMBAT` 위치에 결계를 설치한다. 0.7초 예고 후 2.35초 동안 끌고 느리게 하며, 약한 파동과 마지막 강한 파동을 낸다. 기존 봉인부도 함께 발동한다. | 반경 `205×COMBAT` `[FIELD_RADIUS]`, 예고 0.7초 `[WARNING_TIME]`, 활성 2.35초 `[ACTIVE_TIME]`, 파동 간격 0.58초 `[PULSE_INTERVAL]`; 흡입 240 `[FIELD_PULL_STRENGTH]`; 일반 피해 4 `[PULSE_DAMAGE]`, 넉백 90; 마지막 피해 16 `[FINAL_PULSE_DAMAGE]`, 넉백 520, 기절 1.2초 | `grand_ward` 전체 | 결계 `vfx/yuki_ult_seal.png`(ART-67 채택본, 반투명, 가장자리에 얇은 `Line2D` 링), 마지막 `vfx/yuki_ult_burst.png`; `skill/yuki_grand_ward.png`(얇은 링)는 봉인 그림이 없을 때만; `YukiGrandWard` | 그림 | 실제 반경 307.5, 예고/활성 시간, 0.58초 파동, 마지막 폭발 구분 |
| Guard | 공용 방어/패리 | 공용 지상 방어다. | 공용 조작 절 참고 | `shield` 전체 | `guard_bubble.png`, `parry_flash.png` | 공용 | 방향, 패리 창, 감소율 |

특수 상태: 봉인부는 오래된 것부터 제거되는 최대 2개 큐다. 활성 중에는 공격으로 파괴할 수 없고, Yuki가 쓰러지거나 재생성되면 정리된다. 사방봉진은 Yuki가 쓰러지거나 다른 렐름으로 가면 즉시 사라진다. 별도의 상시 패시브는 없다.

## Nova

역할과 방식: 현재 이동 속도와 방향을 공격의 거리·크기·피해로 바꾸는 중력 벡터 공중 추격자다.

| 입력 | 기술 | 하는 일 | 주요 수치 | 몸 동작 | 이펙트와 그리기 | 상태 | 이펙트가 따라야 할 값 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `J` | 벡터 타격·옆 | 현재 운동량에 따라 더 멀리 이동하는 전방 타격이다. | 운동량 0→1: 이동 76→138, 판정 38×30→54×42, 피해 7→11, 넉백 235→510, 활성 0.075→0.12초 | `vector_side` 전체 | `nova_vector_streak.png`; `_play_vector_flash` (공용 `nova_slash` 없음, D40) | 그림 | 실제 운동 방향, 이동·판정·색의 연속 보간 |
| `공중 J` | 공중 벡터 타격 | 현재 비행 방향으로 치며 K를 취소하고 속도를 공격으로 바꾼다. | 지상 옆 J와 같은 보간; y속도 ×0.82 | `air_side` 전체 | `nova_vector_streak` (공용 `nova_slash` 없음) | 그림 | 입력보다 현재 속도 방향 우선, 운동량 색 |
| `↑J` | 벡터 어퍼컷 | 위로 상승하며 상대를 강제로 띄운다. | 운동량 0→1: 피해 7→11, 판정 38×48→48×62, 넉백 300→510, 자신 y속도 -390→-570, 상대 발사 y=-470→-720, 경직 0.22→0.32초 | `vector_upper` 전체 | `nova_impact_star.png` (공용 `nova_slash` 없음, D40) | 그림 | 운동량에 따른 크기·밝기와 위쪽 발사 |
| `공중 ↑J` | 공중 벡터 어퍼컷 | 공중에서 상승량을 88%로 줄여 같은 띄우기를 쓴다. | 공격은 `↑J`와 같음; 자신 상승 속도 ×0.88 | `vector_upper` 전체 | `nova_impact_star` (공용 `nova_slash` 없음) | 그림 | 공중 상승량과 상단 판정 |
| `↓J` | 중력 압축 발구르기 | 현재 위치 주변에 원형 중력 폭발을 낸다. | 운동량 0→1: 반경 48→72, 피해 7→11, 넉백 260→480; 활성 0.14초 | `compression_stomp` 전체 | `nova_gravity_burst.png`, `nova_impact_star.png`; `NovaGravityBurst.configure` | 그림 | 실제 반경 `×COMBAT`, 운동량 색과 0.14초 |
| `공중 ↓J` | 메테오 킥 | 먼저 아래를 차며 급강하하고, 착지 때 현재 운동량에 따른 원형 충격파를 낸다. 착지까지 행동이 잠긴다. | 발차기 피해 6→9, 40×46, 넉백 270→430, 0.12초; 낙하 y속도 560→760, 추가 중력 2600; 착지 반경 68→98, 피해 9→14, 넉백 350→610 | `meteor_kick` 전체 | 발차기 `nova_slash`; 착지 `nova_gravity_burst`, `nova_impact_star`, 공용 `landing_dust` | 그림 | 낙하 방향, 착지 반경·운동량, 지면 위치 |
| `K` | 벡터 시프트 | 입력한 8방향으로 0.22초 동안 개인 중력을 바꿔 가속한다. 공격 판정은 없고 공중에서는 착지 전 1회다. | 0.22초 `[VECTOR_SHIFT_DURATION]`, 가속 `5400×MOVE` `[VECTOR_SHIFT_ACCELERATION]`, 최대 속도 `760×MOVE` `[VECTOR_SHIFT_MAX_SPEED]` | `vector_shift` 전체 | `attack_vfx/nova_k.png`, `nova_shift_dash.png`; `_start_vector_shift`, `_play_shift_flash` | 그림 | 가속 방향·0.22초, 뒤쪽 52px 잔광 |
| `L` | 중력 제동 | 속도를 0으로 만들고 운동량을 원형 폭발로 바꾼다. 운동량 0.6 이상으로 적중하면 공중 K 1회를 회복한다. | 고정 0.2초 후 발동; 반경 58→112, 피해 6→15, 넉백 210→640, 활성 0.14초; 전체 잠금 0.54초 | `gravity_brake` 전체 | `attack_vfx/nova_l.png`, `nova_gravity_burst.png`, `nova_impact_star.png`; 회복 `nova_shift_ready.png` | 그림 | 반경 `×COMBAT`, 운동량 색, 회복 기준 0.6 |
| `I` 1회 | 사건의 지평선·핵 생성 | 입력 방향 105px 위치에 중력핵을 만들고 230 기본 px 안의 적을 끈다. Nova의 이동은 계속된다. | 핵 거리 105 `[ULTIMATE_CORE_DISTANCE]`, 흡입 반경 `230×COMBAT` `[ULTIMATE_PULL_RADIUS]`, 힘 240 `[ULTIMATE_PULL_STRENGTH]` | `slingshot_start` 전체 | `vfx/nova_ult_core.png`; 없으면 `Polygon2D` 핵과 `Line2D` 고리 | 그림 | 핵 고정 위치, 흡입 반경, 회전 방향 |
| `I` 2회 | 사건의 지평선·공전 | 현재 위치에서 핵 주위를 공전한다. 가까운 공전일수록 빠르고 다음 돌진이 길다. 몸 주위 공격 판정과 예상 궤적이 생긴다. | 공전 반경 최소 52, 조정 상한 260; 공전 속도 1080→560; 몸 판정 반경 `36×COMBAT`, 피해 7→10, 넉백 230→350; 궤적 길이=`launch_speed×duration` | `slingshot_start` 뒤 몸 회전 | 핵 `nova_ult_core`; 예상선·도착원은 `_create_ultimate_launch_preview`의 `Line2D`, 몸 판정은 `Polygon2D` | 그림 | 실제 공전 반경, 접선 방향, 예상 종착점; 전용 핵 그림과 도형 선을 함께 사용 |
| `I` 3회 | 사건의 지평선·투석 | 접선으로 돌진한다. 시작 때 핵이 붕괴하고, 적·지형 충돌 또는 최대 시간에 최종 중력 폭발을 낸다. | 돌진 속도 `860→1460×WORLD`, 지속 0.30→0.46초; 몸 반경 `42×COMBAT`, 피해 15→22, 넉백 480→700; 핵 붕괴 반경 `118×COMBAT`, 피해 18, 넉백 300; 최종 반경 124→170 `×COMBAT`, 피해 34→46, 넉백 700→940 | 몸이 돌진 방향으로 회전 | `nova_launch_flash.png`, `nova_ult_burst.png`, `nova_gravity_burst.png`, `nova_impact_star.png` | 그림 | 접선·돌진력, 핵 붕괴와 최종 폭발의 서로 다른 중심·반경 |
| 투석 중 `K` | 투석 방향 전환 | 궁극기 돌진 중 한 번 입력 방향으로 궤도를 꺾고 속도 110을 더한다. 남은 시간은 바뀌지 않는다. | 1회, 속도 +110, 상한 `ULTIMATE_FAST_LAUNCH_SPEED+110` | `jump` | `nova_shift_dash.png`; `_redirect_ultimate_launch_with_vector_shift` | 그림 | 새 방향, 변경 순간, 남은 돌진 시간 |
| 자동 | 운동량 | 속도 204부터 강화가 시작되고 840에서 최대가 된다. 고속이면 청록에서 금색으로 바뀌는 잔상이 생긴다. | 코드 기본 170→700에 `MOVE=1.2`: 204→840 `[MOMENTUM_START_SPEED]`, `[MOMENTUM_MAX_SPEED]`; 잔상은 비율 0.34부터 0.075→0.035초 간격 | 별도 몸 동작 없음 | `skill/nova_momentum_trail.png`; `_update_momentum_visual` | 그림 | 현재 속도 비율, 실제 이동 방향, 청록→금색 |
| Guard | 공용 방어/패리 | 공용 지상 방어다. | 공용 조작 절 참고 | `shield` 전체 | `guard_bubble.png`, `parry_flash.png` | 공용 | 방향, 패리 창, 감소율 |

특수 상태: 운동량은 게이지가 아니라 `velocity.length()`에서 매번 계산한다. K는 공격이 아니며 J나 L을 누르면 즉시 끝난다. 궁극기는 핵 생성 → 공전 → 투석의 세 번 입력이고, 공전·투석 중 피격되면 핵·판정·예고선을 모두 지운다.

## Rio

역할과 방식: 다단 검술, 짧은 순간이동, 공격을 받아 돌려주는 룬으로 공중에서 진입과 이탈을 반복하는 마검사 어쌔신이다.

| 입력 | 기술 | 하는 일 | 주요 수치 | 몸 동작 | 이펙트와 그리기 | 상태 | 이펙트가 따라야 할 값 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `J` 1타 | 마력 참격 1 | 앞으로 나가며 빠르게 벤다. | 피해 7, 38×30, 끝 90, 넉백 200, 0.075초 | `mana_combo` 1~2 | `attack_vfx/rio_slash.png`; `_draw_attack_art` | 그림 | 전방 궤적·0.075초, 청색 마력 |
| `J` 2타 | 마력 참격 2 | 위로 이어지는 두 번째 검격이다. | 피해 8, 40×32, 끝 94, 넉백 230, 0.08초 | `mana_combo` 3~4 | `rio_slash` | 그림 | 위로 휘는 궤적, 0.08초 |
| `J` 3타 | 마력 참격 3·검기 | 근접 3타와 함께 짧은 마력 검기를 발사한다. 검기가 맞으면 맞은 쪽에 Rio 적중 불꽃이 나오고 검기는 사라진다. | 근접 피해 7, 44×40, 끝 100, 넉백 260, 0.10초; 검기 피해 6, 기본 24×54, 넉백 300, 속도 `640×COMBAT`, 수명 0.24초(비행 약 230.4 화면 px) | `mana_combo` 5~6 | 근접 `rio_slash`, 투사체 `rio_mana_wave.png`; `Projectile.set_art`. 검기 적중은 `apply_hit`의 `hit/rio_hit.png`(검기 전용 적중 그림·`hit_streak`은 없음) | 그림 | 근접/투사체 두 판정, 검기 방향·수명·36×81 실제 판정 |
| `↑J` | 상승 베기 | 위로 베어 상대를 강제로 띄운다. | 피해 8, 40×46, 끝 y=-112, 넉백 300, 강제 발사 (±70,-640), 경직 0.26초; 자신 y속도 최대 `-140×JUMP_SPEED` | `rising_slash` 전체 | `rio_slash` | 그림 | 위쪽 궤적과 강제 발사 방향 |
| `공중 ↑J` | 공중 상승 베기 | 공중에서 더 크게 떠오르며 같은 띄우기를 쓴다. | 공격은 `↑J`와 같음; 자신 y속도 최대 `-300×JUMP_SPEED` | `rising_slash` 전체 | `rio_slash` | 그림 | 공중 상승량, 상단 판정 |
| `↓J` | 낮은 베기 | 지면 가까이를 길게 쓸어 낮게 띄운다. | 피해 7, 52×26, 끝 100, 넉백 300, 방향 (앞,-0.35), 0.09초 | `low_sweep` 전체 | `rio_slash` | 그림 | 낮은 y=-8 궤적, 얕은 위 방향 |
| `공중 J` | 공중 베기 | 낙하를 조금 줄이고 전방을 벤다. | 피해 7, 40×30, 끝 98, 넉백 250, 0.085초; x속도 +110, y속도 ×0.8 | `air_slash` 전체 | `rio_slash` | 그림 | 공중 전방 궤적·0.085초 |
| `공중 ↓J` | 낙하 찌르기 | 짧게 준비한 뒤 대각선 아래로 돌진한다. 착지까지 행동이 잠긴다. | 선딜 0.238초; 돌진 속도 `820×WORLD`, 0.22초; 피해 10, 38×50, 경로 180, 넉백 380, 0.20초 | `plunge` 전체 | `rio_slash`; 착지 `landing_dust` | 그림 | 대각선 방향, 돌진 경로·지속, 착지 잠금 |
| `K` | 차원의 베기 | 마지막 8방향 입력으로 최대 200 기본 px 순간이동하고 실제 지나간 경로를 벤다. 지형 앞에서 멈추며 공중에서는 착지 전 1회다. | 준비 0.06초 `[BLINK_HOLD]`, 후딜 0.20초 `[BLINK_RECOVERY]`; 거리 `200×WORLD=300` 화면 px `[BLINK_DISTANCE]`; 피해 10, 56×44, 넉백 340, 0.08초 | `dimension_slash` 전체 | `attack_vfx/rio_k.png`, `skill/rio_blink_trail.png`; `_dimension_slash`, `_play_blink_trail` | 그림 | 실제 이동한 거리·방향, 잘린 경로, 최대 300 화면 px |
| `L` | 룬 방패·반격 | 0.5초 동안 받은 피해를 절반으로 줄이고 넉백·경직을 없앤다. 끝에 흡수 횟수와 넉백에 따라 전방 충격파를 돌려준다. 아무것도 못 받으면 0.32초 빈틈이 생긴다. | 지속 0.5초 `[RUNE_DURATION]`, 피해 배율 0.5 `[RUNE_DAMAGE_SCALE]`, 쿨 3초 `[RUNE_COOLDOWN]`; 반격 피해 `min(6+3×횟수,15)`, 넉백 `min(320+흡수넉백×0.5,820)`, 판정 70×84, 끝 110, 0.12초 | `rune_shield` 전체; 반격은 기본 `attack` | `attack_vfx/rio_l.png`, `rio_rune_guard.png`, `rio_rune_burst.png`; `_show_rune`, `_play_rune_burst` (반격에 공용 `rio_slash` 없음, D40) | 그림 | 0.5초 육각 방패, 흡수 횟수, 반격 40 기본 반경·전방 방향 |
| `I` | 무한 오버드라이브 | 보석 검 6자루가 0.55초 공전한 뒤 0.07초 간격으로 발사된다. 입력 방향, 같은 렐름의 가장 가까운 적, 바라보는 방향 순으로 조준한다. 피격되면 남은 검이 사라진다. | 6자루 `[OVERDRIVE_SWORDS]`, 공전 0.55초 `[OVERDRIVE_ORBIT_TIME]`, 간격 0.07초 `[OVERDRIVE_FIRE_GAP]`, 공전 반경 `58×COMBAT`; 앞 5자루 피해 11 `[OVERDRIVE_SWORD_DAMAGE]`·넉백 320, 마지막 피해 18 `[OVERDRIVE_LAST_DAMAGE]`·넉백 520; 판정 `28×28×COMBAT`, 속도 `980×COMBAT`, 수명 0.62초, 자동조준 `720×COMBAT` | `infinity_overdrive` 전체 | `rio_gem_sword.png`, `vfx/rio_ult_circle.png`, 적중 `vfx/rio_ult_impact.png`; `_make_gem_sword`, `_fire_gem_sword` | 그림 | 6색·6자루 순서, 공전 반경, 발사 간격, 마지막 검의 더 강한 밝기·충격 |
| 자동 | 공중 2회 추가 점프 | 지상을 떠난 뒤 점프를 두 번 더 쓸 수 있다. Sky Step 카드 포함 상한은 3회다. | 기본 공중 점프 2 (`RioData.air_jumps`), 공통 상한 3 `[MAX_AIR_JUMPS]`; 공중 점프 y속도=`jump_velocity×0.86` | `jump` | 발밑 마력 발판 `skill/rio_air_step.png`, 마지막 공중 점프는 더 밝은 `rio_air_step_last.png`(64×64 5프레임, 40fps, 앵커 위 가운데 (32,3)); `Rio.character_on_air_jump`(공용 훅 `PlayerBase.character_on_air_jump`). 발바닥 높이 `[AIR_STEP_SOLE_RISE]` 남·여 8 | 그림 | 남은 점프 횟수(0이면 `_last`), 공중 점프 순간의 발바닥 위치 |
| Guard | 공용 방어/패리 | 룬 방패 L과 별개인 공용 지상 방어다. | 공용 조작 절 참고 | `shield` 전체 | `guard_bubble.png`, `parry_flash.png` | 공용 | 방향, 패리 창, 감소율; 룬 방패와 시각적으로 구분 |

특수 상태: 룬 방패는 공용 Guard/패리와 별도다. 흡수할 때 마지막 공격자 쪽으로 몸을 돌리고, 여러 번 맞을수록 반격이 커진다. 무한 오버드라이브의 여섯 검은 빨강·주황·초록·하늘·보라·분홍 순으로 돌며 마지막 검만 피해와 넉백이 더 크다.

## 선딜 (2026-10-15, D39)

모션 뷰어에서 채택한 속도대로 타격 전 그림이 보이도록 선딜을 늘렸다(사용자: "표의 필요 값대로 전부 늘려줘"). 필요한 값은 `타격 전 그림 수 ÷ 채택 fps`다. 6장 줄은 2장이고, 2장씩 끊는 콤보는 1장이다. 남·여 값이 다르면 더 느린 쪽을 따랐다. 후딜은 그대로이고, 그만큼 공격 전체가 길어졌다.

| 캐릭터 | 기술 | 선딜 (전 → 후, 초) |
| --- | --- | --- |
| Frey | 공중 J | 0.08 → 0.106 |
| Frey | 강스파이크 | 0.055 → 0.127 `[SPIKE_STARTUP]`, 잠금 0.22 → 0.292 |
| Luna | J, 공중 J | 0.10, 0.09 → 0.112 |
| Brave Luna | J 1·2·3타 | 0.045, 0.055, 0.075 → 0.078 |
| Brave Luna | ↑J·공중 ↑J, ↓J, 공중 ↓J, 공중 J | 0.06 → 0.098, 0.06 → 0.111, 0.07 → 0.111, 0.05 → 0.104 |
| Brave Luna | K Comet Drive, L Luna Breaker | 0.07 → 0.104, 0.12 → 0.156 |
| Nova | J, 공중 J | 0.065 → 0.076, 0.05 → 0.077 |
| Nova | ↑J, 공중 ↑J, ↓J, 공중 ↓J | 0.07, 0.06 → 0.087, 0.10 → 0.102, 0.07 → 0.089 |
| Nova | L 중력 제동 | 제자리 고정 0.08 → 0.2 `[BRAKE_STARTUP]`, 잠금 0.42 → 0.54 |
| Nova | I 핵 생성 | 판정 없음. 몸 동작만 0.16 → 0.327초(타격 그림 0.22초 `[SLINGSHOT_POSE_STRIKE]`), 잠금 0.16 그대로 |
| Rio | J 1·2타, 공중 J | 0.05 → 0.079, 0.05 → 0.077 |
| Rio | ↑J·공중 ↑J, ↓J | 0.07 → 0.103, 0.08 → 0.111 |
| Rio | 공중 ↓J 낙하 찌르기 | 0.08 → 0.238 `[PLUNGE_STARTUP]`, 잠금 0.5 → 0.658 |
| Rio | I 무한 오버드라이브 | 판정 없음. 몸 동작만 0.18 → 0.401초(타격 그림 0.28초 `[OVERDRIVE_POSE_STRIKE]`), 잠금·검 공전 0.55초 그대로 |

- 표(`reports/motion-speeds-2026-10-15.md` 3-2절)에 없던 같은 경우도 맞췄다: Luna 공중 J, Brave J 2·3타, Nova 공중 ↑J·↓J, Rio J 2타.
- 맞추지 않은 것: 이동 기술 K. Nova 벡터 시프트(타격 그림 0.073초, 채택 속도면 0.113초)와 Rio 차원의 베기(0.086초, 채택 속도면 0.134초)는 이동·복귀 반응을 지키려고 그대로 둔다(사용자 2026-10-16). 두 줄은 타격 전 그림이 채택 속도보다 조금 빨리 지나간다.
- Luna 별꽃이 상대를 따라가는 하한 `[ECHO_HOME_MIN]`을 75 → 72로 낮췄다. 선딜이 0.012초 길어져 Luna가 약 3px 더 걸어 들어가므로, 110px에서 걸어 들어가며 칠 때 예전 여유(약 9px)를 되돌린 것이다. 별꽃 그림의 크기·모양과는 상관없어 다시 그릴 것은 없다.
- 이펙트는 판정 순간에 나오므로 따로 고칠 것이 없다. 위 하한 말고는 "이펙트가 따라야 할 값"이 바뀌지 않았다.

## 이펙트 스프라이트 작업 목록 (준비)

리드 확인(2026-10-15): 처음 목록의 "Rio 검기 적중 그림 없음"과 "Nova 핵 그림 중심 불일치"는 실제 문제가 아니었다.
- 맞은 쪽 `apply_hit`이 공격자의 적중 불꽃을 그리므로, 검기 적중에도 Rio 불꽃이 나온다.
- Nova의 위치는 발밑 기준이고 몸 중심은 그보다 32px 위다. 끌려오는 상대의 몸은 그림이 그려진 `ultimate_center + (0,-32)`에 정확히 모인다.

사용자 결정(2026-10-15): 이펙트 작업은 **기본 공격(J)부터** 한다.

| 우선 | 캐릭터·기술 | 지금 상태 | 할 일 | 의존 값 |
| ---: | --- | --- | --- | --- |
| 1 | 모든 캐릭터 J(지상·공중, 방향별) | 그림 | 새 스프라이트 수준으로 다시 그리기: `attack_vfx/<id>_slash.png`, Luna `luna_star_bloom`, Yuki `yuki_talisman`·`yuki_slash`, Nova `nova_slash`·`nova_vector_streak`·`nova_impact_star`·`nova_gravity_burst`, Rio `rio_slash`·`rio_mana_wave` | 각 J 행의 "이펙트가 따라야 할 값" |
| 2 | 스킬 K·L, 궁극기, 패시브 | 그림 | J 다음 단계 | 각 행 |
| 3 | 전 캐릭터 Guard/패리 | 공용 | 캐릭터 색이 읽히게 할지 결정 | `guard_direction`, `guard_parry_timer`, `_get_guard_reduction` |
| 4 | Rio 공중 추가 점프 | **그림(2026-10-29 적용)** | CODEX-VFX-01 a안(마력 발판), 첫·마지막 두 상태. 점프 그림이 바뀌면 `[AIR_STEP_SOLE_RISE]`를 다시 잰다 | `air_jumps_left`, 점프 그림의 발바닥 높이 |
| 5 | Frey 발키리의 날개(정지) | 임시 | 공중에 멈춘 동안 등 뒤의 금빛 날개 그림(지금은 궁극기 날개 기운을 작게). 정지 자세 동작 줄 후보 `art/bakeoff/frey/frey-hover_dash`는 보류 상태 | 정지 0.3초, 발 위치 |
| 6 | Frey 회오리 검기 | 임시 | 한 바퀴 도는 몸 동작 줄(지금 `spike_followup`)과 날아가는 검기 그림(지금 `frey_slash` 2번째 프레임), 맞은 적의 슬로우 표시 | 진행 방향·기울기 ±0.3, 30×64 판정, 슬로우 2초 |
| 7 | Frey 발키리 강림의 빛 | 임시 | 반경 330 화면 px로 퍼지는 빛 그림(지금 코드 원) | 반경 `220×COMBAT`, 0.45초 |
| 8 | Frey 스킬 아이콘 K·패시브 | **다시 그림** | `skill_icons/frey_k.png`가 돌진 그림이라 회오리 검기와 다르다 | K 검기 |
| 9 | Luna 별빛 연사(별 탄)·별 표식 | 임시 | 작은 별·큰 별 그림, 표식 아이콘 | 33×33, 60×60, 24×24 |
| 10 | Luna 반짝 도약 | 임시 | 나타날 때 폭발 그림, 몸 동작 줄 `star_warp` | 195×165, 거리 255 |
| 11 | Luna 별의 방어막 | 임시 | 방어막 반복 그림과 깨짐 그림 | 반경 105, 5초 |
| 12 | Brave 별의 회오리·혜성 붙잡기 | 임시 | 회오리 그림(두르기·발사 겸용), 몸 동작 줄 `brave_cyclone`·`brave_grab` | 반경 120, 탄 105×150 |
| 13 | Luna 스킬 아이콘 | **다시 그림** | `luna_j`·`luna_k`·`luna_l`·`luna_brave_k`·`luna_brave_l` | 새 기술 |
| 14 | Brave 별의 광선 | 하트 광선 그대로 | 별 모양 광선으로 바꿀지 사용자가 정한다 | 840×168, 3초 |

5~8은 2026-11-03 CODEX-SKM-03·VFX-03 후보가 있다(`wing_hover`, 날개·검기·강림 빛·슬로우·K 아이콘 A/B). 9~13은 CODEX-SKM-04·VFX-04가 후보를 만든다.

공용 적중 보조 그림은 이미 있고, 모든 전용 공격 그림이 맞춰야 할 접촉 기준이다.
- 공격자별 `hit/<id>_hit.png`: 96×96, 4프레임, 44fps
- `hit_streak.png`: 160×24, 4프레임. 길이는 넉백에 따라 `46~92×COMBAT`
- `landing_dust.png`: 96×32, 5프레임

## 기술을 바꿀 때

- 기술의 몸 동작 줄이나 프레임 범위를 바꾸면 이 문서도 같은 커밋에서 바꾼다.
- 위 표의 “이펙트가 따라야 할 값”이 바뀌면 해당 효과를 작업 목록에 **다시 그림**으로 표시한다.
- 밸런스 커밋에서는 이펙트 아트 파일을 함께 고치지 않는다. 수치와 계약만 먼저 갱신하고 아트는 별도 작업으로 진행한다.
- 동작 줄 속도를 바꾸려면 모션 뷰어에서 다시 채택하고 `tools/motion_viewer/apply_speeds.py`로 `MotionSpeeds.gd`를 다시 만든다. 손으로 고치지 않는다. 줄 속도로 시간이 정해지는 기술(지금은 Luna 변신)은 판정 시각도 함께 바뀌므로 이 문서의 수치를 같은 커밋에서 갱신한다.

## 출처

- 입력·공용 판정·방어·공용 피격 그림: `characters/common/PlayerBase.gd`의 `_unhandled_input`, `basic_attack`, `skill_one`, `skill_two`, `ultimate`, `_get_basic_attack_type`, `_start_attack`, `_spawn_*attack`, `_draw_attack_art`, `_create_guard_visual`, `_update_guard_visual`, `_spawn_hit_effect`, `_spawn_hit_slash`, `_spawn_landing_puff`
- 공격 궤적 잔상과 투사체 그림: `scripts/Attack.gd`의 `_spawn_trail_afterimage`, `scripts/Projectile.gd`의 `set_art`, `_on_body_entered`
- Frey: `characters/frey/Frey.md`, `Frey.gd`, `FreyData.gd`
- Luna: `characters/luna/Luna.md`, `Luna.gd`, `LunaComet.gd`, `LunaHeartLaser.gd`, `LunaData.gd`
- Yuki: `characters/yuki/Yuki.md`, `Yuki.gd`, `YukiTalisman.gd`, `YukiSeal.gd`, `YukiGrandWard.gd`, `YukiData.gd`
- Nova: `characters/nova/Nova.md`, `Nova.gd`, `NovaGravityBurst.gd`, `NovaBodyHitbox.gd`, `NovaData.gd`
- Rio: `characters/rio/Rio.md`, `Rio.gd`, `RioData.gd`
- 이펙트 파일 계약: `scripts/Vfx.gd`, `assets/art/effects/README.md`, `assets/art/effects/passive/README.md`
- 전역 배율: `scripts/GameScale.gd`
