# QA-25 — Nova의 짧은 J를 테스트가 놓치는가

## 원본 테스트 반복 결과

| 조건 | 유효 횟수 | 통과 | 실패 | 정확한 실패 메시지 |
|---|---:|---:|---:|---|
| 추가 부하 없음, FPS 제한 없음 | 20 | 20 | 0 | 없음 |
| `--max-fps 10` | 20 | 20 | 0 | 없음 |
| 다른 headless Godot 소크 2개 동시 실행 | 20 | 20 | 0 | 없음 |

**판정:** 요청된 원본 `tests/test_nova_prototype.gd`의 실패는 재현하지 못했다. 그러나 도우미가 짧은 공격을 놓칠 수 있다는 **구조적 취약성은 별도 합성 지연 조건에서 재현했다.** 이 두 결과를 구분한다. 원본 게임에서 Nova J가 생성되지 않는 버그는 이번 자료로 주장하지 않는다.

동시 부하 최초 20회 중 마지막 실행 도중 소크 하나가 자연 종료됐다. 그 회차도 통과했으나 완전한 2개 동시 부하 횟수에서 제외하고 `supplement-load-1`을 추가했다. 위 부하 20회는 `load-1~19` + 보충 1회다. 원본 실행 자체는 총 61회 모두 통과했다. 모든 원본 실행의 인증서 외 엔진 오류는 0, 알려진 인증서 오류는 실행당 1줄이었다.

기본 20회 총 251.207초, 10fps 20회 269.941초, 최초 부하 20회 274.569초, 보충 1회 14.033초. 실행·계측·자료 작성은 45분 제한 안에 마쳤다.

## 발견 및 담당

| 발견 | 심각도 | 측정값 | 담당 / 유력 수정 위치 |
|---|---|---|---|
| 살아 있는 노드를 idle 타이머로 찾으면 생성·삭제 사이를 건너뛸 수 있음 | 중(테스트 신뢰성) | 최종 합성 대조: 현재 선딜+idle 검사 3/3 실패, 물리 검사 3/3 통과 | 테스트 도우미 `tests/test_nova_prototype.gd:188`, 특히 `:193` |
| 원본 slow J가 실제 부하 조건에서 실패하는지 | 미재현 | 유효 60/60 통과, 추가 부분 부하 1회도 통과 | 테스트 불안정 가능성은 남지만 발생 빈도·다른 PC 재현은 미확정 |

### 최종 합성 대조(원본 반복 집계에 포함하지 않음)

| 선딜 타이머 | 검사 방식 | 실제 주입 | 통과 / 실패 |
|---|---|---:|---:|
| 제품 그대로: physics | 원본 그대로: idle 0.005초 | 3/3 | 0 / 3 |
| 테스트 폴더의 Nova 서브클래스: idle | idle 0.005초 | 3/3 | 3 / 0 |
| 제품 그대로: physics | 매 `physics_frame` | 3/3 | 3 / 0 |

정확한 실패 문구는 **`Nova slow J did not create an attack`**. 실제 공격 생성·삭제 이벤트가 기록되므로 문구가 실제 발생 사실과 다르다. 계측본은 원본 `_test_momentum_attack_scaling()`을 상속해 그대로 실행한다. `_fail()`만 즉시 종료 대신 기록 후 exit 1을 반환하게 바꾸어 타임라인을 보존했다. 따라서 합성 실패 로그의 엔진 오류 0은 논리 테스트 통과라는 뜻이 아니다.

**합성 fixture 차이:** 렌더링 자원을 유지하도록 멀리 떨어진, physics가 꺼진 Nova 하나를 미리 만들고 0.3초 timer로 초기 catch-up 구간을 지난다. slow J 시작 뒤 최소 2물리 틱이 지난 아직 미검출 poll에서 `OS.delay_msec(150)`을 한 번 호출한다. 최종 9개 자료의 `stall_executed`는 모두 true다. 입력은 원본과 같은 `perform_basic_attack("side", RIGHT)` 호출이며 사람의 키 입력 검사는 아니다. 보통 속도 180, 빠른 속도 700, 물리 60Hz, 프레임당 최대 물리 처리 8틱. 적·랜덤 시드·실제 경기 부하는 이 합성 fixture에 없다.

첫 탐색에서는 초기 8틱 catch-up이 끝나기 전에 공격을 잡아 지연 주입이 실행되지 않는 경우가 있었다. `trace-*`, `warm-trace-*` 원시 파일도 보존했으나 이 최종 대조 표는 자원을 유지해 조건을 맞춘 **`prewarm-trace-*` 9개만** 집계했다. 초기 탐색의 미주입 성공을 지연 대조 성공으로 세지 않았다.

