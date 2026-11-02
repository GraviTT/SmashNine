"""File QA for retained review rows. This does not approve art."""
import json, re, hashlib
from pathlib import Path
import numpy as np
from PIL import Image
root=Path('reports/codex-skm-01b')
state=json.loads((root/'state.json').read_text(encoding='utf-8'))
audit={'rows':{},'candidate_count':0,'commit_executed':False}
for row,s in state.items():
 out=root/'frey'/row/'attempt-1'
 m=json.loads((out/'metrics.json').read_text())
 f=json.loads((out/'face-proposed.json').read_text())
 ex=json.loads((out/'extraction.json').read_text())
 sheet=Image.open(out/f'frey-{row}.png').convert('RGBA')
 assert sheet.size==(1152,192)
 assert len(ex['boxes'])==6 and 'no fixed-width cuts' in ex['method']
 assert len(f['frames'])==6
 assert (root/f'frey-{row}.png').read_bytes()==(out/'review4x.png').read_bytes()
 raw=Path(ex['raw']);assert raw.exists()
 for i in range(6):
  a=np.array(sheet.crop((192*i,0,192*(i+1),192)))
  alpha=a[:,:,3];assert set(np.unique(alpha)).issubset({0,255})
  assert not alpha[:4].any() and not alpha[-4:].any() and not alpha[:,:4].any() and not alpha[:,-4:].any()
  v=m['frames'][i]
  assert v['border_clear'] and v['margin']['minimum']>=4
  assert v['remaining_spill_pixels']==0 and v['interior_detail']>=79
  frame=Image.open(out/'frames'/f'{i:02d}.png') if (out/'frames'/f'{i:02d}.png').exists() else None
  if frame is not None:assert np.array_equal(np.array(frame.convert('RGBA')),a)
 gate=all(.95<=v[k]<=1.06 for v in f['frames'] for k in ['eye_ratio','face_width_ratio'])
 candidate=Path(f'art/bakeoff/frey/frey-{row}-v1.png')
 assert s['pass']==False and not gate
 assert not candidate.exists() and not candidate.with_suffix('.json').exists()
 audit['rows'][row]={'size':sheet.size,'frames':6,'factor':m['summary']['common_scale'],'margin':min(v['margin']['minimum'] for v in m['frames']),'spill':0,'detail':[min(v['interior_detail'] for v in m['frames']),max(v['interior_detail'] for v in m['frames'])],'face_gate':gate,'eye':[v['eye_ratio'] for v in f['frames']],'width':[v['face_width_ratio'] for v in f['frames']],'raw_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'sheet_sha256':hashlib.sha256((out/f'frey-{row}.png').read_bytes()).hexdigest()}
ps=(root/'commit.ps1').read_text(encoding='utf-8-sig')
paths=re.findall(r"^    '([^']+)'$",ps,re.M)
expected={'design/tasks/CODEX-SKM-01b.md','reports/codex-skm-01b/README.md',*[f'reports/codex-skm-01b/frey-{r}.png' for r in state]}
assert set(paths)==expected
assert all(Path(p).is_file() for p in paths)
assert 'git add -f' not in ps and 'Co-Authored-By: Codex <noreply@openai.com>' in ps
assert len(list(Path('art/raw/skm-01b').glob('*.png')))==2
audit.update(file_checks='PASS',commit_paths=paths,art_approval='FAIL: both rows outside face gate')
(root/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('PASS: retained review files, 12 frames, commit allowlist. Art gate FAIL: 0 candidates.')
