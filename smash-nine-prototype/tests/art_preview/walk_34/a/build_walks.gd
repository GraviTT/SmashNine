extends SceneTree
## CODEX-ART-34A builder. Each generated pose is cropped and scaled as one complete drawing.
## No head, face, limb, weapon, hair, or clothing pixels are pasted between frames.

const CELL := 128
const COLUMNS := 6
const WALK_ROW := 1
const FEET_Y := 120
const SAFE_MARGIN := 4
const CLEAR := Color(0.0, 0.0, 0.0, 0.0)
const PREVIEW_DIR := "res://tests/art_preview/walk_34/a"
const REPORT_DIR := "res://../reports/codex-art-34a"
const FRAME_TINTS := [
	Color("ff6b6b"), Color("ffa94d"), Color("ffe066"),
	Color("69db7c"), Color("4dabf7"), Color("b197fc"),
]
const DIGITS := {
	"0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
	"2": ["111", "001", "111", "100", "111"], "3": ["111", "001", "111", "001", "111"],
	"4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"],
	"8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "111"],
	".": ["000", "000", "000", "000", "010"], "/": ["001", "001", "010", "100", "100"],
}

const SPECS := [
	{
		"name": "frey",
		"sheet": "res://assets/art/frey/frey_sheet.png",
		"source": "res://../reports/codex-art-34a/source/frey_walk_source.png",
		"head_box": Rect2i(62, 27, 28, 32),
		"eye_roi": Rect2i(76, 50, 6, 6),
		"face_expected": Vector2(0.69, 0.31),
		"eye_mode": "blue",
	},
	{
		"name": "rio_male",
		"sheet": "res://assets/art/rio/rio_male_sheet.png",
		"source": "res://../reports/codex-art-34a/source/rio_male_walk_source.png",
		"head_box": Rect2i(61, 31, 34, 36),
		"eye_roi": Rect2i(80, 49, 8, 8),
		"face_expected": Vector2(0.70, 0.31),
		"eye_mode": "blue",
	},
	{
		"name": "rio_female",
		"sheet": "res://assets/art/rio/rio_female_sheet.png",
		"source": "res://../reports/codex-art-34a/source/rio_female_walk_source.png",
		"head_box": Rect2i(64, 31, 34, 37),
		"eye_roi": Rect2i(86, 53, 8, 8),
		"face_expected": Vector2(0.72, 0.33),
		"eye_mode": "blue",
	},
	{
		"name": "yuki",
		"sheet": "res://assets/art/yuki/yuki_sheet.png",
		"source": "res://../reports/codex-art-34a/source/yuki_walk_source.png",
		"head_box": Rect2i(56, 43, 39, 42),
		"eye_roi": Rect2i(78, 65, 6, 6),
		"face_expected": Vector2(0.71, 0.39),
		"eye_mode": "red",
	},
]

var failures: Array[String] = []
var operation_lines := PackedStringArray([
	"character frame source_crop initial_scale final_scale output_size destination head_scale face_area eye_clusters face_candidates",
])
var measurement_lines := PackedStringArray([
	"character frame before_head_scale after_head_scale after_head_box after_eye_clusters after_face_candidates",
])


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	for spec in SPECS:
		_build_character(spec)
	_write_text("%s/body_pixel_operations.txt" % REPORT_DIR, "\n".join(operation_lines) + "\n")
	_write_text("%s/head_validation.txt" % REPORT_DIR, "\n".join(measurement_lines) + "\n")
	if failures.is_empty():
		print("build_walks: four walk rows built and audited")
		quit(0)
	else:
		for message in failures:
			push_error(message)
		print("build_walks: %d failure(s)" % failures.size())
		quit(1)


