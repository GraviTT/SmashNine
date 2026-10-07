# 자리 비움 루틴 · SmashNine

이 폴더에 이 프로젝트의 루틴 규칙(이 문서)과 회차 기록(`YYYY-MM-DD-<night|work>/`)을 모은다.
기본 규칙은 `away-routine` 스킬의 기본 규칙 카드이고, 여기 적은 것이 그보다 앞선다.
기본 카드의 🔒 규칙은 사용자 원문 근거가 있을 때만 바꾼다.

## 문서 · 검사
- 인수인계 문서(마무리 때 갱신): `design/ROADMAP.md` (상태·열린 항목), `AGENTS.md` (Codex 유닛 표)
- 방향 문서(뒤집는 결정은 사용자 몫): `design/DECISIONS.md`, `smash-nine-prototype/FINAL_GAME_GOAL.md`
- 검사: `smash-nine-prototype/`에서 `powershell -ExecutionPolicy Bypass -File tests/run_all.ps1 [-SoakRuns 3]`
- 빌드: 저장소 루트에서 `powershell -ExecutionPolicy Bypass -File tools/build_web.ps1`
- 작업 후보 출처: `design/ROADMAP.md`의 M1 열린 항목·M2·M3, `design/tasks/`

## 변경 반영
- 커밋: 작업마다
- push: 커밋마다 `main` (사용자 10-06 "끝나면 백업 할것")
- `gh-pages` 재배포(`tools/deploy_pages.ps1`)는 외부 공개라 사용자 몫

## 실행 방식
- 기본: Codex 사용 (codex-units 스킬)
- Codex 과제 카드 위치: `design/tasks/` · 유닛 클론: `GameProject/SmashNine-units/<unit>/SmashNine` (`--deps smash-nine-prototype/.godot`)
- Codex 샌드박스의 Godot 인증서 저장소 ERROR는 환경 소음 (`AGENTS.md`)

## 도구 · 환경
- Godot 창 모드 캡처는 잠깐 창이 뜬다. 한 번에 하나만.
- 로컬 웹 확인은 브라우저 창 + `.claude/launch.json`의 `smashnine-web`(8060), 마칠 때 닫는다.

## 품질 · 성능 기준
- 규칙 변경은 같은 시드 소크 전후로 잰다 (`tests/analysis/run_sweep.ps1` + `sweep_summary.ps1`).
- 화면 변경은 `tests/capture_screens.gd` 전후 캡처.

## 이 프로젝트에서 더한 사용자 몫 / 허락된 예외
- Frey 밸런스와 사람 플레이테스트는 보류 (사용자 10-06).
- 원본 아트가 기본값(사용자 10-07 채택). 새 아트도 바로 기본 경로에 넣되 F2 토글(prototype)과 폴백은 유지한다.

## 회차
| 날짜 | 모드 | 방식 | 목표 | 기록 |
| --- | --- | --- | --- | --- |
| 2026-10-07 | 근무 | Codex 2 (아트 빌더) | 렐름 기믹 3종, 중앙 렐름 아트 슬라이스, Frey 자체 스프라이트 시안 — 6/6 완료, 0:49에 일찍 마침 | `2026-10-07-work/README.md` |
| 2026-10-07 (2) | 근무 | Codex 2 × 5라운드 (빌더 9회 + 분석 1회) | 원본 아트 기본값, Rio, 체형(남·여), 캐릭터 시트 6장 + Brave Luna, 8렐름·몬스터·효과·로고 아트, 기믹 3종 추가, 소울 크리스탈, 결과 통계, 독립 검토 → P1 수정, gh-pages 재배포 — 11/11 + 남는 시간 작업 | `2026-10-07-work-2/README.md` |
| 2026-10-08 | 취침 | Codex 6회 (빌더 5 + 분석 1) | 스프라이트 184프레임 검사·수정(잘림 65 → 0, 원인: 원본을 같은 칸으로 자름), 궁극기 5명 성능(1회당 4.5~9 → 9.3~12)·이펙트 아트·컷인 연출, 몬스터 1배, 독립 검토 P1 2건 수정 — 8/8 + 남는 시간 작업 | `2026-10-08-night/README.md` |
