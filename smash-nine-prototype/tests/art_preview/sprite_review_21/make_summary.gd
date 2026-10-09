extends SceneTree

## Produces compact visual handoff boards from the verified before/after artifacts.

func _initialize() -> void:
	var report := ProjectSettings.globalize_path("res://../reports/codex-art-21")
	_make_all_contacts(report)
	_make_key_fixes(report)
	print("ART21_SUMMARY boards=2")
	quit(0)

func _make_all_contacts(report: String) -> void:
	var names := ["frey", "luna", "luna_brave"]
	var gap := 24
	var cell := Vector2i(768, 896)
	var board := Image.create(cell.x * 2 + gap, cell.y * 3 + gap * 2, false, Image.FORMAT_RGBA8)
	board.fill(Color("#20242b"))
	for row in names.size():
		var before := Image.load_from_file(report.path_join("contact/%s_before_1x.png" % names[row]))
		var after := Image.load_from_file(report.path_join("contact/%s_after_1x.png" % names[row]))
		board.blit_rect(before, Rect2i(Vector2i.ZERO, cell), Vector2i(0, row * (cell.y + gap)))
		board.blit_rect(after, Rect2i(Vector2i.ZERO, cell), Vector2i(cell.x + gap, row * (cell.y + gap)))
	board.save_png(report.path_join("contact/all_before_after_1x.png"))

func _make_key_fixes(report: String) -> void:
	var keys := [
		["frey_r4c3_attack.png", "frey_r4c3.png"],
		["luna_r0c1_idle.png", "luna_r0c1.png"],
		["luna_r0c2_idle.png", "luna_r0c2.png"],
	]
	var side := 512
	var gap := 16
	var board := Image.create(side * 2 + gap, side * 3 + gap * 2, false, Image.FORMAT_RGBA8)
	board.fill(Color("#20242b"))
	for row in keys.size():
		var before := Image.load_from_file(report.path_join("inspection/frames_4x/%s" % keys[row][0]))
		var after := Image.load_from_file(report.path_join("inspection/after_frames_4x/%s" % keys[row][1]))
		var y := row * (side + gap)
		board.blit_rect(before, Rect2i(0, 0, side, side), Vector2i(0, y))
		board.blit_rect(after, Rect2i(0, 0, side, side), Vector2i(side + gap, y))
		_box(board, 0, y, side, Color("#ff3d52"), 4)
		_box(board, side + gap, y, side, Color("#44df78"), 4)
	board.save_png(report.path_join("contact/key_fixes_before_after_4x.png"))

func _box(image: Image, x: int, y: int, size: int, color: Color, thickness: int) -> void:
	image.fill_rect(Rect2i(x, y, size, thickness), color)
	image.fill_rect(Rect2i(x, y + size - thickness, size, thickness), color)
	image.fill_rect(Rect2i(x, y, thickness, size), color)
	image.fill_rect(Rect2i(x + size - thickness, y, thickness, size), color)
