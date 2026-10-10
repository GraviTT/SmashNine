# CODEX-ART-28 결과 보고

## 완료 범위

- **Part 1 완료:** `frey_moves_sheet.png`의 `descent` 3–5번과 `spike_followup` 4번, 총 4셀을 다시 그렸다. 최종 시트는 768×1024, 셀은 128×128이며 발 기준 y=120과 중앙 여백을 유지했다.
- **Part 2 완료:** `frey`, `luna`, `luna_brave`, `nova`, `rio`, `yuki` 전용 피격 스파크 6종을 만들고 연결했다. 각 파일은 384×96 RGBA8, 96×96 4프레임, hard alpha이다.
- **Part 3 완료:** 전투원 자식 `StatusIcon`을 추가해 슈퍼아머와 명시적 스턴 공격/위험물의 지속 시간 동안 ART-25의 24×24 아이콘을 표시한다. 실드 브레이크 게임 상태는 현재 `PlayerBase`에 존재하지 않아 아이콘 조건을 새로 만들지 않았다.

## 변경 파일과 연결

- `assets/art/frey/frey_moves_sheet.png`, `assets/art/frey/README.md`
- `assets/art/effects/hit/<id>_hit.png`와 `<id>_hit_source.png` 6쌍, `assets/art/effects/README.md`
- `characters/common/PlayerBase.gd`
  - `_spawn_hit_effect`: 공격자 ID로 전용 스트립을 고르고, Brave Luna는 기존 `attack_effect_name()`의 상태를 사용한다. 파일이 없으면 공통 `hit_spark.png`로 돌아간다.
  - `_play_stun_effect`, `_create_status_icon`, `_update_status_icon`: 기존 `***` 텍스트 대신 스턴/슈퍼아머 아이콘을 1x로 표시하고 ±2px bob을 적용한다. 중심 y=-121이므로 가장 낮을 때도 y=-105의 이름표보다 1px 이상 위에 있다.
  - 피해량, 판정, 넉백, 입력, 타이밍, 매치 규칙, AI는 변경하지 않았다.
- `tests/test_hit_sparks.gd`: 6종 선택, Brave 상태, 없는 ID fallback, 4프레임/크기/알파, 상태 아이콘과 UI 비겹침을 검사한다.
- `tests/art_preview/fx_28/build_assets.gd`: ImageGen 원본을 확대 없이 최근접 축소하고 정확한 그리드/투명도/팔레트로 만든다.

## ImageGen 사용

- 방식: 내장 ImageGen, 투명 배경.
- Frey 최종 프롬프트 요약: 기존 move/base 시트를 디자인과 체급 참조로 고정하고, 얼굴과 검 방향이 보이는 하강 3단계와 낮은 후속 찍기 1개를 한 행의 네 포즈로 생성. 1차 3포즈 후보 뒤 2차에서 포즈 수만 4개로 보완했다.
- 스파크 공통 프롬프트 요약: 공통 스파크를 타이밍 참조로, 각 캐릭터의 slash/L VFX를 색·모티프 참조로 사용해 `접촉 → 최대 폭발 → 분리 광선 → 잔광` 네 프레임을 생성했다. 캐릭터별 1회 생성 후 모두 채택했다.
- 보관 위치: `tests/art_preview/fx_28/*_source.png`, `assets/art/effects/hit/*_source.png`.

## 시각 자료

- `tests/art_preview/fx_28/frey_before_after_4x.png`: 위 행이 수정 전, 아래 행이 수정 후인 4셀 비교.
- `tests/art_preview/fx_28/hit_sparks_contact_4x.png`: 위에서부터 Frey, Luna, Brave Luna, Nova, Rio, Yuki의 4프레임 진행.

아래 행의 Frey는 기존 작은/뒤보기 실루엣보다 얼굴과 검 방향이 분명하며, 스파크는 금청·분홍청록·청록금·보라결정·빙결부적 모티프로 공격자를 구분한다.

## 확인 및 테스트

- `build_assets.gd`: 통과, Frey 4셀 + 피격 스파크 6종 생성.
- `edge_audit.gd`: `frey_moves_sheet.png edge-touching: 0`.
- `--headless --import`: 최종 재실행 통과. 신규 PNG의 `.import` 파일 생성 확인.
- `test_hit_sparks.gd`: 통과.
- `run_all.ps1 -SkipSoak`와 같은 25개 기존 테스트 + 신규 테스트를 고유 로그로 각각 실행: **26/26 통과**.
- 모든 Godot 실행의 `Failed to read the root certificate store` 한 줄은 안내된 샌드박스 잡음으로 분리했다. 그 밖의 `ERROR`, `SCRIPT ERROR`, `Parse Error`는 최종 실행에 없다.

## 사람이 판단할 부분

- Frey의 새 하강 후반 두 포즈가 실제 게임 속도에서 충분히 같은 체급으로 이어지는지, 금색 충돌선의 강조가 과하지 않은지.
- 6종 스파크가 additive가 아닌 현재 재생 방식에서도 난전 중 공격자 정체성을 충분히 구분하는지.
- 상태 아이콘의 y=-121 위치와 ±2px bob이 여러 전투원이 겹칠 때도 이름/HP보다 잘 읽히는지.

## 남은 작업 / 하지 못한 것

- 선택 사항인 캐릭터별 strong-hit 별도 스트립은 55분 제한 안에서 필수 3개 Part를 우선해 만들지 않았다.
- 실드 브레이크는 대응하는 게임 상태가 없어 연결하지 않았다. 시각 효과를 위해 새 게임 규칙을 만들지 않았다.
- 동시 빌더 규칙에 따라 창 실행/실매치 캡처와 soak는 하지 않았다. 최종 미감 판단은 리드의 실제 게임 화면 검수가 필요하다.
