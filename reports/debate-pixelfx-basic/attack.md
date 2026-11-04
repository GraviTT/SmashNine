리드안의 **기존 Codex 원화 유지·pixelfx 여운 추가·종류별 비교**는 타당합니다. 다만 아래 5곳은 보완해야 합니다. 기준 커밋 `0ec77253`을 확인했으며, 파일 수정이나 실행 테스트는 하지 않았습니다.

- **D1 — S5는 ‘적중 한 번당 누가 생성하는가’부터 정해야 합니다.** 공통 적중 함수에 덧붙이면 중복되고, 공격자 콜백에만 붙이면 일부 투사체가 빠집니다.  
  **근거:** [Attack.gd:163](C:/Users/TH/Documents/AI/GameProject/SmashNine/smash-nine-prototype/scripts/Attack.gd:163)은 피해자 처리 후 공격자 콜백도 호출합니다. 양쪽 모두 `_spawn_hit_effect`를 호출하며, Rio 검기는 공격자 콜백을 생략합니다([SKILLS.md:21](C:/Users/TH/Documents/AI/GameProject/SmashNine/design/SKILLS.md:21)).  
  **소유·수정:** 적중 이벤트와 `PlayerBase`의 표시 경로가 소유합니다. 새 여운의 생성 책임을 한 곳으로 정해야 하며, 작은 그림·짧은 수명으로 중복을 가리는 것은 다른 계층의 결함을 보상하는 방식입니다.  
  **훼손 기준:** ① 가독성·⑤ 성능. **반증:** 근접·투사체·몬스터 적중 각각에서 새 여운이 성공한 적중당 정확히 한 번 발생하고, 빗나감·패리에서는 발생하지 않는 기록.

- **D2 — 기존 벤치를 그대로 쓰면 ‘현재판 대 후보’가 아니라 ‘채택 전 대 후보’를 심사합니다.** 최신 기준선 확인이 제작보다 먼저입니다.  
  **근거:** [motions.mjs:127](C:/Users/TH/Documents/AI/GameProject/SmashNine/reports/pixelfx-eval-2026-11-03/motions.mjs:127)의 Luna NOW는 별이 없고, [177행](C:/Users/TH/Documents/AI/GameProject/SmashNine/reports/pixelfx-eval-2026-11-03/motions.mjs:177)은 이전 먼지를 재생합니다. 현재 게임은 v3 별·9프레임 먼지이며([Vfx.gd:117](C:/Users/TH/Documents/AI/GameProject/SmashNine/smash-nine-prototype/scripts/Vfx.gd:117)), 먼지 재생도 한 걸음에 맞춥니다([PlayerBase.gd:2527](C:/Users/TH/Documents/AI/GameProject/SmashNine/smash-nine-prototype/characters/common/PlayerBase.gd:2527)).  
  **소유·수정:** 비교 벤치·뷰어가 최신 시트와 재생 계약을 반영해야 합니다. 게임 효과를 옛 벤치에 맞추는 수정은 잘못된 보상입니다.  
  **훼손 기준:** ① 실제 경기 판단·② 사용자 판정·④ 재심사 비용. **반증:** NOW가 현재 게임과 같은 시트·발생 시점·수명·착지 분기를 재현한다는 대조 결과.

