"""Rebuild ART-75 fix-1 from the preserved raw with ONE common scale."""
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path('reports/codex-art-75')
FIX = ROOT / 'fix-1'
FINAL = FIX / 'final'
CANDIDATE = Path('art/bakeoff/yuki/yuki-fall-v2.png')
if CANDIDATE.exists() or CANDIDATE.with_suffix('.json').exists():
	raise SystemExit('Refusing to overwrite an existing candidate.')
subprocess.run([
	sys.executable, '-B', 'tools/sprite_pipeline/normalize.py',
	'--sheet', 'art/raw/motions-75/yuki-fall-fix-1-gen-1.png', '--grid', '2x1', '--bg', '#00ff00',
	'--cell', '128', '--scale-by', 'fixed:0.137', '--resample', 'lanczos', '--sharpen', '60',
	'--despill', 'auto', '--palette', 'none', '--reference', 'art/bakeoff/yuki/yuki-idle-v2.png:0:1',
	'--compare-scale', '4', '--lift-all', '8', '--out-dir', str(FINAL), '--name', 'yuki-fall',
	'--title', 'Yuki fall fix-1'
], check=True)
subprocess.run([sys.executable, '-B', str(FIX / 'measure_row.py'), 'final'], check=True)
subprocess.run([sys.executable, '-B', str(FIX / 'face_check_fix.py'), 'final'], check=True)
m = json.loads((FIX / 'measurements.json').read_text(encoding='utf-8'))
face = json.loads((FINAL / 'face-proposed.json').read_text(encoding='utf-8'))
face['review'] = '양쪽 눈과 얼굴 경계를 최근접 4배로 직접 확인. 표식 수정 없음. 흰 소매 혼동을 막기 위해 얼굴 탐색 영역만 제한.'
(FINAL / 'face-measured.json').write_text(json.dumps(face, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
shutil.copyfile(FINAL / 'yuki-fall.png', CANDIDATE)
meta = {
	'note': 'ART-75 fix-1 유키 낙하 2프레임 후보. 기존 행은 머리 높이 39/40=0.975이나 어깨 폭 25/22=1.136으로 한 배율 동시 보정 불가. idle을 Image 1로 1회 재생성, 행 공통 배율 0.137. 최근접 4배 실측 F1·F2 모두 상투~턱 높이 39px/기준 40px=0.975, 어깨 폭 22px/기준 22px=1.000(각 ±4% 안). 얼굴 눈 간격 F1 0.991·F2 0.993, 얼굴 폭 둘 다 1.000. 전체 높이 86px/기준 89px. 의상·손·부채·부적 확인. 4px 여백·spill 0·detail 108.41–109.84. 실제 게임/모션 뷰어 재생 검수 전.',
	'frames': 2, 'fps': 8, 'cell': 128, 'feet': 120, 'factor': 0.137
}
CANDIDATE.with_suffix('.json').write_text(json.dumps(meta, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
anchor = Image.open('art/bakeoff/yuki/yuki-idle-v2.png').convert('RGBA').crop((0, 0, 128, 128))
before_sheet = Image.open(ROOT / 'best/yuki/fall/yuki-fall.png').convert('RGBA')
after_sheet = Image.open(CANDIDATE).convert('RGBA')

def board(frames, measures, titles, path, align_chin=False):
	w, h = 544, 624
	im = Image.new('RGB', (w * len(frames), h), (24, 31, 46))
	d = ImageDraw.Draw(im)
	for i, (frame, mark, title) in enumerate(zip(frames, measures, titles)):
		x0, y0 = i * w + 16, 48
		if align_chin:
			y0 += int((72 - mark['chin_bottom'][1]) * 4)
		for y in range(0, 512, 16):
			for x in range(0, 512, 16):
				d.rectangle((x0 + x, y0 + y, x0 + x + 15, y0 + y + 15), fill=(35, 43, 61) if (x // 16 + y // 16) % 2 else (43, 52, 71))
		cr = frame.resize((512, 512), Image.Resampling.NEAREST)
		im.paste(cr, (x0, y0), cr)
		d.text((x0, 8), title, fill='white')
		def xy(p): return (x0 + p[0] * 4, y0 + p[1] * 4)
		for name in ['head_top', 'chin_bottom']:
			x, y = xy(mark[name]); d.line((x - 7, y, x + 7, y), fill='#6be5ff', width=2)
		vx = x0 + 108 * 4
		d.line((vx, xy(mark['head_top'])[1], vx, xy(mark['chin_bottom'])[1]), fill='#6be5ff', width=2)
		d.line((*xy(mark['shoulder_left']), *xy(mark['shoulder_right'])), fill='#ffe27a', width=2)
		for name in ['shoulder_left', 'shoulder_right']:
			x, y = xy(mark[name]); d.ellipse((x - 4, y - 4, x + 4, y + 4), outline='#ffe27a', width=2)
		if not align_chin: d.line((x0, y0 + 120 * 4, x0 + 511, y0 + 120 * 4), fill='#ec5b65', width=2)
		d.text((x0, 572), f"HEAD {mark['head_height']}px ({mark.get('head_ratio', 1):.3f}) | SHOULDERS {mark['shoulder_width']}px ({mark.get('shoulder_ratio', 1):.3f})", fill='white')
	d.text((16, 604), 'Nearest 4x | Cyan: bun to chin | Yellow: shoulder attachment edges | Values: original cell pixels', fill='white')
	im.save(path)

after = [after_sheet.crop((i * 128, 0, (i + 1) * 128, 128)) for i in range(2)]
before = [before_sheet.crop((i * 128, 0, (i + 1) * 128, 128)) for i in range(2)]
board([anchor] + after, [m['anchor']] + m['after'], ['IDLE ANCHOR', 'FALL F1 / NEW', 'FALL F2 / NEW'], ROOT / 'yuki-fall.png')
board([anchor] + before, [m['anchor']] + m['before'], ['IDLE ANCHOR', 'OLD FALL F1 / HELD', 'OLD FALL F2 / HELD'], FIX / 'before-measured-4x.png')
board([anchor, before[0], after[0]], [m['anchor'], m['before'][0], m['after'][0]], ['IDLE ANCHOR', 'BEFORE F1', 'AFTER F1'], FIX / 'before-after-4x.png', align_chin=True)
raw = Path(m['source'])
ledger = {'generations': 1, 'prompt': str(FIX / 'generation-1.txt').replace('\\', '/'), 'source': str(raw).replace('\\', '/'), 'raw_sha256': hashlib.sha256(raw.read_bytes()).hexdigest(), 'reference_image_1': 'art/raw/motions-75/yuki-anchor-4x.png', 'reference_image_2': 'art/raw/motions-75/yuki-fall-3.png', 'selected_factor': .137, 'factor_probes_same_raw': [.14, .137, .138, .139], 'candidate_sha256': hashlib.sha256(CANDIDATE.read_bytes()).hexdigest()}
(FIX / 'generation-ledger.json').write_text(json.dumps(ledger, indent=2) + '\n', encoding='utf-8')
print('Candidate and exact 4x boards written; no commit or Godot run.')
