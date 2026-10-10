extends SceneTree
## Part 3 preview only: preserves Rio's live sheet, replacing attack/shield rows in candidate copies.

const CELL := 128
const MAX_WIDTH := 122
const MAX_HEIGHT := 119
const SPECS := [
	{
		"label": "male",
		"base": "res://assets/art/rio/rio_male_sheet.png",
		"source": "res://tests/art_preview/moves_23/rio_male_v2_source.png",
		"output": "res://tests/art_preview/moves_23/rio_male_sheet_v2.png",
		"idle_size": Vector2i(105, 98),
		"anchor": 0,
	},
	{
		"label": "female",
		"base": "res://assets/art/rio/rio_female_sheet.png",
		"source": "res://tests/art_preview/moves_23/rio_female_v2_source.png",
		"output": "res://tests/art_preview/moves_23/rio_female_sheet_v2.png",
		"idle_size": Vector2i(101, 96),
		"anchor": 3,
	},
]

var results := {}

func _init() -> void:
	for spec in SPECS:
		if not _build(spec):
			quit(1)
			return
	_write_contact()
	quit()

func _build(spec: Dictionary) -> bool:
	var base := Image.load_from_file(ProjectSettings.globalize_path(str(spec.base)))
	var source := Image.load_from_file(ProjectSettings.globalize_path(str(spec.source)))
	if base.is_empty() or source.is_empty():
		push_error("moves_23 Rio: missing source/base for %s" % spec.label)
		return false
	var segmented := _segment(source)
	var components: Array = segmented.components
	var main: Array[int] = []
	for index in components.size():
		if int(components[index].count) >= 30000:
			main.append(index)
	if main.size() != 10:
		push_error("moves_23 Rio %s: expected 10 poses, found %d" % [spec.label, main.size()])
		return false
	main.sort_custom(func(a: int, b: int) -> bool: return _center(components[a].bounds).y < _center(components[b].bounds).y)
	var ordered: Array[int] = []
	var attack: Array[int] = main.slice(0, 4)
	var shield: Array[int] = main.slice(4, 10)
	attack.sort_custom(func(a: int, b: int) -> bool: return _center(components[a].bounds).x < _center(components[b].bounds).x)
	shield.sort_custom(func(a: int, b: int) -> bool: return _center(components[a].bounds).x < _center(components[b].bounds).x)
	ordered.append_array(attack)
	ordered.append_array(shield)
	var owner := PackedInt32Array()
	owner.resize(components.size())
	owner.fill(-1)
	for frame_index in ordered.size():
		owner[ordered[frame_index]] = frame_index
	for component_index in components.size():
		if owner[component_index] >= 0 or int(components[component_index].count) < 20:
			continue
		var nearest := -1
		var nearest_distance := INF
		var point := _center(components[component_index].bounds)
		for frame_index in ordered.size():
			var distance := _distance_to_rect(point, components[ordered[frame_index]].bounds)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = frame_index
		if nearest_distance <= 82.0:
			owner[component_index] = nearest
	var bounds: Array[Rect2i] = []
	for frame_index in ordered.size():
		var merged: Rect2i = components[ordered[frame_index]].bounds
		for component_index in components.size():
			if owner[component_index] == frame_index:
				merged = merged.merge(components[component_index].bounds)
		bounds.append(merged)
	var anchor_height := bounds[int(spec.anchor)].size.y
	var scale := float(spec.idle_size.y) / float(anchor_height)
	var candidate := base.duplicate()
	candidate.fill_rect(Rect2i(0, 4 * CELL, 6 * CELL, 2 * CELL), Color(0, 0, 0, 0))
	var frames: Array[Image] = []
	for frame_index in ordered.size():
		var frame := _render(source, segmented.labels, owner, frame_index, bounds[frame_index])
		frame = _compact(frame, scale, spec.idle_size)
		frame = _align_bottom(frame)
		frames.append(frame)
		var row := 4 if frame_index < 4 else 5
		var column := frame_index if frame_index < 4 else frame_index - 4
		candidate.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(column * CELL, row * CELL))
	candidate.save_png(ProjectSettings.globalize_path(str(spec.output)))
	results[spec.label] = {"base": base, "candidate": candidate, "frames": frames}
	print("moves_23 Rio %s v2: idle=%s scale=%.4f" % [spec.label, spec.idle_size, scale])
	return true

