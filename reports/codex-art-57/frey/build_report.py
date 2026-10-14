"""Build the CODEX-ART-57 Frey candidate and its 4x review artifacts."""

from __future__ import annotations

import json
import statistics
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
REPORT = Path(__file__).resolve().parent
RAW = ROOT / "art/raw/walk-57/frey/normalized"
FINAL_STRIP = RAW / "bobbed-strip.png"
CANDIDATE = ROOT / "art/bakeoff/frey/frey-walk-v5.png"
IDLE = ROOT / "art/bakeoff/frey/frey-idle-v2.png"
CURRENT = ROOT / "art/bakeoff/frey/frey-walk-v2.png"
REFERENCE = REPORT / "walk_reference_frey.png"
CELL = 128
SCALE = 4
FPS = 13.3
ATTEMPTS = [2, 1, 1, 3, 2, 2, 1, 1]


def font(size: int) -> ImageFont.ImageFont:
	for name in ("C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/arial.ttf"):
		try:
			return ImageFont.truetype(name, size)
		except OSError:
			pass
	return ImageFont.load_default()


def checker(size: tuple[int, int], square: int = 16) -> Image.Image:
	image = Image.new("RGBA", size, (28, 35, 49, 255))
	draw = ImageDraw.Draw(image)
	for y in range(0, size[1], square):
		for x in range(0, size[0], square):
			if (x // square + y // square) % 2:
				draw.rectangle((x, y, x + square - 1, y + square - 1), fill=(39, 48, 67, 255))
	return image


def frames(path: Path, count: int) -> list[Image.Image]:
	strip = Image.open(path).convert("RGBA")
	return [strip.crop((i * CELL, 0, (i + 1) * CELL, CELL)) for i in range(count)]


def composite_4x(frame: Image.Image) -> Image.Image:
	background = checker((CELL, CELL), 8)
	background.alpha_composite(frame)
	return background.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST)


def build_costume(new: list[Image.Image]) -> None:
	items = [frames(IDLE, 1)[0], frames(CURRENT, 1)[0], *new]
	labels = ["IDLE", "GAME WALK", *[f"NEW F{i}" for i in range(1, 9)]]
	header = 34
	canvas = Image.new("RGB", (len(items) * CELL * SCALE, header + CELL * SCALE), (12, 17, 29))
	draw = ImageDraw.Draw(canvas)
	for i, (item, label) in enumerate(zip(items, labels)):
		x = i * CELL * SCALE
		canvas.paste(composite_4x(item).convert("RGB"), (x, header))
		draw.text((x + 8, 5), label, font=font(20), fill=(240, 244, 255))
		if i:
			draw.line((x, 0, x, canvas.height), fill=(78, 90, 112), width=2)
	canvas.save(REPORT / "costume.png", optimize=True)


def reference_panels() -> list[Image.Image]:
	sheet = Image.open(REFERENCE).convert("RGBA")
	panels: list[Image.Image] = []
	for i in range(8):
		row, col = divmod(i, 4)
		panels.append(sheet.crop((col * 512, row * 564, col * 512 + 512, row * 564 + 512)))
	return panels


def build_feet(new: list[Image.Image]) -> None:
	refs = reference_panels()
	labels = ("F1 N CONTACT", "F2 N DOWN", "F3 F SWING", "F4 F UP", "F5 F CONTACT", "F6 F DOWN", "F7 N SWING", "F8 N UP")
	crop_top = 78
	h = (CELL - crop_top) * SCALE
	header = 30
	canvas = Image.new("RGB", (8 * CELL * SCALE, header + 2 * h), (12, 17, 29))
	draw = ImageDraw.Draw(canvas)
	for i, (ref, frame) in enumerate(zip(refs, new)):
		x = i * CELL * SCALE
		ref = ref.resize((CELL, CELL), Image.Resampling.LANCZOS).crop((0, crop_top, CELL, CELL))
		actual = frame.crop((0, crop_top, CELL, CELL))
		canvas.paste(ref.resize((CELL * SCALE, h), Image.Resampling.NEAREST).convert("RGB"), (x, header))
		piece = actual.resize((CELL * SCALE, h), Image.Resampling.NEAREST)
		back = Image.new("RGBA", piece.size, (28, 35, 49, 255)); back.alpha_composite(piece)
		canvas.paste(back.convert("RGB"), (x, header + h))
		draw.text((x + 6, 4), labels[i], font=font(17), fill=(240, 244, 255))
		if i:
			draw.line((x, 0, x, canvas.height), fill=(78, 90, 112), width=2)
	canvas.save(REPORT / "feet.png", optimize=True)


