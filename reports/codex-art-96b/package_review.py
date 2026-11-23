"""Package ART-96 B measurements and review boards; never edits sprite pixels."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib
import json
import math
import statistics
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
R = ROOT / 'reports/codex-art-96b'
RAW = ROOT / 'art/raw/xion-96b'
CAND = ROOT / 'art/bakeoff/xion/b/xion-idle-b2.png'
FONT = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf', 18)
SMALL = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf', 14)

def write(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def frames(path):
    im = Image.open(path).convert('RGBA')
    return [im.crop((128*i, 0, 128*(i+1), 128)) for i in range(6)]

def stamp(board, frame, x, y, scale=4):
    board.alpha_composite(frame.resize((frame.width*scale, frame.height*scale), Image.Resampling.NEAREST), (x,y))

old = frames(ROOT / 'art/bakeoff/xion/b/xion-idle-b.png')
new = frames(CAND)
rio = frames(ROOT / 'smash-nine-prototype/assets/art/rio/rio_female_sheet.png')
normalization = json.loads((R / 'normalized/metrics.json').read_text(encoding='utf-8'))

# One full-size board plus six practical full-4x pair views.
board = Image.new('RGBA', (3072,1104), '#2a2d34')
d = ImageDraw.Draw(board)
for i in range(6):
    for y, seq, label in [(0,old,'v1'),(552,new,'v2')]:
        stamp(board,seq[i],512*i,y+40)
        d.text((512*i+12,y+9),f'{label} F{i+1} / 4x',font=FONT,fill='white')
    pair = Image.new('RGBA',(1040,552),'#2a2d34'); dp=ImageDraw.Draw(pair)
    for x,seq,label in [(0,old,'v1'),(528,new,'v2')]:
        stamp(pair,seq[i],x,40)
        dp.text((x+12,10),f'{label} F{i+1} / 4x',font=FONT,fill='white')
    pair.convert('RGB').save(R/f'review-{i+1}.png')
board.convert('RGB').save(R/'compare.png')

headboard=Image.new('RGBA',(1024,800),'#c8c4b8'); dh=ImageDraw.Draw(headboard)
heads=[('v1 F1',old[0],(36,20,92,64)),('Rio female F1',rio[0],(60,20,116,64))]
heads += [(f'v2 F{i+1}',f,(36,20,92,64)) for i,f in enumerate(new)]
for i,(label,f,box) in enumerate(heads):
    x=(i%4)*256; y=(i//4)*400
    dh.text((x+12,y+12),label,font=FONT,fill='#20242b')
    stamp(headboard,f.crop(box),x+12,y+55,4)
    stamp(headboard,f,x+64,y+260,1)
headboard.convert('RGB').save(R/'heads-4x.png')

# Manual landmarks are visually selected in the FINAL 128px cells.
# They are not anatomical detections; integer-point uncertainty is about +/-1px.
nape=[(55,53),(55,53),(55,52),(56,53),(55,53),(55,53)]
upper=[(26,65),(26,65),(26,63),(27,63),(26,64),(26,65)]
lower=[(27,74),(27,73),(27,71),(28,70),(27,72),(27,73)]
illustration={'crown_y':92,'sole_y':1443,'standing_height_px':1352,
    'nape':[441,321],'upper_tip':[63,600],'lower_tip':[95,698],
    'landmarks':'육안 지정, 일러스트 좌표 오차 약 ±3px'}
illustration['fractions_euclidean']=[math.dist(illustration['nape'],illustration[k])/1352 for k in ('upper_tip','lower_tip')]
illustration['fractions_horizontal']=[abs(441-illustration[k][0])/1352 for k in ('upper_tip','lower_tip')]
scarf={'measurement':'목 뒤 부착점에서 꼬리 끝까지의 직선거리 / 정수리–발끝 높이. 천의 곡선 길이가 아님. 수평 투영도 함께 보고.',
       'method':'목 뒤와 꼬리 끝 부근을 사람이 지정. 각 끝 부근 5×5 창에서 목 뒤로부터 가장 먼 불투명 픽셀(검은 외곽선 포함)을 끝으로 계산. 목 뒤 좌표 오차 약 ±1px. 최초 수동 끝점도 보존.',
       'illustration':illustration,'frames':[]}
scarfb=Image.new('RGBA',(1008,576),'#2a2d34'); ds=ImageDraw.Draw(scarfb)
for i,(f,n,u,l) in enumerate(zip(new,nape,upper,lower)):
    manual_tips=[u,l]
    a=np.asarray(f)
    def outline_tip(p):
        x,y=p
        visible=[(xx,yy) for yy in range(y-2,y+3) for xx in range(x-2,x+3) if a[yy,xx,3]>0]
        return max(visible,key=lambda point:math.dist(n,point))
    u,l=outline_tip(u),outline_tip(l)
    h=normalization['frames'][i]['body_height']; reach=[math.dist(n,p) for p in (u,l)]
    frac=[v/h for v in reach]; horiz=[(n[0]-p[0])/h for p in (u,l)]
    deviation=[100*(v/ref-1) for v,ref in zip(frac,illustration['fractions_euclidean'])]
    hdev=[100*(v/ref-1) for v,ref in zip(horiz,illustration['fractions_horizontal'])]
    scarf['frames'].append({'frame':i+1,'standing_height_px':h,'nape':n,'upper_tip':u,'lower_tip':l,'manual_tip_neighbourhood_centres':manual_tips,
        'reach_px':reach,'fraction':frac,'relative_error_percent':deviation,
        'within_10_percent_euclidean':all(abs(v)<=10 for v in deviation),
        'horizontal_fraction':horiz,'horizontal_error_percent':hdev,
        'within_10_percent_horizontal':all(abs(v)<=10 for v in hdev)})
    x=(i%3)*336; y=(i//3)*288
    ds.text((x+8,y+10),f'F{i+1}: {reach[0]:.2f} / {reach[1]:.2f} px',font=FONT,fill='white')
    crop=(16,44,72,84)
    stamp(scarfb,f.crop(crop),x,y+44,6)
    for p,color in [(n,'#ffdf54'),(u,'#5ae5ff'),(l,'#ff8bda')]:
        px=x+(p[0]-16)*6+3; py=y+44+(p[1]-44)*6+3
        ds.ellipse((px-4,py-4,px+4,py+4),outline=color,width=2)
    for p,color in [(u,'#5ae5ff'),(l,'#ff8bda')]:
        ds.line((x+(n[0]-16)*6+3,y+44+(n[1]-44)*6+3,x+(p[0]-16)*6+3,y+44+(p[1]-44)*6+3),fill=color,width=1)
scarfb.convert('RGB').save(R/'scarf-landmarks.png')
for j,label in enumerate(('upper','lower')):
    values=[f['reach_px'][j] for f in scarf['frames']]
    med=statistics.median(values)
    scarf[label+'_consistency']={'median_px':med,'min_px':min(values),'max_px':max(values),
       'peak_to_peak_px':max(values)-min(values),'max_deviation_from_median_px':max(abs(v-med) for v in values),
       'within_plus_minus_2px':all(abs(v-med)<=2 for v in values)}
scarf['all_euclidean_within_10_percent']=all(f['within_10_percent_euclidean'] for f in scarf['frames'])
scarf['all_horizontal_within_10_percent']=all(f['within_10_percent_horizontal'] for f in scarf['frames'])
write(R/'scarf.json',scarf)

def feet(seq):
    out=[]
    for i,f in enumerate(seq):
        a=np.asarray(f); xs=np.flatnonzero((a[116:121,:,3]>0).any(axis=0)); runs=np.split(xs,np.where(np.diff(xs)>1)[0]+1)
        out.append({'frame':i+1,'feet':[{'min_x':int(s.min()),'max_x':int(s.max()),'center_x':float((s.min()+s.max())/2)} for s in runs]})
    return out

foot=feet(new)
footranges=[max(f['feet'][j]['center_x'] for f in foot)-min(f['feet'][j]['center_x'] for f in foot) for j in range(2)]
gif=[]
for f in new:
    tile=Image.new('RGBA',(512,512),'#2a2d34');stamp(tile,f,0,0)
    gif.append(tile.convert('RGB'))
gif[0].save(R/'idle-4x.gif',save_all=True,append_images=gif[1:],duration=[160,160,160,160,160,150],loop=0,optimize=False,disposal=2)
write(CAND.with_suffix('.json'),{'note':'Xion B 대기 v2. 전신 원화에 맞춘 긴 진홍 스카프 두 꼬리. 6프레임 공통 배율·공통 가로 기준점, 발 y=120. 세부 검수와 제한은 reports/codex-art-96b/README.md 참고.','fps':6.3,'frames':6,'loop':True})

heads={k:json.loads((R/f'head-{k}.json').read_text(encoding='utf-8'))[0] for k in ('self','rio','v1')}
metrics={'normalization':normalization,'head_scale':heads,'feet':{'final':foot,'v1':feet(old),'center_range_px':footranges,
    'method':'발 밑 5줄(y116..120)의 연결 x 구간 외곽 중점. 자동 측정, 해부학적 발 중심이 아님.'},
    'manual_head_proportions':{'method':'정수리·턱을 눈으로 지정. 주 머리 기준, Rio 높은 포니테일 장식 제외. ±1~2px.',
      'xion_f1_crown_y':24,'xion_f1_chin_y':51,'xion_head_height_px':28,'xion_standing_height_px':97,'xion_heads_tall':97/28,
      'rio_main_crown_y':31,'rio_chin_y':57,'rio_main_head_height_px':27,'height_ratio_xion_to_rio':28/27},
    'scarf_summary':{k:v for k,v in scarf.items() if k not in ('frames','illustration')},
    'animation':{'configured_fps':6.3,'gif_durations_ms':[160,160,160,160,160,150],'gif_total_ms':950,'gif_effective_fps':6/0.950,
      'visual_note':'스카프가 F3에서 들리고 F4에서 가장 높음. 머리카락의 별도 한 프레임 지연과 가슴 호흡은 128px에서 뚜렷하지 않음. 실시간 게임 검증 안 함.'},
    'selected_generation':3,'generation_count':3,'raw':'art/raw/xion-96b/idle-attempt3.png',
    'manual_review':{'all_six_frames_at_4x':True,'single_face':True,'both_arms_hands_guns_feet_visible':True,
      'note':'쥔 손의 개별 손가락까지 낱개 판독하는 해상도는 아님. 두 산탄총의 넓은 총구·펌프·은색 패널을 확인.'},
    'detail_ratio_to_rio_f1':normalization['summary']['interior_detail_mean']/normalization['reference']['frames'][0]['interior_detail'],
    'sha256':{str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in [CAND,RAW/'idle-attempt3.png',RAW/'reference-v1-original-sheet.png']}}
write(R/'metrics.json',metrics)
print(json.dumps({'scarf_euclidean_pass':scarf['all_euclidean_within_10_percent'],'scarf_horizontal_pass':scarf['all_horizontal_within_10_percent'],
 'lengths':[f['reach_px'] for f in scarf['frames']],'feet_ranges':footranges,'detail':normalization['summary']['interior_detail_ratio']},ensure_ascii=False))
