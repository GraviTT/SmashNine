"""Reuse the copied ART-82/77 scripts for an eight-frame whole-row input."""
import os,sys,json
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
gen,factor,label=sys.argv[1:4]
base=Path('reports/codex-art-89');out=base/'attempts/rio_male-walk'/label
assert not out.exists(), f'Refusing overwrite {out}'
source=(base/'process_77.py').read_text(encoding='utf-8')
source=source.replace("counts={'jump'", "counts={'walk':8,'jump'")
source=source.replace("'tools/sprite_pipeline/normalize.py'", "'reports/codex-art-89/normalize_walk.py'")
source=source.replace("f'{3 if row==\"victory\" else counts[row]}x{2 if row==\"victory\" else 1}'", "'4x2'")
source=source.replace("['hurt','land','victory']", "['walk','hurt','land','victory']")
lines=source.splitlines()
for j,line in enumerate(lines):
 if line.startswith('out=Path('):lines[j]='out=Path('+repr(out.as_posix())+')'
sys.argv=['process_77.py','rio_male','walk',gen,factor,'1','0',sys.argv[4] if len(sys.argv)>4 else '0']
exec(compile('\n'.join(lines),'copied-process-77','exec'),{'__name__':'__main__'})
source=(base/'face_check_77.py').read_text(encoding='utf-8')
source=source.replace("('victory',6)", "('victory',6),('walk',8)")
lines=source.splitlines()
for j,line in enumerate(lines):
 if line.startswith(' base=Path('):lines[j]=' base=Path('+repr(out.parent.as_posix())+')'
 if line.startswith(' attempts='):lines[j]=' attempts=[1]'
 if line.startswith(' out=base/'):lines[j]=' out=Path('+repr(out.as_posix())+');'+line.split(';',1)[1]
 if line.startswith("Path(f'reports/codex-art-89/"):lines[j]='# No redundant aggregate output.'
sys.argv=['face_check_77.py','rio_male','walk',gen]
exec(compile('\n'.join(lines),'copied-face-check-77','exec'),{'__name__':'__main__'})
(out/'variant.json').write_text(json.dumps({'stem':'rio_male','row':'walk','generation':int(gen),'factor':float(factor),'label':label},indent=2),encoding='utf-8')
