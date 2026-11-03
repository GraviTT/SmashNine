"""Additive composites at real game anchors and 1x / nearest 4x; not engine shots."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageEnhance, ImageOps
from build_effects import SPECS, ROOT, OUT, REPORT

INK = (225, 234, 249)
MUTED = (155, 172, 198)
BG = (14, 20, 33)
FONT = 'C:/Windows/Fonts/malgun.ttf'
W, H = 480, 224
NOVA_X, FLOOR = 80, 163
BODY_Y = FLOOR - 32
HAND_X = NOVA_X + 24


def text(im, xy, value, size=15, color=INK):
    ImageDraw.Draw(im).text(xy, value, font=ImageFont.truetype(FONT, size), fill=color)


def frame(kind, v, i=0):
    (w, h), *_ = SPECS[kind]
    im = Image.open(OUT / f'nova_beam_{kind}-{v}-v2.png').convert('RGBA')
    return im.crop((i*w, 0, (i+1)*w, h))


def sprite(name):
    p = 'art/bakeoff/nova/nova_male-idle-v2.png' if name == 'nova' else 'art/bakeoff/frey/frey-idle-v2.png'
    im = Image.open(ROOT / p).convert('RGBA').crop((0, 0, 128, 128))
    return im if name == 'nova' else ImageOps.mirror(im)


def composite(dst, src, xy, additive=False):
    x, y = map(int, xy)
    box = (max(x, 0), max(y, 0), min(x+src.width, dst.width), min(y+src.height, dst.height))
    if box[2] <= box[0] or box[3] <= box[1]:
        return
    src = src.crop((box[0]-x, box[1]-y, box[2]-x, box[3]-y)).convert('RGBA')
    if additive:
        a = np.array(src).astype(np.float32)
        b = np.array(dst.crop(box).convert('RGB')).astype(np.float32)
        out = np.minimum(255, b+a[:, :, :3]*(a[:, :, 3:]/255)).astype(np.uint8)
        dst.paste(Image.fromarray(out), box[:2])
    else:
        dst.paste(src, box[:2], src)


def background():
    im = Image.open(ROOT / 'smash-nine-prototype/assets/art/realm_center/bg_far.png').convert('RGB')
    im = im.crop((max(0, im.width//2-W//2), max(0, im.height//2-H//2),
                  max(0, im.width//2-W//2)+W, max(0, im.height//2-H//2)+H))
    im = ImageEnhance.Brightness(im).enhance(.23)
    d = ImageDraw.Draw(im)
    d.rectangle((0, FLOOR, W, H), fill=(17, 24, 36))
    d.line((0, FLOOR, W, FLOOR), fill=(73, 92, 108), width=1)
    return im


def tether(dst, v, start, end, yy):
    tile = frame('tile', v)
    width = max(0, int(end-start))
    if width == 0:
        return
    strip = Image.new('RGBA', (width, 16))
    for x in range(0, width, 64):
        strip.paste(tile, (x, 0))
    composite(dst, strip, (start, yy-8), True)


def scene(v, kind, i=0, distance=300, label=True, guides=False):
    dst = background()
    foe_x = NOVA_X + distance
    composite(dst, sprite('nova'), (NOVA_X-64, FLOOR-120))
    composite(dst, sprite('frey'), (foe_x-64, FLOOR-120))
    if kind == 'head':
        centre = (NOVA_X+150, BODY_Y)
        # The head is 150px from Nova; the line reaches its folded root.
        tether(dst, v, HAND_X, centre[0]-17, BODY_Y)
        composite(dst, frame('head', v, i), (centre[0]-24, centre[1]-24), True)
        caption = f'비행 F{i+1} · 촉 +150px / 상대 +300px'
    else:
        centre = (foe_x, BODY_Y)
        art = frame(kind, v, i)
        pixels = np.array(art)
        row = pixels[77:84, :, 3].max(0)
        root_x = int(np.flatnonzero(row)[0]) if row.any() else 8
        # Tether joins the art's left fork; it does not cross the protected torso.
        tether(dst, v, HAND_X, foe_x-80+root_x+3, BODY_Y)
        composite(dst, art, (foe_x-80, BODY_Y-80), True)
        name = '분리' if kind == 'split' else '결박'
        caption = f'{name} F{i+1} · 상대 +{distance}px'
        if guides:
            d = ImageDraw.Draw(dst)
            d.rectangle((foe_x-25, BODY_Y-40, foe_x+24, BODY_Y+39), outline=(236, 160, 102))
            d.line((foe_x-3, BODY_Y, foe_x+3, BODY_Y), fill=(255, 255, 255))
            d.line((foe_x, BODY_Y-3, foe_x, BODY_Y+3), fill=(255, 255, 255))
    if label:
        text(dst, (9, 7), f'{v.upper()}  {caption}', 14)
        text(dst, (9, H-22), '실제 스프라이트 합성 · additive · 1×', 11, MUTED)
    return dst


def sheet4x(kind, v):
    (w, h), count, *_ = SPECS[kind]
    cw, ch = w*4+24, h*4+44
    dst = Image.new('RGB', (cw*2, ch*2), BG)
    for i in range(count):
        x, y = i%2*cw+12, i//2*ch+28
        text(dst, (x, y-24), f'{v.upper()} {kind} F{i+1} / 4×', 14)
        enlarged = frame(kind, v, i).resize((w*4, h*4), Image.Resampling.NEAREST)
        composite(dst, enlarged, (x, y), True)
    dst.save(REPORT / f'{kind}-{v}-frames-4x.png')


def main():
    manifest = []
    stages = [('head', 0, 300)] + [('split', i, 300) for i in range(4)] + [('bind', i, 300) for i in range(4)] + [('bind', 0, 150), ('bind', 0, 69)]
    overview = Image.new('RGB', (W*2+48, H*len(stages)+110), BG)
    text(overview, (24, 14), 'NOVA · 갈라져 감싸고 끌어오는 중력 광선', 24)
    text(overview, (24, 50), 'A 곡선 촉수 / B 각진 갈고리 · 실제 크기 합성 · 몸 중심 = 발에서 32px 위', 14, MUTED)
    for v in 'ab':
        vx = 12 if v == 'a' else W+36
        for n, (kind, i, dist) in enumerate(stages):
            im = scene(v, kind, i, dist)
            stem = f'{v}-{n+1:02d}-{kind}-f{i+1}-{dist}px'
            overview.paste(im, (vx, 96+n*H))
            im.save(REPORT / (stem+'-1x.png'))
            im.resize((W*4, H*4), Image.Resampling.NEAREST).save(REPORT / (stem+'-4x.png'))
            manifest.append({'candidate': v, 'kind': kind, 'frame': i+1, 'distance': dist,
                             'nova_feet': [NOVA_X, FLOOR], 'foe_feet': [NOVA_X+dist, FLOOR],
                             'body_center': [NOVA_X+dist, BODY_Y], 'file_4x': stem+'-4x.png'})
        for kind in ('head', 'split', 'bind'):
            sheet4x(kind, v)
    overview.save(REPORT / 'board.png')
    # Smaller decision board: representative stages, A left and B right at native size.
    decision = Image.new('RGB', (W*2+48, 100+H*4), BG)
    text(decision, (24, 12), 'NOVA U · A / B 선택 보드', 25)
    text(decision, (24, 49), '비행 → 분리 → 결박 → 앞 69px 도착 · 엔진 캡처가 아닌 실제 아트 합성', 13, MUTED)
    for vi, v in enumerate('ab'):
        for row, args in enumerate([('head', 0, 300), ('split', 1, 300), ('bind', 0, 300), ('bind', 0, 69)]):
            decision.paste(scene(v, *args), (12+vi*(W+24), 90+row*H))
    decision.save(REPORT / 'summary.png')
    seams = Image.new('RGB', (850, 330), BG)
    text(seams, (24, 14), '연결줄 3회 반복 · 4× nearest', 22)
    for vi, v in enumerate('ab'):
        repeated = Image.new('RGBA', (192, 16))
        for x in (0, 64, 128):
            repeated.paste(frame('tile', v), (x, 0))
        y = 88+vi*115
        text(seams, (24, y-25), f'{v.upper()} · 좌우 이음 위치는 분홍 눈금', 14)
        composite(seams, repeated.resize((768, 64), Image.Resampling.NEAREST), (24, y), True)
        d = ImageDraw.Draw(seams)
        for x in (24+256, 24+512):
            d.line((x, y-8, x, y-2), fill=(255, 128, 193), width=2)
    seams.save(REPORT / 'tether-seams-4x.png')
    guides = Image.new('RGB', (W*2, H*4), BG)
    for vi, v in enumerate('ab'):
        for i in range(4):
            guides.paste(scene(v, 'bind', i, guides=True), (vi*W, i*H))
    guides.save(REPORT / 'safe-area.png')
    (REPORT / 'boards.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(f'Built {len(manifest)} in-context 1x/4x pairs, 6 full-frame 4x boards, overview, summary, seams, safe-area.')


if __name__ == '__main__':
    main()
