"""Where a walk strip's feet are in each frame, and how far they move between frames.

The eye pairs each foot with the nearest foot of the next frame. When both feet jump far in one frame
(a passing frame drawn with the swinging foot already in front), the pairing flips and the walk reads
as feet dropping and lifting in place instead of stepping through (ART-57).

- planted feet: runs of opaque pixels touching the ground band (feet-4 .. feet)
- onion board: each frame (red) over the next (cyan), lower body only. Judge the lifted feet here: a
  skirt hem, cape or sword tip cannot be told from a lifted boot by shape alone.

  python walk_feet.py --strip art/bakeoff/frey/frey-walk-v5.png --onion onion.png --report feet.json
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

CELL = 128
FEET = 120


def runs(mask: np.ndarray, min_width: int = 1) -> list[tuple[int, int]]:
	xs = np.nonzero(mask)[0]; out = []
	if len(xs) == 0: return out
	start = prev = int(xs[0])
	for x in xs[1:]:
		if x != prev + 1:
			if prev - start + 1 >= min_width: out.append((start, prev))
			start = int(x)
		prev = int(x)
	if prev - start + 1 >= min_width: out.append((start, prev))
	return out


def feet(alpha: np.ndarray, ground: int = FEET) -> list[dict]:
	return [{"x": [s, e], "centre": (s + e) / 2} for s, e in runs(alpha[ground - 4:ground + 1].any(0))]


def onion(frames: list[np.ndarray], top: int, path: Path, scale: int = 4) -> None:
	tiles = []
	for i, cur in enumerate(frames):
		nxt = frames[(i + 1) % len(frames)]
		a, b = cur[top:FEET + 2].astype(float), nxt[top:FEET + 2].astype(float)
		la, lb = a[..., :3].mean(-1), b[..., :3].mean(-1); ma, mb = a[..., 3] > 0, b[..., 3] > 0
		img = np.full(a.shape[:2] + (3,), 20.0)
		img[ma, 0] = 90 + la[ma] * 0.65
		img[mb, 1] = 90 + lb[mb] * 0.65; img[mb, 2] = 90 + lb[mb] * 0.65
		img[ma & mb] = 200
		tiles.append(Image.fromarray(img.clip(0, 255).astype(np.uint8)).resize((a.shape[1] * scale, a.shape[0] * scale), Image.NEAREST))
	w, h = tiles[0].size; cols = 4; rows = (len(tiles) + cols - 1) // cols
	board = Image.new("RGB", (cols * (w + 4), rows * (h + 4)), (0, 0, 0))
	for i, t in enumerate(tiles): board.paste(t, ((i % cols) * (w + 4), (i // cols) * (h + 4)))
	board.save(path)


def main() -> None:
	ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
	ap.add_argument("--strip", type=Path, required=True)
	ap.add_argument("--cell", type=int, default=CELL)
	ap.add_argument("--onion", type=Path)
	ap.add_argument("--top", type=int, default=80, help="first row of the onion board")
	ap.add_argument("--report", type=Path)
	args = ap.parse_args()
	sheet = np.asarray(Image.open(args.strip).convert("RGBA"))
	frames = [sheet[:args.cell, i * args.cell:(i + 1) * args.cell] for i in range(sheet.shape[1] // args.cell)]
	result = [feet(f[..., 3] > 0) for f in frames]
	for i, r in enumerate(result):
		print("frame %d  planted %s" % (i + 1, " ".join("%d-%d (centre %.1f)" % (p["x"][0], p["x"][1], p["centre"]) for p in r) or "-"))
	if args.report: args.report.write_text(json.dumps(result, indent=1), encoding="utf-8")
	if args.onion: onion(frames, args.top, args.onion)


if __name__ == "__main__":
	main()
