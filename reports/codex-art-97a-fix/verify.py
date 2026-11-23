"""Delivery checks for the two art rows; no Godot or game-source mutations."""
from pathlib import Path
import ast
import importlib.util
import json
import subprocess
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-art-97a-fix'
OUT = ROOT / 'art/bakeoff/xion/b'
spec = importlib.util.spec_from_file_location('norm', ROOT / 'tools/sprite_pipeline/normalize.py')
n = importlib.util.module_from_spec(spec)
spec.loader.exec_module(n)
checks = []


def check(label, result):
    checks.append({'check': label, 'pass': bool(result)})


metrics = json.loads((REPORT / 'metrics.json').read_text(encoding='utf-8'))
for row, fps, factor in [('victory', 8, 0.230), ('defeat', 10, 0.205)]:
    path = OUT / f'xion-{row}-b2.png'
    sheet = Image.open(path).convert('RGBA')
    meta = json.loads(path.with_suffix('.json').read_text(encoding='utf-8'))
    check(f'{row}: 6 x 192px cells', sheet.size == (1152, 192))
    check(f'{row}: metadata and Korean note', meta['frames'] == 6 and meta['fps'] == fps and meta['loop'] is False and any('\uac00' <= c <= '\ud7a3' for c in meta['note']))
    check(f'{row}: reviewed candidate equals normalized file', path.read_bytes() == (REPORT / f'{row}-normalized/{row}.png').read_bytes())
    m = metrics['rows'][row]
    check(f'{row}: one common factor', m['factor'] == factor)
    check(f'{row}: head median in range, >=2 valid frames', 0.96 <= m['head_scale']['median'] <= 1.04 and m['head_scale']['used'] >= 2)
    for i in range(6):
        frame = sheet.crop((i * 192, 0, (i + 1) * 192, 192))
        box = n.alpha_bbox(frame)
        check(f'{row} F{i+1}: 4px margin/border', min(box[0], box[1], 192 - box[2], 192 - box[3]) >= 4)
        check(f'{row} F{i+1}: bottom at y152', box[3] - 1 == 152)
        check(f'{row} F{i+1}: binary alpha', set(np.unique(np.asarray(frame.getchannel('A')))) <= {0, 255})
        check(f'{row} F{i+1}: spill zero', n.spill_pixel_count(frame) == 0)
        check(f'{row} F{i+1}: detail >=90% anchor mean', n.interior_detail(frame) >= 107.5 * 0.9)

feet = json.loads((REPORT / 'feet.json').read_text(encoding='utf-8'))
check('victory: boots max adjacent movement <=3px', feet['after_max_abs_dx'] <= 3)
check('victory: unchanged subject RGBA in all 6 frames', all(feet['unchanged_cropped_rgba']))
check('victory: baseline shows reproduced 13px defect', feet['before_max_abs_dx'] == 13)

for filename, grid in [('victory-2.png', (6, 1)), ('defeat-fix-123-r2.png', (3, 1)), ('defeat-fix-456.png', (3, 1))]:
    source = ROOT / 'art/raw/xion-97a' / filename
    frames, labels = n.split_sheet(source, grid)
    try:
        n.validate_source_cell_margin([n.clean_background(f, '#00ff00')[0] for f in frames], labels)
        good = True
    except ValueError:
        good = False
    check(f'source boundary clear: {filename}', good)

for path in REPORT.rglob('*'):
    if path.suffix in {'.py', '.md', '.txt', '.ps1', '.json'}:
        content = path.read_text(encoding='utf-8-sig')
        check(f'UTF-8: {path.relative_to(REPORT)}', '\ufffd' not in content)
        if path.suffix == '.py':
            ast.parse(content)
        elif path.suffix == '.json':
            json.loads(content)

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT).decode('utf-8', errors='strict')

check('correct branch', git('branch', '--show-current').strip() == 'codex/xion-97a-fix')
check('no game-file diff', not git('diff', '--name-only', 'HEAD', '--', 'smash-nine-prototype/').strip())
baseline = set((REPORT / 'baseline-status.txt').read_text(encoding='utf-8-sig').splitlines())
current = set(git('status', '--porcelain=v1', '-uall').splitlines())
unexpected = []
for line in current - baseline:
    path = line[3:]
    if not (path.startswith('reports/codex-art-97a-fix/') or path.startswith('art/raw/xion-97a/') or path in {
        'art/bakeoff/xion/b/xion-victory-b2.png', 'art/bakeoff/xion/b/xion-victory-b2.json',
        'art/bakeoff/xion/b/xion-defeat-b2.png', 'art/bakeoff/xion/b/xion-defeat-b2.json',
    }):
        unexpected.append(line)
check('all changed/new paths within fix card', not unexpected)
result = {'checks': checks, 'passed': sum(c['pass'] for c in checks), 'failed': [c['check'] for c in checks if not c['pass']], 'unexpected_paths': unexpected,
    'not_tested': ['Godot execution', 'real-time animation playback', 'human adoption'],
    'scope': 'format/measurements only; visual caveats remain in README.md'}
(REPORT / 'validation.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k: result[k] for k in ('passed', 'failed', 'unexpected_paths')}, ensure_ascii=False))
raise SystemExit(1 if result['failed'] else 0)
