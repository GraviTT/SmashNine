"""ART-91 exclusive-create pipeline. Normalize, inspect, then deliver one row."""
from pathlib import Path
from datetime import datetime
import sys, json, hashlib, importlib.util, shutil
import numpy as np
from PIL import Image, ImageDraw, ImageFont
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/'reports/codex-art-91'; RAW=ROOT/'art/raw/monsters-91'; BAKE=ROOT/'art/bakeoff/monsters'
spec=importlib.util.spec_from_file_location('normalizer91',ROOT/'tools/sprite_pipeline/normalize.py')
n=importlib.util.module_from_spec(spec);spec.loader.exec_module(n)
def new_json(p,data):
    with p.open('x',encoding='utf-8') as f:json.dump(data,f,ensure_ascii=False,indent=2);f.write('\n')
def save(im,p):
    with p.open('xb') as f:im.save(f,format='PNG')
def orb(im):
    a=np.asarray(im); mask=(a[:,:,0]>190)&(a[:,:,1]>170)&(a[:,:,2]>210)&(a[:,:,3]>127)
    seen=np.zeros(mask.shape,bool);groups=[]
    for y,x in zip(*np.where(mask)):
        if seen[y,x]:continue
        q=[(int(x),int(y))];seen[y,x]=True;g=[]
        for xx,yy in q:
            g.append((xx,yy))
            for nx,ny in [(xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)]:
                if 0<=ny<mask.shape[0] and 0<=nx<mask.shape[1] and mask[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;q.append((nx,ny))
        groups.append(g)
    g=max(groups,key=len); xs,ys=zip(*g)
    return dict(size=len(g)**.5,center=[(min(xs)+max(xs))/2,(min(ys)+max(ys))/2],bbox=[min(xs),min(ys),max(xs)+1,max(ys)+1])
def prepare(config_path):
    c=json.loads(Path(config_path).read_text(encoding='utf-8-sig'));out=RAW/c['trial'];out.mkdir(parents=True,exist_ok=False)
    src=Path(c['source']);dst=out/'source.png';shutil.copyfile(src,dst)
    frames,labels=n.split_sheet(dst,tuple(c.get('grid',[6,1])))
    assert len(frames)==6
    clean=[n.clean_background(im,'alpha')[0] for im in frames];n.validate_source_cell_margin(clean,labels)
    idle=Image.open(ROOT/c['idle']).convert('RGBA').crop((0,0,96,96))
    if c.get('measure')=='orb':
        ref=orb(idle); raw_m=[orb(im) for im in clean];factor=ref['size']/float(np.mean([m['size'] for m in raw_m]))
    else:
        ref={'size':c['idle_landmark_size']};raw_m=[{'size':x} for x in c['raw_landmark_sizes']];factor=c.get('factor',ref['size']/float(np.mean([m['size'] for m in raw_m])))
    normalized=[];audit=[]
    for i,im in enumerate(clean):
        box=im.getbbox();sub=im.crop(box);sub=sub.resize((round(sub.width*factor),round(sub.height*factor)),Image.Resampling.LANCZOS)
        sub=n.apply_unsharp(sub,60);sub.putalpha(sub.getchannel('A').point(lambda v:255 if v>=128 else 0))
        # True-alpha input has no chroma green. Preserve naturally green bodies.
        if c.get('measure')=='orb':
            lm=orb(sub);target=ref['center'];x=round(target[0]-lm['center'][0]);y=round(target[1]-lm['center'][1])
        else:
            x=round(48-sub.width/2)+c.get('offset_x',0);y=c.get('bottom',72)-sub.height+1
        canvas=Image.new('RGBA',(96,96));
        if x<0 or y<0 or x+sub.width>96 or y+sub.height>96:raise ValueError(f'frame {i+1} clips: {x,y,sub.size}')
        canvas.alpha_composite(sub,(x,y));normalized.append(canvas)
        bb=canvas.getbbox(); rgba=np.asarray(canvas);opaque=rgba[:,:,3]>0
        ratio=orb(canvas)['size']/ref['size'] if c.get('measure')=='orb' else raw_m[i]['size']*factor/ref['size']
        audit.append(dict(frame=i+1,bbox=bb,margin=min(bb[0],bb[1],96-bb[2],96-bb[3]),bottom=bb[3]-1,landmark_ratio=ratio,orb=orb(canvas) if c.get('measure')=='orb' else None,alpha_binary=set(np.unique(rgba[:,:,3]).tolist())<={0,255},pure_chroma_pixels=int(np.sum(opaque&(rgba[:,:,0]==0)&(rgba[:,:,1]==255)&(rgba[:,:,2]==0))),sha256=hashlib.sha256(canvas.tobytes()).hexdigest()))
    strip=Image.new('RGBA',(576,96))
    for i,im in enumerate(normalized):strip.alpha_composite(im,(96*i,0))
    board=Image.new('RGB',(7*384,430),(26,30,40));d=ImageDraw.Draw(board);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
    for i,im in enumerate([idle]+normalized):
        d.text((i*384+8,5),'IDLE reference' if i==0 else f'APPEAR {i}',font=font,fill='white')
        board.paste(im.resize((384,384),Image.Resampling.NEAREST),(i*384,36),im.resize((384,384),Image.Resampling.NEAREST))
    save(strip,out/'strip.png');save(board,out/'board.png')
    failures=[]
    for a in audit:
        if a['margin']<4:failures.append(f"F{a['frame']} margin {a['margin']} <4")
        if not .95<=a['landmark_ratio']<=1.05:failures.append(f"F{a['frame']} size {a['landmark_ratio']:.4f} outside .95..1.05")
        if a['pure_chroma_pixels']:failures.append('chroma key pixels')
        if not a['alpha_binary']:failures.append('alpha')
        if c.get('grounded',True) and a['bottom']!=72:failures.append('feet bottom not 72')
    if len({a['sha256'] for a in audit})!=6:failures.append('duplicate frames')
    m=dict(config=c,source_dimensions=list(Image.open(dst).size),factor=factor,idle_landmark=ref,raw_landmarks=raw_m,frames=audit,failures=failures,notes='Size uses named anatomical landmark, not pose bbox. Manual endpoint uncertainty is separate from nominal ratios. Alpha source means no chroma-key removal or palette remapping.')
    new_json(out/'metrics.json',m);print(json.dumps({'trial':c['trial'],'factor':factor,'audit':audit,'failures':failures}))
def deliver(trial,note):
    out=RAW/trial;m=json.loads((out/'metrics.json').read_text(encoding='utf-8'));c=m['config'];assert not m['failures'],m['failures']
    stem=f"{c['id']}-{c['row']}-v1";png=BAKE/(stem+'.png');jp=png.with_suffix('.json');board=REPORT/f"{c['id']}-{c['row']}.png";evidence=REPORT/f"{c['id']}-{c['row']}-checks.json"
    for p in [png,jp,board,evidence]:assert not p.exists(),str(p)
    save(Image.open(out/'strip.png'),png);save(Image.open(out/'board.png'),board)
    meta=dict(note=note,frames=6,fps=10,cell=96,feet=72,loop=False,new_row=True,factor=m['factor'])
    new_json(jp,meta);m['visual_review']=note;m['delivered_at']=datetime.now().astimezone().isoformat();new_json(evidence,m)
    with (REPORT/'progress.md').open('a',encoding='utf-8') as f:f.write(f"|{m['delivered_at']}|{c['id']}|{c['row']}|{png.relative_to(ROOT).as_posix()}|6|PASS: 정적 규격·크기 지표 + 육안|{note}|\n")
    with (REPORT/'commit-paths.txt').open('a',encoding='utf-8') as f:
        for p in [png,jp,board,evidence]:f.write(p.relative_to(ROOT).as_posix()+'\n')
    print('DELIVERED',stem)
if __name__=='__main__':
    if sys.argv[1]=='prepare':prepare(sys.argv[2])
    elif sys.argv[1]=='deliver':deliver(sys.argv[2],sys.argv[3])
