from pathlib import Path
import json, hashlib, numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[4]
R=ROOT/'reports/codex-art-70';A=ROOT/'smash-nine-prototype/assets/art/story'
picks=json.loads((R/'selection.json').read_text())
m=json.loads((R/'measurements-v2.json').read_text())
results=[];failures=[]
def test(name,ok,detail=''):
 results.append({'check':name,'pass':bool(ok),'detail':detail})
 if not ok: failures.append(name)
for item in m:
 k=item['asset'];v=item['variant']
 im=Image.open(A/f'{k}.png' if picks[k]==v else R/'variants'/f'{k}-v{v}.png').convert('RGBA')
 arr=np.array(im);alpha=arr[:,:,3]
 size=(1600,900) if k.startswith('cg_') else (480,120) if k=='dialogue_frame' else (192,36) if k=='name_plate' else (768,176)
 test(f'{k} v{v}: exact size',im.size==size,str(im.size))
 if k.startswith('cg_'):
  test(f'{k} v{v}: opaque',np.all(alpha==255))
 else:
  test(f'{k} v{v}: transparent corners',all(alpha[y,x]==0 for x,y in [(0,0),(im.width-1,0),(0,im.height-1),(im.width-1,im.height-1)]))
  test(f'{k} v{v}: actual transparency',np.count_nonzero(alpha==0)>im.width*im.height*.005)
  test(f'{k} v{v}: no white halo',not np.any((arr[:,:,:3].min(2)>210)&(alpha>0)))
 if k=='dialogue_frame':
  test(f'{k} v{v}: 24px transparent centre',np.all(alpha[24:-24,24:-24]==0))
  test(f'{k} v{v}: stretchable horizontal edge uniform',item['horizontal_edge_uniform'])
  test(f'{k} v{v}: stretchable vertical edge uniform',item['vertical_edge_uniform'])
  test(f'{k} v{v}: crisp alpha',set(np.unique(alpha))=={0,255})
 elif k=='name_plate':
  test(f'{k} v{v}: flat navy alpha235 in stretch zone',np.all(arr[12:24,12:180]==[16,24,39,235]))
  test(f'{k} v{v}: top and bottom gold border2',np.all(arr[1:3,12:180]==[243,205,124,255]) and np.all(arr[33:35,12:180]==[243,205,124,255]))
  ornaments=(arr[:,:,0]==168)|(arr[:,:,2]>arr[:,:,1]+30)
  ornaments[:,12:180]=False
  # Non-flat pixels in the stretchable columns may only be top/bottom gold border.
  middle=arr[:,12:180]
  allowed=((middle==[16,24,39,235]).all(2)|(middle==[243,205,124,255]).all(2)|(middle[:,:,3]==0))
  test(f'{k} v{v}: ornaments contained in12px ends',allowed.all())
 elif k=='shadow_aura':
  test(f'{k} v{v}: every cell has4px clear margin',item['all_margins_ge4'])
  test(f'{k} v{v}: six distinct frames',len({im.crop((128*i,0,128*(i+1),176)).tobytes() for i in range(6)})==6)
  tiledata=[]
  for i in range(6):
   aa=alpha[:,128*i:128*(i+1)]
   center=float(aa[64:160,43:85].mean())
   sides=float(np.concatenate([aa[64:160,16:43],aa[64:160,85:112]],axis=1).mean())
   tiledata.append({'frame':i+1,'body_center_mean_alpha':center,'side_mean_alpha':sides})
   test(f'{k} v{v} frame{i+1}: centre thinner than sides',center<sides)
  item['density']=tiledata
  test(f'{k} v{v}: seam no isolated jump',item['seam_to_median_ratio']<=1.25,f"ratio {item['seam_to_median_ratio']:.4f}; engineering indicator only; animation feel is visual review")
for k in picks:
 raw=Image.open(A/f'{k}_source.png');test(f'{k}: preserved raw exists',raw.width>0)
for v in [1,2]:
 gif=Image.open(R/f'shadow_aura-v{v}-v2.gif')
 test(f'aura v{v} GIF: six frames',gif.n_frames==6)
 timing=[]
 for i in range(gif.n_frames):
  gif.seek(i);timing.append(gif.info.get('duration'))
 test(f'aura v{v} GIF: 10fps',timing==[100]*6,str(timing))
 gif.seek(0);test(f'aura v{v} GIF: infinite loop',gif.info.get('loop')==0)
report={'results':results,'total':len(results),'passed':len(results)-len(failures),'failed':failures,'measurements':m,'manual_review_required':['text-like marks and figures','narrative clarity','tree before/after registration','10fps rising motion and loop rhythm'],'godot':'separate import log'}
(R/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8',newline='\n')
print(f"Pixel checks: {report['passed']}/{report['total']} passed; failures: {failures}")
if failures: raise SystemExit(1)

