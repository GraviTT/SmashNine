"""Assemble ART-63 by replacing only the two authorised ART-59 cells."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


CELL = 128


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--base", type=Path, required=True)
	parser.add_argument("--frame", type=Path, required=True)
	parser.add_argument("--index", type=int, required=True, help="one-based frame index")
	parser.add_argument("--out", type=Path, required=True)
	args = parser.parse_args()

	strip = Image.open(args.base).convert("RGBA")
	frame = Image.open(args.frame).convert("RGBA")
	if strip.size != (CELL * 8, CELL):
		raise ValueError(f"unexpected strip size: {strip.size}")
	if frame.size != (CELL, CELL):
		raise ValueError(f"unexpected frame size: {frame.size}")
	if not 1 <= args.index <= 8:
		raise ValueError("frame index must be 1..8")

	left = (args.index - 1) * CELL
	strip.paste(frame, (left, 0), frame)
	args.out.parent.mkdir(parents=True, exist_ok=True)
	strip.save(args.out, optimize=True)


if __name__ == "__main__":
	main()
