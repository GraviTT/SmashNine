"""ART-88: create reviewable row candidates within the report before delivery."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, importlib.util
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from audit import ROOT, OUT, BAKE, metrics, digest
spec=importlib.util.spec_from_file_location('normalizer88',ROOT/'tools/sprite_pipeline/normalize.py')
n=importlib.util.module_from_spec(spec);spec.loader.exec_module(n)
FONT=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',17)
def dump(p,d): p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n','utf-8')
def move(im,dx,dy):
    b=im.getbbox(); assert b[0]+dx>=0 and b[1]+dy>=0 and b[2]+dx<=96 and b[3]+dy<=96
    out=Image.new('RGBA',(96,96));out.paste(im,(dx,dy));return out
def fit_x(im):
    b=im.getbbox();assert b[2]-b[0]<=88
    return max(4-b[0],min(0,92-b[2]))
def scale_frame(im,s):
    b=im.getbbox();sub=im.crop(b)
    sub=sub.resize((round(sub.width*s),round(sub.height*s)),Image.Resampling.LANCZOS)
    sub=n.apply_unsharp(sub,60)
    sub.putalpha(sub.getchannel('A').point(lambda a:255 if a>=128 else 0))
    sub=sub.crop(sub.getbbox())
    x=round((b[0]+b[2]-sub.width)/2);y=b[3]-sub.height
    out=Image.new('RGBA',(96,96));out.paste(sub,(x,y));return out
def board(path,title,before,after,indices):
    for previous in OUT.glob(path.stem+'-*.png'):
        previous.unlink()
    for page,start in enumerate(range(0,len(indices),3),1):
        selected=indices[start:start+3]
        im=Image.new('RGB',(1200,880),(24,29,40));d=ImageDraw.Draw(im)
        d.text((12,8),title+' | NEAREST 4x | BEFORE / AFTER',font=FONT,fill='white')
        for j,i in enumerate(selected):
            for ri,frames in enumerate([before,after]):
                x=10+j*398;y=65+ri*415
                cell=Image.new('RGBA',(384,384),(39,44,56,255));cell.alpha_composite(frames[i].resize((384,384),Image.Resampling.NEAREST))
                im.paste(cell.convert('RGB'),(x,y));d.rectangle((x+16,y+16,x+367,y+367),outline='#647d8b')
                d.line((x,y+292,x+383,y+292),fill='#ce718c')
                m=metrics(frames[i])['solid'];d.text((x,y-24),f'F{i+1} min={m["minimum_margin"]}px; band={m["inside_4px"]}px',font=FONT,fill='white')
        im.save(path.with_name(path.stem+f'-{page}.png'))
def wolf_reslice(old):
    raw=ROOT/'art/raw/monsters-76/niflheim_glacier_wolf-hurt.png'
    frames,_=n.split_sheet(raw,(2,1));clean,_=n.clean_background(frames[0],'#00ff00')
    b=clean.getbbox();pad=40
    # Include transparent context around the entire creature while resampling.
    # Tight bbox resampling extends its top-edge colour into a horizontal cap.
    subject=clean.crop((b[0]-pad,b[1]-pad,b[2]+pad,b[3]+pad))
    sub=subject.resize((round(subject.width*.105),round(subject.height*.105)),Image.Resampling.LANCZOS)
    sub=n.apply_unsharp(sub,60);sub.putalpha(sub.getchannel('A').point(lambda a:255 if a>=128 else 0))
    sub=n.despill_green_edge(sub,'auto');sub=sub.crop(sub.getbbox())
    ob=old.getbbox();x=round((ob[0]+ob[2]-sub.width)/2);y=73-sub.height
    out=Image.new('RGBA',(96,96));out.paste(sub,(x,y));out=n.despill_green_edge(out,'auto')
    raw_board=Image.new('RGB',(1180,620),(24,29,40));d=ImageDraw.Draw(raw_board)
    d.text((12,8),'C09 raw F1 (whole cell, scaled to 560) / raw top detail 1x',font=FONT,fill='white')
    raw_board.paste(frames[0].convert('RGB').resize((560,560),Image.Resampling.LANCZOS),(10,45))
    raw_board.paste(frames[0].crop((350,165,850,465)).convert('RGB'),(590,80))
    raw_board.save(OUT/'C09-raw-evidence.png')
    return out,dict(path=raw.relative_to(ROOT).as_posix(),sha256=digest(raw),cell_box=[0,0,887,887],alpha_bbox=list(b),transparent_context_px=pad,factor=.105,source_complete_visual_judgment=True)
def slinger_raw(before):
    raw=ROOT/'art/raw/monsters-74/midgard_rooftop_slinger-defeat.png'
    sources,_=n.split_sheet(raw,(2,2));result=[]
    for old,source in zip(before,sources):
        clean,_=n.clean_background(source,'#00ff00')
        im,_,_=n.normalize_frame(clean,.165,0,None,'off','lanczos',60,'auto',0,True,0,1,256,180)
        sub=im.crop(im.getbbox());ob=old.getbbox()
        x=round((ob[0]+ob[2]-sub.width)/2);y=73-sub.height
        out=Image.new('RGBA',(96,96));out.paste(sub,(x,y));result.append(out)
    return result,dict(path=raw.relative_to(ROOT).as_posix(),sha256=digest(raw),factor=.165,method='whole raw frames; common factor; existing D35 normalizer')
def main():
    base=json.loads((OUT/'baseline.json').read_text('utf-8'))
    stage=OUT/'review-rows';stage.mkdir(exist_ok=True)
    before_dir=OUT/'before';before_dir.mkdir(exist_ok=True)
    results=[]
    for c in base['cases']:
        src=ROOT/c['versions']['latest']['path'];meta=c['versions']['latest']['metadata'].copy()
        saved_source=before_dir/src.name
        im=Image.open(saved_source if saved_source.exists() else src).convert('RGBA');count=meta['frames']
        before=[im.crop((i*96,0,(i+1)*96,96)) for i in range(count)]
        after=[x.copy() for x in before];ops=[];unresolved=[];s=1.0;rawinfo=None
        if max(x.getbbox()[2]-x.getbbox()[0] for x in before)>88:
            s={'C01':.988,'C07':.98,'C14':.98,'C15':.165/.167}[c['id']]
            if c['id']=='C15':after,rawinfo=slinger_raw(before)
            else:after=[scale_frame(x,s) for x in before]
            meta['factor']=round(meta['factor']*s,9)
        if c['id']=='C09':after[0],rawinfo=wolf_reslice(before[0])
        for i,frame in enumerate(after):
            b=frame.getbbox();dx=fit_x(frame);dy=0
            if b[1]<4:
                if c['id'] in ('C08','C22'):
                    unresolved.append(dict(frame=i+1,reason='grounded height 70 > available 69; feet y72; width <=88 so card does not authorize shrinking'))
                else:dy=4-b[1]
            if dx or dy:after[i]=move(frame,dx,dy)
            ops.append(dict(frame=i+1,scale=s,dx=dx,dy=dy,before=metrics(before[i]),after=metrics(after[i]),changed=not np.array_equal(before[i],after[i])))
        changed=[i for i,o in enumerate(ops) if o['changed']]
        target=BAKE/f'{c["monster"]}-{c["row"]}-v2.png'
        if changed:
            saved=before_dir/src.name
            if not saved.exists():saved.write_bytes(src.read_bytes())
            full=Image.new('RGBA',(576,96))
            for i,frame in enumerate(after):full.paste(frame,(96*i,0))
            full.save(stage/target.name)
            details='; '.join(f'F{o["frame"]} 여백 {o["before"]["solid"]["minimum_margin"]}→{o["after"]["solid"]["minimum_margin"]}px, 경계 픽셀 {o["before"]["solid"]["inside_4px"]}→{o["after"]["solid"]["inside_4px"]}' for o in ops if o['changed'])
            meta['note']=meta.get('note','')+f' ART-88 {c["id"]}: '+details+'.'
            if s!=1:meta['note']+=f' 최대 폭 88px 초과로 행 공통 배율 ×{s}.'
            if c['id']=='C09':meta['note']+=' 온전한 ART-76 원본 F1 전체를 투명 여백 포함 재슬라이스; 상단 직선 8→5px. 머리 조각 붙이기 없음.'
            elif rawinfo:meta['note']+=' ART-74 원본 전 프레임에서 공통 factor 0.165로 재구축.'
            if unresolved:meta['note']+=' F1 상단 여백 3px는 접지와 축소 허용 조건 충돌로 유지(미해결).'
            meta['replaces']=f'{c["monster"]}-{c["row"]}-v1.png'
            dump(stage/target.with_suffix('.json').name,meta)
            board(OUT/f'{c["id"]}-changed-4x.png',f'{c["id"]} {c["monster"]} {c["row"]}',before,after,changed)
        if unresolved:board(OUT/f'{c["id"]}-unresolved-4x.png',c['id']+' unchanged F1: top=3 and feet=72',before,after,[x['frame']-1 for x in unresolved])
        if c['id']=='C06':
            qa=Image.open(ROOT/c['versions']['qa_v1']['path']).convert('RGBA')
            qa_frames=[qa.crop((i*96,0,(i+1)*96,96)) for i in range(count)]
            board(OUT/'C06-already-fixed-4x.png','C06 QA v1 / ART-83 v2 (unchanged by ART-88)',qa_frames,after,[2,3])
        result=dict(id=c['id'],monster=c['monster'],row=c['row'],source=src.relative_to(ROOT).as_posix(),output=target.relative_to(ROOT).as_posix() if changed else None,changed_frames=[i+1 for i in changed],operations=ops,scale=s,unresolved=unresolved,raw=rawinfo)
        results.append(result)
        print(c['id'], 'changed',result['changed_frames'],'scale',s,'unresolved',len(unresolved), 'min',[o['after']['solid']['minimum_margin'] for o in ops])
    dump(OUT/'repairs.json',results)
if __name__=='__main__':main()
