"""Measure generated drafts and render native/display-size review copies."""
from pathlib import Path
import json
import re
import numpy as np
from PIL import Image, ImageDraw
from check_faces import ROOT, REPORT, FORMS, EXPRESSIONS, on_bg, dialogue_preview

RAW = ROOT / 'art/raw/faces-73'
review = json.loads((REPORT / 'review.json').read_text(encoding='utf-8'))
rows=[]
for folder, stem in FORMS:
    neutral=Image.open(RAW/'sources'/f'{stem}_face.png').convert('RGBA')
    board=Image.new('RGB',(1088,530),(23,29,40))
    draw=ImageDraw.Draw(board)
    draw.text((16,8),f'{stem} GENERATED DRAFTS | NOT DELIVERED | 256x256 / 142x164',fill='white')
    for col,expr in enumerate(['neutral']+EXPRESSIONS):
        x=16+272*col
        if expr=='neutral':
            im=neutral
        else:
            paths=sorted(RAW.glob(f'{stem}-{expr}-try[123].png'))
            if not paths:
                draw.text((x,32),expr+' PENDING',fill='white')
                continue
            selected=review[stem].get('selected_tries',{}).get(expr)
            path=RAW/f'{stem}-{expr}-try{selected}.png' if selected else paths[-1]
            raw=Image.open(path)
            im=raw.convert('RGBA').resize((256,256),Image.Resampling.LANCZOS)
            a,b=np.array(neutral),np.array(im)
            x0,y0,x1,y1=review[stem]['face_bounds']
            outside=np.ones((256,256),bool)
            outside[y0:y1,x0:x1]=False
            changed=np.any(a!=b,axis=2)
            visible=(a[:,:,3]>0)|(b[:,:,3]>0)
            rgb_delta=np.abs(a[:,:,:3].astype(np.int16)-b[:,:,:3].astype(np.int16)).max(axis=2)
            rows.append(dict(form=stem,expression=expr,raw=str(path.relative_to(ROOT)).replace('\\','/'),raw_size=list(raw.size),raw_mode=raw.mode,tries=len(paths),outside_face_changed_pixels=int((changed&outside).sum()),outside_face_changed_pct=round(float((changed&outside).sum()/outside.sum()*100),4),outside_face_visible_delta_gt16_pixels=int(((rgb_delta>16)&outside&visible).sum()),alpha_changed_pixels=int((a[:,:,3]!=b[:,:,3]).sum()),painted_on_neutral_transparent_pixels=int(((a[:,:,3]==0)&(b[:,:,3]>0)).sum())))
        draw.text((x,32),expr,fill='white')
        board.paste(on_bg(im),(x,54))
        board.paste(on_bg(dialogue_preview(im)),(x+57,340))
    board.save(RAW/f'{stem}-raw-check.png')
(REPORT/'raw-measurements.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(rows,ensure_ascii=False,indent=2))
