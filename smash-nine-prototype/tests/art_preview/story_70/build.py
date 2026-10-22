"""ART-70 reproducible build. No packages/network/Godot; only card-owned paths.
Raw imagegen images are immutable. Rebuilds must be byte-identical or use --revision.
"""
from pathlib import Path
import argparse, json, shutil, hashlib, math
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageChops

ROOT=Path(__file__).resolve().parents[4]
REPORT=ROOT/'reports/codex-art-70'
ASSET=ROOT/'smash-nine-prototype/assets/art/story'
JOBS=json.loads((REPORT/'generation_manifest.json').read_text(encoding='utf-8'))
PICK={'cg_prologue':1,'cg_root':3,'cg_epilogue':1,'dialogue_frame':1,'name_plate':1,'shadow_aura':2}
parser=argparse.ArgumentParser()
parser.add_argument('--revision',default='v2')
args=parser.parse_args()
OUT=REPORT/'candidates'/args.revision
OUT.mkdir(parents=True,exist_ok=True)
LOG=[]
PAL=np.array([(16,24,39),(168,116,44),(243,205,124),(255,232,175),(42,75,133),(61,123,217),(159,210,255)],dtype=np.int32)
AURAPAL=np.array([(26,15,46),(59,29,94),(107,47,168),(255,79,216),(255,155,232)],dtype=np.int32)

def write_png(im,path):
    if path.exists():
        old=Image.open(path)
        if old.mode!=im.mode or old.size!=im.size or old.tobytes()!=im.tobytes():
            raise RuntimeError(f'No overwrite: {path}; choose a new revision')
        return
    im.save(path)

def palette_image(im,palette,cut=128):
    a=np.array(im.convert('RGBA'))
    rgb=a[:,:,:3].astype(np.int32)
    dist=((rgb[:,:,None,:]-palette[None,None,:,:])**2).sum(3)
    a[:,:,:3]=palette[dist.argmin(2)].astype(np.uint8)
    a[:,:,3]=np.where(a[:,:,3]>=cut,255,0)
    a[a[:,:,3]==0,:3]=0
    return Image.fromarray(a)

def raw_dest(job):
    name=job['id'];v=job['variant']
    if PICK[name]==v: return ASSET/f'{name}_source.png'
    return REPORT/'variants'/f'{name}-v{v}_source.png'

