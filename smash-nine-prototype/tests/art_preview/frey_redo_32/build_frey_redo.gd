extends SceneTree
## CODEX-ART-32 pilot builder.  The character id and sheet/source/output paths are CLI
## arguments so the same body/fx separation can be reused for later fighters.
##
## Example:
## godot --headless --path . -s tests/art_preview/frey_redo_32/build_frey_redo.gd -- \
##   --character=frey --base=res://assets/art/frey/frey_sheet.png \
##   --old=res://tests/art_preview/frey_redo_32/before_sheet.png \
##   --source-dir=res://tests/art_preview/frey_redo_32 \
##   --asset-dir=res://assets/art/frey

const CELL := 128
const COLUMNS := 6
const SOURCE_HEAD_SIZE := Vector2(124.444, 142.222)
const REFERENCE_HEAD_BOX := Rect2i(62, 27, 28, 32) # hair + face + helmet; white wings excluded
const SOURCE_SCALE := 0.225 # REFERENCE_HEAD_BOX.size / SOURCE_HEAD_SIZE
const SAFE_MARGIN := 2

const ROWS := [
	{"name": "attack_up", "count": 4, "grounded": [true, true, true, true], "fx_max": 58},
	{"name": "attack_down", "count": 4, "grounded": [true, true, true, true], "fx_max": 58},
	{"name": "attack_air_side", "count": 4, "grounded": [false, false, false, false], "fx_max": 60},
	{"name": "dash_strike", "count": 4, "grounded": [true, true, true, true], "fx_max": 64},
	{"name": "rising_cleave", "count": 5, "grounded": [true, true, false, false, false], "fx_max": 62},
	{"name": "spike_followup", "count": 4, "grounded": [false, false, false, false], "fx_max": 58},
	{"name": "descent", "count": 6, "grounded": [true, true, false, false, true, true], "fx_max": 68},
	{"name": "tumble", "count": 4, "grounded": [false, false, false, false], "fx_max": 30},
]

const FX_ANCHORS := {
	"attack_up": [Vector2i(76, 72), Vector2i(76, 65), Vector2i(78, 55), Vector2i(78, 64)],
	"attack_down": [Vector2i(76, 55), Vector2i(80, 68), Vector2i(82, 80), Vector2i(78, 72)],
	"attack_air_side": [Vector2i(76, 60), Vector2i(84, 62), Vector2i(91, 63), Vector2i(82, 64)],
	"dash_strike": [Vector2i(45, 64), Vector2i(48, 64), Vector2i(48, 64), Vector2i(94, 58)],
	"rising_cleave": [Vector2i(68, 98), Vector2i(72, 82), Vector2i(76, 65), Vector2i(78, 53), Vector2i(76, 60)],
	"spike_followup": [Vector2i(76, 51), Vector2i(82, 62), Vector2i(82, 72), Vector2i(79, 66)],
	"descent": [Vector2i(65, 50), Vector2i(65, 49), Vector2i(66, 60), Vector2i(66, 69), Vector2i(65, 101), Vector2i(65, 99)],
	"tumble": [Vector2i(67, 59), Vector2i(63, 61), Vector2i(61, 66), Vector2i(66, 65)],
}

const BEFORE_SCALES := {
	"attack_up": [0.999, 1.004, 1.101, 1.015],
	"attack_down": [1.042, 0.989, 1.092, 0.980],
	"attack_air_side": [1.015, 0.973, 0.978, 1.018],
	"dash_strike": [0.997, 1.028, 1.054, 1.096],
	"rising_cleave": [1.025, 1.084, 1.085, 0.974, 1.026],
	"spike_followup": [1.031, 1.026, 0.726, 1.364],
	"descent": [1.065, 1.039, 0.968, 0.852, 1.300, 0.979],
	"tumble": [0.905, 0.905, 0.905, 0.905],
}

const DIGITS := {
	"0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
	"2": ["111", "001", "111", "100", "111"], "3": ["111", "001", "111", "001", "111"],
	"4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"],
	"8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "111"],
	".": ["000", "000", "000", "000", "010"], "-": ["000", "000", "111", "000", "000"],
}

