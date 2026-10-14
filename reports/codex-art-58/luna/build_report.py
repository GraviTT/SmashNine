"""Build the CODEX-ART-58 Luna candidate and 4x review artifacts."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
REPORT = Path(__file__).resolve().parent
RAW = ROOT / "art/raw/walk-58/luna/normalized"
CELL = 128
SCALE = 4
FPS = 13.3


def load_module(name: str, path: Path):
	spec = importlib.util.spec_from_file_location(name, path)
	if spec is None or spec.loader is None:
		raise RuntimeError(f"cannot load {path}")
	module = importlib.util.module_from_spec(spec)
	spec.loader.exec_module(module)
	return module


WALK_BOB = load_module("sprite_walk_bob_58", ROOT / "tools/sprite_pipeline/walk_bob.py")
WALK_FEET = load_module("sprite_walk_feet_58", ROOT / "tools/sprite_pipeline/walk_feet.py")
NORMALIZE = load_module("sprite_normalize_58", ROOT / "tools/sprite_pipeline/normalize.py")


def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
	paths = ("C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/arial.ttf") if bold else ("C:/Windows/Fonts/arial.ttf",)
	for path in paths:
		try:
			return ImageFont.truetype(path, size)
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


def cells(path: Path, count: int = 8) -> list[Image.Image]:
	sheet = Image.open(path).convert("RGBA")
	return [sheet.crop((i * CELL, 0, (i + 1) * CELL, CELL)) for i in range(count)]


def build_costume(frames: list[Image.Image]) -> None:
	idle = cells(ROOT / "art/bakeoff/luna/luna-idle-v3.png", 1)[0]
	game_walk = cells(ROOT / "art/bakeoff/luna/luna-walk-v1.png", 1)[0]
	items = [("IDLE", idle), ("GAME WALK", game_walk)] + [(f"F{i + 1}", frame) for i, frame in enumerate(frames)]
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


def build_gif(frames: list[Image.Image]) -> None:
	gif_frames = []
	for frame in frames:
		background = checker((CELL, CELL), 8)
		background.alpha_composite(frame)
		gif_frames.append(background.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST).convert("P", palette=Image.Palette.ADAPTIVE, colors=255))
	gif_frames[0].save(REPORT / "walk.gif", save_all=True, append_images=gif_frames[1:], duration=[80, 70] * 4, loop=0, disposal=2)


def build_bob_board(before: list[Image.Image], after: list[Image.Image], bob: dict[str, object]) -> None:
	b = [np.asarray(frame) for frame in before]
	a = [np.asarray(frame) for frame in after]
	box = tuple(int(value) for value in bob["face_box"])
	before_heads = [WALK_BOB.head_offset(b[0], frame, box)[:2] for frame in b]
	after_heads = [WALK_BOB.head_offset(b[0], frame, box)[:2] for frame in a]
	WALK_BOB.board(b, a, box, [before_heads, after_heads], REPORT / "bob.png", scale=SCALE)


def build_feet(frames: list[Image.Image]) -> None:
	arrays = [np.asarray(frame) for frame in frames]
	feet = [WALK_FEET.feet(frame[..., 3] > 0) for frame in arrays]
	(REPORT / "feet.json").write_text(json.dumps(feet, indent=1) + "\n", encoding="utf-8")
	WALK_FEET.onion(arrays, 80, REPORT / "onion.png", scale=SCALE)


def build_metrics(candidate: Path, bob: dict[str, object]) -> None:
	f3 = json.loads((RAW / "frame-03-gen-1/metrics.json").read_text(encoding="utf-8"))
	f7 = json.loads((RAW / "frame-07-gen-2/metrics.json").read_text(encoding="utf-8"))
	h3 = json.loads((RAW / "head-final.json").read_text(encoding="utf-8"))[0]
	h7 = json.loads((RAW / "frame-07-gen-2-head-final.json").read_text(encoding="utf-8"))[0]
	feet = json.loads((REPORT / "feet.json").read_text(encoding="utf-8"))
	image = Image.open(candidate)
	final_frames = cells(candidate)
	final_metrics = [NORMALIZE.frame_metrics(frame) for frame in final_frames]
	bboxes = [frame.getbbox() for frame in final_frames]
	alpha_values = [set(np.unique(np.asarray(frame.getchannel("A"))).tolist()) for frame in final_frames]
	border_clear = [
		all(frame.getpixel((x, 0))[3] == 0 and frame.getpixel((x, CELL - 1))[3] == 0 for x in range(CELL))
		and all(frame.getpixel((0, y))[3] == 0 and frame.getpixel((CELL - 1, y))[3] == 0 for y in range(CELL))
		for frame in final_frames
	]
	margins = [NORMALIZE.margins(box, CELL) for box in bboxes if box is not None]
	payload = {
		"measured": {
			"output_size": list(image.size),
			"frames": 8,
			"fps": FPS,
			"generated_attempts": {"frame_3": 1, "frame_7": 2},
			"normalization_factor": {"frame_3": f3["summary"]["common_scale"], "frame_7": f7["summary"]["common_scale"]},
			"head_scale": {"frame_3": h3["median"], "frame_7": h7["median"]},
			"body_height": {"frame_3": f3["summary"]["body_height_range"][0], "frame_7": f7["summary"]["body_height_range"][0]},
			"interior_detail": {"frame_3": f3["summary"]["interior_detail_mean"], "frame_7": f7["summary"]["interior_detail_mean"]},
			"remaining_spill_pixels": {"frame_3": f3["summary"]["remaining_spill_pixels"][0], "frame_7": f7["summary"]["remaining_spill_pixels"][0]},
			"border_clear": {"frame_3": f3["summary"]["borders_clear"], "frame_7": f7["summary"]["borders_clear"]},
			"margin_4px": {"frame_3": f3["summary"]["all_have_4px_margin"], "frame_7": f7["summary"]["all_have_4px_margin"]},
			"final_strip_checks": {
				"interior_detail_range": [min(metric["interior_detail"] for metric in final_metrics), max(metric["interior_detail"] for metric in final_metrics)],
				"remaining_spill_pixels": [metric["remaining_spill_pixels"] for metric in final_metrics],
				"all_alpha_binary": all(values <= {0, 255} for values in alpha_values),
				"all_borders_clear": all(border_clear),
				"all_have_4px_margin": all(margin["has_4px_margin"] for margin in margins),
			},
			"planted_feet": {
				"frame_3": {"count": len(feet[2]), "centre": feet[2][0]["centre"], "target": 67, "tolerance": 6},
				"frame_7": {"count": len(feet[6]), "centre": feet[6][0]["centre"], "target": 68, "tolerance": 6},
			},
			"bob": bob,
		},
		"judged_at_4x": {
			"passing_feet_beside_standing_ankle": {"frame_3": True, "frame_7": True},
			"no_corresponding_foot_moves_over_25px": True,
			"swinging_leg_visibly_passes_standing_leg": {"frame_3": True, "frame_7": True},
			"knee_high_purple_boots_no_stripes": True,
			"dress_matches_idle": True,
			"wand_front_star_top_right": True,
			"bob_seam_visible": False,
			"reads_as_two_alternating_steps_at_13_3_fps": True,
			"remaining_issue": "독립 생성한 3·7번은 머리카락 끝, 치마 주름, 부츠 하이라이트와 완드 각도가 인접 프레임과 조금 다르다.",
		},
	}
	(REPORT / "metrics.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
	REPORT.mkdir(parents=True, exist_ok=True)
	prebob = RAW / "prebob.png"
	bobbed = RAW / "bobbed.png"
	before = cells(prebob)
	after = cells(bobbed)
	bob = json.loads((RAW / "bob.json").read_text(encoding="utf-8"))

	candidate = ROOT / "art/bakeoff/luna/luna-walk-v5.png"
	candidate.parent.mkdir(parents=True, exist_ok=True)
	Image.open(bobbed).convert("RGBA").save(candidate, optimize=True)
	candidate.with_suffix(".json").write_text(
		json.dumps({"note": "3·7번을 진짜 passing pose로 다시 그린 Luna 8프레임 보행 후보. 보브 후처리 적용.", "fps": FPS, "frames": 8}, ensure_ascii=False, indent=2) + "\n",
		encoding="utf-8",
	)
	(REPORT / "bob.json").write_text(json.dumps(bob, indent=2) + "\n", encoding="utf-8")
	build_costume(after)
	build_bob_board(before, after, bob)
	build_feet(after)
	build_gif(after)
	build_metrics(candidate, bob)


if __name__ == "__main__":
	main()
