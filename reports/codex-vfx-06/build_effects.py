"""Downsample built-in imagegen art into card-sized candidates; no product writes."""
from pathlib import Path
import json
import math
import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'art/raw/vfx-06'
OUT = ROOT / 'art/bakeoff/effects/nova'
REPORT = ROOT / 'reports/codex-vfx-06'
SPECS = {
    'head': ((48, 48), 4, 16, [24, 24], True, 'assets/art/effects/nova_beam_head.png'),
    'split': ((160, 160), 4, 40, [80, 80], False, 'assets/art/effects/skill/nova_beam_split.png'),
    'bind': ((160, 160), 4, 12, [80, 80], True, 'assets/art/effects/skill/nova_beam_bind.png'),
    'tile': ((64, 16), 1, 0, [32, 8], True, 'assets/art/effects/nova_beam_tile.png'),
}
NOTES = {
    'a': {
        'head': '세 갈래 곡선 촉수가 한 점으로 접힌 비행 촉. 중심 고정, 네 장 광도 맥동.',
        'split': '왼쪽 줄에서 세 갈래 촉수가 벌어져 몸 바깥을 감싼다. 마지막 장은 결박 첫 장과 같다.',
        'bind': '세 갈래 곡선 촉수가 몸을 감싸며 조금 조이고 풀린다. 작은 불꽃은 줄 쪽인 왼쪽으로 흐른다.',
        'tile': '청록 심선을 얇은 보라 섬유가 감싼 줄. 좌우 같은 픽셀로 이어지는 가로 반복 타일.',
    },
    'b': {
        'head': '네 갈래 각진 갈고리가 한 점으로 접힌 비행 촉. 중심 고정, 네 장 광도 맥동.',
        'split': '왼쪽 줄에서 각진 갈고리 네 갈래가 벌어져 몸의 위아래와 오른쪽을 감싼다.',
        'bind': '각진 갈고리가 오른쪽에서 맞물린 결박. 중심은 비우고 바깥 테두리만 맥동한다.',
        'tile': '청록 심선과 작은 보라 각진 마디가 이어진 줄. 좌우 같은 픽셀의 가로 반복 타일.',
    },
}
PROCESS = []


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def clean(arr, tile=False):
    arr = np.asarray(arr).copy().astype(np.uint8)
    arr[:, :, 3] = np.where(arr[:, :, 3] >= 128, 255, 0)
    arr[[0, -1], :, :] = 0
    if not tile:
        arr[:, [0, -1], :] = 0
    arr[arr[:, :, 3] == 0] = 0
    return arr


def sample(im, size, centre, scale, label):
    """Crop/pad in raw coordinates, then LANCZOS shrink once. Never enlarge art."""
    sx, sy = scale
    assert min(sx, sy) >= 1, 'Upscaling is forbidden'
    w, h = size
    box = (round(centre[0]-w*sx/2), round(centre[1]-h*sy/2),
           round(centre[0]+w*sx/2), round(centre[1]+h*sy/2))
    crop = im.crop(box)
    assert crop.width >= w and crop.height >= h
    out = crop.resize(size, Image.Resampling.LANCZOS)
    out = out.filter(ImageFilter.UnsharpMask(radius=.6, percent=55, threshold=3))
    PROCESS.append({'id': label, 'source_size': list(im.size), 'crop': list(box),
                    'output_size': list(size), 'source_px_per_output_px': [crop.width/w, crop.height/h]})
    return clean(out)


def gain(arr, value):
    out = arr.copy()
    out[:, :, :3] = np.minimum(255, out[:, :, :3].astype(float)*value).astype(np.uint8)
    out[out[:, :, 3] == 0] = 0
    return out


def clear_middle(arr):
    """Keep natural hole; shorten the left tail to meet the hand at +69px arrival.

    Only x<55 is compressed, 55 source pixels to 20 destination pixels. The
    50x80 protected middle and all claws on the right retain their original pixels.
    At local x35 the arrival connection is 69-80+35 = 24px ahead of Nova.
    """
    out = arr.copy()
    tail = Image.fromarray(arr[:, :55]).resize((20, 160), Image.Resampling.LANCZOS)
    out[:, :55] = 0
    out[:, 35:55] = np.array(tail)
    return clean(out)


def export(kind, variant, frames):
    size, count, fps, anchor, loop, replaces = SPECS[kind]
    assert len(frames) == count
    strip = Image.new('RGBA', (size[0]*count, size[1]))
    for i, frame in enumerate(frames):
        strip.paste(Image.fromarray(frame), (i*size[0], 0))
    path = OUT / f'nova_beam_{kind}-{variant}-v2.png'
    strip.save(path)
    write_json(path.with_suffix('.json'), {
        'note': NOTES[variant][kind], 'replaces': replaces, 'frames': count,
        'fps': fps, 'anchor': anchor, 'loop': loop,
    })