var character := "frey"
var base_path := "res://assets/art/frey/frey_sheet.png"
var old_path := "res://tests/art_preview/frey_redo_32/before_sheet.png"
var source_dir := "res://tests/art_preview/frey_redo_32"
var asset_dir := "res://assets/art/frey"
var preview_dir := "res://tests/art_preview/frey_redo_32"
var palette: Array[Color] = []
var color_cache := {}
var failures: Array[String] = []
var head_reference: Image


func _init() -> void:
	_parse_args()
	var base := Image.load_from_file(base_path)
	var old := Image.load_from_file(old_path)
	if base.is_empty() or old.is_empty():
		_fail("cannot load base or old move sheet")
		_finish()
		return
	palette = _collect_palette(base)
	head_reference = base.get_region(REFERENCE_HEAD_BOX)
	var body_sheet := Image.create(COLUMNS * CELL, ROWS.size() * CELL, false, Image.FORMAT_RGBA8)
	var fx_sheet := Image.create(COLUMNS * CELL, ROWS.size() * CELL, false, Image.FORMAT_RGBA8)
	body_sheet.fill(Color.TRANSPARENT)
	fx_sheet.fill(Color.TRANSPARENT)
	var heads := {
		"character": character,
		"cell_size": CELL,
		"reference": {
			"sheet": base_path,
			"frame": {"row": 0, "column": 0},
			"box": _rect_dict(REFERENCE_HEAD_BOX),
			"w": REFERENCE_HEAD_BOX.size.x,
			"h": REFERENCE_HEAD_BOX.size.y,
			"excludes": "white helmet wings",
		},
		"rows": {},
	}

	for row_index in ROWS.size():
		var spec: Dictionary = ROWS[row_index]
		_build_body_row(spec, row_index, body_sheet, heads)
		_build_fx_row(spec, row_index, fx_sheet)

	var composite := body_sheet.duplicate()
	composite.blend_rect(fx_sheet, Rect2i(Vector2i.ZERO, fx_sheet.get_size()), Vector2i.ZERO)
	_harden_alpha(composite)
	_clear_all_borders(body_sheet)
	_clear_all_borders(fx_sheet)
	_clear_all_borders(composite)

	_save(body_sheet, "%s/%s_moves_body_sheet.png" % [asset_dir, character])
	_save(fx_sheet, "%s/%s_moves_fx_sheet.png" % [asset_dir, character])
	_save(composite, "%s/%s_moves_sheet.png" % [asset_dir, character])
	_save_json(heads, "%s/%s_moves_heads.json" % [asset_dir, character])
	_make_contacts(base, old, body_sheet, fx_sheet, composite, heads)
	_fix_jotun_golem()
	_finish()


func _parse_args() -> void:
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--") or not argument.contains("="):
			continue
		var pair := argument.trim_prefix("--").split("=", true, 1)
		match pair[0]:
			"character": character = pair[1]
			"base": base_path = pair[1]
			"old": old_path = pair[1]
			"source-dir": source_dir = pair[1]
			"asset-dir": asset_dir = pair[1]
			"preview-dir": preview_dir = pair[1]


