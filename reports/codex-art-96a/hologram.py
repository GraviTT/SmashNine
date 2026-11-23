"""ART-96a: immutable B foreground plus a separately generated double.

Run with the card's Python and PYTHONDONTWRITEBYTECODE=1. Writes only ART-96a
paths. Static shader treatment is defined in final-canvas pixels, not raw pixels.
"""
from pathlib import Path
import argparse
import hashlib
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-art-96a'
RAW = ROOT / 'art/raw/xion-96a'
ASSET = ROOT / 'art/bakeoff/xion/b'
SIZE = (1024, 1536)
MAIN_SCALE = 0.90
MAIN_OFFSET = (120, 68)
DOUBLE_SCALE = 0.83
DOUBLE_OFFSET = (-110, 60)
PERIOD = 6
DIM_ROWS = 4
ALPHA = 0.62
TINT = np.array([0.96, 0.24, 0.34], dtype=np.float64)
BAND_CENTRE = 602
BAND_HALF_WIDTH = 15
SLICES = [(306, 309, -5), (857, 860, 5)]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def save_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

def transparent_rgb_zero(im):
    a = np.array(im)
    a[a[:, :, 3] == 0] = 0
    return Image.fromarray(a)

def resize_float_rgba(im, scale):
    """Ordinary bilinear resize in float premultiplied RGBA.

    Float arithmetic avoids low-alpha RGB quantisation fringes from Pillow's
    8-bit premultiplied mode. No colour clamp/retouch is applied to B's figure.
    """
    size = (round(im.width*scale), round(im.height*scale))
    a = np.array(im).astype(np.float32)/255.0
    def resize(channel):
        return np.array(Image.fromarray(channel).resize(size, Image.Resampling.BILINEAR))
    alpha = resize(a[:,:,3])
    premult = np.stack([resize(a[:,:,k]*a[:,:,3]) for k in range(3)], axis=2)
    rgb = np.divide(premult,alpha[:,:,None],out=np.zeros_like(premult),where=alpha[:,:,None]>1e-8)
    out = np.rint(np.clip(np.dstack([rgb,alpha]),0,1)*255).astype(np.uint8)
    out[out[:,:,3] == 0] = 0
    return Image.fromarray(out)

def place(im, scale, offset):
    resized = resize_float_rgba(im, scale)
    layer = Image.new('RGBA', SIZE)
    layer.paste(resized, offset)
    return transparent_rgb_zero(layer)

def clean_generated(im):
    a = np.array(im.convert('RGBA'))
    count = int(np.sum((a[:, :, 3] > 0) & (a[:, :, 3] <= 4)))
    # The built-in output tops out at 254, with opaque interiors at 253.
    # This restores full-colour opaque interiors, retaining edge antialiasing.
    a[a[:, :, 3] <= 4] = 0
    a[:, :, 3] = np.rint(np.clip(a[:, :, 3].astype(float)*255/253, 0, 255)).astype(np.uint8)
    rgb = a[:, :, :3].astype(np.int16)
    green = (a[:, :, 3] > 0) & (rgb[:, :, 1] > np.maximum(rgb[:, :, 0], rgb[:, :, 2])+20)
    a[:, :, 1][green] = np.maximum(a[:, :, 0], a[:, :, 2])[green]
    a[a[:, :, 3] == 0] = 0
    return Image.fromarray(a), {'alpha_1_to_4_removed': count, 'alpha_gain': 255/253, 'green_corrected': int(green.sum())}

