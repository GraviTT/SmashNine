extends SceneTree

const CELL := 128
const COLUMNS := 6
const ROWS := 8
const PREVIEW_DIR := "res://tests/art_preview/moves_26"
const SAFE_MIN := 4
const SAFE_MAX := 123

const SPECS: Array[Dictionary] = [
	{
		"id": "nova_male",
		"source": "res://assets/art/nova/nova_male_moves_source.png",
		"live": "res://assets/art/nova/nova_male_sheet.png",
		"output": "res://assets/art/nova/nova_male_moves_sheet.png",
		"counts": [4, 4, 4, 4, 5, 4, 5, 6],
		"air_rows": [3, 4, 5],
	},
	{
		"id": "nova_female",
		"source": "res://assets/art/nova/nova_female_moves_source.png",
		"live": "res://assets/art/nova/nova_female_sheet.png",
		"output": "res://assets/art/nova/nova_female_moves_sheet.png",
		"counts": [4, 4, 4, 4, 5, 4, 5, 6],
		"air_rows": [3, 4, 5],
	},
	{
		"id": "yuki",
		"source": "res://assets/art/yuki/yuki_moves_source.png",
		"live": "res://assets/art/yuki/yuki_sheet.png",
		"output": "res://assets/art/yuki/yuki_moves_sheet.png",
		"counts": [4, 4, 4, 4, 4, 5, 5, 6],
		"air_rows": [3, 4, 5],
	},
	{
		"id": "rio_male",
		"source": "res://assets/art/rio/rio_male_moves_source.png",
		"live": "res://assets/art/rio/rio_male_sheet.png",
		"output": "res://assets/art/rio/rio_male_moves_sheet.png",
		"counts": [6, 4, 4, 4, 5, 5, 6, 6],
		"air_rows": [3, 4, 5],
	},
	{
		"id": "rio_female",
		"source": "res://assets/art/rio/rio_female_moves_source.png",
		"live": "res://assets/art/rio/rio_female_sheet.png",
		"output": "res://assets/art/rio/rio_female_moves_sheet.png",
		"counts": [6, 4, 4, 4, 5, 5, 6, 6],
		"air_rows": [3, 4, 5],
	},
]

var metrics_lines: PackedStringArray = PackedStringArray([
	"sheet,row,column,used,feet_y,bounds_height,dark_body_height,idle_dark_delta,partial_alpha,palette_distance"
])


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))
	for spec: Dictionary in SPECS:
		_build_sheet(spec)
	var metrics_path := ProjectSettings.globalize_path(PREVIEW_DIR + "/measurements.csv")
	var file := FileAccess.open(metrics_path, FileAccess.WRITE)
	file.store_string("\n".join(metrics_lines) + "\n")
	file.close()
	print("MOVES_26_BUILD_OK sheets=%d metrics=%s" % [SPECS.size(), metrics_path])
	quit()


