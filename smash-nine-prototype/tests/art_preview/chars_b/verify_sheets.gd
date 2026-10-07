extends SceneTree

const CELL := Vector2i(64, 64)
const COLUMNS := 6
const ROWS := 7
const EXPECTED_SIZE := Vector2i(384, 448)
const USED_COUNTS := [4, 6, 1, 1, 4, 6, 1]
const EXPECTED_FEET_ROW := 48
const SPECS := [
	{"name": "luna", "sheet": "res://assets/art/luna/luna_sheet.png", "portrait": "res://assets/art/luna/luna_portrait.png", "csv": "res://../reports/codex-art-03b/alignment_luna.csv"},
	{"name": "rio_male", "sheet": "res://assets/art/rio/rio_male_sheet.png", "portrait": "res://assets/art/rio/rio_male_portrait.png", "csv": "res://../reports/codex-art-03b/alignment_rio_male.csv"},
	{"name": "rio_female", "sheet": "res://assets/art/rio/rio_female_sheet.png", "portrait": "res://assets/art/rio/rio_female_portrait.png", "csv": "res://../reports/codex-art-03b/alignment_rio_female.csv"},
]

func _init() -> void:
	var all_failures: Array[String] = []
	for spec in SPECS:
		_verify_sheet(spec, all_failures)
	if all_failures.is_empty():
		print("CHARS_B_VERIFY PASS sheets=3 size=%s used_frames=69 feet_row=%d unused_cells=57 transparent" % [EXPECTED_SIZE, EXPECTED_FEET_ROW])
		quit()
	else:
		for failure in all_failures:
			push_error(failure)
		print("CHARS_B_VERIFY FAIL count=%d" % all_failures.size())
		quit(1)

func _verify_sheet(spec: Dictionary, failures: Array[String]) -> void:
	var sheet := Image.load_from_file(String(spec.sheet))
	var name := String(spec.name)
	if sheet.is_empty():
		failures.append("%s could not load" % name)
		return
	if sheet.get_size() != EXPECTED_SIZE:
		failures.append("%s size expected %s, got %s" % [name, EXPECTED_SIZE, sheet.get_size()])
	if sheet.get_format() != Image.FORMAT_RGBA8:
		failures.append("%s expected RGBA8, got format %d" % [name, sheet.get_format()])
	var portrait := Image.load_from_file(String(spec.portrait))
	if portrait.get_size() != CELL:
		failures.append("%s portrait size expected %s, got %s" % [name, CELL, portrait.get_size()])
	if portrait.get_format() != Image.FORMAT_RGBA8:
		failures.append("%s portrait expected RGBA8, got format %d" % [name, portrait.get_format()])
	var csv := FileAccess.open(String(spec.csv), FileAccess.WRITE)
	if csv == null:
		failures.append("%s could not write alignment csv" % name)
		return
	csv.store_line("animation,row,column,bounds_x,bounds_y,bounds_w,bounds_h,feet_y,opaque_centroid_x,opaque_pixels")
	for row in range(ROWS):
		for column in range(COLUMNS):
			var frame := sheet.get_region(Rect2i(column * CELL.x, row * CELL.y, CELL.x, CELL.y))
			var bounds := frame.get_used_rect()
			var should_be_used: bool = column < int(USED_COUNTS[row])
			if should_be_used and bounds.size == Vector2i.ZERO:
				failures.append("%s used frame r%d c%d is empty" % [name, row, column])
			elif not should_be_used and bounds.size != Vector2i.ZERO:
				failures.append("%s unused frame r%d c%d is not transparent" % [name, row, column])
			if not should_be_used or bounds.size == Vector2i.ZERO:
				continue
			var feet_y := bounds.position.y + bounds.size.y - 1
			if feet_y != EXPECTED_FEET_ROW:
				failures.append("%s feet r%d c%d expected %d, got %d" % [name, row, column, EXPECTED_FEET_ROW, feet_y])
			var sum_x := 0.0
			var opaque_pixels := 0
			for y in range(CELL.y):
				for x in range(CELL.x):
					if frame.get_pixel(x, y).a > 0.0:
						sum_x += x
						opaque_pixels += 1
			var centroid_x := sum_x / opaque_pixels
			if centroid_x < 31.5 or centroid_x > 32.5:
				failures.append("%s centre r%d c%d expected 31.5..32.5, got %.2f" % [name, row, column, centroid_x])
			csv.store_line("%s,%d,%d,%d,%d,%d,%d,%d,%.2f,%d" % [
				_animation_name(row), row, column, bounds.position.x, bounds.position.y,
				bounds.size.x, bounds.size.y, feet_y, centroid_x, opaque_pixels
			])
	print("[chars-b-verify] %s PASS" % name)

func _animation_name(row: int) -> String:
	return ["idle", "walk", "jump", "fall", "attack", "shield", "hurt"][row]
