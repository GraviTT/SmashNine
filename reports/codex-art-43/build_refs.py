from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "art" / "raw" / "luna-43"
GAME = ROOT / "smash-nine-prototype" / "assets" / "art" / "luna"
BAKE = ROOT / "art" / "bakeoff" / "luna"


def cell(sheet: Image.Image, column: int, row: int, size: int = 128) -> Image.Image:
	return sheet.crop((column * size, row * size, (column + 1) * size, (row + 1) * size))


def sheet_ref(source: Path, row: int, frames: int, output: str, columns: int = 3) -> None:
	with Image.open(source).convert("RGBA") as sheet:
		rows = (frames + columns - 1) // columns
		out = Image.new("RGBA", (columns * 512, rows * 512), (0, 255, 0, 255))
		for index in range(frames):
			frame = cell(sheet, index, row).resize((512, 512), Image.Resampling.NEAREST)
			out.alpha_composite(frame, ((index % columns) * 512, (index // columns) * 512))
		out.convert("RGB").save(RAW / output)


def mixed_ref(source: Path, rows: list[int], output: str) -> None:
	with Image.open(source).convert("RGBA") as sheet:
		out = Image.new("RGBA", (len(rows) * 512, 512), (0, 255, 0, 255))
		for index, row in enumerate(rows):
			frame = cell(sheet, 0, row).resize((512, 512), Image.Resampling.NEAREST)
			out.alpha_composite(frame, (index * 512, 0))
		out.convert("RGB").save(RAW / output)


RAW.mkdir(parents=True, exist_ok=True)
sheet_ref(BAKE / "luna-idle-v3.png", 0, 1, "luna-idle-v3-frame1-4x.png", 1)
sheet_ref(GAME / "luna_sheet.png", 1, 6, "current-walk-4x.png")
mixed_ref(GAME / "luna_sheet.png", [2, 3, 6], "current-jump-fall-hurt-4x.png")
sheet_ref(GAME / "luna_sheet.png", 4, 4, "current-attack-4x.png", 2)
sheet_ref(GAME / "luna_sheet.png", 5, 6, "current-shield-4x.png")
sheet_ref(GAME / "luna_moves_sheet.png", 0, 4, "current-star_up-4x.png", 2)
sheet_ref(GAME / "luna_moves_sheet.png", 1, 4, "current-star_down-4x.png", 2)
sheet_ref(GAME / "luna_moves_sheet.png", 2, 4, "current-star_comet-4x.png", 2)
sheet_ref(GAME / "luna_moves_sheet.png", 3, 5, "current-moon_ring-4x.png")
sheet_ref(GAME / "luna_moves_sheet.png", 5, 4, "current-tumble-4x.png", 2)
