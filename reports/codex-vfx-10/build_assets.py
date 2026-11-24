"""VFX-10 candidates. Pillow/numpy only; writes only the task's candidate/report paths.

Raw generation frames use explicit art origins, then crop/downsample (never upscale).
Manual effects are drawn at delivery resolution. Run --raw or --manual separately.
"""
from pathlib import Path
import argparse
import json
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-vfx-10'
RAW = ROOT / 'art/raw/vfx-10'
FX = ROOT / 'art/bakeoff/effects/xion'
STATUS = ROOT / 'art/bakeoff/ui/status'
ICONS = ROOT / 'art/bakeoff/skill_icons/xion'
SPECS = {
    'xion_blast': (256, 128, 6, 30, (8, 64), False, 'assets/art/effects/xion_blast.png'),
    'xion_recoil_blast': (192, 176, 6, 30, (96, 16), False, 'assets/art/effects/skill/xion_recoil_blast.png'),
    'xion_point_blank': (112, 112, 5, 36, (56, 56), False, 'assets/art/effects/skill/xion_point_blank.png'),
    'xion_reload': (24, 24, 8, 8 / 3, (12, 12), False, 'assets/art/ui/status/xion_reload.png'),
    'xion_double_in': (128, 176, 6, 24, (64, 160), False, 'assets/art/effects/skill/xion_double_in.png'),
    'xion_dive_trail': (256, 48, 5, 31, (128, 24), False, 'assets/art/effects/skill/xion_dive_trail.png'),
    'xion_bullet': (24, 8, 2, 20, (12, 4), True, 'assets/art/effects/xion_bullet.png'),
}
NOTES = {
    ('xion_blast', 'a'): '가는 진홍 탄흔 다섯 갈래와 금백색 끝. 발사 뒤 가는 불씨만 남는다.',
    ('xion_blast', 'b'): '넓고 짧은 불꽃 조각이 갈라지는 산탄. A보다 총구 섬광과 파편의 면적이 크다.',
    ('xion_recoil_blast', 'a'): '발밑의 얇은 충격 고리에서 가는 산탄이 아래로 퍼진다.',
    ('xion_recoil_blast', 'b'): '두 갈래의 굵은 진홍 불꽃 날개와 가운데 금색 탄 조각이 떨어진다.',
    ('xion_point_blank', 'a'): '가로로 긴 십자 섬광과 가는 둥근 고리. 몸 중심에서 짧게 사라진다.',
    ('xion_point_blank', 'b'): '비스듬한 네 갈래 진홍 파열과 끊어진 원형 고리. 밝은 중심 뒤 대각선 파편이 남는다.',
    ('xion_reload', 'a'): '세운 금색 탄피와 연속 원형 진홍 진행 고리. 위에서 시계 방향으로 채운다.',
    ('xion_reload', 'b'): '비스듬한 은색 탄피와 여덟 구간의 각진 진홍 진행 고리. 위에서 시계 방향으로 채운다.',
    ('xion_double_in', 'a'): '발밑 타원에서 수직 스캔 기둥이 솟고 가로 주사선으로 몸 둘레를 읽은 뒤 사라진다. 인물은 포함하지 않는다.',
    ('xion_double_in', 'b'): '엇갈린 진홍 글리치 기둥과 좌우 꺾쇠가 아래에서 올라와 모인 뒤 조각으로 흩어진다. 인물은 포함하지 않는다.',
    ('xion_dive_trail', 'a'): '날카로운 진홍 리본 세 줄과 규칙적인 주사선. 왼쪽 출발점부터 지워진다.',
    ('xion_dive_trail', 'b'): '분절된 꺾쇠 탄도와 어긋난 홀로그램 조각. 왼쪽부터 붕괴하며 오른쪽 끝만 남는다.',
    ('xion_bullet', 'a'): '금백색 바늘 머리와 길고 가는 진홍 꼬리.',
    ('xion_bullet', 'b'): '두툼한 금색 탄두와 분리된 두 갈래 진홍 꼬리.',
}
INK = (20, 22, 34, 255)
DEEP = (87, 17, 39, 255)
RED = (171, 28, 58, 255)
CRIMSON = (235, 51, 77, 255)
CORAL = (255, 109, 119, 255)
GOLD = (245, 180, 79, 255)
LIGHT = (255, 231, 166, 255)
WHITE = (255, 250, 218, 255)
SILVER = (175, 187, 201, 255)


