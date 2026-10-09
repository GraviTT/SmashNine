# CODEX-QA-14 Round 13 — 현재 R11 코드의 다음 세션 항목

측정일: 2026-10-09 · branch `codex/bot-data-14m`  
조건: seeds 101–112, 8 bots, 480초 상한, `--fixed-fps 60`, 한 경기씩 순차 실행  
비교 기준: `round10.md/json`, `round11.md/json`, `round12.md/json`

## 결론 먼저

현재 제품 코드는 R11 측정 당시와 **12/12 seed에서 완전히 동일**했다. R10은 착지 가능, R11은 불가로 본 낙하에서 복귀를 통째로 끈 B 변형은 링아웃을 **94 → 219**로 늘렸다. 따라서 R11 판정을 느슨하게 되돌리면 안 된다. 비용을 줄이려면 판정 자체를 무시하는 대신 12px 이내 edge graze와 연속 판정 안정성, 복귀 동작의 캐릭터별 효율을 좁게 고쳐야 한다.

```text
R10 수락 / R11 거절 낙하
          │
          ├─ A: 현재 복귀 유지 ── 867 episode ── 착지 856 / 링아웃 9 / 종료 2
          │
          └─ B: episode 전체 복귀 억제 ── 384 episode ── 착지 234 / 링아웃 150

전체 경기 결과: A 링아웃 94, 중앙값 310.4초 → B 링아웃 219, 중앙값 285.0초
```

위 도식의 A/B episode 수는 개입 뒤 경기 궤적이 달라져 같지 않다. 같은 시드의 정책 비교이며 개별 episode 1:1 shadow replay는 아니다.

## 1. Baseline check

길이·승자·링아웃·포털·복귀 진입을 과거 R11과 비교했다. 모든 셀이 같았다.

| seed | 길이(초) | 승자 | 링아웃 | 포털 | 복귀 진입 | R11 일치 |
|---:|---:|---|---:|---:|---:|---|
| 101 | 342.5 | Luna | 7 | 17 | 135 | 예 |
| 102 | 324.8 | Yuki | 11 | 18 | 258 | 예 |
| 103 | 339.6 | Nova | 6 | 19 | 160 | 예 |
| 104 | 298.1 | Frey | 11 | 16 | 170 | 예 |
| 105 | 304.1 | Frey | 9 | 19 | 112 | 예 |
| 106 | 316.7 | Rio | 11 | 23 | 153 | 예 |
| 107 | 320.3 | Frey | 5 | 17 | 113 | 예 |
| 108 | 333.4 | Luna | 0 | 34 | 273 | 예 |
| 109 | 294.4 | Luna | 10 | 22 | 122 | 예 |
| 110 | 272.0 | Frey | 12 | 22 | 147 | 예 |
| 111 | 267.3 | Nova | 4 | 21 | 131 | 예 |
| 112 | 274.3 | Rio | 8 | 24 | 248 | 예 |

기존 비교값도 그대로다.

| 지표 | R10 | R11 = 현재 A | R12 |
|---|---:|---:|---:|
| 경기 중앙값 | 276.1초 | **310.4초** | 295.6초 |
| 링아웃 | 108 | **94** | 120 |
| 복귀 진입 | 1,346 | **2,022** | 1,559 |
| no-progress | 724.3초 | **1,117.5초** | 737.0초 |
| 기존 intent 적중률 | 52.52% | **47.13%** | 51.50% |

캐릭터별로도 현재 A는 R11과 같으며, `전체 링아웃 / 0-jump 링아웃` 비교는 다음과 같다.

| 캐릭터 | R10 | R11 = 현재 A | R12 |
|---|---:|---:|---:|
| Frey | 13 / 3 | **14 / 8** | 11 / 2 |
| Luna | 25 / 20 | **24 / 17** | 30 / 25 |
| Nova | 37 / 28 | **31 / 18** | 37 / 21 |
| Rio | 15 / 6 | **9 / 4** | 16 / 7 |
| Yuki | 18 / 14 | **16 / 16** | 26 / 25 |

