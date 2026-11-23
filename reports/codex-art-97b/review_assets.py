from pathlib import Path
import sys,json,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2]
O=ROOT/'reports/codex-art-97b'
sys.path.insert(0,str(ROOT/'tools/sprite_pipeline'))
import normalize as norm
import head_scale as hs
anchor=Image.open(ROOT/'art/bakeoff/xion/b/xion-idle-b2.png').convert('RGBA').crop((0,0,128,128))
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',14)
rows={}
walk=Image.open(O/'walk-after-bob.png').convert('RGBA')
rows['walk']=[walk.crop((i*128,0,(i+1)*128,128)) for i in range(8)]
for name,n in [('jump',3),('fall',2),('hurt',3),('land',2)]:
    strip=Image.open(O/('fall-a2' if name=='fall' else name)/'frame.png').convert('RGBA')
    rows[name]=[strip.crop((i*128,0,(i+1)*128,128)) for i in range(n)]
allframes=[('anchor',anchor)]+[(f'{name}-{i+1}',f) for name,fs in rows.items() for i,f in enumerate(fs)]
for name,fs in rows.items():
    segments=[norm.render_row([anchor,*fs[i:i+3]],f'{name.upper()} {i+1}+',120,4) for i in range(0,len(fs),3)]
    board=Image.new('RGB',(max(t.width for t in segments),sum(t.height for t in segments)),(21,25,34))
    y=0
    for t in segments:board.paste(t,(0,y));y+=t.height
    board.save(O/f'{name}.png')
    preview=[]
    for f in fs:
        im=Image.new('RGBA',(128,128),(42,45,52,255));im.alpha_composite(f)
        preview.append(im.convert('RGB').resize((512,512),Image.Resampling.NEAREST))
    fps={'walk':13.3,'jump':10,'fall':8,'hurt':12,'land':12}[name]
    duration=[int(round((i+1)*100/fps)*10-round(i*100/fps)*10) for i in range(len(preview))]
    preview[0].save(O/f'{name}-4x.gif',save_all=True,append_images=preview[1:],duration=duration,loop=0,disposal=2)
# 4x head crops are fixed 52px wide, centred on the face without scaling them separately.
for block in range(math.ceil(len(allframes)/8)):
    subset=allframes[block*8:(block+1)*8]
    board=Image.new('RGB',(4*224,2*240),(42,45,52));d=ImageDraw.Draw(board)
    for j,(name,f) in enumerate(subset):
        ar=np.asarray(f); center=hs.face_centre(ar)
        cy,cx=(int(round(v)) for v in center) if center else (40,68)
        crop=f.crop((cx-30,cy-30,cx+22,cy+20))
        tile=Image.new('RGBA',crop.size,(42,45,52,255));tile.alpha_composite(crop)
        x,y=(j%4)*224,(j//4)*240
        d.text((x+4,y+4),name,fill='white',font=font)
        board.paste(tile.convert('RGB').resize((208,200),Image.Resampling.NEAREST),(x,y+24))
    board.save(O/f'heads-4x-{block+1}.png')
# Scarf and boot measurement boards: actual pixel coordinates on 4x grids.
for kind,box in [('scarf',(16,0,112,90)),('feet',(20,85,108,128))]:
    for block in range(math.ceil(len(allframes)/4)):
        subset=allframes[block*4:(block+1)*4]
        tw,th=(box[2]-box[0])*4,(box[3]-box[1])*4
        board=Image.new('RGB',(2*(tw+24),2*(th+40)),(42,45,52));d=ImageDraw.Draw(board)
        for j,(name,f) in enumerate(subset):
            x,y=(j%2)*(tw+24),(j//2)*(th+40)
            crop=f.crop(box);tile=Image.new('RGBA',crop.size,(42,45,52,255));tile.alpha_composite(crop)
            board.paste(tile.convert('RGB').resize((tw,th),Image.Resampling.NEAREST),(x+24,y+24))
            d.text((x+26,y+2),name,fill='white',font=font)
            for xx in range(math.ceil(box[0]/8)*8,box[2],8):
                px=x+24+(xx-box[0])*4;d.line((px,y+24,px,y+24+th),fill=(72,75,82));d.text((px,y+24),str(xx),fill=(190,200,210),font=font)
            for yy in range(math.ceil(box[1]/8)*8,box[3],8):
                py=y+24+(yy-box[1])*4;d.line((x+24,py,x+24+tw,py),fill=(72,75,82));d.text((x,py),str(yy),fill=(190,200,210),font=font)
        board.save(O/f'{kind}-grid-{block+1}.png')
print('Built full 4x boards, heads, scarf/feet coordinate grids and GIFs.')
