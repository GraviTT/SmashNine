extends SceneTree

const COLUMNS := 6
const ROWS := 7
const CELL := Vector2i(64, 64)
const WORK_SIZE := Vector2i(51, 46)
const FEET_ROW := 48
const USED_COUNTS := [4, 6, 1, 1, 4, 6, 1]
const ALPHA_CUTOFF := 0.35
const SHEETS := [
	{
		"name": "yuki",
		"source": "res://assets/art/yuki/yuki_generated_source.png",
		"output": "res://assets/art/yuki/yuki_sheet.png",
		"portrait": "res://assets/art/yuki/yuki_portrait.png",
	},
	{
		"name": "nova_male",
		"source": "res://assets/art/nova/nova_male_generated_source.png",
		"output": "res://assets/art/nova/nova_male_sheet.png",
		"portrait": "res://assets/art/nova/nova_male_portrait.png",
	},
	{
		"name": "nova_female",
		"source": "res://assets/art/nova/nova_female_generated_source.png",
		"output": "res://assets/art/nova/nova_female_sheet.png",
		"portrait": "res://assets/art/nova/nova_female_portrait.png",
	},
]

func _init() -> void:
	for spec in SHEETS:
		if not _build_sheet(spec):
			quit(1)
			return
	quit()

func _build_sheet(spec: Dictionary) -> bool:
	var source := Image.load_from_file(spec.source)
	if source.is_empty():
		push_error("Could not load %s" % spec.source)
		return false
	var sheet := Image.create(COLUMNS * CELL.x, ROWS * CELL.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for row in range(ROWS):
		for column in range(USED_COUNTS[row]):
			var frame := _extract_source_cell(source, column, row)
			frame.resize(WORK_SIZE.x, WORK_SIZE.y, Image.INTERPOLATE_NEAREST)
			_cleanup_alpha(frame)
			var used := frame.get_used_rect()
			if used.size == Vector2i.ZERO:
				push_error("Empty generated frame %s r%d c%d" % [spec.name, row, column])
				return false
			var target_x := roundi(CELL.x * 0.5 - _opaque_centroid_x(frame))
			var target_y := FEET_ROW - (used.position.y + used.size.y - 1)
			var target := Vector2i(target_x, target_y) + Vector2i(column, row) * CELL
			sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, WORK_SIZE), target)
	var error := sheet.save_png(spec.output)
	if error != OK:
		push_error("Could not save %s: %s" % [spec.output, error_string(error)])
		return false
	if not _build_portrait(sheet, spec.portrait):
		return false
	print("[chars-a-build] %s source=%dx%d output=%dx%d feet_row=%d work=%dx%d" % [
		spec.name, source.get_width(), source.get_height(), sheet.get_width(), sheet.get_height(),
		FEET_ROW, WORK_SIZE.x, WORK_SIZE.y
	])
	return true

func _extract_source_cell(source: Image, column: int, row: int) -> Image:
	var x0 := roundi(float(column) * source.get_width() / COLUMNS)
	var x1 := roundi(float(column + 1) * source.get_width() / COLUMNS)
	var y0 := roundi(float(row) * source.get_height() / ROWS)
	var y1 := roundi(float(row + 1) * source.get_height() / ROWS)
	return source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))

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
			if component.size() >= 3:
				continue
			for point in component:
				image.set_pixelv(Vector2i(point), Color(0, 0, 0, 0))

func _build_portrait(sheet: Image, output_path: String) -> bool:
	var idle := sheet.get_region(Rect2i(Vector2i.ZERO, CELL))
	var used := idle.get_used_rect()
	var crop_height := ceili(used.size.y * 0.72)
	var crop_x := maxi(0, used.position.x - 2)
	var crop_y := maxi(0, used.position.y - 2)
	var crop_width := mini(CELL.x - crop_x, used.size.x + 4)
	crop_height = mini(CELL.y - crop_y, crop_height + 2)
	var crop := idle.get_region(Rect2i(crop_x, crop_y, crop_width, crop_height))
	var scale := minf(52.0 / crop.get_width(), 52.0 / crop.get_height())
	var target_size := Vector2i(maxi(1, roundi(crop.get_width() * scale)), maxi(1, roundi(crop.get_height() * scale)))
	crop.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	var portrait := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	portrait.fill(Color(0, 0, 0, 0))
	portrait.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i((64 - target_size.x) / 2, (64 - target_size.y) / 2))
	var error := portrait.save_png(output_path)
	if error != OK:
		push_error("Could not save %s: %s" % [output_path, error_string(error)])
		return false
	return true

func _opaque_centroid_x(image: Image) -> float:
	var sum_x := 0.0
	var opaque_pixels := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.0:
				sum_x += x
				opaque_pixels += 1
	return sum_x / maxf(opaque_pixels, 1)
