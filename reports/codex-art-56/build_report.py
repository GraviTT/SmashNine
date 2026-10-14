"""Build CODEX-ART-56 diagnostics from the selected normalized frames."""

from __future__ import annotations

import json
import statistics
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
CELL = 128
SCALE = 4
FPS = 13.3
TARGET = [0, 2, -1, -2, 0, 2, -1, -2]
PHASES = ["contact", "down", "passing", "up", "contact", "down", "passing", "up"]

CONFIG = {
	"frey": {
		"start": ROOT / "art/bakeoff/frey/frey-walk-v4.png",
		"reference": ROOT / "reports/codex-art-55/walk_reference_frey.png",
		"frames": [ROOT / f"art/raw/walk-56/frey-final-{i:02d}/frames/frey-final-{i:02d}-00.png" for i in range(1, 9)],
		"metric_paths": [ROOT / f"art/raw/walk-56/frey-final-{i:02d}/metrics.json" for i in range(1, 9)],
		"head_path": ROOT / "art/raw/walk-56/frey-head-best.json",
		"factors": [0.159378, 0.155, 0.159776, 0.160573, 0.159378, 0.159378, 0.160972, 0.162566],
		"eye_centres": [(82.5, 39.8), (82.0, 42.83), (82.86, 40.0), (83.17, 40.33), (82.33, 42.83), (82.75, 42.75), (81.8, 39.4), (82.2, 38.2)],
		"landmark": "파란 홍채의 4방향 연결 성분 중심(피부 영역 안, 머리띠·망토의 파란색 제외)",
		"visual": {
			"equipment_pass": True,
			"equipment_note": "4배 육안: 검은 8칸 모두 전방-아래를 향하고 약 15도 안에서 유지되며 방패는 먼 팔 앞에 남는다.",
			"leg_pass": True,
			"leg_note": "4배 육안: 1/5번은 서로 다른 다리가 선행하고 3/7번 스윙 발이 지면에서 분리된다.",
			"smooth_pass": False,
			"smooth_note": "13.3fps 육안: 4번에서 충분히 올라가지 않고 5번에서 약 3px 내려가 한 번 크게 튄다.",
		},
	},
	"luna": {
		"start": ROOT / "art/bakeoff/luna/luna-walk-v3.png",
		"reference": ROOT / "reports/codex-art-55/walk_reference_luna.png",
		"frames": [ROOT / f"art/raw/walk-56/luna-final-{i:02d}/frames/luna-final-{i:02d}-00.png" for i in range(1, 9)],
		"metric_paths": [ROOT / f"art/raw/walk-56/luna-final-{i:02d}/metrics.json" for i in range(1, 9)],
		"head_path": ROOT / "art/raw/walk-56/luna-head-best.json",
		"factors": [0.12529, 0.122534, 0.123035, 0.123092, 0.11877, 0.12028, 0.11877, 0.12103],
		"eye_centres": [(87.14, 66.0), (87.4, 67.0), (87.4, 65.0), (87.38, 64.25), (89.17, 65.33), (88.2, 64.2), (90.0, 65.0), (89.0, 63.0)],
		"landmark": "마젠타 눈의 짙은 위쪽 윤곽 연결 성분 중심(분홍 머리카락은 위치·명도 문턱으로 제외)",
		"visual": {
			"equipment_pass": True,
			"equipment_note": "4배 육안: 완드는 전 프레임 같은 가까운 손에 남고, 자유 팔은 1~4번 앞/5~8번 뒤로 교대한다.",
			"leg_pass": True,
			"leg_note": "4배 육안: 1/5번은 서로 다른 다리가 선행하고 3/7번 스윙 발이 지면에서 분리된다.",
			"smooth_pass": False,
			"smooth_note": "13.3fps 육안: 6번이 down 대신 위로 남아 5→6→7 구간에서 한 번 꺾인다.",
		},
	},
}


def font(size: int) -> ImageFont.ImageFont:
	for path in ("C:/Windows/Fonts/malgunbd.ttf", "C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/arial.ttf"):
		try:
			return ImageFont.truetype(path, size)
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
	return [Image.open(path).convert("RGBA") for path in paths]


def make_strip(frames: list[Image.Image]) -> Image.Image:
	strip = Image.new("RGBA", (CELL * len(frames), CELL))
	for index, frame in enumerate(frames):
		strip.alpha_composite(frame, (CELL * index, 0))
	return strip


def build_compare(character: str, cfg: dict, best: Image.Image, out_dir: Path) -> None:
	start = Image.open(cfg["start"]).convert("RGBA")
	canvas = checker((CELL * 8 * SCALE, CELL * 2 * SCALE), 16)
	canvas.alpha_composite(start.resize((start.width * SCALE, start.height * SCALE), Image.Resampling.NEAREST), (0, 0))
	canvas.alpha_composite(best.resize((best.width * SCALE, best.height * SCALE), Image.Resampling.NEAREST), (0, CELL * SCALE))
	draw = ImageDraw.Draw(canvas)
	for y, label in ((0, f"{character.upper()} ART-55 START"), (CELL * SCALE, f"{character.upper()} ART-56 BEST (FAILED)")):
		draw.rectangle((0, y, 410, y + 42), fill=(12, 17, 29, 235))
		draw.text((12, y + 7), label, font=font(24), fill=(240, 244, 255, 255))
	canvas.convert("RGB").save(out_dir / "compare.png", optimize=True)


