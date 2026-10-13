"""Stack accepted one-row strips into a game sheet (6 columns, one strip per row, in order).

Every strip must be one row of the given cell (height == cell, width <= 6 * cell). The sheet keeps
each strip's pixels exactly; nothing is scaled or moved. Rows follow the character's row table
(base sheet: idle, walk, jump, fall, attack, shield, hurt; move sheet: the MOVE_SHEET_ROWS order).

  python assemble.py --cell 128 --out smash-nine-prototype/assets/art/frey/frey_sheet.png \\
      art/bakeoff/frey/frey-idle-v2.png art/bakeoff/frey/frey-walk-v2.png ...
"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

COLUMNS = 6


def assemble(strips: list[Path], cell: int) -> Image.Image:
	images = []
	for path in strips:
		strip = Image.open(path).convert("RGBA")
		if strip.height != cell or strip.width % cell:
			raise ValueError(f"{path}: {strip.width}x{strip.height} is not one row of {cell}-px cells")
		images.append(strip)
	# A strip longer than six cells (a 12-frame row) continues on the next sheet row, as the game reads it.
	spans = [-(-image.width // (COLUMNS * cell)) for image in images]
	sheet = Image.new("RGBA", (COLUMNS * cell, sum(spans) * cell), (0, 0, 0, 0))
	row = 0
	for image, span in zip(images, spans):
		for part in range(span):
			chunk = image.crop((part * COLUMNS * cell, 0, min(image.width, (part + 1) * COLUMNS * cell), cell))
			sheet.paste(chunk, (0, (row + part) * cell))
		row += span
	return sheet


def main() -> int:
	p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
	p.add_argument("--cell", type=int, required=True)
	p.add_argument("--out", type=Path, required=True)
	p.add_argument("strips", type=Path, nargs="+")
	args = p.parse_args()
	sheet = assemble(args.strips, args.cell)
	args.out.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(args.out)
	print(f"{args.out}: {sheet.width}x{sheet.height}, {len(args.strips)} rows of {args.cell}-px cells")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
