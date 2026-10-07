extends SceneTree

const SHEET_PATH := "res://assets/art/frey/frey_sheet.png"
const CELL := Vector2i(64, 64)
const COLUMNS := 6
const ROWS := 7
const EXPECTED_SIZE := Vector2i(384, 448)
const USED_COUNTS := [4, 6, 1, 1, 4, 6, 1]
const EXPECTED_FEET_ROW := 48

func _init() -> void:
	var sheet := Image.load_from_file(SHEET_PATH)
	var failures: Array[String] = []
	if sheet.get_size() != EXPECTED_SIZE:
		failures.append("size expected %s, got %s" % [EXPECTED_SIZE, sheet.get_size()])
	print("animation,row,column,bounds_x,bounds_y,bounds_w,bounds_h,feet_y,opaque_centroid_x,opaque_pixels")
	for row in range(ROWS):
		for column in range(COLUMNS):
			var frame := sheet.get_region(Rect2i(column * CELL.x, row * CELL.y, CELL.x, CELL.y))
			var bounds := frame.get_used_rect()
			var should_be_used: bool = column < int(USED_COUNTS[row])
			if should_be_used and bounds.size == Vector2i.ZERO:
				failures.append("used frame r%d c%d is empty" % [row, column])
			elif not should_be_used and bounds.size != Vector2i.ZERO:
				failures.append("unused frame r%d c%d is not transparent" % [row, column])
			if not should_be_used or bounds.size == Vector2i.ZERO:
				continue
			var feet_y := bounds.position.y + bounds.size.y - 1
			if feet_y != EXPECTED_FEET_ROW:
				failures.append("feet r%d c%d expected %d, got %d" % [row, column, EXPECTED_FEET_ROW, feet_y])
			var sum_x := 0.0
			var opaque_pixels := 0
			for y in range(CELL.y):
				for x in range(CELL.x):
					if frame.get_pixel(x, y).a > 0.0:
						sum_x += x
						opaque_pixels += 1
			var centroid_x := sum_x / opaque_pixels
			print("%s,%d,%d,%d,%d,%d,%d,%d,%.2f,%d" % [
				_animation_name(row), row, column, bounds.position.x, bounds.position.y,
				bounds.size.x, bounds.size.y, feet_y, centroid_x, opaque_pixels
			])
	if failures.is_empty():
		print("FREY_VERIFY PASS size=%s used_frames=23 feet_row=%d unused_cells=19 transparent" % [EXPECTED_SIZE, EXPECTED_FEET_ROW])
		quit()
	else:
		for failure in failures:
			push_error(failure)
		print("FREY_VERIFY FAIL count=%d" % failures.size())
		quit(1)

func _animation_name(row: int) -> String:
	return ["idle", "walk", "jump", "fall", "attack", "shield", "hurt"][row]
