"""Local landmark matching on nearest-neighbour 4x crops; inspect overlays before accepting."""
import sys,json,math
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import head_scale as h

stem=sys.argv[1]
versions={'frey':2,'luna':3,'luna_brave':4}
folder='frey' if stem=='frey' else 'luna'
a=Image.open(f'art/bakeoff/{folder}/{stem}-idle-v{versions[stem]}.png').convert('RGBA').crop((0,0,128,128))
# Coordinates are original cell pixels. Centres and patch size are fixed per anchor.
points={'frey':[(79,51,3,4),(85,51,3,4),(68,53,4,4),(85.5,53,4,4)],
 'luna':[(82.5,67,4,5),(90,67,3,4),(77,67,3,4),(91,67,3,4)],
 'luna_brave':[(79,64.5,4,5),(86,64.5,3,4),(73,65.5,3,4),(87,65.5,3,4)]}[stem]
ac=h.face_centre(np.array(a));an=np.array(a.resize((512,512),Image.Resampling.NEAREST))[...,:3].astype(float)
def centre(frame):
 ar=np.array(frame)
 if stem=='luna_brave' and row=='hurt' and i==2:
  ar[80:,:,3]=0
 return h.face_centre(ar)
def align_head(frame,s):
 cy,cx=centre(frame);f=np.asarray(frame).astype(float);t=h.head_template(a);t=t.resize((round(t.width*s),round(t.height*s)),Image.Resampling.LANCZOS);ta=np.asarray(t).astype(float);mask=ta[...,3]>0;tv=ta[...,:3][mask];tv-=tv.mean();tn=np.sqrt((tv*tv).sum())+1e-9
 best=(-2,None,None);height,width=ta.shape[:2]
 for dy in range(-12,13):
  for dx in range(-12,13):
   y0=round(cy+h.BOX[1]*s+dy);x0=round(cx+h.BOX[0]*s+dx)
   if y0<0 or x0<0:continue
   p=f[y0:y0+height,x0:x0+width]
   if p.shape!=ta.shape:continue
   pv=np.where(p[...,3][mask,None]>0,p[...,:3][mask],0.);pv-=pv.mean();sc=float((tv*pv).sum()/(tn*(np.sqrt((pv*pv).sum())+1e-9)))
   if sc>best[0]:best=(sc,x0,y0)
 return (s,best[1],best[2],round(best[0],3))
def match(frame,point):
 cy,cx=centre(frame);px,py,w,hh=point
 fx=np.array(frame.resize((frame.width*4,frame.height*4),Image.Resampling.NEAREST))[...,:3].astype(float)
 x0=round((px-w/2)*4);y0=round((py-hh/2)*4);ww=round(w*4);ht=round(hh*4)
 t=an[y0:y0+ht,x0:x0+ww];t=t-t.mean();tn=np.sqrt((t*t).sum())+1e-9
 s,ax,ay,_=alignment;ex=ax+(px-(round(ac[1])+h.BOX[0]))*s;ey=ay+(py-(round(ac[0])+h.BOX[1]))*s;best=(-2,None,None)
 for yy in range(round(ey*4)-6,round(ey*4)+7):
  for xx in range(round(ex*4)-6,round(ex*4)+7):
   sy=yy-ht//2;sx=xx-ww//2;p=fx[sy:sy+ht,sx:sx+ww]
   if p.shape!=t.shape:continue
   p=p-p.mean();score=float((p*t).sum()/(tn*(np.sqrt((p*p).sum())+1e-9)))
   if score>best[0]:best=(score,xx/4,yy/4)
 return {'x':best[1],'y':best[2],'score':round(best[0],3)}

