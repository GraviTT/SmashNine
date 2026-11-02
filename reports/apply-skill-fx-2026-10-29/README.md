# 스킬 후보 적용 확인 (2026-10-29)

사용자 결정(2026-10-29 "적용 진행")에 따라 브랜치 `apply/skill-fx-2026-10-29`에 넣은 것:
- Rio 공중 추가 점프 이펙트: CODEX-VFX-01 a안(마력 발판), 첫 점프와 마지막 점프 두 상태
- Brave Luna 스킬 아이콘 J·K·L: CODEX-VFX-02 A안

## 그림
- `rio_air_step_board.png`: 2배 확대. 위 줄은 Rio 남, 아래 줄은 Rio 여.
  - 칸 순서: 첫 점프 a·b, 마지막 점프 a·b
  - a는 점프 순간이다. Rio를 뛴 자리에 세워 두고 찍었다. 발판이 발바닥 바로 밑에 붙는다.
  - b는 실제 비행 3프레임 뒤다. Rio가 떠오르고 발판이 부서진다.
  - 창 모드는 프레임 간격이 들쭉날쭉해, 0.125초짜리 발판을 정해진 프레임(1, 3)에 멈춰 찍었다. 게임에서는 그대로 재생된다.
  - 찍은 스크립트: `smash-nine-prototype/tests/analysis/lead/rio_air_step_capture.gd`
- `rio_<남|여>_air_step_<1|2>_<a|b>.png`: 원본 8장(480×360)
- `brave_luna_skill_bar_3x.png`: 변신 뒤 경기 HUD 오른쪽 아래 스킬 바를 3배로 키운 것. J·K·L이 새 아이콘이다. 전체 화면은 `brave_luna_screen.png`, 찍은 스크립트는 `tests/analysis/lead/brave_skill_bar_capture.gd`

## 발바닥 높이
두 체형 모두 점프 그림의 발바닥이 128칸 y=112이고, 바닥선은 y=120이다. 그래서 발판을 8px 올렸다(`Rio.AIR_STEP_SOLE_RISE`).
- 남자: `rio_male_jump.png` 0번 프레임
- 여자: 기본 시트의 점프 줄(4번째 줄. 걷기가 2·3번째 줄을 쓴다)
