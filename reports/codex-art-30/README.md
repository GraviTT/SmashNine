# CODEX-ART-30 결과 보고

## 완료 범위

### Part 1 — Rio v2 라이브 시트

- `rio_male_sheet_v2.png`의 9개 마진 위반 셀과 `rio_female_sheet_v2.png`의 2개 마진 위반 셀을 4 px 투명 마진으로 정리했다.
- 수정한 v2 후보를 각각 `assets/art/rio/rio_male_sheet.png`, `rio_female_sheet.png`에 반영했다.
- 시트 크기는 남녀 모두 `768×896`이며, 128×128 셀과 캐릭터 몸체의 크기·위치·팔레트는 바꾸지 않았다.
- 프레임 검사에서 추가로 검출된 직선 절단 윤곽 6셀(남 3, 여 3)은 윤곽 일부의 알파만 0.35로 낮춰 불규칙한 디더 경계를 만들었다. 그 결과 `test_sprite_frames.gd`가 184프레임 전체 통과했다.

### Part 2 — Frey/Luna/Brave 무브 시트

- Frey `768×1024`: 카드 예상 7셀이 아니라 실제 감사에서 검출된 8셀을 수정했다.
- Luna `768×768`: 4셀을 수정했다.
- Luna Brave `768×1152`: 5셀을 수정했다.
- 모든 경우 셀 외곽 0–3 px 밴드의 효과 픽셀만 제거했다. 캐릭터 몸체를 축소하거나 프레임을 이동하지 않았다.

Part 3은 이 카드에 별도 항목이 없어 수행 대상이 없다.

## 수치 검증

- 수정 전 `margin<4`: Rio 남 9 / Rio 여 2 / Frey 8 / Luna 4 / Brave 5셀.
- 수정 후 `margin<4`: 다섯 시트 모두 0셀.
- 수정 전후 `edge_audit`: 다섯 시트 모두 0셀.
- `test_sprite_frames.gd`: `Sprite frame tests passed (8 sheets, 184 frames)`.
- `--headless --import`: 종료 코드 0. 샌드박스 고유의 루트 인증서 저장소 오류 한 줄만 발생했다.
- 기본 `run_all.ps1 -SkipSoak`는 위 알려진 인증서 오류를 실패로 집계했다. 같은 테스트 목록을 `run_filtered_tests.ps1`로 실행해 그 정확한 오류만 제외하고 나머지 엔진 오류와 종료 코드는 그대로 검사했으며, 29/29 테스트가 통과했다.

## 시각 자료

`tests/art_preview/margin_30/`에 각 시트의 전체 before/after, 변경 셀만 모은 1×/4× 좌우 비교판, `margin_changes.csv`를 저장했다. 비교판은 왼쪽이 수정 전, 오른쪽이 수정 후다.

- `rio_male_changed_before_after_4x.png`
- `rio_female_changed_before_after_4x.png`
- `frey_moves_changed_before_after_4x.png`
- `luna_moves_changed_before_after_4x.png`
- `luna_brave_moves_changed_before_after_4x.png`

## 이미지 생성 도구 판단

내장 이미지 생성 도구로 Rio 여성 시트를 참조한 정밀 수정 후보를 1회 생성했다. 프롬프트는 “6열×128 px 셀, 4 px 투명 마진, 몸체·포즈·팔레트·배치 불변, r4c1/r4c2/r5c0의 효과 윤곽만 불규칙 디더 처리”였다. 생성본은 원본보다 크게 재래스터화되고 캐릭터 윤곽까지 달라져 채택하지 않았다. 확대 없는 Godot `Image` API 결과만 프로젝트에 반영했다.

## 사람이 판단할 항목

- 외곽 효과 끝을 1–4 px 다듬은 변화가 실제 게임 배율에서 충분히 자연스러운지.
- Rio의 복원된 큰 공격·방어 자세가 기존 축소판보다 캐릭터 실루엣과 타격감을 더 잘 전달하는지.
- 특히 Frey `r5c3`, `r6c4`의 가장자리 효과 감소량은 계약상 필요했지만, 미감상 더 많은 잔상을 남겨야 하는지는 사용자/리드의 취향 판단이다.

## 제한 사항

- 윈도우 샌드박스의 `Failed to read the root certificate store` 오류는 프로젝트 지침에 명시된 알려진 잡음이며 외부 실행에서는 발생하지 않는다.
- 게임 규칙, 데미지, 히트박스, 타이밍, 입력, 봇 및 제품 코드는 변경하지 않았다.
