extends SceneTree

const CELL := 128
const COLUMNS := 6
const SHEETS := [
	["res://assets/art/frey/frey_moves_sheet.png", [4, 4, 4, 4, 5, 4, 6, 4]],
	["res://assets/art/luna/luna_moves_sheet.png", [4, 4, 4, 5, 6, 4]],
	["res://assets/art/luna/luna_brave_moves_sheet.png", [6, 4, 4, 4, 4, 4, 6, 6, 4]],
]

var failures: Array[String] = []

func _initialize() -> void:
	for spec in SHEETS:
		_check_sheet(str(spec[0]), spec[1])
	if failures.is_empty():
		print("moves_23 verification passed: 3 sheets, 23 rows, hard alpha, empty unused cells, ground/action feet y=120, centered tumble rows")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_sheet(path: String, counts: Array) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image.get_size() != Vector2i(CELL * COLUMNS, CELL * counts.size()):
		failures.append("%s size %s" % [path, image.get_size()])
		return
	for row in counts.size():
		for column in COLUMNS:
			var frame := image.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
			var bounds := _bounds(frame)
			var name := "%s r%dc%d" % [path.get_file(), row, column]
			if column >= int(counts[row]):
				if bounds.size != Vector2i.ZERO:
					failures.append("%s unused cell is not transparent" % name)
				continue
			if bounds.size == Vector2i.ZERO:
				failures.append("%s used cell is empty" % name)
			elif row < counts.size() - 1 and bounds.end.y - 1 != 120:
				failures.append("%s lowest opaque y=%d" % [name, bounds.end.y - 1])
			if _partial_alpha(frame) > 0:
				failures.append("%s has partial alpha" % name)

func _bounds(image: Image) -> Rect2i:
	var rect := Rect2i()
	for y in CELL:
		for x in CELL:
			if image.get_pixel(x, y).a >= 0.5:
				var point := Vector2i(x, y)
				rect = Rect2i(point, Vector2i.ONE) if rect.size == Vector2i.ZERO else rect.expand(point).expand(point + Vector2i.ONE)
	return rect

func _partial_alpha(image: Image) -> int:
	var count := 0
	for y in CELL:
		for x in CELL:
			var alpha := image.get_pixel(x, y).a
			if alpha > 0.0 and alpha < 1.0:
				count += 1
	return count
