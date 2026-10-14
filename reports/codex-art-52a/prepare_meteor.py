from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art/raw/nova-52a/meteor_kick/raw.png"
TARGET = ROOT / "art/raw/nova-52a/meteor_kick/prepared.png"


def main() -> None:
	with Image.open(SOURCE) as opened:
		sheet = opened.convert("RGB")
	cell_w = sheet.width // 3
	cell_h = sheet.height // 2
	result = Image.new("RGB", sheet.size, sheet.getpixel((0, 0)))
	# Whole-pose source-pixel shifts only. At factor 0.284091 these make the
	# output descent 41, 22, 10, 4, 0, 0 px without scaling any frame.
	shifts = (0, 0, -35, 42, 56, 56)
	for index, shift_y in enumerate(shifts):
		x = (index % 3) * cell_w
		y = (index // 3) * cell_h
		cell = sheet.crop((x, y, x + cell_w, y + cell_h))
		result.paste(cell, (x, y + shift_y))
	result.save(TARGET)


if __name__ == "__main__":
	main()
