from pathlib import Path
import sys,json
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/sprite_pipeline'))
import walk_bob as bob
import walk_feet as feet
import normalize as norm
O=ROOT/'reports/codex-art-97b'
selected=['walk-f1','walk-f2','walk-f3-a3','walk-f4','walk-f5','walk-f6-a2','walk-f7-a2','walk-f8']
frames=[Image.open(O/name/'ref-1-4x.png').convert('RGBA').resize((128,128),Image.Resampling.NEAREST) for name in selected]
arrays=[np.asarray(f) for f in frames]
Image.fromarray(np.concatenate(arrays,axis=1)).save(O/'walk-before-bob.png')
box=(65,36,80,50)
offsets=[bob.head_offset(arrays[0],f,box) for f in arrays]
target,shifts=bob.fit_target([x[0] for x in offsets],(0,2,-1,-2))
f=[feet.feet(a[...,3]>0) for a in arrays]
pred={'face_box':box,'offsets':offsets,'target':target,'shifts':shifts,'feet':f}
(O/'walk-precheck.json').write_text(json.dumps(pred,indent=2),encoding='utf-8')
print(json.dumps(pred))
anchor=Image.open(ROOT/'art/bakeoff/xion/b/xion-idle-b2.png').crop((0,0,128,128))
for i in range(4):
    norm.render_row([anchor,*frames[i*2:i*2+2]],f'WALK {i*2+1}-{i*2+2}',120,4).save(O/f'walk-pair-{i+1}.png')
feet.onion(arrays,80,O/'onion.png')
