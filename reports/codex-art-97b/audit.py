"""Artifact checks; manual landmarks remain explicit and separate from automatic metrics."""
from pathlib import Path
import sys,json,math,hashlib
import numpy as np
from PIL import Image,ImageDraw,ImageFont
sys.stdout.reconfigure(encoding='utf-8')
ROOT=Path(__file__).resolve().parents[2]
O=ROOT/'reports/codex-art-97b'
sys.path.insert(0,str(ROOT/'tools/sprite_pipeline'))
import normalize as norm
import head_scale as hs
import walk_feet
WALK=['walk-f1','walk-f2','walk-f3-a3','walk-f4','walk-f5','walk-f6-a2','walk-f7-a2','walk-f8']
CONFIG={'walk':(8,13.3,True),'jump':(3,10,False),'fall':(2,8,True),'hurt':(3,12,False),'land':(2,12,False)}
anchor=Image.open(ROOT/'art/bakeoff/xion/b/xion-idle-b2.png').convert('RGBA').crop((0,0,128,128))
template=hs.head_template(anchor)
frames={}
for row,(count,_,_) in CONFIG.items():
    source=O/'walk-after-bob.png' if row=='walk' else O/('fall-a2' if row=='fall' else row)/'frame.png'
    sheet=Image.open(source).convert('RGBA')
    frames[row]=[sheet.crop((i*128,0,(i+1)*128,128)) for i in range(count)]

# At 4x/8x, manually trace the midline of each fabric tail from nape to tip.
# These are image-coordinate observations, not automatic anatomy/cloth detections.
LINES={
'anchor': [[[55,53],[46,57],[35,59],[25,66]], [[55,53],[46,62],[36,66],[26,74]]],
'walk-1': [[[57,52],[48,56],[39,57],[28,64]], [[57,52],[48,61],[38,65],[29,72]]],
'walk-2': [[[55,54],[46,58],[36,59],[26,66]], [[55,54],[46,64],[37,66],[27,75]]],
'walk-3': [[[53,52],[43,57],[34,58],[23,64]], [[53,52],[43,63],[34,66],[23,73]]],
'walk-4': [[[53,50],[43,55],[33,55],[23,63]], [[53,50],[44,61],[33,64],[23,72]]],
'walk-5': [[[53,52],[43,56],[32,57],[22,64]], [[53,52],[43,62],[33,65],[23,72]]],
'walk-6': [[[57,54],[47,59],[38,60],[28,66]], [[57,54],[47,64],[38,67],[29,75]]],
'walk-7': [[[54,51],[45,55],[35,56],[25,62]], [[54,51],[44,61],[35,64],[26,71]]],
'walk-8': [[[53,50],[43,55],[33,56],[23,64]], [[53,50],[44,61],[33,64],[23,72]]],
'jump-1': [[[59,47],[50,52],[40,55],[31,64]], [[59,47],[51,57],[43,62],[34,71]]],
'jump-2': [[[59,39],[50,44],[40,47],[32,57]], [[59,39],[51,49],[43,53],[35,62]]],
'jump-3': [[[66,33],[57,36],[46,35],[37,40]], [[66,33],[57,40],[47,42],[38,49]]],
'fall-1': [[[55,35],[45,35],[37,30],[33,25],[30,24],[27,27]], [[55,35],[45,38],[35,37],[27,34],[19,38]]],
'fall-2': [[[54,35],[44,35],[36,31],[31,26],[25,26]], [[54,35],[44,38],[34,38],[26,35],[17,38]]],
'hurt-1': [[[59,55],[49,61],[39,61],[28,68]], [[59,55],[50,66],[40,70],[31,77]]],
'hurt-2': [[[54,57],[44,64],[34,65],[23,63]], [[54,57],[44,69],[34,71],[25,77]]],
'hurt-3': [[[62,54],[51,59],[42,60],[32,68]], [[62,54],[52,65],[42,69],[33,76]]],
'land-1': [[[56,65],[45,65],[37,59],[32,58],[27,62]], [[56,65],[45,69],[37,67],[32,65],[26,71]]],
'land-2': [[[53,55],[43,60],[35,58],[25,65]], [[53,55],[43,64],[34,67],[25,73]]],
}
def length(points):return sum(math.dist(a,b) for a,b in zip(points,points[1:]))
baseline=[length(x) for x in LINES['anchor']]
scarf={'method':'사람이 4×/8×에서 지정한 천 중심선의 다각선 길이. 목-끝 직선거리도 별도 기재. 좌표 약 ±1px, 곡선 길이 약 ±2px 추정 오차. 굽힘 때문에 직선거리는 길이 합격 판정에 사용하지 않음.','anchor_lengths_px':baseline,'frames':{}}
for name,lines in LINES.items():
    lengths=[length(x) for x in lines]
    errors=[100*(v/b-1) for v,b in zip(lengths,baseline)]
    scarf['frames'][name]={'manual_polylines':lines,'traced_lengths_px':lengths,'straight_reach_px':[math.dist(x[0],x[-1]) for x in lines],'error_percent':errors,'nominal_within_10_percent':all(abs(e)<=10 for e in errors)}
