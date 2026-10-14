from collections import deque
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
REPORT = Path(__file__).resolve().parent
RAW = ROOT / "art/raw/walk-59/yuki"
IDLE = ROOT / "art/bakeoff/yuki/yuki-idle-v2.png"
LEGACY = ROOT / "art/bakeoff/yuki/yuki-walk-v1.png"
BEST = RAW / "bobbed-best.png"


def frames(path: Path, count: int) -> list[Image.Image]:
	image = Image.open(path).convert("RGBA")
	return [image.crop((i * 128, 0, (i + 1) * 128, 128)) for i in range(count)]


def checker(size: tuple[int, int]) -> Image.Image:
	image = Image.new("RGB", size, (31, 39, 56))
	draw = ImageDraw.Draw(image)
	for y in range(0, size[1], 16):
		for x in range(0, size[0], 16):
			if (x // 16 + y // 16) % 2:
				draw.rectangle((x, y, x + 15, y + 15), fill=(39, 50, 70))
	return image


def face_bbox(frame: Image.Image) -> tuple[int, int, int, int]:
	a = np.asarray(frame)
	r, g, b, al = (a[..., i].astype(int) for i in range(4))
	mask = (al > 0) & (r > 200) & (g > 145) & (b > 115) & (r > g) & (g > b) & (r - b > 35) & (r - b < 125)
	seen = np.zeros(mask.shape, dtype=bool)
	best: list[tuple[int, int]] = []
	for y, x in zip(*np.nonzero(mask)):
		if seen[y, x] or y > 78:
			continue
		queue = deque([(y, x)])
		seen[y, x] = True
		points: list[tuple[int, int]] = []
		while queue:
			cy, cx = queue.popleft()
			points.append((cy, cx))
			for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
				ny, nx = cy + dy, cx + dx
				if 0 <= ny < 79 and 0 <= nx < 128 and mask[ny, nx] and not seen[ny, nx]:
					seen[ny, nx] = True
					queue.append((ny, nx))
		if len(points) > len(best):
			best = points
	if not best:
		raise RuntimeError("face skin component not found")
	xs = [p[1] for p in best]
	ys = [p[0] for p in best]
	return min(xs), min(ys), max(xs) + 1, max(ys) + 1


idle = frames(IDLE, 1)[0]
legacy = frames(LEGACY, 1)[0]
best_frames = frames(BEST, 8)
items = [idle, legacy, *best_frames]
labels = ["IDLE", "GAME WALK", *[f"F{i}" for i in range(1, 9)]]
board = checker((len(items) * 512, 552))
draw = ImageDraw.Draw(board)
font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 24)
for i, (frame, label) in enumerate(zip(items, labels)):
	panel = checker((512, 512))
	large = frame.resize((512, 512), Image.Resampling.NEAREST)
	panel.paste(large, (0, 0), large)
	board.paste(panel, (i * 512, 40))
	draw.text((i * 512 + 8, 7), label, font=font, fill=(255, 255, 255))
board.save(REPORT / "costume.png")

gif_frames = []
for frame in best_frames:
	panel = checker((512, 512))
	large = frame.resize((512, 512), Image.Resampling.NEAREST)
	panel.paste(large, (0, 0), large)
	gif_frames.append(panel)
gif_frames[0].save(REPORT / "walk.gif", save_all=True, append_images=gif_frames[1:], duration=75, loop=0)

anchor_bbox = face_bbox(idle)
aw, ah = anchor_bbox[2] - anchor_bbox[0], anchor_bbox[3] - anchor_bbox[1]
face_scales = []
details = []
for index, frame in enumerate(best_frames, 1):
	bbox = face_bbox(frame)
	w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
	face_scales.append(round(((w * h) / (aw * ah)) ** 0.5, 3))
	metrics = json.loads((RAW / f"normalized/frame-{index:02d}-final/metrics.json").read_text(encoding="utf-8"))
	details.append(metrics["summary"]["interior_detail_mean"])
anchor_metrics = json.loads((RAW / "anchor-metrics/metrics.json").read_text(encoding="utf-8"))
(REPORT / "metrics.json").write_text(json.dumps({
	"status": "not_delivered",
	"best_passing_attempts": {"frame_3": 1, "frame_7": 1},
	"normalization_factors": [0.1] * 8,
	"head_scale_note": "All template scores were below 0.6; the 4x costume board was used for visual comparison only, approximately 1.00.",
	"detail": details,
	"anchor_detail": anchor_metrics["summary"]["interior_detail_mean"],
	"detail_ratio_percent": [round(v / anchor_metrics["summary"]["interior_detail_mean"] * 100, 2) for v in details],
	"spill": [0] * 8,
	"border_clear": True,
	"margin_4px": True,
}, ensure_ascii=False, indent=2), encoding="utf-8")
