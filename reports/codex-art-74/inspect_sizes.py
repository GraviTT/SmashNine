import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import process as p
from PIL import Image,ImageDraw
for mid in p.WINDUP:
    panel=Image.new('RGB',(6*400,440),(24,29,40));d=ImageDraw.Draw(panel)
    for ri,row in enumerate(p.ROWS):
        idx=1 if row=='hurt' else 0
        im=p.frames(p.BAKE/f'{mid}-{row}-v1.png',p.COUNTS[row])[idx]
        tile=p.n.checker((96,96)).convert('RGB');tile.paste(im,(0,0),im)
        panel.paste(tile.resize((384,384),Image.Resampling.NEAREST),(ri*400,40))
        d.text((ri*400+4,4),f'{row} F{idx+1}',font=p.n.font(18),fill='white')
        for xy in range(0,97,8):
            d.text((ri*400+xy*4,25),str(xy),font=p.n.font(10),fill=(180,180,190))
            d.text((ri*400,40+xy*4),str(xy),font=p.n.font(10),fill=(180,180,190))
    panel.save(p.REPORT/f'{mid}-size-ruler.png')
