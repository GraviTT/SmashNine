"""QA-23 offline image audit. Reads product art; writes only card report paths.
Run with Codex runtime Python, one process. No Godot, no art changes.
Pixels: visible alpha>=128; all-alpha diagnostics also retained. Bboxes exclusive.
"""
from pathlib import Path
import argparse, collections, hashlib, json, math, re
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[4]
OUT = ROOT / 'reports/codex-qa-23'
ART = ROOT / 'smash-nine-prototype/assets/art'
STEMS = ['frey','luna','luna_brave','nova_male','nova_female','rio_male','rio_female','yuki']
AIR = {'jump','fall','tumble','attack_air_side','spike_followup','brave_air_side','brave_dive','air_side','meteor_kick','air_slash','plunge','talisman_air_side','talisman_air_down'}
MIXED = {'rising_cleave','descent','transform','brave_upper','comet_drive','luna_breaker','vector_upper','vector_shift','rising_slash'}
FLY = {'alfheim_moon_moth','asgard_runic_raven','ember_imp','jotunheim_storm_wisp','niflheim_frost_owl','svartalfheim_cog_drone','vanaheim_seed_sprite','yggdrasil_root_oracle'}

def dump(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')

def table(path, key):
    s=path.read_text(encoding='utf-8'); start=re.search(r'const '+key+r'\s*:?=\s*\[',s).end()-1
    depth=0
    for end in range(start,len(s)):
        depth += (s[end]=='[')-(s[end]==']')
        if depth==0:break
    return json.loads(re.sub(r',\s*]',']',s[start:end+1]))

def bbox(m):
    y,x=np.nonzero(m)
    return [int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1)] if x.size else None

def components(m):
    # Eight-connected components; no scipy dependency.
    seen=np.zeros_like(m); sizes=[]; small=[]; h,w=m.shape
    for y,x in zip(*np.nonzero(m)):
        if seen[y,x]:continue
        stack=[(int(y),int(x))];seen[y,x]=True;points=[]
        while stack:
            cy,cx=stack.pop();points.append((cy,cx))
            for dy,dx in ((-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)):
                yy,xx=cy+dy,cx+dx
                if 0<=yy<h and 0<=xx<w and m[yy,xx] and not seen[yy,xx]:seen[yy,xx]=True;stack.append((yy,xx))
        sizes.append(len(points))
        if len(points)<=3:small.extend([[x,y] for y,x in points])
    return sorted(sizes,reverse=True),small

