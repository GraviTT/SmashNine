"""Apply approved normalizer despill-auto to an un-delivered trial; exclusive outputs."""
from pathlib import Path
import sys,json,importlib.util,hashlib
from PIL import Image,ImageDraw,ImageFont
sys.dont_write_bytecode=True
s=importlib.util.spec_from_file_location('p91',Path(__file__).with_name('row_pipeline.py'));p=importlib.util.module_from_spec(s);s.loader.exec_module(p)
old=p.RAW/sys.argv[1];out=p.RAW/sys.argv[2];out.mkdir(exist_ok=False);m=json.loads((old/'metrics.json').read_text(encoding='utf-8'));c=m['config'];c['trial']=sys.argv[2];im=Image.open(old/'strip.png').convert('RGBA');frames=[]
for i in range(6):
 before=im.crop((96*i,0,96*(i+1),96));after=p.n.despill_green_edge(before,'auto');frames.append(after);a=m['frames'][i];a.update(spill_before=p.n.spill_pixel_count(before),spill=p.n.spill_pixel_count(after),alpha_unchanged=before.getchannel('A').tobytes()==after.getchannel('A').tobytes(),sha256=hashlib.sha256(after.tobytes()).hexdigest())
strip=Image.new('RGBA',(576,96));board=Image.new('RGB',(2688,430),(26,30,40));d=ImageDraw.Draw(board);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20);idle=Image.open(p.ROOT/c['idle']).convert('RGBA').crop((0,0,96,96))
for i,frame in enumerate([idle]+frames):
 d.text((i*384+8,5),'IDLE reference' if i==0 else f'APPEAR {i}',font=font,fill='white');big=frame.resize((384,384),Image.Resampling.NEAREST);board.paste(big,(384*i,36),big)
for i,frame in enumerate(frames):strip.alpha_composite(frame,(96*i,0))
m['failures']=[a for a in m['frames'] if a['spill'] or not a['alpha_unchanged'] or a['margin']<4 or not .95<=a['landmark_ratio']<=1.05];m['notes']+=' Standard normalize.py despill auto applied to all frames, no palette map.'
p.save(strip,out/'strip.png');p.save(board,out/'board.png');p.new_json(out/'metrics.json',m);print(json.dumps(dict(failures=m['failures'],spill=[a['spill'] for a in m['frames']])))
