# Rio dimension slash 테스트 worktree 상태 보고 (2026-10-25)

- 세션: Rio dimension slash 테스트 — worktree `.claude/worktrees/awesome-hofstadter-9dade4`, 브랜치 `claude/awesome-hofstadter-9dade4`
- 이 보고서 위치: worktree 안 `reports/status-2026-10-25/rio-slash-test-worktree.md`. main 체크아웃 경로(`SmashNine/reports/status-2026-10-25/`)에는 이 세션의 쓰기 보호 훅이 막아서 쓸 수 없었다. 이 파일은 추적되지 않으므로 worktree를 정리하면 함께 지워진다. 정리 전에 옮겨야 한다.
- 근거: 이 worktree에서 2026-10-25에 본 `git log` / `git status` / `git branch` / `git worktree list`, `git show main:<파일>` 코드 대조, `reports/`·`routine/` 문서, 이 세션 대화 기록(압축되지 않음). `git fetch`는 하지 않았고 로컬 `main`(`c51a417f`, 로컬 `origin/main`과 같은 커밋)과 비교했다. 이번 점검에서는 Godot 테스트를 돌리지 않았다(점검 규칙).

## 1. 담당 작업

- 맡은 범위: `smash-nine-prototype/tests/test_rio_prototype.gd`의 `_test_dimension_slash()`가 다른 CPU 작업(Codex 봇 매치)과 동시에 돌 때 한 번 실패한 문제를, 테스트만 고쳐 벽시계 속도와 무관하게 만들기. 조건: 제품 코드(Rio.gd) 변경 금지, `tests/run_all.ps1` ALL PASSED, main에 푸시(강제 푸시 금지).
- 언제: 2026-10-09, 사용자 직접 요청. 같은 날 이 세션이 띄운 후속 작업 칩("Harden Luna and Nova tests against slow frames")을 사용자가 "여기에서 진행해 달라"고 해서 Luna·Nova 테스트도 맡았다.
- 관련 결정: 테스트 타이밍 수정이라 따로 D 번호 없음. 테스트가 확인하는 순간이동 거리 `BLINK_DISTANCE * GameScale.WORLD`는 D27(GameScale)을 따른다.

## 2. 한 일 (날짜순)

| 날짜·시각 | 내용 | 커밋 | 산출물 |
|---|---|---|---|
| 2026-10-09 | 원인 확인: dimension slash 히트박스는 0.08 s(물리 5프레임)인데, 테스트는 프로세스 프레임마다 한 번만 봤다. 부하가 걸리면 프로세스 프레임 하나에 물리 프레임이 최대 8개 돌아, 확인하기 전에 히트박스가 사라졌다. 프로세스 프레임마다 일부러 멈추는 스크립트로 재현했다(70 ms 정지부터 매번 실패). 같은 파일의 rune shield 반격 검사(120 ms 이상)와 overdrive "orbit before firing" 검사(90/120/200 ms)도 같은 유형으로 실패했다. mana wave는 실패하지 않았다. 새 worktree에서 처음 돌린 실행이 한 번 exit 1이었다(어느 검사인지 기록 못 함). | — | 재현 스크립트는 세션 임시 폴더(3절) |
| 2026-10-09 21:59 | Rio 테스트 수정: `_wait_for`가 물리 프레임마다 확인하게 했다. overdrive는 0.55 s 궤도 중 처음 0.3 s를 프레임마다 확인하고, mana wave는 세 번째 J 직후부터 확인한다. 검사 내용은 그대로다. | `560b38b` | `smash-nine-prototype/tests/test_rio_prototype.gd` |
| 2026-10-09 | 검증: 수정 후 정지 0–300 ms와 무작위 정지 16회 모두 통과. Rio.gd를 임시로 네 가지로 망가뜨려(슬래시 없음, 궤도 0.2 s, 반격 없음, 웨이브 없음) 각 검사가 잡는 것을 확인하고 되돌렸다. 일반 실행 8/8, `run_all.ps1` ALL PASSED. | — | (이 세션 기록) |
| 2026-10-09 | 실시간 대기를 쓰는 다른 테스트 8개를 같은 방식으로 점검: `test_luna_prototype`, `test_nova_prototype`가 120/200 ms에서 실패했다. 후속 작업 칩을 만들었다. | — | 칩 `task_9ba2113a` (이 세션 기록) |
| 2026-10-09 | 사용자 요청으로 이 세션에서 진행: 앱 도구로 브랜치를 `origin/main`(`066b7c0`)에 fast-forward하고, worktree에서 `--import`를 실행했다(새 플래시 아트 4개 가져오기). | — | — |
| 2026-10-09 22:55 | Luna·Nova 테스트 수정. Luna: 혜성 블룸(0.13 s)을 물리 프레임마다 확인하고, 링 두 조각은 생성될 때 센다(예방 조치). Nova: 슬링샷 Nova를 `is_dummy = true`로 했다. 원인은 물리를 켜면 봇 두뇌도 돌아 슬링샷을 스스로 눌러 테스트 입력보다 먼저 발사하던 것으로, 프레임별 상태 기록으로 확인했다. 궤도 대기는 게임 시간 0.1 s(물리 6프레임)로 고정하고, 착지 버스트(0.14 s)는 프레임마다 확인한다. | `27d0c54` | `smash-nine-prototype/tests/test_luna_prototype.gd`, `smash-nine-prototype/tests/test_nova_prototype.gd` |
| 2026-10-09 | 검증: 수정 전 Nova는 70 ms부터, 무작위 6회 모두 실패했고 Luna는 200 ms와 무작위 6회 중 4회 실패했다. 수정 후에는 테스트별 0–300 ms 정지와 무작위 6회 모두 통과했다. 제품 코드를 다섯 가지로 임시로 망가뜨려(블룸 없음, 링 한 조각, 발사 안 됨, 궤도 정지, 버스트 없음) 각 검사가 잡는 것을 확인하고 되돌렸다. 일반 실행 각 6/6, `run_all.ps1` ALL PASSED. 두 커밋 모두 `origin/main`에 fast-forward로 푸시했다. | — | (이 세션 기록) |
| 2026-10-25 | 이 상태 보고서 작성(조사만, 코드 변경 없음) | — | 이 파일 |

