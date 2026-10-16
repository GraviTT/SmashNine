<!-- Codex blind answer (CODEX-QA-19, merged c3f96fb). Boards and JSON: reports/codex-qa-19/ -->
# CODEX-QA-19 — 캐릭터 스프라이트·이펙트 블라인드 감사

## 결론

캐릭터 시트 자체는 전반적으로 양호하다. 8형태 658프레임에서 빈 프레임, 완전 중복, 셀 가장자리 접촉, 4px 안전 여백 침범이 모두 0건이었다. 가장 큰 문제는 그림 파일의 규격이 아니라 **공격 도달거리로 이펙트의 폭과 높이를 함께 키우는 공통 배치와, 같은 타격에 여러 완성형 이펙트를 겹치는 코드**다.

아래 평가는 리드의 답을 보지 않은 블라인드 결과다. `측정`과 `의견`을 구분했고, 판정·피해·선딜은 변경 대상으로 삼지 않았다.

## Findings — 강한 순서

### B1. 다섯 근접형의 공용 J 궤적이 몸·판정보다 두껍고 밝다

- **심각도:** 높음. 가장 자주 보는 기본 공격이라 전투 전체의 자세·방향·상대 위치를 흐린다.
- **범위:** Frey, Luna, Brave Luna, Nova, Rio의 J 계열. Yuki는 일반 J가 부적이라 예외이고 지상 `↓J`만 `yuki_slash`를 쓴다.
- **측정:** 논리 프레임은 Frey/Luna/Rio/Yuki `192×128`, Brave `224×128`, Nova `160×128`이다. [`PlayerBase.gd:1175`](../../smash-nine-prototype/characters/common/PlayerBase.gd)은 도달거리로 구한 **하나의 균일 배율**을 x·y에 같이 적용한다. 따라서 폭을 판정 끝에 맞출수록 높이도 폭의 57~80%가 된다. 최대 차이 프레임의 화면 변화율은 Frey 지상 J 7.67%, Luna 공중 J 8.02%, Nova 지상 J 5.31%이고, Yuki 지상 `↓J`는 3.94%였다.
- **시각 근거:** [`boards/problem-vs-good-effects-1x.png`](boards/problem-vs-good-effects-1x.png), 캐릭터별 `clips-*-p*-1x/3x.png`.
- **소유자:** **코드 배치**. 원본 스트립의 프레임 수·2배 소스 보정은 맞고, 런타임의 균일 확대가 문제를 만든다. 다른 결함을 코드에서 보상하는 것이 아니다.
- **조치:** **code fix / 소~중 비용.** `_draw_attack_art`에 로컬 y축 두께 배율을 분리해 x는 도달거리를 유지하고 y만 우선 0.55~0.70 후보로 비교한다. 판정과 타이밍은 그대로 둔다. 수치는 사용자 화면 선택 전 확정하지 않는다.
- **의견:** “화려함이 과하다”는 취향이지만, 동일 배율 비교에서 자세가 사라지고 화면 변화량이 2배 가까이 되는 점은 측정 사실이다.

### B2. Rio 룬 반격은 독립적으로 완성된 효과들이 한 타격에 겹쳐 표적을 지운다

- **심각도:** 높음. 반격 성공 순간은 Rio와 피격자를 읽어야 하는데 가장 복잡한 화면이 된다.
- **측정:** `rio/rune-fx.webp` 프레임 25는 화면 16.50%가 바뀌고, no-fx 전경 프록시의 39.45%가 덮인다. 같은 지표에서 Rio 궁극기는 8.19%/0.81%다. [`Rio.gd:307`](../../smash-nine-prototype/characters/rio/Rio.gd), [`Rio.gd:349`](../../smash-nine-prototype/characters/rio/Rio.gd), [`Rio.gd:366`](../../smash-nine-prototype/characters/rio/Rio.gd)과 공통 slash·hit spark·hit streak가 합쳐진다.
- **시각 근거:** `problem-vs-good-effects-1x.png`의 네 번째 행, `clips-rio-p2-1x/3x.png`.
- **소유자:** **코드 배치**. `rio_slash`, `rio_rune_burst`, 피격 불꽃은 각각 단독으로는 읽힌다. 효과 미술을 다시 그리면 중복 원인을 가리는 보상 수정이다.
- **조치:** **code fix / 소 비용.** 룬 반격 공격에서 공통 `rio_slash`만 끄고 `rio_rune_burst`를 주 신호로 남긴다. hit spark/streak는 적중 신호이므로 유지한다.