func _build_sheet(spec: Dictionary) -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(String(spec.source)))
	var live := Image.load_from_file(ProjectSettings.globalize_path(String(spec.live)))
	assert(source != null and not source.is_empty(), "missing source: " + String(spec.source))
	assert(live != null and not live.is_empty(), "missing live sheet: " + String(spec.live))
	assert(live.get_width() == CELL * COLUMNS, "live sheet must use 128px cells")
	var row_edges := _find_row_edges(source)
	var source_cell_width := source.get_width() / COLUMNS
	assert(source_cell_width >= CELL, "source cells must not be upscaled")
	var extracted := _extract_connected_frames(source, row_edges, spec.counts)

	var live_idle := live.get_region(Rect2i(0, 0, CELL, CELL))
	var live_jump := live.get_region(Rect2i(0, CELL * 2, CELL, CELL))
	var idle_bounds := live_idle.get_used_rect()
	var jump_bounds := _dark_body_rect(live_jump)
	var jump_centroid := _dark_body_centroid(live_jump)
	var source_idle: Image = extracted[0]
	var source_idle_bounds := source_idle.get_used_rect()
	assert(source_idle_bounds.size.y > 0, "source idle is empty")
	var live_idle_core := _main_dark_component_rect(live_idle)
	var source_idle_core := _main_dark_component_rect(source_idle)
	var scale := float(live_idle_core.size.y) / float(source_idle_core.size.y)
	assert(scale <= 1.0, "would upscale source: %s scale=%.3f" % [spec.id, scale])

	var sheet := Image.create_empty(CELL * COLUMNS, CELL * ROWS, false, Image.FORMAT_RGBA8)
	var palette := _top_palette(live, 96)
	var idle_dark_height := _dark_body_height(live_idle)
	for row in ROWS:
		var is_air: bool = row in spec.air_rows
		for column in COLUMNS:
			var used: bool = column < int(spec.counts[row])
			if not used:
				_metrics_for_frame(spec.id, row, column, false, Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8), idle_dark_height, palette)
				continue
			var source_frame: Image = extracted[row * COLUMNS + column]
			assert(not source_frame.is_empty(), "%s r%dc%d extraction empty" % [spec.id, row, column])
			var scaled_size := Vector2i(
				maxi(1, roundi(source_frame.get_width() * scale)),
				maxi(1, roundi(source_frame.get_height() * scale))
			)
			source_frame.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_NEAREST)
			_harden_alpha(source_frame)
			var frame := _fit_frame_without_cutting_body(
				source_frame, is_air, idle_bounds, jump_centroid
			)
			_remove_compressed_effect_combs(frame)
			_soften_compressed_effect_edge(frame)
			_remove_tiny_islands(frame, 8)
			_harden_alpha(frame)
			sheet.blit_rect(frame, Rect2i(0, 0, CELL, CELL), Vector2i(column * CELL, row * CELL))
			_metrics_for_frame(spec.id, row, column, true, frame, idle_dark_height, palette)
	_repair_generated_body_omissions(sheet, spec.counts, live_idle_core.size.y, String(spec.id))
	var stripe_before := sheet.duplicate()
	var changed_cells := _clean_sheet_stripes(sheet, spec.counts)
	_make_stripe_before_after(String(spec.id), stripe_before, sheet, changed_cells)

	var output_path := ProjectSettings.globalize_path(String(spec.output))
	var before_path := ProjectSettings.globalize_path("%s/%s_before_sheet.png" % [PREVIEW_DIR, spec.id])
	if not FileAccess.file_exists(before_path):
		var before := Image.load_from_file(output_path)
		if before != null and not before.is_empty():
			assert(before.save_png(before_path) == OK)
	assert(sheet.save_png(output_path) == OK, "failed to save " + output_path)
	_make_contacts(String(spec.id), sheet, live_idle)
	_make_before_after(String(spec.id), sheet)
	print("BUILT %s source=%dx%d source_cell_width=%d scale=%.4f row_edges=%s output=%dx%d" % [
		spec.id, source.get_width(), source.get_height(), source_cell_width,
		scale, str(row_edges), sheet.get_width(), sheet.get_height()
	])
	print("STRIPE_CLEANED %s cells=%s" % [spec.id, str(changed_cells)])


