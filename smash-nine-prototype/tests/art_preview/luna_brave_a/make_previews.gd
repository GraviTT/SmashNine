extends SceneTree

const NORMAL_PATH := "res://assets/art/luna/luna_sheet.png"
const BRAVE_PATH := "res://assets/art/luna/luna_brave_sheet.png"
const LOGO_PATH := "res://assets/art/ui/title_logo.png"
const REPORT_DIR := "res://../reports/codex-art-06"
const DARK := Color("071622")
const PANEL := Color("102638")
const GRID := Color("2b5970")

func _init() -> void:
	if not _make_luna_contact():
		quit(1)
		return
	if not _make_logo_preview():
		quit(1)
		return
	print("[art-06-preview] PASS luna_contact=2x logo=100%+50%")
	quit()

func _make_luna_contact() -> bool:
	var normal := Image.load_from_file(NORMAL_PATH)
	var brave := Image.load_from_file(BRAVE_PATH)
	if normal.is_empty() or brave.is_empty():
		push_error("Could not load Luna sheets")
		return false
	normal.resize(normal.get_width() * 2, normal.get_height() * 2, Image.INTERPOLATE_NEAREST)
	brave.resize(brave.get_width() * 2, brave.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var margin := 32
	var gap := 32
	var output := Image.create(margin * 2 + normal.get_width() + gap + brave.get_width(), margin * 2 + normal.get_height(), false, Image.FORMAT_RGBA8)
	output.fill(DARK)
	_draw_grid(output, Rect2i(margin, margin, normal.get_width(), normal.get_height()), 128)
	_draw_grid(output, Rect2i(margin + normal.get_width() + gap, margin, brave.get_width(), brave.get_height()), 128)
	output.blend_rect(normal, Rect2i(Vector2i.ZERO, normal.get_size()), Vector2i(margin, margin))
	output.blend_rect(brave, Rect2i(Vector2i.ZERO, brave.get_size()), Vector2i(margin + normal.get_width() + gap, margin))
	var path := "%s/luna_normal_vs_brave_2x.png" % REPORT_DIR
	if output.save_png(path) != OK:
		push_error("Could not save %s" % path)
		return false
	return true

func _make_logo_preview() -> bool:
	var logo := Image.load_from_file(LOGO_PATH)
	if logo.is_empty():
		push_error("Could not load title logo")
		return false
	var half := logo.duplicate()
	half.resize(logo.get_width() / 2, logo.get_height() / 2, Image.INTERPOLATE_NEAREST)
	var output := Image.create(800, 420, false, Image.FORMAT_RGBA8)
	output.fill(DARK)
	output.fill_rect(Rect2i(48, 36, 704, 232), PANEL)
	output.fill_rect(Rect2i(224, 292, 352, 116), PANEL)
	output.blend_rect(logo, Rect2i(Vector2i.ZERO, logo.get_size()), Vector2i(80, 52))
	output.blend_rect(half, Rect2i(Vector2i.ZERO, half.get_size()), Vector2i(240, 300))
	var path := "%s/title_logo_100_50.png" % REPORT_DIR
	if output.save_png(path) != OK:
		push_error("Could not save %s" % path)
		return false
	return true

func _draw_grid(image: Image, rect: Rect2i, step: int) -> void:
	for x in range(rect.position.x, rect.end.x + 1, step):
		image.fill_rect(Rect2i(x, rect.position.y, 1, rect.size.y), GRID)
	for y in range(rect.position.y, rect.end.y + 1, step):
		image.fill_rect(Rect2i(rect.position.x, y, rect.size.x, 1), GRID)
