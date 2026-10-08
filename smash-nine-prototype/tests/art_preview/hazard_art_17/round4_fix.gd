extends SceneTree

const REPORT_DIR := "../reports/codex-art-17"
const HAZARD_PATH := "res://assets/art/hazards/fire_pillar_mid.png"
const BEFORE_PATH := REPORT_DIR + "/round4_before_fire_pillar_mid.png"
const FRAME_SIZE := Vector2i(96, 128)
const FRAME_COUNT := 6
const CENTRE_X := 36
const CENTRE_WIDTH := 24
const CHECK_START := 100
const CHECK_END := 120
const MAX_DARK_DEFICIT := 0.08
const ALPHA_THRESHOLD := 0.12


func _init() -> void:
	if "--probe-only" in OS.get_cmdline_user_args():
		print_probe(load_image(HAZARD_PATH), "current")
		quit()
		return
	preserve_before()
	var before := load_image(BEFORE_PATH)
	var after := repair_sheet(before)
	validate(before, after)
	save_image(after, HAZARD_PATH)
	build_previews(before, after)
	write_verification(before, after)
	print("ART17_ROUND4_OK")
	quit()


func load_image(path: String) -> Image:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_error("Could not load: " + path)
		quit(1)
	return image


func save_image(image: Image, path: String) -> void:
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save: %s error=%s" % [path, error])
		quit(1)


func preserve_before() -> void:
	if not FileAccess.file_exists(BEFORE_PATH):
		save_image(load_image(HAZARD_PATH), BEFORE_PATH)


func repair_sheet(source: Image) -> Image:
	# Rebuild from the preserved Round 3 result so repeated runs are identical.
	var result := source.duplicate()
	blend_band(source, result, 1, 110, 110)
	blend_band(source, result, 2, 110, 110)
	blend_band(source, result, 3, 110, 112)
	blend_band(source, result, 4, 110, 110)
	return result


func blend_band(source: Image, target: Image, frame: int, first_y: int, last_y: int) -> void:
	# Interpolate only RGB between the accepted neighbouring rows. Keeping each
	# target pixel's original alpha preserves the silhouette and creates no shape.
	var frame_x := frame * FRAME_SIZE.x
	for y in range(first_y, last_y + 1):
		var ratio := float(y - first_y + 1) / float(last_y - first_y + 2)
		for local_x in FRAME_SIZE.x:
			var x := frame_x + local_x
			var original := source.get_pixel(x, y)
			if original.a <= ALPHA_THRESHOLD:
				continue
			var above := source.get_pixel(x, first_y - 1)
			var below := source.get_pixel(x, last_y + 1)
			var blended := above.lerp(below, ratio)
			blended.a = original.a
			target.set_pixel(x, y, blended)


func centre_brightness(cell: Image, y: int) -> float:
	var total := 0.0
	for x in range(CENTRE_X, CENTRE_X + CENTRE_WIDTH):
		total += cell.get_pixel(x, y).get_luminance()
	return total / CENTRE_WIDTH


func dark_deficit(cell: Image, y: int) -> float:
	var neighbours := (centre_brightness(cell, y - 1) + centre_brightness(cell, y + 1)) * 0.5
	return neighbours - centre_brightness(cell, y)


func maximum_dark_deficit(cell: Image) -> float:
	var maximum := -INF
	for y in range(CHECK_START, CHECK_END + 1):
		maximum = maxf(maximum, dark_deficit(cell, y))
	return maximum


func row_fill(cell: Image, y: int) -> int:
	var filled := 0
	for x in cell.get_width():
		if cell.get_pixel(x, y).a > ALPHA_THRESHOLD:
			filled += 1
	return filled


func row_bounds(cell: Image, y: int) -> Vector2i:
	var left := cell.get_width()
	var right := -1
	for x in cell.get_width():
		if cell.get_pixel(x, y).a > ALPHA_THRESHOLD:
			left = mini(left, x)
			right = maxi(right, x)
	return Vector2i(left, right)


func row_span(cell: Image, y: int) -> int:
	var bounds := row_bounds(cell, y)
	return 0 if bounds.y < bounds.x else bounds.y - bounds.x + 1


func body_width(cell: Image) -> int:
	var widths: Array[int] = []
	for y in range(20, 108):
		widths.append(row_span(cell, y))
	widths.sort()
	return widths[widths.size() / 2]


func edge_widths(cell: Image) -> String:
	var values: Array[String] = []
	for y in [0, 1, 2, 3, 124, 125, 126, 127]:
		values.append(str(row_span(cell, y)))
	return "/".join(values)


func color_difference(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a)


func wrap_difference(cell: Image) -> float:
	var difference := 0.0
	for x in cell.get_width():
		difference += color_difference(cell.get_pixel(x, 127), cell.get_pixel(x, 0))
	return difference


func changed_pixels(before: Image, after: Image, frame: int) -> int:
	var changed := 0
	for y in FRAME_SIZE.y:
		for local_x in FRAME_SIZE.x:
			var x := frame * FRAME_SIZE.x + local_x
			if before.get_pixel(x, y) != after.get_pixel(x, y):
				changed += 1
	return changed


func changed_outside_allowed_rows(before: Image, after: Image) -> int:
	var allowed := {
		Vector2i(1, 110): true,
		Vector2i(2, 110): true,
		Vector2i(3, 110): true,
		Vector2i(3, 111): true,
		Vector2i(3, 112): true,
		Vector2i(4, 110): true,
	}
	var changed := 0
	for y in FRAME_SIZE.y:
		for x in before.get_width():
			if before.get_pixel(x, y) == after.get_pixel(x, y):
				continue
			if not allowed.has(Vector2i(x / FRAME_SIZE.x, y)):
				changed += 1
	return changed


