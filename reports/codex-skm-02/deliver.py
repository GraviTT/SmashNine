"""Publish only an explicitly reviewed row; update handoff atomically per row."""
import os,sys,json,shutil,subprocess
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
stem,row,att,status,note=sys.argv[1:6];root=Path('reports/codex-skm-02');base=root/stem/row/f'attempt-{att}'
m=json.loads((base/'metrics.json').read_text(encoding='utf-8'));h=json.loads((base/'head-scale.json').read_text(encoding='utf-8'));f=json.loads((base/'face-measured.json').read_text(encoding='utf-8')) if (base/'face-measured.json').exists() else None
delivered=status=='yes';summary=m['summary'];margin=min(x['margin']['minimum'] for x in m['frames']);ratios=[x['face_width_ratio'] for x in (f or {}).get('frames',[]) if x.get('face_width_ratio') is not None]
if delivered:
 assert summary['borders_clear'] and summary['all_have_4px_margin'] and summary['alpha_binary']
 assert max(summary['remaining_spill_pixels'])==0 and min(summary['interior_detail_range'])>=79
 assert ratios and min(ratios)>=.95 and max(ratios)<=1.06
 name=f'{stem}-{row}-v1';target=Path('art/bakeoff')/stem.split('_')[0]/name
 assert not target.with_suffix('.png').exists() and not target.with_suffix('.json').exists()
 shutil.copy2(base/f'{stem}-{row}.png',target.with_suffix('.png'))
 purpose={'dimension_link':'J 적중 → K로 상대 통과 → 후속 J 차원 연결','pogo_bounce':'아래 찌르기 적중 뒤 반동으로 다시 상승','zero_gravity':'위 J로 상대의 중력을 잠시 없애는 시전 동작','seal_link':'두 봉인부 사이 결계선을 연결하는 시전 동작'}[row]
 meta={'note':note,'for':purpose,'frames':6,'fps':13 if row=='zero_gravity' else 12 if row=='seal_link' else 15,'cell':192,'feet':[96,152],'loop':False,'hold_last':row in ['pogo_bounce','seal_link'],'factor':summary['common_scale']}
 target.with_suffix('.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
shutil.copy2(base/'review4x.png',root/f'{stem}-{row}.png')
checks=f'시도 {att}, 배율 {summary["common_scale"]}, 얼굴 폭 {min(ratios) if ratios else "미확정"}–{max(ratios) if ratios else "미확정"}, 머리 중앙값 {h["median"]}; 여백 {margin}px, 테두리 비움, spill {max(summary["remaining_spill_pixels"])}, 디테일 {summary["interior_detail_range"]}. {note}'
states=json.loads((root/'progress.json').read_text(encoding='utf-8'));states=[s for s in states if (s['stem'],s['row'])!=(stem,row)];states.append({'stem':stem,'row':row,'attempt':int(att),'delivered':delivered,'checks':checks,'note':note,'visual_review':'all six frames in page-1, page-2, page-3 and face crops reviewed by agent'})
(root/'progress.json').write_text(json.dumps(states,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
subprocess.run([sys.executable,str(root/'handoff.py')],check=True)
print(checks)
