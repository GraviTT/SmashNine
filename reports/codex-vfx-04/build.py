"""Reproducible candidate-only processing. No writes inside the Godot project."""
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'reports/codex-vfx-04'
RAW = ROOT / 'art/raw/vfx-04'
FX = ROOT / 'art/bakeoff/effects/luna'
ICONS = ROOT / 'art/bakeoff/skill_icons/luna'
STATUS = ROOT / 'art/bakeoff/ui/status'
NEAREST = Image.Resampling.NEAREST
META = []
FIT_AUDIT = []


def hard(im, cutoff=128):
    a = np.array(im.convert('RGBA'))
    a[:, :, 3] = np.where(a[:, :, 3] >= cutoff, 255, 0)
    a[a[:, :, 3] == 0, :3] = 0
    return Image.fromarray(a)


def cells(name, cols=3, rows=2):
    im = Image.open(RAW / (name + '.png')).convert('RGBA')
    w, h = im.width // cols, im.height // rows
    return [hard(im.crop((x*w, y*h, (x+1)*w, (y+1)*h)))
            for y in range(rows) for x in range(cols)]


def border(im):
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, im.width-1, im.height-1), outline=(0, 0, 0, 0))
    return im


def fit(im, size, source_anchor, scale, target=None):
    """Nearest downscale then anchor placement. Never enlarge source pixels."""
    if isinstance(scale, (int, float)):
        scale = (scale, scale)
    assert max(scale) <= 1.0, scale
    target = target or (size//2, size//2)
    nw, nh = [round(v*s) for v, s in zip(im.size, scale)]
    thumb = im.resize((nw, nh), NEAREST)
    position = (round(target[0] - source_anchor[0]*nw/im.width),
                round(target[1] - source_anchor[1]*nh/im.height))
    output = Image.new('RGBA', (size, size))
    output.paste(thumb, position)
    before = int(np.count_nonzero(np.array(thumb)[:,:,3]))
    output = border(hard(output))
    after = int(np.count_nonzero(np.array(output)[:,:,3]))
    FIT_AUDIT.append(dict(source_size=list(im.size), target_size=size, scale=list(scale),
                          source_anchor=list(source_anchor), paste=list(position),
                          visible_before=before, visible_after=after, cropped_pixels=before-after))
    return output


def ring_geometry(im):
    """Robust ellipse fit to coloured rim, excluding white/gold star centres."""
    a = np.array(im).astype(float)
    r, g, b, al = a.transpose(2, 0, 1)
    m = (al > 0) & (((r > g*1.3) & (b > g*1.2)) |
                    ((g > r*1.3) & (b > r*1.3))) & (np.maximum(r, b) > 100)
    yy, xx = np.where(m)
    x = xx - im.width/2
    y = yy - im.height/2
    keep = np.ones(len(x), bool)
    for _ in range(5):
        X = np.column_stack((x[keep]**2, y[keep]**2, x[keep], y[keep]))
        aa, bb, cc, dd = np.linalg.lstsq(X, np.ones(len(X)), rcond=None)[0]
        cx, cy = -cc/(2*aa), -dd/(2*bb)
        k = 1 + aa*cx*cx + bb*cy*cy
        rx, ry = math.sqrt(abs(k/aa)), math.sqrt(abs(k/bb))
        residual = abs(((x-cx)/rx)**2 + ((y-cy)/ry)**2 - 1)
        keep = residual < .12
    return (cx+im.width/2, cy+im.height/2), (rx, ry)


def save(name, frames, fps, loop, note, dest=FX, replaces=None, details=None):
    w, h = frames[0].size
    strip = Image.new('RGBA', (w*len(frames), h))
    for i, frame in enumerate(frames):
        strip.paste(frame, (i*w, 0))
    path = dest / (name + '-v1.png')
    strip.save(path)
    if replaces is None:
        base = name.rsplit('-', 1)[0] if name.endswith(('-a', '-b')) else name
        folder = 'effects/skill' if w >= 192 else 'effects'
        replaces = f'assets/art/{folder}/{base}.png'
    meta = dict(note=note, replaces=replaces, frames=len(frames), fps=fps,
                anchor=[w//2, h//2], loop=loop)
    path.with_suffix('.json').write_text(json.dumps(meta, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    META.append(dict(path=str(path.relative_to(ROOT)).replace('\\', '/'), **meta,
                     frame_size=[w,h], processing=details or {}))
    return frames


def effects():
    for variant in 'ab':
        frames, metrics = [], []
        for frame in cells('barrier-'+variant):
            center, radii = ring_geometry(frame)
            scale = (104/radii[0], 104/radii[1])
            frames.append(fit(frame, 256, center, scale))
            metrics.append(dict(source_center=center, source_radii=radii, scale=scale))
        save('luna_barrier-'+variant, frames, 10, True,
             ('청록 단일 테두리와 회전하는 작은 금색 별. 중심은 거의 비움.' if variant=='a'
              else '분홍·금색 두 가닥 테두리와 청록 반짝임. 중심은 거의 비움.'),
             details=dict(ellipse_fits=metrics, rim_center_radius=104))
        raw = cells('break-'+variant)
        center, radii = ring_geometry(raw[0])
        # First frame uses the matching idle shield to avoid a transition size jump.
        breaks = [frames[0].copy()]
        scale = 104/max(radii)
        for i, frame in enumerate(raw[1:], 1):
            box = frame.getbbox()
            # Generated rows can drift. Their bounding midpoint is the radial emission centre.
            anchor = ((box[0]+box[2])/2, (box[1]+box[3])/2)
            yy,xx = np.where(np.array(frame)[:,:,3]>0)
            extent = float(np.max(np.hypot(xx-anchor[0],yy-anchor[1])))
            # Keep shrinking particles near the expanding shell, not retreating to centre.
            # Each source is still reduced; no generated pixels are enlarged.
            local_scale = [0,119,121,123,124,124][i]/extent
            breaks.append(fit(frame, 256, anchor, local_scale))
        save('luna_barrier_break-'+variant, breaks, 24, False,
             '같은 후보 방어막에서 시작해 테두리가 갈라지고 작은 별 파편으로 사라짐.',
             details=dict(first_frame_matches_barrier=True, source_scale=scale))
    for variant in 'ab':
        raw = cells('cyclone-a-clean' if variant=='a' else 'cyclone-b')
        # A shared scale preserves generated relative sizes; per-frame centring removes sheet drift.
        bounds = [im.getbbox() for im in raw]
        scale = min(178/max(b[3]-b[1] for b in bounds), 144/max(b[2]-b[0] for b in bounds))
        frames = []
        for im, b in zip(raw, bounds):
            frames.append(fit(im, 192, ((b[0]+b[2])/2, (b[1]+b[3])/2), scale))
        save('luna_cyclone-'+variant, frames, 20, True,
             ('가는 나선 리본과 별, 몸이 보이는 큰 틈.' if variant=='a'
              else '넓은 분홍·금색 바람 리본과 짧은 청록 바람, 강한 회전감.'),
             details=dict(source_scale=scale, render_scales=[1.25,1]))
    for variant in 'ab':
        raw = cells('warp-'+variant)
        boxes = [im.getbbox() for im in raw]
        # Peak and scattered particles share the same spatial envelope, smaller ignition stays small.
        sx = 195/max(b[2]-b[0] for b in boxes)
        sy = 165/max(b[3]-b[1] for b in boxes)
        frames = [fit(im, 256, ((b[0]+b[2])/2,(b[1]+b[3])/2), (sx,sy))
                  for im,b in zip(raw,boxes)]
        save('luna_warp-'+variant, frames, 24, False,
             ('얇은 타원 빛 고리가 커진 뒤 별 반짝임으로 흩어짐.' if variant=='a'
              else '별빛 꽃잎이 뻗는 타원 고리 폭발. 중앙은 비워 몸을 보여 줌.'),
             details=dict(source_scale=[sx,sy], envelope=[195,165]))
    for name, raw_name, size, core_width in [('luna_star_shot','shot',48,33),('luna_star_big','big',96,60)]:
        raw = cells(raw_name,2,2)
        frames, details = [], []
        for index, im in enumerate(raw):
            # Correct small-shot phase4: the raw duplicated phase2's orientation.
            if raw_name=='shot' and index==3:
                im = im.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
            a = np.array(im)
            white = (a[:,:,0]>220)&(a[:,:,1]>220)&(a[:,:,2]>150)&(a[:,:,3]>0)
            yy,xx = np.where(white)
            center = (float(np.median(xx)),float(np.median(yy)))
            # Fixed scale per strip, based on full upright core diameter, not the tail.
            scale = core_width/([340,440][raw_name=='big'])
            frames.append(fit(im,size,center,scale))
            details.append(dict(source_center=center,scale=scale,flip_y=(raw_name=='shot' and index==3)))
        save(name, frames, 16, True,
             '오른쪽 비행. 별 중심 고정, 왼쪽 짧은 반짝임 꼬리. '+('작은 연사 별.' if size==48 else '더 밝은 금백색 중심과 큰 꼬리의 마지막 별.'),
             details=dict(frames=details))


# Small pixel icons: drawn directly at native resolution, no antialiasing.
NAVY = '#101625'
PINK = '#f04db8'
LIGHT = '#ffb0dc'
GOLD = '#ffd34d'
IVORY = '#fff4b0'
CYAN = '#42d8ec'
PURPLE = '#8160db'


def star(d, x, y, r, fill, outline=None, inner=None):
    k = max(1, round(r*.32))
    pts = [(x,y-r),(x+k,y-k),(x+r,y),(x+k,y+k),
           (x,y+r),(x-k,y+k),(x-r,y),(x-k,y-k)]
    d.polygon(pts, fill=fill)
    if outline:
        d.line(pts+[pts[0]],fill=outline,width=1)
    if inner and r>=4:
        star(d,x,y,max(2,r-3),inner)


def small_art():
    mark = Image.new('RGBA',(24,24))
    d = ImageDraw.Draw(mark)
    # Broken reticle ring, cardinal notches, central gold star: differs from blue charge diamond.
    for lo,hi in [(12,78),(102,168),(192,258),(282,348)]:
        d.arc((3,3,20,20),lo,hi,fill=NAVY,width=3)
        d.arc((4,4,19,19),lo,hi,fill=PINK,width=1)
    for box in [(10,1,13,3),(10,20,13,22),(1,10,3,13),(20,10,22,13)]:
        d.rectangle(box,fill=NAVY)
    for box in [(11,1,12,3),(11,20,12,22),(1,11,3,12),(20,11,22,12)]:
        d.rectangle(box,fill=PINK)
    star(d,12,12,6,GOLD,NAVY,IVORY)
    save('luna_star_mark',[border(mark)],0,False,'분홍 조준 고리 안의 금색 별. 기절·아머·충전 별과 구분.',
         dest=STATUS,replaces='assets/art/ui/status/luna_star_mark.png')
    for name in ['luna_j','luna_k','luna_l','luna_brave_k','luna_brave_l']:
        im = Image.new('RGBA',(40,40))
        d = ImageDraw.Draw(im)
        if name=='luna_j':
            for x,y,r in [(7,27,4),(14,21,5),(22,15,5)]:
                d.line((x-4,y+3,x-1,y+3),fill=CYAN,width=2)
                star(d,x,y,r,PINK,NAVY,GOLD)
            d.polygon([(16,29),(25,24),(25,28),(17,33)],fill=CYAN)
            star(d,30,23,9,PINK,NAVY,IVORY)
            star(d,30,23,5,GOLD,None,IVORY)
        elif name=='luna_k':
            # An interrupted cyan jump arc, small origin star and large arrival burst.
            for box in [(7,19,9,22),(9,13,11,15),(14,9,16,11),(20,8,22,10)]:
                d.rectangle((box[0]-1,box[1]-1,box[2]+1,box[3]+1),fill=NAVY)
                d.rectangle(box,fill=CYAN)
            star(d,7,29,4,PINK,NAVY)
            d.arc((19,14,37,33),15,150,fill=PINK,width=2)
            star(d,28,23,10,PINK,NAVY,GOLD)
            star(d,28,23,6,IVORY)
        elif name=='luna_l':
            d.ellipse((4,4,35,35),outline=NAVY,width=5)
            d.ellipse((6,6,33,33),outline=PINK,width=2)
            d.arc((8,8,31,31),190,350,fill=CYAN,width=2)
            star(d,20,6,5,GOLD,NAVY,IVORY)
            star(d,7,25,4,GOLD,NAVY)
            star(d,32,25,4,GOLD,NAVY)
            d.line((13,17,13,22),fill=LIGHT,width=2)
        elif name=='luna_brave_k':
            # Violet gauntlet wrapping its thumb over a captive golden star.
            d.polygon([(4,23),(10,22),(14,16),(15,12),(28,12),(31,16),(31,25),(27,29),(15,31),(6,32)],fill=NAVY)
            d.polygon([(6,24),(12,24),(16,18),(16,14),(27,14),(29,17),(29,24),(25,27),(16,29),(7,30)],fill=PURPLE)
            d.rectangle((7,23,11,30),fill=GOLD)
            d.rectangle((17,15,27,18),fill=LIGHT)
            d.rectangle((20,19,28,23),fill=NAVY)
            d.polygon([(14,22),(19,20),(23,22),(23,25),(17,25)],fill=PINK)
            star(d,24,20,4,GOLD)
            d.line([(16,7),(23,4),(30,4),(34,8)],fill=NAVY,width=5)
            d.line([(16,7),(23,5),(29,5),(33,9)],fill=CYAN,width=2)
            d.polygon([(29,9),(36,7),(35,15)],fill=NAVY)
            d.polygon([(30,10),(34,9),(34,13)],fill=CYAN)
        else:
            for pts in [[(6,10),(12,7),(29,7),(34,11),(30,15),(13,19),(8,19),(22,13),(28,11)],
                        [(7,20),(13,18),(29,17),(32,20),(27,25),(15,29),(10,28),(23,22),(26,21)],
                        [(13,31),(22,28),(27,27),(25,31),(19,35),(16,35),(20,31)]]:
                d.polygon(pts,fill=PINK)
                d.line(pts+[pts[0]],fill=NAVY,width=1)
            d.line([(11,11),(26,9),(29,10)],fill=IVORY,width=2)
            d.line([(12,22),(26,19)],fill=GOLD,width=2)
            d.line([(16,32),(22,30)],fill=GOLD,width=2)
            star(d,6,27,3,CYAN,NAVY)
            star(d,33,5,4,GOLD,NAVY)
        save(name,[border(im)],0,False,{
            'luna_j':'작은 별 세 발과 큰 마무리 별이 오른쪽으로 비행.',
            'luna_k':'점선 도약 궤적 끝에서 별빛 폭발.',
            'luna_l':'작은 금색 별이 붙은 둥근 분홍·청록 방어막.',
            'luna_brave_k':'별을 움켜쥔 보라색 건틀릿과 던지기 화살표.',
            'luna_brave_l':'세 층의 분홍·금색 회오리.'}[name],
            dest=ICONS,replaces=f'assets/art/skill_icons/{name}.png')


if __name__ == '__main__':
    effects()
    small_art()
    (OUT/'processing.json').write_text(json.dumps(META,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (OUT/'fit-audit.json').write_text(json.dumps(FIT_AUDIT,indent=2)+'\n',encoding='utf-8')
    print('Created',len(META),'PNG + metadata pairs')
