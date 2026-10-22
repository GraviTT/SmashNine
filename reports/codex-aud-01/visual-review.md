# 비교 그림과 관찰 범위

72개 ID마다 A/B/C 파형과 스펙트로그램을 한 장에 그렸다. 모든 PNG는 독립 검증기로 열어 규격과 디코딩을 확인했다. 파형은 고정 ±1, 시간은 해당 파일 길이, 스펙트로그램은 Hann 1024 / hop 128, 로그 60–22,050Hz와 고정 −80~0dBFS 색상이다.

## 직접 그림을 살핀 항목

아래는 눈으로 확인한 그림의 구조다. 직접 청음 결과가 아니며, 나머지 그림을 모두 수동 검수했다고 주장하지 않는다.

| 그림 | 관찰 |
|---|---|
| [음량 개요](loudness-overview.png) | 6그룹의 RMS 범위가 타격 −13.5부터 대사 −28까지 구분된다. 메뉴의 상단 −14는 기존 확인·취소 보존이다. |
| [프레이 K](skill_frey_1.png) | 하강 검 몸통·상단 종 선이 남는다. A는 반복 배음이 뚜렷하고 B/C는 초반 더 넓게 분포한다. |
| [루나 K](skill_luna_1.png) | 시간차로 들어오는 세 별 음의 수평선·상승선이 보인다. B는 뒤에서 단순한 선으로 모인다. |
| [유키 K](skill_yuki_1.png) | 초반 넓은 종이 마찰 뒤 방울 선이 남는다. 세 스타일 모두 마지막에 낮아지며 끝점은 0이다. |
| [노바 K](skill_nova_1.png) | 상승 서보와 하강 펄스 궤적이 겹친다. B의 초기 FM 띠가 조밀하다. |
| [리오 K](skill_rio_1.png) | 초반 대역 잡음과 두 룬 음, 낮은 검 몸통이 함께 이어진다. |
| [붕괴 경고](collapse_warning.png) | 세 개의 진폭 덩어리와 간격 감소가 보인다. 기본 에너지는 중저역이며 A에는 높은 배음 선도 있다. 청음상 날카로움 여부는 미판정이다. |

## 남은 시각·청음 확인

실제 청음 페이지 스크린샷은 없다. 브라우저 보안 승인 단계에서 `http://127.0.0.1:8077` 접근이 거부되어 렌더링을 확인하지 못했다. 모의 DOM 검사는 화면 캡처나 실제 WAV 디코딩을 대체하지 않는다. 사용자 청음에서는 특히 A 경고의 배음, 기존 확인·취소 음량, C 저역과 궁극기의 긴 꼬리를 판단해야 한다.

## 전체 그림 목록

마지막 열은 합성 코드에 기록한 **의도**다. 측정·청음 판정과 구별한다. 레코드별 실제 Peak·RMS·시작·꼬리·스펙트럼 지표는 measurements.json과 verification.json에 있다.