현재 A의 no-progress 캐릭터별 값은 Frey 159.5초, Luna 176.75초, Nova 268.75초, Rio 440.5초, Yuki 72.0초다. R10은 각각 298.25/139.75/41.75/170.75/73.75초, R12는 150.75/212.25/107.75/220.5/45.75초였다. R11의 전역 증가분은 특히 Nova와 Rio에 집중돼 있다.

## 2. live R11 낙하 판정 flip

공중 낙하 physics frame **366,090개**를 기록했다. 그중 R11 arc가 착지로 본 frame은 274,618개(75.0%). 판정 flip은 1,438회로, `no landing → landing` 919회와 `landing → no landing` 519회였다.

분류 우선순위는 입력 변경 → 피격/knockback/wall 또는 예상 밖 속도 변경 → 플랫폼 가장자리 12px 이내 → 1초 horizon 끝(0.85초 이상) → 기타다.

| 분류 | flip | 비율 | 같은 낙하가 링아웃으로 끝난 flip |
|---|---:|---:|---:|
| edge graze ≤12px | **593** | 41.2% | — |
| 기타 | 487 | 33.9% | — |
| 피격·knockback·wall/속도 변화 | 200 | 13.9% | — |
| move input 변경 | 150 | 10.4% | — |
| 1초 horizon 진입·이탈 | 8 | 0.6% | — |
| 합계 | **1,438** | 100% | **43** |

| 캐릭터 | 전체 flip | 링아웃 전 flip | edge / 속도 / 입력 / horizon / 기타 |
|---|---:|---:|---|
| Frey | 286 | 6 | 121 / 29 / 31 / 0 / 105 |
| Luna | 282 | 8 | 114 / 44 / 28 / 0 / 96 |
| Nova | 319 | **22** | 130 / 38 / 36 / 7 / 108 |
| Rio | **350** | 6 | 131 / 52 / 29 / 1 / 137 |
| Yuki | 201 | 1 | 97 / 37 / 26 / 0 / 41 |

**측정:** flip의 가장 큰 식별 가능한 원인은 edge graze다. 입력 변경은 10.4%뿐이다. 487회는 현재 계측 규칙으로 원인을 단정할 수 없어 `기타`로 남겼다.  
**추론:** 점 하나 ray가 발판 모서리를 스치느냐에 따라 판정이 흔들린다. 다만 B 결과 때문에 edge graze를 곧바로 “착지”로 고정하는 것은 안전하지 않다.

## 3. 복귀가 착지를 만들었는가 — A/B

### 정책 전체

| 정책 | 해당 episode | 착지 | 링아웃 | 종료 중 | episode 링아웃률 | 전체 경기 링아웃 | 경기 중앙값 |
|---|---:|---:|---:|---:|---:|---:|---:|
| A: 현재 R11 복귀 | 867 | **856** | 9 | 2 | **1.0%** | **94** | 310.4초 |
| B: 해당 episode 복귀 억제 | 384 | 234 | **150** | 0 | **39.1%** | **219** | 285.0초 |

### 캐릭터별 episode

| 캐릭터 | A 착지/링아웃/전체 | B 착지/링아웃/전체 | B 링아웃률 | 전체 경기 링아웃 A→B |
|---|---:|---:|---:|---:|
| Frey | 171 / 4 / 175 | 37 / 30 / 67 | 44.8% | 14 → 40 |
| Luna | 194 / 1 / 195 | 31 / 38 / 69 | **55.1%** | 24 → 59 |
| Nova | 165 / 2 / 168 (+1 종료) | 61 / 36 / 97 | 37.1% | 31 → 54 |
| Rio | 203 / 2 / 205 | 58 / 26 / 84 | 31.0% | 9 → 32 |
| Yuki | 123 / 0 / 124 (+1 종료) | 47 / 20 / 67 | 29.9% | 16 → 34 |

**측정:** 현재 복귀 조작은 A의 867건 중 최소 150건 규모에서 생존에 필수다. B는 같은 시드여도 첫 개입 뒤 난수·전투 궤적이 달라지므로 정확한 episode 짝 비교는 아니다.  
**판정:** 현재 R11 arc 유지. R10 수락만으로 recovery를 생략하는 변경은 폐기한다.

