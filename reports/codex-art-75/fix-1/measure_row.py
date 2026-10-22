"""ART-75 fix-1: exact nearest-neighbour inspection; no sprite edits."""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path('tools/sprite_pipeline').resolve()))
import head_scale as h

ROOT = Path('reports/codex-art-75/fix-1')
base = ROOT / sys.argv[1]
anchor = Image.open('art/bakeoff/yuki/yuki-idle-v2.png').convert('RGBA').crop((0, 0, 128, 128))
sheet = Image.open(base / 'yuki-fall.png').convert('RGBA')

def skin(a):
	r, g, b, al = [a[..., j].astype(int) for j in range(4)]
	return (al > 0) & (r > 180) & (g > 125) & (b > 105) & (r > g) & (g > b) & (r - b > 12) & (r - b < 120)

h.skin_mask = skin
original_face_centre = h.face_centre

def face_region(a):
	# Directly inspected head region: exclude the white sleeves from detection.
	copy = a.copy()
	box = Image.fromarray(a).getbbox()
	copy[box[1] + 42:, :, 3] = 0
	copy[:, :70, 3] = 0
	return original_face_centre(copy)

h.face_centre = face_region
report = h.measure(base / 'yuki-fall.png', h.head_template(anchor), 2, .6)
(base / 'head-scale.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
for i, frame in enumerate([anchor] + [sheet.crop((j * 128, 0, (j + 1) * 128, 128)) for j in range(2)]):
	board = Image.new('RGB', (576, 560), (35, 42, 58))
	cr = frame.resize((512, 512), Image.Resampling.NEAREST)
	board.paste(cr, (48, 24), cr)
	d = ImageDraw.Draw(board)
	for n in range(0, 129, 4):
		d.text((48 + n * 4, 8), str(n), fill='white')
		d.text((22, 24 + n * 4), str(n), fill='white')
		d.line((48 + n * 4, 24, 48 + n * 4, 536), fill=(75, 82, 98))
		d.line((48, 24 + n * 4, 560, 24 + n * 4), fill=(75, 82, 98))
	board.save(base / f'grid4x-{i}.png')
print(json.dumps(report))