| 그룹 | 비교 그림 | 길이 s | 목표 RMS dBFS | 합성 의도 |
|---|---|---:|---:|---|
| Fighters | [swing_light](swing_light.png) | 0.160 | -15.0 | 짧은 바람과 내려가는 가는 검 궤적 |
| Fighters | [swing_heavy](swing_heavy.png) | 0.290 | -15.0 | 넓은 바람과 낮은 검 몸통 |
| Fighters | [hit_light](hit_light.png) | 0.180 | -13.5 | 짧은 잡음 타격·음정 몸통·저음 펄스를 겹친 아케이드 무게감 |
| Fighters | [hit_heavy](hit_heavy.png) | 0.340 | -13.5 | 짧은 잡음 타격·음정 몸통·저음 펄스를 겹친 아케이드 무게감 |
| Fighters | [hit_launch](hit_launch.png) | 0.380 | -13.5 | 타격 몸통 뒤 위로 튀는 발사 음정 |
| Fighters | [hurt](hurt.png) | 0.230 | -13.5 | 짧은 잡음 타격·음정 몸통·저음 펄스를 겹친 아케이드 무게감 |
| Fighters | [guard](guard.png) | 0.210 | -14.0 | 짧은 잡음 타격·음정 몸통·저음 펄스를 겹친 아케이드 무게감 |
| Fighters | [parry](parry.png) | 0.340 | -14.0 | 짧은 잡음 타격·음정 몸통·저음 펄스를 겹친 아케이드 무게감 |
| Fighters | [jump](jump.png) | 0.170 | -14.0 | 짧은 잡음 타격·음정 몸통·저음 펄스를 겹친 아케이드 무게감 |
| Fighters | [land](land.png) | 0.120 | -14.0 | 짧은 잡음 타격·음정 몸통·저음 펄스를 겹친 아케이드 무게감 |
| Fighters | [dash](dash.png) | 0.200 | -15.0 | 빠르게 솟는 공기와 짧은 추진 펄스 |
| Fighters | [tumble](tumble.png) | 0.280 | -14.0 | 내려가는 두 펄스의 회전 |
| Fighters | [ko](ko.png) | 0.780 | -16.0 | 짧은 잡음 타격·음정 몸통·저음 펄스를 겹친 아케이드 무게감 |
| Fighters | [respawn](respawn.png) | 0.540 | -16.0 | 올라오는 세 음과 열리는 빛 |
| Fighters | [swing](swing.png) | 0.210 | -15.0 | 짧은 잡음 타격·음정 몸통·저음 펄스를 겹친 아케이드 무게감 |
| Skills | [skill_frey_1](skill_frey_1.png) | 0.250 | -14.0 | 강철 검·날개 바람·금빛 종 |
| Skills | [skill_frey_2](skill_frey_2.png) | 0.340 | -14.0 | 위로 벼리는 검과 열린 날개 |
| Skills | [ult_frey](ult_frey.png) | 1.080 | -14.0 | 강철 호명·날개·두 번의 낮은 여진 |
| Skills | [skill_luna_1](skill_luna_1.png) | 0.280 | -14.0 | 상승 별방울과 작은 반짝임 |
| Skills | [skill_luna_2](skill_luna_2.png) | 0.360 | -14.0 | 두 방향으로 펼치는 부드러운 별 종 |
| Skills | [ult_luna](ult_luna.png) | 1.180 | -14.0 | 여섯 별방울의 상승과 변신의 빛 |
| Skills | [skill_luna_brave_1](skill_luna_brave_1.png) | 0.220 | -14.0 | 압축된 주먹 몸통과 낮은 별 폭발 |
| Skills | [skill_luna_brave_2](skill_luna_brave_2.png) | 0.340 | -14.0 | 회전 킥 두 펄스와 무거운 별 |
| Skills | [ult_luna_brave](ult_luna_brave.png) | 1.050 | -14.0 | 별 충전 후 굵어지는 펄스 광선 |
| Skills | [skill_yuki_1](skill_yuki_1.png) | 0.240 | -14.0 | 종이 넘김·부채 스냅·작은 방울 |
| Skills | [skill_yuki_2](skill_yuki_2.png) | 0.380 | -14.0 | 부채가 펼쳐지고 두 방울이 교차 |
| Skills | [ult_yuki](ult_yuki.png) | 1.120 | -14.0 | 세 번의 종이 봉인과 길게 남는 방울 |
| Skills | [skill_nova_1](skill_nova_1.png) | 0.230 | -14.0 | 서보 기어가 올라가며 짧은 에너지 추진 |
| Skills | [skill_nova_2](skill_nova_2.png) | 0.370 | -14.0 | 하강 서보와 세 번의 중력 펄스 |
| Skills | [ult_nova](ult_nova.png) | 1.160 | -14.0 | 고속 충전·중력 몸통·다중 에너지 펄스 |
| Skills | [skill_rio_1](skill_rio_1.png) | 0.260 | -14.0 | 룬의 두 음과 찢기는 차원·검 울림 |
| Skills | [skill_rio_2](skill_rio_2.png) | 0.360 | -14.0 | 역방향 룬 회전과 검 공명 |
| Skills | [ult_rio](ult_rio.png) | 1.100 | -14.0 | 엇갈린 룬 아르페지오·차원 절단·검 드론 |
| Skills | [skill_cast](skill_cast.png) | 0.240 | -15.0 | 특정 캐릭터에 치우치지 않은 상승 펄스 |
| Skills | [ult_start](ult_start.png) | 0.900 | -14.0 | 중립 충전과 넓어지는 두 공명 |
| Monsters | [monster_windup](monster_windup.png) | 0.160 | -18.0 | 공격음보다 짧은 낮은 두 박 예고 |
| Monsters | [monster_bite](monster_bite.png) | 0.180 | -14.0 | 닫히는 턱·짧은 이빨 스냅 |
| Monsters | [monster_charge](monster_charge.png) | 0.320 | -14.0 | 낮은 발굽 펄스와 전진 바람 |
| Monsters | [monster_leap](monster_leap.png) | 0.280 | -14.0 | 탄력 있는 위쪽 궤적 |
| Monsters | [monster_slam](monster_slam.png) | 0.390 | -13.5 | 깊은 지면 타격과 돌 파편 |
| Monsters | [monster_shell](monster_shell.png) | 0.350 | -14.0 | 단단한 껍질이 세 번 구르는 공명 |
| Monsters | [monster_bolt](monster_bolt.png) | 0.190 | -14.0 | 좁은 고속 에너지 하강 |
| Monsters | [monster_lob](monster_lob.png) | 0.310 | -14.0 | 먼저 올랐다 내려오는 투척 곡선 |
| Monsters | [monster_swoop](monster_swoop.png) | 0.330 | -14.0 | 높은 날개 바람에서 낮은 급강하로 |
| Monsters | [monster_blink](monster_blink.png) | 0.220 | -15.0 | 사라짐·틈·재등장의 두 룬 음 |
| Monsters | [monster_homing](monster_homing.png) | 0.360 | -14.0 | 진폭이 흔들리는 추적 펄스 |
| Monsters | [monster_hurt](monster_hurt.png) | 0.200 | -13.5 | 선수 피격보다 거친 낮은 몸통 |
| Monsters | [monster_defeat](monster_defeat.png) | 0.570 | -16.0 | 부서짐과 두 단계 하강 |
| Monsters | [elite_appear](elite_appear.png) | 0.820 | -16.0 | 완전5도의 짧은 낮은 뿔피리 호명 |
| Monsters | [monster_attack](monster_attack.png) | 0.230 | -14.0 | 중립적인 발톱 바람과 몸통 |
| Realms | [hazard_warning](hazard_warning.png) | 0.400 | -18.0 | 중저음 두 박 경고 |
| Realms | [eruption](eruption.png) | 0.680 | -16.0 | 낮은 압력과 위로 솟는 대역 잡음 |
| Realms | [quake](quake.png) | 0.740 | -16.0 | 서로 어긋난 세 지면 진동 |
| Realms | [beam](beam.png) | 0.550 | -18.0 | 길게 열리는 유리 공명 |
| Realms | [vines](vines.png) | 0.490 | -20.0 | 마찰 잡음과 나무의 상승 공명 |
| Realms | [belt_reverse](belt_reverse.png) | 0.350 | -20.0 | 톱니 세 번과 하강 서보 |
| Realms | [gate_open](gate_open.png) | 0.720 | -18.0 | 완전5도 빛 종과 공간 열림 |
| Realms | [gate_travel](gate_travel.png) | 0.450 | -18.0 | 안쪽으로 모이는 두 음 |
| Realms | [bush_rustle](bush_rustle.png) | 0.180 | -24.0 | 짧고 얇은 잎 마찰 |
| Realms | [collapse_warning](collapse_warning.png) | 0.900 | -17.0 | 고음을 억제한 가속 세 박 경고 |
| Realms | [portal](portal.png) | 1.020 | -16.0 | 짧은 잡음 타격·음정 몸통·저음 펄스를 겹친 아케이드 무게감 |
| Progress | [soul_pickup](soul_pickup.png) | 0.130 | -20.0 | 빠르게 모이는 작은 두 별 음 |
| Progress | [card_offer](card_offer.png) | 0.460 | -18.0 | 펼치는 바람 뒤 열린 세 음 |
| Progress | [card_pick](card_pick.png) | 0.340 | -17.0 | 모이는 룬과 확정의 완전5도 |
| Progress | [match_start](match_start.png) | 0.840 | -16.0 | 두 준비 박 뒤 열리는 시작 화음 |
| Progress | [results](results.png) | 0.670 | -18.0 | 승패에 치우치지 않는 하강 정리 |
| Progress | [victory](victory.png) | 1.650 | -16.0 | 직접 작곡한 D-A-D-F-A-D 짧은 팡파르 |
| Menus/story | [ui_move](ui_move.png) | 0.045 | -24.0 | 반복 탐색에 맞춘 아주 짧은 낮은 틱 |
| Menus/story | [ui_select](ui_select.png) | 0.100 | -14.0 | 짧은 잡음 타격·음정 몸통·저음 펄스를 겹친 아케이드 무게감 |
| Menus/story | [ui_cancel](ui_cancel.png) | 0.100 | -14.0 | 짧은 잡음 타격·음정 몸통·저음 펄스를 겹친 아케이드 무게감 |
| Menus/story | [story_text](story_text.png) | 0.032 | -28.0 | 글자마다가 아닌 한 줄당 작은 틱 |
| Menus/story | [story_advance](story_advance.png) | 0.085 | -23.0 | 위로 열리는 조용한 두 음 |
