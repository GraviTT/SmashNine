# CODEX-ART-09 결과 보고

## 완료

v2 캐릭터 시트 8장, 사용 프레임 184개를 각각 4배 확대해 검토했다. 잘린 공격 효과, 이웃 셀 조각, 4px 안전 여백 위반을 포함한 31개 프레임을 수정했다. Yuki는 23개 프레임 모두 이상이 없어 원본과 픽셀 동일하게 유지했고, 나머지 7개 시트만 변경했다.

- 최종 시트: 모두 768×896, 6열×7행, 셀 128×128
- 사용 프레임: 시트당 23개, 총 184개
- 수정 프레임: 31개
- 미사용 셀: 총 152개, 전부 투명
- 수정 외 사용 프레임: 153개, 원본과 픽셀 동일
- 안전 여백: 184개 모두 바깥 4px 불투명 픽셀 0

행과 열 번호는 모두 0부터 시작한다. 행 이름은 `idle=0 / walk=1 / jump=2 / fall=3 / attack=4 / shield=5 / hurt=6`이다.

## 전체 검토 결과

아래 표는 확대 검토에서 실제로 발견한 항목 전부다. `high`는 플레이 중에도 보이는 직선 잘림 또는 큰 이웃 조각, `medium`은 애니메이션에서 읽히는 작은 잘림·조각·여백 위반, `low`는 확대해야 주로 보이는 항목이다. 모든 high/medium과 함께 같은 원인의 low 항목도 수정했다. 미수정 이슈는 없다.

| 시트 | 행 | 열 | 유형 | 설명 | 심각도 | 처리 |
|---|---|---:|---|---|---|---|
| Frey | attack | 2 | cut | 수평 검 궤적 끝이 직선으로 끊김 | high | 기존 검을 보존하고 끝을 짧은 테이퍼로 정리 |
| Frey | attack | 3 | fragment | 셀 왼쪽에 이전 검격 초승달 조각이 남음 | high | 조각 제거, 회수 자세 재중앙 |
| Nova male | attack | 2 | cut | 청록/금색 펀치 효과 오른쪽이 수직 절단 | high | 소형 테이퍼 충격 효과로 교체 |
| Nova female | attack | 2 | cut | 청록/금색 펀치 효과 오른쪽이 수직 절단 | high | 소형 테이퍼 충격 효과로 교체 |
| Nova female | attack | 3 | fragment | 이전 프레임 충격 효과의 왼쪽 절반이 잔류 | high | 분리 성분 제거 |
| Luna | attack | 1 | cut | 지팡이 앞 대형 결계가 오른쪽에서 절단 | high | 별 지팡이는 유지하고 잘린 대형 결계만 제거 |
| Luna | attack | 2 | fragment | 왼쪽에 이전 결계의 세로 조각 | medium | 조각 제거, 기존 하단 별 궤적 유지 |
| Luna | attack | 3 | fragment | 왼쪽에 이전 궤적의 초승달 조각 | medium | 조각 제거 |
| Brave Luna | attack | 1 | cut | 주먹 앞 청보라 효과가 수직 절단 | high | 큰 효과 제거, 주먹 자세 유지 |
| Brave Luna | attack | 2 | fragment | 왼쪽에 이전 별 폭발 조각 | medium | 조각 제거 |
| Brave Luna | attack | 3 | cut/fragment | 양쪽에 이웃 효과 조각, 오른쪽 효과는 직선 절단 | high | 양쪽 조각 제거 후 작은 테이퍼 별 초승달로 교체 |
| Rio male | jump | 0 | cut | 검 끝이 x=124까지 닿아 4px 여백 위반 | medium | 4px 안쪽으로 축소·재중앙 |
| Rio male | attack | 0 | fragment | 오른쪽에 이웃 망토 조각 | medium | 본체/검 성분만 보존 |
| Rio male | attack | 1 | fragment | 큰 검격 오른쪽에 이웃 망토 조각, x=125 | high | 망토 조각 제거, 검격 테이퍼 유지 |
| Rio male | attack | 2 | fragment | 검격 오른쪽에 128px 규모의 이웃 조각, x=125 | high | 분리 조각 제거 |
| Rio male | attack | 3 | fragment | 회수 프레임의 작은 분리 픽셀과 x=125 여백 위반 | medium | 분리 성분 제거·재중앙 |
| Rio male | shield | 2 | fragment | 왼쪽에 좁은 세로 방패 잔상, x=2 | medium | 좁은 분리 성분 제거 |
| Rio male | shield | 3 | fragment | 왼쪽에 좁은 세로 방패 잔상, x=2 | medium | 좁은 분리 성분 제거 |
| Rio male | shield | 4 | fragment | 왼쪽에 작은 방패 잔상, x=3 | medium | 좁은 분리 성분 제거 |
| Rio male | shield | 5 | fragment | 왼쪽에 작은 방패 잔상, x=3 | medium | 좁은 분리 성분 제거 |
| Rio female | jump | 0 | cut | 검 끝이 x=124까지 닿아 4px 여백 위반 | medium | 4px 안쪽으로 축소·재중앙 |
| Rio female | attack | 0 | pose/fragment | 위쪽 검날이 손잡이와 분리되고 오른쪽 잔상 존재 | high | 검날 보존·손잡이 연결, 이웃 조각 제거 |
| Rio female | attack | 1 | fragment | 오른쪽에 이웃 망토 조각, x=125 | high | 본체/검격 성분만 보존 |
| Rio female | attack | 2 | fragment | 오른쪽에 214px 망토 조각과 작은 잔상, x=125 | high | 분리 성분 제거 |
| Rio female | attack | 3 | cut | 검 끝이 x=125까지 닿음 | medium | 안전 여백 안으로 축소·재중앙 |
| Rio female | shield | 0 | fragment | 방패 주변의 작은 독립 광점 | low | 방패/본체 외 작은 성분 정리 |
| Rio female | shield | 1 | fragment | 다음 프레임에서 이어진 좁은 청록 잔상 | medium | 좁은 분리 성분 제거 |
| Rio female | shield | 2 | fragment | 왼쪽 세로 잔상과 x=2 여백 위반 | high | 세로 조각 제거 |
| Rio female | shield | 3 | fragment | 왼쪽 세로 잔상과 x=3 여백 위반 | high | 세로 조각 제거 |
| Rio female | shield | 4 | fragment | 반복되는 왼쪽 세로 방패 조각 | medium | 세로 조각 제거 |
| Rio female | shield | 5 | fragment | 반복되는 작은 왼쪽 방패 조각 | medium | 세로 조각 제거 |

