"""Build the final CODEX-ART-57 Luna candidate and review artifacts."""

from __future__ import annotations

import importlib.util
import json
import statistics
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
REPORT = Path(__file__).resolve().parent
RAW = ROOT / "art/raw/walk-57/luna/normalized"
CELL = 128
SCALE = 4
FPS = 13.3
FACTORS = [0.1, 0.104167, 0.104167, 0.104167, 0.1, 0.104167, 0.104167, 0.104167]
PHASES = ["contact", "down", "passing", "up", "contact", "down", "passing", "up"]
LEGS = ["near", "near", "far", "far", "far", "far", "near", "near"]


def load_module(name: str, path: Path):
	spec = importlib.util.spec_from_file_location(name, path)
	if spec is None or spec.loader is None:
		raise RuntimeError(f"cannot load {path}")
	module = importlib.util.module_from_spec(spec)
	spec.loader.exec_module(module)
	return module


NORMALIZE = load_module("sprite_normalize", ROOT / "tools/sprite_pipeline/normalize.py")
WALK_BOB = load_module("sprite_walk_bob", ROOT / "tools/sprite_pipeline/walk_bob.py")


def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
	names = ("C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/arial.ttf") if bold else ("C:/Windows/Fonts/arial.ttf",)
	for name in names:
		try:
			return ImageFont.truetype(name, size)
		except OSError:
			pass
	return ImageFont.load_default()


def checker(size: tuple[int, int], square: int = 16) -> Image.Image:
	image = Image.new("RGBA", size, (29, 36, 51, 255))
	draw = ImageDraw.Draw(image)
	for y in range(0, size[1], square):
		for x in range(0, size[0], square):
			if (x // square + y // square) % 2:
				draw.rectangle((x, y, x + square - 1, y + square - 1), fill=(41, 49, 68, 255))
	return image


def cells(path: Path, count: int) -> list[Image.Image]:
	sheet = Image.open(path).convert("RGBA")
	return [sheet.crop((i * CELL, 0, (i + 1) * CELL, CELL)) for i in range(count)]


def frame_box(image: Image.Image) -> tuple[int, int, int, int]:
	box = image.getbbox()
	if box is None:
		raise ValueError("empty frame")
	return box


def build_costume(new: list[Image.Image]) -> None:
	idle = cells(ROOT / "art/bakeoff/luna/luna-idle-v3.png", 1)[0]
	current = cells(ROOT / "art/bakeoff/luna/luna-walk-v1.png", 1)[0]
	items = [("IDLE", idle), ("GAME WALK", current)] + [(f"F{i + 1}", frame) for i, frame in enumerate(new)]
	label_h = 38
	canvas = checker((len(items) * CELL * SCALE, CELL * SCALE + label_h), 16)
	draw = ImageDraw.Draw(canvas)
	for index, (label, frame) in enumerate(items):
		x = index * CELL * SCALE
		canvas.alpha_composite(frame.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST), (x, label_h))
		draw.rectangle((x, 0, x + CELL * SCALE - 1, label_h - 1), fill=(12, 17, 29, 255))
		draw.text((x + 10, 7), label, font=font(20, True), fill=(239, 244, 255, 255))
		if index:
			draw.line((x, 0, x, canvas.height), fill=(86, 98, 122, 255), width=2)
	canvas.convert("RGB").save(REPORT / "costume.png", optimize=True)


def reference_panels() -> list[Image.Image]:
	sheet = Image.open(REPORT / "walk_reference_luna.png").convert("RGBA")
	panels = []
	for index in range(8):
		row, column = divmod(index, 4)
		panels.append(sheet.crop((column * 512, row * 564, column * 512 + 512, row * 564 + 512)))
	return panels


