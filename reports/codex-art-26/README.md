# CODEX-ART-26 — Nova / Yuki / Rio 기술별 동작 시트 경계 보정

## 리드 재검수 — 잔여 줄무늬 제거

`tests/art_preview/moves_26/stripe_audit.gd`를 추가했다. 각 128×128 셀에서 8방향으로
연결된 불투명 성분 중 바운딩 박스가 `폭 ≤ 2px · 높이 ≥ 4px` 또는
`높이 ≤ 2px · 폭 ≥ 4px`인 성분을 센다. 또한 한 행/열에 6px 이상 곧게 이어지고
양옆 행/열이 모두 투명한 고립 직선도 별도로 센다. 아래 셀 좌표는 육안 검수 표기와
맞춘 1부터 시작하는 좌표다.

| 시트 | 얇은 성분 전→후 | 고립 직선 전→후 | 합계 전→후 | 변경 셀 |
|---|---:|---:|---:|---|
| Nova male | 33→0 | 19→0 | **52→0** | r2c2, r2c3, r2c4, r3c3, r5c3, r5c4, r5c5, r7c2 |
| Nova female | 16→0 | 2→0 | **18→0** | r2c3, r4c4, r5c4 |
| Yuki | 0→0 | 1→0 | **1→0** | r8c3 |
| Rio male | 0→0 | 0→0 | **0→0** | 없음 |
| Rio female | 5→0 | 5→0 | **10→0** | r1c6, r6c5, r7c5, r7c6 |
| **전체** | **54→0** | **27→0** | **81→0** | 16셀 |

얇게 분리된 조각은 제거했고, 효과 외곽에 대각선으로만 붙은 곧은 1px 선은 몸체의 주 암색
연결 성분과 그 주변 6px를 보호한 뒤 제거해 끝 모양을 불규칙한 하드 알파 가장자리로
마무리했다. 몸체의 중심 연결 성분은 이 단계에서 수정하지 않았다.

변경 셀만 모은 전/후 비교 이미지는 다음 네 파일이다. 각 행의 왼쪽이 수정 전, 오른쪽이
수정 후다. Rio male은 탐지·변경 셀이 없어서 별도 변경 셀 보드를 만들지 않았다.

- `nova_male_stripe_changed_before_after.png`
- `nova_female_stripe_changed_before_after.png`
- `yuki_stripe_changed_before_after.png`
- `rio_female_stripe_changed_before_after.png`

수정 전/후 원시 출력은 각각 `stripe-before-godot.log`, `stripe-after-godot.log`에 남겼다.
현재 자동 기준으로 남은 줄무늬는 없다.

## 완료

Nova 남·여, Yuki, Rio 남·여의 다섯 `*_moves_sheet.png`를 생성 원본에서 다시 추출했다. 고정 폭으로 자르던 방식을 없애고, 원본 전체의 연결된 포즈/효과를 프레임별로 먼저 분리한 뒤 128×128 셀에 배치했다. 몸체 중심은 라이브 idle 크기를 유지하고, 셀에 들어가지 않는 외곽 효과만 4px 안전 영역 안으로 압축했다.

새 ImageGen 호출은 하지 않았다. 기존 built-in ImageGen 원본인 `*_moves_source.png`를 재사용했다.

## 감사 수치 — 보정 전 → 보정 후

| 시트 | edge cells (3px+) | margin < 4px cells |
|---|---:|---:|
| Nova female | 16 → **0** | 20 → **0** |
| Nova male | 25 → **0** | 28 → **0** |
| Rio female | 32 → **0** | 36 → **0** |
| Rio male | 23 → **0** | 25 → **0** |
| Yuki | 20 → **0** | 22 → **0** |

최종 다섯 시트는 총 188개 사용 프레임이며, 부분 알파 0, scale anchor의 라이브 idle 대비 dark-height 차이 0px이다. 지상 행 첫 프레임은 feet y=120±2, 공중 행 첫 프레임은 라이브 jump 중심 ±4px 검사를 통과했다.

## 다시 그리거나 복원한 부분

