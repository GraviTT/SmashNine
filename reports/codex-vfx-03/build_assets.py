"""Candidate-only build. ImageGen crops -> downscale -> hard alpha. No product writes."""
from pathlib import Path
import json, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
ROOT=Path(__file__).resolve().parents[2]
R=Path(__file__).resolve().parent
RAW=ROOT/'art/raw/vfx-03'
OUT=ROOT/'art/bakeoff/effects/frey'
OUT.mkdir(parents=True,exist_ok=True)
PAL=['#764311','#a96816','#d78d20','#f7af29','#ffce56','#ffe69a','#fff2c3','#fffbe8','#fffef7','#537b9f','#8eb6d1','#c5e3f2']
RGB=np.array([tuple(bytes.fromhex(c[1:])) for c in PAL],dtype=np.int32)
PROVENANCE=[]
def hard(im,threshold=200,palette=True):
 a=np.array(im.convert('RGBA'));m=a[:,:,3]>=threshold
 if palette:
  c=a[m,:3].astype(np.int32)
  a[m,:3]=RGB[((c[:,None,:]-RGB[None,:,:])**2).sum(2).argmin(1)].astype(np.uint8)
 a[:,:,3]=m.astype(np.uint8)*255;a[~m]=0
 return Image.fromarray(a)
def resize_down(im,size):
 assert size[0]<=im.width and size[1]<=im.height,('upscale forbidden',im.size,size)
 return im.resize(size,Image.Resampling.NEAREST)
