"""Estimate what lossy WebP would save on the bigger packed textures.

Usage: python webp_trial.py <project dir> <pck_refs.tsv> <out.tsv>
For every packed .png whose imported file is >= 30 KB: current import mode, packed size, colour count
(pixel art keeps few colours, painted art many), and Pillow WebP sizes (lossless, lossy q85, q90).
"""
import io
import os
import re
import sys
from PIL import Image

proj, refs_tsv, out = sys.argv[1:4]
rows = []
for line in open(refs_tsv, encoding="utf-8"):
    size, level, src = line.rstrip("\n").split("\t")
    size = int(size)
    if not src.endswith(".png") or size < 30_000:
        continue
    path = os.path.join(proj, src)
    imp = open(path + ".import", encoding="utf-8").read()
    mode = re.search(r"^compress/mode=(\d)", imp, re.M).group(1)
    im = Image.open(path)
    im.load()
    rgba = im.convert("RGBA")
    colours = len(rgba.getcolors(1 << 24) or [])
    opaque = sum(1 for a in rgba.getchannel("A").getdata() if a > 0) / (rgba.width * rgba.height)
    def webp(**kw):
        b = io.BytesIO()
        rgba.save(b, "WEBP", **kw)
        return b.tell()
    rows.append((src, mode, size, im.width, im.height, colours, opaque,
                 webp(lossless=True, quality=100, method=4), webp(quality=85, method=6), webp(quality=90, method=6)))
    print(f"{src}: mode {mode}, {size//1000} KB, {colours} colours", flush=True)

with open(out, "w", encoding="utf-8") as f:
    f.write("src\tmode\tpck\tw\th\tcolours\topaque\twebp_lossless\twebp_q85\twebp_q90\n")
    for r in rows:
        f.write("\t".join(str(round(x, 3)) if isinstance(x, float) else str(x) for x in r) + "\n")
