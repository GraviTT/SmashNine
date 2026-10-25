from pathlib import Path
import json, hashlib
import numpy as np
from PIL import Image, ImageFilter
R=Path(__file__).resolve().parents[2]; O=R/'art/bakeoff/skill_icons/luna_brave'; P=Path(__file__).resolve().parent
S=R/'smash-nine-prototype/assets/art/skill_icons'
rows=[]
for k in 'jkl':
 for v in 'ab':
  f=O/f'luna_brave_{k}-{v}-v1.png'; im=Image.open(f); a=np.array(im); mask=im.getchannel('A')
  visible=a[:,:,3]>0; interior=np.array(mask.filter(ImageFilter.MinFilter(3)))>0; edge=visible&~interior
  colors=np.unique(a[visible,:3],axis=0); navy=np.array([16,21,34]); no_navy=visible&np.any(a[:,:,:3]!=navy,axis=2)
  covered=np.zeros((40,40),bool)
  for y in range(39):
   for x in range(39):
    block=a[y:y+2,x:x+2]
    if block[0,0,3]==255 and np.all(block==block[0,0]):covered[y:y+2,x:x+2]=True
  b=im.getbbox(); meta=json.loads(f.with_suffix('.json').read_text(encoding='utf-8'))
  checks={'RGBA8_40x40':im.size==(40,40) and im.mode=='RGBA' and f.read_bytes()[24:26]==bytes([8,6]),
  'single_frame':getattr(im,'n_frames',1)==1,'binary_alpha':set(np.unique(a[:,:,3]))=={0,255},
  'six_visible_colors':len(colors)==6,'navy_boundary':bool(np.all(a[edge,:3]==navy)),
  'all_color_pixels_in_2x2_blocks':not bool(np.any(no_navy&~covered)),
  'center_20_20':[(b[0]+b[2])/2,(b[1]+b[3])/2]==[20,20],
  'transparent_canvas_edge':not bool(visible[0].any() or visible[-1].any() or visible[:,0].any() or visible[:,-1].any()),
  'metadata':set(meta)=={'note','replaces','frames','fps'} and meta['frames']==1 and meta['fps']==0 and bool(meta['note']) and meta['replaces']==f'smash-nine-prototype/assets/art/skill_icons/luna_brave_{k}.png'}
  rows.append({'file':f.name,'checks':checks,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()})
# Each variant contains unchanged originals at every slot other than Brave JKL.
board_checks={}
for variant in ('current','a','b'):
 board=Image.open(P/f'set_{variant}_1x.png')
 for panel,bg in enumerate(('#141824','#d9dde3')):
  for row,who in enumerate(('frey','yuki','luna','luna_brave','nova','rio')):
   for col,k in enumerate('jkli'):
    f=O/f'luna_brave_{k}-{variant}-v1.png' if who=='luna_brave' and k!='i' and variant!='current' else S/f'{who}_{k}.png'
    icon=Image.open(f).convert('RGBA'); expected=Image.new('RGB',(40,40),bg);expected.paste(icon,(0,0),icon)
    x=12+208*panel+48*col;y=16+48*row
    assert np.array_equal(np.array(board.crop((x,y,x+40,y+40))),np.array(expected))
 large=Image.open(P/f'set_{variant}_4x.png')
 board_checks[variant]=bool(np.array_equal(np.array(large),np.array(board.resize(large.size,Image.Resampling.NEAREST))))
assert all(board_checks.values())
assert all(all(r['checks'].values()) for r in rows),rows
result={'files':rows,'numeric_checks':sum(len(r['checks']) for r in rows),'board_slots_checked':144,'nearest_4x':board_checks,'note':'Semantic readability is a separate visual judgement.'}
(P/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('PASS: 54 independent file checks; 144 board slots; 3 nearest-neighbour 4x sheets.')
