"""Review every generated sprite at normalized 4x, including unused attempts."""
import sys,subprocess,math
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2];REP=ROOT/'reports/codex-art-99b';RAW=ROOT/'art/raw/newchar-99b'
selected={'doron-1-idle-v1.png':('doron',1),'doron-2-idle-v4.png':('doron',2),'doron-3-idle-v3.png':('doron',3),'jupi-2-idle-v2.png':('jupi',2),'jupi-3-idle-v5.png':('jupi',3)}
paths=sorted(p for p in RAW.glob('*-idle-v*.png'))
board=Image.new('RGBA',(2560,math.ceil(len(paths)/5)*560),'#2a2d34');d=ImageDraw.Draw(board)
ft=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
for i,p in enumerate(paths):
    if p.name in selected:
        c,n=selected[p.name];im=Image.open(ROOT/f'art/bakeoff/newchar-2026-11-26/{c}/{n}/{c}-idle-{n}.png').convert('RGBA')
    else:
        out=REP/'attempts'/p.stem
        cmd=[sys.executable,str(ROOT/'tools/sprite_pipeline/normalize.py'),'--sheet',str(p),'--grid','1x1','--bg','#00ff00','--cell','128','--scale-by',f"height:{108 if p.name.startswith('jupi') else 88}",'--feet-y','120','--resample','lanczos','--sharpen','60','--despill','auto','--palette','none','--out-dir',str(out),'--name',p.stem,'--compare-scale','4']
        cp=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True)
        if cp.returncode:raise RuntimeError(cp.stdout+cp.stderr)
        im=Image.open(next((out/'frames').glob('*.png'))).convert('RGBA')
    x=(i%5)*512;y=(i//5)*560
    d.text((x+10,y+6),p.stem+(' [SELECTED]' if p.name in selected else ' [unused]'),font=ft,fill='#ffdc67' if p.name in selected else '#c8c4b8')
    board.alpha_composite(im.resize((512,512),Image.Resampling.NEAREST),(x,y+36))
board.convert('RGB').save(REP/'attempts-contact.png')
print(f'Review sheet: {len(paths)} generated sprites, 4x nearest-neighbour.')
