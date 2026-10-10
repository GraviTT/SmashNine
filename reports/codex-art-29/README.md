# CODEX-ART-29 결과 보고

## 완료

Nova, Yuki, Rio의 전용 무브 시트 행을 런타임 포즈 호출에 연결했다. 각 캐릭터는 8행을 사용하며 Nova와 Rio는 남녀 바디가 같은 행 표를 공유한다. 전투 수치, 판정, 입력, 타이밍, 봇 로직은 변경하지 않았다.

이번 카드는 배선 전용(`No art this time`)이므로 PNG를 생성하거나 수정하지 않았다. 병렬 ART-26 유닛의 시트가 합쳐지면 아래 규격으로 즉시 로드된다.

- 시트: 캐릭터/바디별 `768×1024` RGBA PNG
- 격자: 6열 × 8행, 셀당 `128×128`
- 연결 행: Nova 8개, Yuki 8개, Rio 8개(총 24개)

## Part 1 — 행 표

- `characters/nova/Nova.gd`: `vector_side`부터 `slingshot_start`까지 8행
- `characters/yuki/Yuki.gd`: `talisman_side`부터 `grand_ward`까지 8행
- `characters/rio/Rio.gd`: `mana_combo`부터 `infinity_overdrive`까지 8행
- 세 파일에 `get_move_sheet_rows()`를 추가해 공통 로더에 표를 제공한다.

## Part 2 — 기술 포즈 연결

- 기본 공격, 공중 공격, K/L 기술, 궁극기 시작 포즈를 각 전용 행으로 연결했다.
- Rio의 3타 콤보는 `mana_combo`의 `0–1`, `2–3`, `4–5` 프레임을 순서대로 사용한다.
- 시트가 없을 때는 기존 공통 시트 포즈를 유지한다. Nova `vector_shift`는 `jump`, Rio `rune_shield`는 `shield`, 나머지는 `attack`으로 폴백한다.

```text
입력/기술 시작
      ↓
전용 행 애니메이션 존재?
   ┌──┴──┐
  예     아니오
   ↓       ↓
무브 행   기존 attack/jump/shield 행
```

위 흐름은 새 시트가 아직 없는 현재 클론에서도 기존 화면이 깨지지 않고, ART-26 시트가 합쳐진 뒤에는 별도 코드 변경 없이 전용 포즈가 선택되는 구조를 보여 준다.

## Part 3 — 회귀 테스트

`tests/test_moves_sheet.gd`에 `768×1024` 메모리 임시 시트를 추가해 실제 병렬 아트 파일에 의존하지 않도록 했다.

- 24개 행이 모두 올바른 프레임 수로 등록되는지 확인
- 24개 행 각각을 실제 기술 호출이 선택하는지 확인
- 24개 행 각각이 시트 부재 시 기존 포즈로 폴백하는지 확인
- 실제 ART-26 파일이 나중에 들어와도 테스트가 그 파일을 우연히 사용하는 것을 막기 위해 누락 경로 override 후 메모리 시트를 직접 주입

## 확인 및 테스트

- `git diff --check`: 통과
- `tests/test_moves_sheet.gd`: 통과
- `tests/run_all.ps1 -SkipSoak`: 래퍼의 중첩 PowerShell이 첫 Godot 실행 전에 정지하여 중단
- 동일한 27개 테스트 목록을 headless Godot로 직접 실행하고 테스트별 고유 로그를 지정: **전부 통과**
- 전체 매치 soak: 카드 지침에 따라 실행하지 않음

Godot 출력에는 알려진 샌드박스 노이즈 `Failed to read the root certificate store`만 있었다. 그 외 `ERROR`, `SCRIPT ERROR`, `Parse Error`는 없었다.

## 현재 상태

코드 및 자동 테스트 기준으로 배선과 폴백은 완료됐다. 이 클론에는 ART-26의 실제 Nova/Yuki/Rio 무브 시트가 아직 없으므로 실제 픽셀 아트가 게임 화면에서 재생되는 모습은 확인하지 못했다.

## 사람이 판단할 항목

ART-26 시트 병합 후 게임 속도로 다음 미적 항목을 확인해야 한다.

- Nova: `vector_upper`의 중력 입자, `meteor_kick` 불꽃, `slingshot_start` 코어 간격
- Yuki: `seal_activate`와 `grand_ward`의 효과 밀도 및 부적 장식 가독성
- Rio: `dimension_slash`의 몸이 사라지는 전환, 긴 궤적의 셀 경계, 여성형 포니테일 연속성, 6검 궁극기 밀도

이는 측정된 오류가 아니라 README에 기록된 미감 검토 대상이며 최종 채택은 사용자 판단이다.

## 남은 작업 / 다음 권장 단계

1. ART-26 결과를 병합한다.
2. 실제 남녀 Nova/Rio 및 Yuki 시트로 짧은 창 모드 캡처를 실행한다.
3. 각 24행의 실게임 속도, 발 위치, 셀 경계 잘림을 사람이 확인한다.

