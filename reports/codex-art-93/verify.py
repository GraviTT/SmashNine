"""Read-only verification of delivered ART-93 assets; emits a short summary."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json
from pathlib import Path
import numpy as np
from PIL import Image
from inspect_inputs import ROOT, OUT, sha, frames

def main():
 rows=json.loads((OUT/'measurements.json').read_text('utf-8'))
 count=0
 for x in rows:
  p=ROOT/x['new'];im=Image.open(p).convert('RGBA');meta=json.loads(p.with_suffix('.json').read_text('utf-8'))
  oldmeta=json.loads((ROOT/x['old']).with_suffix('.json').read_text('utf-8'))
  assert sha(p)==x['output_sha256'] and im.size==(576,96)
  assert not im.crop((384,0,576,96)).getbbox()
  assert meta['from_raw'] and sha(ROOT/meta['raw_path'])==x['raw_sha256']
  assert 1<=meta['size_used']<=meta['size_k']
  assert meta['factor']==x['old_factor']*meta['size_used']
  assert all(meta[k]==oldmeta[k] for k in ['frames','fps','cell','feet','loop'])
  for i,f in enumerate(frames(p)):
   a=np.array(f);b=f.getbbox();assert min(b[0],b[1],96-b[2],96-b[3])>=4
   assert set(np.unique(a[:,:,3])).issubset({0,255})
   assert list(b)==x['after'][i]['bbox']
   if x['monster']=='yggdrasil_root_oracle' and x['row']=='windup':assert b[3]-1==72
   count+=1
 protected=json.loads((OUT/'input-hashes.json').read_text('utf-8'))
 changed=[p for p,h in protected.items() if not(ROOT/p).is_file() or sha(ROOT/p)!=h]
 assert not changed,changed
 paths=(OUT/'commit-paths.txt').read_text('utf-8').splitlines()
 assert len(paths)==len(set(paths))
 for p in paths:
  assert (ROOT/p).is_file(),p
  assert not any(v in p for v in ['art/raw/','__pycache__','run.log','build_rows.py'])
 print(json.dumps(dict(rows=len(rows),frames=count,protected_files_unchanged=len(protected),stage_files=len(paths),result='PASS')))

if __name__=='__main__':main()
