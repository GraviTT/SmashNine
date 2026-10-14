from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "reports" / "codex-art-43"
BAKE = ROOT / "art" / "bakeoff" / "luna"
GAME = ROOT / "smash-nine-prototype" / "assets" / "art" / "luna"

ROWS = [
	("idle", "luna-idle-v3.png", 128, "luna_sheet.png", [0] * 4, list(range(4))),
	("walk", "luna-walk-v1.png", 128, "luna_sheet.png", [1] * 6, list(range(6))),
	("jump-fall-hurt", "luna-jump-fall-hurt-normalized-01.png", 128, "luna_sheet.png", [2, 3, 6], [0, 0, 0]),
	("star_side", "luna-star_side-v1.png", 192, "luna_sheet.png", [4] * 4, list(range(4))),
	("shield", "luna-shield-v1.png", 128, "luna_sheet.png", [5] * 6, list(range(6))),
	("star_up", "luna-star_up-v1.png", 192, "luna_moves_sheet.png", [0] * 4, list(range(4))),
	("star_down", "luna-star_down-v1.png", 192, "luna_moves_sheet.png", [1] * 4, list(range(4))),
	("star_comet", "luna-star_comet-v1.png", 192, "luna_moves_sheet.png", [2] * 4, list(range(4))),
	("moon_ring", "luna-moon_ring-v1.png", 192, "luna_moves_sheet.png", [3] * 5, list(range(5))),
	("tumble", "luna-tumble-v1.png", 192, "luna_moves_sheet.png", [5] * 4, list(range(4))),
]


def checker(size: int) -> Image.Image:
	out = Image.new("RGBA", (size, size), (28, 35, 49, 255))
	draw = ImageDraw.Draw(out)
	step = 8
	for y in range(0, size, step):
		for x in range(0, size, step):
			if (x // step + y // step) % 2:
				draw.rectangle((x, y, x + step - 1, y + step - 1), fill=(39, 49, 68, 255))
	return out


def cell(sheet: Image.Image, column: int, row: int, size: int) -> Image.Image:
	return sheet.crop((column * size, row * size, (column + 1) * size, (row + 1) * size))


def place(frame: Image.Image, source_cell: int, display_cell: int) -> Image.Image:
	canvas = checker(display_cell)
	target_feet = 152 if display_cell == 192 else 120
	source_feet = 152 if source_cell == 192 else 120
	x = (display_cell - source_cell) // 2
	y = target_feet - source_feet
	canvas.alpha_composite(frame, (x, y))
	return canvas


anchor_sheet = Image.open(BAKE / "luna-idle-v3.png").convert("RGBA")
anchor = cell(anchor_sheet, 0, 0, 128)
font = ImageFont.load_default()

overview_rows: list[tuple[str, Image.Image, int]] = []

for directory, candidate_name, candidate_cell, current_name, current_rows, current_columns in ROWS:
	display_cell = candidate_cell
	if directory == "jump-fall-hurt":
		candidate_path = ROOT / "art" / "raw" / "luna-43" / candidate_name
	else:
		candidate_path = BAKE / candidate_name
	with Image.open(candidate_path).convert("RGBA") as candidate, Image.open(GAME / current_name).convert("RGBA") as current:
		candidate_count = 3 if directory == "jump-fall-hurt" else 6
		current_frames = [cell(current, column, row, 128) for row, column in zip(current_rows, current_columns)]
		candidate_frames = [cell(candidate, index, 0, candidate_cell) for index in range(candidate_count)]
		columns = 1 + max(len(current_frames), len(candidate_frames))
		header = 24
		scale = 4
		row_px = display_cell * scale
		out = Image.new("RGB", (columns * row_px, header * 2 + row_px * 2), (12, 17, 27))
		draw = ImageDraw.Draw(out)
		draw.text((8, 7), f"{directory.upper()}  |  ANCHOR + CURRENT ROW  |  4X", fill=(235, 239, 248), font=font)
		draw.text((8, header + row_px + 7), f"{directory.upper()}  |  ANCHOR + CANDIDATE", fill=(235, 239, 248), font=font)
		for row_index, frames in enumerate((current_frames, candidate_frames)):
			y = header + row_index * (header + row_px)
			anchor_panel = place(anchor, 128, display_cell).resize((row_px, row_px), Image.Resampling.NEAREST)
			out.paste(anchor_panel.convert("RGB"), (0, y))
			for index, frame in enumerate(frames):
				panel = place(frame, 128 if row_index == 0 else candidate_cell, display_cell)
				panel = panel.resize((row_px, row_px), Image.Resampling.NEAREST)
				out.paste(panel.convert("RGB"), ((index + 1) * row_px, y))
		out.save(REPORT / directory / "compare.png")

		strip = Image.new("RGB", (6 * display_cell * 2, display_cell * 2), (12, 17, 27))
		for index, frame in enumerate(candidate_frames):
			panel = place(frame, candidate_cell, display_cell).resize((display_cell * 2, display_cell * 2), Image.Resampling.NEAREST)
			strip.paste(panel.convert("RGB"), (index * display_cell * 2, 0))
		overview_rows.append((directory, strip, display_cell))

label_width = 180
overview_width = label_width + max(strip.width for _, strip, _ in overview_rows)
overview_height = sum(strip.height + 8 for _, strip, _ in overview_rows)
overview = Image.new("RGB", (overview_width, overview_height), (12, 17, 27))
draw = ImageDraw.Draw(overview)
y = 0
for label, strip, _ in overview_rows:
	draw.text((8, y + 10), label.upper(), fill=(235, 239, 248), font=font)
	overview.paste(strip, (label_width, y))
	y += strip.height + 8
overview.save(REPORT / "overview.png")
