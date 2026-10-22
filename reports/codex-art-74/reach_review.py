import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
from PIL import Image,ImageDraw
import process as p
import json,math
POINTS={'midgard_rooftop_slinger':((67,53),(77,49),'슬링 손의 중심'), 'vanaheim_vine_hound':((76,72),(89,52),'앞발 끝'), 'vanaheim_seed_sprite':((69,55),(75,48),'꽃 가지를 잡은 손/가지 접점')}
results=[]
for mid in ['midgard_rooftop_slinger','vanaheim_vine_hound','vanaheim_seed_sprite']:
    ims=[p.frames(p.BAKE/f'{mid}-idle-v1.png',1)[0],p.frames(p.BAKE/f'{mid}-attack-v1.png',6)[2]]
    out=Image.new('RGB',(800,450),(24,29,40));d=ImageDraw.Draw(out)
    points=[]
    for i,im in enumerate(ims):
        tile=p.n.checker((96,96)).convert('RGB');tile.paste(im,(0,0),im);out.paste(tile.resize((384,384),Image.Resampling.NEAREST),(i*400,48))
        d.text((i*400+4,4),'IDLE F1' if i==0 else 'ATTACK F3',font=p.n.font(18),fill='white')
        for x in range(0,96,8):d.text((i*400+x*4,28),str(x),font=p.n.font(12),fill='white')
        for y in range(0,96,8):d.text((i*400,48+y*4),str(y),font=p.n.font(12),fill='white')
        # Track the same manually identified point through the raw row rebuild.
        row='idle' if i==0 else 'attack';idx=0 if i==0 else 2
        before=p.frames(p.REPORT/'fix-1/before'/f'{mid}-{row}-v1.png',p.COUNTS[row])[idx]
        bm=json.loads((p.REPORT/'fix-1/before'/f'{mid}-{row}-v1.json').read_text('utf-8'))
        am=json.loads((p.BAKE/f'{mid}-{row}-v1.json').read_text('utf-8'))
        scale=am['factor']/bm['factor'];ob=before.getbbox();nb=im.getbbox()
        requested=tuple(round(nb[k]+(POINTS[mid][i][k]-ob[k])*scale) for k in range(2))
        a=p.n.np.array(im)[:,:,3]>0;ys,xs=p.n.np.where(a)
        j=min(range(len(xs)),key=lambda j:(xs[j]-requested[0])**2+(ys[j]-requested[1])**2)
        point=(int(xs[j]),int(ys[j]));assert math.dist(point,requested)<=3,(mid,requested,point)
        points.append(point);x=i*400+point[0]*4;y=48+point[1]*4
        d.ellipse((x-6,y-6,x+6,y+6),outline=(255,100,210),width=2)
        d.text((i*400+4,433),f'point={point}',font=p.n.font(14),fill='white')
    out.save(p.REPORT/f'{mid}-reach-ruler.png')
    results.append(dict(monster=mid,feature=POINTS[mid][2],frames=['idle1','attack3'],points=points,before_forward_px=POINTS[mid][1][0]-POINTS[mid][0][0],forward_px=points[1][0]-points[0][0],method='수정 전 수동 지정 부위를 원본 공통배율과 전체 이동으로 추적, 가장 가까운 불투명 픽셀로 보정(최대3px). 정지 프레임 비교이며 실제 게임 이동량 아님'))
(p.REPORT/'reach-measurements.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),'utf-8')
print(results)