## 4. Luna·Yuki 링아웃

원시 JSON에는 40건 모두 한 행씩 연결했다. 아래는 요약이다.

| 캐릭터 | 링아웃 | 0-jump | 마지막 점프 원인 | 복귀 표적이 위(중앙값) | 수평 ledge 거리 | 직전 3초 PvP hit | 실제 이동 skill ready |
|---|---:|---:|---|---:|---:|---:|---:|
| Luna | 24 | 17 | **17/17 recovery** | 904.7px | 232.2px | 22 | 2/24 |
| Yuki | 16 | 16 | **16/16 recovery** | 928.8px | 23.9px | 15 | **0/16** |

- Luna: 평상시 K는 투사체라 몸을 옮기지 않고 공중 cast 때 속도만 0.7배로 줄인다. 변신 K만 `650px/s × 0.14s ≈ 91px` 이동하며, 링아웃 시 ready였던 경우는 2/24. 평상시 L은 수직 속도 0.5배다.
- Yuki: K는 공중에서 속도를 0.38배로 줄이지만 몸을 ledge 쪽으로 옮기는 기술은 아니다. L·I도 이동하지 않는다. 16/16에서 K는 쓸 수 있었지만 현재 AI profile은 Luna/Yuki를 recovery-skill 사용자로 취급하지 않는다.

**측정:** 점프가 등반·전투에서 낭비된 것이 아니라 두 캐릭터 모두 최종 recovery에서 소진됐다. 대부분은 PvP hit가 시작점이었다(Luna 22/24, Yuki 15/16).  
**추론:** 점프 절약 문제가 아니라, 약 900px 아래에서 점프를 모두 쓴 뒤 수평·상향 이동 수단이 없는 캐릭터 kit/AI 문제다.

## 5. no-route drop 110건

| 항목 | 결과 |
|---|---:|
| target kind | monster 85 / crystal 9 / player 16 |
| 원인 | gap jump보다 넓음 106 / 한 번 점프보다 높은 rise 4 |
| 도달 가능한 nav point가 공격 사거리 안 | **35/110 (31.8%)** |
| 10초 안 새 target | 104/110 (94.5%), 중앙값 0초 |
| 10초 안 wander | **88/110 (80.0%)** |
| 10초 안 portal | 9/110 (8.2%) |
| 10초 안 다음 피해 가함 | **26/110 (23.6%)**, 중앙값 6.23초 |

**권고:** 35건은 target을 버리지 말고 “target에 가장 가까운 도달 가능한 nav point”로 이동한 뒤 사거리 안에서 공격한다. 나머지 75건은 지금처럼 즉시 다른 target으로 전환하되, 2초 동안 유효 target이 없으면 portal을 검토한다. 4초 기본 roam만 기다리는 것보다 낫다. 이유는 현재도 104건이 즉시 target을 바꾸지만 88건이 곧 wander가 되고, 10초 안 피해를 준 것은 26건뿐이기 때문이다. monster 85건에는 이 규칙을 먼저 적용하고 player 16건은 더 긴 ignore 대신 재평가 시간을 짧게 유지한다.

## 6. 회귀 fixture

요청한 두 dead band를 그대로 포착했다.

| fixture | 지속 | 시작 거리 | target |
|---|---:|---:|---|
| seed 106 Rio | 5.02초 | 306.5px | player |
| seed 112 Luna | 5.65초 | 256.4px | crystal |

gap/no-landing drop의 50px 양자화 위치 상위 5개:

| 순위 | realm·bot x/y·target x/y | 빈도 |
|---:|---|---:|
| 1 | `7|10000|6250|10000|6450` | 5 |
| 2 | `7|9950|6500|9600|6300` | 4 |
| 3 | `7|10350|6500|10750|6300` | 3 |
| 4 | `6|5200|6550|5000|6350` | 3 |
| 5 | `5|1200|6550|1550|6350` | 2 |

`fixtures-round13/`의 각 JSON에는 800px 안 발판 rect, 두 body 위치·속도·facing·on-floor, state/action, profile range, `blocked_age`, `attack_age`, navigation path, 직전 2초 frame intent가 들어 있다.

