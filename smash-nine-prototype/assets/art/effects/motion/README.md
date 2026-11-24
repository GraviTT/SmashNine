# pixelfx 동작 이펙트 (2026-11-04, D48)

사용자: "새로운 Luna v3는 좋다. 현재 테스트로 만든 것들 전부 게임에 넣어볼 것."

pixelfx(`/도트이펙트`, 코드로 그리는 픽셀 이펙트)로 그린 동작 이펙트를 Vfx 한 줄 시트로 구웠다.
비교와 근거는 `reports/pixelfx-eval-2026-11-03/` 11~13장에 있다.

## 파일 계약

| 파일 | 전체 크기 | 프레임 | fps | 앵커(px) | 섞기 | 쓰는 곳 |
|---|---:|---:|---:|---:|---|---|
| `luna_idle_stars.png` | 2048×128 | 16 × 128×128 | 12, 반복 | (64,120), 발 | 더하기 | Luna(노말)의 `luna_idle` 동안 몸에 붙여 반복한다. 실루엣 가장자리 반짝임(머리 위·얼굴 구역 제외), 지팡이 번쩍임, 아래로 흩날리는 알갱이, 허리 둘레 별 셋 (v3) |
| `luna_land_stardust.png` | 3536×104 | 17 × 208×104 | 20 | (104,72), 발 | 보통(반투명) | Luna의 큰 착지: 130px 이상 떨어진 착지(꾹 누른 점프는 약 220px). 공중 0.12초 이상 뒤 착지마다 나온다(착지 소리와 같은 조건). 행동 뒤 착지의 회색 먼지도 대신한다 (v2) |
| `luna_land_stardust_small.png` | 1760×64 | 10 × 176×64 | 20 | (88,56), 발 | 보통(반투명) | Luna의 작은 착지: 130px보다 낮게 떨어진 착지(짧게 누른 점프 50~110px, 위 발판에 올라섬) (v1, 사용자 2026-11-04) |
| `frey_step_dust.png` | 864×40 | 9 × 96×40 | 16 → 걸음 박자 | (70,34), 앞발 | 보통(반투명) | Frey 달리기. `frey_walk` 4·8번째 그림(앞발이 닿는 순간)에 그 발 자리(발에서 앞으로 18·21px)에 남는다. v2에서 빈 첫·끝 그림을 뺐고, 걷기 그림 4장(한 걸음, 0.35초) 안에 다 재생된다("Frey의 발걸음 속도에 맞춰서", 사용자 2026-11-04) |
| `frey_slash_sparks_{1,2,3}.png` | 5320×128 | 19 × 280×128 | 20 | (20,64), 몸 중심 | 더하기 | Frey J 1~3타. `frey_slash`와 같은 자리(몸 중심)·같은 순간에 나온다. 궤적 길이 181·193·209.5와 방향 -0.06·-0.1·-0.18에 맞춰 구웠다 (v2) |
| `frey_jfx_up.png` · `frey_jfx_up_air.png` | 3800×260 | 19 × 200×260 | 20 | (80,210), 몸 중심 | 더하기 | Frey ↑J(땅 · 공중) 여운. 베기 그림과 같은 순간·자리. 칼끝 불꽃이 튄 뒤 금빛 반짝임과 테두리 잔상이 남아 흩어진다 (A안, 리드 pixelfx `art/bakeoff/effects/pixelfx/frey/a/`. 시안 월드컵 2026-11-24에서 다시 골랐다. 11-04에는 페이지 버그로 B안 Codex CODEX-VFX-07이 들어갔었다) |
| `frey_jfx_down.png` · `frey_jfx_down_air.png` | 5700×150 · 3800×260 | 19 × 300×150 · 19 × 200×260 | 20 | (20,80) · (60,60) | 더하기 | Frey ↓J 여운. 땅은 15°로 눕힌 베기에 맞춤 (A안) |
| `frey_jfx_side_air.png` | 5700×150 | 19 × 300×150 | 20 | (20,70) | 더하기 | Frey 공중 J 여운 (A안) |
| `frey_hit_after.png` · `frey_hit_after_big.png` | 10 × 128×112 · 14 × 192×160 | | 20 | (64,56) · (96,80), 맞은 몸 중심 | 더하기 | Frey 근접 적중 한 번에 한 번 남는 여운: 금빛 고리, 강철 불꽃, 반짝임. 넉백 400 이상은 큰 것 (A안, 리드) |
| `frey_jump.png` | 992×32 | 8 × 124×32 | 24 | (62,9) | 더하기 | Frey 땅 점프. 발이 떠난 자리에 한 번, 바라보는 쪽으로 뒤집음 (A) |
| `frey_air_jump.png` | 1380×38 | 10 × 138×38 | 30 | (68,9) | 더하기 | Frey 공중 점프. 그 자리 발 위치에 한 번 (A) |
| `frey_land.png` | 992×28 | 8 × 124×28 | 30 | (62,22) | 더하기 | Frey 착지, 130px보다 낮게 떨어짐. 발 위치, 바라보는 쪽으로 뒤집음, 행동 뒤 회색 먼지도 대신함 (A) |
| `frey_land_big.png` | 2136×42 | 12 × 178×42 | 30 | (89,34) | 더하기 | Frey 착지, 130px 이상 떨어짐 (A) |
| `luna_jump.png` | 1044×22 | 9 × 116×22 | 30 | (58,9) | 더하기 | Luna(노말) 땅 점프 (A). Brave에는 없음 |
| `luna_air_jump.png` | 1370×51 | 10 × 137×51 | 30 | (79,-1) | 더하기 | Luna(노말) 공중 점프 (A) |
| `luna_step.png` | 420×22 | 7 × 60×22 | 20 | (52,20) | 더하기 | Luna(노말) 달리기. `luna_walk` 4·8번째 그림, 앞발 +17·+18px, 한 걸음 안에 재생 (A) |
| `luna_star_launch.png` | 180×52 | 6 × 30×52 | 30 | (1,26) | 더하기 | J 작은 별이 생긴 자리에 한 번. +x를 조준 방향으로 돌리고, 왼쪽은 뒤집은 뒤 반대 방향으로 돌림 (A) |
| `luna_star_launch_big.png` | 308×78 | 7 × 44×78 | 30 | (1,39) | 더하기 | J 큰 별 발사 (A) |
| `luna_star_trail.png` | 576×28 | 8 × 72×28 | 40, 반복 | (90,14) | 더하기 | 작은 별에 붙어 날아가는 동안 반복하는 꼬리. 별과 같이 돌림 (A) |
| `luna_star_trail_big.png` | 960×40 | 10 × 96×40 | 40, 반복 | (128,20) | 더하기 | 큰 별의 꼬리 (A) |
| `luna_hit_after.png` | 2112×100 | 12 × 176×100 | 20 | (76,40) | 더하기 | 작은 별이 맞힐 때 별 하나에 한 번, 맞은 몸 중심. 날아간 쪽으로 뒤집음 (B) |
| `luna_hit_after_big.png` | 3456×112 | 16 × 216×112 | 20 | (96,44) | 더하기 | 큰 별이 맞힐 때 한 번. 폭발의 적중에는 더 나오지 않음 (B) |
| `brave_rush_1.png` | 830×47 | 10 × 83×47 | 20 | (-54,23) | 더하기 | Brave J 1타(잽). `luna_brave_slash`와 같은 순간·자리(몸 중심). 앵커가 그림 밖이라 몸 앞에 그려짐 (B) |
| `brave_rush_2.png` | 1308×58 | 12 × 109×58 | 20 | (-61,27) | 더하기 | Brave J 2타(보디 킥) (B) |
| `brave_rush_3.png` | 1680×91 | 14 × 120×91 | 20 | (-52,85) | 더하기 | Brave J 3타(회전 킥) (B) |
| `brave_up.png` | 490×95 | 14 × 35×95 | 20 | (-50,146) | 더하기 | Brave ↑J·공중 ↑J(어퍼컷) (B) |
| `brave_low.png` | 1332×44 | 12 × 111×44 | 20 | (-65,-13) | 더하기 | Brave ↓J(낮은 다리 후리기) (B) |
| `brave_side_air.png` | 1416×60 | 12 × 118×60 | 20 | (-70,38) | 더하기 | Brave 공중 J(비행 발차기) (B) |
| `brave_down_air.png` | 1136×179 | 16 × 71×179 | 20 | (8,-84) | 더하기 | Brave 공중 ↓J(급강하 킥) (B) |
| `brave_hit_after.png` | 1848×51 | 12 × 154×51 | 20 | (73,12) | 더하기 | Brave 근접 적중 한 번에 한 번, 맞은 몸 중심. 넉백 400 미만 (B) |
| `brave_hit_after_big.png` | 3312×70 | 16 × 207×70 | 20 | (102,12) | 더하기 | Brave 근접 강타(넉백 400 이상: 회전 킥 520, 어퍼컷 430, 급강하 475) (B) |

