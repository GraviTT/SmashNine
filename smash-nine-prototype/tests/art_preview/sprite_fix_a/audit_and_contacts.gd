extends SceneTree
## CODEX-ART-09 frame audit. Reads the eight v2 sheets, writes enlarged review contacts
## plus per-frame measurements. It never modifies source sheets.

const CELL := 128
const SCALE := 4
const ROW_COUNTS := [4, 6, 1, 1, 4, 6, 1]
const ROW_NAMES := ["idle", "walk", "jump", "fall", "attack", "shield", "hurt"]
const SHEETS := [
	{"id": "frey", "path": "res://assets/art/frey/frey_sheet.png"},
	{"id": "yuki", "path": "res://assets/art/yuki/yuki_sheet.png"},
	{"id": "luna", "path": "res://assets/art/luna/luna_sheet.png"},
	{"id": "luna_brave", "path": "res://assets/art/luna/luna_brave_sheet.png"},
	{"id": "nova_male", "path": "res://assets/art/nova/nova_male_sheet.png"},
	{"id": "nova_female", "path": "res://assets/art/nova/nova_female_sheet.png"},
	{"id": "rio_male", "path": "res://assets/art/rio/rio_male_sheet.png"},
	{"id": "rio_female", "path": "res://assets/art/rio/rio_female_sheet.png"},
]
const REPORT_DIR := "res://../reports/codex-art-09"
var _contact_dir := ""


func _initialize() -> void:
	var suffix := "after" if "--after" in OS.get_cmdline_user_args() else "before"
	_contact_dir = REPORT_DIR + "/review_contacts_" + suffix
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_contact_dir))
	var csv := "sheet,row,column,bbox_left,bbox_top,bbox_right,bbox_bottom,width,height,feet_y,centroid_x,opaque_px,outer4_px,components,largest_component,second_component,tiny_components,longest_left_edge,longest_right_edge,longest_top_edge,longest_bottom_edge\n"
	for spec: Dictionary in SHEETS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(spec.path))
		if image == null:
			push_error("Missing sheet: %s" % spec.path)
			continue
		image.convert(Image.FORMAT_RGBA8)
		if image.get_size() != Vector2i(768, 896):
			push_error("Unexpected sheet size for %s: %s" % [spec.id, image.get_size()])
			continue
		if "--contacts" in OS.get_cmdline_user_args():
			_build_contact(spec.id, image)
		for row in 7:
			for column in ROW_COUNTS[row]:
				var frame := image.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
				csv += _measure_frame(spec.id, row, column, frame)
	var csv_path := ProjectSettings.globalize_path(REPORT_DIR + "/frame_metrics_%s.csv" % suffix)
	var file := FileAccess.open(csv_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s" % csv_path)
		quit(1)
		return
	file.store_string(csv)
	file.close()
	print("SPRITE_FIX_A_AUDIT_OK sheets=%d frames=%d" % [SHEETS.size(), 184])
	quit(0)


func _build_contact(id: String, sheet: Image) -> void:
	var scaled_cell := CELL * SCALE
	var board := Image.create_empty(6 * scaled_cell, 7 * scaled_cell, false, Image.FORMAT_RGBA8)
	_fill_checker(board, 16)
	for row in 7:
		for column in ROW_COUNTS[row]:
			var frame := sheet.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
			frame.resize(scaled_cell, scaled_cell, Image.INTERPOLATE_NEAREST)
			board.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(column * scaled_cell, row * scaled_cell))
	var output := _contact_dir + "/%s_review_4x.png" % id
	var error := board.save_png(ProjectSettings.globalize_path(output))
	if error != OK:
		push_error("Cannot save %s: %s" % [output, error])


func _fill_checker(image: Image, tile: int) -> void:
	var dark := Color8(20, 27, 42, 255)
	var light := Color8(35, 45, 64, 255)
	for y in image.get_height():
		for x in image.get_width():
			image.set_pixel(x, y, dark if ((x / tile) + (y / tile)) % 2 == 0 else light)


