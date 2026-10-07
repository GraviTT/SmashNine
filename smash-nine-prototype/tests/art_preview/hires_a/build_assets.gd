extends SceneTree

const CELL := 128
const COLS := 6
const ROWS := 7
const FEET_Y := 120
const COUNTS := [4, 6, 1, 1, 4, 6, 1]
const REPORT_DIR := "res://../reports/codex-art-08a"

const CHARACTERS := [
	{
		"id": "frey",
		"illustration_source": "res://assets/art/frey/frey_illustration_source.png",
		"illustration": "res://assets/art/frey/frey_illustration.png",
		"face": "res://assets/art/frey/frey_face.png",
		"sheet_source": "res://assets/art/frey/frey_v2_source.png",
		"sheet": "res://assets/art/frey/frey_sheet.png",
		"face_rect": Rect2i(400, 0, 420, 420),
		"body_height": 100,
		"full_height": 112,
	},
	{
		"id": "nova_male",
		"illustration_source": "res://assets/art/nova/nova_male_illustration_source.png",
		"illustration": "res://assets/art/nova/nova_male_illustration.png",
		"face": "res://assets/art/nova/nova_male_face.png",
		"sheet_source": "res://assets/art/nova/nova_male_v2_source.png",
		"sheet": "res://assets/art/nova/nova_male_sheet.png",
		"face_rect": Rect2i(360, 0, 420, 420),
		"body_height": 92,
		"full_height": 98,
	},
	{
		"id": "nova_female",
		"illustration_source": "res://assets/art/nova/nova_female_illustration_source.png",
		"illustration": "res://assets/art/nova/nova_female_illustration.png",
		"face": "res://assets/art/nova/nova_female_face.png",
		"sheet_source": "res://assets/art/nova/nova_female_v2_source.png",
		"sheet": "res://assets/art/nova/nova_female_sheet.png",
		"face_rect": Rect2i(300, 0, 420, 420),
		"body_height": 90,
		"full_height": 96,
	},
	{
		"id": "yuki",
		"illustration_source": "res://assets/art/yuki/yuki_illustration_source.png",
		"illustration": "res://assets/art/yuki/yuki_illustration.png",
		"face": "res://assets/art/yuki/yuki_face.png",
		"sheet_source": "res://assets/art/yuki/yuki_v2_source.png",
		"sheet": "res://assets/art/yuki/yuki_sheet.png",
		"face_rect": Rect2i(330, 20, 460, 460),
		"body_height": 88,
		"full_height": 100,
	},
]

var _alignment_lines: PackedStringArray = PackedStringArray([
	"sheet,row,column,frame,feet_y,centroid_x,opaque_top,opaque_bottom,opaque_height,configured_body_height"
])

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	var old_sheets: Array[Image] = []
	for entry: Dictionary in CHARACTERS:
		old_sheets.append(Image.load_from_file(entry.sheet))
		_build_character(entry)
	_write_alignment()
	if not OS.get_cmdline_user_args().has("--no-contact"):
		_build_contact_sheet(old_sheets)
	print("[hires_a] built %d character variants" % CHARACTERS.size())
	quit()

func _build_character(entry: Dictionary) -> void:
	var illustration := Image.load_from_file(entry.illustration_source)
	if illustration.get_width() != 1024 or illustration.get_height() != 1536:
		illustration.resize(1024, 1536, Image.INTERPOLATE_LANCZOS)
	_cleanup_soft_alpha(illustration)
	_assert_ok(illustration.save_png(entry.illustration), entry.illustration)

	var face := illustration.get_region(entry.face_rect)
	face.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	_cleanup_soft_alpha(face)
	_assert_ok(face.save_png(entry.face), entry.face)

	var source := Image.load_from_file(entry.sheet_source)
	var source_cell := _source_cell(source, 0, 0)
	var reference_bounds := _alpha_bounds(source_cell)
	var scale: float = float(entry.full_height) / float(reference_bounds.size.y)
	var output := Image.create_empty(COLS * CELL, ROWS * CELL, false, Image.FORMAT_RGBA8)
	output.fill(Color(0, 0, 0, 0))

	var frame_index := 0
	for row: int in range(ROWS):
		for column: int in range(COUNTS[row]):
			var frame := _source_cell(source, column, row)
			frame.resize(maxi(1, roundi(frame.get_width() * scale)), maxi(1, roundi(frame.get_height() * scale)), Image.INTERPOLATE_NEAREST)
			_pixel_cleanup(frame)
			var bounds := _alpha_bounds(frame)
			if bounds.size == Vector2i.ZERO:
				push_error("Empty generated frame: %s row=%d column=%d" % [entry.id, row, column])
				continue
			var centroid_x := _alpha_centroid_x(frame, bounds)
			var frame_feet := bounds.end.y - 1
			var paste := Vector2i(
				roundi(CELL / 2.0 - centroid_x),
				FEET_Y - frame_feet
			)
			var cell_output := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
			cell_output.fill(Color(0, 0, 0, 0))
			cell_output.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), paste)
			cell_output = _recenter_image(cell_output)
			output.blend_rect(cell_output, Rect2i(Vector2i.ZERO, cell_output.get_size()), Vector2i(column * CELL, row * CELL))
			var final_bounds := _cell_alpha_bounds(output, column, row)
			var final_centroid := _cell_alpha_centroid_x(output, column, row, final_bounds)
			_alignment_lines.append("%s,%d,%d,%d,%d,%.2f,%d,%d,%d,%d" % [
				entry.id, row, column, frame_index, final_bounds.end.y - 1,
				final_centroid, final_bounds.position.y, final_bounds.end.y - 1,
				final_bounds.size.y, entry.body_height
			])
			frame_index += 1
	_assert_ok(output.save_png(entry.sheet), entry.sheet)
	print("[hires_a] %s scale=%.4f source_ref=%s" % [entry.id, scale, reference_bounds])

