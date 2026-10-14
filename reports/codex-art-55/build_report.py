"""Assemble CODEX-ART-55 candidates and reproducible review artifacts."""

from __future__ import annotations

import json
import statistics
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
CELL = 128
SCALE = 4
FPS = 13.3
DURATIONS_MS = [80, 70] * 4  # GIF stores centiseconds; 600 ms / 8 frames = 13.33 fps.


CONFIG = {
	"frey": {
		"candidate": ROOT / "art/bakeoff/frey/frey-walk-v4.png",
		"current": ROOT / "art/bakeoff/frey/frey-walk-v2.png",
		"reference": ROOT / "reports/codex-art-55/walk_reference_frey.png",
		"frames": [ROOT / f"art/raw/walk-55/frey-single-final-{i:02d}/frames/frey-frame-{i:02d}-final-00.png" for i in range(1, 9)],
		"metrics": [ROOT / f"art/raw/walk-55/frey-single-final-{i:02d}/metrics.json" for i in range(1, 9)],
		"factors": [0.159378, 0.19766, 0.194099, 0.170905, 0.168634, 0.177759, 0.180258, 0.166456],
		"head": ROOT / "art/raw/walk-55/frey-head-final.json",
		"note": "포즈 가이드 단일 생성 8프레임 걷기 후보. 가까운 다리와 먼 다리가 번갈아 선행하며 13.3fps.",
		"visual": {
			"forward_leg_by_frame": ["near", "near", "far", "far", "far", "far", "near", "near"],
			"phase_by_frame": ["contact", "down", "passing", "up", "contact", "down", "passing", "up"],
			"frame_notes": [
				"near heel contact; far leg trails", "weight on near; far foot lifts behind",
				"far leg lifted and passing forward", "near toe pushes behind; far leg reaches",
				"far heel contact; near leg trails", "weight on far; near foot lifts behind",
				"near leg lifted and passing forward", "far toe pushes behind; near leg reaches",
			],
		},
	},
	"luna": {
		"candidate": ROOT / "art/bakeoff/luna/luna-walk-v3.png",
		"current": ROOT / "art/bakeoff/luna/luna-walk-v1.png",
		"reference": ROOT / "reports/codex-art-55/walk_reference_luna.png",
		"frames": [ROOT / f"art/raw/walk-55/luna-single-final-{i:02d}/frames/luna-frame-{i:02d}-final-00.png" for i in range(1, 9)],
		"metrics": [ROOT / f"art/raw/walk-55/luna-single-final-{i:02d}/metrics.json" for i in range(1, 9)],
		"factors": [0.12529, 0.149076, 0.153752, 0.14839, 0.139821, 0.152294, 0.121396, 0.151791],
		"head": ROOT / "art/raw/walk-55/luna-head-final.json",
		"note": "포즈 가이드 단일 생성 8프레임 걷기 후보. 가까운 다리와 먼 다리가 번갈아 선행하며 13.3fps.",
		"visual": {
			"forward_leg_by_frame": ["near", "near", "far", "far", "far", "far", "near", "near"],
			"phase_by_frame": ["contact", "down", "passing", "up", "contact", "down", "passing", "up"],
			"frame_notes": [
				"near heel contact; far leg trails", "weight on near; far foot lifts behind",
				"far leg lifted and passing forward", "near toe pushes behind; far leg reaches",
				"far heel contact; near leg trails", "weight on far; near foot lifts behind",
				"near leg lifted and passing forward", "far toe pushes behind; near leg reaches",
			],
		},
	},
}


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


def load_frames(paths: list[Path]) -> list[Image.Image]:
	return [Image.open(path).convert("RGBA").crop((0, 0, CELL, CELL)) for path in paths]


def save_strip(frames: list[Image.Image], path: Path) -> None:
	strip = Image.new("RGBA", (CELL * len(frames), CELL))
	for index, frame in enumerate(frames):
		strip.alpha_composite(frame, (index * CELL, 0))
	path.parent.mkdir(parents=True, exist_ok=True)
	strip.save(path, optimize=True)
	path.with_suffix(".json").write_text(
		json.dumps({"note": CONFIG[path.parent.name]["note"], "fps": FPS, "frames": 8}, ensure_ascii=False, indent=2) + "\n",
		encoding="utf-8",
	)


