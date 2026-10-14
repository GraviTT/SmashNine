"""Assemble and review the CODEX-ART-58 Frey walk candidate."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
REPORT = Path(__file__).resolve().parent
RAW = ROOT / "art/raw/walk-58/frey"
BASE_PREBOB = ROOT / "art/raw/walk-57/frey/normalized/selected-strip.png"
PREBOB = RAW / "normalized/prebob-strip.png"
BOBBED = RAW / "normalized/bobbed-strip.png"
BOB_BOARD = RAW / "normalized/bob-3x.png"
FRAME_3 = RAW / "normalized/frame-03-a3/frames/frey-frame-03-a3-00.png"
FRAME_7 = RAW / "normalized/frame-07-a1/frames/frey-frame-07-a1-00.png"
CANDIDATE = ROOT / "art/bakeoff/frey/frey-walk-v6.png"
IDLE = ROOT / "art/bakeoff/frey/frey-idle-v2.png"
GAME_WALK = ROOT / "art/bakeoff/frey/frey-walk-v2.png"
CELL = 128
SCALE = 4
FPS = 13.3


def font(size: int) -> ImageFont.ImageFont:
	for name in ("C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/arial.ttf"):
		try:
			return ImageFont.truetype(name, size)
		except OSError:
			pass
	return ImageFont.load_default()


def frames(path: Path, count: int | None = None) -> list[Image.Image]:
	strip = Image.open(path).convert("RGBA")
	if count is None:
		count = strip.width // CELL
	return [strip.crop((i * CELL, 0, (i + 1) * CELL, CELL)) for i in range(count)]


def checker(size: tuple[int, int], square: int = 8) -> Image.Image:
	image = Image.new("RGBA", size, (28, 35, 49, 255))
	draw = ImageDraw.Draw(image)
	for y in range(0, size[1], square):
		for x in range(0, size[0], square):
			if (x // square + y // square) % 2:
				draw.rectangle((x, y, x + square - 1, y + square - 1), fill=(39, 48, 67, 255))
	return image


def composite_4x(frame: Image.Image) -> Image.Image:
	background = checker((CELL, CELL))
	background.alpha_composite(frame)
	return background.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST)


def prepare() -> None:
	RAW.joinpath("normalized").mkdir(parents=True, exist_ok=True)
	base = frames(BASE_PREBOB, 8)
	base[2] = Image.open(FRAME_3).convert("RGBA")
	base[6] = Image.open(FRAME_7).convert("RGBA")
	strip = Image.new("RGBA", (8 * CELL, CELL))
	for index, frame in enumerate(base):
		strip.alpha_composite(frame, (index * CELL, 0))
	strip.save(PREBOB, optimize=True)


def build_costume(final: list[Image.Image]) -> None:
	items = [frames(IDLE, 1)[0], frames(GAME_WALK, 1)[0], *final]
	labels = ["IDLE", "GAME WALK", *[f"NEW F{i}" for i in range(1, 9)]]
	header = 34
	canvas = Image.new("RGB", (len(items) * CELL * SCALE, header + CELL * SCALE), (12, 17, 29))
	draw = ImageDraw.Draw(canvas)
	for index, (item, label) in enumerate(zip(items, labels)):
		x = index * CELL * SCALE
		canvas.paste(composite_4x(item).convert("RGB"), (x, header))
		draw.text((x + 8, 5), label, font=font(20), fill=(240, 244, 255))
		if index:
			draw.line((x, 0, x, canvas.height), fill=(78, 90, 112), width=2)
	canvas.save(REPORT / "costume.png", optimize=True)


def build_gif(final: list[Image.Image]) -> None:
	gif_frames = [composite_4x(frame).convert("P", palette=Image.Palette.ADAPTIVE, colors=255) for frame in final]
	gif_frames[0].save(
		REPORT / "walk.gif",
		save_all=True,
		append_images=gif_frames[1:],
		duration=[80, 70] * (len(gif_frames) // 2),
		loop=0,
		disposal=2,
	)


def build_bob_board() -> None:
	board = Image.open(BOB_BOARD)
	board.resize((round(board.width * 4 / 3), round(board.height * 4 / 3)), Image.Resampling.NEAREST).save(
		REPORT / "bob.png", optimize=True
	)


def pixel_metrics(frame: Image.Image, index: int) -> dict[str, object]:
	a = np.asarray(frame.convert("RGBA"), dtype=np.uint8)
	visible = a[..., 3] >= 128
	box = frame.getbbox()
	if box is None:
		raise ValueError(f"frame {index} is empty")
	rgb = a[..., :3].astype(np.int16)
	spill = int(np.count_nonzero(visible & (rgb[..., 1] > np.maximum(rgb[..., 0], rgb[..., 2]) + 20)))
	margins = [box[0], box[1], CELL - box[2], CELL - box[3]]
	interior = visible[1:-1, 1:-1] & visible[:-2, 1:-1] & visible[2:, 1:-1] & visible[1:-1, :-2] & visible[1:-1, 2:]
	luma = np.mean(a[..., :3].astype(np.float64), axis=2)
	lap = np.abs(4 * luma[1:-1, 1:-1] - luma[:-2, 1:-1] - luma[2:, 1:-1] - luma[1:-1, :-2] - luma[1:-1, 2:])
	return {
		"frame": index,
		"bbox": list(box),
		"body_width": box[2] - box[0],
		"body_height": box[3] - box[1],
		"area": int(np.count_nonzero(visible)),
		"interior_detail": round(float(np.mean(lap[interior])), 2) if np.any(interior) else 0.0,
		"minimum_margin": min(margins),
		"border_clear": bool(not visible[0].any() and not visible[-1].any() and not visible[:, 0].any() and not visible[:, -1].any()),
		"alpha_binary": set(np.unique(a[..., 3]).tolist()) <= {0, 255},
		"remaining_spill_pixels": spill,
	}


def build_measurements(final: list[Image.Image]) -> None:
	frame_3_metrics = json.loads((RAW / "normalized/frame-03-a3/metrics.json").read_text(encoding="utf-8"))
	frame_7_metrics = json.loads((RAW / "normalized/frame-07-a1/metrics.json").read_text(encoding="utf-8"))
	frame_3_head = json.loads((RAW / "normalized/frame-03-a3/head-scale.json").read_text(encoding="utf-8"))[0]
	frame_7_head = json.loads((RAW / "normalized/frame-07-a1/head-scale.json").read_text(encoding="utf-8"))[0]
	feet = json.loads((REPORT / "feet.json").read_text(encoding="utf-8"))
	bob = json.loads((REPORT / "bob.json").read_text(encoding="utf-8"))
	pixel_audit = [pixel_metrics(frame, index + 1) for index, frame in enumerate(final)]
	payload = {
		"output": {"size": [8 * CELL, CELL], "frames": 8, "fps": FPS},
		"selected_attempts": {"frame_3": 3, "frame_7": 1},
		"new_frame_normalization": {
			"frame_3": {
				"factor": frame_3_metrics["summary"]["common_scale"],
				"head_scale": frame_3_head["median"],
				"detail": frame_3_metrics["summary"]["interior_detail_mean"],
			},
			"frame_7": {
				"factor": frame_7_metrics["summary"]["common_scale"],
				"head_scale": frame_7_head["median"],
				"detail": frame_7_metrics["summary"]["interior_detail_mean"],
			},
		},
		"planted_feet": feet,
		"bob": bob,
		"final_summary": {
			"detail_range": [min(item["interior_detail"] for item in pixel_audit), max(item["interior_detail"] for item in pixel_audit)],
			"minimum_margin": min(item["minimum_margin"] for item in pixel_audit),
			"all_borders_clear": all(item["border_clear"] for item in pixel_audit),
			"all_alpha_binary": all(item["alpha_binary"] for item in pixel_audit),
			"remaining_spill_pixels": [item["remaining_spill_pixels"] for item in pixel_audit],
		},
		"pixel_audit": pixel_audit,
	}
	(REPORT / "measurements.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def finalize() -> None:
	REPORT.mkdir(parents=True, exist_ok=True)
	CANDIDATE.parent.mkdir(parents=True, exist_ok=True)
	final_strip = Image.open(BOBBED).convert("RGBA")
	if final_strip.size != (8 * CELL, CELL):
		raise ValueError(f"unexpected final size: {final_strip.size}")
	final_strip.save(CANDIDATE, optimize=True)
	CANDIDATE.with_suffix(".json").write_text(
		json.dumps(
			{"note": "통과 자세 3·7번의 발이 지지발 발목 옆을 지나도록 다시 그린 Frey 8프레임 걷기 후보.", "fps": FPS, "frames": 8},
			ensure_ascii=False,
			indent=2,
		) + "\n",
		encoding="utf-8",
	)
	final = frames(CANDIDATE, 8)
	build_costume(final)
	build_gif(final)
	build_bob_board()
	build_measurements(final)


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--prepare", action="store_true", help="assemble the pre-bob strip only")
	args = parser.parse_args()
	if args.prepare:
		prepare()
	else:
		finalize()


if __name__ == "__main__":
	main()
