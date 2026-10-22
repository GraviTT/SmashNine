"""ART-76 only: invoke the unmodified D35 normalizer and audit 96px candidates."""
import os
os.environ['PYTHONDONTWRITEBYTECODE'] = '1'
import sys, json, statistics, importlib.util
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('normalizer', ROOT/'tools/sprite_pipeline/normalize.py')
n = importlib.util.module_from_spec(spec); spec.loader.exec_module(n)
REPORT = ROOT/'reports/codex-art-76'
BAKE = ROOT/'art/bakeoff/monsters'
ROWS = ['idle','walk','windup','attack','hurt','defeat']
COUNTS = dict(zip(ROWS,[6,6,4,6,2,4]))
WINDUP = dict(muspelheim_magma_boar=.65,niflheim_glacier_wolf=.55,niflheim_frost_owl=.45,jotunheim_storm_wisp=.45,yggdrasil_root_guardian=.9,yggdrasil_root_oracle=.7)
NOTES = {'idle':'기준 대기: 호흡 또는 제자리 날갯짓','walk':'이동: 보행 또는 비행 날갯짓','windup':'새 준비 행: 실루엣으로 공격 예고, 마지막 자세 유지','attack':'행동 원형에 맞춘 공격 동작','hurt':'피격: 충격과 반동','defeat':'새 쓰러짐 행: 마지막에 바닥으로 쓰러짐'}

def frames(path,count):
    im=Image.open(path).convert('RGBA')
    return [im.crop((96*i,0,96*(i+1),96)) for i in range(count)]

def audit(mid,row):
    path=BAKE/f'{mid}-{row}-v1.png'
    ims=frames(path,COUNTS[row]); data=[]
    for i,im in enumerate(ims):
        box=im.getbbox()
        data.append(dict(index=i,bbox=box,margin=n.margins(box,96)['minimum'],detail=n.interior_detail(im),spill=n.spill_pixel_count(im),alpha_binary=set(im.getchannel('A').get_flattened_data()) <= {0,255},bottom=box[3]-1))
    mpath=REPORT/mid/row/'metrics.json'
    m=json.loads(mpath.read_text('utf-8'))
    m['audit96']=data
    mpath.write_text(json.dumps(m,ensure_ascii=False,indent=2),'utf-8')
    print(mid,row,'factor',m['summary']['common_scale'],'margin',min(x['margin'] for x in data),'detail',[min(x['detail'] for x in data),max(x['detail'] for x in data)],'spill',sum(x['spill'] for x in data),'bottom',[x['bottom'] for x in data])
    return data

def align(mid,row,coords,target=None):
    """Flyers use the card's body centre, not the normalizer's walking feet pivot."""
    target=target or ((68,44) if mid=='yggdrasil_root_oracle' else (47,44) if mid=='jotunheim_storm_wisp' else (62,50) if mid=='alfheim_moon_moth' else (49,50))
    points=[tuple(map(float,p.split(','))) for p in coords.split(';')]
    out=REPORT/mid/row; mp=out/'metrics.json'; m=json.loads(mp.read_text('utf-8'))
    ims=frames(BAKE/f'{mid}-{row}-v1.png',COUNTS[row]); source,_=n.split_sheet(ROOT/f'art/raw/monsters-76/{mid}-{row}.png',tuple(m['input']['grid']))
    assert len(points)==len(ims)
    factor=m['summary']['common_scale']; fixed=[]; positions=[]
    for i,(im,raw,point) in enumerate(zip(ims,source,points)):
        clean,_=n.clean_background(raw,'#00ff00'); sb=clean.getbbox(); ob=im.getbbox()
        centre=(ob[0]+(point[0]-sb[0])*factor,ob[1]+(point[1]-sb[1])*factor)
        delta=(round(target[0]-centre[0]),round(target[1]-centre[1]))
        box=tuple(ob[j]+delta[j%2] for j in range(4))
        if min(box[:2])<3 or max(box[2:])>93:raise ValueError(f'body alignment clips frame {i}: {box}; choose one smaller factor or regenerate')
        dst=Image.new('RGBA',(96,96));dst.alpha_composite(im,delta);fixed.append(dst)
        positions.append(dict(frame=i,source_point=point,target=target,translation=delta,body_centre_after=[round(centre[j]+delta[j],2) for j in range(2)]))
    for i,im in enumerate(fixed):im.save(out/'frames'/f'{mid}-{row}-v1-{i:02d}.png')
    n.save_sheet(fixed,BAKE/f'{mid}-{row}-v1.png',96);n.save_sheet(fixed,out/f'{mid}-{row}-v1.png',96)
    n.write_visuals(fixed,out,None,f'{mid} {row}',72,4)
    m['body_alignment']=dict(method='whole-frame translation to stable body landmark; no rescaling',landmark='magenta eye' if mid=='yggdrasil_root_oracle' else 'cyan core' if mid=='jotunheim_storm_wisp' else 'shoulder medallion' if 'raven' in mid else 'featureless orb head',frames=positions)
    mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),'utf-8');audit(mid,row)

