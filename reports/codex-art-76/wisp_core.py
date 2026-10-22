"""ART-71 connected-colour landmark measurement adapted for the storm core."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, sys
from collections import deque
import process as p

def measure(im):
    a=p.n.np.asarray(im.convert('RGBA')).astype(float)
    cyan=(a[:,:,2]>1.15*a[:,:,0])&(a[:,:,1]>1.25*a[:,:,0])
    white=(a[:,:,0]>180)&(a[:,:,1]>210)&(a[:,:,2]>220)
    mask=(a[:,:,1]>140)&(a[:,:,2]>190)&(cyan|white)&(a[:,:,3]>0)
    seen=p.n.np.zeros(mask.shape,dtype=bool); groups=[]
    for sy,sx in zip(*p.n.np.where(mask)):
        if seen[sy,sx]:continue
        q=deque([(int(sx),int(sy))]);seen[sy,sx]=True;pixels=[]
        while q:
            x,y=q.popleft();pixels.append((x,y))
            for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if 0<=ny<mask.shape[0] and 0<=nx<mask.shape[1] and mask[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;q.append((nx,ny))
        groups.append(pixels)
    pixels=max(groups,key=len);xs,ys=zip(*pixels)
    box=[min(xs),min(ys),max(xs)+1,max(ys)+1]
    return dict(bbox=box,centre=[(box[0]+box[2]-1)/2,(box[1]+box[3]-1)/2],width=box[2]-box[0],height=box[3]-box[1],area=len(pixels))

if __name__=='__main__':
    row=sys.argv[1];mid='jotunheim_storm_wisp'
    mp=p.REPORT/mid/row/'metrics.json';m=json.loads(mp.read_text('utf-8'))
    source,_=p.n.split_sheet(p.ROOT/f'art/raw/monsters-76/{mid}-{row}.png',tuple(m['input']['grid']))
    data=[measure(p.n.clean_background(im,'#00ff00')[0]) for im in source]
    print(json.dumps(data))
    if '--align' in sys.argv:
        p.align(mid,row,';'.join(','.join(map(str,x['centre'])) for x in data))
    m=json.loads(mp.read_text('utf-8'))
    m['core_measurement']={'method':'largest connected cyan/white component: G>140 B>190 and (B>1.15R G>1.25R or R>180 G>210 B>220); colour-area proxy, not full stone/body outline','frames':data,'output_widths':[round(x['width']*m['summary']['common_scale'],2) for x in data]}
    mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),'utf-8')
