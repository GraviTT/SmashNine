"""Normalize LF and trailing whitespace only in the task's explicit new text files."""
import json
from pathlib import Path
from config import ROOT
paths=json.loads((ROOT/'files-to-stage.json').read_text(encoding='utf-8'))
for s in paths:
    p=Path(s)
    if s=='design/tasks/CODEX-SKM-08.md' or p.suffix not in {'.py','.ps1','.md','.json','.txt'}:continue
    assert s.startswith('reports/codex-skm-08/') or s.startswith('art/bakeoff/rio/rio_')
    text=p.read_text(encoding='utf-8')
    p.write_text('\n'.join(line.rstrip() for line in text.splitlines())+'\n',encoding='utf-8',newline='\n')
print('Normalized explicit task text files to UTF-8 / LF.')
