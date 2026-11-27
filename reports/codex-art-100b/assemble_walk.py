from process import ROOT,REPORT,RAW,n,h,board,module,anchor
from PIL import Image,ImageDraw
import numpy as np,json
b=module('walk_bob');f=module('walk_feet')
selected=['walk-f1','walk-f2','walk-f3-a3','walk-f4','walk-f5','walk-f6','walk-f7-a3','walk-f8']
frames=[Image.open(REPORT/s/'strip.png').convert('RGBA') for s in selected]
strip=Image.fromarray(np.concatenate([np.asarray(x) for x in frames],axis=1))
strip.save(REPORT/'walk-before-bob.png')
cy,cx=h.face_centre(np.asarray(frames[0]));box=(round(cx)-11,round(cy)-9,round(cx)+8,round(cy)+8)
arrays=[np.asarray(x) for x in frames]
before=[b.head_offset(arrays[0],x,box) for x in arrays]
target,shifts=b.fit_target([x[0] for x in before],(0,2,-1,-2))
data={'selected':selected,'face_box':box,'heads':before,'target':target,'shifts':shifts,'feet_including_staff':[f.feet(x[...,3]>0) for x in arrays]}
(REPORT/'walk-precheck.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
board([anchor]+frames,['ANCHOR']+[f'WALK F{i+1}' for i in range(8)],REPORT/'walk-pre.png')
grid=Image.new('RGB',(576*4,320*2),(35,40,50));d=ImageDraw.Draw(grid)
for i,im in enumerate(frames):
    tile=im.crop((28,86,100,124));bg=Image.new('RGBA',tile.size,(45,50,60));bg.alpha_composite(tile)
    x=(i%4)*576;y=(i//4)*320;grid.paste(bg.resize((576,304),Image.Resampling.NEAREST).convert('RGB'),(x,y+16));d.text((x+4,y+2),f'F{i+1} crop x28..100 y86..124',fill='white')
grid.save(REPORT/'feet-grid.png')
print(json.dumps(data))
