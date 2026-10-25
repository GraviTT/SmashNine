"""Independent stricter warm-paper measurement, excluding the bright cyan ring."""
import json
from collections import deque
import numpy as np
from PIL import Image, ImageDraw
from audit import ROOT, OUT
from prepare_root import ROIS
from paper_review import rotated_box

im=Image.open(ROOT/'art/bakeoff/story/cg_root-v5.png').convert('RGB')
rows=[]
for ident in [1,23,35]:
    roi=ROIS[ident-1];rgb=np.array(im.crop(roi),dtype=np.int16);r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    white=(r>140)&(g>140)&(b>110)&((r-b)>4)&(r>=g)&(g>=b)
    seen=set();parts=[];h,w=white.shape
    for y,x in np.argwhere(white):
        p=(int(x),int(y))
        if p in seen:continue
        seen.add(p);q=deque([p]);part=[]
        while q:
            xx,yy=q.popleft();part.append((xx,yy))
            for nx,ny in [(xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)]:
                p=(nx,ny)
                if 0<=nx<w and 0<=ny<h and white[ny,nx] and p not in seen:seen.add(p);q.append(p)
        parts.append(part)
    best=max(parts,key=len);mask=Image.new('L',(w,h));d=ImageDraw.Draw(mask)
    for p in best:d.point(p,255)
    measure=rotated_box(mask)
    rows.append({'roi_id':ident,'pixels':len(best),'bbox_local':list(mask.getbbox()),**measure})
data={'method':'Largest connected warm ivory region: R>140,G>140,B>110,R-B>4,R>=G>=B; minimum-area rotated rectangle. Excludes cool cyan ring; projection/curl still affects ratios.',
      'note_ko':'앞선 느슨한 마스크 측정은 청색 고리의 밝은 픽셀을 포함하여 가운데 부적 폭을 과대 추정했다. 이 보조 측정은 따뜻한 종이색만 사용한다. 원근이 포함된 화면상 비율이다.',
      'measurements':rows}
path=OUT/'paper-shape-refined-v1.json';assert not path.exists()
path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(data,ensure_ascii=True,indent=2))
