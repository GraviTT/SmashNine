"""ART-86: non-destructive extraction, ART-61 normalization, and review boards."""
import sys, json, hashlib, shutil
from pathlib import Path
from collections import deque
import numpy as np
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/sprite_pipeline'))
import normalize as n
import head_scale as h
OUT=ROOT/'reports/codex-art-86'
RAW=ROOT/'art/raw/fighters-86'
def save(im,path):
    path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
    if path.exists(): raise FileExistsError(path)
    im.save(path)
def js(obj,path):
    with Path(path).open('x',encoding='utf-8') as f:json.dump(obj,f,ensure_ascii=False,indent=2)
def copy(src,name=None):
    src=ROOT/src;dst=RAW/(name or src.name)
    dst.parent.mkdir(parents=True,exist_ok=True)
    if dst.exists():raise FileExistsError(dst)
    shutil.copy2(src,dst);return dst
def cells(path):
    im=Image.open(path).convert('RGBA');c=im.height
    return [im.crop((i*c,0,(i+1)*c,c)) for i in range(im.width//c)]
def norm(im,factor,cell=128,feet=120,offset=0):
    return n.normalize_frame(im,factor,im.getbbox()[3]-1,None,'off','lanczos',60,'auto',offset,True,0,1,cell,feet)[0]
def strip(fs):
    out=Image.new('RGBA',(fs[0].width*len(fs),fs[0].height))
    for i,f in enumerate(fs):out.paste(f,(i*f.width,0))
    return out
def metrics(f):
    a=np.array(f);b=f.getbbox()
    return dict(bbox=b,area=int((a[...,3]>0).sum()),bottom=b[3]-1,margin=n.margins(b,f.height),**n.frame_metrics(f),sha256=hashlib.sha256(f.tobytes()).hexdigest(),alpha_binary=set(np.unique(a[...,3]).tolist())<={0,255})
def board(before,after,changed,path,title,anchor=None):
    c=before[0].height;cols=3;tw=c*4;th=tw+30
    groups=(len(before)+cols-1)//cols
    im=Image.new('RGB',(cols*tw,70+groups*th*2),(24,30,43));d=ImageDraw.Draw(im)
    d.text((12,10),title,fill='white',font=n.font(22))
    d.text((12,40),'4x nearest | BEFORE then AFTER | yellow = changed frame',fill='white',font=n.font(16))
    for i in range(len(before)):
        for k,fs in enumerate([before,after]):
            x=(i%cols)*tw;y=70+(i//cols)*th*2+k*th
            tile=n.checker((tw,tw));f=fs[i].resize((tw,tw),Image.Resampling.NEAREST);tile.paste(f,(0,0),f)
            im.paste(tile,(x,y));d.text((x+8,y+5),f'{"BEFORE" if k==0 else "AFTER"} F{i+1}',fill='white',font=n.font(17))
            if i+1 in changed:d.rectangle((x+1,y+1,x+tw-2,y+tw-2),outline='yellow',width=3)
    save(im,path)
def faceboard(fs,anchor,path):
    tiles=[]
    for f in [anchor]+fs:
        cy,cx=h.face_centre(np.array(f));tiles.append(f.crop((round(cx)-26,round(cy)-26,round(cx)+26,round(cy)+26)))
    out=Image.new('RGB',(len(tiles)*216,250),(31,38,55));d=ImageDraw.Draw(out)
    for i,t in enumerate(tiles):
        t=t.resize((208,208),Image.Resampling.NEAREST);out.paste(t,(216*i,30),t);d.text((216*i+4,4),'ANCHOR' if i==0 else f'F{i}',fill='white',font=n.font(17))
    save(out,path)
def components(im):
    a=np.array(im);m=a[...,3]>0;seen=np.zeros_like(m);result=[]
    for y,x in zip(*np.nonzero(m)):
        if seen[y,x]:continue
        q=deque([(y,x)]);seen[y,x]=True;pts=[]
        while q:
            cy,cx=q.popleft();pts.append((cy,cx))
            for dy,dx in ((-1,0),(1,0),(0,-1),(0,1)):
                ny,nx=cy+dy,cx+dx
                if 0<=ny<m.shape[0] and 0<=nx<m.shape[1] and m[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;q.append((ny,nx))
        result.append(pts)
    return sorted(result,key=len,reverse=True)
