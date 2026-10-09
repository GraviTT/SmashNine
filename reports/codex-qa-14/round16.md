# CODEX-QA-14 Round 16 — 표적 선택과 궁극기 reach A/B

## 결론 먼저

같은 seeds 101–112, 8 bots, 480초 상한, `--fixed-fps 60`, 한 경기씩 순차 실행했다. S0는 R11의 같은 층 표적 선택만, U0는 R11의 궁극기 reach만 되돌린 probe-side `EnemyAI` 하위 클래스다. 제품 소스와 기존 테스트는 수정하지 않았다.

- **엄격한 표적 선택(`a94d3d6`): REWORK.** S0에서 wrong-level이 `969.5→509.5초`, 전체 no-progress가 `1,596→1,051.25초`, 표적 없음이 `11.13→8.66%`, Yuki 링아웃이 `37→24`로 개선됐다. 그러나 no-route drop이 `5→84`로 되살아 완전 revert는 적절하지 않다.
- **궁극기 reach × COMBAT(`f0dc673`): REVERT to R11 reach.** U0에서 링아웃 `119→99`, Yuki `37→31`, wrong-level `969.5→565.5초`, recovery 진입 `2,400→1,789`로 개선됐고 no-route drop `5`도 유지됐다. 경기 중앙값은 `296.2→281.9초`로 더 짧아지는 비용이 있다.

```text
현재 R15
  ├─ S0: 같은 층 후보를 R11처럼 허용 ─→ 정체/무표적/링아웃 개선, no-route 재발
  └─ U0: R11 궁극기 reach 복원       ─→ no-route 유지 + 생존/정체 개선, 경기 단축
```

위 도식은 측정된 방향을 요약한다. S0의 trade-off 때문에 표적 선택은 그대로 유지하거나 통째로 되돌리는 대신 fallback을 다시 설계해야 한다.

## R11 / R15 / S0 / U0 핵심표

| 지표 | R11 | R15 현재 | S0 | U0 |
|---|---:|---:|---:|---:|
| 경기 길이 중앙값 (범위), 초 | 310.4 (267.3–342.5) | 296.2 (245.6–322.6) | **287.35 (255.7–332.1)** | **281.9 (240.1–336.7)** |
| 링아웃 / 경기당 | 94 / 7.83 | 119 / 9.92 | **101 / 8.42** | **99 / 8.25** |
| 0점프 링아웃 | 63 | 68 | 69 | **54** |
| no-progress 전체, 초 | 1,117.5 | 1,596.0 | **1,051.25** | **1,191.5** |
| wrong-level no-progress, 초 | 431.75 | 969.5 | **509.5** | **565.5** |
| 표적 없음 | 8.24% | 11.13% | **8.66%** | 10.77% |
| wander | 5.86% | 8.21% | **6.21%** | 8.29% |
| progress drop | 297 | 151 | 221 | 164 |
| no-route drop | 110 | **5** | 84 | **5** |
| recovery 진입 | 2,022 | 2,400 | 2,002 | **1,789** |
| walked/dashed-off recovery | 881 | 806 | 723 | **710** |
| PvP DPM 합 | 192.17 | 191.59 | 190.97 | **195.38** |

R11 wrong-level `431.75초`는 R15 보고서의 동일 비교값이다. 당시 observer는 원인별 no-progress를 직접 저장하지 않았고, R13의 R11 결정론 재현이 그 세부 observer를 추가했다.

## 캐릭터별 링아웃과 직전 피격

| 캐릭터 | R11 링아웃(0점프) | R15 | S0 | U0 |
|---|---:|---:|---:|---:|
| Frey | 14 (8) | 18 (8) | **10 (3)** | 13 (5) |
| Luna | 24 (17) | 25 (15) | 27 (19) | **15 (8)** |
| Nova | 31 (18) | 27 (17) | 29 (22) | **25 (15)** |
| Rio | 9 (4) | 12 (2) | 11 (5) | 15 (3) |
| Yuki | **16 (16)** | **37 (26)** | **24 (20)** | **31 (23)** |

