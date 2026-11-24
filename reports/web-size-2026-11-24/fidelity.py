"""Compare what the game decodes (tests/analysis/lead/lossy_fidelity.gd output) with the source PNGs.

Usage: python fidelity.py <project dir> <decoded dir> [crop.png]
Per texture: PSNR of the alpha-premultiplied colour over the pixels that are not fully transparent,
the 99.9th percentile of that error (0-255), and the largest alpha error. With crop.png, also draws source vs game crops of the face with the
lowest PSNR and of the title background at 3x.
"""
import math
import os
import sys
from PIL import Image, ImageDraw, ImageFont

proj, decoded = sys.argv[1:3]
crop_out = sys.argv[3] if len(sys.argv) > 3 else None
rows = []
for name in sorted(os.listdir(decoded)):
    src = Image.open(os.path.join(proj, "assets", "art", name.replace("__", "/"))).convert("RGBA")
    got = Image.open(os.path.join(decoded, name)).convert("RGBA")
    a, b = src.tobytes(), got.tobytes()
    # Colours are compared premultiplied by alpha: that is what shows over the background, so a
    # nearly transparent edge pixel whose hidden colour changed does not count as an error.
    sq = 0
    n = 0
    errors = []
    alpha_worst = 0
    for i in range(0, len(a), 4):
        alpha_worst = max(alpha_worst, abs(a[i + 3] - b[i + 3]))
        if a[i + 3] == 0 and b[i + 3] == 0:
            continue
        for c in range(3):
            d = (a[i + c] * a[i + 3] - b[i + c] * b[i + 3]) / 255.0
            sq += d * d
            errors.append(abs(d))
        n += 3
    errors.sort()
    worst = round(errors[int(len(errors) * 0.999)]) if errors else 0
    psnr = 10 * math.log10(255 * 255 / (sq / n)) if sq else float("inf")
    rows.append((psnr, worst, alpha_worst, name))

rows.sort()
for psnr, worst, alpha_worst, name in rows:
    print(f"{psnr:6.2f} dB  p99.9 {worst:3d}  alpha {alpha_worst:3d}  {name}")
faces = [r for r in rows if "_face" in r[3]]
print(f"faces: PSNR {faces[0][0]:.1f}-{faces[-1][0]:.1f} dB (median {faces[len(faces) // 2][0]:.1f})")

if crop_out:
    font = ImageFont.truetype(r"C:\Windows\Fonts\malgun.ttf", 20)
    picks = [(faces[0][3], (60, 50, 180, 150)), ("ui__title_bg.png", (860, 300, 1060, 420))]
    panels = []
    for name, box in picks:
        src = Image.open(os.path.join(proj, "assets", "art", name.replace("__", "/"))).convert("RGBA").crop(box)
        got = Image.open(os.path.join(decoded, name)).convert("RGBA").crop(box)
        short = name.split("__")[-1].replace(".png", "")
        panels.append((short, [(f"{short} 원본", src), (f"{short} 게임(손실 q0.9)", got)]))
    scale = 3
    pad = 20
    w = pad + 2 * (max(p[1][0][1].width for p in panels) * scale + pad)
    h = pad
    for _, pair in panels:
        h += 34 + pair[0][1].height * scale + pad
    canvas = Image.new("RGB", (w, h), (24, 26, 34))
    d = ImageDraw.Draw(canvas)
    y = pad
    for title, pair in panels:
        for i, (label, im) in enumerate(pair):
            x = pad + i * (im.width * scale + pad)
            d.text((x, y), label, font=font, fill=(230, 230, 236))
            big = Image.new("RGBA", im.size, (58, 60, 70, 255))
            big.alpha_composite(im)
            canvas.paste(big.convert("RGB").resize((im.width * scale, im.height * scale), Image.NEAREST), (x, y + 34))
        y += 34 + pair[0][1].height * scale + pad
    canvas.save(crop_out)
    print(crop_out, canvas.size)
