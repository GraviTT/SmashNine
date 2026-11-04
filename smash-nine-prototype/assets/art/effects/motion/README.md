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

- 모두 오른쪽을 보고 그렸고, 바라보는 쪽으로 좌우만 뒤집어 그린다(회전 없음).
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
- J 불꽃: `Frey._spawn_slash_sparks`
- 시험: `tests/test_motion_fx.gd`
