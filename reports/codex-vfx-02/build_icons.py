from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/bakeoff/skill_icons/luna_brave'
REPORT=Path(__file__).resolve().parent
SOURCE=ROOT/'smash-nine-prototype/assets/art/skill_icons'
N='#101522'; V='#8062ec'; P='#ff5fb8'; G='#ffc84a'; W='#fff09a'; LIGHT='#f7fbff'
NOTES={
'j-a':'금색 손목띠를 두른 보라 건틀릿의 잽. 짧은 분홍 타격광 세 덩어리로 빠른 연타를 표현했다.',
'j-b':'무릎을 굽혀 앞으로 차는 보라 부츠의 보디 킥. 발끝의 짧은 분홍 타격광으로 근접 연계를 표현했다.',
'k-a':'작은 건틀릿을 품은 압축 별이 앞장서는 몸통 돌진. 뒤의 짧고 넓은 분홍 잔상은 일반 루나의 긴 혜성과 구분된다.',
'k-b':'주먹을 앞으로 내밀고 다리를 접은 작은 전투 자세. 몸에 붙은 짧은 분홍 잔상과 금색 충격광으로 돌진을 표현했다.',
'l-a':'보라 부츠가 큰 분홍 반원 궤적을 따라 전방을 차고 커다란 금색 별에 닿는 회전 마무리 킥.',
'l-b':'위에서 감겨 내려오는 분홍 회전 궤적과 아래로 뻗은 보라 부츠. 오른쪽 아래의 무거운 별은 공중 마무리 킥의 충격이다.'}
def drawing(key):
 im=Image.new('RGBA',(20,20)); d=ImageDraw.Draw(im)
 def poly(p,c): d.polygon(p,fill=c)
 def rect(b,c): d.rectangle(b,fill=c)
 def star(x,y,c): poly([(x,y-3),(x+1,y-1),(x+3,y),(x+1,y+1),(x,y+3),(x-1,y+1),(x-3,y),(x-1,y-1)],c)
 if key=='j-a':
  # Horizontal armored jab; closed palm, square knuckles and curled thumb.
  poly([(3,10),(7,9),(9,10),(10,7),(15,7),(17,9),(17,12),(15,14),(10,14),(8,13),(3,14)],V)
  rect((6,9,7,13),G);rect((11,7,14,8),G);rect((14,9,16,10),LIGHT)
  rect((11,11,14,11),N);rect((10,12,13,13),P)
  rect((16,4,17,5),P);rect((19,8,19,9),W);rect((18,13,19,14),P)
 elif key=='j-b':
  poly([(3,5),(7,5),(10,8),(9,11),(13,11),(15,10),(17,11),(17,14),(8,14),(6,12),(7,9),(3,8)],V)
  poly([(3,5),(6,5),(7,6),(6,8),(3,8)],P)
  rect((8,8,9,9),G);rect((10,11,11,13),G);rect((13,11,15,12),LIGHT);rect((8,14,16,14),G)
  rect((16,5,17,6),P);rect((18,8,19,9),W);rect((18,14,19,15),P)
 elif key=='k-a':
  # Short broad wake with a large leading gauntlet inside compressed starlight.
  poly([(3,7),(8,7),(10,9),(5,9)],P);rect((2,10,8,11),P);poly([(4,13),(9,12),(9,14),(5,15)],P)
  poly([(12,3),(14,7),(18,9),(15,12),(13,17),(10,13),(7,11),(9,7)],G)
  poly([(12,5),(13,8),(16,9),(13,11),(12,15),(10,12),(9,10),(10,8)],W)
  poly([(10,9),(12,7),(16,7),(17,8),(17,11),(15,12),(11,12)],V)
  rect((14,7,16,8),LIGHT);rect((10,9,11,12),G)
  rect((13,10,16,10),N);rect((12,11,14,12),P)
 elif key=='k-b':
  poly([(3,7),(7,7),(9,9),(5,9)],P);rect((2,11,6,12),P);poly([(4,15),(7,13),(9,13),(7,15)],P)
  rect((9,6,11,8),W);rect((8,5,10,5),P)
  poly([(8,9),(12,9),(14,10),(12,12),(10,12),(8,14),(5,14),(6,12)],V);rect((8,9,10,10),P)
  poly([(10,13),(12,12),(14,13),(13,15),(10,16),(8,16),(8,15)],V);rect((8,15,9,16),G)
  rect((12,9,14,10),G);poly([(14,7),(17,7),(18,8),(18,10),(16,11),(14,10)],V)
  rect((15,7,17,8),LIGHT);rect((15,10,17,10),G);rect((18,4,19,5),G);rect((19,12,20,13),G)
 elif key=='l-a':
  poly([(11,2),(7,2),(4,4),(2,7),(2,11),(4,14),(7,16),(11,16),(14,14),(15,12),(12,13),(9,13),(6,12),(5,10),(5,7),(7,5),(10,4)],P)
  poly([(3,7),(3,10),(5,13),(8,15),(11,15),(11,14),(8,14),(6,12),(4,9),(4,7)],W)
  poly([(7,7),(10,6),(12,8),(11,10),(14,10),(16,9),(17,10),(17,12),(10,12),(8,10)],V)
  rect((8,7,9,8),G);rect((11,10,12,11),G);rect((14,10,16,11),LIGHT);star(16,7,G);rect((15,6,16,7),W)
 elif key=='l-b':
  poly([(3,12),(2,9),(3,6),(5,3),(8,2),(12,2),(15,4),(17,7),(17,10),(15,13),(14,10),(14,7),(12,5),(9,4),(6,5),(4,8)],P)
  poly([(5,4),(8,3),(11,3),(14,5),(15,8),(14,8),(13,6),(11,5),(8,4),(6,5)],W)
  poly([(7,7),(10,7),(12,10),(12,12),(15,14),(14,16),(11,15),(9,12),(8,11)],V)
  rect((7,7,9,8),G);rect((10,10,11,11),P);rect((11,12,12,13),G);rect((12,14,13,15),LIGHT)
  star(16,15,G);rect((15,14,16,15),W)
 # Hand-authored 2px clusters. No smoothing or palette quantisation.
 fill=im.resize((40,40),Image.Resampling.NEAREST); b=fill.getbbox()
 centered=Image.new('RGBA',(40,40));centered.paste(fill,(20-(b[0]+b[2])//2,20-(b[1]+b[3])//2))
 mask=centered.getchannel('A').filter(ImageFilter.MaxFilter(3))
 result=Image.new('RGBA',(40,40),N);result.putalpha(mask);result.alpha_composite(centered)
 return result,centered

def components(mask):
 seen=set();sizes=[]
 for y,x in zip(*np.where(mask)):
  if (y,x) in seen:continue
  q=[(y,x)];seen.add((y,x));n=0
  while q:
   yy,xx=q.pop();n+=1
   for dy,dx in ((0,1),(1,0),(0,-1),(-1,0)):
    p=(yy+dy,xx+dx)
    if 0<=p[0]<40 and 0<=p[1]<40 and mask[p] and p not in seen:seen.add(p);q.append(p)
  sizes.append(n)
 return sizes

def measure(key,im,fill):
 a=np.array(im);f=np.array(fill);visible=a[:,:,3]>0;rgb=a[:,:,:3];navy=np.array((16,21,34))
 dilated=np.array(fill.getchannel('A').filter(ImageFilter.MaxFilter(3)))>0
 border=dilated&(f[:,:,3]==0);bad=int(np.sum(border&np.any(rgb!=navy,axis=2)))
 colors=np.unique(a[visible,:3],axis=0);cc=[]
 for c in colors:
  if not np.array_equal(c,navy):cc+=components(np.all(rgb==c,axis=2)&visible)
 b=im.getbbox();ys,xs=np.where(visible);center=[(b[0]+b[2])/2,(b[1]+b[3])/2]
 checks={'canvas':im.size==(40,40) and im.mode=='RGBA','alpha_0_1':set(np.unique(a[:,:,3]))=={0,255},
 'outline_1px':bad==0 and np.array_equal(visible,dilated),'center':center==[20,20],'few_colors':len(colors)<=6,
 'clusters_2px':min(cc)>=4,'clear_margin':not(np.any(visible[0]) or np.any(visible[-1]) or np.any(visible[:,0]) or np.any(visible[:,-1]))}
 return dict(file=f'luna_brave_{key}-v1.png',size=list(im.size),mode=im.mode,visible_colors=len(colors),
 colors=['#'+''.join(f'{v:02x}' for v in c) for c in colors],alpha=[int(x) for x in np.unique(a[:,:,3])],bbox=list(b),bbox_center=center,
 alpha_centroid=[round(float(xs.mean()+.5),2),round(float(ys.mean()+.5),2)],outline_pixels=int(border.sum()),outline_bad_pixels=bad,
 smallest_color_component=min(cc),checks=checks)
FIGHTERS=['frey','yuki','luna','luna_brave','nova','rio']
def contact(icons,scale=1):
 im=Image.new('RGB',(416,312),'#0a0d14');d=ImageDraw.Draw(im)
 for panel,bg in enumerate(('#141824','#d9dde3')):
  for row,f in enumerate(FIGHTERS):
   for col,k in enumerate('jkli'):
    x=8+208*panel+48*col;y=12+48*row;d.rectangle((x,y,x+47,y+47),fill=bg)
    icon=icons.get(k) if f=='luna_brave' else None
    if icon is None:icon=Image.open(SOURCE/f'{f}_{k}.png').convert('RGBA')
    im.paste(icon,(x+4,y+4),icon)
 return im.resize((416*scale,312*scale),Image.Resampling.NEAREST)
def main():
 records=[];images={}
 for key,note in NOTES.items():
  im,fill=drawing(key);images[key]=im;name=f'luna_brave_{key}-v1';im.save(OUT/f'{name}.png')
  (OUT/f'{name}.json').write_text(json.dumps(dict(note=note,replaces=f'smash-nine-prototype/assets/art/skill_icons/luna_brave_{key[0]}.png',frames=1,fps=0),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
  records.append(measure(key,im,fill))
 (REPORT/'measurements.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
 board=Image.new('RGB',(1712,4860),'#0a0d14');bd=ImageDraw.Draw(board)
 for index,variant in enumerate(('current','a','b')):
  icons={} if variant=='current' else {k:images[f'{k}-{variant}'] for k in 'jkl'}
  c=contact(icons);c4=contact(icons,4);c.save(REPORT/f'set_{variant}_1x.png');c4.save(REPORT/f'set_{variant}_4x.png');y=index*1620
  bd.text((24,y+12),f'{variant.upper()} | Rows: Frey / Yuki / Luna / BRAVE LUNA / Nova / Rio | Columns: J K L I',font=font,fill='white')
  board.paste(c,(24,y+48));bd.text((464,y+75),'1x | dark #141824 / light #d9dde3',font=font,fill='white')
  bd.text((464,y+110),'Fourth row: current / candidate A / candidate B. Heart Laser I unchanged.',font=font,fill='white')
  board.paste(c4,(24,y+372))
 board.save(REPORT/'board.png')
 for scale in (1,4):
  detail=Image.new('RGB',(416,180),'#0a0d14')
  for row,variant in enumerate(('current','a','b')):
   icons={} if variant=='current' else {k:images[f'{k}-{variant}'] for k in 'jkl'}
   detail.paste(contact(icons).crop((0,156,416,204)),(0,row*60+6))
  detail.resize((416*scale,180*scale),Image.Resampling.NEAREST).save(REPORT/f'brave_rows_{scale}x.png')
 print(json.dumps(records,ensure_ascii=False,indent=2))
 failed=[(r['file'],k) for r in records for k,v in r['checks'].items() if not v]
 if failed:raise SystemExit(f'FAILED: {failed}')
 print('PASS: 6 PNGs / 42 numeric checks. Visual review is separate.')
if __name__=='__main__':main()
