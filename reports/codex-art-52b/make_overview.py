from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
REPORT = Path(__file__).resolve().parent
ROWS = [
	("walk", "v1"), ("jump", "v1"), ("fall", "v1"), ("hurt", "v1"),
	("shield", "v1"), ("attack", "v1"), ("vector_side", "v3"),
	("vector_upper", "v1"), ("compression_stomp", "v1"), ("air_side", "v1"),
	("meteor_kick", "v1"), ("vector_shift", "v1"), ("gravity_brake", "v1"),
	("slingshot_start", "v1"), ("tumble", "v1"),
]
LABEL = 180
GAP = 8


strips = []
for row, version in ROWS:
	path = ROOT / f"art/bakeoff/nova/nova_female-{row}-{version}.png"
	strips.append((row, Image.open(path).convert("RGBA")))

width = LABEL + max(image.width for _, image in strips)
height = GAP + sum(image.height + GAP for _, image in strips)
canvas = Image.new("RGBA", (width, height), (15, 20, 30, 255))
draw = ImageDraw.Draw(canvas)
y = GAP
for row, strip in strips:
	for yy in range(0, strip.height, 8):
		for xx in range(0, strip.width, 8):
			shade = (31, 40, 57, 255) if (xx // 8 + yy // 8) % 2 else (39, 49, 69, 255)
			draw.rectangle((LABEL + xx, y + yy, LABEL + xx + 7, y + yy + 7), fill=shade)
	canvas.alpha_composite(strip, (LABEL, y))
	draw.text((12, y + 8), row, fill=(225, 234, 250, 255), stroke_width=1, stroke_fill=(0, 0, 0, 255))
	draw.line((0, y + strip.height, width, y + strip.height), fill=(81, 100, 132, 255), width=1)
	y += strip.height + GAP

canvas.convert("RGB").save(REPORT / "overview.png", quality=95)
