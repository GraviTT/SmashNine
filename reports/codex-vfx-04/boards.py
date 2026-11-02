"""In-context candidate composites, not Godot screenshots."""
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageEnhance

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'reports/codex-vfx-04'
ART = ROOT / 'smash-nine-prototype/assets/art'
FX = ROOT / 'art/bakeoff/effects/luna'
ICONS = ROOT / 'art/bakeoff/skill_icons/luna'
NEAREST = Image.Resampling.NEAREST
FONT = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',14)
SMALL = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',11)
TITLE = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',20)
BG = '#111a2b'


def frames(name, count):
    im = Image.open(FX / (name+'-v1.png')).convert('RGBA')
    return [im.crop((i*im.height,0,(i+1)*im.height,im.height)) for i in range(count)]


def idle(brave=False, index=0):
    name = 'luna_brave-idle-v4.png' if brave else 'luna-idle-v3.png'
    im = Image.open(ROOT/'art/bakeoff/luna'/name).convert('RGBA')
    return im.crop((128*index,0,128*(index+1),128))


def add(dst,src,at):
    layer = Image.new('RGBA',dst.size)
    layer.paste(src,at)
    a = np.array(dst.convert('RGB')).astype(np.uint16)
    b = np.array(layer).astype(np.uint16)
    result = np.minimum(255,a+b[:,:,:3]*(b[:,:,3:4]>0)).astype(np.uint8)
    return Image.fromarray(result)