### B3. 지상 하향·저공격의 궤적이 발판 아래로 크게 빠진다

- **심각도:** 중상. 공격 방향을 보여 줘야 할 밝은 부분이 지면 아래나 화면 밖으로 사라지고 발끝 파편만 남는 장면이 있다.
- **측정:** 1× 클립에서 Frey/Luna/Brave/Nova/Rio의 `ground-j`와 `down-j` 최대 차이 bbox가 모두 화면 아래 `y=540`에 닿았다. Yuki의 여섯 J 클립은 모두 아래 경계에 닿지 않았다. `PlayerBase.gd:1189-1193`은 몸 중심에서 궤적을 회전할 뿐 바닥 기준 보정이 없다.
- **시각 근거:** `clips-frey-p1-1x.png`의 `down-j`, `clips-luna-p1-1x.png`, `clips-rio-p1-1x.png`.
- **소유자:** **코드 배치**. 판정 방향은 gameplay 소유이므로 건드리지 않는다. 시각 원점·표시 각도를 판정과 분리하는 것이 소유자 안의 수정이며 gameplay 결함을 아트로 보상하는 것이 아니다.
- **조치:** **code fix / 중 비용.** 지상 하향 계열에 시각 전용 원점/각도 옵션을 주어 밝은 날이 발판 윗면에 남게 한다. 변경 전후에 hit area 중심과의 오차를 캡처로 확인한다.

### B4. Luna·Brave Luna는 slash와 star bloom이 둘 다 전경 완성형이라 두 번째 타격 정보가 묻힌다

- **심각도:** 중상. 2단 구조(궤적 뒤 별꽃)가 Luna의 핵심인데, 현재는 두 그림이 합쳐져 한 번의 흰 섬광처럼 보인다.
- **측정:** `luna_slash`는 논리 `192×128`, bloom은 `256×256`, 각각 z=5와 z=6이다. `Luna.gd:288-332`가 같은 입력에 궤적과 지연 bloom을 만들고, `Luna.gd:681-704`가 bloom을 공격 반경의 2.5배 가시 지름으로 그린다. Luna 공중 J 최대 차이 점수는 13.498, 공중 `↓J`는 10.003이었다. Brave의 모든 J/K/L도 두 계열을 반복 사용한다.
- **시각 근거:** `clips-luna-p1/p2-1x.png`, `clips-luna_brave-p1/p2-1x.png`.
- **소유자:** **코드 배치**. 두 효과 파일은 단독 식별성이 있다. 다시 그리기보다 합성의 크기·레이어·알파가 소유한다.
- **조치:** **code fix / 소 비용.** bloom을 몸 뒤(z<캐릭터)로 보내고 가시 지름 계수 2.5 및 알파 0.82의 축소 후보를 캡처 비교한다. 판정 반경은 유지한다.

### B5. Nova 옆·위 J는 공통 `nova_slash`와 전용 방향 신호를 중복 출력한다

- **심각도:** 중상. 빠른 캐릭터의 이동 벡터보다 흰 덩어리가 먼저 읽힌다.
- **측정:** 옆 J는 [`Nova.gd:212-217`](../../smash-nine-prototype/characters/nova/Nova.gd)에서 공통 sweeping attack과 `nova_vector_streak`를, 위 J는 `Nova.gd:226-231`에서 공통 slash와 `nova_impact_star`를 함께 낸다. 전용 streak는 논리 `192×48`로 방향 표시에 충분하지만 공통 slash는 `160×128`이다. 지상 J 프레임 4는 전경 프록시 11.10%가 바뀐다.
- **시각 근거:** `problem-vs-good-effects-1x.png`의 Nova 행, `clips-nova-p1/p2-3x.png`.
- **소유자:** **코드 배치**. 전용 효과가 이미 있으므로 새 그림은 중복 원인을 고치지 못한다.
- **조치:** **code fix / 소 비용.** vector side/air side/upper에 한해 공통 slash를 끄고 streak/impact만 남긴다. compression stomp의 gravity burst는 별도라 유지한다.

### B6. Rio 네 행은 D34 기준 머리보다 확실히 작다

