extends SceneTree

const CELL := 128
const COLUMNS := 6
const ROWS := 8

const SPECS: Array[Dictionary] = [
	{"id": "nova_male", "sheet": "res://assets/art/nova/nova_male_moves_sheet.png", "live": "res://assets/art/nova/nova_male_sheet.png", "counts": [4, 4, 4, 4, 5, 4, 5, 6], "ground_rows": [0, 1, 2, 6, 7], "air_rows": [3, 4, 5]},
	{"id": "nova_female", "sheet": "res://assets/art/nova/nova_female_moves_sheet.png", "live": "res://assets/art/nova/nova_female_sheet.png", "counts": [4, 4, 4, 4, 5, 4, 5, 6], "ground_rows": [0, 1, 2, 6, 7], "air_rows": [3, 4, 5]},
	{"id": "yuki", "sheet": "res://assets/art/yuki/yuki_moves_sheet.png", "live": "res://assets/art/yuki/yuki_sheet.png", "counts": [4, 4, 4, 4, 4, 5, 5, 6], "ground_rows": [0, 1, 2, 6, 7], "air_rows": [3, 4, 5]},
	{"id": "rio_male", "sheet": "res://assets/art/rio/rio_male_moves_sheet.png", "live": "res://assets/art/rio/rio_male_sheet.png", "counts": [6, 4, 4, 4, 5, 5, 6, 6], "ground_rows": [0, 1, 2, 6, 7], "air_rows": [3, 4, 5]},
	{"id": "rio_female", "sheet": "res://assets/art/rio/rio_female_moves_sheet.png", "live": "res://assets/art/rio/rio_female_sheet.png", "counts": [6, 4, 4, 4, 5, 5, 6, 6], "ground_rows": [0, 1, 2, 6, 7], "air_rows": [3, 4, 5]},
]


func _init() -> void:
	var failures: PackedStringArray = []
	var total_frames := 0
	for spec: Dictionary in SPECS:
		var sheet := Image.load_from_file(ProjectSettings.globalize_path(String(spec.sheet)))
		var live := Image.load_from_file(ProjectSettings.globalize_path(String(spec.live)))
		if sheet == null or sheet.is_empty():
			failures.append("%s missing sheet" % spec.id)
			continue
		if sheet.get_size() != Vector2i(CELL * COLUMNS, CELL * ROWS):
			failures.append("%s wrong size %s" % [spec.id, sheet.get_size()])
			continue
		var idle := live.get_region(Rect2i(0, 0, CELL, CELL))
		var jump := live.get_region(Rect2i(0, CELL * 2, CELL, CELL))
		var idle_dark_height := _dark_body_rect(idle).size.y
		var jump_center := _dark_body_centroid(jump).y
		var sheet_partial := 0
		for row in ROWS:
			for column in COLUMNS:
				var frame := sheet.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
				var bounds := frame.get_used_rect()
				var used: bool = column < int(spec.counts[row])
				if used:
					total_frames += 1
					if bounds.size == Vector2i.ZERO:
						failures.append("%s r%dc%d used cell empty" % [spec.id, row, column])
					if _smallest_component(frame) < 3:
						failures.append("%s r%dc%d has <3px island" % [spec.id, row, column])
				else:
					if bounds.size != Vector2i.ZERO:
						failures.append("%s r%dc%d unused cell nonempty" % [spec.id, row, column])
				sheet_partial += _partial_alpha_count(frame)
		if sheet_partial != 0:
			failures.append("%s partial alpha=%d" % [spec.id, sheet_partial])
		for row in spec.ground_rows:
			var frame := sheet.get_region(Rect2i(0, int(row) * CELL, CELL, CELL))
			var feet := frame.get_used_rect().end.y - 1
			if absi(feet - 120) > 2:
				failures.append("%s ground row %d anchor feet=%d" % [spec.id, row, feet])
		for row in spec.air_rows:
			var frame := sheet.get_region(Rect2i(0, int(row) * CELL, CELL, CELL))
			var center := _dark_body_centroid(frame).y
			if absf(center - jump_center) > 4.0:
				failures.append("%s air row %d anchor center=%.1f live=%.1f" % [spec.id, row, center, jump_center])
		var scale_anchor := sheet.get_region(Rect2i(0, 0, CELL, CELL))
		var scale_delta := _dark_body_rect(scale_anchor).size.y - idle_dark_height
		if absi(scale_delta) > 4:
			failures.append("%s scale anchor dark-height delta=%d" % [spec.id, scale_delta])
		print("VERIFY %s frames=%d partial_alpha=%d scale_anchor_delta=%d" % [spec.id, _sum_counts(spec.counts), sheet_partial, scale_delta])
	if failures.is_empty():
		print("MOVES_26_VERIFY_OK sheets=%d frames=%d" % [SPECS.size(), total_frames])
		quit()
		return
	for failure in failures:
		push_error(failure)
	print("MOVES_26_VERIFY_FAILED count=%d" % failures.size())
	quit(1)


func _sum_counts(counts: Array) -> int:
	var total := 0
	for count in counts:
		total += int(count)
	return total


func _rect_center(rect: Rect2i) -> Vector2:
	return Vector2(rect.position) + Vector2(rect.size) * 0.5


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


func _partial_alpha_count(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var alpha := image.get_pixel(x, y).a
			if alpha > 0.0 and alpha < 1.0:
				count += 1
	return count


func _smallest_component(image: Image) -> int:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var smallest := 1 << 30
	for y in height:
		for x in width:
			var start_index := y * width + x
			if visited[start_index] != 0 or image.get_pixel(x, y).a < 0.5:
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			var size := 0
			visited[start_index] = 1
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				size += 1
				for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = point + direction
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var next_index: int = next.y * width + next.x
					if visited[next_index] != 0 or image.get_pixelv(next).a < 0.5:
						continue
					visited[next_index] = 1
					stack.append(next)
			smallest = mini(smallest, size)
	return smallest