func _render(source: Image, labels: PackedInt32Array, owner: PackedInt32Array, frame_index: int, bounds: Rect2i) -> Image:
	var crop := Image.create(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
	for y in bounds.size.y:
		for x in bounds.size.x:
			var point := bounds.position + Vector2i(x, y)
			var component_index: int = labels[point.y * source.get_width() + point.x]
			if component_index >= 0 and owner[component_index] == frame_index:
				var color := source.get_pixelv(point)
				crop.set_pixel(x, y, Color(color.r, color.g, color.b, 1.0))
	return crop

func _compact(source: Image, scale: float, idle_size: Vector2i) -> Image:
	var image := _resize_axis(source, true, scale, mini(idle_size.x + 8, MAX_WIDTH), MAX_WIDTH)
	image = _resize_axis(image, false, scale, mini(idle_size.y + 4, MAX_HEIGHT), MAX_HEIGHT)
	return image

func _resize_axis(source: Image, horizontal: bool, scale: float, core_target: int, maximum: int) -> Image:
	var source_length := source.get_width() if horizontal else source.get_height()
	var other_length := source.get_height() if horizontal else source.get_width()
	var natural_length := maxi(1, int(round(source_length * scale)))
	if natural_length <= maximum:
		var resized := source.duplicate()
		if horizontal:
			resized.resize(natural_length, source.get_height(), Image.INTERPOLATE_NEAREST)
		else:
			resized.resize(source.get_width(), natural_length, Image.INTERPOLATE_NEAREST)
		return resized
	var core_source := mini(source_length, maxi(1, int(round(float(core_target) / scale))))
	var scores := PackedFloat32Array()
	scores.resize(source_length)
	for primary in source_length:
		for secondary in other_length:
			var color := source.get_pixel(primary, secondary) if horizontal else source.get_pixel(secondary, primary)
			if color.a >= 0.5:
				scores[primary] += 1.0 + (1.0 - color.get_luminance()) * 2.0
	var core_start := 0
	var running := 0.0
	for i in core_source:
		running += scores[i]
	var best := running
	for start in range(1, source_length - core_source + 1):
		running += scores[start + core_source - 1] - scores[start - 1]
		if running > best:
			best = running
			core_start = start
	var core_out := mini(core_target, maximum)
	var outer_out := maximum - core_out
	var left_source := core_start
	var right_source := source_length - core_start - core_source
	var left_out := 0 if left_source + right_source == 0 else int(round(float(outer_out * left_source) / float(left_source + right_source)))
	var right_out := outer_out - left_out
	var output := Image.create(maximum if horizontal else other_length, other_length if horizontal else maximum, false, Image.FORMAT_RGBA8)
	for target in maximum:
		var source_primary := 0
		if target < left_out and left_out > 0:
			source_primary = mini(left_source - 1, int(floor(float(target * left_source) / float(left_out))))
		elif target < left_out + core_out:
			source_primary = core_start + mini(core_source - 1, int(floor(float((target - left_out) * core_source) / float(core_out))))
		elif right_out > 0:
			source_primary = core_start + core_source + mini(right_source - 1, int(floor(float((target - left_out - core_out) * right_source) / float(right_out))))
		else:
			source_primary = source_length - 1
		for secondary in other_length:
			if horizontal:
				output.set_pixel(target, secondary, source.get_pixel(source_primary, secondary))
			else:
				output.set_pixel(secondary, target, source.get_pixel(secondary, source_primary))
	return output

func _align_bottom(image: Image) -> Image:
	var output := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	output.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i((CELL - image.get_width()) / 2, 121 - image.get_height()))
	return output

func _write_contact() -> void:
	var board := Image.create(CELL * 7, CELL * 4, false, Image.FORMAT_RGBA8)
	var row := 0
	for label in ["male", "female"]:
		var base: Image = results[label].base
		var candidate: Image = results[label].candidate
		var idle := base.get_region(Rect2i(0, 0, CELL, CELL))
		for source_row in [4, 5]:
			board.blit_rect(idle, Rect2i(0, 0, CELL, CELL), Vector2i(0, row * CELL))
			board.blit_rect(candidate, Rect2i(0, source_row * CELL, CELL * 6, CELL), Vector2i(CELL, row * CELL))
			row += 1
	board.save_png(ProjectSettings.globalize_path("res://tests/art_preview/moves_23/rio_v2_contact_1x.png"))
	var enlarged := board.duplicate()
	enlarged.resize(board.get_width() * 4, board.get_height() * 4, Image.INTERPOLATE_NEAREST)
	enlarged.save_png(ProjectSettings.globalize_path("res://tests/art_preview/moves_23/rio_v2_contact_4x.png"))

func _segment(image: Image) -> Dictionary:
	var labels := PackedInt32Array()
	labels.resize(image.get_width() * image.get_height())
	labels.fill(-1)
	var components: Array[Dictionary] = []
	for y in image.get_height():
		for x in image.get_width():
			var start := y * image.get_width() + x
			if labels[start] >= 0 or image.get_pixel(x, y).a < 0.5:
				continue
			var index := components.size()
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			labels[start] = index
			var bounds := Rect2i(Vector2i(x, y), Vector2i.ONE)
			var count := 0
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				bounds = bounds.expand(point).expand(point + Vector2i.ONE)
				count += 1
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						if ox == 0 and oy == 0:
							continue
						var next := point + Vector2i(ox, oy)
						if next.x < 0 or next.y < 0 or next.x >= image.get_width() or next.y >= image.get_height():
							continue
						var next_index := next.y * image.get_width() + next.x
						if labels[next_index] < 0 and image.get_pixelv(next).a >= 0.5:
							labels[next_index] = index
							stack.append(next)
			components.append({"bounds": bounds, "count": count})
	return {"labels": labels, "components": components}

func _center(rect: Rect2i) -> Vector2:
	return Vector2(rect.position) + Vector2(rect.size) * 0.5

func _distance_to_rect(point: Vector2, rect: Rect2i) -> float:
	return point.distance_to(Vector2(clampf(point.x, rect.position.x, rect.end.x), clampf(point.y, rect.position.y, rect.end.y)))
