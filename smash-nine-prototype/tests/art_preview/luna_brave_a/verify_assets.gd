extends SceneTree

const SHEET_PATH := "res://assets/art/luna/luna_brave_sheet.png"
const LOGO_PATH := "res://assets/art/ui/title_logo.png"
const CSV_PATH := "res://../reports/codex-art-06/alignment_luna_brave.csv"
const CELL := Vector2i(64, 64)
const SHEET_SIZE := Vector2i(384, 448)
const LOGO_SIZE := Vector2i(640, 200)
const USED_COUNTS := [4, 6, 1, 1, 4, 6, 1]
const EXPECTED_FEET_ROW := 48
const ANIMATIONS := ["idle", "walk", "jump", "fall", "attack", "shield", "hurt"]

func _init() -> void:
	var failures: Array[String] = []
	var sheet := Image.load_from_file(SHEET_PATH)
	var logo := Image.load_from_file(LOGO_PATH)
	if sheet.is_empty():
		failures.append("Brave Luna sheet could not load")
	else:
		_verify_sheet(sheet, failures)
	if logo.is_empty():
		failures.append("Title logo could not load")
	else:
		_verify_logo(logo, failures)
	if failures.is_empty():
		print("ART_06_VERIFY PASS sheet=384x448 frames=23 feet=48 centre=31.5..32.5 logo=640x200 alpha=hard")
		quit()
	else:
		for failure in failures:
			push_error(failure)
		print("ART_06_VERIFY FAIL count=%d" % failures.size())
		quit(1)

func _verify_sheet(sheet: Image, failures: Array[String]) -> void:
	if sheet.get_size() != SHEET_SIZE:
		failures.append("Sheet size expected %s, got %s" % [SHEET_SIZE, sheet.get_size()])
	if sheet.get_format() != Image.FORMAT_RGBA8:
		failures.append("Sheet expected RGBA8, got %d" % sheet.get_format())
	var csv := FileAccess.open(CSV_PATH, FileAccess.WRITE)
	if csv == null:
		failures.append("Could not write alignment table")
		return
	csv.store_line("animation,row,column,bounds_x,bounds_y,bounds_w,bounds_h,feet_y,opaque_centroid_x,opaque_pixels")
	var used_frames := 0
	for row in range(USED_COUNTS.size()):
		for column in range(6):
			var frame := sheet.get_region(Rect2i(column * CELL.x, row * CELL.y, CELL.x, CELL.y))
			var bounds := frame.get_used_rect()
			var should_be_used: bool = column < int(USED_COUNTS[row])
			if should_be_used and bounds.size == Vector2i.ZERO:
				failures.append("Used frame r%d c%d is empty" % [row, column])
			elif not should_be_used and bounds.size != Vector2i.ZERO:
				failures.append("Unused frame r%d c%d is not transparent" % [row, column])
			if not should_be_used or bounds.size == Vector2i.ZERO:
				continue
			used_frames += 1
			var feet_y := bounds.end.y - 1
			var centroid := _opaque_centroid_x(frame)
			var opaque_pixels := _opaque_pixel_count(frame)
			if feet_y != EXPECTED_FEET_ROW:
				failures.append("Feet r%d c%d expected %d, got %d" % [row, column, EXPECTED_FEET_ROW, feet_y])
			if centroid < 31.5 or centroid > 32.5:
				failures.append("Centre r%d c%d expected 31.5..32.5, got %.2f" % [row, column, centroid])
			if bounds.position.x < 0 or bounds.position.y < 0 or bounds.end.x > CELL.x or bounds.end.y > CELL.y:
				failures.append("Frame r%d c%d exceeds its cell" % [row, column])
			csv.store_line("%s,%d,%d,%d,%d,%d,%d,%d,%.2f,%d" % [
				ANIMATIONS[row], row, column, bounds.position.x, bounds.position.y,
				bounds.size.x, bounds.size.y, feet_y, centroid, opaque_pixels
			])
	if used_frames != 23:
		failures.append("Expected 23 used frames, got %d" % used_frames)
	_verify_hard_alpha(sheet, "sheet", failures)

func _verify_logo(logo: Image, failures: Array[String]) -> void:
	if logo.get_size() != LOGO_SIZE:
		failures.append("Logo size expected %s, got %s" % [LOGO_SIZE, logo.get_size()])
	if logo.get_format() != Image.FORMAT_RGBA8:
		failures.append("Logo expected RGBA8, got %d" % logo.get_format())
	var bounds := logo.get_used_rect()
	if bounds.size == Vector2i.ZERO:
		failures.append("Logo is empty")
	if bounds.position.x <= 0 or bounds.position.y <= 0 or bounds.end.x >= LOGO_SIZE.x or bounds.end.y >= LOGO_SIZE.y:
		failures.append("Logo needs transparent edge padding, got %s" % bounds)
	_verify_hard_alpha(logo, "logo", failures)

func _verify_hard_alpha(image: Image, label: String, failures: Array[String]) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var alpha := image.get_pixel(x, y).a
			if alpha > 0.0 and alpha < 1.0:
				failures.append("%s contains partial alpha at %d,%d" % [label, x, y])
				return

func _opaque_centroid_x(image: Image) -> float:
	var sum_x := 0.0
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.0:
				sum_x += x
				count += 1
	return sum_x / maxf(count, 1)

func _opaque_pixel_count(image: Image) -> int:
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.0:
				count += 1
	return count
