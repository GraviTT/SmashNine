"""Side-by-side of lossless vs lossy WebP (q90, q85) for a face and a body sprite frame.

Usage: python lossy_compare.py <project dir> <out.png>
Every panel is the image decoded back from that WebP, so it shows what the game would draw.
"""
import io
import sys
from PIL import Image, ImageDraw, ImageFont

proj, out = sys.argv[1:3]
FONT = ImageFont.truetype(r"C:\Windows\Fonts\malgun.ttf", 22)
SMALL = ImageFont.truetype(r"C:\Windows\Fonts\malgun.ttf", 18)
BG = (24, 26, 34)
CHECK = [(58, 60, 70), (44, 46, 56)]


def roundtrip(im, **kw):
    b = io.BytesIO()
    im.save(b, "WEBP", **kw)
    size = b.tell()
    b.seek(0)
    back = Image.open(b)
    back.load()
    return back.convert("RGBA"), size


def on_checker(im):
    board = Image.new("RGBA", im.size)
    d = ImageDraw.Draw(board)
    for y in range(0, im.height, 8):
        for x in range(0, im.width, 8):
            d.rectangle([x, y, x + 7, y + 7], fill=CHECK[(x // 8 + y // 8) % 2])
    board.alpha_composite(im)
    return board


def busiest_cell(sheet, cell):
    best, at = -1, (0, 0)
    alpha = sheet.getchannel("A")
    for y in range(0, sheet.height, cell):
        for x in range(0, sheet.width, cell):
            n = sum(1 for a in alpha.crop((x, y, x + cell, y + cell)).getdata() if a > 0)
            if n > best:
                best, at = n, (x, y)
    return sheet.crop((at[0], at[1], at[0] + cell, at[1] + cell))


face = Image.open(f"{proj}/assets/art/luna/luna_face.png").convert("RGBA")
sheet = Image.open(f"{proj}/assets/art/frey/frey_moves_sheet.png").convert("RGBA")
frame = busiest_cell(sheet, 128)

rows = []
for title, im, scale, zoom_box, zoom in (
    ("Luna 얼굴 256×256 (대화창 그림)", face, 1, (70, 70, 170, 150), 3),
    ("Frey 기술 시트 한 칸 128×128 (게임 몸 그림)", frame, 2, (32, 24, 96, 72), 5),
):
    panels = []
    for label, kw in (("지금: 무손실", dict(lossless=True, quality=100, method=4)),
                      ("손실 q90", dict(quality=90, method=6)),
                      ("손실 q85", dict(quality=85, method=6))):
        back, size = roundtrip(im, **kw)
        whole = on_checker(back).resize((back.width * scale, back.height * scale), Image.NEAREST)
        crop = on_checker(back.crop(zoom_box))
        crop = crop.resize((crop.width * zoom, crop.height * zoom), Image.NEAREST)
        panels.append((f"{label} · {size / 1000:.0f} KB", whole, crop))
    rows.append((title, panels))

pad = 24
col_w = max(max(p[1].width, p[2].width) for _, ps in rows for p in ps)
width = pad + 3 * (col_w + pad)
height = 70
for _, ps in rows:
    height += 40 + 34 + max(p[1].height for p in ps) + 12 + max(p[2].height for p in ps) + pad
canvas = Image.new("RGBA", (width, height), BG + (255,))
d = ImageDraw.Draw(canvas)
d.text((pad, 18), "WebP 무손실 대 손실 (같은 그림을 저장했다가 다시 읽은 결과, Pillow로 측정)", font=FONT, fill=(235, 235, 240))
y = 70
for title, ps in rows:
    d.text((pad, y), title, font=FONT, fill=(255, 214, 120))
    y += 40
    for i, (label, whole, crop) in enumerate(ps):
        x = pad + i * (col_w + pad)
        d.text((x, y), label, font=SMALL, fill=(220, 220, 228))
        canvas.alpha_composite(whole, (x, y + 34))
        canvas.alpha_composite(crop, (x, y + 34 + max(p[1].height for p in ps) + 12))
    y += 34 + max(p[1].height for p in ps) + 12 + max(p[2].height for p in ps) + pad
canvas.convert("RGB").save(out)
print(out, canvas.size)