func _build_body_row(spec: Dictionary, row_index: int, sheet: Image, heads: Dictionary) -> void:
	var row := String(spec.name)
	var count := int(spec.count)
	var source := Image.load_from_file("%s/%s_body_source.png" % [source_dir, row])
	if source.is_empty():
		_fail("%s body source missing" % row)
		return
	var pose_bounds := _body_pose_bounds(source, count)
	if pose_bounds.size() != count:
		_fail("%s expected %d connected poses, found %d" % [row, count, pose_bounds.size()])
		return
	var row_heads: Array = []
	for frame_index in count:
		var bounds: Rect2i = pose_bounds[frame_index]
		if bounds.size == Vector2i.ZERO:
			_fail("%s frame %d body source empty" % [row, frame_index + 1])
			continue
		var face := _select_face_component(source, bounds, row, frame_index)
		var crop := source.get_region(bounds)
		var target_size := Vector2i(maxi(1, roundi(bounds.size.x * SOURCE_SCALE)), maxi(1, roundi(bounds.size.y * SOURCE_SCALE)))
		if target_size.x > CELL - SAFE_MARGIN * 2 or target_size.y > CELL - SAFE_MARGIN * 2:
			_fail("%s frame %d is %s after head scaling; regenerate tighter" % [row, frame_index + 1, target_size])
			continue
		crop.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
		_quantize(crop)
		var destination := Vector2i((CELL - crop.get_width()) / 2, 0)
		if bool(spec.grounded[frame_index]):
			destination.y = 120 - crop.get_height() + 1
		else:
			destination.y = (CELL - crop.get_height()) / 2
		destination.x = clampi(destination.x, SAFE_MARGIN, CELL - SAFE_MARGIN - crop.get_width())
		destination.y = clampi(destination.y, SAFE_MARGIN, CELL - SAFE_MARGIN - crop.get_height())
		var cell := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
		cell.fill(Color.TRANSPARENT)
		cell.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), destination)
		var face_center := Vector2(face.get_center() - bounds.position) * SOURCE_SCALE + Vector2(destination)
		var head_position := Vector2i(roundi(face_center.x - REFERENCE_HEAD_BOX.size.x * 0.5), roundi(face_center.y - REFERENCE_HEAD_BOX.size.y * 0.62))
		head_position.x = clampi(head_position.x, 1, CELL - 1 - REFERENCE_HEAD_BOX.size.x)
		head_position.y = clampi(head_position.y, 1, CELL - 1 - REFERENCE_HEAD_BOX.size.y)
		var canonical_head := head_reference.duplicate()
		if row == "tumble":
			canonical_head = _rotate_quarter(canonical_head, frame_index)
			canonical_head.resize(REFERENCE_HEAD_BOX.size.x, REFERENCE_HEAD_BOX.size.y, Image.INTERPOLATE_NEAREST)
		# The canonical head is an independent layer over the generated body. Transparent pixels
		# leave the row-specific hair/wing silhouette intact, while visible head pixels are exact.
		cell.blend_rect(canonical_head, Rect2i(Vector2i.ZERO, canonical_head.get_size()), head_position)
		_clear_border(cell)
		sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(frame_index * CELL, row_index * CELL))
		row_heads.append({"frame": frame_index + 1, "head": _rect_dict(Rect2i(head_position, REFERENCE_HEAD_BOX.size))})
	heads.rows[row] = row_heads


func _build_fx_row(spec: Dictionary, row_index: int, sheet: Image) -> void:
	var row := String(spec.name)
	var count := int(spec.count)
	var source := Image.load_from_file("%s/%s_fx_source.png" % [source_dir, row])
	if source.is_empty():
		_fail("%s fx source missing" % row)
		return
	var bounds_list: Array[Rect2i] = []
	var largest := 1
	for frame_index in count:
		var bounds := _alpha_bounds(source, _source_slot(source, frame_index, count))
		bounds_list.append(bounds)
		largest = maxi(largest, maxi(bounds.size.x, bounds.size.y))
	var scale := minf(1.0, float(spec.fx_max) / float(largest))
	for frame_index in count:
		var bounds := bounds_list[frame_index]
		if bounds.size == Vector2i.ZERO:
			continue
		var crop := source.get_region(bounds)
		var target_size := Vector2i(maxi(1, roundi(bounds.size.x * scale)), maxi(1, roundi(bounds.size.y * scale)))
		crop.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
		_quantize(crop)
		var anchor: Vector2i = FX_ANCHORS[row][frame_index]
		var destination := anchor - crop.get_size() / 2
		destination.x = clampi(destination.x, SAFE_MARGIN, CELL - SAFE_MARGIN - crop.get_width())
		destination.y = clampi(destination.y, SAFE_MARGIN, CELL - SAFE_MARGIN - crop.get_height())
		var cell := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
		cell.fill(Color.TRANSPARENT)
		cell.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), destination)
		_clear_border(cell)
		sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(frame_index * CELL, row_index * CELL))


func _source_slot(image: Image, index: int, count: int) -> Rect2i:
	var x0 := roundi(float(index) * image.get_width() / count)
	var x1 := roundi(float(index + 1) * image.get_width() / count)
	return Rect2i(x0, 0, x1 - x0, image.get_height())


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
			var component_area := 0
			var bounds := Rect2i()
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				component_area += 1
				bounds = Rect2i(point, Vector2i.ONE) if bounds.size == Vector2i.ZERO else bounds.expand(point).expand(point + Vector2i.ONE)
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						if ox == 0 and oy == 0:
							continue
						var next: Vector2i = point + Vector2i(ox, oy)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
							continue
						var next_index: int = next.y * width + next.x
						if visited[next_index] == 0 and image.get_pixelv(next).a >= 0.5:
							visited[next_index] = 1
							stack.append(next)
			if component_area >= 1000:
				components.append({"area": component_area, "bounds": bounds})
	components.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(left.area) > int(right.area))
	if components.size() > expected:
		components.resize(expected)
	components.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(left.bounds.position.x) < int(right.bounds.position.x))
	var result: Array[Rect2i] = []
	for component in components:
		result.append(component.bounds)
	return result


