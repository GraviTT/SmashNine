from pathlib import Path
import json

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
REPORT = Path(__file__).resolve().parent
ANCHOR = ROOT / "art/bakeoff/luna/luna_brave-idle-v4.png"
BASE = ROOT / "smash-nine-prototype/assets/art/luna/luna_brave_sheet.png"
MOVES = ROOT / "smash-nine-prototype/assets/art/luna/luna_brave_moves_sheet.png"


ROWS = {
	"walk": ("luna_brave-walk-v1.png", 128, BASE, 1, 6),
	"jump": ("luna_brave-jump-v1.png", 128, BASE, 2, 1),
	"fall": ("luna_brave-fall-v1.png", 128, BASE, 3, 1),
	"hurt": ("luna_brave-hurt-v1.png", 128, BASE, 6, 1),
	"shield": ("luna_brave-shield-v1.png", 128, BASE, 5, 6),
	"attack": ("luna_brave-attack-v1.png", 128, BASE, 4, 4),
	"brave_combo": ("luna_brave-brave_combo-v1.png", 192, MOVES, 0, 6),
	"brave_upper": ("luna_brave-brave_upper-v1.png", 192, MOVES, 1, 4),
	"brave_low": ("luna_brave-brave_low-v1.png", 192, MOVES, 2, 4),
	"brave_air_side": ("luna_brave-brave_air_side-v1.png", 192, MOVES, 3, 4),
	"brave_dive": ("luna_brave-brave_dive-v1.png", 192, MOVES, 4, 4),
	"comet_drive": ("luna_brave-comet_drive-v1.png", 192, MOVES, 5, 4),
	"luna_breaker": ("luna_brave-luna_breaker-v1.png", 192, MOVES, 6, 6),
	"heart_laser": ("luna_brave-heart_laser-v1.png", 192, MOVES, 7, 6),
	"tumble": ("luna_brave-tumble-v1.png", 192, MOVES, 8, 4),
}


def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
	name = "arialbd.ttf" if bold else "arial.ttf"
	path = Path("C:/Windows/Fonts") / name
	return ImageFont.truetype(str(path), size) if path.exists() else ImageFont.load_default()


