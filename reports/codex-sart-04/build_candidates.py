"""SART-04 candidate-only art. Pillow 12; no product writes, no downloads.

All output assets are immutable: an existing PNG/JSON aborts the build.
The two generated source sheets retain one common scale and crop grid each.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import argparse, hashlib, json, math

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'art/bakeoff/story'
REPORT = ROOT / 'reports/codex-sart-04'
PALETTE = {
    'ink': '#101827', 'gold': '#f3cd7c', 'ochre': '#a8742c',
    'blue': '#3d7bd9', 'ice': '#9fd2ff', 'violet': '#3b1d5e',
    'purple': '#6b2fa8', 'lilac': '#b98af0',
    'pink': '#ff4fd8', 'blush': '#ffd6f5',
}
RGB = {k: tuple(bytes.fromhex(v[1:])) for k, v in PALETTE.items()}

def canvas(size):
    return Image.new('RGBA', size, (0, 0, 0, 0))

def color(name):
    return RGB[name] + (255,)

def poly(im, pts, fill):
    ImageDraw.Draw(im).polygon(pts, fill=color(fill))

def line(im, pts, fill, width=1):
    ImageDraw.Draw(im).line(pts, fill=color(fill), width=width)

def dot(im, xy, fill):
    im.putpixel(xy, color(fill))

def outline(im, width=1):
    a = im.getchannel('A')
    border = a.filter(ImageFilter.MaxFilter(2 * width + 1))
    bg = Image.new('RGBA', im.size, color('ink'))
    bg.putalpha(border)
    bg.alpha_composite(im)
    return bg

def diamond(cx, cy, rx, ry):
    return [(cx,cy-ry),(cx+rx,cy),(cx,cy+ry),(cx-rx,cy)]

def root_tile(variant):
    im = canvas((32,12))
    if variant == 1:
        ys = [6,6,6,6,5,5,5,5,5,5,6,6,6,6,7,7,7,7,7,6,6,6,5,5,5,5,5,6,6,6,6,6]
        leaves = [[(6,4),(7,2),(10,1),(10,3),(9,4)],[(21,8),(22,10),(25,10),(24,8),(23,7)]]
    else:
        ys = [6,6,6,5,5,5,5,6,6,6,7,7,7,7,7,6,6,5,5,5,5,5,6,6,6,6,7,7,6,6,6,6]
        leaves = [[(8,5),(8,3),(6,1),(4,1),(5,3),(6,4)],[(23,7),(25,8),(27,10),(24,10),(22,8)]]
    for x,y in enumerate(ys):
        for yy in range(y-1,y+2): dot(im,(x,yy),'ochre')
        dot(im,(x,y-1),'gold' if x%7 in [1,2,3] else 'ochre')
        dot(im,(x,y),'violet')
        if x%8 in [3,4]: dot(im,(x,y),'pink')
        if x%8 == 5: dot(im,(x,y),'lilac')
    for pts in leaves:
        poly(im,pts,'blue')
    if variant == 1:
        line(im,[(7,4),(9,2)],'ice')
        line(im,[(22,8),(24,9)],'ice')
    else:
        line(im,[(6,2),(8,4)],'ice')
        line(im,[(23,8),(26,9)],'ice')
    im = outline(im)
    # Periodic endpoints: the tangent and all RGBA values are identical.
    for y in range(12):
        im.putpixel((31,y),im.getpixel((0,y)))
        im.putpixel((30,y),im.getpixel((1,y)))
    return im

def heart(im, cx, cy, shade='blush'):
    pts=[(cx-4,cy-2),(cx-3,cy-3),(cx-1,cy-3),(cx,cy-2),
         (cx+1,cy-3),(cx+3,cy-3),(cx+4,cy-2),(cx+4,cy),
         (cx+2,cy+2),(cx,cy+4),(cx-2,cy+2),(cx-4,cy)]
    h=canvas(im.size)
    poly(h,pts,'pink')
    line(h,[(cx-3,cy-2),(cx-1,cy-2),(cx,cy-1),(cx+1,cy-2),(cx+3,cy-2)],shade)
    line(h,[(cx-3,cy-1),(cx-3,cy),(cx-1,cy+2)],shade)
    dot(h,(cx,cy+2),shade)
    im.alpha_composite(outline(h))

def marker_frame(variant, i):
    im=canvas((48,48))
    sway=[0,1,1,0,-1,-1][i]
    lift=[0,-1,-2,-1,0,1][i]
    side=[-1,-1,0,1,1,0][i]
    if variant == 1:
        poly(im,[(24,40),(19,39),(15,36),(13,31),(14,26),(16,22),
                 (15+side,17),(19,20),(20,16),(20+sway,12),
                 (24+sway,7+lift),(24+sway,12),(27,16),
                 (28,21),(29,25),(32+side,22),(34,27),(34,32),
                 (31,37),(27,40)],'violet')
        poly(im,[(22,38),(18,35),(16,30),(18,25),(19,27),(22,23),
                 (23+sway,16),(25,20),(26,26),(30,29),(31,27),
                 (32,31),(29,36),(26,38)],'purple')
        poly(im,[(20,34),(19,30),(21,27),(22,24),(25,25),(27,29),
                 (29,32),(28,35),(24,37)],'pink')
        line(im,[(17,30),(17,33),(19,35)],'lilac')
        line(im,[(24+sway,11+lift),(24+sway,14+lift)],'purple')
        line(im,[(30,35),(28,37),(25,38)],'lilac')
        im=outline(im)
        heart(im,24,30)
    else:
        poly(im,[(24,40),(18,39),(14,36),(12,32),(13,27),
                 (16,24),(17,19),(16+sway,12+lift),(21,16),
                 (24,22),(26,19),(27,13),(30+sway,8-lift),
                 (29,16),(32,21),(34,24),(35,29),(34,34),
                 (30,38),(27,40)],'violet')
        poly(im,[(18,37),(15,33),(15,29),(18,26),(19,22),
                 (20,19),(22,23),(24,26),(27,23),(28,19),
                 (30,23),(33,27),(32,32),(30,36),(25,38)],'purple')
        poly(im,[(17,32),(20,28),(22,27),(24,29),(27,26),
                 (30,29),(30,33),(27,36),(23,38),(20,36)],'pink')
        line(im,[(16,30),(16,33),(18,35)],'lilac')
        line(im,[(30,33),(29,35),(26,37)],'lilac')
        line(im,[(28+sway,14),(28+sway,17)],'purple')
        im=outline(im)
        heart(im,24,31)
    return im

def marker(variant):
    im=canvas((288,48))
    for i in range(6): im.alpha_composite(marker_frame(variant,i),(i*48,0))
    return im

def clear_seal(variant):
    im=canvas((40,40)); d=ImageDraw.Draw(im)
    # Bevel is part of the solid gold seal itself, not a UI frame.
    d.ellipse((4,4,35,35),fill=color('ink'))
    d.ellipse((5,5,34,34),fill=color('ochre'))
    d.ellipse((6,5,33,32),fill=color('gold'))
    d.arc((6,6,33,33),20,162,fill=color('ink'),width=1)
    d.ellipse((9,9,30,30),fill=color('ochre'))
    d.ellipse((10,10,29,29),fill=color('gold'))
    line(im,[(11,10),(17,8),(23,8)],'gold')
    # Small edge incisions suggest struck metal, with deliberately sparse details.
    for xy in [(13,6),(28,9),(33,20),(26,32),(8,27)]: dot(im,xy,'ochre')
    if variant == 1:
        rune=canvas((40,40))
        line(rune,[(20,12),(26,20),(20,28),(14,20),(20,12)],'ink',3)
        line(rune,[(20,12),(26,20),(20,28),(14,20),(20,12)],'blue',1)
        poly(rune,diamond(20,20,2,3),'ink')
        dot(rune,(20,19),'ice')
        dot(rune,(12,20),'ink'); dot(rune,(28,20),'ink')
        im.alpha_composite(rune)
        line(im,[(9,12),(11,10),(13,9)],'blush')
    else:
        # Three linked closed lozenges; no alphabetic rune or checkmark.
        for cx,cy in [(20,15),(16,22),(24,22)]:
            p=diamond(cx,cy,3,4)
            line(im,p+[p[0]],'ink',3)
            line(im,p+[p[0]],'blue',1)
        dot(im,(20,15),'ice')
        dot(im,(16,22),'ice'); dot(im,(24,22),'ice')
        line(im,[(9,12),(11,10),(13,9)],'blush')
    return im

def locked_seal(variant):
    im=canvas((40,40))
    if variant == 1:
        # Iron shackle, subdued with a mostly navy surface and sparse cold edges.
        line(im,[(12,20),(12,12),(14,8),(17,6),(23,6),(26,8),(28,12),(28,20)],'ink',5)
        line(im,[(12,19),(12,12),(15,8),(18,7),(23,7),(26,10),(27,14),(27,19)],'blue',1)
        line(im,[(15,18),(15,13),(17,10),(22,10),(24,12),(24,18)],'violet',1)
        poly(im,[(10,17),(29,17),(32,20),(32,29),(27,34),(13,34),(8,29),(8,20)],'ink')
        line(im,[(10,19),(28,19),(30,21),(30,28),(27,31)],'blue')
        line(im,[(10,22),(10,28),(14,32),(25,32)],'violet')
        line(im,[(12,21),(27,21)],'violet')
        line(im,diamond(20,25,3,4)+[(20,21)],'blue')
        dot(im,(20,25),'violet')
        dot(im,(12,20),'ice'); dot(im,(16,8),'ice')
        dot(im,(11,28),'blue'); dot(im,(28,28),'blue')
    else:
        # Two interwoven squared chain links, separated by dark crossover notches.
        a=[(8,16),(16,8),(21,8),(31,18),(31,23),(23,31),(18,31),(8,21),(8,16)]
        b=[(8,22),(8,17),(18,7),(23,7),(32,16),(32,21),(22,31),(17,31),(8,22)]
        line(im,a,'ink',7)
        line(im,b,'ink',7)
        line(im,a,'violet',3)
        line(im,a,'blue',1)
        line(im,b,'blue',1)
        line(im,[(12,14),(17,9),(21,9)],'ice')
        line(im,[(27,24),(23,28),(19,28)],'violet',3)
        line(im,[(15,19),(18,22),(20,24)],'ink',3)
        line(im,[(21,16),(24,19),(25,20)],'ink',3)
        line(im,[(13,16),(16,19),(19,22)],'blue')
        line(im,[(22,14),(25,17),(27,19)],'blue')
        dot(im,(14,17),'ice')
    return im

def shadow(variant):
    src = ROOT / f'art/raw/story/shadow_dissolve-v{variant}_raw.png'
    raw = Image.open(src).convert('RGBA')
    assert raw.size == (1536,1024)
    sheet=canvas((1152,192))
    colors=[RGB[n] for n in ['ink','violet','purple','lilac','pink','blush']]
    # Single scale for all six cells: 512 -> 144, nearest neighbour only.
    scale=144/512
    # First frame's last occupied row is the foot anchor. Later frames rise.
    raw_feet=485 if variant==1 else 477
    y0=152-round(raw_feet*scale)
    lift=[0,4,10,16,20,22]
    mappings=[]
    for i in range(6):
        x,y=i%3*512,i//3*512
        cell=raw.crop((x,y,x+512,y+512)).resize((144,144),Image.Resampling.NEAREST)
        cleaned=canvas((144,144))
        px=[]
        for r,g,b,a in cell.get_flattened_data():
            if a<128:
                px.append((0,0,0,0)); continue
            # Nearest listed palette color; no dithering or invented matte colors.
            c=min(colors,key=lambda c:(r-c[0])**2+(g-c[1])**2+(b-c[2])**2)
            px.append(c+(255,))
        cleaned.putdata(px)
        cleaned=outline(cleaned,1)
        target=canvas((192,192))
        target.alpha_composite(cleaned,(24,y0-lift[i]))
        sheet.alpha_composite(target,(192*i,0))
        mappings.append({'frame':i+1,'source_box':[x,y,x+512,y+512],
                         'resize':[144,144],'paste':[24,y0-lift[i]],
                         'rise_px':lift[i]})
    return sheet, {'raw':str(src.relative_to(ROOT)).replace('\\','/'),
                   'raw_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),
                   'grid':[3,2],'common_scale':scale,'alpha_threshold':128,
                   'palette':colors,'outline_px':1,'frame_mapping':mappings}

NOTES={
    'map_path_tile':[
        '완만한 금빛 뿌리와 위아래의 작은 푸른 잎 두 장. 중앙의 보라 결 속 분홍 소울 점이 반복된다.',
        '더 굽이치는 뿌리와 서로 바깥쪽을 향한 잎 두 장. 가는 길에서도 잎의 실루엣을 읽기 쉽다.'],
    'map_marker_next':[
        '한 줄기 영혼 불꽃. 작은 하트 중심은 고정하고 끝과 측면만 부드럽게 흔들리는 6프레임 루프.',
        '두 갈래로 갈라지는 영혼 불꽃. 넓은 아래쪽 보라 불꽃 안에 분홍 하트가 남는 6프레임 루프.'],
    'map_seal_clear':[
        '금색 원형 도장에 푸른 마름모와 작은 씨앗점으로 만든 비문자 룬. 간결한 완료 표식.',
        '금색 원형 도장에 세 개의 닫힌 마름모가 맞물린 비문자 룬. 세계들이 연결된 느낌.'],
    'map_seal_locked':[
        '짙은 남청 철제 자물쇠. 차가운 푸른 모서리와 작은 마름모 각인만 드러나도록 억제했다.',
        '두 개의 각진 철제 사슬 고리가 맞물린 매듭. 교차 지점은 짙은 절개로 앞뒤를 구분했다.'],
    'shadow_dissolve':[
        '가늘고 찢어진 보라 연무가 위로 흩어지며 작은 분홍 입자만 남는다. 발 원점은 (96,152).',
        '둥글게 말린 보라 연무 덩어리가 나뉘어 위로 흩어진다. 발 원점은 (96,152).'],
}

def save_asset(name,variant,im,processing=None,note=None):
    stem=f'{name}-v{variant}'
    png=OUT/(stem+'.png'); meta=OUT/(stem+'.json')
    if png.exists() or meta.exists():
        raise FileExistsError(f'Never overwrite candidates: {stem}; choose a new version.')
    is_marker=name=='map_marker_next'; is_shadow=name=='shadow_dissolve'
    animated=is_marker or is_shadow
    frames=6 if animated else 1
    size=[48,48] if is_marker else ([192,192] if is_shadow else list(im.size))
    data={'asset':name,'variant':f'v{variant}','status':'candidate',
          'note_ko':note if note is not None else NOTES[name][variant-1],
          'canvas_size':list(im.size),'frame_size':size,'frames':frames,
          'fps':8 if is_marker else (12 if is_shadow else None),'loop':is_marker,
          'pivot':[96,152] if is_shadow else ([24,40] if is_marker else None),
          'method':('내장 image_gen 원본 → 3×2 고정 칸 분리 → 공통 배율 최근접 축소 → '
                    '지정 6색 매핑 → alpha 128 문턱의 이진화 → 1px 남청 외곽 → 상승 위치 보정') if is_shadow
                    else 'Python + Pillow로 정확한 1배 캔버스에 직접 픽셀 드로잉. 보간·안티앨리어싱·디더링 없음.',
          'alpha':'binary 0/255; transparent RGB not used for rendering','palette':PALETTE,
          'processing':processing,
          'blend':'normal alpha (not additive)',
          'filter':'nearest','task':'design/tasks/SART-04.md'}
    im.save(png)
    data['sha256']=hashlib.sha256(png.read_bytes()).hexdigest()
    meta.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('WROTE',stem,im.size)

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    for name,fn in [('map_path_tile',root_tile),('map_marker_next',marker),
                    ('map_seal_clear',clear_seal),('map_seal_locked',locked_seal)]:
        for v in [1,2]: save_asset(name,v,fn(v))
    for v in [1,2]:
        im,processing=shadow(v)
        save_asset('shadow_dissolve',v,im,processing)

if __name__=='__main__': main()