def measure(im, ref=None):
    a=np.array(im.convert('RGBA'));al=a[:,:,3];m=al>=128; anym=al>0; b=bbox(m);h,w=m.shape
    pad=np.pad(m,1);inner=m.copy();near=np.zeros_like(m)
    for dy,dx in ((-1,0),(1,0),(0,-1),(0,1)):
        adj=pad[1+dy:1+dy+h,1+dx:1+dx+w];inner &= adj;near |= adj
    rim=anym & ~inner
    r,g,bl=(a[:,:,i].astype(np.int16) for i in range(3))
    green=anym & (g>80) & (g-r>35) & (g-bl>25)
    magenta=anym & (r>150) & (bl>120) & (r-g>60) & (bl-g>40)
    white=anym & (r>235) & (g>235) & (bl>235)
    border=np.ones_like(m);border[1:-1,1:-1]=False
    margin=np.ones_like(m);margin[4:-4,4:-4]=False
    sizes,small=components(m)
    pix=a[:,:,:3][m]
    hist=[]
    if len(pix):
        # Coarse RGB histogram measures a change, never proves a colour fault.
        idx=(pix[:,0]//32).astype(int)*64+(pix[:,1]//32)*8+pix[:,2]//32
        hist=(np.bincount(idx,minlength=512)/len(pix)).tolist()
    out={'bbox':b,'bbox_any_alpha':bbox(anym),'width':b[2]-b[0] if b else 0,'height':b[3]-b[1] if b else 0,
         'area':int(m.sum()),'alpha_any':int(anym.sum()),'partial_alpha':int(((al>0)&(al<255)).sum()),
         'partial_rim':int(((al>0)&(al<255)&rim).sum()),'partial_interior':int(((al>0)&(al<255)&inner).sum()),
         'edge_px':int((m&border).sum()),'edge_any_alpha':int((anym&border).sum()),
         'edge_sides':[int(m[:,0].sum()),int(m[:,-1].sum()),int(m[0].sum()),int(m[-1].sum())],
         'margin4_px':int((m&margin).sum()),'margin4_any_alpha':int((anym&margin).sum()),
         'min_margin':min(b[0],b[1],w-b[2],h-b[3]) if b else None,
         'bottom':b[3]-1 if b else None,'bottom_boundary':b[3] if b else None,
         'centre':[(b[0]+b[2])/2,(b[1]+b[3])/2] if b else None,
         'green_px':int(green.sum()),'green_rim_px':int((green&rim).sum()),'green_bbox':bbox(green),
         'magenta_px':int(magenta.sum()),'magenta_rim_px':int((magenta&rim).sum()),
         'white_rim_px':int((white&rim).sum()),'component_sizes':sizes,'tiny_component_pixels':small,
         'rgb_median':np.median(pix,axis=0).tolist() if len(pix) else None,
         'rgba_sha256':hashlib.sha256(a.tobytes()).hexdigest(),'rgb_histogram':hist}
    if ref and hist and ref['rgb_histogram']:out['colour_distance_idle']=round(float(np.abs(np.array(hist)-ref['rgb_histogram']).sum()/2),4)
    return out

def summarize(frames,ref):
    out={}
    for key in ['width','height','area','bottom_boundary']:
        vals=[f[key] for f in frames if f[key] is not None];out[key+'_range']=[min(vals),max(vals)] if vals else []
    for key in ['edge_px','edge_any_alpha','margin4_px','margin4_any_alpha','partial_alpha','green_px','green_rim_px','magenta_px','white_rim_px']:
        out[key]=sum(f[key] for f in frames)
    out['missing']=[i+1 for i,f in enumerate(frames) if not f['alpha_any']]
    out['identical_adjacent']=[[i,i+1] for i in range(1,len(frames)) if frames[i]['rgba_sha256']==frames[i-1]['rgba_sha256']]
    out['identical_loop']=len(frames)>1 and frames[0]['rgba_sha256']==frames[-1]['rgba_sha256']
    out['max_area_step_pct']=round(max([abs(b['area']-a['area'])/max(1,a['area'])*100 for a,b in zip(frames,frames[1:])] or [0]),2)
    out['max_centre_step']=round(max([math.dist(a['centre'],b['centre']) for a,b in zip(frames,frames[1:]) if a['centre'] and b['centre']] or [0]),2)
    out['max_height_step']=max([abs(a['height']-b['height']) for a,b in zip(frames,frames[1:])] or [0])
    out['first_area_vs_idle_pct']=round((frames[0]['area']/max(1,ref['area'])-1)*100,2)
    out['first_height_vs_idle_pct']=round((frames[0]['height']/max(1,ref['height'])-1)*100,2)
    return out

FONT=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
SMALL=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',15)

def contact(key,rows,ref,cell,feet=None, pages=True):
    # One full contact per sheet; pages are exact 2x crops for readable viewing.
    cw,ch=cell;sw,sh=cw*2,ch*2;label=200;header=38;rh=sh+45;width=label+7*(sw+8)+8
    lines=[]
    for row in rows:
        for start in range(0,len(row['images']),6):lines.append((row,start))
    canvas=Image.new('RGB',(width,header+len(lines)*rh),(26,29,36));d=ImageDraw.Draw(canvas)
    d.text((8,8),key+' | 2x nearest | cyan: feet boundary | orange: 4px margin',font=FONT,fill='white')
    for n,(row,start) in enumerate(lines):
        y=header+n*rh;d.text((8,y+8),row['name'],font=FONT,fill='white');d.text((8,y+31),'R'+str(row['start_row']+start//6+1),font=SMALL,fill='#adb9cd')
        imgs=[ref]+row['images'][start:start+6]
        for k,im in enumerate(imgs):
            x=label+k*(sw+8);bg=Image.new('RGB',(sw,sh),(48,52,61));bd=ImageDraw.Draw(bg)
            for yy in range(0,sh,16):
                for xx in range(0,sw,16):
                    if (yy//16+xx//16)%2:bd.rectangle((xx,yy,xx+15,yy+15),fill=(55,59,68))
            # Idle is centred and anchored without rescaling in larger move cells.
            tile=Image.new('RGBA',(cw,ch));ox=(cw-im.width)//2;oy=(feet-120 if im.height==128 and ch==192 else (ch-im.height)//2)
            tile.alpha_composite(im,(ox,oy));tile=tile.resize((sw,sh),Image.Resampling.NEAREST);bg.paste(tile,(0,0),tile)
            canvas.paste(bg,(x,y));d.rectangle((x,y,x+sw-1,y+sh-1),outline='#738098');d.rectangle((x+8,y+8,x+sw-9,y+sh-9),outline='#876038')
            if feet is not None:d.line((x,y+feet*2,x+sw-1,y+feet*2),fill='#389ea6')
            d.text((x+5,y+sh+3),'IDLE F1' if k==0 else 'F'+str(start+k),font=FONT,fill='white')
    p=OUT/'contact'/f'{key}_2x.png';p.parent.mkdir(parents=True,exist_ok=True);canvas.save(p)
    paths=[]
    if pages:
        for start in range(0,len(lines),3):
            page=canvas.crop((0,header+start*rh,width,min(canvas.height,header+(start+3)*rh)))
            pp=OUT/'contact'/f'{key}_p{start//3+1}.png';page.save(pp);paths.append(pp.relative_to(ROOT).as_posix())
    return p.relative_to(ROOT).as_posix(),paths

def scan(path, specs, cell, columns, feet, stem, kind, reference=None, make_contact=True,metadata=None):
    sheet=Image.open(path).convert('RGBA');cw,ch=cell
    ref=reference if reference is not None else sheet.crop((0,0,cw,ch));rm=measure(ref)
    rows=[];used=set();start=0
    for name,count,fps,loop in specs:
        ims=[];ms=[]
        mode='air' if name in AIR else 'mixed' if name in MIXED else 'ground'
        if kind=='monster' and stem in FLY:mode='flying'
        if kind=='projectile' or (metadata and metadata.get('expression')):mode='not_applicable'
        for i in range(count):
            y=start+i//columns;x=i%columns;used.add((y,x));im=sheet.crop((x*cw,y*ch,(x+1)*cw,(y+1)*ch));ims.append(im)
            m=measure(im,rm);m.update(frame=i+1,sheet_row=y+1,sheet_column=x+1)
            m['bottom_delta']=m['bottom']-feet if feet is not None and m['bottom'] is not None else None
            m['boundary_delta']=m['bottom_boundary']-feet if feet is not None and m['bottom_boundary'] is not None else None
            ms.append(m)
        rows.append({'name':name,'start_row':start,'count':count,'fps_table':fps,'loop':loop,'feet_mode':mode,'frames':ms,'summary':summarize(ms,rm),'images':ims})
        start+=math.ceil(count/columns)
    extra=[]
    for y in range(math.ceil(sheet.height/ch)):
        for x in range(math.ceil(sheet.width/cw)):
            if (y,x) not in used:
                m=measure(sheet.crop((x*cw,y*ch,(x+1)*cw,(y+1)*ch)))
                if m['alpha_any']:extra.append({'row':y+1,'col':x+1,'alpha_any':m['alpha_any']})
    data={'path':path.relative_to(ROOT).as_posix(),'stem':stem,'kind':kind,'size':list(sheet.size),'cell':list(cell),'columns':columns,'feet':feet,
          'expected_size':[columns*cw,start*ch],'dimensions_match':sheet.size==(columns*cw,start*ch),'extra_drawn_cells':extra,'reference':rm,'metadata':metadata,
          'head_metadata_present':path.with_name(path.stem+'_heads.json').exists()}
    if make_contact:data['contact'],data['pages']=contact(path.stem,rows,ref,cell,feet)
    for row in rows:del row['images']
    data['rows']=rows
    return data

def live():
    results=[]
    for stem in STEMS:
        char=stem.split('_')[0];code=ROOT/f'smash-nine-prototype/characters/{char}/{char.capitalize()}.gd'
        ref=Image.open(ART/char/f'{stem}_sheet.png').convert('RGBA').crop((0,0,128,128))
        for moves in [False,True]:
            key=('BRAVE_MOVE_SHEET_ROWS' if stem=='luna_brave' else 'MOVE_SHEET_ROWS') if moves else 'SHEET_ROWS'
            p=ART/char/f'{stem}_{"moves_sheet" if moves else "sheet"}.png';c=192 if moves else 128
            d=scan(p,table(code,key),(c,c),6,152 if moves else 120,stem,'fighter_moves' if moves else 'fighter_main',ref)
            dump(OUT/'metrics'/f'{p.stem}.json',d);results.append(d);print(p.name,flush=True)
    code=ROOT/'smash-nine-prototype/scripts/RealmMonster.gd'
    for p in sorted((ART/'monsters').glob('*_sheet.png')):
        w,h=Image.open(p).size;c=w//6;six=h==c*6;stem=p.stem.removesuffix('_sheet')
        feet=80 if stem=='jotunheim_rune_golem' and not six else int(c*.75)
        d=scan(p,table(code,'ART_ROWS_SIX' if six else 'ART_ROWS'),(c,c),6,feet,stem,'monster')
        dump(OUT/'metrics'/f'{p.stem}.json',d);results.append(d);print(p.name,flush=True)
    for p in sorted(list((ART/'monsters').glob('*_projectile.png'))+[ART/'monsters/ember_fireball.png']):
        w,h=Image.open(p).size;n=w//h if w%h==0 else 1;cw=h if n>1 else w
        d=scan(p,[['projectile',n,12,True]],(cw,h),n,None,p.stem,'projectile')
        dump(OUT/'metrics'/f'{p.stem}.json',d);results.append(d);print(p.name,flush=True)
    dump(OUT/'metrics/live_index.json',[{'path':d['path'],'kind':d['kind'],'rows':len(d['rows']),'frames':sum(r['count'] for r in d['rows']),'contact':d['contact'],'pages':d['pages']} for d in results])

def candidates():
    results=[]
    for folder in ['frey','luna','nova','rio','yuki','monsters']:
        for p in sorted((ROOT/'art/bakeoff'/folder).glob('*.png')):
            side=p.with_suffix('.json');meta=json.loads(side.read_text(encoding='utf-8-sig')) if side.exists() else {}
            im=Image.open(p);w,h=im.size;full_sheet=bool(re.search(r'_sheet-v\d+$',p.stem))
            cell=meta.get('cell',w//6 if full_sheet else h);cell=[cell,cell] if isinstance(cell,int) else cell;n=int(meta.get('frames',max(1,w//cell[0])))
            stem=next((x for x in sorted(STEMS,key=len,reverse=True) if p.stem.startswith(x)),p.stem.split('-')[0]);row=p.stem[len(stem):].strip('-_');row=re.sub(r'-v\d+$','',row)
            if full_sheet:stem=re.sub(r'_sheet-v\d+$','',p.stem)
            kind='portrait' if meta.get('expression') else 'projectile' if 'projectile' in row or p.stem.startswith('slam_shockwave') else 'monster' if folder=='monsters' else 'fighter_candidate'
            feet=meta.get('feet',meta.get('floor',72 if kind=='monster' else 120 if cell[1]==128 else 152 if cell[1]==192 else None))
            refpath=ART/(folder if folder!='monsters' else 'monsters')/f'{stem}_sheet.png';ref=None
            if kind=='portrait':
                cell=[w,h];n=1;feet=None
                refpath=ROOT/meta.get('edited_from','')
            if refpath.is_file():
                rr=Image.open(refpath).convert('RGBA');c=rr.width//6 if kind!='portrait' else rr.width;ref=rr.crop((0,0,c,c if kind!='portrait' else rr.height))
            columns=max(1,w//cell[0])
            specs=table(ROOT/'smash-nine-prototype/scripts/RealmMonster.gd','ART_ROWS_SIX' if h==6*cell[1] else 'ART_ROWS') if full_sheet else [[row,n,meta.get('fps'),meta.get('loop',False)]]
            d=scan(p,specs,cell,columns,feet,stem,kind,ref,False,meta)
            d['candidate_status']='adopted_archive' if meta.get('adopted') else 'awaiting_selection';d['has_sidecar']=side.exists()
            flags=[]
            if not d['dimensions_match']:flags.append('dimensions')
            if d['extra_drawn_cells']:flags.append('extra_drawn_cells')
            for rr in d['rows']:
                sm=rr['summary']
                if kind!='portrait':
                    for k in ['edge_px','margin4_px','missing','identical_adjacent']:
                        if sm[k]:flags.append(k)
                    if sm['max_area_step_pct']>30:flags.append('area_step')
                    if sm['max_centre_step']>cell[0]*.2:flags.append('centre_step')
                    if sm['green_rim_px']>10:flags.append('green_rim')
                    if sm['partial_alpha']>0:flags.append('partial_alpha')
            d['flags']=sorted(set(flags))
            d['storage']='six_column_atlas' if full_sheet else 'portrait' if kind=='portrait' else 'padded_strip' if columns>n else 'strip'
            dump(OUT/'metrics/candidates'/f'{p.stem}.json',d);results.append({'path':d['path'],'status':d['candidate_status'],'kind':kind,'flags':d['flags'],'frames':sum(rr['count'] for rr in d['rows']),'storage':d['storage']})
        print(folder,'done',len(results),flush=True)
    dump(OUT/'metrics/candidate_index.json',results)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('scope',choices=['live','candidates']);args=parser.parse_args()
    (live if args.scope=='live' else candidates)()
