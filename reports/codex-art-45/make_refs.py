from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "_refs"
OUT.mkdir(parents=True, exist_ok=True)


def row_grid(source: Path, row: int, frames: int, out_name: str) -> None:
	image = Image.open(source).convert("RGBA")
	cell = 128
	canvas = Image.new("RGB", (1536, 1024), (0, 255, 0))
	for index in range(frames):
		frame = image.crop((index * cell, row * cell, (index + 1) * cell, (row + 1) * cell))
		backdrop = Image.new("RGBA", frame.size, (0, 255, 0, 255))
		backdrop.alpha_composite(frame)
		frame_4x = backdrop.convert("RGB").resize((512, 512), Image.Resampling.NEAREST)
		canvas.paste(frame_4x, ((index % 3) * 512, (index // 3) * 512))
	canvas.save(OUT / out_name)


base = ROOT / "smash-nine-prototype/assets/art/luna/luna_brave_sheet.png"
moves = ROOT / "smash-nine-prototype/assets/art/luna/luna_brave_moves_sheet.png"

row_grid(base, 1, 6, "current-walk-4x.png")
row_grid(base, 5, 6, "current-shield-4x.png")
row_grid(moves, 0, 6, "current-brave_combo-4x.png")
row_grid(moves, 1, 4, "current-brave_upper-4x.png")
row_grid(moves, 2, 4, "current-brave_low-4x.png")
row_grid(moves, 3, 4, "current-brave_air_side-4x.png")
row_grid(moves, 4, 4, "current-brave_dive-4x.png")
row_grid(moves, 5, 4, "current-comet_drive-4x.png")
row_grid(moves, 6, 6, "current-luna_breaker-4x.png")
row_grid(moves, 7, 6, "current-heart_laser-4x.png")
row_grid(moves, 8, 4, "current-tumble-4x.png")

# The three single-pose base rows share one 3-up reference image.
base_image = Image.open(base).convert("RGBA")
triptych = Image.new("RGB", (1536, 512), (0, 255, 0))
for column, row in enumerate((2, 3, 6)):
	frame = base_image.crop((0, row * 128, 128, (row + 1) * 128))
	backdrop = Image.new("RGBA", frame.size, (0, 255, 0, 255))
	backdrop.alpha_composite(frame)
	triptych.paste(backdrop.convert("RGB").resize((512, 512), Image.Resampling.NEAREST), (column * 512, 0))
triptych.save(OUT / "current-jump-fall-hurt-4x.png")

# The chosen six-frame anchor, also supplied at 4x in the same 3x2 layout.
anchor = Image.open(ROOT / "art/bakeoff/luna/luna_brave-idle-v4.png").convert("RGBA")
anchor_grid = Image.new("RGB", (1536, 1024), (0, 255, 0))
for index in range(6):
	frame = anchor.crop((index * 128, 0, (index + 1) * 128, 128))
	backdrop = Image.new("RGBA", frame.size, (0, 255, 0, 255))
	backdrop.alpha_composite(frame)
	anchor_grid.paste(backdrop.convert("RGB").resize((512, 512), Image.Resampling.NEAREST), ((index % 3) * 512, (index // 3) * 512))
anchor_grid.save(OUT / "anchor-v4-4x.png")
