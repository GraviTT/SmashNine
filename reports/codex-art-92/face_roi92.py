"""ART-89 face method with visually located face ROI, avoiding exposed arms/legs."""
import sys,json
from pathlib import Path
roi=json.loads(sys.argv.pop())
code=Path('reports/codex-art-92/face92.py').read_text(encoding='utf-8')
needle="Image=env['Image'];"
insert="original_centre=env['centre']\ndef roi_centre(frame):\n key=str(env.get('i',0))\n if key in roi:return tuple(roi[key])\n return original_centre(frame)\nenv['centre']=roi_centre\n"
assert needle in code
exec(compile(code.replace(needle,insert+needle),'face92-roi-adapter','exec'))
