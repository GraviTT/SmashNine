"""Compare all three built-in edit attempts without altering the images."""
import json
import numpy as np
from PIL import Image
from check_faces import ROOT, REPORT, on_bg

a=Image.open(ROOT/'art/raw/faces-73/sources/frey_face.png').convert('RGBA')
aa=np.array(a)
outside=np.ones((256,256),bool)
outside[89:142,91:149]=False
rows=[]
for attempt in (1,2,3):
    b=Image.open(ROOT/f'art/raw/faces-73/frey-happy-try{attempt}.png').convert('RGBA').resize((256,256),Image.Resampling.LANCZOS)
    bb=np.array(b)
    delta=np.abs(np.array(on_bg(a)).astype(np.int16)-np.array(on_bg(b)).astype(np.int16))
    rows.append(dict(attempt=attempt,outside_rgba_changed_pixels=int((np.any(aa!=bb,axis=2)&outside).sum()),outside_display_delta_gt16_pixels=int(((delta.max(axis=2)>16)&outside).sum()),outside_display_mean_abs_channel_delta=round(float(delta[outside].mean()),4),alpha_changed_pixels=int((aa[:,:,3]!=bb[:,:,3]).sum()),new_alpha_on_neutral_transparent_pixels=int(((aa[:,:,3]==0)&(bb[:,:,3]>0)).sum()),new_alpha_gt16_on_neutral_transparent_pixels=int(((aa[:,:,3]==0)&(bb[:,:,3]>16)).sum())))
(REPORT/'frey-happy-attempts.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(rows,ensure_ascii=False,indent=2))
