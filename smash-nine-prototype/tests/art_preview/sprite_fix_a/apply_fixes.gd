extends SceneTree
## CODEX-ART-09 one-shot repair builder. Always reads the preserved report snapshots,
## so rerunning does not compound scaling or cleanup.

const CELL := 128
const FEET_Y := 120
const CENTER_X := 64
const SCALE := 4
const REPORT_DIR := "res://../reports/codex-art-09"
const SOURCE_EFFECTS := REPORT_DIR + "/sprite_effect_fix_source.png"
const TRANSPARENT := Color(0, 0, 0, 0)

const SHEETS := [
	{
		"id": "frey", "before": REPORT_DIR + "/original_sheets/frey_sheet.png",
		"output": "res://assets/art/frey/frey_sheet.png",
		"frames": [Vector2i(2, 4), Vector2i(3, 4)]
	},
	{
		"id": "nova_male", "before": REPORT_DIR + "/original_sheets/nova_male_sheet.png",
		"output": "res://assets/art/nova/nova_male_sheet.png",
		"frames": [Vector2i(2, 4)]
	},
	{
		"id": "nova_female", "before": REPORT_DIR + "/original_sheets/nova_female_sheet.png",
		"output": "res://assets/art/nova/nova_female_sheet.png",
		"frames": [Vector2i(2, 4), Vector2i(3, 4)]
	},
	{
		"id": "luna", "before": REPORT_DIR + "/original_sheets/luna_sheet.png",
		"output": "res://assets/art/luna/luna_sheet.png",
		"frames": [Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]
	},
	{
		"id": "luna_brave", "before": REPORT_DIR + "/original_sheets/luna_brave_sheet.png",
		"output": "res://assets/art/luna/luna_brave_sheet.png",
		"frames": [Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]
	},
	{
		"id": "rio_male", "before": REPORT_DIR + "/original_sheets/rio_male_sheet.png",
		"output": "res://assets/art/rio/rio_male_sheet.png",
		"frames": [Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5)]
	},
	{
		"id": "rio_female", "before": REPORT_DIR + "/original_sheets/rio_female_sheet.png",
		"output": "res://assets/art/rio/rio_female_sheet.png",
		"frames": [Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5)]
	},
]

const FREY_PALETTE := [
	Color8(247, 251, 255), Color8(183, 220, 255), Color8(67, 139, 210),
	Color8(255, 212, 94), Color8(42, 70, 119), Color8(20, 33, 66)
]
const NOVA_PALETTE := [
	Color8(239, 255, 255), Color8(84, 244, 244), Color8(0, 190, 211),
	Color8(8, 116, 154), Color8(255, 216, 74), Color8(24, 48, 91)
]
const LUNA_PALETTE := [
	Color8(255, 247, 255), Color8(238, 146, 255), Color8(190, 77, 255),
	Color8(255, 75, 210), Color8(113, 82, 218), Color8(255, 216, 77), Color8(35, 42, 93)
]

var _effects: Image
var _comparison_index := "sheet,sequence,pair_row,pair_column,animation_row,column\n"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR + "/before_after"))
	_effects = Image.load_from_file(ProjectSettings.globalize_path(SOURCE_EFFECTS))
	if _effects == null:
		push_error("Missing generated effect source: %s" % SOURCE_EFFECTS)
		quit(1)
		return
	_effects.convert(Image.FORMAT_RGBA8)
	var failures: Array[String] = []
	for spec: Dictionary in SHEETS:
		var before := Image.load_from_file(ProjectSettings.globalize_path(spec.before))
		if before == null:
			failures.append("missing before snapshot %s" % spec.before)
			continue
		before.convert(Image.FORMAT_RGBA8)
		var after := before.duplicate()
		_apply_sheet_fixes(spec.id, after)
		_validate_sheet(spec, before, after, failures)
		var error: Error = after.save_png(ProjectSettings.globalize_path(spec.output))
		if error != OK:
			failures.append("save failed %s (%s)" % [spec.output, error])
		_build_comparison(spec, before, after)
	var index_file := FileAccess.open(ProjectSettings.globalize_path(REPORT_DIR + "/before_after/index.csv"), FileAccess.WRITE)
	if index_file == null:
		failures.append("cannot write comparison index")
	else:
		index_file.store_string(_comparison_index)
		index_file.close()
	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		quit(1)
		return
	print("SPRITE_FIX_A_APPLY_OK sheets=%d changed_frames=%d unchanged_frames_pixel_identical=true" % [SHEETS.size(), 31])
	quit(0)