## ImageGen does not keep each pose inside an equal-width tile.  Extract every connected
## component from the complete source, then assign the whole component to the nearest intended
## pose.  This is deliberately done before fitting: no body, weapon, or effect is sliced at a
## nominal column/row boundary.
func _extract_connected_frames(source: Image, row_edges: PackedInt32Array, counts: Array) -> Dictionary:
	_harden_alpha(source)
	var visited := PackedByteArray()
	visited.resize(source.get_width() * source.get_height())
	var row_centres := PackedFloat32Array()
	for row in ROWS:
		row_centres.append((row_edges[row] + row_edges[row + 1]) * 0.5)
	var components: Array[Dictionary] = []
	for y in source.get_height():
		for x in source.get_width():
			var start_index := y * source.get_width() + x
			if visited[start_index] != 0 or source.get_pixel(x, y).a < 0.5:
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			var component: Array[Vector2i] = []
			var dark_total := Vector2.ZERO
			var dark_count := 0
			var total := Vector2.ZERO
			visited[start_index] = 1
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				component.append(point)
				total += Vector2(point)
				if source.get_pixelv(point).get_luminance() < 0.58:
					dark_total += Vector2(point)
					dark_count += 1
				for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = point + direction
					if next.x < 0 or next.y < 0 or next.x >= source.get_width() or next.y >= source.get_height():
						continue
					var next_index: int = next.y * source.get_width() + next.x
					if visited[next_index] != 0 or source.get_pixelv(next).a < 0.5:
						continue
					visited[next_index] = 1
					stack.append(next)
			if component.size() < 3:
				continue
			var bounds := Rect2i(component[0], Vector2i.ONE)
			for point: Vector2i in component:
				bounds = bounds.expand(point).expand(point + Vector2i.ONE)
			components.append({
				"pixels": component,
				"dark_count": dark_count,
				"dark_centre": dark_total / float(dark_count) if dark_count > 0 else total / float(component.size()),
				"centre": total / float(component.size()),
				"bounds": bounds,
			})

	# Pick the body-bearing connected component inside each nominal slot first.  The nominal slot
	# is used only to identify the body; the selected component is kept whole even when its pose or
	# effect extends across that slot.  Already selected components cannot steal the next frame.
	var seeds: Array[Dictionary] = []
	var selected_components: Dictionary = {}
	var nominal_width := float(source.get_width()) / float(COLUMNS)
	for row in ROWS:
		for column in int(counts[row]):
			var best_component: Dictionary = {}
			var best_score := 0
			var slot := Rect2(
				Vector2(column * nominal_width, row_edges[row]),
				Vector2(nominal_width, row_edges[row + 1] - row_edges[row])
			)
			for component_index in components.size():
				if selected_components.has(component_index):
					continue
				var component: Dictionary = components[component_index]
				var score := 0
				for point: Vector2i in component.pixels:
					if slot.has_point(Vector2(point)) and source.get_pixelv(point).get_luminance() < 0.58:
						score += 1
				if score > best_score:
					best_score = score
					best_component = component
					best_component["component_index"] = component_index
			assert(not best_component.is_empty(), "no body component in r%dc%d" % [row, column])
			selected_components[int(best_component.component_index)] = true
			best_component["key"] = row * COLUMNS + column
			seeds.append(best_component)

	var groups: Dictionary = {}
	for seed: Dictionary in seeds:
		groups[int(seed.key)] = []
	for component_index in components.size():
		var component: Dictionary = components[component_index]
		var component_bounds: Rect2i = component.bounds
		if not selected_components.has(component_index) and (
			component.pixels.size() < 24
			or mini(component_bounds.size.x, component_bounds.size.y) <= 2
		):
			continue
		var centre: Vector2 = component.dark_centre if int(component.dark_count) > 0 else component.centre
		var nearest_seed: Dictionary = seeds[0]
		var nearest_distance := INF
		for seed: Dictionary in seeds:
			var seed_centre: Vector2 = seed.dark_centre
			var distance := centre.distance_squared_to(seed_centre)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_seed = seed
		var pixels: Array = groups[int(nearest_seed.key)]
		pixels.append_array(component.pixels)
		groups[int(nearest_seed.key)] = pixels
	var result: Dictionary = {}
	for key in groups:
		var pixels: Array = groups[key]
		assert(not pixels.is_empty(), "connected extraction produced an empty used cell %d" % key)
		var bounds := Rect2i(pixels[0], Vector2i.ONE)
		for point: Vector2i in pixels:
			bounds = bounds.expand(point).expand(point + Vector2i.ONE)
		var frame := Image.create_empty(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
		for point: Vector2i in pixels:
			frame.set_pixelv(point - bounds.position, source.get_pixelv(point))
		result[key] = frame
	return result


## A few generated rows contain an effect-only slot rather than the requested body pose.  Keep
## that slot's own effect, but restore a full-size body from the nearest pose in the same row.
## This is intentionally limited to objectively empty-body cells (under 55% idle body height).
func _repair_generated_body_omissions(sheet: Image, counts: Array, idle_core_height: int, id: String) -> void:
	for row in ROWS:
		for column in int(counts[row]):
			var rect := Rect2i(column * CELL, row * CELL, CELL, CELL)
			var frame := sheet.get_region(rect)
			var core := _main_dark_component_rect(frame)
			if core.size.y >= roundi(idle_core_height * 0.55):
				continue
			var donor := Image.new()
			for offset in range(1, int(counts[row])):
				for donor_column in [column - offset, column + offset]:
					if donor_column < 0 or donor_column >= int(counts[row]):
						continue
					var candidate := sheet.get_region(Rect2i(donor_column * CELL, row * CELL, CELL, CELL))
					if _main_dark_component_rect(candidate).size.y >= roundi(idle_core_height * 0.55):
						donor = candidate
						break
				if not donor.is_empty():
					break
			assert(not donor.is_empty(), "%s r%dc%d has no donor body" % [id, row, column])
			var donor_core := _main_dark_component_rect(donor).grow(6).intersection(Rect2i(Vector2i.ZERO, Vector2i(CELL, CELL)))
			frame.blit_rect(donor, donor_core, donor_core.position)
			sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), rect.position)
			print("REPAIRED_GENERATED_BODY_OMISSION %s r%dc%d" % [id, row, column])