def reference_panels(sheet: Image.Image) -> list[Image.Image]:
	panels = []
	for index in range(8):
		row, column = divmod(index, 4)
		y = row * (512 + 52)
		panels.append(sheet.crop((column * 512, y, column * 512 + 512, y + 512)))
	return panels


def build_feet(cfg: dict, frames: list[Image.Image], out_dir: Path) -> None:
	refs = reference_panels(Image.open(cfg["reference"]).convert("RGBA"))
	height = 48 * SCALE
	canvas = Image.new("RGB", (CELL * 8 * SCALE, height * 2 + 56), (12, 17, 29))
	draw = ImageDraw.Draw(canvas)
	for index, (ref, frame) in enumerate(zip(refs, frames)):
		x = index * CELL * SCALE
		ref_crop = ref.resize((CELL, CELL), Image.Resampling.LANCZOS).crop((0, 80, CELL, CELL))
		frame_crop = frame.crop((0, 80, CELL, CELL))
		ref_big = ref_crop.resize((CELL * SCALE, height), Image.Resampling.NEAREST)
		frame_big = frame_crop.resize((CELL * SCALE, height), Image.Resampling.NEAREST)
		canvas.paste(ref_big.convert("RGB"), (x, 28))
		canvas.paste(frame_big.convert("RGB"), (x, 28 + height), frame_big.getchannel("A"))
		draw.text((x + 8, 3), f"F{index + 1} {PHASES[index].upper()}", font=font(18), fill=(240, 244, 255))
		if index:
			draw.line((x, 0, x, canvas.height), fill=(78, 90, 112), width=2)
	canvas.save(out_dir / "feet.png", optimize=True)


def build_gif(frames: list[Image.Image], out_dir: Path) -> None:
	gif_frames = []
	for frame in frames:
		background = checker((CELL, CELL), 8)
		background.alpha_composite(frame)
		gif_frames.append(background.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST).convert("P", palette=Image.Palette.ADAPTIVE, colors=255))
	# GIF stores centiseconds, so alternate 70/80 ms for an exact 75 ms mean (13.33 fps).
	gif_frames[0].save(out_dir / "walk.gif", save_all=True, append_images=gif_frames[1:], duration=[70, 80] * 4, loop=0, disposal=2)


