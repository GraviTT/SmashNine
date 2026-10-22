"""Whole-frame translations and manually located feature measurements, ART-71 method."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import sys,json,statistics
from PIL import Image,ImageDraw
import process as p

def translate(mid,row,deltas,reason):
    out=p.REPORT/mid/row; mp=out/'metrics.json';m=json.loads(mp.read_text('utf-8'))
    ims=p.frames(p.BAKE/f'{mid}-{row}-v1.png',p.COUNTS[row]); fixed=[]
    assert len(deltas)==len(ims)
    for i,(im,delta) in enumerate(zip(ims,deltas)):
        b=im.getbbox(); box=[b[k]+delta[k%2] for k in range(4)]
        assert p.n.margins(tuple(box),96)['minimum']>=3,(mid,row,i,box)
        dst=Image.new('RGBA',(96,96));dst.alpha_composite(im,tuple(delta));fixed.append(dst)
        dst.save(out/'frames'/f'{mid}-{row}-v1-{i:02d}.png')
    p.n.save_sheet(fixed,p.BAKE/f'{mid}-{row}-v1.png',96)
    p.n.save_sheet(fixed,out/f'{mid}-{row}-v1.png',96)
    p.n.write_visuals(fixed,out,None,f'{mid} {row}',72,4)
    m.setdefault('whole_frame_translations',[]).append(dict(reason=reason,deltas=deltas))
    mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),'utf-8');p.audit(mid,row)

if __name__=='__main__':
    translate(sys.argv[1],sys.argv[2],json.loads(sys.argv[3]),sys.argv[4])