- 모두 오른쪽을 보고 그렸고, 바라보는 쪽으로 좌우만 뒤집어 그린다(회전 없음). 예외는 Luna 별의 발사·꼬리로, 조준 방향으로 돌린다.
- 시안 월드컵 2026-11-19 라운드(사용자 2026-11-23)에서 이긴 22장은 Codex CODEX-VFX-08·09 후보(A "순간 강조" `art/bakeoff/effects/pixelfx/<frey|luna|luna_brave>/a/`, B "방향 있는 여운" `…/b/`)를 이름 끝 `-a`·`-b`만 떼고 복사했다. 크기·앵커·fps는 각 후보의 `.json`과 같다.
- 1 art px = 1 screen px(월드 1배)이다. 확대하지 않는다.
- 더하기 시트는 색과 빛을 RGB에 미리 곱했고, 알파는 0/255다. 밝기 40 미만의 빛은 버렸다(몸 위의 안개 방지).
- 보통 시트는 먼지·별가루 뭉치가 반투명이다(알파 여러 단계). 이 폴더는 effects 폴더의 "알파 0/1" 규칙에서 예외다.
- 원본 아트 모드에서만 나온다. F2 시제품 모습에서는 나오지 않는다.

## 원본과 다시 굽기

- pixelfx 고정 사본(`C:/Users/TH/Documents/AI/GameProject/pixelfx`, `a84159688af3`)의 맞춤 이펙트로 그렸다.
  - `src/fx/arcane/sn-luna-idle-stars.js`
  - `src/fx/impacts/sn-luna-stardust-land.js`
  - `src/fx/impacts/sn-frey-step-dust.js`
  - `src/fx/melee/sn-frey-slash-sparks.js`
