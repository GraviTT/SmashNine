"""Measure foot evidence. Staff runs are retained separately, not called feet."""
from process import REPORT,module,board,anchor,n
from PIL import Image,ImageDraw
import numpy as np,json
f=module('walk_feet')
result={}
for row in ['walk','hurt','hurt-a2','land','land-a2']:
    path=REPORT/'walk-after-bob.png' if row=='walk' else REPORT/row/'strip.png'
    im=Image.open(path).convert('RGBA');frames=[im.crop((i*128,0,(i+1)*128,128)) for i in range(im.width//128)]
    result[row]=[f.feet(np.asarray(x)[...,3]>0) for x in frames]
    board([anchor]+frames,['ANCHOR']+[f'{row.upper()} F{i+1}' for i in range(len(frames))],REPORT/f'{row}-feet-review.png')
    # Coordinate grid for identifying separate boot silhouettes only, never modifies art.
    sheet=Image.new('RGB',(600*len(frames),330),(33,37,45));d=ImageDraw.Draw(sheet)
    for i,frame in enumerate(frames):
        tile=n.checker((128,128),8).convert('RGBA');tile.alpha_composite(frame)
        tile=tile.crop((30,88,105,125)).resize((600,296),Image.Resampling.NEAREST).convert('RGB')
        sheet.paste(tile,(600*i,30))
        for x in range(30,106,5):
            xx=600*i+(x-30)*8;d.line((xx,30,xx,326),fill=(60,95,105));d.text((xx+1,15),str(x),fill='white')
        for y in range(90,125,5):
            yy=30+(y-88)*8;d.line((600*i,yy,600*(i+1)-1,yy),fill=(60,95,105));d.text((600*i+2,yy),str(y),fill='white')
    sheet.save(REPORT/f'{row}-feet-grid.png')
(REPORT/'feet-precheck.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result))
