"""Reproducible composites and contract audit; no Godot/project writes."""
from pathlib import Path
import argparse
import hashlib
import json
import math
import subprocess

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from build import ROOT, REPORT, RAW, ART, FX, ICONS, SPECS, NOTES, P, write_json, write_text, manifest

FONT_PATH = 'C:/Windows/Fonts/malgun.ttf'
BG = (16,24,41,255)
LIGHT = (153,170,187,255)
LABELS = {'rio_mana_sword':'마검 · 비행', 'rio_mana_sword_stuck':'마검 · 대기',
          'rio_backstab':'급소 X', 'rio_shadow_blink':'그림자 이동',
          'rio_counter_stance':'받아치기 자세', 'rio_decoy_burst':'분신 폭발'}
SCENES = ['flying','body','wall','air']
SCENE_LABELS = {'flying':'던지는 손 앞', 'body':'적 몸 중심', 'wall':'벽에 꽂힘', 'air':'공중 대기'}


def font(size=18):
    return ImageFont.truetype(FONT_PATH,size)


def frame(name,v,n):
    w,h,*_=SPECS[name]
    return Image.open(FX/f'{name}-{v}-v1.png').convert('RGBA').crop((n*w,0,(n+1)*w,h))


def sprite(kind='male',throw=False):
    if throw:
        # Existing temporary K pose: dimension_slash, third frame, 192-px cell.
        p=ART/'rio'/f'rio_{kind}_moves_sheet.png'
        return Image.open(p).convert('RGBA').crop((384,960,576,1152)),(96,152)
    p=ART/('frey/frey_sheet.png' if kind=='foe' else f'rio/rio_{kind}_sheet.png')
    return Image.open(p).convert('RGBA').crop((0,0,128,128)),(64,120)


def tint(im,rgba):
    a=np.array(im).astype(float)
    a*=np.array(rgba)[None,None,:]
    return Image.fromarray(np.rint(a).clip(0,255).astype(np.uint8))


def paste_anchor(canvas,im,at,anchor,blend='normal'):
    layer=Image.new('RGBA',canvas.size)
    layer.paste(im,(round(at[0]-anchor[0]),round(at[1]-anchor[1])))
    if blend=='normal':
        return Image.alpha_composite(canvas,layer)
    a=np.array(canvas).astype(np.float32)
    b=np.array(layer).astype(np.float32)
    a[:,:,:3]=np.clip(a[:,:,:3]+b[:,:,:3]*(b[:,:,3:4]/255),0,255)
    return Image.fromarray(np.rint(a).astype(np.uint8))


def scene(name,v,f,kind='male',sword_scene='flying',light=False,marks=False):
    size=(256,160) if 'mana_sword' in name else (192,192)
    canvas=Image.new('RGBA',size,LIGHT if light else BG)
    d=ImageDraw.Draw(canvas)
    foot=(96,170) if size==(192,192) else (112,144)
    if 'mana_sword' in name:
        if sword_scene=='flying':
            foot=(64,144)
            fig,anchor=sprite(kind,True)
            canvas=paste_anchor(canvas,fig,foot,anchor)
            # F3 hand at cell (101,100): 5px forward and 52px above feet.
            at=(188,92)
        elif sword_scene=='body':
            fig,anchor=sprite('foe')
            canvas=paste_anchor(canvas,fig,foot,anchor)
            at=(112,112)
        elif sword_scene=='wall':
            d.rectangle((116,18,184,144),fill=(49,65,84),outline=(99,121,142),width=2)
            for y in range(34,144,24):
                d.line((118,y,182,y),fill=(26,37,51))
            at=(110,90)
        else:
            at=(112,77)
        d=ImageDraw.Draw(canvas)
        d.line((4,145,251,145),fill=(44,61,76))
    else:
        if name=='rio_backstab':
            fig,anchor=sprite('foe')
        else:
            fig,anchor=sprite(kind)
        if name=='rio_counter_stance':
            fig=tint(fig,(.45,.52,1,1))
        if name=='rio_decoy_burst':
            fig=tint(fig,(.5,.78,1,.62))
        canvas=paste_anchor(canvas,fig,foot,anchor)
        d=ImageDraw.Draw(canvas)
        d.line((4,171,187,171),fill=(44,61,76))
        at=foot if name in ('rio_shadow_blink','rio_counter_stance') else (foot[0],foot[1]-32)
    spec=SPECS[name]
    canvas=paste_anchor(canvas,frame(name,v,f),at,spec[4],spec[6])
    if marks:
        d=ImageDraw.Draw(canvas)
        d.line((at[0]-3,at[1],at[0]+3,at[1]),fill='#F3B96D')
        d.line((at[0],at[1]-3,at[0],at[1]+3),fill='#F3B96D')
    return canvas


