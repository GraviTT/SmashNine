"""In-context, explicitly labelled compositing boards. Not engine captures."""
from pathlib import Path
import json
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageEnhance
from build_effects import SPECS

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-vfx-05'
ART = ROOT / 'smash-nine-prototype/assets/art'
FX = ROOT / 'art/bakeoff/effects/nova'
BG = (17, 23, 40)
INK = (216, 230, 249)
MUTED = (143, 161, 189)
TEAL = (75, 222, 227)
FONT = 'C:/Windows/Fonts/malgun.ttf'


def text(im, xy, value, size=17, colour=INK):
    d = ImageDraw.Draw(im)
    d.text(xy, value, font=ImageFont.truetype(FONT, size), fill=colour)


def board(w, h, title, sub):
    im = Image.new('RGB', (w, h), BG)
    text(im, (24, 15), title, 25)
    text(im, (24, 51), sub, 14, MUTED)
    return im


def composite(dst, src, xy, additive=False):
    x, y = map(int, xy)
    if not additive:
        dst.paste(src, (x, y), src)
        return
    box = (max(0, x), max(0, y), min(dst.width, x+src.width), min(dst.height, y+src.height))
    if box[2] <= box[0] or box[3] <= box[1]:
        return
    cut = src.crop((box[0]-x, box[1]-y, box[2]-x, box[3]-y)).convert('RGBA')
    a = np.array(cut).astype(np.uint16)
    b = np.array(dst.crop(box).convert('RGB')).astype(np.uint16)
    out = np.minimum(255, b + a[:, :, :3] * (a[:, :, 3:] > 0)).astype(np.uint8)
    dst.paste(Image.fromarray(out), box[:2])


def effect(kind, var, frame=0):
    name, (w,h), n, *_ = SPECS[kind]
    p = FX / f'{name}-{var}-v1.png'
    if not p.exists():
        return None
    return Image.open(p).convert('RGBA').crop((frame*w, 0, (frame+1)*w, h))


def sprite(name):
    files = {
        'nova': 'art/bakeoff/nova/nova_male-idle-v2.png',
        'female': 'art/bakeoff/nova/nova_female-idle-v2.png',
        'frey': 'art/bakeoff/frey/frey-idle-v2.png',
        'luna': 'art/bakeoff/luna/luna-idle-v3.png',
    }
    im = Image.open(ROOT / files[name]).convert('RGBA')
    return im.crop((0, 0, 128, 128))


def fighter(dst, name, feet):
    im = sprite(name)
    # Adopted idle anchors: sheet base at (64,120), visible soles y=119.
    composite(dst, im, (feet[0]-64, feet[1]-120))


