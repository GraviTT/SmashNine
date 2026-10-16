from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


def skin_mask(image: Image.Image) -> np.ndarray:
	a = np.asarray(image.convert("RGBA"))
	r, g, b, alpha = (a[..., i].astype(int) for i in range(4))
	return (alpha > 0) & (r > 200) & (g > 150) & (b > 120) & (r > g) & (g > b) & (r - b > 40) & (r - b < 110)


def largest_skin_component(image: Image.Image) -> list[tuple[int, int]]:
	mask = skin_mask(image)
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


def strip_frames(path: Path) -> list[Image.Image]:
	strip = Image.open(path).convert("RGBA")
	cell = strip.height
	return [strip.crop((i * cell, 0, (i + 1) * cell, cell)) for i in range(6)]


def crop_face(frame: Image.Image, size: int = 32) -> tuple[Image.Image, dict[str, int]]:
	points = largest_skin_component(frame)
	if not points:
		raise ValueError("face skin component not found")
	ys = [p[0] for p in points]
	xs = [p[1] for p in points]
	cx = round(sum(xs) / len(xs))
	cy = round(sum(ys) / len(ys))
	half = size // 2
	return frame.crop((cx - half, cy - half, cx + half, cy + half)), {
		"cx": cx,
		"cy": cy,
		"skin_left": min(xs),
		"skin_top": min(ys),
		"skin_right": max(xs),
		"skin_bottom": max(ys),
	}


def checker(size: tuple[int, int], step: int = 8) -> Image.Image:
	out = Image.new("RGB", size, "#202738")
	draw = ImageDraw.Draw(out)
	for y in range(0, size[1], step):
		for x in range(0, size[0], step):
			if (x // step + y // step) % 2:
				draw.rectangle((x, y, x + step - 1, y + step - 1), fill="#2a3347")
	return out


def main() -> int:
	p = argparse.ArgumentParser()
	p.add_argument("--anchor", type=Path, required=True)
	p.add_argument("--sheet", type=Path, required=True)
	p.add_argument("--out", type=Path, required=True)
	p.add_argument("--title", required=True)
	args = p.parse_args()

	anchor = strip_frames(args.anchor)[0]
	frames = [anchor, *strip_frames(args.sheet)]
	labels = ["ANCHOR", *[f"F{i}" for i in range(1, 7)]]
	scale = 4
	crop_size = 32
	label_h = 22
	gap = 8
	panel = crop_size * scale
	board = checker((gap + len(frames) * (panel + gap), 44 + panel + gap))
	draw = ImageDraw.Draw(board)
	draw.text((8, 6), args.title, fill="white")
	draw.text((8, 22), "same-scale 4x nearest; skin-centred 32x32 crops", fill="#9fb4d8")
	measurements = []
	for i, (frame, label) in enumerate(zip(frames, labels)):
		crop, info = crop_face(frame, crop_size)
		x = gap + i * (panel + gap)
		y = 44
		bg = checker((panel, panel))
		up = crop.resize((panel, panel), Image.Resampling.NEAREST)
		bg.paste(up, (0, 0), up)
		board.paste(bg, (x, y))
		draw.rectangle((x, y, x + panel - 1, y + panel - 1), outline="#506080")
		draw.text((x + 3, y + 3), label, fill="#ffffff")
		measurements.append((label, info))
	args.out.parent.mkdir(parents=True, exist_ok=True)
	board.save(args.out)
	for label, info in measurements:
		print(label, info)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
