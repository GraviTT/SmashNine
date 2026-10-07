extends SceneTree

const CELL := 128
const COUNTS := [4, 6, 1, 1, 4, 6, 1]
const ENTRIES := [
	["frey", "res://assets/art/frey/frey_illustration.png", "res://assets/art/frey/frey_face.png", "res://assets/art/frey/frey_sheet.png"],
	["nova_male", "res://assets/art/nova/nova_male_illustration.png", "res://assets/art/nova/nova_male_face.png", "res://assets/art/nova/nova_male_sheet.png"],
	["nova_female", "res://assets/art/nova/nova_female_illustration.png", "res://assets/art/nova/nova_female_face.png", "res://assets/art/nova/nova_female_sheet.png"],
	["yuki", "res://assets/art/yuki/yuki_illustration.png", "res://assets/art/yuki/yuki_face.png", "res://assets/art/yuki/yuki_sheet.png"],
]

var _failures := 0

func _initialize() -> void:
	for entry: Array in ENTRIES:
		_verify_size(entry[0] + " illustration", entry[1], Vector2i(1024, 1536))
		_verify_size(entry[0] + " face", entry[2], Vector2i(256, 256))
		_verify_sheet(entry[0], entry[3])
	if _failures == 0:
		print("[verify_hires_a] PASS: all dimensions, used cells, transparent unused cells, feet and centres")
	else:
		push_error("[verify_hires_a] FAIL: %d checks" % _failures)
	quit(_failures)

func _verify_size(label: String, path: String, expected: Vector2i) -> void:
	var image := Image.load_from_file(path)
	_check(image.get_size() == expected, "%s size %s expected %s" % [label, image.get_size(), expected])

func _verify_sheet(label: String, path: String) -> void:
	var image := Image.load_from_file(path)
	_check(image.get_size() == Vector2i(768, 896), "%s sheet size %s" % [label, image.get_size()])
	var used := 0
	for row: int in range(7):
		for column: int in range(6):
			var cell := image.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
			var bounds := _alpha_bounds(cell)
			if column < COUNTS[row]:
				used += 1
				_check(bounds.size != Vector2i.ZERO, "%s used cell r%d c%d empty" % [label, row, column])
				if bounds.size != Vector2i.ZERO:
					_check(bounds.end.y - 1 == 120, "%s feet r%d c%d=%d" % [label, row, column, bounds.end.y - 1])
					var centroid := _centroid_x(cell, bounds)
					_check(centroid >= 63.5 and centroid <= 64.5, "%s centre r%d c%d=%.2f" % [label, row, column, centroid])
			else:
				_check(bounds.size == Vector2i.ZERO, "%s unused cell r%d c%d not transparent" % [label, row, column])
	_check(used == 23, "%s used frame count=%d" % [label, used])

func _alpha_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.0:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _centroid_x(image: Image, bounds: Rect2i) -> float:
	var sum_x := 0.0
	var count := 0.0
	for y: int in range(bounds.position.y, bounds.end.y):
		for x: int in range(bounds.position.x, bounds.end.x):
			if image.get_pixel(x, y).a > 0.0:
				sum_x += x
				count += 1.0
	return sum_x / maxf(count, 1.0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