## Preserve the body-sized centre at the common scale.  Only the space outside the main dark
## body component is compressed toward the 4 px safe margin when an effect is too large.
func _fit_frame_without_cutting_body(source: Image, is_air: bool, idle_bounds: Rect2i, jump_centroid: Vector2) -> Image:
	var core := _main_dark_component_rect(source)
	assert(core.size != Vector2i.ZERO, "frame has no body component")
	core = core.grow(4).intersection(Rect2i(Vector2i.ZERO, source.get_size()))
	var target_anchor := jump_centroid if is_air else Vector2(idle_bounds.position.x + idle_bounds.size.x * 0.5, 120.0)
	var source_anchor := _dark_body_centroid(source) if is_air else Vector2(core.position.x + core.size.x * 0.5, core.end.y - 1)
	var destination := target_anchor - source_anchor
	var ideal_min := destination
	var ideal_max := destination + Vector2(source.get_size() - Vector2i.ONE)
	var core_min := destination + Vector2(core.position)
	var core_max := destination + Vector2(core.end - Vector2i.ONE)
	var frame := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
	var max_y := SAFE_MAX if is_air else 120
	for y in source.get_height():
		for x in source.get_width():
			var pixel: Color = source.get_pixel(x, y)
			if pixel.a < 0.5:
				continue
			var ideal := destination + Vector2(x, y)
			var mapped := Vector2(
				_map_outer(ideal.x, ideal_min.x, ideal_max.x, core_min.x, core_max.x, SAFE_MIN, SAFE_MAX),
				_map_outer(ideal.y, ideal_min.y, ideal_max.y, core_min.y, core_max.y, SAFE_MIN, max_y)
			)
			var point := Vector2i(clampi(roundi(mapped.x), SAFE_MIN, SAFE_MAX), clampi(roundi(mapped.y), SAFE_MIN, max_y))
			frame.set_pixelv(point, pixel)
	return frame


