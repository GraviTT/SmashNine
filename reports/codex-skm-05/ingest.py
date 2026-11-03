"""Preserve a built-in image_gen result and its exact prompt; never request generation."""
import json, sys, shutil, hashlib
from pathlib import Path
stem,row,attempt,source=sys.argv[1:5]
attempt=int(attempt)
assert stem in ['nova_male','nova_female'] and row in ['gravity_beam','orb_throw','field_fly'] and 1<=attempt<=2
root=Path('reports/codex-skm-05');raw=Path(f'art/raw/skm-05/{stem}-{row}-{attempt}.png')
if raw.exists():assert raw.read_bytes()==Path(source).read_bytes()
else:shutil.copyfile(source,raw)
ledger=json.loads((root/'generation-ledger.json').read_text(encoding='utf-8'))
assert not any(v['stem']==stem and v['row']==row and v['attempt']==attempt for v in ledger)
ledger.append({'stem':stem,'row':row,'attempt':attempt,'raw':raw.as_posix(),'original':source,'references':[str(Path(f'art/bakeoff/nova/{stem}-idle-v2.png').resolve()),str(Path(f'smash-nine-prototype/assets/art/nova/{stem}_moves_sheet.png').resolve())],'prompt':raw.with_suffix('.prompt.txt').read_text(encoding='utf-8').strip(),'sha256':hashlib.sha256(raw.read_bytes()).hexdigest()})
(root/'generation-ledger.json').write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'Preserved {stem} {row} attempt {attempt}')
