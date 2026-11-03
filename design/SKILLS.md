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

`PlayerBase._get_basic_attack_type`은 지상과 공중, 입력 방향을 조합해 `neutral`, `side`, `up`, `down`, `air_side`, `air_up`, `air_down`으로 나눈다. `basic_attack`, `skill_one`, `skill_two`, `skill_three`, `ultimate`이 각 캐릭터의 `perform_*` 함수로 넘긴다. `skill_three`(U 키, 2026-11-03 D47)는 세 번째 스킬이 있는 캐릭터(`has_skill_three`, 지금 Nova)만 쓰고, 스킬 바의 U 칸도 그때만 보인다. 독립된 공용 대시 입력은 없으며, 코드에서 대시는 Frey K, Brave Luna K, Nova K, Rio K처럼 각 캐릭터 기술의 `skill_dash_velocity`로 구현된다.

방어는 전 캐릭터 공통이다. 지상에서 Guard를 누르면 입력 방향의 140도 범위를 막는다. 처음 0.1초는 패리이며 `[GUARD_PARRY_WINDOW]`, 일반 막기의 피해 감소율은 처음 75%에서 5초 동안 30%까지 내려간다 `[GUARD_START_REDUCTION]`, `[GUARD_MIN_REDUCTION]`, `[GUARD_DECAY_TIME]`. 놓은 뒤 회복은 0.26초다 `[GUARD_RECOVERY]`. 동작은 `shield` 줄 전체이며, 이펙트는 공용 `assets/art/effects/skill/guard_bubble.png`의 평상/피격/패리 프레임과 패리 성공 시 `parry_flash.png`다. 그림이 없으면 `PlayerBase._update_guard_visual`의 `Line2D` 호와 `_play_parry_effect`의 `ColorRect`가 대신한다.

## Frey