## 7. recovery skill 1

| 캐릭터 | 사용/바닥 도달 | 0.5초 이동량 평균 | recovery 표적 거리 단축 | 도달/실패 단축 | ledge | 0.5초 내 피격 |
|---|---:|---:|---:|---:|---:|---:|
| Frey | 21 / 9 | 179.8px | 187.5px | 226.4 / 158.4px | |dx| 190.6, dy -38.9 | 2 |
| Nova | **21 / 5** | 180.6px | 107.8px | **148.8 / 95.0px** | |dx| 75.4, dy **-117.6** | 3 |
| Rio | 5 / 1 | 272.9px | 161.9px | 127.9 / 170.4px | |dx| 78.6, dy -120.0 | 0 |

모든 사용은 air jump 0에서 일어났다. Nova는 벡터 시프트 자체로 약 181px 움직이지만, ledge는 중앙값 118px 위에 있고 실패 episode에서는 recovery 표적까지 거리를 평균 95px만 줄였다. 도달한 경우는 149px 줄였다. 3건은 0.5초 안 피격됐다.

**측정:** Nova의 5/21은 “기술이 전혀 움직이지 않아서”가 아니라, 단 한 번의 0.22초 shift가 위쪽 ledge까지 남은 낙하를 충분히 상쇄하지 못하는 경우가 많아서다.  
**추론/실험안:** Nova는 점프 0이 된 뒤가 아니라 마지막 air jump를 쓰기 직전, recovery target이 100px 이상 위이고 shift가 사용 가능할 때 위쪽 성분을 더 크게 주는 A/B가 우선이다. 두 번째 shift를 허용하는 변경은 캐릭터의 airtime 제한과 충돌하므로 먼저 하지 않는다.

## 8. no-progress와 activation-only hit rate

### no-progress 원인(초)

| 캐릭터 | 합계 | blocked gap | no route | pursue no closer | wrong level | stuck |
|---|---:|---:|---:|---:|---:|---:|
| Frey | **159.5** | 28.5 | 18.5 | 44.75 | **67.5** | 0.25 |
| Luna | 176.75 | 10.25 | 17.75 | 60.5 | **87.75** | 0.5 |
| Nova | **268.75** | 59.25 | 38.75 | 69.0 | **101.5** | 0.25 |
| Rio | **440.5** | 121.5 | 35.5 | **146.0** | 136.25 | 1.25 |
| Yuki | 72.0 | 7.25 | 5.5 | 20.5 | 38.75 | 0 |

Rio의 440.5초 중 403.75초(91.7%)가 `blocked gap + pursue no closer + wrong level`이다. Frey는 wrong level 67.5초가 가장 크다.

### frame request와 실제 activation

실제 activation은 `attack_serial` 증가와 recovery skill의 실제 character-state 변화를 사용했다. 적중은 activation 뒤 0.4초 안 damage다. 궁극기는 발동 후 피해까지 0.4초보다 긴 경우가 많아 아래 `ultimate 0%`를 궁극기 성능으로 해석하지 않는다.

| 공격 | request frame | activation | activation hit | activation 적중률 | R11 기존 intent 적중률 |
|---|---:|---:|---:|---:|---:|
| ground side | 15,608 | 6,712 | 4,751 | **70.78%** | 58.81% |
| ground up | 655 | 625 | 346 | 55.36% | 53.31% |
| ground down | 303 | 258 | 54 | 20.93% | 19.71% |
| air side | 1,669 | 966 | 412 | **42.65%** | 38.51% |
| air up | 554 | 483 | 299 | 61.90% | 59.44% |
| air down | 3,127 | 672 | 370 | **55.06%** | 47.87% |
| skill 1 | 14,294 | 926 | 331 | 35.75% | 27.42% |
| skill 2 | 821 | 392 | 89 | 22.70% | 15.44% |
| ultimate | 714 | 61 | 0 | 0%* | 21.46% |

Frey skill 1만 보면 request frame **12,782**, 실제 recovery activation **21**, 0.4초 적중 4(19.05%)다. 따라서 R10→R11의 ground-side `66.37→58.81%`, air-down `58.32→47.87%` 하락에는 실제 행동 변화도 있지만, R11 수치는 request episode를 activation처럼 세어 낮아진 부분이 크다. activation-only R11은 각각 70.78%, 55.06%다.

