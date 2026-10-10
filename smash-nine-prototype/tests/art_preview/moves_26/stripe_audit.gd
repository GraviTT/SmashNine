extends SceneTree

const CELL := 128
const COLUMNS := 6
const ROWS := 8
const SHEETS: Array[Dictionary] = [
	{"id": "nova_male", "path": "res://assets/art/nova/nova_male_moves_sheet.png"},
	{"id": "nova_female", "path": "res://assets/art/nova/nova_female_moves_sheet.png"},
	{"id": "yuki", "path": "res://assets/art/yuki/yuki_moves_sheet.png"},
	{"id": "rio_male", "path": "res://assets/art/rio/rio_male_moves_sheet.png"},
	{"id": "rio_female", "path": "res://assets/art/rio/rio_female_moves_sheet.png"},
]
const DIRECTIONS_8: Array[Vector2i] = [
	Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
]


func _init() -> void:
	var grand_components := 0
	var grand_runs := 0
	for spec: Dictionary in SHEETS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(String(spec.path)))
		assert(image != null and not image.is_empty(), "missing sheet: " + String(spec.path))
		assert(image.get_size() == Vector2i(COLUMNS * CELL, ROWS * CELL), "bad sheet size: " + String(spec.path))
		var sheet_components := 0
		var sheet_runs := 0
		var flagged_cells := 0
		for row in ROWS:
			for column in COLUMNS:
				var cell := image.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
				var thin_components := _count_thin_components(cell)
				var isolated_runs := _count_isolated_runs(cell)
				sheet_components += thin_components
				sheet_runs += isolated_runs
				if thin_components + isolated_runs > 0:
					flagged_cells += 1
					# Coordinates are one-based to match the visual review notation.
					print("STRIPE_CELL sheet=%s r%dc%d components=%d runs=%d total=%d" % [
						spec.id, row + 1, column + 1, thin_components, isolated_runs,
						thin_components + isolated_runs,
					])
		grand_components += sheet_components
		grand_runs += sheet_runs
		print("STRIPE_SHEET sheet=%s components=%d runs=%d total=%d flagged_cells=%d" % [
			spec.id, sheet_components, sheet_runs, sheet_components + sheet_runs, flagged_cells,
		])
	print("STRIPE_AUDIT_OK sheets=%d components=%d runs=%d total=%d" % [
		SHEETS.size(), grand_components, grand_runs, grand_components + grand_runs,
	])
	quit()


func _count_thin_components(image: Image) -> int:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var flagged := 0
	for y in height:
		for x in width:
			var start_index := y * width + x
			if visited[start_index] != 0 or not _opaque(image, x, y):
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			var bounds := Rect2i(Vector2i(x, y), Vector2i.ONE)
			visited[start_index] = 1
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				bounds = bounds.expand(point).expand(point + Vector2i.ONE)
				for direction: Vector2i in DIRECTIONS_8:
					var next := point + direction
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var next_index := next.y * width + next.x
					if visited[next_index] != 0 or not _opaque(image, next.x, next.y):
						continue
					visited[next_index] = 1
					stack.append(next)
			if (bounds.size.x <= 2 and bounds.size.y >= 4) or (bounds.size.y <= 2 and bounds.size.x >= 4):
				flagged += 1
	return flagged


func _count_isolated_runs(image: Image) -> int:
	var count := 0
	for x in image.get_width():
		var y := 0
		while y < image.get_height():
			if not _opaque(image, x, y):
				y += 1
				continue
			var start := y
			while y < image.get_height() and _opaque(image, x, y):
				y += 1
			if y - start >= 6 and _vertical_neighbours_clear(image, x, start, y):
				count += 1
	for y in image.get_height():
		var x := 0
		while x < image.get_width():
			if not _opaque(image, x, y):
				x += 1
				continue
			var start := x
			while x < image.get_width() and _opaque(image, x, y):
				x += 1
			if x - start >= 6 and _horizontal_neighbours_clear(image, y, start, x):
				count += 1
	return count


func _vertical_neighbours_clear(image: Image, x: int, start: int, end: int) -> bool:
	for y in range(start, end):
		if (x > 0 and _opaque(image, x - 1, y)) or (x + 1 < image.get_width() and _opaque(image, x + 1, y)):
			return false
	return true


func _horizontal_neighbours_clear(image: Image, y: int, start: int, end: int) -> bool:
	for x in range(start, end):
		if (y > 0 and _opaque(image, x, y - 1)) or (y + 1 < image.get_height() and _opaque(image, x, y + 1)):
			return false
	return true


func _opaque(image: Image, x: int, y: int) -> bool:
	return image.get_pixel(x, y).a >= 0.5
