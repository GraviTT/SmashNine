from pathlib import Path
import sys,json
import numpy as np
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/'reports/codex-art-97a'
sys.path.insert(0,str(ROOT/'tools/sprite_pipeline'))
from head_scale import face_centre
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',12)
items=[]
for row in ('attack','shield','victory'):
    im=Image.open(REPORT/f'{row}-trial/{row}.png').convert('RGBA');c=im.height
    cards=[]
    for i in range(6):
        f=im.crop((i*c,0,(i+1)*c,c))
        cy,cx=face_centre(np.asarray(f))
        left=max(0,round(cx)-51);top=max(0,round(cy)-4)
        crop=f.crop((left,top,left+64,top+48)).resize((512,384),Image.Resampling.NEAREST)
        b=Image.new('RGB',(552,424),'#343b48');b.paste(crop,(40,40),crop)
        d=ImageDraw.Draw(b)
        for x in range(0,65,4):
            d.line((40+x*8,40,40+x*8,424),fill='#687587',width=1)
            d.text((40+x*8,22),str(left+x),font=font,fill='white')
        for y in range(0,49,4):
            d.line((40,40+y*8,552,40+y*8),fill='#687587',width=1)
            d.text((15,40+y*8),str(top+y),font=font,fill='white')
        d.text((4,3),f'{row.upper()} F{i+1}',font=font,fill='white');cards.append(b)
        items.append({'row':row,'frame':i+1,'face_centre_yx':[cy,cx],'view_origin':[left,top]})
    board=Image.new('RGB',(552*3,424*2),'#11151b')
    for i,b in enumerate(cards):board.paste(b,((i%3)*552,(i//3)*424))
    board.save(REPORT/f'{row}-scarf-ruler.png')
(REPORT/'landmark-helper.json').write_text(json.dumps(items,indent=2),encoding='utf-8')
