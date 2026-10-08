extends SceneTree

const FRAME_COUNT := 6
const OUTPUT_DIR := "res://assets/art/attack_vfx"
const OLD_SOURCE_DIR := "res://../reports/codex-art-16/source"
const NEW_SOURCE_DIR := "res://../reports/codex-art-16/source"
const REPORT_DIR := "res://../reports/codex-art-16"
const MARGIN := 8

const SPECS := {
	"frey_slash": {"size": Vector2i(384, 256), "align": "left_middle", "palette": "frey", "source": NEW_SOURCE_DIR},
	"yuki_slash": {"size": Vector2i(384, 256), "align": "left_middle", "palette": "yuki"},
	"luna_slash": {"size": Vector2i(384, 256), "align": "left_middle", "palette": "luna", "source": NEW_SOURCE_DIR},
	"luna_brave_slash": {"size": Vector2i(448, 256), "align": "left_middle", "palette": "brave", "source": NEW_SOURCE_DIR, "cuts": [0, 240, 525, 920, 1410, 1750, 2048]},
	"nova_slash": {"size": Vector2i(320, 256), "align": "left_middle", "palette": "nova"},
	"rio_slash": {"size": Vector2i(384, 256), "align": "left_middle", "palette": "rio"},
	"frey_k": {"size": Vector2i(448, 192), "align": "left_middle", "palette": "frey"},
	"yuki_k": {"size": Vector2i(256, 256), "align": "center", "palette": "yuki"},
	"luna_k": {"size": Vector2i(320, 192), "align": "left_middle", "palette": "luna"},
	"nova_k": {"size": Vector2i(448, 192), "align": "left_middle", "palette": "nova"},
	"rio_k": {"size": Vector2i(512, 192), "align": "left_middle", "palette": "rio", "dark_cut": 0.34},
	"frey_l": {"size": Vector2i(256, 384), "align": "bottom_center", "palette": "frey"},
	"yuki_l": {"size": Vector2i(384, 384), "align": "center", "palette": "yuki"},
	"luna_l": {"size": Vector2i(384, 384), "align": "center", "palette": "luna"},
	"nova_l": {"size": Vector2i(384, 384), "align": "bottom_center", "palette": "nova"},
	"rio_l": {"size": Vector2i(256, 320), "align": "left_middle", "palette": "rio"},
}

const PALETTES := {
	"frey": [Color("713619"), Color("b66520"), Color("f2a62b"), Color("ffd85a"), Color("fff1a1"), Color("fffbe5")],
	"yuki": [Color("174f76"), Color("258cc1"), Color("55cbe3"), Color("a8eff4"), Color("f5ffff"), Color("dc3e48")],
	"luna": [Color("8f347f"), Color("e74faa"), Color("ff87c8"), Color("67dce8"), Color("ffd65e"), Color("fff7f0")],
	"brave": [Color("8d2d60"), Color("e74387"), Color("ff79ad"), Color("f4a33d"), Color("ffe174"), Color("fff9df")],
	"nova": [Color("123c50"), Color("08798b"), Color("13bdc2"), Color("72edf0"), Color("f4ffff"), Color("efbb39")],
	"rio": [Color("282875"), Color("4d3fc2"), Color("745fe8"), Color("4bb8ed"), Color("b4eeff"), Color("fbffff")],
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	for effect_name: String in SPECS:
		_build_strip(effect_name, SPECS[effect_name])
	_build_comparison()
	_build_all_frames()
	print("ATTACK_VFX_2X_BUILD_OK count=%d" % SPECS.size())
	quit(0)


func _build_strip(effect_name: String, spec: Dictionary) -> void:
	var source_dir: String = spec.get("source", OLD_SOURCE_DIR)
	var source_path := "%s/%s_source.png" % [source_dir, effect_name]
	var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	if source == null or source.is_empty():
		push_error("Cannot load source: %s" % source_path)
		return
	source.convert(Image.FORMAT_RGBA8)
	var frame_size: Vector2i = spec.size
	var contents: Array[Image] = []
	var maximum_source_size := Vector2i.ZERO
	for frame_index in FRAME_COUNT:
		var cuts: Array = spec.get("cuts", [])
		var x0 := roundi(float(cuts[frame_index]) * source.get_width() / 2048.0) if not cuts.is_empty() else floori(float(frame_index) * source.get_width() / FRAME_COUNT)
		var x1 := roundi(float(cuts[frame_index + 1]) * source.get_width() / 2048.0) if not cuts.is_empty() else floori(float(frame_index + 1) * source.get_width() / FRAME_COUNT)
		var cell := source.get_region(Rect2i(x0, 0, x1 - x0, source.get_height()))
		_clean_background(cell, float(spec.get("dark_cut", 0.045)))
		var used := cell.get_used_rect()
		if used.size == Vector2i.ZERO:
			push_error("Empty generated frame: %s[%d]" % [effect_name, frame_index])
			contents.append(Image.create_empty(1, 1, false, Image.FORMAT_RGBA8))
			continue
		used = _padded_rect(used, cell.get_size(), 3)
		var content := cell.get_region(used)
		contents.append(content)
		maximum_source_size.x = maxi(maximum_source_size.x, content.get_width())
		maximum_source_size.y = maxi(maximum_source_size.y, content.get_height())
	var max_size := frame_size - Vector2i(MARGIN * 2, MARGIN * 2)
	var scale_x := float(max_size.x) / maximum_source_size.x
	var scale_y := float(max_size.y) / maximum_source_size.y
	var uniform_scale := minf(scale_x, scale_y)
	var strip := Image.create_empty(frame_size.x * FRAME_COUNT, frame_size.y, false, Image.FORMAT_RGBA8)
	strip.fill(Color.TRANSPARENT)
	for frame_index in FRAME_COUNT:
		var content := contents[frame_index]
		var stretch := effect_name.ends_with("_slash") or (effect_name.ends_with("_k") and effect_name != "yuki_k")
		var target := Vector2i(
			maxi(1, roundi(content.get_width() * (scale_x if stretch else uniform_scale))),
			maxi(1, roundi(content.get_height() * (scale_y if stretch else uniform_scale)))
		)
		content.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
		if effect_name == "nova_k":
			content.flip_x()
		_quantize(content, PALETTES[spec.palette])
		var destination := _aligned_position(frame_size, target, spec.align)
		strip.blit_rect(content, Rect2i(Vector2i.ZERO, target), Vector2i(frame_index * frame_size.x, 0) + destination)
	var error := strip.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, effect_name]))
	if error != OK:
		push_error("Failed to save %s (%d)" % [effect_name, error])
	else:
		print("built %s frame=%s strip=%s" % [effect_name, frame_size, strip.get_size()])


