"""ART-79 image post-processing only. No Godot, no procedural replacement artwork.

Run from repository root with PYTHONDONTWRITEBYTECODE=1.
Inputs are the preserved built-in ImageGen results and palette-reference sheets.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'art/raw/projectiles-79'
OUT = ROOT / 'art/bakeoff/monsters'
REPORT = ROOT / 'reports/codex-art-79'
IDS = ['ember_imp', 'niflheim_frost_owl', 'jotunheim_storm_wisp',
       'midgard_rooftop_slinger', 'vanaheim_seed_sprite',
       'svartalfheim_cog_drone', 'yggdrasil_root_oracle', 'slam_shockwave']
NAMES = ['불덩이', '얼음 파편', '번개', '투석', '씨앗 꼬투리', '기계 폭탄', '유도 구체', '지면 충격파']
NOTES = [
    '오른쪽 밝은 불씨와 왼쪽으로 휘는 불꼬리. 꼬리만 흔들리는 반복 후보.',
    '오른쪽으로 향한 청백색 얼음 촉과 뒤로 흩날리는 서리. 첫 칸 단독 표시 가능.',
    '오른쪽에 모인 청백색 핵과 두 갈래 전기 가지. 가지 모양이 변하는 반복 후보.',
    '둥근 갈색 돌의 면과 밝은 광맥이 돌아가는 투석 후보.',
    '올리브색 껍질과 청록색 틈, 네 칸 모두 중앙에 보이는 밝은 생명핵. 껍질이 돌아가는 둥근 씨앗 후보.',
    '검은 철구와 황동 띠, 짧은 불붙은 도화선. 몸 중심을 기준으로 칸마다 90도 회전 보정.',
    '보라색 껍질과 청록 뿌리띠 안에서 분홍빛 핵이 맥동하는 둥근 유도탄 후보.',
    '오른쪽으로 솟는 청회색 바위와 왼쪽 먼지. 최하단 픽셀 y=43, 바닥 경계 y=44. 왼쪽 진행은 수평 반전.'
]
BGS = [(30, 13, 19), (5, 17, 22), (12, 17, 31), (12, 10, 8),
       (8, 21, 13), (18, 15, 12), (17, 9, 28), (12, 17, 31)]
FPS = [12, 12, 12, 10, 10, 12, 8, 12]
GENERATIONS = {'vanaheim_seed_sprite': 2, 'slam_shockwave': 2}
NN = Image.Resampling.NEAREST
LZ = Image.Resampling.LANCZOS
FONT_PATH = Path('C:/Windows/Fonts/malgun.ttf')


def font(size):
    return ImageFont.truetype(str(FONT_PATH), size)


def text(draw, xy, value, size=16, fill=(225, 232, 243)):
    draw.text(xy, value, font=font(size), fill=fill)


def bbox(arr):
    ys, xs = np.where(arr[..., 3] > 0)
    if not len(xs):
        raise ValueError('Empty frame')
    return [int(xs.min()), int(ys.min()), int(xs.max())+1, int(ys.max())+1]


def source_frames(id):
    path = RAW / f'{id}-gen{GENERATIONS.get(id, 1)}.png'
    a = np.array(Image.open(path).convert('RGBA'))
    # Remove near-transparent generator residue, not a chroma-key extraction.
    a[a[..., 3] < 32] = 0
    occupied = np.flatnonzero((a[..., 3] > 0).any(axis=0))
    runs = []
    start = prev = int(occupied[0])
    for x in occupied[1:]:
        if x - prev > 8:
            runs.append((start, int(prev)+1))
            start = int(x)
        prev = int(x)
    runs.append((start, prev+1))
    if len(runs) != 4:
        raise ValueError(f'{id}: expected 4 isolated groups, found {runs}')
    frames, boxes, anchors = [], [], []
    for left, right in runs:
        piece = a[:, left:right].copy()
        b = bbox(piece)
        boxes.append([b[0]+left, b[1], b[2]+left, b[3]])
        piece = piece[b[1]:b[3], b[0]:b[2]]
        h, w = piece.shape[:2]
        if id in IDS[:3]:
            lum = piece[..., :3].astype(float) @ np.array([.2126, .7152, .0722])
            yy, xx = np.indices((h, w))
            bright = (lum > 190) & (xx > w*.70) & (piece[..., 3] > 128)
            if not bright.any():
                raise ValueError(f'{id}: no front core')
            weights = np.maximum(lum[bright]-180, 1)
            anchor = (float(np.average(xx[bright], weights=weights)),
                      float(np.average(yy[bright], weights=weights)))
        elif id == 'svartalfheim_cog_drone':
            # The sphere occupies the broad lower portion; ignore the fuse for pivot.
            anchor = ((w-1)/2, h-1-(w-1)/2)
        elif id == 'slam_shockwave':
            anchor = (w-1, h)
        else:
            anchor = ((w-1)/2, (h-1)/2)
        frames.append(Image.fromarray(piece))
        anchors.append(anchor)
    return frames, boxes, anchors


def clean_final(image):
    a = np.array(image)
    a[a[..., 3] < 24] = 0
    # Single isolated pixel crumbs are not useful at the requested display scale.
    mask = a[..., 3] > 0
    seen = np.zeros(mask.shape, dtype=bool)
    for y, x in zip(*np.where(mask)):
        if seen[y, x]:
            continue
        todo = [(int(y), int(x))]
        seen[y, x] = True
        component = []
        while todo:
            cy, cx = todo.pop()
            component.append((cy, cx))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = cy+dy, cx+dx
                    if 0 <= ny < mask.shape[0] and 0 <= nx < mask.shape[1] and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        todo.append((ny, nx))
        if len(component) == 1:
            cy, cx = component[0]
            a[cy, cx] = 0
    a[a[..., 3] == 0] = 0
    return Image.fromarray(a)


def assemble(id):
    frames, boxes, anchors = source_frames(id)
    cell = (64, 48) if id == 'slam_shockwave' else (48, 48)
    if id in IDS[:3]:
        target = (37, 24)
    elif id == 'slam_shockwave':
        target = (60, 44)
    else:
        target = (24, 24)
    limits = []
    for im, (ax, ay) in zip(frames, anchors):
        # Every row has one scale; no frame-by-frame rescaling.
        if id == 'slam_shockwave':
            limits.extend([58/im.width, 39/im.height])
        else:
            limits.extend([(target[0]-3)/max(ax, 1), (cell[0]-3-target[0])/max(im.width-ax, 1),
                           (target[1]-3)/max(ay, 1), (cell[1]-3-target[1])/max(im.height-ay, 1)])
    factor = min(limits)
    result = []
    for n, (im, (ax, ay)) in enumerate(zip(frames, anchors)):
        scaled = im.resize((max(1, round(im.width*factor)), max(1, round(im.height*factor))), LZ)
        rgb = scaled.convert('RGB').filter(ImageFilter.UnsharpMask(radius=.6, percent=60, threshold=3))
        rgb.putalpha(scaled.getchannel('A'))
        scaled = clean_final(rgb)
        frame = Image.new('RGBA', cell)
        if id == 'slam_shockwave':
            pos = (61-scaled.width, 44-scaled.height)
        else:
            pos = (round(target[0]-ax*factor), round(target[1]-ay*factor))
        frame.alpha_composite(scaled, pos)
        if id == 'svartalfheim_cog_drone' and n:
            # Exact quarter-turns: no interpolation and no changing scale.
            frame = frame.rotate(-90*n, resample=NN, center=(24, 24))
        frame = clean_final(frame)
        if id not in ['vanaheim_seed_sprite', 'yggdrasil_root_oracle']:
            a = np.array(frame)
            rgb = a[..., :3].astype(np.int16)
            excess_green = (a[..., 3] > 0) & (rgb[..., 1] > np.maximum(rgb[..., 0], rgb[..., 2])+20)
            a[..., 1][excess_green] = np.maximum(a[..., 0], a[..., 2])[excess_green]
            frame = Image.fromarray(a)
        result.append(frame)
    strip = Image.new('RGBA', (cell[0]*4, cell[1]))
    for n, im in enumerate(result):
        strip.paste(im, (n*cell[0], 0))
    filename = f'{id}-v1' if id == 'slam_shockwave' else f'{id}-projectile-v1'
    strip.save(OUT / f'{filename}.png')
    k = IDS.index(id)
    meta = {'note': NOTES[k]+' 후보 전용이며 게임에는 연결하지 않음.', 'frames': 4,
            'fps': FPS[k], 'cell': list(cell) if id == 'slam_shockwave' else 48,
            'aim': 'right' if id in IDS[:3] or id == 'slam_shockwave' else 'none',
            'loop': True, 'pivot': list(target),
            'source': f'art/raw/projectiles-79/{id}-gen{GENERATIONS.get(id, 1)}.png',
            'source_boxes': boxes, 'scale': round(factor, 8)}
    if id == 'slam_shockwave':
        meta['floor'] = 44
        meta['pivot'] = [32, 44]
    elif id in IDS[:3]:
        meta['pivot'] = [24, 24]
        meta['core_anchor'] = list(target)
    (OUT / f'{filename}.json').write_text(json.dumps(meta, ensure_ascii=False, indent=2)+'\n', encoding='utf-8', newline='\n')
    return result, meta


def old_image(id):
    path = RAW / ('ember_fireball.png' if id == 'ember_imp' else f'{id}_projectile.png')
    if path.exists():
        return Image.open(path).convert('RGBA')
    # Faithful report-only mock of RealmMonster.gd:624-626 Line2D, not an old asset.
    im = Image.new('RGBA', (44, 44))
    ImageDraw.Draw(im).line([(6, 37), (14, 15), (22, 3), (30, 15), (38, 37)],
                           fill=(255, 204, 77, 255), width=5)
    return im


def attack_frame(id):
    monster = 'jotunheim_rune_golem' if id == 'slam_shockwave' else id
    candidate = RAW / f'{monster}-attack-reference.png'
    if candidate.exists():
        im = Image.open(candidate).convert('RGBA')
        c = im.height
        return im.crop((c*2, 0, c*3, c)), '신규 후보 공격 3번'
    im = Image.open(RAW / f'{monster}_sheet.png').convert('RGBA')
    c = im.width//6
    return im.crop((c*2, c*2, c*3, c*3)), '현재 시트 공격 3번'


def checker(im, box, tile=8):
    d = ImageDraw.Draw(im)
    x, y, w, h = box
    for yy in range(y, y+h, tile):
        for xx in range(x, x+w, tile):
            color = (37, 43, 55) if ((xx-x)//tile+(yy-y)//tile)%2 == 0 else (48, 55, 68)
            d.rectangle((xx, yy, min(xx+tile-1, x+w-1), min(yy+tile-1, y+h-1)), fill=color)


def mock(id, shot, bg, old=False):
    im = Image.new('RGBA', (480, 176), bg+(255,))
    d = ImageDraw.Draw(im)
    floor = 142
    d.rectangle((0, floor, 479, 175), fill=(40, 45, 50))
    d.line((0, floor, 479, floor), fill=(100, 109, 121), width=2)
    actor, kind = attack_frame(id)
    actor = actor.resize((96, 96), NN)
    x, y = (56, floor-72)
    if id in ['niflheim_frost_owl', 'jotunheim_storm_wisp', 'vanaheim_seed_sprite', 'yggdrasil_root_oracle']:
        y -= 30
    if id == 'svartalfheim_cog_drone':
        y -= 62
    im.alpha_composite(actor, (x, y))
    if id == 'slam_shockwave':
        if old:
            # Code line's actual points: origin y=-18, bottom +12, width 5.
            pts = [(224-16, floor-18+12), (224-8, floor-18-10),
                   (224, floor-18-22), (224+8, floor-18-10), (224+16, floor-18+12)]
            d.line(pts, fill=(255, 204, 77), width=5)
        else:
            im.alpha_composite(shot, (192, floor-44))
    else:
        # Code: 36 authored width * WORLD 1.5, monster cell remains 96px.
        shot = shot.resize((54, 54), NN)
        if id == 'svartalfheim_cog_drone':
            im.alpha_composite(shot, (106, 76))
        elif id == 'vanaheim_seed_sprite':
            for sx, sy in [(209, 51), (254, 68), (297, 93)]:
                im.alpha_composite(shot, (sx, sy))
        else:
            im.alpha_composite(shot, (215, 65))
    text(d, (10, 8), '이전 코드/그림 모형' if old else '후보 합성 모형 · 실행 화면 아님', 14)
    return im.convert('RGB'), kind


def board(id, frames, meta):
    k = IDS.index(id)
    w, h = frames[0].size
    im = Image.new('RGB', (1160, 780), (19, 24, 35))
    d = ImageDraw.Draw(im)
    text(d, (24, 14), f'ART-79  {id}  /  {NAMES[k]}', 23)
    text(d, (24, 51), f'4 frames · {w}×{h} cell · {meta["fps"]} fps · aim {meta["aim"]} · 후보 전용', 16)
    text(d, (24, 83), '원본 크기 1×', 16)
    for n, frame in enumerate(frames):
        x = 24+n*85
        checker(im, (x, 114, w, h), 6)
        im.paste(frame, (x, 114), frame)
        text(d, (x, 165), str(n+1), 13)
    text(d, (425, 83), '이전 1× / 36px 비교', 16)
    old = old_image(id)
    im.paste(old, (425, 114), old)
    old36 = old.resize((36, 36), NN)
    new36 = frames[0].resize((48, 36) if id == 'slam_shockwave' else (36, 36), NN)
    im.paste(old36, (505, 121), old36)
    text(d, (550, 126), '→', 16)
    im.paste(new36, (590, 121), new36)
    text(d, (700, 83), '36px 4칸 · 어두운 배경', 16)
    for n, frame in enumerate(frames):
        f = frame.resize((48, 36) if id == 'slam_shockwave' else (36, 36), NN)
        im.paste(f, (700+n*90, 121), f)
    text(d, (24, 196), '4× 확대 · 최근접', 16)
    for n, frame in enumerate(frames):
        x = 24+n*278
        checker(im, (x, 230, w*4, h*4), 16)
        f = frame.resize((w*4, h*4), NN)
        im.paste(f, (x, 230), f)
        if id == 'slam_shockwave':
            d.line((x, 230+44*4, x+w*4-1, 230+44*4), fill=(73, 181, 240), width=1)
    text(d, (24, 443), '색 테두리 확인 · 밝은 바탕 / 어두운 바탕', 16)
    for n, frame in enumerate(frames):
        x = 24+n*278
        for dx, color in [(0, (224, 226, 230)), (96, (8, 10, 15))]:
            d.rectangle((x+dx, 477, x+dx+87, 539), fill=color)
            im.paste(frame, (x+dx+10, 484), frame)
    before, _ = mock(id, old, BGS[k], old=True)
    after, kind = mock(id, frames[0], BGS[k])
    im.paste(before, (24, 575))
    im.paste(after, (650, 575))
    text(d, (24, 549), f'몬스터 96px · {kind}', 14)
    text(d, (650, 549), '투사체 54px (36×WORLD 1.5)' if id != 'slam_shockwave' else '충격파 64×48 · 청색 선은 y=44 바닥 경계', 14)
    im.save(REPORT / f'{id}.png')
    return im


def verify(id, frames, meta):
    records = []
    for n, frame in enumerate(frames):
        a = np.array(frame)
        b = bbox(a)
        margins = [b[0], b[1], frame.width-b[2], frame.height-b[3]]
        border = np.ones(a.shape[:2], dtype=bool)
        border[2:-2, 2:-2] = False
        spill = int(np.count_nonzero(a[..., 3][border]))
        if min(margins) < 2 or spill:
            raise ValueError(f'{id} frame {n+1}: margin {margins}, spill {spill}')
        if id == 'slam_shockwave' and b[3] != 44:
            raise ValueError(f'{id} frame {n+1}: floor end {b[3]}')
        transparent_rgb = int(np.count_nonzero(a[..., :3][a[..., 3] == 0]))
        rgb = a[..., :3].astype(np.int16)
        visible = a[..., 3] >= 24
        green_dominant = int(np.count_nonzero(visible & (rgb[..., 1] > np.maximum(rgb[..., 0], rgb[..., 2])+20)))
        # Pure saturated key-like green is different from the requested green/teal palette.
        near_key_green = int(np.count_nonzero(visible & (rgb[..., 0] <= 40) & (rgb[..., 1] >= 215) & (rgb[..., 2] <= 40)))
        assert near_key_green == 0
        if id not in ['vanaheim_seed_sprite', 'yggdrasil_root_oracle']:
            assert green_dominant == 0
        assert transparent_rgb == 0
        assert np.any(a[..., 3] == 0) and np.any(a[..., 3] == 255)
        records.append({'frame': n+1, 'bbox_exclusive': b, 'margins_LTRB': margins,
                        'min_margin': min(margins), 'margin_spill_pixels': spill,
                        'transparent_rgb_nonzero': transparent_rgb,
                        'green_dominant_pixels': green_dominant,
                        'near_key_green_pixels': near_key_green,
                        'alpha_nonzero_pixels': int(np.count_nonzero(a[..., 3])),
                        'rgba_sha256': hashlib.sha256(a.tobytes()).hexdigest()})
    hashes = [r['rgba_sha256'] for r in records]
    assert len(set(hashes)) == 4, f'{id}: duplicate frames'
    return {'id': id, 'frames': records, 'min_margin': min(r['min_margin'] for r in records),
            'spill_pixels': sum(r['margin_spill_pixels'] for r in records),
            'all_frames_distinct': True, 'passed': True}


def main():
    results, all_frames = [], []
    for id in IDS:
        frames, meta = assemble(id)
        results.append(verify(id, frames, meta))
        board(id, frames, meta)
        all_frames.append(frames)
        print(id, 'PASS', 'min_margin', results[-1]['min_margin'])
    (REPORT / 'measurements.json').write_text(json.dumps(results, ensure_ascii=False, indent=2)+'\n', encoding='utf-8', newline='\n')
    overview = Image.new('RGB', (1160, 8*175+82), (19, 24, 35))
    d = ImageDraw.Draw(overview)
    text(d, (24, 12), 'ART-79 · 몬스터 투사체 7종 + 지면 충격파 후보', 25)
    text(d, (24, 48), '왼쪽: 1× 네 칸 / 가운데: 첫 칸 3× / 오른쪽: 36px 네 칸 · Godot 미실행', 16)
    for k, (id, frames) in enumerate(zip(IDS, all_frames)):
        y = 82+k*175
        d.rectangle((12, y, 1147, y+163), fill=BGS[k])
        text(d, (24, y+7), f'{k+1:02d}  {id}  /  {NAMES[k]}', 16)
        for n, frame in enumerate(frames):
            overview.paste(frame, (24+n*75, y+61), frame)
            f = frame.resize((48, 36) if id == 'slam_shockwave' else (36, 36), NN)
            overview.paste(f, (730+n*96, y+69), f)
        f = frames[0].resize((frames[0].width*3, 144), NN)
        overview.paste(f, (421, y+17), f)
        text(d, (24, y+133), f'48×48 · 여백 ≥{results[k]["min_margin"]}px' if id != 'slam_shockwave' else '64×48 · 바닥 y=44 · 여백 ≥3px', 13)
    overview.save(REPORT / 'overview.png')
    compact = Image.new('RGB', (1160, 350), (19, 24, 35))
    draw = ImageDraw.Draw(compact)
    text(draw, (18, 9), 'ART-79 · 8종 / 32프레임 후보 · 실제 크기 1×', 21)
    for k, frames in enumerate(all_frames):
        x = 12+(k%4)*288
        y = 52+(k//4)*144
        draw.rectangle((x, y, x+279, y+131), fill=BGS[k])
        text(draw, (x+10, y+6), f'{k+1:02d} {NAMES[k]}', 16)
        for n, frame in enumerate(frames):
            compact.paste(frame, (x+10+n*(64 if k == 7 else 60), y+40), frame)
        text(draw, (x+10, y+99), '64×48 · 바닥 y=44' if k == 7 else '48×48 · 최소 여백 3px', 13)
    compact.save(REPORT / 'overview_compact.png')
    # Shared wave: also inspect the other monster and both horizontal directions.
    shared = Image.new('RGB', (1160, 410), (19, 24, 35))
    draw = ImageDraw.Draw(shared)
    text(draw, (24, 14), '공용 지면 충격파 · 두 사용자와 좌우 반전 합성 모형', 22)
    text(draw, (24, 49), '실행 화면 아님 · 몬스터 96px / 충격파 64×48 / 바닥 경계 y=44', 15)
    for n, monster in enumerate(['jotunheim_rune_golem', 'yggdrasil_root_guardian']):
        x = 24+n*568
        draw.rectangle((x, 90, x+543, 371), fill=(12, 17, 31) if n == 0 else (17, 9, 28))
        text(draw, (x+12, 103), monster, 17)
        draw.rectangle((x, 317, x+543, 371), fill=(40, 45, 50))
        draw.line((x, 317, x+543, 317), fill=(73, 181, 240), width=1)
        sheet = Image.open(RAW / f'{monster}_sheet.png').convert('RGBA')
        actor = sheet.crop((192, 192, 288, 288))
        shared.paste(actor, (x+224, 317-72), actor)
        wave = all_frames[-1][0]
        shared.paste(wave, (x+360, 317-44), wave)
        flipped = wave.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        shared.paste(flipped, (x+120, 317-44), flipped)
    shared.save(REPORT / 'slam_shared_context.png')


if __name__ == '__main__':
    main()