그 밖의 153개 사용 프레임은 확대 육안 검토에서 cut/fragment/pose/design 문제가 없었다. Idle 4장은 각 시트에서 호흡·머리카락·망토 또는 손 위치가 서로 달랐고, walk 6장은 다리와 상체 진행이 순환 동작으로 읽혔다. Yuki의 직사각 결계와 Rio의 완성된 마름모 방패처럼 원래 직선형인 디자인은 셀 잘림으로 판정하지 않았다.

## 측정 결과

`frame_metrics_after.csv`에서 직접 읽은 값이다. 중심 범위는 모든 사용 프레임의 불투명 픽셀 중심이다. Idle 높이는 위·아래 불투명 경계를 포함한 픽셀 수다. `불투명 최하단`이 118/119인 일부 기존 프레임도 발 기준선은 y=120으로 유지되며, 이번에 수정한 31개 프레임은 모두 최하단 y=120이다.

| 시트 | 발 기준선 | 불투명 최하단 범위 | 중심 x 범위 | idle 높이 4프레임 | 목표 |
|---|---:|---|---|---|---:|
| Frey | 120 | 120 | 63.522–64.474 | 100 / 100 / 100 / 100 | 100 |
| Yuki | 120 | 120 | 63.535–64.475 | 88 / 88 / 88 / 88 | 88 |
| Luna | 120 | 118–120 | 63.365–64.616 | 83 / 82 / 84 / 83 | 84 |
| Brave Luna | 120 | 119–120 | 63.579–64.481 | 83 / 83 / 83 / 83 | 84 |
| Nova male | 120 | 120 | 63.667–64.457 | 92 / 92 / 92 / 92 | 92 |
| Nova female | 120 | 120 | 63.620–64.496 | 90 / 90 / 90 / 90 | 90 |
| Rio male | 120 | 119–120 | 63.199–64.430 | 97 / 96 / 96 / 96 | 98 |
| Rio female | 120 | 120 | 63.504–64.394 | 95 / 94 / 94 / 94 | 96 |

수정 전/후 전체 측정치는 각각 `frame_metrics_before.csv`, `frame_metrics_after.csv`에 있다.

## 시각적 확인

최종 4배 컨택트:

- [Frey](review_contacts_after/frey_review_4x.png)
- [Yuki](review_contacts_after/yuki_review_4x.png)
- [Luna](review_contacts_after/luna_review_4x.png)
- [Brave Luna](review_contacts_after/luna_brave_review_4x.png)
- [Nova male](review_contacts_after/nova_male_review_4x.png)
- [Nova female](review_contacts_after/nova_female_review_4x.png)
- [Rio male](review_contacts_after/rio_male_review_4x.png)
- [Rio female](review_contacts_after/rio_female_review_4x.png)

