"""ART-100a: ART-96b shared-anchor wrapper around the unchanged normalizer."""
from pathlib import Path
import argparse, importlib.util, json, statistics
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/'reports/codex-art-100a'
RAW=ROOT/'art/raw/jupi-100a'
ANCHOR=ROOT/'art/bakeoff/newchar-2026-11-26/jupi/2/jupi-idle-2.png'
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
n=module('normalizer',ROOT/'tools/sprite_pipeline/normalize.py')
h=module('heads',ROOT/'tools/sprite_pipeline/head_scale.py')
def dump(path,value):
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def runs(mask):
    out=[];start=None
    for x,v in enumerate(list(mask)+[False]):
        if v and start is None:start=x
        elif not v and start is not None:out.append([start,x-1]);start=None
    return out
def feet(frame,depth=4):
    bottom=n.alpha_bbox(frame)[3]-1
    bands=runs((np.asarray(frame.getchannel('A'))[bottom-depth+1:bottom+1]>0).any(axis=0))
    return {'bottom':bottom,'runs':bands,'centres':[sum(x)/2 for x in bands]}
def board(frames,labels,path,cell):
    # Two rows, four columns retains actual 4x pixels when opened at original resolution.
    tile=cell*4;pad=34
    out=n.checker((4*tile,2*(tile+pad)),24);d=ImageDraw.Draw(out)
    f=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',19)
    for i,(im,label) in enumerate(zip(frames,labels)):
        x=(i%4)*tile;y=(i//4)*(tile+pad)
        d.text((x+10,y+7),label,font=f,fill='white')
        out.paste(im.resize((tile,tile),Image.Resampling.NEAREST),(x,y+pad),im.resize((tile,tile),Image.Resampling.NEAREST))
        floor=(cell//2+57)*4
        d.line((x,y+pad+floor,x+tile-1,y+pad+floor),fill=(82,170,218),width=1)
    out.save(path)
def main():
    p=argparse.ArgumentParser();p.add_argument('row');p.add_argument('--attempt',type=int,default=1);p.add_argument('--factor',type=float,required=True);p.add_argument('--anchor-x',type=float);p.add_argument('--offset-x',type=int,default=0);a=p.parse_args()
    cell=192 if a.row in ('victory','defeat') else 128
    source=RAW/f'{a.row}-{a.attempt}.png';out=REPORT/f'{a.row}-normalized';out.mkdir(exist_ok=True)
    raw,labels=n.split_sheet(source,(6,1));clean=[n.clean_background(f,'#00ff00')[0] for f in raw]
    n.validate_source_cell_margin(clean,labels)
    boot=[feet(f,round(4/a.factor)) for f in clean]
    # ONE row-wide source coordinate; never move a frame separately.
    fixed=a.anchor_x if a.anchor_x is not None else statistics.median(n.torso_anchor_x(f) for f in clean)
    default=[n.torso_anchor_x(f) for f in clean];n.torso_anchor_x=lambda _frame:fixed
    args=n.parser().parse_args(['--sheet',str(source),'--grid','6x1','--cell',str(cell),'--feet-y',str(cell//2+56),'--bg','#00ff00','--scale-by',f'fixed:{a.factor}','--ground-all','--resample','lanczos','--sharpen','60','--despill','auto','--palette','none','--offset-x',str(a.offset_x),'--reference',str(ANCHOR)+':0:1','--compare-scale','4','--title',f'JUPI {a.row.upper()}','--out-dir',str(out),'--name',a.row])
    args.palette=None;m=n.normalize(args)
    m['normalization'].update({'horizontal_anchor':'one shared source-grid x for whole row','fixed_source_anchor_x':fixed,'rejected_default_anchors':default,'source_boot_bands':boot})
    dump(out/'metrics.json',m)
    sh=Image.open(out/f'{a.row}.png').convert('RGBA');frames=[sh.crop((i*cell,0,(i+1)*cell,cell)) for i in range(6)]
    anc=Image.open(ANCHOR).convert('RGBA')
    if a.row=='idle':
        # Explicit card requirement: replace WHOLE F1 with unchanged anchor. No body parts copied.
        frames[0]=anc.copy();n.save_sheet(frames,out/f'{a.row}.png',cell)
    ref=Image.new('RGBA',(cell,cell));ref.paste(anc,((cell-128)//2,(cell-128)//2))
    board([ref,*frames],['ANCHOR']+[f'{a.row.upper()} F{i+1}' for i in range(6)],REPORT/f'{a.row}.png',cell)
    # Individual 4x frames for unscaled inspection, no hidden reduction by a wide board.
    review=REPORT/f'{a.row}-4x';review.mkdir(exist_ok=True)
    for i,fr in enumerate(frames):
        bg=n.checker((cell*4,cell*4),24);v=fr.resize((cell*4,cell*4),Image.Resampling.NEAREST);bg.paste(v,(0,0),v);bg.save(review/f'F{i+1}.png')
    detail0=n.interior_detail(anc)
    data={'row':a.row,'attempt':a.attempt,'factor':a.factor,'fixed_source_anchor_x':fixed,'offset_x':a.offset_x,'anchor_detail':detail0,'frames':[]}
    for i,fr in enumerate(frames):
        box=n.alpha_bbox(fr);fm=n.frame_metrics(fr);data['frames'].append({'frame':i+1,'bbox':list(box),'margin':n.margins(box,cell),'alpha_binary':set(fr.getchannel('A').getdata())<={0,255},'border_clear':min(box[0],box[1],cell-box[2],cell-box[3])>0,**fm,'detail_ratio':round(fm['interior_detail']/detail0,4),'feet_band':feet(fr)})
    data['head']=h.measure(out/f'{a.row}.png',h.head_template(anc),6,0.6)
    data['anchor_unchanged']=bool(np.array_equal(np.asarray(frames[0]),np.asarray(anc))) if a.row=='idle' else None
    dump(REPORT/f'{a.row}-metrics.json',data)
    print(json.dumps({'row':a.row,'factor':a.factor,'anchor_x':fixed,'head':data['head'],'detail':[x['detail_ratio'] for x in data['frames']],'feet':[x['feet_band']['centres'] for x in data['frames']],'margin':[x['margin'] for x in data['frames']]},ensure_ascii=False))
if __name__=='__main__':main()