def contacts(mid,row,indices):
    out=REPORT/mid/row;mp=out/'metrics.json';m=json.loads(mp.read_text('utf-8'))
    ims=frames(BAKE/f'{mid}-{row}-v1.png',COUNTS[row]);moves=[]
    for i in map(int,indices.split(',')):
        box=ims[i].getbbox();dy=72-(box[3]-1);dst=Image.new('RGBA',(96,96));dst.alpha_composite(ims[i],(0,dy));ims[i]=dst
        assert n.margins(dst.getbbox(),96)['minimum']>=3
        moves.append(dict(frame=i,translation_y=dy,contact_y=72))
    for i,im in enumerate(ims):im.save(out/'frames'/f'{mid}-{row}-v1-{i:02d}.png')
    n.save_sheet(ims,BAKE/f'{mid}-{row}-v1.png',96);n.save_sheet(ims,out/f'{mid}-{row}-v1.png',96)
    n.write_visuals(ims,out,None,f'{mid} {row}',72,4)
    m['ground_contacts']=moves;mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),'utf-8');audit(mid,row)

def orb(mid,row):
    out=REPORT/mid/row;mp=out/'metrics.json';m=json.loads(mp.read_text('utf-8'))
    source,_=n.split_sheet(ROOT/f'art/raw/monsters-76/{mid}-{row}.png',tuple(m['input']['grid']))
    points=[];landmarks=[]
    for frame_index,frame in enumerate(source):
        a=n.np.asarray(frame.convert('RGBA'));mask=(a[:,:,0]>190)&(a[:,:,1]>170)&(a[:,:,2]>210)&(a[:,:,3]>0);seen=n.np.zeros(mask.shape,dtype=bool);groups=[]
        for sy,sx in zip(*n.np.where(mask)):
            if seen[sy,sx]:continue
            q=n.deque([(int(sx),int(sy))]);seen[sy,sx]=True;pixels=[]
            while q:
                x,y=q.popleft();pixels.append((x,y))
                for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                    if 0<=ny<mask.shape[0] and 0<=nx<mask.shape[1] and mask[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;q.append((nx,ny))
            groups.append(pixels)
        pixels=[p for g in groups for p in g] if row=='attack' and frame_index==3 else max(groups,key=len)
        xs,ys=zip(*pixels);box=[min(xs),min(ys),max(xs)+1,max(ys)+1];point=((box[0]+box[2]-1)/2,(box[1]+box[3]-1)/2)
        points.append(point);landmarks.append(dict(bright_orb_bbox=box,source_centre=point,bright_width_output=round((box[2]-box[0])*m['summary']['common_scale'],2)))
    print('measured bright orb',mid,row,landmarks)
    align(mid,row,';'.join(f'{x},{y}' for x,y in points))
    m=json.loads(mp.read_text('utf-8'));m['orb_measurement']=dict(threshold='R>190 G>170 B>210; largest 4-connected component',frames=landmarks);mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),'utf-8')

