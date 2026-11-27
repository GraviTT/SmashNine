from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2]
REP=ROOT/'reports/codex-art-99b'
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',13)
for c,n in [('doron',1),('doron',2),('doron',3),('jupi',2),('jupi',3)]:
    im=Image.open(ROOT/f'art/bakeoff/newchar-2026-11-26/{c}/{n}/{c}-idle-{n}.png').convert('RGBA')
    canvas=Image.new('RGBA',(552,552),'#2a2d34')
    canvas.alpha_composite(im.resize((512,512),Image.Resampling.NEAREST),(40,40))
    d=ImageDraw.Draw(canvas)
    for p in range(0,129,4):
        col='#555555' if p%8==0 else '#373a41'
        d.line((40,40+p*4,551,40+p*4),fill=col)
        if p%4==0:d.text((3,34+p*4),str(p),font=font,fill='white')
    for p in range(0,129,8):
        d.text((35+p*4,16),str(p),font=font,fill='white')
    canvas.convert('RGB').save(REP/f'{c}-{n}-grid.png')
