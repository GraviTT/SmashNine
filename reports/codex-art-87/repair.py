"""ART-87: deterministic, source-first legacy sheet repair. No Godot needed."""
import os
os.environ['PYTHONDONTWRITEBYTECODE'] = '1'
from pathlib import Path
from collections import deque
import json, hashlib, shutil, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
GAME = ROOT / 'smash-nine-prototype/assets/art/monsters'
RAW = ROOT / 'art/raw/monsters-87'
OUT = ROOT / 'art/bakeoff/monsters/legacy'
REPORT = ROOT / 'reports/codex-art-87'
for d in (RAW, OUT, REPORT): d.mkdir(parents=True, exist_ok=True)
COUNTS = [4,6,4,1]
ROWS = ['idle','walk','attack','hurt']

def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def load(p): return Image.open(p).convert('RGBA')
def copy_input(name):
    dst = RAW / name
    if not dst.exists(): shutil.copy2(GAME / name, dst)
    return dst

def clear_background(im, threshold=19.125):
    """Flood along locally smooth RGB edges, from image border. Source art is opaque."""
    a=np.array(im)
    if (a[:,:,3]<128).sum()>a.shape[0]*a.shape[1]*.05:
        a[a[:,:,3]<41]=0
        return Image.fromarray(a)
    rgb=a[:,:,:3].astype(np.int32); h,w=a.shape[:2]
    right=np.sum(np.diff(rgb,axis=1)**2,axis=2)<=threshold**2
    down=np.sum(np.diff(rgb,axis=0)**2,axis=2)<=threshold**2
    seen=np.zeros((h,w),bool); q=deque()
    for x in range(w):
        q.append((0,x)); q.append((h-1,x)); seen[0,x]=seen[h-1,x]=True
    for y in range(1,h-1):
        q.append((y,0)); q.append((y,w-1)); seen[y,0]=seen[y,w-1]=True
    while q:
        y,x=q.popleft()
        for yy,xx,ok in ((y,x-1,x>0 and right[y,x-1]),(y,x+1,x<w-1 and right[y,x]),(y-1,x,y>0 and down[y-1,x]),(y+1,x,y<h-1 and down[y,x])):
            if ok and not seen[yy,xx]: seen[yy,xx]=True; q.append((yy,xx))
    a[seen]=0
    return Image.fromarray(a)

def source(id):
    path=copy_input(id+'_source.png'); cache=RAW/(id+'_transparent.png')
    if not cache.exists() or np.any((np.array(load(cache))[:,:,3]>0)&(np.array(load(cache))[:,:,3]<41)):
        clear_background(load(path)).save(cache)
    return load(cache)

def bbox(im, threshold=1):
    a=np.array(im)[:,:,3]>=threshold
    y,x=np.where(a)
    return [int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1)] if len(x) else None

def components(im, threshold=1):
    a=np.array(im); mask=a[:,:,3]>=threshold; h,w=mask.shape; seen=np.zeros_like(mask); comps=[]
    for y,x in zip(*np.where(mask)):
        if seen[y,x]: continue
        q=[(int(y),int(x))]; seen[y,x]=True; pts=[]
        while q:
            yy,xx=q.pop(); pts.append((yy,xx))
            for ny in range(max(0,yy-1),min(h,yy+2)):
                for nx in range(max(0,xx-1),min(w,xx+2)):
                    if mask[ny,nx] and not seen[ny,nx]: seen[ny,nx]=True; q.append((ny,nx))
        comps.append(pts)
    return sorted(comps,key=len,reverse=True)

def clean_specks(im, minimum=9):
    a=np.array(im)
    for comp in components(im):
        if len(comp)<minimum:
            y,x=zip(*comp); a[y,x]=0
    return Image.fromarray(a)