(O/'scarf.json').write_text(json.dumps(scarf,ensure_ascii=False,indent=2),encoding='utf-8')
allframes={'anchor':anchor,**{f'{row}-{i+1}':f for row,fs in frames.items() for i,f in enumerate(fs)}}
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',15)
for block in range(math.ceil(len(allframes)/6)):
    subset=list(allframes.items())[block*6:(block+1)*6]
    board=Image.new('RGB',(3*384,2*400),(42,45,52));d=ImageDraw.Draw(board)
    for j,(name,f) in enumerate(subset):
        tile=Image.new('RGBA',(128,128),(42,45,52,255));tile.alpha_composite(f)
        tile=tile.crop((16,0,112,90)).resize((384,360),Image.Resampling.NEAREST)
        td=ImageDraw.Draw(tile)
        for line,color in zip(LINES[name],['#ffe45e','#49ddff']):
            points=[((x-16)*4,y*4) for x,y in line]
            td.line(points,fill=color,width=1)
            for x,y in points:td.ellipse((x-2,y-2,x+2,y+2),outline=color,width=1)
        x,y=(j%3)*384,(j//3)*400
        d.text((x+4,y+4),name,fill='white',font=font);board.paste(tile.convert('RGB'),(x,y+24))
    board.save(O/f'scarf-landmarks-{block+1}.png')

# Foot ownership is judged from hip/knee overlap. Ground runs are automatic;
# boxes for the airborne boot tips are manually selected on the 4x grid.
lift_boxes={1:(24,60,100,116),2:(64,77,100,114),3:(65,105,100,116),5:(38,65,99,115),6:(62,77,103,115),7:(66,105,103,117)}
walk=frames['walk']; planted=[walk_feet.feet(np.asarray(f)[...,3]>0) for f in walk]
lifts={}
for i,(x0,x1,y0,y1) in lift_boxes.items():
    a=np.asarray(walk[i])[...,3]>0;ys,xs=np.nonzero(a[y0:y1,x0:x1]);bottom=int(ys.max())+y0
    _,xs=np.nonzero(a[bottom-3:bottom+1,x0:x1]);lifts[i]=[(int(xs.min())+int(xs.max()))/2+x0,bottom]
positions=[{'near':[83.5,120],'far':[42.5,120]},
 {'near':[planted[1][0]['centre'],120],'far':lifts[1]},
 {'near':[planted[2][0]['centre'],120],'far':lifts[2]},
 {'near':[planted[3][0]['centre'],120],'far':lifts[3]},
 {'near':[34.5,120],'far':[85.5,120]},
 {'near':lifts[5],'far':[planted[5][0]['centre'],120]},
 {'near':lifts[6],'far':[planted[6][0]['centre'],120]},
 {'near':lifts[7],'far':[planted[7][0]['centre'],120]}]
steps=[]
for i,p in enumerate(positions):
    q=positions[(i+1)%8]
    steps.append({'from':i+1,'to':(i+1)%8+1,**{leg:math.dist(p[leg],q[leg]) for leg in ('near','far')}})
passing=[]
for i in [2,6]:
    before=planted[i-1][0]['centre'];after=planted[i+1][0]['centre'];mid=(before+after)/2
    passing.append({'frame':i+1,'planted_runs':len(planted[i]),'centre':planted[i][0]['centre'],'neighbour_midpoint':mid,'error':planted[i][0]['centre']-mid,'lift_px':120-lifts[i][1]})
feet={'method':'지지발은 walk_feet.py의 y116–120 run. 들린 발은 사람이 지정한 사각형에서 발끝 하단 4줄의 x중심/최저 y를 계산. near/far 소속은 육안 판정. 이동량은 루프 끝→처음 포함 2D 거리.','lift_boxes':lift_boxes,'positions':positions,'steps':steps,'max_distance':max(s[k] for s in steps for k in ['near','far']),'passing':passing}
(O/'feet-motion.json').write_text(json.dumps(feet,ensure_ascii=False,indent=2),encoding='utf-8')

metrics={'anchor':'art/bakeoff/xion/b/xion-idle-b2.png:0','anchor_detail':norm.interior_detail(anchor),'head_method':'head_scale.py의 동일 함수/128px 셀. 신뢰 프레임 2개 미만인 hurt는 heads-4x 판을 육안 비교.','rows':{}}
for row,(count,fps,loop) in CONFIG.items():
    fs=frames[row];heads=[hs.head_scale(f,template) for f in fs];good=[v for v,s in heads if v is not None and s>=.6]
    fm=[]
    for i,f in enumerate(fs):
        a=np.asarray(f);b=f.getbbox();mar=norm.margins(b,128)
        fm.append({'frame':i+1,'bbox':b,'head_scale':heads[i][0],'head_score':heads[i][1],'detail':norm.interior_detail(f),'margin':mar,'border_clear':mar['minimum']>=1,'spill':norm.spill_pixel_count(f),'alpha_values':np.unique(a[...,3]).tolist(),'bottom_y':b[3]-1})
    factors=[json.loads((O/n/'head.json').read_text())['factor'] for n in WALK] if row=='walk' else [json.loads((O/('fall-a2' if row=='fall' else row)/'head.json').read_text())['factor']]
    d=[m['detail'] for m in fm]
    metrics['rows'][row]={'frames':count,'fps':fps,'loop':loop,'factors':factors,'head_median':float(np.median(good)) if len(good)>=2 else None,'head_used':len(good),'head_manual_review':row=='hurt','detail_range': [min(d),max(d)],'detail_percent_range':[100*min(d)/metrics['anchor_detail'],100*max(d)/metrics['anchor_detail']],'border_clear':all(m['border_clear'] for m in fm),'min_margin':min(m['margin']['minimum'] for m in fm),'spill':sum(m['spill'] for m in fm),'scarf_nominal_within_10_percent':all(scarf['frames'][f'{row}-{i+1}']['nominal_within_10_percent'] for i in range(count)),'frame_metrics':fm}
(O/'metrics.json').write_text(json.dumps(metrics,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'feet':feet,'scarf_failures':{k:v['error_percent'] for k,v in scarf['frames'].items() if not v['nominal_within_10_percent']},'rows':{k:{kk:vv for kk,vv in v.items() if kk!='frame_metrics'} for k,v in metrics['rows'].items()}},ensure_ascii=False))
