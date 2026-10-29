"""Adapt the copied ART-72 helpers; no product paths are written."""
from pathlib import Path
p=Path(__file__).parent
for f in p.glob('*.py'):
 if f.name=='setup.py': continue
 s=f.read_text(encoding='utf-8').replace('reports/codex-art-72','reports/codex-skm-01').replace('art/raw/motions-72','art/raw/skm-01')
 if f.name=='face_check.py':
  s=s.replace("[('jump',3),('fall',2),('hurt',3),('land',2),('victory',6)]", "[(r,6) for r in ['hover_dash','launch_chase','shield_bash','sword_plant','air_hover_swing']]")
 f.write_text(s,encoding='utf-8',newline='\n')
