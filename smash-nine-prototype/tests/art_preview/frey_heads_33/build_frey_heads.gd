extends SceneTree
## CODEX-ART-33 builder. Every body frame is one crop of one generated drawing. The only blend
## operation between semantic layers is FX over body. No head, face, limb, or equipment is pasted.

const Detector := preload("res://tests/art_preview/frey_heads_33/head_detector.gd")
const CELL := 128
const COLUMNS := 6
const INITIAL_SOURCE_SCALE := 0.225
const TARGET_FINAL_HEAD_UNIT := 22.95 # 102 source pixels at the ART-32 baseline 0.225 scale
const SAFE_MARGIN := 2
const BASE := "res://assets/art/frey/frey_sheet.png"
const BODY_OUT := "res://assets/art/frey/frey_moves_body_sheet.png"
const FX_OUT := "res://assets/art/frey/frey_moves_fx_sheet.png"
const COMPOSITE_OUT := "res://assets/art/frey/frey_moves_sheet.png"
const HEADS_OUT := "res://assets/art/frey/frey_moves_heads.json"
const SOURCE_DIR := "res://tests/art_preview/frey_redo_32"
const PREVIEW_DIR := "res://tests/art_preview/frey_heads_33"
const REPORT_DIR := "res://../reports/codex-art-33"
const ART32 := "res://tests/art_preview/frey_heads_33/art32_pasted_body_sheet.png"

const ROWS := [
	{"name": "attack_up", "count": 4, "grounded": [true, true, true, true]},
	{"name": "attack_down", "count": 4, "grounded": [true, true, true, true]},
	{"name": "attack_air_side", "count": 4, "grounded": [false, false, false, false]},
	{"name": "dash_strike", "count": 4, "grounded": [true, true, true, true]},
	{"name": "rising_cleave", "count": 5, "grounded": [true, true, false, false, false]},
	{"name": "spike_followup", "count": 4, "grounded": [false, false, false, false]},
	{"name": "descent", "count": 6, "grounded": [true, true, false, false, true, true]},
	{"name": "tumble", "count": 4, "grounded": [false, false, false, false]},
]

const DIGITS := {
	"0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
	"2": ["111", "001", "111", "100", "111"], "3": ["111", "001", "111", "001", "111"],
	"4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"],
	"8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "111"],
	".": ["000", "000", "000", "000", "010"], "/": ["001", "001", "010", "100", "100"],
}

var detector
var palette: Array[Color] = []
var color_cache := {}
var failures: Array[String] = []
var operation_lines := PackedStringArray([
	"row frame source_crop source_head_unit initial_scale correction final_scale target_size destination grounded trims palette",
])


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	var base := Image.load_from_file(BASE)
	var fx := Image.load_from_file(FX_OUT)
	var before := Image.load_from_file(ART32)
	if base.is_empty() or fx.is_empty() or before.is_empty():
		_fail("missing base, ART-32 fixture, or FX sheet")
		_finish()
		return
	if fx.get_size() != Vector2i(COLUMNS * CELL, ROWS.size() * CELL):
		_fail("FX sheet has wrong size %s" % fx.get_size())
		_finish()
		return
	detector = Detector.new()
	detector.configure(base)
	palette = _collect_palette(base)
	var body := Image.create(COLUMNS * CELL, ROWS.size() * CELL, false, Image.FORMAT_RGBA8)
	body.fill(Color.TRANSPARENT)
	var heads := {
		"character": "frey", "cell_size": CELL,
		"measurement": "source-drawn eye-anchored face-colour region multiplied by the one whole-frame scale; no pasted head pixels",
		"reference": {
			"sheet": BASE,
			"frame": {"row": 0, "column": 0},
			"box": _rect_dict(Detector.HEAD_BOX),
			"w": Detector.HEAD_BOX.size.x,
			"h": Detector.HEAD_BOX.size.y,
		},
		"rows": {},
	}
	for row_index in ROWS.size():
		_build_body_row(ROWS[row_index], row_index, body, heads)
	_clear_all_borders(body)
	_clear_all_borders(fx)
	var composite := body.duplicate()
	# D32 rule 3: this is the sole semantic compositing operation in the production pipeline.
	composite.blend_rect(fx, Rect2i(Vector2i.ZERO, fx.get_size()), Vector2i.ZERO)
	_harden_alpha(composite)
	_clear_all_borders(composite)
	_save(body, BODY_OUT)
	_save(fx, FX_OUT)
	_save(composite, COMPOSITE_OUT)
	_save_json(heads, HEADS_OUT)
	_make_contacts(base, before, body, heads)
	_write_text("%s/body_pixel_operations.txt" % REPORT_DIR, "\n".join(operation_lines) + "\n")
	_finish()


