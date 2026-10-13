from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
CELL = 128
BG = (12, 18, 30, 255)
GRID_A = (31, 43, 64, 255)
GRID_B = (41, 55, 79, 255)


def font(size: int):
	try:
		return ImageFont.truetype("C:/Windows/Fonts/consola.ttf", size)
	except OSError:
		return ImageFont.load_default()


def tile(path: str, index: int, scale: int) -> Image.Image:
	image = Image.open(ROOT / path).convert("RGBA")
	frame = image.crop((index * CELL, 0, (index + 1) * CELL, CELL))
	frame = frame.resize((CELL * scale, CELL * scale), Image.Resampling.NEAREST)
	canvas = Image.new("RGBA", frame.size, GRID_A)
	draw = ImageDraw.Draw(canvas)
	block = 8 * scale
	for y in range(0, frame.height, block):
		for x in range(0, frame.width, block):
			if (x // block + y // block) % 2:
				draw.rectangle((x, y, x + block - 1, y + block - 1), fill=GRID_B)
	canvas.alpha_composite(frame)
	return canvas


def overview() -> None:
	rows = [
		("JUMP", "art/bakeoff/nova/nova_male-jump-v1.png", 1),
		("FALL", "art/bakeoff/nova/nova_male-fall-v1.png", 1),
		("SHIELD", "art/bakeoff/nova/nova_male-shield-v1.png", 6),
	]
	scale = 2
	tile_size = CELL * scale
	label_width = 150
	width = label_width + tile_size * 7
	row_height = tile_size + 46
	canvas = Image.new("RGBA", (width, row_height * len(rows)), BG)
	draw = ImageDraw.Draw(canvas)
	for row_index, (label, path, count) in enumerate(rows):
		y = row_index * row_height
		draw.text((12, y + 12), label, font=font(20), fill=(235, 241, 255))
		draw.text((label_width + 6, y + 12), "ANCHOR F1", font=font(15), fill=(255, 211, 96))
		canvas.alpha_composite(tile("art/bakeoff/nova/nova_male-idle-v1.png", 1, scale), (label_width, y + 42))
		for index in range(count):
			x = label_width + tile_size * (index + 1)
			draw.text((x + 6, y + 12), f"F{index}", font=font(15), fill=(148, 220, 255))
			canvas.alpha_composite(tile(path, index, scale), (x, y + 42))
	canvas.convert("RGB").save(OUT / "nova-male-base-overview-2x.png", optimize=True)


def scale_check() -> None:
	items = [
		("ANCHOR F1", "art/bakeoff/nova/nova_male-idle-v1.png", 1),
		("JUMP F0", "art/bakeoff/nova/nova_male-jump-v1.png", 0),
		("FALL F0", "art/bakeoff/nova/nova_male-fall-v1.png", 0),
		("SHIELD F5", "art/bakeoff/nova/nova_male-shield-v1.png", 5),
	]
	scale = 3
	tile_size = CELL * scale
	canvas = Image.new("RGBA", (tile_size * len(items), tile_size + 50), BG)
	draw = ImageDraw.Draw(canvas)
	for column, (label, path, index) in enumerate(items):
		x = column * tile_size
		draw.text((x + 10, 14), label, font=font(20), fill=(255, 211, 96) if column == 0 else (148, 220, 255))
		canvas.alpha_composite(tile(path, index, scale), (x, 50))
	canvas.convert("RGB").save(OUT / "nova-male-base-scale-3x.png", optimize=True)


if __name__ == "__main__":
	overview()
	scale_check()
