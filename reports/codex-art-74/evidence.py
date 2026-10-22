"""Measurements and annotated review boards. No sprite pixels are edited here."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json,statistics
from PIL import Image,ImageDraw
import process as p
from landmarks import groups

# Manually located stable feature outer boxes on a 4x ruler. Bounds are approximate ±2px.
# One representative frame per row: normal/rest F1, hurt recovery F2, attack recovery F6.
BOXES={
'svartalfheim_gear_beetle':[(18,44,37,63),(18,40,37,59),(20,46,39,65),(13,49,30,66),(17,47,36,66),(21,48,39,66)],
'svartalfheim_cog_drone':[(14,36,33,55),(15,37,34,56),(18,41,36,59),(15,38,35,58),(16,39,35,58),(18,32,39,53)],
'vanaheim_vine_hound':[(63,40,91,64),(64,36,92,61),(65,41,91,63),(65,33,90,58),(64,44,91,67),(69,44,94,69)],
'vanaheim_seed_sprite':[(26,38,71,72),(24,35,69,68),(29,42,71,72),(23,41,65,72),(25,48,68,72),(26,38,71,72)],
'jotunheim_rune_golem':[(26,35,53,62),(33,40,56,63),(32,35,57,62),(32,40,56,64),(31,40,55,64),(31,33,57,59)],
}
NAMES={'svartalfheim_gear_beetle':'측면 기어','svartalfheim_cog_drone':'측면 기어','vanaheim_vine_hound':'눈·주둥이 머리 외곽','vanaheim_seed_sprite':'잎을 제외한 씨앗 몸통','jotunheim_rune_golem':'어깨 룬 판 외곽'}

def contacts(im):
    a=p.n.np.array(im)[:,:,3]>0
    xs=p.n.np.where(a[71:74].any(axis=0))[0].tolist(); runs=[]
    for x in xs:
        if not runs or x>runs[-1][-1]+1:runs.append([x])
        else:runs[-1].append(x)
    return [dict(x0=r[0],x1=r[-1],centre=round(statistics.mean(r),1)) for r in runs]

def build():
    size_results=[];walks={};loops={}
    for mid in p.WINDUP:
        panel=Image.new('RGB',(6*400,448),(24,29,40));d=ImageDraw.Draw(panel);anchor_width=None
        for ri,row in enumerate(p.ROWS):
            ims=p.frames(p.BAKE/f'{mid}-{row}-v1.png',p.COUNTS[row]);idx=1 if row=='hurt' else 5 if row=='attack' and mid in ['vanaheim_vine_hound','vanaheim_seed_sprite','jotunheim_rune_golem'] else 0
            im=ims[idx]
            if mid=='midgard_rooftop_slinger':
                a=p.n.np.array(im).astype(float);r,g,b,al=[a[:,:,i] for i in range(4)]
                gs=groups((r>70)&(r>g*1.35)&(r>b*1.8)&(al>0));box=max(gs,key=lambda x:x['area'])['bbox'];method='주황색 후드 면의 가장 큰 4연결 성분: R>70 R>1.35G R>1.8B';feature='후드 주황 면';error=0
            else:box=BOXES[mid][ri];method='4배 눈금판에서 사람이 지정한 외곽 상자, ±2px. 대표 1프레임의 가로폭이며 전체 프레임의 자동 머리 비율 검사가 아님';feature=NAMES[mid];error=2
            if row=='idle':anchor_width=box[2]-box[0]
            width=box[2]-box[0];ratio=round(width/anchor_width,3)
            item=dict(monster=mid,row=row,frame=idx+1,feature=feature,box=box,width=width,anchor_width=anchor_width,ratio=ratio,uncertainty_px=error,method=method)
            size_results.append(item)
            tile=p.n.checker((96,96)).convert('RGB');tile.paste(im,(0,0),im);panel.paste(tile.resize((384,384),Image.Resampling.NEAREST),(ri*400,48))
            d.text((ri*400+4,4),f'{row} F{idx+1} | {width}px / {ratio:.2f}x',font=p.n.font(16),fill='white')
            d.rectangle((ri*400+box[0]*4,48+box[1]*4,ri*400+box[2]*4-1,48+box[3]*4-1),outline=(255,100,210),width=1)
        panel.save(p.REPORT/f'{mid}-size-4x.png')
        if mid!='svartalfheim_cog_drone':
            ims=p.frames(p.BAKE/f'{mid}-walk-v1.png',6);wp=Image.new('RGB',(6*384,440),(24,29,40));wd=ImageDraw.Draw(wp);data=[]
            for i,im in enumerate(ims):
                runs=contacts(im);data.append(dict(frame=i+1,ground_band='y71..73 opaque runs; leg identity judged visually',contacts=runs))
                tile=p.n.checker((96,96)).convert('RGB');tile.paste(im,(0,0),im);wp.paste(tile.resize((384,384),Image.Resampling.NEAREST),(i*384,40))
                wd.text((i*384+6,5),f'F{i+1}: '+','.join(str(r['centre']) for r in runs),font=p.n.font(14),fill='white')
                wd.line((i*384,40+72*4,(i+1)*384,40+72*4),fill=(255,90,140),width=1)
                for run in runs:
                    x=i*384+run['centre']*4;y=40+72*4;wd.ellipse((x-4,y-4,x+4,y+4),outline=(90,255,210),width=2)
            wp.save(p.REPORT/f'{mid}-walk-feet-4x.png');walks[mid]=data
        if mid in ['svartalfheim_gear_beetle','svartalfheim_cog_drone']:
            ims=p.frames(p.BAKE/f'{mid}-attack-v1.png',6);aa=[p.n.np.array(i).astype(float) for i in ims]
            diffs=[round(float(abs(aa[i]-aa[(i+1)%6]).mean()),3) for i in range(6)]
            masks=[a[:,:,3]>0 for a in aa];union=(masks[0]|masks[-1]).sum();iou=round(float((masks[0]&masks[-1]).sum()/union),3)
            loops[mid]=dict(adjacent_rgba_mean_abs_differences=diffs,wrap_difference=diffs[-1],wrap_alpha_iou=iou,judgment='정지 프레임 수치이며 실제 재생의 매끄러움을 증명하지 않음')
    (p.REPORT/'size-measurements.json').write_text(json.dumps(size_results,ensure_ascii=False,indent=2),'utf-8')
    (p.REPORT/'walk-contacts.json').write_text(json.dumps(walks,ensure_ascii=False,indent=2),'utf-8')
    (p.REPORT/'loop-measurements.json').write_text(json.dumps(loops,ensure_ascii=False,indent=2),'utf-8')
    print('SIZE',[(x['monster'],x['row'],x['ratio']) for x in size_results]);print('LOOPS',loops)

if __name__=='__main__':build()
