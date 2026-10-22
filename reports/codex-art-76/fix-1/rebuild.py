"""ART-76 fix-1: read-only shared normalizer; all writes scoped to this card.

Run with the supplied Python and -B. No image generation, Godot, git writes,
per-frame scale, palette edits, fragment replacement or raw edits.
"""
import os
os.environ['PYTHONDONTWRITEBYTECODE'] = '1'
import sys, json, math, hashlib, shutil, importlib.util
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np

FIX = Path(__file__).resolve().parent
ROOT = FIX.parents[2]
REPORT = FIX.parent
BAKE = ROOT / 'art/bakeoff/monsters'
RAW = ROOT / 'art/raw/monsters-76'
ROWS = ['idle', 'walk', 'windup', 'attack', 'hurt', 'defeat']
COUNTS = dict(zip(ROWS, [6, 6, 4, 6, 2, 4]))
IDS = ['muspelheim_magma_boar', 'niflheim_glacier_wolf', 'niflheim_frost_owl',
       'jotunheim_storm_wisp', 'yggdrasil_root_guardian', 'yggdrasil_root_oracle']
SPEC = importlib.util.spec_from_file_location('normalizer76fix', ROOT/'tools/sprite_pipeline/normalize.py')
n = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(n)
LANDMARKS = json.loads((REPORT/'manual_landmarks.json').read_text('utf-8'))

# Representative frame is chosen before resizing: comparable, visible part.
# Hurt F2 avoids recoil foreshortening; wolf attack F6 avoids the airborne pose.
def rep_index(mid, row):
    return COUNTS[row]-1 if row == 'hurt' or (mid == IDS[1] and row == 'attack') else 0

def load_json(path):
    return json.loads(path.read_text('utf-8'))

