"""ART-71 orb-centre whole-frame alignment; no resizing."""
import sys,json
from PIL import Image
import repair as r
from reuse71 import review as v
mid='alfheim_moon_moth';row='windup';src=r.REPORT/'trials'/f'{mid}-{row}-{sys.argv[1]}';dst=r.REPORT/'trials'/f'{mid}-{row}-{sys.argv[2]}'
assert not dst.exists();dst.mkdir(parents=True)
data=json.loads((src/'metrics.json').read_text('utf-8'));ims=r.frames(src/'strip.png',4);out=[];features=[]
base=v.feature(mid,'idle',r.frames(r.BAKE/f'{mid}-idle-v1.png',6)[0])['size']
for i,im in enumerate(ims):
 feature=v.feature(mid,row,im);box=feature['box'];dx=round(62-(box[0]+box[2]-1)/2);dy=round(50-(box[1]+box[3]-1)/2)
 new=Image.new('RGBA',(96,96));new.alpha_composite(im,(dx,dy));assert r.n.alpha_area(im)==r.n.alpha_area(new);out.append(new)
 f=v.feature(mid,row,new);features.append(dict(frame=i+1,translation=[dx,dy],feature=f,ratio=f['size']/base))
data.update(after=r.audit(out),orb_alignment=features);r.save(dst/'strip.png',r.strip(out));r.save(dst/'review-4x.png',r.panel(out,'Moth windup /4x'));r.save(dst/'review-1x.png',r.panel(out,'Moth windup /1x',1));r.jsave(dst/'metrics.json',data);print(features)
