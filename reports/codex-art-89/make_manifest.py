"""Create a narrow commit list and source hashes, without staging anything."""
from pathlib import Path
import json,hashlib
R=Path('reports/codex-art-89')
rows=json.loads((R/'results.json').read_text(encoding='utf-8'))
ledger=json.loads((R/'generation-ledger.json').read_text(encoding='utf-8'))
raw=sorted({p for g in ledger for p in [g['raw'],*g['references']]})
hashes={p:hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in raw}
with (R/'source-hashes.json').open('x',encoding='utf-8',newline='\n') as f:json.dump(hashes,f,indent=2)
names=['README.md','prompts.txt','generation-ledger.json','selection.json','results.json','source-hashes.json','processing-incident.txt','process.py','process_75.py','process_77.py','face_check.py','face_check_75.py','face_check_77.py','grid_faces_77.py','manual_faces_77.py','run_variant_v2.py','run_walk_v2.py','normalize_walk.py','make_review_v2.py','package_results.py','verify_delivery.py','make_manifest.py','commit.ps1','commit-paths.txt','audit.json','rio_male-walk-1x.png']
files=[(R/n).as_posix() for n in names]
files += [p.as_posix() for folder in ['best','qa4x'] for p in sorted((R/folder).rglob('*')) if p.is_file()]
files += [(R/f"{r['stem']}-{r['row']}.png").as_posix() for r in rows]
files += [p for r in rows if r['deliver'] for p in [r['candidate'],Path(r['candidate']).with_suffix('.json').as_posix()]]
files += ['design/tasks/CODEX-ART-89.md','design/tasks/CODEX-ART-89.prompt.md']
assert len(files)==len(set(files))
assert not any(any(x in p for x in ['art/raw/','ref82/','__pycache__','run.log','/attempts/','/review/','/attempt-']) for p in files)
with (R/'commit-paths.txt').open('x',encoding='utf-8',newline='\n') as f:f.write('\n'.join(sorted(files))+'\n')
print(json.dumps({'paths':len(files),'raw_hashes_only':len(hashes)}))
