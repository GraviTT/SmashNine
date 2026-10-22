"""ART-73: align generated expression pixels, feather locally onto immutable neutrals.

No drawing of expression features. Only generated RGB is pasted through feature masks.
Run with the project-provided Python and PYTHONDONTWRITEBYTECODE=1.
"""
from pathlib import Path
import hashlib
import json
import shutil
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = Path(__file__).resolve().parents[2]
REPORT = Path(__file__).resolve().parent
RAW = ROOT / 'art/raw/faces-73'
FORMS = json.loads((REPORT / 'composite-config.json').read_text(encoding='utf-8'))
EXPRESSIONS = ['happy', 'angry', 'hurt']
FEATHER = 4


def dump(path, obj):
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def source_path(stem, cfg):
    return ROOT / f'smash-nine-prototype/assets/art/{cfg["folder"]}/{stem}_face.png'


def selection(stem, cfg, expression):
    old_cfg = json.loads((REPORT / 'review.json').read_text(encoding='utf-8'))
    return cfg.get('selected_tries', {}).get(expression,
        old_cfg[stem].get('selected_tries', {}).get(expression, 1))


def read_edit(stem, cfg, expression, attempt=None):
    attempt = attempt or selection(stem, cfg, expression)
    path = RAW / f'{stem}-{expression}-try{attempt}.png'
    return Image.open(path).convert('RGBA').resize((256, 256), Image.Resampling.LANCZOS), path


def mask_for(cfg, expression):
    support = Image.new('L', (256, 256))
    d = ImageDraw.Draw(support)
    features = dict(cfg['features'])
    features.update(cfg.get('expression_features', {}).get(expression, {}))
    for name, polygon in features.items():
        if name == 'mouth' and 'mouth_core' in cfg:
            feature = Image.new('L', (256, 256))
            ImageDraw.Draw(feature).polygon([tuple(p) for p in cfg['mouth_core']], fill=255)
            # Shared envelope of neutral + all aligned expression mouths.
            # Put the complete lip drawing inside 100% opacity, then feather
            # over the 4px skin margin rather than through the lower lip.
            support = ImageChops.lighter(support, feature.filter(ImageFilter.MaxFilter(9)))
            d = ImageDraw.Draw(support)
        else:
            d.polygon([tuple(p) for p in polygon], fill=255)
    # Finite 4px inward smoothstep feather. The drawn support already includes
    # the 3-5px feature margin, so no unbounded Gaussian tail can alter the hair.
    # Distance from the support exterior is estimated in an 8-neighbour grid.
    a = np.array(support) > 0
    distance = np.zeros((256, 256), dtype=np.float32)
    eroded = support
    for _ in range(FEATHER):
        distance += np.array(eroded) > 0
        eroded = eroded.filter(ImageFilter.MinFilter(3))
    t = np.clip(distance / FEATHER, 0, 1)
    m = np.rint(255 * t * t * (3 - 2 * t)).astype(np.uint8)
    m[~a] = 0
    return Image.fromarray(m)


def alignment_roi(cfg):
    roi = Image.new('L', (256, 256))
    d = ImageDraw.Draw(roi)
    for points in cfg['alignment']:
        d.line([tuple(p) for p in points], fill=255, width=5)
    excluded = Image.new('L', (256, 256))
    for e in EXPRESSIONS:
        excluded = ImageChops.lighter(excluded, mask_for(cfg, e))
    # Absolutely no expression pixels in the scoring region, including margin.
    excluded = excluded.point(lambda v: 255 if v else 0).filter(ImageFilter.MaxFilter(3))
    return Image.fromarray(np.where((np.array(roi) > 0) & (np.array(excluded) == 0), 255, 0).astype(np.uint8))


def shift(im, offset):
    out = Image.new('RGBA', im.size)
    out.paste(im, tuple(offset))
    return out