- **D3 — S1을 ‘공용 베기 옆 생성’으로 통일하는 연결안은 모든 J를 포괄하지 못합니다.** 분류는 공통화하되 발생 위치와 시점은 기술별 소유권을 유지해야 합니다.  
  **근거:** Luna J는 별도 투사체를 만들고([Luna.gd:365](C:/Users/TH/Documents/AI/GameProject/SmashNine/smash-nine-prototype/characters/luna/Luna.gd:365)), Nova 벡터 타격은 공용 궤적을 의도적으로 끕니다([SKILLS.md:15](C:/Users/TH/Documents/AI/GameProject/SmashNine/design/SKILLS.md:15)). 프레임 효과 훅도 현재는 지상 이동 중에만 작동합니다([PlayerBase.gd:2521](C:/Users/TH/Documents/AI/GameProject/SmashNine/smash-nine-prototype/characters/common/PlayerBase.gd:2521)).  
  **소유·수정:** 발사 여운은 캐릭터의 발사 함수, 비행·전개 여운은 투사체, 적중은 적중 경로가 소유합니다. 리드가 그곳에 연결하고 `Vfx`는 재생을 맡아야 하며, 공용 베기를 다시 켜서 해결하면 D40 수정의 역행입니다.  
  **훼손 기준:** ① 동작 가독성·③ 캐릭터 차별성. **반증:** 여섯 형태의 지상·공중·방향별 J에 대해 실제 발생 함수와 연결 지점이 빠짐없이 매핑된 표.

- **D4 — 다섯 슬롯을 전 형태의 제작 의무로 삼기보다, 보강 필요 여부를 먼저 거르는 편이 낫습니다.** 특히 대기는 선택 항목이어야 합니다.  
  **근거:** [position.md:16](C:/Users/TH/Documents/AI/GameProject/SmashNine/reports/debate-pixelfx-basic/position.md:16)의 규칙대로면 최소 **신규 60후보·90경기**, 슬롯당 한 번에 18경기입니다. 사용자는 항목 과다로 기존 뷰어가 복잡해졌다고 했고([question.md:30](C:/Users/TH/Documents/AI/GameProject/SmashNine/reports/debate-pixelfx-basic/question.md:30)), 전 형태 대기 효과의 필요성은 아직 검증되지 않았습니다.  
  **소유·수정:** 리드의 작업 목록·심사 배치가 소유합니다. 슬롯은 점검표로 유지하고 필요 항목만 2~3개씩 제작·심사하는 대안입니다. UI를 단순화하는 것만으로 제작량 문제를 보상해서는 안 됩니다.  
  **훼손 기준:** ④ 비용; 불필요한 장식의 ① 영향은 **argument only**입니다. **반증:** 실제 소규모 심사에서 전 슬롯의 개선 필요성과 18경기 연속 심사의 부담 허용이 확인되는 경우.

- **D5 — ‘배치당 몇 ms 이하’는 최종 웹 성능의 합격 기준이 될 수 없습니다.** 누적된 전체 효과의 절대 프레임 시간도 제한해야 합니다.  
  **근거:** [position.md:20](C:/Users/TH/Documents/AI/GameProject/SmashNine/reports/debate-pixelfx-basic/position.md:20)은 배치별 증가량만 제시합니다. 예컨대 각 배치가 2ms씩 늘면 다섯 배치가 10ms를 소비합니다. 이는 **argument only인 예시**이며 실제 측정값은 아닙니다.  
  **소유·수정:** 웹 성능 검증 절차가 기준선과 누적 p95/p99·최대 활성 효과를 관리해야 합니다. 초과 원인을 생성 빈도·동시 수·텍스처 등에서 찾아 해당 소유 컴포넌트를 고쳐야 하며, 측정 없이 원화를 약하게 만드는 것은 보상에 불과합니다.  
  **훼손 기준:** ⑤ 웹 성능. **반증:** 동일 기기·브라우저·경기 조건에서 전체 채택 효과를 켠 결과가 사전에 정한 프레임 예산을 충족하는 기록.

블라인드안과 비교하면, **최신 채택분 검증부터 시작하고 필요한 항목을 작게 묶는 쪽은 블라인드안이 더 낫습니다.** 반면 제가 제안한 ‘S5 전체를 S1보다 먼저’와 ‘방어·패리 보강’까지 우선할 근거는 부족합니다. Frey의 S1과 S5를 함께 시험해 중첩을 확인한 뒤 순서를 정하는 편이 낫습니다. 제작자도 두 명이면 다양성이 보장되지는 않지만, 제 ‘리드만 pixelfx 작성’ 역시 비교 근거가 없으므로 한 항목에서 품질·수정 횟수·비용을 비교한 뒤 정해야 합니다.