func _map_outer(value: float, full_min: float, full_max: float, core_min: float, core_max: float, safe_min: int, safe_max: int) -> float:
	if value < core_min and core_min > full_min:
		return lerpf(float(safe_min), core_min, (value - full_min) / (core_min - full_min))
	if value > core_max and full_max > core_max:
		return lerpf(core_max, float(safe_max), (value - core_max) / (full_max - core_max))
	return value


func _main_dark_component_rect(image: Image) -> Rect2i:
	var visited := PackedByteArray()
	visited.resize(image.get_width() * image.get_height())
	var best := Rect2i()
	var best_count := 0
	for y in image.get_height():
		for x in image.get_width():
			var index := y * image.get_width() + x
			var pixel := image.get_pixel(x, y)
			if visited[index] != 0 or pixel.a < 0.5 or pixel.get_luminance() >= 0.58:
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			var bounds := Rect2i(Vector2i(x, y), Vector2i.ONE)
			var count := 0
			visited[index] = 1
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				count += 1
				bounds = bounds.expand(point).expand(point + Vector2i.ONE)
				for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
					var next: Vector2i = point + direction
					if next.x < 0 or next.y < 0 or next.x >= image.get_width() or next.y >= image.get_height():
						continue
					var next_index: int = next.y * image.get_width() + next.x
					var next_pixel := image.get_pixelv(next)
					if visited[next_index] != 0 or next_pixel.a < 0.5 or next_pixel.get_luminance() >= 0.58:
						continue
					visited[next_index] = 1
					stack.append(next)
			if count > best_count:
				best_count = count
				best = bounds
	return best


func _find_row_edges(source: Image) -> PackedInt32Array:
	var height := source.get_height()
	var dark_coverage := PackedInt32Array()
	dark_coverage.resize(height)
	for y in height:
		var count := 0
		for x in range(0, source.get_width(), 2):
			var pixel := source.get_pixel(x, y)
			if pixel.a >= 0.42 and pixel.get_luminance() < 0.62:
				count += 1
		dark_coverage[y] = count
	var edges := PackedInt32Array([0])
	var average_row := float(height) / float(ROWS)
	for boundary in range(1, ROWS):
		var expected := roundi(average_row * boundary)
		var radius := maxi(12, roundi(average_row * 0.28))
		var start := maxi(edges[-1] + 24, expected - radius)
		var finish := mini(height - 24, expected + radius)
		var best_y := expected
		var best_score := 1 << 30
		for y in range(start, finish + 1):
			var score := 0
			for sample_y in range(maxi(0, y - 2), mini(height, y + 3)):
				score += dark_coverage[sample_y]
			if score < best_score:
				best_score = score
				best_y = y
		edges.append(best_y)
	edges.append(height)
	return edges


func _harden_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.42:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				pixel.a = 1.0
				image.set_pixel(x, y, pixel)