func _apply_sheet_fixes(id: String, sheet: Image) -> void:
	match id:
		"frey":
			_taper_frey_thrust(sheet)
			_repair_cut_effect(sheet, 4, 3, [Rect2i(0, 20, 50, 86)], -1, -1, Vector2i.ZERO, Vector2i.ZERO, FREY_PALETTE)
		"nova_male":
			_repair_cut_effect(sheet, 4, 2, [Rect2i(91, 34, 37, 62)], 1, 0, Vector2i(29, 24), Vector2i(91, 56), NOVA_PALETTE)
		"nova_female":
			_repair_cut_effect(sheet, 4, 2, [Rect2i(91, 34, 37, 66)], 1, 0, Vector2i(29, 24), Vector2i(91, 58), NOVA_PALETTE)
			_repair_cut_effect(sheet, 4, 3, [Rect2i(0, 30, 45, 74)], -1, -1, Vector2i.ZERO, Vector2i.ZERO, NOVA_PALETTE)
			_cleanup_cell(sheet, 4, 3, 1000)
		"luna":
			_keep_luna_wand_remove_barrier(sheet)
			_repair_cut_effect(sheet, 4, 2, [Rect2i(0, 30, 35, 82)], -1, -1, Vector2i.ZERO, Vector2i.ZERO, LUNA_PALETTE)
			_repair_cut_effect(sheet, 4, 3, [Rect2i(0, 30, 38, 82)], -1, -1, Vector2i.ZERO, Vector2i.ZERO, LUNA_PALETTE)
		"luna_brave":
			_repair_cut_effect(sheet, 4, 1, [Rect2i(97, 32, 31, 82)], -1, -1, Vector2i.ZERO, Vector2i.ZERO, LUNA_PALETTE)
			_repair_cut_effect(sheet, 4, 2, [Rect2i(0, 30, 37, 82)], -1, -1, Vector2i.ZERO, Vector2i.ZERO, LUNA_PALETTE)
			_repair_cut_effect(sheet, 4, 3, [Rect2i(0, 28, 24, 88), Rect2i(101, 28, 27, 88)], 2, 1, Vector2i(24, 25), Vector2i(92, 57), LUNA_PALETTE)
		"rio_male":
			_repair_rio(sheet, [Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5)], false)
		"rio_female":
			_repair_rio(sheet, [Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5)], true)


func _repair_cut_effect(sheet: Image, row: int, column: int, erase_rects: Array, effect_row: int, effect_column: int, effect_size: Vector2i, effect_position: Vector2i, palette: Array) -> void:
	var frame := _cell(sheet, row, column)
	for rect: Rect2i in erase_rects:
		_fill_rect(frame, rect, TRANSPARENT)
	_remove_tiny_components(frame, 8, false)
	if effect_row >= 0:
		var effect := _effect_cell(effect_row, effect_column, effect_size, palette)
		frame.blend_rect(effect, Rect2i(Vector2i.ZERO, effect.get_size()), effect_position)
	frame = _safe_recenter(frame)
	_write_cell(sheet, row, column, frame)


func _repair_rio(sheet: Image, frames: Array, female: bool) -> void:
	for coord: Vector2i in frames:
		var frame := _cell(sheet, coord.y, coord.x)
		# Rio's cut-looking bars are complete components sliced from neighbouring cells.
		# Attack frames keep one connected body/effect component; female attack 0 also
		# keeps its intentionally separated overhead blade and reconnects it below.
		var keep_count := 2 if coord.y == 5 or (female and coord == Vector2i(0, 4)) else 1
		_keep_largest_components(frame, keep_count)
		if coord.y == 5:
			_remove_narrow_components(frame, 10, 12)
		if female and coord == Vector2i(0, 4):
			_bridge_two_largest(frame, Color8(19, 37, 66), Color8(105, 214, 255))
		frame = _safe_recenter(frame)
		_write_cell(sheet, coord.y, coord.x, frame)


func _taper_frey_thrust(sheet: Image) -> void:
	var frame := _cell(sheet, 4, 2)
	# Preserve the existing sword and turn its former flat crop into a narrowing point.
	for x in range(98, 117):
		var half_height := maxi(0, floori(float(116 - x) * 0.48))
		for y in range(48, 86):
			if absi(y - 67) > half_height:
				frame.set_pixel(x, y, TRANSPARENT)
	frame = _safe_recenter(frame)
	_write_cell(sheet, 4, 2, frame)