report={'method':'4x nearest local patch matching. Proposed landmarks; visual review required. Width endpoints sample the exposed eye-lower-edge face, excluding hair. Closed lids cannot establish open-eye spacing.','anchor':points,'rows':{}}
def refine_eyes(f,marks):
 ar=np.array(f.resize((f.width*4,f.height*4),Image.Resampling.NEAREST)).astype(float)
 for j in [0,1]:
  m=marks[j];x,y=round(m['x']*4),round(m['y']*4);radius=10 if j==0 else 6;sx=x-radius;sy=y-8;p=ar[sy:y+8,sx:x+radius,:3]
  if j==0:
   w=np.maximum(p[...,2]-p[...,0],0) if stem=='frey' else np.maximum(np.minimum(p[...,0],p[...,2])-p[...,1],0)
  else:w=np.maximum(100-p.mean(axis=2),0)
  yy,xx=np.indices(w.shape)
  if w.sum()>0:m.update(x=round((sx+(xx*w).sum()/w.sum()+.5)/4,3),y=round((sy+(yy*w).sum()/w.sum()+.5)/4,3))
 return marks
am=refine_eyes(a,[{'x':p[0],'y':p[1],'score':1} for p in points])
for row,count in [('jump',3),('fall',2),('hurt',3),('land',2),('victory',6)]:
 if len(sys.argv)>2 and row!=sys.argv[2]:continue
 base=Path(f'reports/codex-art-72/{stem}/{row}')
 attempts=[p for p in sorted(base.glob('attempt-*')) if (p/f'{stem}-{row}.png').exists()]
 if not attempts:continue
 out=base/f'attempt-{sys.argv[3]}' if len(sys.argv)>3 else attempts[-1];im=Image.open(out/f'{stem}-{row}.png').convert('RGBA');cell=im.height
 hs=json.loads((out/'head-scale.json').read_text())
 board=Image.new('RGB',(256*(count+1),320),(31,38,55));bd=ImageDraw.Draw(board)
 rs=[]
 for i,f in enumerate([a]+[im.crop((j*cell,0,(j+1)*cell,cell)) for j in range(count)]):
  if i:
   hf=hs['frames'][i-1];alignment=align_head(f,hf['scale'] if hf['score']>=.6 else (hs['median'] or 1.0))
  marks=[dict(m) for m in am] if i==0 else refine_eyes(f,[match(f,p) for p in points])
  cy,cx=centre(f);ox,oy=round(cx)-24,round(cy)-24
  cr=f.crop((ox,oy,ox+48,oy+48)).resize((192,192),Image.Resampling.NEAREST);bx=i*256+32;by=48;board.paste(cr,(bx,by),cr)
  for j,m in enumerate(marks):
   x=bx+(m['x']-ox)*4;y=by+(m['y']-oy)*4;col=['cyan','cyan','yellow','yellow'][j]
   bd.line((x-4,y,x+4,y),fill=col);bd.line((x,y-4,x,y+4),fill=col)
  eye=math.hypot(marks[1]['x']-marks[0]['x'],marks[1]['y']-marks[0]['y']);fw=marks[3]['x']-marks[2]['x']
  ae=math.hypot(am[1]['x']-am[0]['x'],am[1]['y']-am[0]['y']);aw=points[3][0]-points[2][0]
  r={'frame':i,'landmarks':marks,'eye_distance':round(eye,3),'face_width':fw,'eye_ratio':round(eye/ae,3),'face_width_ratio':round(fw/aw,3)}
  if i:r['head_alignment']=alignment
  bd.text((i*256+6,6),'ANCHOR' if i==0 else f'F{i} E{r["eye_ratio"]} W{r["face_width_ratio"]}',fill='white');bd.text((i*256+6,260),f'min score {min(m["score"] for m in marks)}',fill='white')
  if i:rs.append(r)
 report['rows'][row]=rs;board.save(out/'face-landmarks-proposed.png')
 (out/'face-proposed.json').write_text(json.dumps({'method':report['method'],'anchor':points,'anchor_landmarks':am,'reference_eye_distance':ae,'reference_face_width':aw,'frames':rs},indent=2),encoding='utf-8')
Path(f'reports/codex-art-72/{stem}/face-proposed.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({row:[(f['eye_ratio'],f['face_width_ratio']) for f in frames] for row,frames in report['rows'].items()}))
