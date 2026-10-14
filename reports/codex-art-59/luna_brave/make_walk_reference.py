"""Draw Brave Luna's grey 8-pose walk reference for CODEX-ART-59."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


CELL = 512
LABEL_H = 52
LABELS = ("1 CONTACT", "2 DOWN", "3 PASSING", "4 UP", "5 CONTACT", "6 DOWN", "7 PASSING", "8 UP")
BG = (246, 248, 251, 255)
GRID = (188, 196, 208, 255)
GROUND = (55, 60, 70, 255)
TORSO = (128, 136, 148, 255)
TORSO_DARK = (76, 82, 92, 255)
NEAR = (208, 208, 208, 255)
NEAR_DARK = (138, 138, 138, 255)
FAR = (90, 90, 90, 255)
FAR_DARK = (46, 46, 46, 255)


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


def poses(index: int, hip_y: int, ground_y: int, leg: int, stride: int) -> tuple[list[tuple[int, int]], list[tuple[int, int]]]:
	data = [
		([(256, hip_y), (292, hip_y + leg // 2), (256 + stride, ground_y - 7), (256 + stride + 25, ground_y)], [(252, hip_y + 4), (222, hip_y + leg // 2), (256 - stride, ground_y - 20), (256 - stride - 13, ground_y)]),
		([(256, hip_y + 12), (300, hip_y + leg // 2 + 21), (256 + stride - 10, ground_y - 5), (256 + stride + 17, ground_y)], [(252, hip_y + 16), (217, hip_y + leg // 2 + 3), (219, ground_y - 50), (240, ground_y - 40)]),
		([(256, hip_y), (273, hip_y + leg // 2), (278, ground_y - 7), (300, ground_y)], [(252, hip_y + 4), (286, hip_y + leg // 2 - 11), (309, ground_y - 61), (333, ground_y - 52)]),
		([(256, hip_y - 11), (226, hip_y + leg // 2), (256 - stride + 10, ground_y - 25), (256 - stride + 31, ground_y)], [(252, hip_y - 7), (288, hip_y + leg // 2 - 9), (256 + stride - 12, ground_y - 12), (256 + stride + 20, ground_y)]),
		([(252, hip_y + 4), (222, hip_y + leg // 2), (256 - stride, ground_y - 20), (256 - stride - 13, ground_y)], [(256, hip_y), (292, hip_y + leg // 2), (256 + stride, ground_y - 7), (256 + stride + 25, ground_y)]),
		([(252, hip_y + 16), (217, hip_y + leg // 2 + 3), (219, ground_y - 50), (240, ground_y - 40)], [(256, hip_y + 12), (300, hip_y + leg // 2 + 21), (256 + stride - 10, ground_y - 5), (256 + stride + 17, ground_y)]),
		([(252, hip_y + 4), (286, hip_y + leg // 2 - 11), (309, ground_y - 61), (333, ground_y - 52)], [(256, hip_y), (273, hip_y + leg // 2), (278, ground_y - 7), (300, ground_y)]),
		([(252, hip_y - 7), (288, hip_y + leg // 2 - 9), (256 + stride - 12, ground_y - 12), (256 + stride + 20, ground_y)], [(256, hip_y - 11), (226, hip_y + leg // 2), (256 - stride + 10, ground_y - 25), (256 - stride + 31, ground_y)]),
	]
	return data[index]


def draw_panel(draw: ImageDraw.ImageDraw, index: int, x0: int, y0: int) -> None:
	ground_y = y0 + 416
	head_r, torso_len, leg_len, stride = 66, 54, 91, 76
	vertical = (0, 15, 0, -14, 0, 15, 0, -14)[index]
	hip_y = ground_y - leg_len + vertical
	shoulder_y = hip_y - torso_len
	head_c = (x0 + 265, shoulder_y - head_r + 5)
	near, far = poses(index, hip_y - y0, ground_y - y0, leg_len, stride)
	near = [(x0 + x, y0 + y) for x, y in near]
	far = [(x0 + x, y0 + y) for x, y in far]
	near_arm = [(x0 + 260, shoulder_y + 16), (x0 + 301, shoulder_y + 4), (x0 + 326, shoulder_y - 22)]
	far_delta = 8 if index < 4 else -8
	far_arm = [(x0 + 250, shoulder_y + 20), (x0 + 286 + far_delta, shoulder_y + 32), (x0 + 310 + far_delta, shoulder_y + 8)]
	draw.rectangle((x0, y0, x0 + 511, y0 + 511), fill=BG, outline=GRID, width=3)
	draw.line((x0 + 55, ground_y + 3, x0 + 457, ground_y + 3), fill=GROUND, width=8)
	limb(draw, far, FAR, FAR_DARK, 34)
	limb(draw, far_arm, FAR, FAR_DARK, 30)
	draw.rounded_rectangle((x0 + 213, shoulder_y, x0 + 299, hip_y + 18), radius=24, fill=TORSO, outline=TORSO_DARK, width=8)
	draw.ellipse((head_c[0] - head_r, head_c[1] - head_r, head_c[0] + head_r, head_c[1] + head_r), fill=TORSO, outline=TORSO_DARK, width=8)
	draw.polygon([(head_c[0] + head_r - 4, head_c[1] - 9), (head_c[0] + head_r + 20, head_c[1] + 2), (head_c[0] + head_r - 4, head_c[1] + 10)], fill=TORSO, outline=TORSO_DARK)
	limb(draw, near, NEAR, NEAR_DARK, 34)
	limb(draw, near_arm, NEAR, NEAR_DARK, 30)


def main() -> None:
	base = Path(__file__).resolve().parent
	panels = base.parents[2] / "art/raw/walk-59/luna_brave/poses"
	canvas = Image.new("RGBA", (2048, 1128), (255, 255, 255, 255))
	draw = ImageDraw.Draw(canvas)
	label_font = font(28)
	for index in range(8):
		row, col = divmod(index, 4)
		x0, y0 = col * CELL, row * (CELL + LABEL_H)
		draw_panel(draw, index, x0, y0)
		label = LABELS[index]
		box = draw.textbbox((0, 0), label, font=label_font)
		draw.text((x0 + (CELL - box[2] + box[0]) // 2, y0 + CELL + 9), label, fill=GROUND, font=label_font)
	panels.mkdir(parents=True, exist_ok=True)
	canvas.convert("RGB").save(base / "walk_reference_luna_brave.png")
	for index in range(8):
		row, col = divmod(index, 4)
		x0, y0 = col * CELL, row * (CELL + LABEL_H)
		canvas.crop((x0, y0, x0 + CELL, y0 + CELL)).convert("RGB").save(panels / f"luna_brave_pose_{index + 1:02d}.png")


if __name__ == "__main__":
	main()