def heads(variant):
    raw = Image.open(RAW / f'head-{variant}.png').convert('RGBA')
    if variant == 'a':
        center, scale = (620, 659), (22.7, 22.7)
    else:
        center, scale = (886, 468), (25.7, 25.7)
    # Constant silhouette and anchor; four distinct lighting phases close evenly.
    base = sample(raw, (48, 48), center, scale, f'head-{variant}')
    yy, xx = np.mgrid[:48, :48]
    frames = []
    for i in range(4):
        phase = i*math.tau/4
        field = .88 + .12*np.cos(phase + (xx-24)*.10)
        frame = base.copy()
        frame[:, :, :3] = np.clip(base[:, :, :3]*field[:, :, None], 0, 255).astype(np.uint8)
        frames.append(clean(frame))
    export('head', variant, frames)


def bindings(variant):
    raw = Image.open(RAW / f'bind-{variant}.png').convert('RGBA')
    centre, scale = ((690, 642), (7.8, 8.2)) if variant == 'a' else ((670, 606), (8.5, 7.6))
    # Cyclic 0,1,0,-1 contraction around a fixed body anchor. All samples shrink RAW.
    frames = []
    for i in range(4):
        phase = i*math.tau/4
        contraction = 1 + .018*math.sin(phase)
        arr = sample(raw, (160, 160), centre,
                     (scale[0]*contraction, scale[1]*(1+.010*math.sin(phase))), f'bind-{variant}-{i}')
        arr = gain(arr, .92+.08*math.cos(phase))
        # Small source-generated sparks, isolated to the upper/lower LEFT root zone,
        # advance left in a 4-phase loop. Do not create procedural effect drawings.
        for y0, y1 in ((65, 75), (87, 97)):
            patch = arr[y0:y1, 4:28].copy()
            arr[y0:y1, 4:28] = np.roll(patch, -i*6, axis=1)
        arr = clear_middle(clean(arr))
        frames.append(arr)
    export('bind', variant, frames)
    return frames[0]


def splits(variant, last):
    raw = Image.open(RAW / f'split-{variant}.png').convert('RGBA')
    c = raw.width//2
    frames = []
    for i in range(3):
        cell = raw.crop(((i%2)*c, (i//2)*c, (i%2+1)*c, (i//2+1)*c))
        if variant == 'a':
            centre = (350, [316, 316, 341][i])
            scale = (4.15, 4.15)
        else:
            centre, scale = (335, 297), (4.05, 4.05)
        arr = sample(cell, (160, 160), centre, scale, f'split-{variant}-{i}')
        frames.append(clear_middle(arr))
    # Exact RGBA equality, including transparent RGB, across the state transition.
    frames.append(last.copy())
    export('split', variant, frames)


def tiles(variant):
    raw = Image.open(RAW / f'tile-{variant}.png').convert('RGBA')
    # A 32px half period is mirrored to guarantee a seam without repainting art.
    # Actual filament height is 7-9px within the card's 16px cell.
    if variant == 'a':
        centre, scale = (1086, 361), (7.0, 7.0)
    else:
        centre, scale = (1086, 360), (4.5, 4.5)
    half = sample(raw, (32, 16), centre, scale, f'tile-{variant}-half')
    # sample() clears a frame border; recover horizontal edges from a wider crop.
    wide = sample(raw, (36, 16), centre, scale, f'tile-{variant}-source')
    half = wide[:, 2:34].copy()
    out = np.concatenate([half, half[:, ::-1]], axis=1)
    if variant == 'a':
        # The generated braid occasionally covers its core. Copy an exposed
        # cyan core sample from the generated texture to keep one core row continuous.
        core = half[7:10, :, :].reshape(-1, 4)
        score = core[:, 1].astype(float)+core[:, 2]-core[:, 0]*.5
        selected = core[int(score.argmax())].copy()
        assert selected[3] == 255
        out[8, :] = selected
    out = clean(out, tile=True)
    export('tile', variant, [out])


def main():
    for v in 'ab':
        heads(v)
        last = bindings(v)
        splits(v, last)
        tiles(v)
    write_json(REPORT / 'processing.json', {
        'tool': 'built-in image_gen', 'raw_generation_count': 8,
        'reference_images': ['art/bakeoff/nova/nova_male-idle-v2.png',
                             'art/bakeoff/effects/nova/nova_orb-a-v1.png',
                             'art/bakeoff/effects/nova/nova_field-b-v1.png',
                             'art/bakeoff/effects/nova/nova_sphere-a-v1.png'],
        'method': 'Raw crop/pad, LANCZOS downscale, unsharp55, alpha>=128, transparent RGB zero. Left tail x0..55 shrinks to x35..55 for the 69px arrival. Bind first is split last. Cyclic contraction and luminance; source sparks move left. Tether mirrored period, generated exposed core copied across A core row.',
        'samples': PROCESS,
    })
    print('Built 8 PNG / 26 frames / 8 JSON; only permitted candidate paths.')


if __name__ == '__main__':
    main()