func _build_body_row(spec: Dictionary, row_index: int, sheet: Image, heads: Dictionary) -> void:
	var row := String(spec.name)
	var count := int(spec.count)
	var source_path := "%s/%s_body_source.png" % [SOURCE_DIR, row]
	var source := Image.load_from_file(source_path)
	if source.is_empty():
		_fail("%s source missing" % row)
		return
	var bounds_list := _body_pose_bounds(source, count)
	if bounds_list.size() != count:
		_fail("%s expected %d whole drawings, found %d" % [row, count, bounds_list.size()])
		return
	var row_heads: Array = []
	for frame_index in count:
		var bounds: Rect2i = bounds_list[frame_index]
		var whole_drawing := source.get_region(bounds)
		var source_measure: Dictionary = detector.measure_source_drawing(source, bounds, _expected_face(row, frame_index))
		if not bool(source_measure.valid):
			_fail("%s frame %d could not measure source-drawn head" % [row, frame_index + 1])
			continue
		var source_unit := float(source_measure.unit)
		var absolute_scale := TARGET_FINAL_HEAD_UNIT / source_unit
		var projected := Vector2(whole_drawing.get_size()) * absolute_scale
		if projected.x > CELL - SAFE_MARGIN * 2 or projected.y > CELL - SAFE_MARGIN * 2:
			absolute_scale *= minf(float(CELL - SAFE_MARGIN * 2) / projected.x, float(CELL - SAFE_MARGIN * 2) / projected.y)
		var render: Dictionary = _render_whole_drawing(whole_drawing, absolute_scale, bool(spec.grounded[frame_index]))
		if not bool(render.valid):
			_fail("%s frame %d could not render at measured scale" % [row, frame_index + 1])
			continue
		var cell: Image = render.cell
		var head_scale := absolute_scale * source_unit / TARGET_FINAL_HEAD_UNIT
		var eye_rect: Rect2i = source_measure.eye
		var local_eye := Vector2(eye_rect.get_center() - bounds.position) * absolute_scale + Vector2(render.destination)
		var offset := Vector2(Detector.HEAD_BOX.get_center() - Detector.EYE_ROI.get_center()) * head_scale
		var turns := frame_index if row == "tumble" else 0
		offset = _rotate_vector(offset, turns)
		var head_size := Vector2i(roundi(Detector.HEAD_BOX.size.x * head_scale), roundi(Detector.HEAD_BOX.size.y * head_scale))
		if turns % 2 == 1:
			head_size = Vector2i(head_size.y, head_size.x)
		var head_center := local_eye + offset
		var measured_head := Rect2i(Vector2i(roundi(head_center.x - head_size.x * 0.5), roundi(head_center.y - head_size.y * 0.5)), head_size)
		var eye_count := int(detector.count_eye_clusters(cell, measured_head))
		var stamp := float(detector.stamp_score(cell, measured_head))
		var valid := absf(head_scale - 1.0) <= 0.0501 and eye_count <= 2 and stamp < 0.96
		if not valid:
			_fail("%s frame %d audit failed: scale=%.4f eyes=%d stamp=%.4f" % [row, frame_index + 1, head_scale, eye_count, stamp])
			continue
		_clear_border(cell)
		sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(frame_index * CELL, row_index * CELL))
		var correction := absolute_scale / INITIAL_SOURCE_SCALE
		operation_lines.append("%s %d %s %.4f %.6f %.6f %.6f %s %s %s none nearest+canonical192+hard-alpha" % [
			row, frame_index + 1, bounds, source_unit, INITIAL_SOURCE_SCALE, correction, absolute_scale,
			render.target_size, render.destination, spec.grounded[frame_index],
		])
		# Runtime metadata keeps the established upright 28x32 contract even when the
		# source-drawn head is rotated during tumble. The independent audit above still
		# measures the true rotated rectangle and never reads this JSON.
		var metadata_head := _reference_sized_head_rect(measured_head)
		row_heads.append({"frame": frame_index + 1, "head": _rect_dict(metadata_head),
			"scale": snappedf(head_scale, 0.0001), "eye_clusters": eye_count,
			"source_head_unit": snappedf(source_unit, 0.0001), "whole_frame_scale": snappedf(absolute_scale, 0.000001)})
	heads.rows[row] = row_heads