func _keep_luna_wand_remove_barrier(sheet: Image) -> void:
	var frame := _cell(sheet, 4, 1)
	# The gold/white star wand is part of Luna's accepted design. Remove only the
	# blue-violet generated barrier that was clipped on the right.
	var bright_mask := PackedByteArray()
	bright_mask.resize(CELL * CELL)
	var wand_region := Rect2i(88, 53, 20, 23)
	for y in range(wand_region.position.y, wand_region.end.y):
		for x in range(wand_region.position.x, wand_region.end.x):
			var color := frame.get_pixel(x, y)
			var white := color.a >= 0.5 and color.r8 > 185 and color.g8 > 185 and color.b8 > 185
			var gold := color.a >= 0.5 and color.r8 > 175 and color.g8 > 105 and color.b8 < 135
			if white or gold:
				bright_mask[y * CELL + x] = 1
	for y in range(28, 114):
		for x in range(89, CELL):
			if frame.get_pixel(x, y).a < 0.5:
				continue
			var near_bright := false
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var sample := Vector2i(x + ox, y + oy)
					if wand_region.has_point(sample) and bright_mask[sample.y * CELL + sample.x] != 0:
						near_bright = true
			if not near_bright:
				frame.set_pixel(x, y, TRANSPARENT)
	_remove_tiny_components(frame, 10, false)
	frame = _safe_recenter(frame)
	_write_cell(sheet, 4, 1, frame)


func _cleanup_cell(sheet: Image, row: int, column: int, threshold: int) -> void:
	var frame := _cell(sheet, row, column)
	_remove_tiny_components(frame, threshold, false)
	frame = _safe_recenter(frame)
	_write_cell(sheet, row, column, frame)


func _keep_largest_components(image: Image, keep_count: int) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var offsets: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
		Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	var components: Array = []
	for start_y in height:
		for start_x in width:
			var start_index := start_y * width + start_x
			if visited[start_index] != 0 or image.get_pixel(start_x, start_y).a < 0.5:
				continue
			var stack: Array[Vector2i] = [Vector2i(start_x, start_y)]
			var component: Array[Vector2i] = []
			visited[start_index] = 1
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				component.append(point)
				for offset: Vector2i in offsets:
					var next: Vector2i = point + offset
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var next_index: int = next.y * width + next.x
					if visited[next_index] == 0 and image.get_pixelv(next).a >= 0.5:
						visited[next_index] = 1
						stack.append(next)
			components.append(component)
	components.sort_custom(func(a: Array, b: Array) -> bool: return a.size() > b.size())
	for index in range(keep_count, components.size()):
		for point: Vector2i in components[index]:
			image.set_pixelv(point, TRANSPARENT)


func _remove_narrow_components(image: Image, maximum_width: int, minimum_height: int) -> void:
	var components := _collect_components(image)
	for component: Array in components:
		var left := CELL
		var top := CELL
		var right := -1
		var bottom := -1
		for point: Vector2i in component:
			left = mini(left, point.x)
			top = mini(top, point.y)
			right = maxi(right, point.x)
			bottom = maxi(bottom, point.y)
		if right - left + 1 > maximum_width or bottom - top + 1 < minimum_height:
			continue
		for point: Vector2i in component:
			image.set_pixelv(point, TRANSPARENT)


func _bridge_two_largest(image: Image, outline: Color, core: Color) -> void:
	var components := _collect_components(image)
	components.sort_custom(func(a: Array, b: Array) -> bool: return a.size() > b.size())
	if components.size() < 2:
		return
	var a: Array = components[0]
	var b: Array = components[1]
	var best_a: Vector2i
	var best_b: Vector2i
	var best_distance := INF
	for point_a: Vector2i in a:
		for point_b: Vector2i in b:
			var distance := point_a.distance_squared_to(point_b)
			if distance < best_distance:
				best_distance = distance
				best_a = point_a
				best_b = point_b
	_draw_pixel_line(image, best_a, best_b, outline, 1)
	_draw_pixel_line(image, best_a, best_b, core, 0)


func _draw_pixel_line(image: Image, start: Vector2i, finish: Vector2i, color: Color, radius: int) -> void:
	var delta := finish - start
	var steps := maxi(absi(delta.x), absi(delta.y))
	for step in range(steps + 1):
		var t := float(step) / maxf(1.0, steps)
		var point := Vector2i(roundi(lerpf(start.x, finish.x, t)), roundi(lerpf(start.y, finish.y, t)))
		for oy in range(-radius, radius + 1):
			for ox in range(-radius, radius + 1):
				var target := point + Vector2i(ox, oy)
				if target.x >= 0 and target.y >= 0 and target.x < CELL and target.y < CELL:
					image.set_pixelv(target, color)