## 실제 타임라인

P=물리 프레임, F=process 프레임. 번호는 각 프로세스 안의 절대 관측값이다. 모든 poll은 JSON에 있고 아래는 핵심 이벤트만 추렸다.

### 원본 시작 순서의 통과 사례

`trace-physics-idle-fps0-stall0-1.json`:

| 이벤트 | P | F | 결과 |
|---|---:|---:|---|
| slow J 호출 전/후, poll 0 | 1 | 0 | 없음 |
| 공격이 tree에 들어옴 | 5 | 0 | 생성 확인 |
| poll 1 | 8 | 0 | 공격 검출 |
| 해당 공격이 tree에서 나감 | 10 | 1 | 정상 수명 종료 |

### 합성 지연의 실패 사례

`prewarm-trace-physics-idle-fps0-stall150-1.json`:

| 이벤트 | P | F | 벽시계 μs(프로브 시작 기준) |
|---|---:|---:|---:|
| slow J 호출 전 | 18 | 7 | 233223 |
| poll 5: 공격 없음 | 20 | 12 | 265046 |
| 지연 시작 → 끝 | 20 | 12 | 265059→415144 |
| 공격 생성 | 23 | 13 | 423391 |
| 공격 삭제 | 28 | 13 | 452834 |
| poll 6: 공격 없음 | 28 | 13 | 455735 |
| 100회 검사 후 실패 | 113 | 121 | 1822771 |

**동일한 F13 안에서 생성(P23)과 삭제(P28)가 모두 끝났고 다음 idle poll은 삭제 뒤였다.** 수명은 5물리 틱이었다. 지연 주입은 요청 150ms, 이 사례 실측 150.085ms다.

```text
idle 검사       없음(P20) ───── 150ms 지연 ─────────────── 없음(P28)
physics 실행                              생성(P23) → 삭제(P28)
```

이 그림은 실제 실패 타임라인을 줄인 것이다. 공격이 생성되지 않은 것이 아니라 관측 사이에서 수명이 끝났다.

### 같은 지연, idle 선딜 대조

`prewarm-trace-idle-idle-fps0-stall150-1.json`: J=P18/F20, 지연=P20/F25(201079→351975μs), 생성=P28/F26, poll 6=P28/F26에서 검출, 삭제=P33/F37. `nova_idle.gd`가 `_wait_action`만 `create_timer(seconds)`로 바꾸고 epoch/defeat 검사를 그대로 유지한다. **과거 커밋 자체를 실행한 것이 아니라 현재 코드의 타이머만 바꾼 반사실 대조**다.

### 같은 지연, physics 검사 대조

`prewarm-trace-physics-physics-fps0-stall150-1.json`: J=P18/F18, 지연=P20/F23(185180→336127μs), 생성=P23/F24, 다음 physics poll=P24/F24에서 검출. process frame이 다음으로 넘어가기 전에도 검사하므로 짧은 영역을 잡는다.

## 원인과 제안

**측정한 사실:** Nova 지상 J는 `characters/nova/Nova.gd:111`의 0.076초 선딜 후 `:199`에서 공격을 만들고, `:219`가 수명을 0.075~0.12초로 정한다. `scripts/Attack.gd:31`의 물리 업데이트가 수명을 계산하여 `:37`에서 제거한다. 공통 선딜도 `characters/common/PlayerBase.gd:1097`에서 physics timer를 기다린다. 원본 테스트 `:193`만 idle timer로 기다리며, 한 process frame 안에서 여러 물리 틱이 실행되는 경우 공격 전체가 두 poll 사이에 들어갈 수 있음을 이벤트로 확인했다.

**추정의 범위:** 다른 세션의 과거 실패가 바로 이 원인이었는지는 당시 타임라인이 없어 확정하지 못한다. 이번 원본 61회에서 실패하지 않았다는 결과가 모든 부하·시작 위상에서 안전하다는 증명도 아니다. 합성 조건은 관측 공백의 가능성을 확인하며 실제 사용 빈도를 측정하지 않는다.

**리드에게 제안(미수정):** `_wait_for_source_script`를 같은 파일 `:199`의 `_wait_for`처럼 매 `physics_frame` 검사 및 게임 시간 제한으로 바꾼다. 단순히 timeout을 늘리면 이미 삭제된 공격을 찾을 수 없다. 제품 선딜을 idle로 되돌리거나 공격 수명을 늘릴 근거는 없다. 최종 physics 검사 대조는 이 제안의 작은 검증이며 원본 테스트 파일은 수정하지 않았다.

## 다른 테스트의 동일·유사 패턴

