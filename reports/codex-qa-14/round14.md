# CODEX-QA-14 Round 14 — lead 변경 재측정

측정일: 2026-10-09 · branch `codex/bot-data-14n`  
조건: seeds 101–112, 8 bots, 480초 상한, `--fixed-fps 60`, 한 경기씩 순차 실행, Round 13 probe variant A

## 결론 먼저

`a94d3d6`의 **도달 불가 표적 선택 차단은 KEEP**이다. no-route drop이 `110→6`으로 94.5% 줄었고, 재구성 가능한 표적 획득에서는 세 후보 검사 뒤 route 확인 없이 선택된 사례가 0회였다(전체 3,288회 중 185회는 미확정). `df87560`의 두 fixture 수정도 **KEEP**이다. 5초+ 무입력 engage가 `2→0`이고 bot brain 회귀 테스트가 통과했다.

반면 `a94d3d6`의 **pursue/engage 경로 추종은 현재 구현 그대로 REVERT 후 재작업**을 권한다. gap/wrong-level drop은 `171→59`로 줄었지만, drop 대신 같은 표적을 오래 붙드는 시간이 늘어 no-progress가 `1,117.5→1,633.25초`, 특히 wrong-level이 `431.75→894.25초`가 됐다. 복귀 진입도 `2,022→2,999`, 자력 절벽 이탈은 `881→1,522`로 늘었다. `114581a`의 Nova 조기 shift도 바닥 도달이 `5/21→2/17`로 나빠져 **REVERT**다.

```text
도달 불가 표적 선택 차단 ──→ no-route drop 110 → 6          [KEEP]
경로 추종 확대             ──→ gap/wrong drop 171 → 59      [개선]
                              no-progress 1,117.5 → 1,633.25 [회귀]
                              recovery 2,022 → 2,999         [회귀]
Nova 조기 shift            ──→ floor 5/21 → 2/17            [REVERT]
두 dead-band fixture       ──→ input-less 2 → 0             [KEEP]
```

위 흐름도는 같은 변경 묶음 안에서도 표적 선택과 이동 실행의 판정이 갈리는 이유를 보여 준다.

## R11 / R14 핵심표

| 지표 | R11 | R14 | 변화 |
|---|---:|---:|---:|
| 경기 길이 중앙값 (범위), 초 | 310.4 (267.3–342.5) | **280.15 (252.2–330.4)** | -30.25초; 중앙값이 목표 5분 아래 |
| 링아웃 / 경기당 | 94 / 7.83 | **98 / 8.17** | +4 (+4.3%) |
| 공중 점프 0 링아웃 | 63/94 (67.0%) | **62/98 (63.3%)** | 건수 -1, 비율 -3.7%p |
| recovery 성공 / 전체 | 1,925/2,022 (95.20%) | **2,897/2,999 (96.60%)** | 성공률 +1.40%p, 진입 +48.3% |
| 표적 없음 | 8.24% | **10.47% (2,112.25초)** | +2.23%p |
| wander | 5.86% | **7.73% (1,560초)** | +1.87%p |
| 표적 전환/표적 active 분 | 14.59 | **14.24** | 소폭 감소 |
| progress drop | 297 | **68** | -77.1% |
| no-progress episode / 시간 / active 비율 | 88 / 1,117.5초 / 5.39% | **109 / 1,633.25초 / 8.09%** | 시간 +46.2% |
| 5초+ 무입력 engage | 2 | **0** | fixture 개선 |
| 20초+ 대치 수 / 최장 | 4 / 50.6초 | **3 / 103.9초** | 수는 -1, 최장은 2.05배 |
| 포털 이동 | 252 | **239** | -5.2% |
| 전체 캐릭터 PvP DPM 합 | 192.17 | **188.92** | -1.7% |
| 승수 Frey/Luna/Nova/Rio/Yuki | 4/3/2/2/1 | **4/1/5/2/0** | Nova 쏠림, Yuki 0승 |

측정값이다. R11과 R14는 같은 seed지만 여러 제품 변경을 한꺼번에 적용한 전후 비교이므로, 경기 전체 결과를 한 변경의 단독 효과로 단정하지 않는다. 변경과 직접 연결되는 drop 원인, fixture, recovery-skill activation을 우선 판정 근거로 썼다.

