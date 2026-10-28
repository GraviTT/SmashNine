# ART-91 행별 전달 기록

목록 완료: 2026-10-28 14:46 KST. 이 파일과 commit-paths.txt는 카드 지시대로 새 기록을 추가한다. 기존 자산은 덮어쓰지 않는다.

|시간|ID|행|PNG|프레임|검사|비고|
|---|---|---|---|---:|---|---|
|2026-10-28T14:51:26.830564+09:00|alfheim_moon_moth|appear|art/bakeoff/monsters/alfheim_moon_moth-appear-v1.png|6|PASS: 정적 규격·크기 지표 + 육안|접힌 날개와 더듬이를 펼쳐 부유 준비 자세로 전환. 밝은 머리 연결영역 제곱근 크기 idle 대비 0.998~1.013, 중심 y49.5 유지. 4~6번 정착 동작은 작음(육안); 색·정체성 일치, 이펙트 없음. 전체 해부 크기 정밀 측정은 아님.|
|2026-10-28 14:54 KST|alfheim_moon_stag|appear|not delivered|6|FAIL visual identity|See failed-rows.md; 2 generations.|
|2026-10-28T14:59:23.488387+09:00|asgard_aegis_ram|appear|not delivered|6|HOLD size verification|See failed-rows.md.|
|2026-10-28T15:06:31.098601+09:00|asgard_runic_raven|appear|art/bakeoff/monsters/asgard_runic_raven-appear-v1.png|6|PASS: 정적 규격·크기 지표 + 육안|접은 날개를 펼쳐 부유 준비 자세로 전환. 문양 전체 금색 고리의 반경 중앙값은 idle 대비 0.986~1.040배, 부유 중심 y50 유지. 날개 여백을 위해 몸 전체 x를 기준보다 2.5px 오른쪽 정렬. 최소 여백5px·spill0. 문양은 대표 크기 지표이며 해부 전체 정밀 보장은 아님.|
|2026-10-28T15:12:54.821105+09:00|ember_imp|appear|art/bakeoff/monsters/ember_imp-appear-v1.png|6|PASS: 정적 규격·크기 지표 + 육안|낮게 웅크린 뒤 다리를 펴 준비 자세로 일어남. 눈높이 붉은 얼굴 폭을 수동 표식으로 비교한 명목 크기는 idle 대비 0.969~1.039배(원본 끝점 약 ±3px, idle ±1px 불확실성). 여백6px 이상, 발 하단 y72. 머리 불꽃·꼬리는 몸 일부이며 별도 효과 없음. 5번에서 약간 크게 일어선 뒤 6번에 정착(육안).|
|2026-10-28T15:21:07.068287+09:00|jotunheim_rune_golem|appear|art/bakeoff/monsters/jotunheim_rune_golem-appear-v1.png|6|PASS: 정적 규격·크기 지표 + 육안|접힌 바위 몸을 앞주먹으로 받치며 일으켜 준비 자세로 전환. 눈높이 돌 얼굴 폭 수동 명목 크기 0.989~1.011배(원본 ±3px, idle ±1px). 발 하단 y72·최소 여백4px. 첫 생성의 F5 경계 접촉을 재생성으로 해결. 둘째 프레임은 앞팔을 조금 넓게 짚음(육안).|
|2026-10-28T15:30:04.359600+09:00|ember_imp|appear|WITHDRAWN to raw|6|FAIL spill 8 total|Earlier delivery superseded; removed from commit manifest. No existing game or pre-task candidate changed.|
|2026-10-28T15:31:01.767166+09:00|jotunheim_storm_wisp|appear|art/bakeoff/monsters/jotunheim_storm_wisp-appear-v1.png|6|PASS: 정적 규격·크기 지표 + 육안|접힌 룬판이 열리며 중심핵이 드러나는 등장. 상단 타원석 장축 명목 크기 idle 대비 0.985~1.026배(수동 원본 끝점 약 ±3px). 몸 전체 이동으로 핵 중심 (47,44)에 정렬, 추정 y43.63~44.31. 표준 despill auto 후 spill0·알파 불변. 4~6번 정착 변화는 작음(육안).|
|2026-10-28T15:33:57.672576+09:00|ember_imp|appear|art/bakeoff/monsters/ember_imp-appear-v1.png|6|PASS: 정적 규격·크기 지표 + 육안|재검사 통과: 표준 despill auto로 8개 번짐 판정 픽셀 제거, 전 프레임 spill0·알파 불변. 낮은 웅크림에서 준비 자세로 일어남. 눈높이 얼굴 폭 수동 명목 크기 idle 대비 0.969~1.039배(원본 ±3px, idle ±1px). 여백6px 이상·발 하단 y72. 이전 회수본은 raw 보존; 이번 파일이 최종 후보.|
|2026-10-28T15:35:38.662293+09:00|niflheim_frost_owl|appear|art/bakeoff/monsters/niflheim_frost_owl-appear-v1.png|6|PASS: 정적 규격·크기 지표 + 육안|웅크린 자세에서 일어나 날개를 느슨하게 펼친 뒤 준비 자세로 정착. 깃 장식 제외 뒤통수~부리 밑동 축 수동 명목 크기 0.990~1.021배(원본 ±3px, idle ±1px). 발 하단 y72·최소 여백12px·표준 despill 후 spill0. 4~5번 날개가 기준보다 옆으로 펼쳐짐(육안).|
|2026-10-28T15:40:53.282129+09:00|svartalfheim_cog_drone|appear|art/bakeoff/monsters/svartalfheim_cog_drone-appear-v1.png|6|PASS: 정적 규격·크기 지표 + 육안|접힌 하부 집게·안정판을 펼쳐 부유 준비 자세로 전환. 상부 회색 외피 중간 높이 가로폭 수동 명목 크기 0.954~1.026배(원본 ±3px, idle ±1px). 전면 렌즈 y40 부유 높이에 정렬, x는 여백 때문에 기준보다 약2px 오른쪽. 최소 여백5px·spill0. 마지막 집게가 idle보다 조금 열려 있음(육안).|
|2026-10-28T15:48:15.789420+09:00|svartalfheim_gear_beetle|appear|art/bakeoff/monsters/svartalfheim_gear_beetle-appear-v1.png|6|PASS: 정적 규격·크기 지표 + 육안|다리를 접은 낮은 몸에서 관절을 펴 준비 자세로 올라옴. 상부 외피의 금색 테두리 포함 뒤~앞 축 수동 명목 크기 0.988~1.019배(원본 ±3px, idle ±1px). 발 하단 y72·최소 여백8px·표준 despill 후 spill0·알파 불변. 마지막 두 자세 변화는 작음(육안).|