- **심각도:** 중간. 이펙트가 없는 순간에도 같은 캐릭터의 체격이 공격마다 줄어들어 한 캐스트 감각을 해친다.
- **측정:** 프로젝트의 `head_scale.py`를 각 형태 idle 1번에 맞춰 대표 타격 프레임을 비교했다. 신뢰 점수 0.6 이상에서 Rio male 기본 `attack` 0.76(score 0.779), Rio female 기본 `attack` 0.86(0.779), female `low_sweep` 0.72(0.611), female `dimension_slash` 0.72(0.679)였다. 다른 신뢰 통과 행 범위는 Frey 0.92~1.02, Luna 0.96~1.02, Nova male 0.96~1.02, Nova female 0.96~1.06이었다.
- **시각 근거:** [`boards/rio-head-scale-3x.png`](boards/rio-head-scale-3x.png). 같은 3× 배율이다.
- **소유자:** **스프라이트 미술**. 코드에서 행별 확대하면 발·검·충돌 중심까지 함께 어긋나므로 원본 크기 문제를 코드로 보상하게 된다.
- **조치:** **redraw candidate / 중 비용.** D35 방식으로 Rio만 한 차례 진행해 위 네 행을 기준 idle 머리 0.96~1.04로 다시 후보화한다. 사용자 채택 전 게임 시트에는 넣지 않는다.

### B7. Luna 변신, Nova 궁 폭발, Yuki 궁 종결은 순간적으로 전투 위치를 지운다

- **심각도:** 중간. 궁극기 연출의 화려함은 필요하지만 배틀로열에서 다른 선수의 위치까지 사라지는 순간은 조작 정보를 잃게 한다.
- **측정:** 최대 차이 프레임에서 화면 변화/전경 겹침은 Luna 변신 28.10%/42.35%, Nova 궁 38.81%/58.52%, Yuki 궁 종결 25.74%/33.05%였다. Rio 궁은 8.19%/0.81%로 몸이 남는 대조군이다.
- **시각 근거:** [`boards/ultimate-body-visibility-1x.png`](boards/ultimate-body-visibility-1x.png).
- **소유자:** **코드 배치**. 원본 궁극기 그림은 의도대로 크다. 문제는 전경 z와 최종 알파이므로 redraw는 원인을 옮기는 보상이다.
- **조치:** **code fix / 소 비용.** 세 효과의 최종 알파를 0.65~0.80 후보로 비교하고, 가능하면 캐릭터 몸보다 뒤에 둔다. 화면 채움 면적과 판정은 유지한다.
- **의견:** 궁극기에서 짧은 white-out을 허용할지는 연출 취향이다. 다만 수치와 비교 화면상 Rio만 전투 실루엣을 보존한다.

### B8. Rio의 고유 공중 점프 2회에 남은 횟수·발동 신호가 없다

- **심각도:** 중간. 플레이어가 Rio만의 이동 자원을 눈으로 셀 수 없고 상대도 두 번째 공중 점프를 구분하기 어렵다.
- **근거:** `RioData.gd:18`은 `air_jumps=2`, 공통 `PlayerBase.gd:737-740`은 속도와 카운트만 바꾸며 효과를 만들지 않는다. `design/SKILLS.md`도 “별도 점프 이펙트 없음”으로 기록한다.
- **소유자:** **효과 미술 + gameplay 피드백 훅**. 수치 문제는 아니며, 스프라이트 행을 고치는 것은 다른 컴포넌트에서 보상하는 수정이다.
- **조치:** **redraw candidate / 소 비용(+작은 연결 코드).** 4프레임 이하의 작은 청색 발판/보석 파편 후보를 공중 점프 순간 발밑에만 표시한다. 채택 전에는 연결하지 않는다.
- **의견/미확인:** 전용 점프 클립이 없어 실제 혼전 체감은 추론이다.

### B9. Nova female 피격 프레임만 바닥에서 8px 뜬다

- **심각도:** 낮음~중간. 피격 때 한 프레임이므로 짧지만, 지상 피격이 공중으로 들리는 것처럼 보인다. 게임의 1× 기준 8px다.
- **측정:** 모든 형태의 base `hurt` 마지막 불투명 y는 120인데 Nova female만 y=112다. 셀 가장자리 문제는 아니다.
- **시각 근거:** [`boards/hurt-feet-baseline-3x.png`](boards/hurt-feet-baseline-3x.png).
- **소유자:** **스프라이트 미술**. 캐릭터별 코드 오프셋은 한 장의 원본 기준선 결함을 런타임에서 보상하게 된다.
- **조치:** **redraw candidate / 매우 소 비용.** 같은 그림을 8px 내린 한 프레임 후보를 비교한다.