### 측정과 추론의 경계

- **직접 측정:** drop 원인, target selection mode, recovery 진입·원인, skill activation과 바닥 도달, ring-out, no-progress, fixture 재발 여부, 궁극기 window hit.
- **직접 판정 가능한 변경:** no-route 표적 선택, Nova 조기 shift, 두 fixture 수정은 각각 전용 event 또는 고정 회귀 사례가 있어 keep/revert 근거가 직접 연결된다.
- **추론이 포함된 변경:** route-follow와 no-progress/recovery 악화의 인과는 단독 toggle A/B가 아니다. 다만 새 이동 규칙이 직접 겨냥한 gap/wrong-level 지표와 함께 walked-off recovery·edge flip이 동시에 크게 늘었고 다른 변경 셋에는 일반 이동 경로를 바꾸는 항목이 없어, 현재 route-follow 구현을 가장 유력한 원인으로 본다. 따라서 판정은 영구 폐기가 아니라 **현재 구현 revert 후 좁은 A/B 재작업**이다.

## drop·표적 선택·정체

| drop 원인 | R11 | R14 | 변화 |
|---|---:|---:|---:|
| no route | 110 | **6** | -94.5% |
| route 있으나 gap landing 없음 | 98 | **37** | -62.2% |
| route 있으나 wrong level | 73 | **22** | -69.9% |
| target moved away | 15 | **3** | -80.0% |
| other | 1 | **0** | -1 |
| 합계 | 297 | **68** | -77.1% |

R14 drop의 표적 종류는 monster 47 / crystal 10 / player 11이다. 표적 획득 mode는 `checked_same_level 1,870`, `checked_route 1,202`, `unchecked_self_over_void 31`, 계측 시점에 재현 불가 185였다. 카드가 지목한 **세 번 검사 뒤 route 확인 없이 선택(`unchecked_after_3`)은 관측 가능한 획득에서 0, drop 0**이다. 단, 3,288회 중 185회(5.6%)는 획득 직후 scored set을 동일하게 재구성하지 못해 이 항목에 대해 미확정이다.

표적 선택은 성공했지만 표적을 얻은 뒤의 정체는 악화했다.

| 캐릭터 | R11 no-progress 초 | R14 no-progress 초 | R14 주요 원인 |
|---|---:|---:|---|
| Frey | 159.5 | **332.5** | wrong level 173.5, pursue 102.0 |
| Luna | 176.75 | **310.25** | wrong level 183.25, pursue 75.5 |
| Nova | 268.75 | **564.5** | wrong level 276.0, pursue 179.0 |
| Rio | 440.5 | **254.5** | wrong level 124.25, pursue 67.25 |
| Yuki | 72.0 | **171.5** | wrong level 137.25 |
| 합계 | **1,117.5** | **1,633.25** | wrong level 431.75→**894.25** |

Rio만 `440.5→254.5초`로 개선됐다. 나머지 네 캐릭터는 75–138% 악화했다. 표적 없음/wander도 전 캐릭터가 늘었다: Frey `11.61/9.43→13.16/10.49%`, Luna `8.81/5.81→9.38/6.45%`, Nova `9.20/5.95→10.60/7.27%`, Rio `5.97/4.12→9.28/6.79%`, Yuki `4.27/2.80→8.88/6.84%`.

대치는 seed 101 realm 7 `103.9초`, seed 101 realm 1 `22.0초`, seed 111 realm 1 `81.5초`였다. fixture 두 건은 없어졌지만 더 긴 별도 대치가 남았다.

## recovery·링아웃

| recovery 진입 원인 | R11 | R14 | 변화 |
|---|---:|---:|---:|
| walked/dashed off | 881 | **1,522** | +72.8% |
| knocked off | 536 | **683** | +27.4% |
| air-down | 26 | **48** | +84.6% |
| other | 579 | **746** | +28.8% |
| 합계 | 2,022 | **2,999** | +48.3% |

