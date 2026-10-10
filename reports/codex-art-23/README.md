# CODEX-ART-23 · 기술별 스프라이트 행 수정 라운드 + Rio v2 + tumble

## 완료 범위

- **Part 1/2 수정 완료:** 생성 원본의 고정 폭 분할을 제거하고 Frey/Luna/Brave Luna의 모든
  프레임을 자기 연결 성분(몸+무기+해당 효과) 바운드로 재추출했다.
- **Part 3 완료:** Rio 남/여 공격 4프레임·방어 6프레임을 idle 체급으로 다시 만든 후보 시트를
  프리뷰 경로에 저장했다. 라이브 Rio 시트는 바꾸지 않았다. 지시대로 제안 표는 생략했다.
- **Part 4 완료:** 세 move sheet에 4프레임 `tumble` 행을 추가하고, 강한 발사 피격 때만 재생한
  뒤 해당 행이 없는 캐릭터는 기존 `hurt`로 폴백하도록 연결했다.

## 수정 원인과 방식

이전 빌더는 생성 캔버스를 행/열의 고정 폭으로 나눈 뒤 각 조각을 128×128로 축소했다. 생성
포즈의 간격은 균등하지 않아 Frey `r1c2 R60 / r1c3 L60`처럼 같은 칼·효과가 인접 셀 양쪽에
나뉘었다. `rebuild_safe_sheets.gd`는 다음 순서로 다시 만든다.

1. 생성 원본 전체에서 8방향 연결 성분을 찾고, 큰 몸 성분 92개를 행별 y·프레임별 x로 정렬한다.
2. 82px 안의 별·먼지·궤적 성분을 가장 가까운 몸 성분에 귀속한다.
3. 각 프레임의 독립 바운드만 추출한다. 기준 시트와 같은 배율로 몸의 조밀한 중심 띠를 유지하고,
   122×119 안전 영역을 넘는 바깥 효과 띠만 압축한다.
4. nearest, 하드 알파, 3px 미만 찌꺼기 제거, 액션 발 y=120, 셀 중앙 배치를 적용한다.

따라서 몸·칼을 셀 경계에서 직선으로 자르지 않고, 모든 셀에 최소 여백이 남는다. 몸 중심 띠는
idle 기준 크기(Frey 87×100, Luna 92×82, Brave 95×83)를 ±4px 범위로 유지하도록 매핑했다.

## Part 1/2 결과

| 시트 | 이전 edge 셀 | 수정 후 | 최종 규격 | 사용 프레임 |
|---|---:|---:|---:|---:|
| `frey_moves_sheet.png` | 20 | **0** | 768×1024, 8행 | 35 |
| `luna_moves_sheet.png` | 19 | **0** | 768×768, 6행 | 27 |
| `luna_brave_moves_sheet.png` | 12 | **0** | 768×1152, 9행 | 42 |

총 104프레임이다. 미사용 셀은 완전 투명이고 부분 알파는 0이다. 액션 프레임의 최저 불투명
픽셀은 y=120이며, 공중 tumble은 셀 중심 회전을 위해 이 발 기준 검사를 적용하지 않는다.

### 다시 그린 프레임

- Frey `spike_followup` 3–4: 뒤통수/망토 덩어리 대신 검 끝이 아래를 향하고 얼굴이 보이는
  낙하·회수 실루엣으로 교체했다.
- Frey `descent` 3–4: 방패 선도 측면 자세와 검 선도 수직 하강으로 교체했다.
- Brave `brave_dive` 1–4: 무릎 접기 → 대각 킥 시작 → 부츠 선도 강타 → 착지 회수의 네
  실루엣을 새로 만들었다. 후반에도 얼굴과 차는 발이 분리된다.

재생성은 built-in ImageGen을 사용했다. Frey는 `frey_sheet.png` + `frey_illustration.png` + 기존
move source, Brave는 `luna_brave_sheet.png` + `luna_illustration.png` + 기존 move source를
레퍼런스로 사용했다. 최종 프롬프트의 핵심은 “원래 체급/픽셀 밀도/하드 알파 고정, 얼굴·무기·
차는 발이 1배에서 보이는 측면/3/4 포즈, 콤팩트한 효과, 뒤보기·겹침·잘림 금지”였다. 보존 원본:

- `tests/art_preview/moves_23/frey_redraw_source.png`
- `tests/art_preview/moves_23/luna_brave_dive_redraw_source.png`

## Part 3 · Rio v2 후보