플레이 스타일: **올라운더**(D46).

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
| `K` | 회오리 검기 | 한 바퀴 돌며 전방으로 검기를 날린다. 맞은 적은 2초 동안 느려진다. 위·아래 방향키로 검기가 조금 위·아래로 기운다. 공중에서도 쓴다. | 선딜/후딜 0.16/0.26초; 검기 피해 10, 기본 30×64, 넉백 300, 속도 `640×COMBAT` `[WAVE_SPEED]`, 수명 0.36초 `[WAVE_LIFETIME]`(약 346 화면 px), 기울기 ±0.3 `[WAVE_TILT]`; 슬로우 2초 `[WAVE_SLOW_TIME]`(이동 ×0.55, `apply_slow`) | 임시: `spike_followup` 전체(회전 동작 줄이 생길 때까지) | `effects/frey_wave.png`(VFX-03 B, 4프레임 16fps 반복, 1배)를 `Projectile.set_effect_art`가 날아가는 방향에 맞춰 그림. 슬로우 동안 맞은 적 머리 위 `ui/status/slow.png`(VFX-03 A 모래시계). 그림이 없으면 색 사각형 | 그림(몸 동작은 임시) | 진행 방향·기울기, 30×64 판정(화면 45×96), 수명 0.36초, 금빛; 슬로우 표시 |
| `L` | 비상 베기 | 검을 올려치며 뛰어올라 전방의 적을 Frey보다 높이 띄운다. 맞든 안 맞든 L 재입력 창이 열린다. 공중에서도 쓴다. | 피해 15, 58×58, 끝점 (62,-136), 넉백 510, 활성 0.16초; 강제 발사 (105,-760), 경직 0.32초; 재입력 0.45초 `[RISING_FOLLOWUP_WINDOW]` | `rising_cleave` 2~4 | `attack_vfx/frey_l.png`; 재입력 신호 `frey_spike_ring.png` | 그림 | 위쪽 판정 136, 발사 방향, 재입력 창 0.45초 |
| `L` 재입력 | 발할라 일격 | 비상 베기 뒤 다시 누르면 후딜을 끊고 공중에서 전방을 크게 베어 적들을 날려 버린다. 그 뒤 땅에 닿을 때까지 무방비(다른 행동 잠금)다. | 피해 18, 76×48, 끝점 150, 넉백 700, 활성 0.14초; 선딜 0.127초 `[SPIKE_STARTUP]` | `spike_followup` 3~4 | `frey_slash`; 창이 열린 동안 `frey_spike_ring.png` | 그림 | 0.45초 입력 창, 전방 150 판정, 큰 넉백과 붉은 금색 |
| `I` 지상 | 발키리 강림 | 주위에 빛을 펼쳐 빛에 닿은 적을 자신에게 끌어들인 뒤, 바닥을 내려찍어 좌우 충격파를 내고 0.28초 뒤 여진으로 띄운다. 빛에 아무도 없어도 내려찍는다. 방어 중인 적은 끌려오지 않는다. | 빛 0.45초 `[ULTIMATE_LIGHT_TIME]`, 기본 반경 220 `[ULTIMATE_LIGHT_RADIUS]`(화면 330), 끌어당김 900px/s `[ULTIMATE_PULL_SPEED]`(`apply_grab_pull`, 방어 중이면 안 끌림); 첫 파 피해 26 `[ULTIMATE_WAVE_DAMAGE]`, 기본 도달 240 `[ULTIMATE_WAVE_REACH]`, 76×54, 넉백 420, 활성 0.24초, 기절 2초; 여진 지연 0.28초 `[ULTIMATE_AFTERSHOCK_DELAY]`, 피해 10 `[ULTIMATE_AFTERSHOCK_DAMAGE]`, 84×70, 강제 발사 (±260,-720) | `descent` 전체(빛 0.45초 동안 모으고, 내려찍는 그림이 충격과 함께) | 빛: `vfx/frey_ult_light.png`(VFX-03 B, 6프레임 13.3fps, 2배; `_show_light`, 그림이 없으면 코드 원) + `vfx/frey_ult_charge.png`; 충격파 `vfx/frey_ult_wave.png`; `_ultimate_impact` | 그림 | 빛 반경 330 화면 px·0.45초, 좌우 240 기본 도달과 1.5배 전투 배율, 첫 파/여진 간격, 금빛 |
| `공중 I` | 공중 발키리 강림 | 공중에서 빛을 펼쳐 끌어들인 뒤, 아래 바닥까지 수직으로 내려와 지상판과 같은 충격파를 낸다. 끌린 적은 내려찍을 때까지 계속 끌려온다. | 빛은 지상과 같음; 급강하 속도 1050, 최대 1.2초; 착지 뒤 수치는 지상 I와 동일 | `descent` 전체 | 빛(`frey_ult_light`) 뒤 급강하 중 `frey_ult_charge`, 착지 `frey_ult_wave` | 그림 | 수직 방향, 착지점, 충격파 수치와 타이밍 |
| 자동 | 발키리의 날개 | 공중에서 점프를 꾹 누르면 잠시 멈췄다가, 그때 누른 8방향 중 하나로 짧게 돌진하며 벤다. 아무 방향도 누르지 않으면 그냥 떨어진다. 2단 점프와 횟수를 공유하고, 돌진 뒤 착지 전까지 점프·공격이 막힌다. 맞아 날아가는 중에는 못 쓴다. 짧게 누르면 그대로 2단 점프(뗄 때 뜀). 사람만(봇은 쓰지 않음). | 꾹 누름 0.15초 `[WING_HOLD_TIME]`, 정지 0.3초 `[WING_HOVER_TIME]`, 돌진 `760×WORLD` `[WING_DASH_SPEED]` 0.12초 `[WING_DASH_TIME]`; 피해 12, 54×40, 끝 124 `[WING_DASH_REACH]`, 넉백 420; 넉백 속도 120px/s 이상이면 못 씀 `[WING_KNOCKBACK_LIMIT]` | 정지 `wing_hover` 전체(SKM-03), 돌진 `dash_strike` 3~6 | 날개: `effects/skill/frey_wings.png`(VFX-03 A, 6프레임 20fps, 2배 밀도라 0.5배로 표시해 펼친 폭 약 117px, 왼쪽을 보면 뒤집음); 돌진 `attack_vfx/frey_k.png`; 공용 훅 `PlayerBase.character_defers_air_jump`, `_perform_air_jump` | 그림 | 정지 위치·0.3초, 돌진 방향과 끝 124, 금빛 날개 |
| Guard | 공용 방어/패리 | 입력 방향을 막고 시작 0.1초에는 패리한다. | 공용 조작 절 참고 | `shield` 전체 | `guard_bubble.png`, `parry_flash.png`; `PlayerBase` | 공용 | 방향, 140도 범위, 0.1초 패리, 감소율 |

특수 상태: 발할라 일격 고리는 공격 판정이 아니라 0.45초 재입력 가능 신호다. 날개 정지는 공중 점프 1회를 쓰고, 돌진 뒤에는 남은 공중 점프가 0이 된다. 회오리 검기의 슬로우는 투사체의 `hit_slow_time`이 적중 때 `apply_slow`를 부른다.

## Luna

플레이 스타일: 노말 **회피형 아웃파이터**, 브레이브 **추격형 인파이터**(D46).