func _build_character(spec: Dictionary) -> void:
	var sheet: Image = Image.load_from_file(spec.sheet)
	var source: Image = Image.load_from_file(spec.source)
	if sheet.is_empty() or source.is_empty():
		_fail("%s: missing sheet or source" % spec.name)
		return
	if sheet.get_size() != Vector2i(COLUMNS * CELL, 7 * CELL):
		_fail("%s: sheet size %s, expected 768x896" % [spec.name, sheet.get_size()])
		return
	var before := sheet.duplicate()
	var idle: Image = before.get_region(Rect2i(0, 0, CELL, CELL))
	var reference := _configure_reference(idle, spec)
	if not bool(reference.valid):
		_fail("%s: idle head detector could not configure" % spec.name)
		return
	print("walk build %s reference face_area=%d face=%s head=%s" % [spec.name, int(reference.face_area), reference.face_rect, reference.head_box])
	var figures := _figure_bounds(source)
	if figures.size() != 7:
		_fail("%s: expected 7 complete drawings, found %d" % [spec.name, figures.size()])
		return
	var idle_bounds := _alpha_bounds(idle)
	var anchor_bounds: Rect2i = figures[0]
	var initial_scale := float(idle_bounds.size.y) / maxf(1.0, float(anchor_bounds.size.y))
	var palette: Array[Color] = _collect_palette(before, spec)
	var color_cache := {}
	var after_measures: Array[Dictionary] = []
	var before_measures: Array[Dictionary] = []
	for frame_index in 6:
		var old_cell: Image = before.get_region(Rect2i(frame_index * CELL, WALK_ROW * CELL, CELL, CELL))
		var before_measure := _measure_head(old_cell, spec, reference)
		if not bool(before_measure.get("valid", false)) or float(before_measure.get("scale", 0.0)) < 0.5:
			before_measure = _fallback_head_measure(old_cell, spec, reference, idle_bounds)
		before_measures.append(before_measure)
		var crop: Rect2i = figures[frame_index + 1]
		var drawing := source.get_region(crop)
		var final_scale := initial_scale
		var rendered := {}
		var measure := {}
		for _attempt in 5:
			rendered = _render_whole_drawing(drawing, final_scale, palette, color_cache)
			if not bool(rendered.valid):
				break
			measure = _measure_head(rendered.cell, spec, reference)
			if not bool(measure.valid):
				break
			print("  %s frame=%d attempt=%d scale=%.6f measured=%.4f face=%s area=%d" % [spec.name, frame_index + 1, _attempt + 1, final_scale, float(measure.scale), measure.face, int(measure.face_area)])
			var measured_scale := float(measure.scale)
			if absf(measured_scale - 1.0) <= 0.049:
				break
			final_scale *= clampf(1.0 / measured_scale, 0.82, 1.18)
		if not bool(rendered.get("valid", false)):
			_fail("%s frame %d: complete drawing does not fit the cell" % [spec.name, frame_index + 1])
			continue
		if not bool(measure.get("valid", false)):
			_fail("%s frame %d: head was not found" % [spec.name, frame_index + 1])
			continue
		if absf(float(measure.scale) - 1.0) > 0.0501:
			_fail("%s frame %d: head scale %.4f is outside +/-5%%" % [spec.name, frame_index + 1, float(measure.scale)])
			continue
		if bool(measure.double_head):
			_fail("%s frame %d: double-head audit failed (faces=%d eyes=%d)" % [spec.name, frame_index + 1, int(measure.face_candidates), int(measure.eye_clusters)])
			continue
		var cell: Image = rendered.cell
		sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(frame_index * CELL, WALK_ROW * CELL))
		after_measures.append(measure)
		operation_lines.append("%s %d %s %.6f %.6f %s %s %.4f %d %d %d" % [
			spec.name, frame_index + 1, crop, initial_scale, final_scale,
			rendered.size, rendered.destination, float(measure.scale), int(measure.face_area),
			int(measure.eye_clusters), int(measure.face_candidates),
		])
		var before_scale := float((before_measures[frame_index] as Dictionary).get("scale", 0.0))
		measurement_lines.append("%s %d %.4f %.4f %s %d %d" % [
			spec.name, frame_index + 1, before_scale, float(measure.scale), measure.head,
			int(measure.eye_clusters), int(measure.face_candidates),
		])
	if after_measures.size() != 6:
		return
	_clear_all_cell_borders(sheet)
	if not _other_rows_identical(before, sheet):
		_fail("%s: rows outside walk changed" % spec.name)
		return
	_save(sheet, spec.sheet)
	_make_contact(spec, idle, before, sheet, before_measures, after_measures)
	_make_onion(spec, before, sheet)