Codex 카드, Codex 실행, Artifact는 없다.

## 3. 현재 진행 정도

| 항목 | 상태 |
|---|---|
| Rio 테스트 부하 내성 수정 (`560b38b`) | 완료(확인함) — main에 있음 |
| Luna·Nova 테스트 부하 내성 수정 (`27d0c54`) | 완료(확인함) — main에 있음 |
| 10-09 이후 main 변경 뒤에도 세 테스트가 유효한지 | 완료(확인 안 함) — 코드 대조로는 유효(4절). 이번 점검 규칙상 Godot 재실행은 안 함 |
| 이 worktree 정리 | 보류 — 사용자·점검 세션 승인 대기 |

- 브랜치 머지: `git branch --merged main`에 `claude/awesome-hofstadter-9dade4`가 있고, `git log main..HEAD`는 비어 있다. HEAD는 `27d0c54`, main은 `c51a417f`.
- 커밋 안 된 변경: 추적 파일 변경은 없다. 추적 안 되는 파일은 이 보고서와 `.gd.uid` 26개다. `.gd.uid`는 2026-10-09 `--import` 실행 때 Godot가 다른 세션 스크립트들에 만들어 준 uid로, main 체크아웃에도 같은 종류가 추적 안 된 채 있다. 무시되는 `smash-nine-prototype/.godot/`(약 69 MB)는 main 체크아웃에서 복사한 가져오기 캐시다.
- 머지 안 된 브랜치·worktree·Codex 클론: 이 세션 것은 없다. `claude/bugfix-review-2026-10-21` worktree와 `claude/realm-gimmicks-2026-10-22` 브랜치는 다른 세션 작업으로 보인다.
- 켜져 있을 수 있는 서버·백그라운드 작업: 없다. 이 세션의 백그라운드 작업(run_all 3회, 정지 테스트, `--import`)은 2026-10-09에 모두 끝났고, 서버는 띄운 적이 없다.
- 저장소 밖 재현 스크립트: 세션 임시 폴더 `C:\Users\TH\AppData\Local\Temp\claude\C--Users-TH-Documents-AI-GameProject-SmashNine--claude-worktrees-awesome-hofstadter-9dade4\899d3b3e-70aa-45d8-a56e-345945b9150c\scratchpad\`에 `stress_rio.gd`, `stall\stall_<테스트>.gd` 8개, `stress2\stress_test_luna_prototype.gd`·`stress_test_nova_prototype.gd`, `nova_probe.gd`가 있다. 임시 폴더 정리 때 사라질 수 있다.

## 4. 문제와 위험

1. **Nova 테스트에 새 부하 경합이 생겼을 수 있음 (확인 안 함).** 2026-10-21 `501f0978` "Count attack start-ups in physics ticks, not idle frames"(bugfix-review 브랜치, 다른 세션 작업으로 보임)가 `PlayerBase._wait_action`을 물리 틱 타이머(`create_timer(seconds, true, true)`)로 바꿨다. 10-09에 그대로 둔 Nova의 `_wait_for_source_script`는 0.005 s 프로세스 타이머로 확인하는데, "공격이 프로세스 타이머에서 생긴다"는 전제가 있어야 안전했다. 이제 공격은 물리 스텝 끝에서 생기므로, 부하가 걸리면 같은 프레임 안에서 물리 프레임이 최대 7개 더 지난 뒤에야 확인한다. 느린 J 공격의 수명은 `lerpf(0.075, 0.12, momentum)`(약 5프레임)이라 `_test_momentum_attack_scaling`이 "Nova slow J did not create an attack"로 실패할 수 있다. 중력 브레이크 버스트(0.14 s, 9프레임)는 안전하다. 그 뒤의 run_all 통과 기록(`reports/bugfix-review-2026-10-21.md`, `routine/2026-10-22-night/README.md` 08:58)은 부하 없는 실행이라 이 위험을 반증하지 못한다.
2. **Rio 테스트 주석 일부가 옛 전제 (동작은 정상).** `_test_overdrive` 주석은 "부하 때 타이머가 ~0.15 s씩 진행"을 이유로 든다. `501f0978` 이후 궤도 타이머는 물리 틱이라 여유가 오히려 커졌다. 검사는 맞고 설명만 낡았다.
3. **"두 번째 공중 슬래시는 순간이동하면 안 됨" 검사가 부하 때 약해짐.** 거짓 실패는 아니고, 거짓 통과만 가능하다. 이 검사는 0.1 s 프로세스 타이머로 기다리는데 블링크 홀드(0.06 s)가 이제 물리 틱이라, 부하 때 물리 4틱이 지나기 전에 대기가 끝날 수 있다. 그러면 잘못 허용된 순간이동을 놓친다.
4. **10-09 이후 Rio 변경과 ART-77 대조 결과: 테스트는 여전히 유효하다고 판단(재실행은 안 함).**
   - 대조한 Rio 코드 변경: `de1f2599`(스킬 이펙트), `6d492149`(모션 행 연결), `710acfb9`(Rio 다시 그림), `2188e542`(시작 시간 늘림, D39), `de03768e`(스프라이트 감사), `501f0978`(물리 틱 시작 시간).
   - ART-77: `9b6a8505`(카드), `9e6678ec`·`dca69f4f`(후보 이미지, `art/bakeoff/rio/`만).
   - 테스트가 기대는 값은 main에서도 그대로다: `BLINK_DISTANCE` 200, `BLINK_HOLD` 0.06, 슬래시 수명 0.08, 반격 수명 0.12, `RUNE_DURATION` 0.5, `OVERDRIVE_ORBIT_TIME` 0.55, `OVERDRIVE_FIRE_GAP` 0.07, 마나 웨이브 0.24, `air_jumps` 2, `GameScale.WORLD` 1.5. 물리 설정은 기본값(초당 60틱, 프레임당 최대 8스텝)이다.
   - 모션 쪽 변경은 스프라이트 포즈와 이펙트뿐이고, ART-77 후보는 게임에 연결되지 않았다.
   - 세 테스트 파일은 `27d0c54` 이후 바뀌지 않았고, `run_all.ps1` 목록에 그대로 있다.
   - `501f0978` 이후 생성 시점이 물리 스텝 끝으로 옮겨졌어도 Rio·Luna 수정은 성립한다. 물리 타이머로 생긴 노드는 다음 물리 스텝부터 처리되므로, 물리 프레임마다 보는 대기가 여전히 먼저 본다.
5. 되돌려야 할 것: 없다. 결정 문서와 어긋나는 것: 없다(테스트만 수정). 다른 세션과 겹치는 것: 위 1번처럼 bugfix-review의 `501f0978`이 Nova 헬퍼의 전제를 바꾼 것뿐이다.

## 5. 앞으로의 계획

1. Godot을 돌릴 수 있는 세션에서 현재 main으로 Nova·Luna·Rio 테스트를 정지 재현 스크립트로 확인한다. 4-1이 실제로 나오면 `test_nova_prototype.gd`의 `_wait_for_source_script`를 물리 프레임 확인으로 바꾼다(테스트만 수정). 사용자 확인은 필요 없고, 순서만 점검 세션·총괄이 정한다.
2. 같은 김에 4-2 주석과 4-3 검사를 현재 타이머 방식(물리 틱 대기)에 맞게 손본다. 사용자 확인은 필요 없다.
3. 이 worktree 정리: 이 보고서를 main 쪽 `reports/status-2026-10-25/`로 먼저 옮긴다. 브랜치는 이미 main에 있고 남은 것은 다시 만들 수 있는 `.uid`와 캐시뿐이다. 정리(삭제)라서 사용자 확인이 필요하다.
4. 정지 재현 스크립트를 저장소 도구로 남길지 정한다(예: `smash-nine-prototype/tests/analysis/stall/`). 사용자·총괄 판단이 필요하다. 안 남기면 1단계 때 다시 써야 한다.

## 6. 사용자가 직접 확인해야 할 것

| 우선순위 | 무엇 | 어디서 (경로 · URL · 실행 방법) | 걸리는 시간 | 왜 / 안 하면 무엇이 막히는지 |
|---|---|---|---|---|
| P3 | 이 worktree 정리 승인 (보고서를 옮긴 뒤) | `.claude/worktrees/awesome-hofstadter-9dade4` — Claude 앱의 worktree 정리, 또는 `git worktree remove .claude/worktrees/awesome-hofstadter-9dade4` | 1분 | 작업은 모두 main에 있다. 안 해도 막히는 것은 없다(디스크 약 70 MB) |
| P3 | 정지 재현 스크립트를 저장소에 남길지 | 3절의 세션 임시 폴더 경로 | 1분 | 임시 폴더가 지워지면 5-1 때 다시 작성해야 한다 |

P1 0개, P2 0개.