func _source_cell(source: Image, column: int, row: int) -> Image:
	var x0 := roundi(float(column) * source.get_width() / COLS)
	var x1 := roundi(float(column + 1) * source.get_width() / COLS)
	var y0 := roundi(float(row) * source.get_height() / ROWS)
	var y1 := roundi(float(row + 1) * source.get_height() / ROWS)
	return source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))

func _cleanup_soft_alpha(image: Image) -> void:
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a < 0.015:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _pixel_cleanup(image: Image) -> void:
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a < 0.22:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				image.set_pixel(x, y, Color(
					round(color.r * 31.0) / 31.0,
					round(color.g * 31.0) / 31.0,
					round(color.b * 31.0) / 31.0,
					1.0
				))

func _alpha_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a >= 0.22:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _alpha_centroid_x(image: Image, bounds: Rect2i) -> float:
	var weighted_x := 0.0
	var weight := 0.0
	for y: int in range(bounds.position.y, bounds.end.y):
		for x: int in range(bounds.position.x, bounds.end.x):
			var alpha := image.get_pixel(x, y).a
			if alpha >= 0.22:
				weighted_x += x * alpha
				weight += alpha
	return weighted_x / maxf(weight, 1.0)

func _cell_alpha_bounds(sheet: Image, column: int, row: int) -> Rect2i:
	var cell_image := sheet.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
	return _alpha_bounds(cell_image)

func _cell_alpha_centroid_x(sheet: Image, column: int, row: int, bounds: Rect2i) -> float:
	var cell_image := sheet.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
	return _alpha_centroid_x(cell_image, bounds)

func _recenter_image(cell_image: Image) -> Image:
	for iteration: int in range(3):
		var bounds := _alpha_bounds(cell_image)
		if bounds.size == Vector2i.ZERO:
			return cell_image
		var centroid := _alpha_centroid_x(cell_image, bounds)
		var delta_x := roundi(CELL / 2.0 - centroid)
		if delta_x == 0:
			break
		var shifted := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
		shifted.fill(Color(0, 0, 0, 0))
		shifted.blend_rect(cell_image, Rect2i(Vector2i.ZERO, cell_image.get_size()), Vector2i(delta_x, 0))
		cell_image = shifted
	return cell_image

func _write_alignment() -> void:
	var path := REPORT_DIR + "/alignment.csv"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s" % path)
		return
	file.store_string("\n".join(_alignment_lines) + "\n")
	file.close()

func _build_contact_sheet(old_sheets: Array[Image]) -> void:
	const ROW_HEIGHT := 928
	const WIDTH := 2144
	var board := Image.create_empty(WIDTH, ROW_HEIGHT * CHARACTERS.size(), false, Image.FORMAT_RGBA8)
	board.fill(Color("101827"))
	for i: int in range(CHARACTERS.size()):
		var entry: Dictionary = CHARACTERS[i]
		var old: Image = old_sheets[i].duplicate()
		old.resize(768, 896, Image.INTERPOLATE_NEAREST)
		board.blend_rect(old, Rect2i(Vector2i.ZERO, old.get_size()), Vector2i(16, i * ROW_HEIGHT + 16))
		var current := Image.load_from_file(entry.sheet)
		board.blend_rect(current, Rect2i(Vector2i.ZERO, current.get_size()), Vector2i(800, i * ROW_HEIGHT + 16))
		var face := Image.load_from_file(entry.face)
		board.blend_rect(face, Rect2i(Vector2i.ZERO, face.get_size()), Vector2i(1584, i * ROW_HEIGHT + 80))
		var illustration := Image.load_from_file(entry.illustration)
		illustration.resize(256, 384, Image.INTERPOLATE_LANCZOS)
		board.blend_rect(illustration, Rect2i(Vector2i.ZERO, illustration.get_size()), Vector2i(1864, i * ROW_HEIGHT + 16))
	_assert_ok(board.save_png(REPORT_DIR + "/contact_sheet.png"), REPORT_DIR + "/contact_sheet.png")

func _assert_ok(error: Error, path: String) -> void:
	if error != OK:
		push_error("Failed to save %s: %s" % [path, error_string(error)])
