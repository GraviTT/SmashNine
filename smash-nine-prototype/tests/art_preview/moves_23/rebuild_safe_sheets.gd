extends SceneTree
## Rebuilds ART-23 move atlases from per-pose connected components. The previous scripts divided
## generated canvases into fixed cells, which sliced irregularly spaced poses across cell edges.

const CELL := 128
const COLUMNS := 6
const MAX_WIDTH := 122
const MAX_HEIGHT := 119
const PREVIEW_DIR := "res://tests/art_preview/moves_23"
const SPECS := [
	{
		"label": "frey",
		"base": "res://assets/art/frey/frey_sheet.png",
		"source": "res://assets/art/frey/frey_moves_source.png",
		"output": "res://assets/art/frey/frey_moves_sheet.png",
		"rows": [["attack_up", 4], ["attack_down", 4], ["attack_air_side", 4], ["dash_strike", 4], ["rising_cleave", 5], ["spike_followup", 4], ["descent", 6]],
		"main_min": 8000,
		"idle_size": Vector2i(87, 100),
		"snap_palette": true,
	},
	{
		"label": "luna",
		"base": "res://assets/art/luna/luna_sheet.png",
		"source": "res://assets/art/luna/luna_moves_source.png",
		"output": "res://assets/art/luna/luna_moves_sheet.png",
		"rows": [["star_up", 4], ["star_down", 4], ["star_comet", 4], ["moon_ring", 5], ["transform", 6]],
		"main_min": 10000,
		"idle_size": Vector2i(92, 82),
		"snap_palette": false,
	},
	{
		"label": "luna_brave",
		"base": "res://assets/art/luna/luna_brave_sheet.png",
		"source": "res://assets/art/luna/luna_brave_moves_source.png",
		"output": "res://assets/art/luna/luna_brave_moves_sheet.png",
		"rows": [["brave_combo", 6], ["brave_upper", 4], ["brave_low", 4], ["brave_air_side", 4], ["brave_dive", 4], ["comet_drive", 4], ["luna_breaker", 6], ["heart_laser", 6]],
		"main_min": 7000,
		"idle_size": Vector2i(95, 83),
		"snap_palette": false,
	},
]

var failed := false

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))
	for spec in SPECS:
		if not _build_sheet(spec):
			failed = true
	if not failed:
		_write_before_after()
	quit(1 if failed else 0)

