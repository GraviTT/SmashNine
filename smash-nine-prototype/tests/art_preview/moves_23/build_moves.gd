extends SceneTree
## Legacy fixed-grid builder retained for audit history only. It is deliberately disabled because
## generated poses do not occupy equal cells; use rebuild_safe_sheets.gd (connected components).

const CELL := 128
const COLUMNS := 6
const BASE := "res://assets/art/frey/frey_sheet.png"
const SOURCE := "res://assets/art/frey/frey_moves_source.png"
const OUTPUT := "res://assets/art/frey/frey_moves_sheet.png"
const PREVIEW_DIR := "res://tests/art_preview/moves_23"
const ROWS := [
	["attack_up", 4],
	["attack_down", 4],
	["attack_air_side", 4],
	["dash_strike", 4],
	["rising_cleave", 5],
	["spike_followup", 4],
	["descent", 6],
]

func _initialize() -> void:
	push_error("moves_23: fixed-grid builder disabled; run rebuild_safe_sheets.gd")
	quit(1)

func _legacy_initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	var base := Image.load_from_file(ProjectSettings.globalize_path(BASE))
	if source.is_empty() or base.is_empty():
		push_error("moves_23: missing Frey source or base sheet")
		quit(1)
		return
	var source_cell_width := float(source.get_width()) / float(COLUMNS)
	var source_cell_height := float(source.get_height()) / float(ROWS.size())
	if source_cell_width < CELL or source_cell_height < CELL:
		push_error("moves_23: refusing to upscale %.1fx%.1f source cells to %dpx" % [source_cell_width, source_cell_height, CELL])
		quit(1)
		return
	var palette := _canonical_palette(base, 128)
	var atlas := Image.create(CELL * COLUMNS, CELL * ROWS.size(), false, Image.FORMAT_RGBA8)
	var measurements := PackedStringArray(["row,frame,x,y,width,height,feet,partial_alpha,source_palette_mean"])
	for row in ROWS.size():
		for column in int(ROWS[row][1]):
			var x0 := int(floor(float(column) * source_cell_width))
			var x1 := int(floor(float(column + 1) * source_cell_width))
			var y0 := int(floor(float(row) * source_cell_height))
			var y1 := int(floor(float(row + 1) * source_cell_height))
			var frame := source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
			frame.resize(CELL, CELL, Image.INTERPOLATE_NEAREST)
			_harden_alpha(frame)
			_remove_strays(frame, 3)
			var palette_stats := _map_to_palette(frame, palette)
			frame = _align_bottom(frame, 120)
			var bounds := _bounds(frame)
			atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(column * CELL, row * CELL))
			measurements.append("%s,%d,%d,%d,%d,%d,%d,%d,%.3f" % [ROWS[row][0], column, bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y, bounds.end.y - 1, _partial_alpha(frame), float(palette_stats.mean)])
	atlas.save_png(ProjectSettings.globalize_path(OUTPUT))
	_write_contacts(base, atlas)
	var file := FileAccess.open(ProjectSettings.globalize_path("%s/frey_measurements.csv" % PREVIEW_DIR), FileAccess.WRITE)
	file.store_string("\n".join(measurements) + "\n")
	file.close()
	print("moves_23 Frey built: %dx%d, rows=%d, palette=%d" % [atlas.get_width(), atlas.get_height(), ROWS.size(), palette.size()])
	quit(0)

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

func _map_to_palette(image: Image, palette: Array[Color]) -> Dictionary:
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
				var cached: Array = cache[key]
				mapped = cached[0]
				distance = float(cached[1])
			else:
				var best := INF
				mapped = palette[0]
				for candidate in palette:
					var dr := color.r - candidate.r
					var dg := color.g - candidate.g
					var db := color.b - candidate.b
					var d := sqrt(dr * dr + dg * dg + db * db) * 255.0
					if d < best:
						best = d
						mapped = candidate
				distance = best
				cache[key] = [mapped, distance]
			image.set_pixel(x, y, Color(mapped.r, mapped.g, mapped.b, 1.0))
			distance_sum += distance
			visible += 1
	return {"mean": distance_sum / maxf(float(visible), 1.0)}

func _harden_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				color.a = 1.0
				image.set_pixel(x, y, color)

func _remove_strays(image: Image, minimum: int) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var seen := PackedByteArray()
	seen.resize(width * height)
	for y in height:
		for x in width:
			var start := y * width + x
			if seen[start] != 0 or image.get_pixel(x, y).a < 0.5:
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			var component: Array[Vector2i] = []
			seen[start] = 1
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				component.append(point)
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = point + offset
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var index: int = next.y * width + next.x
					if seen[index] == 0 and image.get_pixelv(next).a >= 0.5:
						seen[index] = 1
						stack.append(next)
			if component.size() < minimum:
				for point in component:
					image.set_pixelv(point, Color(0, 0, 0, 0))

func _align_bottom(image: Image, target: int) -> Image:
	var bounds := _bounds(image)
	if bounds.size == Vector2i.ZERO:
		return image
	var offset := target - (bounds.end.y - 1)
	var aligned := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	for y in CELL:
		for x in CELL:
			var destination_y := y + offset
			if destination_y >= 0 and destination_y < CELL:
				aligned.set_pixel(x, destination_y, image.get_pixel(x, y))
	return aligned

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

func _write_contacts(base: Image, atlas: Image) -> void:
	var contact := Image.create(CELL * (COLUMNS + 1), CELL * ROWS.size(), false, Image.FORMAT_RGBA8)
	var idle := base.get_region(Rect2i(0, 0, CELL, CELL))
	for row in ROWS.size():
		contact.blit_rect(idle, Rect2i(0, 0, CELL, CELL), Vector2i(0, row * CELL))
		contact.blit_rect(atlas, Rect2i(0, row * CELL, CELL * COLUMNS, CELL), Vector2i(CELL, row * CELL))
	contact.save_png(ProjectSettings.globalize_path("%s/frey_moves_contact_1x.png" % PREVIEW_DIR))
	var enlarged := contact.duplicate()
	enlarged.resize(contact.get_width() * 4, contact.get_height() * 4, Image.INTERPOLATE_NEAREST)
	enlarged.save_png(ProjectSettings.globalize_path("%s/frey_moves_contact_4x.png" % PREVIEW_DIR))

func _rgb_key(color: Color) -> int:
	return int(round(color.r * 255.0)) << 16 | int(round(color.g * 255.0)) << 8 | int(round(color.b * 255.0))

func _key_color(key: int) -> Color:
	return Color8((key >> 16) & 255, (key >> 8) & 255, key & 255, 255)
