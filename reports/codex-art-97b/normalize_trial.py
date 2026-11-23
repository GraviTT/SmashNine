from pathlib import Path
import sys,json,subprocess
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/sprite_pipeline'))
import head_scale as hs
import normalize as norm
raw,name,factor_s,grid,mode=sys.argv[1:6]
factor=float(factor_s)
out=ROOT/'reports/codex-art-97b'/name
anchor=Image.open(ROOT/'art/bakeoff/xion/b/xion-idle-b2.png').convert('RGBA').crop((0,0,128,128))
template=hs.head_template(anchor)
history=[]
for attempt in range(3):
    args=['--sheet',raw,'--grid',grid,'--bg','#00ff00','--cell','128','--scale-by',f'fixed:{factor}','--resample','lanczos','--sharpen','60','--despill','auto','--palette','none','--compare-scale','4','--out-dir',str(out),'--name','frame']
    if mode=='ground': args+=['--ground-all']
    elif mode.startswith('air'): args+=['--lift-all',mode.split(':')[1]]
    parsed=norm.parser().parse_args(args)
    parsed.palette=None
    parsed.feet_y=120
    result=norm.normalize(parsed)
    frames=[Image.open(p).convert('RGBA') for p in sorted((out/'frames').glob('*.png'))]
    heads=[hs.head_scale(f,template) for f in frames]
    good=[s for s,score in heads if s and score>=.6]
    import numpy as np
    median=float(np.median(good)) if good else None
    history.append({'factor':factor,'head':heads,'median':median,'used':len(good)})
    if median is None or .96<=median<=1.04: break
    if attempt<2: factor=round(factor/median,8)
board=norm.render_row([anchor,*frames],f'{name} 4X',120,4)
board.save(out/'review.png')
for i,f in enumerate(frames):
    norm.render_row([anchor,f],f'{name} F{i+1}',120,4).save(out/f'review-{i+1}.png')
    f.resize((512,512),Image.Resampling.NEAREST).save(out/f'ref-{i+1}-4x.png')
(out/'head.json').write_text(json.dumps({'history':history,'factor':factor,'frames':[{'scale':s,'score':sc} for s,sc in heads],'median':median,'used':len(good)},indent=2),encoding='utf-8')
print(json.dumps({'name':name,'factor':factor,'head':heads,'median':median,'used':len(good)},ensure_ascii=False))