def icon_bar(scale=1):
    bar=Image.new('RGBA',(5*52+8,64),BG)
    d=ImageDraw.Draw(bar)
    for i,key in enumerate('jklui'):
        x=8+i*52
        d.rectangle((x,4,x+47,51),fill='#182D49',outline='#35556A')
        im=Image.open(ICONS/f'rio_{key}-v1.png').convert('RGBA')
        bar.alpha_composite(im,(x+4,8))
        d.text((x+20,52),key.upper(),font=font(10),fill='#C4D9E9')
    return bar.resize((bar.width*scale,bar.height*scale),Image.Resampling.NEAREST)


def detail(name,v,sword_scene='flying'):
    n=SPECS[name][2]
    samples=[scene(name,v,i,sword_scene=sword_scene) for i in range(n)]
    sw,sh=samples[0].size
    cols=3 if n>4 else 2
    bigw=cols*(sw*4+16)+16
    rows=math.ceil(n/cols)
    h=100+sh+rows*(sh*4+32)+90
    out=Image.new('RGB',(max(bigw,n*(sw+8)+16),h),BG[:3])
    d=ImageDraw.Draw(out)
    title=f'{LABELS[name]}  {v.upper()}  |  {SCENE_LABELS[sword_scene]}' if 'mana_sword' in name else f'{LABELS[name]}  {v.upper()}'
    d.text((16,10),title,font=font(24),fill='#E5F3FF')
    d.text((16,48),'실제 시트 합성 · 위 1× / 아래 4× 최근접 · 게임 실행 화면이 아님',font=font(16),fill='#95AEC5')
    for i,im in enumerate(samples):
        x=16+i*(sw+8)
        d.text((x,76),f'F{i+1}',font=font(12),fill='#96CDE7')
        out.paste(im.convert('RGB'),(x,98))
        x=16+(i%cols)*(sw*4+16);y=122+sh+(i//cols)*(sh*4+32)
        d.text((x,y-23),f'F{i+1} · {i/SPECS[name][3]:.3f} s',font=font(14),fill='#96CDE7')
        out.paste(im.resize((sw*4,sh*4),Image.Resampling.NEAREST).convert('RGB'),(x,y))
    d.text((16,h-42),f'셀 {SPECS[name][0]}×{SPECS[name][1]} | {SPECS[name][3]} fps | anchor {SPECS[name][4]} | {SPECS[name][6]}',font=font(17),fill='#AFC5D5')
    suffix='-'+sword_scene if 'mana_sword' in name else ''
    out.save(REPORT/f'{name}-{v}{suffix}-board.png')


def overview():
    out=Image.new('RGB',(1200,1800),BG[:3]);d=ImageDraw.Draw(out)
    d.text((24,15),'RIO  /  KIT v3  /  VFX-11',font=font(28),fill='#E7F6FF')
    d.text((24,58),'시안 비교 · A 왼쪽 / B 오른쪽 · 실제 스프라이트 합성',font=font(17),fill='#A3B9CB')
    d.text((290,92),'A',font=font(24),fill='#5FE1FF');d.text((880,92),'B',font=font(24),fill='#5FE1FF')
    for row,name in enumerate(SPECS):
        y=132+row*240
        d.line((24,y,1176,y),fill='#2D4155')
        d.text((24,y+6),LABELS[name],font=font(18),fill='#E4EDF6')
        for col,v in enumerate('ab'):
            x=24+col*590
            if 'mana_sword' in name:
                scen='flying' if name=='rio_mana_sword' else 'body'
                a=scene(name,v,1,sword_scene=scen)
                b=scene(name,v,2,sword_scene='air' if name.endswith('stuck') else scen,light=True)
            else:
                a=scene(name,v,1 if name=='rio_backstab' else 2)
                b=scene(name,v,1 if name=='rio_backstab' else 2,kind='female',light=True)
            out.paste(a.convert('RGB'),(x+10,y+32))
            out.paste(b.convert('RGB'),(x+275,y+32))
    y=1590
    d.line((24,y,1176,y),fill='#2D4155')
    d.text((24,y+10),'스킬 아이콘  J · K · L · U · I',font=font(18),fill='#E4EDF6')
    out.paste(icon_bar(1).convert('RGB'),(24,y+47))
    out.paste(icon_bar(2).convert('RGB'),(385,y+28))
    d.text((24,1762),'1× 스프라이트 / 원화 확대 없음 / 후보 파일만 작성 / 실제 전투의 타이밍과 선택은 사람 검수',font=font(14),fill='#8DA8BC')
    out.save(REPORT/'board.png')


def boards():
    for name in SPECS:
        for v in 'ab':
            if name=='rio_mana_sword':
                detail(name,v,'flying')
            elif name=='rio_mana_sword_stuck':
                for scen in ['body','wall','air']: detail(name,v,scen)
            else:
                detail(name,v)
    out=Image.new('RGB',(1120,410),BG[:3]);d=ImageDraw.Draw(out)
    d.text((20,10),'스킬 아이콘 · 1× / 4× 최근접 확대',font=font(22),fill='#D9F2FF')
    out.paste(icon_bar().convert('RGB'),(20,48));out.paste(icon_bar(4).convert('RGB'),(20,130))
    out.save(REPORT/'icons-board.png')
    overview()
    # The pure sheets support pixel QA without blend/background interference.
    height=sum(2*(spec[1]+38) for spec in SPECS.values())+16
    out=Image.new('RGB',(1280,height),BG[:3]);d=ImageDraw.Draw(out);y=8
    for name in SPECS:
        for v in 'ab':
            im=Image.open(FX/f'{name}-{v}-v1.png')
            d.text((12,y),f'{LABELS[name]} {v.upper()} · {SPECS[name][3]} fps',font=font(16),fill='#D9F2FF')
            out.paste(im,(116,y+26),im);y+=im.height+38
    out.crop((0,0,1280,y)).save(REPORT/'strips-board.png')


def validate():
    checks=[];metrics=[]
    for name,(w,h,n,fps,anchor,loop,blend,folder) in SPECS.items():
        for v in 'ab':
            path=FX/f'{name}-{v}-v1.png';im=Image.open(path)
            meta=json.loads(path.with_suffix('.json').read_text(encoding='utf-8'))
            assert im.mode=='RGBA' and im.size==(w*n,h),path
            a=np.array(im)
            assert set(np.unique(a[:,:,3])).issubset({0,255}),path
            assert np.all(a[a[:,:,3]==0,:3]==0),path
            assert meta['frames']==n and meta['fps']==fps and meta['anchor']==list(anchor),path
            assert meta['loop']==loop and meta['blend']==blend,path
            assert meta['replaces']==f'assets/art/{folder}{name}.png',path
            counts=[];bounds=[];above=[];below=[]
            for i in range(n):
                c=a[:,i*w:(i+1)*w,:];m=c[:,:,3]>0
                border=int(m[0,:].sum()+m[-1,:].sum()+m[:,0].sum()+m[:,-1].sum())
                assert border==0,(path,i,'border')
                counts.append(int(m.sum()))
                bounds.append(Image.fromarray(c).getbbox())
                above.append(int(m[:anchor[1],:].sum()));below.append(int(m[anchor[1]:,:].sum()))
            rgba_hash=hashlib.sha256(a.tobytes()).hexdigest()
            colors=len(np.unique(a[:,:,:3][a[:,:,3]>0],axis=0))
            metrics.append({'name':name,'candidate':v,'file':path.relative_to(ROOT).as_posix(),
                'strip_size':list(im.size),'cell':[w,h],'frames':n,'fps':fps,
                'duration_seconds':n/fps,'anchor':list(anchor),'loop':loop,'blend':blend,
                'alpha_values':[0,255],'border_nonzero':0,'colors':colors,
                'opaque_pixels':counts,'frame_bboxes':bounds,'pixels_above_anchor':above,
                'pixels_at_or_below_anchor':below,'rgba_sha256':rgba_hash})
            checks.append(f'{name}-{v}: PASS')
    for key in 'jklui':
        path=ICONS/f'rio_{key}-v1.png';im=Image.open(path);a=np.array(im)
        meta=json.loads(path.with_suffix('.json').read_text(encoding='utf-8'))
        assert im.mode=='RGBA' and im.size==(40,40)
        assert set(np.unique(a[:,:,3]))=={0,255}
        assert not (a[0,:,3].any() or a[-1,:,3].any() or a[:,0,3].any() or a[:,-1,3].any())
        assert meta['anchor']==[20,20] and meta['frames']==1 and not meta['loop'] and meta['blend']=='normal'
        checks.append(f'rio_{key}: PASS')
        metrics.append({'name':f'rio_{key}','file':path.relative_to(ROOT).as_posix(),
            'strip_size':[40,40],'frames':1,'anchor':[20,20],'alpha_values':[0,255],
            'border_nonzero':0,'colors':len(np.unique(a[:,:,:3][a[:,:,3]>0],axis=0))})
    # Compact X against the same foe body's centre as the composite boards.
    for v in 'ab':
        for f in range(5):
            fx=frame('rio_backstab',v,f)
            # Explicit probe rectangle around Frey's visible face in the QA scene.
            layer=Image.new('RGBA',(192,192));layer.paste(fx,(48,90))
            assert not np.array(layer)[87:112,84:115,3].any(),('face rectangle',v,f)
        checks.append(f'backstab-{v}: Frey face probe rectangle (84,87)-(115,112) clear, 5/5')
    # Flying and waiting retain exactly the same core blade, including animated shimmer.
    for v in 'ab':
        for f in range(4):
            fly=np.array(frame('rio_mana_sword',v,f))[8:25,30:92]
            wait=np.array(frame('rio_mana_sword_stuck',v,f))[8:25,30:92]
            # Waiting rune sparks are outside the blade body; ignore blank blade pixels.
            mask=fly[:,:,3]>0
            assert np.array_equal(fly[mask],wait[mask]),('blade core differs',v,f)
        checks.append(f'mana sword-{v}: flying/waiting blade pixels identical, 4/4')
    for p in REPORT.iterdir():
        if p.is_file() and p.suffix in {'.py','.ps1','.md','.txt','.json','.html'}:
            content=p.read_text(encoding='utf-8-sig')
            assert '\ufffd' not in content,p
            assert all(line==line.rstrip() for line in content.splitlines()),('trailing whitespace',p)
    write_json(REPORT/'measurements.json',metrics)
    write_text(REPORT/'validation.txt','\n'.join(checks)+'\n17 assets: size / RGBA / binary alpha / empty 1-px border / metadata PASS.\nNo Godot runtime test performed; boards are Pillow composites.')
    print('\n'.join(checks))
    print('17 assets PASS')


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('action',choices=['boards','validate','all'])
    args=parser.parse_args()
    if args.action in ('boards','all'): boards()
    if args.action in ('validate','all'): validate()
    manifest()