func _alpha_bounds(image: Image, area: Rect2i) -> Rect2i:
	var result := Rect2i()
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if image.get_pixel(x, y).a >= 0.5:
				result = Rect2i(x, y, 1, 1) if result.size == Vector2i.ZERO else result.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
	return result


func _select_face_component(image: Image, area: Rect2i, row: String, frame_index: int) -> Rect2i:
	var components := _skin_components(image, area)
	var expected := Vector2(0.68, 0.36)
	if row == "attack_up" and frame_index == 2:
		expected = Vector2(0.50, 0.43)
	if row == "tumble":
		expected = [Vector2(0.72, 0.34), Vector2(0.20, 0.38), Vector2(0.55, 0.78), Vector2(0.76, 0.34)][frame_index]
	var best_score := -1000000.0
	var best := Rect2i(area.position + Vector2i(roundi(area.size.x * expected.x), roundi(area.size.y * expected.y)), Vector2i.ONE)
	for component in components:
		var rect: Rect2i = component.rect
		var normalized := Vector2(rect.get_center() - area.position) / Vector2(area.size)
		var distance := normalized.distance_to(expected)
		# Position dominates: large exposed hands must not outrank the smaller face cluster.
		var score := minf(float(component.area), 500.0) * 0.0002 - distance
		if score > best_score:
			best_score = score
			best = rect
	return best


func _skin_components(image: Image, area: Rect2i) -> Array[Dictionary]:
	var width := area.size.x
	var height := area.size.y
	var mask := PackedByteArray()
	mask.resize(width * height)
	for local_y in height:
		for local_x in width:
			var color := image.get_pixel(area.position.x + local_x, area.position.y + local_y)
			var skin := color.a >= 0.5 and color.r > 0.62 and color.g > 0.30 and color.g < 0.82 \
				and color.b > 0.25 and color.b < 0.68 and color.r - color.g > 0.08 \
				and color.r - color.g < 0.48 and color.g - color.b > 0.02 and color.g - color.b < 0.25
			mask[local_y * width + local_x] = 1 if skin else 0
	var visited := PackedByteArray()
	visited.resize(mask.size())
	var components: Array[Dictionary] = []
	for start_y in height:
		for start_x in width:
			var start := start_y * width + start_x
			if mask[start] == 0 or visited[start] != 0:
				continue
			var queue: Array[Vector2i] = [Vector2i(start_x, start_y)]
			visited[start] = 1
			var cursor := 0
			var component_area := 0
			var bounds := Rect2i()
			while cursor < queue.size():
				var point := queue[cursor]
				cursor += 1
				component_area += 1
				bounds = Rect2i(point, Vector2i.ONE) if bounds.size == Vector2i.ZERO else bounds.expand(point).expand(point + Vector2i.ONE)
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = point + offset
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var next_index: int = next.y * width + next.x
					if mask[next_index] != 0 and visited[next_index] == 0:
						visited[next_index] = 1
						queue.append(next)
			if component_area >= 3:
				components.append({"rect": Rect2i(bounds.position + area.position, bounds.size), "area": component_area})
	return components