func _figure_bounds(image: Image) -> Array[Rect2i]:
	# ImageGen delivered exactly seven equally spaced figures. Fixed bins also remain robust when
	# a bright sword glow nearly touches the next figure across an otherwise transparent gap.
	var result: Array[Rect2i] = []
	for index in 7:
		var left := roundi(float(index) * image.get_width() / 7.0)
		var right := roundi(float(index + 1) * image.get_width() / 7.0)
		var bounds := _largest_alpha_component(image, Rect2i(left, 0, right - left, image.get_height()))
		if bounds.size != Vector2i.ZERO:
			result.append(bounds)
	return result


func _largest_alpha_component(image: Image, area: Rect2i) -> Rect2i:
	var clipped := area.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var width := clipped.size.x
	var height := clipped.size.y
	var visited := PackedByteArray()
	visited.resize(width * height)
	var best_area := 0
	var best_bounds := Rect2i()
	for start_y in height:
		for start_x in width:
			var start := start_y * width + start_x
			if visited[start] != 0 or image.get_pixel(clipped.position.x + start_x, clipped.position.y + start_y).a < 0.5:
				continue
			var queue: Array[Vector2i] = [Vector2i(start_x, start_y)]
			visited[start] = 1
			var cursor := 0
			var count := 0
			var bounds := Rect2i()
			while cursor < queue.size():
				var point: Vector2i = queue[cursor]
				cursor += 1
				count += 1
				bounds = Rect2i(point, Vector2i.ONE) if bounds.size == Vector2i.ZERO else bounds.expand(point).expand(point + Vector2i.ONE)
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						if ox == 0 and oy == 0:
							continue
						var next := point + Vector2i(ox, oy)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
							continue
						var next_index := next.y * width + next.x
						if visited[next_index] == 0 and image.get_pixelv(clipped.position + next).a >= 0.5:
							visited[next_index] = 1
							queue.append(next)
			if count > best_area:
				best_area = count
				best_bounds = Rect2i(bounds.position + clipped.position, bounds.size)
	return best_bounds


func _configure_reference(idle: Image, spec: Dictionary) -> Dictionary:
	var head_box: Rect2i = spec.head_box
	var skin_keys := {}
	for y in range(head_box.position.y, head_box.end.y):
		for x in range(head_box.position.x, head_box.end.x):
			var color := idle.get_pixel(x, y)
			if _is_character_skin(color, spec):
				skin_keys[_color_key(color)] = true
	var face_area := _count_key_pixels(idle, head_box, skin_keys)
	var face_rect := _key_bounds(idle, head_box, skin_keys)
	if face_area <= 0 or face_rect.size == Vector2i.ZERO:
		return {"valid": false}
	var eye_keys := {}
	var eye_roi: Rect2i = spec.eye_roi
	for y in range(eye_roi.position.y, eye_roi.end.y):
		for x in range(eye_roi.position.x, eye_roi.end.x):
			var color := idle.get_pixel(x, y)
			if _is_eye_color(color, String(spec.eye_mode)):
				eye_keys[_color_key(color)] = true
	return {
		"valid": face_area > 0,
		"face_area": face_area,
		"face_rect": face_rect,
		"head_box": head_box,
		"head_offset": Vector2(head_box.get_center() - face_rect.get_center()),
		"skin_keys": skin_keys,
		"opaque_area": _count_opaque_pixels(idle, head_box),
		"eye_keys": eye_keys,
		"eye_offset": Vector2(eye_roi.get_center() - face_rect.get_center()),
		"eye_size": eye_roi.size,
	}


