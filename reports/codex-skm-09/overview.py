"""Contact sheet of inspected sprites; no modification of the delivered assets."""
import json
from PIL import Image, ImageDraw, ImageFont
from config import ROOT
rows=json.loads((ROOT/'selection.json').read_text(encoding='utf-8'))
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',16)
small=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',13)
title=ImageFont.truetype('C:/Windows/Fonts/malgunbd.ttf',24)
W=1320; row_h=175
im=Image.new('RGB',(W,90+row_h*len(rows)),(24,30,43));d=ImageDraw.Draw(im)
d.text((16,10),'리오 SKM-09 · 몸 동작 검수표',font=title,fill='white')
d.text((16,47),'왼쪽은 대기 기준 · 오른쪽은 F1 → F6 · 초록: 후보 전달 / 주황: 보류 · 게임에 반영하지 않음',font=font,fill=(199,211,227))
for i,r in enumerate(rows):
 y=86+i*row_h;key=r['stem']+'-'+r['row'];color=(101,224,165) if r['accepted'] else (255,179,93)
 d.text((16,y),('전달  ' if r['accepted'] else '보류  ')+key,font=font,fill=color)
 base=ROOT/r['stem']/r['row']/f'attempt-{r["attempt"]}'
 sheet=Image.open(base/(key+'.png')).convert('RGBA')
 # Retain exact 1x pixels; omit only transparent top/bottom padding in the overview.
 crop=sheet.crop((0,24,1152,160)); im.paste(crop,(152,y+29),crop)
 a=Image.open(f'art/bakeoff/rio/{r["stem"]}-idle-v2.png').convert('RGBA').crop((0,0,128,128))
 bottom=a.getbbox()[3]-1; im.paste(a,(12,y+29+128-bottom),a)
 d.line((10,y+29+128,1305,y+29+128),fill=(146,72,86))
 d.line((10,y+row_h-3,1305,y+row_h-3),fill=(53,66,85))
im.save(ROOT/'overview.png')
print(ROOT/'overview.png')
