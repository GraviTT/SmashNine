from pathlib import Path
import json
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];REPORT=ROOT/'reports/codex-art-97a'
data={}
for row in ('attack','shield','victory'):
    im=Image.open(REPORT/f'{row}-trial/{row}.png').convert('RGBA');c=im.height;y=c//2+56
    frames=[]
    for i in range(6):
        mask=np.array(im.crop((i*c,0,(i+1)*c,c)))[:,:,3]>0
        cols=mask[y-4:y+1,:].any(axis=0)
        groups=[];start=None
        for x,v in enumerate(cols.tolist()+[False]):
            if v and start is None:start=x
            if not v and start is not None:groups.append([start,x-1]);start=None
        frames.append({'frame':i+1,'feet_runs':groups,'centres':[sum(g)/2 for g in groups]})
    data[row]={'method':'bottom five alpha rows; not an anatomical foot detector','frames':frames}
(REPORT/'feet.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
for row,record in data.items():print(row,[f['centres'] for f in record['frames']])
