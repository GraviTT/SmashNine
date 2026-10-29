"""SART-01: crop/downscale only; preserve every raw and candidate without overwrite.

Run with an existing Python + Pillow environment. No installs, downloads or Godot.
"""
from __future__ import annotations

import hashlib
import io
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageStat, __version__ as pillow_version

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-sart-01'
BAKE = ROOT / 'art/bakeoff/story'
RAW = ROOT / 'art/raw/story'
MANIFEST = REPORT / 'generation-manifest-v2.json'
PALETTES = {
    'cg_forest': ['#0e3b2a', '#3f7d3a', '#e8c86a', '#ff6a3d', '#b77cff'],
    'cg_beast': ['#2a1410', '#ff5a1f', '#ffd27a', '#4a2a2a'],
    'cg_heart': ['#3b1d5e', '#1a0f2e', '#9b5cff', '#ff4fd8', '#ffd6f5'],
}
NOTES = {
    'cg_forest-v1': '높은 왼쪽 사원과 내려앉는 오른쪽 거목 섬을 멀리서 보는 전경. 끊어진 덩굴 다리와 높이가 다른 수정 3개가 한눈에 보인다. v2보다 넓고 안정된 구도.',
    'cg_forest-v2': '왼쪽 거목과 가까운 끊어진 다리를 통해 오른쪽 위로 기운 사원을 올려다보는 사선 구도. v1보다 다리와 뿌리가 가까워 붕괴 압박이 강하다.',
    'cg_beast-v1': '오른쪽을 향한 거대 마그마 멧돼지의 측면 원안. 앞발과 바닥을 긁는 불꽃이 하단 25%에 걸쳐 검수에서 탈락. 수정본 v3를 비교 후보로 사용한다.',
    'cg_beast-v2': '정면에 가까운 왼쪽 사선의 멧돼지 원안. 양쪽 엄니와 들이받기 직전 자세가 강조되나 앞발과 불꽃이 하단 25%에 걸쳐 탈락. 수정본 v4 사용.',
    'cg_beast-v3': 'v1의 측면 구도를 유지하며 카메라를 물려 발과 바닥 긁기를 위로 올린 수정본. 하단은 어두운 식은 암석과 연무이며 v4보다 몸통과 등 가시 실루엣이 잘 보인다.',
    'cg_beast-v4': 'v2의 정면 사선 구도를 유지하며 발과 바닥 긁기를 위로 올린 수정본. v3보다 눈앞으로 돌진할 듯한 압박감과 두 엄니가 강조된다.',
    'cg_heart-v1': '세계수와 뒤틀려 갈라진 심장을 정면 중앙에 놓은 원형 경기장. 어두운 보라 불꽃 5개가 얕은 호로 분리되어 v2보다 수량과 최종 무대가 빠르게 읽힌다.',
    'cg_heart-v2': '경기장 왼쪽에서 오른쪽 위 심장을 보는 비대칭 사선 구도. 보라 불꽃 5개와 뿌리가 대각선 흐름을 이루며 v1보다 공간 깊이가 강조된다.',
}
FINAL_PAIRS = {
    'cg_forest': ('cg_forest-v1', 'cg_forest-v2'),
    'cg_beast': ('cg_beast-v3', 'cg_beast-v4'),
    'cg_heart': ('cg_heart-v1', 'cg_heart-v2'),
}
STAGES = {'cg_forest': '05', 'cg_beast': '07', 'cg_heart': '09'}
RECOMMENDED = {'cg_forest-v1', 'cg_beast-v3', 'cg_heart-v1'}


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def write_once(path: Path, data: bytes) -> None:
    assert any(path.resolve().is_relative_to(p.resolve()) for p in (REPORT, BAKE, RAW))
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        if path.read_bytes() != data:
            raise RuntimeError(f'Refusing to overwrite different content: {path}')
        return
    with path.open('xb') as stream:
        stream.write(data)