def dump(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', 'utf-8')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def frames(path, row):
    with Image.open(path) as im:
        im = im.convert('RGBA')
        return [im.crop((i*96, 0, (i+1)*96, 96)) for i in range(COUNTS[row])]

def snapshot():
    dest = FIX/'before'
    dest.mkdir(exist_ok=True)
    for mid in IDS:
        for row in ROWS:
            for ext in ['png', 'json']:
                name = f'{mid}-{row}-v1.{ext}'
                if not (dest/name).exists():
                    shutil.copy2(BAKE/name, dest/name)
        name = f'{mid}_sheet-v1.png'
        if not (dest/name).exists(): shutil.copy2(BAKE/name, dest/name)
    manifest = FIX/'baseline.json'
    if not manifest.exists():
        import subprocess
        paths = subprocess.check_output(['git','ls-files','-z'], cwd=ROOT).decode('utf-8').split('\0')
        protected = {p:sha(ROOT/p) for p in paths if p and (p.startswith('smash-nine-prototype/') or p.startswith('tools/')) and (ROOT/p).is_file()}
        index_path = subprocess.check_output(['git','rev-parse','--git-path','index'],cwd=ROOT,text=True).strip()
        index = Path(index_path)
        if not index.is_absolute(): index = ROOT/index
        dump(manifest, dict(protected=protected, git_index_path=str(index), git_index_sha256=sha(index),
                            raws={p.name:sha(p) for p in RAW.glob('*.png')}))

CACHE = {}
def source(mid, row):
    key = (mid,row)
    if key not in CACHE:
        path = RAW/f'{mid}-{row}.png'
        if not path.is_file(): raise FileNotFoundError(path)
        count = COUNTS[row]
        raw, labels = n.split_sheet(path, (3,2) if count==6 else (2,2) if count==4 else (2,1))
        clean = [n.clean_background(im, '#00ff00')[0] for im in raw]
        n.validate_source_cell_margin(clean, labels)
        CACHE[key] = clean
    return CACHE[key]

def rebuild_row(mid, row, factor, extra_x=None):
    old = frames(FIX/'before'/f'{mid}-{row}-v1.png', row)
    oldmeta = load_json(FIX/'before'/f'{mid}-{row}-v1.json')
    m = load_json(REPORT/mid/row/'metrics.json')
    raw = source(mid,row)
    sg = max(im.getbbox()[3]-1 for im in raw)
    output, placements = [], []
    oldfactor = oldmeta['factor']
    oldoffset = m['summary']['common_offset_x']
    for i,(clean,prev) in enumerate(zip(raw,old)):
        # Large temporary canvas; exact same resample/sharpen/key/despill as ART-76.
        canvas,_,_ = n.normalize_frame(clean, factor, sg, None, 'off', 'lanczos',60,'auto',
                                      oldoffset,True,0,1,256,200)
        box = canvas.getbbox(); ob = prev.getbbox()
        w,h = box[2]-box[0],box[3]-box[1]
        if w>90 or h>90: raise ValueError(f'{mid}/{row} F{i+1} cannot fit 3px margin: {w}x{h}')
        x = box[0]-80 # x128 -> x48, same torso anchor as original
        bottom = ob[3]-1
        y = bottom-h+1
        # Preserve the old floating body anchor, rather than aligning a tendril tip.
        align = m.get('body_alignment',{}).get('frames',[])
        if align:
            pt = align[i]['source_point']; target = align[i]['target']
            sb = clean.getbbox()
            x = round(target[0]-(pt[0]-sb[0])*factor)
            y = round(target[1]-(pt[1]-sb[1])*factor)
        dx = int(extra_x[i]) if extra_x else 0
        requested = (x+dx,y)
        x = max(3,min(93-w,x+dx))
        if not align and y<3:
            raise ValueError(f'{mid}/{row} F{i+1}: ground/preserved bottom requires top {y}; reduce row factor')
        y=max(3,min(93-h,y))
        im=Image.new('RGBA',(96,96)); im.alpha_composite(canvas.crop(box),(x,y))
        assert np.count_nonzero(np.array(im)[:,:,3]) == np.count_nonzero(np.array(canvas)[:,:,3])
        output.append(im)
        placements.append(dict(frame=i+1,raw_bbox=list(clean.getbbox()),working_bbox=list(box),
            before_bbox=list(ob),after_bbox=list(im.getbbox()),requested_xy=list(requested),
            margin_adjustment=[x-requested[0],y-requested[1]],extra_x=dx,
            source_sha256=sha(RAW/f'{mid}-{row}.png')))
    return output, placements

def mapped_points(mid,row,index,factor,im):
    # Existing manually inspected ruler traced through raw common scale and
    # whole-frame placement, retaining subpixel length. Pixel boundary uncertainty
    # remains +/-1 per endpoint; this is a traced ruler, not an anatomy classifier.
    prev=frames(FIX/'before'/f'{mid}-{row}-v1.png',row)[index]
    points=LANDMARKS[mid][row][0 if index==0 else 1]
    oldfactor=load_json(FIX/'before'/f'{mid}-{row}-v1.json')['factor']
    ob=prev.getbbox(); nb=im.getbbox()
    return [[nb[j]+(pt[j]-ob[j])*factor/oldfactor for j in [0,1]] for pt in points]

def ruler_length(points):
    return math.dist(*points)

def cell_tile(im, scale=4, points=None):
    tile=n.checker((96,96)).convert('RGB'); tile.paste(im,(0,0),im)
    tile=tile.resize((96*scale,96*scale),Image.Resampling.NEAREST)
    d=ImageDraw.Draw(tile)
    d.line((0,72*scale,96*scale,72*scale),fill=(220,90,155),width=1)
    if points:
        xy=[(x*scale,y*scale) for x,y in points]
        d.line(xy,fill=(255,225,85),width=2)
        for x,y in xy:d.ellipse((x-3,y-3,x+3,y+3),outline='white')
    return tile

def measure(factors):
    data=[]
    for mid in IDS:
        for row in ROWS:
            before=frames(FIX/'before'/f'{mid}-{row}-v1.png',row)
            after=frames(BAKE/f'{mid}-{row}-v1.png',row)
            idx=rep_index(mid,row)
            factor=factors[mid][ROWS.index(row)]
            bp=LANDMARKS[mid][row][0 if idx==0 else 1]
            ap=mapped_points(mid,row,idx,factor,after[idx])
            data.append(dict(monster=mid,row=row,frame=idx+1,part=LANDMARKS[mid]['part'],
                             before_points=bp,after_points=ap,before_px=ruler_length(bp),after_px=ruler_length(ap),
                             factor_before=load_json(FIX/'before'/f'{mid}-{row}-v1.json')['factor'],factor_after=factor))
        idle=data[-6]
        # Same idle first/last mean as the original ART-76 report.
        b_idle=sum(ruler_length(p) for p in LANDMARKS[mid]['idle'])/2
        idle_factor=factors[mid][0]/load_json(FIX/'before'/f'{mid}-idle-v1.json')['factor']
        a_idle=b_idle*idle_factor
        for d in data[-6:]:
            d['idle_reference_before_px']=b_idle;d['idle_reference_after_px']=a_idle
            d['ratio_before']=d['before_px']/b_idle;d['ratio_after']=d['after_px']/a_idle
            d['nominal_within_5pct']=.95<=d['ratio_after']<=1.05
    dump(FIX/'sizes.json',data)
    return data

def boards(sizes):
    for mid in IDS:
        items=[x for x in sizes if x['monster']==mid]
        panel=Image.new('RGB',(3*412,4*442+50),(22,27,39)); d=ImageDraw.Draw(panel)
        d.text((10,6),f'{mid} | BEFORE top / AFTER bottom | exact 4x',font=n.font(19),fill='white')
        for ri,item in enumerate(items):
            row=item['row'];idx=item['frame']-1
            for phase in [0,1]:
                im=frames((FIX/'before' if phase==0 else BAKE)/f'{mid}-{row}-v1.png',row)[idx]
                x=(ri%3)*412+16;y=50+(ri//3*2+phase)*442
                length=item['before_px' if phase==0 else 'after_px'];ratio=item['ratio_before' if phase==0 else 'ratio_after']
                d.text((x,y),f'{row} F{idx+1} {"before" if phase==0 else "after"} {length:.2f}px {ratio:.3f}x',font=n.font(16),fill='white')
                panel.paste(cell_tile(im,points=item['before_points' if phase==0 else 'after_points']),(x,y+30))
        panel.save(FIX/f'{mid}-size-before-after-4x.png')
    # Every changed row, all frames at exact 4x, three columns to avoid downsampling.
    for item in sizes:
        mid,row=item['monster'],item['row']
        path=BAKE/f'{mid}-{row}-v1.png'
        if sha(path)==sha(FIX/'before'/path.name):continue
        a=frames(path,row); b=frames(FIX/'before'/path.name,row)
        panel=Image.new('RGB',(3*400,math.ceil(len(a)/3)*2*418+45),(22,27,39));d=ImageDraw.Draw(panel)
        d.text((10,4),f'{mid} / {row} | before above / after below | 4x',font=n.font(18),fill='white')
        for i in range(len(a)):
            for phase,ims in enumerate([b,a]):
                x=(i%3)*400;y=45+(i//3*2+phase)*418
                d.text((x+5,y),f'F{i+1} {"before" if phase==0 else "after"}',font=n.font(15),fill='white')
                panel.paste(cell_tile(ims[i]),(x+6,y+24))
        panel.save(FIX/f'{mid}-{row}-all-frames-4x.png')

def main():
    snapshot()
    config=load_json(FIX/'config.json')
    factors=config['factors'];extra=config.get('extra_x',{})
    results=[]
    for mid in IDS:
        for ri,row in enumerate(ROWS):
            name=f'{mid}-{row}-v1'
            meta=load_json(FIX/'before'/f'{name}.json')
            factor=factors[mid][ri];ex=extra.get(mid,{}).get(row)
            if factor==meta['factor'] and not ex:
                shutil.copy2(FIX/'before'/f'{name}.png',BAKE/f'{name}.png')
                shutil.copy2(FIX/'before'/f'{name}.json',BAKE/f'{name}.json')
                continue
            ims,moves=rebuild_row(mid,row,factor,ex)
            n.save_sheet(ims,BAKE/f'{name}.png',96)
            meta['factor']=factor
            meta['note']+=' ART-76 fix-1: raw에서 행 공통 배율로 재구축, 전체 프레임 평행 이동.'
            meta['size_review']='reports/codex-art-76/fix-1/sizes.json'
            dump(BAKE/f'{name}.json',meta)
            results.append(dict(monster=mid,row=row,factor=factor,placements=moves))
            print(mid,row,factor,'min-detail',min(n.interior_detail(im) for im in ims),
                  'min-margin',min(n.margins(im.getbbox(),96)['minimum'] for im in ims),flush=True)
        sheet=Image.new('RGBA',(576,576))
        for ri,row in enumerate(ROWS):
            sheet.alpha_composite(Image.open(BAKE/f'{mid}-{row}-v1.png').convert('RGBA'),(0,ri*96))
        sheet.save(BAKE/f'{mid}_sheet-v1.png')
    dump(FIX/'rebuild-metrics.json',results)
    sizes=measure(factors);boards(sizes)
    print('SIZE FAILURES',[(d['monster'],d['row'],round(d['ratio_after'],3)) for d in sizes if not d['nominal_within_5pct']],flush=True)

if __name__=='__main__':main()