| 캐릭터 | 링아웃(0점프) R11→R14 | recovery skill 사용/바닥 R11→R14 | PvP DPM R11→R14 |
|---|---:|---:|---:|
| Frey | 14(8)→**13(7)** | 21/9→**15/5** | 43.85→**43.10** |
| Luna | 24(17)→**23(15)** | — | 39.32→**36.94** |
| Nova | 31(18)→**29(17)** | 21/5→**17/2** | 41.09→**44.85** |
| Rio | 9(4)→**9(4)** | 5/1→**5/1** | 42.15→**38.43** |
| Yuki | 16(16)→**24(19)** | — | 25.76→**25.60** |

Nova 전체 링아웃은 2건 줄었지만 조기 shift의 직접 목표인 바닥 도달률은 `23.8%→11.8%`로 절반이 됐다. 17회 중 aim이 아래/수평인 경우가 3회였고, 0.5초 위치를 읽은 16회 중 12회는 shift 뒤에도 아래로 이동했다. 반면 Yuki 링아웃은 `16→24`, 0-jump는 `16→19`로 가장 크게 악화했다. Yuki의 0-jump 19건은 모두 마지막 점프를 recovery에서 썼고, 24건 중 18건은 직전 3초 PvP hit가 있었다. recovery 표적은 중앙값 938.4px 위, ledge 수평 거리는 124.7px였으며 실제 이동 skill ready는 0/24였다.

낙하 판정 자체는 R11과 같지만 이동 경로가 달라져 계측량도 변했다.

| Round 13 낙하 계측 | R11 | R14 |
|---|---:|---:|
| falling frame / arc landing frame | 366,090 / 274,618 | **374,954 / 257,440** |
| verdict flip / ring-out 전 flip | 1,438 / 43 | **2,266 / 46** |
| edge-graze flip | 593 | **1,094** |
| R10 수락·R11 거절 episode | 867 | **1,126** |
| 그 결과 landed / ring-out / unfinished | 856 / 9 / 2 | **1,110 / 16 / 0** |

이는 fall predictor 회귀라기보다 새 경로에서 모서리와 낙하를 더 많이 통과한다는 측정 근거다. 특히 edge-graze flip `+84.5%`와 walked-off recovery `+72.8%`가 함께 늘었다.

## 공격 activation과 궁극기

실제 `attack_serial` activation만 센 적중률이다.

| 공격 종류 | R11 activation/적중률 | R14 activation/적중률 |
|---|---:|---:|
| ground side | 6,712 / 70.78% | **6,544 / 73.90%** |
| ground up | 625 / 55.36% | **557 / 59.61%** |
| ground down | 258 / 20.93% | **225 / 30.67%** |
| air side | 966 / 42.65% | **1,015 / 41.58%** |
| air up | 483 / 61.90% | **464 / 51.29%** |
| air down | 672 / 55.06% | **736 / 58.15%** |
| skill 1 | 926 / 35.75% | **852 / 30.05%** |
| skill 2 | 392 / 22.70% | **350 / 20.57%** |

궁극기는 두 정의를 분리했다. 이전 observer의 0.4초 request 계측은 R11/R14 비교용이고, R14 판정은 `ultimate_cast`부터 제품의 `ultimate_window_timer`가 끝날 때까지 PvP damage를 직접 연결했다.

| 캐릭터 | R11 request/0.4초 hit | R14 request/0.4초 hit | R14 전체 window activation/hit activation |
|---|---:|---:|---:|
| Frey | 120/58 (48.33%) | **109/48 (44.04%)** | **95/75 (78.95%)** |
| Luna | 106/36 (33.96%) | **86/34 (39.53%)** | **75/69 (92.00%)** |
| Nova | 89/18 (20.22%) | **105/23 (21.90%)** | **82/74 (90.24%)** |
| Rio | 130/0 | **91/0** | **79/54 (68.35%)** |
| Yuki | 77/0 | **80/0** | **66/58 (87.88%)** |
| 합계 | 522/112 (21.46%) | **471/105 (22.29%)** | **397/330 (83.12%)** |