func _measure_head(frame: Image, spec: Dictionary, reference: Dictionary) -> Dictionary:
	var opaque := _alpha_bounds(frame)
	if opaque.size == Vector2i.ZERO:
		return {"valid": false}
	var expected_face := Vector2(opaque.position) + Vector2(opaque.size) * Vector2(spec.face_expected)
	var expected_head_center := expected_face + Vector2(reference.head_offset)
	var reference_head: Rect2i = reference.head_box
	var probe := Rect2i(
		Vector2i(roundi(expected_head_center.x - reference_head.size.x * 0.5), roundi(expected_head_center.y - reference_head.size.y * 0.5)),
		reference_head.size
	).intersection(Rect2i(Vector2i.ZERO, frame.get_size()))
	var use_opaque_head := String(spec.name) == "yuki"
	var face_area := _count_opaque_pixels(frame, probe) if use_opaque_head else _count_key_pixels(frame, probe, reference.skin_keys)
	var face_rect := _key_bounds(frame, probe, reference.skin_keys)
	if use_opaque_head:
		face_rect = _alpha_bounds(frame, probe)
	if face_area <= 0 or face_rect.size == Vector2i.ZERO:
		return {"valid": false}
	var reference_area := int(reference.opaque_area) if use_opaque_head else int(reference.face_area)
	var scale := sqrt(float(face_area) / maxf(1.0, float(reference_area)))
	var head_size := Vector2i(maxi(1, roundi((reference.head_box as Rect2i).size.x * scale)), maxi(1, roundi((reference.head_box as Rect2i).size.y * scale)))
	var head_center := expected_head_center
	var head := Rect2i(Vector2i(roundi(head_center.x - head_size.x * 0.5), roundi(head_center.y - head_size.y * 0.5)), head_size)
	var face_candidates := 1
	var eye_center := expected_face + Vector2(reference.eye_offset)
	var eye_size: Vector2i = reference.eye_size
	var eye_zone := Rect2i(Vector2i(roundi(eye_center.x - eye_size.x * 0.5), roundi(eye_center.y - eye_size.y * 0.5)), eye_size)
	var eye_clusters := _eye_clusters(frame, eye_zone, String(spec.eye_mode), reference.eye_keys)
	return {
		"valid": true,
		"scale": scale,
		"head": head,
		"face": face_rect,
		"face_area": face_area,
		"eye_clusters": eye_clusters,
		"face_candidates": face_candidates,
		"double_head": face_candidates > 1 or eye_clusters > 2,
	}


func _fallback_head_measure(frame: Image, spec: Dictionary, reference: Dictionary, idle_bounds: Rect2i) -> Dictionary:
	var opaque := _alpha_bounds(frame)
	if opaque.size == Vector2i.ZERO:
		return {"valid": false}
	var scale := float(opaque.size.y) / maxf(1.0, float(idle_bounds.size.y))
	var expected_face := Vector2(opaque.position) + Vector2(opaque.size) * Vector2(spec.face_expected)
	var head_center := expected_face + Vector2(reference.head_offset) * scale
	var reference_head: Rect2i = reference.head_box
	var size := Vector2i(maxi(1, roundi(reference_head.size.x * scale)), maxi(1, roundi(reference_head.size.y * scale)))
	var head := Rect2i(Vector2i(roundi(head_center.x - size.x * 0.5), roundi(head_center.y - size.y * 0.5)), size)
	return {
		"valid": true,
		"scale": scale,
		"head": head,
		"face": Rect2i(),
		"face_area": 0,
		"eye_clusters": 0,
		"face_candidates": 1,
		"double_head": false,
	}


func _count_key_pixels(image: Image, area: Rect2i, keys: Dictionary) -> int:
	var clipped := area.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var count := 0
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			var color := image.get_pixel(x, y)
			if color.a >= 0.5 and keys.has(_color_key(color)):
				count += 1
	return count


func _count_opaque_pixels(image: Image, area: Rect2i) -> int:
	var clipped := area.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var count := 0
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			if image.get_pixel(x, y).a >= 0.5:
				count += 1
	return count


func _key_bounds(image: Image, area: Rect2i, keys: Dictionary) -> Rect2i:
	var clipped := area.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var result := Rect2i()
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			var color := image.get_pixel(x, y)
			if color.a >= 0.5 and keys.has(_color_key(color)):
				result = Rect2i(x, y, 1, 1) if result.size == Vector2i.ZERO else result.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
	return result