| Yuki 링아웃 시작 | R11 | R15 | S0 | U0 |
|---|---:|---:|---:|---:|
| 전체 | 16 | 37 | 24 | 31 |
| 직전 3초 내 PvP hit | 15 | 33 | **22** | **29** |
| 그중 궁극기 full-window hit | 미계측 | 미계측 | **10** | **18** |

궁극기 hit는 PvP hit의 부분집합이다. R11의 PvP `15/16`은 결정론적으로 같은 R13-A 상세 observer, R15의 `33/37`은 기존 ringout detail에서 가져왔다. R11/R15는 피해 당시 `ultimate_window_timer`를 피해자별로 저장하지 않아 궁극기 세부는 추정하지 않았다. S0/U0는 이번 observer가 정확히 기록했다.

## drop·recovery·전투량

| drop 원인 | R11 | R15 | S0 | U0 |
|---|---:|---:|---:|---:|
| no route | 110 | 5 | **84** | **5** |
| route 있으나 gap landing 없음 | 98 | 55 | 58 | 53 |
| route 있으나 wrong level | 73 | 81 | **68** | 97 |
| target moved away | 15 | 10 | 10 | 9 |
| stuck / other | 1 | 0 | 1 | 0 |

| recovery 원인 | R11 | R15 | S0 | U0 |
|---|---:|---:|---:|---:|
| walked/dashed off | 881 | 806 | 723 | **710** |
| knocked off | 536 | 622 | 612 | **552** |
| air-down | 26 | 29 | 39 | 30 |
| other | 579 | 943 | 628 | **497** |
| 합계 | 2,022 | 2,400 | 2,002 | **1,789** |

| 캐릭터 PvP DPM | R11 | R15 | S0 | U0 |
|---|---:|---:|---:|---:|
| Frey | 43.85 | 41.70 | 46.64 | 45.67 |
| Luna | 39.32 | 35.53 | 33.92 | 36.27 |
| Nova | 41.09 | 44.32 | 43.80 | 46.00 |
| Rio | 42.15 | 39.76 | 38.90 | 39.59 |
| Yuki | 25.76 | 30.28 | 27.71 | 27.85 |

## 궁극기 full-window

R11 observer에는 full-window activation 단위 계측이 없으므로 억지 비교하지 않는다.

| 캐릭터 | R15 활성/적중(%) | S0 | U0 |
|---|---:|---:|---:|
| Frey | 95/75 (78.95%) | 89/74 (83.15%) | 90/69 (76.67%) |
| Luna | 73/62 (84.93%) | 71/63 (88.73%) | 75/70 (93.33%) |
| Nova | 77/73 (94.81%) | 79/69 (87.34%) | 80/74 (92.50%) |
| Rio | 84/63 (75.00%) | 78/63 (80.77%) | 73/59 (80.82%) |
| Yuki | 87/76 (87.36%) | 77/68 (88.31%) | 73/60 (82.19%) |

U0는 궁극기 activation 수를 늘리지 않았지만, Luna/Nova의 full-window 적중과 전체 PvP DPM을 높였다. 따라서 U0의 개선은 단순히 궁극기를 더 자주 누른 결과가 아니다.

## 변경별 판정

### 1. 엄격한 표적 선택 — REWORK

**측정:** S0는 R15 대비 wrong-level `-460초(-47.4%)`, 전체 no-progress `-544.75초(-34.1%)`, 표적 없음 `-2.47%p`, Yuki 링아웃 `-13`, 전체 recovery `-398`이다. 반면 no-route drop은 `+79`다.