수정 프레임 전/후 4배 비교(각 쌍에서 왼쪽=수정 전, 오른쪽=수정 후):

- [Frey](before_after/frey_before_after_4x.png)
- [Luna](before_after/luna_before_after_4x.png)
- [Brave Luna](before_after/luna_brave_before_after_4x.png)
- [Nova male](before_after/nova_male_before_after_4x.png)
- [Nova female](before_after/nova_female_before_after_4x.png)
- [Rio male](before_after/rio_male_before_after_4x.png)
- [Rio female](before_after/rio_female_before_after_4x.png)

비교판의 프레임 순서는 `before_after/index.csv`에 기록했다. `sprite_effect_fix_source.png`는 built-in ImageGen으로 만든 4행×4열 소형 효과 원본이며, Nova와 Brave Luna의 잘린 큰 효과를 교체할 때만 일부를 최근접 축소·이진 알파·제한 팔레트로 정리해 사용했다.

## 수정 방식

- 원본 시트를 `original_sheets/`에 보존하고 항상 이 스냅샷에서 다시 빌드해 반복 실행에 따른 열화를 막았다.
- Godot `Image` API로 셀 격리, 연결 성분 분석, 좁은 세로 조각 제거, 최근접 축소, 발선/중심 정렬, 알파 정리를 수행했다.
- 대형 잘림 효과는 삭제하거나 작은 자연 테이퍼 효과로 바꿨다. 캐릭터 본체, 의상, 머리, 기존 일러스트와 얼굴은 변경하지 않았다.
- 생성 도구와 최종 프롬프트는 [PROMPTS.md](PROMPTS.md)에 기록했다.

## 확인 및 테스트

- `apply_fixes.gd`: `SPRITE_FIX_A_APPLY_OK sheets=7 changed_frames=31 unchanged_frames_pixel_identical=true`
- `verify_fixes.gd`: `RESULT PASS`
  - 사용 프레임 184, 미사용 셀 152, 수정 프레임 31
  - 4px 안전 여백 위반 0
  - 수정 대상 외 프레임 픽셀 동일
  - 모든 수정 프레임 최하단 y=120
- 기존 `hires_a/sheet_audit.gd`: 8장 모두 `edge_px=0`, `fringe_px=0`, `stray_px=0`
- Godot의 `Failed to read the root certificate store` 한 줄은 카드에 명시된 샌드박스 잡음이다. 그 외 최종 실행의 `SCRIPT ERROR`, `Parse Error`, 추가 `ERROR`는 없었다.

세부 로그는 `verification.txt`에 있다.

## 리드 통합 메모

- 교체 파일은 기존 파일명과 규격을 유지한다. 수정된 시트는 Frey, Luna, Brave Luna, Nova 남/여, Rio 남/여의 7장이다. Yuki는 변경하지 않았다.
- `.import` 파일은 경로와 import 설정이 바뀌지 않아 수정하지 않았다. 리드 환경에서 PNG 재import만 수행하면 된다.
- 제품 소스, 캐릭터 로직, 씬, 기존 테스트는 수정하지 않았다.
- `apply_fixes.gd`는 보고서의 `original_sheets/`와 `sprite_effect_fix_source.png`를 입력으로 사용하므로 재현 가능하다.

## 사람이 판단해야 하는 부분

- Frey attack 2의 짧아진 thrust 테이퍼가 실제 공격 타이밍에서 충분히 검으로 읽히는지.
- Nova 남/여의 소형 청록 충격 효과가 1배에서 너무 약하거나 투사체처럼 보이지 않는지.
- Luna attack 1에서 큰 결계를 제거하고 별 지팡이만 남긴 것이 동작 전달에 적절한지.
- Brave Luna attack 3의 작은 별 초승달 위치가 손 동작과 자연스럽게 이어지는지.
- Rio 여성 attack 0의 위쪽 검날과 새로 연결한 손잡이 선이 연속 재생에서 자연스러운지.
- 정지 확대가 아닌 실제 게임 속도에서 attack/shield 루프의 리듬이 좋은지.

## 하지 않은 작업

- 제품 코드 연결, 캐릭터 판정, 씬, 게임 밸런스는 범위 밖이라 수정하지 않았다.
- 다른 빌더가 동시에 창 실행 작업을 수행할 수 있어 실제 게임 창 캡처는 실행하지 않았다. 대신 184개 프레임의 4배 컨택트와 31개 전/후 비교판을 제공했다.
- `.git`이 쓰기 불가이므로 직접 커밋하지 않고 `commit.ps1`을 준비했다.

