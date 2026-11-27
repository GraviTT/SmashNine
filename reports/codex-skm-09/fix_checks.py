"""Separate visual anatomy observations from pixel measurements of sword-tip margins."""
import json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from config import ROOT

font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',17)
def dump(p,data):
    p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')

key='rio_female-sword_throw'
sheet=Image.open(ROOT/'rio_female/sword_throw/attempt-2'/f'{key}.png').convert('RGBA')
# Approximate centres marked by visual inspection, NOT an automated hand detector.
hands=[[(103,119),(132,121)],[(104,119),(110,84)],[(98,119),(148,91)],[(98,119),(148,91)],[(98,119),(132,107)],[(103,119),(132,121)]]
board=Image.new('RGB',(1536,1280),(27,34,48));d=ImageDraw.Draw(board)
items=[]
for i,points in enumerate(hands):
    f=sheet.crop((i*192,0,(i+1)*192,192))
    # Upper body plus sword guard; every pixel is shown at 4x.
    crop=f.crop((64,56,160,136)).resize((384,320),Image.Resampling.NEAREST)
    x=(i%3)*512;y=(i//3)*400
    board.paste(crop,(x+48,y+50),crop)
    d.text((x+16,y+12),f'F{i+1}: two hands (visual)',font=font,fill='white')
    for j,(px,py) in enumerate(points):
        cx=x+48+(px-64)*4;cy=y+50+(py-56)*4
        d.ellipse((cx-20,cy-20,cx+20,cy+20),outline=('cyan' if j==0 else 'yellow'),width=2)
        d.text((cx+22,cy-12),'R' if j==0 else 'L',font=font,fill='white')
    items.append({'frame':i+1,'visible_hand_count':2,'right_hand_holds_sword':True,'approximate_hand_centres':points,'method':'visual observation of raw and final 4x frames; marker centres approximate; no automatic anatomy inference'})
# Add F2 first-attempt / selected-attempt close-ups for the specific fix.
for j,attempt in enumerate([1,2]):
    im=Image.open(ROOT/f'rio_female/sword_throw/attempt-{attempt}'/f'{key}.png').convert('RGBA')
    f=im.crop((192,0,384,192)).crop((88,72,148,136)).resize((240,256),Image.Resampling.NEAREST)
    x=j*512+48;y=960;board.paste(f,(x,y),f)
    d.text((x,y-28),f'F2 generation {attempt}: '+('3 hands - rejected' if attempt==1 else '2 hands - selected'),font=font,fill='white')
board.save(ROOT/(key+'-fixes.png'))
dump(ROOT/(key+'-fixes.json'),{'kind':'visual_observation','frames':items,'frame_2_fix':'Removed extra lowered sleeve/hand at viewer-right waist using second image_gen call. No manual anatomy or part compositing.'})

key='rio_male-pierce'
sheet=Image.open(ROOT/'rio_male/pierce/attempt-1'/f'{key}.png').convert('RGBA')
# Each window isolates the visible blade tip from boots and coat, checked on the board.
windows=[(125,125,180,153),(125,120,180,153),(0,100,70,125),(0,115,70,137),(0,118,70,148),(125,125,180,153)]
directions=['right','right','left','left','left','right']
board=Image.new('RGB',(2304,1536),(27,34,48));d=ImageDraw.Draw(board);items=[]
for i,(window,direction) in enumerate(zip(windows,directions)):
    f=sheet.crop((i*192,0,(i+1)*192,192));arr=np.asarray(f)
    l,t,r,b=window;yy,xx=np.nonzero(arr[t:b,l:r,3]);assert len(xx)>0
    extreme=xx.max() if direction=='right' else xx.min()
    y=int(np.median(yy[xx==extreme]))+t;x=int(extreme)+l
    edge_distance=191-x if direction=='right' else x
    box=f.getbbox();margin=min(box[0],box[1],192-box[2],192-box[3])
    assert margin>=4 and edge_distance>=4
    bx=(i%3)*768;by=(i//3)*768
    scaled=f.resize((768,768),Image.Resampling.NEAREST);board.paste(scaled,(bx,by),scaled)
    d.rectangle((bx+16,by+16,bx+751,by+751),outline=(74,112,88),width=2)
    d.line((bx+4*x,by+4*y,bx+(764 if direction=='right' else 0),by+4*y),fill='yellow',width=2)
    d.ellipse((bx+4*x-8,by+4*y-8,bx+4*x+8,by+4*y+8),outline='yellow',width=2)
    d.text((bx+20,by+20),f'F{i+1} tip ({x},{y}) / {direction} edge: {edge_distance}px',font=font,fill='white')
    d.text((bx+20,by+48),f'whole sprite minimum margin: {margin}px',font=font,fill='white')
    items.append({'frame':i+1,'tip_window_ltrb':window,'outward_direction':direction,'tip_pixel':[x,y],'distance_to_outward_cell_edge':edge_distance,'whole_sprite_bbox_ltrb':box,'whole_sprite_minimum_margin':margin})
board.save(ROOT/(key+'-fixes.png'))
dump(ROOT/(key+'-fixes.json'),{'kind':'pixel_measurement_with_visually_selected_tip_windows','cell':192,'method':'Outermost non-transparent tip pixel within an inspected window; distance to x0 or x191. Whole-sprite alpha bbox independently bounds every sword pixel. Pixel indices are zero-based.','frames':items,'minimum_tip_edge_distance':min(f['distance_to_outward_cell_edge'] for f in items),'minimum_whole_sprite_margin':min(f['whole_sprite_minimum_margin'] for f in items)})
print('Sword tip checks:',[(f['frame'],f['tip_pixel'],f['distance_to_outward_cell_edge'],f['whole_sprite_minimum_margin']) for f in items])