전체 window에서 397회 중 330회가 적어도 한 번 맞았고, hit event는 1,523회였다. R11에는 같은 signal/window 정의의 원시 계측이 없어 마지막 열을 R11과 직접 비교할 수 없다. 따라서 `f0dc673` 판정은 x1.5 실제 reach와 판단 거리의 정합성, 0.4초 지표의 비회귀, R14 전체-window 83.12%를 함께 근거로 한다.

## 변경별 판정

| 변경 | 판정 | 측정 근거 |
|---|---|---|
| `f0dc673` 궁극기 판단 reach를 `GameScale.COMBAT`에 맞춤 | **KEEP** | request `522→471`, 0.4초 적중률 `21.46→22.29%`, 전체 window activation 적중 `330/397=83.12%`; 전체 PvP DPM은 -1.7%로 유지 |
| `a94d3d6` 같은 층의 못 건너는 gap 표적은 route/사거리 없으면 선택하지 않음 | **KEEP** | no-route drop `110→6`; 관측 가능한 `unchecked_after_3` 선택/drop `0/0`(185 acquisition은 미확정); 단 no-target `8.24→10.47%`는 후속 보완 필요 |
| `a94d3d6` pursue와 engage approach가 route를 따라감 | **REVERT / REWORK** | gap+wrong drop `171→59`는 개선됐지만 no-progress `+46.2%`, wrong-level `+107.1%`, recovery `+48.3%`, walked-off `+72.8%`; 중앙 경기 길이 310.4→280.15초 |
| `114581a` Nova가 느린 낙하 중 조기 shift | **REVERT** | 직접 성과인 바닥 도달 `5/21→2/17`(23.8→11.8%); 전체 Nova 링아웃 `31→29` 개선만으로 실패한 activation을 정당화하지 못함 |
| `df87560` Rio counter는 progress attack으로 세지 않음 | **KEEP** | seed 106 fixture 재발 없음, 전체 5초+ 무입력 engage `2→0`; 회귀 테스트 통과 |
| `df87560` overhead route jump를 ledge에서 실행 + walkable rise 90px 제한 | **KEEP** | seed 112 fixture 재발 없음, 전체 5초+ 무입력 engage `2→0`; 회귀 테스트 통과. 단 일반 route-follow 구현은 별도 REWORK |

`a94d3d6`은 한 commit이지만 **표적 선택 절반은 유지하고 이동 실행 절반은 되돌려 재작업**하는 판정이다. 측정상 서로 반대 결과가 나왔기 때문에 commit 단위 일괄 keep/revert는 권하지 않는다.

## seed별 결과

| seed | R11 길이/승자/링아웃/recovery | R14 길이/승자/링아웃/recovery |
|---:|---|---|
| 101 | 342.5 / Luna / 7 / 135 | **330.4 / Nova / 10 / 427** |
| 102 | 324.8 / Yuki / 11 / 258 | **268.2 / Luna / 4 / 175** |
| 103 | 339.6 / Nova / 6 / 160 | **259.6 / Rio / 8 / 139** |
| 104 | 298.1 / Frey / 11 / 170 | **272.3 / Frey / 9 / 280** |
| 105 | 304.1 / Frey / 9 / 112 | **325.4 / Nova / 5 / 330** |
| 106 | 316.7 / Rio / 11 / 153 | **317.7 / Nova / 7 / 192** |
| 107 | 320.3 / Frey / 5 / 113 | **273.9 / Frey / 12 / 167** |
| 108 | 333.4 / Luna / 0 / 273 | **281.0 / Rio / 11 / 298** |
| 109 | 294.4 / Luna / 10 / 122 | **279.3 / Frey / 9 / 360** |
| 110 | 272.0 / Frey / 12 / 147 | **317.6 / Frey / 10 / 168** |
| 111 | 267.3 / Nova / 4 / 131 | **288.9 / Nova / 6 / 310** |
| 112 | 274.3 / Rio / 8 / 248 | **252.2 / Nova / 7 / 153** |

## 열린 항목 우선순위

