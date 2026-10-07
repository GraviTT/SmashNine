extends SceneTree

const CELL := Vector2i(128, 128)
const SHEET_SIZE := Vector2i(768, 896)
const FEET_Y := 120
const CENTER_X := 64
const ROW_NAMES := ["idle", "walk", "jump", "fall", "attack", "shield", "hurt"]
const ROW_COUNTS := [4, 6, 1, 1, 4, 6, 1]
const ROOT := "res://"

const SHEETS := [
	{
		"id": "rio_male",
		"source": "res://assets/art/rio/rio_male_v2_source.png",
		"output": "res://assets/art/rio/rio_male_sheet.png",
		"old": "res://tests/art_preview/hires_b/rio_male_v1.png",
		"illustration": "res://assets/art/rio/rio_male_illustration.png",
		"face": "res://assets/art/rio/rio_male_face.png",
		"body_height": 98,
		"alpha_height": 104
	},
	{
		"id": "rio_female",
		"source": "res://assets/art/rio/rio_female_v2_source.png",
		"output": "res://assets/art/rio/rio_female_sheet.png",
		"old": "res://tests/art_preview/hires_b/rio_female_v1.png",
		"illustration": "res://assets/art/rio/rio_female_illustration.png",
		"face": "res://assets/art/rio/rio_female_face.png",
		"body_height": 96,
		"alpha_height": 102
	},
	{
		"id": "luna",
		"source": "res://assets/art/luna/luna_v2_source.png",
		"output": "res://assets/art/luna/luna_sheet.png",
		"old": "res://tests/art_preview/hires_b/luna_v1.png",
		"illustration": "res://assets/art/luna/luna_illustration.png",
		"face": "res://assets/art/luna/luna_face.png",
		"body_height": 84,
		"alpha_height": 94
	},
	{
		"id": "luna_brave",
		"source": "res://assets/art/luna/luna_brave_v2_source.png",
		"output": "res://assets/art/luna/luna_brave_sheet.png",
		"old": "res://tests/art_preview/hires_b/luna_brave_v1.png",
		"illustration": "res://assets/art/luna/luna_illustration.png",
		"face": "res://assets/art/luna/luna_face.png",
		"body_height": 84,
		"alpha_height": 94
	}
]

const ILLUSTRATIONS := [
	{
		"source": "res://assets/art/rio/rio_male_illustration_source.png",
		"output": "res://assets/art/rio/rio_male_illustration.png",
		"face": "res://assets/art/rio/rio_male_face.png",
		"face_center": Vector2(0.515, 0.145),
		"face_span": 0.31
	},
	{
		"source": "res://assets/art/rio/rio_female_illustration_source.png",
		"output": "res://assets/art/rio/rio_female_illustration.png",
		"face": "res://assets/art/rio/rio_female_face.png",
		"face_center": Vector2(0.525, 0.145),
		"face_span": 0.31
	},
	{
		"source": "res://assets/art/luna/luna_illustration_source.png",
		"output": "res://assets/art/luna/luna_illustration.png",
		"face": "res://assets/art/luna/luna_face.png",
		"face_center": Vector2(0.555, 0.155),
		"face_span": 0.32
	}
]

var alignment_lines: PackedStringArray = PackedStringArray([
	"sheet,animation,row,column,bounds_x,bounds_y,bounds_w,bounds_h,feet_y,opaque_centroid_x,opaque_pixels,target_body_height_px"
])

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for spec in ILLUSTRATIONS:
		_build_illustration(spec)
	for spec in SHEETS:
		_build_sheet(spec)
	_write_alignment()
	_build_contact_sheet()
	print("HIRES_B_BUILD_OK")
	quit()

func _load_image(path: String) -> Image:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_error("Could not load image: %s" % path)
		quit(1)
	return image

