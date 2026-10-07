extends SceneTree

const SOURCE_DIR := "res://../reports/codex-art-05a/"
const MONSTER_DIR := "res://assets/art/monsters/"
const OBJECT_DIR := "res://assets/art/objects/"
const ALPHA_CUTOFF := 0.55
const MONSTER_LAYOUT := [4, 6, 4, 1]


func _init() -> void:
	var failures: Array[String] = []
	if not _build_monster(
		SOURCE_DIR + "source_mossling.png",
		MONSTER_DIR + "mossling_sheet.png",
		Vector2i(54, 42),
		48,
		"mossling"
	):
		failures.append("mossling")
	if not _build_monster(
		SOURCE_DIR + "source_ember_imp.png",
		MONSTER_DIR + "ember_imp_sheet.png",
		Vector2i(48, 50),
		48,
		"ember_imp"
	):
		failures.append("ember_imp")
	if not _build_single(
		SOURCE_DIR + "source_ember_fireball.png",
		MONSTER_DIR + "ember_fireball.png",
		Vector2i(24, 24),
		Vector2i(22, 18),
		"ember_fireball"
	):
		failures.append("ember_fireball")
	if not _build_strip(
		SOURCE_DIR + "source_soul_crystal.png",
		OBJECT_DIR + "soul_crystal.png",
		Vector2i(48, 64),
		Vector2i(44, 56),
		56,
		"soul_crystal"
	):
		failures.append("soul_crystal")
	if not _build_strip(
		SOURCE_DIR + "source_soul_crystal_shatter.png",
		OBJECT_DIR + "soul_crystal_shatter.png",
		Vector2i(48, 64),
		Vector2i(46, 56),
		56,
		"soul_crystal_shatter"
	):
		failures.append("soul_crystal_shatter")
	if failures.is_empty():
		print("BUILD_OK all five Unit A assets saved")
		quit(0)
	else:
		push_error("BUILD_FAILED: %s" % ", ".join(failures))
		quit(1)


func _build_monster(source_path: String, output_path: String, max_size: Vector2i, baseline_y: int, label: String) -> bool:
	var source := Image.load_from_file(source_path)
	if source.is_empty() or source.get_width() % 6 != 0 or source.get_height() % 4 != 0:
		push_error("Invalid 6x4 source: %s" % source_path)
		return false
	var source_cell := Vector2i(source.get_width() / 6, source.get_height() / 4)
	var sheet := Image.create(384, 256, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	for row in range(4):
		for column in range(MONSTER_LAYOUT[row]):
			var source_rect := Rect2i(column * source_cell.x, row * source_cell.y, source_cell.x, source_cell.y)
			var raw_cell := source.get_region(source_rect)
			var frame := _extract_pixel_art(raw_cell, max_size)
			if frame.is_empty():
				push_error("No opaque art in %s row=%d col=%d" % [label, row, column])
				return false
			var position := Vector2i(column * 64 + (64 - frame.get_width()) / 2, row * 64 + baseline_y - frame.get_height() + 1)
			sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), position)
	var error := sheet.save_png(output_path)
	if error != OK:
		push_error("Could not save %s: %s" % [output_path, error_string(error)])
		return false
	_print_sheet_metrics(label, sheet, Vector2i(64, 64), MONSTER_LAYOUT)
	return true


func _build_single(source_path: String, output_path: String, canvas_size: Vector2i, max_size: Vector2i, label: String) -> bool:
	var source := Image.load_from_file(source_path)
	if source.is_empty():
		push_error("Invalid source: %s" % source_path)
		return false
	var sprite := _extract_pixel_art(source, max_size)
	if sprite.is_empty():
		push_error("No opaque art in %s" % label)
		return false
	var output := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	var position := Vector2i((canvas_size.x - sprite.get_width()) / 2, (canvas_size.y - sprite.get_height()) / 2)
	output.blit_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), position)
	var error := output.save_png(output_path)
	if error != OK:
		push_error("Could not save %s: %s" % [output_path, error_string(error)])
		return false
	var bounds := _alpha_bounds(output)
	print("ALIGN %s frame=0 bounds=%s center_x=%.1f" % [label, bounds, bounds.position.x + bounds.size.x / 2.0])
	return true


func _build_strip(source_path: String, output_path: String, cell_size: Vector2i, max_size: Vector2i, baseline_y: int, label: String) -> bool:
	var source := Image.load_from_file(source_path)
	if source.is_empty() or source.get_width() % 4 != 0:
		push_error("Invalid 4-frame strip source: %s" % source_path)
		return false
	var source_cell_width := source.get_width() / 4
	var output := Image.create(cell_size.x * 4, cell_size.y, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for column in range(4):
		var source_rect := Rect2i(column * source_cell_width, 0, source_cell_width, source.get_height())
		var raw_cell := source.get_region(source_rect)
		var frame := _extract_pixel_art(raw_cell, max_size)
		if frame.is_empty():
			push_error("No opaque art in %s frame=%d" % [label, column])
			return false
		var position := Vector2i(column * cell_size.x + (cell_size.x - frame.get_width()) / 2, baseline_y - frame.get_height() + 1)
		output.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), position)
	var error := output.save_png(output_path)
	if error != OK:
		push_error("Could not save %s: %s" % [output_path, error_string(error)])
		return false
	_print_sheet_metrics(label, output, cell_size, [4])
	return true


func _extract_pixel_art(source: Image, max_size: Vector2i) -> Image:
	var bounds := _alpha_bounds(source)
	if bounds.size == Vector2i.ZERO:
		return Image.new()
	bounds = bounds.grow(2).intersection(Rect2i(Vector2i.ZERO, source.get_size()))
	var cropped := source.get_region(bounds)
	var scale := minf(float(max_size.x) / cropped.get_width(), float(max_size.y) / cropped.get_height())
	var width := maxi(2, int(floor(cropped.get_width() * scale / 2.0)) * 2)
	var height := maxi(2, int(floor(cropped.get_height() * scale / 2.0)) * 2)
	width = mini(width, max_size.x - (max_size.x % 2))
	height = mini(height, max_size.y - (max_size.y % 2))
	cropped.resize(width / 2, height / 2, Image.INTERPOLATE_NEAREST)
	cropped.resize(width, height, Image.INTERPOLATE_NEAREST)
	_harden_and_quantize(cropped)
	var final_bounds := _alpha_bounds(cropped)
	return cropped.get_region(final_bounds) if final_bounds.size != Vector2i.ZERO else Image.new()


func _alpha_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a >= ALPHA_CUTOFF:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _harden_and_quantize(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_CUTOFF:
				image.set_pixel(x, y, Color.TRANSPARENT)
			else:
				color.r = roundf(color.r * 15.0) / 15.0
				color.g = roundf(color.g * 15.0) / 15.0
				color.b = roundf(color.b * 15.0) / 15.0
				color.a = 1.0
				image.set_pixel(x, y, color)


func _print_sheet_metrics(label: String, sheet: Image, cell_size: Vector2i, row_counts: Array) -> void:
	for row in range(row_counts.size()):
		for column in range(row_counts[row]):
			var cell := sheet.get_region(Rect2i(column * cell_size.x, row * cell_size.y, cell_size.x, cell_size.y))
			var bounds := _alpha_bounds(cell)
			var center_x := bounds.position.x + bounds.size.x / 2.0
			var bottom_y := bounds.end.y - 1
			print("ALIGN %s row=%d frame=%d bounds=%s center_x=%.1f bottom_y=%d" % [label, row, column, bounds, center_x, bottom_y])
