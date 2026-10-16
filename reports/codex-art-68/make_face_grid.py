from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw

from make_face_boards import crop_face, strip_frames


def main() -> int:
	p = argparse.ArgumentParser()
	p.add_argument("--anchor", type=Path, required=True)
	p.add_argument("--sheet", type=Path, required=True)
	p.add_argument("--out", type=Path, required=True)
	args = p.parse_args()
	frames = [strip_frames(args.anchor)[0], *strip_frames(args.sheet)]
	labels = ["A", "F1", "F2", "F3", "F4", "F5", "F6"]
	crop_size = 24
	scale = 12
	panel = crop_size * scale
	cols = 4
	rows = 2
	header = 24
	board = Image.new("RGB", (cols * panel, rows * (panel + header)), "#161b28")
	draw = ImageDraw.Draw(board)
	for i, (frame, label) in enumerate(zip(frames, labels)):
		crop, _ = crop_face(frame, crop_size)
		up = crop.resize((panel, panel), Image.Resampling.NEAREST)
		x = (i % cols) * panel
		y = (i // cols) * (panel + header) + header
		checker = Image.new("RGB", (panel, panel), "#202738")
		cd = ImageDraw.Draw(checker)
		for yy in range(0, panel, scale):
			for xx in range(0, panel, scale):
				if (xx // scale + yy // scale) % 2:
					cd.rectangle((xx, yy, xx + scale - 1, yy + scale - 1), fill="#2a3347")
		checker.paste(up, (0, 0), up)
		board.paste(checker, (x, y))
		for k in range(crop_size + 1):
			line = "#56627a" if k % 4 == 0 else "#384258"
			draw.line((x + k * scale, y, x + k * scale, y + panel), fill=line)
			draw.line((x, y + k * scale, x + panel, y + k * scale), fill=line)
		draw.text((x + 4, y - 19), label, fill="white")
	board.save(args.out)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
