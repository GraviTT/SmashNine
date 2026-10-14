from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "references"
OUT.mkdir(parents=True, exist_ok=True)
GREEN = (0, 255, 0, 255)


def frame(sheet: Path, cell: int, row: int, col: int) -> Image.Image:
	return Image.open(sheet).convert("RGBA").crop((col * cell, row * cell, (col + 1) * cell, (row + 1) * cell))


def on_green(image: Image.Image, scale: int = 4) -> Image.Image:
	bg = Image.new("RGBA", image.size, GREEN)
	bg.alpha_composite(image)
	return bg.resize((image.width * scale, image.height * scale), Image.Resampling.NEAREST).convert("RGB")


def row_ref(sheet: Path, cell: int, row: int, count: int, name: str) -> None:
	strip = Image.new("RGBA", (cell * count, cell))
	for index in range(count):
		strip.alpha_composite(frame(sheet, cell, row, index), (index * cell, 0))
	on_green(strip).save(OUT / f"{name}_4x.png")


anchor = ROOT / "art/bakeoff/rio/rio_female-idle-v2.png"
base = ROOT / "smash-nine-prototype/assets/art/rio/rio_female_sheet.png"
moves = ROOT / "smash-nine-prototype/assets/art/rio/rio_female_moves_sheet.png"

on_green(frame(anchor, 128, 0, 0)).save(OUT / "anchor_frame0_4x.png")
accepted_walk_1 = ROOT / "reports/codex-art-61b/walk/frame-01-attempt2/frame-01.png"
if accepted_walk_1.exists():
	on_green(frame(accepted_walk_1, 128, 0, 0)).save(OUT / "accepted_walk_frame01_4x.png")
for row, count, name in [
	(1, 6, "walk"), (2, 1, "jump"), (3, 1, "fall"),
	(6, 1, "hurt"), (5, 6, "shield"), (4, 4, "attack"),
]:
	row_ref(base, 128, row, count, name)

for row, count, name in [
	(0, 6, "mana_combo"), (1, 4, "rising_slash"), (2, 4, "low_sweep"),
	(3, 4, "air_slash"), (4, 5, "plunge"), (5, 5, "dimension_slash"),
	(6, 6, "rune_shield"), (7, 6, "infinity_overdrive"),
]:
	row_ref(moves, 128, row, count, name)

poses = [Image.open(OUT / f"{name}_4x.png").convert("RGB") for name in ("jump", "fall", "hurt")]
triptych = Image.new("RGB", (1536, 512), GREEN[:3])
for index, image in enumerate(poses):
	triptych.paste(image, (index * 512, 0))
triptych.save(OUT / "jump_fall_hurt_4x.png")

# Rio has no live tumble row. The accepted Yuki tumble is motion timing only.
yuki = ROOT / "art/bakeoff/yuki/yuki-tumble-v2.png"
if yuki.exists():
	on_green(Image.open(yuki).convert("RGBA")).save(OUT / "tumble_motion_4x.png")

# A compact grey eight-pose guide. Near limbs are light, far limbs dark.
cell = 512
board = Image.new("RGB", (cell * 4, cell * 2), (246, 248, 251))
draw = ImageDraw.Draw(board)
ground = 430
phases = [
	((70, 0), (-65, 0)), ((58, 0), (-20, -40)), ((8, 0), (8, -52)), ((-52, -25), (45, 0)),
	((-65, 0), (70, 0)), ((-20, -40), (58, 0)), ((8, -52), (0, 0)), ((45, 0), (-52, -25)),
]

def limb(points, fill, width=30):
	draw.line(points, fill=(38, 38, 38), width=width + 10, joint="curve")
	draw.line(points, fill=fill, width=width, joint="curve")

for index, (near_step, far_step) in enumerate(phases):
	row, col = divmod(index, 4)
	x0, y0 = col * cell, row * cell
	draw.rectangle((x0, y0, x0 + cell - 1, y0 + cell - 1), fill=(246, 248, 251), outline=(188, 196, 208), width=3)
	draw.line((x0 + 45, y0 + ground, x0 + cell - 45, y0 + ground), fill=(55, 60, 70), width=7)
	hip = (x0 + 255, y0 + 322)
	shoulder = (x0 + 253, y0 + 210)
	# Far leg/arm first.
	fx, fy = far_step
	far_knee = (hip[0] + fx // 2, hip[1] + 52 + min(0, fy // 4))
	far_ankle = (hip[0] + fx, y0 + ground + fy)
	limb([hip, far_knee, far_ankle], (86, 86, 86))
	limb([shoulder, (x0 + 210, y0 + 275), (x0 + 185, y0 + 330)], (86, 86, 86), 24)
	# Torso and head: roughly 2.2 heads tall, matching Rio female anchor.
	draw.rounded_rectangle((x0 + 210, y0 + 195, x0 + 295, y0 + 330), radius=24, fill=(132, 138, 147), outline=(70, 75, 84), width=8)
	draw.ellipse((x0 + 204, y0 + 74, x0 + 310, y0 + 190), fill=(132, 138, 147), outline=(70, 75, 84), width=8)
	draw.polygon([(x0 + 302, y0 + 120), (x0 + 328, y0 + 131), (x0 + 301, y0 + 141)], fill=(132, 138, 147), outline=(70, 75, 84))
	# Near leg and sword arm. Sword stays low and forward.
	nx, ny = near_step
	near_knee = (hip[0] + nx // 2, hip[1] + 52 + min(0, ny // 4))
	near_ankle = (hip[0] + nx, y0 + ground + ny)
	limb([hip, near_knee, near_ankle], (205, 205, 205))
	limb([shoulder, (x0 + 300, y0 + 265), (x0 + 330, y0 + 310)], (205, 205, 205), 24)
	limb([(x0 + 330, y0 + 310), (x0 + 420, y0 + 370)], (205, 205, 205), 13)

board.save(OUT / "walk_mannequin.png")
for index in range(8):
	row, col = divmod(index, 4)
	board.crop((col * cell, row * cell, (col + 1) * cell, (row + 1) * cell)).save(OUT / f"walk_pose_{index + 1:02d}.png")