func _measure_frame(id: String, row: int, column: int, frame: Image) -> String:
	var left := CELL
	var top := CELL
	var right := -1
	var bottom := -1
	var opaque := 0
	var outer4 := 0
	var sum_x := 0.0
	for y in CELL:
		for x in CELL:
			if frame.get_pixel(x, y).a < 0.5:
				continue
			opaque += 1
			sum_x += x
			left = mini(left, x)
			top = mini(top, y)
			right = maxi(right, x)
			bottom = maxi(bottom, y)
			if x < 4 or y < 4 or x >= CELL - 4 or y >= CELL - 4:
				outer4 += 1
	var components := _component_sizes(frame)
	components.sort()
	components.reverse()
	var largest := components[0] if not components.is_empty() else 0
	var second := components[1] if components.size() > 1 else 0
	var tiny := 0
	for size: int in components:
		if size <= 8:
			tiny += 1
	var edges := _longest_bbox_edge_runs(frame, Rect2i(left, top, right - left + 1, bottom - top + 1))
	var width := right - left + 1
	var height := bottom - top + 1
	var centroid := sum_x / float(opaque) if opaque > 0 else -1.0
	return "%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%.3f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n" % [
		id, ROW_NAMES[row], column, left, top, right, bottom, width, height, bottom,
		centroid, opaque, outer4, components.size(), largest, second, tiny,
		edges.left, edges.right, edges.top, edges.bottom
	]


func _component_sizes(frame: Image) -> Array[int]:
	var visited := PackedByteArray()
	visited.resize(CELL * CELL)
	var sizes: Array[int] = []
	var directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for y in CELL:
		for x in CELL:
			var index := y * CELL + x
			if visited[index] != 0 or frame.get_pixel(x, y).a < 0.5:
				continue
			var queue: Array[Vector2i] = [Vector2i(x, y)]
			visited[index] = 1
			var read_index := 0
			var size := 0
			while read_index < queue.size():
				var point := queue[read_index]
				read_index += 1
				size += 1
				for direction: Vector2i in directions:
					var next := point + direction
					if next.x < 0 or next.y < 0 or next.x >= CELL or next.y >= CELL:
						continue
					var next_index := next.y * CELL + next.x
					if visited[next_index] != 0 or frame.get_pixelv(next).a < 0.5:
						continue
					visited[next_index] = 1
					queue.append(next)
			sizes.append(size)
	return sizes


func _longest_bbox_edge_runs(frame: Image, bbox: Rect2i) -> Dictionary:
	if bbox.size.x <= 0 or bbox.size.y <= 0:
		return {"left": 0, "right": 0, "top": 0, "bottom": 0}
	return {
		"left": _longest_vertical_run(frame, bbox.position.x, bbox.position.y, bbox.end.y),
		"right": _longest_vertical_run(frame, bbox.end.x - 1, bbox.position.y, bbox.end.y),
		"top": _longest_horizontal_run(frame, bbox.position.y, bbox.position.x, bbox.end.x),
		"bottom": _longest_horizontal_run(frame, bbox.end.y - 1, bbox.position.x, bbox.end.x),
	}


func _longest_vertical_run(frame: Image, x: int, y_start: int, y_end: int) -> int:
	var longest := 0
	var current := 0
	for y in range(y_start, y_end):
		if frame.get_pixel(x, y).a >= 0.5:
			current += 1
			longest = maxi(longest, current)
		else:
			current = 0
	return longest


func _longest_horizontal_run(frame: Image, y: int, x_start: int, x_end: int) -> int:
	var longest := 0
	var current := 0
	for x in range(x_start, x_end):
		if frame.get_pixel(x, y).a >= 0.5:
			current += 1
			longest = maxi(longest, current)
		else:
			current = 0
	return longest
