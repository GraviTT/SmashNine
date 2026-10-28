"""Rigid medallion is measured as a ring, not a fragmented colour component."""
from pathlib import Path
import sys,importlib.util,json,hashlib
import numpy as np
from PIL import Image,ImageDraw,ImageFont
sys.dont_write_bytecode=True
s=importlib.util.spec_from_file_location('l91',Path(__file__).with_name('landmark_scan.py'));l=importlib.util.module_from_spec(s);s.loader.exec_module(l);p=l.p
c=json.loads((p.RAW/'asgard_runic_raven-appear-a.json').read_text(encoding='utf-8'));c['trial']='asgard_runic_raven-appear-b';c['measure_override']='median gold ring radius inside fixed anatomical ROI; not isolated connected fragment';out=p.RAW/c['trial'];out.mkdir(exist_ok=False)
factor=.235;target=(51,50);idle=Image.open(p.ROOT/c['idle']).convert('RGBA').crop((0,0,96,96))
def ring(im,center):
 a=np.asarray(im).astype(int);r,g,b=a[:,:,0],a[:,:,1],a[:,:,2];ys,xs=np.indices(a.shape[:2]);rad=np.sqrt((xs-center[0])**2+(ys-center[1])**2)
 mask=(r>140)&(g>65)&(b<130)&(r>g*1.1)&(a[:,:,3]>127)&(rad<9)
 return float(np.median(rad[mask]))
ref=ring(idle,(48.5,50));ims,labs=p.n.split_sheet(Path(c['source']),(6,1));ims=[p.n.clean_background(im,'alpha')[0] for im in ims];p.n.validate_source_cell_margin(ims,labs)
frames=[];audit=[]
for i,im in enumerate(ims):
 box=im.getbbox();land=l.component(im,'gold')['bbox'];center=((land[0]+land[2]-1)/2,(land[1]+land[3]-1)/2)
 sub=im.crop(box);sub=sub.resize((round(sub.width*factor),round(sub.height*factor)),Image.Resampling.LANCZOS);sub=p.n.apply_unsharp(sub,60);sub.putalpha(sub.getchannel('A').point(lambda a:255 if a>=128 else 0))
 x=round(target[0]-(center[0]-box[0])*factor);y=round(target[1]-(center[1]-box[1])*factor)
 assert x>=0 and y>=0 and x+sub.width<=96 and y+sub.height<=96
 frame=Image.new('RGBA',(96,96));frame.alpha_composite(sub,(x,y));frames.append(frame);bb=frame.getbbox();size=ring(frame,target)
 audit.append(dict(frame=i+1,bbox=bb,margin=min(bb[0],bb[1],96-bb[2],96-bb[3]),bottom=bb[3]-1,landmark_ratio=size/ref,ring_radius=size,alignment=target,alpha_binary=True,spill=p.n.spill_pixel_count(frame),sha256=hashlib.sha256(frame.tobytes()).hexdigest()))
strip=Image.new('RGBA',(576,96));board=Image.new('RGB',(2688,430),(26,30,40));d=ImageDraw.Draw(board);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
for i,im in enumerate([idle]+frames):
 d.text((i*384+8,5),'IDLE reference' if i==0 else f'APPEAR {i}',font=font,fill='white');big=im.resize((384,384),Image.Resampling.NEAREST);board.paste(big,(384*i,36),big)
for i,im in enumerate(frames):strip.alpha_composite(im,(96*i,0))
fail=[]
for a in audit:
 if a['margin']<4 or not .95<=a['landmark_ratio']<=1.05 or a['spill']:fail.append(a)
p.save(strip,out/'strip.png');p.save(board,out/'board.png');p.new_json(out/'metrics.json',dict(config=c,factor=factor,idle_landmark=dict(size=ref,center=[48.5,50],method='median gold ring radius'),frames=audit,failures=fail,notes='Whole-frame translation only. Gold ring entire circumference replaces unstable 4-connected fragment metric. X centre +2.5px for wing clearance; original hover y retained.'))
print(json.dumps(dict(audit=audit,failures=fail)))