func _build_sheet(spec: Dictionary) -> bool:
	var source := Image.load_from_file(ProjectSettings.globalize_path(str(spec.source)))
	var base := Image.load_from_file(ProjectSettings.globalize_path(str(spec.base)))
	if source.is_empty() or base.is_empty():
		push_error("moves_23: missing source/base for %s" % spec.label)
		return false
	var expected := 0
	for row in spec.rows:
		expected += int(row[1])
	var segmentation := _segment(source)
	var components: Array = segmentation.components
	var main_indices: Array[int] = []
	for index in components.size():
		if int(components[index].count) >= int(spec.main_min):
			main_indices.append(index)
	if main_indices.size() != expected:
		push_error("moves_23: %s expected %d pose components, found %d" % [spec.label, expected, main_indices.size()])
		return false
	main_indices.sort_custom(func(a: int, b: int) -> bool:
		return _center(components[a].bounds).y < _center(components[b].bounds).y
	)
	var ordered: Array[int] = []
	var cursor := 0
	for row in spec.rows:
		var row_indices: Array[int] = []
		for offset in int(row[1]):
			row_indices.append(main_indices[cursor + offset])
		row_indices.sort_custom(func(a: int, b: int) -> bool:
			return _center(components[a].bounds).x < _center(components[b].bounds).x
		)
		ordered.append_array(row_indices)
		cursor += int(row[1])
	var owner := PackedInt32Array()
	owner.resize(components.size())
	owner.fill(-1)
	for frame_index in ordered.size():
		owner[ordered[frame_index]] = frame_index
	for component_index in components.size():
		if owner[component_index] >= 0 or int(components[component_index].count) < 20:
			continue
		var best_frame := -1
		var best_distance := INF
		var point := _center(components[component_index].bounds)
		for frame_index in ordered.size():
			var distance := _distance_to_rect(point, components[ordered[frame_index]].bounds)
			if distance < best_distance:
				best_distance = distance
				best_frame = frame_index
		if best_distance <= 82.0:
			owner[component_index] = best_frame
	var frame_bounds: Array[Rect2i] = []
	for frame_index in ordered.size():
		var bounds: Rect2i = components[ordered[frame_index]].bounds
		for component_index in components.size():
			if owner[component_index] == frame_index:
				bounds = bounds.merge(components[component_index].bounds)
		frame_bounds.append(bounds)
	var scale := Vector2(
		float(CELL * COLUMNS) / float(source.get_width()),
		float(CELL * spec.rows.size()) / float(source.get_height())
	)
	var palette := _canonical_palette(base, 128)
	var atlas := Image.create(CELL * COLUMNS, CELL * (spec.rows.size() + 1), false, Image.FORMAT_RGBA8)
	var measurements := PackedStringArray(["row,frame,x,y,width,height,feet,partial_alpha,source_palette_mean,component_bounds"])
	var frame_cursor := 0
	for row_index in spec.rows.size():
		for column in int(spec.rows[row_index][1]):
			var frame := _render_assigned(source, segmentation.labels, owner, frame_cursor, frame_bounds[frame_cursor], scale, spec.idle_size)
			if bool(spec.snap_palette):
				_map_to_palette(frame, palette, true)
			var palette_mean := _map_to_palette(frame, palette, false)
			frame = _align_bottom(frame, 120)
			atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(column * CELL, row_index * CELL))
			var bounds := _bounds(frame)
			measurements.append("%s,%d,%d,%d,%d,%d,%d,%d,%.3f,%s" % [spec.rows[row_index][0], column, bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y, bounds.end.y - 1, _partial_alpha(frame), palette_mean, frame_bounds[frame_cursor]])
			frame_cursor += 1
	_apply_redraws(str(spec.label), atlas, palette)
	_append_tumble(atlas, base, spec.rows.size(), measurements)
	atlas.save_png(ProjectSettings.globalize_path(str(spec.output)))
	_write_contacts(str(spec.label), base, atlas, spec.rows.size() + 1)
	var csv := FileAccess.open(ProjectSettings.globalize_path("%s/%s_measurements.csv" % [PREVIEW_DIR, spec.label]), FileAccess.WRITE)
	csv.store_string("\n".join(measurements) + "\n")
	csv.close()
	print("moves_23 safe rebuild: %s %dx%d poses=%d scale=%s" % [spec.label, atlas.get_width(), atlas.get_height(), expected, scale])
	return true

func _append_tumble(atlas: Image, base: Image, row: int, measurements: PackedStringArray) -> void:
	var hurt := base.get_region(Rect2i(0, 6 * CELL, CELL, CELL))
	var hurt_bounds := _bounds(hurt)
	var crop := hurt.get_region(hurt_bounds)
	for frame_index in 4:
		var rotated := _rotate_quarter(crop, frame_index)
		var frame := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
		var destination := Vector2i((CELL - rotated.get_width()) / 2, (CELL - rotated.get_height()) / 2)
		frame.blit_rect(rotated, Rect2i(Vector2i.ZERO, rotated.get_size()), destination)
		atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(frame_index * CELL, row * CELL))
		var bounds := _bounds(frame)
		measurements.append("tumble,%d,%d,%d,%d,%d,%d,%d,0,rotated_hurt" % [frame_index, bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y, bounds.end.y - 1, _partial_alpha(frame)])

func _rotate_quarter(source: Image, turns: int) -> Image:
	var normalized := posmod(turns, 4)
	if normalized == 0:
		return source.duplicate()
	var output_size := Vector2i(source.get_height(), source.get_width()) if normalized % 2 == 1 else source.get_size()
	var output := Image.create(output_size.x, output_size.y, false, Image.FORMAT_RGBA8)
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

