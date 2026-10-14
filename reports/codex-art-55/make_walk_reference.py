"""Draw colour-coded 8-pose walk references for CODEX-ART-55."""

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
NEAR = (242, 118, 27, 255)
NEAR_DARK = (156, 65, 9, 255)
FAR = (30, 111, 218, 255)
FAR_DARK = (13, 59, 130, 255)
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
	"""Draw a jointed limb with a dark rim and visible circular joints."""
	draw.line(points, fill=dark, width=width + 12, joint="curve")
	draw.line(points, fill=fill, width=width, joint="curve")
	radius = width // 2
	for x, y in points[1:-1]:
		draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=fill, outline=dark, width=5)


def foot(draw: ImageDraw.ImageDraw, ankle: tuple[int, int], toe: tuple[int, int], fill: tuple[int, ...], dark: tuple[int, ...], width: int) -> None:
	limb(draw, [ankle, toe], fill, dark, width)


def panel_origin(index: int) -> tuple[int, int]:
	row, col = divmod(index, COLS)
	return col * CELL, row * (CELL + LABEL_H)


def pose_data(index: int, hip_y: int, ground_y: int, leg: int, stride: int) -> dict[str, object]:
	"""Return exact near/far joint locations for the eight canonical keys."""
	hip = (256, hip_y)
	# Contact/down/passing/up, then the colour identities swap for the second step.
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
	return {"hip": hip, **keys[index]}


def draw_character_panel(draw: ImageDraw.ImageDraw, index: int, x0: int, y0: int, character: str) -> None:
	ground_y = y0 + 416
	if character == "frey":
		head_r, torso_len, leg_len, stride = 51, 72, 104, 91
		limb_width = 30
	else:
		head_r, torso_len, leg_len, stride = 66, 54, 91, 76
		limb_width = 34

	vertical = (0, 15, 0, -14, 0, 15, 0, -14)[index]
	hip_y = ground_y - leg_len + vertical
	shoulder_y = hip_y - torso_len
	head_c = (x0 + 265, shoulder_y - head_r + 5)
	hip_x = x0 + 256
	data = pose_data(index, hip_y - y0, ground_y - y0, leg_len, stride)
	near_leg = [(x0 + px, y0 + py) for px, py in data["near"]]  # type: ignore[index]
	far_leg = [(x0 + px, y0 + py) for px, py in data["far"]]  # type: ignore[index]

	# Arm swing is opposite its same-colour leg. The far arm is rendered first.
	near_forward = index in (4, 5, 6, 7)
	arm_swing = 45
	shoulder = (hip_x + 2, shoulder_y + 14)
	if near_forward:
		near_arm = [shoulder, (hip_x + 32, shoulder_y + 55), (hip_x + arm_swing, shoulder_y + 89)]
		far_arm = [(hip_x - 5, shoulder_y + 18), (hip_x - 34, shoulder_y + 58), (hip_x - arm_swing, shoulder_y + 91)]
	else:
		near_arm = [shoulder, (hip_x - 31, shoulder_y + 57), (hip_x - arm_swing, shoulder_y + 91)]
		far_arm = [(hip_x - 5, shoulder_y + 18), (hip_x + 31, shoulder_y + 55), (hip_x + arm_swing, shoulder_y + 88)]

	# Panel and ground.
	draw.rectangle((x0, y0, x0 + CELL - 1, y0 + CELL - 1), fill=BG, outline=GRID, width=3)
	draw.line((x0 + 55, ground_y + 3, x0 + CELL - 55, ground_y + 3), fill=GROUND, width=8)

	# Far limbs, torso/head, then near limbs to make depth unambiguous.
	limb(draw, far_leg, FAR, FAR_DARK, limb_width)
	foot(draw, far_leg[-2], far_leg[-1], FAR, FAR_DARK, limb_width)
	limb(draw, far_arm, FAR, FAR_DARK, limb_width - 4)

	torso_box = (hip_x - 43, shoulder_y, hip_x + 43, hip_y + 18)
	draw.rounded_rectangle(torso_box, radius=24, fill=TORSO, outline=TORSO_DARK, width=8)
	draw.ellipse((head_c[0] - head_r, head_c[1] - head_r, head_c[0] + head_r, head_c[1] + head_r), fill=TORSO, outline=TORSO_DARK, width=8)
	# Nose and eye establish a strict right-facing side view.
	draw.polygon([(head_c[0] + head_r - 4, head_c[1] - 9), (head_c[0] + head_r + 20, head_c[1] + 2), (head_c[0] + head_r - 4, head_c[1] + 10)], fill=TORSO, outline=TORSO_DARK)
	draw.ellipse((head_c[0] + 20, head_c[1] - 18, head_c[0] + 31, head_c[1] - 7), fill=WHITE, outline=TORSO_DARK, width=3)

	limb(draw, near_leg, NEAR, NEAR_DARK, limb_width)
	foot(draw, near_leg[-2], near_leg[-1], NEAR, NEAR_DARK, limb_width)
	limb(draw, near_arm, NEAR, NEAR_DARK, limb_width - 4)


def build(character: str, output: Path, panels_dir: Path | None = None) -> None:
	canvas = Image.new("RGBA", (COLS * CELL, ROWS * (CELL + LABEL_H)), WHITE)
	draw = ImageDraw.Draw(canvas)
	label_font = font(28)
	for index in range(8):
		x0, y0 = panel_origin(index)
		draw_character_panel(draw, index, x0, y0, character)
		label = LABELS[index]
		bbox = draw.textbbox((0, 0), label, font=label_font)
		text_w = bbox[2] - bbox[0]
		draw.text((x0 + (CELL - text_w) // 2, y0 + CELL + 9), label, fill=GROUND, font=label_font)
	output.parent.mkdir(parents=True, exist_ok=True)
	canvas.convert("RGB").save(output)
	if panels_dir is not None:
		panels_dir.mkdir(parents=True, exist_ok=True)
		for index in range(8):
			x0, y0 = panel_origin(index)
			canvas.crop((x0, y0, x0 + CELL, y0 + CELL)).convert("RGB").save(
				panels_dir / f"{character}_pose_{index + 1:02d}.png"
			)


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--out-dir", type=Path, default=Path(__file__).resolve().parent)
	parser.add_argument("--panels-dir", type=Path)
	args = parser.parse_args()
	for character in ("frey", "luna"):
		build(character, args.out_dir / f"walk_reference_{character}.png", args.panels_dir)


if __name__ == "__main__":
	main()
