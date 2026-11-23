from pathlib import Path
import importlib.util
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-art-97a-fix'
spec = importlib.util.spec_from_file_location('norm', ROOT / 'tools/sprite_pipeline/normalize.py')
n = importlib.util.module_from_spec(spec)
spec.loader.exec_module(n)
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 23)
anchor = Image.open(ROOT / 'art/bakeoff/xion/b/xion-idle-b2.png').convert('RGBA').crop((0, 0, 128, 128))
anchor192 = Image.new('RGBA', (192, 192))
anchor192.alpha_composite(anchor, (32, 32))


def frames(path):
    sheet = Image.open(path).convert('RGBA')
    return [sheet.crop((i * 192, 0, (i + 1) * 192, 192)) for i in range(6)]


def feet(frame):
    a = np.asarray(frame.getchannel('A')) > 0
    cols = a[148:153].any(axis=0)
    groups = []
    start = None
    for x, value in enumerate(list(cols) + [False]):
        if value and start is None:
            start = x
        elif not value and start is not None:
            groups.append([start, x - 1])
            start = None
    return {'runs': groups, 'centres': [sum(g) / 2 for g in groups]}


def panel(items, labels, out):
    board = n.checker((len(items) * 768, 822), 32)
    draw = ImageDraw.Draw(board)
    for i, (frame, label) in enumerate(zip(items, labels)):
        tile = frame.resize((768, 768), Image.Resampling.NEAREST)
        board.paste(tile, (i * 768, 54), tile)
        draw.text((i * 768 + 16, 12), label, font=font, fill='white')
        # Put the floor immediately BELOW the contact pixels; do not hide soles.
        draw.line((i * 768, 54 + 153 * 4, (i + 1) * 768 - 1, 54 + 153 * 4), fill=(90, 190, 235), width=2)
    board.save(out)


before = frames(REPORT / 'victory-before.png')
after = frames(REPORT / 'victory-normalized/victory.png')
data = {'method': 'boots only: union of opaque pixels at y148..152; left and right boot runs paired by order; all victory frames remain planted', 'before': [], 'after': []}
for key, group in [('before', before), ('after', after)]:
    data[key] = [dict(frame=i + 1, **feet(f)) for i, f in enumerate(group)]
    centres = [f['centres'] for f in data[key]]
    assert all(len(x) == 2 for x in centres), centres
    deltas = [[round(b - a, 2) for a, b in zip(centres[i], centres[i + 1])] for i in range(5)]
    data[key + '_neighbour_dx'] = deltas
    data[key + '_max_abs_dx'] = max(abs(x) for pair in deltas for x in pair)
data['unchanged_cropped_rgba'] = [np.array_equal(np.asarray(a.crop(a.getbbox())), np.asarray(b.crop(b.getbbox()))) for a, b in zip(before, after)]
(REPORT / 'feet.json').write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
print(json.dumps(data, indent=2))
for row in ('victory', 'defeat'):
    group = frames(REPORT / f'{row}-normalized/{row}.png')
    out = REPORT / f'{row}-4x'
    out.mkdir(exist_ok=True)
    for i, frame in enumerate(group):
        panel([anchor192, frame], ['ANCHOR - identical pixel scale', f'{row.upper()} F{i + 1} - 4X'], out / f'F{i + 1}.png')
    # One full 4x board including the anchor, kept as the review deliverable.
    panel([anchor192, *group], ['ANCHOR'] + [f'{row.upper()} F{i + 1}' for i in range(6)], REPORT / f'{row}.png')
for i in (3, 4):
    panel([before[i], after[i]], [f'BEFORE F{i + 1}', f'AFTER F{i + 1}'], REPORT / f'victory-before-after-F{i + 1}.png')

