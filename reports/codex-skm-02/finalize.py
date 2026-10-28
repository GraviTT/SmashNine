"""Record the final human visual review, then run package.py separately."""
import json
from pathlib import Path

root=Path('reports/codex-art-72')
rows=json.loads((root/'selection.json').read_text(encoding='utf-8'))
notes={
('frey','jump'):'3회 생성 종료. 최선 3차도 F2 눈 비율 1.045, F3 1.042로 상한 1.04를 넘는다. 도약 자세와 장비는 확인했으나 미전달.',
('frey','fall'):'머리카락과 망토가 위로 후행하는 두 낙하 자세. 얼굴과 장비를 4배로 확인했다.',
('frey','hurt'):'타격 순간, 반동, 회복의 3장. 자동 머리 검사의 F2 점수는 낮지만 실제 얼굴 표식과 장비를 4배로 확인했다.',
('frey','land'):'착지 웅크림에서 대기 자세 쪽으로 일어선다. 양발 접지와 장비를 확인했다.',
('frey','victory'):'3회 생성 종료. 1·3차는 원본 셀 경계 침범. 최선 2차는 얼굴 눈·폭 비율이 기준 밖이다. F4에서 올린 검을 F5에서 내렸다가 F6에서 다시 드는 흐름도 남았다.',
('luna','jump'):'도약·상승·정점 3장. 얼굴과 지팡이를 확인했다. F2·3 무릎 자세 차이는 작다.',
('luna','fall'):'위로 들린 머리카락과 치맛자락의 낙하 반복. 자동 머리 중앙값 0.94와 달라 얼굴 측정을 우선했다.',
('luna','hurt'):'타격 순간, 반동, 회복의 3장. 지팡이와 의상, 양발 접지를 확인했다.',
('luna','land'):'착지 웅크림에서 대기 자세로 회복한다. 3차에서 얼굴 크기와 양발 접지, 지팡이를 확인했다.',
('luna','victory'):'3회 생성 종료. F1·3·4 눈 비율과 F3·4 얼굴 폭이 기준 밖이다. F6 윙크는 두 눈 거리 측정에서 제외했다. 지팡이 돌리기의 손 전환도 매끄럽지 않다.',
('luna_brave','jump'):'3회 생성 종료. 최선 2차의 F1·2 얼굴 비율은 맞지만 F3 얼굴 폭 1.071이 상한을 넘는다.',
('luna_brave','fall'):'3회 생성 종료. 최선 3차 공통 배율 0.13525에서 F1 눈 비율 0.955로 하한 0.96에 못 미친다. 장갑과 의상, 낙하 자세는 확인했다.',
('luna_brave','hurt'):'3회 생성 종료. F1 눈 비율 0.945와 F1·3 얼굴 폭 1.071이 기준 밖이다. F2 자동 머리 위치가 팔·다리 피부에 혼동되어 해당 얼굴 측정값은 제외했다.',
('luna_brave','land'):'착지 웅크림에서 양주먹 가드로 회복한다. 장갑과 무릎 별 장식을 확인했다.',
('luna_brave','victory'):'3회 생성 종료. 2차는 원본 셀 경계 실패. 최선 3차도 F1·2·5·6 얼굴 폭 1.071로 기준 밖이다. F3·4는 들어 올린 팔 때문에 자동 표식이 빗나가 얼굴 측정에서 제외했다.'
}
counts={'jump':3,'fall':2,'hurt':3,'land':2,'victory':6}
for r in rows:
    r['reason']=notes[r['stem'],r['row']]
    r['reviewed_frames']=list(range(1,counts[r['row']]+1))
    r['costume_ok']=True
    r['pose_ok']=(r['stem'],r['row']) not in [('frey','victory'),('luna','victory')]
    r['visual_review']='Every normalized frame reviewed at exact 4x; invalid source-grid sheets also reviewed at raw 4x.'
(root/'selection.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Final selection: 8 deliverable rows; 7 rejected rows, each at three generations.')