역할과 방식: 평상시에는 별 탄으로 표식을 남기고 순간이동과 방어막으로 거리를 다루는 마법소녀다. 궁극기 동안 Brave Luna가 되어 돌진 연타, 붙잡아 던지기, 회오리로 몰아붙이고 별의 광선으로 끝낸다. 2026-11-03 사용자 컨셉안으로 J·K·L·I·패시브를 모두 바꿨다(D45). 예전 별빛 메아리(J), 별 혜성(K), 달고리(L), 별빛 충전(패시브), Brave 혜성 돌진(K), Luna Breaker(L)는 없앴다.

| 입력 | 기술 | 하는 일 | 주요 수치 | 몸 동작 | 이펙트와 그리기 | 상태 | 이펙트가 따라야 할 값 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `J` 1~3번째 | 별빛 연사·작은 별 | 누를 때마다 별을 하나씩 쏜다. 맞은 적에게 별 표식(10초)을 남긴다. 0.6초 안에 다시 누르면 다음 별이다. | 피해 3, 기본 22×22(화면 33×33), 넉백 120, 속도 `700×COMBAT`, 수명 0.3초(약 315 화면 px); 선딜/후딜 0.1/0.2초; 이어 누르기 0.6초 `[STAR_VOLLEY_RESET_TIME]` | `star_side` 전체 | `effects/luna_star_shot.png`(VFX-04, 4프레임 16fps 반복, 1배; `Projectile.set_effect_art`); `LunaStar` | 그림 | 진행 방향, 33×33 판정 |
| `J` 4번째 | 별빛 연사·큰 별 | 큰 별이 맞은 자리나 비행 끝에서 폭발한다. 폭발에 맞아도 표식이 남는다. | 별 피해 2, 기본 40×40(화면 60×60), 속도 `620×COMBAT`, 수명 0.36초; 폭발 피해 8, 기본 120×120(화면 180×180), 넉백 420; 선딜/후딜 0.14/0.3초 | `star_side` 전체 | 별: `effects/luna_star_big.png`(VFX-04, 1배). 폭발: `skill/luna_comet_burst.png` 1.25배; `star_burst_at` | 그림 | 폭발 180×180, 비행 끝 위치 |
| 방향 `J` | 별빛 연사 | ↑J와 공중 ↑J는 위 60°로, 공중 ↓J는 아래 60°로, 지상 ↓J는 낮게 앞으로 쏜다. 순서(작은 별 3, 큰 별 1)는 같다. | 위와 같음 | `star_up`, `star_down` | 위와 같음 | 그림 | 비스듬한 진행 방향 |
| `K` | 반짝 도약 | 누른 방향(없으면 앞)으로 순간이동하고, 나타난 자리에서 주변을 친다. 땅과 벽은 못 뚫는다. 공중에서는 착지 전에 한 번만 쓴다. | 선딜/후딜 0.14/0.24초(선딜 동안 제자리), 거리 `170×WORLD`(255 화면 px) `[WARP_DISTANCE]`; 폭발은 좌우 반쪽 각 65×110(합쳐 화면 195×165), 피해 9, 넉백 360, 바깥쪽으로 | `star_warp` 전체(SKM-04): 웅크림·사라짐이 선딜, 3번째 그림(나타나며 휘두름)이 순간이동 순간 | 떠난 자리에 `luna_star_bloom`, 나타난 자리에 `skill/luna_warp.png`(VFX-04 B, 6프레임 24fps, 1배, 몸 중심) | 그림(몸 동작은 임시) | 거리 255, 폭발 195×165 |
| `L` | 별의 방어막 | 몸 둘레에 5초 동안 원형 방어막을 두른다. 다른 사람의 투사체를 막고, 자신을 향한 공격을 대신 맞는다(피해 30을 받으면 깨짐). 닿은 적은 작은 피해와 함께 밀려난다. 움직이고 공격할 수 있다. | 반경 `70×COMBAT`(105 화면 px) `[BARRIER_RADIUS]`, 5초 `[BARRIER_TIME]`, 내구 30 `[BARRIER_HP]`, 접촉 피해 3·넉백 280(같은 적에게 0.6초마다) `[BARRIER_CONTACT_*]`, 쿨다운 8초 `[BARRIER_COOLDOWN]`(스킬 바에 표시); 선딜/후딜 0.12/0.2초 | `moon_ring` 전체 | `skill/luna_barrier.png`(VFX-04 B, 6프레임 10fps 반복, 1배; 마지막 1초 깜박임), 깨질 때 `skill/luna_barrier_break.png`(B, 24fps), 생길 때 `luna_moon_ring`, 막을 때 작은 `luna_star_bloom`; `LunaBarrier`. 그림이 없으면 코드 원 | 그림 | 반경 105, 5초, 마지막 1초 깜박임 |
| `I` | 브레이브 변신 | 12프레임 변신 뒤 9번째 프레임에 주변을 띄우고 6초간 Brave가 된다(그대로). 같은 순간, 이 Luna가 남긴 별 표식을 같은 렐름에서 거리와 상관없이 모두 터뜨려 피해를 주고 3초 기절시킨다. | 변신 값은 그대로(폭발 피해 14, 240×192, 강제 발사 (0,-560), 지속 6초); 표식 폭발 피해 10, 넉백 140, 기절 3초 `[MARK_BURST_*]` | `transform` 1~12 | `vfx/luna_ult_transform.png`, `luna_star_bloom`, 이후 `luna_brave_aura.png`; 표식 자리에 `luna_comet_burst` | 그림 | 9번째 프레임 폭발, 표식 위치 |
| 자동 | 별의 마법 | 별 표식이 있는 적은 누구에게 맞든 피해를 10% 더 받는다. 표식은 10초이고, 다시 맞으면 새로 10초다. | `PlayerBase.STAR_MARK_DAMAGE_SCALE` 1.1, 10초 `[STAR_MARK_TIME]`; 쓰러지거나 부활하면 지워짐 | 없음 | 머리 위 `ui/status/luna_star_mark.png`(VFX-04, 분홍 조준 고리 속 금별; 마지막 2초 깜박임). 기절·아머·슬로우 표시가 있으면 오른쪽 22px 옆 | 그림 | 24×24, 머리 위 |
| Brave `J` | 브레이브 러시 | 앞으로 짧게 돌진하다가 적을 만나면(앞 72px 안) 그 앞에 멈춰 바로 친다. 잽, 보디 킥, 회전 킥 순서이고 회전 킥이 날려 버린다. 처음부터 가까우면 돌진 없이 친다. | 돌진 `620×WORLD` 최대 0.14초, 타격은 빨라도 0.05초 뒤 `[BRAVE_RUSH_*]`; 적 앞 50px에 선다; 잽 피해 5·넉백 150, 보디 킥 6·205(둘 다 맞으면 후딜을 끊음), 회전 킥 피해 10·강제 발사 (±560,-480)·경직 0.32초; 후딜 0.10/0.11/0.18초 | `brave_combo` 1~2, 3~4, 5~6 | `luna_brave_slash`, `luna_star_bloom` | 그림 | 돌진 거리, 적 앞 50px |
| Brave 방향 `J` | 그대로 | 별빛 어퍼컷(↑J, 공중 ↑J), 낮은 다리 후리기(↓J), 급강하 킥(공중 ↓J), 비행 발차기(공중 J). | 예전 값 그대로 | `brave_upper`, `brave_low`, `brave_dive`, `brave_air_side` | `luna_brave_slash`, `luna_star_bloom` | 그림 | 예전과 같음 |
| 자동(Brave) | 별의 정화 | Brave K·L로 적에게 피해를 준 뒤 3초 안에 J(옆·공중 옆 포함)를 누르면 그 적 앞(560px 안)으로 순간이동해 러시를 친다. 한 번 쓰면 사라진다. | 3초 `[PURIFY_WINDOW]`, 560 화면 px `[PURIFY_RANGE]`, 오던 쪽에 선다, 땅·벽은 못 뚫음 | `brave_combo` | 떠난 자리와 도착한 자리에 `luna_star_bloom` | 임시 | 도착 위치 |
| Brave `K` | 혜성 붙잡기 | 누른 방향으로 돌진해 처음 닿은 적을 붙잡고 0.3초 들고 있다가 던진다. 위를 누르고 있으면 위로, 좌·우를 누르면 그쪽으로, 없으면 앞으로 던진다. 방어 중인 적도 잡힌다. 몬스터는 잡지 못하고 친다. | 선딜 0.08초, 돌진 `760×WORLD` 0.18초, 잡는 거리 64(몸 중심 사이) `[GRAB_*]`; 던지기 피해 12, 옆 (±820,-420)·위 (±60,-1050), 경직 0.5초 `[THROW_*]`; 헛치면 후딜 0.28초; 잡힌 쪽은 `PlayerBase.apply_grab_hold` | `brave_grab`(SKM-04): 돌진 1, 잡고 당기기 2~4, 던지기 5~6 | `luna_star_bloom` | 임시 | 잡는 거리, 던지는 방향 |
| Brave `L` | 별의 회오리 | 최대 3초 동안 회오리 속에서 돈다. 다른 사람의 투사체를 막고 걸어 다닐 수 있다(공격·점프 불가). L을 다시 누르거나 3초가 끝나면 회오리를 앞으로 쏜다. 맞은 적은 2초 기절한 뒤 위로 날아간다. | 반경 `80×COMBAT` `[CYCLONE_RADIUS]`, 3초 `[CYCLONE_TIME]`; 회오리 탄 기본 70×100(화면 105×150), 속도 `520×COMBAT`, 수명 0.6초, 관통; 피해 6 + 기절 2초, 이어서 피해 6·강제 발사 (0,-900) | 선딜 `luna_breaker` 1~2, 회전 `tumble` 반복(임시, `brave_cyclone` 줄이 생기면 그것), 발사 `luna_breaker` 4~6 | 도는 동안 `skill/luna_cyclone.png`(VFX-04 B, 6프레임 20fps 반복, 1.25배; `LunaBarrier` 회오리 모양), 쏜 회오리 `skill/luna_cyclone_shot.png`(VFX-04 A, 1배; `LunaCyclone`). 그림이 없으면 코드 호 | 그림(몸 동작은 임시) | 반경 120, 탄 105×150 |
| Brave `I` | 별의 광선 | 3초 동안 앞으로 광선을 쏜다. 맞은 적은 경직된 채 조금씩 밀리고, 끝에 강한 피해와 함께 날아간다. 끝나면 노말 루나로 돌아간다. Brave 6초가 끝날 때까지 안 쓰면 그냥 돌아간다. | 3초 `[BEAM_TIME]`, 0.15초마다 피해 2.2·넉백 70, 경직 유지 0.2초, 마지막 피해 14·넉백 760 `[BEAM_*]`; 길이·높이는 예전 Heart Laser와 같음(화면 840×168) | `heart_laser` 전체 | `vfx/luna_ult_laser.png` 반복 + `luna_ult_laser_head.png`(하트 광선 그림 그대로), 끝에 `luna_comet_burst`; `LunaHeartLaser` | 그림(하트) | 3초, 끝 폭발 |
| Guard | 공용 방어/패리 | 공용 지상 방어다. | 공용 조작 절 참고 | 현재 형태의 `shield` 전체 | `guard_bubble.png`, `parry_flash.png` | 공용 | 방향, 패리 창, 감소율 |

