extends SceneTree

const REPORT_DIR := "../reports/codex-art-17"
const HAZARD_DIR := "res://assets/art/hazards"
const FRAME_SIZE := Vector2i(96, 128)
const ALPHA_THRESHOLD := 0.12
const MIN_FILLED := 32
const TRANSPARENT := Color(0, 0, 0, 0)


func _init() -> void:
	preserve_before("light_beam_mid.png")
	preserve_before("fire_pillar_mid.png")
	preserve_before("quake_impact.png")
	repair_mid("light_beam_mid.png")
	repair_mid("fire_pillar_mid.png")
	reorder_quake_impact()
	build_tile_sequence_preview()
	build_sheet_comparison_preview()
	build_quake_comparison_preview()
	write_verification()
	print("ART17_ROUND2_OK")
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


func preserve_before(filename: String) -> void:
	var before_path := REPORT_DIR + "/round2_before_" + filename
	if not FileAccess.file_exists(before_path):
		save_image(load_image(HAZARD_DIR + "/" + filename), before_path)


func row_fill(cell: Image, y: int) -> int:
	var filled := 0
	for x in cell.get_width():
		if cell.get_pixel(x, y).a > ALPHA_THRESHOLD:
			filled += 1
	return filled


func copy_row(source: Image, source_y: int, target: Image, target_y: int) -> void:
	for x in target.get_width():
		target.set_pixel(x, target_y, source.get_pixel(x, source_y))


func nearest_full_row(cell: Image, target_y: int) -> int:
	for distance in cell.get_height():
		var above := target_y - distance
		if above >= 4 and above <= 123 and row_fill(cell, above) >= MIN_FILLED:
			return above
		var below := target_y + distance
		if below >= 4 and below <= 123 and row_fill(cell, below) >= MIN_FILLED:
			return below
	return 64


func repair_mid(filename: String) -> void:
	var source := load_image(REPORT_DIR + "/round2_before_" + filename)
	var repaired := Image.create_empty(96 * 6, 128, false, Image.FORMAT_RGBA8)
	# Frame 1 was already complete and accepted; its original four-row seam band
	# is retained and shared verbatim instead of inventing a new visual motif.
	var common_band := source.get_region(Rect2i(0, 0, 96, 4))
	for frame in 6:
		var cell := source.get_region(Rect2i(frame * 96, 0, 96, 128))
		var original_cell := cell.duplicate()
		# Repair only insufficient rows; all accepted interior pixels otherwise remain unchanged.
		for y in range(4, 124):
			if row_fill(original_cell, y) < MIN_FILLED:
				# Continue the preceding 16-row texture cadence rather than stretching
				# one donor row into a flat block.
				var donor_y := y - 16
				while donor_y >= 4 and row_fill(original_cell, donor_y) < MIN_FILLED:
					donor_y -= 16
				if donor_y < 4:
					donor_y = nearest_full_row(original_cell, y)
				copy_row(original_cell, donor_y, cell, y)
		# A shared four-row band makes every possible frame-to-frame join exact.
		for y in 4:
			copy_row(common_band, y, cell, y)
			copy_row(common_band, y, cell, 124 + y)
		for y in cell.get_height():
			if row_fill(cell, y) < MIN_FILLED:
				push_error("%s frame=%d row=%d remains thin" % [filename, frame + 1, y])
				quit(1)
		repaired.blit_rect(cell, Rect2i(Vector2i.ZERO, FRAME_SIZE), Vector2i(frame * 96, 0))
	save_image(repaired, HAZARD_DIR + "/" + filename)


func reorder_quake_impact() -> void:
	var source := load_image(REPORT_DIR + "/round2_before_quake_impact.png")
	var result := Image.create_empty(128 * 6, 64, false, Image.FORMAT_RGBA8)
	# Original frame 4 is the ignition, followed by growth, peak, and two settling frames.
	var order := [3, 0, 2, 1, 4, 5]
	for target_frame in 6:
		var source_frame: int = order[target_frame]
		result.blit_rect(source, Rect2i(source_frame * 128, 0, 128, 64), Vector2i(target_frame * 128, 0))
	save_image(result, HAZARD_DIR + "/quake_impact.png")


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


func build_tile_sequence_preview() -> void:
	var board := checkerboard(Vector2i(640, 2080), 16)
	var sequence := [0, 1, 2, 3, 4, 5, 5, 0]
	var files := ["light_beam_mid.png", "fire_pillar_mid.png"]
	for column in 2:
		var sheet := load_image(HAZARD_DIR + "/" + files[column])
		for index in sequence.size():
			var frame: int = sequence[index]
			var cell := sheet.get_region(Rect2i(frame * 96, 0, 96, 128))
			paste_scaled(board, cell, Vector2i(80 + column * 320, 16 + index * 256), 2)
			# One-pixel frame-index ticks at the far side do not touch the art.
			for tick in frame + 1:
				for dy in 6:
					board.set_pixel(48 + column * 320 + tick * 4, 24 + index * 256 + dy, Color("f2dfa3"))
	save_image(board, REPORT_DIR + "/round2_tile_sequence_2x.png")