def write_json(path: Path, value: object) -> None:
    write_once(path, (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode('utf-8'))


def png_bytes(im: Image.Image) -> bytes:
    buf = io.BytesIO()
    im.save(buf, format='PNG', optimize=True)
    return buf.getvalue()


LUT = [v / 255 / 12.92 if v / 255 <= 0.04045 else ((v / 255 + 0.055) / 1.055) ** 2.4 for v in range(256)]


def lab(rgb: tuple[int, int, int]) -> tuple[float, float, float]:
    r, g, b = (LUT[c] for c in rgb)
    xyz = ((.4124564*r + .3575761*g + .1804375*b) / .95047,
           .2126729*r + .7151522*g + .0721750*b,
           (.0193339*r + .1191920*g + .9503041*b) / 1.08883)
    f = [t ** (1/3) if t > 216/24389 else (24389/27*t + 16)/116 for t in xyz]
    return (116*f[1]-16, 500*(f[0]-f[1]), 200*(f[1]-f[2]))


def measures(im: Image.Image, colors: list[str]) -> dict:
    w, h = im.size
    split = h * 3 // 4
    luma = lambda rgb: .2126*rgb[0] + .7152*rgb[1] + .0722*rgb[2]
    top = luma(ImageStat.Stat(im.crop((0, 0, w, split))).mean)
    bottom_image = im.crop((0, split, w, h))
    bottom = luma(ImageStat.Stat(bottom_image).mean)
    bright_count = sum(n for n, rgb in bottom_image.getcolors(w*(h-split)) if luma(rgb) >= 128)
    targets = [lab(tuple(bytes.fromhex(c[1:]))) for c in colors]
    nearest = []
    minima = [float('inf')] * len(colors)
    close = [0] * len(colors)
    total = w*h
    histogram = im.getcolors(total)
    for n, rgb in histogram:
        value = lab(rgb)
        distances = [math.sqrt(sum((a-b)**2 for a, b in zip(value, t))) for t in targets]
        nearest.append((min(distances), n))
        for i, distance in enumerate(distances):
            minima[i] = min(minima[i], distance)
            if distance <= 10:
                close[i] += n
    distance_mean = sum(d*n for d, n in nearest) / total
    cumulative = 0
    p90 = 0
    for d, n in sorted(nearest):
        cumulative += n
        if cumulative >= total * .9:
            p90 = d
            break
    return {
        'brightness_method': "Mean encoded-sRGB luma Y'=0.2126R+0.7152G+0.0722B, range 0..255; all pixels; no dialogue overlay",
        'top_three_quarters_box': [0, 0, w, split],
        'bottom_quarter_box': [0, split, w, h],
        'top_mean_luma': round(top, 4),
        'bottom_mean_luma': round(bottom, 4),
        'bottom_to_top_ratio': round(bottom/top, 6),
        'bottom_pixels_luma_at_least_128_percent': round(bright_count/(w*(h-split))*100, 5),
        'palette_method': 'CIE76 DeltaE in CIELAB D65 from sRGB, exact weighted RGB histogram of all final pixels; lower distance is closer. No palette quantization. Contract supplies no numeric pass threshold.',
        'nearest_palette_mean_delta_e76': round(distance_mean, 4),
        'nearest_palette_p90_delta_e76': round(p90, 4),
        'palette_swatches': [{
            'hex': c, 'minimum_delta_e76': round(minima[i], 4),
            'pixels_within_delta_e76_10_percent': round(close[i]/total*100, 5),
        } for i, c in enumerate(colors)],
    }


def make_sheet(asset: str, names: tuple[str, str], filename: str) -> dict:
    tiles = [BAKE / (name + '.png') for name in names]
    tiles.append(ROOT / 'smash-nine-prototype/assets/art/story/cg_prologue.png')
    width, height, header, footer = 1280, 720, 60, 48
    sheet = Image.new('RGB', (width*3, height+header+footer), '#111522')
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf', 26)
    small = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf', 22)
    titles = [names[0] + ('  추천' if names[0] in RECOMMENDED else ''), names[1], 'ART-70 cg_prologue  스타일 기준']
    for index, path in enumerate(tiles):
        im = Image.open(path).convert('RGB')
        assert im.width >= width and im.height >= height
        tile = im.resize((width, height), Image.Resampling.LANCZOS).convert('RGBA')
        overlay = Image.new('RGBA', tile.size, (0, 0, 0, 0))
        ImageDraw.Draw(overlay).rectangle((0, height*3//4, width-1, height-1), fill=(8, 12, 25, 200))
        tile = Image.alpha_composite(tile, overlay).convert('RGB')
        sheet.paste(tile, (width*index, header))
        draw.text((width*index+22, 16), titles[index], font=font, fill='#f0e9ff')
    draw.text((22, height+header+10), '각 그림 1280×720 · 하단 25%에 대화 영역 확인용 어두운 띠 · 후보 PNG에는 띠가 없음', font=small, fill='#c4cbd9')
    buffer = io.BytesIO()
    sheet.save(buffer, format='JPEG', quality=90, subsampling=2, optimize=True, progressive=True)
    data = buffer.getvalue()
    assert len(data) <= 2_000_000, f'Contact sheet exceeds 2 MB: {len(data)}'
    output = REPORT / filename
    write_once(output, data)
    return {'path': output.relative_to(ROOT).as_posix(), 'size': list(sheet.size), 'tile_size': [1280,720],
            'jpeg_quality': 90, 'subsampling': 2, 'bytes': len(data), 'sha256': sha(data),
            'band': {'y_in_tile': 540, 'height': 180, 'rgba': [8,12,25,200]}, 'sources': [p.relative_to(ROOT).as_posix() for p in tiles]}


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    results = []
    for item in manifest['candidates']:
        name = item['name']
        asset = name.rsplit('-v', 1)[0]
        source = Path(item['source_tool_path'])
        source_data = source.read_bytes()
        raw = RAW / f'{name}_raw.png'
        write_once(raw, source_data)
        im = Image.open(io.BytesIO(source_data))
        original_mode = im.mode
        if 'A' in im.getbands():
            assert im.getchannel('A').getextrema() == (255,255), 'Unexpected transparency; do not flatten silently'
        w, h = im.size
        k = min(w//16, h//9)
        cw, ch = 16*k, 9*k
        x, y = (w-cw)//2, (h-ch)//2
        box = (x,y,x+cw,y+ch)
        target = (1600,900) if w >= 1600 else (1280,720)
        assert cw >= target[0] and ch >= target[1], 'Raw too small; upscale forbidden'
        output_image = im.convert('RGB').crop(box).resize(target, Image.Resampling.LANCZOS)
        data = png_bytes(output_image)
        candidate = BAKE / (name + '.png')
        write_once(candidate, data)
        metrics = measures(output_image, PALETTES[asset])
        info = {
            'name': name, 'note': NOTES[name],
            'for_lines': [f'story.s{STAGES[asset]}.pre.1', f'story.s{STAGES[asset]}.pre.2'],
            'size': list(target), 'mode': 'RGB', 'opaque': True,
            'candidate_status': 'superseded_failed_bottom_quarter' if name in ('cg_beast-v1','cg_beast-v2') else 'review_candidate',
            'recommended_by_unit': name in RECOMMENDED, 'adopted': False,
            'parent_variant': item.get('parent'),
            'raw': raw.relative_to(ROOT).as_posix(), 'source_tool_path': str(source),
            'raw_sha256': sha(source_data), 'candidate_sha256': sha(data),
            'reference_images_in_order': item['refs'],
            'prompt_manifest': 'reports/codex-sart-01/generation-manifest-v2.json',
            'processing': {'tool': 'Python + Pillow', 'pillow_version': pillow_version,
                'raw_size': [w,h], 'raw_mode': original_mode, 'crop_box': list(box),
                'crop_convention': '[left, top, right, bottom), exclusive right/bottom',
                'cropped_size': [cw,ch], 'resize': {'from': [cw,ch], 'to': list(target), 'filter': 'LANCZOS', 'scale': target[0]/cw},
                'upscaled': False, 'other_operations': 'RGB encoding only; no paint, compositing, palette mapping, sharpening, darkening or text removal'},
            'measurements': metrics,
        }
        write_json(BAKE / (name + '.json'), info)
        results.append(info)
        print(json.dumps({'name': name, 'size': target, 'crop': box, 'top': metrics['top_mean_luma'], 'bottom': metrics['bottom_mean_luma'], 'ratio': metrics['bottom_to_top_ratio'], 'palette_mean_de76': metrics['nearest_palette_mean_delta_e76']}, ensure_ascii=False), flush=True)
    sheets = [make_sheet(asset, names, asset+'-contact.jpg') for asset, names in FINAL_PAIRS.items()]
    sheets.append(make_sheet('cg_beast', ('cg_beast-v1','cg_beast-v2'), 'cg_beast-before-contact.jpg'))
    write_json(REPORT / 'measurements-v1.json', {'pillow_version': pillow_version, 'candidates': results, 'contact_sheets': sheets})
    print(json.dumps({'contact_sheets': sheets}, ensure_ascii=False), flush=True)


if __name__ == '__main__':
    main()