## 형태별 판정

| 형태 | 스프라이트 | 이펙트 |
|---|---|---|
| Frey | **OK.** 83프레임, 경계/빈칸/중복 0. 머리 신뢰 통과 13행 0.92~1.02. | **문제.** 공통 slash 과대, 지상 하향 궤적 바닥 아래. 궁·표식은 유지 가능. |
| Luna | **OK.** 77프레임, 특수 변신 12프레임 포함 규격 일치. | **문제.** slash+bloom 중첩, 변신 white-out. 혜성·달고리는 유지. |
| Brave Luna | **OK(자동 머리 검사는 제한).** 83프레임, 경계/빈칸/중복 0. | **문제.** 거의 모든 공격의 slash+bloom 중첩. 오라는 몸을 남겨 유지. |
| Yuki | **OK(머리 자동 검사는 실패, 1×/3× 육안 확인).** 83프레임. | **대체로 OK.** 일반 부적·봉인·가드가 좋은 대조군. 궁 종결 알파만 조정 후보. |
| Nova male | **OK.** 머리 신뢰 통과 13행 0.96~1.02. | **문제.** 공통 slash+전용 방향 신호 중복, 궁 white-out. |
| Nova female | **피격 1프레임 y=112 문제.** 그 외 규격·머리 범위 양호. | male과 같은 코드라 같은 문제로 추정. **실제 female 클립 없음.** |
| Rio male | **문제.** 기본 `attack` 머리 0.76. 그 외 시트 규격 양호. | **문제.** 공통 slash, 룬 반격 중첩, 공중 점프 신호 없음. |
| Rio female | **문제.** 기본 `attack` 0.86, `low_sweep`·`dimension_slash` 0.72. | male과 같은 코드라 같은 문제로 추정. **실제 female 클립 없음.** |

## 게임을 가장 해치는 세 문제

1. **B1 공통 J 궤적의 균일 과대 확대:** 가장 자주 반복되고 다섯 형태에 동시에 영향을 준다.
2. **B2 Rio 룬 반격의 다중 전경 중첩:** 성공·피격·대상 위치가 모두 같은 흰/청색 덩어리에 묻힌다.
3. **B3 지상 하향 궤적의 바닥 아래 손실:** 밝은 타격 방향이 실제 플레이 공간 밖으로 빠져 입력과 결과의 연결이 약해진다.

## 유지 권고

- **현재 공용 가드:** `(24,-58)` 전방 배치 후 몸과 방향을 남긴다. `keep`.
- **Yuki 일반 부적·봉인 효과:** 작은 투사체와 발동 지점을 구분하며 몸을 가리지 않는다. `keep`.
- **Luna 혜성 trail/burst, Brave aura, Rio 궁 원형·검:** 역할과 레이어가 분리된다. `keep`.
- **50개 Vfx 스트립의 규격:** 모든 폭이 `frames`로 나누어지고 `AUTHORED_WIDTH` 대비 1×/2× 비율이 맞는다. `luna_ult_laser`만 프레임 옆면 픽셀이 닿지만 x축 타일용이므로 결함이 아니다. `keep`.

## 시각 비교

![일반 효과 문제와 양호한 예](boards/problem-vs-good-effects-1x.png)

위 보드는 동일 프레임의 no-fx/fx를 1×로 붙였다. 위 네 행은 효과가 자세·대상을 압도하는 예이고, 아래 두 행은 Yuki의 제한된 전경 점유와 수정된 공용 가드다.

![궁극기 몸 가시성 비교](boards/ultimate-body-visibility-1x.png)

Luna·Nova·Yuki의 최대 차이 프레임과, 캐릭터 실루엣을 남기는 Rio 궁극기를 같은 1× 조건으로 비교했다.

![Rio 머리 크기 비교](boards/rio-head-scale-3x.png)

모든 그림은 같은 3× nearest 배율이다. 숫자는 각 형태 idle 머리 대비 D34 템플릿 매칭값이다.

## 스프라이트 행 인벤토리

표기는 `행(프레임@게임 fps)`이다. fps는 표의 원래 값이 아니라 `MotionSpeeds.gd`의 사용자 채택값이다. 전체 프레임별 발선·몸 높이·머리 프록시·중심 이동은 [`sheet_measurements.json`](sheet_measurements.json), D34 머리 매칭은 [`head_scale_measurements.json`](head_scale_measurements.json)에 있다.