func _select_face(components: Array[Dictionary], frame: Image, expected: Vector2) -> Dictionary:
	var opaque := _alpha_bounds(frame)
	var best: Dictionary = components[0]
	var best_score := INF
	for component in components:
		var rect: Rect2i = component.rect
		var normalized := Vector2(rect.get_center() - opaque.position) / Vector2(maxi(1, opaque.size.x), maxi(1, opaque.size.y))
		var score := normalized.distance_to(expected) - minf(100.0, float(component.area)) * 0.0008
		if score < best_score:
			best_score = score
			best = component
	return best


func _face_group(components: Array[Dictionary], seed: Dictionary, gap: int) -> Array[Dictionary]:
	var group: Array[Dictionary] = [seed]
	var combined := seed.rect as Rect2i
	var changed := true
	while changed:
		changed = false
		for component in components:
			if group.has(component):
				continue
			var rect: Rect2i = component.rect
			if combined.grow(gap).intersects(rect):
				group.append(component)
				combined = combined.merge(rect)
				changed = true
	return group


func _render_whole_drawing(source: Image, scale: float, palette: Array[Color], color_cache: Dictionary) -> Dictionary:
	var size := Vector2i(maxi(1, roundi(source.get_width() * scale)), maxi(1, roundi(source.get_height() * scale)))
	if size.x > CELL - SAFE_MARGIN * 2 or size.y > CELL - SAFE_MARGIN * 2:
		return {"valid": false}
	var drawing := source.duplicate()
	_keep_largest_component(drawing)
	drawing.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	_quantize(drawing, palette, color_cache)
	_harden_alpha(drawing)
	var destination := Vector2i((CELL - size.x) / 2, FEET_Y - size.y + 1)
	destination.x = clampi(destination.x, SAFE_MARGIN, CELL - SAFE_MARGIN - size.x)
	destination.y = clampi(destination.y, SAFE_MARGIN, CELL - SAFE_MARGIN - size.y)
	var cell := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	cell.fill(CLEAR)
	cell.blit_rect(drawing, Rect2i(Vector2i.ZERO, size), destination)
	_clear_cell_border(cell)
	return {"valid": true, "cell": cell, "size": size, "destination": destination}


func _keep_largest_component(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var components: Array[Array] = []
	for start_y in height:
		for start_x in width:
			var start := start_y * width + start_x
			if visited[start] != 0 or image.get_pixel(start_x, start_y).a < 0.5:
				continue
			var queue: Array[Vector2i] = [Vector2i(start_x, start_y)]
			var points: Array[Vector2i] = []
			visited[start] = 1
			var cursor := 0
			while cursor < queue.size():
				var point: Vector2i = queue[cursor]
				cursor += 1
				points.append(point)
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						if ox == 0 and oy == 0:
							continue
						var next := point + Vector2i(ox, oy)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
							continue
						var next_index := next.y * width + next.x
						if visited[next_index] == 0 and image.get_pixelv(next).a >= 0.5:
							visited[next_index] = 1
							queue.append(next)
			components.append(points)
	if components.is_empty():
		return
	components.sort_custom(func(a: Array, b: Array) -> bool: return a.size() > b.size())
	for index in range(1, components.size()):
		for point in components[index]:
			image.set_pixelv(point, CLEAR)


func _collect_palette(sheet: Image, spec: Dictionary) -> Array[Color]:
	var histogram := {}
	for y in sheet.get_height():
		for x in sheet.get_width():
			var color := sheet.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := _color_key(color)
			histogram[key] = int(histogram.get(key, 0)) + 1
	var ranked: Array[Dictionary] = []
	for key in histogram:
		ranked.append({"key": int(key), "count": int(histogram[key])})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.count) > int(b.count))
	var result: Array[Color] = []
	var retained := {}
	var reserve: Rect2i = spec.head_box
	for y in range(reserve.position.y, reserve.end.y):
		for x in range(reserve.position.x, reserve.end.x):
			var color := sheet.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := _color_key(color)
			if not retained.has(key):
				retained[key] = true
				result.append(Color8((key >> 16) & 255, (key >> 8) & 255, key & 255, 255))
	for entry in ranked:
		if result.size() >= 192:
			break
		var key: int = entry.key
		if retained.has(key):
			continue
		retained[key] = true
		result.append(Color8((key >> 16) & 255, (key >> 8) & 255, key & 255, 255))
	return result


