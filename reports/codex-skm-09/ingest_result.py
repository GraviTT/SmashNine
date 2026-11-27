"""Preserve built-in result, prompt, hashes, references and before/after clocks."""
import json,shutil,hashlib
from pathlib import Path
from config import ROOT,ORDER
d=json.loads((ROOT/'last-generation.json').read_text(encoding='utf-8'))
assert (d['stem'],d['row']) in ORDER and d['attempt'] in [1,2]
raw=Path(f"art/raw/skm-09/{d['stem']}-{d['row']}-{d['attempt']}.png")
assert not raw.exists()
shutil.copyfile(d['original'],raw)
d.update(raw=raw.as_posix(),sha256=hashlib.sha256(raw.read_bytes()).hexdigest())
raw.with_suffix('.prompt.txt').write_text(d['prompt']+'\n',encoding='utf-8')
p=ROOT/'generation-ledger.json'
ledger=json.loads(p.read_text(encoding='utf-8')) if p.exists() else []
ledger.append(d);p.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(ROOT/'prompts.txt').write_text('\n\n'.join(f"{g['stem']} {g['row']} #{g['attempt']}\nReferences: "+', '.join(g['references'])+'\n'+g['prompt'] for g in ledger)+'\n',encoding='utf-8')
print(raw)
