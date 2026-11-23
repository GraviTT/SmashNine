from pathlib import Path
import sys
import json
from PIL import Image, ImageDraw, ImageFont
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/'reports/codex-art-97a'
sys.path.insert(0,str(ROOT/'tools/sprite_pipeline'))
from normalize import clean_background, checker

anchor=Image.open(ROOT/'art/bakeoff/xion/b/xion-idle-b2.png').convert('RGBA').crop((0,0,128,128))
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)

for row in ('attack','shield','victory'):
    folder=REPORT/(row+'-trial')
    strip=Image.open(folder/(row+'.png')).convert('RGBA')
    cell=strip.height
    out=folder/'review'
    out.mkdir(exist_ok=True)
    tiles=[]
    for i in range(6):
        f=strip.crop((i*cell,0,(i+1)*cell,cell))
        board=checker(((128+cell)*4,cell*4+40))
        draw=ImageDraw.Draw(board)
        draw.rectangle((0,0,board.width,39),fill='#101520')
        draw.text((12,8),'ANCHOR 4x',font=font,fill='white')
        draw.text((524,8),f'{row.upper()} F{i+1} 4x',font=font,fill='white')
        a=anchor.resize((512,512),Image.Resampling.NEAREST)
        board.paste(a,(0,40+(cell-128)*2),a)
        s=f.resize((cell*4,cell*4),Image.Resampling.NEAREST)
        board.paste(s,(512,40),s)
        board.save(out/f'f{i+1}.png')
        tiles.append(board)
    full=Image.new('RGB',(tiles[0].width*2,tiles[0].height*3),'#101520')
    for i,t in enumerate(tiles):full.paste(t,((i%2)*t.width,(i//2)*t.height))
    full.save(REPORT/(row+'.png'))

# Failed strips are shown only as source crops. No repaired candidate is made.
for motion,attempt in (('defeat',1),('defeat',2),('attack',2)):
    raw=Image.open(ROOT/f'art/raw/xion-97a/{motion}-{attempt}.png').convert('RGBA')
    a,_=clean_background(raw,'#00ff00')
    mask=np.array(a.getchannel('A'))>0
    columns=mask.any(axis=0)
    runs=[]; start=None
    for x,v in enumerate(columns.tolist()+[False]):
        if v and start is None:start=x
        if not v and start is not None:
            runs.append([start,x]);start=None
    merged=[]
    for run in runs:
        if merged and run[0]-merged[-1][1]<12:merged[-1][1]=run[1]
        else:merged.append(run)
    out=REPORT/f'{motion}-rejected-{attempt}'
    out.mkdir(exist_ok=True)
    boxes=[]
    for i,(left,right) in enumerate(merged):
        ys=np.where(mask[:,left:right])[0]
        box=(max(0,left-3),max(0,int(ys.min())-3),min(raw.width,right+3),min(raw.height,int(ys.max())+4))
        raw.crop(box).resize(((box[2]-box[0])*4,(box[3]-box[1])*4),Image.Resampling.NEAREST).save(out/f'f{i+1}-source-4x.png')
        boxes.append(box)
    (out/'source-crops.json').write_text(json.dumps({'purpose':'inspection only; source grid rejected; no normalization or delivery','boxes':boxes},indent=2),encoding='utf-8')
    print(motion,attempt,'source crops',len(boxes),raw.size)
print('review boards ready')
