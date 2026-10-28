"""Non-overwriting wrapper around the copied ART-72/82 normalisation and face checks."""
import os,sys,json
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
stem,row,gen,factor,label=sys.argv[1:6]
base=Path('reports/codex-art-89'); out=base/'attempts'/f'{stem}-{row}'/label
assert not out.exists(),f'Refusing overwrite {out}'
family='_75' if stem in ['yuki','nova_female'] else '_77' if stem=='rio_male' else ''
process=(base/f'process{family}.py').read_text(encoding='utf-8')
lines=process.splitlines(); found=False
for j,line in enumerate(lines):
 if line.startswith('out=Path('): lines[j]='out=Path('+repr(out.as_posix())+')';found=True
assert found
sys.argv=['process.py',stem,row,gen,factor]+sys.argv[6:]
exec(compile('\n'.join(lines),'copied-process','exec'),{'__name__':'__main__'})
face=(base/f'face_check{family}.py').read_text(encoding='utf-8');lines=face.splitlines()
for j,line in enumerate(lines):
 if line.startswith(' base=Path('):lines[j]=' base=Path('+repr(out.parent.as_posix())+')'
 if line.startswith(' attempts='):lines[j]=' attempts=[1]'
 if line.startswith(' out=base/'):lines[j]=' out=Path('+repr(out.as_posix())+');'+line.split(';',1)[1]
 if line.startswith("Path(f'reports/codex-art-89/"):lines[j]='# Aggregate is omitted to preserve earlier outputs.'
sys.argv=['face_check.py',stem,row,gen]
exec(compile('\n'.join(lines),'copied-face-check','exec'),{'__name__':'__main__'})
(out/'variant.json').write_text(json.dumps({'stem':stem,'row':row,'generation':int(gen),'factor':float(factor),'label':label},indent=2),encoding='utf-8')