## Large generated trails are compressed into the 4 px safe area.  Keep the dark body/weapon
## pixels verbatim, but break up the last twelve pixels of bright effects with a deterministic
## hard-alpha dither so the trail tapers instead of ending on a rectangular clipping line.
func _soften_compressed_effect_edge(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.5 or pixel.get_luminance() < 0.58:
				continue
			var edge_distance := mini(mini(x - SAFE_MIN, SAFE_MAX - x), mini(y - SAFE_MIN, SAFE_MAX - y))
			if edge_distance < 0 or edge_distance > 11:
				continue
			var pattern := posmod(x * 13 + y * 7 + x * y * 3, 17)
			var keep_threshold: int = mini(16, 2 + edge_distance * 2)
			if pattern >= keep_threshold:
				image.set_pixel(x, y, Color(0, 0, 0, 0))


## Forward compression can leave one-pixel comb teeth parallel to a cell edge.  Remove only
## bright effect pixels in the outer band that have no thickness on one axis; centered bodies,
## dark outlines and weapons are outside this rule.
func _remove_compressed_effect_combs(image: Image) -> void:
	var source := image.duplicate()
	var protected_core := _main_dark_component_rect(source).grow(4)
	for y in image.get_height():
		for x in image.get_width():
			var pixel: Color = source.get_pixel(x, y)
			if pixel.a < 0.5 or protected_core.has_point(Vector2i(x, y)):
				continue
			var edge_distance := mini(mini(x - SAFE_MIN, SAFE_MAX - x), mini(y - SAFE_MIN, SAFE_MAX - y))
			if edge_distance < 0 or edge_distance > 23:
				continue
			var horizontal_support := 0
			var vertical_support := 0
			for offset in range(-2, 3):
				var hx := x + offset
				var vy := y + offset
				if hx >= 0 and hx < image.get_width():
					var horizontal_pixel: Color = source.get_pixel(hx, y)
					if horizontal_pixel.a >= 0.5:
						horizontal_support += 1
				if vy >= 0 and vy < image.get_height():
					var vertical_pixel: Color = source.get_pixel(x, vy)
					if vertical_pixel.a >= 0.5:
						vertical_support += 1
			if horizontal_support <= 2 or vertical_support <= 2:
				image.set_pixel(x, y, Color(0, 0, 0, 0))


func _blit_clipped(target: Image, source: Image, destination: Vector2i) -> void:
	var source_rect := Rect2i(Vector2i.ZERO, source.get_size())
	if destination.x < 0:
		source_rect.position.x = -destination.x
		source_rect.size.x -= source_rect.position.x
		destination.x = 0
	if destination.y < 0:
		source_rect.position.y = -destination.y
		source_rect.size.y -= source_rect.position.y
		destination.y = 0
	source_rect.size.x = mini(source_rect.size.x, target.get_width() - destination.x)
	source_rect.size.y = mini(source_rect.size.y, target.get_height() - destination.y)
	if source_rect.size.x > 0 and source_rect.size.y > 0:
		target.blit_rect(source, source_rect, destination)


func _remove_tiny_islands(image: Image, minimum_pixels: int) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	for y in height:
		for x in width:
			var start_index := y * width + x
			if visited[start_index] != 0 or image.get_pixel(x, y).a < 0.5:
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			var component: Array[Vector2i] = []
			visited[start_index] = 1
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				component.append(point)
				for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = point + direction
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var next_index: int = next.y * width + next.x
					if visited[next_index] != 0 or image.get_pixelv(next).a < 0.5:
						continue
					visited[next_index] = 1
					stack.append(next)
			if component.size() < minimum_pixels:
				for point in component:
					image.set_pixelv(point, Color(0, 0, 0, 0))


## Remove compression slivers after all body restoration is complete.  Whole thin detached
## components are discarded.  Isolated 1 px runs are removed only outside the main dark body
## rectangle; this leaves the authored body pixels untouched and turns the surrounding effect
## contour into an irregular, dithered edge rather than a straight generated stripe.
func _clean_sheet_stripes(sheet: Image, counts: Array) -> Array[String]:
	var changed: Array[String] = []
	for row in ROWS:
		for column in int(counts[row]):
			var rect := Rect2i(column * CELL, row * CELL, CELL, CELL)
			var frame := sheet.get_region(rect)
			var before_data := frame.get_data()
			for _pass in 4:
				var pass_changed := _remove_thin_stripe_components(frame)
				pass_changed = _remove_isolated_stripe_runs(frame) or pass_changed
				if not pass_changed:
					break
			if frame.get_data() != before_data:
				changed.append("r%dc%d" % [row + 1, column + 1])
				sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), rect.position)
	return changed


