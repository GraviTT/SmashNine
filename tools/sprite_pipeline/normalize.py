#!/usr/bin/env python3
"""Normalize one generated motion to Smash Nine's 128px sprite contract."""

from __future__ import annotations

import argparse
from collections import Counter, deque
import glob
import json
import math
from pathlib import Path
import statistics
import sys
from typing import Iterable, Sequence

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
CELL = 128
COLUMNS = 6
FEET_Y = 120
ALPHA_CUT = 128
BG_TOLERANCE = 58.0
DEFAULT_HEIGHT = 100.0


def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
	name = "arialbd.ttf" if bold else "arial.ttf"
	path = Path("C:/Windows/Fonts") / name
	return ImageFont.truetype(str(path), size) if path.exists() else ImageFont.load_default()


def parse_grid(value: str) -> tuple[int, int]:
	try:
		columns, rows = (int(part) for part in value.lower().split("x", 1))
	except (TypeError, ValueError) as error:
		raise argparse.ArgumentTypeError("grid must be COLUMNSxROWS, for example 6x1") from error
	if columns < 1 or rows < 1:
		raise argparse.ArgumentTypeError("grid dimensions must be positive")
	return columns, rows


def parse_pick(value: str | None) -> list[int] | None:
	if value is None:
		return None
	try:
		items = [int(part.strip()) for part in value.split(",") if part.strip()]
	except ValueError as error:
		raise ValueError("--pick must contain zero-based frame indices") from error
	if not items or min(items) < 0:
		raise ValueError("--pick must contain non-negative frame indices")
	return items


def split_sheet(path: Path, grid: tuple[int, int]) -> tuple[list[Image.Image], list[str]]:
	image = Image.open(path).convert("RGBA")
	columns, rows = grid
	# Generated sheets are sometimes one or two pixels away from exact divisibility.
	# Ratio boundaries keep every source pixel and never assume a fixed-width body crop.
	xs = [round(index * image.width / columns) for index in range(columns + 1)]
	ys = [round(index * image.height / rows) for index in range(rows + 1)]
	frames: list[Image.Image] = []
	labels: list[str] = []
	for row in range(rows):
		for column in range(columns):
			frames.append(image.crop((xs[column], ys[row], xs[column + 1], ys[row + 1])))
			labels.append(f"{path.as_posix()}#{column},{row}")
	return frames, labels


def load_inputs(args: argparse.Namespace) -> tuple[list[Image.Image], list[str]]:
	if args.sheet:
		frames, labels = split_sheet(args.sheet, args.grid)
	else:
		path = Path(args.frames)
		paths = sorted(path.glob("*.png")) if path.is_dir() else [Path(p) for p in sorted(glob.glob(args.frames))]
		if not paths:
			raise ValueError(f"no PNG frames matched: {args.frames}")
		frames = [Image.open(path).convert("RGBA") for path in paths]
		labels = [path.as_posix() for path in paths]
	picks = parse_pick(args.pick)
	if picks is not None:
		if max(picks) >= len(frames):
			raise ValueError(f"--pick index {max(picks)} exceeds {len(frames)} loaded frames")
		frames = [frames[index] for index in picks]
		labels = [labels[index] for index in picks]
	if not frames or len(frames) > COLUMNS:
		raise ValueError(f"one motion must contain 1-{COLUMNS} selected frames")
	return frames, labels


def edge_pixels(image: Image.Image) -> list[tuple[int, int, int, int]]:
	p = image.load()
	result = [p[x, y] for y in (0, image.height - 1) for x in range(image.width)]
	result += [p[x, y] for x in (0, image.width - 1) for y in range(1, image.height - 1)]
	return result


def parse_color(value: str) -> tuple[int, int, int]:
	token = value.removeprefix("#")
	if len(token) != 6 or any(ch not in "0123456789abcdefABCDEF" for ch in token):
		raise ValueError("--bg must be auto, alpha, or #RRGGBB")
	return tuple(int(token[i:i + 2], 16) for i in (0, 2, 4))


