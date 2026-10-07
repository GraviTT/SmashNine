extends SceneTree

const COLUMNS := 6
const ROWS := 7
const CELL := Vector2i(64, 64)
const WORK_SIZE := Vector2i(51, 42)
const FEET_ROW := 48
const USED_COUNTS := [4, 6, 1, 1, 4, 6, 1]
const ALPHA_CUTOFF := 0.42
const SPECS := [
	{
		"name": "luna",
		"source": "res://assets/art/luna/generated_source.png",
		"sheet": "res://assets/art/luna/luna_sheet.png",
		"portrait": "res://assets/art/luna/luna_portrait.png",
	},
	{
		"name": "rio_male",
		"source": "res://assets/art/rio/generated_male_source.png",
		"sheet": "res://assets/art/rio/rio_male_sheet.png",
		"portrait": "res://assets/art/rio/rio_male_portrait.png",
	},
	{
		"name": "rio_female",
		"source": "res://assets/art/rio/generated_female_source.png",
		"sheet": "res://assets/art/rio/rio_female_sheet.png",
		"portrait": "res://assets/art/rio/rio_female_portrait.png",
	},
]

func _init() -> void:
	for spec in SPECS:
		if not _build_sheet(spec):
			quit(1)
			return
	print("[chars-b-build] PASS sheets=3 size=384x448 cell=64 feet_row=%d work=%dx%d" % [
		FEET_ROW, WORK_SIZE.x, WORK_SIZE.y
	])
	quit()

func _build_sheet(spec: Dictionary) -> bool:
	var source := Image.load_from_file(String(spec.source))
	if source.is_empty():
		push_error("Could not load %s" % String(spec.source))
		return false
	var sheet := Image.create(COLUMNS * CELL.x, ROWS * CELL.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for row in range(ROWS):
		for column in range(USED_COUNTS[row]):
			var frame := _extract_source_cell(source, column, row)
			_cleanup_alpha_and_islands(frame)
			frame = _crop_and_fit(frame)
			_cleanup_alpha_and_islands(frame)
			var used := frame.get_used_rect()
			if used.size == Vector2i.ZERO:
				push_error("Empty generated frame %s r%d c%d" % [String(spec.name), row, column])
				return false
			var target_x := roundi(CELL.x * 0.5 - _opaque_centroid_x(frame))
			var target_y := FEET_ROW - (used.position.y + used.size.y - 1)
			sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(target_x, target_y) + Vector2i(column, row) * CELL)
	var error := sheet.save_png(String(spec.sheet))
	if error != OK:
		push_error("Could not save %s: %s" % [String(spec.sheet), error_string(error)])
		return false
	if not _save_portrait(sheet, String(spec.portrait)):
		return false
	print("[chars-b-build] %s source=%dx%d sheet=%dx%d" % [
		String(spec.name), source.get_width(), source.get_height(), sheet.get_width(), sheet.get_height()
	])
	return true

func _extract_source_cell(source: Image, column: int, row: int) -> Image:
	var x0 := roundi(float(column) * source.get_width() / COLUMNS)
	var x1 := roundi(float(column + 1) * source.get_width() / COLUMNS)
	var y0 := roundi(float(row) * source.get_height() / ROWS)
	var y1 := roundi(float(row + 1) * source.get_height() / ROWS)
	return source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))

func _crop_and_fit(image: Image) -> Image:
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		return image
	var cropped := image.get_region(used)
	var scale_factor := minf(float(WORK_SIZE.x) / cropped.get_width(), float(WORK_SIZE.y) / cropped.get_height())
	var fitted_size := Vector2i(
		maxi(1, roundi(cropped.get_width() * scale_factor)),
		maxi(1, roundi(cropped.get_height() * scale_factor))
	)
	cropped.resize(fitted_size.x, fitted_size.y, Image.INTERPOLATE_NEAREST)
	return cropped

func _cleanup_alpha_and_islands(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_CUTOFF:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				color.a = 1.0
				image.set_pixel(x, y, color)
	_remove_tiny_islands(image)

func _remove_tiny_islands(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var components: Array[PackedVector2Array] = []
	for y in range(height):
		for x in range(width):
			var index := y * width + x
			if visited[index] != 0 or image.get_pixel(x, y).a == 0.0:
				continue
			var component := PackedVector2Array()
			var queue := PackedVector2Array([Vector2(x, y)])
			visited[index] = 1
			var cursor := 0
			while cursor < queue.size():
				var point := Vector2i(queue[cursor])
				cursor += 1
				component.append(point)
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						if ox == 0 and oy == 0:
							continue
						var next := point + Vector2i(ox, oy)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
							continue
						var next_index := next.y * width + next.x
						if visited[next_index] != 0 or image.get_pixelv(next).a == 0.0:
							continue
						visited[next_index] = 1
						queue.append(next)
			components.append(component)
	var largest := 0
	for component in components:
		largest = maxi(largest, component.size())
	var minimum_size := maxi(3, ceili(largest * 0.05))
	for component in components:
		if component.size() >= minimum_size:
			continue
		for point in component:
			image.set_pixelv(Vector2i(point), Color(0, 0, 0, 0))

func _opaque_centroid_x(image: Image) -> float:
	var sum_x := 0.0
	var opaque_pixels := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.0:
				sum_x += x
				opaque_pixels += 1
	return sum_x / maxf(opaque_pixels, 1)

func _save_portrait(sheet: Image, output_path: String) -> bool:
	var idle := sheet.get_region(Rect2i(0, 0, CELL.x, CELL.y))
	var used := idle.get_used_rect()
	var crop_height := maxi(18, roundi(used.size.y * 0.72))
	var crop_width := mini(used.size.x, crop_height)
	var crop_x := clampi(roundi(_opaque_centroid_x(idle) - crop_width * 0.5), 0, CELL.x - crop_width)
	var crop_y := used.position.y
	var portrait_source := idle.get_region(Rect2i(crop_x, crop_y, crop_width, crop_height))
	portrait_source.resize(56, 56, Image.INTERPOLATE_NEAREST)
	var portrait := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	portrait.fill(Color(0, 0, 0, 0))
	portrait.blit_rect(portrait_source, Rect2i(0, 0, 56, 56), Vector2i(4, 4))
	var error := portrait.save_png(output_path)
	if error != OK:
		push_error("Could not save %s: %s" % [output_path, error_string(error)])
		return false
	return true
