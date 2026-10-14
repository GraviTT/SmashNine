"""Draw the grey Frey 8-pose walk reference for CODEX-ART-57."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


CELL = 512
LABEL_H = 52
COLS = 4
BG = (246, 248, 251, 255)
GRID = (188, 196, 208, 255)
GROUND = (55, 60, 70, 255)
TORSO = (128, 136, 148, 255)
TORSO_RIM = (76, 82, 92, 255)
NEAR = (208, 208, 208, 255)
NEAR_RIM = (138, 138, 138, 255)
FAR = (90, 90, 90, 255)
FAR_RIM = (46, 46, 46, 255)
WHITE = (255, 255, 255, 255)
LABELS = ("1 CONTACT", "2 DOWN", "3 PASSING", "4 UP", "5 CONTACT", "6 DOWN", "7 PASSING", "8 UP")


def font(size: int) -> ImageFont.ImageFont:
	for name in ("C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/arial.ttf"):
		try:
			return ImageFont.truetype(name, size)
		except OSError:
			pass
	return ImageFont.load_default()


def limb(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], fill: tuple[int, ...], rim: tuple[int, ...], width: int) -> None:
	draw.line(points, fill=rim, width=width + 12, joint="curve")
	draw.line(points, fill=fill, width=width, joint="curve")
	radius = width // 2
	for x, y in points[1:-1]:
		draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=fill, outline=rim, width=5)


def pose_data(index: int, hip_y: int, ground_y: int, leg: int, stride: int) -> dict[str, object]:
	"""The ART-55 canonical walk keys, unchanged."""
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


def draw_panel(draw: ImageDraw.ImageDraw, index: int, x0: int, y0: int) -> None:
	ground_y = y0 + 416
	head_r, torso_len, leg_len, stride = 51, 72, 104, 91
	vertical = (0, 15, 0, -14, 0, 15, 0, -14)[index]
	hip_y = ground_y - leg_len + vertical
	shoulder_y = hip_y - torso_len
	hip_x = x0 + 256
	data = pose_data(index, hip_y - y0, ground_y - y0, leg_len, stride)
	near_leg = [(x0 + px, y0 + py) for px, py in data["near"]]  # type: ignore[index]
	far_leg = [(x0 + px, y0 + py) for px, py in data["far"]]  # type: ignore[index]

	# Frey's far shield arm remains steady in front. The sword arm points forward-down
	# with only a small opposing swing across the cycle.
	sword_dx = (-8, -5, 0, 5, 8, 5, 0, -5)[index]
	shoulder = (hip_x + 2, shoulder_y + 14)
	near_arm = [shoulder, (hip_x + 25 + sword_dx, shoulder_y + 51), (hip_x + 42 + sword_dx, shoulder_y + 86)]
	far_arm = [(hip_x - 5, shoulder_y + 18), (hip_x + 25, shoulder_y + 48), (hip_x + 41, shoulder_y + 73)]

	draw.rectangle((x0, y0, x0 + CELL - 1, y0 + CELL - 1), fill=BG, outline=GRID, width=3)
	draw.line((x0 + 55, ground_y + 3, x0 + CELL - 55, ground_y + 3), fill=GROUND, width=8)
	limb(draw, far_leg, FAR, FAR_RIM, 30)
	limb(draw, far_arm, FAR, FAR_RIM, 26)
	draw.rounded_rectangle((hip_x - 43, shoulder_y, hip_x + 43, hip_y + 18), radius=24, fill=TORSO, outline=TORSO_RIM, width=8)
	head_c = (x0 + 265, shoulder_y - head_r + 5)
	draw.ellipse((head_c[0] - head_r, head_c[1] - head_r, head_c[0] + head_r, head_c[1] + head_r), fill=TORSO, outline=TORSO_RIM, width=8)
	draw.polygon([(head_c[0] + head_r - 4, head_c[1] - 9), (head_c[0] + head_r + 20, head_c[1] + 2), (head_c[0] + head_r - 4, head_c[1] + 10)], fill=TORSO, outline=TORSO_RIM)
	draw.ellipse((head_c[0] + 20, head_c[1] - 18, head_c[0] + 31, head_c[1] - 7), fill=WHITE, outline=TORSO_RIM, width=3)
	limb(draw, near_leg, NEAR, NEAR_RIM, 30)
	limb(draw, near_arm, NEAR, NEAR_RIM, 26)


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--out", type=Path, default=Path(__file__).resolve().parent / "walk_reference_frey.png")
	parser.add_argument("--panels-dir", type=Path)
	args = parser.parse_args()
	canvas = Image.new("RGBA", (4 * CELL, 2 * (CELL + LABEL_H)), WHITE)
	draw = ImageDraw.Draw(canvas)
	label_font = font(28)
	for index in range(8):
		row, col = divmod(index, 4)
		x0, y0 = col * CELL, row * (CELL + LABEL_H)
		draw_panel(draw, index, x0, y0)
		bbox = draw.textbbox((0, 0), LABELS[index], font=label_font)
		draw.text((x0 + (CELL - (bbox[2] - bbox[0])) // 2, y0 + CELL + 9), LABELS[index], fill=GROUND, font=label_font)
	args.out.parent.mkdir(parents=True, exist_ok=True)
	canvas.convert("RGB").save(args.out)
	if args.panels_dir:
		args.panels_dir.mkdir(parents=True, exist_ok=True)
		for index in range(8):
			row, col = divmod(index, 4)
			x0, y0 = col * CELL, row * (CELL + LABEL_H)
			canvas.crop((x0, y0, x0 + CELL, y0 + CELL)).convert("RGB").save(args.panels_dir / f"frey_pose_{index + 1:02d}.png")


if __name__ == "__main__":
	main()
