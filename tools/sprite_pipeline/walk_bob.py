"""Set the head bob of a walk strip exactly, without moving the feet.

An image generator cannot place a head to within a pixel, so the bob is set after normalising.
- Each frame's head offset is found by template matching frame 1's face box.
- A target curve is fitted per step (contact 0, down +2, passing -1, up -2 by default), with the
  baseline that needs the least change.
- Each frame is raised by inserting horizontal seams, or lowered by removing them, inside the leg
  zone only. Everything above the seam (head, body, cape, held weapon) moves as one piece, the feet
  stay on the ground line, and each seam takes the path that shows least (forward energy).

  python walk_bob.py --strip in.png --face 70,34,86,48 --out out.png --report bob.json --board bob.png
  python walk_bob.py --selftest
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

CELL = 128
FEET = 120
SHAPE = (0, 2, -1, -2)


def cells(path: Path, cell: int) -> list[np.ndarray]:
	sheet = np.asarray(Image.open(path).convert("RGBA"))
	return [sheet[:cell, i * cell:(i + 1) * cell].copy() for i in range(sheet.shape[1] // cell)]


def premul(a: np.ndarray) -> np.ndarray:
	f = a.astype(np.float32)
	return np.concatenate([f[..., :3] * (f[..., 3:] / 255.0), f[..., 3:]], axis=-1)


def head_offset(ref: np.ndarray, frame: np.ndarray, box: tuple[int, int, int, int], search: int = 8) -> tuple[int, int, float]:
	"""(dy, dx, error) of frame's face against ref's face box; + dy is down."""
	x0, y0, x1, y1 = box
	t = premul(ref[y0:y1, x0:x1]); f = premul(frame); h, w = frame.shape[:2]
	best = (0, 0, float("inf"))
	for dy in range(-search, search + 1):
		for dx in range(-search // 2 - 2, search // 2 + 3):
			if y0 + dy < 0 or x0 + dx < 0 or y1 + dy > h or x1 + dx > w: continue
			err = float(np.abs(f[y0 + dy:y1 + dy, x0 + dx:x1 + dx] - t).mean())
			if err < best[2]: best = (dy, dx, err)
	return best


def fit_target(measured: list[int], shape: tuple[int, ...]) -> tuple[list[int], list[int]]:
	"""Target heads (shape + one baseline) and per-frame shifts (+ = lower the body)."""
	curve = [shape[i % len(shape)] for i in range(len(measured))]
	best = None
	for base in range(min(measured) - 6, max(measured) + 7):
		shifts = [base + c - m for c, m in zip(curve, measured)]
		key = (max(abs(s) for s in shifts), sum(abs(s) for s in shifts), abs(base))
		if best is None or key < best[0]: best = (key, [base + c for c in curve], shifts)
	return best[1], best[2]


def seam(a: np.ndarray, zone: tuple[int, int]) -> np.ndarray:
	"""Row of the least visible horizontal seam in each column, within zone rows [z0, z1)."""
	p = premul(a); h, w = a.shape[:2]; z0, z1 = zone
	up = p[np.clip(np.arange(z0, z1) - 1, 0, h - 1)]; down = p[np.clip(np.arange(z0, z1) + 1, 0, h - 1)]; mid = p[z0:z1]
	base = np.abs(down - up).sum(-1)  # (Z, W): rows above and below meet when this pixel goes
	cost_from_above = np.zeros_like(base); cost_from_below = np.zeros_like(base)
	cost_from_above[:, 1:] = np.abs(mid[:, :-1] - up[:, 1:]).sum(-1)    # path comes from (x-1, y-1)
	cost_from_below[:, 1:] = np.abs(mid[:, :-1] - down[:, 1:]).sum(-1)  # path comes from (x-1, y+1)
	z = z1 - z0; m = np.full((z, w), np.inf, np.float32); back = np.zeros((z, w), np.int8)
	m[:, 0] = base[:, 0]
	for x in range(1, w):
		prev = m[:, x - 1]
		a_ = np.full(z, np.inf, np.float32); a_[1:] = prev[:-1] + cost_from_above[1:, x]
		b_ = prev
		c_ = np.full(z, np.inf, np.float32); c_[:-1] = prev[1:] + cost_from_below[:-1, x]
		options = np.stack([a_, b_, c_]); pick = options.argmin(0)
		m[:, x] = options[pick, np.arange(z)] + base[:, x]; back[:, x] = pick - 1
	rows = np.zeros(w, int); rows[-1] = int(m[:, -1].argmin())
	for x in range(w - 1, 0, -1): rows[x - 1] = rows[x] + back[rows[x], x]
	return rows + z0


def lower(a: np.ndarray, zone: tuple[int, int], k: int) -> np.ndarray:
	"""Remove k seams in the zone: the body above comes down k px, the feet stay."""
	for _ in range(k):
		rows = seam(a, zone); out = np.zeros_like(a)
		for x, y in enumerate(rows): out[1:, x] = np.concatenate([a[:y, x], a[y + 1:, x]])
		a = out
	return a


def raise_(a: np.ndarray, zone: tuple[int, int], k: int) -> np.ndarray:
	"""Insert k seams in the zone: the body above goes up k px, the feet stay.

	The k seams are found by successive removal on a copy (so they are distinct), then all duplicated."""
	work = a.copy(); h, w = a.shape[:2]; index = np.tile(np.arange(h)[:, None], (1, w)); picked = [set() for _ in range(w)]
	for _ in range(k):
		rows = seam(work, zone); nw = np.zeros_like(work); ni = np.full_like(index, -1)
		for x, y in enumerate(rows):
			picked[x].add(int(index[y, x]))
			nw[1:, x] = np.concatenate([work[:y, x], work[y + 1:, x]]); ni[1:, x] = np.concatenate([index[:y, x], index[y + 1:, x]])
		work, index = nw, ni
	out = np.zeros_like(a)
	for x in range(w):
		col = [a[y, x] for y in range(h) for _ in range(2 if y in picked[x] else 1)]
		if np.any(np.asarray(col[:k])[:, 3]): raise ValueError("raising would cut the top of column %d" % x)
		out[:, x] = np.asarray(col[k:])
	return out


def apply(frames: list[np.ndarray], shifts: list[int], zone: tuple[int, int]) -> list[np.ndarray]:
	return [lower(f, zone, s) if s > 0 else raise_(f, zone, -s) if s < 0 else f.copy() for f, s in zip(frames, shifts)]


def board(before: list[np.ndarray], after: list[np.ndarray], box, heads, path: Path, scale: int = 3) -> None:
	n = len(before); c = before[0].shape[0]; img = Image.new("RGBA", (n * c * scale, 2 * c * scale + 8), (32, 36, 48, 255))
	for row, strip in enumerate((before, after)):
		for i, f in enumerate(strip):
			tile = Image.new("RGBA", (c, c), (32, 36, 48, 255)); tile.alpha_composite(Image.fromarray(f))
			img.paste(tile.resize((c * scale, c * scale), Image.NEAREST), (i * c * scale, row * (c * scale + 8)))
	d = ImageDraw.Draw(img); x0, y0, x1, y1 = box
	for row, hs in enumerate(heads):
		for i, (dy, dx) in enumerate(hs):
			oy = row * (c * scale + 8)
			d.rectangle([(i * c + x0 + dx) * scale, oy + (y0 + dy) * scale, (i * c + x1 + dx) * scale, oy + (y1 + dy) * scale], outline=(255, 220, 0, 255))
			d.line([(i * c) * scale, oy + FEET * scale, (i * c + c) * scale - 1, oy + FEET * scale], fill=(0, 200, 255, 255))
	img.save(path)


def selftest() -> None:
	"""A synthetic figure: a head on a body on two legs. Raising and lowering must move the head by
	exactly k and leave the feet rows untouched."""
	a = np.zeros((CELL, CELL, 4), np.uint8)
	a[30:50, 50:70] = (230, 190, 160, 255); a[50:90, 45:75] = (60, 80, 200, 255)
	a[90:120, 48:56] = (90, 60, 40, 255); a[90:120, 64:72] = (90, 60, 40, 255); a[60:110, 75:80] = (220, 220, 230, 255)
	box = (50, 30, 70, 50); before = (a[..., 3] > 0).sum(0)
	for k in (1, 2, 3):
		up = raise_(a, (92, 115), k); down = lower(a, (92, 115), k)
		assert head_offset(a, up, box)[0] == -k, k
		assert head_offset(a, down, box)[0] == k, k
		assert (up[115:] == a[115:]).all() and (down[115:] == a[115:]).all()
		grow = (up[..., 3] > 0).sum(0) - before; shrink = before - (down[..., 3] > 0).sum(0)
		legs = np.r_[48:56, 64:72]
		assert (grow[legs] == k).all() and (shrink[legs] == k).all(), k
		assert set(np.unique(grow)) <= {0, k} and set(np.unique(shrink)) <= {0, k}, k
	print("selftest ok")


def main() -> None:
	ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
	ap.add_argument("--strip", type=Path)
	ap.add_argument("--out", type=Path)
	ap.add_argument("--face", help="x0,y0,x1,y1: face box in frame 1 (cell pixels)")
	ap.add_argument("--cell", type=int, default=CELL)
	ap.add_argument("--zone", help="y0,y1: rows the seams may use (default: lower 30%% of the body down to feet-5)")
	ap.add_argument("--shape", default=",".join(map(str, SHAPE)), help="bob per step: contact,down,passing,up")
	ap.add_argument("--report", type=Path)
	ap.add_argument("--board", type=Path)
	ap.add_argument("--selftest", action="store_true")
	args = ap.parse_args()
	if args.selftest: return selftest()
	frames = cells(args.strip, args.cell); box = tuple(int(v) for v in args.face.split(","))
	shape = tuple(int(v) for v in args.shape.split(","))
	if args.zone: zone = tuple(int(v) for v in args.zone.split(","))
	else:
		top = min(int(np.nonzero(f[..., 3].any(1))[0][0]) for f in frames); zone = (int(FEET - 0.3 * (FEET - top)), FEET - 5)
	before = [head_offset(frames[0], f, box) for f in frames]
	measured = [b[0] for b in before]
	target, shifts = fit_target(measured, shape)
	out = apply(frames, shifts, zone)
	after = [head_offset(frames[0], f, box) for f in out]
	Image.fromarray(np.concatenate(out, axis=1)).save(args.out)
	report = {"face_box": box, "zone": zone, "shape": shape, "measured": measured, "target": target, "shifts": shifts,
		"after": [a[0] for a in after], "match_error": [round(b[2], 2) for b in before],
		"feet_rows_unchanged": all((o[zone[1]:] == f[zone[1]:]).all() for o, f in zip(out, frames))}
	print(json.dumps(report))
	if args.report: args.report.write_text(json.dumps(report, indent=1), encoding="utf-8")
	if args.board: board(frames, out, box, [[b[:2] for b in before], [a[:2] for a in after]], args.board)


if __name__ == "__main__":
	main()
