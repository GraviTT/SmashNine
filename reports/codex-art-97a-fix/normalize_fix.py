"""ART-97 fix: shared source-grid anchors; no per-frame x offsets or scale.

Reuses the ART-96b wrapper method without editing the shared normalizer.
Only equal thirds are extracted from the two defeat images, without resizing.
"""
from pathlib import Path
import importlib.util
import json
import statistics
import argparse
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-art-97a-fix'
RAW = ROOT / 'art/raw/xion-97a'
spec = importlib.util.spec_from_file_location('sprite_normalize', ROOT / 'tools/sprite_pipeline/normalize.py')
n = importlib.util.module_from_spec(spec)
spec.loader.exec_module(n)


def dump(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def runs(values):
    result = []
    start = None
    for x, val in enumerate(list(values) + [False]):
        if val and start is None:
            start = x
        elif not val and start is not None:
            result.append([start, x - 1])
            start = None
    return result


def boot_centres(frame, depth):
    mask = np.asarray(frame.getchannel('A')) > 0
    bottom = n.alpha_bbox(frame)[3] - 1
    groups = runs(mask[bottom - depth + 1:bottom + 1].any(axis=0))
    return {'bottom': bottom, 'runs': groups, 'centres': [sum(g) / 2 for g in groups]}


def normalize(row, factor):
    if row == 'victory':
        source = RAW / 'victory-2.png'
        frames, labels = n.split_sheet(source, (6, 1))
        cleaned = [n.clean_background(f, '#00ff00')[0] for f in frames]
        boots = [boot_centres(f, 22) for f in cleaned]
        assert all(len(b['centres']) == 2 for b in boots), boots
        # One median planted-boot midpoint is chosen ONCE. Same x for all poses.
        anchor = statistics.median(statistics.mean(b['centres']) for b in boots)
        source_args = ['--sheet', str(source), '--grid', '6x1']
        reason = '6칸 원본의 부츠 바닥 22줄에서 잰 두 발 중점의 중앙값 하나. 프레임별 이동 없음.'
    else:
        directory = RAW / 'defeat-fix-frames'
        directory.mkdir(exist_ok=True)
        frames = []
        labels = []
        for suffix in ('123-r2', '456'):
            source = RAW / f'defeat-fix-{suffix}.png'
            group, names = n.split_sheet(source, (3, 1))
            frames.extend(group)
            labels.extend(names)
        assert len({f.size for f in frames}) == 1, 'Source cells must share one coordinate system'
        for i, frame in enumerate(frames):
            frame.save(directory / f'frame-{i + 1:02d}.png')
        cleaned = [n.clean_background(f, '#00ff00')[0] for f in frames]
        anchor = frames[0].width / 2
        boots = None
        source_args = ['--frames', str(directory / '*.png')]
        reason = '두 원본 모두 같은 크기의 균등 3칸. 각 원본 칸의 x=256 하나를 6프레임에 공통 적용.'
    default = [n.torso_anchor_x(f) for f in cleaned]
    n.validate_source_cell_margin(cleaned, labels)
    n.torso_anchor_x = lambda _image: anchor
    folder = REPORT / f'{row}-normalized'
    args = n.parser().parse_args(source_args + [
        '--cell', '192', '--feet-y', '152', '--bg', '#00ff00',
        '--scale-by', f'fixed:{factor}', '--ground-all',
        '--resample', 'lanczos', '--sharpen', '60', '--despill', 'auto', '--palette', 'none',
        '--reference', 'art/bakeoff/xion/b/xion-idle-b2.png:0:6',
        '--compare-scale', '4', '--title', f'XION B {row.upper()} FIX',
        '--out-dir', str(folder), '--name', row,
    ])
    args.palette = None
    metrics = n.normalize(args)
    metrics['normalization'].update({
        'horizontal_anchor': 'one fixed source-grid x for all six frames',
        'fixed_source_anchor_x': anchor,
        'rejected_default_torso_anchors': default,
        'reason': reason,
        'source_boots': boots,
    })
    dump(folder / 'metrics.json', metrics)
    print(json.dumps({'row': row, 'anchor': anchor, 'summary': metrics['summary']}, ensure_ascii=False))


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('row', choices=['victory', 'defeat'])
    p.add_argument('--factor', required=True, type=float)
    a = p.parse_args()
    normalize(a.row, a.factor)