| 형태 | base 128px (발 y=120) | moves 192px (발 y=152) |
|---|---|---|
| Frey | idle(6@6.3), walk(8@11.31), jump(1@1), fall(1@1), attack(6@17.85), shield(6@9), hurt(1@1) | attack_up(6@16.8), attack_down(6@17.85), attack_air_side(6@18.9), dash_strike(6@17.85), rising_cleave(6@15.12), spike_followup(6@15.75), descent(6@9.8), tumble(6@18.9), attack_chain(6@14.7) |
| Luna | idle(6@6.3), walk(8@11.31), jump(1@1), fall(1@1), attack(6@17.85), shield(6@9.6), hurt(1@1) | star_up(6@19.95), star_down(6@17.85), star_comet(6@16.8), moon_ring(6@13.44), transform(12@7.8), tumble(6@24.15), star_side(6@17.85) |
| Brave Luna | idle(6@5.36), walk(8@11.97), jump(1@1), fall(1@1), attack(6@16.8), shield(6@10.8), hurt(1@1) | brave_combo(6@12.8), brave_upper(6@20.4), brave_low(6@18), brave_air_side(6@19.2), brave_dive(6@18), comet_drive(6@19.2), luna_breaker(6@12.8), heart_laser(6@10.2), tumble(6@26.25) |
| Yuki | idle(6@6.3), walk(8@9.98), jump(1@1), fall(1@1), attack(6@21.38), shield(6@9.6), hurt(1@1) | talisman_side(6@19.95), talisman_up(6@17.5), ground_ward(6@17.33), talisman_air_side(6@23.31), talisman_air_down(6@16.65), seal_place(6@14.02), seal_activate(6@12.48), grand_ward(6@6.31), tumble(6@21) |
| Nova male | idle(6@6.3), walk(8@10.64), jump(1@1), fall(1@1), attack(6@26.44), shield(6@10.2), hurt(1@1) | vector_side(6@26.44), vector_upper(6@23.1), compression_stomp(6@19.58), air_side(6@30), meteor_kick(6@22.5), vector_shift(6@17.75), gravity_brake(6@10.73), slingshot_start(6@9.1), tumble(6@17.85) |
| Nova female | idle(6@6.3), walk(8@10.64), jump(1@1), fall(1@1), attack(6@24.67), shield(6@9), hurt(1@1) | vector_side(6@28.2), vector_upper(6@24.75), compression_stomp(6@19.58), air_side(6@26), meteor_kick(6@22.5), vector_shift(6@17.75), gravity_brake(6@10.01), slingshot_start(6@10.5), tumble(6@21) |
| Rio male | idle(6@6.3), walk(8@9.31), jump(1@1), fall(1@1), attack(6@14.7), shield(6@9.6), hurt(1@1) | mana_combo(6@13.5), rising_slash(6@19.5), low_sweep(6@19.5), air_slash(6@26), plunge(6@9), dimension_slash(6@14.95), rune_shield(6@8.4), infinity_overdrive(6@7.15), tumble(6@21) |
| Rio female | idle(6@6.3), walk(8@9.31), jump(1@1), fall(1@1), attack(6@13.65), shield(6@9), hurt(1@1) | mana_combo(6@12.6), rising_slash(6@21), low_sweep(6@18), air_slash(6@26), plunge(6@8.4), dimension_slash(6@14.95), rune_shield(6@7.8), infinity_overdrive(6@8.25), tumble(6@21) |

## 이펙트 인벤토리

총 **65개**다. 각 항목의 실제 경로, `file:line`, 중심, 동적/고정 크기, 회전, z, 알파, Vfx 스펙, 실제 프레임 크기는 [`effect_inventory.json`](effect_inventory.json)에 전부 기록했다. 원시 치수·경계·빈/중복 프레임은 [`effect_measurements.json`](effect_measurements.json)에 있다.

