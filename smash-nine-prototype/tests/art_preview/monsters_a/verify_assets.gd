extends SceneTree

const SPECS := {
	"res://assets/art/monsters/mossling_sheet.png": Vector2i(384, 256),
	"res://assets/art/monsters/ember_imp_sheet.png": Vector2i(384, 256),
	"res://assets/art/monsters/ember_fireball.png": Vector2i(24, 24),
	"res://assets/art/objects/soul_crystal.png": Vector2i(192, 64),
	"res://assets/art/objects/soul_crystal_shatter.png": Vector2i(192, 64),
}
const MONSTER_LAYOUT := [4, 6, 4, 1]

var failures: Array[String] = []


func _init() -> void:
	for path in SPECS:
		_verify_basic(path, SPECS[path])
	_verify_monster_sheet("res://assets/art/monsters/mossling_sheet.png")
	_verify_monster_sheet("res://assets/art/monsters/ember_imp_sheet.png")
	_verify_crystal_strip("res://assets/art/objects/soul_crystal.png")
	_verify_crystal_strip("res://assets/art/objects/soul_crystal_shatter.png")
	if failures.is_empty():
		print("VERIFY_OK exact sizes, RGBA8, transparency, frame occupancy, alignment, and 2x pixel grid")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _verify_basic(path: String, expected_size: Vector2i) -> void:
	var image := Image.load_from_file(path)
	if image.is_empty():
		failures.append("Could not load %s" % path)
		return
	if image.get_size() != expected_size:
		failures.append("%s size %s, expected %s" % [path, image.get_size(), expected_size])
	if image.get_format() != Image.FORMAT_RGBA8:
		failures.append("%s format %s, expected RGBA8" % [path, image.get_format()])
	var transparent := 0
	var opaque := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a == 0.0:
				transparent += 1
			else:
				opaque += 1
	if transparent == 0 or opaque == 0:
		failures.append("%s must contain both transparent and visible pixels" % path)
	print("FILE %s size=%s format=RGBA8 transparent=%d opaque=%d" % [path.get_file(), image.get_size(), transparent, opaque])


func _verify_monster_sheet(path: String) -> void:
	var sheet := Image.load_from_file(path)
	for row in range(4):
		for column in range(6):
			var frame := sheet.get_region(Rect2i(column * 64, row * 64, 64, 64))
			var bounds := frame.get_used_rect()
			var should_be_used: bool = column < int(MONSTER_LAYOUT[row])
			if should_be_used and bounds.size == Vector2i.ZERO:
				failures.append("%s row %d frame %d is empty" % [path, row, column])
			elif not should_be_used and bounds.size != Vector2i.ZERO:
				failures.append("%s row %d frame %d should be transparent" % [path, row, column])
			elif should_be_used:
				var center_x := bounds.position.x + bounds.size.x / 2.0
				var bottom_y := bounds.end.y - 1
				if absf(center_x - 32.0) > 2.0:
					failures.append("%s row %d frame %d center %.1f outside 32 +/- 2" % [path, row, column, center_x])
				if bottom_y != 48:
					failures.append("%s row %d frame %d bottom %d, expected 48" % [path, row, column, bottom_y])
				_verify_2x_grid(frame, bounds, "%s r%d f%d" % [path.get_file(), row, column])


func _verify_crystal_strip(path: String) -> void:
	var sheet := Image.load_from_file(path)
	for column in range(4):
		var frame := sheet.get_region(Rect2i(column * 48, 0, 48, 64))
		var bounds := frame.get_used_rect()
		var center_x := bounds.position.x + bounds.size.x / 2.0
		var bottom_y := bounds.end.y - 1
		if absf(center_x - 24.0) > 1.0:
			failures.append("%s frame %d center %.1f outside 24 +/- 1" % [path, column, center_x])
		if bottom_y != 56:
			failures.append("%s frame %d bottom %d, expected 56" % [path, column, bottom_y])
		_verify_2x_grid(frame, bounds, "%s f%d" % [path.get_file(), column])


func _verify_2x_grid(image: Image, bounds: Rect2i, label: String) -> void:
	for local_y in range(0, bounds.size.y - 1, 2):
		for local_x in range(0, bounds.size.x - 1, 2):
			var origin := bounds.position + Vector2i(local_x, local_y)
			var color := image.get_pixelv(origin)
			if image.get_pixelv(origin + Vector2i(1, 0)) != color or image.get_pixelv(origin + Vector2i(0, 1)) != color or image.get_pixelv(origin + Vector2i(1, 1)) != color:
				failures.append("%s breaks the 2x pixel grid at %s" % [label, origin])
				return
