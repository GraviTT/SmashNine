from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "smash-nine-prototype/assets/art/nova/nova_male_sheet.png"
MOVES = ROOT / "smash-nine-prototype/assets/art/nova/nova_male_moves_sheet.png"
OUT = ROOT / "reports/codex-art-52a"


def row_reference(name: str, sheet_path: Path, row: int, frames: int = 6) -> None:
	with Image.open(sheet_path) as source:
		sheet = source.convert("RGBA")
		strip = sheet.crop((0, row * 128, frames * 128, (row + 1) * 128))
		strip = strip.resize((strip.width * 4, strip.height * 4), Image.Resampling.NEAREST)
		target = OUT / name / "current-row-4x.png"
		target.parent.mkdir(parents=True, exist_ok=True)
		strip.save(target)


def pose_reference() -> None:
	with Image.open(BASE) as source:
		sheet = source.convert("RGBA")
		strip = Image.new("RGBA", (3 * 128, 128), (0, 0, 0, 0))
		for column, row in enumerate((2, 3, 6)):
			frame = sheet.crop((0, row * 128, 128, (row + 1) * 128))
			strip.alpha_composite(frame, (column * 128, 0))
		strip = strip.resize((strip.width * 4, strip.height * 4), Image.Resampling.NEAREST)
		target = OUT / "jump-fall-hurt" / "current-row-4x.png"
		target.parent.mkdir(parents=True, exist_ok=True)
		strip.save(target)


def main() -> None:
	row_reference("walk", BASE, 1)
	pose_reference()
	row_reference("shield", BASE, 5)
	for row, name in enumerate((
		"vector_side",
		"vector_upper",
		"compression_stomp",
		"air_side",
		"meteor_kick",
		"vector_shift",
		"gravity_brake",
		"slingshot_start",
	)):
		row_reference(name, MOVES, row)
	# Nova has no current tumble row; the current hurt pose is the closest motion cue.
	row_reference("tumble", BASE, 6, frames=1)


if __name__ == "__main__":
	main()