| 파일 | 내용 | 상태 |
|---|---|---|
| `rio_male_sheet_v2.png` | idle 105×98 기준 공격 4 + 방어 6 | edge 0 |
| `rio_female_sheet_v2.png` | idle 101×96 기준 공격 4 + 방어 6 | edge 0 |
| `rio_v2_contact_{1x,4x}.png` | idle 옆에서 두 행 체급 비교 | 생성 완료 |

각 성별의 라이브 시트와 전신 일러스트를 ImageGen 레퍼런스로 사용했다. 프롬프트는 “idle과 같은
몸/머리 크기, 효과 때문에 몸을 줄이지 않음, 오른쪽 방향, 공격 4장과 룬 방어 6장, 콤팩트한
청록 검기·방벽, 겹침/잘림 없음”이었다. 원본은 `rio_{male,female}_v2_source.png`에 보존했다.
라이브 `assets/art/rio/rio_*_sheet.png`는 변경하지 않았다.

## Part 4 · tumble

- Frey/Luna/Brave move row table에 `tumble` 4프레임, 14fps loop를 추가했다.
- 기준 hurt 프레임을 nearest 0°/90°/180°/270°로 회전해 체급·팔레트·하드 알파를 그대로
  유지했다.
- `PlayerBase._play_launch_hit_sprite()`는 기존 강한 넉백 기준 `480` 이상이고 현재 형태의
  tumble 애니메이션이 있을 때만 이를 재생한다. 없으면 기존 `hurt`를 재생한다.
- `apply_hit()`과 `apply_forced_launch_hit()`의 시각 호출만 이 헬퍼로 바꿨다. 피해, 판정,
  넉백, hitstun 시간, 입력, 봇은 변경하지 않았다.

## 시각 자료

- `edge_fix_before_after_1x.png`: 리드가 지정한 51개 문제 셀을 **왼쪽 이전 / 오른쪽 수정**
  쌍으로 배치했다.
- `frey_moves_contact_{1x,4x}.png`
- `luna_moves_contact_{1x,4x}.png`
- `luna_brave_moves_contact_{1x,4x}.png`
- `rio_v2_contact_{1x,4x}.png`

각 move contact의 첫 열은 현재 idle이며, 그 오른쪽이 해당 행의 최종 프레임이다. 마지막 행은
tumble이다.

## 확인 및 테스트

| 실행 | 결과 |
|---|---|
| `edge_audit.gd` (3 move sheets) | **20/19/12 → 모두 0** |
| `edge_audit.gd` (Rio 남/여 후보) | 둘 다 **0** |
| `verify_moves.gd` | 통과: 3시트, 23행, 104프레임, hard alpha, unused 투명 |
| `--headless --import` | 알려진 root certificate ERROR 외 실패 오류 없음 |
| `test_moves_sheet.gd` | 통과: 전용 행/폴백 + Frey/Luna/Brave tumble/없는 시트 hurt 폴백 |
| `test_sprite_pose.gd` | 통과 |
| `test_frey_kit.gd` | 통과 |
| `test_luna_kit.gd` | 통과 |

Godot의 `ERROR: Failed to read the root certificate store.`는 카드에 명시된 샌드박스 소음으로
분리했다. 그 밖의 SCRIPT ERROR, Parse Error, ERROR는 최종 실행에 없었다. 창 실행과 소크는
카드 지시대로 하지 않았다.

## 사람이 판단할 것

- Frey의 새 수직 스파이크/하강 프레임에서 작은 얼굴과 검 방향이 실제 게임 속도에서도 충분히
  읽히는지
- Brave 새 dive 네 프레임의 1배 연결이 “회전”보다 “대각 킥”으로 보이는지
- overflow 효과 압축이 큰 Luna `star_up`/`transform`, Brave `heart_laser`의 박력을 지나치게
  줄이지 않았는지
- Rio 후보의 몸 크기는 idle과 맞지만, 새 공격 검기와 룬 방벽의 크기·밝기를 라이브로 채택할지
- quarter-turn tumble이 의도한 코믹한 회전 감각인지, 이후 손그림 중간각이 필요한지

## 현재 상태 / 남은 작업

- 완료: Part 1–4, 시트/프리뷰/배선/회귀 테스트/문서/커밋 스크립트.
- 현재 상태: headless 검증 통과, 라이브 창 확인은 미수행.
- 남은 작업: 리드가 Rio 후보 채택 여부와 행별 미술 취향을 결정하고, 필요하면 전체 테스트 러너에
  `test_moves_sheet.gd`를 추가한다.