func _segment(image: Image) -> Dictionary:
	var width := image.get_width()
	var height := image.get_height()
	var labels := PackedInt32Array()
	labels.resize(width * height)
	labels.fill(-1)
	var components: Array[Dictionary] = []
	for y in height:
		for x in width:
			var start := y * width + x
			if labels[start] >= 0 or image.get_pixel(x, y).a < 0.5:
				continue
			var component_index := components.size()
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			labels[start] = component_index
			var bounds := Rect2i(Vector2i(x, y), Vector2i.ONE)
			var count := 0
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				count += 1
				bounds = bounds.expand(point).expand(point + Vector2i.ONE)
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						if ox == 0 and oy == 0:
							continue
						var next := point + Vector2i(ox, oy)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
							continue
						var next_index := next.y * width + next.x
						if labels[next_index] < 0 and image.get_pixelv(next).a >= 0.5:
							labels[next_index] = component_index
							stack.append(next)
			components.append({"count": count, "bounds": bounds})
	return {"labels": labels, "components": components}

func _render_assigned(source: Image, labels: PackedInt32Array, owner: PackedInt32Array, frame_index: int, bounds: Rect2i, scale: Vector2, idle_size: Vector2i) -> Image:
	var crop := Image.create(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
	for y in bounds.size.y:
		for x in bounds.size.x:
			var source_point := bounds.position + Vector2i(x, y)
			var component_index := labels[source_point.y * source.get_width() + source_point.x]
			if component_index >= 0 and owner[component_index] == frame_index:
				var color := source.get_pixelv(source_point)
				crop.set_pixel(x, y, Color(color.r, color.g, color.b, 1.0))
	return _compact_pose(crop, scale, idle_size)

func _compact_pose(source: Image, scale: Vector2, idle_size: Vector2i) -> Image:
	var image := _resize_axis(source, true, scale.x, mini(idle_size.x + 10, MAX_WIDTH), MAX_WIDTH)
	image = _resize_axis(image, false, scale.y, mini(idle_size.y + 4, MAX_HEIGHT), MAX_HEIGHT)
	_harden_alpha(image)
	_remove_strays(image, 3)
	return image

## Preserves the densest body-sized band at the requested scale. Only the outer overflow bands
## (generated arcs, trails and particles) are compacted to fit the safe cell interior.
func _resize_axis(source: Image, horizontal: bool, scale: float, core_target: int, maximum: int) -> Image:
	var source_length := source.get_width() if horizontal else source.get_height()
	var other_length := source.get_height() if horizontal else source.get_width()
	var natural_length := maxi(1, int(round(float(source_length) * scale)))
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
		var score := 0.0
		for secondary in other_length:
			var color := source.get_pixel(primary, secondary) if horizontal else source.get_pixel(secondary, primary)
			if color.a >= 0.5:
				score += 1.0 + (1.0 - color.get_luminance()) * 2.0
		scores[primary] = score
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
	var left_out := 0
	if left_source + right_source > 0:
		left_out = int(round(float(outer_out) * float(left_source) / float(left_source + right_source)))
	var right_out := outer_out - left_out
	var output := Image.create(maximum if horizontal else other_length, other_length if horizontal else maximum, false, Image.FORMAT_RGBA8)
	for target_primary in maximum:
		var source_primary := 0
		if target_primary < left_out and left_out > 0:
			source_primary = mini(left_source - 1, int(floor(float(target_primary) * float(left_source) / float(left_out))))
		elif target_primary < left_out + core_out:
			source_primary = core_start + mini(core_source - 1, int(floor(float(target_primary - left_out) * float(core_source) / float(core_out))))
		elif right_out > 0:
			source_primary = core_start + core_source + mini(right_source - 1, int(floor(float(target_primary - left_out - core_out) * float(right_source) / float(right_out))))
		else:
			source_primary = source_length - 1
		for secondary in other_length:
			if horizontal:
				output.set_pixel(target_primary, secondary, source.get_pixel(source_primary, secondary))
			else:
				output.set_pixel(secondary, target_primary, source.get_pixel(secondary, source_primary))
	return output

func _apply_redraws(label: String, atlas: Image, palette: Array[Color]) -> void:
	if label == "frey":
		var frames := _redraw_frames("res://tests/art_preview/moves_23/frey_redraw_source.png", 6, 100)
		if frames.size() == 6:
			_blit_redraw(atlas, frames[1], 5, 2, palette, true)
			_blit_redraw(atlas, frames[2], 5, 3, palette, true)
			_blit_redraw(atlas, frames[3], 6, 2, palette, true)
			_blit_redraw(atlas, frames[4], 6, 3, palette, true)
	elif label == "luna_brave":
		var frames := _redraw_frames("res://tests/art_preview/moves_23/luna_brave_dive_redraw_source.png", 4, 83)
		if frames.size() == 4:
			for column in 4:
				_blit_redraw(atlas, frames[column], 4, column, palette, false)

func _redraw_frames(path: String, expected: int, target_first_height: int) -> Array[Image]:
	var source := Image.load_from_file(ProjectSettings.globalize_path(path))
	if source.is_empty():
		return []
	var segmentation := _segment(source)
	var components: Array = segmentation.components
	var indices: Array[int] = []
	for index in components.size():
		if int(components[index].count) >= 5000:
			indices.append(index)
	indices.sort_custom(func(a: int, b: int) -> bool: return _center(components[a].bounds).x < _center(components[b].bounds).x)
	if indices.size() != expected:
		push_error("moves_23: redraw %s expected %d components, found %d" % [path.get_file(), expected, indices.size()])
		return []
	var first_height := int(components[indices[0]].bounds.size.y)
	var uniform_scale := float(target_first_height) / float(first_height)
	var frames: Array[Image] = []
	for component_index in indices:
		var bounds: Rect2i = components[component_index].bounds
		var crop := Image.create(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
		for y in bounds.size.y:
			for x in bounds.size.x:
				var point := bounds.position + Vector2i(x, y)
				if segmentation.labels[point.y * source.get_width() + point.x] == component_index:
					var color := source.get_pixelv(point)
					crop.set_pixel(x, y, Color(color.r, color.g, color.b, 1.0))
		frames.append(_compact_pose(crop, Vector2(uniform_scale, uniform_scale), Vector2i(100, target_first_height)))
	return frames

func _blit_redraw(atlas: Image, frame: Image, row: int, column: int, palette: Array[Color], snap_palette: bool) -> void:
	var prepared := frame.duplicate()
	if snap_palette:
		_map_to_palette(prepared, palette, true)
	prepared = _align_bottom(prepared, 120)
	atlas.fill_rect(Rect2i(column * CELL, row * CELL, CELL, CELL), Color(0, 0, 0, 0))
	atlas.blit_rect(prepared, Rect2i(Vector2i.ZERO, prepared.get_size()), Vector2i(column * CELL, row * CELL))

func _align_bottom(image: Image, target: int) -> Image:
	var bounds := _bounds(image)
	if bounds.size == Vector2i.ZERO:
		return Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	var aligned := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	var destination := Vector2i((CELL - image.get_width()) / 2, target - (bounds.end.y - 1))
	aligned.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), destination)
	return aligned