def cell(name,i,cols):
 im=Image.open(RAW/f'{name}.png').convert('RGBA');w=im.width//cols;h=im.height//2
 return hard(im.crop((i%cols*w,i//cols*h,(i%cols+1)*w,(i//cols+1)*h)))
def border(im):
 a=np.array(im);a[0]=0;a[-1]=0;a[:,0]=0;a[:,-1]=0
 return Image.fromarray(a)
def emit(name,v,frames,fps,anchor,note,replaces,out=OUT):
 out.mkdir(parents=True,exist_ok=True);stem=f'{name}-{v}-v1'
 w,h=frames[0].size;strip=Image.new('RGBA',(w*len(frames),h))
 for i,f in enumerate(frames):strip.alpha_composite(border(f),(i*w,0))
 strip.save(out/f'{stem}.png')
 meta={'note':note,'replaces':'smash-nine-prototype/assets/art/'+replaces,'frames':len(frames),'fps':fps,'anchor':anchor}
 (out/f'{stem}.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 return frames
def wings(v):
 # Root points are marked on the cleaned raw atlas in source_roots.png.
 roots={'a':[(256,350),(256,338),(256,332),(256,292)],'b':[(256,350),(256,346),(256,346),(256,350)]}[v]
 scales={'a':[.51,.51,.42,.51],'b':[.40,.40,.40,.40]}[v];frames=[]
 for i in range(4):
  scale=scales[i];src=cell('wings-'+v,i,3);sx,sy=roots[i];size=(round(src.width*scale),round(src.height*scale));scaled=resize_down(src,size)
  dest=Image.new('RGBA',(256,256));offset=(128-round(sx*scale),130-round(sy*scale));dest.alpha_composite(scaled,offset);frames.append(border(dest))
  PROVENANCE.append({'asset':f'wings-{v}','frame':i+1,'raw_cell':i,'source_root':[sx,sy],'scale':scale,'offset':offset,'target_root':[128,130]})
 # Hold the open feather geometry so 4->6 is shimmer, never another flap.
 base=np.array(frames[3]);yy,xx=np.indices(base.shape[:2]);mask=base[:,:,3]>0
 for i in (4,5):
  a=base.copy();sweep=((xx+2*yy+i*17)%79<8)&mask&(yy<125)&(a[:,:,0]>200)
  a[sweep,:3]=[255,254,247];frames.append(Image.fromarray(a))
 return emit('frey_wings',v,frames,20,[128,240],
  '넓은 부채형 금백색 날개. 1 접힘 → 2·3 펼침 → 4~6 펼친 실루엣을 유지하며 깃 끝이 반짝인다.' if v=='a' else '위로 솟는 긴 매의 깃 날개. 1 접힘 → 2·3 펼침 → 4~6 같은 실루엣에 가느다란 백금빛이 흐른다.',
  'effects/skill/frey_wings.png')
def wave(v):
 frames=[]
 for i in range(4):
  src=cell('wave-'+v,i,2);b=src.getbbox();crop=src.crop(b)
  # Match the intended flight envelope; leading edge and centre never move.
  dst=resize_down(crop,(60,100));frame=Image.new('RGBA',(128,128));frame.alpha_composite(dst,(34,14));frames.append(frame)
  PROVENANCE.append({'asset':f'wave-{v}','frame':i+1,'crop':b,'target_size':[60,100],'scale_xy':[60/crop.width,100/crop.height],'offset':[34,14]})
 return emit('frey_wave',v,frames,16,[64,64],
  '오른쪽을 향하는 매끈한 단일 초승달. 금빛 내부 띠와 뒤쪽 불꽃만 변화하는 비행 반복.' if v=='a' else '오른쪽 날카로운 초승달과 뒤쪽으로 갈라진 세 깃 검기. 작은 깃 불꽃이 남는 비행 반복.',
  'effects/frey_wave.png')
def light(v):
 centres={'a':[(256,258),(256,260),(256,256),(256,254),(256,256),(256,255)],'b':[(256,258),(256,258),(256,260),(256,255),(256,257),(256,256)]}[v]
 radii={'a':[52,115,166,198,217,232],'b':[36,85,129,174,200,222]}[v]
 targets=[50,116,198,270,314,330]
 # A generated isolated feather, cut from A frame 3. Preserve raster drawing.
 feather=cell('light-a',2,3).crop((138,157,214,225))
 fa=np.array(feather);yy,xx=np.indices(fa.shape[:2]);fa[(xx<3)|(yy<3)]=0;feather=Image.fromarray(fa)
 feather=resize_down(feather,(26,23))
 ray=cell('light-a',5,3).crop((246,58,266,112));ray=resize_down(ray,(6,18))
 frames=[]
 for i in range(6):
  # Reuse the generated final ring for a stable concentric expansion. Earlier
  # raw cells are retained for audit; their feather drift was inconsistent.
  src=cell('light-'+v,5,3);cx,cy=centres[5];rad=radii[5];crop=src.crop((cx-rad,cy-rad,cx+rad,cy+rad));a=np.array(crop)
  yy,xx=np.indices(a.shape[:2]);dist=np.sqrt((xx-rad)**2+(yy-rad)**2)
  # Remove floating feathers from the source, retaining the generated rim and
  # wreath. Recompose a single coherent inward-moving feather layer below.
  a[dist<rad*(.87 if v=='a' else .36)]=0
  a[dist>rad]=0
  # Earlier rim frames have a warmer, darker trim; final frame is brightest.
  m=a[:,:,3]>0
  if i<5:
   factor=[.72,.76,.81,.87,.94][i];a[m,:3]=np.rint(a[m,:3]*factor).astype(np.uint8)
  crop=Image.fromarray(a);sz=targets[i];dst=resize_down(crop,(sz,sz));frame=Image.new('RGBA',(336,336));frame.alpha_composite(dst,(168-sz//2,168-sz//2))
  if i<2:
   core=cell('light-'+v,0,3).crop((225,225,287,287));cs=26 if i==0 else 16
   core=resize_down(core,(cs,cs));frame.alpha_composite(core,(168-cs//2,168-cs//2))
  if i>=2:
   if v=='a':
    # Four slim rays cut from the generated atlas, aimed into the clear area.
    ray_radius=[79,113,133,141][i-2]
    for q in range(4):
     rrim=ray.rotate(q*90,expand=True,resample=Image.Resampling.NEAREST)
     angle=math.radians(-90-q*90)
     frame.alpha_composite(rrim,(round(168+ray_radius*math.cos(angle)-rrim.width/2),round(168+ray_radius*math.sin(angle)-rrim.height/2)))
   rr=[80,64,48,32][i-2]
   for q in range(4):
    # Source feather points southeast; quarter-turns point all quills inward.
    ang=math.radians(225-q*90);f=feather.rotate(q*90,expand=True,resample=Image.Resampling.NEAREST)
    x=round(168+rr*math.cos(ang)-f.width/2);y=round(168+rr*math.sin(ang)-f.height/2)
    frame.alpha_composite(f,(x,y))
  frames.append(border(frame))
  PROVENANCE.append({'asset':f'light-{v}','frame':i+1,'raw_cell':5,'source_center':[cx,cy],'crop_radius':rad,'target_diameter':sz,'scale':sz/(rad*2),'floating_feather_radius':None if i<2 else [80,64,48,32][i-2]})
 return emit('frey_ult_light',v,frames,13.3,[168,168],
  '금백색 이중 고리가 퍼지고, 네 깃이 중심 쪽으로 모인다. 안쪽은 비우고 마지막 테두리가 가장 밝다.' if v=='a' else '안쪽을 향한 깃 화관과 금빛 고리가 펼쳐진다. 별도의 작은 깃 네 개가 안쪽으로 모이며 마지막 테두리가 빛난다.',
  'vfx/frey_ult_light.png')
N='#101522';G='#ffc84a';W='#fff09a';L='#f7fbff';B='#75a4c3';D='#b97524'
def outlined(fill):
 m=fill.getchannel('A').filter(ImageFilter.MaxFilter(3));im=Image.new('RGBA',fill.size,N);im.putalpha(m);im.alpha_composite(fill);return im
def small(v):
 im=Image.new('RGBA',(24,24));d=ImageDraw.Draw(im)
 if v=='a':
  d.rectangle((5,3,18,5),fill=G);d.rectangle((5,18,18,20),fill=G)
  d.polygon([(7,6),(16,6),(16,8),(13,11),(13,12),(16,15),(16,17),(7,17),(7,15),(10,12),(10,11),(7,8)],fill=W)
  d.polygon([(9,7),(14,7),(12,10),(11,10)],fill=G);d.rectangle((11,11,12,13),fill=D)
  d.polygon([(11,14),(12,14),(15,17),(8,17)],fill=G);d.rectangle((6,3,9,4),fill=L)
 else:
  d.polygon([(4,4),(8,4),(12,8),(16,4),(19,4),(19,8),(12,14),(4,8)],fill=G)
  d.polygon([(4,11),(8,11),(12,15),(16,11),(19,11),(19,15),(12,21),(4,15)],fill=G)
  d.line([(5,5),(12,11),(18,5)],fill=W,width=2);d.line([(5,12),(12,18),(18,12)],fill=W,width=2)
 im=outlined(im)
 return emit('slow',v,[im],0,[12,12], '금색 모래시계. 기절 별 및 푸른 아머 방패와 모양으로 구분한다.' if v=='a' else '무겁게 내려가는 금색 이중 갈매기표. 이동이 느려지는 상태를 아래 방향으로 표현한다.', 'ui/status/slow.png',ROOT/'art/bakeoff/ui/status')
def icon(v):
 # Draw at the final 40px size with explicit 2px blocks; outline is 1px navy.
 im=Image.new('RGBA',(40,40));d=ImageDraw.Draw(im)
 def poly(points,c):d.polygon([(x*2,y*2) for x,y in points],fill=c)
 # Low-resolution fill is rasterised directly into 2x2 cells, no asset upscaling.
 low=Image.new('RGBA',(20,20));ld=ImageDraw.Draw(low)
 def p(points,c):ld.polygon(points,fill=c)
 def rect(b,c):ld.rectangle(b,fill=c)
 if v=='a':
  # Circular sword swing on left, separate crescent released on right.
  p([(8,2),(4,3),(2,6),(2,10),(4,13),(8,14),(10,12),(6,12),(4,10),(4,6),(6,4),(9,4)],G)
  p([(14,3),(17,5),(18,9),(17,13),(14,16),(15,12),(16,9),(15,6)],G)
  p([(15,5),(17,7),(17,10),(15,13),(16,9)],W)
  p([(5,12),(11,5),(13,4),(13,7),(7,14)],B)
  p([(7,11),(12,5),(12,7),(8,12)],L)
  p([(4,11),(8,15),(7,16),(3,12)],G);p([(3,14),(5,16),(4,18),(2,16)],B)
 else:
  # Wide near-complete orbit, horizontal sword, large forward crescent.
  p([(10,2),(6,2),(3,4),(2,7),(3,10),(5,11),(4,8),(4,5),(7,4),(10,4),(12,6),(13,5)],G)
  p([(14,3),(17,6),(18,10),(17,14),(13,17),(15,12),(15,8)],G)
  p([(15,5),(17,8),(17,11),(15,14),(16,10)],W)
  p([(4,9),(11,9),(14,10),(11,12),(4,12)],B);rect((5,9,11,9),L)
  rect((4,7,5,14),G);rect((2,10,3,11),B)
  p([(7,15),(10,15),(12,13),(11,16),(8,17),(6,16)],G)
 for yy in range(20):
  for xx in range(20):
   c=low.getpixel((xx,yy))
   if c[3]:d.rectangle((xx*2,yy*2,xx*2+1,yy*2+1),fill=c)
 bb=im.getbbox();shift=(20-(bb[0]+bb[2])//2,20-(bb[1]+bb[3])//2);centred=Image.new('RGBA',(40,40));centred.alpha_composite(im,shift);im=outlined(centred)
 return emit('frey_k',v,[im],0,[20,20], '대각선 검을 감싼 회전 궤적에서 오른쪽 초승달이 분리되는 아이콘.' if v=='a' else '수평 검의 넓은 회전 궤적과 앞쪽 큰 초승달. 검과 방출 방향을 강조한 아이콘.', 'skill_icons/frey_k.png',ROOT/'art/bakeoff/skill_icons/frey')
if __name__=='__main__':
 for v in 'ab':wings(v);wave(v);light(v);small(v);icon(v)
 (R/'processing.json').write_text(json.dumps(PROVENANCE,indent=2)+'\n',encoding='utf-8')
 # Small source inspection: alpha-cleaned atlases with root crosshairs.
 for v in 'ab':
  im=hard(Image.open(RAW/f'wings-{v}.png'));d=ImageDraw.Draw(im)
  for row in PROVENANCE:
   if row['asset']==f'wings-{v}':
    i=row['frame']-1;x,y=row['source_root'];x+=i%3*512;y+=i//3*512
    d.line((x-10,y,x+10,y),fill='#ff44aa',width=2);d.line((x,y-10,x,y+10),fill='#ff44aa',width=2)
  im.save(R/f'source_roots_{v}.png')
 print('10 candidates + metadata built; no product writes')
