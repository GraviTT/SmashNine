extends SceneTree

const CELL := Vector2i(64, 64)
const COLUMNS := 6
const ROWS := 7
const EXPECTED_SIZE := Vector2i(384, 448)
const USED_COUNTS := [4, 6, 1, 1, 4, 6, 1]
const EXPECTED_FEET_ROW := 48
const REPORT_PATH := "res://../reports/codex-art-03a/alignment.csv"
const SHEETS := [
	{"name": "yuki", "path": "res://assets/art/yuki/yuki_sheet.png", "portrait": "res://assets/art/yuki/yuki_portrait.png"},
	{"name": "nova_male", "path": "res://assets/art/nova/nova_male_sheet.png", "portrait": "res://assets/art/nova/nova_male_portrait.png"},
	{"name": "nova_female", "path": "res://assets/art/nova/nova_female_sheet.png", "portrait": "res://assets/art/nova/nova_female_portrait.png"},
]

func _init() -> void:
	var failures: Array[String] = []
	var csv := "sheet,animation,row,column,bounds_x,bounds_y,bounds_w,bounds_h,feet_y,opaque_centroid_x,opaque_pixels\n"
	for spec in SHEETS:
		var result := _verify_sheet(spec, failures)
		csv += result
		_verify_portrait(spec, failures)
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		failures.append("could not write %s" % REPORT_PATH)
	else:
		file.store_string(csv)
	if failures.is_empty():
		print("CHARS_A_VERIFY PASS sheets=3 size=%s used_frames=69 feet_row=%d unused_cells=57 transparent" % [EXPECTED_SIZE, EXPECTED_FEET_ROW])
		quit()
	else:
		for failure in failures:
			push_error(failure)
		print("CHARS_A_VERIFY FAIL count=%d" % failures.size())
		quit(1)

func _verify_sheet(spec: Dictionary, failures: Array[String]) -> String:
	var sheet := Image.load_from_file(spec.path)
	var csv := ""
	if sheet.is_empty():
		failures.append("%s could not load" % spec.name)
		return csv
	if sheet.get_size() != EXPECTED_SIZE:
		failures.append("%s size expected %s, got %s" % [spec.name, EXPECTED_SIZE, sheet.get_size()])
	if sheet.get_format() != Image.FORMAT_RGBA8:
		failures.append("%s format expected RGBA8, got %s" % [spec.name, sheet.get_format()])
	for row in range(ROWS):
		for column in range(COLUMNS):
			var frame := sheet.get_region(Rect2i(column * CELL.x, row * CELL.y, CELL.x, CELL.y))
			var bounds := frame.get_used_rect()
			var should_be_used: bool = column < int(USED_COUNTS[row])
			if should_be_used and bounds.size == Vector2i.ZERO:
				failures.append("%s used frame r%d c%d is empty" % [spec.name, row, column])
			elif not should_be_used and bounds.size != Vector2i.ZERO:
				failures.append("%s unused frame r%d c%d is not transparent" % [spec.name, row, column])
			if not should_be_used or bounds.size == Vector2i.ZERO:
				continue
			var feet_y := bounds.position.y + bounds.size.y - 1
			if feet_y != EXPECTED_FEET_ROW:
				failures.append("%s feet r%d c%d expected %d, got %d" % [spec.name, row, column, EXPECTED_FEET_ROW, feet_y])
			var sum_x := 0.0
			var opaque_pixels := 0
			for y in range(CELL.y):
				for x in range(CELL.x):
					var alpha := frame.get_pixel(x, y).a
					if alpha > 0.0:
						sum_x += x
						opaque_pixels += 1
						if alpha < 1.0:
							failures.append("%s r%d c%d has semi-transparent pixels" % [spec.name, row, column])
			var centroid_x := sum_x / opaque_pixels
			if absf(centroid_x - 32.0) > 0.75:
				failures.append("%s centroid r%d c%d expected within 0.75 of 32, got %.2f" % [spec.name, row, column, centroid_x])
			csv += "%s,%s,%d,%d,%d,%d,%d,%d,%d,%.2f,%d\n" % [
				spec.name, _animation_name(row), row, column, bounds.position.x, bounds.position.y,
				bounds.size.x, bounds.size.y, feet_y, centroid_x, opaque_pixels
			]
	return csv

func _animation_name(row: int) -> String:
	return ["idle", "walk", "jump", "fall", "attack", "shield", "hurt"][row]

func _verify_portrait(spec: Dictionary, failures: Array[String]) -> void:
	var portrait := Image.load_from_file(spec.portrait)
	if portrait.is_empty():
		failures.append("%s portrait could not load" % spec.name)
		return
	if portrait.get_size() != Vector2i(64, 64):
		failures.append("%s portrait size expected (64, 64), got %s" % [spec.name, portrait.get_size()])
	if portrait.get_format() != Image.FORMAT_RGBA8:
		failures.append("%s portrait format expected RGBA8, got %s" % [spec.name, portrait.get_format()])
	if portrait.get_used_rect().size == Vector2i.ZERO:
		failures.append("%s portrait is empty" % spec.name)
