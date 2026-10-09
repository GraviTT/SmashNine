extends SceneTree

## CODEX-ART-21 frame-by-frame measurement and inspection renderer.
## This script is deliberately self-contained and only writes below reports/codex-art-21/.

const CELL := 128
const COLS := 6
const ROWS := 7
const USED := [4, 6, 1, 1, 4, 6, 1]
const ROW_NAMES := ["idle", "walk", "jump", "fall", "attack", "shield", "hurt"]
const SHEETS := {
	"frey": "res://assets/art/frey/frey_sheet.png",
	"luna": "res://assets/art/luna/luna_sheet.png",
	"luna_brave": "res://assets/art/luna/luna_brave_sheet.png",
}

var out_dir := ""
var csv: Array[String] = [
	"sheet,row,column,animation,opaque_px,partial_alpha_px,alpha_min_nonzero,alpha_max,"
	+ "left,top,right,bottom,width,height,centroid_x,centroid_y,feet_y,ground_gap,"
	+ "unique_rgba,edge_px,holes,unused_nonzero"
]

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://../reports/codex-art-21")
	DirAccess.make_dir_recursive_absolute(out_dir.path_join("inspection/frames_4x"))
	DirAccess.make_dir_recursive_absolute(out_dir.path_join("inspection/rows_4x"))
	DirAccess.make_dir_recursive_absolute(out_dir.path_join("contact/before"))
	for sheet_name in SHEETS:
		_audit_sheet(sheet_name, SHEETS[sheet_name])
	var measurements_path := out_dir.path_join("measurements.csv")
	if not FileAccess.file_exists(measurements_path):
		var file := FileAccess.open(measurements_path, FileAccess.WRITE)
		file.store_string("\n".join(csv) + "\n")
	else:
		print("ART21_AUDIT preserving existing before measurements: " + measurements_path)
	print("ART21_AUDIT rows=%d out=%s" % [csv.size() - 1, out_dir])
	quit(0)

func _audit_sheet(sheet_name: String, path: String) -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(path))
	if sheet == null or sheet.is_empty():
		push_error("Cannot load " + path)
		return
	sheet.convert(Image.FORMAT_RGBA8)
	if sheet.get_size() != Vector2i(COLS * CELL, ROWS * CELL):
		push_error("Wrong sheet dimensions: %s %s" % [path, sheet.get_size()])
		return
	var baseline_path := out_dir.path_join("contact/before/%s_sheet.png" % sheet_name)
	if not FileAccess.file_exists(baseline_path):
		sheet.save_png(baseline_path)
		_make_contact(sheet, out_dir.path_join("contact/before/%s_1x.png" % sheet_name), 1)
		_make_contact(sheet, out_dir.path_join("contact/before/%s_4x.png" % sheet_name), 4)
	for row in ROWS:
		var row_path := out_dir.path_join("inspection/rows_4x/%s_r%d_%s.png" % [sheet_name, row, ROW_NAMES[row]])
		if not FileAccess.file_exists(row_path):
			_make_row_strip(sheet_name, sheet, row)
		for column in COLS:
			var frame := sheet.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
			var info := _measure(frame)
			var unused_nonzero := int(info.nonzero) if column >= USED[row] else 0
			if column < USED[row]:
				var frame_board := _checker(CELL * 4, CELL * 4, 32)
				var enlarged := frame.duplicate()
				enlarged.resize(CELL * 4, CELL * 4, Image.INTERPOLATE_NEAREST)
				frame_board.blend_rect(enlarged, Rect2i(0, 0, CELL * 4, CELL * 4), Vector2i.ZERO)
				var frame_path := out_dir.path_join("inspection/frames_4x/%s_r%dc%d_%s.png" % [sheet_name, row, column, ROW_NAMES[row]])
				if not FileAccess.file_exists(frame_path):
					frame_board.save_png(frame_path)
				csv.append(_csv_line(sheet_name, row, column, info, unused_nonzero))
			elif unused_nonzero > 0:
				csv.append(_csv_line(sheet_name, row, column, info, unused_nonzero))

func _csv_line(sheet_name: String, row: int, column: int, info: Dictionary, unused_nonzero: int) -> String:
	return "%s,%d,%d,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%.3f,%.3f,%d,%d,%d,%d,%d,%d" % [
		sheet_name, row, column, ROW_NAMES[row], info.opaque, info.partial, info.alpha_min,
		info.alpha_max, info.left, info.top, info.right, info.bottom, info.width, info.height,
		info.cx, info.cy, info.feet_y, 120 - int(info.feet_y), info.unique, info.edge_px,
		info.holes, unused_nonzero
	]

