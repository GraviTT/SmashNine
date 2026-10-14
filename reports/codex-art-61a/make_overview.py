from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "overview.png"
ROWS = [
	("jump", 1, 24),
	("hurt", 1, 15),
	("attack", 6, 21),
	("mana_combo", 6, 18),
	("rising_slash", 6, 30),
	("low_sweep", 6, 30),
	("air_slash", 6, 40),
	("plunge", 6, 12),
	("dimension_slash", 6, 23),
	("rune_shield", 6, 12),
	("tumble", 6, 21),
]


def checker(size: tuple[int, int]) -> Image.Image:
	image = Image.new("RGB", size, (31, 41, 58))
	draw = ImageDraw.Draw(image)
	for y in range(0, size[1], 16):
		for x in range(0, size[0], 16):
			if (x // 16 + y // 16) % 2:
				draw.rectangle((x, y, x + 15, y + 15), fill=(39, 52, 72))
	return image


font = ImageFont.load_default()
width = 1232
heights: list[int] = []
sheets: list[tuple[str, int, int, Image.Image]] = []
for name, frames, fps in ROWS:
	path = ROOT / "art" / "bakeoff" / "rio" / f"rio_male-{name}-v1.png"
	sheet = Image.open(path).convert("RGBA")
	heights.append(sheet.height + 42)
	sheets.append((name, frames, fps, sheet))

canvas = Image.new("RGB", (width, 56 + sum(heights) + 62), (12, 18, 29))
draw = ImageDraw.Draw(canvas)
draw.text((16, 14), "RIO MALE / ART-61A / DELIVERED ROWS", fill=(238, 245, 255), font=font)
draw.text((16, 31), "Actual candidate pixels at 1x; every row was inspected in its 4x compare sheet.", fill=(139, 166, 196), font=font)
y = 56
for name, frames, fps, sheet in sheets:
	draw.text((16, y + 8), f"{name}   {frames} frame(s) @ {fps} fps", fill=(213, 228, 245), font=font)
	panel_y = y + 28
	panel = checker((width - 32, sheet.height))
	panel.paste(sheet, (0, 0), sheet)
	canvas.paste(panel, (16, panel_y))
	y += sheet.height + 42

draw.text((16, y + 12), "NOT DELIVERED: walk / fall / shield / infinity_overdrive", fill=(255, 139, 130), font=font)
draw.text((16, y + 30), "Reason: head-match and cell-fit/margin constraints could not be satisfied together.", fill=(184, 195, 211), font=font)
canvas.save(OUT)
print(OUT)