1. **P0 — route-follow 실행을 좁혀 재작업한다.** drop 감소는 보존하되, waypoint가 실제로 가까워질 때만 같은 target을 유지한다. no-progress `1,633.25초`, wrong-level `894.25초`, recovery `2,999`, walked-off `1,522`를 R11 이하로 돌리는 것이 gate다.
2. **P1 — Yuki의 새 낙사 회귀를 seed 단위로 추적한다.** 링아웃 `16→24`, 0-jump `16→19`, 0승이다. route 진입 직후 ledge/air-jump 소비와 seed 108의 전체 링아웃 `0→11`을 먼저 본다.
3. **P1 — Nova 조기 shift는 되돌리고 activation 시점 A/B를 더 좁게 설계한다.** 바닥 도달 `2/17`; R11의 `5/21`보다 낮다. 17회 중 3회는 아래/수평 aim, 16회 중 12회는 0.5초 뒤에도 아래로 이동했다. `velocity <450`만으로는 부족하며 `aim.y < 0`, ledge 높이와 shift 뒤 예상 정점 조건이 필요하다.
4. **P1 — 새 장기 대치 2건을 fixture로 만든다.** seed 101 realm 7 `103.9초`는 Yuki/Luna가 soul crystal의 다른 층 접근과 recovery를 번갈아 반복했고, seed 111 realm 1 `81.5초`는 Luna의 monster recovery와 Nova의 no-target wander로 시작했다. 기존 fixture 2건은 해결됐지만 최장 대치는 `50.6→103.9초`다.
5. **P2 — 엄격한 target 선택 뒤의 무표적 fallback을 보완한다.** no-target `8.24→10.47%`, wander `5.86→7.73%`; 특히 Yuki none `4.27→8.88%`, wander `2.80→6.84%`. 2초 무표적이면 reachable target 재평가 또는 portal을 검토한다.
6. **P2 — 궁극기 full-window signal 계측을 기준 telemetry로 승격한다.** 기존 0.4초 지표는 Rio/Yuki를 0%로 잘못 보지만 실제 전체 window는 68.35/87.88%였다. R11과 정확히 같은 정의의 과거 비교값은 만들 수 없으므로 다음 변경부터 이 기준을 고정한다.

## 실행·검증

- import 1회 성공.
- 5초 smoke에서 새 분석 probe의 지역 변수 타입 추론 parse 오류 1건을 발견해 분석 코드만 수정한 뒤 재실행했다. 제품 오류가 아니다.
- 정식 probe 12/12 finished, 한 경기씩 순차 실행. 전체 wall time은 compact JSON 기준 기록됐다.
- seed 106을 한 번 더 재실행했다. 경기 tuple과 22개 event array의 행동 payload는 동일했고, 달라진 것은 process마다 바뀌는 instance ID와 wall-clock뿐이었다. 계측이 재현 가능한 게임 결과를 바꾸지 않음을 확인했다.
- 정식 12개 로그는 모두 exit 0. 각 로그의 `Failed to read the root certificate store` 1줄 외 `SCRIPT ERROR`, `Parse Error`, 다른 `ERROR`는 0건이다.
- `tests/test_bot_brain.gd`: exit 0, `Bot brain tests passed`; 인증서 잡음 외 오류 0.
- 원시 full-frame archive `round14-full.json.gz`는 clone에만 남기고 commit script에서 제외한다. compact 결과 `round14-results.json`, 집계 `round14-summary.json`을 포함한다.
- SHA-256: results `65BA22E361C1080A0CC69B8A9B7A9C833E416D3C889EFECBABCF257E8F6E815A`, summary `B5B0A3A2C67A0EE9675C6CB642A7CEE9DA02143DC964D195D9F65D7CDDF847B7`.
- 제품 소스와 기존 테스트는 수정하지 않았다. Round 14 전용 probe/runner/analyzer만 허용 경로에 추가했다.

재실행:

```powershell
powershell -ExecutionPolicy Bypass -File smash-nine-prototype/tests/analysis/codex_qa_14/run_round14.ps1 -Seed 101 -Count 12 -Seconds 480 -Players 8
node smash-nine-prototype/tests/analysis/codex_qa_14/analyze_round14.js
node smash-nine-prototype/tests/analysis/codex_qa_14/archive_round14.js
```