func _rotate_quarter(source: Image, turns: int) -> Image:
	var normalized := posmod(turns, 4)
	if normalized == 0:
		return source.duplicate()
	var output_size := Vector2i(source.get_height(), source.get_width()) if normalized % 2 == 1 else source.get_size()
	var output := Image.create(output_size.x, output_size.y, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for y in source.get_height():
		for x in source.get_width():
			var target := Vector2i.ZERO
			if normalized == 1:
				target = Vector2i(source.get_height() - 1 - y, x)
			elif normalized == 2:
				target = Vector2i(source.get_width() - 1 - x, source.get_height() - 1 - y)
			else:
				target = Vector2i(y, source.get_width() - 1 - x)
			output.set_pixelv(target, source.get_pixel(x, y))
	return output


func _collect_palette(base: Image) -> Array[Color]:
	var histogram := {}
	for y in base.get_height():
		for x in base.get_width():
			var color := base.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := _color_key(color)
			histogram[key] = int(histogram.get(key, 0)) + 1
	var ranked: Array[Dictionary] = []
	for key in histogram:
		ranked.append({"key": int(key), "count": int(histogram[key])})
	ranked.sort_custom(_palette_more_frequent)
	var result: Array[Color] = []
	for index in mini(192, ranked.size()):
		var key: int = ranked[index].key
		result.append(Color8((key >> 16) & 255, (key >> 8) & 255, key & 255, 255))
	print("palette colors: %d retained from %d source colors" % [result.size(), ranked.size()])
	return result


func _palette_more_frequent(left: Dictionary, right: Dictionary) -> bool:
	return int(left.count) > int(right.count)


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


func _color_key(color: Color) -> int:
	return (roundi(color.r * 255.0) << 16) | (roundi(color.g * 255.0) << 8) | roundi(color.b * 255.0)


func _harden_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, 1.0) if color.a >= 0.5 else Color.TRANSPARENT)


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


func _make_contacts(base: Image, old: Image, body: Image, fx: Image, composite: Image, heads: Dictionary) -> void:
	var idle := base.get_region(Rect2i(0, 0, CELL, CELL))
	for row_index in ROWS.size():
		var spec: Dictionary = ROWS[row_index]
		var row := String(spec.name)
		var count := int(spec.count)
		var contact := Image.create((count + 1) * CELL, 2 * (CELL + 10), false, Image.FORMAT_RGBA8)
		contact.fill(Color("101729"))
		for line in 2:
			contact.blend_rect(idle, Rect2i(Vector2i.ZERO, idle.get_size()), Vector2i(0, line * (CELL + 10)))
		for frame in count:
			var source_before := old.get_region(Rect2i(frame * CELL, row_index * CELL, CELL, CELL))
			var source_after := composite.get_region(Rect2i(frame * CELL, row_index * CELL, CELL, CELL))
			contact.blend_rect(source_before, Rect2i(Vector2i.ZERO, source_before.get_size()), Vector2i((frame + 1) * CELL, 0))
			contact.blend_rect(source_after, Rect2i(Vector2i.ZERO, source_after.get_size()), Vector2i((frame + 1) * CELL, CELL + 10))
			_draw_text(contact, Vector2i((frame + 1) * CELL + 48, CELL + 2), "%.2f" % float(BEFORE_SCALES[row][frame]), Color("ffcf6b"))
			_draw_text(contact, Vector2i((frame + 1) * CELL + 48, 2 * CELL + 12), "1.00", Color("8ef2d0"))
		_save(contact, "%s/%s_before_after_1x.png" % [preview_dir, row])
		var contact_3x := contact.duplicate()
		contact_3x.resize(contact.get_width() * 3, contact.get_height() * 3, Image.INTERPOLATE_NEAREST)
		_save(contact_3x, "%s/%s_before_after_3x.png" % [preview_dir, row])

	for row in ["spike_followup", "descent"]:
		var row_index := _row_index(row)
		var count := int(ROWS[row_index].count)
		var layers := Image.create(count * CELL * 3, CELL, false, Image.FORMAT_RGBA8)
		layers.fill(Color("101729"))
		for panel in 3:
			var sheet := [body, fx, composite][panel] as Image
			var strip := sheet.get_region(Rect2i(0, row_index * CELL, count * CELL, CELL))
			layers.blend_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(panel * count * CELL, 0))
		_save(layers, "%s/%s_layers_1x.png" % [preview_dir, row])
		var layers_3x := layers.duplicate()
		layers_3x.resize(layers.get_width() * 3, layers.get_height() * 3, Image.INTERPOLATE_NEAREST)
		_save(layers_3x, "%s/%s_layers_3x.png" % [preview_dir, row])

	var overlay := composite.duplicate()
	for row_index in ROWS.size():
		var row := String(ROWS[row_index].name)
		for entry in heads.rows[row]:
			var head: Dictionary = entry.head
			var rect := Rect2i(int(head.x) + (int(entry.frame) - 1) * CELL, int(head.y) + row_index * CELL, int(head.w), int(head.h))
			_draw_rect_outline(overlay, rect, Color("62f4ff"))
	_save(overlay, "%s/head_boxes_1x.png" % preview_dir)
	var overlay_3x := overlay.duplicate()
	overlay_3x.resize(overlay.get_width() * 3, overlay.get_height() * 3, Image.INTERPOLATE_NEAREST)
	_save(overlay_3x, "%s/head_boxes_3x.png" % preview_dir)


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