def build_feet(new: list[Image.Image]) -> None:
	refs = reference_panels()
	height = 48 * SCALE
	label_h = 32
	canvas = Image.new("RGB", (8 * CELL * SCALE, label_h + 2 * height), (12, 17, 29))
	draw = ImageDraw.Draw(canvas)
	for index, (ref, frame) in enumerate(zip(refs, new)):
		x = index * CELL * SCALE
		ref_small = ref.resize((CELL, CELL), Image.Resampling.LANCZOS).crop((0, 80, CELL, CELL))
		candidate = frame.crop((0, 80, CELL, CELL))
		canvas.paste(ref_small.resize((CELL * SCALE, height), Image.Resampling.NEAREST).convert("RGB"), (x, label_h))
		large = candidate.resize((CELL * SCALE, height), Image.Resampling.NEAREST)
		canvas.paste(large.convert("RGB"), (x, label_h + height), large.getchannel("A"))
		label = f"F{index + 1} {'N' if LEGS[index] == 'near' else 'F'} {'SWING' if PHASES[index] == 'passing' else PHASES[index].upper()}"
		draw.text((x + 8, 5), label, font=font(18, True), fill=(235, 239, 248))
		if index:
			draw.line((x, 0, x, canvas.height), fill=(78, 90, 112), width=2)
	canvas.save(REPORT / "feet.png", optimize=True)


def build_compare(new: list[Image.Image]) -> None:
	current = cells(ROOT / "art/bakeoff/luna/luna-walk-v1.png", 6)
	label_w = 220
	canvas = checker((label_w + 8 * CELL * SCALE, 2 * CELL * SCALE), 16)
	draw = ImageDraw.Draw(canvas)
	for row, frames in enumerate((current, new)):
		for index, frame in enumerate(frames):
			canvas.alpha_composite(frame.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST), (label_w + index * CELL * SCALE, row * CELL * SCALE))
		draw.rectangle((0, row * CELL * SCALE, label_w - 1, (row + 1) * CELL * SCALE - 1), fill=(12, 17, 29, 255))
		draw.text((14, row * CELL * SCALE + 18), "CURRENT 6F" if row == 0 else "WALK 57 8F", font=font(24, True), fill=(239, 244, 255, 255))
	canvas.convert("RGB").save(REPORT / "compare.png", optimize=True)


def build_gif(new: list[Image.Image]) -> None:
	frames = []
	for frame in new:
		bg = checker((CELL, CELL), 8)
		bg.alpha_composite(frame)
		frames.append(bg.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST).convert("P", palette=Image.Palette.ADAPTIVE, colors=255))
	frames[0].save(REPORT / "walk.gif", save_all=True, append_images=frames[1:], duration=[80, 70] * 4, loop=0, disposal=2)


def build_bob_board(before: list[Image.Image], after: list[Image.Image], bob: dict[str, object]) -> None:
	b = [np.asarray(frame) for frame in before]
	a = [np.asarray(frame) for frame in after]
	box = tuple(int(value) for value in bob["face_box"])
	before_heads = [WALK_BOB.head_offset(b[0], frame, box)[:2] for frame in b]
	after_heads = [WALK_BOB.head_offset(b[0], frame, box)[:2] for frame in a]
	WALK_BOB.board(b, a, box, [before_heads, after_heads], REPORT / "bob.png", scale=SCALE)


def measured_frame(image: Image.Image, index: int) -> dict[str, object]:
	box = frame_box(image)
	alpha = list(image.getchannel("A").getdata())
	metric = NORMALIZE.frame_metrics(image)
	metric.update({
		"index": index,
		"bbox": list(box),
		"body_width": box[2] - box[0],
		"body_height": box[3] - box[1],
		"area": sum(1 for value in alpha if value),
		"alpha_binary": set(alpha) <= {0, 255},
		"border_clear": all(image.getpixel((x, 0))[3] == 0 and image.getpixel((x, CELL - 1))[3] == 0 for x in range(CELL)) and all(image.getpixel((0, y))[3] == 0 and image.getpixel((CELL - 1, y))[3] == 0 for y in range(CELL)),
		"margin": NORMALIZE.margins(box, CELL),
	})
	return metric