- 공격/궁 Vfx 27: `frey_slash`, `frey_k`, `frey_l`, `frey_ult_charge`, `frey_ult_wave`; `luna_slash`, `luna_k`, `luna_l`, `luna_brave_slash`, `luna_ult_transform`, `luna_ult_laser`, `luna_ult_laser_head`; `yuki_slash`, `yuki_k`, `yuki_l`, `yuki_ult_seal`, `yuki_ult_burst`; `nova_slash`, `nova_k`, `nova_l`, `nova_ult_core`, `nova_ult_burst`; `rio_slash`, `rio_k`, `rio_l`, `rio_ult_circle`, `rio_ult_impact`.
- 기술/공용 Vfx 23: `luna_star_bloom`, `luna_moon_ring`, `luna_brave_aura`, `luna_comet_trail`, `luna_comet_burst`; `nova_gravity_burst`, `nova_momentum_trail`, `nova_vector_streak`, `nova_shift_dash`, `nova_shift_ready`, `nova_impact_star`, `nova_launch_flash`; `rio_rune_guard`, `rio_rune_burst`, `rio_blink_trail`; `yuki_seal_idle`, `yuki_seal_break`, `yuki_grand_ward`; `guard_bubble`, `parry_flash`, `landing_dust`, `hit_streak`, `attack_afterimage`.
- 직접 텍스처 15: `frey_pursuit_mark`, `frey_spike_ring`, `luna_star_charge`, `luna_star_projectile`, `yuki_talisman`, `rio_mana_wave`, `rio_gem_sword`; `hit_frey`, `hit_luna`, `hit_luna_brave`, `hit_yuki`, `hit_nova`, `hit_rio`; `status_stun`, `status_super_armor`.

## 측정·검증 방법

- [`audit_assets.py`](../../tests/analysis/codex_qa_19/audit_assets.py)가 8형태의 시트를 코드 행표대로 자르고 658프레임을 측정했다. 발선, alpha bbox 몸 높이, alpha 중심 이동, 가장자리/4px 여백, 빈 프레임, SHA-256 완전 중복을 기록했다.
- 정지 기준 대기행의 최대 중심 이동은 Frey 2.40, Luna 2.55, Brave 7.16, Yuki 2.01, Nova male 3.15, Nova female 2.11, Rio male 3.50, Rio female 5.40px였다. 1×/3× 보드로 확인했으며 Brave/Rio female의 큰 값은 발 고정 상태의 머리카락·숨쉬기 실루엣 이동이라 결함으로 판정하지 않았다.
- 단순 피부색 머리 높이는 갑옷·머리카락을 섞어 잡으므로 JSON에 `proxy`로만 남겼다. 최종 머리 판단은 [`measure_head_consistency.py`](../../tests/analysis/codex_qa_19/measure_head_consistency.py)에서 D34 도구를 사용했다. 91행 중 77행이 score≥0.6이었다. Yuki 16행은 피부 마스크가 맞지 않아 자동값을 사용하지 않았다.
- 55개 fx/nofx WebP 쌍을 전 프레임 비교해 평균 휘도 차이가 가장 큰 프레임을 골랐다. 1× 전체 주변과 3× nearest 확대를 모두 직접 확인했다. 픽셀 변화율은 시각적 덮임의 비교값이지 판정 크기가 아니다.
- `effect_inventory.json`은 런타임 GDScript만 검색해 호출 위치를 모으고, `Vfx.gd:107-133`의 `centered=false`, anchor, source ratio 보정을 반영했다.
- 실행: 번들 Python에서 두 스크립트 `py_compile` 통과 후 생성 완료. Godot 제품 코드와 아트는 수정하지 않았고, windowed Godot는 실행하지 않았다.

## 확인하지 못한 것

- `capture_move_clips.gd:26-27`이 Nova와 Rio를 male로 고정하므로 **Nova female/Rio female 실제 fx 클립**은 확인하지 못했다. 같은 코드 효과라는 것은 확인했지만 몸과의 겹침은 추정이다.
- 클립은 통제된 장면이다. 8인전에서 효과 여러 개가 동시에 겹칠 때의 가독성은 측정하지 못했다.
- 디버그 hitbox 오버레이가 포함된 클립이 아니므로 픽셀과 판정의 프레임별 교차 면적은 계산하지 못했다. 대신 코드의 중심·크기와 클립 위치를 따로 기록했다.
- Yuki는 D34 피부 마스크와 맞지 않아 행별 머리 배율 자동 검증이 0/16이었다. 1×/3× 육안에서는 즉시 재작업할 불일치를 찾지 못했지만, 다른 색 마스크로 재측정할 수 있다.
- 클립에 공중 점프 전용 장면이 없어 B8의 혼전 체감은 확인하지 못했다.