func _build_illustration(spec: Dictionary) -> void:
	var source := _load_image(spec.source)
	var used := _alpha_rect(source, Rect2i(Vector2i.ZERO, source.get_size()))
	var crop := source.get_region(used)
	var max_size := Vector2i(960, 1450)
	var scale := minf(float(max_size.x) / crop.get_width(), float(max_size.y) / crop.get_height())
	var resized_size := Vector2i(maxi(1, roundi(crop.get_width() * scale)), maxi(1, roundi(crop.get_height() * scale)))
	crop.resize(resized_size.x, resized_size.y, Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create_empty(1024, 1536, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	var destination := Vector2i((1024 - resized_size.x) / 2, (1536 - resized_size.y) / 2)
	canvas.blend_rect(crop, Rect2i(Vector2i.ZERO, resized_size), destination)
	canvas.save_png(spec.output)

	var face_center: Vector2 = spec.face_center
	var face_span: float = spec.face_span
	var span := roundi(mini(source.get_width(), source.get_height()) * face_span)
	var center := Vector2i(roundi(source.get_width() * face_center.x), roundi(source.get_height() * face_center.y))
	var face_rect := Rect2i(center - Vector2i(span / 2, span / 2), Vector2i(span, span))
	face_rect.position.x = clampi(face_rect.position.x, 0, source.get_width() - span)
	face_rect.position.y = clampi(face_rect.position.y, 0, source.get_height() - span)
	var face := source.get_region(face_rect)
	face.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	face.save_png(spec.face)

func _build_sheet(spec: Dictionary) -> void:
	var source := _load_image(spec.source)
	var output := Image.create_empty(SHEET_SIZE.x, SHEET_SIZE.y, false, Image.FORMAT_RGBA8)
	output.fill(Color(0, 0, 0, 0))
	var source_cell_w := source.get_width() / 6.0
	var source_cell_h := source.get_height() / 7.0
	var idle_cell := _source_cell_rect(source, 0, 0)
	var idle_used := _alpha_rect(source, idle_cell)
	var target_alpha_height: int = spec.alpha_height
	var common_scale := float(target_alpha_height) / maxf(1.0, idle_used.size.y)

	for row in 7:
		for column in ROW_COUNTS[row]:
			var cell_rect := _source_cell_rect(source, column, row)
			var used := _alpha_rect(source, cell_rect)
			if used.size.x <= 0 or used.size.y <= 0:
				push_error("Missing frame %s row=%d col=%d" % [spec.id, row, column])
				continue
			var frame := source.get_region(used)
			var resized := Vector2i(maxi(1, roundi(frame.get_width() * common_scale)), maxi(1, roundi(frame.get_height() * common_scale)))
			frame.resize(resized.x, resized.y, Image.INTERPOLATE_NEAREST)
			var stats := _alpha_stats(frame, Rect2i(Vector2i.ZERO, frame.get_size()))
			var centroid: Vector2 = stats.centroid
			var local_destination := Vector2i(
				CENTER_X - roundi(centroid.x),
				FEET_Y - (resized.y - 1)
			)
			# Composite through an isolated cell so effects can never leak into an unused cell.
			var cell_canvas := Image.create_empty(CELL.x, CELL.y, false, Image.FORMAT_RGBA8)
			var recenter_x := 0
			for _pass in 3:
				cell_canvas.fill(Color(0, 0, 0, 0))
				cell_canvas.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), local_destination + Vector2i(recenter_x, 0))
				var clipped_stats := _alpha_stats(cell_canvas, Rect2i(Vector2i.ZERO, CELL))
				var clipped_centroid: Vector2 = clipped_stats.centroid
				var correction := roundi(CENTER_X - clipped_centroid.x)
				if correction == 0:
					break
				recenter_x += correction
			output.blit_rect(cell_canvas, Rect2i(Vector2i.ZERO, CELL), Vector2i(column * CELL.x, row * CELL.y))

	var save_error := output.save_png(spec.output)
	if save_error != OK:
		push_error("Could not save sheet: %s" % spec.output)
		quit(1)
	_measure_sheet(spec, output)
	print("sheet %s source=%dx%d scale=%.4f target_body=%d" % [spec.id, source.get_width(), source.get_height(), common_scale, spec.body_height])

