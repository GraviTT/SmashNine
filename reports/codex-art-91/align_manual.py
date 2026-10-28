"""Translate entire prepared frames to a documented body landmark; no part edits."""
from pathlib import Path
import sys,json,importlib.util,hashlib
from PIL import Image,ImageDraw,ImageFont
sys.dont_write_bytecode=True
s=importlib.util.spec_from_file_location('p91',Path(__file__).with_name('row_pipeline.py'));p=importlib.util.module_from_spec(s);s.loader.exec_module(p)
old=p.RAW/sys.argv[1];out=p.RAW/sys.argv[2];out.mkdir(exist_ok=False);m=json.loads((old/'metrics.json').read_text(encoding='utf-8'));c=m['config'];c['trial']=sys.argv[2];factor=m['factor'];target=c['target_center']
raw,_=p.n.split_sheet(Path(c['source']),(6,1));strip=Image.open(old/'strip.png').convert('RGBA');frames=[];audits=[]
for i,(src,center) in enumerate(zip(raw,c['source_centers'])):
 src=p.n.clean_background(src,'alpha')[0];sb=src.getbbox();im=strip.crop((96*i,0,96*(i+1),96));bb=im.getbbox();before=[bb[j]+(center[j]-sb[j])*factor for j in range(2)];delta=[round(target[j]-before[j]) for j in range(2)];nb=[bb[j]+delta[j%2] for j in range(4)]
 if min(nb[:2])<4 or max(nb[2:])>92:raise ValueError(f'frame {i+1} has insufficient margin after alignment {nb}')
 frame=Image.new('RGBA',(96,96));frame.alpha_composite(im,tuple(delta));frames.append(frame);a=m['frames'][i];bb=frame.getbbox();a.update(bbox=bb,margin=min(bb[0],bb[1],96-bb[2],96-bb[3]),bottom=bb[3]-1,body_alignment=dict(source=center,target=target,translation=delta,after=[before[j]+delta[j] for j in range(2)]),spill=p.n.spill_pixel_count(frame),sha256=hashlib.sha256(frame.tobytes()).hexdigest());audits.append(a)
newstrip=Image.new('RGBA',(576,96));board=Image.new('RGB',(2688,430),(26,30,40));d=ImageDraw.Draw(board);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20);idle=Image.open(p.ROOT/c['idle']).convert('RGBA').crop((0,0,96,96))
for i,im in enumerate([idle]+frames):
 d.text((i*384+8,5),'IDLE reference' if i==0 else f'APPEAR {i}',font=font,fill='white');big=im.resize((384,384),Image.Resampling.NEAREST);board.paste(big,(384*i,36),big)
for i,im in enumerate(frames):newstrip.alpha_composite(im,(96*i,0))
m['frames']=audits;m['failures']=[a for a in audits if a['margin']<4 or not .95<=a['landmark_ratio']<=1.05 or a['spill']];m['notes']='Common factor unchanged; whole-frame translation to manually indicated core centre; source centre uncertainty +-3px.'
p.save(newstrip,out/'strip.png');p.save(board,out/'board.png');p.new_json(out/'metrics.json',m);print(json.dumps(dict(audit=audits,failures=m['failures'])))
