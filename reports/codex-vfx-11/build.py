"""CODEX-VFX-11: native pixel art, generated-art reduction, composite QA.

Writes only new task-owned paths. Pillow and NumPy are already installed.
"""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import json
import math
import subprocess

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-vfx-11'
RAW = ROOT / 'art/raw/vfx-11'
FX = ROOT / 'art/bakeoff/effects/rio'
ICONS = ROOT / 'art/bakeoff/skill_icons/rio'
ART = ROOT / 'smash-nine-prototype/assets/art'
START = '2026-11-26T15:08:26+00:00'
DEADLINE = '2026-11-26T17:38:26+00:00'
P = {'ink': '#10172A', 'navy': '#15295B', 'shadow': '#283C94',
     'blue': '#4A5CFF', 'teal': '#0F6683', 'mid': '#188FBA',
     'cyan': '#39D8FF', 'ice': '#9DEEFF', 'silver': '#DCECF2', 'white': '#F2FFFF'}
SPECS = {
    'rio_mana_sword': (96, 32, 4, 20, (48, 16), True, 'normal', 'effects/'),
    'rio_mana_sword_stuck': (96, 32, 4, 8, (48, 16), True, 'normal', 'effects/'),
    'rio_backstab': (96, 96, 5, 36, (48, 48), False, 'additive', 'effects/skill/'),
    'rio_shadow_blink': (128, 160, 6, 30, (64, 144), False, 'normal', 'effects/skill/'),
    'rio_counter_stance': (192, 192, 6, 15, (96, 152), True, 'normal', 'effects/skill/'),
    'rio_decoy_burst': (160, 160, 6, 30, (80, 80), False, 'additive', 'effects/skill/'),
}
NOTES = {
    ('rio_mana_sword', 'a'): '가는 은색 날 안에 청록 마력이 흐르는 마검. 짧은 직선 잔상.',
    ('rio_mana_sword', 'b'): '두 갈래 결정 가드와 긴 청색 결정 날. 쐐기 모양 잔상.',
    ('rio_mana_sword_stuck', 'a'): 'A 마검과 같은 날이 고정되어 기다림. 가드의 작은 룬이 맥동.',
    ('rio_mana_sword_stuck', 'b'): 'B 마검과 같은 날이 고정되어 기다림. 두 결정 불빛이 교대로 맥동.',
    ('rio_backstab', 'a'): '몸 중심에서 짧고 정확하게 교차하는 청록 X. 5장 뒤 사라짐.',
    ('rio_backstab', 'b'): '비대칭 X 베기와 양옆 결정 파편. 몸 중심의 밝은 교차점.',
    ('rio_shadow_blink', 'a'): '몸 양옆에서 안으로 닫히는 그림자 리본과 청록 조각.',
    ('rio_shadow_blink', 'b'): '몸 양옆으로 찢어져 나가는 각진 그림자 틈과 청록 조각.',
    ('rio_counter_stance', 'a'): '96픽셀 육각 룬 둘레를 흐르는 낮은 그림자 불꽃.',
    ('rio_counter_stance', 'b'): '96픽셀 육각 룬의 여섯 꼭짓점에서 번갈아 떠오르는 결정 조각.',
    ('rio_decoy_burst', 'a'): '얇은 청색 유리 조각이 위로 퍼지고 청록 고리가 짧게 확장.',
    ('rio_decoy_burst', 'b'): '굵은 쐐기 유리 조각이 위로 갈라지는 분신 파열과 끊어진 청록 고리.',
}


