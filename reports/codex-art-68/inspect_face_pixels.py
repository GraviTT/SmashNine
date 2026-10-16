from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


def cells(path: Path) -> list[Image.Image]:
	strip = Image.open(path).convert("RGBA")
	cell = strip.height
	return [strip.crop((i * cell, 0, (i + 1) * cell, cell)) for i in range(6)]


def largest_component(mask: np.ndarray) -> list[tuple[int, int]]:
	h, w = mask.shape
	seen = np.zeros_like(mask)
	best: list[tuple[int, int]] = []
	for y, x in zip(*np.nonzero(mask)):
		if seen[y, x]:
			continue
		queue = deque([(int(y), int(x))])
		seen[y, x] = True
		points: list[tuple[int, int]] = []
		while queue:
			cy, cx = queue.popleft()
			points.append((cy, cx))
			for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
				ny, nx = cy + dy, cx + dx
				if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
					seen[ny, nx] = True
					queue.append((ny, nx))
		if len(points) > len(best):
			best = points
	return best


def inspect(frame: Image.Image) -> dict:
	a = np.asarray(frame)
	r, g, b, alpha = (a[..., i].astype(int) for i in range(4))
	skin = (alpha > 0) & (r > 200) & (g > 150) & (b > 120) & (r > g) & (g > b) & (r - b > 40) & (r - b < 110)
	points = largest_component(skin)
	if not points:
		return {"error": "no skin"}
	ys = np.array([p[0] for p in points])
	xs = np.array([p[1] for p in points])
	left, right, top, bottom = int(xs.min()), int(xs.max()), int(ys.min()), int(ys.max())
	# Bright blue/cyan eye pixels only, constrained to the face skin neighbourhood.
	blue = (alpha > 0) & (b > 135) & (g > 75) & (b - r > 55) & (g - r > 15)
	near = np.zeros_like(blue)
	near[max(0, top - 2):bottom + 3, max(0, left - 3):right + 4] = True
	eye_points = list(zip(*np.nonzero(blue & near)))
	if eye_points:
		eye_y = int(round(float(np.median([p[0] for p in eye_points]))))
		eye_xs = [int(p[1]) for p in eye_points]
		eye_span = max(eye_xs) - min(eye_xs) + 1
	else:
		eye_y = int(round(float(np.median(ys))))
		eye_span = None
	# Cheek-to-cheek proxy at eye height: outer span of face skin/eye pixels across eye_y ±1.
	face_pixels: list[int] = []
	for yy in range(max(0, eye_y - 1), min(alpha.shape[0], eye_y + 2)):
		for xx in range(max(0, left - 1), min(alpha.shape[1], right + 2)):
			if skin[yy, xx] or blue[yy, xx]:
				face_pixels.append(xx)
	face_width = max(face_pixels) - min(face_pixels) + 1 if face_pixels else None
	return {
		"skin_bbox": [left, top, right, bottom],
		"eye_y": eye_y,
		"eye_span": eye_span,
		"face_width_at_eyes": face_width,
	}


def main() -> int:
	p = argparse.ArgumentParser()
	p.add_argument("--anchor", type=Path, required=True)
	p.add_argument("--sheet", type=Path, required=True)
	p.add_argument("--out", type=Path, required=True)
	args = p.parse_args()
	anchor = inspect(cells(args.anchor)[0])
	frames = [inspect(frame) for frame in cells(args.sheet)]
	result = {"anchor": anchor, "frames": frames}
	args.out.write_text(json.dumps(result, indent=2), encoding="utf-8")
	print(json.dumps(result))
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