`polling-search.txt`는 `tests/**/*.gd` 전체에서 `create_timer(0.0...)`를 찾은 결과다(이번 프로브 제외). 0.005초 루프는 Nova와 Luna 2곳이다. 더 넓은 0.01/0.02초 패턴도 함께 검토했다.

| 위치 | 검사 대상 | 동일한 누락 위험 판단(정적 검토) |
|---|---|---|
| `tests/test_nova_prototype.gd:193` (호출 `:48`, `:57`, `:97`, `:106`) | J 공격, L burst의 살아 있는 노드 | J는 합성 재현. L은 수명 0.14초로 더 길지만 같은 도우미 사용; L 누락은 별도 재현하지 않음 |
| `tests/test_luna_prototype.gd:56` | 생성 이벤트 배열의 개수 | **같은 방식으로 놓치지 않음.** `:47~51`에서 node_added를 누적하므로 노드 삭제 뒤에도 개수가 남음 |
| `tests/test_luna_prototype.gd:74` | 살아 있는 혜성 | 패턴은 유사. 고립 fixture의 비행 260/620≈0.419초로 J보다 길다. 충돌 등으로 빨리 사라지는 경우의 위험은 추정, 이번에 재현하지 않음 |
| `tests/test_luna_prototype.gd:144` | 살아 있는 하트 레이저 | 패턴은 유사. fixture 지속 0.46초로 J보다 길다. 누락 미재현 |
| `tests/test_luna_prototype.gd:109`, `:126`, `:164` | 변신 시작, 대시 속도, 변신 종료 상태 | 해당 fixture는 캐릭터 physics가 꺼져 있고 상태를 본다. 짧은 노드 생존 구간 검사와 다름 |
| `tests/test_character_architecture.gd:83` | Yuki 봉인 배열 | 생존 노드 계열이지만 기본 5초이며 고립 fixture다. 이번 짧은 J와 같은 누락은 미재현 |
| `tests/test_character_architecture.gd:57` | 정리 전 0.02초 대기 | 노드를 찾는 반복 검사 아님 |

Luna 혜성 폭발 `:81`, 달고리 `:94`와 Nova 궁극기 폭발 `:167`은 이미 physics 검사 또는 생성 이벤트 기록으로 되어 있다.

## 부하와 실행 방법

4개 논리 CPU 환경. 추가 소크는 seed 2501/2502, 8봇, headless, `--fixed-fps 60`, 480초 상한이며 원본 soak를 상속해 실제 엔진 PID 기록과 종료 파일 감시만 더했다. 부하 도중 system CPU의 5개 약 5초 샘플은 모두 **OS 보고 사용률 100%(4개 코어 상당)**였다. 이는 다른 세션을 포함한 총량이다. 같은 샘플의 두 소크 CPU 시간/벽시계는 0.456~0.673코어 상당, 테스트별 전체 구간에서는 0.530~1.005코어 상당이었다. 특정 물리 코어를 점유했다고 주장하지 않는다.

`cpu-samples.json`의 normalized core 수는 GetSystemTimes의 busy/total 비율×4다. `raw_unaligned_core_ratio`는 SystemTimes와 프로세스 조회 시각 차이가 있는 벽시계 나눗셈도 보존한 값이며 코어 개수 판정에 쓰지 않았다. 콘솔 exe는 wrapper이므로 그 CPU 값은 `console_wrapper_cpu_seconds`로 따로 적고 실제 부하 측정은 worker PID의 엔진 프로세스를 사용했다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File reports/codex-qa-25/run.ps1 -Condition baseline
powershell -NoProfile -ExecutionPolicy Bypass -File reports/codex-qa-25/run.ps1 -Condition fps10
powershell -NoProfile -ExecutionPolicy Bypass -File reports/codex-qa-25/run.ps1 -Condition load
powershell -NoProfile -ExecutionPolicy Bypass -File reports/codex-qa-25/prewarm-traces.ps1
```

한 번에 테스트 엔진 1개, `load` 조건에서만 추가 소크 2개. 모든 추가 부하 프로세스는 종료했다. 제품 코드·기존 테스트·실제 `user://` 세이브·git에 손대지 않았다. 파일 목록은 `files.txt`, 전체 집계는 `summary.json`, 개별 실행 결과와 명령은 `*-results*.json`, 이벤트는 `*trace-*.json`, stdout/stderr는 `logs/`다.

**남은 작업:** 리드가 Nova 도우미를 physics 검사로 바꿀지 결정하고 기존 전체 테스트로 검증. 다른 PC에서의 원본 실패 빈도, Luna의 더 긴 노드 누락 가능성은 미확정. 이 카드에서는 수정하지 않음.