func validate(before: Image, after: Image) -> void:
	if before.get_size() != Vector2i(576, 128) or after.get_size() != before.get_size():
		fail("wrong sheet size")
	if changed_outside_allowed_rows(before, after) != 0:
		fail("pixels changed outside the six allowed frame rows")
	for frame in FRAME_COUNT:
		var before_cell := before.get_region(Rect2i(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y))
		var cell := after.get_region(Rect2i(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y))
		for y in cell.get_height():
			if row_fill(cell, y) < 32:
				fail("f%d row%d became empty/thin" % [frame + 1, y])
		for y in [0, 1, 2, 3, 124, 125, 126, 127]:
			if row_span(cell, y) != row_span(before_cell, y):
				fail("f%d Round 3 edge width changed" % [frame + 1])
		if absf(wrap_difference(cell) - wrap_difference(before_cell)) > 0.0001:
			fail("f%d Round 3 wrap difference changed" % [frame + 1])
		if maximum_dark_deficit(cell) > MAX_DARK_DEFICIT + 0.0001:
			fail("f%d has a dark deficit %.4f over %.2f" % [frame + 1, maximum_dark_deficit(cell), MAX_DARK_DEFICIT])


func fail(message: String) -> void:
	push_error(message)
	quit(1)


func checkerboard(size: Vector2i, cell_size: int = 16) -> Image:
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in range(0, size.y, cell_size):
		for x in range(0, size.x, cell_size):
			var parity := (x / cell_size + y / cell_size) as int
			var color := Color("182234") if parity % 2 == 0 else Color("24344a")
			image.fill_rect(Rect2i(x, y, mini(cell_size, size.x - x), mini(cell_size, size.y - y)), color)
	return image


func paste_scaled(canvas: Image, source: Image, position: Vector2i, scale: int) -> void:
	var scaled := source.duplicate()
	scaled.resize(source.get_width() * scale, source.get_height() * scale, Image.INTERPOLATE_NEAREST)
	canvas.blend_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), position)


func build_previews(before: Image, after: Image) -> void:
	# Each repaired frame is tiled three times under itself at nearest-neighbour 2x.
	var tiles := checkerboard(Vector2i(1248, 800), 16)
	for frame in FRAME_COUNT:
		var cell := after.get_region(Rect2i(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y))
		var x := 16 + frame * 208
		for repeat in 3:
			paste_scaled(tiles, cell, Vector2i(x, 16 + repeat * 256), 2)
		for tick in frame + 1:
			tiles.fill_rect(Rect2i(x + tick * 6, 6, 4, 4), Color("f2dfa3"))
	save_image(tiles, REPORT_DIR + "/round4_fire_self_tiles_2x.png")

	# Top row is before, bottom row after. Crop rows 96..123 to make the repaired
	# internal band visible at 4x without confusing it with the wrap joint.
	var comparison := checkerboard(Vector2i(2400, 240), 16)
	for version in 2:
		var sheet := before if version == 0 else after
		for frame in FRAME_COUNT:
			var crop := sheet.get_region(Rect2i(frame * FRAME_SIZE.x, 96, FRAME_SIZE.x, 28))
			paste_scaled(comparison, crop, Vector2i(8 + frame * 400, 8 + version * 120), 4)
	save_image(comparison, REPORT_DIR + "/round4_fire_before_after_4x.png")


func five_row_values(cell: Image) -> String:
	var values: Array[String] = []
	for y in range(108, 113):
		values.append("%.3f" % centre_brightness(cell, y))
	return "/".join(values)


func print_probe(sheet: Image, label: String) -> void:
	print("Round 4 probe: " + label)
	for frame in FRAME_COUNT:
		var cell := sheet.get_region(Rect2i(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y))
		print("f%d rows108..112=%s max_dark_deficit_100..120=%.4f" % [frame + 1, five_row_values(cell), maximum_dark_deficit(cell)])


func write_verification(before: Image, after: Image) -> void:
	var lines: Array[String] = []
	lines.append("Round 4 fire internal dark-row verification")
	lines.append("brightness=Godot Color.get_luminance mean over local x=36..59; check rows=100..120")
	lines.append("threshold=no row more than 0.08 darker than mean of immediate neighbours")
	lines.append("sheet_size=%s expected=(576, 128) ok=%s" % [after.get_size(), after.get_size() == Vector2i(576, 128)])
	lines.append("changed_outside_allowed_rows=%d" % changed_outside_allowed_rows(before, after))
	for frame in FRAME_COUNT:
		var before_cell := before.get_region(Rect2i(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y))
		var cell := after.get_region(Rect2i(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y))
		lines.append("f%d before_rows108..112=%s after_rows108..112=%s max_dark_before=%.4f max_dark_after=%.4f changed_pixels=%d body=%d edge_before=%s edge_after=%s wrap_before=%.4f wrap_after=%.4f" % [frame + 1, five_row_values(before_cell), five_row_values(cell), maximum_dark_deficit(before_cell), maximum_dark_deficit(cell), changed_pixels(before, after, frame), body_width(cell), edge_widths(before_cell), edge_widths(cell), wrap_difference(before_cell), wrap_difference(cell)])
	lines.append("alpha_shape=unchanged; RGB only on f2:r110, f3:r110, f4:r110..112, f5:r110")
	lines.append("anchors_unchanged=top-left per 96x128 cell; fire 12 fps loop")
	lines.append("preview=round4_fire_self_tiles_2x.png; each frame repeated 3x under itself at nearest-neighbour 2x")
	lines.append("comparison=round4_fire_before_after_4x.png; top before, bottom after, source rows 96..123")
	var file := FileAccess.open(REPORT_DIR + "/round4-verification.txt", FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
