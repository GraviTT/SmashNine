"""Head size of each frame relative to the anchor's head (D32 ②), by multi-scale template matching.

The template is the anchor frame's head (wings, circlet, face) cut around the largest skin-coloured
region. Each candidate frame is searched near its own skin region at scales 0.60-1.60, and the best
masked correlation gives that frame's head scale. A sheet's head scale is the median of the frames that
match well (score >= --min-score); rotated or face-hidden frames score low and are left out.

Use it to choose ONE factor per sheet: new factor = current factor / sheet head scale. Never per frame.

  python head_scale.py --anchor art/bakeoff/frey/frey-idle-v2.png:0 --sheet art/bakeoff/frey/frey-dash_strike-v1.png --factor 0.245
  python head_scale.py --anchor art/bakeoff/frey/frey-idle-v2.png:0 --selftest
"""
from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

CELL = 128
PAD = 40
SCALES = np.round(np.arange(0.60, 1.62, 0.02), 2)
# Template box around the face centre: left, top, right, bottom (anchor pixels).
BOX = (-18, -22, 12, 8)


def skin_mask(a: np.ndarray) -> np.ndarray:
	"""Light skin (tuned on Frey; widen for other characters)."""
	r, g, b, al = (a[..., i].astype(int) for i in range(4))
	return (al > 0) & (r > 200) & (g > 150) & (b > 120) & (r > g) & (g > b) & (r - b > 40) & (r - b < 110)


def face_centre(a: np.ndarray) -> tuple[float, float] | None:
	mask = skin_mask(a); h, w = mask.shape; seen = np.zeros_like(mask); best: list[tuple[int, int]] = []
	for y, x in zip(*np.nonzero(mask)):
		if seen[y, x]: continue
		queue = deque([(y, x)]); seen[y, x] = True; points = []
		while queue:
			cy, cx = queue.popleft(); points.append((cy, cx))
			for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
				ny, nx = cy + dy, cx + dx
				if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
					seen[ny, nx] = True; queue.append((ny, nx))
		if len(points) > len(best): best = points
	if not best: return None
	return float(np.mean([p[0] for p in best])), float(np.mean([p[1] for p in best]))


def cells(path: Path, count: int | None = None) -> list[Image.Image]:
	sheet = Image.open(path).convert("RGBA")
	if count is None:
		meta = path.with_suffix(".json")
		if meta.exists(): count = int(json.loads(meta.read_text(encoding="utf-8")).get("frames") or 0) or None
	if count is None:
		count = sum(1 for i in range(sheet.width // CELL) if sheet.crop((i * CELL, 0, i * CELL + CELL, CELL)).getbbox())
	return [sheet.crop((i * CELL, 0, i * CELL + CELL, CELL)) for i in range(count)]


def head_template(anchor: Image.Image) -> Image.Image:
	centre = face_centre(np.asarray(anchor))
	if centre is None: raise ValueError("no face found in the anchor frame")
	cy, cx = round(centre[0]), round(centre[1])
	return anchor.crop((cx + BOX[0], cy + BOX[1], cx + BOX[2], cy + BOX[3]))


def head_scale(frame: Image.Image, template: Image.Image) -> tuple[float | None, float]:
	f = np.asarray(frame).astype(float); centre = face_centre(f.astype(np.uint8))
	if centre is None: return None, 0.0
	padded = np.zeros((CELL + 2 * PAD, CELL + 2 * PAD, 4)); padded[PAD:PAD + CELL, PAD:PAD + CELL] = f
	best: tuple[float | None, float] = (None, -2.0)
	for s in SCALES:
		w, h = max(4, round(template.width * s)), max(4, round(template.height * s))
		t = np.asarray(template.resize((w, h), Image.Resampling.LANCZOS)).astype(float)
		mask = np.asarray(template.getchannel("A").resize((w, h), Image.Resampling.NEAREST)) > 0
		tv = t[..., :3][mask]; tv = tv - tv.mean(); tn = np.sqrt((tv ** 2).sum()) + 1e-6
		ey, ex = centre[0] + BOX[1] * s, centre[1] + BOX[0] * s
		for dy in range(-8, 9):
			for dx in range(-8, 9):
				y0 = int(round(ey + dy)) + PAD; x0 = int(round(ex + dx)) + PAD
				patch = padded[y0:y0 + h, x0:x0 + w]
				if patch.shape[:2] != (h, w): continue
				pv = np.where(patch[..., 3][mask][:, None] > 0, patch[..., :3][mask], 0.0)
				pv = pv - pv.mean()
				score = float((tv * pv).sum() / (tn * (np.sqrt((pv ** 2).sum()) + 1e-6)))
				if score > best[1]: best = (float(s), score)
	return best


def measure(sheet: Path, template: Image.Image, count: int | None, min_score: float) -> dict:
	frames = [head_scale(frame, template) for frame in cells(sheet, count)]
	good = [s for s, score in frames if s is not None and score >= min_score]
	return {"sheet": str(sheet), "frames": [{"scale": s, "score": round(score, 3)} for s, score in frames],
		"median": round(float(np.median(good)), 3) if good else None, "used": len(good)}


def selftest(anchor: Image.Image, template: Image.Image) -> bool:
	ok = True
	for k in (0.7, 0.8, 0.9, 1.1, 1.2, 1.3):
		sub = anchor.crop(anchor.getbbox())
		sub = sub.resize((round(sub.width * k), round(sub.height * k)), Image.Resampling.LANCZOS)
		sub.putalpha(sub.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
		if sub.height > CELL - 4: sub = sub.crop((0, sub.height - (CELL - 4), sub.width, sub.height))
		canvas = Image.new("RGBA", (CELL, CELL)); canvas.alpha_composite(sub, (max(0, CELL // 2 - sub.width // 2), CELL - 4 - sub.height))
		s, score = head_scale(canvas, template)
		print(f"anchor x{k}: measured {s} (score {score:.2f})"); ok &= s is not None and abs(s - k) <= 0.021
	return ok


def main() -> int:
	p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
	p.add_argument("--anchor", required=True, help="SHEET.png:FRAME of the anchor idle")
	p.add_argument("--sheet", type=Path, action="append", default=[], help="candidate strip (repeatable)")
	p.add_argument("--frames", type=int, help="frame count (default: the .json next to the sheet)")
	p.add_argument("--factor", type=float, help="the sheet's current factor; prints the head-matched factor")
	p.add_argument("--min-score", type=float, default=0.6)
	p.add_argument("--json", type=Path, help="write results here")
	p.add_argument("--selftest", action="store_true")
	args = p.parse_args()
	path, _, index = args.anchor.rpartition(":")
	anchor = cells(Path(path), int(index) + 1)[int(index)]
	template = head_template(anchor)
	if args.selftest: return 0 if selftest(anchor, template) else 1
	results = []
	for sheet in args.sheet:
		r = measure(sheet, template, args.frames, args.min_score)
		if args.factor and r["median"]: r["head_matched_factor"] = round(args.factor / r["median"], 6)
		results.append(r)
		frames = " ".join(f"{f['scale']}({f['score']:.2f})" for f in r["frames"])
		print(f"{sheet.name}: head scale {r['median']} from {r['used']} frames | {frames}" + (f" | factor {args.factor} -> {r['head_matched_factor']}" if "head_matched_factor" in r else ""))
	if args.json: args.json.write_text(json.dumps(results, indent=2), encoding="utf-8")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