def checker(size: tuple[int, int], tile: int = 32) -> Image.Image:
	image = Image.new("RGBA", size, (31, 42, 61, 255))
	draw = ImageDraw.Draw(image)
	for y in range(0, size[1], tile):
		for x in range(0, size[0], tile):
			if (x // tile + y // tile) % 2:
				draw.rectangle((x, y, x + tile - 1, y + tile - 1), fill=(39, 53, 75, 255))
	return image


def cell(sheet: Image.Image, index: int, source_cell: int = 128) -> Image.Image:
	return sheet.crop((index * source_cell, 0, (index + 1) * source_cell, source_cell))


def atlas_cell(sheet: Image.Image, row: int, index: int) -> Image.Image:
	return sheet.crop((index * 128, row * 128, (index + 1) * 128, (row + 1) * 128))


def padded(frame: Image.Image, target_cell: int) -> Image.Image:
	if target_cell == 128:
		return frame
	canvas = Image.new("RGBA", (target_cell, target_cell), (0, 0, 0, 0))
	canvas.alpha_composite(frame, ((target_cell - 128) // 2, 32))
	return canvas


def render_row(frames: list[Image.Image], columns: int, target_cell: int, feet_y: int) -> Image.Image:
	scale = 4
	width = columns * target_cell * scale
	height = target_cell * scale
	row = checker((width, height))
	for index, frame in enumerate(frames):
		large = frame.resize((target_cell * scale, target_cell * scale), Image.Resampling.NEAREST)
		row.alpha_composite(large, (index * target_cell * scale, 0))
	draw = ImageDraw.Draw(row)
	draw.line((0, feet_y * scale, width, feet_y * scale), fill=(255, 52, 92, 255), width=3)
	for index in range(columns + 1):
		x = index * target_cell * scale
		draw.line((x, 0, x, height), fill=(75, 93, 122, 255), width=2)
	return row


anchor_sheet = Image.open(ANCHOR).convert("RGBA")
base_sheet = Image.open(BASE).convert("RGBA")
moves_sheet = Image.open(MOVES).convert("RGBA")

for name, (candidate_name, target_cell, current_path, current_row, current_frames) in ROWS.items():
	candidate_path = ROOT / "art/bakeoff/luna" / candidate_name
	candidate_sheet = Image.open(candidate_path).convert("RGBA")
	frames = 1 if name in {"jump", "fall", "hurt"} else 6
	columns = max(frames, current_frames)
	feet_y = 120 if target_cell == 128 else 152

	anchor_frames = [padded(cell(anchor_sheet, index % 6), target_cell) for index in range(columns)]
	current_sheet = base_sheet if current_path == BASE else moves_sheet
	current = [padded(atlas_cell(current_sheet, current_row, index), target_cell) for index in range(current_frames)]
	candidate = [cell(candidate_sheet, index, target_cell) for index in range(frames)]

	rows = [
		("CHOSEN V4 ANCHOR", render_row(anchor_frames, columns, target_cell, feet_y)),
		("CURRENT GAME ROW", render_row(current, columns, target_cell, feet_y)),
		("NEW CANDIDATE", render_row(candidate, columns, target_cell, feet_y)),
	]
	label_width = 230
	header_height = 54
	row_height = target_cell * 4
	canvas = Image.new("RGBA", (label_width + columns * target_cell * 4, header_height + row_height * 3), (13, 19, 31, 255))
	draw = ImageDraw.Draw(canvas)
	draw.text((14, 10), f"BRAVE LUNA {name.upper()} — 4X", font=font(26, True), fill=(245, 248, 255, 255))
	draw.text((14, 38), f"cell {target_cell}px, feet y={feet_y}; same game-pixel scale", font=font(12), fill=(172, 190, 219, 255))
	for row_index, (label, image) in enumerate(rows):
		y = header_height + row_index * row_height
		draw.text((14, y + 14), label, font=font(15, True), fill=(230, 236, 248, 255))
		canvas.alpha_composite(image, (label_width, y))
	canvas.convert("RGB").save(REPORT / name / "compare.png", quality=95)


# Compact one-page view of every finished candidate at native pixel scale.
panel_width = 1216
panel_height = 250
overview_columns = 2
overview_rows = (len(ROWS) + overview_columns - 1) // overview_columns
overview = Image.new("RGBA", (panel_width * overview_columns, panel_height * overview_rows), (13, 19, 31, 255))
overview_draw = ImageDraw.Draw(overview)
for item_index, (name, (candidate_name, target_cell, _current_path, _current_row, _current_frames)) in enumerate(ROWS.items()):
	x0 = (item_index % overview_columns) * panel_width
	y0 = (item_index // overview_columns) * panel_height
	candidate_path = ROOT / "art/bakeoff/luna" / candidate_name
	candidate = Image.open(candidate_path).convert("RGBA")
	metrics = json.loads((REPORT / name / "metrics.json").read_text(encoding="utf-8"))
	head = json.loads((REPORT / name / "head_scale.json").read_text(encoding="utf-8"))
	if isinstance(head, list):
		head = head[0]
	head_text = "auto n/a" if head.get("median") is None else f"head {head['median']:.2f}"
	used_frames = 1 if name in {"jump", "fall", "hurt"} else 6
	label = f"{name}  |  {used_frames}f  |  factor {metrics['summary']['common_scale']:.6f}  |  {head_text}"
	overview_draw.text((x0 + 14, y0 + 10), label, font=font(16, True), fill=(239, 244, 255, 255))
	back = checker((panel_width - 28, panel_height - 46), tile=16)
	overview.alpha_composite(back, (x0 + 14, y0 + 38))
	px = x0 + 14 + (panel_width - 28 - candidate.width) // 2
	py = y0 + 38 + (panel_height - 46 - candidate.height) // 2
	overview.alpha_composite(candidate, (px, py))
	overview_draw.rectangle((x0, y0, x0 + panel_width - 1, y0 + panel_height - 1), outline=(61, 78, 105, 255), width=2)

overview.convert("RGB").save(REPORT / "overview.png", quality=95)