def align(neutral, edit, cfg):
    roi = np.array(alignment_roi(cfg)) > 0
    n = np.array(neutral).astype(np.float32)[:, :, :3]
    ngy, ngx = np.gradient(n, axis=(0, 1))
    scores = []
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            a = np.array(shift(edit, (dx, dy))).astype(np.float32)[:, :, :3]
            gy, gx = np.gradient(a, axis=(0, 1))
            rgb = float(np.abs(a[roi] - n[roi]).mean())
            gradient = float((np.abs(gx[roi]-ngx[roi]).mean() + np.abs(gy[roi]-ngy[roi]).mean()) / 2)
            scores.append({'offset': [dx, dy], 'score': .5 * rgb + gradient,
                           'rgb_mae': rgb, 'gradient_mae': gradient})
    scores.sort(key=lambda s: (s['score'], abs(s['offset'][0]) + abs(s['offset'][1])))
    return scores[0]['offset'], scores, int(roi.sum())


def make_composite(neutral, aligned, mask):
    out = Image.composite(aligned, neutral, mask)
    # The masks are internal opaque face regions. Alpha always belongs to neutral.
    out.putalpha(neutral.getchannel('A'))
    return out


def measure(neutral, aligned, output, mask):
    n, a, o, m = np.array(neutral), np.array(aligned), np.array(output), np.array(mask)
    band = (m > 0) & (m < 255)
    delta = np.abs(a[:, :, :3].astype(np.int16) - n[:, :, :3].astype(np.int16))
    out_delta = np.abs(o[:, :, :3].astype(np.int16) - n[:, :, :3].astype(np.int16))
    return {
        'outside_mask_changed_pixels': int(np.any(n != o, axis=2)[m == 0].sum()),
        'alpha_changed_pixels': int((n[:, :, 3] != o[:, :, 3]).sum()),
        'seam_band_pixels': int(band.sum()),
        'seam_edit_neutral_rgb_mae': round(float(delta[band].mean()), 4),
        'seam_composite_neutral_rgb_mae': round(float(out_delta[band].mean()), 4),
        'seam_edit_neutral_rgb_p95': round(float(np.percentile(delta[band].max(axis=1), 95)), 2),
        'mask_pixels': int((m > 0).sum()),
        'changed_pixels': int(np.any(n != o, axis=2).sum())
    }


def on_bg(im, color=(34, 42, 57, 255)):
    return Image.alpha_composite(Image.new('RGBA', im.size, color), im).convert('RGB')


def dialogue_preview(im):
    frame = Image.new('RGBA', (142, 164))
    frame.alpha_composite(im.resize((142, 142), Image.Resampling.BILINEAR), (0, 11))
    return frame


def crop_with_outline(im, mask, crop):
    rgb = on_bg(im).crop(tuple(crop)).resize(((crop[2]-crop[0])*4, (crop[3]-crop[1])*4), Image.Resampling.NEAREST)
    # One output pixel, not four: avoid hiding the feather band under the line.
    high = mask.crop(tuple(crop)).resize(rgb.size, Image.Resampling.NEAREST)
    boundary = high.point(lambda v: 255 if v >= 128 else 0)
    edge = ImageChops.subtract(boundary, boundary.filter(ImageFilter.MinFilter(3)))
    rgb.paste((53, 233, 212), mask=edge)
    return rgb