def treat(colour):
    a = np.array(colour).astype(np.float64)/255.0
    lum = a[:, :, :3] @ np.array([0.299, 0.587, 0.114])
    yy = np.arange(SIZE[1])
    lines = np.where(yy % PERIOD < DIM_ROWS, 0.55, 1.0)
    # One frozen smooth sweep; center reaches exactly x1.6.
    distance = np.clip(np.abs(yy-BAND_CENTRE)/BAND_HALF_WIDTH, 0, 1)
    sweep = 1-(distance*distance*(3-2*distance))
    rgb = TINT[None, None, :]*(0.42+0.85*lum[:, :, None])*(1+0.6*sweep[:, None, None])
    alpha = a[:, :, 3]*lines[:, None]*ALPHA
    rgba = np.concatenate([np.clip(rgb, 0, 1), alpha[:, :, None]], axis=2)
    rgba = np.rint(rgba*255).astype(np.uint8)
    rgba[rgba[:, :, 3] == 0] = 0
    for y0, y1, dx in SLICES:
        strip = rgba[y0:y1].copy()
        rgba[y0:y1] = 0
        if dx > 0:
            rgba[y0:y1, dx:] = strip[:, :-dx]
        else:
            rgba[y0:y1, :dx] = strip[:, -dx:]
    return Image.fromarray(rgba)

def over_bg(im, bg):
    board = Image.new('RGBA', im.size, bg)
    board.alpha_composite(im)
    return board.convert('RGB')

def font(size=20):
    return ImageFont.truetype('C:/Windows/Fonts/malgun.ttf', size)