def build_metrics(before: list[Image.Image], after: list[Image.Image], bob: dict[str, object]) -> None:
	head_payload = json.loads((RAW / "head_final.json").read_text(encoding="utf-8"))
	head_scales = [item["median"] for item in head_payload]
	# Frame 6 exposes a large skin-coloured leg. The head-only diagnostic avoids that known false match.
	frame6 = json.loads((RAW / "frame-06-head-mask.json").read_text(encoding="utf-8"))[0]
	head_scales[5] = frame6["median"]
	frames = [measured_frame(frame, index) for index, frame in enumerate(after)]
	heights = [int(frame["body_height"]) for frame in frames]
	widths = [int(frame["body_width"]) for frame in frames]
	areas = [int(frame["area"]) for frame in frames]
	details = [float(frame["interior_detail"]) for frame in frames]
	payload = {
		"input": {
			"mode": "eight independent built-in image generations",
			"look_reference": "art/bakeoff/luna/luna-idle-v3.png:0",
			"costume_reference": "accepted frame 1 for frames 2-8",
			"pose_reference": "reports/codex-art-57/luna/walk_reference_luna.png",
		},
		"measured": {
			"output_size": [1024, 128],
			"frame_count": 8,
			"fps": FPS,
			"normalization_factors": FACTORS,
			"head_scale": head_scales,
			"head_scale_range": [min(head_scales), max(head_scales)],
			"head_scale_note": "Frame 6 uses a head-only diagnostic (1.00, score 0.91); exposed leg skin caused the full-frame false match.",
			"body_height_range": [min(heights), max(heights)],
			"body_width_range": [min(widths), max(widths)],
			"area_range": [min(areas), max(areas)],
			"area_spread_percent": round((max(areas) - min(areas)) / statistics.mean(areas) * 100, 2),
			"interior_detail_range": [min(details), max(details)],
			"interior_detail_mean": round(statistics.mean(details), 2),
			"remaining_spill_pixels": [frame["remaining_spill_pixels"] for frame in frames],
			"all_alpha_binary": all(bool(frame["alpha_binary"]) for frame in frames),
			"all_borders_clear": all(bool(frame["border_clear"]) for frame in frames),
			"all_have_4px_margin": all(bool(frame["margin"]["has_4px_margin"]) for frame in frames),
			"bob": bob,
		},
		"judged_at_4x": {
			"costume_per_frame": [
				{"frame": i + 1, "knee_high_purple_boots": True, "no_stripes": True, "dress_matches_idle": True, "wand_front_star_top_right": True}
				for i in range(8)
			],
			"pose_matches_mannequin": [True] * 8,
			"near_leg_in_front": [True] * 8,
			"frames_1_and_5_different_leading_leg": True,
			"frame_3_swing_foot_lifted": True,
			"frame_7_swing_foot_lifted": True,
			"wand_within_about_15_degrees": True,
			"bob_seam_mark_visible_in_legs": False,
			"reads_as_two_alternating_steps_at_13_3_fps": True,
			"jitter": False,
			"costume_flicker": False,
			"remaining_issue": "Hair tips, skirt folds, and boot highlights vary slightly between independently generated frames.",
		},
		"frames": frames,
	}
	(REPORT / "metrics.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
	REPORT.mkdir(parents=True, exist_ok=True)
	pre = RAW / "prebob.png"
	bobbed = RAW / "bobbed.png"
	before = cells(pre, 8)
	after = cells(bobbed, 8)
	bob = json.loads((RAW / "bob.json").read_text(encoding="utf-8"))
	candidate = ROOT / "art/bakeoff/luna/luna-walk-v4.png"
	candidate.parent.mkdir(parents=True, exist_ok=True)
	Image.open(bobbed).convert("RGBA").save(candidate, optimize=True)
	candidate.with_suffix(".json").write_text(
		json.dumps({"note": "회색 포즈 가이드와 대기 의상을 고정한 Luna 8프레임 2보행 후보. 보브 후처리 적용.", "fps": FPS, "frames": 8}, ensure_ascii=False, indent=2) + "\n",
		encoding="utf-8",
	)
	(REPORT / "bob.json").write_text(json.dumps(bob, indent=2) + "\n", encoding="utf-8")
	build_costume(after)
	build_feet(after)
	build_compare(after)
	build_gif(after)
	build_bob_board(before, after, bob)
	build_metrics(before, after, bob)


if __name__ == "__main__":
	main()