def build_boards(stem, cfg, neutral, images, masks, aligned_images, records):
    crop = cfg['crop']
    # Equal columns; true native 1x, literal 142x164 preview, native 4x face crop.
    col_w = max(272, (crop[2]-crop[0])*4 + 16)
    face_h = (crop[3]-crop[1])*4
    board = Image.new('RGB', (col_w*4, 600 + face_h), (23, 29, 40))
    d = ImageDraw.Draw(board)
    d.text((16, 9), f'{stem} | 256x256 native / 142x164 dialogue simulation / face x4', fill='white')
    d.text((16, 321), '142x164 | aspect kept, bilinear, centered', fill='white')
    d.text((16, 533), 'Face x4 | cyan = 50% mask contour (1 output pixel); no color adjustment', fill='white')
    all_images = [('neutral', neutral)] + [(e, images[e]) for e in EXPRESSIONS]
    for i, (label, im) in enumerate(all_images):
        x = i*col_w + (col_w-256)//2
        d.text((x, 34), label, fill='white')
        board.paste(on_bg(im), (x, 54))
        board.paste(on_bg(dialogue_preview(im)), (i*col_w+(col_w-142)//2, 347))
        mask = masks[label] if label != 'neutral' else masks['happy']
        fc = crop_with_outline(im, mask, crop)
        board.paste(fc, (i*col_w+(col_w-fc.width)//2, 570))
    board.save(REPORT / f'{stem}-faces.png')
    for e in EXPRESSIONS:
        out = images[e]
        review = Image.new('RGB', (1088, 310), (23, 29, 40)); rd = ImageDraw.Draw(review)
        diff = ImageChops.difference(neutral, out).convert('RGB').point(lambda v: min(v*4, 255))
        for i, (label, im) in enumerate([('neutral', neutral), ('composite candidate', out),
                                        ('50% overlay', Image.blend(neutral, out, .5)), ('RGB abs diff x4', diff)]):
            rd.text((16+i*272, 10), label, fill='white')
            review.paste(on_bg(im) if im.mode == 'RGBA' else im, (16+i*272, 38))
        review.save(REPORT / f'{stem}-{e}-difference.png')
        # Unobscured feather inspection with aligned donor + neutral for comparison.
        tiles = [neutral, aligned_images[e], out, out]
        tile_w = (crop[2]-crop[0])*4; tile_h = face_h
        seam = Image.new('RGB', (tile_w*4, tile_h+44), (23, 29, 40)); sd = ImageDraw.Draw(seam)
        for i, (label, im) in enumerate(zip(['neutral x4', 'aligned edit x4', 'composite x4', 'mask contour x4'], tiles)):
            sd.text((i*tile_w+4, 6), label, fill='white')
            tile = crop_with_outline(im, masks[e], crop) if i == 3 else on_bg(im).crop(tuple(crop)).resize((tile_w,tile_h), Image.Resampling.NEAREST)
            seam.paste(tile, (i*tile_w, 30))
        seam.save(REPORT / f'{stem}-{e}-seam.png')
    # Scoring ROI is visible on a separate board, never on the delivered image.
    roi = alignment_roi(cfg)
    r = on_bg(neutral)
    r.paste((255, 211, 52), mask=roi.point(lambda v: 110 if v else 0))
    r.crop(tuple(crop)).resize(((crop[2]-crop[0])*4, face_h), Image.Resampling.NEAREST).save(REPORT / f'{stem}-alignment.png')
    rows = [Image.open(REPORT / f'{stem}-{e}-seam.png').convert('RGB') for e in EXPRESSIONS]
    combined = Image.new('RGB', (max(im.width for im in rows), sum(im.height+22 for im in rows)), (23,29,40))
    cd = ImageDraw.Draw(combined); y = 0
    for e, im in zip(EXPRESSIONS, rows):
        cd.text((4,y), f'{stem} {e}', fill='white')
        combined.paste(im, (0,y+20)); y += im.height+22
    combined.save(REPORT / f'{stem}-seams.png')


def build_yuki_comparison():
    cfg = FORMS['yuki']
    neutral = Image.open(source_path('yuki',cfg)).convert('RGBA')
    mask = mask_for(cfg,'hurt'); images = []; records = []
    for attempt in [1,2]:
        edit, _ = read_edit('yuki',cfg,'hurt',attempt)
        offset, _, _ = align(neutral,edit,cfg)
        aligned = shift(edit,offset)
        output = make_composite(neutral,aligned,mask)
        images.append(output)
        records.append(dict(attempt=attempt,offset=offset,**measure(neutral,aligned,output,mask)))
    b = Image.new('RGB',(640,500),(23,29,40)); d = ImageDraw.Draw(b)
    for col,(attempt,im) in enumerate(zip([1,2],images)):
        d.text((col*320+10,10),f'Yuki hurt try {attempt}',fill='white')
        b.paste(on_bg(dialogue_preview(im)),(col*320+10,40))
        b.paste(on_bg(im).crop(tuple(cfg['crop'])).resize((228,224),Image.Resampling.NEAREST),(col*320+10,240))
    b.save(REPORT/'yuki-hurt-comparison.png')
    dump(REPORT/'yuki-hurt-comparison.json',records)


def run():
    archive = RAW / 'pre-composite'; archive.mkdir(exist_ok=True)
    for filename in ['README.md', 'measurements.json', 'verification.json', 'review.json']:
        dest = archive / filename
        if not dest.exists():
            shutil.copy2(REPORT / filename, dest)
    records = []; alignment_records = []; hashes = {}
    for stem, cfg in FORMS.items():
        source = source_path(stem, cfg)
        neutral = Image.open(source).convert('RGBA')
        assert neutral.size == (256, 256)
        assert source.read_bytes() == (RAW/'sources'/f'{stem}_face.png').read_bytes()
        hashes[source.relative_to(ROOT).as_posix()] = hashlib.sha256(source.read_bytes()).hexdigest()
        images = {}; masks = {}; donors = {}; form_records = []
        for e in EXPRESSIONS:
            path = ROOT / f'art/bakeoff/{cfg["folder"]}/{stem}_face-{e}-v1.png'
            for p in [path, path.with_suffix('.json')]:
                dest = archive / p.name
                if not dest.exists():
                    shutil.copy2(p, dest)
            edit, raw = read_edit(stem, cfg, e)
            offset, scores, roi_pixels = align(neutral, edit, cfg)
            aligned = shift(edit, offset)
            mask = mask_for(cfg, e)
            output = make_composite(neutral, aligned, mask)
            measurements = measure(neutral, aligned, output, mask)
            assert measurements['outside_mask_changed_pixels'] == 0
            assert measurements['alpha_changed_pixels'] == 0
            output.save(path)
            mask.save(REPORT / f'{stem}-{e}-mask.png')
            attempt = selection(stem, cfg, e)
            meta = json.loads(path.with_suffix('.json').read_text(encoding='utf-8'))
            meta.update({
                'note': '현재 무표정 초상화를 내장 이미지 도구로 편집한 뒤, 얼굴 윤곽·앞머리로 정수 정렬하고 눈·눈썹·입(필요한 볼 포함)만 Pillow 마스크로 합성한 스토리 대화용 후보. 마스크 밖 RGBA와 전체 알파는 무표정 원본과 완전히 같다. 게임 연결은 하지 않았다.',
                'expression': e, 'edited_from': source.relative_to(ROOT).as_posix(),
                'source_raw': raw.relative_to(ROOT).as_posix(), 'selected_try': attempt,
                'tries': len(list(RAW.glob(f'{stem}-{e}-try[123].png'))),
                'review_status': 'candidate', 'delivered': True, 'candidate_only': True,
                'size_normalization': 'Pillow LANCZOS 256x256 RGBA before integer alignment; no feature drawing',
                'composite': {'mask_bbox': list(mask.getbbox()), 'feather': FEATHER, 'offset': offset},
                'measurements': measurements,
                'redone_this_pass': stem == 'yuki' and e == 'hurt'
            })
            dump(path.with_suffix('.json'), meta)
            record = dict(form=stem, label=cfg['label'], expression=e, path=path.relative_to(ROOT).as_posix(),
                          offset=offset, mask_bbox=list(mask.getbbox()), feather=FEATHER,
                          selected_try=attempt, redone_this_pass=meta['redone_this_pass'], **measurements)
            records.append(record); form_records.append(record)
            alignment_records.append(dict(form=stem, expression=e, roi_pixels=roi_pixels, scores=scores))
            images[e] = output; masks[e] = mask; donors[e] = aligned
        build_boards(stem, cfg, neutral, images, masks, donors, form_records)
    dump(REPORT/'composite-measurements.json', records)
    dump(REPORT/'alignment-scores.json', alignment_records)
    dump(REPORT/'source-sha256.json', hashes)
    build_yuki_comparison()
    print('24 composites, 8 boards, 24 masks, 24 seam boards saved.')
    for r in records:
        print(f'{r["form"]:12} {r["expression"]:5} offset={r["offset"]} outside={r["outside_mask_changed_pixels"]} seam={r["seam_edit_neutral_rgb_mae"]:.2f}')


if __name__ == '__main__':
    run()