func _collect_components(image: Image) -> Array:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var offsets: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
		Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	var components: Array = []
	for start_y in height:
		for start_x in width:
			var start_index := start_y * width + start_x
			if visited[start_index] != 0 or image.get_pixel(start_x, start_y).a < 0.5:
				continue
			var stack: Array[Vector2i] = [Vector2i(start_x, start_y)]
			var component: Array[Vector2i] = []
			visited[start_index] = 1
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				component.append(point)
				for offset: Vector2i in offsets:
					var next: Vector2i = point + offset
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var next_index: int = next.y * width + next.x
					if visited[next_index] == 0 and image.get_pixelv(next).a >= 0.5:
						visited[next_index] = 1
						stack.append(next)
			components.append(component)
	return components


func _effect_cell(row: int, column: int, target_size: Vector2i, palette: Array) -> Image:
	var source_cell_size := Vector2i(_effects.get_width() / 4, _effects.get_height() / 4)
	var cell := _effects.get_region(Rect2i(column * source_cell_size.x, row * source_cell_size.y, source_cell_size.x, source_cell_size.y))
	var bounds := _alpha_bounds(cell, 0.12)
	if bounds.size == Vector2i.ZERO:
		return Image.create_empty(target_size.x, target_size.y, false, Image.FORMAT_RGBA8)
	cell = cell.get_region(bounds)
	cell.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	for y in cell.get_height():
		for x in cell.get_width():
			var color := cell.get_pixel(x, y)
			if color.a < 0.38:
				cell.set_pixel(x, y, TRANSPARENT)
				continue
			cell.set_pixel(x, y, _nearest_color(color, palette))
	_remove_tiny_components(cell, 2, false)
	return cell


func _nearest_color(color: Color, palette: Array) -> Color:
	var best: Color = palette[0]
	var best_distance := INF
	for candidate: Color in palette:
		var dr := color.r - candidate.r
		var dg := color.g - candidate.g
		var db := color.b - candidate.b
		var distance := dr * dr + dg * dg + db * db
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return Color(best.r, best.g, best.b, 1.0)


func _remove_tiny_components(image: Image, maximum_size: int, edge_only: bool) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var offsets: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
		Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	for start_y in height:
		for start_x in width:
			var start_index := start_y * width + start_x
			if visited[start_index] != 0 or image.get_pixel(start_x, start_y).a < 0.5:
				continue
			var stack: Array[Vector2i] = [Vector2i(start_x, start_y)]
			var component: Array[Vector2i] = []
			var touches_margin := false
			visited[start_index] = 1
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				component.append(point)
				touches_margin = touches_margin or point.x < 4 or point.y < 4 or point.x >= width - 4 or point.y >= height - 4
				for offset: Vector2i in offsets:
					var next: Vector2i = point + offset
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var next_index: int = next.y * width + next.x
					if visited[next_index] == 0 and image.get_pixelv(next).a >= 0.5:
						visited[next_index] = 1
						stack.append(next)
			if component.size() > maximum_size or (edge_only and not touches_margin):
				continue
			for point: Vector2i in component:
				image.set_pixelv(point, TRANSPARENT)


func _safe_recenter(frame: Image) -> Image:
	var bounds := _alpha_bounds(frame)
	if bounds.size == Vector2i.ZERO:
		return frame
	var crop := frame.get_region(bounds)
	var scale := minf(1.0, 120.0 / float(crop.get_width()))
	scale = minf(scale, 117.0 / float(crop.get_height()))
	var initial_bounds := _alpha_bounds(crop)
	var initial_centroid := _alpha_centroid_x(crop, initial_bounds)
	var left_radius := initial_centroid - initial_bounds.position.x
	var right_radius := initial_bounds.end.x - 1 - initial_centroid
	scale = minf(scale, 60.0 / maxf(1.0, left_radius))
	scale = minf(scale, 59.0 / maxf(1.0, right_radius))
	if scale < 1.0:
		crop.resize(maxi(1, floori(crop.get_width() * scale)), maxi(1, floori(crop.get_height() * scale)), Image.INTERPOLATE_NEAREST)
	var crop_bounds := _alpha_bounds(crop)
	var centroid_x := _alpha_centroid_x(crop, crop_bounds)
	var destination := Vector2i(roundi(CENTER_X - centroid_x), FEET_Y - (crop_bounds.end.y - 1))
	destination.x = clampi(destination.x, 4 - crop_bounds.position.x, 124 - crop_bounds.end.x)
	destination.y = maxi(destination.y, 4 - crop_bounds.position.y)
	var output := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
	output.fill(TRANSPARENT)
	output.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), destination)
	return output


