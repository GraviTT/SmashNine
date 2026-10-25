"""One-shot creation of new ART-83 candidates. Never replaces a file."""
import json
from PIL import Image,ImageDraw
import repair as r
from measure83 import SELECT
NOTES={
 ('mossling','walk'):'가까운 밝은 앞다리가 F1 전방→F3 후방→F6 전방으로 교대하도록 재생성. 1×에서 기존 교대 불명확→교대 식별 가능(육안). 윗얼굴 폭 idle 22px / 대표 F1 22px.',
 ('ember_imp','walk'):'밝은 가까운 다리와 어두운 먼 다리의 전후 순서가 반전하도록 재생성. 1× 교대 불명확→식별 가능(육안). 두개골 폭 idle 20px / 대표 F1 21px(1.05).',
 ('ember_imp','idle'):'두개골/몸 비율을 유지하며 비늘과 명암을 보강. interior_detail 72.40–76.21→96.58–100.55. 대표 두개골 폭 idle 20px / v2 20px.',
 ('asgard_aegis_ram','idle'):'깃/털과 금속 명암을 보강. interior_detail 74.75–80.76→92.44–97.10. 금색 주뿔 높이 기준 16px / v2 전 프레임 16px.',
 ('mossling','attack'):'몸통이 앞으로 뻗는 돌진으로 재생성. 등 위 싹의 갈색 줄기 부착부 F1→F3 x 변화 −2→+16px(수동 표식 ±1px). 윗얼굴 폭 22px. 게임 이동/타격 범위 수치 아님.',
 ('vanaheim_seed_sprite','attack'):'꽃 가지를 앞으로 뻗도록 재생성 후 ART-74 방식 녹색 복원. idle F1→attack F3 손/가지 접점 x 변화 5→10px(수동 표식 ±1px). 몸통 폭 idle 45px / F6 44px. 게임 공격 범위 수치 아님.',
 ('alfheim_moon_moth','windup'):'행 공통 배율로 구형 머리 크기 보정. F2 sqrt(밝은 연결색 면적)/idle 0.896→1.020. 전체 F1–F4 0.951–1.037. 몸 중심 정렬. 더듬이 끝 식별은 여전히 약함.',
 ('jotunheim_storm_wisp','hurt'):'돌 군집이 한쪽으로 기울어지는 피격 자세로 재생성. F1 상단 돌–청색 핵 중심 수평 차이 5→16px(수동 ±1px). F2 상단 타원석 장축 23.26px / idle 기준 평균 23.26px. 색 변화뿐 아니라 배치/실루엣 변화.',
 ('niflheim_glacier_wolf','attack'):'도약 정점을 F4→F3으로 이동. 최하단 y: 72,67,62,53,72,72→72,62,52,59,67,72. 대표 F6 가까운 뒷다리 청색 허벅지 폭 14px로 idle과 일치. 전 프레임 공통 배율 0.215.',
}
def run():
 selection=[]
 for mid,row,label in SELECT:
  for ext in ['png','json']:assert not (r.BAKE/f'{mid}-{row}-v2.{ext}').exists()
 for mid in dict.fromkeys(x[0] for x in SELECT):assert not (r.BAKE/f'{mid}_sheet-v2.png').exists()
 for mid,row,label in SELECT:
  d=json.loads((r.REPORT/'trials'/f'{mid}-{row}-{label}/metrics.json').read_text('utf-8'))
  if mid=='vanaheim_vine_hound':
   a=sum(x['count'] for x in d['colour']['before_leaf_outliers']);b=sum(x['count'] for x in d['colour']['after_leaf_outliers'])
   note=f'ART-74 참조 팔레트의 색 경계를 부드럽게 연결하고 잎 하이라이트 확대를 줄임. 잎 영역 국소 밝기 이상점 {a}→{b}(보조 지표; 실제 결함 픽셀 수 아님). 전 프레임 알파/위치/크기 v1과 동일. 미세 점상 질감은 남아 있음.'
  else:note=NOTES[mid,row]
  r.deliver(mid,row,label,note)
  selection.append(dict(monster=mid,row=row,trial=label,factor=d['factor'],frames=r.p.COUNTS[row],candidate=f'art/bakeoff/monsters/{mid}-{row}-v2.png',metrics=f'reports/codex-art-83/trials/{mid}-{row}-{label}/metrics.json',note=note,visual_review='모든 사용 프레임을 1×/4× 정지 비교판으로 직접 확인. 재생/게임 실행 검증 아님.'))
 for mid in dict.fromkeys(x[0] for x in SELECT):r.assemble(mid)
 r.jsave(r.REPORT/'selection.json',selection)
 overview=Image.new('RGB',(1250,710),(24,29,40));draw=ImageDraw.Draw(overview)
 for j,(mid,row) in enumerate([('mossling','walk'),('ember_imp','walk'),('mossling','attack'),('vanaheim_seed_sprite','attack'),('niflheim_glacier_wolf','attack')]):
  y=10+j*140;draw.text((10,y),mid+' / '+row+'   V1 (left) -> V2 (right), native 1x',font=r.FONT,fill='white')
  for k,version in enumerate(['v1','v2']):
   strip=Image.open(r.BAKE/f'{mid}-{row}-{version}.png').convert('RGBA');bg=r.n.checker((576,96),8);bg.paste(strip,(0,0),strip);overview.paste(bg,(10+k*620,y+28))
 r.save(r.REPORT/'overview.png',overview)
 print(f'Delivered {len(selection)} rows, {sum(x["frames"] for x in selection)} frames, {len(set(x["monster"] for x in selection))} sheets')
if __name__=='__main__':run()
