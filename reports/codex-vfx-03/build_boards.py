"""Static compositing boards, NOT screenshots of an integrated game."""
from pathlib import Path
import json
import numpy as np
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2];R=Path(__file__).resolve().parent;P=ROOT/'smash-nine-prototype/assets/art'
E=ROOT/'art/bakeoff/effects/frey';N=Image.Resampling.NEAREST
F=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',12);FB=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',16)
MAN=[]
def label(im,xy,text,colour='#dce4ed',font=F):ImageDraw.Draw(im).text(xy,text,fill=colour,font=font)
def frames(name,v,n):
 im=Image.open(E/f'{name}-{v}-v1.png').convert('RGBA');w=im.width//n
 return [im.crop((i*w,0,(i+1)*w,im.height)) for i in range(n)]
def save(im,name):im.convert('RGB').save(R/name)
def scale(im,n):return im.resize((im.width*n,im.height*n),N)
def hero(name='frey',hover=False):
 path=P/name/(f'{name}_moves_sheet.png' if hover else f'{name}_sheet.png');im=Image.open(path).convert('RGBA');w=im.width//6
 return im.crop((0,3*w if hover else 0,w,4*w if hover else w)),(w//2,152 if hover else 120)
H,HA=hero(hover=True);ID,IA=hero();LU,LA=hero('luna')
def put(im,art,anchor,pos,factor=1,additive=False):
 if factor!=1:art=art.resize((round(art.width*factor),round(art.height*factor)),N)
 offset=(round(pos[0]-anchor[0]*factor),round(pos[1]-anchor[1]*factor))
 if additive:
  layer=Image.new('RGBA',im.size);layer.alpha_composite(art,offset)
  a=np.array(im);b=np.array(layer);a[:,:,:3]=np.minimum(a[:,:,:3].astype(np.uint16)+b[:,:,:3].astype(np.uint16)*(b[:,:,3:4]>0),255).astype(np.uint8)
  im.paste(Image.fromarray(a))
 else:im.alpha_composite(art,offset)
def cross(im,x,y,colour='#55c0c5'):
 d=ImageDraw.Draw(im);d.line((x-3,y,x+3,y),fill=colour);d.line((x,y-3,x,y+3),fill=colour)
def bg(size):
 # Existing realm art, dimmed as in the game's art direction. Not a new asset.
 src=Image.open(P/'realm_asgard/bg_far.png').convert('RGB');src=src.resize(size,N)
 a=np.array(src).astype(float)*.22+np.array([9,11,19]);a=np.minimum(a,255).astype(np.uint8)
 return Image.fromarray(a).convert('RGBA')
def wings(v):
 fs=frames('frey_wings',v,6);board=Image.new('RGBA',(660,440),'#151c2b')
 for i,f in enumerate(fs):
  panel=bg((220,220));feet=(110,181)
  put(panel,f,(128,240),feet,.5,additive=True);put(panel,H,HA,feet)
  label(panel,(8,8),f'WINGS {v.upper()} / {i+1} / {i*50:03d}ms')
  label(panel,(8,200),'0.5x / ADD / root -55px')
  cross(panel,*feet);cross(panel,110,126,'#e278c8')
  board.alpha_composite(panel,((i%3)*220,(i//3)*220))
  MAN.append({'board':f'wings_{v}_1x.png','frame':i+1,'feet':feet,'root':[110,126],'effect_scale':.5,'hero_anchor':HA,'hero_scale':1})
 for z in (1,2,4):save(scale(board,z),f'wings_{v}_{z}x.png')
 return board
def wave(v):
 fs=frames('frey_wave',v,4);board=Image.new('RGBA',(560,350),'#151c2b')
 label(board,(12,8),f'WAVE {v.upper()}  /  4 frames @ 16 fps  /  flight loop',font=FB)
 for i,f in enumerate(fs):
  board.alpha_composite(f,(20+i*130,31));label(board,(20+i*130,160),f'{i+1}  ({i*62.5:g}ms)')
 feet=(113,322);put(board,H,HA,feet)
 pos=(300,270);put(board,fs[1],(64,64),pos)
 d=ImageDraw.Draw(board);d.rectangle((278,222,322,317),outline='#48dee6',width=1)
 d.line((169,270,231,270),fill='#b3c5d7');d.polygon([(231,270),(225,267),(225,273)],fill='#b3c5d7')
 label(board,(370,222),'cyan: hitbox 45 x 96');label(board,(370,244),'gold: art 60 x 100');label(board,(370,266),'anchor (64,64)');label(board,(370,288),'moves RIGHT')
 cross(board,*pos)
 save(board,f'wave_{v}_1x.png');save(scale(board,4),f'wave_{v}_4x.png')
 MAN.append({'board':f'wave_{v}_1x.png','hitbox_rect':[278,222,45,96],'wave_centre':pos,'effect_scale':1})
 return board
def light(v):
 fs=frames('frey_ult_light',v,6);board=Image.new('RGBA',(2160,1500),'#151c2b')
 for i,f in enumerate(fs):
  panel=bg((720,750));centre=(360,384);feet=(360,424);other=(610,424)
  put(panel,f,(168,168),centre,2,additive=True)
  d=ImageDraw.Draw(panel);d.rectangle((0,426,720,442),fill='#303b50');d.line((0,426,720,426),fill='#75809a')
  put(panel,ID,IA,feet);put(panel,LU,LA,other)
  label(panel,(18,14),f'LIGHT {v.upper()} / {i+1} / {i/13.3*1000:.0f}ms | 2x ADD | COMPOSITE, NOT GAME CAPTURE',font=FB)
  cross(panel,*centre);cross(panel,*other)
  d.line((360,458,610,458),fill='#4d9ea6');d.line((360,453,360,463),fill='#4d9ea6');d.line((610,453,610,463),fill='#4d9ea6')
  label(panel,(448,465),'250px horizontal')
  label(panel,(18,720),'Centre: feet -40px (current _show_light)  |  full frame 672px / intended reach R330')
  board.alpha_composite(panel,((i%3)*720,(i//3)*750))
  # A separate exact 4x zoom of each entire in-context panel for inspection.
  # One at a time: <=35 MB in memory, not a video frame dump.
  save(scale(panel,4),f'light_{v}_f{i+1}_4x.png')
  MAN.append({'board':f'light_{v}_display_2x.png','frame':i+1,'effect_centre':centre,'frey_feet':feet,'other_feet':other,'effect_scale':2,'horizontal_separation':250,'panel_size':[720,750]})
 save(board,f'light_{v}_display_2x.png')
 return board
def slow():
 board=Image.new('RGBA',(640,210),'#151c2b')
 arts=[('SLOW A',Image.open(ROOT/'art/bakeoff/ui/status/slow-a-v1.png')),('SLOW B',Image.open(ROOT/'art/bakeoff/ui/status/slow-b-v1.png')),('STUN',Image.open(P/'ui/status/stun.png')),('ARMOR',Image.open(P/'ui/status/super_armor.png'))]
 for j,(name,im) in enumerate(arts):
  feet=(80+j*160,182);put(board,ID,IA,feet);put(board,im,(12,12),(feet[0],feet[1]-121));label(board,(20+j*160,14),name,font=FB)
  label(board,(15+j*160,193),'24px / feet -121px')
 save(board,'slow_1x.png');save(scale(board,4),'slow_4x.png')
 return board
def icons(v):
 board=Image.new('RGBA',(400,350),'#0c111c');d=ImageDraw.Draw(board)
 label(board,(12,6),f'FREY K {v.upper()} | full set, 6 rows x 4 keys',font=FB)
 for k,key in enumerate('JKLI'):label(board,(113+k*64,28),key)
 for row,who in enumerate(['frey','yuki','luna','luna_brave','nova','rio']):
  y=49+row*49;label(board,(8,y+18),who)
  for col,key in enumerate('jkli'):
   x=100+col*64;d.rectangle((x,y,x+47,y+47),fill='#141824')
   path=(ROOT/f'art/bakeoff/skill_icons/frey/frey_k-{v}-v1.png') if who=='frey' and key=='k' else (P/f'skill_icons/{who}_{key}.png')
   im=Image.open(path).convert('RGBA');board.alpha_composite(im,(x+4,y+4))
   if who=='frey' and key=='k':d.rectangle((x-1,y-1,x+48,y+48),outline='#e4b84a')
   MAN.append({'board':f'icons_{v}_1x.png','source':path.relative_to(ROOT).as_posix(),'rect':[x+4,y+4,40,40]})
 save(board,f'icons_{v}_1x.png');save(scale(board,4),f'icons_{v}_4x.png')
 return board
def overview(w,wa,l,s,ic):
 out=Image.new('RGBA',(1400,1190),'#111827');label(out,(24,14),'FREY / VFX-03  |  CANDIDATES ONLY  |  A left / B right',font=FB)
 # Representative screen composites, captions outside the assets.
 for col,v in enumerate('ab'):
  x=24+col*690;label(out,(x,50),'WINGS '+v.upper(),font=FB)
  out.alpha_composite(w[v].crop((0,220,660,440)).resize((660,220),N),(x,80))
  label(out,(x,312),'WAVE '+v.upper(),font=FB);out.alpha_composite(wa[v].crop((0,190,560,350)),(x,338))
  label(out,(x,510),'DESCENT LIGHT '+v.upper()+' / frame 6',font=FB)
  panel=l[v].crop((1440,750,2160,1500)).resize((450,469),N);out.alpha_composite(panel,(x,538))
  si=Image.open(ROOT/f'art/bakeoff/ui/status/slow-{v}-v1.png');ki=Image.open(ROOT/f'art/bakeoff/skill_icons/frey/frey_k-{v}-v1.png')
  label(out,(x+475,566),'SLOW '+v.upper(),font=FB);out.alpha_composite(scale(si,4),(x+475,600))
  label(out,(x+475,748),'K ICON '+v.upper(),font=FB);out.alpha_composite(scale(ki,4),(x+475,782))
 label(out,(24,1030),'All scenes are offline composites of real game sprites. No product assets or code were changed.',font=FB)
 label(out,(24,1060),'Wings: 256px @ 0.5x cannot reach 170px; candidate A 117.5px, B 86.5px. Scale decision stays with lead.')
 label(out,(24,1084),'Light boards: art x2 (672px cell), Frey at centre, Luna 250px right. 4x inspection panels are separate.')
 label(out,(24,1108),'Slow marks: 24px above head. K icons: 40px in the complete 24-icon set. Nearest filtering throughout.')
 label(out,(24,1144),'Pick independently: feather silhouette / flight readability / inward pull / slow vs stun / spin + released wave.',font=FB)
 save(out,'board.png')
if __name__=='__main__':
 w={v:wings(v) for v in 'ab'};wa={v:wave(v) for v in 'ab'};l={v:light(v) for v in 'ab'};s=slow();ic={v:icons(v) for v in 'ab'};overview(w,wa,l,s,ic)
 (R/'board_manifest.json').write_text(json.dumps(MAN,indent=2)+'\n',encoding='utf-8')
 print('Context boards + nearest 4x inspection panels saved')