- 다시 굽기: `node reports/pixelfx-eval-2026-11-03/motions.mjs strips-v2` (대기 별은 `strips-idle-v3`)
  - 결과는 `art/bakeoff/effects/pixelfx/*-v2.png` · `luna_idle_stars-v3.png`로 나온다.
  - 이름에서 `-v2`·`-v3`를 떼고 이 폴더에 복사한다. 작은 별가루는 `luna_land_stardust-v1`을 `_small`로 복사한다.
  - 발걸음 먼지는 v2 시트의 1~9번째 그림만 쓴다(0번과 10번은 거의 비어 있음).
- Frey 걷기 그림이 바뀌면 `Frey.STEP_DUST`의 그림 번호와 발 위치를 다시 잰다.
- J 판정의 길이나 방향이 바뀌면 불꽃 시트를 그 값으로 다시 굽는다.

## 코드

- `scripts/Vfx.gd` SPECS (`MOTION_DIR`)
- 몸에 붙는 반복: `PlayerBase.get_motion_overlays()` — Luna `MOTION_OVERLAYS`
- 그림 번호에 맞춘 한 번: `PlayerBase.get_motion_frame_effects()` — Frey `STEP_DUST`. 수풀에 숨었을 때는 나오지 않는다.
- 착지: `PlayerBase.character_landing_effect(drop)` — Luna, 낙하 높이 `drop`(`air_top_y`부터)이 `Luna.BIG_LANDING_DROP` 130px 이상이면 큰 것
- 걸음 박자: `get_motion_frame_effects()` 항목의 다섯째 값(걷기 그림 수)에 맞춰 이펙트 재생 속도를 정한다.
- J 불꽃 · 여운: `Frey._spawn_follow_through`(3연타 `_spawn_slash_sparks`, ↑J · ↓J · 공중 J)
- 적중 여운: `PlayerBase.character_hit_afterglow(knockback)` → `on_attack_hit_body`에서 한 번 (Frey `BIG_HIT_KNOCKBACK` 400)
- 원본: B안은 `art/bakeoff/effects/pixelfx/frey/b/src/`(굽기 `bake.mjs`), A안은 pixelfx 사본의 `sn-frey-hit-after-a.js`(`reports/pixelfx-frey-pilot-2026-11-04/bake_a.mjs`)
- 점프: `PlayerBase.character_jump_effect(공중)` → 땅 점프·`_perform_air_jump`에서 한 번(`_spawn_jump_effect`) — Frey, Luna(노말)
- 착지 뒤집기: `PlayerBase.character_landing_effect_turns()` — Frey만 참(Luna 별가루는 그대로)
- 발걸음: Luna `STEP_FLASH`(Frey `STEP_DUST`와 같은 방식)
- 별 발사·꼬리: `Luna._spawn_star_flight_art`(`_fire_star`), 별 적중 여운: `Luna.on_star_hit(몸, 별)`(`LunaStar`가 별을 넘김), 자리 `PlayerBase.hit_afterglow_point`
- Brave J 여운: `Luna._spawn_brave_follow_through`(각 기술 함수), Brave 적중 여운: `Luna.character_hit_afterglow`(변신 중만, `BRAVE_BIG_HIT_KNOCKBACK` 400)
- 시험: `tests/test_motion_fx.gd`
