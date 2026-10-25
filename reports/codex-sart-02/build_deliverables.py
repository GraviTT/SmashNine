"""SART-02: exclusive candidate ingest, deterministic Pillow measurements/boards."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageStat
import argparse, hashlib, json, math, statistics

REPORT = Path(__file__).resolve().parent
ROOT = REPORT.parents[1]
RAW = ROOT / 'art/raw/story'
CAND = ROOT / 'art/bakeoff/story'
FONT = Path('C:/Windows/Fonts/malgun.ttf')
RESAMPLE = Image.Resampling.LANCZOS
ORDER = [2, 1, 8, 3, 9, 7, 4, 5, 6]
CIRCLED = dict(enumerate('①②③④⑤⑥⑦⑧⑨', 1))

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def dump(path, data, exclusive=False):
    with path.open('x' if exclusive else 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def metric(im):
    im = im.convert('RGB')
    # Y' uses sRGB code values; it is a display-brightness proxy, NOT linear luminance.
    y = [(.2126*r + .7152*g + .0722*b) / 255 for r,g,b in im.getdata()]
    avg = statistics.fmean(y)
    sat = ImageStat.Stat(im.convert('HSV').getchannel('S')).mean[0] / 255
    contrast = math.sqrt(statistics.fmean((v-avg)**2 for v in y))
    w,h = im.size
    mask = Image.new('L',(w,h),0)
    ImageDraw.Draw(mask).rectangle((0,0,w-1,h-1),outline=255,width=8)
    edge = ImageStat.Stat(im.convert('L'),mask=mask)
    return {'brightness_mean_y709':round(avg,6), 'saturation_mean_hsv':round(sat,6),
            'contrast_std_y709':round(contrast,6), 'outer_8px_mean_luma601':round(edge.mean[0]/255,6)}

def ingest(jobs):
    RAW.mkdir(parents=True,exist_ok=True)
    CAND.mkdir(parents=True,exist_ok=True)
    for j in jobs:
        if not j.get('source'):
            raise ValueError('No generated source: '+j['id'])
        raw = RAW / (j['id']+'_raw.png')
        cand = CAND / (j['id']+'.png')
        meta = CAND / (j['id']+'.json')
        src = Path(j['source'])
        if meta.exists():
            m=read(meta)
            assert sha(raw)==m['raw_sha256'] and sha(cand)==m['candidate_sha256']
            continue
        if cand.exists():
            raise FileExistsError('Partial previous ingest; will not overwrite '+j['id'])
        if raw.exists():
            assert sha(raw)==sha(src), 'Existing raw differs from source'
        else:
            with raw.open('xb') as f:
                f.write(src.read_bytes())
        with Image.open(raw) as original:
            original.load()
            w,h=original.size
            k=min(w//16,h//9)
            cw,ch=16*k,9*k
            assert cw>=640 and ch>=360, 'Upscale prohibited'
            x,y=(w-cw)//2,(h-ch)//2
            box=j.get('crop_box',[x,y,x+cw,y+ch])
            cw,ch=box[2]-box[0],box[3]-box[1]
            assert cw*9==ch*16 and cw>=640 and ch>=360
            opaque=original.convert('RGBA').getchannel('A').getextrema()==(255,255)
            assert opaque, 'Unexpected alpha requires review'
            final=original.crop(box).convert('RGB').resize((640,360),RESAMPLE)
            with cand.open('xb') as f:
                final.save(f,format='PNG',optimize=True)
            m={'note':j['note'], 'stage':j['stage'], 'title':j['title'], 'version':j['version'],
               'status':'candidate', 'size':[640,360], 'mode':'RGB', 'opaque':True,
               'processing':{'source_returned_by_image_gen':j['source'],
                 'raw_copy':raw.relative_to(ROOT).as_posix(),'raw_byte_identical':sha(src)==sha(raw),
                 'raw_size':[w,h], 'raw_mode':original.mode,'crop_box_ltrb_exclusive':box,
                 'crop_size':[cw,ch], 'crop_method':'review-directed exact 16:9 crop' if j.get('crop_box') else 'largest centred exact 16:9 integer crop',
                 'resize_to':[640,360], 'resize_filter':'Pillow Image.Resampling.LANCZOS',
                 'scale_x':640/cw,'scale_y':360/ch,'upscale':False,
                 'other_operations':['convert RGB (source already opaque)'],
                 'colour_or_content_edit':False},
               'raw_sha256':sha(raw),'candidate_sha256':sha(cand),'metrics':metric(final),
               'prompt':j['prompt'],'references_in_order':j['refs']}
        dump(meta,m,exclusive=True)
        print(j['id'],f'{w}x{h} -> {box} -> 640x360')

def font(size):
    return ImageFont.truetype(str(FONT),size)

def text(d,xy,string,size=22,colour='#e9ecff'):
    d.text(xy,string,font=font(size),fill=colour)

def save_board(im,path):
    im.save(path,format='JPEG',quality=90,subsampling=0,optimize=True)
    assert path.stat().st_size<=2_000_000,(path,path.stat().st_size)

def boards(jobs,selected):
    for s in range(1,10):
        group=sorted((j for j in jobs if j['stage']==s),key=lambda x:x['version'])
        w=24+len(group)*664
        board=Image.new('RGB',(w,810),'#101727')
        d=ImageDraw.Draw(board)
        text(d,(24,12),f"{CIRCLED[s]} {group[0]['title']}  ·  원본 후보 640×360 / 축소 480×270",24)
        for n,j in enumerate(group):
            x=24+n*664
            chosen=selected.get(str(s))==j['version']
            text(d,(x,55),f"v{j['version']}"+(' · 추천' if chosen else ''),22,'#f3cd7c' if chosen else '#b7c4dc')
            with Image.open(CAND/(j['id']+'.png')) as im:
                board.paste(im,(x,91))
                board.paste(im.resize((480,270),RESAMPLE),(x+80,493))
        save_board(board,REPORT/f'stage-{s:02d}-comparison.jpg')
    board=Image.new('RGB',(1512,1038),'#101727')
    d=ImageDraw.Draw(board)
    text(d,(24,12),'SART-02 · 추천 세트 · 후보 / 게임 미적용',26)
    for n,s in enumerate(ORDER):
        j=next(j for j in jobs if j['stage']==s and j['version']==selected[str(s)])
        x=24+(n%3)*496
        y=64+(n//3)*320
        with Image.open(CAND/(j['id']+'.png')) as im:
            board.paste(im.resize((480,270),RESAMPLE),(x,y))
        text(d,(x,y+276),f"{CIRCLED[s]} {j['title']}",23)
        text(d,(x+420,y+279),f"v{j['version']}",18,'#f3cd7c')
    save_board(board,REPORT/'set-board.jpg')

def measure(jobs,selected):
    rows=[]
    for j in jobs:
        m=read(CAND/(j['id']+'.json'))
        with Image.open(CAND/(j['id']+'.png')) as im:
            assert im.size==(640,360) and im.mode=='RGB'
            actual=metric(im)
        assert actual==m['metrics']
        rows.append({'id':j['id'],'stage':j['stage'],'version':j['version'],
          'recommended':selected.get(str(j['stage']))==j['version'],'size':[640,360],**actual})
    keys=['brightness_mean_y709','saturation_mean_hsv','contrast_std_y709']
    def spread(rs):
        return {k:{'mean':statistics.fmean(r[k] for r in rs),
          'min':min(r[k] for r in rs),'max':max(r[k] for r in rs),
          'range':max(r[k] for r in rs)-min(r[k] for r in rs),
          'std_population':statistics.pstdev(r[k] for r in rs)} for k in keys}
    data={'definitions':{'brightness_mean_y709':'mean((0.2126 R + 0.7152 G + 0.0722 B)/255), sRGB code values',
      'saturation_mean_hsv':'Pillow HSV S channel mean /255',
      'contrast_std_y709':'population standard deviation of per-pixel Y709',
      'interpretation':'diagnostic spread only; aesthetic matching requires visual judgement'},
      'variants':rows,'all':spread(rows),'recommended':spread([r for r in rows if r['recommended']])}
    dump(REPORT/'measurements.json',data)
    return data

if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--manifest',default='generations.json')
    p.add_argument('--selection',default='selection.json')
    a=p.parse_args()
    jobs=read(REPORT/a.manifest)['jobs']
    for extra in sorted(REPORT.glob('reworks*.json')):
        jobs += read(extra)['jobs']
    selected=read(REPORT/a.selection) if (REPORT/a.selection).exists() else {str(s):1 for s in range(1,10)}
    ingest(jobs)
    data=measure(jobs,selected)
    boards(jobs,selected)
    print(json.dumps({'candidates':len(jobs),'recommended_spread':data['recommended']},ensure_ascii=False))
