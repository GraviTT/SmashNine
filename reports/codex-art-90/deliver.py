"""Publish reviewed ART-90 candidates only. No git mutations, no product/tools writes."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json,hashlib,math
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
import work as w
R=w.ROOT;B=w.BAKE;P=w.REPORT;RAW=w.RAW
ROWS=['idle','walk','windup','attack','hurt','defeat'];COUNTS=[6,6,4,6,2,4]
def metrics(im):
 a=np.array(im);b=im.getbbox();mask=a[:,:,3]>0
 return dict(bbox=list(b) if b else None,margin=min(b[0],b[1],im.width-b[2],im.height-b[3]) if b else None,bottom=b[3]-1 if b else None,alpha_values=np.unique(a[:,:,3]).tolist(),detail=w.n.interior_detail(im),spill_legacy=w.n.spill_pixel_count(im),area=int(mask.sum()),rgba_sha256=hashlib.sha256(a.tobytes()).hexdigest())
def speckle_stats(before,after):
 a=np.asarray(before).astype(float);b=np.asarray(after).astype(float);rgb=a[:,:,:3];leaf=(rgb[:,:,1]>rgb[:,:,0]*1.08)&(rgb[:,:,1]>rgb[:,:,2]*1.08)&(a[:,:,3]>0)
 shifts=[(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]
 mask=leaf&(np.stack([np.roll(np.roll(leaf,y,0),x,1) for y,x in shifts]).sum(0)>=6)
 def calc(ar):
  lum=ar[:,:,:3].mean(2);med=np.median(np.stack([np.roll(np.roll(lum,y,0),x,1) for y,x in shifts]),axis=0);delta=np.abs(lum-med)
  return {'outliers_gt25':int((mask&(delta>25)).sum()),'outliers_gt35':int((mask&(delta>35)).sum()),'mean_abs_deviation':float(delta[mask].mean())}
 return dict(before=calc(a),after=calc(b),evaluated=int(mask.sum()),changed_rgb_pixels=int(np.any(a[:,:,:3]!=b[:,:,:3],2).sum()),alpha_identical=bool(np.array_equal(a[:,:,3],b[:,:,3])))
def compare_row(old,new,count,cell=96):
 return [dict(frame=i+1,unchanged=np.array_equal(np.array(x),np.array(y)),before=metrics(x),after=metrics(y)) for i,(x,y) in enumerate(zip(w.frames(old,count,cell),w.frames(new,count,cell)))]
def main():
 outputs=[];record={};
 for row,oldver in [('attack','v1'),('defeat','v2')]:
  old=w.copy(f'art/bakeoff/monsters/yggdrasil_root_guardian-{row}-{oldver}.png');dest=B/f'monsters/yggdrasil_root_guardian-{row}-v2.png'
  if row=='attack' and dest.exists():assert w.sha(dest)==w.sha(RAW/f'guardian-{row}-final.png'),'new version differs; inspect before rerunning'
  w.load(RAW/f'guardian-{row}-final.png').save(dest)
  meta=json.loads(w.copy(f'art/bakeoff/monsters/yggdrasil_root_guardian-{row}-{oldver}.json').read_text('utf-8'))
  meta['note']+=' ART-90: F1만 원본 전체 개체 bbox에 투명 주변 4 원본px를 포함해 기존 공통 배율로 재슬라이싱. 상단 여백 3→4px, 높이 70→69px, 발 y72 유지. 재작화·부분 붙이기·프레임별 축소 없음. F1 외 RGBA 동일. ART-88의 F1 미해결 기록은 이 수정으로 해소.'
  meta['replaces']=f'yggdrasil_root_guardian-{row}-v1.png'
  meta['art90']=dict(method='source reslice with transparent padding; LANCZOS/unsharp60/alpha128/despill auto',source=f'art/raw/art-90/inputs/art/raw/monsters-76/yggdrasil_root_guardian-{row}.png',source_padding=4,changed_frames=[1],before_top=3,after_top=4,feet=72,review='reports/codex-art-90/README.md')
  w.js(dest.with_suffix('.json'),meta);outputs += [dest,dest.with_suffix('.json')]
  record['guardian_'+row]=compare_row(old,dest,6 if row=='attack' else 4)
 hound=[]
 for row,count in zip(ROWS,COUNTS):
  old=w.copy(f'art/bakeoff/monsters/vanaheim_vine_hound-{row}-v2.png');dest=B/f'monsters/vanaheim_vine_hound-{row}-v2.png';w.load(RAW/f'hound-{row}-final.png').save(dest)
  meta=json.loads(w.copy(f'art/bakeoff/monsters/vanaheim_vine_hound-{row}-v2.json').read_text('utf-8'));fs=w.frames(old,count);ns=w.frames(dest,count)
  stats=[speckle_stats(x,y) for x,y in zip(fs,ns)]
  meta['note']+=' ART-90: 잎 내부의 주변 중앙값 대비 25 초과 고립 대비만 RGB 80% 중앙값 혼합으로 완화. 밝은 눈 코어와 주변 3px는 보호. 실루엣/알파/위치/배율/눈/갈색 목질은 유지. 모든 점 제거가 아닌 잎 질감 보존형 잔점 정리.'
  meta['art90']=dict(method='leaf-only local outlier attenuation; one pass; no whole-frame blur',changed_pixels=sum(x['changed_rgb_pixels'] for x in stats),outliers_before=sum(x['before']['outliers_gt35'] for x in stats),outliers_after=sum(x['after']['outliers_gt35'] for x in stats),alpha_unchanged=True,review='reports/codex-art-90/README.md')
  w.js(dest.with_suffix('.json'),meta);outputs += [dest,dest.with_suffix('.json')]
  hound.append(dict(row=row,frames=compare_row(old,dest,count),speckle=stats))
 record['hound']=hound
 for mid in ['yggdrasil_root_guardian','vanaheim_vine_hound']:
  sheet=Image.new('RGBA',(576,576))
  for ri,row in enumerate(ROWS):
   p=B/f'monsters/{mid}-{row}-v2.png'
   if not p.exists():p=B/f'monsters/{mid}-{row}-v1.png'
   sheet.paste(w.load(p),(0,ri*96))
  dest=B/f'monsters/{mid}_sheet-v2.png';sheet.save(dest);outputs.append(dest)
 dest=B/'monsters/legacy/alfheim_moon_stag_sheet-fix1.png';w.load(RAW/'stag-trial.png').save(dest)
 old=w.copy('art/bakeoff/monsters/legacy/alfheim_moon_stag_sheet-fix1.png');meta=json.loads(w.copy('art/bakeoff/monsters/legacy/alfheim_moon_stag_sheet-fix1.json').read_text('utf-8'))
 meta['note']='L12/L27 fallback 후보. ART-90: 기존 공격행 공통 0.25→원본 재추출 F1·F2 0.294(대기/피격의 원본 배율). F3는 같은 몸 크기에서 폭 초과하므로 도약을 모은 전신 재작화, F4는 중복 F1 대신 착지 회복 전신 재작화. 4장 모두 고유. 공격 외 20셀은 ART-87 fix1과 RGBA 동일; 피격 복구 유지.'
 oldsheet=w.load(old);new=w.load(dest);trials=json.loads((RAW/'stag-trial.json').read_text('utf-8'));recs=[]
 for i,t in enumerate(trials):
  t.update(row='attack',method='re-slice' if i<2 else 'whole-frame redraw, built-in image tool',source='art/raw/art-90/inputs/smash-nine-prototype/assets/art/monsters/alfheim_moon_stag_source.png' if i<2 else f'art/raw/art-90/stag-F{i+1}-generated.png',feet_boundary=72,before=metrics(oldsheet.crop((i*96,192,(i+1)*96,288))),after=metrics(new.crop((i*96,192,(i+1)*96,288))))
  recs.append(t)
 meta['frames']=recs+[x for x in meta['frames'] if x['row']!='attack'];meta['candidate_file_sha256']=w.sha(dest);meta['art90_input_sha256']=w.sha(old);meta['art90_unchanged_cells_rgba_identical']=[[r,c] for r in range(4) for c in range(6) if r!=2 or c>=4]
 meta['art90_size_note']='F1/F2는 원본 배율 0.294. 단일 생성 프레임 F3/F4는 각자 원본 해상도가 달라 0.065/0.075. 머리/다리를 붙이지 않고 전신 전체만 축소. 96셀/4px 여백 유지. 같은 체격 여부는 4배 육안 대조이며 모든 해부 부위 ±5% 인증 아님.'
 w.js(dest.with_suffix('.json'),meta);outputs += [dest,dest.with_suffix('.json')];record['stag']=recs
 w.js(P/'measurements.json',record)
 w.js(P/'outputs.json',[str(p.relative_to(R)).replace('\\','/') for p in outputs])
 print('Delivered',len(outputs),'PNG/JSON files; no git commands executed.')
if __name__=='__main__':main()
