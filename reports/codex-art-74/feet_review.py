import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
from PIL import Image,ImageDraw
import process as p
for mid in p.WINDUP:
    if mid=='svartalfheim_cog_drone':continue
    for row in p.ROWS:
        ims=p.frames(p.BAKE/f'{mid}-{row}-v1.png',p.COUNTS[row]);out=Image.new('RGB',(96*6*4,96*4+48),(24,29,40));d=ImageDraw.Draw(out)
        d.text((4,3),f'{mid} {row} | pink=72 | frame-local px',font=p.n.font(18),fill='white')
        for i,im in enumerate(ims):
            tile=p.n.checker((96,96)).convert('RGB');tile.paste(im,(0,0),im);out.paste(tile.resize((384,384),Image.Resampling.NEAREST),(384*i,48))
            d.line((384*i,48+72*4,384*(i+1),48+72*4),fill=(255,90,140),width=1)
            for x in range(0,96,8):d.text((384*i+x*4,30),str(x),font=p.n.font(10),fill='white')
            for y in range(16,88,8):d.text((384*i,48+y*4),str(y),font=p.n.font(10),fill='white')
            d.text((384*i+6,10),f'F{i+1}',font=p.n.font(12),fill='white')
        out.save(p.REPORT/mid/row/'feet-review-4x.png')