func _source_cell_rect(source: Image, column: int, row: int) -> Rect2i:
	var x0 := roundi(float(column) * source.get_width() / 6.0)
	var x1 := roundi(float(column + 1) * source.get_width() / 6.0)
	var y0 := roundi(float(row) * source.get_height() / 7.0)
	var y1 := roundi(float(row + 1) * source.get_height() / 7.0)
	return Rect2i(x0, y0, x1 - x0, y1 - y0)

func _measure_sheet(spec: Dictionary, sheet: Image) -> void:
	for row in 7:
		for column in ROW_COUNTS[row]:
			var cell_rect := Rect2i(column * CELL.x, row * CELL.y, CELL.x, CELL.y)
			var bounds := _alpha_rect(sheet, cell_rect)
			var stats := _alpha_stats(sheet, cell_rect)
			var local_bounds := Rect2i(bounds.position - cell_rect.position, bounds.size)
			alignment_lines.append("%s,%s,%d,%d,%d,%d,%d,%d,%d,%.2f,%d,%d" % [
				spec.id, ROW_NAMES[row], row, column,
				local_bounds.position.x, local_bounds.position.y, local_bounds.size.x, local_bounds.size.y,
				FEET_Y, stats.centroid.x - cell_rect.position.x, stats.pixels, spec.body_height
			])

func _alpha_rect(image: Image, area: Rect2i, threshold: float = 0.04) -> Rect2i:
	var min_x := area.end.x
	var min_y := area.end.y
	var max_x := area.position.x - 1
	var max_y := area.position.y - 1
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if image.get_pixel(x, y).a > threshold:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i(area.position, Vector2i.ZERO)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _alpha_stats(image: Image, area: Rect2i, threshold: float = 0.04) -> Dictionary:
	var weighted := Vector2.ZERO
	var weight := 0.0
	var pixels := 0
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var alpha := image.get_pixel(x, y).a
			if alpha > threshold:
				weighted += Vector2(x, y) * alpha
				weight += alpha
				pixels += 1
	return {
		"centroid": weighted / maxf(weight, 0.0001),
		"pixels": pixels
	}

func _write_alignment() -> void:
	var file := FileAccess.open("res://../reports/codex-art-08b/alignment.csv", FileAccess.WRITE)
	if file == null:
		push_error("Could not open alignment.csv")
		quit(1)
	file.store_string("\n".join(alignment_lines) + "\n")

func _build_contact_sheet() -> void:
	var row_height := 896
	var board := Image.create_empty(2048, row_height * SHEETS.size(), false, Image.FORMAT_RGBA8)
	board.fill(Color("09111f"))
	for index in SHEETS.size():
		var spec: Dictionary = SHEETS[index]
		var y := index * row_height
		board.fill_rect(Rect2i(0, y, 768, row_height), Color("101d31"))
		board.fill_rect(Rect2i(768, y, 768, row_height), Color("0c1728"))
		board.fill_rect(Rect2i(1536, y, 512, row_height), Color("142238"))

		var old := _load_image(spec.old)
		old.resize(768, 896, Image.INTERPOLATE_NEAREST)
		board.blend_rect(old, Rect2i(Vector2i.ZERO, old.get_size()), Vector2i(0, y))
		var current := _load_image(spec.output)
		board.blend_rect(current, Rect2i(Vector2i.ZERO, current.get_size()), Vector2i(768, y))

		if spec.id != "luna_brave":
			var face := _load_image(spec.face)
			board.blend_rect(face, Rect2i(Vector2i.ZERO, face.get_size()), Vector2i(1536, y + 24))
			var illustration := _load_image(spec.illustration)
			illustration.resize(256, 384, Image.INTERPOLATE_LANCZOS)
			board.blend_rect(illustration, Rect2i(Vector2i.ZERO, illustration.get_size()), Vector2i(1792, y + 24))

	board.save_png("res://../reports/codex-art-08b/contact_sheet.png")
