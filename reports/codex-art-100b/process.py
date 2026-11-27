"""D35 normalization + head measurements, never change the source drawings."""
from pathlib import Path
import argparse, importlib.util, json
import numpy as np
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/'reports/codex-art-100b';RAW=ROOT/'art/raw/jupi-100b'
def module(name):
    spec=importlib.util.spec_from_file_location(name,ROOT/f'tools/sprite_pipeline/{name}.py')
    mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod);return mod
n=module('normalize');h=module('head_scale')
anchor=Image.open(RAW/'anchor.png').convert('RGBA')
def board(frames,labels,path,cols=3):
    s=4;cw=512;ch=544
    out=Image.new('RGBA',(cw*cols,ch*((len(frames)+cols-1)//cols)),(37,42,52,255));d=ImageDraw.Draw(out)
    for i,(f,label) in enumerate(zip(frames,labels)):
        x=(i%cols)*cw;y=(i//cols)*ch
        tile=n.checker((128,128),8).convert('RGBA');tile.alpha_composite(f)
        out.alpha_composite(tile.resize((512,512),Image.Resampling.NEAREST),(x,y+32))
        d.text((x+10,y+9),label,fill='white')
    out.convert('RGB').save(path)
def run(args):
    out=REPORT/args.name;out.mkdir(parents=True,exist_ok=True)
    argv=['--sheet',str(RAW/f'{args.name}.png'),'--grid',f'{args.count}x1','--cell','128','--bg','#00ff00','--scale-by',f'fixed:{args.factor}','--resample','lanczos','--sharpen','60','--despill','auto','--palette','none','--compare-scale','4','--out-dir',str(out),'--name',args.name]
    if args.air: argv+=['--lift-all',str(args.lift)]
    else: argv+=['--ground-all']
    normargs=n.parser().parse_args(argv);normargs.palette=None;normargs.feet_y=120
    fixed=None
    if args.shared:
        frames,_=n.split_sheet(RAW/f'{args.name}.png',(args.count,1))
        default=[n.torso_anchor_x(n.clean_background(f,'#00ff00')[0]) for f in frames]
        fixed=float(np.median(default));n.torso_anchor_x=lambda _:fixed
    metrics=n.normalize(normargs)
    frames=[Image.open(p).convert('RGBA') for p in sorted((out/'frames').glob('*.png'))]
    strip=Image.new('RGBA',(128*len(frames),128))
    for i,f in enumerate(frames):strip.alpha_composite(f,(i*128,0))
    strip.save(out/'strip.png')
    template=h.head_template(anchor)
    heads=[h.head_scale(f,template) for f in frames]
    good=[scale for scale,score in heads if scale is not None and score>=0.6]
    result={'name':args.name,'factor':args.factor,'fixed_anchor_x':fixed,'heads':[{'scale':s,'score':round(c,4)} for s,c in heads],'median':float(np.median(good)) if good else None,'used':len(good),'anchor_detail':n.interior_detail(anchor),'frames':[n.frame_metrics(f) for f in frames]}
    (out/'review.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    board([anchor]+frames,['ANCHOR']+[f'{args.name} F{i+1}' for i in range(len(frames))],out/'review-4x.png')
    if len(frames)==1:frames[0].resize((512,512),Image.Resampling.NEAREST).save(RAW/f'{args.name}-4x.png')
    print(json.dumps(result,ensure_ascii=True))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('name');p.add_argument('count',type=int);p.add_argument('factor',type=float);p.add_argument('--air',action='store_true');p.add_argument('--lift',type=int,default=8);p.add_argument('--shared',action='store_true');run(p.parse_args())
