extends SceneTree

## CODEX-ART-21 final sheet repair. All bitmap manipulation uses Godot Image API.

const CELL := 128
const COLS := 6
const ROWS := 7
const USED := [4, 6, 1, 1, 4, 6, 1]
const GROUND_ROWS := {0: true, 1: true, 4: true, 5: true, 6: true}
const SHEETS := {
	"frey": "res://assets/art/frey/frey_sheet.png",
	"luna": "res://assets/art/luna/luna_sheet.png",
	"luna_brave": "res://assets/art/luna/luna_brave_sheet.png",
}

var report := ""
var verification: Array[String] = ["sheet,row,column,changed,pixel_diff,reason"]

func _initialize() -> void:
	report = ProjectSettings.globalize_path("res://../reports/codex-art-21")
	var only_sheet := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sheet="):
			only_sheet = arg.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(report.path_join("contact"))
	DirAccess.make_dir_recursive_absolute(report.path_join("inspection/after_frames_4x"))
	DirAccess.make_dir_recursive_absolute(report.path_join("inspection/after_rows_4x"))
	for sheet_name in SHEETS:
		if not only_sheet.is_empty() and sheet_name != only_sheet:
			continue
		_build_sheet(sheet_name, SHEETS[sheet_name])
	var verification_name := "verification.csv" if only_sheet.is_empty() else "verification_%s.csv" % only_sheet
	var out := FileAccess.open(report.path_join(verification_name), FileAccess.WRITE)
	out.store_string("\n".join(verification) + "\n")
	print("ART21_BUILD complete selection=%s" % ("all" if only_sheet.is_empty() else only_sheet))
	quit(0)

