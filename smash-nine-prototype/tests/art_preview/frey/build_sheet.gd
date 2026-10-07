extends SceneTree

const SOURCE_PATH := "res://assets/art/frey/generated_source.png"
const OUTPUT_PATH := "res://assets/art/frey/frey_sheet.png"
const COLUMNS := 6
const ROWS := 7
const CELL := Vector2i(64, 64)
const WORK_SIZE := Vector2i(51, 46)
const FEET_ROW := 48
const USED_COUNTS := [4, 6, 1, 1, 4, 6, 1]
const ALPHA_CUTOFF := 0.42

func _init() -> void:
	var source := Image.load_from_file(SOURCE_PATH)
	if source.is_empty():
		push_error("Could not load %s" % SOURCE_PATH)
		quit(1)
		return
	var sheet := Image.create(COLUMNS * CELL.x, ROWS * CELL.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for row in range(ROWS):
		for column in range(USED_COUNTS[row]):
			var frame := _extract_source_cell(source, column, row)
			frame.resize(WORK_SIZE.x, WORK_SIZE.y, Image.INTERPOLATE_NEAREST)
			_cleanup_alpha_and_islands(frame)
			var used := frame.get_used_rect()
			if used.size == Vector2i.ZERO:
				push_error("Empty generated frame r%d c%d" % [row, column])
				quit(1)
				return
			var target_x := roundi(CELL.x * 0.5 - _opaque_centroid_x(frame))
			var target_y := FEET_ROW - (used.position.y + used.size.y - 1)
			sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, WORK_SIZE), Vector2i(target_x, target_y) + Vector2i(column, row) * CELL)
	var error := sheet.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Could not save %s: %s" % [OUTPUT_PATH, error_string(error)])
		quit(1)
		return
	print("[frey-build] source=%dx%d output=%dx%d feet_row=%d work=%dx%d" % [
		source.get_width(), source.get_height(), sheet.get_width(), sheet.get_height(),
		FEET_ROW, WORK_SIZE.x, WORK_SIZE.y
	])
	quit()

func _opaque_centroid_x(image: Image) -> float:
	var sum_x := 0.0
	var opaque_pixels := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.0:
				sum_x += x
				opaque_pixels += 1
	return sum_x / maxf(opaque_pixels, 1)

func _extract_source_cell(source: Image, column: int, row: int) -> Image:
	var x0 := roundi(float(column) * source.get_width() / COLUMNS)
	var x1 := roundi(float(column + 1) * source.get_width() / COLUMNS)
	var y0 := roundi(float(row) * source.get_height() / ROWS)
	var y1 := roundi(float(row + 1) * source.get_height() / ROWS)
	return source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))

func _cleanup_alpha_and_islands(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_CUTOFF:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				color.a = 1.0
				image.set_pixel(x, y, color)
	_remove_small_islands(image)

func _remove_small_islands(image: Image) -> void:
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
	if components.is_empty():
		return
	var largest := 0
	for component in components:
		largest = maxi(largest, component.size())
	var minimum_size := maxi(3, ceili(largest * 0.05))
	for component in components:
		if component.size() >= minimum_size:
			continue
		for point in component:
			image.set_pixelv(Vector2i(point), Color(0, 0, 0, 0))
