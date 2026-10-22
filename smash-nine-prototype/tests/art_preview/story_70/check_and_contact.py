"""Measure actual output pixels and produce ART-70 review sheets (Pillow only)."""
from pathlib import Path
import json, math, argparse, numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageChops
ROOT=Path(__file__).resolve().parents[4]
parser=argparse.ArgumentParser();parser.add_argument('--revision',default='v2');args=parser.parse_args()
R=ROOT/'reports/codex-art-70';C=R/'candidates'/args.revision
A=ROOT/'smash-nine-prototype/assets/art/story'
J=json.loads((R/'generation_manifest.json').read_text(encoding='utf-8'))
S=json.loads((R/'selection.json').read_text(encoding='utf-8'))
try:
 FONT=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',20)
 SMALL=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',14)
except OSError: FONT=SMALL=ImageFont.load_default()

def bg(size,mode='dark'):
 colors={'dark':((21,25,42),(21,25,42)),'light':((235,237,244),(235,237,244)),'check':((90,96,110),(132,138,150))}
 a,b=colors[mode];im=Image.new('RGB',size,a);d=ImageDraw.Draw(im)
 if mode=='check':
  for y in range(0,size[1],8):
   for x in range(0,size[0],8):
    if (x//8+y//8)%2: d.rectangle((x,y,x+7,y+7),fill=b)
 return im

def comp(im,mode='dark'):
 out=bg(im.size,mode).convert('RGBA');out.alpha_composite(im.convert('RGBA'));return out.convert('RGB')

def label(im,text,pos=(12,8)):
 ImageDraw.Draw(im).text(pos,text,font=SMALL,fill=(235,239,249))

def nine(im,size,m):
 w,h=im.size;W,H=size;out=Image.new('RGBA',size)
 sx=[0,m,w-m,w];sy=[0,m,h-m,h];dx=[0,m,W-m,W];dy=[0,m,H-m,H]
 for y in range(3):
  for x in range(3):
   tile=im.crop((sx[x],sy[y],sx[x+1],sy[y+1]))
   tile=tile.resize((dx[x+1]-dx[x],dy[y+1]-dy[y]),Image.Resampling.NEAREST)
   out.alpha_composite(tile,(dx[x],dy[y]))
 return out

M=[]
for kind in dict.fromkeys(j['id'] for j in J):
 jobs=[j for j in J if j['id']==kind]
 if kind.startswith('cg_'):
  sheet=Image.new('RGB',(2900,len(jobs)*965),(14,18,31))
  for row,j in enumerate(jobs):
   im=Image.open(C/f"{kind}-v{j['variant']}.png").convert('RGB');y=row*965
   label(sheet,f"{kind} v{j['variant']} | final 1600x900 at 1:1",(12,y+6));sheet.paste(im,(0,y+35))
   display=im.resize((1280,720),Image.Resampling.LANCZOS).convert('RGBA')
   bar=Image.new('RGBA',(1280,180),(7,12,28,235));display.alpha_composite(bar,(0,540))
   d=ImageDraw.Draw(display);d.text((54,576),'해설 · 세계수의 심장',font=FONT,fill='#f3cd7c')
   d.text((54,620),'대화 영역 미리보기 — 주요 장면은 위쪽에 남습니다.',font=FONT,fill='#ebeff9')
   label(sheet,'1280x720 display / bottom quarter covered',(1612,y+6));sheet.paste(display.convert('RGB'),(1610,y+35))
   source=A/f"{kind}_source.png" if S[kind]==j['variant'] else R/'variants'/f"{kind}-v{j['variant']}_source.png"
   M.append({'asset':kind,'variant':j['variant'],'size':im.size,'opaque':True,'raw':Image.open(source).size})
  sheet.save(R/f'{kind}_contact-{args.revision}.png')
 elif kind in ['dialogue_frame','name_plate']:
  margin=24 if kind=='dialogue_frame' else 12
  target=(1160,170) if kind=='dialogue_frame' else (220,40)
  sheet=Image.new('RGB',(1400,600*len(jobs)),(21,25,42))
  for row,j in enumerate(jobs):
   im=Image.open(C/f"{kind}-v{j['variant']}.png").convert('RGBA');a=np.array(im)[:,:,3]
   y=row*600;label(sheet,f"{kind} v{j['variant']} 1:1 / slice {margin}px",(12,y+10))
   sheet.paste(comp(im,'check'),(15,y+45))
   lined=comp(im,'dark');d=ImageDraw.Draw(lined);w,h=im.size
   for x in [margin,w-margin]:d.line((x,0,x,h-1),fill='#ff4fd8')
   for yy in [margin,h-margin]:d.line((0,yy,w-1,yy),fill='#ff4fd8')
   sheet.paste(lined,(15+im.width+20,y+45))
   stretch=nine(im,target,margin)
   preview=bg(target).convert('RGBA')
   if kind=='dialogue_frame':
    ImageDraw.Draw(preview).rectangle((10,10,target[0]-11,target[1]-11),fill=(7,12,28,235))
   preview.alpha_composite(stretch)
   d=ImageDraw.Draw(preview)
   d.text((38 if kind=='dialogue_frame' else 32,55 if kind=='dialogue_frame' else 8),'이그드라실의 심장이 고요해졌다.' if kind=='dialogue_frame' else '그림자 프레이',font=FONT if kind=='dialogue_frame' else SMALL,fill='#ebeff9')
   label(sheet,f'9-slice display {target[0]}x{target[1]} with sample text',(15,y+195))
   sheet.paste(preview.convert('RGB'),(15,y+225))
   label(sheet,'dark / light alpha edge check',(15,y+425))
   sheet.paste(comp(im,'dark'),(15,y+455));sheet.paste(comp(im,'light'),(30+im.width,y+455))
   center=a[margin:im.height-margin,margin:im.width-margin]
   data={'asset':kind,'variant':j['variant'],'size':im.size,'mode':im.mode,'alpha_range':[int(a.min()),int(a.max())],'transparent_corners':all(a[yy,xx]==0 for xx,yy in [(0,0),(im.width-1,0),(0,im.height-1),(im.width-1,im.height-1)]),'alpha_unique':np.unique(a).tolist(),'slice_margin':margin,'center_alpha':np.unique(center).tolist(),'white_opaque_pixels':int(((np.array(im)[:,:,:3].min(2)>220)&(a>0)).sum())}
   if kind=='dialogue_frame':
    # Every stretchable edge column / row must be identical.
    data['horizontal_edge_uniform']=all(np.array_equal(a[:,margin],a[:,x]) and np.array_equal(np.array(im)[:,margin],np.array(im)[:,x]) for x in range(margin,im.width-margin))
    data['vertical_edge_uniform']=all(np.array_equal(np.array(im)[margin,:],np.array(im)[yy,:]) for yy in range(margin,im.height-margin))
   else:
    data['flat_center_rgba']=np.unique(np.array(im)[12:24,12:180].reshape(-1,4),axis=0).tolist()
    data['border_2px_straight']=np.all(np.array(im)[1:3,12:180]==[243,205,124,255]).item()
   M.append(data)
  sheet.save(R/f'{kind}_contact-{args.revision}.png')
 else:
  sheet=Image.new('RGB',(1150,550*len(jobs)),(21,25,42))
  for row,j in enumerate(jobs):
   im=Image.open(C/f"{kind}-v{j['variant']}.png").convert('RGBA');y=row*550
   label(sheet,f"shadow aura v{j['variant']} — 768x176 1:1",(12,y+8))
   sheet.paste(comp(im,'check'),(15,y+40));frames=[];boxes=[]
   for i in range(6):
    f=im.crop((128*i,0,128*(i+1),176));a=np.array(f)[:,:,3];box=f.getchannel('A').getbbox();boxes.append(box)
    back=bg((128,176)).convert('RGBA');back.alpha_composite(f)
    d=ImageDraw.Draw(back);d.rectangle((43,64,84,159),fill=(135,140,150,255),outline=(200,205,214,255))
    d.line((4,160,123,160),fill=(88,214,168,255));d.line((64,4,64,171),fill=(45,60,80,100))
    d.text((5,5),str(i+1),font=SMALL,fill='#eeeeee');frames.append(back.convert('RGB'))
    sheet.paste(back.convert('RGB'),(15+i*138,y+270))
   frames[0].save(R/f"shadow_aura-v{j['variant']}-{args.revision}.gif",save_all=True,append_images=frames[1:],duration=100,loop=0,disposal=2)
   # Premultiplied RGBA difference includes alpha and color, normalized to 0..255.
   values=[]
   for i in range(6):
    f=np.array(im.crop((i*128,0,(i+1)*128,176))).astype(float)
    f[:,:,:3]*=f[:,:,3:4]/255;values.append(f)
   diffs=[float(np.abs(values[(i+1)%6]-values[i]).mean()) for i in range(6)]
   M.append({'asset':kind,'variant':j['variant'],'size':im.size,'frames':6,'fps':10,'pivot':[64,160],'boxes':boxes,'margins':[[b[0],b[1],128-b[2],176-b[3]] for b in boxes],'all_margins_ge4':all(b[0]>=4 and b[1]>=4 and b[2]<=124 and b[3]<=172 for b in boxes),'adjacent_premultiplied_mae':diffs,'seam_mae':diffs[-1],'seam_to_median_ratio':diffs[-1]/float(np.median(diffs[:-1])),'center_alpha_mean':float(np.array(im)[:,43:85,3].mean()),'white_halo_pixels':int(((np.array(im)[:,:,:3].min(2)>210)&(np.array(im)[:,:,3]>0)).sum())})
  sheet.save(R/f'shadow_aura_contact-{args.revision}.png')
(R/f'measurements-{args.revision}.json').write_text(json.dumps(M,indent=2),encoding='utf-8',newline='\n')
print(json.dumps(M,indent=2))