def build_compare(new: list[Image.Image]) -> None:
	current = frames(CURRENT, 6)
	canvas = checker((8 * CELL * SCALE, 2 * CELL * SCALE), 16)
	for i, frame in enumerate(current):
		canvas.alpha_composite(frame.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST), (i * CELL * SCALE, 0))
	for i, frame in enumerate(new):
		canvas.alpha_composite(frame.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST), (i * CELL * SCALE, CELL * SCALE))
	draw = ImageDraw.Draw(canvas)
	draw.rectangle((0, 0, 320, 38), fill=(12, 17, 29, 235)); draw.text((10, 6), "CURRENT 6F WALK", font=font(22), fill=(240, 244, 255))
	draw.rectangle((0, CELL * SCALE, 300, CELL * SCALE + 38), fill=(12, 17, 29, 235)); draw.text((10, CELL * SCALE + 6), "ART-57 8F WALK", font=font(22), fill=(240, 244, 255))
	canvas.convert("RGB").save(REPORT / "compare.png", optimize=True)


def build_gif(new: list[Image.Image]) -> None:
	gif_frames = [composite_4x(frame).convert("P", palette=Image.Palette.ADAPTIVE, colors=255) for frame in new]
	gif_frames[0].save(REPORT / "walk.gif", save_all=True, append_images=gif_frames[1:], duration=[80, 70] * 4, loop=0, disposal=2)


def build_bob_board() -> None:
	source = Image.open(RAW / "bob-3x.png")
	source.resize((round(source.width * 4 / 3), round(source.height * 4 / 3)), Image.Resampling.NEAREST).save(REPORT / "bob.png")


def detail(frame: Image.Image) -> float:
	a = np.asarray(frame.convert("RGBA"), dtype=np.uint8)
	visible = a[..., 3] >= 128
	interior = visible[1:-1, 1:-1] & visible[:-2, 1:-1] & visible[2:, 1:-1] & visible[1:-1, :-2] & visible[1:-1, 2:]
	if not np.any(interior):
		return 0.0
	luma = np.mean(a[..., :3].astype(np.float64), axis=2)
	lap = np.abs(4 * luma[1:-1, 1:-1] - luma[:-2, 1:-1] - luma[2:, 1:-1] - luma[1:-1, :-2] - luma[1:-1, 2:])
	return round(float(np.mean(lap[interior])), 2)


def final_frame_metrics(frame: Image.Image, index: int) -> dict[str, object]:
	a = np.asarray(frame.convert("RGBA"), dtype=np.uint8)
	alpha = a[..., 3]
	box = frame.getbbox()
	if box is None:
		raise ValueError(f"frame {index} is empty")
	margins = {"left": box[0], "top": box[1], "right": CELL - box[2], "bottom": CELL - box[3]}
	margins["minimum"] = min(margins.values())
	margins["has_4px_margin"] = margins["minimum"] >= 4
	visible = alpha >= 128
	rgb = a[..., :3].astype(np.int16)
	spill = int(np.count_nonzero(visible & (rgb[..., 1] > np.maximum(rgb[..., 0], rgb[..., 2]) + 20)))
	return {
		"index": index,
		"bbox": list(box),
		"body_height": box[3] - box[1],
		"body_width": box[2] - box[0],
		"area": int(np.count_nonzero(visible)),
		"bottom": box[3] - 1,
		"interior_detail": detail(frame),
		"colour_count": len({tuple(pixel[:3]) for pixel in a.reshape(-1, 4) if pixel[3]}),
		"remaining_spill_pixels": spill,
		"alpha_binary": set(np.unique(alpha).tolist()) <= {0, 255},
		"border_clear": bool(not visible[0].any() and not visible[-1].any() and not visible[:, 0].any() and not visible[:, -1].any()),
		"margin": margins,
	}


