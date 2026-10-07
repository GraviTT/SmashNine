extends SceneTree

const CELL := 128
const SHEETS := [
	{"id": "rio_male", "path": "res://assets/art/rio/rio_male_sheet.png"},
	{"id": "rio_female", "path": "res://assets/art/rio/rio_female_sheet.png"},
]


func _initialize() -> void:
	for spec: Dictionary in SHEETS:
		var sheet := Image.load_from_file(spec.path)
		sheet.convert(Image.FORMAT_RGBA8)
		for column in 4:
			var frame := sheet.get_region(Rect2i(column * CELL, 4 * CELL, CELL, CELL))
			var details := _components(frame)
			details.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.size) > int(b.size))
			print("COMPONENTS %s attack c%d %s" % [spec.id, column, str(details)])
	quit(0)


func _components(image: Image) -> Array[Dictionary]:
	var visited := PackedByteArray()
	visited.resize(CELL * CELL)
	var offsets: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]
	var result: Array[Dictionary] = []
	for start_y in CELL:
		for start_x in CELL:
			var start_index := start_y * CELL + start_x
			if visited[start_index] != 0 or image.get_pixel(start_x, start_y).a < 0.5:
				continue
			var stack: Array[Vector2i] = [Vector2i(start_x, start_y)]
			visited[start_index] = 1
			var count := 0
			var left := CELL
			var top := CELL
			var right := -1
			var bottom := -1
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				count += 1
				left = mini(left, point.x)
				top = mini(top, point.y)
				right = maxi(right, point.x)
				bottom = maxi(bottom, point.y)
				for offset: Vector2i in offsets:
					var next := point + offset
					if next.x < 0 or next.y < 0 or next.x >= CELL or next.y >= CELL:
						continue
					var next_index := next.y * CELL + next.x
					if visited[next_index] == 0 and image.get_pixelv(next).a >= 0.5:
						visited[next_index] = 1
						stack.append(next)
			result.append({"size": count, "bbox": Rect2i(left, top, right - left + 1, bottom - top + 1)})
	return result
