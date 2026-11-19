from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2]
R=ROOT/'reports/codex-art-95a'
for c in 'cd':
 im=Image.open(R/f'normalize-{c}/xion-idle-{c}.png').convert('RGBA').crop((0,0,128,128))
 im.save(ROOT/f'art/bakeoff/xion/{c}/xion-idle-{c}.png')
 im.resize((512,512),Image.Resampling.NEAREST).save(R/f'idle-{c}-4x.png')
def font(n):return ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
def sprite(p):return Image.open(ROOT/p).convert('RGBA').crop((0,0,128,128))
rows=[('Xion C','art/bakeoff/xion/c/xion-idle-c.png'),('Xion D','art/bakeoff/xion/d/xion-idle-d.png'),
      ('Frey','smash-nine-prototype/assets/art/frey/frey_sheet.png'),('Rio female','smash-nine-prototype/assets/art/rio/rio_female_sheet.png'),
      ('Nova female','smash-nine-prototype/assets/art/nova/nova_female_sheet.png'),('Luna','smash-nine-prototype/assets/art/luna/luna_sheet.png')]
panels=[('#2a2d34',1),('#c8c4b8',1),('#2a2d34',3),('#c8c4b8',3)]
width=2360;heights=[128*s+64 for _,s in panels]
lineup=Image.new('RGBA',(width,sum(heights)))
d=ImageDraw.Draw(lineup);y=0
for (bg,s),h in zip(panels,heights):
 d.rectangle((0,y,width-1,y+h-1),fill=bg);fg='#f1eee6' if bg=='#2a2d34' else '#24262c'
 d.text((12,y+5),f'{s}x  |  {bg}  |  feet y=120',font=font(18),fill=fg)
 d.line((12,y+55+121*s,width-12,y+55+121*s),fill='#777b81')
 for i,(name,p) in enumerate(rows):
  im=sprite(p);x=10+i*390+(390-128*s)//2
  lineup.alpha_composite(im.resize((128*s,128*s),Image.Resampling.NEAREST),(x,y+55))
  d.text((20+i*390,y+30),name,font=font(20),fill=fg)
 y+=h
lineup.convert('RGB').save(R/'lineup.png')
# Exactly 4x nearest-neighbour crops preserve the relative head scale.
heads=Image.new('RGBA',(864,280),'#c8c4b8');draw=ImageDraw.Draw(heads)
for i,(label,p,box) in enumerate([(rows[0][0],rows[0][1],(38,16,94,72)),(rows[1][0],rows[1][1],(38,16,94,72)),('Rio female',rows[3][1],(54,23,110,79))]):
 heads.alpha_composite(sprite(p).crop(box).resize((224,224),Image.Resampling.NEAREST),(i*288+30,45))
 draw.text((i*288+30,12),label,font=font(22),fill='#23242a')
heads.convert('RGB').save(R/'heads-4x.png')
# Full-size references already have dark/light plates; these are extra anatomy crops.
for c,boxes in {'c':[(580,505,855,755),(265,625,500,850),(285,1170,900,1440),(475,145,735,365)],
                'd':[(455,540,745,740),(755,695,945,910),(280,1160,830,1440),(475,145,725,365)]}.items():
 im=Image.open(R/f'illustration-{c}-light.png').convert('RGB')
 board=Image.new('RGB',(1280,1500),'#c8c4b8');dr=ImageDraw.Draw(board)
 for i,box in enumerate(boxes):
  part=im.crop(box).resize(((box[2]-box[0])*2,(box[3]-box[1])*2),Image.Resampling.NEAREST)
  x=0 if i!=1 else 660;y=40 if i<2 else (560 if i==2 else 1230)
  if i==3:
   part=im.crop(box);x=20;y=1230
  board.paste(part,(x,y));dr.text((x+8,y-30),['Hand 1 - 2x','Hand 2 - 2x','Boots - 2x','Head - 1x'][i],font=font(22),fill='#23242a')
 board.save(R/f'anatomy-{c}.png')
# Small final overview for the report, separate from the original-size QA plates.
overview=Image.new('RGB',(1024,920),'#2a2d34');draw=ImageDraw.Draw(overview)
for i,c in enumerate('cd'):
 im=Image.open(R/f'illustration-{c}-dark.png').resize((512,768),Image.Resampling.LANCZOS)
 overview.paste(im,(i*512,40));draw.text((i*512+24,10),f'XION {c.upper()}',font=font(24),fill='#eee9e1')
 si=sprite(f'art/bakeoff/xion/{c}/xion-idle-{c}.png').resize((128,128),Image.Resampling.NEAREST)
 overview.paste(si,(i*512+360,780),si)
 draw.text((i*512+24,825),'Illustration + 128px idle',font=font(20),fill='#eee9e1')