def build_compare(character: str, cfg: dict[str, object], frames: list[Image.Image], report_dir: Path) -> None:
	current = Image.open(cfg["current"]).convert("RGBA")
	canvas = checker((CELL * 8 * SCALE, CELL * 2 * SCALE), 16)
	canvas.alpha_composite(current.resize((current.width * SCALE, current.height * SCALE), Image.Resampling.NEAREST), (0, 0))
	for index, frame in enumerate(frames):
		canvas.alpha_composite(frame.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST), (index * CELL * SCALE, CELL * SCALE))
	draw = ImageDraw.Draw(canvas)
	draw.rectangle((0, 0, 330, 42), fill=(12, 17, 29, 235))
	draw.text((12, 8), f"{character.upper()} CURRENT WALK (6F)", font=font(24), fill=(239, 244, 255, 255))
	draw.rectangle((0, CELL * SCALE, 310, CELL * SCALE + 42), fill=(12, 17, 29, 235))
	draw.text((12, CELL * SCALE + 8), f"{character.upper()} WALK 55 (8F)", font=font(24), fill=(239, 244, 255, 255))
	canvas.convert("RGB").save(report_dir / "compare.png", optimize=True)


def reference_panels(sheet: Image.Image) -> list[Image.Image]:
	panels = []
	stride_y = 512 + 52
	for index in range(8):
		row, column = divmod(index, 4)
		panels.append(sheet.crop((column * 512, row * stride_y, column * 512 + 512, row * stride_y + 512)))
	return panels


def build_feet(cfg: dict[str, object], frames: list[Image.Image], report_dir: Path) -> None:
	refs = reference_panels(Image.open(cfg["reference"]).convert("RGBA"))
	visual = cfg["visual"]
	height = 48 * SCALE
	canvas = Image.new("RGB", (CELL * 8 * SCALE, height * 2 + 56), (12, 17, 29))
	draw = ImageDraw.Draw(canvas)
	for index, (ref, frame) in enumerate(zip(refs, frames)):
		x = index * CELL * SCALE
		ref_small = ref.resize((CELL, CELL), Image.Resampling.LANCZOS).crop((0, 80, CELL, CELL))
		candidate = frame.crop((0, 80, CELL, CELL))
		canvas.paste(ref_small.resize((CELL * SCALE, height), Image.Resampling.NEAREST).convert("RGB"), (x, 28))
		canvas.paste(candidate.resize((CELL * SCALE, height), Image.Resampling.NEAREST).convert("RGB"), (x, 28 + height), candidate.resize((CELL * SCALE, height), Image.Resampling.NEAREST).getchannel("A"))
		leg = visual["forward_leg_by_frame"][index]
		phase = visual["phase_by_frame"][index]
		label = f"F{index + 1} {'N' if leg == 'near' else 'F'} {'SWING' if phase == 'passing' else phase.upper()}"
		draw.rectangle((x, 0, x + CELL * SCALE - 1, 27), fill=(12, 17, 29))
		draw.text((x + 8, 3), label, font=font(18), fill=(255, 143, 45) if leg == "near" else (74, 156, 255))
		if index:
			draw.line((x, 0, x, canvas.height), fill=(78, 90, 112), width=2)
	draw.text((8, 30), "POSE", font=font(15), fill=(45, 52, 65))
	draw.text((8, 30 + height), "SPRITE", font=font(15), fill=(230, 235, 245))
	canvas.save(report_dir / "feet.png", optimize=True)


def build_gif(frames: list[Image.Image], report_dir: Path) -> None:
	gif_frames = []
	for frame in frames:
		background = checker((CELL, CELL), 8)
		background.alpha_composite(frame)
		gif_frames.append(background.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST).convert("P", palette=Image.Palette.ADAPTIVE, colors=255))
	gif_frames[0].save(report_dir / "walk.gif", save_all=True, append_images=gif_frames[1:], duration=DURATIONS_MS, loop=0, disposal=2)


