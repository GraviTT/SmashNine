extends SceneTree
## Run: --headless --script tests/art_preview/flash_art_20/make_after_contact.gd -- <reports/codex-art-20/after> <out.png> (after capture_after.gd run with --fixed-fps 60).
## Lead's contact sheet of after-capture frames: rows = scenarios, columns = frames, centre crops.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var base: String = args[0]
	var out: String = args[1]
	var rows := ["parry", "landing", "streak_heavy", "seal_break", "hit_heavy"]
	var frames := [0, 1, 2, 3, 4]
	var crop := Rect2i(320, 120, 640, 480)
	var cell := Vector2i(320, 240)
	var sheet := Image.create(cell.x * frames.size(), cell.y * rows.size(), false, Image.FORMAT_RGBA8)
	for r in rows.size():
		for c in frames.size():
			var path := "%s/%s/%s_%02d.png" % [base, rows[r], rows[r], frames[c]]
			var image := Image.load_from_file(path)
			if image == null:
				continue
			var part := image.get_region(crop)
			part.resize(cell.x, cell.y, Image.INTERPOLATE_NEAREST)
			sheet.blit_rect(part, Rect2i(Vector2i.ZERO, cell), Vector2i(c * cell.x, r * cell.y))
	sheet.save_png(out)
	print("sheet saved")
	quit(0)