특수 상태: 투사체를 막는 것은 `projectile_barriers` 무리다(`scripts/ProjectileBarriers.gd`). `Projectile`과 Yuki 부적은 날아가는 매 걸음마다 묻고, 막히면 사라진다(Rio 검기·궁극기 검, Frey 검기, 몬스터 탄, Yuki 부적). 자기 Luna의 탄은 막지 않는다. 방어막은 Luna가 맞는 피해를 대신 받는다(`character_hit_absorption` 0, 받은 피해는 `PlayerBase.last_incoming_damage`). 회오리는 막기만 하고 피해를 대신 받지 않는다. 변신은 폭발 시점부터 6초이고 마지막 1초에는 몸과 오라가 빠르게 깜박인다. 별의 광선이 시작되면 남은 변신 시간은 0이 된다.

## Yuki

플레이 스타일: **지역 장악·설치형**(D46).

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

플레이 스타일: **적군·중력 제어**(D46).

역할과 방식: 공격으로 중력 중첩을 쌓아 적을 느리게 하고, 3단계에서 그 자리에 묶는다. 구체로 끌어오고, 광선으로 낚아채고, 필드 안에서는 날아다니며, 궁극기로 적을 구체 둘레에 돌리다 떨어뜨린다. 2026-11-03 사용자 컨셉으로 J·K·L·I·패시브를 바꾸고 세 번째 스킬(U)을 더했다(D47). 예전 벡터 시프트(K), 중력 제동(L), 운동량(패시브), 세 번 누르는 투석은 없앴다. 원문과 리드가 채운 빈 부분은 `reports/nova-kit-2026-11-03/README.md`.

