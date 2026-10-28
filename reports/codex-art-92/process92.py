"""ART-89 normalizer adapter. All attempt files are new, under ignored raw directory."""
import os,sys,json,hashlib
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
import head_scale as h
from PIL import Image
R=Path('reports/codex-art-92'); RAW=Path('art/raw/motions-92')
forms={'frey':('frey',2),'luna':('luna',3),'luna_brave':('luna',4),'nova_male':('nova',2),'nova_female':('nova',2),'rio_male':('rio',2),'rio_female':('rio',2),'yuki':('yuki',2)}
stem,row,gen,factor,label=sys.argv[1:6]; factor=float(factor)
folder,v=forms[stem]; anchor=f'art/bakeoff/{folder}/{stem}-idle-v{v}.png'
out=RAW/f'{stem}-{row}'/label
assert not out.exists(),f'Refusing overwrite {out}'
cell=192 if row=='taunt' else 128
args=n.parser().parse_args(['--sheet',str(RAW/f'{stem}-{row}-{gen}.png'),'--grid','6x1','--bg','#00ff00','--cell',str(cell),'--scale-by',f'fixed:{factor}','--resample','lanczos','--sharpen','60','--despill','auto','--palette','none','--reference',anchor+':0:1','--compare-scale','4','--out-dir',str(out),'--name',f'{stem}-{row}','--ground-all'])
args.feet_y=cell//2+56;args.palette=None
metrics=n.normalize(args)
a=Image.open(anchor).convert('RGBA').crop((0,0,128,128));im=Image.open(out/f'{stem}-{row}.png').convert('RGBA')
frames=[im.crop((i*cell,0,(i+1)*cell,cell)) for i in range(6)]
n.render_anchor_candidates(a,frames,args.feet_y,4).save(out/'board.png')
if stem in ['yuki','nova_male','nova_female']:
 def tuned(a):
  r,g,b,al=[a[...,j].astype(int) for j in range(4)]
  return (al>0)&(r>180)&(g>125)&(b>105)&(r>g)&(g>b)&(r-b>12)&(r-b<120)
 h.skin_mask=tuned
head=h.measure(out/f'{stem}-{row}.png',h.head_template(a),6,.6)
with (out/'head-scale.json').open('x') as f:json.dump(head,f,indent=2)
with (out/'variant.json').open('x') as f:json.dump({'stem':stem,'row':row,'generation':int(gen),'factor':factor,'label':label,'anchor':anchor},f,indent=2)
print(json.dumps({'out':str(out),'summary':metrics['summary'],'head':head}))
