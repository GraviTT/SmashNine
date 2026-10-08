extends SceneTree

const REPORT_DIR := "../reports/codex-art-17"
const HAZARD_DIR := "res://assets/art/hazards"
const FRAME_SIZE := Vector2i(96, 128)
const FRAME_COUNT := 6
const ALPHA_THRESHOLD := 0.12
const EDGE_ROWS := 4


func _init() -> void:
	for filename in ["light_beam_mid.png", "fire_pillar_mid.png"]:
		preserve_before(filename)
		repair_sheet(filename)
		validate_sheet(filename)
	build_preview()
	write_verification()
	print("ART17_ROUND3_OK")
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
	var before_path := REPORT_DIR + "/round3_before_" + filename
	if not FileAccess.file_exists(before_path):
		save_image(load_image(HAZARD_DIR + "/" + filename), before_path)


func copy_row(source: Image, source_y: int, target: Image, target_y: int) -> void:
	for x in target.get_width():
		target.set_pixel(x, target_y, source.get_pixel(x, source_y))


func repair_sheet(filename: String) -> void:
	# Always rebuild from the preserved round-2 result. This makes reruns idempotent.
	var source := load_image(REPORT_DIR + "/round3_before_" + filename)
	var result := Image.create_empty(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	for frame in FRAME_COUNT:
		var cell := source.get_region(Rect2i(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y))
		# Round 2 incorrectly copied frame 1's four-row band into every frame.
		# Bridge the last accepted interior row (123) to the first one (4) through
		# a shared seam row. Only the eight bad edge rows are changed; row 127 and
		# row 0 become identical, while both sides retain this frame's width/centre.
		bridge_wrap(cell)
		result.blit_rect(cell, Rect2i(Vector2i.ZERO, FRAME_SIZE), Vector2i(frame * FRAME_SIZE.x, 0))
	save_image(result, HAZARD_DIR + "/" + filename)


func bridge_wrap(cell: Image) -> void:
	for x in cell.get_width():
		var bottom := cell.get_pixel(x, 123)
		var top := cell.get_pixel(x, 4)
		var middle := bottom.lerp(top, 0.5)
		for step in EDGE_ROWS:
			var toward_middle := float(step + 1) / float(EDGE_ROWS)
			cell.set_pixel(x, 124 + step, bottom.lerp(middle, toward_middle))
			cell.set_pixel(x, 3 - step, top.lerp(middle, toward_middle))


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


func build_preview() -> void:
	# Six columns per effect. Every column repeats one frame three times at 2x.
	var board := checkerboard(Vector2i(1248, 1600), 16)
	var files := ["light_beam_mid.png", "fire_pillar_mid.png"]
	for effect in 2:
		var sheet := load_image(HAZARD_DIR + "/" + files[effect])
		var section_y := 16 + effect * 800
		for frame in FRAME_COUNT:
			var cell := sheet.get_region(Rect2i(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y))
			var x := 16 + frame * 208
			for repeat in 3:
				paste_scaled(board, cell, Vector2i(x, section_y + repeat * 256), 2)
			# Frame number: one-pixel ticks outside the art, enlarged to 2x.
			for tick in frame + 1:
				board.fill_rect(Rect2i(x + tick * 6, section_y - 10, 4, 4), Color("f2dfa3"))
	save_image(board, REPORT_DIR + "/round3_self_tiles_2x.png")
	build_joint_comparison()


func build_joint_comparison() -> void:
	# Four rows: before/after light, then before/after fire. Each sample is the
	# last 12 rows followed by the first 12 rows, enlarged 4x.
	var board := checkerboard(Vector2i(2400, 448), 16)
	var files := ["light_beam_mid.png", "fire_pillar_mid.png"]
	for effect in 2:
		var before := load_image(REPORT_DIR + "/round3_before_" + files[effect])
		var after := load_image(HAZARD_DIR + "/" + files[effect])
		for version in 2:
			var sheet := before if version == 0 else after
			var y := 8 + (effect * 2 + version) * 112
			for frame in FRAME_COUNT:
				var cell := sheet.get_region(Rect2i(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y))
				var joint := Image.create_empty(96, 24, false, Image.FORMAT_RGBA8)
				joint.blit_rect(cell, Rect2i(0, 116, 96, 12), Vector2i.ZERO)
				joint.blit_rect(cell, Rect2i(0, 0, 96, 12), Vector2i(0, 12))
				paste_scaled(board, joint, Vector2i(8 + frame * 400, y), 4)
	save_image(board, REPORT_DIR + "/round3_joints_before_after_4x.png")


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


func body_max_width(cell: Image) -> int:
	var maximum := 0
	for y in range(20, 108):
		maximum = maxi(maximum, row_span(cell, y))
	return maximum


func row_center_x2(cell: Image, y: int) -> int:
	var bounds := row_bounds(cell, y)
	return bounds.x + bounds.y


func body_center_x2(cell: Image) -> int:
	var centres: Array[int] = []
	for y in range(20, 108):
		centres.append(row_center_x2(cell, y))
	centres.sort()
	return centres[centres.size() / 2]


func edge_widths(cell: Image) -> String:
	var values: Array[String] = []
	for y in EDGE_ROWS:
		values.append(str(row_span(cell, y)))
	for y in range(124, 128):
		values.append(str(row_span(cell, y)))
	return "/".join(values)


func color_difference(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a)


func wrap_difference(cell: Image) -> float:
	var difference := 0.0
	for x in cell.get_width():
		difference += color_difference(cell.get_pixel(x, 127), cell.get_pixel(x, 0))
	return difference


func changed_pixels(before: Image, after: Image, y_values: Array[int]) -> int:
	var changed := 0
	for y in y_values:
		for x in before.get_width():
			if before.get_pixel(x, y) != after.get_pixel(x, y):
				changed += 1
	return changed


func frame_metrics(cell: Image) -> String:
	var empty_rows := 0
	var thin_rows := 0
	var maximum_span := 0
	var body := body_width(cell)
	var edge_deviation := 0
	var centre_deviation_x2 := 0
	var body_centre := body_center_x2(cell)
	for y in cell.get_height():
		var filled := row_fill(cell, y)
		if filled == 0:
			empty_rows += 1
		if filled < 32:
			thin_rows += 1
		maximum_span = maxi(maximum_span, row_span(cell, y))
	for y in EDGE_ROWS:
		edge_deviation = maxi(edge_deviation, absi(row_span(cell, y) - body))
		edge_deviation = maxi(edge_deviation, absi(row_span(cell, 124 + y) - body))
		centre_deviation_x2 = maxi(centre_deviation_x2, absi(row_center_x2(cell, y) - body_centre))
		centre_deviation_x2 = maxi(centre_deviation_x2, absi(row_center_x2(cell, 124 + y) - body_centre))
	return "body=%d edge=%s edge_max_delta=%d edge_center_max_delta=%.1f max_span=%d empty=%d under_1_3=%d wrap_diff=%.3f" % [body, edge_widths(cell), edge_deviation, centre_deviation_x2 / 2.0, maximum_span, empty_rows, thin_rows, wrap_difference(cell)]


func validate_sheet(filename: String) -> void:
	var sheet := load_image(HAZARD_DIR + "/" + filename)
	if sheet.get_size() != Vector2i(576, 128):
		push_error("%s wrong size: %s" % [filename, sheet.get_size()])
		quit(1)
		return
	for frame in FRAME_COUNT:
		var cell := sheet.get_region(Rect2i(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y))
		var body := body_width(cell)
		var body_max := body_max_width(cell)
		var body_centre := body_center_x2(cell)
		for y in cell.get_height():
			if row_fill(cell, y) < 32:
				push_error("%s f%d row%d is empty/thin" % [filename, frame + 1, y])
				quit(1)
				return
		for y in [0, 1, 2, 3, 124, 125, 126, 127]:
			if absi(row_span(cell, y) - body) > 2:
				push_error("%s f%d row%d width differs from body by >2" % [filename, frame + 1, y])
				quit(1)
				return
			if row_span(cell, y) > body_max:
				push_error("%s f%d row%d is wider than the body" % [filename, frame + 1, y])
				quit(1)
				return
			if absi(row_center_x2(cell, y) - body_centre) > 4:
				push_error("%s f%d row%d centre differs from body by >2px" % [filename, frame + 1, y])
				quit(1)
				return
		if wrap_difference(cell) > 0.1:
			push_error("%s f%d wrap difference is too high" % [filename, frame + 1])
			quit(1)
			return


func write_verification() -> void:
	var lines: Array[String] = []
	lines.append("Round 3 column self-tiling verification")
	lines.append("alpha_threshold=%.2f body_width=median(row spans 20..107) edge_rows=0..3,124..127" % ALPHA_THRESHOLD)
	for filename in ["light_beam_mid.png", "fire_pillar_mid.png"]:
		var before := load_image(REPORT_DIR + "/round3_before_" + filename)
		var image := load_image(HAZARD_DIR + "/" + filename)
		lines.append("%s size=%s expected=(576, 128) ok=%s" % [filename, image.get_size(), image.get_size() == Vector2i(576, 128)])
		for frame in FRAME_COUNT:
			var before_cell := before.get_region(Rect2i(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y))
			var cell := image.get_region(Rect2i(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y))
			var interior_rows: Array[int] = []
			interior_rows.assign(range(4, 124))
			var edge_rows: Array[int] = [0, 1, 2, 3, 124, 125, 126, 127]
			lines.append("  f%d %s changed_interior=%d changed_edge=%d" % [frame + 1, frame_metrics(cell), changed_pixels(before_cell, cell, interior_rows), changed_pixels(before_cell, cell, edge_rows)])
	lines.append("anchors_unchanged=top-left per 96x128 cell; light 10 fps loop; fire 12 fps loop")
	lines.append("preview=round3_self_tiles_2x.png; each frame repeated 3x under itself at nearest-neighbor 2x")
	lines.append("joint_comparison=round3_joints_before_after_4x.png; rows are before/after light, before/after fire")
	var file := FileAccess.open(REPORT_DIR + "/round3-verification.txt", FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
