extends SceneTree

## Reduces the retained ImageGen redraw to the 128 px atlas contract using only Godot Image API.

const CELL := 128
const TARGET_HEIGHT := 91

func _initialize() -> void:
	var report := ProjectSettings.globalize_path("res://../reports/codex-art-21")
	_prepare(report, "frey_attack4", 91)
	_prepare(report, "luna_idle2", 81)
	_prepare(report, "luna_idle3", 83)
	quit(0)

func _prepare(report: String, stem: String, target_height: int) -> void:
	var source_path := report.path_join("generated_sources/%s_imagegen.png" % stem)
	var source := Image.load_from_file(source_path)
	source.convert(Image.FORMAT_RGBA8)
	var bounds := _alpha_bounds(source)
	var cropped := source.get_region(bounds)
	var width := int(round(float(cropped.get_width()) * target_height / cropped.get_height()))
	cropped.resize(width, target_height, Image.INTERPOLATE_NEAREST)
	_hard_alpha(cropped)
	var frame := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	frame.fill(Color.TRANSPARENT)
	var x := (CELL - width) / 2
	var y := 120 - target_height + 1
	frame.blit_rect(cropped, Rect2i(0, 0, width, target_height), Vector2i(x, y))
	frame.save_png(report.path_join("generated_sources/%s_candidate_128.png" % stem))
	var board := Image.create(CELL * 4, CELL * 4, false, Image.FORMAT_RGBA8)
	board.fill(Color("#3c414a"))
	var large := frame.duplicate()
	large.resize(CELL * 4, CELL * 4, Image.INTERPOLATE_NEAREST)
	board.blend_rect(large, Rect2i(0, 0, CELL * 4, CELL * 4), Vector2i.ZERO)
	board.save_png(report.path_join("generated_sources/%s_candidate_4x.png" % stem))
	print("ART21_CANDIDATE %s source=%s bounds=%s target=%dx%d at=(%d,%d)" % [stem, source.get_size(), bounds, width, target_height, x, y])

func _alpha_bounds(image: Image) -> Rect2i:
	var left := image.get_width()
	var top := image.get_height()
	var right := -1
	var bottom := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.1:
				left = mini(left, x)
				top = mini(top, y)
				right = maxi(right, x)
				bottom = maxi(bottom, y)
	return Rect2i(left, top, right - left + 1, bottom - top + 1)

func _hard_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				image.set_pixel(x, y, Color.TRANSPARENT)
			else:
				color.a = 1.0
				image.set_pixel(x, y, color)