func _remove_thin_stripe_components(image: Image) -> bool:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var changed := false
	var directions: Array[Vector2i] = [
		Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
	]
	for y in height:
		for x in width:
			var start_index := y * width + x
			if visited[start_index] != 0 or image.get_pixel(x, y).a < 0.5:
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			var component: Array[Vector2i] = []
			var bounds := Rect2i(Vector2i(x, y), Vector2i.ONE)
			visited[start_index] = 1
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				component.append(point)
				bounds = bounds.expand(point).expand(point + Vector2i.ONE)
				for direction: Vector2i in directions:
					var next := point + direction
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var next_index := next.y * width + next.x
					if visited[next_index] != 0 or image.get_pixelv(next).a < 0.5:
						continue
					visited[next_index] = 1
					stack.append(next)
			if (bounds.size.x <= 2 and bounds.size.y >= 4) or (bounds.size.y <= 2 and bounds.size.x >= 4):
				for point: Vector2i in component:
					image.set_pixelv(point, Color(0, 0, 0, 0))
				changed = true
	return changed


func _remove_isolated_stripe_runs(image: Image) -> bool:
	var source := image.duplicate()
	var protected_body := _main_dark_component_rect(source).grow(6)
	var remove: Dictionary = {}
	for x in source.get_width():
		var y := 0
		while y < source.get_height():
			if source.get_pixel(x, y).a < 0.5:
				y += 1
				continue
			var start := y
			while y < source.get_height() and source.get_pixel(x, y).a >= 0.5:
				y += 1
			if y - start < 6:
				continue
			var clear := true
			for sample_y in range(start, y):
				if protected_body.has_point(Vector2i(x, sample_y)) or (x > 0 and source.get_pixel(x - 1, sample_y).a >= 0.5) or (x + 1 < source.get_width() and source.get_pixel(x + 1, sample_y).a >= 0.5):
					clear = false
					break
			if clear:
				for sample_y in range(start, y):
					remove[Vector2i(x, sample_y)] = true
	for y in source.get_height():
		var x := 0
		while x < source.get_width():
			if source.get_pixel(x, y).a < 0.5:
				x += 1
				continue
			var start := x
			while x < source.get_width() and source.get_pixel(x, y).a >= 0.5:
				x += 1
			if x - start < 6:
				continue
			var clear := true
			for sample_x in range(start, x):
				if protected_body.has_point(Vector2i(sample_x, y)) or (y > 0 and source.get_pixel(sample_x, y - 1).a >= 0.5) or (y + 1 < source.get_height() and source.get_pixel(sample_x, y + 1).a >= 0.5):
					clear = false
					break
			if clear:
				for sample_x in range(start, x):
					remove[Vector2i(sample_x, y)] = true
	for point: Vector2i in remove:
		image.set_pixelv(point, Color(0, 0, 0, 0))
	return not remove.is_empty()


func _make_stripe_before_after(id: String, before: Image, after: Image, cells: Array[String]) -> void:
	if cells.is_empty():
		return
	var board := Image.create_empty(CELL * 2, CELL * cells.size(), false, Image.FORMAT_RGBA8)
	for index in cells.size():
		var pieces := cells[index].trim_prefix("r").split("c")
		var row := int(pieces[0]) - 1
		var column := int(pieces[1]) - 1
		var rect := Rect2i(column * CELL, row * CELL, CELL, CELL)
		board.blit_rect(before, rect, Vector2i(0, index * CELL))
		board.blit_rect(after, rect, Vector2i(CELL, index * CELL))
	var path := ProjectSettings.globalize_path("%s/%s_stripe_changed_before_after.png" % [PREVIEW_DIR, id])
	assert(board.save_png(path) == OK, "failed to save stripe comparison: " + path)


