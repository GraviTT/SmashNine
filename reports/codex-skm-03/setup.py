"""Copy ART-72 tools and adapt its processing/measurement to SKM-03 paths only."""
import os
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE'] = '1'
root = Path('reports/codex-skm-03')
# ART-72 normalization/board logic, with SKM-01's connected-component input adapter.
process = Path('reports/codex-skm-01/process_row.py').read_text(encoding='utf-8')
process = process.replace('codex-skm-01', 'codex-skm-03').replace('raw/skm-01', 'raw/skm-03')
process = process.replace("['shield_bash','sword_plant']", "['whirl_spin']")
process = process.replace("['hover_dash','air_hover_swing']", "['wing_hover']")
process = process.replace("if len(sys.argv)>5:cmd+=['--lift-scale',sys.argv[5]]", "if len(sys.argv)>5:cmd+=['--lift-scale',sys.argv[5]]\nif len(sys.argv)>6:\n assert row == 'wing_hover'\n cmd[cmd.index('--lift-all')+1] = sys.argv[6]")
(root/'process.py').write_text(process, encoding='utf-8')
face = (root/'art72_source/face_check.py').read_text(encoding='utf-8')
face = face.replace('codex-art-72', 'codex-skm-03')
face = face.replace("[('jump',3),('fall',2),('hurt',3),('land',2),('victory',6)]", "[('wing_hover',6),('whirl_spin',6)]")
(root/'face_check.py').write_text(face, encoding='utf-8')