func _draw_rect_outline(image: Image, rect: Rect2i, color: Color) -> void:
	for x in range(rect.position.x, rect.end.x):
		if x >= 0 and x < image.get_width():
			if rect.position.y >= 0 and rect.position.y < image.get_height(): image.set_pixel(x, rect.position.y, color)
			if rect.end.y - 1 >= 0 and rect.end.y - 1 < image.get_height(): image.set_pixel(x, rect.end.y - 1, color)
	for y in range(rect.position.y, rect.end.y):
		if y >= 0 and y < image.get_height():
			if rect.position.x >= 0 and rect.position.x < image.get_width(): image.set_pixel(rect.position.x, y, color)
			if rect.end.x - 1 >= 0 and rect.end.x - 1 < image.get_width(): image.set_pixel(rect.end.x - 1, y, color)


func _row_index(row: String) -> int:
	for index in ROWS.size():
		if String(ROWS[index].name) == row:
			return index
	return -1


func _fix_jotun_golem() -> void:
	var path := "res://assets/art/monsters/jotunheim_rune_golem_sheet.png"
	var sheet := Image.load_from_file(path)
	if sheet.is_empty():
		_fail("cannot load Jotunheim rune golem sheet")
		return
	const MONSTER_CELL := 96
	var origin := Vector2i(MONSTER_CELL, MONSTER_CELL * 2)
	var frame := sheet.get_region(Rect2i(origin, Vector2i(MONSTER_CELL, MONSTER_CELL)))
	var edge := _edge_counts(frame)
	var shift := Vector2i.ZERO
	if edge[0] > 0 and edge[1] == 0: shift.x = 1
	elif edge[1] > 0 and edge[0] == 0: shift.x = -1
	if edge[2] > 0 and edge[3] == 0: shift.y = 1
	elif edge[3] > 0 and edge[2] == 0: shift.y = -1
	if shift != Vector2i.ZERO:
		var moved := Image.create(MONSTER_CELL, MONSTER_CELL, false, Image.FORMAT_RGBA8)
		moved.fill(Color.TRANSPARENT)
		moved.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), shift)
		frame = moved
	for index in MONSTER_CELL:
		frame.set_pixel(0, index, Color.TRANSPARENT)
		frame.set_pixel(MONSTER_CELL - 1, index, Color.TRANSPARENT)
		frame.set_pixel(index, 0, Color.TRANSPARENT)
		frame.set_pixel(index, MONSTER_CELL - 1, Color.TRANSPARENT)
	sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), origin)
	_save(sheet, path)
	print("golem r2c1 border before=%s shift=%s after=%s" % [edge, shift, _edge_counts(frame)])


func _edge_counts(image: Image) -> Array[int]:
	var result: Array[int] = [0, 0, 0, 0]
	for index in image.get_height():
		if image.get_pixel(0, index).a >= 0.5: result[0] += 1
		if image.get_pixel(image.get_width() - 1, index).a >= 0.5: result[1] += 1
	for index in image.get_width():
		if image.get_pixel(index, 0).a >= 0.5: result[2] += 1
		if image.get_pixel(index, image.get_height() - 1).a >= 0.5: result[3] += 1
	return result


func _rect_dict(rect: Rect2i) -> Dictionary:
	return {"x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y}


func _save(image: Image, path: String) -> void:
	var error := image.save_png(path)
	if error != OK:
		_fail("save failed %s: %s" % [path, error_string(error)])


func _save_json(data: Dictionary, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("cannot write %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t") + "\n")


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("build_frey_redo: body/fx/composite/heads/previews built")
		quit(0)
	else:
		print("build_frey_redo: %d failures" % failures.size())
		quit(1)
