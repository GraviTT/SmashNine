"""ART-71 body landmark translation, located by the bright yellow core of the front eye."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json,sys
import process as p
from landmarks import groups
from refine import translate

mid='svartalfheim_cog_drone'
targets={'idle':[40,39,38,39,41,40],'walk':[40,40,39,40,41,40], 'windup':[40,38,35,34],'attack':[40,40,36,38,40,40],'hurt':[37,40]}
for row,ys in targets.items():
    if len(sys.argv)>1 and row!=sys.argv[1]:continue
    ims=p.frames(p.BAKE/f'{mid}-{row}-v1.png',p.COUNTS[row]); deltas=[]; measured=[]
    for i,im in enumerate(ims):
        a=p.n.np.array(im); r,g,b,al=[a[:,:,k].astype(float) for k in range(4)]
        mask=(r>240)&(g>150)&(b<180)&(al>0)
        mask[:,:58]=False;mask[:,76:]=False;mask[55:]=False
        gs=groups(mask); gg=max(gs,key=lambda z:z['area']);box=gg['bbox']
        centre=[(box[0]+box[2]-1)/2,(box[1]+box[3]-1)/2]
        delta=[round(64-centre[0]),round(ys[i]-centre[1])]
        deltas.append(delta); measured.append(dict(frame=i,eye_bright_core_box=box,eye_bright_core_area=gg['area'],centre_before=centre,target=[64,ys[i]],delta=delta))
    print(row,measured)
    translate(mid,row,deltas,'front amber eye bright core (R>240 G>150 B<180, x58:76 y0:55) centre; reference game eye at (64,40); prescribed small hover/recoil offsets')
    mp=p.REPORT/mid/row/'metrics.json';m=json.loads(mp.read_text('utf-8'));m['eye_alignment']=measured;mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),'utf-8')