def checkboard(size,step=12):
    im=Image.new('RGB',size,(42,46,56)); d=ImageDraw.Draw(im)
    for y in range(0,size[1],step):
        for x in range(0,size[0],step):
            if (x//step+y//step)%2: d.rectangle((x,y,x+step-1,y+step-1),fill=(57,62,73))
    return im

def paste_alpha(bg,im,xy): bg.paste(im,xy,im)

def source_board(id):
    im=source(id); bg=checkboard(im.size); paste_alpha(bg,im,(0,0)); bg.save(RAW/(id+'_source_check.png'))
    return [{'pixels':len(c),'box':[min(x for y,x in c),min(y for y,x in c),max(x for y,x in c)+1,max(y for y,x in c)+1]} for c in components(im) if len(c)>100]

SPECS={
 'jotunheim_rune_golem': {'qa':['L01','L07','L08'],'scale':.32,'feet':80,'rects':{
  'idle':[[16,105,257,278],[269,101,501,278],[518,109,751,278],[774,101,1018,278]],
  'walk':[[16,337,266,506],[273,328,522,506],[529,331,766,506],[766,338,1026,506],[1030,338,1278,506],[1283,326,1523,506]],
  'attack':[[16,590,264,763],[277,525,509,763],[506,600,779,763],[790,590,1042,763]],
  'hurt':[[16,840,252,990]]}},
 'muspelheim_magma_boar': {'qa':['L02','L17'],'scale':.32,'feet':72,'rects':{
  'idle':[[30,130,265,285],[284,126,515,285],[536,128,774,285],[787,130,1015,285]],
  'attack':[None,[282,572,547,717],[540,575,815,724],None]},'overrides':{'attack:2':{'largest_only':True},'attack:3':{'scale':.315,'largest_only':True}}},
 'alfheim_moon_stag': {'qa':['L12','L27'],'scale':.25,'feet':72,'rects':{
  'attack':[[20,574,311,756],[315,570,623,756],[634,574,1000,756],[20,574,311,756]],
  'hurt':[[22,781,274,989]]},'overrides':{'hurt:1':{'scale':.294}},
  'notes':'공격 원본은 3자세뿐. F4는 F1을 회수 자세로 재사용. 공격행 공통 0.25배로 넓은 돌진까지 보존하며 대기 대비 머리가 약 15% 작아지는 한계.'},
 'yggdrasil_root_guardian': {'qa':['L13'],'scale':.303,'feet':72,'rects':{
  'attack':[[17,548,274,766],[296,548,537,766],[550,548,840,766],[843,555,1060,766]]}},
 'niflheim_glacier_wolf': {'qa':['L03','L18'],'scale':.32,'feet':72,'rects':{
  'idle':[[10,118,260,282],[275,119,511,282],[520,114,763,282],[773,123,1022,282]],
  'attack':[None,[276,578,558,742],None,None]},'overrides':{'attack:2':{'scale':.315,'largest_only':True}}},
 'asgard_runic_raven': {'qa':['L15'],'scale':.32,'feet':72,'rects':{
  'attack':[None,None,[520,580,715,750],None]},'notes':'원본 F3 전체 부리까지 복구하고, 부리 앞 독립 깃털 발사체(x>=715)는 몸에 넣지 않음.'},
 'midgard_rooftop_slinger': {'qa':['L16'],'scale':.32,'feet':72,'rects':{
  'attack':[None,None,[518,552,791,754],None]}},
 'svartalfheim_cog_drone': {'qa':['L19'],'scale':.32,'feet':72,'rects':{
  'attack':[None,[283,547,531,754],None,None]}},
 'svartalfheim_gear_beetle': {'qa':['L20'],'scale':.32,'feet':72,'rects':{
  'attack':[None,[280,577,521,771],[524,577,797,772],None]},'notes':'원본에서 드릴 전체 복구. 전방 파편은 후속 마스크로 분리.'}
}

# Pixel masks were traced from the displayed legacy cells, not inferred from colors.
# Coordinates are local 96px cell coordinates; polygon endpoints are inclusive.
FX_MASKS={
 'jotunheim_storm_wisp': {'attack:4': [[(50,10),(79,10),(89,28),(95,28),(95,67),(77,67),(67,76),(50,76),(50,55),(38,48),(50,38)]]},
 'alfheim_moon_moth': {'attack:2': [[(68,46),(90,46),(90,74),(68,74)]]},
 'asgard_aegis_ram': {'attack:3': [[(53,20),(80,20),(80,33),(68,33),(60,29),(53,29)],[(19,68),(54,68),(54,75),(19,75)],[(0,39),(18,39),(18,45),(0,45)],[(0,48),(12,48),(12,56),(0,56)]]},
 'ember_imp': {'attack:2': [[(69,28),(89,28),(89,62),(69,62)]], 'attack:4': [[(74,32),(89,32),(89,64),(74,64)],[(68,34),(73,34),(73,44),(68,44)]]},
 'svartalfheim_cog_drone': {'attack:4': [[(81,34),(92,34),(92,55),(81,55)],[(75,28),(80,28),(80,34),(75,34)]]},
 'yggdrasil_root_oracle': {'attack:2': [[(69,31),(91,31),(91,72),(69,72)],[(70,23),(89,23),(89,31),(70,31)]]},
 'mossling': {'hurt:1': [[(63,0),(95,0),(95,27),(73,27),(73,24),(63,24)],[(71,24),(95,24),(95,30),(71,30)],[(75,24),(95,24),(95,33),(75,33)]]},
 'muspelheim_magma_boar': {'hurt:1': [[(68,25),(76,25),(76,34),(68,34)],[(77,23),(89,23),(89,36),(77,36)]]},
 'svartalfheim_gear_beetle': {'attack:2': [[(75,40),(88,40),(88,54),(75,54)]], 'attack:3': [[(71,28),(95,28),(95,52),(85,52),(85,47),(71,47)],[(75,61),(95,61),(95,78),(75,78)]]},
}
for id,qa in [('ember_imp',['L04','L06','L23']),('mossling',['L05','L29']),('alfheim_moon_moth',['L21']),('asgard_aegis_ram',['L22']),('yggdrasil_root_oracle',['L26']),('jotunheim_storm_wisp',['L24'])]:
    SPECS[id]={'qa':qa,'rects':{},'scale':1,'feet':72}
SPECS['muspelheim_magma_boar']['qa'].append('L30')
SPECS['svartalfheim_cog_drone']['qa'].append('L25')

REDRAWS={
 'jotunheim_storm_wisp': {'frame':(2,3),'file':'wisp_attack4_redraw.png','size':(67,61),'at':(9,11)},
 'ember_imp': {'frame':(2,1),'file':'ember_imp_attack2_redraw.png','size':(65,58),'at':(12,15)},
 'svartalfheim_cog_drone': {'frame':(2,3),'file':'svartalfheim_cog_drone_attack4_redraw.png','size':(77,64),'at':(8,8)},
 'yggdrasil_root_oracle': {'frame':(2,1),'file':'yggdrasil_root_oracle_attack2_redraw.png','size':(61,64),'at':(10,8)}
}

def remove_fx(im,polygons):
    mask=Image.new('L',im.size);d=ImageDraw.Draw(mask)
    for points in polygons:d.polygon(points,fill=255)
    select=np.array(mask)>0;a=np.array(im);removed=np.zeros_like(a);removed[select]=a[select];a[select]=0
    return Image.fromarray(a),Image.fromarray(removed)

def cell(sheet,row,col): return sheet.crop((col*96,row*96,col*96+96,row*96+96))

def extract(id,rect,scale,feet,largest_only=False):
    im=clean_specks(source(id).crop(rect),20)
    if largest_only:
        a=np.array(im); keep=np.zeros(a.shape[:2],bool)
        for y,x in components(im)[0]:keep[y,x]=True
        a[~keep]=0;im=Image.fromarray(a)
    b=bbox(im); im=im.crop(b)
    size=(round(im.width*scale),round(im.height*scale))
    assert size[0]<=88 and size[1]<=feet-4,(id,rect,size)
    im=im.resize(size,Image.Resampling.LANCZOS)
    rgb=im.convert('RGB').filter(ImageFilter.UnsharpMask(radius=1,percent=60,threshold=3))
    rgb.putalpha(im.getchannel('A')); im=rgb
    a=np.array(im); a[a[:,:,3]<32]=0; im=Image.fromarray(a)
    # Keep original source shading. No palette quantization or painted additions.
    b2=bbox(im); im=im.crop(b2)
    at=((96-im.width)//2,feet-im.height)
    out=Image.new('RGBA',(96,96)); out.paste(im,at)
    return out,{'source':f'art/raw/monsters-87/{id}_source.png','source_region':rect,'alpha_bbox_in_region':b,'scale':scale,'placement':list(at),'method':'re-slice','feet_boundary':feet,'largest_component_only':largest_only,'resampling':'LANCZOS + RGB unsharp(radius=1, percent=60, threshold=3); alpha<32 cleared'}

def metrics(im):
    a=np.array(im); m=a[:,:,3]>=128; b=bbox(im,128)
    return {'bbox_alpha128':b,'bbox_alpha1':bbox(im),'area_alpha128':int(m.sum()),'edge_1px':int(m[0].sum()+m[-1].sum()+m[1:-1,0].sum()+m[1:-1,-1].sum()),'margin_4px':int(m.sum()-m[4:-4,4:-4].sum()),'rgba_sha256':hashlib.sha256(a.tobytes()).hexdigest()}

def make_board(id,old,new,changed):
    n=len(changed); h=450+n*430
    board=Image.new('RGB',(1200,h),(23,28,38)); d=ImageDraw.Draw(board)
    d.text((12,8),id+' | ART-87 | BEFORE / AFTER | 1x sheets, 4x changed frames',fill='white')
    for x,im,label in [(12,old,'GAME 1x'),(612,new,'CANDIDATE 1x (yellow = changed)')]:
        bg=checkboard(im.size); paste_alpha(bg,im,(0,0)); board.paste(bg,(x,40)); d.text((x,26),label,fill='white')
        for r,c in changed: d.rectangle((x+c*96,40+r*96,x+c*96+95,40+r*96+95),outline='#ffd15b',width=1)
    for i,(r,c) in enumerate(changed):
        x=12; y=450+i*430
        d.text((x,y),f'{ROWS[r]} F{c+1}: left thumbnails BEFORE / AFTER 1x | BEFORE 4x | AFTER 4x',fill='#ffd15b')
        for im,xx,yy,s in [(cell(old,r,c),x,y+28,1),(cell(new,r,c),x,y+140,1),(cell(old,r,c),x+114,y+28,4),(cell(new,r,c),x+530,y+28,4)]:
            bg=checkboard((96*s,96*s)); paste_alpha(bg,im.resize(bg.size,Image.Resampling.NEAREST),(0,0)); board.paste(bg,(xx,yy))
    board.save(REPORT/(id+'.png'))
    # Paging keeps tool inspection at actual 1x/4x; these pages stay raw-only.
    for i in range(0,n,2):
        page=board.crop((0,450+i*430,1200,min(h,450+(i+2)*430)))
        page.save(RAW/f'{id}_review_{i//2+1:02}.png')

def build(id):
    spec=SPECS[id]; original=load(copy_input(id+'_sheet.png')); out=original.copy(); recmap={}; records=[]; changed=[]; fx=Image.new('RGBA',out.size)
    if id in ['ember_imp','mossling']:
        base_path=RAW/(id+'_before_art17.png')
        if not base_path.exists(): shutil.copy2(ROOT/f'reports/codex-art-17/before/{id}_sheet.png',base_path)
        base=load(base_path);a=np.array(base);o=np.array(original)
        assert np.all(a[a[:,:,3]>30]==o[a[:,:,3]>30]),'Pre-rim solid pixels do not match game'
        for r,n in enumerate(COUNTS):
            for c in range(n):
                out.paste(cell(base,r,c),(c*96,r*96))
                recmap[(r,c)]={'method':'remove ART-17 added rim; restore preserved pixels','source':f'art/raw/monsters-87/{id}_before_art17.png','source_region':[c*96,r*96,c*96+96,r*96+96],'solid_body_preserved_exact':True,'feet_boundary':73}
    for row,rects in spec['rects'].items():
        for i,rect in enumerate(rects):
            if rect is None: continue
            r=ROWS.index(row); override=spec.get('overrides',{}).get(f'{row}:{i+1}',{})
            im,rec=extract(id,rect,override.get('scale',spec['scale']),spec['feet'],override.get('largest_only',False))
            if id=='muspelheim_magma_boar' and row=='attack' and i==2:
                shifted=Image.new('RGBA',(96,96));shifted.paste(im,(0,1));im=shifted
                rec['placement'][1]+=1
                rec['body_feet_roi']=[0,0,60,96]
                rec['alignment_note']='부분 알파 포함 발굽은 y=72 경계, 엄니 궤적은 y=73 경계. 몸 발굽 기준 1px 하향.'
            out.paste(im,(i*96,r*96)); recmap[(r,i)]=rec
    for key,polys in FX_MASKS.get(id,{}).items():
        row,num=key.split(':');r=ROWS.index(row);c=int(num)-1;im=cell(out,r,c)
        cleaned,removed=remove_fx(im,polys);out.paste(cleaned,(c*96,r*96));fx.paste(removed,(c*96,r*96))
        rec=recmap.setdefault((r,c),{'method':'pixel cleanup only','source':f'art/raw/monsters-87/{id}_sheet.png','source_region':[c*96,r*96,c*96+96,r*96+96]})
        rec['removed_fx_polygons_local']=polys;rec['removed_fx_pixels']=int((np.array(removed)[:,:,3]>0).sum())
    if id in REDRAWS:
        redraw=REDRAWS[id];r,c=redraw['frame'];p=RAW/redraw['file'];im=load(p)
        a=np.array(im);a[a[:,:,3]<41]=0;im=clean_specks(Image.fromarray(a),100);b=bbox(im);im=im.crop(b)
        im=im.resize(redraw['size'],Image.Resampling.LANCZOS)
        rgb=im.convert('RGB').filter(ImageFilter.UnsharpMask(radius=1,percent=60,threshold=3));rgb.putalpha(im.getchannel('A'));im=rgb
        a=np.array(im);a[a[:,:,3]<32]=0;im=Image.fromarray(a)
        fr=Image.new('RGBA',(96,96));fr.paste(im,redraw['at']);out.paste(fr,(c*96,r*96))
        prior=recmap.get((r,c),{})
        recmap[(r,c)]={'method':'built-in imagegen redraw: shot occluded source body','source':'art/raw/monsters-87/'+redraw['file'],'source_region':b,'target_size':list(redraw['size']),'placement':list(redraw['at']),'feet_boundary':73 if id=='ember_imp' else 72,'prior_cleanup':prior,'reference':['wisp_attack4_edit_target.png','wisp_reference.png'] if id=='jotunheim_storm_wisp' else [id+'_edit_target.png',id+'_edit_reference.png']}
        recmap[(r,c)]['original_source_compared']='art/raw/monsters-87/'+(id+'_before_art17.png' if id=='ember_imp' else id+'_source.png')
        recmap[(r,c)]['redraw_reason']='원본에도 발사 효과가 손·포구·얼굴·돌 윤곽을 가림. 재슬라이스만으로 가려진 몸 픽셀을 복구할 수 없음.'
    if id=='asgard_runic_raven':
        # Diagnostic preservation of the shot visible in the game cell, not a new runtime VFX.
        shot=Image.new('RGBA',(96,96));shot.paste(cell(original,2,2).crop((74,25,96,54)),(74,25));fx.paste(shot,(192,192))
    for (r,c),rec in sorted(recmap.items()):
        if cell(original,r,c).tobytes()==cell(out,r,c).tobytes():continue
        changed.append((r,c));records.append({'row':ROWS[r],'frame':c+1,**rec,'before':metrics(cell(original,r,c)),'after':metrics(cell(out,r,c))})
    if bbox(fx):
        (REPORT/'effects').mkdir(exist_ok=True);fx.save(REPORT/'effects'/(id+'_removed-fx.png'))
    outfile=OUT/(id+'_sheet-fix1.png'); out.save(outfile)
    unchanged=[]
    for r in range(4):
        for c in range(6):
            if (r,c) not in changed:
                assert cell(original,r,c).tobytes()==cell(out,r,c).tobytes()
                unchanged.append([r,c])
    methods=[]
    if spec['rects']:methods.append('원본의 완전한 몸 영역을 다시 잘라 배치')
    if id in ['ember_imp','mossling']:methods.append('ART-17 이전 보존본과 대조해 추가 림 제거')
    if id in FX_MASKS:methods.append('몸과 분리된 발사체·잔상·피격 표시 픽셀 제거')
    if id in REDRAWS:methods.append('발사체가 몸을 가린 1프레임은 이웃 프레임 참조로 재작화')
    data={'id':id,'status':'fallback_candidate','qa_ids':spec['qa'],'note':', '.join(spec['qa'])+': '+'; '.join(methods)+'. '+spec.get('notes',''), 'replaces':f'smash-nine-prototype/assets/art/monsters/{id}_sheet.png','size':[576,384],'cell':[96,96],'frame_counts':COUNTS,'original_file_sha256':sha(GAME/(id+'_sheet.png')),'candidate_file_sha256':sha(outfile),'unchanged_cells_rgba_identical':unchanged,'frames':records}
    outfile.with_suffix('.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    make_board(id,original,out,changed)
    print(id,len(changed),'changed',len(unchanged),'identical cells',flush=True)

if __name__=='__main__' and len(sys.argv)>1 and sys.argv[1]=='build':
    for id in (sys.argv[2:] or list(SPECS)): build(id)

if __name__=='__main__' and len(sys.argv)>1 and sys.argv[1]=='sources':
    for id in sys.argv[2:]:
        print(id, json.dumps(source_board(id)), flush=True)