| 입력 | 기술 | 하는 일 | 주요 수치 | 몸 동작 | 이펙트와 그리기 | 상태 | 이펙트가 따라야 할 값 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 자동 | 중력 중첩 | 쌓는 공격에 맞은 적은 중첩이 1단계씩 오른다(최대 3). 쌓일 때마다 2초가 새로 시작되고, 2초마다 한 단계씩 내려간다. 1단계 이동 80%·점프 높이 80%, 2단계 50%·60%. 3단계는 그 자리에 2초 고정(걷기·점프·이동기·넉백 없음, 공격·방어는 됨, 공중이면 그 자리에 뜸)된 뒤 0단계로 돌아간다. 고정 중에는 쌓이지 않는다. | `PlayerBase.GRAVITY_STACK_TIME` 2초, `GRAVITY_ROOT_TIME` 2초, `GRAVITY_MOVE_SCALES` [1, 0.8, 0.5], `GRAVITY_JUMP_HEIGHTS` [1, 0.8, 0.6](점프 속도는 제곱근); `add_gravity_stack`, `is_gravity_rooted` | 없음 | 머리 위 `ui/status/nova_gravity_{1,2,3}.png`(VFX-05 B, 채워지는 중력 우물; 필드 안 중첩 없음은 1단계를 흐리게), 고정 중 발밑 `skill/nova_gravity_root.png`(B 사슬 고리, 6프레임 10fps 반복); `_update_gravity_marks`. 그림이 없으면 코드 점 3개와 고리 | 그림 | 상태 아이콘 줄 위 26px, 3단계 구분, 고정 고리 |
| `J` 1~3타 | 벡터 연타 | 세 번 이어 친다. 1·2타는 적중하면 다음 타가 바로 이어지고, 3타째는 조금 날리며 중첩 1. | 1타 피해 6·40×32·끝 70·넉백 200, 2타 7·42×34·80·230, 3타 9·48×38·104·400 방향 (앞,-0.3); 선딜/후딜 0.07/0.15, 0.07/0.16, 0.09/0.24초; 이어 누르기 0.46초 `[COMBO_RESET_TIME]` | `vector_side` 1~2, 3~4, 5~6 | `nova_vector_streak`; `_chain_strike` | 그림 | 궤적 끝, 3타째 중첩 |
| `↑J`·`공중 ↑J`·`↓J`·`공중 ↓J`·`공중 J` | 벡터 어퍼컷·압축 발구르기·메테오 킥·공중 벡터 타격 | 동작은 그대로다. 운동량이 없어져 예전 중간 세기로 고정했다. 중첩은 쌓지 않는다. | 예전 운동량 0.5의 값 `[STRIKE_POWER]`(예: ↑J 피해 9, ↓J 반경 60·피해 9) | 각 줄 그대로 | 그대로 | 그림 | 그대로 |
| `K` | 중력 구체 | 누른 방향(없으면 앞)으로 구체를 날린다. 처음 닿은 몸이나 최대 사거리에서 터지고, 터진 곳 둘레의 적을 0.35초 끌어온 뒤 중첩 1. 몬스터도 끌려온다. | 선딜/후딜 0.12/0.22초; 구체 30×30(화면 45), 속도 `520×COMBAT`, 수명 0.5초(약 390px); 폭발 반경 `90×COMBAT`(135px), 피해 8, 끌기 0.35초·760px/s `[ORB_*]` | `orb_throw` 전체(SKM-05): 3번째 그림에서 던짐 | 날아가는 구체 `effects/nova_orb.png`(VFX-05 A, 4프레임 16fps 반복, 1배), 폭발은 `skill/nova_gravity_burst`; `NovaOrb`, `orb_burst_at` | 그림 | 45px 구체, 반경 135 폭발 |
| `L` | 중력 필드 | 쓴 자리에 큰 필드를 6초 깐다. 안에서 Nova는 떠서 W/A/S/D로 8방향을 빠르게 날아다닌다(점프 없음). 다른 캐릭터는 안에 있는 동안 1단계 효과(중첩은 아님)를 받고, 나가면 바로 풀린다. 중립 몬스터는 떠올라 아무것도 못 한다. | 반경 `200×COMBAT`(300px), 6초, 쿨다운 12초(스킬 바), 비행 `470×MOVE`, 가속 `3200×MOVE` `[FIELD_*]` | 시전 `zero_gravity` 전체, 필드 안 공중에서는 `field_fly` 반복(SKM-05, `character_air_motion`) | `skill/nova_field.png`(VFX-05 B, 640 칸 6프레임 8fps 반복, 테두리 반경 300, 1배, 마지막 1초 깜박임; `NovaField`). 그림이 없으면 코드 원 | 그림 | 반경 300, 6초 |
| `U` | 중력 광선 | 누른 방향(없으면 앞)으로 광선을 쏜다. 처음 닿은 몸이 땅에 있으면 Nova 앞까지 끌어오고(도착하면 0.3초 경직) 중첩 1. 공중에 있거나 떠 있으면 바로 아래로 내리꽂고 더 큰 피해와 중첩 1. | 선딜/후딜 0.1/0.24초; 26×18, 속도 `1150×COMBAT`, 수명 0.36초(약 620px); 끌기 피해 5·1100px/s·최대 0.45초, 앞 46px; 내리꽂기 피해 11·아래 1000·경직 0.45초 `[BEAM_*]` | 쏘기 `gravity_beam` 1~3(조준·발사·유지), 맞히면 당기기·받기 4~6(SKM-05) | CODEX-VFX-06 A(사용자 2026-11-03): 날아갈 때 곡선 촉수 촉 `effects/nova_beam_head.png`(4프레임 16fps)와 손에서 이어진 줄(`effects/nova_beam_tile.png` 64×16을 이어 붙임, `NovaBeam.make_cord`). 맞히면 끝이 갈라져 적을 감싸고(`skill/nova_beam_split.png` 4프레임 40fps) 끌려오는 동안 조인다(`skill/nova_beam_bind.png` 4프레임 12fps 반복); 줄은 왼쪽에서 오는 그림이라 Nova가 오른쪽이면 뒤집는다(`_start_beam_wrap`). 그림이 없으면 코드 별·선·갈고리 4개 | 그림 | 줄의 시작(몸 중심)과 머리, 감싼 몸 중심(160 칸 중심) |
| `I` 1회 | 사건의 지평선·구체 | 머리 위에 큰 구체를 띄운다. 3초 동안 둘레 345px 안의 적·몬스터(방어 중이어도)가 구체 둘레를 돈다. Nova는 그동안 자유롭다. | 구체 높이 몸 중심 위 150 `[ULTIMATE_SPHERE_HEIGHT]`, 3초, 잡는 반경 `230×COMBAT`, 도는 반경 `75×COMBAT`(112px), 회전 3.2rad/s | `slingshot_start` 전체 | `vfx/nova_sphere.png`(VFX-05 A, 6프레임 12fps 반복, 일반 혼합, 1배, 도는 적 뒤에 그림; `_create_singularity_visual`). 그림이 없으면 `nova_ult_core` 2.2배와 고리 2개 | 그림 | 검은 핵 지름 110, 도는 반경 112 |
| `I` 다시(누르고 있기) | 사건의 지평선·공전과 사출 | 누르고 있는 동안 Nova도 구체 둘레를 돌고(예상 궤적 표시), 떼면 누르고 있던 방향(없으면 궤도 접선)으로 날아가 부딪힌 적에게 피해와 중첩 1. 사출하면 구체가 떨어진다. 봇은 한 번 더 눌러 사출한다. | 공전 반경 `60~200×COMBAT`, 속도 900; 사출 `1150×WORLD` 0.4초, 몸 반경 `42×COMBAT`, 피해 14, 넉백 520 `[ULTIMATE_LAUNCH_*]` | 몸이 진행 방향으로 회전 | `nova_launch_flash`, 예상선 `Line2D` | 그림 | 사출 방향·거리 |
| `I` 끝 | 사건의 지평선·낙하 | 3초가 지나거나, Nova가 사출하거나, 공전·사출 중 Nova가 맞으면 구체가 떨어진다. 아래 발판에 닿으면(없으면 1초 뒤) 터지며 돌던 적에게 피해와 중첩 1. | 낙하 가속 2600, 최대 1100, 최대 1초 `[ULTIMATE_FALL_*]`; 폭발 피해 16, 넉백 600, 반경 `120×COMBAT` `[ULTIMATE_COLLAPSE_*]` | 없음 | `vfx/nova_ult_burst`, `nova_impact_star` | 그림 | 터지는 자리(발판 위) |
| Guard | 공용 방어/패리 | 공용 지상 방어다. | 공용 조작 절 참고 | `shield` 전체 | `guard_bubble.png`, `parry_flash.png` | 공용 | 방향, 패리 창, 감소율 |