func _make_contacts(id: String, sheet: Image, idle: Image) -> void:
	var contact := Image.create_empty(CELL * 7, CELL * ROWS, false, Image.FORMAT_RGBA8)
	for row in ROWS:
		contact.blit_rect(idle, Rect2i(0, 0, CELL, CELL), Vector2i(0, row * CELL))
		var strip := sheet.get_region(Rect2i(0, row * CELL, CELL * COLUMNS, CELL))
		contact.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(CELL, row * CELL))
	var path_1x := ProjectSettings.globalize_path("%s/%s_contact_1x.png" % [PREVIEW_DIR, id])
	assert(contact.save_png(path_1x) == OK)
	contact.resize(contact.get_width() * 4, contact.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var path_4x := ProjectSettings.globalize_path("%s/%s_contact_4x.png" % [PREVIEW_DIR, id])
	assert(contact.save_png(path_4x) == OK)


func _make_before_after(id: String, after: Image) -> void:
	var before_path := ProjectSettings.globalize_path("%s/%s_before_sheet.png" % [PREVIEW_DIR, id])
	var before := Image.load_from_file(before_path)
	assert(before != null and not before.is_empty(), "missing before sheet: " + before_path)
	var comparison := Image.create_empty(before.get_width() + after.get_width(), maxi(before.get_height(), after.get_height()), false, Image.FORMAT_RGBA8)
	comparison.blit_rect(before, Rect2i(Vector2i.ZERO, before.get_size()), Vector2i.ZERO)
	comparison.blit_rect(after, Rect2i(Vector2i.ZERO, after.get_size()), Vector2i(before.get_width(), 0))
	var path := ProjectSettings.globalize_path("%s/%s_before_after.png" % [PREVIEW_DIR, id])
	assert(comparison.save_png(path) == OK)


func _dark_body_height(image: Image) -> int:
	return _dark_body_rect(image).size.y


func _dark_body_rect(image: Image) -> Rect2i:
	var mask := Image.create_empty(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a >= 0.5 and pixel.get_luminance() < 0.58:
				mask.set_pixel(x, y, Color.WHITE)
	return mask.get_used_rect()


func _dark_body_centroid(image: Image) -> Vector2:
	var total := Vector2.ZERO
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a >= 0.5 and pixel.get_luminance() < 0.58:
				total += Vector2(x, y)
				count += 1
	return total / float(maxi(count, 1))


func _top_palette(image: Image, limit: int) -> Array[Color]:
	var frequencies: Dictionary = {}
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.5:
				continue
			var key := (int(pixel.r * 255.0) << 16) | (int(pixel.g * 255.0) << 8) | int(pixel.b * 255.0)
			frequencies[key] = int(frequencies.get(key, 0)) + 1
	var keys: Array = frequencies.keys()
	keys.sort_custom(func(a: int, b: int) -> bool: return int(frequencies[a]) > int(frequencies[b]))
	var palette: Array[Color] = []
	for index in mini(limit, keys.size()):
		var key: int = keys[index]
		palette.append(Color(float((key >> 16) & 255) / 255.0, float((key >> 8) & 255) / 255.0, float(key & 255) / 255.0))
	return palette


func _palette_distance(image: Image, palette: Array[Color]) -> float:
	var total := 0.0
	var samples := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.5:
				continue
			var best := 999.0
			for reference in palette:
				var distance := Vector3(pixel.r - reference.r, pixel.g - reference.g, pixel.b - reference.b).length() * 255.0
				best = minf(best, distance)
			total += best
			samples += 1
	return total / float(maxi(samples, 1))


func _partial_alpha_count(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var alpha := image.get_pixel(x, y).a
			if alpha > 0.0 and alpha < 1.0:
				count += 1
	return count


func _metrics_for_frame(id: String, row: int, column: int, used: bool, frame: Image, idle_dark_height: int, palette: Array[Color]) -> void:
	var bounds := frame.get_used_rect()
	var feet_y := bounds.end.y - 1 if bounds.size != Vector2i.ZERO else -1
	var dark_height := _dark_body_height(frame)
	metrics_lines.append("%s,%d,%d,%s,%d,%d,%d,%d,%d,%.2f" % [
		id, row, column, str(used).to_lower(), feet_y, bounds.size.y, dark_height,
		dark_height - idle_dark_height, _partial_alpha_count(frame), _palette_distance(frame, palette) if used else 0.0
	])
