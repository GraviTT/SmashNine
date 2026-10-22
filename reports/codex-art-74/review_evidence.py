"""Before/after review boards and visible, reproducible landmark rulers."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, statistics, hashlib
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import process as p
from landmarks import groups
from evidence import BOXES as PREVIOUS_BOXES

FIX=p.REPORT/'fix-1';BEFORE=FIX/'before'
BOXES=dict(PREVIOUS_BOXES)
# The earlier side-gear measurement missed the drone's smaller hull. Measure
# the central armoured oval vertically, excluding nozzle, top gear and engine.
BOXES['svartalfheim_cog_drone']=[(24,23,73,60),(25,24,73,59),(25,26,73,60),(25,26,73,59),(26,28,72,59),(26,22,73,56)]
# Tighten placement of the earlier head rulers; preserve the measured widths.
# Bounds enclose the brow/face including the muzzle, excluding rear mane.
BOXES['vanaheim_vine_hound']=[(61,40,89,64),(63,36,91,61),(63,41,89,63),(62,33,87,58),(61,44,88,67),(61,44,86,69)]
PARTS={'midgard_rooftop_slinger':'후드 주황 면의 √면적(px, 목 아래 제외)',
 'svartalfheim_gear_beetle':'등딱지 측면 고정 기어 지름(가로)',
 'svartalfheim_cog_drone':'중앙 장갑 타원 높이(윗기어·노즐·엔진 제외)',
 'vanaheim_vine_hound':'갈기를 뺀 얼굴·주둥이 외곽 가로폭',
 'vanaheim_seed_sprite':'잎을 뺀 씨앗 몸통 가로폭',
 'jotunheim_rune_golem':'어깨 룬 원판 외곽 가로폭'}

def sample(mid,row,base):
 idx=1 if row=='hurt' else 5 if row=='attack' and mid in ['vanaheim_vine_hound','vanaheim_seed_sprite','jotunheim_rune_golem'] else 0
 path=base/f'{mid}-{row}-v1.png'
 return p.frames(path,p.COUNTS[row])[idx],idx

def tile(im,scale=4):
 t=p.n.checker((96,96)).convert('RGBA');t.alpha_composite(im)
 return t.convert('RGB').resize((96*scale,96*scale),Image.Resampling.NEAREST)

def feature(mid,row,im):
 if 'slinger' in mid:
  a=np.array(im).astype(float);r,g,b,al=[a[:,:,i] for i in range(4)]
  mask=(r>70)&(r>g*1.35)&(r>b*1.8)&(al>0);mask[48:]=False
  return max(groups(mask),key=lambda z:z['area'])['bbox']
 return list(BOXES[mid][p.ROWS.index(row)])

def size_boards():
 result=[];tables=[]
 for mid in p.WINDUP:
  panel=Image.new('RGB',(6*400,920),(24,29,40));d=ImageDraw.Draw(panel)
  oldanchor=None;newanchor=None
  for ri,row in enumerate(p.ROWS):
   old,idx=sample(mid,row,BEFORE);new,_=sample(mid,row,p.BAKE)
   ob=feature(mid,row,old)
   oldfactor=json.loads((BEFORE/f'{mid}-{row}-v1.json').read_text('utf-8'))['factor']
   newfactor=json.loads((p.BAKE/f'{mid}-{row}-v1.json').read_text('utf-8'))['factor']
   if 'slinger' in mid:nb=feature(mid,row,new)
   else:
    oldbounds=old.getbbox();newbounds=new.getbbox();scale=newfactor/oldfactor
    # Follow the identical feature through the raw rebuild's one row factor.
    # Raster bounds are rounded to output pixels and displayed for inspection.
    nb=[round(newbounds[k%2]+(ob[k]-oldbounds[k%2])*scale) for k in range(4)]
   axis=1 if 'drone' in mid else 0
   before=ob[axis+2]-ob[axis];after=nb[axis+2]-nb[axis]
   if 'slinger' in mid:
    sizes=[]
    for im in [old,new]:
     a=np.array(im).astype(float);r,g,b,al=[a[:,:,i] for i in range(4)];mask=(r>70)&(r>g*1.35)&(r>b*1.8)&(al>0);mask[48:]=False
     sizes.append(max(groups(mask),key=lambda z:z['area'])['area']**.5)
    before,after=sizes
   if ri==0:oldanchor=before;newanchor=after
   br=before/oldanchor;ar=after/newanchor
   item=dict(monster=mid,row=row,frame=idx+1,part=PARTS[mid],axis='sqrt_area' if 'slinger' in mid else 'height' if axis else 'width',before_px=round(before,2),after_px=round(after,2),before_ratio=round(br,4),after_ratio=round(ar,4),before_box=ob,after_box=nb,before_factor=oldfactor,after_factor=newfactor,within_5_percent=.95<=ar<=1.05,method='출력 4배 눈금판의 같은 부위. 수동 경계는 원본 공통배율 및 전체 프레임 이동으로 추적하고 최종 픽셀 경계로 반올림. 슬링거만 y<48의 가장 큰 주황 연결 성분 면적을 전후 재측정(외곽폭의 1px 연결 변동을 줄이는 등가 선형크기).',manual_boundary_uncertainty_px=0 if 'slinger' in mid else 1)
   result.append(item)
   for j,(im,box,size,ratio) in enumerate([(old,ob,before,br),(new,nb,after,ar)]):
    y=38+j*450;panel.paste(tile(im),(ri*400,y))
    d.text((ri*400+4,y-30),f'{row} F{idx+1} {"BEFORE" if j==0 else "AFTER"}: {size:.2f}px / {ratio:.3f}',font=p.n.font(15),fill='white')
    d.rectangle((ri*400+box[0]*4,y+box[1]*4,ri*400+box[2]*4-1,y+box[3]*4-1),outline=(255,100,210),width=1)
  panel.save(FIX/f'{mid}-size-before-after-4x.png')
  # Replace the obsolete after-only landmark board as well.
  panel.crop((0,450,panel.width,900)).save(p.REPORT/f'{mid}-size-4x.png')
 tables=['| 몬스터 | 행(F) | 측정 부위 | 전 크기 px | 전 / idle | 후 크기 px | 후 / idle | factor 전 → 후 |','|---|---|---|---:|---:|---:|---:|---|']
 for x in result:
  tables.append(f"| {x['monster']} | {x['row']}({x['frame']}) | {x['part']} | {x['before_px']} | {x['before_ratio']:.3f} | {x['after_px']} | {x['after_ratio']:.3f} | {x['before_factor']:.6g} → {x['after_factor']:.6g} |")
 (FIX/'size-table.md').write_text('\n'.join(tables)+'\n','utf-8')
 (FIX/'sizes.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n','utf-8')
 (p.REPORT/'size-measurements.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n','utf-8')
 print('SIZE FAILURES',[(x['monster'],x['row'],x['after_ratio']) for x in result if not x['within_5_percent']])
 assert all(x['within_5_percent'] for x in result),'row landmark outside +/-5 percent'

def colour_boards():
 for mid in ['vanaheim_vine_hound','vanaheim_seed_sprite']:
  current=Image.open(p.ROOT/f'smash-nine-prototype/assets/art/monsters/{mid}_sheet.png').convert('RGBA')
  before=Image.open(BEFORE/f'{mid}_sheet-v1.png').convert('RGBA')
  after=Image.open(p.BAKE/f'{mid}_sheet-v1.png').convert('RGBA')
  board=Image.new('RGB',(1800,800),(24,29,40));d=ImageDraw.Draw(board)
  for j,label in enumerate(['CURRENT GAME','OLD CANDIDATE','FIXED CANDIDATE']):d.text((600*j+12,8),label+' / 1x',font=p.n.font(20),fill='white')
  for ri,row in enumerate(p.ROWS):
   y=42+ri*124
   d.text((8,y),row,font=p.n.font(15),fill='white')
   oldri={'idle':0,'walk':1,'attack':2,'hurt':3}.get(row)
   for j,im in enumerate([current,before,after]):
    if j==0 and oldri is None:continue
    sr=oldri if j==0 else ri;strip=im.crop((0,96*sr,576,96*(sr+1)))
    board.paste(strip,(j*600+8,y+24),strip)
  board.save(p.REPORT/f'{mid}-colour-1x.png')
  large=board.resize((board.width*4,board.height*4),Image.Resampling.NEAREST);large.save(p.REPORT/f'{mid}-colour-4x.png')
  combo=Image.new('RGB',(large.width,board.height+large.height+20),(24,29,40));combo.paste(board,(0,0));combo.paste(large,(0,board.height+20));combo.save(p.REPORT/f'{mid}-colour.png')
 # Compact six-column focus board for report/chat display, still exact 1x+4x.
 focus=Image.new('RGB',(3*400,2*560),(24,29,40));d=ImageDraw.Draw(focus)
 for i,mid in enumerate(['vanaheim_vine_hound','vanaheim_seed_sprite']):
  for j,(label,path) in enumerate([('CURRENT',p.ROOT/f'smash-nine-prototype/assets/art/monsters/{mid}_sheet.png'),('BEFORE',BEFORE/f'{mid}-idle-v1.png'),('AFTER',p.BAKE/f'{mid}-idle-v1.png')]):
   im=Image.open(path).convert('RGBA').crop((0,0,96,96));x=j*400;y=i*560
   d.text((x+8,y+5),mid.replace('vanaheim_','')+' '+label,font=p.n.font(18),fill='white')
   focus.paste(tile(im,1),(x+8,y+35));focus.paste(tile(im,4),(x+8,y+150))
 focus.save(FIX/'colour-focus.png')

def palette_verify():
 report={}
 for mid in ['vanaheim_vine_hound','vanaheim_seed_sprite']:
  lutdata=json.loads((FIX/f'{mid}-palette.json').read_text('utf-8'))
  lut={tuple(x['source']):tuple(x['target']) for x in lutdata['lut']};rows=[]
  for row in p.ROWS:
   inp=np.array(Image.open(FIX/'colour-input'/f'{mid}-{row}.png').convert('RGBA'))
   out=np.array(Image.open(p.BAKE/f'{mid}-{row}-v1.png').convert('RGBA'))
   assert np.array_equal(inp[:,:,3],out[:,:,3])
   for src,dst in zip(inp.reshape(-1,4),out.reshape(-1,4)):
    if src[3]:assert tuple(dst[:3])==lut[tuple(src[:3])]
   rows.append(dict(row=row,alpha_equal=True,every_pixel_matches_shared_lut=True,input_spill=p.n.spill_pixel_count(Image.fromarray(inp)),legacy_green_dominance=p.n.spill_pixel_count(Image.fromarray(out))))
  report[mid]=dict(rows=rows,one_mapping_for_all_rows=True)
 (FIX/'palette-verification.json').write_text(json.dumps(report,indent=2)+'\n','utf-8')
 print('PALETTE six rows per monster: exact shared-LUT and alpha checks passed')

if __name__=='__main__':
 size_boards();colour_boards();palette_verify()
