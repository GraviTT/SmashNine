"""Store a reviewed decision; caller supplies facts after inspecting the boards."""
import json,sys
from pathlib import Path
from config import ROOT,ROWS
row,attempt=sys.argv[1:3]
base=ROOT/'xion'/row/f'attempt-{attempt}'
d=json.loads((base/'decision.json').read_text(encoding='utf-8'))
fps,loop,label=ROWS[row]
d.update(stem='xion',row=row,attempt=int(attempt),fps=fps,loop=loop,**{'for':label})
rows=json.loads((ROOT/'selection.json').read_text(encoding='utf-8'))
rows=[r for r in rows if r['row']!=row]+[d]
rows.sort(key=lambda r:list(ROWS).index(r['row']))
(ROOT/'selection.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