func _validate_sheet(spec: Dictionary, before: Image, after: Image, failures: Array[String]) -> void:
	var fixed: Dictionary = {}
	for coord: Vector2i in spec.frames:
		fixed[coord] = true
	for row in 7:
		for column in 6:
			var coord := Vector2i(column, row)
			var before_cell := _cell(before, row, column)
			var after_cell := _cell(after, row, column)
			if not fixed.has(coord) and before_cell.get_data() != after_cell.get_data():
				failures.append("%s r%dc%d changed outside declared fixes" % [spec.id, row, column])
			if fixed.has(coord):
				if before_cell.get_data() == after_cell.get_data():
					failures.append("%s r%dc%d declared but unchanged" % [spec.id, row, column])
				var bounds := _alpha_bounds(after_cell)
				if bounds.position.x < 4 or bounds.position.y < 4 or bounds.end.x > 124 or bounds.end.y > 124:
					failures.append("%s r%dc%d violates 4px margin: %s" % [spec.id, row, column, bounds])
				if bounds.end.y - 1 != FEET_Y:
					failures.append("%s r%dc%d feet=%d" % [spec.id, row, column, bounds.end.y - 1])


func _build_comparison(spec: Dictionary, before: Image, after: Image) -> void:
	var frames: Array = spec.frames
	var pair_width := CELL * SCALE * 2
	var pair_height := CELL * SCALE
	var pairs_per_row := 2
	var rows := ceili(float(frames.size()) / pairs_per_row)
	var board := Image.create_empty(pair_width * pairs_per_row, pair_height * rows, false, Image.FORMAT_RGBA8)
	_fill_checker(board, 16)
	for index in frames.size():
		var coord: Vector2i = frames[index]
		var pair_column := index % pairs_per_row
		var pair_row := floori(float(index) / pairs_per_row)
		var before_cell := _cell(before, coord.y, coord.x)
		var after_cell := _cell(after, coord.y, coord.x)
		before_cell.resize(CELL * SCALE, CELL * SCALE, Image.INTERPOLATE_NEAREST)
		after_cell.resize(CELL * SCALE, CELL * SCALE, Image.INTERPOLATE_NEAREST)
		var base := Vector2i(pair_column * pair_width, pair_row * pair_height)
		board.blend_rect(before_cell, Rect2i(Vector2i.ZERO, before_cell.get_size()), base)
		board.blend_rect(after_cell, Rect2i(Vector2i.ZERO, after_cell.get_size()), base + Vector2i(CELL * SCALE, 0))
		_comparison_index += "%s,%d,%d,%d,%d,%d\n" % [spec.id, index, pair_row, pair_column, coord.y, coord.x]
	var output := REPORT_DIR + "/before_after/%s_before_after_4x.png" % spec.id
	var error: Error = board.save_png(ProjectSettings.globalize_path(output))
	if error != OK:
		push_error("Cannot save comparison %s" % output)


func _cell(sheet: Image, row: int, column: int) -> Image:
	return sheet.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))


func _write_cell(sheet: Image, row: int, column: int, frame: Image) -> void:
	sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, Vector2i(CELL, CELL)), Vector2i(column * CELL, row * CELL))


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			image.set_pixel(x, y, color)


func _fill_checker(image: Image, tile: int) -> void:
	var dark := Color8(20, 27, 42, 255)
	var light := Color8(35, 45, 64, 255)
	for y in image.get_height():
		for x in image.get_width():
			var checker := floori(float(x) / tile) + floori(float(y) / tile)
			image.set_pixel(x, y, dark if checker % 2 == 0 else light)


func _alpha_bounds(image: Image, threshold: float = 0.5) -> Rect2i:
	var left := image.get_width()
	var top := image.get_height()
	var right := -1
	var bottom := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < threshold:
				continue
			left = mini(left, x)
			top = mini(top, y)
			right = maxi(right, x)
			bottom = maxi(bottom, y)
	if right < left or bottom < top:
		return Rect2i()
	return Rect2i(left, top, right - left + 1, bottom - top + 1)


func _alpha_centroid_x(image: Image, bounds: Rect2i) -> float:
	var sum_x := 0.0
	var count := 0
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			if image.get_pixel(x, y).a < 0.5:
				continue
			sum_x += x
			count += 1
	return sum_x / maxf(1.0, count)
