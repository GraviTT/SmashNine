from pathlib import Path
ROOT=Path('reports/codex-skm-08')
ROWS={
 'sword_throw':(20,False,'K 마검 투척'),
 'counter_stance':(15,False,'L 그림자 받아치기'),
 'pierce':(20,False,'J 3타 관통 베기'),
 'decoy_step':(16,False,'U 분신 바꿔치기'),
 'flurry_cut':(24,False,'I 마검 난무 마무리 베기'),
}
ORDER=[(f'rio_{b}',r) for r in ROWS for b in ['male','female']]
FACE_POINTS={
 'rio_male':[(75.5,49,3,4),(81,47,2,3),(66.5,52,3,4),(82.5,52,3,4)],
 'rio_female':[(83,51,3,4),(88,49,2,3),(77.5,53,3,4),(87.5,53,3,4)],
}
