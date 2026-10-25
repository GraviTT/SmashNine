"""ART-85: generated raster post-processing only; never overwrites a file.
Run from the clone root with PYTHONDONTWRITEBYTECODE=1.
Default output is ignored raw/draft-1. Pass a fresh --draft directory name to retry.
No Godot, downloads, package installs or product writes.
"""
from pathlib import Path
import argparse, hashlib, json, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'art/raw/projectiles-85'
REPORT = ROOT / 'reports/codex-art-85'
NN = Image.Resampling.NEAREST
LZ = Image.Resampling.LANCZOS
IDS = ['ember_imp','niflheim_frost_owl','jotunheim_storm_wisp','midgard_rooftop_slinger','vanaheim_seed_sprite','svartalfheim_cog_drone','yggdrasil_root_oracle']
BOMB = 'svartalfheim_cog_drone'
ICE = 'niflheim_frost_owl'
GUARD = 'yggdrasil_root_guardian'
FONT = 'C:/Windows/Fonts/malgun.ttf'

def save_png(im, path):
    with path.open('xb') as f: im.save(f,format='PNG')

def save_json(obj,path):
    with path.open('x',encoding='utf-8',newline='\n') as f: json.dump(obj,f,ensure_ascii=False,indent=2); f.write('\n')

def clean(im,threshold=24):
    a=np.array(im.convert('RGBA')); a[a[:,:,3]<threshold]=0
    # Transparent RGB is zero. No palette quantization or invented sprite shapes.
    return Image.fromarray(a)

def source(name):
    return clean(Image.open(RAW/(name+'.png')),64)

def scale(im,factor):
    im=im.resize((round(im.width*factor),round(im.height*factor)),LZ)
    rgb=im.convert('RGB').filter(ImageFilter.UnsharpMask(radius=.6,percent=60,threshold=3))
    rgb.putalpha(im.getchannel('A'))
    return clean(rgb)