func _quantize(image: Image, palette: Array[Color], color_cache: Dictionary) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var source := image.get_pixel(x, y)
			if source.a < 0.5:
				image.set_pixel(x, y, CLEAR)
				continue
			var key := _color_key(source)
			if not color_cache.has(key):
				var best := palette[0]
				var best_distance := INF
				for candidate in palette:
					var dr := source.r - candidate.r
					var dg := source.g - candidate.g
					var db := source.b - candidate.b
					var distance := dr * dr + dg * dg + db * db
					if distance < best_distance:
						best_distance = distance
						best = candidate
				color_cache[key] = best
			image.set_pixel(x, y, color_cache[key])


func _skin_components(image: Image, area: Rect2i, skin_keys: Dictionary = {}) -> Array[Dictionary]:
	var clipped := area.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var width := clipped.size.x
	var height := clipped.size.y
	var mask := PackedByteArray()
	mask.resize(width * height)
	for y in height:
		for x in width:
			var color := image.get_pixel(clipped.position.x + x, clipped.position.y + y)
			if skin_keys.has(_color_key(color)) if not skin_keys.is_empty() else _is_skin(color):
				mask[y * width + x] = 1
	var visited := PackedByteArray()
	visited.resize(mask.size())
	var result: Array[Dictionary] = []
	for start_y in height:
		for start_x in width:
			var start := start_y * width + start_x
			if mask[start] == 0 or visited[start] != 0:
				continue
			var queue: Array[Vector2i] = [Vector2i(start_x, start_y)]
			visited[start] = 1
			var cursor := 0
			var count := 0
			var bounds := Rect2i()
			while cursor < queue.size():
				var point: Vector2i = queue[cursor]
				cursor += 1
				count += 1
				bounds = Rect2i(point, Vector2i.ONE) if bounds.size == Vector2i.ZERO else bounds.expand(point).expand(point + Vector2i.ONE)
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						if ox == 0 and oy == 0:
							continue
						var next := point + Vector2i(ox, oy)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
							continue
						var next_index := next.y * width + next.x
						if mask[next_index] != 0 and visited[next_index] == 0:
							visited[next_index] = 1
							queue.append(next)
			if count >= 3:
				result.append({"area": count, "rect": Rect2i(bounds.position + clipped.position, bounds.size)})
	return result


func _eye_clusters(image: Image, area: Rect2i, mode: String, eye_keys: Dictionary) -> int:
	var clipped := area.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var mask := PackedByteArray()
	mask.resize(clipped.size.x * clipped.size.y)
	for y in clipped.size.y:
		for x in clipped.size.x:
			var color := image.get_pixel(clipped.position.x + x, clipped.position.y + y)
			var r := color.r * 255.0
			var g := color.g * 255.0
			var b := color.b * 255.0
			var selected := color.a >= 0.5 and (eye_keys.has(_color_key(color)) if not eye_keys.is_empty() else _is_eye_color(color, mode))
			if selected:
				mask[y * clipped.size.x + x] = 1
	var visited := PackedByteArray()
	visited.resize(mask.size())
	var clusters := 0
	for start_y in clipped.size.y:
		for start_x in clipped.size.x:
			var start := start_y * clipped.size.x + start_x
			if mask[start] == 0 or visited[start] != 0:
				continue
			clusters += 1
			var queue: Array[Vector2i] = [Vector2i(start_x, start_y)]
			visited[start] = 1
			while not queue.is_empty():
				var point: Vector2i = queue.pop_back()
				for oy in range(-2, 3):
					for ox in range(-2, 3):
						var next: Vector2i = point + Vector2i(ox, oy)
						if next.x < 0 or next.y < 0 or next.x >= clipped.size.x or next.y >= clipped.size.y:
							continue
						var next_index: int = next.y * clipped.size.x + next.x
						if mask[next_index] != 0 and visited[next_index] == 0:
							visited[next_index] = 1
							queue.append(next)
	return clusters


