#!/usr/bin/env python3
"""Flatten a generated near-green background and erase green grid lines."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


def parse_grid(value: str) -> tuple[int, int]:
	columns, rows = (int(part) for part in value.lower().split("x", 1))
	if columns < 1 or rows < 1:
		raise argparse.ArgumentTypeError("grid must be positive COLUMNSxROWS")
	return columns, rows


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("source", type=Path)
	parser.add_argument("output", type=Path)
	parser.add_argument("--grid", type=parse_grid)
	parser.add_argument("--tolerance", type=int, default=90)
	parser.add_argument("--line-width", type=int, default=2)
	args = parser.parse_args()
	rgba = np.asarray(Image.open(args.source).convert("RGBA"), dtype=np.uint8).copy()
	rgb = rgba[..., :3].astype(np.int16)
	green_score = np.abs(rgb[..., 0]) + np.abs(rgb[..., 1] - 255) + np.abs(rgb[..., 2])
	near = green_score <= args.tolerance
	rgba[..., :3][near] = (0, 255, 0)
	rgba[..., 3][near] = 255
	if args.grid:
		columns, rows = args.grid
		# Only erase divider bands that are overwhelmingly green. Character pixels crossing
		# a nominal boundary are preserved.
		for coordinate, limit, axis in [(round(i * rgba.shape[1] / columns), rgba.shape[1], 1) for i in range(1, columns)] + [(round(i * rgba.shape[0] / rows), rgba.shape[0], 0) for i in range(1, rows)]:
			lo = max(0, coordinate - args.line_width); hi = min(limit, coordinate + args.line_width + 1)
			band = near[:, lo:hi] if axis == 1 else near[lo:hi, :]
			if band.size and float(np.mean(band)) >= .92:
				if axis == 1: rgba[:, lo:hi] = (0, 255, 0, 255)
				else: rgba[lo:hi, :] = (0, 255, 0, 255)
	args.output.parent.mkdir(parents=True, exist_ok=True)
	Image.fromarray(rgba, "RGBA").save(args.output, optimize=True)
	print(f"prepared {args.source} -> {args.output}; flattened={int(np.count_nonzero(near))}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
