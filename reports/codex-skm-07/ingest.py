"""Preserve a built-in image_gen result and its exact prompt; never request generation."""
import json, sys, shutil, hashlib
from pathlib import Path
from config import ROWS, REFS
row,attempt,source=sys.argv[1:4]
stem='xion'
attempt=int(attempt)
assert row == 'shot_air_down' and 1<=attempt<=3
root=Path('reports/codex-skm-07');raw=Path(f'art/raw/skm-07/{stem}-{row}-{attempt}.png')
if raw.exists():assert raw.read_bytes()==Path(source).read_bytes()
else:shutil.copyfile(source,raw)
ledger=json.loads((root/'generation-ledger.json').read_text(encoding='utf-8')) if (root/'generation-ledger.json').exists() else []
assert not any(v['stem']==stem and v['row']==row and v['attempt']==attempt for v in ledger)
ledger.append({'stem':stem,'row':row,'attempt':attempt,'raw':raw.as_posix(),'original':source,'references':REFS,'prompt':raw.with_suffix('.prompt.txt').read_text(encoding='utf-8').strip(),'sha256':hashlib.sha256(raw.read_bytes()).hexdigest()})
(root/'generation-ledger.json').write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'Preserved {stem} {row} attempt {attempt}')