func _clean_background(image: Image, dark_cut: float) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.12 or maxf(color.r, maxf(color.g, color.b)) < dark_cut:
				image.set_pixel(x, y, Color.TRANSPARENT)
			elif color.a < 0.5:
				color.a = 0.5
				image.set_pixel(x, y, color)


func _quantize(image: Image, palette: Array) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var source := image.get_pixel(x, y)
			if source.a < 0.12:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
			var nearest: Color = palette[0]
			var nearest_distance := INF
			for candidate: Color in palette:
				var delta := Vector3(source.r - candidate.r, source.g - candidate.g, source.b - candidate.b)
				if delta.length_squared() < nearest_distance:
					nearest_distance = delta.length_squared()
					nearest = candidate
			image.set_pixel(x, y, Color(nearest.r, nearest.g, nearest.b, 1.0 if source.a >= 0.58 else 0.5))


func _aligned_position(frame_size: Vector2i, content_size: Vector2i, alignment: String) -> Vector2i:
	match alignment:
		"left_middle":
			return Vector2i(MARGIN, clampi((frame_size.y - content_size.y) / 2, MARGIN, frame_size.y - content_size.y - MARGIN))
		"bottom_center":
			return Vector2i(clampi((frame_size.x - content_size.x) / 2, MARGIN, frame_size.x - content_size.x - MARGIN), frame_size.y - content_size.y - MARGIN)
		_:
			return Vector2i(
				clampi((frame_size.x - content_size.x) / 2, MARGIN, frame_size.x - content_size.x - MARGIN),
				clampi((frame_size.y - content_size.y) / 2, MARGIN, frame_size.y - content_size.y - MARGIN)
			)


func _padded_rect(rect: Rect2i, image_size: Vector2i, padding: int) -> Rect2i:
	var start := Vector2i(maxi(0, rect.position.x - padding), maxi(0, rect.position.y - padding))
	var end := Vector2i(mini(image_size.x, rect.end.x + padding), mini(image_size.y, rect.end.y + padding))
	return Rect2i(start, end - start)


func _build_comparison() -> void:
	var names: Array[String] = []
	for effect_name: String in SPECS:
		names.append(effect_name)
	names.sort()
	var tile := Vector2i(1040, 400)
	var board := Image.create_empty(tile.x * 2, tile.y * names.size(), false, Image.FORMAT_RGBA8)
	_draw_checker(board)
	for row in names.size():
		var name := names[row]
		var new_size: Vector2i = SPECS[name].size
		var old_size := new_size / 2
		var old_strip := Image.load_from_file(ProjectSettings.globalize_path("res://tests/art_preview/attack_vfx_2x_a/baseline_vfx/%s.png" % name))
		var new_strip := Image.load_from_file(ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, name]))
		var old_frame := old_strip.get_region(Rect2i(old_size.x * 3, 0, old_size.x, old_size.y))
		old_frame.resize(new_size.x, new_size.y, Image.INTERPOLATE_NEAREST)
		var new_frame := new_strip.get_region(Rect2i(new_size.x * 3, 0, new_size.x, new_size.y))
		var y := row * tile.y + (tile.y - new_size.y) / 2
		board.blend_rect(old_frame, Rect2i(Vector2i.ZERO, old_frame.get_size()), Vector2i(32 + (tile.x - new_size.x) / 2, y))
		board.blend_rect(new_frame, Rect2i(Vector2i.ZERO, new_frame.get_size()), Vector2i(tile.x + 32 + (tile.x - new_size.x) / 2, y))
	board.save_png(ProjectSettings.globalize_path(REPORT_DIR + "/attack_vfx_before_after.png"))


func _draw_checker(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			image.set_pixel(x, y, Color("151a24") if ((x / 16) + (y / 16)) % 2 == 0 else Color("202738"))

func _build_all_frames() -> void:
	var names: Array[String] = []
	for effect_name: String in SPECS:
		names.append(effect_name)
	names.sort()
	var width := 3104
	var height := 16
	for name in names:
		height += SPECS[name].size.y + 16
	var board := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	_draw_checker(board)
	var y := 8
	for name in names:
		var strip := Image.load_from_file(ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, name]))
		board.blend_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(8, y))
		y += strip.get_height() + 16
	board.save_png(ProjectSettings.globalize_path(REPORT_DIR + "/attack_vfx_all_frames.png"))
