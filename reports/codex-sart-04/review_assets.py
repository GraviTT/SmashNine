"""Measure actual output PNGs and render labeled review evidence only."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from collections import Counter
import hashlib, json, statistics

ROOT=Path(__file__).resolve().parents[2]
DIR=ROOT/'reports/codex-sart-04'
ART=ROOT/'art/bakeoff/story'
BG=(7,7,21)
PANEL=(22,34,54)
FG=(225,231,243)
DIM=(151,167,192)
GOLD=(243,205,124)
FONT_PATH='C:/Windows/Fonts/malgun.ttf'

def font(size): return ImageFont.truetype(FONT_PATH,size)
def drawtext(im,xy,t,size=20,fill=FG): ImageDraw.Draw(im).text(xy,t,font=font(size),fill=fill)
def frame(im,i,size): return im.crop((i*size,0,(i+1)*size,size))
def asset(name,v): return Image.open(ART/f'{name}-v{v}.png').convert('RGBA')
def put(im,src,xy,scale=1):
    if scale != 1: src=src.resize((src.width*scale,src.height*scale),Image.Resampling.NEAREST)
    im.paste(src,xy,src)
def box(im,rect,fill=PANEL,stroke=None): ImageDraw.Draw(im).rectangle(rect,fill=fill,outline=stroke)
def proof_background(im,rect,kind='dark'):
    box(im,rect,fill=BG if kind=='dark' else (224,228,236))

def metrics():
    result=[]
    allowed={(16,24,39),(243,205,124),(168,116,44),(61,123,217),(159,210,255),
             (59,29,94),(107,47,168),(185,138,240),(255,79,216),(255,214,245)}
    for name,sz,fc,cell in [('map_path_tile',(32,12),1,(32,12)),
                            ('map_marker_next',(288,48),6,(48,48)),
                            ('map_seal_clear',(40,40),1,(40,40)),
                            ('map_seal_locked',(40,40),1,(40,40)),
                            ('shadow_dissolve',(1152,192),6,(192,192))]:
        for v in ([1,2,3] if name in ['map_seal_clear','map_seal_locked'] else [1,2]):
            im=asset(name,v); px=list(im.get_flattened_data())
            alpha=sorted(set(p[3] for p in px)); colors=set(p[:3] for p in px if p[3])
            row={'file':f'{name}-v{v}.png','size':list(im.size),'mode':im.mode,
                 'alpha_values':alpha,'opaque_palette':[list(c) for c in sorted(colors)],
                 'colors':len(colors),'hidden_rgb_nonzero':sum(p[3]==0 and any(p[:3]) for p in px),
                 'checks':{'size':im.size==sz,'rgba':im.mode=='RGBA',
                           'binary_alpha':alpha==[0,255],'palette':colors<=allowed},
                 'frames':[],'sha256':hashlib.sha256((ART/f'{name}-v{v}.png').read_bytes()).hexdigest()}
            for i in range(fc):
                fr=im.crop((i*cell[0],0,(i+1)*cell[0],cell[1]))
                a=fr.getchannel('A'); bb=a.getbbox()
                coords=[(x,y) for y in range(fr.height) for x in range(fr.width) if a.getpixel((x,y))]
                corners=[a.getpixel(p) for p in [(0,0),(fr.width-1,0),(0,fr.height-1),(fr.width-1,fr.height-1)]]
                margins=[bb[0],bb[1],fr.width-bb[2],fr.height-bb[3]]
                item={'frame':i+1,'bbox':list(bb),'margins_ltrb':margins,'occupied_px':len(coords),
                      'coverage_pct':round(len(coords)*100/(fr.width*fr.height),4),
                      'centroid':[round(statistics.mean(x for x,y in coords),3),round(statistics.mean(y for x,y in coords),3)],
                      'corners_alpha':corners}
                row['frames'].append(item)
            row['checks']['transparent_corners']=all(f['corners_alpha']==[0,0,0,0] for f in row['frames'])
            if name=='map_path_tile':
                mismatches=sum(im.getpixel((0,y))!=im.getpixel((31,y)) for y in range(12))
                row['seam_mismatched_pixels']=mismatches
                row['checks']['seam_exact']=mismatches==0
            if name=='map_marker_next':
                frs=[list(frame(im,i,48).get_flattened_data()) for i in range(6)]
                changes=[]; mads=[]
                for i in range(6):
                    a,b=frs[i],frs[(i+1)%6]
                    changes.append(sum(x!=y for x,y in zip(a,b)))
                    mads.append(round(sum(abs(x[k]-y[k]) for x,y in zip(a,b) for k in range(4))/(48*48*4),5))
                row['transition_changed_pixels_12_23_34_45_56_61']=changes
                row['transition_rgba_mad']=mads
                row['loop_seam_vs_internal_median']=round(mads[-1]/statistics.median(mads[:-1]),4)
                row['checks']['six_unique_frames']=len({bytes(sum((list(p) for p in f),[])) for f in frs})==6
                row['checks']['loop_seam_not_outlier']=mads[-1]<=max(mads[:-1])*1.25
                row['checks']['visible_margin']=min(min(f['margins_ltrb']) for f in row['frames'])>=4
            if name=='shadow_dissolve':
                row['checks']['margin_at_least_4']=min(min(f['margins_ltrb']) for f in row['frames'])>=4
                row['checks']['last_frame_under_1pct']=row['frames'][-1]['coverage_pct']<1
                row['checks']['mass_decreases']=all(a['occupied_px']>b['occupied_px'] for a,b in zip(row['frames'],row['frames'][1:]))
                row['last_to_first_occupied_ratio']=round(row['frames'][-1]['occupied_px']/row['frames'][0]['occupied_px'],4)
            row['automatic_pass']=all(row['checks'].values())
            result.append(row)
    (DIR/'measurements.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for r in result:
        print(r['file'],'PASS' if r['automatic_pass'] else 'FAIL',r['checks'])
        if 'loop_seam_vs_internal_median' in r: print('  loop ratio',r['loop_seam_vs_internal_median'],r['transition_changed_pixels_12_23_34_45_56_61'])
        if r['file'].startswith('shadow'): print('  occupancy',[f['occupied_px'] for f in r['frames']], 'margins',[f['margins_ltrb'] for f in r['frames']], 'centroidY',[f['centroid'][1] for f in r['frames']])
    return result

def icon_board():
    im=Image.new('RGB',(1320,784),BG)
    drawtext(im,(24,16),'SART-04 · 지도 아이콘 1× / 4×',27,GOLD)
    rows=[('map_path_tile','세계수 뿌리 길'),('map_seal_clear','완료 봉인'),('map_seal_locked','잠금 봉인')]
    for ri,(name,title) in enumerate(rows):
        y=80+ri*228
        drawtext(im,(24,y),title,22)
        for v in [1,2]:
            x=250+(v-1)*520
            drawtext(im,(x,y),f'v{v}',20,DIM)
            src=asset(name,v)
            put(im,src,(x,y+52),1)
            put(im,src,(x+72,y+42),4)
            box(im,(x+280,y+32,x+480,y+212),fill=(224,228,236))
            put(im,src,(x+300,y+42),4)
            if name=='map_path_tile':
                repeat=Image.new('RGBA',(32*6,12))
                for i in range(6):repeat.alpha_composite(src,(i*32,0))
                put(im,repeat,(x,y+128),2)
                drawtext(im,(x,y+164),'32px 타일 × 6, 이음매 반복',15,DIM)
    im.save(DIR/'icons-4x.png')
    return im

def revision_board():
    im=Image.new('RGB',(1320,464),BG)
    drawtext(im,(24,16),'육안 검토 뒤 추가한 v3 · v1/v2 원본 보존',27,GOLD)
    for j,name in enumerate(['map_seal_clear','map_seal_locked']):
        x=24+j*650
        drawtext(im,(x,80),'완료: 네 방향 씨앗별 룬' if j==0 else '잠금: 분리된 두 사슬 고리',22)
        a=asset(name,3)
        put(im,a,(x,144),1);put(im,a,(x+80,134),4)
        box(im,(x+300,124,x+500,324),fill=(224,228,236))
        put(im,a,(x+320,144),4)
        drawtext(im,(x,354),'v2는 문자처럼 보일 여지 → 비문자 룬' if j==0 else 'v2는 테두리처럼 보일 여지 → 두 구멍과 교차',18,DIM)
    im.save(DIR/'seals-v3-4x.png')
    return im

def marker_board():
    im=Image.new('RGB',(1320,672),BG)
    drawtext(im,(24,14),'SART-04 · 다음 스테이지 표식 · 각 6프레임',27,GOLD)
    for v in [1,2]:
        y=65+(v-1)*302
        drawtext(im,(24,y),f'v{v} · 1×',20)
        src=asset('map_marker_next',v)
        put(im,src,(150,y),1)
        for i in range(6):
            x=24+i*214
            drawtext(im,(x,y+56),str(i+1),16,DIM)
            put(im,frame(src,i,48),(x,y+84),4)
    im.save(DIR/'marker-4x.png')
    return im

def map_mock(v):
    im=Image.new('RGB',(706,236),BG)
    drawtext(im,(24,12),f'지도 배치 모형 · v{v} 세트 · 셀 196×152',20,GOLD)
    tile=asset('map_path_tile',v)
    # Exact authored tile height 12; the existing Line2D width 5 is documented separately.
    for x in range(122,584,32):put(im,tile,(x,123))
    emblems=['asgard','yggdrasil_heart','niflheim']
    labels=['CLEAR','NEXT','LOCKED']
    for j in range(3):
        x=24+j*226; y=58
        box(im,(x,y,x+195,y+151),PANEL,(73,83,110))
        e=Image.open(ROOT/f'smash-nine-prototype/assets/art/ui/realm_emblems/{emblems[j]}.png').convert('RGBA')
        e=e.resize((96,96),Image.Resampling.NEAREST)
        if j==2:
            e.putalpha(e.getchannel('A').point(lambda p:round(p*.3)))
        put(im,e,(x+50,y+4))
        seal=asset(['map_seal_clear','map_marker_next','map_seal_locked'][j],v)
        if j==1:seal=frame(seal,0,48)
        put(im,seal,(x+150-(4 if j==1 else 0),y+101))
        drawtext(im,(x+16,y+117),labels[j],15,DIM)
    im.save(DIR/f'mock-map-v{v}.png')
    return im

def shadow_boards():
    panels=[]
    for v in [1,2]:
        src=asset('shadow_dissolve',v)
        panel=Image.new('RGB',(2360,1920),BG)
        drawtext(panel,(24,16),f'SART-04 · 그림자 소멸 v{v} · 1× / 4× · 12 fps 단발',30,GOLD)
        for i in range(6):
            fr=frame(src,i,192); x=24+i*388
            drawtext(panel,(x,70),f'F{i+1} · 몸 상자 42×96',16,DIM)
            put(panel,fr,(x,102))
            body=Image.new('RGBA',(42,96),(130,138,152,168))
            put(panel,body,(x+75,102+56))
            ImageDraw.Draw(panel).rectangle((x+75,158,x+116,253),outline=(180,186,199))
            ImageDraw.Draw(panel).line((x+91,254,x+101,254),fill=(255,79,216))
            # A separate image for exact 4x inspection of every frame.
            one=Image.new('RGB',(816,832),BG)
            drawtext(one,(24,10),f'v{v} / F{i+1} / 4×',22,GOLD)
            put(one,fr,(24,56),4)
            one.save(DIR/f'shadow-v{v}-f{i+1}-4x.png')
            sx=24+(i%3)*780; sy=328+(i//3)*776
            drawtext(panel,(sx,sy),f'F{i+1} · 4×',18,DIM)
            put(panel,fr,(sx,sy+28),4)
        panel.save(DIR/f'shadow-v{v}-4x.png')
        panels.append(panel)
    return panels

def gif_palette():
    # A fixed palette prevents GIF color flicker. Every review background is opaque.
    colors=[BG,PANEL,FG,DIM,GOLD,(130,138,152),(180,186,199)]
    for c in ['101827','f3cd7c','a8742c','3d7bd9','9fd2ff','3b1d5e','6b2fa8','b98af0','ff4fd8','ffd6f5']:
        q=tuple(bytes.fromhex(c))
        if q not in colors:colors.append(q)
    pal=Image.new('P',(1,1)); flat=[n for c in colors for n in c]; flat.extend([0]*(768-len(flat)));pal.putpalette(flat)
    return pal

def gifs():
    pal=gif_palette()
    ms=[]; ss=[]
    for i in range(6):
        m=Image.new('RGB',(520,272),BG)
        s=Image.new('RGB',(832,476),BG)
        for v in [1,2]:
            drawtext(m,(20+(v-1)*260,10),f'v{v} · 8 fps',20,GOLD)
            put(m,frame(asset('map_marker_next',v),i,48),(34+(v-1)*260,58),4)
            drawtext(s,(20+(v-1)*416,10),f'v{v} · F{i+1} · 12 fps',20,GOLD)
            put(s,frame(asset('shadow_dissolve',v),i,192),(16+(v-1)*416,64),2)
        ms.append(m.quantize(palette=pal,dither=Image.Dither.NONE))
        ss.append(s.quantize(palette=pal,dither=Image.Dither.NONE))
    ms[0].save(DIR/'map_marker_next.gif',save_all=True,append_images=ms[1:],duration=[120,130]*3,loop=0,disposal=2,optimize=False)
    ss[0].save(DIR/'shadow_dissolve.gif',save_all=True,append_images=ss[1:],duration=[80,80,90,80,80,90],disposal=2,optimize=False)
    blank=Image.new('RGB',(832,476),BG)
    drawtext(blank,(24,22),'재생 완료 · 검토용 반복 대기',22,DIM)
    b=blank.quantize(palette=pal,dither=Image.Dither.NONE)
    ss[0].save(DIR/'shadow_dissolve_review.gif',save_all=True,append_images=ss[1:]+[b],duration=[80,80,90,80,80,90,1200],loop=0,disposal=2,optimize=False)

def contact(icons,markers,mocks,shadows,revisions):
    im=Image.new('RGB',(2408,6200),BG)
    drawtext(im,(24,18),'SART-04 · 최초 10개 + 수정 2개 전체 접촉시트',36,GOLD)
    drawtext(im,(24,72),'위: 아이콘과 지도 모형 / 중간: 6프레임 표식 / 아래: 소멸 1× 몸 상자 비교와 모든 프레임 4×',23,DIM)
    im.paste(icons,(24,126))
    im.paste(mocks[0],(1400,160)); im.paste(mocks[1],(1400,458))
    drawtext(im,(1400,730),'지도 모형은 Pillow 합성입니다.',22,DIM)
    drawtext(im,(1400,768),'실제 Godot 실행 화면이 아닙니다.',22,DIM)
    im.paste(markers,(24,938))
    im.paste(shadows[0],(24,1660))
    im.paste(shadows[1],(24,3612))
    im.paste(revisions,(24,5620))
    im.save(DIR/'contact.png',optimize=True)
    # Compact overview for chat; the full contact sheet keeps the requested true scales.
    cover=Image.new('RGB',(1448,1100),BG)
    drawtext(cover,(24,14),'SART-04 · 스토리 지도와 그림자 소멸 후보',30,GOLD)
    cover.paste(mocks[0],(12,66));cover.paste(mocks[1],(730,66))
    drawtext(cover,(24,320),'아이콘 4× · v1 / v2',22,GOLD)
    xx=24
    for name in ['map_path_tile','map_marker_next','map_seal_clear','map_seal_locked']:
        for v in [1,2]:
            a=asset(name,v)
            if name=='map_marker_next':a=frame(a,0,48)
            put(cover,a,(xx,372),4)
            drawtext(cover,(xx,568),f'v{v}',18,DIM)
            xx+=174
    drawtext(cover,(24,616),'그림자 소멸 · 1× · 왼쪽에서 오른쪽으로 6프레임',22,GOLD)
    for v in [1,2]:
        drawtext(cover,(24,668+(v-1)*204),f'v{v}',22,DIM)
        put(cover,asset('shadow_dissolve',v),(112,660+(v-1)*204))
    cover.save(DIR/'overview.png',optimize=True)

if __name__=='__main__':
    metrics()
    icons=icon_board();markers=marker_board();mocks=[map_mock(1),map_mock(2)]
    revisions=revision_board()
    shadows=shadow_boards();gifs();contact(icons,markers,mocks,shadows,revisions)
    print('review evidence saved')
