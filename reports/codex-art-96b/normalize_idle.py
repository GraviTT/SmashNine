"""ART-96 B: shared-scale normalization with one fixed source-grid anchor.

The long scarf crosses the stock normalizer's torso sampling band. Use the
median approved-v1 torso coordinate ONCE for the whole sheet, not per-frame
offsets. All resampling, keying, despill and validation use normalize.py.
No source pixels, body parts, tool files or game files are edited.
"""
from pathlib import Path
import importlib.util
import json
import statistics

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-art-96b'
spec = importlib.util.spec_from_file_location('sprite_normalize', ROOT / 'tools/sprite_pipeline/normalize.py')
normalizer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(normalizer)

reference = ROOT / 'art/raw/xion-96b/reference-v1-original-sheet.png'
source = ROOT / 'art/raw/xion-96b/idle-attempt3.png'
frames, _ = normalizer.split_sheet(reference, (3, 2))
v1_anchors = [normalizer.torso_anchor_x(normalizer.clean_background(f, '#00ff00')[0]) for f in frames]
anchor = statistics.median(v1_anchors)
new_frames, _ = normalizer.split_sheet(source, (3, 2))
default_anchors = [normalizer.torso_anchor_x(normalizer.clean_background(f, '#00ff00')[0]) for f in new_frames]
normalizer.torso_anchor_x = lambda _image: anchor

args = normalizer.parser().parse_args([
    '--sheet', str(source), '--grid', '3x2', '--cell', '128', '--bg', '#00ff00',
    '--scale-by', 'height:97', '--ground-all', '--resample', 'lanczos',
    '--sharpen', '60', '--despill', 'auto', '--palette', 'none',
    '--reference', str(ROOT / 'smash-nine-prototype/assets/art/rio/rio_female_sheet.png') + ':0:6',
    '--compare-scale', '4', '--title', 'XION B2 FINAL',
    '--out-dir', str(REPORT / 'normalized'), '--name', 'xion-idle-b2',
    '--candidate-out', str(ROOT / 'art/bakeoff/xion/b/xion-idle-b2.png'),
])
args.palette = None
args.feet_y = 120
metrics = normalizer.normalize(args)
metrics['normalization']['horizontal_anchor'] = 'one fixed source-grid x for all six frames'
metrics['normalization']['fixed_source_anchor_x'] = anchor
metrics['normalization']['v1_torso_anchors'] = v1_anchors
metrics['normalization']['rejected_default_torso_anchors'] = default_anchors
metrics['normalization']['reason'] = '긴 스카프가 몸통 외곽선 계산에 포함되어 생기는 가로 밀림 방지. v1 좌표 중앙값 하나를 여섯 칸 전체에 공통 적용.'
(REPORT / 'normalized/metrics.json').write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(metrics['summary'], ensure_ascii=False))
