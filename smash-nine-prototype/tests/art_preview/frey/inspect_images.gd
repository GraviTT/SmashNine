extends SceneTree

const CELL := Vector2i(64, 64)
const COLUMNS := 6
const USED_COUNTS := [4, 6, 1, 1, 4, 6, 1]

func _init() -> void:
	_print_image("existing", "res://assets/characters/frey/frey_prototype.png", true)
	_print_image("generated", "res://assets/art/frey/generated_source.png", false)
	quit()

func _print_image(label: String, path: String, fixed_grid: bool) -> void:
	var image := Image.load_from_file(path)
	print("[inspect] %s size=%dx%d format=%s" % [label, image.get_width(), image.get_height(), image.get_format()])
	for row in range(USED_COUNTS.size()):
		for column in range(USED_COUNTS[row]):
			var source_rect: Rect2i
			if fixed_grid:
				source_rect = Rect2i(column * CELL.x, row * CELL.y, CELL.x, CELL.y)
			else:
				var x0 := roundi(float(column) * image.get_width() / COLUMNS)
				var x1 := roundi(float(column + 1) * image.get_width() / COLUMNS)
				var y0 := roundi(float(row) * image.get_height() / USED_COUNTS.size())
				var y1 := roundi(float(row + 1) * image.get_height() / USED_COUNTS.size())
				source_rect = Rect2i(x0, y0, x1 - x0, y1 - y0)
			var frame := image.get_region(source_rect)
			var bounds := frame.get_used_rect()
			print("[inspect] %s r%d c%d source=%s alpha=%s" % [label, row, column, source_rect, bounds])
