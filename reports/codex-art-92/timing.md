# ART-92 시간 확인 기록

아래는 각 행 시작 전에 도구에서 실제 확인한 KST 시각이다. 완료 시각은 progress.md에 별도로 기록했다.

폼 | 행 | 시작 전 시계 확인
---|---|---
frey | dodge_roll | 14:42:54
luna | dodge_roll | 14:48:23
luna_brave | dodge_roll | 14:52:56
nova_male | dodge_roll | 14:59:54
nova_female | dodge_roll | 15:03:28
rio_male | dodge_roll | 15:07:19
rio_female | dodge_roll | 15:13:08
yuki | dodge_roll | 15:16:50
frey | taunt | 15:27:12
luna | taunt | 15:31:50
luna_brave | taunt | 15:38:10

15:45:31에 마감선 경과를 확인했다. 이후 새 행을 시작하지 않았고 기존 브레이브 루나 도발의 공통 배율 검증 및 보고 작업만 진행했다.

일부 행의 정규화 계산 중 다음 순서 행의 생성을 진행했지만, 통과 판정한 행은 즉시 따로 납품했다. 최종 납품을 일괄 미루지 않았다.

실패 행의 face-proposed.json에 나오는 제외 사유는 도구의 공통 문구다. dodge_roll은 회전/가림/감은 눈이며, taunt의 F3은 감은 눈 또는 윙크다. 자동 대응점 제안은 실제 육안 판정과 구분한다. 납품 후보는 각 JSON의 개별 제외 사유가 최종 기록이다.