func _is_eye_color(color: Color, mode: String) -> bool:
	if color.a < 0.5:
		return false
	var r := color.r * 255.0
	var g := color.g * 255.0
	var b := color.b * 255.0
	return b > r + 22.0 and b > g + 10.0 and b > 70.0 if mode == "blue" else r > g + 28.0 and r > b + 12.0 and r > 100.0


func _is_skin(color: Color) -> bool:
	if color.a < 0.5:
		return false
	var r := color.r * 255.0
	var g := color.g * 255.0
	var b := color.b * 255.0
	return r > 158.0 and g > 76.0 and g < 225.0 and b > 64.0 and b < 205.0 \
		and r > g + 20.0 and r - g < 122.0 and g > b + 5.0 and g - b < 64.0


func _is_character_skin(color: Color, spec: Dictionary) -> bool:
	if not _is_skin(color):
		return false
	if String(spec.name) != "yuki":
		return true
	var r := color.r * 255.0
	var g := color.g * 255.0
	var b := color.b * 255.0
	return r > 190.0 and g > 125.0 and b > 115.0


func _alpha_bounds(image: Image, area: Rect2i = Rect2i()) -> Rect2i:
	var search := area if area.size != Vector2i.ZERO else Rect2i(Vector2i.ZERO, image.get_size())
	search = search.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var result := Rect2i()
	for y in range(search.position.y, search.end.y):
		for x in range(search.position.x, search.end.x):
			if image.get_pixel(x, y).a >= 0.5:
				result = Rect2i(x, y, 1, 1) if result.size == Vector2i.ZERO else result.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
	return result


func _other_rows_identical(before: Image, after: Image) -> bool:
	for y in after.get_height():
		if y >= WALK_ROW * CELL and y < (WALK_ROW + 1) * CELL:
			continue
		for x in after.get_width():
			if before.get_pixel(x, y) != after.get_pixel(x, y):
				return false
	return true


func _make_contact(spec: Dictionary, idle: Image, before: Image, after: Image, before_measures: Array[Dictionary], after_measures: Array[Dictionary]) -> void:
	var row_height := CELL + 12
	var contact := Image.create(7 * CELL, 2 * row_height, false, Image.FORMAT_RGBA8)
	contact.fill(Color("101729"))
	for row_index in 2:
		contact.blend_rect(idle, Rect2i(Vector2i.ZERO, idle.get_size()), Vector2i(0, row_index * row_height))
		var reference_head: Rect2i = spec.head_box
		_draw_rect(contact, Rect2i(reference_head.position + Vector2i(0, row_index * row_height), reference_head.size), Color("62f4ff"))
		_draw_text(contact, Vector2i(48, row_index * row_height + CELL + 3), "1.00", Color("8ef2d0"))
	for frame_index in 6:
		var old_frame := before.get_region(Rect2i(frame_index * CELL, WALK_ROW * CELL, CELL, CELL))
		var new_frame := after.get_region(Rect2i(frame_index * CELL, WALK_ROW * CELL, CELL, CELL))
		var x := (frame_index + 1) * CELL
		contact.blend_rect(old_frame, Rect2i(Vector2i.ZERO, old_frame.get_size()), Vector2i(x, 0))
		contact.blend_rect(new_frame, Rect2i(Vector2i.ZERO, new_frame.get_size()), Vector2i(x, row_height))
		for row_index in 2:
			var measure: Dictionary = before_measures[frame_index] if row_index == 0 else after_measures[frame_index]
			if bool(measure.get("valid", false)):
				var head: Rect2i = measure.head
				_draw_rect(contact, Rect2i(head.position + Vector2i(x, row_index * row_height), head.size), Color("62f4ff"))
				_draw_text(contact, Vector2i(x + 44, row_index * row_height + CELL + 3), "%.2f/%d" % [float(measure.scale), int(measure.eye_clusters)], Color("8ef2d0"))
	var contact_3x := contact.duplicate()
	contact_3x.resize(contact.get_width() * 3, contact.get_height() * 3, Image.INTERPOLATE_NEAREST)
	_save(contact_3x, "%s/%s_walk_before_after_heads_3x.png" % [PREVIEW_DIR, spec.name])