def realm(w, h):
    src = Image.open(ART / 'realm_center/bg_far.png').convert('RGB')
    # Crop at native resolution; no background scaling is needed for QA.
    if src.width >= w and src.height >= h:
        src = src.crop(((src.width-w)//2, (src.height-h)//2, (src.width+w)//2, (src.height+h)//2))
    else:
        out = Image.new('RGB', (w,h), BG)
        out.paste(src, (0,0))
        src = out
    return ImageEnhance.Brightness(src).enhance(.26)


def save(im, name):
    im.save(REPORT / name)


def stacks():
    existing = [('기절','stun.png'),('아머','super_armor.png'),('슬로우','slow.png'),('루나 표식','luna_star_mark.png')]
    out = board(1510, 880, '01 · 중력 중첩 — 머리 위 표식 비교', '1× 실제 배치 + 4× 표식 확대 · 기존 네 상태와 같은 크기 · 합성 검토')
    full = board(2740, 1430, '01 · 중력 중첩 — 머리 위 배치 전체 4×', '최근접 확대 · 위 A, 아래 B · 1·2·3단계 / 기절 / 아머 / 슬로우 / 루나 표식')
    for row, var in enumerate('ab'):
        y = 95 + row*385
        files = [(f'{var.upper()} {i}단계', ROOT/f'art/bakeoff/ui/status/nova_gravity_{i}-{var}-v1.png') for i in (1,2,3)]
        files += [(label,ART/'ui/status'/file) for label,file in existing]
        for col, (label,path) in enumerate(files):
            x=25+col*210
            text(out,(x,y),label,17,TEAL if col<3 else INK)
            scene=Image.new('RGB',(128,160),BG)
            fighter(scene,'nova',(64,152))
            icon=Image.open(path).convert('RGBA')
            composite(scene,icon,(52,5))
            out.paste(scene,(x+30,y+30))
            zoom=scene.crop((40,0,88,30)).resize((192,120),Image.Resampling.NEAREST)
            out.paste(zoom,(x,y+202))
            full.paste(scene.crop((16,0,112,160)).resize((384,640),Image.Resampling.NEAREST), (20+col*388,95+row*665))
    save(out,'stacks.png')
    save(full,'stacks-4x.png')


def roots():
    if effect('root','b') is None:return
    out=board(2380,760,'01 · 고정 고리 — 발 앵커 (48,16)','6장 전부 · 위: 1× 실제 배치 / 아래: 4× 발·고리 확대 · additive 합성')
    for row,var in enumerate('ab'):
        y=90+row*330
        text(out,(24,y),f'{var.upper()} · 6 frames / 10 fps',19,TEAL)
        for n in range(6):
            x=25+n*390
            scene=Image.new('RGB',(128,145),BG)
            fighter(scene,'nova',(64,125))
            composite(scene,effect('root',var,n),(64-48,125-16),True)
            ImageDraw.Draw(scene).line((15,139,113,139),fill=(50,63,85))
            out.paste(scene,(x+128,y+25))
            zoom=scene.crop((16,99,112,143)).resize((384,176),Image.Resampling.NEAREST)
            out.paste(zoom,(x,y+163))
            text(out,(x,y+28),str(n+1),14,MUTED)
    save(out,'roots.png')


def orbs():
    if effect('orb','b') is None:return
    out=board(1340,850,'02 · 중력 구체 — 64×64 / 45×45 판정','모든 프레임 1×·4× + Nova 옆 배치 · 노란 사각형은 45×45 참고선 · additive 합성')
    for row,var in enumerate('ab'):
        y=95+row*370
        text(out,(24,y),f'{var.upper()} · 4 frames / 16 fps',19,TEAL)
        for n in range(4):
            x=25+n*260
            f=effect('orb',var,n)
            sc=Image.new('RGB',(64,64),BG);composite(sc,f,(0,0),True)
            out.paste(sc,(x+90,y+28))
            out.paste(sc.resize((256,256),Image.Resampling.NEAREST),(x,y+97))
        sc=Image.new('RGB',(230,180),BG)
        fighter(sc,'nova',(62,150))
        composite(sc,effect('orb',var),(153-32,90-32),True)
        ImageDraw.Draw(sc).rectangle((131,68,175,112),outline=(190,155,67))
        out.paste(sc,(1080,y+90));text(out,(1090,y+270),'1× · 45×45',15,MUTED)
    save(out,'orbs.png')


def field_scene(var, frame=0, guide=True):
    sc=realm(640,640)
    fighter(sc,'nova',(295,390))
    fighter(sc,'frey',(465,330))
    composite(sc,effect('field',var,frame),(0,0),True)
    if guide:
        ImageDraw.Draw(sc).ellipse((20,20,620,620),outline=(105,91,57),width=1)
        ImageDraw.Draw(sc).line((314,320,326,320),fill=TEAL)
        ImageDraw.Draw(sc).line((320,314,320,326),fill=TEAL)
    return sc


def fields():
    if effect('field','b') is None:return
    out=board(1340,1150,'03 · 중력 필드 — 실제 반경 300px','A 왼쪽 / B 오른쪽 · 위 1× (640×640), 아래 경계 4× · 가는 황갈색 원은 반경300 참고선')
    for col,var in enumerate('ab'):
        x=20+col*660
        text(out,(x,82),f'{var.upper()} · 6 frames / 8 fps',18,TEAL)
        sc=field_scene(var)
        out.paste(sc,(x,112))
        # Top rim and side rim, at real nearest-neighbour 4x.
        clean=field_scene(var,guide=False)
        out.paste(clean.crop((240,0,400,70)).resize((640,280),Image.Resampling.NEAREST),(x,795))
        text(out,(x,1087),'상단 경계 4× · 내부 캐릭터는 이펙트보다 먼저 합성',14,MUTED)
    save(out,'fields.png')
    loops=board(1980,1010,'03 · 필드 경계의 여섯 위상 4×','A 위 / B 아래 · 각 160×48 경계 크롭을 640×192로 확대 · 마지막→첫 장도 같은 주기')
    for row,var in enumerate('ab'):
        for n in range(6):
            sc=field_scene(var,n,guide=False)
            cut=sc.crop((240,0,400,48)).resize((640,192),Image.Resampling.NEAREST)
            x=20+(n%3)*650;y=95+row*450+(n//3)*215
            loops.paste(cut,(x,y));text(loops,(x+5,y+3),f'{var.upper()} {n+1}',14,MUTED)
    save(loops,'field-phases-4x.png')
    # Whole perimeter preserved at 4x in four quadrants per candidate.
    for var in 'ab':
        sc=field_scene(var,guide=False)
        for i,(x,y) in enumerate(((0,0),(320,0),(0,320),(320,320))):
            save(sc.crop((x,y,x+320,y+320)).resize((1280,1280),Image.Resampling.NEAREST),f'field-{var}-4x-q{i+1}.png')


def beam_scene(var, frame=0):
    sc=Image.new('RGB',(470,150),BG)
    fighter(sc,'nova',(65,138))
    start=(86,99);end=(386,99)
    tile=effect('tile',var)
    for x in range(start[0],end[0],64):
        length=min(64,end[0]-x)
        composite(sc,tile.crop((0,0,length,16)),(x,start[1]-8),True)
    composite(sc,effect('head',var,frame),(end[0]-24,end[1]-24),True)
    return sc


def beams():
    if effect('head','b') is None or effect('tile','b') is None:return
    out=board(1340,990,'04 · 중력 광선 — 손에서 300px / 타일 반복','head 48×48, 4장 16fps · tile 64×16 · 아래 타일 3회 반복 4×, 분홍선은 이음 위치')
    for row,var in enumerate('ab'):
        y=95+row*440
        text(out,(24,y),f'{var.upper()} · 1× 손→머리 300px',18,TEAL)
        out.paste(beam_scene(var),(24,y+30))
        for n in range(4):
            sc=Image.new('RGB',(48,48),BG);composite(sc,effect('head',var,n),(0,0),True)
            out.paste(sc.resize((192,192),Image.Resampling.NEAREST),(520+n*198,y+30))
        sc=Image.new('RGB',(192,16),BG)
        for i in range(3):composite(sc,effect('tile',var),(i*64,0),True)
        zoom=sc.resize((768,64),Image.Resampling.NEAREST)
        out.paste(zoom,(24,y+270))
        d=ImageDraw.Draw(out)
        for x in (24+256,24+512):d.line((x,y+258,x,y+268),fill=(234,136,176),width=2)
        text(out,(24,y+350),'4× · 좌우 RGBA 일치 / 타일 자체에 끝점 없음',15,MUTED)
    save(out,'beams.png')


def sphere_scene(var,frame=0,guide=True):
    sc=realm(380,415)
    centre=(190,170)
    composite(sc,effect('sphere',var,frame),(centre[0]-160,centre[1]-160),False)
    if guide:
        ImageDraw.Draw(sc).ellipse((78,58,302,282),outline=(72,76,77),width=1)
    # Body centres, not feet, are placed exactly +-112px from the sphere centre.
    fighter(sc,'frey',(centre[0]-112,centre[1]+42))
    fighter(sc,'luna',(centre[0]+112,centre[1]+42))
    fighter(sc,'nova',(centre[0],centre[1]+192))
    return sc


def spheres():
    if effect('sphere','b') is None:return
    for var in 'ab':
        out=board(1180,965,f'05 · 사건의 지평선 {var.upper()} — 여섯 프레임 전부 1×','일반 합성 · 구체 뒤 / 적 둘 앞 · 적 몸 중심은 좌우112px · Nova 몸 중심은 아래150px')
        for n in range(6):
            x=15+(n%3)*390;y=110+(n//3)*425
            out.paste(sphere_scene(var,n),(x,y))
            text(out,(x+5,y+5),f'{n+1} / 6',15,MUTED)
        save(out,f'spheres-{var}.png')
        # Every frame's core + near-orbit overlap is inspected at 4x.
        zoom=board(1980,1420,f'05 · {var.upper()} 핵 경계·공전 캐릭터 겹침 4×','각 프레임 오른쪽 중첩부 (160×160) · 같은 고정 크롭, 최근접 확대')
        for n in range(6):
            sc=sphere_scene(var,n,guide=False)
            cut=sc.crop((202,85,362,245)).resize((640,640),Image.Resampling.NEAREST)
            zoom.paste(cut,(20+(n%3)*650,95+(n//3)*650))
        save(zoom,f'sphere-{var}-4x.png')
        save(sphere_scene(var,guide=False).resize((1520,1660),Image.Resampling.NEAREST),f'sphere-{var}-full-4x.png')


def icon_bar():
    im=Image.new('RGB',(300,68),BG);d=ImageDraw.Draw(im)
    for i,key in enumerate('jklui'):
        x=i*60+3
        d.rounded_rectangle((x,2,x+47,49),radius=5,fill=(26,34,54),outline=(71,85,113),width=1)
        icon=Image.open(ROOT/f'art/bakeoff/skill_icons/nova/nova_{key}-v1.png').convert('RGBA')
        composite(im,icon,(x+4,6));text(im,(x+19,50),key.upper(),12)
    return im


def icons():
    out=board(1260,550,'06 · HUD 아이콘 — J · K · L · U · I','40×40 그림을 48×48 슬롯 안에 4px inset · U는 L과 I 사이 · 위1× / 아래4×')
    bar=icon_bar();out.paste(bar,(28,100));out.paste(bar.resize((1200,272),Image.Resampling.NEAREST),(28,225))
    save(out,'icons.png')


def overview():
    if any(effect(k,'b') is None for k in SPECS):return
    out=board(1400,2050,'Nova · 새 키트 이펙트 후보','CODEX-VFX-05 · 실제 스프라이트 합성 보드 / 게임 적용 전 · 왼쪽 A, 오른쪽 B')
    for col,var in enumerate('ab'):
        x=30+col*690
        text(out,(x,85),f'{var.upper()}  '+('궤도 · 나선' if var=='a' else '사슬 · 분절'),24,TEAL)
        text(out,(x,135),'01  중력 중첩 / 고정',17)
        for stage in (1,2,3):
            icon=Image.open(ROOT/f'art/bakeoff/ui/status/nova_gravity_{stage}-{var}-v1.png').convert('RGBA')
            composite(out,icon.resize((72,72),Image.Resampling.NEAREST),(x+(stage-1)*84,170))
        root=Image.new('RGB',(128,140),BG);fighter(root,'nova',(64,122));composite(root,effect('root',var),(16,106),True)
        out.paste(root,(x+325,132))
        text(out,(x,280),'02  K · 중력 구체',17)
        sc=Image.new('RGB',(600,105),BG);fighter(sc,'nova',(65,103))
        for n in range(4):composite(sc,effect('orb',var,n),(150+n*94,25),True)
        out.paste(sc,(x,312))
        text(out,(x,430),'03  L · 필드 / 1× · 반경300',17)
        out.paste(field_scene(var),(x,465))
        text(out,(x,1120),'04  U · 광선 / 손에서300px',17)
        out.paste(beam_scene(var),(x+40,1150))
        text(out,(x,1325),'05  I · 사건의 지평선 / 1×',17)
        out.paste(sphere_scene(var),(x+130,1358))
    text(out,(30,1810),'06  HUD · 공통 1종 / J · K · L · U · I',20)
    bar=icon_bar();out.paste(bar,(35,1855));out.paste(bar.resize((900,204),Image.Resampling.NEAREST),(440,1825))
    save(out,'board.png')


if __name__=='__main__':
    for fn in (stacks,roots,orbs,fields,beams,spheres,icons,overview):
        fn()
        print(fn.__name__+' board complete (if sources available).')