def frames(im,cell):
    w,h=cell
    return [im.crop((i*w,0,(i+1)*w,h)) for i in range(im.width//w)]

def strip(fs):
    out=Image.new('RGBA',(fs[0].width*len(fs),fs[0].height))
    for n,im in enumerate(fs):out.alpha_composite(im,(n*im.width,0))
    return out

def make_bomb():
    im=source('bomb-gen2'); a=np.array(im)
    # Manually inspected sphere center in source coordinates, not whole-art bbox.
    pivot=(582.5,791.5)
    yy,xx=np.where(a[:,:,3]>0)
    radius=float(np.sqrt((xx-pivot[0])**2+(yy-pivot[1])**2).max())
    factor=20/radius
    box=im.getbbox(); cropped=im.crop(box)
    # Work at 4x target resolution, always rotate the SAME master, then shrink.
    master=Image.new('RGBA',(192,192)); s=scale(cropped,factor*4)
    pos=(round(96-(pivot[0]-box[0])*factor*4),round(96-(pivot[1]-box[1])*factor*4))
    master.alpha_composite(s,pos)
    raw=np.array(master)
    y,x=np.indices(raw.shape[:2])
    spark=(y<35)&(raw[:,:,0]>150)&(raw[:,:,1]>45)&(raw[:,:,2]<160)&(raw[:,:,3]>0)
    assert spark.sum()>0
    fs=[]
    gains=[1,.82,1.08,.9,1.04,.86,1.1,.94]
    for i,gain in enumerate(gains):
        aa=raw.copy(); aa[spark,:3]=np.clip(aa[spark,:3].astype(float)*gain,0,255).astype('uint8')
        # Each step is clockwise 45 degrees around the body, including 315->360.
        rotated=Image.fromarray(aa).rotate(-45*i,resample=Image.Resampling.BICUBIC,center=(96,96))
        fs.append(clean(rotated.resize((48,48),LZ)))
    meta={'source':'art/raw/projectiles-85/bomb-gen2.png','source_box':box,'source_body_pivot':pivot,'scale':factor,'supersampling':4,'rotation_degrees_clockwise':list(range(0,360,45)),'spark_gain':gains,'spark_source_mask_pixels_at_4x':int(spark.sum())}
    return fs,meta

def make_ice():
    im=source('ice-gen1'); box=im.getbbox(); im=im.crop(box); factor=42/im.width
    im=scale(im,factor); base=Image.new('RGBA',(48,48)); base.alpha_composite(im,(3,24-im.height//2))
    a=np.array(base); yy,xx=np.indices(a.shape[:2])
    # Shard begins around x=24. Entire right-hand shard and outline are immutable.
    mask=(xx<23)&(a[:,:,3]>0)&(a[:,:,2]>100)&(a[:,:,1]>65)
    fs=[]; gains=[.96,1.03,1.06,.99]
    for gain in gains:
        aa=a.copy(); aa[mask,:3]=np.clip(aa[mask,:3].astype(float)*gain,0,255).astype('uint8'); fs.append(Image.fromarray(aa))
    return fs,{'source':'art/raw/projectiles-85/ice-gen1.png','source_box':box,'scale':factor,'immutable_region':[23,0,48,48],'tail_gain':gains,'tail_mask_pixels':int(mask.sum()),'method':'same master RGBA; RGB shimmer confined to x<23; alpha identical'}

def make_guardian():
    im=source('guardian-gen1'); a=np.array(im)
    occ=np.flatnonzero((a[:,:,3]>0).any(0)); cuts=np.where(np.diff(occ)>8)[0]
    runs=list(zip(np.r_[occ[0],occ[cuts+1]],np.r_[occ[cuts],occ[-1]]+1)); assert len(runs)==4
    pieces=[]; boxes=[]
    for l,r in runs:
        sub=im.crop((int(l),0,int(r),im.height)); b=sub.getbbox(); boxes.append([int(l)+b[0],b[1],int(l)+b[2],b[3]]); pieces.append(sub.crop(b))
    factor=min(58/max(p.width for p in pieces),38/max(p.height for p in pieces))
    fs=[]
    for p in pieces:
        p=scale(p,factor); b=p.getbbox();p=p.crop(b)
        f=Image.new('RGBA',(64,48)); f.alpha_composite(p,(61-p.width,44-p.height)); fs.append(f)
    return fs,{'source':'art/raw/projectiles-85/guardian-gen1.png','source_boxes':boxes,'scale':factor,'floor':44,'alignment':'opaque bottom edge 44, leading right edge 61; one common scale'}

def measure(fs):
    results=[]
    for im in fs:
        a=np.array(im); b=im.getbbox(); w,h=im.size
        border=np.ones((h,w),bool);border[2:-2,2:-2]=False
        y,x=np.indices((h,w)); weights=a[:,:,3].astype(float)
        results.append({'bbox':b,'margin':min(b[0],b[1],w-b[2],h-b[3]),'border_2px_spill':int(((a[:,:,3]>0)&border).sum()),'transparent_rgb':int(((a[:,:,:3]!=0).any(2)&(a[:,:,3]==0)).sum()),'key_green_pixels':int(((a[:,:,3]>=24)&(a[:,:,0]<=40)&(a[:,:,1]>=215)&(a[:,:,2]<=40)).sum()),'green_dominance_pixels':int(((a[:,:,3]>0)&(a[:,:,1].astype(int)>np.maximum(a[:,:,0],a[:,:,2]).astype(int)+20)).sum()),'visible_pixels':int((a[:,:,3]>0).sum()),'alpha_centroid':[round(float((x*weights).sum()/weights.sum()),3),round(float((y*weights).sum()/weights.sum()),3)],'sha256':hashlib.sha256(im.tobytes()).hexdigest()})
    return results

def txt(draw,xy,s,size=15,fill='#e4e9f2'):
    draw.text(xy,s,font=ImageFont.truetype(FONT,size),fill=fill)

def tile(board,im,x,y,w,h,light=False):
    d=ImageDraw.Draw(board);d.rectangle((x,y,x+w-1,y+h-1),fill='#d6dbe2' if light else '#111923')
    board.alpha_composite(im,(x+(w-im.width)//2,y+(h-im.height)//2))

def review_board(id,old,new,cell,label):
    count=max(len(old),len(new)); multi=len(new)>4
    out=Image.new('RGBA',(1120,1030 if multi else 810),'#202936');d=ImageDraw.Draw(out)
    txt(d,(24,14),'ART-85  '+id,22);txt(d,(24,48),label,16)
    txt(d,(24,80),'OLD 1x',15)
    for i,f in enumerate(old):tile(out,f,135+i*70,75,64,50,i%2==1)
    txt(d,(24,143),'NEW 1x' if id not in IDS or id in [BOMB,ICE] else 'KEEP 1x')
    for i,f in enumerate(new):tile(out,f,135+i*70,138,64,50,i%2==1)
    txt(d,(24,209),'OLD 36px')
    for i,f in enumerate(old):tile(out,f.resize((36,round(36*f.height/f.width)),NN),135+i*70,202,64,44,i%2==1)
    txt(d,(24,264),'NEW 36px' if id not in IDS or id in [BOMB,ICE] else 'KEEP 36px')
    for i,f in enumerate(new):tile(out,f.resize((36,round(36*f.height/f.width)),NN),135+i*70,257,64,44,i%2==1)
    txt(d,(24,310),'OLD 4x — all frames / alternating dark and light')
    for i,f in enumerate(old):tile(out,f.resize((cell[0]*4,cell[1]*4),NN),24+i*272,338,264,192,i%2==1)
    txt(d,(24,542),'NEW 4x' if id not in IDS or id in [BOMB,ICE] else 'KEEP 4x')
    for i,f in enumerate(new):tile(out,f.resize((cell[0]*4,cell[1]*4),NN),24+(i%4)*272,570+(i//4)*220,264,192,i%2==1)
    # Context boards are separate, allowing every inspection pixel to stay 1:1.
    return out

def context_board(id,old,new,cell):
    out=Image.new('RGBA',(1120,400),'#13111d');d=ImageDraw.Draw(out)
    txt(d,(24,12),'IN-CONTEXT MOCK — 합성 모형 / 실제 게임 캡처 아님',20)
    txt(d,(24,44),'셀 표시 폭 54px (36 × WORLD 1.5), 몬스터 96px. 왼쪽은 수평 반전.',15)
    mon=Image.open(RAW/(id+'_sheet.png')).convert('RGBA').crop((192,192,288,288))
    if id==GUARD:
        mon=Image.open(RAW/(GUARD+'-attack-v1.png')).convert('RGBA').crop((192,0,288,96))
    for row,fs in enumerate([old,new]):
        ground=205+row*150
        d.rectangle((16,ground,1104,ground+9),fill='#345449')
        txt(d,(24,ground-112),'OLD' if row==0 else 'NEW / KEEP',16)
        out.alpha_composite(mon,(110,ground-72));out.alpha_composite(mon.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(940,ground-72))
        for i,f in enumerate(fs):
            small=f.resize((54,round(54*f.height/f.width)),NN)
            y=ground-round(44*54/64) if id==GUARD else ground-62
            out.alpha_composite(small,(225+i*70,y))
        mir=fs[1%len(fs)].transpose(Image.Transpose.FLIP_LEFT_RIGHT).resize((54,round(54*cell[1]/cell[0])),NN)
        out.alpha_composite(mir,(860,ground-round(44*54/64) if id==GUARD else ground-62))
    return out

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--draft',default='draft-1');args=ap.parse_args()
    assert Path(args.draft).name==args.draft
    out=RAW/args.draft;out.mkdir(exist_ok=False)
    datasets={BOMB:make_bomb(),ICE:make_ice(),GUARD:make_guardian()}
    measurements={};sources={}
    for id,(fs,meta) in datasets.items():
        cell=(64,48) if id==GUARD else (48,48)
        oldname='slam_shockwave-v1' if id==GUARD else id+'-projectile-v1'
        old=frames(Image.open(RAW/(oldname+'.png')).convert('RGBA'),cell)
        name=id+('-shockwave-v1' if id==GUARD else '-projectile-v2')
        save_png(strip(fs),out/(name+'.png'))
        note={BOMB:'같은 폭탄 원화 한 장을 몸 중심에서 45도씩 시계 방향으로 회전한 8프레임. 도화선 불꽃만 밝기 변화. 12fps 후보이며 기존 파일은 보존.',ICE:'얼음 파편 본체와 알파 실루엣은 네 프레임에서 완전히 동일. 왼쪽 서리 꼬리 RGB만 약하게 반짝임. 12fps 후보이며 기존 파일은 보존.',GUARD:'수호자의 보라색 나무껍질·청록 뿌리·자홍빛을 따른 오른쪽 진행 뿌리/흙 충격파. 바닥 경계 y=44, 최하단 y=43. 현재 게임은 몬스터별 충격파를 선택하지 않으므로 채택 후 별도 연결 필요. 공용 골렘 충격파를 전역 교체하지 말 것.'}[id]
        data={'note':note,'frames':len(fs),'fps':12,'cell':list(cell) if id==GUARD else 48,'aim':'none' if id==BOMB else 'right','replaces':'art/bakeoff/monsters/'+oldname+'.png','loop':True,'status':'candidate','processing':meta}
        if id==GUARD:data['floor']=44;data['replaces_scope']='guardian only; keep the existing shared golem asset'
        else:data['pivot']=[24,24]
        save_json(data,out/(name+'.json'))
        measurements[id]={'old':measure(old),'new':measure(fs)}
        sources[id]=meta
        save_png(review_board(id,old,fs,cell,note.split('.')[0]),out/(id+'.png'))
        save_png(context_board(id,old,fs,cell),out/(id+'-context.png'))
        for m in measurements[id]['new']:
            assert m['margin']>=2 and m['border_2px_spill']==0 and m['transparent_rgb']==0 and m['key_green_pixels']==0
    for id in IDS:
        if id in [BOMB,ICE]:continue
        old=frames(Image.open(RAW/(id+'-projectile-v1.png')).convert('RGBA'),(48,48))
        measurements[id]={'old':measure(old)}
        save_png(review_board(id,old,old,(48,48),'기존 ART-79 재검수 — 이번 후보 변경 없음'),out/(id+'-review.png'))
        save_png(context_board(id,old,old,(48,48)),out/(id+'-context.png'))
    ice=datasets[ICE][0]; core=np.array(ice[0])[:,23:]
    measurements['invariants']={'ice_core_changed_pixels':[int((np.array(f)[:,23:]!=core).any(2).sum()) for f in ice],'ice_alpha_changed_pixels':[int((np.array(f)[:,:,3]!=np.array(ice[0])[:,:,3]).sum()) for f in ice],'guardian_bottom_exclusive':[f.getbbox()[3] for f in datasets[GUARD][0]],'bomb_angles':list(range(0,360,45))}
    save_json(measurements,out/'measurements.json');save_json(sources,out/'processing.json')
    print(json.dumps({'draft':str(out),'invariants':measurements['invariants'],'new_margins':{id:[m['margin'] for m in measurements[id]['new']] for id in datasets}},indent=2))

if __name__=='__main__':main()
