"""Record an inspected decision from the per-attempt decision.json."""
import json,sys
from config import ROOT,ORDER
stem,row,attempt=sys.argv[1:4]
d=json.loads((ROOT/stem/row/f'attempt-{attempt}'/'decision.json').read_text(encoding='utf-8'))
d.update(stem=stem,row=row,attempt=int(attempt))
p=ROOT/'selection.json';rows=json.loads(p.read_text(encoding='utf-8')) if p.exists() else []
rows=[r for r in rows if (r['stem'],r['row'])!=(stem,row)]+[d]
rows.sort(key=lambda r:ORDER.index((r['stem'],r['row'])))
p.write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