- 고정 폭 슬라이스로 이웃 셀에 잘려 있던 포즈·무기·효과를 연결 성분 단위로 전부 재추출했다.
- 셀을 넘는 큰 효과는 몸체 배율을 바꾸지 않고 바깥 효과 영역만 축소했다. 몸체나 무기를 직선으로 자르지 않았다.
- 생성 원본이 요청한 몸체 프레임을 누락하고 효과만 만든 네 칸을 보정했다: `yuki r7c4`, `rio_male r2c2`, `rio_male r5c2`, `rio_female r2c2`. 각 칸의 고유 효과는 유지하고 같은 행에서 가장 가까운 정상 프레임의 동일 크기 몸체를 합성했다.
- 원본 포즈 사이의 작은 생성 노이즈 조각과 8px 미만 고립 픽셀을 제거했다.

재현 스크립트는 `smash-nine-prototype/tests/art_preview/moves_26/build_moves.gd`이다. 보정 전 시트는 `*_before_sheet.png`, 좌측 보정 전/우측 보정 후 비교는 `*_before_after.png`, 최종 접촉 시트는 `*_contact_1x.png`와 `*_contact_4x.png`로 저장했다.

## 테스트 확장

`tests/test_sprite_frames.gd`가 이제 `assets/art/` 아래의 모든 `*_moves_sheet.png`를 재귀적으로 찾고, 각 128×128 셀의 어느 변에도 불투명 픽셀이 3개 이상 놓이지 않는지 검사한다. 현재 이 브랜치에 존재하는 다섯 moves 시트를 모두 검사한다.

최종 실행 결과:

```text
MOVES_26_VERIFY_OK sheets=5 frames=188
nova_female_moves_sheet.png edge-touching: 0
nova_male_moves_sheet.png edge-touching: 0
rio_female_moves_sheet.png edge-touching: 0
rio_male_moves_sheet.png edge-touching: 0
yuki_moves_sheet.png edge-touching: 0
모든 시트 margin<4: 0
Sprite frame tests passed (8 main sheets, 184 frames, 5 moves sheets edge-clean)
```

리드 검수 후 재실행에서도 edge audit 0, margin audit 0, 부분 알파 0,
`MOVES_26_VERIFY_OK sheets=5 frames=188`, `test_sprite_frames.gd` 통과를 유지했다.

샌드박스에서만 발생하는 알려진 `Failed to read the root certificate store` 메시지는 별도 환경 잡음이다. 그 외 SCRIPT ERROR, Parse Error, 예상 밖 ERROR는 최종 실행에 없었다.

## 선택 작업 3 상태

이번 클론에는 `assets/art/luna/luna_moves_sheet.png`, `assets/art/luna/luna_brave_moves_sheet.png`, `tests/art_preview/moves_23/rio_male_sheet_v2.png`, `rio_female_sheet_v2.png`가 존재하지 않았다. 필수 1·2단계를 완료하고 검증한 시점에 38분 제한에 도달해, 존재하는 live Rio 시트를 임의로 대체하지 않았다. `frey_moves_sheet.png`는 지시대로 건드리지 않았다.

## 사람이 판단할 부분

- 네 개 생성 누락 칸에 합성한 인접 몸체가 실제 재생 속도에서 충분히 다른 동작으로 읽히는지
- Nova의 큰 중력 궤적과 Rio의 검광을 셀 안으로 압축한 정도가 타격 거리 표현을 약하게 만들지 않는지
- Yuki 최종 결계의 포털/부적 밀도가 배경과 충돌하지 않는지
- 1× 실제 게임 화면에서 각 기술 행이 기본 공격 행과 확실히 구분되는지

## 주요 결과물

- `smash-nine-prototype/assets/art/nova/nova_{male,female}_moves_sheet.png`
- `smash-nine-prototype/assets/art/yuki/yuki_moves_sheet.png`
- `smash-nine-prototype/assets/art/rio/rio_{male,female}_moves_sheet.png`
- `smash-nine-prototype/tests/art_preview/moves_26/*_before_after.png`
- `smash-nine-prototype/tests/art_preview/moves_26/*_contact_{1x,4x}.png`
- `smash-nine-prototype/tests/test_sprite_frames.gd`
