"""Offline scene composites, never a claim of a live Godot capture."""
from pathlib import Path
import math
import json
import sys
sys.dont_write_bytecode = True
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from build_assets import ROOT, REPORT, SPECS, output_path

BG = (22, 27, 38, 255)
GRID = (31, 37, 49, 255)
TEXT = (211, 218, 231, 255)
FONT = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf', 14)
SMALL = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf', 11)
ART = ROOT / 'smash-nine-prototype/assets/art'
XION = Image.open(ART / 'xion/xion_sheet.png').convert('RGBA')
FREY = Image.open(ART / 'frey/frey_sheet.png').convert('RGBA')
STATUS_NAMES = ['stun','super_armor','slow','luna_star_mark','nova_gravity_1','nova_gravity_2','nova_gravity_3']


def sprite(sheet, row=0, col=0):
    return sheet.crop((col*128,row*128,(col+1)*128,(row+1)*128))


def surface(size):
    im = Image.new('RGBA', size, BG)
    d = ImageDraw.Draw(im)
    for y in range(0,size[1],16):
        for x in range(0,size[0],16):
            if (x//16+y//16)%2:
                d.rectangle((x,y,x+15,y+15),fill=GRID)
    return im


def paste(im, src, xy, add=False):
    layer = Image.new('RGBA',im.size)
    layer.paste(src,tuple(map(round,xy)))
    if add:
        b=np.array(im).astype(np.float32); a=np.array(layer).astype(np.float32)
        b[:,:,:3]=np.minimum(255,b[:,:,:3]+a[:,:,:3]*(a[:,:,3:4]/255))
        return Image.fromarray(b.astype(np.uint8))
    return Image.alpha_composite(im,layer)


def hologram(src, top_y, time=0):
    # XionDouble.gd exact shader terms (pixel-centre FRAGCOORD, TIME chosen per frame).
    a=np.array(src).astype(np.float32)/255
    lum=np.sum(a[:,:,:3]*[.299,.587,.114],axis=2)
    yy=np.arange(src.height,dtype=np.float32)[:,None]+top_y+.5
    lines=.55+.45*((yy/3)%1>=.5)
    distance=np.abs((yy/170-time*.7)%1-.5)
    t=np.clip(distance/.05,0,1); sweep=1-t*t*(3-2*t)
    rgb=np.array([.96,.24,.34])[None,None,:]*(.42+.85*lum[:,:,None])*(1+.6*sweep[:,:,None])
    out=np.concatenate((np.broadcast_to(np.clip(rgb,0,1),a[:,:,:3].shape), (a[:,:,3]*lines*.62)[:,:,None]),axis=2)
    return Image.fromarray(np.uint8(np.clip(out*255,0,255)))


def frame_list(name, variant):
    p=output_path(name,variant)
    if not p.exists():
        return []
    im=Image.open(p).convert('RGBA'); w,h,n,*_=SPECS[name]
    return [im.crop((k*w,0,(k+1)*w,h)) for k in range(n)]


def scene(name, frame, k=0, annotate=True):
    if name=='xion_blast':
        im=surface((380,180)); im=paste(im,sprite(XION,5,1),(6,26))
        origin=(114,79)
        im=paste(im,frame,(origin[0]-8,origin[1]-64),True)
        if annotate:
            d=ImageDraw.Draw(im); d.line((114,160,364,160),fill=(108,126,153),width=1)
            for x in [114,364]: d.line((x,156,x,164),fill=TEXT)
            d.text((178,163),'250 px / muzzle',font=SMALL,fill=TEXT)
    elif name=='xion_recoil_blast':
        im=surface((240,292)); im=paste(im,sprite(XION,3),(56,5))
        # Sheet origin is (64,120); the pose's lifted soles remain above it.
        im=paste(im,frame,(24,109),True)
        if annotate:
            d=ImageDraw.Draw(im); d.line((8,125,8,265),fill=TEXT); d.text((12,264),'140 px',font=SMALL,fill=TEXT)
    elif name=='xion_point_blank':
        im=surface((176,156)); im=paste(im,sprite(FREY),(24,16))
        im=paste(im,frame,(32,48),True)
        if annotate:
            ImageDraw.Draw(im).text((5,138),'Frey / feet -32 px',font=SMALL,fill=TEXT)
    elif name=='xion_reload':
        im=surface((152,176)); im=paste(im,sprite(XION),(12,40)); im=paste(im,frame,(64,13))
        if annotate:
            ImageDraw.Draw(im).text((5,155),f'{k}/8  /  {k*3/8:.3f} s',font=SMALL,fill=TEXT)
    elif name=='xion_double_in':
        im=surface((176,200)); im=paste(im,hologram(sprite(XION),60,k/24),(24,60))
        im=paste(im,frame,(24,20),True)
    elif name=='xion_dive_trail':
        im=surface((464,168)); im=paste(im,sprite(XION),(16,24))
        im=paste(im,hologram(sprite(XION),24,k/31),(316,24))
        # Runtime contract explicitly stretches the 256px authored asset to the dive distance.
        trail=frame.resize((300,48),Image.Resampling.NEAREST)
        im=paste(im,trail,(80,88),True)
        if annotate:
            d=ImageDraw.Draw(im); d.line((80,151,380,151),fill=TEXT); d.text((191,154),'300 px',font=SMALL,fill=TEXT)
    elif name=='xion_bullet':
        im=surface((256,256)); im=paste(im,sprite(XION),(64,64))
        for j in range(12):
            angle=j*math.tau/12; shot=frame.rotate(-j*30,resample=Image.Resampling.NEAREST,expand=True)
            x=128+96*math.cos(angle)-shot.width/2; y=128+96*math.sin(angle)-shot.height/2
            im=paste(im,shot,(x,y),True)
    else:
        raise ValueError(name)
    return im


def contact(name, variant, scale):
    frames=frame_list(name,variant)
    if not frames: return
    scenes=[scene(name,frame,k) for k,frame in enumerate(frames)]
    cols=3 if name not in ('xion_reload','xion_bullet') else 4 if name=='xion_reload' else 2
    if name=='xion_dive_trail': cols=2
    cw,ch=scenes[0].size; gap=10; top=58
    footer=154 if name=='xion_reload' else 0
    board=Image.new('RGB',(cols*(cw*scale+gap)+gap,top+math.ceil(len(frames)/cols)*(ch*scale+35)+footer),(15,19,28))
    d=ImageDraw.Draw(board)
    d.text((12,8),f'{name} / {variant.upper()} / {scale}x nearest',font=FONT,fill=TEXT)
    d.text((12,29),'실제 게임 스프라이트 합성 · 실행 캡처 아님 · 가산 합성(재장전은 일반 합성)',font=SMALL,fill=TEXT)
    for k,im in enumerate(scenes):
        x=gap+(k%cols)*(cw*scale+gap); y=top+(k//cols)*(ch*scale+35)
        board.paste(im.resize((cw*scale,ch*scale),Image.Resampling.NEAREST),(x,y))
        d.text((x,y+ch*scale+5),f'F{k+1}  {k/SPECS[name][3]*1000:.0f} ms',font=SMALL,fill=TEXT)
    if footer:
        for j,status in enumerate(STATUS_NAMES):
            st=Image.open(ART/f'ui/status/{status}.png').convert('RGBA').resize((24*scale,24*scale),Image.Resampling.NEAREST)
            x=10+j*(board.width-20)//7; y=board.height-125
            board.paste(st,(x,y),st); d.text((x,y+77),status.replace('nova_gravity_','gravity '),font=SMALL,fill=TEXT)
    board.save(REPORT/f'{name}-{variant}-{scale}x.png')
    return scenes


def icon_board():
    names=['xion_j','xion_k','xion_l','xion_u','xion_i']
    if not all(output_path(n).exists() for n in names): return
    board=Image.new('RGB',(920,330),(15,19,28)); d=ImageDraw.Draw(board)
    d.text((16,10),'Skill bar / J K L U I / 1x and 4x',font=FONT,fill=TEXT)
    for j,name in enumerate(names):
        icon=Image.open(output_path(name)).convert('RGBA')
        board.paste(icon,(20+j*48,45),icon)
        large=icon.resize((160,160),Image.Resampling.NEAREST)
        board.paste(large,(20+j*180,130),large); d.text((20+j*180,303),name,font=SMALL,fill=TEXT)
    board.save(REPORT/'icons.png')


def overview():
    board=Image.new('RGB',(1200,1710),(15,19,28)); d=ImageDraw.Draw(board)
    d.text((24,16),'XION / VFX-10 · 후보 비교 · A 왼쪽 / B 오른쪽',font=FONT,fill=TEXT)
    d.text((24,40),'게임 스프라이트와 합성한 검토 자료입니다. 후보는 아직 게임에 연결되지 않았습니다.',font=SMALL,fill=TEXT)
    row_y=70
    peaks={'xion_blast':2,'xion_recoil_blast':2,'xion_point_blank':1,'xion_reload':6,'xion_double_in':2,'xion_dive_trail':1,'xion_bullet':0}
    for name,peak in peaks.items():
        d.line((20,row_y,1180,row_y),fill=(56,64,80)); d.text((24,row_y+5),name,font=FONT,fill=TEXT)
        if name=='xion_blast':
            d.text((195,row_y+7),'보류: 밝은 외곽 픽셀 일부가 ±14° 초과 (A 18.2° / B 19.2°)',font=SMALL,fill=(255,181,108))
        for j,variant in enumerate('ab'):
            frames=frame_list(name,variant)
            if not frames: continue
            im=scene(name,frames[peak],peak)
            if im.height>186:
                # Overview preview only: detail boards preserve exact 1x/4x.
                im.thumbnail((540,186),Image.Resampling.NEAREST)
            x=35+j*585; y=row_y+28
            board.paste(im,(x,y)); d.text((x+im.width+8,y),variant.upper(),font=FONT,fill=TEXT)
        row_y+=220
    for j,name in enumerate(['xion_j','xion_k','xion_l','xion_u','xion_i']):
        p=output_path(name)
        if p.exists():
            im=Image.open(p).convert('RGBA').resize((80,80),Image.Resampling.NEAREST)
            board.paste(im,(50+j*215,1620),im); d.text((50+j*215,1600),name,font=SMALL,fill=TEXT)
    if not output_path('xion_j').exists():
        d.text((24,1635),'미착수: 40×40 기술 아이콘 J / K / L / U / I — 시간 제한 이후 신규 제작 중단',font=FONT,fill=(255,181,108))
        d.text((24,1663),'정적 합성 보드만 검토함. 실제 게임의 재생 속도·다수 중첩·가시성은 채택 전 사람 검토 필요.',font=SMALL,fill=TEXT)
    board.save(REPORT/'board.png')


if __name__=='__main__':
    for name in SPECS:
        for variant in 'ab':
            for scale in ([1,4] if name in ('xion_blast','xion_recoil_blast','xion_point_blank','xion_reload') else [1]):
                contact(name,variant,scale)
    icon_board()
    overview()
