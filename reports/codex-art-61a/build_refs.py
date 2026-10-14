"""Build Rio male pose references and the ART-59 grey walk mannequin."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "reports/codex-art-61a"
BASE = ROOT / "smash-nine-prototype/assets/art/rio/rio_male_sheet.png"
MOVES = ROOT / "smash-nine-prototype/assets/art/rio/rio_male_moves_sheet.png"
ANCHOR = ROOT / "art/bakeoff/rio/rio_male-idle-v2.png"


def save_zoom(source: Image.Image, path: Path, scale: int = 4) -> None:
	path.parent.mkdir(parents=True, exist_ok=True)
	source.resize((source.width * scale, source.height * scale), Image.Resampling.NEAREST).save(path)


def extract_refs() -> None:
	with Image.open(ANCHOR) as opened:
		anchor = opened.convert("RGBA").crop((0, 0, 128, 128))
	save_zoom(anchor, REPORT / "refs/anchor-4x.png")
	with Image.open(BASE) as opened:
		base = opened.convert("RGBA")
		walk = base.crop((0, 128, 6 * 128, 2 * 128))
		walk.save(REPORT / "refs/current-walk.png")
		save_zoom(walk, REPORT / "walk/current-row-4x.png")
		poses = Image.new("RGBA", (3 * 128, 128), (0, 0, 0, 0))
		for column, row in enumerate((2, 3, 6)):
			poses.alpha_composite(base.crop((0, row * 128, 128, (row + 1) * 128)), (column * 128, 0))
		save_zoom(poses, REPORT / "jump-fall-hurt/current-row-4x.png")
		for name, row in (("shield", 5), ("attack", 4)):
			save_zoom(base.crop((0, row * 128, 6 * 128, (row + 1) * 128)), REPORT / name / "current-row-4x.png")
	with Image.open(MOVES) as opened:
		moves = opened.convert("RGBA")
		for row, name in enumerate((
			"mana_combo", "rising_slash", "low_sweep", "air_slash", "plunge",
			"dimension_slash", "rune_shield", "infinity_overdrive",
		)):
			save_zoom(moves.crop((0, row * 128, 6 * 128, (row + 1) * 128)), REPORT / name / "current-row-4x.png")


def limb(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], fill: tuple[int, ...], rim: tuple[int, ...], width: int) -> None:
	draw.line(points, fill=rim, width=width + 12, joint="curve")
	draw.line(points, fill=fill, width=width, joint="curve")


def walk_pose(index: int, x0: int, y0: int) -> Image.Image:
	cell = 512
	panel = Image.new("RGB", (cell, cell), (246, 248, 251))
	draw = ImageDraw.Draw(panel)
	ground = 440
	hip_x = 256
	vertical = (0, 12, -8, -15, 0, 12, -8, -15)[index]
	hip_y = 330 + vertical
	shoulder_y = 218 + vertical
	head_r = 64
	near = (212, 212, 212)
	far = (92, 92, 92)
	near_rim = (136, 136, 136)
	far_rim = (44, 44, 44)
	poses = [
		(((275, 330), (310, 385), (360, 440)), ((245, 332), (215, 388), (165, 440))),
		(((275, 342), (317, 397), (345, 440)), ((245, 344), (220, 385), (250, 423))),
		(((275, 322), (278, 382), (276, 440)), ((245, 326), (274, 370), (292, 416))),
		(((275, 315), (240, 373), (192, 440)), ((245, 318), (286, 378), (338, 440))),
		(((245, 332), (215, 388), (165, 440)), ((275, 330), (310, 385), (360, 440))),
		(((245, 344), (220, 385), (250, 423)), ((275, 342), (317, 397), (345, 440))),
		(((245, 326), (274, 370), (292, 416)), ((275, 322), (278, 382), (276, 440))),
		(((245, 318), (286, 378), (338, 440)), ((275, 315), (240, 373), (192, 440))),
	]
	near_leg, far_leg = poses[index]
	shift = vertical
	near_leg = [(x, y + shift) for x, y in near_leg]
	far_leg = [(x, y + shift) for x, y in far_leg]
	draw.line((48, ground + 3, 464, ground + 3), fill=(55, 60, 70), width=8)
	limb(draw, far_leg, far, far_rim, 30)
	# Far arm stays near the sword grip; near arm follows it, keeping the low forward blade steady.
	limb(draw, [(242, shoulder_y + 18), (276, shoulder_y + 58), (314, shoulder_y + 82)], far, far_rim, 25)
	draw.rounded_rectangle((205, shoulder_y, 303, hip_y + 18), radius=25, fill=(128, 136, 148), outline=(74, 80, 90), width=8)
	draw.ellipse((202, shoulder_y - 124, 330, shoulder_y + 4), fill=(128, 136, 148), outline=(74, 80, 90), width=8)
	draw.polygon(((326, shoulder_y - 72), (350, shoulder_y - 60), (326, shoulder_y - 48)), fill=(128, 136, 148))
	limb(draw, near_leg, near, near_rim, 30)
	limb(draw, [(263, shoulder_y + 14), (299, shoulder_y + 52), (324, shoulder_y + 80)], near, near_rim, 25)
	# Sword and cape are neutral grey pose guides, not costume colours.
	draw.line((318, shoulder_y + 79, 433, shoulder_y + 121), fill=(95, 95, 95), width=14)
	draw.polygon(((207, shoulder_y + 30), (150, shoulder_y + 76), (179, hip_y + 28), (218, hip_y)), fill=(108, 108, 108), outline=(55, 55, 55))
	return panel


def make_walk_mannequin() -> None:
	out = REPORT / "refs/walk_mannequin"
	out.mkdir(parents=True, exist_ok=True)
	board = Image.new("RGB", (4 * 512, 2 * 512), (255, 255, 255))
	for index in range(8):
		panel = walk_pose(index, 0, 0)
		panel.save(out / f"rio_male_pose_{index + 1:02d}.png")
		board.paste(panel, ((index % 4) * 512, (index // 4) * 512))
	board.save(REPORT / "refs/walk_mannequin.png")


if __name__ == "__main__":
	extract_refs()
	make_walk_mannequin()
