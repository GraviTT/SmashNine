extends SceneTree

const FRAME_COUNT := 6
const OUTPUT_DIR := "res://assets/art/attack_vfx"
const REPORT_DIR := "res://../reports/codex-art-13"
const SOURCE_DIR := "res://../reports/codex-art-13/source"

const SPECS := {
	"frey_slash": {"size": Vector2i(192, 128), "align": "left_middle", "palette": "frey"},
	"yuki_slash": {"size": Vector2i(192, 128), "align": "left_middle", "palette": "yuki"},
	"luna_slash": {"size": Vector2i(192, 128), "align": "left_middle", "palette": "luna"},
	"luna_brave_slash": {"size": Vector2i(224, 128), "align": "left_middle", "palette": "brave"},
	"nova_slash": {"size": Vector2i(160, 128), "align": "left_middle", "palette": "nova"},
	"rio_slash": {"size": Vector2i(192, 128), "align": "left_middle", "palette": "rio"},
	"frey_k": {"size": Vector2i(224, 96), "align": "left_middle", "palette": "frey"},
	"yuki_k": {"size": Vector2i(128, 128), "align": "center", "palette": "yuki"},
	"luna_k": {"size": Vector2i(160, 96), "align": "left_middle", "palette": "luna"},
	"nova_k": {"size": Vector2i(224, 96), "align": "left_middle", "palette": "nova"},
	"rio_k": {"size": Vector2i(256, 96), "align": "left_middle", "palette": "rio", "dark_cut": 0.34},
	"frey_l": {"size": Vector2i(128, 192), "align": "bottom_center", "palette": "frey"},
	"yuki_l": {"size": Vector2i(192, 192), "align": "center", "palette": "yuki"},
	"luna_l": {"size": Vector2i(192, 192), "align": "center", "palette": "luna"},
	"nova_l": {"size": Vector2i(192, 192), "align": "bottom_center", "palette": "nova"},
	"rio_l": {"size": Vector2i(128, 160), "align": "left_middle", "palette": "rio"},
}

const PALETTES := {
	"frey": [
		Color("713619"), Color("b66520"), Color("f2a62b"), Color("ffd85a"),
		Color("fff1a1"), Color("fffbe5")
	],
	"yuki": [
		Color("174f76"), Color("258cc1"), Color("55cbe3"), Color("a8eff4"),
		Color("f5ffff"), Color("dc3e48")
	],
	"luna": [
		Color("8f347f"), Color("e74faa"), Color("ff87c8"), Color("67dce8"),
		Color("ffd65e"), Color("fff7f0")
	],
	"brave": [
		Color("8d2d60"), Color("e74387"), Color("ff79ad"), Color("f4a33d"),
		Color("ffe174"), Color("fff9df")
	],
	"nova": [
		Color("123c50"), Color("08798b"), Color("13bdc2"), Color("72edf0"),
		Color("f4ffff"), Color("efbb39")
	],
	"rio": [
		Color("282875"), Color("4d3fc2"), Color("745fe8"), Color("4bb8ed"),
		Color("b4eeff"), Color("fbffff")
	],
}

const FIGHTERS := {
	"frey": "res://assets/art/frey/frey_sheet.png",
	"yuki": "res://assets/art/yuki/yuki_sheet.png",
	"luna": "res://assets/art/luna/luna_sheet.png",
	"nova": "res://assets/art/nova/nova_female_sheet.png",
	"rio": "res://assets/art/rio/rio_female_sheet.png",
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	for effect_name in SPECS:
		_build_strip(effect_name, SPECS[effect_name])
	_build_preview()
	print("ATTACK_VFX_BUILD_OK count=%d" % SPECS.size())
	quit()


func _build_strip(effect_name: String, spec: Dictionary) -> void:
	var source_path := "%s/%s_source.png" % [SOURCE_DIR, effect_name]
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("Cannot load source: %s" % source_path)
		return
	var frame_size: Vector2i = spec["size"]
	var strip := Image.create(frame_size.x * FRAME_COUNT, frame_size.y, false, Image.FORMAT_RGBA8)
	strip.fill(Color.TRANSPARENT)
	var contents: Array[Image] = []
	var maximum_source_size := Vector2i.ZERO
	for frame_index in FRAME_COUNT:
		var x0 := int(floor(float(frame_index) * source.get_width() / FRAME_COUNT))
		var x1 := int(floor(float(frame_index + 1) * source.get_width() / FRAME_COUNT))
		var cell := source.get_region(Rect2i(x0, 0, x1 - x0, source.get_height()))
		var dark_cut: float = float(spec.get("dark_cut", 0.045))
		_clean_background(cell, dark_cut)
		var used := cell.get_used_rect()
		if used.size.x <= 0 or used.size.y <= 0:
			push_error("Empty generated frame: %s[%d]" % [effect_name, frame_index])
			contents.append(Image.create(1, 1, false, Image.FORMAT_RGBA8))
			continue
		used = _padded_rect(used, cell.get_size(), 2)
		var content := cell.get_region(used)
		contents.append(content)
		maximum_source_size.x = maxi(maximum_source_size.x, content.get_width())
		maximum_source_size.y = maxi(maximum_source_size.y, content.get_height())
	var max_size := frame_size - Vector2i(8, 8)
	var scale_x := float(max_size.x) / maximum_source_size.x
	var scale_y := float(max_size.y) / maximum_source_size.y
	var uniform_scale := minf(scale_x, scale_y)
	for frame_index in FRAME_COUNT:
		var content: Image = contents[frame_index]
		var stretch_to_range := effect_name.ends_with("_slash") or (effect_name.ends_with("_k") and effect_name != "yuki_k")
		var frame_scale_x := scale_x if stretch_to_range else uniform_scale
		var frame_scale_y := scale_y if stretch_to_range else uniform_scale
		var scaled_size := Vector2i(
			maxi(1, int(round(content.get_width() * frame_scale_x))),
			maxi(1, int(round(content.get_height() * frame_scale_y)))
		)
		content.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_NEAREST)
		if effect_name == "nova_k":
			content.flip_x()
		_quantize(content, PALETTES[spec["palette"]])
		var destination := _aligned_position(frame_size, scaled_size, String(spec["align"]))
		strip.blit_rect(content, Rect2i(Vector2i.ZERO, scaled_size), Vector2i(frame_index * frame_size.x, 0) + destination)
	var output_path := "%s/%s.png" % [OUTPUT_DIR, effect_name]
	var error := strip.save_png(output_path)
	if error != OK:
		push_error("Failed to save %s (%d)" % [output_path, error])
	else:
		print("built %s %dx%d frames=%d" % [effect_name, frame_size.x, frame_size.y, FRAME_COUNT])


