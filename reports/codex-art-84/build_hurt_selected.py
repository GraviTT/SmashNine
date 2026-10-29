"""Selected hurt candidates: Yuki generated attempt 2; Rio attempt 1."""
import copy, hashlib, json
from build_hurt import *

if __name__=='__main__':
    dest=RAW/'hurt-selected'; dest.mkdir(exist_ok=False)
    src=Path('C:/Users/TH/.codex/generated_images/01a172a6-2741-7742-9613-eeca78f7635a/exec-46fa959e-2a88-48d7-b9dd-50a56403e2e9.png')
    data=src.read_bytes()
    with (RAW/'yuki-hurt-generated-2.png').open('xb') as f: f.write(data)
    records=[]; configs={}
    for stem,attempt in [('yuki',2),('rio_male',1)]:
        cfg=copy.deepcopy(old.FORMS[stem])
        if stem=='yuki':
            # A four-pixel skin margin keeps the entire generated bead inside
            # the full-opacity area rather than fading its outline away.
            cfg['expression_features']['hurt']['sweat']=[[94,113],[103,110],[109,116],[109,126],[99,130],[94,124]]
        configs[stem]=cfg
        n=Image.open(RAW/f'{stem}-neutral.png').convert('RGBA')
        edit=Image.open(RAW/f'{stem}-hurt-generated-{attempt}.png').convert('RGBA').resize((256,256),Image.Resampling.LANCZOS)
        offset,scores,roi=old.align(n,edit,cfg)
        aligned=old.shift(edit,offset); mask=old.mask_for(cfg,'hurt'); out=old.make_composite(n,aligned,mask)
        record=dict(stem=stem,expression='hurt',selected_attempt=attempt,offset=offset,alignment_roi_pixels=roi,**old.measure(n,aligned,out,mask))
        records.append(record)
        save(out,dest/f'{stem}-hurt.png'); save(mask,dest/f'{stem}-hurt-mask.png'); save(aligned,dest/f'{stem}-hurt-aligned.png')
        save(board(stem,'hurt',n,Image.open(RAW/f'{stem}-hurt-v1.png').convert('RGBA'),out),dest/f'{stem}-hurt-board.png')
        crop=cfg['crop']; w=(crop[2]-crop[0])*4; h=(crop[3]-crop[1])*4
        seam=Image.new('RGB',(w*4,h+45),'#151621')
        for i,(name,im) in enumerate([('neutral',n),('aligned edit',aligned),('composite',out),('mask',mask.convert('RGBA'))]):
            text(seam,(i*w+4,5),name,14); seam.paste(old.on_bg(im).crop(crop).resize((w,h),Image.Resampling.NEAREST),(i*w,40))
        save(seam,dest/f'{stem}-hurt-seam.png')
        dump(dest/f'{stem}-alignment-scores.json',scores)
    dump(dest/'config.json',configs); dump(dest/'measurements.json',records)
    dump(dest/'generation-2.json',{'source':str(src),'sha256':hashlib.sha256(data).hexdigest()})
    print(json.dumps(records,indent=2))