def scene(effect, kind, index=0, scale=1, guides=True, realm=False):
    tile = Image.new('RGB',(280,304),BG)
    if realm:
        bg = Image.open(ART/'realm_alfheim/bg_far.png').convert('RGB')
        x,y = bg.width//2-140,bg.height//2-152
        tile = ImageEnhance.Brightness(bg.crop((x,y,x+280,y+304))).enhance(.38)
    cx,cy = 140,156
    draw = ImageDraw.Draw(tile)
    if guides:
        if kind in ('barrier','break'):
            draw.ellipse((cx-105,cy-105,cx+105,cy+105),outline='#56785d',width=1)
        elif kind=='warp':
            draw.rectangle((cx-97,cy-82,cx+97,cy+82),outline='#76804d',width=1)
        elif kind=='cyclone-flying':
            draw.rectangle((cx-52,cy-75,cx+52,cy+74),outline='#76804d',width=1)
    if kind!='cyclone-flying':
        char = idle(kind.startswith('cyclone'),index%6)
        tile.paste(char,(cx-64,cy-86),char)
    else:
        draw.line((224,156,260,156),fill='#a6d5dc',width=1)
        draw.polygon([(260,156),(254,152),(254,160)],fill='#a6d5dc')
    if scale!=1:
        effect=effect.resize((round(effect.width*scale),round(effect.height*scale)),NEAREST)
    tile=add(tile,effect,(cx-effect.width//2,cy-effect.height//2))
    draw=ImageDraw.Draw(tile)
    draw.text((8,8),f'{kind}  F{index+1}',font=FONT,fill='#e5edff')
    draw.line((cx-3,cy,cx+3,cy),fill='#68b889')
    draw.line((cx,cy-3,cx,cy+3),fill='#68b889')
    if kind in ('barrier','break'):
        caption='R105 | body = feet - 34 | ADD'
    elif kind=='warp':
        caption='195 x 165 | body centre | ADD'
    elif kind=='cyclone-flying':
        caption='1x projectile | 105 x 150 | ADD'
    else:
        caption='1.25x effect | body centre | ADD'
    draw.text((8,282),caption,font=SMALL,fill='#a9b6d0')
    return tile


def contact(tiles,title,path,zoom=1,cols=3):
    w,h=tiles[0].size
    rows=math.ceil(len(tiles)/cols)
    board=Image.new('RGB',(cols*w,rows*h+30),BG)
    d=ImageDraw.Draw(board)
    d.text((8,6),title,font=FONT,fill='#f1e5be')
    for i,tile in enumerate(tiles):
        board.paste(tile,((i%cols)*w,30+(i//cols)*h))
    if zoom!=1:
        board=board.resize((board.width*zoom,board.height*zoom),NEAREST)
    board.save(OUT/path)
    return board


def effect_boards():
    for v in 'ab':
        for name,kind in [('luna_barrier','barrier'),('luna_barrier_break','break'),('luna_warp','warp')]:
            tiles=[scene(f,kind,i) for i,f in enumerate(frames(name+'-'+v,6))]
            for z in ([1,2,4] if kind in ('barrier','break') else [1,4]):
                contact(tiles,f'{name} {v.upper()} | {z}x viewing zoom | composite',f'{kind}-{v}-{z}x.png',z)
        tiles=[scene(f,'barrier',i,realm=True,guides=False) for i,f in enumerate(frames('luna_barrier-'+v,6))]
        contact([tiles[0]],f'Barrier {v.upper()} | dark Alfheim composite',f'barrier-{v}-dark-4x.png',4,1)
        cy=frames('luna_cyclone-'+v,6)
        for kind in ['cyclone-held','cyclone-flying']:
            tiles=[scene(f,kind,i,scale=1.25 if kind=='cyclone-held' else 1) for i,f in enumerate(cy)]
            for z in [1,4]:
                contact(tiles,f'{kind} {v.upper()} | {z}x viewing zoom | composite',f'{kind}-{v}-{z}x.png',z)


def shots_board():
    all_tiles=[]
    for name,sz,box in [('luna_star_shot',48,33),('luna_star_big',96,60)]:
        fs=frames(name,4)
        strip=Image.new('RGB',(sz*4,sz),BG)
        for i,f in enumerate(fs):
            strip.paste(f,(i*sz,0),f)
        strip.save(OUT/(name+'-strip-1x.png'))
        strip.resize((strip.width*4,strip.height*4),NEAREST).save(OUT/(name+'-strip-4x.png'))
        for i,f in enumerate(fs):
            im=Image.new('RGB',(240,176),BG)
            d=ImageDraw.Draw(im)
            d.text((8,5),f'{name} F{i+1}',font=FONT,fill='white')
            char=idle(index=i)
            im.paste(char,(-10,34),char)
            cx,cy=169,107
            d.rectangle((cx-box//2,cy-box//2,cx+(box-1)//2,cy+(box-1)//2),outline='#76804d')
            im.paste(f,(cx-sz//2,cy-sz//2),f)
            d.text((120,151),f'{box} x {box} hit box',font=SMALL,fill='#abbcd6')
            all_tiles.append(im)
    contact(all_tiles,'Star shots | native-size sprites beside Luna | normal blend','shots-1x.png',1,4)
    contact(all_tiles,'Star shots | 4x viewing zoom | normal blend','shots-4x.png',4,4)


def status_board():
    paths=[ROOT/'art/bakeoff/ui/status/luna_star_mark-v1.png']
    paths += [ART/'ui/status'/f'{x}.png' for x in ['stun','super_armor','luna_star_charge']]
    tiles=[]
    for p in paths:
        im=Image.new('RGB',(160,220),BG)
        d=ImageDraw.Draw(im)
        d.text((5,6),p.stem.replace('-v1',''),font=SMALL,fill='white')
        char=idle()
        feet=185
        im.paste(char,(16,feet-120),char)
        icon=Image.open(p).convert('RGBA')
        im.paste(icon,(80-icon.width//2,feet-121-icon.height//2),icon)
        d.text((5,204),'status centre = feet - 121',font=SMALL,fill='#9cacbf')
        tiles.append(im)
    for z in [1,4]:
        contact(tiles,'New mark / existing stun / armour / charge | comparison',f'status-{z}x.png',z,4)


def icons_board():
    fighters=['frey','yuki','luna','luna_brave','nova','rio']
    keys=['j','k','l','i']
    im=Image.new('RGB',(384,430),BG)
    d=ImageDraw.Draw(im)
    d.text((8,6),'HUD icon set | cyan edge = candidate slot',font=FONT,fill='#f1e5be')
    for row,fighter in enumerate(fighters):
        y=40+row*64
        d.text((4,y+16),fighter,font=SMALL,fill='white')
        for col,key in enumerate(keys):
            name=f'{fighter}_{key}'
            new=ICONS/(name+'-v1.png')
            path=new if new.exists() else ART/'skill_icons'/(name+'.png')
            icon=Image.open(path).convert('RGBA')
            x=100+col*64
            d.rounded_rectangle((x,y,x+47,y+47),radius=5,fill='#202943',outline='#79d9e0' if new.exists() else '#47516b',width=1)
            im.paste(icon,(x+4,y+4),icon)
            d.text((x+19,y+49),key.upper(),font=SMALL,fill='#c1cfec')
    im.save(OUT/'icons-1x.png')
    im.resize((im.width*4,im.height*4),NEAREST).save(OUT/'icons-4x.png')


def overview():
    board=Image.new('RGB',(1000,1600),BG)
    d=ImageDraw.Draw(board)
    d.text((20,14),'LUNA / VFX-04 CANDIDATES',font=TITLE,fill='white')
    d.text((220,48),'A',font=TITLE,fill='#84deec')
    d.text((720,48),'B',font=TITLE,fill='#ffa5d4')
    rows=[('luna_barrier','barrier',0),('luna_barrier_break','break',2),('luna_cyclone','cyclone-held',2),('luna_warp','warp',2)]
    for row,(name,kind,index) in enumerate(rows):
        y=82+row*302
        for col,v in enumerate('ab'):
            f=frames(name+'-'+v,6)[index]
            tile=scene(f,kind,index,scale=1.25 if kind=='cyclone-held' else 1)
            board.paste(tile,(110+col*500,y))
    y=1300
    d.text((20,y),'Star shots  /  1x & 4x boards supplied',font=FONT,fill='#f1e5be')
    for x,name,sz in [(30,'luna_star_shot',48),(170,'luna_star_big',96)]:
        f=frames(name,4)[0]
        board.paste(f,(x,y+38),f)
    mark=Image.open(ROOT/'art/bakeoff/ui/status/luna_star_mark-v1.png').convert('RGBA').resize((96,96),NEAREST)
    board.paste(mark,(370,y+35),mark)
    d.text((360,y+137),'Star mark 4x',font=SMALL,fill='white')
    d.text((540,y),'New HUD icons (2x overview)',font=FONT,fill='#f1e5be')
    for i,name in enumerate(['luna_j','luna_k','luna_l','luna_brave_k','luna_brave_l']):
        im=Image.open(ICONS/(name+'-v1.png')).convert('RGBA').resize((80,80),NEAREST)
        x=540+i*88
        board.paste(im,(x,y+44),im)
        d.text((x,y+130),['J','K','L','Brave K','Brave L'][i],font=SMALL,fill='white')
    d.text((20,1550),'Candidate composites, not game screenshots. Guides show the card reach / hit boxes.',font=FONT,fill='#b4c3da')
    board.save(OUT/'board.png')


if __name__=='__main__':
    effect_boards()
    shots_board()
    status_board()
    icons_board()
    overview()
    print('Context boards built.')
