"""Build the grey Nova walk mannequin and 4x generation references for ART-59."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


CELL = 512
LABEL_H = 52
COLS = 4
ROWS = 2
BG = (246, 248, 251, 255)
GRID = (188, 196, 208, 255)
GROUND = (55, 60, 70, 255)
TORSO = (128, 136, 148, 255)
TORSO_DARK = (76, 82, 92, 255)
NEAR = (208, 208, 208, 255)
NEAR_DARK = (138, 138, 138, 255)
FAR = (90, 90, 90, 255)
FAR_DARK = (46, 46, 46, 255)
WHITE = (255, 255, 255, 255)
LABELS = ("1 CONTACT", "2 DOWN", "3 PASSING", "4 UP", "5 CONTACT", "6 DOWN", "7 PASSING", "8 UP")


def font(size: int) -> ImageFont.ImageFont:
	for name in ("C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/arial.ttf"):
		try:
			return ImageFont.truetype(name, size)
		except OSError:
			pass
	return ImageFont.load_default()


def limb(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], fill: tuple[int, ...], dark: tuple[int, ...], width: int) -> None:
	draw.line(points, fill=dark, width=width + 12, joint="curve")
	draw.line(points, fill=fill, width=width, joint="curve")
	radius = width // 2
	for x, y in points[1:-1]:
		draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=fill, outline=dark, width=5)


def pose_data(index: int, hip_y: int, ground_y: int, leg: int, stride: int) -> dict[str, object]:
	keys = [
		{"near": [(256, hip_y), (292, hip_y + leg // 2), (256 + stride, ground_y - 7), (256 + stride + 25, ground_y)],
		 "far": [(252, hip_y + 4), (222, hip_y + leg // 2), (256 - stride, ground_y - 20), (256 - stride - 13, ground_y)]},
		{"near": [(256, hip_y + 12), (300, hip_y + leg // 2 + 21), (256 + stride - 10, ground_y - 5), (256 + stride + 17, ground_y)],
		 "far": [(252, hip_y + 16), (217, hip_y + leg // 2 + 3), (219, ground_y - 50), (240, ground_y - 40)]},
		{"near": [(256, hip_y), (273, hip_y + leg // 2), (278, ground_y - 7), (300, ground_y)],
		 "far": [(252, hip_y + 4), (286, hip_y + leg // 2 - 11), (309, ground_y - 61), (333, ground_y - 52)]},
		{"near": [(256, hip_y - 11), (226, hip_y + leg // 2), (256 - stride + 10, ground_y - 25), (256 - stride + 31, ground_y)],
		 "far": [(252, hip_y - 7), (288, hip_y + leg // 2 - 9), (256 + stride - 12, ground_y - 12), (256 + stride + 20, ground_y)]},
		{"near": [(252, hip_y + 4), (222, hip_y + leg // 2), (256 - stride, ground_y - 20), (256 - stride - 13, ground_y)],
		 "far": [(256, hip_y), (292, hip_y + leg // 2), (256 + stride, ground_y - 7), (256 + stride + 25, ground_y)]},
		{"near": [(252, hip_y + 16), (217, hip_y + leg // 2 + 3), (219, ground_y - 50), (240, ground_y - 40)],
		 "far": [(256, hip_y + 12), (300, hip_y + leg // 2 + 21), (256 + stride - 10, ground_y - 5), (256 + stride + 17, ground_y)]},
		{"near": [(252, hip_y + 4), (286, hip_y + leg // 2 - 11), (309, ground_y - 61), (333, ground_y - 52)],
		 "far": [(256, hip_y), (273, hip_y + leg // 2), (278, ground_y - 7), (300, ground_y)]},
		{"near": [(252, hip_y - 7), (288, hip_y + leg // 2 - 9), (256 + stride - 12, ground_y - 12), (256 + stride + 20, ground_y)],
		 "far": [(256, hip_y - 11), (226, hip_y + leg // 2), (256 - stride + 10, ground_y - 25), (256 - stride + 31, ground_y)]},
	]
	return keys[index]


def panel_origin(index: int) -> tuple[int, int]:
	row, col = divmod(index, COLS)
	return col * CELL, row * (CELL + LABEL_H)


def draw_nova_panel(draw: ImageDraw.ImageDraw, index: int, x0: int, y0: int) -> None:
	ground_y = y0 + 416
	head_r, torso_len, leg_len, stride = 50, 82, 130, 82
	limb_width = 32
	vertical = (0, 15, 0, -14, 0, 15, 0, -14)[index]
	hip_y = ground_y - leg_len + vertical
	shoulder_y = hip_y - torso_len
	head_c = (x0 + 265, shoulder_y - head_r + 8)
	hip_x = x0 + 256
	data = pose_data(index, hip_y - y0, ground_y - y0, leg_len, stride)
	near_leg = [(x0 + px, y0 + py) for px, py in data["near"]]  # type: ignore[index]
	far_leg = [(x0 + px, y0 + py) for px, py in data["far"]]  # type: ignore[index]

	# Nova has no held prop. Both guarded fists swing only slightly, opposite the legs.
	near_leg_forward = index < 4
	if near_leg_forward:
		near_arm = [(hip_x + 6, shoulder_y + 15), (hip_x - 24, shoulder_y + 57), (hip_x - 8, shoulder_y + 85)]
		far_arm = [(hip_x - 7, shoulder_y + 17), (hip_x + 29, shoulder_y + 48), (hip_x + 53, shoulder_y + 64)]
	else:
		near_arm = [(hip_x + 6, shoulder_y + 15), (hip_x + 34, shoulder_y + 47), (hip_x + 56, shoulder_y + 64)]
		far_arm = [(hip_x - 7, shoulder_y + 17), (hip_x - 28, shoulder_y + 58), (hip_x - 12, shoulder_y + 85)]

	draw.rectangle((x0, y0, x0 + CELL - 1, y0 + CELL - 1), fill=BG, outline=GRID, width=3)
	draw.line((x0 + 55, ground_y + 3, x0 + CELL - 55, ground_y + 3), fill=GROUND, width=8)
	limb(draw, far_leg, FAR, FAR_DARK, limb_width)
	limb(draw, far_arm, FAR, FAR_DARK, limb_width - 4)
	draw.rounded_rectangle((hip_x - 42, shoulder_y, hip_x + 42, hip_y + 18), radius=22, fill=TORSO, outline=TORSO_DARK, width=8)
	draw.ellipse((head_c[0] - head_r, head_c[1] - head_r, head_c[0] + head_r, head_c[1] + head_r), fill=TORSO, outline=TORSO_DARK, width=8)
	draw.polygon([(head_c[0] + head_r - 4, head_c[1] - 9), (head_c[0] + head_r + 20, head_c[1] + 2), (head_c[0] + head_r - 4, head_c[1] + 10)], fill=TORSO, outline=TORSO_DARK)
	draw.ellipse((head_c[0] + 20, head_c[1] - 18, head_c[0] + 31, head_c[1] - 7), fill=WHITE, outline=TORSO_DARK, width=3)
	limb(draw, near_leg, NEAR, NEAR_DARK, limb_width)
	limb(draw, near_arm, NEAR, NEAR_DARK, limb_width - 4)


def crop_frame(path: Path, frame: int) -> Image.Image:
	image = Image.open(path).convert("RGBA")
	return image.crop((frame * 128, 0, frame * 128 + 128, 128))


def build(args: argparse.Namespace) -> None:
	canvas = Image.new("RGBA", (COLS * CELL, ROWS * (CELL + LABEL_H)), WHITE)
	draw = ImageDraw.Draw(canvas)
	label_font = font(28)
	for index in range(8):
		x0, y0 = panel_origin(index)
		draw_nova_panel(draw, index, x0, y0)
		bbox = draw.textbbox((0, 0), LABELS[index], font=label_font)
		draw.text((x0 + (CELL - (bbox[2] - bbox[0])) // 2, y0 + CELL + 9), LABELS[index], fill=GROUND, font=label_font)

	args.report_dir.mkdir(parents=True, exist_ok=True)
	args.raw_dir.mkdir(parents=True, exist_ok=True)
	poses = args.raw_dir / "poses"
	refs = args.raw_dir / "refs"
	poses.mkdir(parents=True, exist_ok=True)
	refs.mkdir(parents=True, exist_ok=True)
	canvas.convert("RGB").save(args.report_dir / f"walk_reference_{args.stem}.png")
	for index in range(8):
		x0, y0 = panel_origin(index)
		canvas.crop((x0, y0, x0 + CELL, y0 + CELL)).convert("RGB").save(poses / f"{args.stem}_pose_{index + 1:02d}.png")

	resample = Image.Resampling.NEAREST
	crop_frame(args.idle, 0).resize((512, 512), resample).save(refs / "idle_frame0_4x.png")
	crop_frame(args.walk, 0).resize((512, 512), resample).save(refs / "game_walk_frame0_4x.png")
	crop_frame(args.walk, args.together_frame).resize((512, 512), resample).save(refs / "legacy_together_4x.png")


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--stem", required=True)
	parser.add_argument("--idle", type=Path, required=True)
	parser.add_argument("--walk", type=Path, required=True)
	parser.add_argument("--together-frame", type=int, required=True, help="zero-based frame index")
	parser.add_argument("--report-dir", type=Path, required=True)
	parser.add_argument("--raw-dir", type=Path, required=True)
	build(parser.parse_args())


if __name__ == "__main__":
	main()
