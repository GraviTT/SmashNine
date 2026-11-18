from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import numpy as np,json
r=Path('reports/codex-art-94b'); out=Path('art/bakeoff/xion/b')
sheet=Image.open(out/'xion-idle-b.png').convert('RGBA')
frames=[sheet.crop((i*128,0,(i+1)*128,128)) for i in range(6)]
for j in range(3):
    board=Image.new('RGBA',(1024,544),'#2a2d34'); d=ImageDraw.Draw(board)
    for k in range(2):
        i=j*2+k
        board.alpha_composite(frames[i].resize((512,512),Image.Resampling.NEAREST),(k*512,32))
        d.text((k*512+20,8),f'XION B  F{i+1} - 4x',fill='white')
    board.convert('RGB').save(r/f'idle-review-{j+1}.png')
boots=[]
for im in frames:
    mask=np.array(im)[:,:,3]>0
    xx=np.flatnonzero(mask[116:121].any(axis=0))
    groups=np.split(xx,np.flatnonzero(np.diff(xx)>1)+1)
    boots.append([{'x_range':[int(g.min()),int(g.max())],'centre':float(g.mean())} for g in groups if len(g)])
print('boots',boots)
(r/'feet-check.json').write_text(json.dumps(boots,indent=2),encoding='utf-8')
roster=[('Xion B',frames[0]),('Frey',Image.open('smash-nine-prototype/assets/art/frey/frey_sheet.png').convert('RGBA').crop((0,0,128,128))),('Rio female',Image.open('smash-nine-prototype/assets/art/rio/rio_female_sheet.png').convert('RGBA').crop((0,0,128,128))),('Nova female',Image.open('smash-nine-prototype/assets/art/nova/nova_female_sheet.png').convert('RGBA').crop((0,0,128,128))),('Luna',Image.open('smash-nine-prototype/assets/art/luna/luna_sheet.png').convert('RGBA').crop((0,0,128,128)))]
# Each row uses a common ground baseline; scale is exact nearest neighbour.
W=5*384; H=(128+42)*2+(384+42)*2
lineup=Image.new('RGB',(W,H),'#2a2d34');d=ImageDraw.Draw(lineup)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
y=0
for scale,bg in [(1,'#2a2d34'),(1,'#c8c4b8'),(3,'#2a2d34'),(3,'#c8c4b8')]:
    rowh=128*scale+42;d.rectangle((0,y,W-1,y+rowh-1),fill=bg)
    fg='#f0f0f0' if bg=='#2a2d34' else '#222222'
    base=y+36+120*scale
    d.line((0,base,W,base),fill='#828282')
    for i,(name,im) in enumerate(roster):
        tile=im.resize((128*scale,128*scale),Image.Resampling.NEAREST)
        x=i*384+(384-tile.width)//2
        foot=im.getbbox()[3]-1
        lineup.paste(tile,(x,base-foot*scale),tile)
        d.text((i*384+12,y+8),f'{name}  {scale}x',font=font,fill=fg)
    y+=rowh
lineup.save(r/'lineup.png')
# GIF uses one shared palette, derived from the six composited frames.
gframes=[]
for im in frames:
    bg=Image.new('RGBA',(128,128),'#2a2d34');bg.alpha_composite(im)
    gframes.append(bg.convert('RGB').resize((512,512),Image.Resampling.NEAREST))
contact=Image.new('RGB',(512*6,512))
for i,f in enumerate(gframes):contact.paste(f,(512*i,0))
pal=contact.quantize(colors=256,method=Image.Quantize.MEDIANCUT)
gframes=[f.quantize(palette=pal,dither=Image.Dither.NONE) for f in gframes]
gframes[0].save(r/'idle-4x.gif',save_all=True,append_images=gframes[1:],duration=[160,160,160,160,160,150],loop=0,optimize=False,disposal=2)
# 4x heads and complete first-frame comparison, each at exact 4x.
board=Image.new('RGBA',(1024,552),'#c8c4b8');d=ImageDraw.Draw(board)
for i,(name,im) in enumerate([roster[0],roster[2]]):
    board.alpha_composite(im.resize((512,512),Image.Resampling.NEAREST),(i*512,40));d.text((i*512+12,10),name+' 4x',fill='#222222')
board.convert('RGB').save(r/'head-reference-4x.png')
meta={'note':'Xion B 짧은 코트 후보. 검정·은색·진홍 스카프, 쌍산탄총. 2차 생성 채택, 게임 미적용.','fps':6.3,'frames':6,'loop':True}
(out/'xion-idle-b.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
