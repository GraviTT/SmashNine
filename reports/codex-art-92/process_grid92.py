"""ART-89 victory source layout: 3x2 input, exact 6x1 output strip."""
import os,sys
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
n.parse_grid=lambda value:(3,2)
exec(compile(Path('reports/codex-art-92/process_fast92.py').read_text(encoding='utf-8'),'process-fast-grid-adapter','exec'))
