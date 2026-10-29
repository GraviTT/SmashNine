"""Rebuild final PNGs from preserved raws, compare pixel bytes, never overwrite.
Run from repo root with PYTHONDONTWRITEBYTECODE=1. Inputs in ignored art/raw/fighters-86.
The output directory argument must not exist. No generation, feature painting, or head pastes.
"""
from common import *
import walk_bob as wb
import argparse

def sample(source,factor,phase,cell=128):
    im=source if isinstance(source,Image.Image) else Image.open(RAW/source).convert('RGBA')
    im=n.clean_background(im,'alpha' if im.getchannel('A').getextrema()[0]==0 else '#00ff00')[0]
    sub=im.crop(im.getbbox());pad=32;edge=8
    padded=Image.new('RGBA',(sub.width+pad*2,sub.height+pad*2));padded.paste(sub,(pad,pad))
    w=sub.width+edge*2;ht=sub.height+edge*2;sx=pad-edge+phase[0]/factor;sy=pad-edge+phase[1]/factor
    f=padded.resize((round(w*factor),round(ht*factor)),Image.Resampling.LANCZOS,box=(sx,sy,sx+w,sy+ht))
    f=n.apply_unsharp(f,60);f.putalpha(f.getchannel('A').point(lambda v:255 if v>=128 else 0));f=n.despill_green_edge(f,'auto');f=f.crop(f.getbbox())
    feet=cell//2+56;canvas=Image.new('RGBA',(cell,cell));canvas.paste(f,((cell-f.width)//2,feet+1-f.height));return canvas

def shift(f,x=0,y=0):
    g=Image.new('RGBA',f.size);g.paste(f,(x,y));return g

def l14_sources():
    raw=Image.open(RAW/'L14-source.png').convert('RGBA');ar=np.array(raw.crop((515,515,1533,1021)))
    ar[:776-515,1020-515:1028-515,3]=0;ar[802-515:,1020-515:1028-515,3]=0
    part=n.clean_background(Image.fromarray(ar),'#00ff00')[0];selected=[]
    for pts in components(part)[:2]:
        z=np.zeros_like(ar);ys,xs=zip(*pts);z[ys,xs]=np.array(part)[ys,xs];im=Image.fromarray(z);selected.append((im.getbbox()[0],im))
    return [im for _,im in sorted(selected,key=lambda t:t[0])]

def l14_restore_position(frame):
    """Restore F5 body by +8px; shorten only the already extracted blade.

    The isolated blade crop (132,95)-(188,113) becomes 48x18, anchored
    at (140,95). No body/head/frame resampling; pointed source tip retained.
    """
    out=shift(frame,8)
    a=np.array(out);a[95:113,140:]=0;out=Image.fromarray(a)
    blade=frame.crop((132,95,188,113)).resize((48,18),Image.Resampling.LANCZOS)
    blade.putalpha(blade.getchannel('A').point(lambda v:255 if v>=128 else 0))
    out.paste(blade,(140,95))
    return out

def rebuild():
    results={}
    fs=cells(RAW/'L14-adopted.png');raw=l14_sources()
    fs[4]=l14_restore_position(shift(sample(raw[0],.260,[-.125,-.125],192),19));fs[5]=shift(sample(raw[1],.260,[.25,.375],192),17)
    results['rio/rio_female-mana_combo-v2.png']=fs
    fs=cells(RAW/'nova_male-walk-v2.png');f=sample('L09-generated-3.png',.100,[-.25,.25]);fs[2]=Image.fromarray(wb.raise_(np.array(f),(92,115),1))
    results['nova/nova_male-walk-v3.png']=fs
    fs=cells(RAW/'rio_female-walk-v3.png');f=shift(sample('L10-generated-1.png',.124,[-.25,.25]),8);fs[3]=Image.fromarray(wb.raise_(np.array(f),(92,115),3))
    results['rio/rio_female-walk-v4.png']=fs
    configs=[('L11-generated-F1-attempt2.png',.108,[-.5,-.25]),('L11-generated-F2.png',.102,[0,-.25]),('L11-generated-F3-attempt2.png',.108,[.375,0]),('L11-generated-F4.png',.102,[-.25,.5]),('L11-generated-F5-attempt2.png',.100,[0,-.25]),('L11-generated-F6.png',.102,[.25,0]),('L11-generated-F7-attempt2.png',.102,[.25,0]),('L11-generated-F8.png',.102,[.25,0])]
    arr=[np.array(sample(*config)) for config in configs];arr=wb.apply(arr,[1,0,2,-1,0,0,0,-3],(89,115))
    results['rio/rio_male-walk-v2.png']=[Image.fromarray(a) for a in arr]
    fs=cells(RAW/'L34-adopted.png')
    for i in [3,4,5]:fs[i]=shift(fs[i],y=4)
    results['nova/nova_female-gravity_brake-v2.png']=fs
    fs=cells(RAW/'L37-game-base-attack.png');original=fs.copy();source=Image.open(RAW/'L37-source.png').convert('RGBA')
    for i,phase in zip([2,3,4],[[-.25,-.5],[0,0],[0,.25]]):
        x=i%3*512;y=i//3*512;raw=n.clean_background(source.crop((x,y,x+512,y+512)),'#00ff00')[0];fs[i]=sample(raw,.253,phase)
    fs[5]=sample('L37-generated-F6-attempt3.png',.104,[.25,0])
    for i in [2,3,4,5]:
        f=fs[i];dx=round(h.face_centre(np.array(original[i]))[1]-h.face_centre(np.array(f))[1]);dx=min(dx,124-f.getbbox()[2]);dx=max(dx,4-f.getbbox()[0]);fs[i]=shift(f,dx)
    results['frey/frey-attack-v5.png']=fs
    return results

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--out',required=True,type=Path);ap.add_argument('--report',required=True,type=Path);args=ap.parse_args()
    assert not args.out.exists(),args.out;assert not args.report.exists(),args.report
    allowed=RAW.resolve();target=args.out.resolve();assert target.is_relative_to(allowed),target
    args.out.mkdir(parents=True);records=[]
    for rel,fs in rebuild().items():
        im=strip(fs);expected=Image.open(ROOT/'art/bakeoff'/rel).convert('RGBA');same=im.tobytes()==expected.tobytes()
        save(im,args.out/rel);records.append({'file':f'art/bakeoff/{rel}','rgba_identical':same,'sha256_rgba':hashlib.sha256(im.tobytes()).hexdigest()})
    js(records,args.report);print(records);assert all(x['rgba_identical'] for x in records)