func _expected_face(row: String, frame_index: int) -> Vector2:
	if row == "attack_up" and frame_index == 2:
		return Vector2(0.50, 0.43)
	if row == "tumble":
		return [Vector2(0.72, 0.34), Vector2(0.20, 0.38), Vector2(0.55, 0.78), Vector2(0.76, 0.34)][frame_index]
	return Vector2(0.68, 0.36)


func _rotate_vector(value: Vector2, turns: int) -> Vector2:
	match posmod(turns, 4):
		1: return Vector2(-value.y, value.x)
		2: return -value
		3: return Vector2(value.y, -value.x)
	return value


func _reference_sized_head_rect(measured: Rect2i) -> Rect2i:
	var size := Detector.HEAD_BOX.size
	var top_left := Vector2i(roundi(measured.get_center().x - size.x * 0.5), roundi(measured.get_center().y - size.y * 0.5))
	top_left.x = clampi(top_left.x, 0, CELL - size.x)
	top_left.y = clampi(top_left.y, 0, CELL - size.y)
	return Rect2i(top_left, size)


func _render_whole_drawing(source: Image, scale: float, grounded: bool) -> Dictionary:
	var target_size := Vector2i(maxi(1, roundi(source.get_width() * scale)), maxi(1, roundi(source.get_height() * scale)))
	if target_size.x > CELL - SAFE_MARGIN * 2 or target_size.y > CELL - SAFE_MARGIN * 2:
		return {"valid": false, "cell": Image.new(), "target_size": target_size, "destination": Vector2i.ZERO}
	var drawing := source.duplicate()
	drawing.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	_quantize(drawing)
	_harden_alpha(drawing)
	var destination := Vector2i((CELL - drawing.get_width()) / 2, 0)
	destination.y = 120 - drawing.get_height() + 1 if grounded else (CELL - drawing.get_height()) / 2
	destination.x = clampi(destination.x, SAFE_MARGIN, CELL - SAFE_MARGIN - drawing.get_width())
	destination.y = clampi(destination.y, SAFE_MARGIN, CELL - SAFE_MARGIN - drawing.get_height())
	var cell := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	cell.fill(Color.TRANSPARENT)
	# This is a whole-frame placement, not per-part compositing.
	cell.blit_rect(drawing, Rect2i(Vector2i.ZERO, drawing.get_size()), destination)
	_clear_border(cell)
	return {"valid": true, "cell": cell, "target_size": target_size, "destination": destination}


func _body_pose_bounds(image: Image, expected: int) -> Array[Rect2i]:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var components: Array[Dictionary] = []
	for start_y in height:
		for start_x in width:
			var start := start_y * width + start_x
			if visited[start] != 0 or image.get_pixel(start_x, start_y).a < 0.5:
				continue
			var stack: Array[Vector2i] = [Vector2i(start_x, start_y)]
			visited[start] = 1
			var area := 0
			var bounds := Rect2i()
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				area += 1
				bounds = Rect2i(point, Vector2i.ONE) if bounds.size == Vector2i.ZERO else bounds.expand(point).expand(point + Vector2i.ONE)
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
							stack.append(next)
			if area >= 1000:
				components.append({"area": area, "bounds": bounds})
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.area) > int(b.area))
	if components.size() > expected:
		components.resize(expected)
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int((a.bounds as Rect2i).position.x) < int((b.bounds as Rect2i).position.x))
	var result: Array[Rect2i] = []
	for component in components:
		result.append(component.bounds)
	return result