def build_bob(cfg: dict, frames: list[Image.Image], out_dir: Path) -> tuple[list[int], list[int], list[bool]]:
	centres = cfg["eye_centres"]
	absolute = [int(value[1] + 0.5) for value in centres]
	relative = [value - absolute[0] for value in absolute]
	passes = [abs(value - target) <= 1 for value, target in zip(relative, TARGET)]
	width = CELL * 8 * SCALE
	height = 900
	canvas = checker((width, height), 16)
	draw = ImageDraw.Draw(canvas)
	for index, (frame, centre, passed) in enumerate(zip(frames, centres, passes)):
		x0 = index * CELL * SCALE
		big = frame.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST)
		canvas.alpha_composite(big, (x0, 0))
		x = x0 + int(centre[0] * SCALE)
		y = int(centre[1] * SCALE)
		colour = (70, 235, 150, 255) if passed else (255, 76, 92, 255)
		draw.ellipse((x - 12, y - 12, x + 12, y + 12), outline=colour, width=4)
		draw.line((x - 16, y, x + 16, y), fill=colour, width=2)
		draw.line((x, y - 16, x, y + 16), fill=colour, width=2)
		draw.rectangle((x0, 0, x0 + 164, 32), fill=(12, 17, 29, 230))
		draw.text((x0 + 7, 4), f"F{index + 1} y={absolute[index]}", font=font(17), fill=colour)
	graph_top = CELL * SCALE + 42
	graph_bottom = height - 45
	draw.rectangle((0, graph_top - 20, width, height), fill=(12, 17, 29, 245))
	draw.text((14, graph_top - 13), "EYE CENTRE BOB (relative output pixels)", font=font(22), fill=(240, 244, 255))
	zero_y = graph_top + 95
	for value in range(-4, 5):
		y = zero_y + value * 32
		draw.line((45, y, width - 20, y), fill=(55, 65, 83), width=1)
		draw.text((8, y - 10), f"{value:+d}", font=font(16), fill=(168, 180, 201))
	points_target = []
	points_measured = []
	for index, (target, measured, passed) in enumerate(zip(TARGET, relative, passes)):
		x = 90 + index * ((width - 130) // 7)
		y_target = zero_y + target * 32
		y_measured = zero_y + measured * 32
		points_target.append((x, y_target))
		points_measured.append((x, y_measured))
		draw.text((x - 10, graph_bottom + 7), str(index + 1), font=font(18), fill=(200, 209, 224))
		draw.ellipse((x - 6, y_measured - 6, x + 6, y_measured + 6), fill=(70, 235, 150) if passed else (255, 76, 92))
	if len(points_target) > 1:
		draw.line(points_target, fill=(80, 165, 255), width=4)
		draw.line(points_measured, fill=(255, 205, 70), width=3)
	draw.text((width - 385, graph_top - 13), "blue=target  yellow=measured  red=fail", font=font(18), fill=(214, 222, 237))
	canvas.convert("RGB").save(out_dir / "bob.png", optimize=True)
	return absolute, relative, passes


def build_metrics(character: str, cfg: dict, frames: list[Image.Image], out_dir: Path, absolute: list[int], relative: list[int], passes: list[bool]) -> None:
	frame_metrics = [json.loads(path.read_text(encoding="utf-8"))["frames"][0] for path in cfg["metric_paths"]]
	head = json.loads(cfg["head_path"].read_text(encoding="utf-8"))
	head_values = [float(item["frames"][0]["scale"]) for item in head]
	heights = [int(item["body_height"]) for item in frame_metrics]
	widths = [int(item["body_width"]) for item in frame_metrics]
	areas = [int(item["area"]) for item in frame_metrics]
	details = [float(item["interior_detail"]) for item in frame_metrics]
	colours = [int(item["colour_count"]) for item in frame_metrics]
	payload = {
		"status": "failed_acceptance",
		"delivered_candidate": False,
		"reason": "Frey frames 4 and 5 miss bob tolerance; Luna frame 6 misses bob tolerance. Card says deliver only a passing character.",
		"input": {
			"mode": "sequential anchor + pose + accepted-neighbour generations",
			"raw": f"art/raw/walk-56/{character}/",
			"starting_strip": str(cfg["start"].relative_to(ROOT)).replace("\\", "/"),
		},
		"summary": {
			"frame_count": 8,
			"best_attempt_size": [1024, 128],
			"normalization_factors": cfg["factors"],
			"factor_mode": "one factor per generation, matched to anchor head",
			"head_scale_range": [min(head_values), max(head_values)],
			"body_height_range": [min(heights), max(heights)],
			"body_width_range": [min(widths), max(widths)],
			"area_range": [min(areas), max(areas)],
			"area_spread_percent": round((max(areas) - min(areas)) / statistics.mean(areas) * 100, 2),
			"interior_detail_range": [round(min(details), 2), round(max(details), 2)],
			"interior_detail_mean": round(statistics.mean(details), 2),
			"colour_count_range": [min(colours), max(colours)],
			"remaining_spill_pixels": [int(item["remaining_spill_pixels"]) for item in frame_metrics],
			"borders_clear": all(bool(item["border_clear"]) for item in frame_metrics),
			"all_have_4px_margin": all(bool(item["margin"]["has_4px_margin"]) for item in frame_metrics),
			"alpha_binary": all(bool(item["alpha_binary"]) for item in frame_metrics),
			"contact_on_y120": all(int(item["bottom"]) == 120 for item in frame_metrics),
		},
		"bob": {
			"landmark": cfg["landmark"],
			"target_relative_y": TARGET,
			"tolerance_px": 1,
			"absolute_face_centre_y": absolute,
			"measured_relative_y": relative,
			"pass_by_frame": passes,
			"overall_pass": all(passes),
		},
		"head_scale": head,
		"visual_judgment_at_4x": cfg["visual"],
		"frames": frame_metrics,
		"outputs": {
			"best_attempt": str((out_dir / "best.png").relative_to(ROOT)).replace("\\", "/"),
			"bob": str((out_dir / "bob.png").relative_to(ROOT)).replace("\\", "/"),
			"feet": str((out_dir / "feet.png").relative_to(ROOT)).replace("\\", "/"),
			"gif": str((out_dir / "walk.gif").relative_to(ROOT)).replace("\\", "/"),
			"compare": str((out_dir / "compare.png").relative_to(ROOT)).replace("\\", "/"),
		},
	}
	(out_dir / "metrics.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
	for character, cfg in CONFIG.items():
		out_dir = ROOT / f"reports/codex-art-56/{character}"
		out_dir.mkdir(parents=True, exist_ok=True)
		frames = load_frames(cfg["frames"])
		best = make_strip(frames)
		best.save(out_dir / "best.png", optimize=True)
		build_compare(character, cfg, best, out_dir)
		build_feet(cfg, frames, out_dir)
		build_gif(frames, out_dir)
		absolute, relative, passes = build_bob(cfg, frames, out_dir)
		build_metrics(character, cfg, frames, out_dir, absolute, relative, passes)


if __name__ == "__main__":
	main()
