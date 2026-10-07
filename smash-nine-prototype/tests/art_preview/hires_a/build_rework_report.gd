extends SceneTree

const CELL := 128
const SCALE := 4
const ROW_HEIGHT := 928
const REPORT_DIR := "res://../reports/codex-art-08a"

const ENTRIES := [
	{
		"id": "frey",
		"sheet": "res://assets/art/frey/frey_sheet.png",
		"face": "res://assets/art/frey/frey_face.png",
		"illustration": "res://assets/art/frey/frey_illustration.png",
		"head_top": 30,
		"chin": 63,
		"feet": 120,
		"idle_height": 99,
	},
	{
		"id": "nova_male",
		"sheet": "res://assets/art/nova/nova_male_sheet.png",
		"face": "res://assets/art/nova/nova_male_face.png",
		"illustration": "res://assets/art/nova/nova_male_illustration.png",
		"head_top": 29,
		"chin": 65,
		"feet": 120,
		"idle_height": 91,
	},
	{
		"id": "nova_female",
		"sheet": "res://assets/art/nova/nova_female_sheet.png",
		"face": "res://assets/art/nova/nova_female_face.png",
		"illustration": "res://assets/art/nova/nova_female_illustration.png",
		"head_top": 31,
		"chin": 67,
		"feet": 120,
		"idle_height": 89,
	},
	{
		"id": "yuki",
		"sheet": "res://assets/art/yuki/yuki_sheet.png",
		"face": "res://assets/art/yuki/yuki_face.png",
		"illustration": "res://assets/art/yuki/yuki_illustration.png",
		"head_top": 34,
		"chin": 69,
		"feet": 120,
		"idle_height": 87,
	},
]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	_build_idle_guides()
	_build_contact_sheet()
	quit()

func _build_idle_guides() -> void:
	for entry: Dictionary in ENTRIES:
		var sheet := Image.load_from_file(entry.sheet)
		var idle := sheet.get_region(Rect2i(0, 0, CELL, CELL))
		idle.resize(CELL * SCALE, CELL * SCALE, Image.INTERPOLATE_NEAREST)
		var board := Image.create_empty(CELL * SCALE, CELL * SCALE, false, Image.FORMAT_RGBA8)
		board.fill(Color("101827"))
		board.blend_rect(idle, Rect2i(Vector2i.ZERO, idle.get_size()), Vector2i.ZERO)
		_draw_guide(board, int(entry.head_top) * SCALE, Color("ff4d6d"))
		_draw_guide(board, int(entry.chin) * SCALE, Color("4dd7ff"))
		_draw_guide(board, int(entry.feet) * SCALE, Color("62e675"))
		var ratio: float = float(entry.idle_height) / float(int(entry.chin) - int(entry.head_top))
		var path := "%s/%s_idle_4x_guides_ratio_%.2f.png" % [REPORT_DIR, entry.id, ratio]
		_assert_ok(board.save_png(path), path)

func _draw_guide(image: Image, y: int, color: Color) -> void:
	for thickness: int in range(3):
		for x: int in range(image.get_width()):
			image.set_pixel(x, mini(y + thickness, image.get_height() - 1), color)

func _build_contact_sheet() -> void:
	var before := Image.load_from_file(REPORT_DIR + "/contact_sheet_before_rework.png")
	var width := 2144
	var board := Image.create_empty(width, ROW_HEIGHT * ENTRIES.size(), false, Image.FORMAT_RGBA8)
	board.fill(Color("101827"))
	for i: int in range(ENTRIES.size()):
		var entry: Dictionary = ENTRIES[i]
		# The preserved first-pass contact contains the original 64 px v1 sheet
		# already enlarged 2x in its left column.
		var old_v1 := before.get_region(Rect2i(16, i * ROW_HEIGHT + 16, 768, 896))
		board.blend_rect(old_v1, Rect2i(Vector2i.ZERO, old_v1.get_size()), Vector2i(16, i * ROW_HEIGHT + 16))
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
