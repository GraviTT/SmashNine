"""ART-84 Part 1: generated neutral edits, ART-73 alignment and finite masks.
Drafts go only in an exclusive new raw subdirectory. No product writes.
"""
from pathlib import Path
import importlib.util, json, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
REPORT=Path(__file__).resolve().parent
RAW=ROOT/'art/raw/faces-84'
spec=importlib.util.spec_from_file_location('art73',ROOT/'reports/codex-art-73/composite_faces.py')
old=importlib.util.module_from_spec(spec); spec.loader.exec_module(old)
FONT='C:/Windows/Fonts/malgun.ttf'

def dump(p,obj):
    with p.open('x',encoding='utf-8',newline='\n') as f: json.dump(obj,f,ensure_ascii=False,indent=2); f.write('\n')

def save(im,p):
    with p.open('xb') as f: im.save(f,format='PNG')

def text(im,xy,s,size=17):
    ImageDraw.Draw(im).text(xy,s,font=ImageFont.truetype(FONT,size),fill='#e6dfef')

def board(stem,expression,neutral,before,after):
    b=Image.new('RGBA',(900,1040),'#151621')
    text(b,(18,10),f'{stem} · {expression} · v1 → v2 후보 (Godot 실행 화면 아님)',22)
    for i,(label,im) in enumerate([('중립',neutral),('v1',before),('v2',after)]):
        x=20+290*i
        text(b,(x,48),label+' / 256×256 · 1배')
        b.alpha_composite(im,(x,78))
        text(b,(x,348),'142×164 영역 · 등비 축소')
        b.alpha_composite(old.dialogue_preview(im),(x+57,379))
    for j,(ver,im) in enumerate([('v1',before),('v2',after)]):
        y=580+j*218
        text(b,(20,y),f'{ver} 대화 모사 / 주인공 왼쪽 · 발화자 오른쪽')
        ImageDraw.Draw(b).rounded_rectangle((20,y+30,880,y+205),10,fill='#242138',outline='#716180',width=2)
        hero=neutral if expression=='shadow' else Image.open(RAW/'frey-neutral.png').convert('RGBA')
        b.alpha_composite(old.dialogue_preview(hero),(28,y+36))
        b.alpha_composite(old.dialogue_preview(im),(730,y+36))
        text(b,(190,y+55),('그림자 ' if expression=='shadow' else '')+old.FORMS[stem]['label'],21)
        text(b,(190,y+102),'네가 끝까지 버틸 수 있을까.' if expression=='shadow' else '윽… 아직 버틸 수 있어.',20)
        text(b,(190,y+150),'추가 틴트 없음 · 비교용 목업',15)
    return b.convert('RGB')

def run(dest):
    dest.mkdir(parents=True,exist_ok=False)
    records=[]
    for stem in ['yuki','rio_male']:
        cfg=old.FORMS[stem]
        n=Image.open(RAW/f'{stem}-neutral.png').convert('RGBA')
        edit=Image.open(RAW/f'{stem}-hurt-generated-1.png').convert('RGBA').resize((256,256),Image.Resampling.LANCZOS)
        mask=old.mask_for(cfg,'hurt')
        offset,scores,roi=old.align(n,edit,cfg)
        aligned=old.shift(edit,offset)
        out=old.make_composite(n,aligned,mask)
        m=old.measure(n,aligned,out,mask)
        record=dict(stem=stem,expression='hurt',offset=offset,alignment_roi_pixels=roi,**m)
        records.append(record)
        save(out,dest/f'{stem}-hurt.png'); save(mask,dest/f'{stem}-hurt-mask.png')
        save(aligned,dest/f'{stem}-hurt-aligned.png')
        save(board(stem,'hurt',n,Image.open(RAW/f'{stem}-hurt-v1.png').convert('RGBA'),out),dest/f'{stem}-hurt-board.png')
        crop=cfg['crop']; w=(crop[2]-crop[0])*4; h=(crop[3]-crop[1])*4
        seam=Image.new('RGB',(w*4,h+45),'#151621')
        for i,(name,im) in enumerate([('neutral',n),('aligned edit',aligned),('composite',out),('mask',mask.convert('RGBA'))]):
            text(seam,(i*w+4,5),name,14)
            seam.paste(old.on_bg(im).crop(crop).resize((w,h),Image.Resampling.NEAREST),(i*w,40))
        save(seam,dest/f'{stem}-hurt-seam.png')
        dump(dest/f'{stem}-alignment-scores.json',scores)
    dump(dest/'measurements.json',records)
    print(json.dumps(records,indent=2))

if __name__=='__main__': run(RAW/(sys.argv[1] if len(sys.argv)>1 else 'hurt-pass1'))