**해석/제안:** 현재 첫 pass의 reachable 후보 선호는 유지하되, 실패 시 “다른 층의 route 후보”보다 “같은 층 후보”를 fallback으로 앞세운다. 단, R11처럼 무조건 반환하지 말고 **reachable navigation point가 target의 실제 공격 reach 안에 있는 경우**만 허용한다. 이것이 S0가 되살린 84 no-route를 막으면서, 현재 정책이 만든 wrong-level/무표적 회귀를 겨냥하는 최소 rework다. 이 제안 자체는 아직 미측정 가설이므로 별도 A/B가 필요하다.

### 2. 궁극기 reach × COMBAT — REVERT

**측정:** U0는 no-route `5`를 그대로 유지하면서 R15 대비 전체 링아웃 `-20`, Yuki `-6`, 0점프 `-14`, wrong-level `-404초`, recovery `-611`, PvP DPM `+3.79`다. 표적 없음은 `-0.36%p`로 거의 그대로이고 경기 중앙값은 `-14.3초` 짧다.

**판정:** R11의 이미 스케일된 reach `480/820/420/460/900px`로 되돌린다. 단, Yuki는 U0에서도 31회이고 그중 18회가 궁극기 hit 뒤 3초 내 발생하므로, reach revert만으로 Yuki 문제 해결이라고 보지 않는다.

## 측정과 추정의 경계

- 위 표의 경기, 상태, drop, recovery, 피해, 궁극기 수치는 observer 측정값이다.
- 각 variant는 함수 하나만 바꿨으므로 R15와의 차이는 해당 변경의 **전체 경기 인과 효과**다. 다만 RNG 소비와 전투 순서가 갈라지므로 개별 사건을 1:1 대응한 효과 크기로 해석하지 않는다.
- S0 fallback 설계와 Yuki 전용 생존 보정은 수치에서 도출한 제안이며 아직 구현·측정하지 않았다.

## 우선순위 open items

1. **P1 — target fallback A/B.** strict first pass + reachable attack-point same-level fallback을 시험한다. 목표는 S0 수준의 wrong-level `≈509.5초`, no-target `≈8.66%`를 유지하면서 no-route를 현재 `5`에 가깝게 두는 것이다.
2. **P1 — Yuki 궁극기 피격 후 링아웃 추적/완화.** S0 `10/24`, U0 `18/31`이 궁극기 hit 3초 내다. attacker·ultimate별 knockback과 ledge 거리로 나눠 reach 문제가 아니라 Yuki의 복귀/피격 내성 문제인지 확인한다.
3. **P2 — U0 경기 단축 확인.** median `281.9초`는 목표 5–7분과 R11 `310.4초`보다 짧다. reach revert를 적용한다면 24-seed 확인에서 5분 미만 비율을 gate로 둔다.
4. **P2 — recovery `other` churn 회귀 test.** R15 `943→U0 497`, S0 `628`로 크게 움직였다. 변경과 직접 관계없는 낙하 판정 회귀가 섞이지 않도록 원인별 fixture를 유지한다.

## 실행·검증

- current seed 101 재실행은 R15와 경기 길이 `288.9초`, 승자 Nova, 링아웃 6, 포털 26, recovery `204/6`, standoff 2가 일치했다.
- S0 12/12, U0 12/12 모두 finished. 각 run 로그에서 알려진 certificate-store 잡음 외 `SCRIPT ERROR`, `Parse Error`, 다른 `ERROR`는 없었다.
- 최초 import는 exit 0이었으나 상대 `--log-file`이 임시 user 경로로 해석돼 `Could not create directory: user://..`가 1회 출력됐다. 제품 스크립트 오류가 아니라 import 실행 wrapper의 로그 경로 오류이며, 경기 run은 절대 로그 경로를 사용했다.
- 전체 제품 test suite는 이 분석 카드 범위가 아니므로 실행하지 않았다.

재실행:

```powershell
powershell -ExecutionPolicy Bypass -File tests/analysis/codex_qa_14/run_round16.ps1 -Variant s0
powershell -ExecutionPolicy Bypass -File tests/analysis/codex_qa_14/run_round16.ps1 -Variant u0
node tests/analysis/codex_qa_14/analyze_round16.js
```
