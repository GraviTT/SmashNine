"""Independent card-contract checks. No Godot import or product mutation."""
from pathlib import Path
import ast
import hashlib
import json
import re
import subprocess
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-vfx-06'
OUT = ROOT / 'art/bakeoff/effects/nova'
CONTRACT = {
    'head': (48, 48, 4, 16, [24, 24], True, 'assets/art/effects/nova_beam_head.png'),
    'split': (160, 160, 4, 40, [80, 80], False, 'assets/art/effects/skill/nova_beam_split.png'),
    'bind': (160, 160, 4, 12, [80, 80], True, 'assets/art/effects/skill/nova_beam_bind.png'),
    'tile': (64, 16, 1, 0, [32, 8], True, 'assets/art/effects/nova_beam_tile.png'),
}
results = {}
frames = {}
for v in 'ab':
    for k, (w, h, n, fps, anchor, loop, replaces) in CONTRACT.items():
        p = OUT / f'nova_beam_{k}-{v}-v2.png'
        im = Image.open(p)
        assert im.mode == 'RGBA' and im.size == (w*n, h), p
        meta = json.loads(p.with_suffix('.json').read_text(encoding='utf-8'))
        for key, expected in [('frames', n), ('fps', fps), ('anchor', anchor), ('loop', loop), ('replaces', replaces)]:
            assert meta[key] == expected, (p, key)
        a = np.array(im)
        assert set(np.unique(a[:, :, 3])).issubset({0, 255}), p
        assert not a[a[:, :, 3] == 0, :3].any(), p
        fs = [a[:, i*w:(i+1)*w].copy() for i in range(n)]
        frames[k, v] = fs
        rows = []
        for f in fs:
            assert not f[[0, -1]].any(), p
            if k != 'tile':
                assert not f[:, [0, -1]].any(), p
            row = {'bbox': list(Image.fromarray(f[:, :, 3]).getbbox()), 'opaque_pixels': int((f[:, :, 3] > 0).sum())}
            if k in ('split', 'bind'):
                coverage = float((f[40:120, 55:105, 3] > 0).mean())
                assert coverage <= .10, (p, coverage)
                row['middle_50x80_clear_percent'] = round(100*(1-coverage), 3)
                row['left_entry_x'] = int(np.flatnonzero(f[77:84, :, 3].max(0))[0])
            rows.append(row)
        record = {'dimensions': list(im.size), 'frames': rows, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
        if loop and n > 1:
            deltas = [float(np.abs(fs[(i+1)%n][:, :, :3].astype(float)-fs[i][:, :, :3]).mean()) for i in range(n)]
            ratio = deltas[-1]/(sum(deltas)/n)
            assert ratio < 1.5, (p, ratio)
            record['loop_step_rgb_mae'] = deltas
            record['last_to_first_over_mean'] = ratio
        if k == 'tile':
            assert np.array_equal(a[:, 0], a[:, -1]), p
            assert np.all(a[8, :, 3] == 255), p
            record['seam_max_rgba_difference'] = 0
            record['continuous_core_row'] = 8
        results[p.name] = record
    assert np.array_equal(frames['split', v][-1], frames['bind', v][0])

boards = json.loads((REPORT / 'boards.json').read_text(encoding='utf-8'))
assert len(boards) == 22
for row in boards:
    assert Image.open(REPORT / row['file_4x']).size == (1920, 896)
    assert row['foe_feet'][0]-row['nova_feet'][0] == row['distance']
    assert row['body_center'][1] == row['foe_feet'][1]-32
processing = json.loads((REPORT / 'processing.json').read_text(encoding='utf-8'))
assert all(min(s['source_px_per_output_px']) >= 1 for s in processing['samples'])
for p in REPORT.glob('*.py'):
    ast.parse(p.read_text(encoding='utf-8'))

status = subprocess.check_output(['git', 'status', '--porcelain=v1', '-uall'], cwd=ROOT, text=True)
baseline = (REPORT / 'baseline-status.txt').read_text(encoding='utf-8-sig').splitlines()
# Baseline status can collapse existing untracked directories; compare only product state verbatim.
old_product = sorted(x for x in baseline if 'smash-nine-prototype/' in x)
new_product = sorted(x for x in status.splitlines() if 'smash-nine-prototype/' in x)
assert old_product == new_product, 'Product status changed'
tracked = subprocess.check_output(['git', 'diff', '--name-only'], cwd=ROOT, text=True).splitlines()
assert not tracked, tracked

sizes = {}
for label, directory in [('raw', ROOT/'art/raw/vfx-06'), ('report', REPORT), ('clone', ROOT)]:
    sizes[label] = sum(p.stat().st_size for p in directory.rglob('*') if p.is_file())
sizes['candidates'] = sum(p.stat().st_size for p in OUT.glob('nova_beam_*-?-v2.*'))
output = {'passed': True, 'png_count': 8, 'frame_count': 26, 'json_count': 8,
          'split_last_equals_bind_first': True, 'product_status_unchanged': True,
          'board_pairs': 22, 'sizes_bytes': sizes, 'items': results}
(REPORT / 'measurements.json').write_text(json.dumps(output, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps({'passed': True, 'png': 8, 'frames': 26, 'board_pairs': 22,
                  'clear_percent_min': min(f['middle_50x80_clear_percent'] for r in results.values() for f in r['frames'] if 'middle_50x80_clear_percent' in f),
                  'loop_ratios': {k: round(r['last_to_first_over_mean'], 3) for k, r in results.items() if 'last_to_first_over_mean' in r},
                  'sizes_bytes': sizes}, ensure_ascii=False))