def save_json(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def output_path(name, variant=None):
    folder = STATUS if name == 'xion_reload' else ICONS if name in ('xion_j', 'xion_k', 'xion_l', 'xion_u', 'xion_i') else FX
    return folder / (name + ('-' + variant if variant else '') + '-v1.png')


def hard_alpha(im, threshold=128):
    a = np.array(im.convert('RGBA'))
    a[:, :, 3] = np.where(a[:, :, 3] >= threshold, 255, 0)
    a[a[:, :, 3] == 0, :3] = 0
    return Image.fromarray(a)


def save_strip(name, variant, frames, method, extra=None):
    w, h, n, fps, anchor, loop, replaces = SPECS[name]
    assert len(frames) == n
    strip = Image.new('RGBA', (w * n, h))
    for k, frame in enumerate(frames):
        assert frame.size == (w, h)
        assert set(np.unique(np.array(frame)[:, :, 3])).issubset({0, 255})
        border = np.array(frame)[:, :, 3]
        assert not (border[0].any() or border[-1].any() or border[:, 0].any() or border[:, -1].any())
        strip.paste(frame, (w * k, 0))
    p = output_path(name, variant)
    p.parent.mkdir(parents=True, exist_ok=True)
    strip.save(p)
    data = dict(note=NOTES[name, variant], replaces=replaces, frames=n, fps=fps,
                anchor=list(anchor), loop=loop, frame_size=[w, h],
                blend='normal' if name == 'xion_reload' else 'additive',
                filter='nearest', alpha='binary', method=method)
    if name == 'xion_reload':
        data['playback'] = 'progress-indexed: floor(clamp(progress,0,0.999999)*8); k=0..7 => k/8; hide at completion'
    if extra:
        data.update(extra)
    save_json(p.with_suffix('.json'), data)
    print('saved', p.relative_to(ROOT))


# Crop boundaries separate the six art drawings, not an assumption that their origins match.
RAW_LAYOUT = {
    ('xion_blast', 'a'): (2, 3, [(44,205),(768,205),(44,546),(768,546),(44,906),(768,906)], (0.354,0.354), 160),
    ('xion_blast', 'b'): (2, 3, [(58,207),(786,208),(56,546),(786,546),(56,906),(786,906)], (0.395,0.30), 160),
    ('xion_recoil_blast', 'a'): (3, 2, [(256,63),(768,63),(1280,63),(256,577),(768,577),(1280,577)], (0.40,0.36), 160),
    ('xion_recoil_blast', 'b'): (3, 2, [(222,132),(665,136),(1108,137),(222,728),(665,728),(1108,728)], (0.37,0.35), 160),
    ('xion_point_blank', 'a'): (5, 1, [(273,362),(678,362),(1087,362),(1491,362),(1902,362)], (0.31,0.29), 160),
    ('xion_point_blank', 'b'): (5, 1, [(229,362),(655,362),(1085,362),(1506,362),(1944,362)], (0.32,0.27), 160),
}


def normalize_raw(name, variant):
    cols, rows, origins, scales, threshold = RAW_LAYOUT[name, variant]
    raw = Image.open(RAW / f'{name}-{variant}.png').convert('RGBA')
    w, h, n, _, anchor, _, _ = SPECS[name]
    frames, extraction = [], []
    sx, sy = scales
    assert 0 < sx <= 1 and 0 < sy <= 1
    for k in range(n):
        cell = (round(k % cols * raw.width / cols), round(k // cols * raw.height / rows),
                round((k % cols + 1) * raw.width / cols), round((k // cols + 1) * raw.height / rows))
        piece = hard_alpha(raw.crop(cell), threshold)
        bbox = piece.getbbox()
        assert bbox, (name, k)
        crop = piece.crop(bbox)
        nw, nh = max(1, round(crop.width * sx)), max(1, round(crop.height * sy))
        # No enlargement; common per-sequence scale preserves the growth/fade of frames.
        assert nw <= crop.width and nh <= crop.height
        small = hard_alpha(crop.resize((nw, nh), Image.Resampling.LANCZOS), 100)
        ox, oy = origins[k]
        at = (round(anchor[0] + (cell[0] + bbox[0] - ox) * sx),
              round(anchor[1] + (cell[1] + bbox[1] - oy) * sy))
        frame = Image.new('RGBA', (w, h))
        frame.paste(small, at)
        # Muzzle backs can extend behind the authored origin. Clip only the outside border.
        d = ImageDraw.Draw(frame)
        d.rectangle((0,0,w-1,h-1), outline=(0,0,0,0), width=1)
        frame = hard_alpha(frame)
        frames.append(frame)
        extraction.append(dict(source_cell=list(cell), source_crop=list(bbox), source_origin=list(origins[k]),
                               scale=[sx,sy], target_paste=list(at), alpha_threshold=threshold))
    save_strip(name, variant, frames, 'image_gen raw; explicit crop; downsample; hard alpha',
               dict(source_raw=f'art/raw/vfx-10/{name}-{variant}.png', extraction=extraction))


def reload_mark(variant):
    frames=[]
    for k in range(8):
        im=Image.new('RGBA',(24,24)); px=im.load()
        for y in range(1,23):
            for x in range(1,23):
                dx=x-12; dy=y-12
                angle=(math.atan2(dy,dx)+math.pi/2)%math.tau
                if variant=='a':
                    radius=math.hypot(dx,dy)
                    if 8<=radius<=10:
                        lit=angle < k/8*math.tau
                        px[x,y]=INK if radius>9.5 or radius<8.5 else DEEP
                        if lit and radius<=9.5:
                            px[x,y]=CORAL if radius<8.8 else CRIMSON
                else:
                    # Pixel octagon, eight separate segments with visible one-pixel joints.
                    radius=max(abs(dx),abs(dy))+.41421356*min(abs(dx),abs(dy))
                    sector=int(angle/(math.tau/8))
                    if 8.3<=radius<=10 and angle%(math.tau/8)>.10:
                        px[x,y]=CRIMSON if sector<k else INK
                        if sector<k and radius<9:
                            px[x,y]=CORAL
        d=ImageDraw.Draw(im)
        if variant=='a':
            d.rectangle((9,6,14,17),fill=INK)
            d.rectangle((10,7,13,14),fill=GOLD)
            d.line((10,7,10,13),fill=LIGHT)
            d.rectangle((9,15,14,17),fill=GOLD)
            d.line((10,15,13,15),fill=WHITE)
            d.line((11,8,13,8),fill=RED)
        else:
            d.polygon([(8,7),(11,5),(17,15),(13,18),(7,8)],fill=INK)
            d.polygon([(9,7),(11,7),(15,13),(12,15),(8,9)],fill=SILVER)
            d.line((9,8,12,13),fill=WHITE,width=1)
            d.polygon([(11,15),(15,12),(17,15),(13,18)],fill=GOLD)
            d.line((12,15,15,13),fill=LIGHT,width=1)
        frames.append(im)
    save_strip('xion_reload',variant,frames,'Pillow; hand-authored native pixels')


def barrage_shot(variant):
    frames=[]
    for k in range(2):
        im=Image.new('RGBA',(24,8)); d=ImageDraw.Draw(im)
        if variant=='a':
            d.line((2+k,4,19,4),fill=DEEP)
            d.line((7+k,3,18,3),fill=RED)
            d.line((5+k,4,20,4),fill=CRIMSON)
            d.line((10+k,5,19,5),fill=RED)
            d.polygon([(15,3),(20,2),(22,4),(20,5),(15,5)],fill=GOLD)
            d.line((15+k,4,22,4),fill=WHITE)
        else:
            d.line((2,2,8-k,2),fill=RED)
            d.line((5,3,13,3),fill=CRIMSON)
            d.line((2,6,8-k,6),fill=RED)
            d.line((6,5,13,5),fill=CRIMSON)
            d.polygon([(12,2),(18,2),(22,4),(18,6),(12,6),(14,4)],fill=RED)
            d.polygon([(15,2),(19,3),(21,4),(18,5),(14,5)],fill=GOLD)
            d.line((16+k,3,19,3),fill=LIGHT)
            d.line((17,4,21,4),fill=WHITE)
        frames.append(im)
    save_strip('xion_bullet',variant,frames,'Pillow; hand-authored native pixels')


def scan_colour(lum, y, time=0.0, strength=1.0):
    # Same scan period, phase, tint and sweep equation as XionDouble.gd.
    # Binary-alpha effect assets encode line attenuation in RGB, never partial alpha.
    frag_y=y+.5
    lines=.55+.45*float((frag_y/3)%1>=.5)
    distance=abs((frag_y/170-time*.7)%1-.5)
    t=max(0,min(1,distance/.05)); sweep=1-t*t*(3-2*t)
    power=(.42+.85*lum)*(1+.6*sweep)*lines*strength
    return tuple(min(255,round(c*255*power)) for c in (.96,.24,.34))+(255,)


def scan_finish(im,k,fps,strength=1):
    pix=im.load()
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=pix[x,y]
            if a:
                lum=(.299*r+.587*g+.114*b)/255
                pix[x,y]=scan_colour(lum,y,k/fps,strength)
    return im


def dive_trail(variant):
    frames=[]
    starts=[2,35,90,148,211]
    for k in range(5):
        im=Image.new('RGBA',(256,48)); d=ImageDraw.Draw(im)
        cut=starts[k]
        if variant=='a':
            # Three coherent scarf-like ribbons; narrow ends, no soft gradients/halo.
            for y in range(5,43):
                for x in range(cut,253):
                    end=max(0,(253-x)/251)
                    main=abs(y-24) <= 1+5*math.sin((x-1)/252*math.pi)
                    upper=abs(y-(14+7*(1-x/252))) <= 1+2*(1-end)
                    lower=abs(y-(34-7*(1-x/252))) <= 1+2*(1-end)
                    if main or upper or lower:
                        lum=.8 if main and abs(y-24)<2 else .42 if main else .23
                        if x<cut+15 and (x+y)%5==0: continue
                        im.putpixel((x,y),scan_colour(lum,y,k/31,[1,.94,.77,.58,.36][k]))
            for x,y in [(24,10),(68,36),(108,10),(154,37),(198,8)]:
                if x>cut:
                    d.line((x,y,x+13,y),fill=scan_colour(.3,y,k/31,.7))
        else:
            # Broken chevrons advance into the destination, with asymmetric parallel echo bits.
            for j in range(7):
                x=12+j*34
                if x+28<cut: continue
                d.polygon([(x,11),(x+8,11),(x+28,24),(x+8,37),(x,37),(x+17,24)],fill=(130,130,130,255))
                d.line((x+6,12,x+24,24,x+6,36),fill=(225,225,225,255),width=1)
                if j%2==0:
                    d.line((x+11,7,x+27,7),fill=(90,90,90,255),width=2)
                else:
                    d.line((x+2,40,x+16,40),fill=(90,90,90,255),width=2)
            d.rectangle((0,0,cut-1,47),fill=(0,0,0,0))
            # Break up late frames rather than simply modulating the whole asset's alpha.
            if k>=2:
                for y in range(1,47):
                    for x in range(cut,255):
                        if ((x//7+y//3+k)%7)<k-1: im.putpixel((x,y),(0,0,0,0))
            scan_finish(im,k,31,[1,.92,.76,.58,.35][k])
        frames.append(im)
    save_strip('xion_dive_trail',variant,frames,'Pillow; hand-authored native pixels',
               dict(scan_formula='XionDouble.gd: tint (.96,.24,.34), luminance .299/.587/.114, 3px lines .55/1, 170px sweep at .7/s; attenuation in RGB for binary alpha'))


def hologram_cast(variant):
    frames=[]
    for k in range(6):
        im=Image.new('RGBA',(128,176)); d=ImageDraw.Draw(im)
        gray=lambda v:(v,v,v,255)
        if variant=='a':
            # The platform / scaffold rises bottom-to-top. The actor is intentionally absent.
            if k<4:
                rx=[20,33,42,36][k]
                d.ellipse((64-rx,155,64+rx,165),outline=gray(190 if k<3 else 100),width=1)
                d.arc((64-rx+4,157,64+rx-4,163),180,335,fill=gray(240),width=1)
            tops=[150,103,38,20,22,35]
            for j,x in enumerate([27,39,51,77,89,101]):
                if k==0 and j not in [1,4]: continue
                if k==5 and j not in [0,5]: continue
                top=tops[k]+[9,0,16,7,1,13][j]
                bottom=158 if k<4 else 115 if k==4 else 65
                if bottom>top:
                    d.line((x,top,x,bottom),fill=gray(90 if j%2 else 140),width=1)
                    d.rectangle((x-1,top,x+1,top+5),fill=gray(225))
            if 1<=k<=4:
                yy=[0,137,83,35,26][k]
                for n in range(3):
                    # Negative gaps leave the central figure readable.
                    y=yy+n*9
                    d.line((22,y,43,y),fill=gray(185-n*30),width=1)
                    d.line((83,y,106,y),fill=gray(185-n*30),width=1)
                    d.line((49,y+2,78,y+2),fill=gray(95-n*16),width=1)
        else:
            # Wider jagged columns and bracket bites, intentionally unlike A's wire scaffold.
            tops=[149,104,48,19,21,35]
            for j,(x,width) in enumerate([(18,5),(34,8),(54,4),(73,6),(92,9),(108,3)]):
                if k==0 and j%2: continue
                if k==5 and j not in [0,4]: continue
                top=tops[k]+(j*11)%23; bottom=162 if k<3 else 140 if k==3 else 91 if k==4 else 62
                for y in range(top,bottom,8):
                    if ((j+y//8+k)%4)==0: continue
                    offset=3 if (y//8+j)%2 else -2
                    d.rectangle((x+offset,y,x+offset+width,y+2),fill=gray(145+(j%3)*24))
                    if y%24<8: d.line((x+offset,y-1,x+offset+width//2,y-1),fill=gray(230))
            if k<4:
                y=[159,143,99,50][k]
                d.line((31,y-8,23,y-8,23,y+5,31,y+5),fill=gray(220),width=2)
                d.line((97,y-8,105,y-8,105,y+5,97,y+5),fill=gray(220),width=2)
                d.line((40,160,55,162,73,162,88,160),fill=gray(130),width=1)
        scan_finish(im,k,24,[.8,1,1,.9,.55,.3][k])
        frames.append(im)
    save_strip('xion_double_in',variant,frames,'Pillow; hand-authored native pixels',
               dict(scan_formula='XionDouble.gd tint/luminance/3px scan/sweep; binary-alpha effect uses RGB scan attenuation. Board figure uses exact shader alpha with HOLOGRAM_ALPHA=.62.'))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--raw', action='store_true')
    parser.add_argument('--only')
    parser.add_argument('--manual', action='store_true')
    args = parser.parse_args()
    if args.raw:
        for name, variant in RAW_LAYOUT:
            if args.only is None or args.only == name:
                normalize_raw(name, variant)
    if args.manual:
        functions={'xion_reload':reload_mark,'xion_bullet':barrage_shot,'xion_dive_trail':dive_trail,'xion_double_in':hologram_cast}
        for name,func in functions.items():
            if args.only is None or args.only==name:
                for variant in 'ab': func(variant)