func _write_contacts(label: String, base: Image, atlas: Image, row_count: int) -> void:
	var contact := Image.create(CELL * (COLUMNS + 1), CELL * row_count, false, Image.FORMAT_RGBA8)
	var idle := base.get_region(Rect2i(0, 0, CELL, CELL))
	for row in row_count:
		contact.blit_rect(idle, Rect2i(0, 0, CELL, CELL), Vector2i(0, row * CELL))
		contact.blit_rect(atlas, Rect2i(0, row * CELL, CELL * COLUMNS, CELL), Vector2i(CELL, row * CELL))
	contact.save_png(ProjectSettings.globalize_path("%s/%s_moves_contact_1x.png" % [PREVIEW_DIR, label]))
	var enlarged := contact.duplicate()
	enlarged.resize(contact.get_width() * 4, contact.get_height() * 4, Image.INTERPOLATE_NEAREST)
	enlarged.save_png(ProjectSettings.globalize_path("%s/%s_moves_contact_4x.png" % [PREVIEW_DIR, label]))

func _write_before_after() -> void:
	var specs := [
		["res://tests/art_preview/moves_23/before_edge_fix_frey_moves_sheet.png", "res://assets/art/frey/frey_moves_sheet.png", [Vector2i(2,0),Vector2i(3,0),Vector2i(2,1),Vector2i(3,1),Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6)]],
		["res://tests/art_preview/moves_23/before_edge_fix_luna_moves_sheet.png", "res://assets/art/luna/luna_moves_sheet.png", [Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(0,2),Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4)]],
		["res://tests/art_preview/moves_23/before_edge_fix_luna_brave_moves_sheet.png", "res://assets/art/luna/luna_brave_moves_sheet.png", [Vector2i(0,2),Vector2i(1,2),Vector2i(2,2),Vector2i(2,3),Vector2i(2,5),Vector2i(3,5),Vector2i(1,6),Vector2i(2,6),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7)]],
	]
	var total := 0
	for spec in specs:
		total += spec[2].size()
	var pair_columns := 8
	var rows := ceili(float(total) / float(pair_columns))
	var board := Image.create(pair_columns * CELL * 2, rows * CELL, false, Image.FORMAT_RGBA8)
	var cursor := 0
	for spec in specs:
		var before := Image.load_from_file(ProjectSettings.globalize_path(spec[0]))
		var after := Image.load_from_file(ProjectSettings.globalize_path(spec[1]))
		for cell in spec[2]:
			var destination := Vector2i((cursor % pair_columns) * CELL * 2, (cursor / pair_columns) * CELL)
			var rect := Rect2i(cell.x * CELL, cell.y * CELL, CELL, CELL)
			board.blit_rect(before, rect, destination)
			board.blit_rect(after, rect, destination + Vector2i(CELL, 0))
			cursor += 1
	board.save_png(ProjectSettings.globalize_path("%s/edge_fix_before_after_1x.png" % PREVIEW_DIR))