overview.save(R/'overview.png')
illustrations=json.loads((R/'illustration-metrics.json').read_text(encoding='utf-8'))
metrics={'generation':{'tool':'built-in image_gen','c_illustration_outputs':3,'d_illustration_outputs':3,'c_idle_outputs':2,'d_idle_outputs':1,'blocked_idle_calls':1,
  'selected':{'c_illustration':'c-illustration-chroma.png','d_illustration':'d-illustration-proportion.png','c_idle':'c-idle-02.png','d_idle':'d-idle-01.png'},
  'raw_directory':'art/raw/xion-95a/','source_sha256':{}},'concepts':{},'qa':{'lineup_size':list(lineup.size),'head_board_scale':4,'in_game_test':False}}
for p in sorted((ROOT/'art/raw/xion-95a').glob('*.png')):
 metrics['generation']['source_sha256'][p.name]=hashlib.sha256(p.read_bytes()).hexdigest()
for c in 'cd':
 n=json.loads((R/f'normalize-{c}/metrics.json').read_text(encoding='utf-8'))
 metrics['concepts'][c]={'illustration':illustrations[c],'sprite':{'size':[128,128],'frames':1,'factor':n['summary']['common_scale'],
  'height':n['frames'][0]['body_height'],'feet_y':n['frames'][0]['bottom'],'margin':n['frames'][0]['margin'],
  'green_spill':n['summary']['remaining_spill_pixels'][0],'border_clear':n['summary']['borders_clear'],'alpha_binary':n['summary']['alpha_binary'],
  'detail':n['summary']['interior_detail_mean'],'rio_idle_mean':n['summary']['reference_interior_detail_mean'],
  'detail_ratio_vs_rio_idle_mean':n['summary']['interior_detail_ratio'],
  'rio_f1_detail':n['reference']['frames'][0]['interior_detail'],
  'detail_ratio_vs_rio_f1':round(n['summary']['interior_detail_mean']/n['reference']['frames'][0]['interior_detail'],4),
  'packaging':'normalize.py emits six columns even for grid 1x1. Final is the unchanged first 128x128 cell; five empty columns omitted.'}}
 (ROOT/f'art/bakeoff/xion/{c}/xion-idle-{c}.json').write_text(json.dumps({'note':('Xion C 후보: 잿빛 머리, 괴물 가죽 판초, 붕대와 쌍산탄총. ' if c=='c' else 'Xion D 후보: 버건디 케이프 코트, 땋은 머리와 회중시계, 쌍열 산탄총. ')+'대기 한 프레임, 높이 98px, 발 y=120. 게임 미적용.', 'frames':1},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
manual={'c':{'illustration_crown_chin_sole_y':[160,337,1422],'illustration_heads':7.13,'sprite_crown_chin_y':[23,56],'sprite_head_height':33,'sprite_heads':2.97,'head_ratio_vs_rio':round(33/28,4)},
        'd':{'illustration_crown_chin_sole_y':[150,324,1427],'illustration_heads':7.34,'sprite_crown_chin_y':[23,55],'sprite_head_height':32,'sprite_heads':3.06,'head_ratio_vs_rio':round(32/28,4)}}
for c in 'cd':
 metrics['concepts'][c]['manual_landmarks']={**manual[c],'method':'Human-selected crown/chin/sole positions, not automatic anatomy detection; illustration uncertainty +/-3px, sprite +/-1px.', 'rio_head_height':28,'rio_crown_chin_y':[35,63]}
 metrics['concepts'][c]['visual_review']={'illustration_full_size_dark_and_light':True,'hands_and_boots_at_2x':True,'sprite_at_4x':True,'two_complete_matching_shotguns':True,'clear_front_face':True,'rear_hologram':True,
  'limits':'Head 14-18% larger than Rio main head. Individual sprite fingers/trigger and C wristwatch have weak 128px readability. Occluded fingers not individually countable.'}
(R/'metrics.json').write_text(json.dumps(metrics,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Packaged lineup, overview, anatomy plates, head board, metrics and one-frame JSONs.')