func _measure(frame: Image) -> Dictionary:
	var left := CELL
	var top := CELL
	var right := -1
	var bottom := -1
	var opaque := 0
	var partial := 0
	var nonzero := 0
	var alpha_min := 255
	var alpha_max := 0
	var sum_x := 0.0
	var sum_y := 0.0
	var colors := {}
	var edge_px := 0
	for y in CELL:
		for x in CELL:
			var color := frame.get_pixel(x, y)
			var a := int(round(color.a * 255.0))
			if a == 0:
				continue
			nonzero += 1
			alpha_min = mini(alpha_min, a)
			alpha_max = maxi(alpha_max, a)
			if a < 255:
				partial += 1
			if a >= 128:
				opaque += 1
				left = mini(left, x)
				top = mini(top, y)
				right = maxi(right, x)
				bottom = maxi(bottom, y)
				sum_x += x
				sum_y += y
				if x == 0 or y == 0 or x == CELL - 1 or y == CELL - 1:
					edge_px += 1
			var rgba := color.to_rgba32()
			colors[rgba] = true
	var holes := _count_holes(frame, left, top, right, bottom)
	return {
		"left": left if opaque > 0 else -1, "top": top if opaque > 0 else -1,
		"right": right, "bottom": bottom,
		"width": right - left + 1 if opaque > 0 else 0,
		"height": bottom - top + 1 if opaque > 0 else 0,
		"opaque": opaque, "partial": partial, "nonzero": nonzero,
		"alpha_min": alpha_min if nonzero > 0 else 0, "alpha_max": alpha_max,
		"cx": sum_x / opaque if opaque > 0 else -1.0,
		"cy": sum_y / opaque if opaque > 0 else -1.0,
		"feet_y": bottom, "unique": colors.size(), "edge_px": edge_px, "holes": holes,
	}

func _count_holes(frame: Image, left: int, top: int, right: int, bottom: int) -> int:
	if right < left:
		return 0
	var visited := PackedByteArray()
	visited.resize(CELL * CELL)
	var queue: Array[Vector2i] = []
	for x in range(left, right + 1):
		for y in [top, bottom]:
			if frame.get_pixel(x, y).a < 0.5:
				queue.append(Vector2i(x, y))
	for y in range(top, bottom + 1):
		for x in [left, right]:
			if frame.get_pixel(x, y).a < 0.5:
				queue.append(Vector2i(x, y))
	_flood_clear(frame, queue, visited, left, top, right, bottom)
	var holes := 0
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			var idx := y * CELL + x
			if visited[idx] == 0 and frame.get_pixel(x, y).a < 0.5:
				holes += 1
				_flood_clear(frame, [Vector2i(x, y)], visited, left, top, right, bottom)
	return holes

func _flood_clear(frame: Image, initial: Array[Vector2i], visited: PackedByteArray, left: int, top: int, right: int, bottom: int) -> void:
	var queue := initial.duplicate()
	var at := 0
	while at < queue.size():
		var p: Vector2i = queue[at]
		at += 1
		if p.x < left or p.x > right or p.y < top or p.y > bottom:
			continue
		var idx := p.y * CELL + p.x
		if visited[idx] != 0 or frame.get_pixel(p.x, p.y).a >= 0.5:
			continue
		visited[idx] = 1
		queue.append(p + Vector2i.LEFT)
		queue.append(p + Vector2i.RIGHT)
		queue.append(p + Vector2i.UP)
		queue.append(p + Vector2i.DOWN)

func _make_row_strip(sheet_name: String, sheet: Image, row: int) -> void:
	var count: int = USED[row]
	var gap := 8
	var scale := 4
	var side := CELL * scale
	var strip := _checker(count * side + (count - 1) * gap, side, 32)
	for column in count:
		var frame := sheet.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
		frame.resize(side, side, Image.INTERPOLATE_NEAREST)
		strip.blend_rect(frame, Rect2i(0, 0, side, side), Vector2i(column * (side + gap), 0))
	strip.save_png(out_dir.path_join("inspection/rows_4x/%s_r%d_%s.png" % [sheet_name, row, ROW_NAMES[row]]))

func _make_contact(sheet: Image, path: String, scale: int) -> void:
	var width := sheet.get_width() * scale
	var height := sheet.get_height() * scale
	var board := _checker(width, height, 16 * scale)
	var enlarged := sheet.duplicate()
	if scale != 1:
		enlarged.resize(width, height, Image.INTERPOLATE_NEAREST)
	board.blend_rect(enlarged, Rect2i(0, 0, width, height), Vector2i.ZERO)
	for col in range(1, COLS):
		_draw_vline(board, col * CELL * scale, Color(0.25, 0.75, 1.0, 0.75))
	for row in range(1, ROWS):
		_draw_hline(board, row * CELL * scale, Color(0.25, 0.75, 1.0, 0.75))
	path = path.replace("_sheet_", "_")
	board.save_png(path)

func _checker(width: int, height: int, tile: int) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color("#30343b"))
	for y in range(0, height, tile):
		for x in range(0, width, tile):
			if ((x / tile) as int + (y / tile) as int) % 2 != 0:
				image.fill_rect(Rect2i(x, y, mini(tile, width - x), mini(tile, height - y)), Color("#464b55"))
	return image

func _draw_vline(image: Image, x: int, color: Color) -> void:
	if x < 0 or x >= image.get_width():
		return
	for y in image.get_height():
		image.set_pixel(x, y, color)

func _draw_hline(image: Image, y: int, color: Color) -> void:
	if y < 0 or y >= image.get_height():
		return
	for x in image.get_width():
		image.set_pixel(x, y, color)
