"""Render a compact visual summary of CODEX-ART-65 at 4x nearest scale."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "reports/codex-art-65"
BAKE = ROOT / "art/bakeoff/rio"


def checker(width: int, height: int, tile: int = 32) -> Image.Image:
	image = Image.new("RGBA", (width, height), (15, 22, 33, 255))
	draw = ImageDraw.Draw(image)
	for y in range(0, height, tile):
		for x in range(0, width, tile):
			if (x // tile + y // tile) % 2:
				draw.rectangle((x, y, x + tile - 1, y + tile - 1), fill=(26, 37, 53, 255))
	return image


def main() -> None:
	rows = [
		("FALL · DELIVERED", BAKE / "rio_male-fall-v1.png"),
		("SHIELD · DELIVERED", BAKE / "rio_male-shield-v1.png"),
		("INFINITY OVERDRIVE · DELIVERED", BAKE / "rio_male-infinity_overdrive-v1.png"),
		("WALK · BEST ATTEMPT, NOT DELIVERED", REPORT / "walk/best.png"),
	]
	font = ImageFont.load_default(size=24)
	strips: list[tuple[str, Image.Image]] = []
	max_width = 0
	for label, path in rows:
		with Image.open(path) as opened:
			strip = opened.convert("RGBA").resize((opened.width * 4, opened.height * 4), Image.Resampling.NEAREST)
		strips.append((label, strip))
		max_width = max(max_width, strip.width)
	line_height = 580
	board = checker(max_width + 64, 80 + line_height * len(strips))
	draw = ImageDraw.Draw(board)
	draw.text((24, 18), "RIO MALE · CODEX-ART-65 · 4X REVIEW", fill=(235, 241, 250, 255), font=font)
	for index, (label, strip) in enumerate(strips):
		y = 80 + index * line_height
		color = (110, 231, 183, 255) if "DELIVERED" in label and "NOT" not in label else (251, 191, 36, 255)
		draw.text((24, y), label, fill=color, font=font)
		board.alpha_composite(strip, (24, y + 42))
	board.save(REPORT / "overview.png")


if __name__ == "__main__":
	main()