def scene(raw,job):
    im=raw.convert('RGB'); w,h=im.size
    unit=min(w//16,h//9); cw,ch=unit*16,unit*9
    box=((w-cw)//2,(h-ch)//2,(w-cw)//2+cw,(h-ch)//2+ch)
    size=(1600,900) if cw>=1600 and ch>=900 else (1280,720)
    assert cw>=size[0] and ch>=size[1], 'No upscale'
    LOG.append({'asset':job['id'],'variant':job['variant'],'raw_size':[w,h],'crop':box,'resize':size,'filter':'LANCZOS','upscale':False})
    return im.crop(box).resize(size,Image.Resampling.LANCZOS)

def frame(raw,job):
    v=job['variant']
    # One generated corner is retained; mirrored corners avoid generated asymmetry.
    box=(12,14,188,190) if v==1 else (24,80,184,240)
    corner=raw.crop(box).resize((22,22),Image.Resampling.NEAREST)
    corner=palette_image(corner,PAL)
    im=Image.new('RGBA',(480,120));d=ImageDraw.Draw(im)
    # Plain stretchable straight double-line edges, with a dark one-pixel separation.
    d.rectangle((6,6,473,113),outline=(16,24,39,255),width=6)
    d.rectangle((7,7,472,112),outline=(243,205,124,255),width=2)
    d.rectangle((10,10,469,109),outline=(61,123,217,255),width=1)
    # Remove all line pixels from the 24x24 corner regions before placing ornaments.
    for x,y in [(0,0),(456,0),(0,96),(456,96)]: d.rectangle((x,y,x+23,y+23),fill=(0,0,0,0))
    for x,y,c in [(1,1,corner),(457,1,corner.transpose(Image.Transpose.FLIP_LEFT_RIGHT)),(1,97,corner.transpose(Image.Transpose.FLIP_TOP_BOTTOM)),(457,97,corner.transpose(Image.Transpose.ROTATE_180))]:
        im.alpha_composite(c,(x,y))
    LOG.append({'asset':job['id'],'variant':v,'raw_size':raw.size,'corner_crop':box,'corner_downscale':[22,22],'filter':'NEAREST','finish':'binary alpha, seven-color palette; exact 480x120 double-line frame; generated corner mirrored inside four 24px zones','upscale':False})
    return im

def plate(raw,job):
    v=job['variant']; im=Image.new('RGBA',(192,36));d=ImageDraw.Draw(im)
    if v==1:
        outer=[(7,1),(184,1),(190,7),(190,28),(184,34),(7,34),(1,28),(1,7)]
        inner=[(8,3),(183,3),(188,8),(188,27),(183,32),(8,32),(3,27),(3,8)]
        box=(72,350,139,417)
    else:
        outer=[(4,1),(187,1),(190,4),(190,31),(187,34),(4,34),(1,31),(1,4)]
        inner=[(5,3),(186,3),(188,5),(188,30),(186,32),(5,32),(3,30),(3,5)]
        box=(63,344,139,420)
    d.polygon(outer,fill=(243,205,124,255));d.polygon(inner,fill=(16,24,39,235))
    gem=palette_image(raw.crop(box).resize((7,7),Image.Resampling.NEAREST),PAL)
    # Only generated blue gem pixels; gold bezel stays in the tiny end zones.
    ar=np.array(gem); rgb=ar[:,:,:3].astype(np.int32)
    blue=(rgb[:,:,2]>rgb[:,:,0]+40)&(rgb[:,:,2]>rgb[:,:,1]+20)
    ar[~blue]=0;gem=Image.fromarray(ar)
    for x in [4,181]:
        # Small gold pixel bezel around the retained blue pixels.
        if v==1: d.polygon([(x+3,12),(x+7,17),(x+3,22),(x-1,17)],fill=(168,116,44,255))
        else: d.rectangle((x-1,13,x+7,22),fill=(168,116,44,255))
        im.alpha_composite(gem,(x,14))
    LOG.append({'asset':job['id'],'variant':v,'raw_size':raw.size,'gem_crop':box,'gem_downscale':[7,7],'filter':'NEAREST','finish':'exact 192x36 navy alpha235 polygon, 2px gold border, no outer glow; generated blue gem retained in 12px end zones','upscale':False})
    return im

def aura(raw,job):
    # Native RGBA retained. Alpha<64 is discarded to remove generated edge noise.
    rgba=np.array(raw.convert('RGBA'))
    rgba[rgba[:,:,3]<64]=0
    clean=Image.fromarray(rgba)
    crops=[]
    for i in range(6):
        l=round(raw.width*i/6);r=round(raw.width*(i+1)/6)
        cell=clean.crop((l,0,r,raw.height))
        crops.append((l,r,cell,cell.getchannel('A').getbbox()))
    top=min(c[3][1] for c in crops);bottom=max(c[3][3] for c in crops)
    maxw=max(c[3][2]-c[3][0] for c in crops)
    scale=min(116/maxw,150/(bottom-top),1)
    result=Image.new('RGBA',(768,176))
    for i,(l,r,cell,box) in enumerate(crops):
        # Same scale and shared vertical range preserve relative rising motion.
        cx=(box[0]+box[2])/2
        crop=cell.crop((box[0],top,box[2],bottom))
        size=(max(1,round(crop.width*scale)),max(1,round(crop.height*scale)))
        crop=crop.resize(size,Image.Resampling.NEAREST)
        arr=np.array(crop);rgb=arr[:,:,:3].astype(np.int32)
        dist=((rgb[:,:,None,:]-AURAPAL[None,None,:,:])**2).sum(3)
        arr[:,:,:3]=AURAPAL[dist.argmin(2)].astype(np.uint8)
        # Preserve alpha, quantize for pixel-art smoke; remove residual low alpha.
        arr[:,:,3]=np.where(arr[:,:,3]>=64,np.maximum(64,((arr[:,:,3].astype(int)+16)//32)*32).clip(0,255),0)
        arr[arr[:,:,3]==0,:3]=0
        tile=Image.fromarray(arr)
        pos=(i*128+64-size[0]//2,160-size[1])
        result.alpha_composite(tile,pos)
        LOG.append({'asset':job['id'],'variant':job['variant'],'frame':i+1,'raw_cell':[l,0,r,raw.height],'content_bbox':box,'crop':[box[0],top,box[2],bottom],'downscale':size,'scale':scale,'paste':pos,'filter':'NEAREST','finish':'native alpha cutoff64, violet 5-color palette, alpha quantization32, feet160; shared scale','upscale':False})
    return result

for job in JOBS:
    dest=raw_dest(job);dest.parent.mkdir(parents=True,exist_ok=True)
    source=dest if dest.exists() else Path(job['path'])
    if dest.exists():
        assert hashlib.sha256(dest.read_bytes()).digest()==hashlib.sha256(source.read_bytes()).digest()
    else: shutil.copy2(source,dest)
    raw=Image.open(source).convert('RGBA')
    kind=job['id']
    out=scene(raw,job) if kind.startswith('cg_') else frame(raw,job) if kind=='dialogue_frame' else plate(raw,job) if kind=='name_plate' else aura(raw,job)
    target=OUT/f"{kind}-v{job['variant']}.png"
    write_png(out,target)
    if not (kind=='cg_prologue' and job['variant']==1):
        # Promotion is a separate review step, so this script initially only builds candidates.
        pass
(REPORT/f'processing-{args.revision}.json').write_text(json.dumps(LOG,indent=2),encoding='utf-8',newline='\n')
print(json.dumps({'candidates':str(OUT),'count':len(JOBS),'picks':PICK},indent=2))