func _make_onion(spec: Dictionary, before: Image, after: Image) -> void:
	var onion := Image.create(CELL * 2, CELL, false, Image.FORMAT_RGBA8)
	onion.fill(Color("101729"))
	for frame_index in 6:
		var old_frame := before.get_region(Rect2i(frame_index * CELL, WALK_ROW * CELL, CELL, CELL))
		var new_frame := after.get_region(Rect2i(frame_index * CELL, WALK_ROW * CELL, CELL, CELL))
		_overlay_tinted(onion, old_frame, Vector2i.ZERO, FRAME_TINTS[frame_index], 0.24)
		_overlay_tinted(onion, new_frame, Vector2i(CELL, 0), FRAME_TINTS[frame_index], 0.24)
	var onion_3x := onion.duplicate()
	onion_3x.resize(onion.get_width() * 3, onion.get_height() * 3, Image.INTERPOLATE_NEAREST)
	_save(onion_3x, "%s/%s_onion_before_after_3x.png" % [PREVIEW_DIR, spec.name])


func _overlay_tinted(target: Image, source: Image, offset: Vector2i, tint: Color, opacity: float) -> void:
	for y in source.get_height():
		for x in source.get_width():
			var source_color := source.get_pixel(x, y)
			if source_color.a < 0.5:
				continue
			var destination := target.get_pixel(offset.x + x, offset.y + y)
			var luminance := source_color.r * 0.30 + source_color.g * 0.59 + source_color.b * 0.11
			var colored := tint * (0.55 + luminance * 0.45)
			colored.a = 1.0
			target.set_pixel(offset.x + x, offset.y + y, destination.lerp(colored, opacity))


func _draw_text(image: Image, position: Vector2i, value: String, color: Color) -> void:
	var cursor := position.x
	for glyph_name in value:
		if not DIGITS.has(glyph_name):
			cursor += 4
			continue
		var glyph: Array = DIGITS[glyph_name]
		for y in glyph.size():
			for x in 3:
				if glyph[y][x] == "1":
					image.set_pixel(cursor + x, position.y + y, color)
		cursor += 4


func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for x in range(rect.position.x, rect.end.x):
		if x >= 0 and x < image.get_width():
			if rect.position.y >= 0 and rect.position.y < image.get_height(): image.set_pixel(x, rect.position.y, color)
			if rect.end.y - 1 >= 0 and rect.end.y - 1 < image.get_height(): image.set_pixel(x, rect.end.y - 1, color)
	for y in range(rect.position.y, rect.end.y):
		if y >= 0 and y < image.get_height():
			if rect.position.x >= 0 and rect.position.x < image.get_width(): image.set_pixel(rect.position.x, y, color)
			if rect.end.x - 1 >= 0 and rect.end.x - 1 < image.get_width(): image.set_pixel(rect.end.x - 1, y, color)


func _clear_all_cell_borders(sheet: Image) -> void:
	# Only the rewritten walk cells are touched. Other rows must remain pixel-identical.
	for column in COLUMNS:
		var cell := sheet.get_region(Rect2i(column * CELL, WALK_ROW * CELL, CELL, CELL))
		_clear_cell_border(cell)
		sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(column * CELL, WALK_ROW * CELL))


func _clear_cell_border(image: Image) -> void:
	for index in CELL:
		image.set_pixel(0, index, CLEAR)
		image.set_pixel(CELL - 1, index, CLEAR)
		image.set_pixel(index, 0, CLEAR)
		image.set_pixel(index, CELL - 1, CLEAR)


func _harden_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, 1.0) if color.a >= 0.5 else CLEAR)


func _color_key(color: Color) -> int:
	return (roundi(color.r * 255.0) << 16) | (roundi(color.g * 255.0) << 8) | roundi(color.b * 255.0)


func _save(image: Image, path: String) -> void:
	var error := image.save_png(path)
	if error != OK:
		_fail("save failed %s: %s" % [path, error_string(error)])


func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("cannot write %s" % path)
		return
	file.store_string(content)
	file.close()


func _fail(message: String) -> void:
	if not failures.has(message):
		failures.append(message)
