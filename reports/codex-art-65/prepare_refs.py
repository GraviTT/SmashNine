"""Create the compact Rio-male walk pose guides required by CODEX-ART-65."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "reports/codex-art-65"
ANCHOR = ROOT / "art/bakeoff/rio/rio_male-idle-v2.png"
CURRENT_WALK = ROOT / "reports/codex-art-61a/refs/current-walk.png"


def zoom(image: Image.Image, path: Path, factor: int = 4) -> None:
	path.parent.mkdir(parents=True, exist_ok=True)
	image.resize((image.width * factor, image.height * factor), Image.Resampling.NEAREST).save(path)


def limb(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], fill: str, rim: str, width: int) -> None:
	draw.line(points, fill=rim, width=width + 12, joint="curve")
	draw.line(points, fill=fill, width=width, joint="curve")


def pose(index: int) -> Image.Image:
	panel = Image.new("RGB", (512, 512), (246, 248, 251))
	draw = ImageDraw.Draw(panel)
	ground = 440
	vertical = (0, 10, -7, -13, 0, 10, -7, -13)[index]
	hip_y = 330 + vertical
	shoulder_y = 218 + vertical
	near = "#D0D0D0"
	near_rim = "#8A8A8A"
	far = "#5A5A5A"
	far_rim = "#2E2E2E"
	# Compact cycle: all feet remain inside an 88 px horizontal envelope.
	legs = [
		(((270, 330), (286, 387), (300, 440)), ((244, 332), (230, 390), (214, 440))),
		(((270, 340), (286, 399), (292, 440)), ((244, 342), (235, 388), (253, 425))),
		(((270, 322), (270, 382), (270, 440)), ((244, 326), (269, 371), (282, 416))),
		(((270, 316), (250, 374), (218, 440)), ((244, 319), (266, 379), (299, 440))),
		(((244, 332), (230, 390), (214, 440)), ((270, 330), (286, 387), (300, 440))),
		(((244, 342), (235, 388), (253, 425)), ((270, 340), (286, 399), (292, 440))),
		(((244, 326), (269, 371), (282, 416)), ((270, 322), (270, 382), (270, 440))),
		(((244, 319), (266, 379), (299, 440)), ((270, 316), (250, 374), (218, 440))),
	]
	near_leg, far_leg = legs[index]
	near_leg = [(x, y + vertical) for x, y in near_leg]
	far_leg = [(x, y + vertical) for x, y in far_leg]
	draw.line((80, ground + 3, 432, ground + 3), fill="#373C46", width=8)
	limb(draw, far_leg, far, far_rim, 30)
	limb(draw, [(242, shoulder_y + 18), (274, shoulder_y + 55), (305, shoulder_y + 76)], far, far_rim, 25)
	draw.rounded_rectangle((205, shoulder_y, 303, hip_y + 18), radius=25, fill="#808894", outline="#4A505A", width=8)
	draw.ellipse((202, shoulder_y - 124, 330, shoulder_y + 4), fill="#808894", outline="#4A505A", width=8)
	draw.polygon(((326, shoulder_y - 72), (350, shoulder_y - 60), (326, shoulder_y - 48)), fill="#808894")
	# Tight cape and low sword stay close to the body so head-matched art fits 128 px.
	draw.polygon(((207, shoulder_y + 32), (178, shoulder_y + 68), (190, hip_y + 20), (220, hip_y)), fill="#6C6C6C", outline="#373737")
	limb(draw, near_leg, near, near_rim, 30)
	limb(draw, [(263, shoulder_y + 14), (293, shoulder_y + 50), (315, shoulder_y + 75)], near, near_rim, 25)
	draw.line((313, shoulder_y + 75, 404, shoulder_y + 105), fill="#5F5F5F", width=14)
	return panel


def main() -> None:
	refs = REPORT / "refs"
	mannequins = refs / "walk_mannequin"
	mannequins.mkdir(parents=True, exist_ok=True)
	with Image.open(ANCHOR) as opened:
		zoom(opened.convert("RGBA").crop((0, 0, 128, 128)), refs / "anchor-4x.png")
	with Image.open(CURRENT_WALK) as opened:
		walk = opened.convert("RGBA")
		zoom(walk.crop((0, 0, 128, 128)), refs / "current-walk-frame1-4x.png")
		zoom(walk.crop((2 * 128, 0, 3 * 128, 128)), refs / "current-walk-passing-4x.png")
	board = Image.new("RGB", (4 * 512, 2 * 512), "white")
	for index in range(8):
		panel = pose(index)
		panel.save(mannequins / f"pose-{index + 1:02d}.png")
		board.paste(panel, ((index % 4) * 512, (index // 4) * 512))
	board.save(refs / "walk-mannequin.png")


if __name__ == "__main__":
	main()
