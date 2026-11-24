"""Coordinate grid for manual belt, gun and boot inspection; never edits a sprite."""
from pathlib import Path
import sys
from PIL import Image, ImageDraw

base = Path('reports/codex-skm-07/xion/shot_air_down') / ('attempt-' + sys.argv[1])
sheet = Image.open(base / 'xion-shot_air_down.png').convert('RGBA')
for i in range(6):
    frame = sheet.crop((192*i, 0, 192*(i+1), 192))
    crop = frame.crop((40, 80, 152, 160)).resize((896, 640), Image.Resampling.NEAREST)
    out = Image.new('RGB', (976, 700), (31, 38, 55))
    out.paste(crop, (48, 32), crop)
    draw = ImageDraw.Draw(out)
    for x in range(0, 113, 4):
        draw.line((48+x*8, 32, 48+x*8, 672), fill=(70,70,70))
        draw.text((48+x*8, 14), str(40+x), fill='white')
    for y in range(0, 81, 4):
        draw.line((48, 32+y*8, 944, 32+y*8), fill=(70,70,70))
        draw.text((18, 32+y*8), str(80+y), fill='white')
    out.save(base / f'body-grid-{i+1}.png')