func _clean_background(image: Image, dark_cut: float) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			var value := maxf(color.r, maxf(color.g, color.b))
			if color.a < 0.12 or value < dark_cut:
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
				var distance := delta.length_squared()
				if distance < nearest_distance:
					nearest_distance = distance
					nearest = candidate
			var alpha := 1.0 if source.a >= 0.58 else 0.5
			image.set_pixel(x, y, Color(nearest.r, nearest.g, nearest.b, alpha))


func _padded_rect(rect: Rect2i, image_size: Vector2i, padding: int) -> Rect2i:
	var start := Vector2i(maxi(0, rect.position.x - padding), maxi(0, rect.position.y - padding))
	var end := Vector2i(
		mini(image_size.x, rect.end.x + padding),
		mini(image_size.y, rect.end.y + padding)
	)
	return Rect2i(start, end - start)


func _aligned_position(frame_size: Vector2i, content_size: Vector2i, alignment: String) -> Vector2i:
	match alignment:
		"left_middle":
			return Vector2i(4, clampi((frame_size.y - content_size.y) / 2, 4, frame_size.y - content_size.y - 4))
		"bottom_center":
			return Vector2i(clampi((frame_size.x - content_size.x) / 2, 4, frame_size.x - content_size.x - 4), frame_size.y - content_size.y - 4)
		_:
			return Vector2i(
				clampi((frame_size.x - content_size.x) / 2, 4, frame_size.x - content_size.x - 4),
				clampi((frame_size.y - content_size.y) / 2, 4, frame_size.y - content_size.y - 4)
			)


func _build_preview() -> void:
	var rows := [
		["frey", "frey_slash", "frey_k", "frey_l"],
		["yuki", "yuki_slash", "yuki_k", "yuki_l"],
		["luna", "luna_slash", "luna_k", "luna_l"],
		["luna", "luna_brave_slash", "luna_k", "luna_l"],
		["nova", "nova_slash", "nova_k", "nova_l"],
		["rio", "rio_slash", "rio_k", "rio_l"],
	]
	var row_height := 208
	var preview := Image.create(936, rows.size() * row_height + 16, false, Image.FORMAT_RGBA8)
	_draw_checkerboard(preview, Color("151a24"), Color("202738"), 16)
	for row_index in rows.size():
		var row: Array = rows[row_index]
		var y0 := 8 + row_index * row_height
		var fighter := Image.load_from_file(FIGHTERS[row[0]])
		var fighter_frame := fighter.get_region(Rect2i(0, 0, 128, 128))
		preview.blend_rect(fighter_frame, Rect2i(0, 0, 128, 128), Vector2i(8, y0 + 40))
		var slots := [Vector2i(152, y0), Vector2i(416, y0), Vector2i(680, y0)]
		for effect_index in 3:
			var effect_name: String = row[effect_index + 1]
			var effect: Image = Image.load_from_file("%s/%s.png" % [OUTPUT_DIR, effect_name])
			var frame_size: Vector2i = SPECS[effect_name]["size"]
			var peak_frame := effect.get_region(Rect2i(frame_size.x * 3, 0, frame_size.x, frame_size.y))
			var position: Vector2i = slots[effect_index] + Vector2i((256 - frame_size.x) / 2, (192 - frame_size.y) / 2)
			preview.blend_rect(peak_frame, Rect2i(Vector2i.ZERO, frame_size), position)
		_draw_rect_outline(preview, Rect2i(0, y0 + row_height - 1, preview.get_width(), 1), Color("526079"))
	preview.save_png("%s/preview.png" % REPORT_DIR)
	var inspection := preview.duplicate()
	inspection.resize(preview.get_width() * 4, preview.get_height() * 4, Image.INTERPOLATE_NEAREST)
	inspection.save_png("%s/inspection_4x.png" % REPORT_DIR)


func _draw_checkerboard(image: Image, a: Color, b: Color, tile: int) -> void:
	for y in image.get_height():
		for x in image.get_width():
			image.set_pixel(x, y, a if ((x / tile) + (y / tile)) % 2 == 0 else b)


func _draw_rect_outline(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect, color)