def metrics(im):
    a = np.array(im); mask = a[:, :, 3] > 0
    x0, y0, x1, y1 = im.getbbox()
    border = np.zeros(mask.shape, bool)
    border[[0,-1],:] = True; border[:,[0,-1]] = True
    rgb = a[:, :, :3].astype(np.int16)
    return {'size': list(im.size), 'mode': im.mode, 'bbox': [x0,y0,x1,y1],
        'margins_ltrb': [x0,y0,im.width-x1,im.height-y1],
        'alpha_range': [int(a[:,:,3].min()),int(a[:,:,3].max())],
        'border_nontransparent_pixels': int(np.sum(mask & border)),
        'transparent_rgb_residue_pixels': int(np.sum((~mask) & np.any(rgb != 0, axis=2))),
        'green_fringe_pixels': int(np.sum(mask & (rgb[:,:,1] > np.maximum(rgb[:,:,0],rgb[:,:,2])+20) & (rgb[:,:,1] > 80))),
        'visible_pixels': int(mask.sum())}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--from-raw', action='store_true', help='Rebuild the colour cutout from ignored double-v2.png')
    args = parser.parse_args()
    original_path = ASSET/'xion_illustration-b.png'
    original = Image.open(original_path).convert('RGBA')
    colour_path = ASSET/'xion_double-b2-colour.png'
    if args.from_raw or not colour_path.exists():
        source = Image.open(RAW/'double-v2.png').convert('RGBA')
        colour, cleanup = clean_generated(source)
        colour.save(colour_path)
    else:
        colour = Image.open(colour_path).convert('RGBA')
        cleanup = {'alpha_1_to_4_removed':20713,'alpha_gain':255/253,'green_corrected':0,
                   'note':'Previously measured raw-to-colour treatment; existing colour asset loaded without further changes.'}
    front = place(original, MAIN_SCALE, MAIN_OFFSET)
    back_colour = place(colour, DOUBLE_SCALE, DOUBLE_OFFSET)
    holo = treat(back_colour)
    # Ordinary source-over composition; foreground RGBA is never retouched.
    # Original B has interior alpha mostly 253, which is preserved as authored.
    composite = transparent_rgb_zero(Image.alpha_composite(holo, front))
    composite.save(ASSET/'xion_illustration-b2.png')
    front.save(REPORT/'foreground-layer.png')
    back_colour.save(REPORT/'double-colour-layer.png')
    holo.save(REPORT/'hologram-layer.png')
    for name, im in [('final',composite), ('double-colour',colour)]:
        for suffix, bg in [('dark','#2a2d34'),('light','#c8c4b8')]:
            over_bg(im,bg).save(REPORT/f'{name}-{suffix}.png')
    # The comparison is exactly 50%: four full canvases, no tight crops.
    compare = Image.new('RGB', (1024, 1600), '#202329')
    draw = ImageDraw.Draw(compare)
    for row, bg in enumerate(['#2a2d34','#c8c4b8']):
        for col, (name,im) in enumerate([('v1 / original B',original),('v2 / B + double',composite)]):
            thumb = over_bg(im,bg).resize((512,768),Image.Resampling.LANCZOS)
            compare.paste(thumb,(col*512,row*800+32))
            draw.text((col*512+14,row*800+3),name,font=font(20),fill='white')
    compare.save(REPORT/'compare.png')
    # Full image without any downscale, side-by-side dark / light.
    board = Image.new('RGB',(2048,1576),'#202329')
    board.paste(over_bg(composite,'#2a2d34'),(0,40))
    board.paste(over_bg(composite,'#c8c4b8'),(1024,40))
    draw = ImageDraw.Draw(board)
    draw.text((20,8),'v2 100% / #2a2d34',font=font(),fill='white')
    draw.text((1044,8),'v2 100% / #c8c4b8',font=font(),fill='white')
    board.save(REPORT/'full-size-checks.png')
    a = np.array(front); c = np.array(composite)
    exposed = (a[:,:,3] > 0) & (np.array(holo)[:,:,3] == 0)
    # Original head crop, transformed into final space; ownership is by layer.
    head_box = (round(360*MAIN_SCALE)+MAIN_OFFSET[0],round(80*MAIN_SCALE)+MAIN_OFFSET[1],round(640*MAIN_SCALE)+MAIN_OFFSET[0],round(300*MAIN_SCALE)+MAIN_OFFSET[1])
    x0,y0,x1,y1 = head_box
    head_support = a[y0:y1,x0:x1,3] > 0
    expected_front = place(original, MAIN_SCALE, MAIN_OFFSET)
    result = {
        'source_sha256': {p.relative_to(ROOT).as_posix():sha(p) for p in [original_path,ASSET/'xion_face-b.png',colour_path]},
        'generated_cleanup': cleanup,
        'main': {'scale': MAIN_SCALE,'offset_xy': MAIN_OFFSET,'resize':'float premultiplied bilinear','redrawn':False,'body_parts_modified':False,
            'nontransparent_pixel_count':int((a[:,:,3]>0).sum()),
            'layer_mismatch_against_resized_source':int(np.sum(np.any(a != np.array(expected_front),axis=2))),
            'exposed_main_pixel_count':int(exposed.sum()),
            'exposed_main_pixel_mismatch':int(np.sum(np.any(a != c,axis=2)&exposed)),
            'composition':'unmodified foreground RGBA source-over treated double',
            'head_region_xyxy':head_box,'head_support_pixel_count':int(head_support.sum()),
            'head_pixel_mismatch':int(np.sum(np.any(a[y0:y1,x0:x1] != c[y0:y1,x0:x1],axis=2)&head_support))},
        'double': {'scale':DOUBLE_SCALE,'offset_xy':DOUBLE_OFFSET,'cleanup':cleanup},
        'hologram': {'tint':TINT.tolist(),'luminance_weights':[0.299,0.587,0.114], 'brightness':'0.42 + 0.85 * luminance',
            'alpha':ALPHA,'scanline_period_px':PERIOD,'dim_rows':DIM_ROWS,'dim_alpha_factor':0.55,
            'bright_band_centre_y':BAND_CENTRE,'bright_band_half_width':BAND_HALF_WIDTH,'bright_band_peak_multiplier':1.6,
            'slices_y0_y1_dx':SLICES,'colour_space':'normalised PNG RGB, per task formula; no extra gamma conversion',
            'note':'Static adaptation: 6px period, one frozen sweep, two shifted 3px slices. Runtime TIME/flicker not simulated.'},
        'final': metrics(composite),'colour':metrics(colour),'hologram_layer':metrics(holo),
        'fringe_definition':'Visible G > max(R,B)+20 and G>80. Hidden RGB checked separately. This does not automatically detect all possible halos.',
    }
    save_json(REPORT/'metrics.json',result)
    print(json.dumps({k:result[k] for k in ['main','final','colour']},indent=2))

if __name__ == '__main__':
    main()