def normalize(mid,row,factor,ground=False,feet=72,pick=None,offset=0):
    count=COUNTS[row]; grid='3x2' if count==6 else '2x2' if count==4 else '2x1'
    out=REPORT/mid/row
    args=['--sheet',str(ROOT/f'art/raw/monsters-76/{mid}-{row}.png'),'--grid',grid,'--bg','#00ff00','--cell','96','--feet-y',str(feet),'--scale-by',f'fixed:{factor}','--resample','lanczos','--sharpen','60','--despill','auto','--palette','none','--compare-scale','4','--out-dir',str(out),'--name',f'{mid}-{row}-v1','--candidate-out',str(BAKE/f'{mid}-{row}-v1.png')]
    args+=['--offset-x',str(offset)]
    if ground: args+=['--ground-all']
    if pick: args+=['--pick',pick]
    parsed=n.parser().parse_args(args); parsed.palette=None
    m=n.normalize(parsed)
    fps=4/WINDUP[mid] if row=='windup' else dict(idle=6,walk=10,attack=12,hurt=8,defeat=8)[row]
    meta=dict(note=NOTES[row],frames=count,fps=round(fps,6),loop=row in ['idle','walk'] or (row=='attack' and mid in ['muspelheim_magma_boar']),cell=96,feet=72,factor=factor)
    if row=='windup':meta.update(windup_seconds=WINDUP[mid],hold_last=True)
    (BAKE/f'{mid}-{row}-v1.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n','utf-8')
    audit(mid,row)

def board(mid):
    old=Image.open(ROOT/f'smash-nine-prototype/assets/art/monsters/{mid}_sheet.png').convert('RGBA')
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
    small=Image.new('RGB',(1192,6*124+50),(24,29,40)); d=ImageDraw.Draw(small)
    d.text((12,8),f'{mid} | LEFT current game / RIGHT candidate | 1x',font=font,fill='white')
    sheet=Image.new('RGBA',(576,576))
    for ri,row in enumerate(ROWS):
        y=50+124*ri
        d.text((10,y),row,font=font,fill='white')
        oi={'idle':0,'walk':1,'attack':2,'hurt':3}.get(row)
        if oi is not None: small.paste(old.crop((0,96*oi,576,96*(oi+1))),(0,y+25),old.crop((0,96*oi,576,96*(oi+1))))
        p=BAKE/f'{mid}-{row}-v1.png'
        if p.exists():
            im=Image.open(p).convert('RGBA'); small.paste(im,(600,y+25),im);sheet.alpha_composite(im,(0,96*ri))
    small.save(REPORT/f'{mid}-1x.png')
    # Full 4x board is kept separately to avoid downscaling in image viewers.
    large=small.resize((small.width*4,small.height*4),Image.Resampling.NEAREST)
    large.save(REPORT/f'{mid}-4x.png')
    combined=Image.new('RGB',(large.width,small.height+large.height+25),(24,29,40))
    combined.paste(small,(0,0));combined.paste(large,(0,small.height+25));combined.save(REPORT/f'{mid}.png')
    if all((BAKE/f'{mid}-{r}-v1.png').exists() for r in ROWS):sheet.save(BAKE/f'{mid}_sheet-v1.png')

if __name__=='__main__':
    if sys.argv[1]=='orb':orb(sys.argv[2],sys.argv[3])
    elif sys.argv[1]=='contacts':contacts(sys.argv[2],sys.argv[3],sys.argv[4])
    elif sys.argv[1]=='align':align(sys.argv[2],sys.argv[3],sys.argv[4])
    elif sys.argv[1]=='board':board(sys.argv[2])
    elif sys.argv[1]=='audit':audit(sys.argv[2],sys.argv[3])
    else:normalize(sys.argv[1],sys.argv[2],float(sys.argv[3]),'--ground' in sys.argv,feet=int(sys.argv[sys.argv.index('--feet')+1]) if '--feet' in sys.argv else 72,offset=int(sys.argv[sys.argv.index('--offset')+1]) if '--offset' in sys.argv else 0)