func build_sheet_comparison_preview() -> void:
	var board := checkerboard(Vector2i(1152, 1088), 16)
	var names := ["light_beam_mid.png", "fire_pillar_mid.png"]
	for index in 2:
		var before := load_image(REPORT_DIR + "/round2_before_" + names[index])
		var after := load_image(HAZARD_DIR + "/" + names[index])
		var section_y := index * 544
		paste_scaled(board, before, Vector2i(0, section_y + 8), 2)
		paste_scaled(board, after, Vector2i(0, section_y + 280), 2)
	save_image(board, REPORT_DIR + "/round2_mid_before_after_2x.png")


func build_quake_comparison_preview() -> void:
	var board := checkerboard(Vector2i(1536, 288), 16)
	var before := load_image(REPORT_DIR + "/round2_before_quake_impact.png")
	var after := load_image(HAZARD_DIR + "/quake_impact.png")
	paste_scaled(board, before, Vector2i.ZERO, 2)
	paste_scaled(board, after, Vector2i(0, 144), 2)
	save_image(board, REPORT_DIR + "/round2_quake_before_after_2x.png")


func frame_bounds(cell: Image) -> Rect2i:
	var min_x := cell.get_width()
	var min_y := cell.get_height()
	var max_x := -1
	var max_y := -1
	for y in cell.get_height():
		for x in cell.get_width():
			if cell.get_pixel(x, y).a > ALPHA_THRESHOLD:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func occupied_pixels(cell: Image) -> int:
	var count := 0
	for y in cell.get_height():
		for x in cell.get_width():
			if cell.get_pixel(x, y).a > ALPHA_THRESHOLD:
				count += 1
	return count


func mid_metrics(sheet: Image) -> String:
	var values: Array[String] = []
	for frame in 6:
		var cell := sheet.get_region(Rect2i(frame * 96, 0, 96, 128))
		var empty_rows := 0
		var thin_rows := 0
		var minimum := 96
		for y in 128:
			var filled := row_fill(cell, y)
			minimum = mini(minimum, filled)
			if filled == 0:
				empty_rows += 1
			if filled < MIN_FILLED:
				thin_rows += 1
		values.append("f%d empty=%d under_1_3=%d min_fill=%d" % [frame + 1, empty_rows, thin_rows, minimum])
	return "; ".join(values)


func cross_frame_band_mismatch(sheet: Image) -> int:
	var mismatch := 0
	for frame in 6:
		for y in 4:
			for x in 96:
				var reference := sheet.get_pixel(x, y)
				if sheet.get_pixel(frame * 96 + x, y) != reference:
					mismatch += 1
				if sheet.get_pixel(frame * 96 + x, 124 + y) != reference:
					mismatch += 1
	return mismatch


func quake_metrics(sheet: Image) -> String:
	var values: Array[String] = []
	for frame in 6:
		var cell := sheet.get_region(Rect2i(frame * 128, 0, 128, 64))
		values.append("f%d bounds=%s occupied=%d" % [frame + 1, frame_bounds(cell), occupied_pixels(cell)])
	return "; ".join(values)


func write_verification() -> void:
	var lines: Array[String] = []
	for filename in ["light_beam_mid.png", "fire_pillar_mid.png"]:
		var before := load_image(REPORT_DIR + "/round2_before_" + filename)
		var after := load_image(HAZARD_DIR + "/" + filename)
		lines.append(filename + " size=" + str(after.get_size()) + " expected=(576, 128) ok=" + str(after.get_size() == Vector2i(576, 128)))
		lines.append(filename + " before: " + mid_metrics(before))
		lines.append(filename + " after:  " + mid_metrics(after))
		lines.append(filename + " after_cross_frame_top_bottom_4_mismatch=" + str(cross_frame_band_mismatch(after)))
	var quake_before := load_image(REPORT_DIR + "/round2_before_quake_impact.png")
	var quake_after := load_image(HAZARD_DIR + "/quake_impact.png")
	lines.append("quake_impact.png size=" + str(quake_after.get_size()) + " expected=(768, 64) ok=" + str(quake_after.get_size() == Vector2i(768, 64)))
	lines.append("quake_impact before: " + quake_metrics(quake_before))
	lines.append("quake_impact after:  " + quake_metrics(quake_after))
	lines.append("quake_impact_order=old4,old1,old3,old2,old5,old6")
	lines.append("anchors_unchanged=mid top-left per 96x128 cell; quake bottom-center (64,63) per 128x64 cell")
	var file := FileAccess.open(REPORT_DIR + "/round2-verification.txt", FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
