from pathlib import Path
import json,math
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2];REPORT=ROOT/'reports/codex-art-97a'
# Landmarks chosen by eye from scarf-ruler boards, not automatic anatomy detection.
# Coordinates are original output pixels. Order: nape, upper tip, lower tip.
points={
 'attack':[
  [[58,50],[28,61],[30,69]],
  [[55,50],[26,61],[27,70]],
  [[54,50],[32,69],[36,77]],
  [[54,49],[27,63],[28,72]],
  [[51,49],[24,62],[25,71]],
  [[55,49],[25,61],[26,68]],
 ],
 'shield':[
  [[56,47],[27,59],[27,67]],
  [[60,47],[33,59],[32,69]],
  [[58,48],[30,59],[30,69]],
  [[58,49],[30,61],[31,71]],
  [[61,50],[34,65],[35,72]],
  [[62,50],[36,67],[36,76]],
 ],
 'victory':[
  [[90,84],[60,97],[61,106]],
  [[84,84],[55,98],[56,106]],
  [[97,84],[68,99],[69,107]],
  [[84,84],[53,98],[54,106]],
  [[96,84],[65,99],[65,107]],
  [[97,84],[66,99],[66,107]],
 ]}
reference={'nape':[55,53],'tips':[[25,66],[26,74]]}
lengths=[math.dist(reference['nape'],t) for t in reference['tips']]
result={'method':'사람이 8배 좌표판에서 목 뒤·두 꼬리 끝을 지정한 직선거리. 오차 약 ±1~2px; 굽은 천의 실제 길이가 아니며, 가려진 목 뒤는 추정. 통과 여부는 지정값 기준으로만 계산한다.','reference':{**reference,'lengths':lengths},'rows':{}}
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
for row,frames in points.items():
    strip=Image.open(REPORT/f'{row}-trial/{row}.png').convert('RGBA');c=strip.height
    cards=[];records=[]
    for i,(nape,upper,lower) in enumerate(frames):
        f=strip.crop((i*c,0,(i+1)*c,c));scale=4
        b=Image.new('RGB',(c*scale,c*scale+32),'#353c49');s=f.resize((c*scale,c*scale),Image.Resampling.NEAREST);b.paste(s,(0,32),s);d=ImageDraw.Draw(b)
        d.text((10,6),f'{row} F{i+1}',font=font,fill='white')
        for tip,color in ((upper,'#43ddff'),(lower,'#ffc65c')):
            p=(nape[0]*scale+2,nape[1]*scale+34);q=(tip[0]*scale+2,tip[1]*scale+34)
            d.line((*p,*q),fill=color,width=1)
            for x,y in (p,q):d.ellipse((x-3,y-3,x+3,y+3),outline=color,width=1)
        measured=[math.dist(nape,t) for t in (upper,lower)]
        errors=[100*(v/ref-1) for v,ref in zip(measured,lengths)]
        records.append({'frame':i+1,'nape':nape,'tips':[upper,lower],'straight_length_px':measured,'error_percent':errors,'within_10_percent':[abs(e)<=10 for e in errors]})
        cards.append(b)
    board=Image.new('RGB',(cards[0].width*3,cards[0].height*2),'#11151b')
    for i,b in enumerate(cards):board.paste(b,((i%3)*b.width,(i//3)*b.height))
    board.save(REPORT/f'{row}-scarf-landmarks.png')
    result['rows'][row]=records
(REPORT/'scarf.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
for row,items in result['rows'].items():
    errors=[v for f in items for v in f['error_percent']]
    print(row,'range',round(min(errors),2),round(max(errors),2),'outside',[(f['frame'],[round(e,2) for e in f['error_percent']]) for f in items if not all(f['within_10_percent'])])
