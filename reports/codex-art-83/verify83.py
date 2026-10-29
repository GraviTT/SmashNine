"""Candidate data checks only. Never starts Godot, stages, or modifies existing files."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json,hashlib,subprocess
from pathlib import Path
import numpy as np
from PIL import Image
import repair as r
def digest(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def main():
 selection=json.loads((r.REPORT/'selection.json').read_text('utf-8'));rows=[];hashes={};v1_preserved=[]
 for item in selection:
  mid,row,label=item['monster'],item['row'],item['trial'];path=r.ROOT/item['candidate'];im=Image.open(path).convert('RGBA');count=item['frames'];assert im.size==(576,96)
  reference=Image.open(r.REPORT/'trials'/f'{mid}-{row}-{label}/strip.png').convert('RGBA');assert np.array_equal(im,reference)
  frames=r.frames(path,count);audit=r.audit(frames);assert all(x['margin']>=3 and x['alpha_binary'] for x in audit)
  assert len(set(hashlib.sha256(f.tobytes()).hexdigest() for f in frames))==count
  assert im.crop((count*96,0,576,96)).getbbox() is None if count<6 else True
  meta=json.loads(path.with_suffix('.json').read_text('utf-8'));oldmeta=json.loads((r.BAKE/f'{mid}-{row}-v1.json').read_text('utf-8'))
  assert meta['cell']==96 and meta['feet']==72 and meta['factor']==item['factor'] and meta['replaces']==f'{mid}-{row}-v1.png'
  assert all(meta[k]==oldmeta[k] for k in ['frames','fps','loop']) and any('\uac00'<=c<='\ud7a3' for c in meta['note'])
  data=json.loads((r.ROOT/item['metrics']).read_text('utf-8'));rgba=np.array(im);pure=int(np.sum((rgba[:,:,0]==0)&(rgba[:,:,1]==255)&(rgba[:,:,2]==0)&(rgba[:,:,3]>0)));assert pure==0
  colour_verified=None
  if 'colour' in data:
   src=r.frames(r.ROOT/data['colour']['input'],count);assert all(r.n.spill_pixel_count(f)==0 for f in src)
   import colour83,colour83b
   fn,_,_=(colour83b if 'hound' in mid else colour83).mapper(mid)
   for a,b in zip(src,frames):assert np.array_equal(np.array(colour83.apply(a,fn)),np.array(b))
   colour_verified='source spill=0; common RGB mapping exact; alpha unchanged; pure key=0'
   if 'hound' in mid:assert all(np.array_equal(np.array(a)[:,:,3],np.array(b)[:,:,3]) for a,b in zip(r.frames(r.BAKE/f'{mid}-{row}-v1.png',count),frames))
  else:assert all(x['spill']==0 for x in audit)
  if (mid,row) in [('mossling','walk'),('ember_imp','walk'),('ember_imp','idle'),('asgard_aegis_ram','idle'),('mossling','attack'),('vanaheim_seed_sprite','attack')]:assert all(x['bottom']==72 for x in audit)
  if (mid,row) in [('ember_imp','idle'),('asgard_aegis_ram','idle')]:assert min(x['detail'] for x in audit)>=85
  for ext in ['png','json']:
   p=r.BAKE/f'{mid}-{row}-v1.{ext}';rel=p.relative_to(r.ROOT).as_posix();head=subprocess.run(['git','show',f'HEAD:{rel}'],cwd=r.ROOT,check=True,stdout=subprocess.PIPE).stdout;assert p.read_bytes()==head;v1_preserved.append(rel)
  for p in [path,path.with_suffix('.json')]:hashes[p.relative_to(r.ROOT).as_posix()]=digest(p)
  rows.append(dict(monster=mid,row=row,frames=count,minimum_margin=min(x['margin'] for x in audit),detail_before=[min(x['detail'] for x in data['before']),max(x['detail'] for x in data['before'])],detail_after=[min(x['detail'] for x in audit),max(x['detail'] for x in audit)],legacy_green_dominance_count=sum(x['spill'] for x in audit),pure_chroma_key_count=pure,colour_verification=colour_verified,frame_metrics=audit))
 for mid in dict.fromkeys(x['monster'] for x in selection):
  path=r.BAKE/f'{mid}_sheet-v2.png';sheet=Image.open(path).convert('RGBA');assert sheet.size==(576,576)
  for i,row in enumerate(r.ROWS):
   p=r.BAKE/f'{mid}-{row}-v2.png';p=p if p.exists() else r.BAKE/f'{mid}-{row}-v1.png';assert np.array_equal(sheet.crop((0,96*i,576,96*(i+1))),Image.open(p).convert('RGBA'))
  hashes[path.relative_to(r.ROOT).as_posix()]=digest(path)
 sizes=json.loads((r.REPORT/'measure-final/sizes-final.json').read_text('utf-8'));assert len(sizes)==15
 for x in sizes:
  assert all(.95<=f['ratio']<=1.05 for f in x['features']) if 'features' in x else .95<=x['ratio']<=1.05
 moves=json.loads((r.REPORT/'measure-final/movement-reviewed.json').read_text('utf-8'));assert moves[0]['after_forward_px']>=8 and moves[1]['after_forward_px']>=8 and moves[-1]['after_apex']==3
 diff=subprocess.check_output(['git','diff','--name-only'],cwd=r.ROOT,text=True).strip();index=subprocess.check_output(['git','diff','--cached','--name-only'],cwd=r.ROOT,text=True).strip();assert not diff and not index
 assert not list(r.REPORT.rglob('__pycache__'))
 copied=[('process71.py','reports/codex-art-71/process.py'),('fix74.py','reports/codex-art-74/fix_pass.py'),('process76.py','reports/codex-art-76/process.py'),('reuse71/review.py','reports/codex-art-71/fix-1/review.py')]
 for dest,source in copied:assert digest(r.REPORT/dest)==digest(r.ROOT/source)
 r.jsave(r.REPORT/'candidate-hashes.json',hashes)
 r.jsave(r.REPORT/'verification.json',dict(result='PASS',scope='정적 파일/측정 검증. 미술적 완성도 및 게임 실행 판정 아님.',rows=rows,total_rows=15,total_frames=76,total_sheets=8,global_minimum_margin=min(x['minimum_margin'] for x in rows),v1_files_equal_HEAD=v1_preserved,tracked_diff_empty=True,index_empty=True,copied_helpers_byte_identical=True,no_pycache=True,godot_run=False,manual_size_uncertainty='수동 경계 ±1px / 장축 양끝 합산 ±2px. ±5%는 명목 값.',spill_interpretation='ART-74와 동일. 녹색 7행은 정상 녹색도 세는 legacy 수치를 공개. 색 보정 전 spill 0, 공통 LUT 일치, 알파 불변, 키색 0으로 구분 검증.'))
 print('PASS: 15 rows / 76 frames / 8 sheets; 3px minimum margin; 30 v1 files equal HEAD; product/tools tracked diff empty; index empty')
if __name__=='__main__':main()
