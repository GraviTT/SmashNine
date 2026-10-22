"""Inspect connected colour features; boxes are visual-reviewed proxies, not anatomical truth."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json,statistics,math
from collections import deque
from PIL import Image,ImageDraw
import process as p

def groups(mask):
    seen=p.n.np.zeros(mask.shape,bool);out=[]
    for sy,sx in zip(*p.n.np.where(mask)):
        if seen[sy,sx]:continue
        q=deque([(int(sx),int(sy))]);seen[sy,sx]=True;pts=[]
        while q:
            x,y=q.popleft();pts.append((x,y))
            for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if 0<=nx<96 and 0<=ny<96 and mask[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;q.append((nx,ny))
        if len(pts)>2:
            xs,ys=zip(*pts);out.append(dict(area=len(pts),bbox=[min(xs),min(ys),max(xs)+1,max(ys)+1]))
    return sorted(out,key=lambda g:g['area'],reverse=True)

def inspect(mid):
    panel=Image.new('RGB',(384*6,430),(24,29,40));d=ImageDraw.Draw(panel);res={}
    for ri,row in enumerate(p.ROWS):
        im=p.frames(p.BAKE/f'{mid}-{row}-v1.png',1)[0];a=p.n.np.array(im).astype(float);r,g,b,alpha=[a[:,:,i] for i in range(4)]
        if 'slinger' in mid:mask=(r>70)&(r>g*1.35)&(r>b*1.8)&(alpha>0);mask[52:]=False
        elif 'golem' in mid:mask=(g>100)&(b>130)&(g>r*1.2)&(b>r*1.5)&(alpha>0)
        elif 'drone' in mid:mask=(r>220)&(g>85)&(g<210)&(b<90)&(alpha>0)
        else:mask=(r>160)&(g>110)&(b<110)&(alpha>0)
        gs=groups(mask);res[row]=gs[:10]
        tile=p.n.checker((96,96)).convert('RGB');tile.paste(im,(0,0),im);tile=tile.resize((384,384),Image.Resampling.NEAREST);panel.paste(tile,(ri*384,30))
        d.text((ri*384+4,4),row,font=p.n.font(18),fill='white')
        for j,gg in enumerate(gs[:5]):
            box=gg['bbox'];d.rectangle(tuple((box[k]*4+(ri*384 if k%2==0 else 30)) for k in range(4)),outline=(255,90,180),width=1);d.text((ri*384+box[0]*4,30+box[1]*4),str(j),font=p.n.font(12),fill=(255,90,180))
    panel.save(p.REPORT/f'{mid}-landmark-probes.png')
    (p.REPORT/f'{mid}-landmark-probes.json').write_text(json.dumps(res,indent=2),'utf-8')
    print(mid,json.dumps({k:v[:3] for k,v in res.items()}))

if __name__=='__main__':
    for mid in p.WINDUP:inspect(mid)
