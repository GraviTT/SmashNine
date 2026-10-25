"""Normalize image_gen ornament to exact 9-slice geometry; no game writes."""
from pathlib import Path
import json
import hashlib
import numpy as np
from PIL import Image, ImageDraw, ImageOps
from audit import ROOT, OUT, font, checker, nine_audit, jpg

RAW=ROOT/'art/raw/story/start_card_frame-v1_raw.png'
DEST=ROOT/'art/bakeoff/story/start_card_frame-v1.png'
PALETTE=['#f3cd7c','#a8742c','#3d7bd9','#9fd2ff','#101827']

def nine(im, size, margin=24):
    out=Image.new('RGBA',size)
    sx=[0,margin,im.width-margin,im.width]; sy=[0,margin,im.height-margin,im.height]
    dx=[0,margin,size[0]-margin,size[0]]; dy=[0,margin,size[1]-margin,size[1]]
    for y in range(3):
        for x in range(3):
            tile=im.crop((sx[x],sy[y],sx[x+1],sy[y+1]))
            tile=tile.resize((dx[x+1]-dx[x],dy[y+1]-dy[y]),Image.Resampling.NEAREST)
            out.paste(tile,(dx[x],dy[y]))
    return out

def main():
    assert not DEST.exists()
    raw=Image.open(RAW).convert('RGBA')
    # A single generated leaf-wing/diamond ornament, including the corner join.
    crop=(0,70,100,170)
    corner=raw.crop(crop).resize((22,22),Image.Resampling.NEAREST)
    a=np.asarray(corner).copy()
    pal=np.array([tuple(bytes.fromhex(c[1:])) for c in PALETTE],dtype=float)
    rgb=a[:,:,:3].astype(float)
    idx=((rgb[:,:,None,:]-pal[None,None,:,:])**2).sum(axis=3).argmin(axis=2)
    a[:,:,:3]=pal[idx].astype(np.uint8);a[:,:,3]=np.where(a[:,:,3]>=180,255,0)
    a[a[:,:,3]==0]=0
    corner=Image.fromarray(a)
    out=Image.new('RGBA',(480,300));d=ImageDraw.Draw(out)
    # Uniform one-pixel rows/columns; the drawing is only border construction.
    for inset,color in [(6,'#101827'),(7,'#f3cd7c'),(8,'#a8742c'),(9,'#101827'),(10,'#3d7bd9'),(11,'#101827')]:
        d.line((23,inset,456,inset),fill=color,width=1)
        d.line((23,299-inset,456,299-inset),fill=color,width=1)
        d.line((inset,23,inset,276),fill=color,width=1)
        d.line((479-inset,23,479-inset,276),fill=color,width=1)
    out.alpha_composite(corner,(1,1));out.alpha_composite(ImageOps.mirror(corner),(457,1))
    out.alpha_composite(ImageOps.flip(corner),(1,277));out.alpha_composite(ImageOps.flip(ImageOps.mirror(corner)),(457,277))
    DEST.parent.mkdir(parents=True,exist_ok=True);out.save(DEST)
    metrics=nine_audit(out,24)
    assert metrics['centre_fully_transparent'] and metrics['opaque_pixels_outside_margins']==0
    assert all(metrics[k] for k in ['horizontal_top_repeatable','horizontal_bottom_repeatable','vertical_left_repeatable','vertical_right_repeatable'])
    meta={'task':'SART-03','status':'candidate','note_ko':'대화 틀과 같은 금색 잎날개·청색 마름모 계열의 시작 카드 후보. image_gen 코너를 추출하고 정확한 24px 9-slice 직선부를 구성했다. 게임 미반영.',
          'size':[480,300],'nine_slice_margins_LTRB':[24,24,24,24],'palette':PALETTE,
          'raw':str(RAW.relative_to(ROOT)).replace('\\','/'),'raw_sha256':hashlib.sha256(RAW.read_bytes()).hexdigest(),
          'processing':{'corner_crop_xyxy':list(crop),'corner_resize':[22,22],'filter':'NEAREST','alpha_threshold':180,'corner_placements':[[1,1],[457,1],[1,277],[457,277]],'palette_mapping':'nearest RGB squared distance','straight_edges':'Pillow 1px uniform gold/blue double lines; no centre gem'},
          'metrics':metrics,'human_judgment_ko':'원본 대화 틀과 코너 장식 밀도·크기, 900×520에서의 금/청색 선 두께와 연결부를 판단해 주세요.'}
    DEST.with_suffix('.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    # 1280x720 layout preview: actual 900x520 target, sample text is separate.
    bg=Image.open(ROOT/'smash-nine-prototype/assets/art/story/cg_root.png').resize((1280,720),Image.Resampling.LANCZOS).convert('RGBA')
    dark=Image.new('RGBA',bg.size,(4,10,20,150));bg=Image.alpha_composite(bg,dark)
    backing=Image.new('RGBA',(888,508),(16,24,39,250));bg.alpha_composite(backing,(196,104))
    bg.alpha_composite(nine(out,(900,520)),(190,98))
    bd=ImageDraw.Draw(bg)
    bd.text((348,120),'스테이지 3',fill='#f3cd7c',font=font(28))
    bd.text((348,164),'달빛 다리',fill='white',font=font(38))
    bd.text((224,244),'알프헤임',fill='#f3cd7c',font=font(24))
    bd.text((224,294),'빛을 따라 다음 렐름으로 이동하세요.',fill='white',font=font(24))
    bd.text((224,364),'9-slice 24px · 900×520 · Pillow 예시',fill='#aebbd0',font=font(19))
    bd.rectangle((490,550,790,598),fill='#1f304b',outline='#a8742c',width=1)
    bd.text((640,560),'시작하기',fill='white',font=font(24),anchor='mt')
    bd.text((24,18),'SART-03 시작 카드 후보 — 합성 검토 화면 / 게임 실행 화면 아님',fill='#f3cd7c',font=font(22))
    jpg('start-card-preview-1280-v1.jpg',bg)
    sheet=Image.new('RGB',(1200,710),'#101827');sd=ImageDraw.Draw(sheet)
    sd.text((24,14),'시작 카드 480×300 / 코너 24×24 / 중앙 완전 투명',fill='white',font=font(24))
    native=checker(out.size);native.alpha_composite(out);nd=ImageDraw.Draw(native)
    for x in [24,456]:nd.line((x,0,x,299),fill='#ff80bd')
    for y in [24,276]:nd.line((0,y,479,y),fill='#ff80bd')
    sheet.paste(native.convert('RGB'),(24,64))
    ref=Image.open(ROOT/'smash-nine-prototype/assets/art/story/dialogue_frame.png').convert('RGBA')
    rb=checker(ref.size);rb.alpha_composite(ref);sheet.paste(rb.convert('RGB'),(24,410))
    sd.text((24,556),'기존 대화 틀 480×120 (읽기 전용)',fill='#9fd2ff',font=font(22))
    c=checker((24,24));c.alpha_composite(out.crop((0,0,24,24)));sheet.paste(c.resize((288,288),Image.Resampling.NEAREST).convert('RGB'),(640,64))
    sd.text((640,374),'생성 코너 12× / 분홍 선=슬라이스 경계',fill='#9fd2ff',font=font(22))
    sd.text((640,430),'팔레트',fill='white',font=font(22))
    for i,color in enumerate(PALETTE):
        sd.rectangle((640+i*100,472,718+i*100,510),fill=color)
        sd.text((640+i*100,520),color,fill='white',font=font(16))
    jpg('start-card-frame-spec-v1.jpg',sheet)
    print(json.dumps(meta,ensure_ascii=False,indent=2))

if __name__=='__main__':main()
