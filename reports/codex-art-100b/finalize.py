"""Package only rows passing ART-100B. No product files, body-part edits or commits."""
from process import ROOT,REPORT,RAW,n,h,module,board,anchor
from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import numpy as np,json,hashlib,shutil,math
f=module('walk_feet')
OUT=ROOT/'art/bakeoff/jupi';OUT.mkdir(parents=True,exist_ok=True)
SPECS={
 'walk':{'source':'walk-after-bob.png','count':8,'fps':13.3,'loop':True,'factors':[.114,.100,.100,.100,.100,.100,.100,.100],'delivered':True,'note':'천둥 북잡이 유피의 가벼운 8프레임 걷기. 양다리 교대, 통과 자세 3·7번, 보브 1회 적용. ART-100B 검토 후보.'},
 'jump':{'source':'jump/strip.png','count':3,'fps':10,'loop':False,'factor':.190,'delivered':True,'note':'이륙·상승·정점 3프레임. 마지막 자세 유지용. 발선 위 공중 동작. ART-100B 검토 후보.'},
 'fall':{'source':'fall/strip.png','count':2,'fps':8,'loop':True,'factor':.160,'delivered':True,'note':'머리끈·치마·허리 장식이 움직이는 낙하 2프레임 반복. ART-100B 검토 후보.'},
 'hurt':{'source':'hurt-a2/strip.png','count':3,'fps':12,'loop':False,'factor':.160,'delivered':False,'note':'미납품: 공통 가로 기준점에서 F1→F2 양발이 7px 이동하여 3px 기준 실패. 허용 2회 생성 소진.'},
 'land':{'source':'land-a2/strip.png','count':2,'fps':12,'loop':False,'factor':.160,'delivered':True,'note':'착지 웅크림에서 대기로 일어나는 2프레임. 공통 가로 기준점, 발 이동 1–1.5px. ART-100B 검토 후보.'},
}
def cells(path):
    im=Image.open(path).convert('RGBA');return [im.crop((i*128,0,(i+1)*128,128)) for i in range(im.width//128)]
def inspect(fr):
    a=np.asarray(fr);m=a[...,3]>0;box=fr.getbbox();x0,y0,x1,y1=box
    return {'bbox':box,'width':x1-x0,'height_including_staff':y1-y0,'bottom':y1-1,'border_pixels':int(m[0].sum()+m[-1].sum()+m[:,0].sum()+m[:,-1].sum()),'margin':min(x0,y0,128-x1,128-y1),'spill':n.spill_pixel_count(fr),'detail':n.interior_detail(fr),'detail_anchor_percent':round(n.interior_detail(fr)/n.interior_detail(anchor)*100,2),'binary_alpha':set(np.unique(a[...,3]).tolist())<={0,255}}
def boot_point(fr,box):
    a=np.asarray(fr)[box[1]:box[3],box[0]:box[2],3]>0
    yy,xx=np.nonzero(a);bottom=int(yy.max());band=a[max(0,bottom-4):bottom+1].any(0);xs=np.nonzero(band)[0]
    return {'box':box,'x':float((xs.min()+xs.max())/2+box[0]),'y':int(bottom+box[1])}
allframes={};metrics={'anchor':{'path':'art/bakeoff/newchar-2026-11-26/jupi/2/jupi-idle-2.png','detail':n.interior_detail(anchor)},'rows':{}}
template=h.head_template(anchor)
for row,spec in SPECS.items():
    fr=cells(REPORT/spec['source']);allframes[row]=fr;assert len(fr)==spec['count']
    measures=[inspect(x) for x in fr];heads=[h.head_scale(x,template) for x in fr];good=[s for s,c in heads if s and c>=.6]
    rowdata={**spec,'head_scale':{'frames':[{'scale':s,'score':round(c,4)} for s,c in heads],'median':round(float(np.median(good)),3) if good else None,'trusted':len(good)},'frames':measures,'detail_min_percent':min(x['detail_anchor_percent'] for x in measures),'detail_mean_percent':round(np.mean([x['detail_anchor_percent'] for x in measures]),2),'min_margin':min(x['margin'] for x in measures),'border_pixels':sum(x['border_pixels'] for x in measures),'spill_pixels':sum(x['spill'] for x in measures)}
    if row in ('hurt','land'):
        rev=json.loads((REPORT/Path(spec['source']).parent/'review.json').read_text(encoding='utf-8'))
        rowdata['shared_source_anchor_x']=rev['fixed_anchor_x']
        feet=[f.feet(np.asarray(x)[...,3]>0)[-2:] for x in fr]
        moves=[[abs(feet[i+1][j]['centre']-feet[i][j]['centre']) for j in range(2)] for i in range(len(fr)-1)]
        rowdata['planted_boot_centres']=[[x['centre'] for x in ff] for ff in feet];rowdata['planted_boot_dx']=moves;rowdata['max_planted_boot_dx']=max(v for pair in moves for v in pair)
    metrics['rows'][row]=rowdata
    board([anchor]+fr,['ANCHOR']+[f'{row.upper()} F{i+1}'+(' HOLD' if not spec['delivered'] else '') for i in range(len(fr))],REPORT/f'{row}.png')
    # 4x frame pairs retain a 1:4 display on ordinary image viewers.
    for k in range(0,len(fr),2):board([anchor]+fr[k:k+2],['ANCHOR']+[f'{row.upper()} F{i+1}' for i in range(k,min(k+2,len(fr)))],REPORT/f'{row}-pair-{k//2+1}.png')
    if spec['delivered']:
        assert rowdata['head_scale']['trusted']>=2 and .96<=rowdata['head_scale']['median']<=1.04
        assert rowdata['detail_min_percent']>=90 and rowdata['min_margin']>=4 and rowdata['border_pixels']==0 and rowdata['spill_pixels']==0
        assert all(x['binary_alpha'] for x in measures)
        if row=='land':assert rowdata['max_planted_boot_dx']<=3
        dst=OUT/f'jupi-{row}-v1.png';shutil.copy2(REPORT/spec['source'],dst)
        dst.with_suffix('.json').write_text(json.dumps({'note':spec['note'],'fps':spec['fps'],'frames':spec['count'],'loop':spec['loop']},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    gifs=[]
    for frame in fr:
        bg=Image.new('RGBA',(128,128),(43,48,57));bg.alpha_composite(frame);gifs.append(bg.resize((512,512),Image.Resampling.NEAREST).convert('RGB'))
    durations=[round((i+1)*100/spec['fps'])*10-round(i*100/spec['fps'])*10 for i in range(len(fr))]
    gifs[0].save(REPORT/f'{row}-4x.gif',save_all=True,append_images=gifs[1:],duration=durations,loop=0,disposal=2)

# Anatomical near/far identities and boot boxes were assigned by visual inspection.
# Coordinates are then measured from the actual opaque bottom band, not guessed.
boot_boxes=[
 {'near':[74,106,92,122],'far':[44,104,56,122]},
 {'near':[67,105,84,122],'far':[44,99,58,116]},
 {'near':[55,107,69,122],'far':[68,97,78,114]},
 {'near':[45,105,57,122],'far':[73,101,88,119]},
 {'near':[44,104,56,122],'far':[76,106,94,122]},
 {'near':[44,98,58,116],'far':[65,105,83,122]},
 {'near':[68,99,77,115],'far':[54,107,69,122]},
 {'near':[78,101,93,119],'far':[47,105,59,122]},
]
walk=allframes['walk'];feet=[{side:boot_point(fr,bx) for side,bx in boxes.items()} for fr,boxes in zip(walk,boot_boxes)]
moves=[]
for i in range(8):
    a,b=feet[i],feet[(i+1)%8];moves.append({side:round(math.hypot(b[side]['x']-a[side]['x'],b[side]['y']-a[side]['y']),3) for side in ('near','far')})
passings=[]
for i,side,other in [(2,'near','far'),(6,'far','near')]:
    midpoint=(feet[i-1][side]['x']+feet[i+1][side]['x'])/2
    passings.append({'frame':i+1,'support_leg':side,'support_x':feet[i][side]['x'],'neighbour_midpoint':midpoint,'error':round(feet[i][side]['x']-midpoint,3),'lifted_toe_y':feet[i][other]['y'],'lift_above_feet_line':120-feet[i][other]['y']})
feet_data={'method':'Boot ROIs and near/far identities manually designated on 4x boards; bottom 5 opaque rows measured. Staff excluded by ROI.','frames':feet,'moves_2d':moves,'max_move_2d':max(v for m in moves for v in m.values()),'passing':passings,'ground_runs_including_staff':json.loads((REPORT/'feet-with-staff.json').read_text()),'bob':json.loads((REPORT/'bob.json').read_text())}
(REPORT/'feet.json').write_text(json.dumps(feet_data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
metrics['rows']['walk']['feet_summary']={'max_move_2d':feet_data['max_move_2d'],'passing':passings}
metrics['rows']['walk']['bob']=feet_data['bob']
# ROI evidence at 4x, with foot identities displayed.
for start in range(0,8,2):
    frout=[]
    for i in range(start,start+2):
        bg=Image.new('RGBA',(128,128),(40,45,55));bg.alpha_composite(walk[i]);d=ImageDraw.Draw(bg)
        for side,color in [('near',(255,190,90)),('far',(90,220,255))]:
            bx=boot_boxes[i][side];d.rectangle((bx[0],bx[1],bx[2]-1,bx[3]-1),outline=color)
        frout.append(bg)
    board(frout,[f'WALK F{i+1}: orange NEAR / cyan FAR' for i in range(start,start+2)],REPORT/f'feet-roi-{start//2+1}.png',cols=2)

# Head crop comparisons, no art alteration.
head_frames=[('ANCHOR',anchor)]+[(f'{row} F{i+1}',fr) for row,frames in allframes.items() for i,fr in enumerate(frames)]
headsboard=Image.new('RGB',(256*5,240*((len(head_frames)+4)//5)),(38,42,52));d=ImageDraw.Draw(headsboard)
for i,(label,fr) in enumerate(head_frames):
    cy,cx=h.face_centre(np.asarray(fr));cx=round(cx);cy=round(cy)
    cut=fr.crop((cx-34,cy-30,cx+30,cy+24));bg=Image.new('RGBA',cut.size,(43,48,58));bg.alpha_composite(cut)
    x=(i%5)*256;y=(i//5)*240;headsboard.paste(bg.resize((256,216),Image.Resampling.NEAREST).convert('RGB'),(x,y+24));d.text((x+5,y+7),label,fill='white')
headsboard.save(REPORT/'heads-4x.png')
(REPORT/'metrics.json').write_text(json.dumps(metrics,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
# All final frames in a compact overview. HOLD is explicit for the undelivered row.
overview=Image.new('RGB',(128*2*8+130,292*5),(30,35,45));d=ImageDraw.Draw(overview)
for j,(row,frames) in enumerate(allframes.items()):
    spec=SPECS[row];d.text((12,j*292+20),row.upper()+(' / HOLD' if not spec['delivered'] else ''),fill=(255,180,100) if not spec['delivered'] else 'white')
    for i,fr in enumerate(frames):
        bg=Image.new('RGBA',(128,128),(43,48,58));bg.alpha_composite(fr);overview.paste(bg.resize((256,256),Image.Resampling.NEAREST).convert('RGB'),(130+i*256,j*292+30))
overview.save(REPORT/'overview.png')
print(json.dumps({row:{k:data[k] for k in ['delivered','min_margin','detail_min_percent','detail_mean_percent','head_scale']} for row,data in metrics['rows'].items()}))
print(json.dumps({'walk_feet':feet_data['max_move_2d'],'passing':passings}))