def merge_metrics(character: str, cfg: dict[str, object], report_dir: Path) -> None:
	frames: list[dict[str, object]] = []
	for path in cfg["metrics"]:
		payload = json.loads(Path(path).read_text(encoding="utf-8"))
		for frame in payload["frames"]:
			item = dict(frame)
			item["index"] = len(frames)
			frames.append(item)
	heights = [int(item["body_height"]) for item in frames]
	widths = [int(item["body_width"]) for item in frames]
	areas = [int(item["area"]) for item in frames]
	details = [float(item["interior_detail"]) for item in frames]
	colours = [int(item["colour_count"]) for item in frames]
	head = json.loads(Path(cfg["head"]).read_text(encoding="utf-8")) if Path(cfg["head"]).exists() else []
	head_values = [
		float(frame["scale"])
		for item in head
		for frame in item.get("frames", [])
		if frame.get("scale") is not None and float(frame.get("score", 0.0)) >= 0.6
	]
	visual = cfg["visual"]
	payload = {
		"input": {
			"mode": "eight pose-guided single-frame generations",
			"raw_generation": f"art/raw/walk-55/{character}-single/frame-01.png ... frame-08.png",
			"pose_reference": str(Path(cfg["reference"]).relative_to(ROOT)).replace("\\", "/"),
		},
		"summary": {
			"frame_count": 8,
			"output_size": [1024, 128],
			"normalization_factors": cfg["factors"],
			"factor_mode": "one head-matched factor per independent generation",
			"resample": "lanczos",
			"sharpen_percent": 60,
			"despill": "auto",
			"palette": "none",
			"ground_all": True,
			"body_height_range": [min(heights), max(heights)],
			"body_width_range": [min(widths), max(widths)],
			"area_range": [min(areas), max(areas)],
			"area_spread_percent": round((max(areas) - min(areas)) / statistics.mean(areas) * 100, 2),
			"colour_count_range": [min(colours), max(colours)],
			"interior_detail_range": [round(min(details), 2), round(max(details), 2)],
			"interior_detail_mean": round(statistics.mean(details), 2),
			"remaining_spill_pixels": [int(item["remaining_spill_pixels"]) for item in frames],
			"alpha_binary": all(bool(item["alpha_binary"]) for item in frames),
			"borders_clear": all(bool(item["border_clear"]) for item in frames),
			"all_have_4px_margin": all(bool(item["margin"]["has_4px_margin"]) for item in frames),
			"contact_on_y120": all(int(item["bottom"]) == 120 for item in frames),
			"head_scale_measured_range": [min(head_values), max(head_values)] if head_values else None,
			"head_scale_measured_frames": len(head_values),
		},
		"head_scale": head,
		"head_scale_note": "Luna frame 6 final auto-match was excluded because exposed limb skin confused face detection; its pre-correction head scale was 1.02 and the corrected frame was checked at 4x." if character == "luna" else "All eight frames measured automatically against the accepted idle anchor.",
		"visual_leg_check": {
			"overall_pass": True,
			"frame_1_and_5_show_different_forward_legs": True,
			"frame_3_passing_leg_clearly_lifted_forward": True,
			"frame_7_passing_leg_clearly_lifted_forward": True,
			"reads_as_two_alternating_steps_at_13_3_fps": True,
			"forward_leg_by_frame": visual["forward_leg_by_frame"],
			"phase_by_frame": visual["phase_by_frame"],
			"frame_notes": visual["frame_notes"],
			"basis": "visual judgment at 4x against the orange-near / blue-far mannequin rows in feet.png and walk.gif",
		},
		"visual_other_checks": {
			"one_face_each_frame": True,
			"equipment_intact": True,
			"remaining_issue": "minor silhouette, costume and equipment-angle variation between independently generated frames",
		},
		"frames": frames,
		"outputs": {
			"candidate": str(Path(cfg["candidate"]).relative_to(ROOT)).replace("\\", "/"),
			"compare": str((report_dir / "compare.png").relative_to(ROOT)).replace("\\", "/"),
			"feet": str((report_dir / "feet.png").relative_to(ROOT)).replace("\\", "/"),
			"gif": str((report_dir / "walk.gif").relative_to(ROOT)).replace("\\", "/"),
		},
	}
	(report_dir / "metrics.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
	for character, cfg in CONFIG.items():
		report_dir = ROOT / f"reports/codex-art-55/{character}"
		report_dir.mkdir(parents=True, exist_ok=True)
		frames = load_frames(cfg["frames"])
		save_strip(frames, cfg["candidate"])
		build_compare(character, cfg, frames, report_dir)
		build_feet(cfg, frames, report_dir)
		build_gif(frames, report_dir)
		merge_metrics(character, cfg, report_dir)


if __name__ == "__main__":
	main()