func _build_sheet(sheet_name: String, path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	var baseline_path := report.path_join("contact/before/%s_sheet.png" % sheet_name)
	var before := Image.load_from_file(baseline_path) if FileAccess.file_exists(baseline_path) else Image.load_from_file(absolute)
	before.convert(Image.FORMAT_RGBA8)
	var after := before.duplicate() as Image

	if sheet_name == "frey":
		_replace_frame(after, 4, 3, report.path_join("generated_sources/frey_attack4_candidate_128.png"))
	elif sheet_name == "luna":
		_replace_frame(after, 0, 1, report.path_join("generated_sources/luna_idle2_candidate_128.png"))
		_replace_frame(after, 0, 2, report.path_join("generated_sources/luna_idle3_candidate_128.png"))

	for row in ROWS:
		for column in USED[row]:
			var rect := Rect2i(column * CELL, row * CELL, CELL, CELL)
			var frame := after.get_region(rect)
			if sheet_name != "frey":
				_hard_alpha(frame)
			if GROUND_ROWS.has(row):
				frame = _align_feet(frame, 120)
			after.fill_rect(rect, Color.TRANSPARENT)
			after.blit_rect(frame, Rect2i(0, 0, CELL, CELL), rect.position)

	var changed: Array[Vector2i] = []
	for row in ROWS:
		for column in COLS:
			var rect := Rect2i(column * CELL, row * CELL, CELL, CELL)
			var old_frame := before.get_region(rect)
			var new_frame := after.get_region(rect)
			var is_changed := old_frame.get_data() != new_frame.get_data()
			var diff := _pixel_diff(old_frame, new_frame)
			if is_changed:
				changed.append(Vector2i(column, row))
			var reason := _reason(sheet_name, row, column, is_changed)
			verification.append("%s,%d,%d,%s,%d,%s" % [sheet_name, row, column, str(is_changed), diff, reason])

	after.save_png(absolute)
	_make_contact(before, report.path_join("contact/%s_before_1x.png" % sheet_name), 1, changed, Color("#ff3d52"))
	_make_contact(before, report.path_join("contact/%s_before_4x.png" % sheet_name), 4, changed, Color("#ff3d52"))
	_make_contact(after, report.path_join("contact/%s_after_1x.png" % sheet_name), 1, changed, Color("#44df78"))
	_make_contact(after, report.path_join("contact/%s_after_4x.png" % sheet_name), 4, changed, Color("#44df78"))
	_make_after_inspection(sheet_name, after)
	print("ART21_BUILD_SHEET %s changed=%d unchanged=%d" % [sheet_name, changed.size(), 42 - changed.size()])

func _replace_frame(sheet: Image, row: int, column: int, source_path: String) -> void:
	var frame := Image.load_from_file(source_path)
	frame.convert(Image.FORMAT_RGBA8)
	var rect := Rect2i(column * CELL, row * CELL, CELL, CELL)
	sheet.fill_rect(rect, Color.TRANSPARENT)
	sheet.blit_rect(frame, Rect2i(0, 0, CELL, CELL), rect.position)

func _hard_alpha(frame: Image) -> void:
	for y in CELL:
		for x in CELL:
			var color := frame.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			if color.a < 0.5:
				frame.set_pixel(x, y, Color.TRANSPARENT)
			elif color.a < 1.0:
				color.a = 1.0
				frame.set_pixel(x, y, color)

func _align_feet(frame: Image, target_y: int) -> Image:
	var bottom := -1
	for y in CELL:
		for x in CELL:
			if frame.get_pixel(x, y).a >= 0.5:
				bottom = maxi(bottom, y)
	if bottom < 0 or bottom == target_y:
		return frame
	var shifted := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	shifted.fill(Color.TRANSPARENT)
	shifted.blit_rect(frame, Rect2i(0, 0, CELL, CELL), Vector2i(0, target_y - bottom))
	return shifted

func _pixel_diff(a: Image, b: Image) -> int:
	var count := 0
	for y in CELL:
		for x in CELL:
			if a.get_pixel(x, y).to_rgba32() != b.get_pixel(x, y).to_rgba32():
				count += 1
	return count

func _reason(sheet_name: String, row: int, column: int, changed: bool) -> String:
	if not changed:
		return "pixel-identical"
	if sheet_name == "frey" and row == 4 and column == 3:
		return "redraw-shield"
	if sheet_name == "luna" and row == 0 and column in [1, 2]:
		return "redraw-wand-head+alpha+baseline"
	if sheet_name == "frey":
		return "baseline"
	return "alpha-cutoff+baseline" if GROUND_ROWS.has(row) else "alpha-cutoff"

func _make_contact(sheet: Image, path: String, scale: int, changed: Array[Vector2i], marker: Color) -> void:
	var width := sheet.get_width() * scale
	var height := sheet.get_height() * scale
	var board := _checker(width, height, 16 * scale)
	var art := sheet.duplicate()
	if scale != 1:
		art.resize(width, height, Image.INTERPOLATE_NEAREST)
	board.blend_rect(art, Rect2i(0, 0, width, height), Vector2i.ZERO)
	for cell in changed:
		_box(board, cell.x * CELL * scale, cell.y * CELL * scale, CELL * scale, marker, maxi(1, scale))
	board.save_png(path)

func _make_after_inspection(sheet_name: String, sheet: Image) -> void:
	for row in 7:
		var count: int = USED[row]
		var side := CELL * 4
		var gap := 8
		var strip := _checker(count * side + (count - 1) * gap, side, 32)
		for column in count:
			var frame := sheet.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
			var large := frame.duplicate()
			large.resize(side, side, Image.INTERPOLATE_NEAREST)
			strip.blend_rect(large, Rect2i(0, 0, side, side), Vector2i(column * (side + gap), 0))
			var single := _checker(side, side, 32)
			single.blend_rect(large, Rect2i(0, 0, side, side), Vector2i.ZERO)
			single.save_png(report.path_join("inspection/after_frames_4x/%s_r%dc%d.png" % [sheet_name, row, column]))
		strip.save_png(report.path_join("inspection/after_rows_4x/%s_r%d.png" % [sheet_name, row]))

func _checker(width: int, height: int, tile: int) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color("#30343b"))
	for y in range(0, height, tile):
		for x in range(0, width, tile):
			if ((x / tile) as int + (y / tile) as int) % 2 != 0:
				image.fill_rect(Rect2i(x, y, mini(tile, width - x), mini(tile, height - y)), Color("#464b55"))
	return image

func _box(image: Image, x0: int, y0: int, size: int, color: Color, thickness: int) -> void:
	image.fill_rect(Rect2i(x0, y0, size, thickness), color)
	image.fill_rect(Rect2i(x0, y0 + size - thickness, size, thickness), color)
	image.fill_rect(Rect2i(x0, y0, thickness, size), color)
	image.fill_rect(Rect2i(x0 + size - thickness, y0, thickness, size), color)
