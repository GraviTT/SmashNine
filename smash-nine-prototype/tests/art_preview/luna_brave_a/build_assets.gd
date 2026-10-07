extends SceneTree

const BRAVE_SOURCE := "res://assets/art/luna/luna_brave_generated_source.png"
const BRAVE_OUTPUT := "res://assets/art/luna/luna_brave_sheet.png"
const LOGO_SOURCE := "res://assets/art/ui/title_logo_generated_source.png"
const LOGO_OUTPUT := "res://assets/art/ui/title_logo.png"
const COLUMNS := 6
const ROWS := 7
const CELL := Vector2i(64, 64)
const MAX_FRAME := Vector2i(58, 46)
const FEET_ROW := 48
const USED_COUNTS := [4, 6, 1, 1, 4, 6, 1]
const ALPHA_CUTOFF := 0.42
const LOGO_SIZE := Vector2i(640, 200)
const LOGO_INSET := Vector2i(12, 8)

func _init() -> void:
	if not _build_brave_sheet():
		quit(1)
		return
	if not _build_logo():
		quit(1)
		return
	print("[art-06-build] PASS brave=384x448 logo=640x200 feet_row=%d" % FEET_ROW)
	quit()

func _build_brave_sheet() -> bool:
	var source := Image.load_from_file(BRAVE_SOURCE)
	if source.is_empty():
		push_error("Could not load %s" % BRAVE_SOURCE)
		return false
	var sheet := Image.create(COLUMNS * CELL.x, ROWS * CELL.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for row in range(ROWS):
		for column in range(USED_COUNTS[row]):
			var frame := _extract_source_cell(source, column, row)
			_cleanup_alpha(frame)
			frame = _crop_and_fit(frame, MAX_FRAME)
			_cleanup_alpha(frame)
			var used := frame.get_used_rect()
			if used.size == Vector2i.ZERO:
				push_error("Empty generated Brave Luna frame r%d c%d" % [row, column])
				return false
			var target_x := roundi(CELL.x * 0.5 - _opaque_centroid_x(frame))
			var target_y := FEET_ROW - (used.position.y + used.size.y - 1)
			var destination := Vector2i(column, row) * CELL + Vector2i(target_x, target_y)
			sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), destination)
	var error := sheet.save_png(BRAVE_OUTPUT)
	if error != OK:
		push_error("Could not save %s: %s" % [BRAVE_OUTPUT, error_string(error)])
		return false
	print("[art-06-build] brave source=%dx%d output=%dx%d" % [
		source.get_width(), source.get_height(), sheet.get_width(), sheet.get_height()
	])
	return true

func _build_logo() -> bool:
	var source := Image.load_from_file(LOGO_SOURCE)
	if source.is_empty():
		push_error("Could not load %s" % LOGO_SOURCE)
		return false
	_cleanup_alpha(source)
	var used := source.get_used_rect()
	if used.size == Vector2i.ZERO:
		push_error("Generated logo source is empty")
		return false
	var cropped := source.get_region(used)
	# The source is reduced directly onto a final-size pixel grid. A mild horizontal
	# expansion preserves the requested broad title-screen frame at 640x200.
	var fitted_size := LOGO_SIZE - LOGO_INSET * 2
	cropped.resize(fitted_size.x, fitted_size.y, Image.INTERPOLATE_NEAREST)
	_cleanup_alpha(cropped)
	var logo := Image.create(LOGO_SIZE.x, LOGO_SIZE.y, false, Image.FORMAT_RGBA8)
	logo.fill(Color(0, 0, 0, 0))
	logo.blit_rect(cropped, Rect2i(Vector2i.ZERO, cropped.get_size()), LOGO_INSET)
	var error := logo.save_png(LOGO_OUTPUT)
	if error != OK:
		push_error("Could not save %s: %s" % [LOGO_OUTPUT, error_string(error)])
		return false
	print("[art-06-build] logo source=%dx%d used=%s output=%dx%d" % [
		source.get_width(), source.get_height(), used, logo.get_width(), logo.get_height()
	])
	return true

func _extract_source_cell(source: Image, column: int, row: int) -> Image:
	var x0 := roundi(float(column) * source.get_width() / COLUMNS)
	var x1 := roundi(float(column + 1) * source.get_width() / COLUMNS)
	var y0 := roundi(float(row) * source.get_height() / ROWS)
	var y1 := roundi(float(row + 1) * source.get_height() / ROWS)
	return source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))

func _crop_and_fit(image: Image, maximum: Vector2i) -> Image:
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		return image
	var cropped := image.get_region(used)
	var scale_factor := minf(float(maximum.x) / cropped.get_width(), float(maximum.y) / cropped.get_height())
	var fitted_size := Vector2i(
		maxi(1, roundi(cropped.get_width() * scale_factor)),
		maxi(1, roundi(cropped.get_height() * scale_factor))
	)
	cropped.resize(fitted_size.x, fitted_size.y, Image.INTERPOLATE_NEAREST)
	return cropped

func _cleanup_alpha(image: Image) -> void:
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
	var minimum_size := maxi(3, ceili(largest * 0.025))
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