## 수정 우선순위

1. **P0 — R11 recovery 판정은 유지하고, R10 수락을 이유로 episode 전체를 풀지 않는다.** B는 episode 링아웃률 1.0% → 39.1%, 전체 링아웃 94 → 219. 새 판정은 반드시 링아웃과 함께 A/B한다.
2. **P1 — edge graze 안정화만 좁게 실험한다.** flip 1,438회 중 593회(41.2%)가 12px 이내 모서리다. 제안: blast line 여유가 충분할 때만 2개 연속 physics frame의 `no landing`을 요구하거나 발 폭의 두 ray를 추가하고, 현재 recovery를 안전 fallback으로 유지한다. `accept` 고정은 금지한다.
3. **P1 — Luna/Yuki의 캐릭터별 복귀 수단을 추가 계측 A/B한다.** 0-jump 링아웃 33/33이 마지막 점프를 recovery에서 썼다. Yuki K fall brake(속도 ×0.38), Luna K/L fall brake를 AI가 쓰는 실험부터 하되 수평 이동이 없다는 한계를 명시한다. 실제 이동 skill ready는 Luna 2/24, Yuki 0/16뿐이다.
4. **P1 — no-route 대체 목적지를 넣는다.** 35/110은 도달 가능한 nav point가 이미 공격 사거리 안이다. 그 지점으로 이동한다. 나머지 75건은 즉시 target 전환, 2초 무표적이면 portal 후보. 현재 10초 내 피해는 26/110뿐이다.
5. **P2 — Nova recovery shift를 더 일찍·더 위로 쓰는 A/B를 한다.** 21회 중 5회만 바닥 도달. 도달 episode는 표적 거리를 148.8px, 실패는 95.0px 줄였다. 마지막 air jump 직전의 upward shift를 실험한다.
6. **P2 — activation telemetry를 제품 debug counter/signal로 고정한다.** Frey skill 1은 12,782 request frame 대 21 activation이다. request를 공격 횟수로 세면 적중률 회귀를 과장한다.
7. **P2 — 새 fixture 7개를 회귀 테스트로 승격한다.** dead band 2개와 빈도 상위 gap/no-landing 5개를 먼저 고정한다.

## 실행·검증

- clean import 1회, A/B 5초 smoke, A 12경기, 기준선 비교, B 12경기, 로그 스캔을 수행했다.
- formal 24개 경기 로그는 모두 exit 0. 알려진 `Failed to read the root certificate store` 1줄 외 `SCRIPT ERROR`, `Parse Error`, 다른 `ERROR`는 0건이다.
- 첫 import 명령은 Godot signal 11로 한 번 종료됐다. 첫 재시도는 상대 log path 때문에 `user://..` 디렉터리 ERROR가 추가됐고, 절대 log path로 다시 실행한 clean import는 인증서 경고 외 오류 없이 exit 0이었다. 정식 측정에는 영향이 없다.
- A는 12/12 finished이며 R11 seed별 5개 기준값이 전부 일치했다. B도 12/12 finished다.
- 원시 full-frame 자료는 `round13-a-full.json.gz`, `round13-b-full.json.gz`; compact 결과는 `round13-a-results.json`, `round13-b-results.json`; 집계는 `round13-summary.json`; fixture는 `fixtures-round13/`에 둔다.
- 전체 제품 test suite는 분석 카드 범위가 아니므로 실행하지 않았다.

재실행:

```powershell
powershell -ExecutionPolicy Bypass -File smash-nine-prototype/tests/analysis/codex_qa_14/run_round13.ps1 -Variant a -Seed 101 -Count 12 -Seconds 480 -Players 8
powershell -ExecutionPolicy Bypass -File smash-nine-prototype/tests/analysis/codex_qa_14/run_round13.ps1 -Variant b -Seed 101 -Count 12 -Seconds 480 -Players 8
node smash-nine-prototype/tests/analysis/codex_qa_14/analyze_round13.js
```