func _canonical_palette(image: Image, limit: int) -> Array[Color]:
	var counts := {}
	var colors := {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := _rgb_key(color)
			counts[key] = int(counts.get(key, 0)) + 1
			colors[key] = color
	var ranked: Array = counts.keys()
	ranked.sort_custom(func(a: Variant, b: Variant) -> bool: return int(counts[a]) > int(counts[b]))
	var palette: Array[Color] = []
	for index in mini(limit, ranked.size()):
		palette.append(colors[ranked[index]])
	return palette

func _map_to_palette(image: Image, palette: Array[Color], apply: bool) -> float:
	var cache := {}
	var distance_sum := 0.0
	var visible := 0
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := _rgb_key(color)
			var mapped: Color
			var distance := 0.0
			if cache.has(key):
				mapped = cache[key][0]
				distance = float(cache[key][1])
			else:
				var best := INF
				mapped = palette[0]
				for candidate in palette:
					var d := Vector3(color.r - candidate.r, color.g - candidate.g, color.b - candidate.b).length() * 255.0
					if d < best:
						best = d
						mapped = candidate
				distance = best
				cache[key] = [mapped, distance]
			if apply:
				image.set_pixel(x, y, Color(mapped.r, mapped.g, mapped.b, 1.0))
			distance_sum += distance
			visible += 1
	return distance_sum / maxf(float(visible), 1.0)

func _harden_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(0, 0, 0, 0) if color.a < 0.5 else Color(color.r, color.g, color.b, 1.0))

func _remove_strays(image: Image, minimum: int) -> void:
	var segmentation := _segment(image)
	for y in image.get_height():
		for x in image.get_width():
			var component_index: int = int(segmentation.labels[y * image.get_width() + x])
			if component_index >= 0 and int(segmentation.components[component_index].count) < minimum:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _bounds(image: Image) -> Rect2i:
	var rect := Rect2i()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.5:
				var point := Vector2i(x, y)
				rect = Rect2i(point, Vector2i.ONE) if rect.size == Vector2i.ZERO else rect.expand(point).expand(point + Vector2i.ONE)
	return rect

func _partial_alpha(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var alpha := image.get_pixel(x, y).a
			if alpha > 0.0 and alpha < 1.0:
				count += 1
	return count

func _center(rect: Rect2i) -> Vector2:
	return Vector2(rect.position) + Vector2(rect.size) * 0.5

func _distance_to_rect(point: Vector2, rect: Rect2i) -> float:
	var closest := Vector2(clampf(point.x, rect.position.x, rect.end.x), clampf(point.y, rect.position.y, rect.end.y))
	return point.distance_to(closest)

func _rgb_key(color: Color) -> int:
	return int(round(color.r * 255.0)) << 16 | int(round(color.g * 255.0)) << 8 | int(round(color.b * 255.0))
