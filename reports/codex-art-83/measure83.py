"""Read-only measurements; save new evidence only. Manual landmarks have +/-1 px uncertainty."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json,math
import numpy as np
from PIL import Image,ImageDraw
import repair as r
from reuse71 import review as v
SELECT=[('mossling','walk','b'),('ember_imp','walk','b'),('ember_imp','idle','a'),('asgard_aegis_ram','idle','b'),('mossling','attack','a'),('vanaheim_seed_sprite','attack','e')]+[('vanaheim_vine_hound',row,'b') for row in r.ROWS]+[('alfheim_moon_moth','windup','e'),('jotunheim_storm_wisp','hurt','b'),('niflheim_glacier_wolf','attack','b')]
def ims(mid,row,label=None):
 return r.frames(r.REPORT/'trials'/f'{mid}-{row}-{label}'/'strip.png' if label else r.BAKE/f'{mid}-{row}-v1.png',r.p.COUNTS[row])
def annotated(im,label,box=None,points=None):
 out=v.tile(im,label);d=ImageDraw.Draw(out)
 # reuse71.tile places the sprite at (32,36).
 # Determine layout from its documented implementation before drawing.
 return out
def board(mid,row,frames,labels,marks,name):
 out=Image.new('RGB',(432*len(frames),462),(24,29,40));d=ImageDraw.Draw(out)
 for i,(im,lab,mark) in enumerate(zip(frames,labels,marks)):
  ox=i*432+24;oy=44;bg=r.n.checker((384,384),32);big=im.resize((384,384),Image.Resampling.NEAREST);bg.paste(big,(0,0),big);out.paste(bg,(ox,oy));d.text((ox,4),lab,font=r.FONT,fill='white')
  for x in range(0,97,8):d.text((ox+x*4,25),str(x),fill='white')
  for y in range(0,97,8):d.text((i*432,oy+y*4),str(y),fill='white')
  if 'box' in mark:
   b=mark['box'];d.rectangle((ox+b[0]*4,oy+b[1]*4,ox+b[2]*4,oy+b[3]*4),outline='#ff77cc',width=2)
  if 'points' in mark:
   pts=mark['points'];d.line([(ox+x*4+2,oy+y*4+2) for x,y in pts],fill='#ff77cc',width=2)
   for x,y in pts:d.ellipse((ox+x*4-3,oy+y*4-3,ox+x*4+7,oy+y*4+7),outline='#ffffff',width=1)
  d.text((ox,437),str(mark),font=r.FONT,fill='white')
 r.save(r.REPORT/'measure-final'/name,out)
def run():
 sizes=[]
 cfg=[('mossling','walk','b',0,22,(64,48,86,62),'윗얼굴 폭; 잎/아래턱 제외'),('ember_imp','walk','b',0,20,(52,29,73,43),'두개골 폭; 뿔/등가시 제외'),('ember_imp','idle','a',0,20,(54,30,74,45),'두개골 폭; 뿔/등가시 제외'),('mossling','attack','a',0,22,(56,50,78,64),'윗얼굴 폭; 잎/아래턱 제외'),('vanaheim_seed_sprite','attack','e',5,45,(26,39,70,67),'잎/팔 제외 씨앗 몸통 폭')]
 for mid,row,label,idx,base,box,part in cfg:
  f=ims(mid,row,label)[idx];sz=box[2]-box[0];rec=dict(monster=mid,row=row,frame=idx+1,part=part,box=box,idle_px=base,after_px=sz,ratio=sz/base,uncertainty_px=1,method='출력 픽셀의 같은 해부 부위 수동 경계. 명목 비율; 오차까지 포함한 정밀 보장은 아님.')
  assert .95<=rec['ratio']<=1.05; sizes.append(rec)
  board(mid,row,[ims(mid,'idle')[0],f],['IDLE v1 F1',f'V2 {row} F{idx+1}'],[{},dict(box=box)],f'{mid}-{row}-final-size.png')
 for mid,row,label in [('asgard_aegis_ram','idle','b'),('alfheim_moon_moth','windup','e')]:
  base=v.feature(mid,'idle',ims(mid,'idle')[0])['size'];features=[]
  for i,f in enumerate(ims(mid,row,label)):
   a=v.feature(mid,row,f);ratio=a['size']/base;assert .95<=ratio<=1.05;features.append(dict(frame=i+1,**a,ratio=ratio))
  sizes.append(dict(monster=mid,row=row,idle_px=base,features=features,method='ART-71 fix-1의 동일 연결색 영역 측정; ram 높이 / moth sqrt(area)'))
  old=v.feature(mid,row,ims(mid,row)[1]);new=features[1]
  board(mid,row,[ims(mid,'idle')[0],ims(mid,row)[1],ims(mid,row,label)[1]],['IDLE v1 F1',f'V1 {row} F2',f'V2 {row} F2'],[dict(box=v.feature(mid,'idle',ims(mid,'idle')[0])['box']),dict(box=old['box']),dict(box=new['box'])],f'{mid}-{row}-final-size.png')
 for mid,row,label,idx,base,points,part in [('jotunheim_storm_wisp','hurt','b',1,23.26338586109352,[(32,27),(53,17)],'상단 타원석 장축; idle 6프레임 기준 평균'),('niflheim_glacier_wolf','attack','b',5,14,[(32,56),(46,56)],'가까운 뒷다리 청색 허벅지 폭')]:
  f=ims(mid,row,label)[idx];sz=math.dist(*points);ratio=sz/base;assert .95<=ratio<=1.05
  for x,y in points:assert f.getpixel((x,y))[3]>0
  sizes.append(dict(monster=mid,row=row,frame=idx+1,part=part,points=points,idle_px=base,after_px=sz,ratio=ratio,endpoint_uncertainty_px=1,length_uncertainty_px=2,method='ART-76 fix-1과 같은 수동 부위; 출력에서 재지정. 명목 비율.'))
  board(mid,row,[ims(mid,'idle')[0],f],['IDLE v1 F1',f'V2 {row} F{idx+1}'],[{},dict(points=points)],f'{mid}-{row}-final-size.png')
 for row in r.ROWS:
  old=ims('vanaheim_vine_hound',row);new=ims('vanaheim_vine_hound',row,'b');assert all(np.array_equal(np.array(a)[:,:,3],np.array(b)[:,:,3]) for a,b in zip(old,new))
  rec=next(x for x in json.loads((r.ROOT/'reports/codex-art-74/fix-1/sizes.json').read_text('utf-8')) if x['monster']=='vanaheim_vine_hound' and x['row']==row)
  sizes.append(dict(monster='vanaheim_vine_hound',row=row,frame=rec['frame'],part=rec['part'],idle_px=27,after_px=rec['after_px'],ratio=rec['after_ratio'],box=rec['after_box'],method='모든 알파 픽셀이 v1과 동일. fix-1 크기/위치 그대로.'))
 r.jsave(r.REPORT/'measure-final'/'sizes-final.json',sizes)
 movement=[]
 for mid,row,label,frames_old,frames_new,pts_old,pts_new,feature in [
  ('mossling','attack','a',[0,2],[0,2],[(58,37),(59,33)],[(41,35),(59,34)],'몸통 위 싹의 부착부: attack F1→F3'),
  ('vanaheim_seed_sprite','attack','e',[-1,2],[-1,2],[(69,55),(74,47)],[(69,55),(79,52)],'꽃 가지를 쥔 손/가지 접점: idle F1→attack F3')]:
  def getfs(indices,lab):return [ims(mid,'idle')[0] if ix==-1 else ims(mid,row,lab)[ix] for ix in indices]
  old=getfs(frames_old,None);new=getfs(frames_new,label)
  for f,pt in zip(old+new,pts_old+pts_new):assert f.getpixel(pt)[3]>0,(mid,pt)
  before=pts_old[1][0]-pts_old[0][0];after=pts_new[1][0]-pts_new[0][0];assert after>=8
  movement.append(dict(monster=mid,row=row,feature=feature,before_points=pts_old,after_points=pts_new,before_forward_px=before,after_forward_px=after,endpoint_uncertainty_px=1,note='정지 프레임 안 그림의 위치. 게임 이동/타격 범위 아님.'))
  board(mid,row,old+new,['V1 start','V1 strike','V2 start','V2 strike'],[dict(points=[pt]) for pt in pts_old+pts_new],f'{mid}-forward-final.png')
 mid='jotunheim_storm_wisp';old=ims(mid,'hurt')[0];new=ims(mid,'hurt','b')[0];points_old=[(43,24),(48,46)];points_new=[(27,27),(43,40)]
 movement.append(dict(monster=mid,row='hurt',feature='F1 상단 돌 중심과 청색 핵 중심의 수평 벌어짐',before_points=points_old,after_points=points_new,before_px=5,after_px=16,endpoint_uncertainty_px=1,note='수동 중심. 몸체 기울기와 돌 배치 변화의 보조 지표; 피격감은 육안 판단.'))
 board(mid,'hurt',[old,new],['V1 F1','V2 F1'],[dict(points=points_old),dict(points=points_new)],'wisp-flinch-final.png')
 wolf_old=[f.getbbox()[3]-1 for f in ims('niflheim_glacier_wolf','attack')];wolf_new=[f.getbbox()[3]-1 for f in ims('niflheim_glacier_wolf','attack','b')]
 movement.append(dict(monster='niflheim_glacier_wolf',row='attack',feature='프레임 최하단 불투명 픽셀 y',before_y=wolf_old,after_y=wolf_new,before_apex=1+wolf_old.index(min(wolf_old)),after_apex=1+wolf_new.index(min(wolf_new))))
 r.jsave(r.REPORT/'measure-final'/'movement-final.json',movement)
 print(json.dumps(dict(size_rows=len(sizes),movement=movement),ensure_ascii=False))
if __name__=='__main__':run()