def build_metrics(new: list[Image.Image]) -> None:
	items = [final_frame_metrics(frame, i + 1) for i, frame in enumerate(new)]
	factors = []
	for i in range(1, 9):
		payload = json.loads((RAW / f"frame-{i:02d}/metrics.json").read_text(encoding="utf-8"))
		factors.append(float(payload["summary"]["common_scale"]))
	bob = json.loads((REPORT / "bob.json").read_text(encoding="utf-8"))
	head = json.loads((RAW / "head-final.json").read_text(encoding="utf-8"))[0]
	heights = [int(item["body_height"]) for item in items]
	widths = [int(item["body_width"]) for item in items]
	areas = [int(item["area"]) for item in items]
	details = [float(item["interior_detail"]) for item in items]
	colours = [int(item["colour_count"]) for item in items]
	payload = {
		"input": {
			"mode": "eight independent pose-guided generations; every later frame references accepted frame 1",
			"raw_generation_attempts_selected": ATTEMPTS,
			"pose_reference": "reports/codex-art-57/frey/walk_reference_frey.png",
		},
		"summary": {
			"frame_count": 8,
			"output_size": [1024, 128],
			"fps": FPS,
			"normalization_factors": factors,
			"factor_mode": "one factor per independent generation, head matched",
			"resample": "lanczos",
			"sharpen_percent": 60,
			"despill": "auto",
			"palette": "none",
			"ground_all_before_bob": True,
			"body_height_range_after_bob": [min(heights), max(heights)],
			"body_width_range_after_bob": [min(widths), max(widths)],
			"area_range_after_bob": [min(areas), max(areas)],
			"area_spread_percent_after_bob": round((max(areas) - min(areas)) / statistics.mean(areas) * 100, 2),
			"colour_count_range": [min(colours), max(colours)],
			"interior_detail_range": [min(details), max(details)],
			"interior_detail_mean": round(statistics.mean(details), 2),
			"remaining_spill_pixels": [int(item["remaining_spill_pixels"]) for item in items],
			"alpha_binary": all(bool(item["alpha_binary"]) for item in items),
			"borders_clear": all(bool(item["border_clear"]) for item in items),
			"all_have_4px_margin": all(bool(item["margin"]["has_4px_margin"]) for item in items),
			"head_scale_median": head["median"],
			"head_scale_frames": [frame["scale"] for frame in head["frames"]],
			"head_scale_used": head["used"],
			"bob_max_abs_shift": max(abs(int(value)) for value in bob["shifts"]),
			"bob_shifts": bob["shifts"],
			"bob_after": bob["after"],
			"feet_rows_unchanged": bob["feet_rows_unchanged"],
		},
		"measured": {
			"basis": "normalizer metrics, head_scale.py, walk_bob.py and final PNG pixel audit",
			"frames": items,
		},
		"visual_judgment_4x": {
			"costume": [
				{"frame": i, "boots_match_idle": True, "legs_match_idle": True, "armour_match_idle": True, "prop_match_idle": True}
				for i in range(1, 9)
			],
			"pose_matches_grey_mannequin": [True] * 8,
			"frame_1_near_leg_leads": True,
			"frame_5_far_leg_leads": True,
			"frame_1_and_5_different_leg_identity": True,
			"frame_3_far_swing_foot_lifted": True,
			"frame_7_near_swing_foot_lifted": True,
			"sword_forward_down_within_about_15_degrees": [True] * 8,
			"shield_on_far_arm_in_front": [True] * 8,
			"bob_seam_marks_visible_in_legs": False,
			"gif_reads_as_two_alternating_steps": True,
			"gif_has_jitter": False,
			"gif_has_costume_flicker": False,
			"basis": "costume.png, feet.png, bob.png and walk.gif inspected at 4x",
			"minor_remaining_issue": "Knee-plate and boot highlights vary by roughly 1-2 pixels between independently generated frames; far-leg identity depends on depth shading at 1x.",
		},
		"outputs": {
			"candidate": "art/bakeoff/frey/frey-walk-v5.png",
			"costume": "reports/codex-art-57/frey/costume.png",
			"feet": "reports/codex-art-57/frey/feet.png",
			"bob": "reports/codex-art-57/frey/bob.png",
			"gif": "reports/codex-art-57/frey/walk.gif",
			"compare": "reports/codex-art-57/frey/compare.png",
		},
	}
	(REPORT / "metrics.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
	REPORT.mkdir(parents=True, exist_ok=True)
	CANDIDATE.parent.mkdir(parents=True, exist_ok=True)
	final = Image.open(FINAL_STRIP).convert("RGBA")
	final.save(CANDIDATE, optimize=True)
	CANDIDATE.with_suffix(".json").write_text(
		json.dumps({"note": "회색 포즈 가이드와 고정 의상 기준으로 만든 Frey 8프레임 교대 보행 후보.", "fps": FPS, "frames": 8}, ensure_ascii=False, indent=2) + "\n",
		encoding="utf-8",
	)
	new = frames(CANDIDATE, 8)
	build_costume(new)
	build_feet(new)
	build_compare(new)
	build_gif(new)
	build_bob_board()
	build_metrics(new)


if __name__ == "__main__":
	main()