특수 상태: 중첩·고정은 `PlayerBase`에 있어 누구나 받는다(쌓는 것은 Nova뿐). 고정은 다른 위치 고정(잡기, 끌기, 궁극기 공전)보다 우선한다. 고정 중에는 순간이동·날개 돌진이 막힌다(Luna 반짝 도약·별의 정화, Rio 차원의 베기, Frey 날개). 필드 안 Nova는 `apply_character_gravity`로 난다. 몬스터는 `RealmMonster.apply_gravity_float`·`apply_gravity_hold`로 뜨고 붙잡힌다.

## Rio

플레이 스타일: **다양한 이동기로 적을 농락하는 암살자**(D46). 새 컨셉안은 `reports/nova-rio-concepts-2026-11-03/`에 있다.

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
| 5 | Frey 발키리의 날개(정지) | **날개 그림·정지 자세(2026-11-03 적용)** | VFX-03 A안, 정지 자세 `wing_hover`(SKM-03, 플레이 테스트 전 리드 선택) | 정지 0.3초, 발 위치 |
| 6 | Frey 회오리 검기 | **검기·슬로우 그림(2026-11-03 적용)** | 검기 VFX-03 B안, 슬로우 표시 A안(모래시계). 한 바퀴 도는 몸 동작 줄은 아직 `spike_followup`(`whirl_spin` 후보 보류) | 진행 방향·기울기 ±0.3, 30×64 판정, 슬로우 2초 |
| 7 | Frey 발키리 강림의 빛 | **그림(2026-11-03 적용)** | VFX-03 B안(깃 화관) | 반경 `220×COMBAT`, 0.45초 |
| 8 | Frey 스킬 아이콘 K | **그림(2026-11-03 적용)** | VFX-03 A안(대각선 검·회전 궤적·떨어져 나가는 초승달, J·L 아이콘과 같은 검), 플레이 테스트 전 리드 선택. B안은 `art/bakeoff/skill_icons/frey/frey_k-b-v1.png`에 남음 | K 검기 |
| 9 | Luna 별빛 연사(별 탄)·별 표식 | **그림(2026-11-03 적용)** | VFX-04 작은 별·큰 별·표식 | 33×33, 60×60, 24×24 |
| 10 | Luna 반짝 도약 | **폭발 그림·몸 동작(2026-11-03 적용)** | VFX-04 B안, 몸 동작 줄 `star_warp`(SKM-04, 리드 선택) | 195×165, 거리 255 |
| 11 | Luna 별의 방어막 | **그림(2026-11-03 적용)** | VFX-04 B안(방어막·깨짐) | 반경 105, 5초 |
| 12 | Brave 별의 회오리·혜성 붙잡기 | **회오리 그림(2026-11-03 적용)** | 도는 동안 VFX-04 B안, 쏜 회오리 A안. 붙잡기 몸 동작 줄 `brave_grab`(SKM-04, 리드 선택). 회오리 몸 동작 `brave_cyclone`은 보류(다시 그림) | 반경 120, 탄 105×150 |
| 13 | Luna 스킬 아이콘 | **그림(2026-11-03 적용)** | VFX-04 `luna_j`·`luna_k`·`luna_l`·`luna_brave_k`·`luna_brave_l` | 새 기술 |
| 14 | Brave 별의 광선 | **하트 광선 유지(2026-11-03 리드 결정)** | 플레이 테스트 전에 빠르게 정함: Brave I 아이콘(하트)과 `heart_laser` 동작(손 하트)에 맞는 지금 광선 그대로. 별 모양은 나중 스킬 작업에서 다시 볼 수 있다 | 840×168, 3초 |
| 15 | Nova 중력 중첩 표시·고정 | **그림(2026-11-03 적용)** | VFX-05 B안(중력 우물 3단계, 사슬 고리) | 상태 아이콘 줄 위, 3단계 |
| 16 | Nova 중력 구체·폭발 | **구체 그림(2026-11-03 적용)** | VFX-05 A안. 터짐은 지금 중력 폭발 그대로 | 45px, 반경 135 |
| 17 | Nova 중력 필드 | **그림(2026-11-03 적용)** | VFX-05 B안(밝은 분절 테두리) | 반경 300, 6초 |
| 18 | Nova 중력 광선 | **그림(2026-11-03 적용)** | 사용자: 끝이 갈라져 적을 감싼 뒤 앞으로 끌고 옴. CODEX-VFX-06 A안(곡선 촉수, 보라 섬유 줄). B안과 pixelfx C안(`reports/pixelfx-eval-2026-11-03/`)과 비교해 골랐다 | 26×18, 약 620px, 감싼 몸 60×90 |
| 19 | Nova 사건의 지평선 구체 | **그림(2026-11-03 적용)** | VFX-05 A안(나선 강착 원반). 낙하 뒤 폭발은 `nova_ult_burst` 그대로 | 도는 반경 112 |
| 20 | Nova 스킬 아이콘 | **그림(2026-11-03 적용)** | VFX-05 `nova_j`·`nova_k`·`nova_l`·`nova_u`(새)·`nova_i` | 새 기술 |
| 21 | Nova 몸 동작 줄 | **그림(2026-11-03 적용)** | 리드 선택(남·여 모두): K `orb_throw`, U `gravity_beam`, L 시전 `zero_gravity`, 필드 안 비행 `field_fly` | 줄 표 13줄. `vector_shift`·`gravity_brake`는 더 안 씀(줄 자리만 유지) |

5~13의 이펙트는 2026-11-03 사용자 선택으로 넣었다(Frey 날개 A·검기 B·강림 빛 B·슬로우 모래시계, Luna 회오리 투사체 A·회전 중 B·나머지 B와 하나뿐인 후보; `reports/vfx-picks-2026-11-03/`). Frey K 아이콘(A안), 몸 동작 줄(`wing_hover`, `star_warp`, `brave_grab`, Nova 4줄), 별의 광선(하트 유지)은 사용자가 플레이 테스트 전에 리드에게 맡겨 2026-11-03 리드가 정했다(`reports/playtest-prep-2026-11-03/`). 남은 것: `whirl_spin`·`brave_cyclone`은 다시 그림.

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