func _collect_palette(image: Image) -> Array[Color]:
	var histogram := {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
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
	# Reserve the canonical face and eye colours before filling by frequency. They are rare but are
	# the explicit D32 measurement anchors; all still come from the canonical Frey sheet.
	for roi in [Detector.FACE_ROI, Detector.EYE_ROI]:
		for y in range(roi.position.y, roi.end.y):
			for x in range(roi.position.x, roi.end.x):
				var color := image.get_pixel(x, y)
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


func _quantize(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var source := image.get_pixel(x, y)
			if source.a < 0.5:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
			var key := _color_key(source)
			if not color_cache.has(key):
				var best := palette[0]
				var distance := INF
				for candidate in palette:
					var dr := source.r - candidate.r
					var dg := source.g - candidate.g
					var db := source.b - candidate.b
					var candidate_distance := dr * dr + dg * dg + db * db
					if candidate_distance < distance:
						distance = candidate_distance
						best = candidate
				color_cache[key] = best
			image.set_pixel(x, y, color_cache[key])


func _make_contacts(base: Image, before: Image, after: Image, heads: Dictionary) -> void:
	var idle := base.get_region(Rect2i(0, 0, CELL, CELL))
	var full_overlay := after.duplicate()
	for row_index in ROWS.size():
		var row := String(ROWS[row_index].name)
		var count := int(ROWS[row_index].count)
		var contact := Image.create((count + 1) * CELL, 2 * (CELL + 12), false, Image.FORMAT_RGBA8)
		contact.fill(Color("101729"))
		contact.blend_rect(idle, Rect2i(Vector2i.ZERO, idle.get_size()), Vector2i(0, 0))
		contact.blend_rect(idle, Rect2i(Vector2i.ZERO, idle.get_size()), Vector2i(0, CELL + 12))
		for frame_index in count:
			var old_frame := before.get_region(Rect2i(frame_index * CELL, row_index * CELL, CELL, CELL))
			var new_frame := after.get_region(Rect2i(frame_index * CELL, row_index * CELL, CELL, CELL))
			contact.blend_rect(old_frame, Rect2i(Vector2i.ZERO, old_frame.get_size()), Vector2i((frame_index + 1) * CELL, 0))
			contact.blend_rect(new_frame, Rect2i(Vector2i.ZERO, new_frame.get_size()), Vector2i((frame_index + 1) * CELL, CELL + 12))
			var entry: Dictionary = heads.rows[row][frame_index]
			var head := _dict_rect(entry.head)
			var contact_head := Rect2i(head.position + Vector2i((frame_index + 1) * CELL, CELL + 12), head.size)
			_draw_rect(contact, contact_head, Color("62f4ff"))
			_draw_text(contact, Vector2i((frame_index + 1) * CELL + 38, CELL * 2 + 14), "%.2f/%d" % [float(entry.scale), int(entry.eye_clusters)], Color("8ef2d0"))
			var full_head := Rect2i(head.position + Vector2i(frame_index * CELL, row_index * CELL), head.size)
			_draw_rect(full_overlay, full_head, Color("62f4ff"))
		var contact_3x := contact.duplicate()
		contact_3x.resize(contact.get_width() * 3, contact.get_height() * 3, Image.INTERPOLATE_NEAREST)
		_save(contact_3x, "%s/%s_before_after_heads_3x.png" % [PREVIEW_DIR, row])
	var overlay_3x := full_overlay.duplicate()
	overlay_3x.resize(full_overlay.get_width() * 3, full_overlay.get_height() * 3, Image.INTERPOLATE_NEAREST)
	_save(overlay_3x, "%s/head_boxes_after_3x.png" % PREVIEW_DIR)


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


func _clear_all_borders(sheet: Image) -> void:
	for row in sheet.get_height() / CELL:
		for column in sheet.get_width() / CELL:
			var cell := sheet.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
			_clear_border(cell)
			sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(column * CELL, row * CELL))


func _clear_border(image: Image) -> void:
	for index in CELL:
		image.set_pixel(0, index, Color.TRANSPARENT)
		image.set_pixel(CELL - 1, index, Color.TRANSPARENT)
		image.set_pixel(index, 0, Color.TRANSPARENT)
		image.set_pixel(index, CELL - 1, Color.TRANSPARENT)


func _harden_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, 1.0) if color.a >= 0.5 else Color.TRANSPARENT)


func _color_key(color: Color) -> int:
	return (roundi(color.r * 255.0) << 16) | (roundi(color.g * 255.0) << 8) | roundi(color.b * 255.0)


func _rect_dict(rect: Rect2i) -> Dictionary:
	return {"x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y}


func _dict_rect(value: Dictionary) -> Rect2i:
	return Rect2i(int(value.x), int(value.y), int(value.w), int(value.h))


func _save(image: Image, path: String) -> void:
	var error := image.save_png(path)
	if error != OK:
		_fail("save failed %s: %s" % [path, error_string(error)])


func _save_json(data: Dictionary, path: String) -> void:
	_write_text(path, JSON.stringify(data, "\t") + "\n")


func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("cannot write %s" % path)
		return
	file.store_string(content)
	file.close()


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("build_frey_heads: body/fx/composite/heads/contact sheets built")
		quit(0)
	else:
		print("build_frey_heads: %d failures" % failures.size())
		quit(1)