def write_text(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('\n'.join(s.rstrip() for s in content.splitlines()) + '\n', encoding='utf-8', newline='\n')


def write_json(path, data):
    write_text(path, json.dumps(data, ensure_ascii=False, indent=2))


def check_clock(label):
    now = datetime.now(timezone.utc)
    if now >= datetime.fromisoformat(DEADLINE):
        raise SystemExit('150-minute hard stop reached')
    log = REPORT / 'clock.json'
    entries = json.loads(log.read_text(encoding='utf-8')) if log.exists() else []
    entries.append({'action': label, 'utc': now.isoformat()})
    write_json(log, entries)
    print(label, now.isoformat())


def blank(size):
    return Image.new('RGBA', size)


def diamond(draw, x, y, rx, ry, col, core=None):
    draw.polygon([(x-rx,y),(x,y-ry),(x+rx,y),(x,y+ry)], fill=col)
    if core:
        draw.line([(x,y-ry+1),(x,y+ry-1)], fill=core, width=1)


def save_strip(name, variant, frames):
    w,h,n,fps,anchor,loop,blend,folder = SPECS[name]
    assert len(frames) == n
    strip = blank((w*n,h))
    for i, frame in enumerate(frames):
        assert frame.size == (w,h)
        strip.paste(frame, (i*w,0))
    path = FX / f'{name}-{variant}-v1.png'
    path.parent.mkdir(parents=True, exist_ok=True)
    strip.save(path)
    write_json(path.with_suffix('.json'), {
        'note': NOTES[name, variant], 'replaces': f'assets/art/{folder}{name}.png',
        'frames': n, 'fps': fps, 'anchor': anchor, 'loop': loop, 'blend': blend,
    })


def sword(variant, frame, stuck=False):
    im = blank((96,32))
    d = ImageDraw.Draw(im)
    phase = [0,1,2,1][frame]
    # Same blade vertices in flying and waiting modes; only light and sparks change.
    if not stuck:
        if variant == 'a':
            for y, x, length in [(12,7+frame%2*2,14),(16,4+frame%2,17),(20,9,11)]:
                d.line((x,y,x+length,y),fill=P['teal'],width=1)
                d.line((x+6,y,x+length,y),fill=P['cyan'],width=1)
        else:
            d.polygon([(3+frame,16),(23,10),(19,15),(25,16),(19,17),(23,22)],fill=P['shadow'])
            d.line([(8+frame,16),(19,13),(15,16),(20,18)],fill=P['cyan'],width=1)
    d.rectangle((19,14,31,18), fill=P['ink'])
    d.rectangle((20,15,31,17), fill=P['silver'])
    for x in (22,25,28):
        d.line((x,15,x,17),fill=P['teal'])
    diamond(d,18,16,3,3,P['navy'],P['silver'])
    if variant == 'a':
        d.polygon([(31,9),(34,8),(36,14),(79,12),(90,16),(79,20),(36,18),(34,24),(31,23)],fill=P['navy'])
        d.polygon([(36,14),(78,13),(88,16),(78,19),(36,18)],fill=P['silver'])
        d.polygon([(37,15),(76,14),(85,16),(76,18),(37,17)],fill=P['cyan'])
        d.line((38,17,77,17),fill=P['teal'])
        d.line((38,14,77,14),fill=P['ice'])
        d.line([(32,10),(33,14),(33,18),(32,22)],fill=P['silver'])
        diamond(d,34,16,4,5,P['teal'],P['ice'])
        diamond(d,34,16,2,3,P['cyan'],P['white'])
    else:
        d.polygon([(30,10),(37,7),(38,13),(73,11),(89,16),(73,21),(38,19),(37,25),(30,22),(33,16)],fill=P['navy'])
        d.polygon([(38,14),(72,12),(87,16),(72,20),(38,18),(42,16)],fill=P['silver'])
        d.polygon([(42,15),(71,13),(84,16),(71,19),(42,17),(46,16)],fill=P['cyan'])
        d.polygon([(46,16),(82,16),(71,19),(42,17)],fill=P['mid'])
        d.line((47,16,82,16),fill=P['ice'])
        for y in (11,21):
            diamond(d,35,y,3,3,P['teal'],P['silver'])
            diamond(d,35,y,1,2,P['cyan'])
        diamond(d,35,16,3,3,P['silver'],P['white'])
    # Periodic blade shimmer; silhouette never shifts.
    sx = [47,60,73,60][frame]
    d.line([(sx-1,15),(sx+2,15)],fill=P['white'],width=1)
    d.point((sx,16),fill=P['white'])
    if stuck:
        if variant == 'a':
            diamond(d,48,6,1+phase//2,2,P['teal'] if phase == 0 else P['cyan'],P['ice'])
            diamond(d,62,26,1,1+phase//2,P['mid'])
            if phase == 2:
                d.point((55,23),fill=P['ice'])
        else:
            diamond(d,45,7,2,2,P['cyan'] if frame < 2 else P['teal'],P['ice'] if frame == 1 else None)
            diamond(d,67,25,2,2,P['teal'] if frame < 2 else P['cyan'],P['ice'] if frame == 3 else None)
    return im


def backstab(variant, frame):
    im = blank((96,96))
    d = ImageDraw.Draw(im)
    def cut(a,b,width,col):
        ax,ay=a;bx,by=b
        vx,vy=bx-ax,by-ay
        length=math.hypot(vx,vy)
        px,py=-vy/length*width/2,vx/length*width/2
        mx,my=(ax+bx)/2,(ay+by)/2
        d.polygon([(ax,ay),(round(mx+px),round(my+py)),(bx,by),(round(mx-px),round(my-py))], fill=col)
    if frame < 4:
        extent=[8,17,18,13][frame]
        width=[4,7,4,2][frame]
        for sign in (-1,1):
            a=(48-extent,48-sign*extent*.78)
            b=(48+extent,48+sign*extent*.78)
            if variant == 'b' and sign == -1:
                a=(46-extent,48+extent*.63);b=(51+extent,48-extent*.70)
            a=tuple(round(v) for v in a);b=tuple(round(v) for v in b)
            cut(a,b,width+2,P['mid'])
            cut(a,b,width,P['cyan'])
            if frame < 3:
                cut(a,b,max(1,width-3),P['ice'])
        if frame in (0,1,2):
            diamond(d,48,48,[2,4,2][frame],[3,4,2][frame],P['white'])
        if variant == 'b' and frame in (1,2,3):
            r=[0,22,26,28][frame]
            diamond(d,48-r,48+3,2 if frame < 3 else 1,1,P['cyan'])
            diamond(d,48+r,48-4,2 if frame < 3 else 1,1,P['ice'])
    else:
        for x,y in [(33,60),(63,36)]:
            d.line((x,y,x+1,y),fill=P['teal'])
    return im


def small():
    check_clock('pixel generation: mana sword A/B, flying + waiting')
    for variant in 'ab':
        for stuck in (False, True):
            name='rio_mana_sword_stuck' if stuck else 'rio_mana_sword'
            save_strip(name,variant,[sword(variant,f,stuck) for f in range(4)])
    check_clock('pixel generation: backstab A/B')
    for variant in 'ab':
        save_strip('rio_backstab',variant,[backstab(variant,f) for f in range(5)])


def generated():
    check_clock('generated-art normalization and pixel ring repair')
    # All frames of each strip use ONE affine transform, not per-frame bbox fits.
    # Anchors are measured against source cell coordinates after visual inspection.
    settings = {
        ('rio_shadow_blink','a'): (0.30,(256,456),(64,144)),
        ('rio_shadow_blink','b'): (0.27,(256,475),(64,144)),
        ('rio_counter_stance','a'): (1/3,(256,249),(96,102)),
        ('rio_counter_stance','b'): (0.32,(256,253),(96,102)),
        ('rio_decoy_burst','a'): (0.25,(256,366),(80,80)),
        ('rio_decoy_burst','b'): (0.235,(256,376),(80,80)),
    }
    palette = np.array([tuple(bytes.fromhex(c[1:])) for c in P.values()],dtype=np.int32)
    records = []
    for (name,v),(scale,source_anchor,target_anchor) in settings.items():
        source = Image.open(RAW/f'{name}-{v}.png').convert('RGBA')
        assert source.size == (1536,1024)
        w,h,*_ = SPECS[name]
        frames=[]
        for f in range(6):
            cell=source.crop((f%3*512,f//3*512,f%3*512+512,f//3*512+512))
            a=np.array(cell)
            a[:,:,3]=np.where(a[:,:,3]>=128,255,0)
            a[a[:,:,3]==0]=0
            cell=Image.fromarray(a)
            sx,sy=source_anchor;tx,ty=target_anchor
            frame=cell.transform((w,h),Image.Transform.AFFINE,
                (1/scale,0,sx-tx/scale,0,1/scale,sy-ty/scale),
                resample=Image.Resampling.NEAREST)
            a=np.array(frame)
            mask=a[:,:,3]>0
            colors=a[:,:,:3][mask].astype(np.int32)
            near=((colors[:,None,:]-palette[None,:,:])**2).sum(axis=2).argmin(axis=1)
            a[:,:,:3][mask]=palette[near].astype(np.uint8)
            a[a[:,:,3]==0]=0
            frame=Image.fromarray(a)
            if name=='rio_counter_stance':
                # Restore a fixed 1-px six-sided baseline: thresholding the model's
                # soft line otherwise leaves holes and makes it shimmer unevenly.
                points=[(96,54),(138,78),(138,126),(96,150),(54,126),(54,78),(96,54)]
                ImageDraw.Draw(frame).line(points,fill=P['shadow'] if v=='a' else P['navy'],width=1)
            frames.append(frame)
        save_strip(name,v,frames)
        records.append({'name':name,'candidate':v,'source_grid':[3,2],
            'source_cell':[512,512],'scale':scale,'source_anchor':source_anchor,
            'target_anchor':target_anchor,'alpha_cutoff':128,
            'resample':'nearest','palette':P,'per_frame_rescale':False,
            'ring_baseline':[[96,54],[138,78],[138,126],[96,150],[54,126],[54,78]] if name=='rio_counter_stance' else None})
    write_json(REPORT/'normalization.json',records)


def icon_figure(d,x,y,ghost=False):
    dark=P['teal'] if ghost else P['navy']
    light=P['cyan'] if ghost else P['silver']
    d.polygon([(x-2,y),(x+2,y),(x+3,y+2),(x+3,y+5),(x+1,y+7),
               (x+5,y+10),(x+6,y+20),(x+1,y+20),(x,y+16),
               (x-1,y+20),(x-6,y+20),(x-5,y+10),(x-1,y+7),
               (x-3,y+5),(x-3,y+2)],fill=dark,outline=P['ink'])
    d.line((x-2,y+2,x+1,y+2),fill=light,width=2)
    d.line((x-3,y+10,x-3,y+16),fill=light,width=2)
    d.line((x+2,y+11,x+2,y+16),fill=P['mid'],width=2)
    if ghost:
        # Transparent cutouts suggest a holographic copy while preserving binary alpha.
        for yy in (y+4,y+12,y+17):
            d.line((x-1,yy,x+2,yy),fill=(0,0,0,0),width=1)


def icon(key):
    im=blank((40,40)); d=ImageDraw.Draw(im)
    if key=='j':
        d.polygon([(3,12),(23,12),(23,7),(37,18),(23,28),(23,23),(3,23)],
                  fill=P['teal'],outline=P['ink'])
        d.line([(5,14),(24,14),(24,11),(32,18)],fill=P['cyan'],width=2)
        d.polygon([(5,25),(10,20),(8,17),(11,15),(15,18),(33,13),
                   (37,13),(34,17),(17,22),(16,27),(13,28),(12,24),(7,28)],
                  fill=P['silver'],outline=P['ink'])
        d.line([(16,20),(33,15)],fill=P['cyan'],width=2)
        d.line((6,26,11,22),fill=P['navy'],width=2)
        diamond(d,14,21,2,2,P['cyan'])
    elif key=='k':
        # Dotted route ends in a small arrowhead behind the flying blade.
        for x,y in [(4,29),(7,26),(10,23),(13,20)]:
            d.rectangle((x,y,x+1,y+1),fill=P['cyan'])
        d.polygon([(12,14),(20,14),(20,22),(17,19),(15,21),(13,19),(15,17)],
                  fill=P['mid'],outline=P['ink'])
        d.polygon([(17,29),(21,23),(18,21),(20,18),(24,20),
                   (32,7),(36,4),(35,10),(28,23),(31,27),(28,29),
                   (25,26),(20,32)],fill=P['silver'],outline=P['ink'])
        d.line((25,21,33,8),fill=P['cyan'],width=2)
        d.line((20,28,23,24),fill=P['navy'],width=2)
        diamond(d,25,23,2,2,P['cyan'])
    elif key=='l':
        d.polygon([(23,4),(30,7),(35,13),(37,20),(35,27),(29,33),
                   (21,35),(27,29),(30,23),(30,17),(27,10)],
                  fill=P['blue'],outline=P['ink'])
        d.line([(27,7),(32,13),(34,20),(32,26),(27,31)],fill=P['cyan'],width=2)
        icon_figure(d,17,12)
        d.line((12,22,16,27),fill=P['mid'],width=2)
    elif key=='u':
        icon_figure(d,10,11)
        icon_figure(d,30,11,True)
        d.polygon([(8,7),(8,5),(28,5),(28,2),(34,6),(28,10),(28,7)],
                  fill=P['cyan'],outline=P['ink'])
        d.polygon([(32,34),(32,36),(12,36),(12,38),(6,35),(12,31),(12,34)],
                  fill=P['silver'],outline=P['ink'])
        d.rectangle((18,19,21,20),fill=P['teal'])
    elif key=='i':
        for i in range(6):
            angle=math.radians(-90+i*60)
            ux,uy=math.cos(angle),math.sin(angle)
            vx,vy=-uy,ux
            def pt(r,t):return (round(20+ux*r+vx*t),round(20+uy*r+vy*t))
            # Tip is nearer the centre than the crossguard and grip.
            poly=[pt(6,0),pt(12,-2),pt(14,-1),pt(14,-3),pt(16,-3),
                  pt(16,-1),pt(18,-1),pt(18,1),pt(16,1),pt(16,3),
                  pt(14,3),pt(14,1),pt(12,2)]
            d.polygon(poly,fill=P['silver'],outline=P['ink'])
            d.line([pt(8,0),pt(13,0)],fill=P['cyan'],width=1)
            d.point(pt(15,0),fill=P['teal'])
        diamond(d,20,20,2,2,P['mid'],P['ice'])
    return im


def icons():
    check_clock('pixel generation: five skill icons')
    notes={'j':'관통 화살표를 뚫고 나가는 검.', 'k':'점선 순간이동 화살표와 날아가는 마검.',
           'l':'그림자 인물 뒤의 초승달 베기.', 'u':'본체와 푸른 분신 사이의 양방향 교환 화살표.',
           'i':'날끝이 안쪽을 향하는 보석 검 여섯 자루.'}
    for key in 'jklui':
        path=ICONS/f'rio_{key}-v1.png'
        icon(key).save(path)
        write_json(path.with_suffix('.json'),{'note':notes[key],
            'replaces':f'assets/art/skill_icons/rio_{key}.png', 'frames':1,
            'fps':1,'anchor':[20,20],'loop':False,'blend':'normal'})


def manifest():
    files=[]
    for name in SPECS:
        for v in 'ab':
            for ext in ['.png','.json']:
                p=FX/f'{name}-{v}-v1{ext}'
                if p.exists(): files.append(p.relative_to(ROOT).as_posix())
    for key in 'jklui':
        for ext in ['.png','.json']:
            p=ICONS/f'rio_{key}-v1{ext}'
            if p.exists(): files.append(p.relative_to(ROOT).as_posix())
    for p in sorted(REPORT.iterdir()):
        excluded={'draft-contact.png','reference-cells.png','smoke_preview.py'}
        if p.is_file() and p.suffix in {'.py','.ps1','.md','.txt','.json','.png','.html'} and not p.name.startswith('baseline') and p.name not in excluded:
            files.append(p.relative_to(ROOT).as_posix())
    files += ['reports/codex-vfx-11/delivered_files.json','design/tasks/CODEX-VFX-11.md']
    write_json(REPORT/'delivered_files.json',sorted(set(files)))


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('action',choices=['small','generated','icons','manifest'])
    args=parser.parse_args()
    for p in [REPORT,RAW,FX,ICONS]: p.mkdir(parents=True,exist_ok=True)
    if args.action == 'small': small()
    if args.action == 'generated': generated()
    if args.action == 'icons': icons()
    manifest()