def infer_background(image: Image.Image) -> tuple[int, int, int] | None:
	edge = edge_pixels(image)
	if any(pixel[3] < 32 for pixel in edge):
		return None
	coarse = Counter((r // 8 * 8, g // 8 * 8, b // 8 * 8) for r, g, b, _ in edge).most_common(1)
	if not coarse or coarse[0][1] < max(4, len(edge) // 20):
		return None
	base = coarse[0][0]
	near = [pixel[:3] for pixel in edge if max(abs(pixel[i] - base[i]) for i in range(3)) <= 16]
	return tuple(round(statistics.median(pixel[i] for pixel in near)) for i in range(3)) if near else base


def remove_connected_background(image: Image.Image, target: tuple[int, int, int]) -> Image.Image:
	rgba = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
	# int32 keeps squared RGB deltas (up to 3 * 255^2) from overflowing.
	delta = rgba[..., :3].astype(np.int32) - np.asarray(target, dtype=np.int32)
	distance = np.sqrt(np.sum(delta * delta, axis=2))
	candidate = distance <= BG_TOLERANCE
	h, w = candidate.shape
	connected = np.zeros((h, w), dtype=bool)
	queue: deque[tuple[int, int]] = deque()
	for x in range(w):
		for y in (0, h - 1):
			if candidate[y, x] and not connected[y, x]:
				connected[y, x] = True; queue.append((x, y))
	for y in range(h):
		for x in (0, w - 1):
			if candidate[y, x] and not connected[y, x]:
				connected[y, x] = True; queue.append((x, y))
	while queue:
		x, y = queue.popleft()
		for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
			if 0 <= nx < w and 0 <= ny < h and candidate[ny, nx] and not connected[ny, nx]:
				connected[ny, nx] = True; queue.append((nx, ny))
	rgba[..., 3][connected] = 0
	fringe = connected.copy()
	for _ in range(2):
		expanded = fringe.copy()
		expanded[1:] |= fringe[:-1]; expanded[:-1] |= fringe[1:]
		expanded[:, 1:] |= fringe[:, :-1]; expanded[:, :-1] |= fringe[:, 1:]
		fringe = expanded
	rgba[..., 3][fringe & (distance <= BG_TOLERANCE * 1.45)] = 0
	return Image.fromarray(rgba, "RGBA")


def clean_background(image: Image.Image, mode: str) -> tuple[Image.Image, dict[str, object]]:
	rgba = image.convert("RGBA")
	alpha = np.asarray(rgba.getchannel("A"), dtype=np.uint8)
	background = None
	resolved = mode
	if mode == "auto":
		background = None if np.any(alpha < 250) else infer_background(rgba)
		resolved = "alpha" if background is None else "color"
	elif mode != "alpha":
		background = parse_color(mode); resolved = "color"
	if background is not None:
		rgba = remove_connected_background(rgba, background)
	rgba.putalpha(rgba.getchannel("A").point(lambda value: 255 if value >= ALPHA_CUT else 0))
	return rgba, {"mode": resolved, "color": list(background) if background else None}


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
	box = image.getchannel("A").getbbox()
	if box is None:
		raise ValueError("a frame has no opaque subject after background removal")
	return box


def alpha_area(image: Image.Image) -> int:
	return int(np.count_nonzero(np.asarray(image.getchannel("A"), dtype=np.uint8)))


def load_palette(path: Path) -> list[tuple[int, int, int]]:
	data = json.loads(path.read_text(encoding="utf-8"))
	colors = [tuple(int(c) for c in item["rgb"]) for item in data["colors"]]
	if not colors or any(len(color) != 3 for color in colors):
		raise ValueError(f"invalid palette: {path}")
	return colors


def palette_violation_count(image: Image.Image, palette: Sequence[tuple[int, int, int]]) -> int:
	allowed = set(palette)
	return len({pixel[:3] for pixel in image.get_flattened_data() if pixel[3] and pixel[:3] not in allowed})


def map_palette(image: Image.Image, palette: Sequence[tuple[int, int, int]]) -> Image.Image:
	rgba = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
	visible = rgba[..., 3] >= ALPHA_CUT
	rgba[..., 3] = np.where(visible, 255, 0).astype(np.uint8)
	colors = np.asarray(palette, dtype=np.int32)
	source = rgba[..., :3][visible].astype(np.int32)
	if len(source):
		mapped = np.empty_like(source, dtype=np.uint8)
		for start in range(0, len(source), 32768):
			chunk = source[start:start + 32768]
			distance = np.sum((chunk[:, None] - colors[None]) ** 2, axis=2)
			mapped[start:start + len(chunk)] = colors[np.argmin(distance, axis=1)].astype(np.uint8)
		rgba[..., :3][visible] = mapped
	rgba[..., :3][~visible] = 0
	return Image.fromarray(rgba, "RGBA")


def bridge_outline(image: Image.Image, palette: Sequence[tuple[int, int, int]]) -> Image.Image:
	rgba = np.asarray(image, dtype=np.uint8).copy()
	visible = rgba[..., 3] == 255
	luma = rgba[..., 0] * .2126 + rgba[..., 1] * .7152 + rgba[..., 2] * .0722
	dark = visible & (luma < 72)
	left = np.roll(visible, 1, 1); right = np.roll(visible, -1, 1)
	up = np.roll(visible, 1, 0); down = np.roll(visible, -1, 0)
	dark_neighbors = sum(np.roll(np.roll(dark, dy, 0), dx, 1) for dy, dx in ((0,1),(0,-1),(1,0),(-1,0)))
	bridge = ~visible & ((left & right) | (up & down)) & (dark_neighbors >= 2)
	bridge[[0, -1], :] = False; bridge[:, [0, -1]] = False
	outline = min(palette, key=lambda c: .2126 * c[0] + .7152 * c[1] + .0722 * c[2])
	rgba[..., :3][bridge] = outline; rgba[..., 3][bridge] = 255
	return Image.fromarray(rgba, "RGBA")


def drop_small_components(image: Image.Image, minimum: int) -> tuple[Image.Image, list[dict[str, object]]]:
	"""Drop 4-connected opaque components smaller than ``minimum`` output pixels."""
	if minimum <= 0:
		return image, []
	rgba = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
	visible = rgba[..., 3] == 255
	height, width = visible.shape
	visited = np.zeros((height, width), dtype=bool)
	dropped: list[dict[str, object]] = []
	for y in range(height):
		for x in range(width):
			if not visible[y, x] or visited[y, x]:
				continue
			queue: deque[tuple[int, int]] = deque([(x, y)])
			visited[y, x] = True
			component: list[tuple[int, int]] = []
			while queue:
				cx, cy = queue.popleft()
				component.append((cx, cy))
				for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
					if 0 <= nx < width and 0 <= ny < height and visible[ny, nx] and not visited[ny, nx]:
						visited[ny, nx] = True
						queue.append((nx, ny))
			if len(component) >= minimum:
				continue
			xs = [point[0] for point in component]
			ys = [point[1] for point in component]
			for cx, cy in component:
				rgba[cy, cx] = 0
			dropped.append({
				"pixels": len(component),
				"bbox": [min(xs), min(ys), max(xs) + 1, max(ys) + 1],
			})
	return Image.fromarray(rgba, "RGBA"), dropped


def common_scale(frames: Sequence[Image.Image], rule: str, source_ground: int) -> tuple[float, dict[str, object]]:
	boxes = [alpha_bbox(frame) for frame in frames]
	tolerance = max(1, round(max(frame.height for frame in frames) * .01))
	contact = [i for i, box in enumerate(boxes) if source_ground - (box[3] - 1) <= tolerance] or list(range(len(frames)))
	if rule.startswith("fixed:"):
		scale = float(rule.split(":", 1)[1]); detail = {"measurement": "fixed", "contact_indices": contact}
	elif rule == "height" or rule.startswith("height:"):
		target = float(rule.split(":", 1)[1]) if ":" in rule else DEFAULT_HEIGHT
		heights = [boxes[i][3] - boxes[i][1] for i in contact]
		reference = float(statistics.median(heights)); scale = target / reference
		detail = {"measurement": "median contact-frame body height", "source_median_px": reference, "target_px": target, "contact_indices": contact}
	else:
		raise ValueError("--scale-by must be fixed:<factor>, height, or height:<px>")
	if not math.isfinite(scale) or scale <= 0:
		raise ValueError("common scale must be a positive finite number")
	return scale, detail


def torso_anchor_x(image: Image.Image) -> float:
	box = alpha_bbox(image); alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
	top = box[1] + round((box[3] - box[1]) * .36); bottom = box[1] + round((box[3] - box[1]) * .72)
	centers = []
	for y in range(top, max(top + 1, bottom)):
		xs = np.flatnonzero(alpha[y] > 0)
		if xs.size: centers.append((int(xs.min()) + int(xs.max())) / 2)
	return float(statistics.median(centers)) if centers else (box[0] + box[2] - 1) / 2


def normalize_frame(source: Image.Image, scale: float, source_ground: int, palette: Sequence[tuple[int, int, int]], outline: str) -> tuple[Image.Image, int, int]:
	box = alpha_bbox(source); bottom = box[3] - 1
	subject = source.crop(box)
	size = (max(1, round(subject.width * scale)), max(1, round(subject.height * scale)))
	resample = Image.Resampling.BOX if scale < 1 else Image.Resampling.NEAREST
	subject = subject.resize(size, resample)
	subject.putalpha(subject.getchannel("A").point(lambda value: 255 if value >= ALPHA_CUT else 0))
	trim = subject.getbbox()
	if trim is None: raise ValueError("a frame disappeared while resizing")
	subject = subject.crop(trim)
	lift = max(0, round((source_ground - bottom) * scale)); target_bottom = FEET_Y - lift
	anchor = (torso_anchor_x(source) - box[0]) * scale
	x = round(CELL / 2 - anchor); y = target_bottom - subject.height + 1
	if x < 1 or y < 1 or x + subject.width > CELL - 1 or y + subject.height > CELL - 1:
		raise ValueError(f"frame does not fit at common scale {scale:.8g}: placement x={x}, y={y}, size={subject.width}x{subject.height}; regenerate or choose one smaller fixed factor for the whole motion")
	canvas = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0)); canvas.alpha_composite(subject, (x, y))
	violations = palette_violation_count(canvas, palette)
	canvas = map_palette(canvas, palette)
	if outline == "auto": canvas = bridge_outline(canvas, palette)
	return canvas, lift, violations


def margins(box: tuple[int, int, int, int]) -> dict[str, int | bool]:
	values = {"left": box[0], "top": box[1], "right": CELL - box[2], "bottom": CELL - box[3]}
	values["minimum"] = min(int(value) for value in values.values())
	values["has_4px_margin"] = bool(values["minimum"] >= 4)
	return values


def parse_reference(spec: str) -> tuple[Path, int, int]:
	parts = spec.split(":")
	if len(parts) > 1 and len(parts[0]) == 1 and parts[1].startswith(("/", "\\")):
		parts = [parts[0] + ":" + parts[1], *parts[2:]]
	path = Path(parts[0]); path = path if path.is_absolute() else ROOT / path
	return path, int(parts[1]) if len(parts) > 1 else 0, int(parts[2]) if len(parts) > 2 else COLUMNS


def reference_frames(spec: str) -> tuple[Image.Image, list[Image.Image]]:
	path, row, count = parse_reference(spec); sheet = Image.open(path).convert("RGBA")
	idle = sheet.crop((0, 0, CELL, CELL))
	return idle, [sheet.crop((i * CELL, row * CELL, (i + 1) * CELL, (row + 1) * CELL)) for i in range(count)]


def checker(size: tuple[int, int], square: int = 16) -> Image.Image:
	image = Image.new("RGB", size, (31, 38, 55)); draw = ImageDraw.Draw(image)
	for y in range(0, size[1], square):
		for x in range(0, size[0], square):
			if (x // square + y // square) % 2: draw.rectangle((x, y, x + square - 1, y + square - 1), fill=(43, 52, 72))
	return image


def render_row(frames: Sequence[Image.Image], label: str, scale: int = 2) -> Image.Image:
	cell = CELL * scale; label_width = 190
	row = checker((label_width + cell * len(frames), cell), 16); draw = ImageDraw.Draw(row)
	draw.rectangle((0, 0, label_width - 1, cell - 1), fill=(15, 21, 34)); draw.text((12, 14), label, font=font(18, True), fill=(239, 244, 255))
	for i, frame in enumerate(frames):
		x = label_width + i * cell; tile = frame.resize((cell, cell), Image.Resampling.NEAREST)
		row.paste(tile.convert("RGB"), (x, 0), tile.getchannel("A")); draw.rectangle((x, 0, x + cell - 1, cell - 1), outline=(76, 92, 125))
		draw.line((x, FEET_Y * scale, x + cell - 1, FEET_Y * scale), fill=(240, 75, 84), width=scale)
		draw.text((x + 5, 4), f"F{i}", font=font(13, True), fill=(235, 240, 250))
	return row


def save_sheet(frames: Sequence[Image.Image], path: Path) -> None:
	sheet = Image.new("RGBA", (CELL * COLUMNS, CELL), (0, 0, 0, 0))
	for i, frame in enumerate(frames): sheet.alpha_composite(frame, (i * CELL, 0))
	sheet.save(path, optimize=True)


def write_visuals(frames: Sequence[Image.Image], out: Path, reference: str | None, title: str) -> None:
	render_row(frames, "CANDIDATE 2X").save(out / "closeup.png", optimize=True)
	if reference:
		idle, current = reference_frames(reference)
		rows = [render_row([idle, *current], "CURRENT + IDLE"), render_row([idle, *frames], "CANDIDATE + IDLE")]
	else:
		rows = [render_row(frames, "CANDIDATE")]
	width = max(row.width for row in rows); head = 62; gap = 8
	canvas = Image.new("RGB", (width, head + sum(row.height for row in rows) + gap * (len(rows) - 1)), (12, 17, 29)); draw = ImageDraw.Draw(canvas)
	draw.text((16, 10), title, font=font(24, True), fill=(243, 247, 255)); draw.text((16, 39), "red = feet y120; first cell = current idle", font=font(14), fill=(166, 190, 228))
	y = head
	for row in rows: canvas.paste(row, (0, y)); y += row.height + gap
	canvas.save(out / "compare.png", optimize=True)


def spread(values: Iterable[float]) -> float:
	items = list(values)
	return round((max(items) - min(items)) / max(items) * 100, 2) if items and max(items) else 0.0


def normalize(args: argparse.Namespace) -> dict[str, object]:
	frames, labels = load_inputs(args); prepared = []; backgrounds = []
	for frame in frames:
		cleaned, report = clean_background(frame, args.bg); prepared.append(cleaned); backgrounds.append(report)
	bottoms = [alpha_bbox(frame)[3] - 1 for frame in prepared]; source_ground = max(bottoms)
	scale, scale_detail = common_scale(prepared, args.scale_by, source_ground); palette = load_palette(args.palette)
	results = []; lifts = []; violations = []; dropped_components = []
	for frame in prepared:
		result, lift, before = normalize_frame(frame, scale, source_ground, palette, args.outline)
		result, dropped = drop_small_components(result, args.min_component)
		results.append(result); lifts.append(lift); violations.append(before); dropped_components.append(dropped)
	args.out_dir.mkdir(parents=True, exist_ok=True); frame_dir = args.out_dir / "frames"; frame_dir.mkdir(exist_ok=True)
	sheet_path = args.out_dir / f"{args.name}.png"; save_sheet(results, sheet_path)
	if args.candidate_out:
		args.candidate_out.parent.mkdir(parents=True, exist_ok=True)
		save_sheet(results, args.candidate_out)
	for i, frame in enumerate(results): frame.save(frame_dir / f"{args.name}-{i:02d}.png", optimize=True)
	write_visuals(results, args.out_dir, args.reference, args.title)
	items = []
	for i, frame in enumerate(results):
		box = alpha_bbox(frame); colors = {p[:3] for p in frame.get_flattened_data() if p[3]}; alpha = sorted(set(frame.getchannel("A").get_flattened_data()))
		items.append({"index": i, "source": labels[i], "bbox": list(box), "body_height": box[3] - box[1], "body_width": box[2] - box[0], "area": alpha_area(frame), "bottom": box[3] - 1, "lift": FEET_Y - (box[3] - 1), "expected_lift": lifts[i], "colour_count": len(colors), "palette_violations_before_map": violations[i], "palette_violations": palette_violation_count(frame, palette), "alpha_values": alpha, "alpha_binary": set(alpha) <= {0, 255}, "border_clear": box[0] > 0 and box[1] > 0 and box[2] < CELL and box[3] < CELL, "margin": margins(box), "dropped_components": dropped_components[i], "dropped_component_pixels": sum(item["pixels"] for item in dropped_components[i])})
	heights = [item["body_height"] for item in items]; widths = [item["body_width"] for item in items]; areas = [item["area"] for item in items]
	summary = {"frame_count": len(items), "output_columns": COLUMNS, "common_scale": round(scale, 8), "scale_by": args.scale_by, "min_component": args.min_component, "dropped_component_count": sum(len(group) for group in dropped_components), "dropped_component_pixels": sum(component["pixels"] for group in dropped_components for component in group), "body_height_range": [min(heights), max(heights)], "body_width_range": [min(widths), max(widths)], "area_range": [min(areas), max(areas)], "area_spread_percent": spread(areas), "bottom_range": [min(item["bottom"] for item in items), max(item["bottom"] for item in items)], "lift_range": [min(lifts), max(lifts)], "contact_on_y120": all(item["bottom"] == FEET_Y for item in items if item["expected_lift"] == 0), "airborne_lift_preserved": all(item["lift"] == item["expected_lift"] for item in items), "colour_count_range": [min(item["colour_count"] for item in items), max(item["colour_count"] for item in items)], "palette_violations_before_map": sum(violations), "palette_violations": sum(item["palette_violations"] for item in items), "alpha_binary": all(item["alpha_binary"] for item in items), "borders_clear": all(item["border_clear"] for item in items), "all_have_4px_margin": all(item["margin"]["has_4px_margin"] for item in items)}
	metrics = {"input": {"sheet": args.sheet.as_posix() if args.sheet else None, "frames": args.frames, "grid": list(args.grid) if args.grid else None, "pick": parse_pick(args.pick), "backgrounds": backgrounds}, "normalization": {**scale_detail, "outline": args.outline, "cell": CELL, "feet_y": FEET_Y, "horizontal_anchor": "median torso row centre"}, "summary": summary, "frames": items, "outputs": {"sheet": sheet_path.as_posix(), "candidate": args.candidate_out.as_posix() if args.candidate_out else None, "frames": frame_dir.as_posix(), "closeup": (args.out_dir / "closeup.png").as_posix(), "compare": (args.out_dir / "compare.png").as_posix()}}
	(args.out_dir / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2), encoding="utf-8")
	return metrics


def parser() -> argparse.ArgumentParser:
	p = argparse.ArgumentParser(description=__doc__); source = p.add_mutually_exclusive_group(required=True)
	source.add_argument("--sheet", type=Path); source.add_argument("--frames")
	p.add_argument("--grid", type=parse_grid); p.add_argument("--pick"); p.add_argument("--bg", default="auto")
	p.add_argument("--scale-by", default="height"); p.add_argument("--palette", type=Path, required=True)
	p.add_argument("--outline", choices=("auto", "off"), default="off"); p.add_argument("--reference")
	p.add_argument("--min-component", type=int, default=0, metavar="PX", help="drop detached 4-connected output components smaller than PX pixels")
	p.add_argument("--title", default="SMASH NINE SPRITE NORMALIZATION"); p.add_argument("--out-dir", type=Path, required=True); p.add_argument("--name", required=True)
	p.add_argument("--candidate-out", type=Path, help="optional art/bakeoff/<id>/<stem>-<row>-vN.png copy")
	return p


def main(argv: Sequence[str] | None = None) -> int:
	args = parser().parse_args(argv)
	try:
		if args.sheet and args.grid is None: raise ValueError("--sheet requires --grid")
		if args.min_component < 0: raise ValueError("--min-component must be non-negative")
		metrics = normalize(args); summary = metrics["summary"]
		print(f"normalized {summary['frame_count']} frames; factor={summary['common_scale']}; height={summary['body_height_range']}; lift={summary['lift_range']}; border={summary['borders_clear']}; margin4={summary['all_have_4px_margin']}; dropped={summary['dropped_component_count']} components/{summary['dropped_component_pixels']} px")
		return 0
	except (OSError, ValueError, json.JSONDecodeError) as error:
		print(f"Error: {error}", file=sys.stderr); return 1


if __name__ == "__main__":
	raise SystemExit(main())
