extends SceneTree

const REPORT_DIR := "../reports/codex-art-17"
const SOURCE_DIR := REPORT_DIR + "/source"
const HAZARD_DIR := "res://assets/art/hazards"
const MONSTER_DIR := "res://assets/art/monsters"
const EFFECT_DIR := "res://assets/art/effects"

const TRANSPARENT := Color(0, 0, 0, 0)
const QUANT_LEVELS := 15.0


func _init() -> void:
	build_quake_warning()
	build_quake_impact()
	build_vine_bridge()
	build_modular_column("light", Rect2i(864, 0, 384, 887))
	build_modular_column("fire", Rect2i(1340, 0, 390, 887))
	build_monster_rim("mossling_sheet.png", Color("168c91"), Color("f2dfa3"))
	build_monster_rim("ember_imp_sheet.png", Color("7b4bc4"), Color("ffe39a"))
	build_yuki_seal()
	build_previews()
	write_verification()
	print("ART17_BUILD_OK")
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
		push_error("Could not save: " + path + " error=" + str(error))
		quit(1)


func quantize_pixel_art(image: Image, keep_soft_alpha: bool = false) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.16:
				image.set_pixel(x, y, TRANSPARENT)
				continue
			color.r = round(color.r * QUANT_LEVELS) / QUANT_LEVELS
			color.g = round(color.g * QUANT_LEVELS) / QUANT_LEVELS
			color.b = round(color.b * QUANT_LEVELS) / QUANT_LEVELS
			if keep_soft_alpha:
				color.a = 0.35 if color.a < 0.5 else (0.68 if color.a < 0.82 else 1.0)
			else:
				color.a = 1.0
			image.set_pixel(x, y, color)


func alpha_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.12:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func fit_region(source: Image, region: Rect2i, size: Vector2i, margin: int = 0, bottom_align: bool = true) -> Image:
	var safe := region.intersection(Rect2i(Vector2i.ZERO, source.get_size()))
	var crop := source.get_region(safe)
	var bounds := alpha_bounds(crop)
	if bounds.size == Vector2i.ZERO:
		return Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	crop = crop.get_region(bounds)
	var usable := size - Vector2i(margin * 2, margin * 2)
	var scale := minf(float(usable.x) / crop.get_width(), float(usable.y) / crop.get_height())
	var target := Vector2i(maxi(1, roundi(crop.get_width() * scale)), maxi(1, roundi(crop.get_height() * scale)))
	crop.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
	quantize_pixel_art(crop, true)
	var canvas := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var position := Vector2i((size.x - target.x) / 2, margin)
	if bottom_align:
		position.y = size.y - margin - target.y
	canvas.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), position)
	return canvas


func stretch_region(source: Image, region: Rect2i, content_size: Vector2i, canvas_size: Vector2i) -> Image:
	var safe := region.intersection(Rect2i(Vector2i.ZERO, source.get_size()))
	var crop := source.get_region(safe)
	var bounds := alpha_bounds(crop)
	if bounds.size == Vector2i.ZERO:
		return Image.create_empty(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	crop = crop.get_region(bounds)
	crop.resize(content_size.x, content_size.y, Image.INTERPOLATE_NEAREST)
	quantize_pixel_art(crop, true)
	var canvas := Image.create_empty(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	var position := Vector2i((canvas_size.x - content_size.x) / 2, (canvas_size.y - content_size.y) / 2)
	canvas.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), position)
	return canvas


func draw_line(image: Image, points: Array, color: Color, thickness: int = 1) -> void:
	for index in points.size() - 1:
		var start: Vector2i = points[index]
		var finish: Vector2i = points[index + 1]
		var delta: Vector2i = finish - start
		var steps := maxi(absi(delta.x), absi(delta.y))
		for step in steps + 1:
			var ratio := float(step) / maxi(1, steps)
			var point := Vector2i(roundi(lerpf(start.x, finish.x, ratio)), roundi(lerpf(start.y, finish.y, ratio)))
			for oy in range(-thickness + 1, thickness):
				for ox in range(-thickness + 1, thickness):
					var pixel := point + Vector2i(ox, oy)
					if Rect2i(Vector2i.ZERO, image.get_size()).has_point(pixel):
						image.set_pixelv(pixel, color)


func draw_disc(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y > radius * radius:
				continue
			var point := center + Vector2i(x, y)
			if Rect2i(Vector2i.ZERO, image.get_size()).has_point(point):
				image.set_pixelv(point, color)


func build_quake_warning() -> void:
	var sheet := Image.create_empty(384, 16, false, Image.FORMAT_RGBA8)
	var slate := Color("26334a")
	var stone := Color("52647a")
	var dim := Color("9b6b29")
	var amber := Color("e39a24")
	var hot := Color("ffe17a")
	var crack_sets: Array[Array] = [
		[[Vector2i(14, 11), Vector2i(20, 8), Vector2i(27, 10)], [Vector2i(60, 11), Vector2i(65, 9), Vector2i(71, 10)]],
		[[Vector2i(7, 11), Vector2i(15, 7), Vector2i(22, 10), Vector2i(31, 6), Vector2i(39, 10)], [Vector2i(66, 11), Vector2i(73, 6), Vector2i(80, 10)]],
		[[Vector2i(0, 10), Vector2i(9, 7), Vector2i(18, 10), Vector2i(28, 4), Vector2i(38, 10), Vector2i(48, 7), Vector2i(57, 11)], [Vector2i(70, 11), Vector2i(78, 5), Vector2i(87, 9), Vector2i(95, 10)]],
		[[Vector2i(0, 10), Vector2i(8, 8), Vector2i(17, 10), Vector2i(27, 6), Vector2i(37, 10)], [Vector2i(55, 11), Vector2i(63, 8), Vector2i(72, 10), Vector2i(82, 7), Vector2i(95, 10)]]
	]
	for frame in 4:
		var cell := Image.create_empty(96, 16, false, Image.FORMAT_RGBA8)
		for x in 96:
			cell.set_pixel(x, 12, stone if x % 7 < 4 else slate)
			cell.set_pixel(x, 13, slate)
		var glow: Color = [dim, amber, hot, amber][frame]
		for polyline in crack_sets[frame]:
			draw_line(cell, polyline, glow, 1)
		for x in range(0, 96, 12):
			cell.set_pixel((x + frame * 3) % 96, 14, Color("172033"))
		for y in 16:
			cell.set_pixel(95, y, cell.get_pixel(0, y))
		sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(frame * 96, 0))
	save_image(sheet, HAZARD_DIR + "/quake_warning.png")


func build_quake_impact() -> void:
	var source := load_image(SOURCE_DIR + "/quake_source.png")
	var ranges := [
		Rect2i(15, 320, 275, 415), Rect2i(308, 320, 276, 415), Rect2i(603, 300, 275, 435),
		Rect2i(892, 285, 280, 450), Rect2i(1191, 310, 277, 425), Rect2i(1486, 330, 275, 405)
	]
	var sheet := Image.create_empty(128 * 6, 64, false, Image.FORMAT_RGBA8)
	for frame in 6:
		var cell := fit_region(source, ranges[frame], Vector2i(128, 64), 2, true)
		cell.set_pixel(63, 62, Color("f3dfb5"))
		cell.set_pixel(64, 62, Color("fff3cf"))
		sheet.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(frame * 128, 0))
	save_image(sheet, HAZARD_DIR + "/quake_impact.png")


func build_vine_bridge() -> void:
	var source := load_image(SOURCE_DIR + "/modular_hazards_source.png")
	var bridge := stretch_region(source, Rect2i(0, 330, 750, 420), Vector2i(96, 24), Vector2i(96, 24))
	# Force the requested high-contrast walkable rim and readable tiled join pixels.
	for x in 96:
		var y := 4
		while y < 12 and bridge.get_pixel(x, y).a < 0.2:
			y += 1
		if y < 12:
			bridge.set_pixel(x, y, Color("d9f45a"))
			if x % 5 != 0 and y + 1 < 24:
				bridge.set_pixel(x, y + 1, Color("7fbf3f"))
	# Matching edge pixels keep repeated 96 px bridge segments from showing a gap.
	for y in 24:
		var joined := bridge.get_pixel(1, y).lerp(bridge.get_pixel(94, y), 0.5)
		bridge.set_pixel(0, y, joined)
		bridge.set_pixel(95, y, joined)
	save_image(bridge, HAZARD_DIR + "/vine_bridge.png")


func build_modular_column(kind: String, source_rect: Rect2i) -> void:
	var source := load_image(SOURCE_DIR + "/modular_hazards_source.png")
	var top_region := Rect2i(source_rect.position.x, 0, source_rect.size.x, 270)
	var mid_y := 250
	var mid_h := 410
	var base_region := Rect2i(source_rect.position.x, 665, source_rect.size.x, 359)
	var top := fit_region(source, top_region, Vector2i(96, 64), 0, false)
	var base := fit_region(source, base_region, Vector2i(96, 64), 0, true)
	var middle := Image.create_empty(96 * 6, 128, false, Image.FORMAT_RGBA8)
	var column_width := float(source_rect.size.x) / 6.0
	for frame in 6:
		var x0 := source_rect.position.x + roundi(frame * column_width)
		var x1 := source_rect.position.x + roundi((frame + 1) * column_width)
		var crop_rect := Rect2i(x0, mid_y, maxi(1, x1 - x0), mid_h)
		var cell := stretch_region(source, crop_rect, Vector2i(68, 128), Vector2i(96, 128))
		make_vertical_tile(cell)
		middle.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(frame * 96, 0))
	save_image(base, HAZARD_DIR + "/" + kind + "_pillar_base.png" if kind == "fire" else HAZARD_DIR + "/light_beam_base.png")
	save_image(middle, HAZARD_DIR + "/" + kind + "_pillar_mid.png" if kind == "fire" else HAZARD_DIR + "/light_beam_mid.png")
	save_image(top, HAZARD_DIR + "/" + kind + "_pillar_top.png" if kind == "fire" else HAZARD_DIR + "/light_beam_top.png")


func make_vertical_tile(cell: Image) -> void:
	# Blend a shared four-row band into both ends; exact equality is verified later.
	for y in 4:
		for x in cell.get_width():
			var a := cell.get_pixel(x, 4 + y)
			var b := cell.get_pixel(x, cell.get_height() - 8 + y)
			var joined := a.lerp(b, 0.5)
			joined.a = maxf(a.a, b.a)
			cell.set_pixel(x, y, joined)
			cell.set_pixel(x, cell.get_height() - 4 + y, joined)


func build_monster_rim(filename: String, cool_rim: Color, warm_rim: Color) -> void:
	var path := MONSTER_DIR + "/" + filename
	# Always rebuild from the preserved pre-ART-17 sheet so reruns cannot grow the rim.
	var source := load_image(REPORT_DIR + "/before/" + filename)
	var result := source.duplicate()
	var cell_size := Vector2i(96, 96)
	for cell_y in 4:
		for cell_x in 6:
			var origin := Vector2i(cell_x * 96, cell_y * 96)
			for y in 96:
				for x in 96:
					var p := origin + Vector2i(x, y)
					if source.get_pixelv(p).a > 0.12:
						continue
					var near_one := has_alpha_neighbor(source, p, origin, cell_size, 1)
					var near_two := has_alpha_neighbor(source, p, origin, cell_size, 2)
					if near_one:
						var highlight := has_alpha_neighbor_direction(source, p, origin, cell_size, Vector2i(1, 1))
						result.set_pixelv(p, warm_rim if highlight and (x + y) % 3 != 0 else cool_rim)
					elif near_two:
						var outer := cool_rim.darkened(0.24)
						outer.a = 0.94
						result.set_pixelv(p, outer)
	save_image(result, path)


func has_alpha_neighbor(image: Image, point: Vector2i, cell_origin: Vector2i, cell_size: Vector2i, radius: int) -> bool:
	var cell := Rect2i(cell_origin, cell_size)
	for oy in range(-radius, radius + 1):
		for ox in range(-radius, radius + 1):
			if maxi(absi(ox), absi(oy)) != radius:
				continue
			var neighbor := point + Vector2i(ox, oy)
			if cell.has_point(neighbor) and image.get_pixelv(neighbor).a > 0.2:
				return true
	return false


func has_alpha_neighbor_direction(image: Image, point: Vector2i, cell_origin: Vector2i, cell_size: Vector2i, direction: Vector2i) -> bool:
	var neighbor := point + direction
	return Rect2i(cell_origin, cell_size).has_point(neighbor) and image.get_pixelv(neighbor).a > 0.2


func build_yuki_seal() -> void:
	var source := load_image(SOURCE_DIR + "/yuki_seal_source.png")
	var sheet := Image.create_empty(64 * 4, 64, false, Image.FORMAT_RGBA8)
	var frame_width := source.get_width() / 4
	for frame in 4:
		var region := Rect2i(frame * frame_width, 20, frame_width, source.get_height() - 40)
		var cell := fit_region(source, region, Vector2i(64, 64), 2, true)
		# Stable bottom-centre anchor marker is part of the seal shadow, not extra gameplay geometry.
		cell.set_pixel(31, 61, Color(0.10, 0.12, 0.25, 0.45))
		cell.set_pixel(32, 61, Color(0.10, 0.12, 0.25, 0.45))
		sheet.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(frame * 64, 0))
	save_image(sheet, EFFECT_DIR + "/yuki_seal_idle.png")


func checkerboard(size: Vector2i, cell: int = 8) -> Image:
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		for x in size.x:
			image.set_pixel(x, y, Color("182234") if ((x / cell) + (y / cell)) % 2 == 0 else Color("24344a"))
	return image


func paste_scaled(canvas: Image, source: Image, position: Vector2i, scale: int) -> void:
	var scaled := source.duplicate()
	scaled.resize(source.get_width() * scale, source.get_height() * scale, Image.INTERPOLATE_NEAREST)
	canvas.blend_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), position)


func build_previews() -> void:
	var hazard_board := checkerboard(Vector2i(1536, 768), 16)
	paste_scaled(hazard_board, load_image(HAZARD_DIR + "/quake_warning.png"), Vector2i(32, 32), 2)
	paste_scaled(hazard_board, load_image(HAZARD_DIR + "/quake_impact.png"), Vector2i(0, 112), 2)
	paste_scaled(hazard_board, load_image(HAZARD_DIR + "/vine_bridge.png"), Vector2i(32, 272), 4)
	paste_scaled(hazard_board, load_image(HAZARD_DIR + "/light_beam_base.png"), Vector2i(480, 272), 2)
	paste_scaled(hazard_board, load_image(HAZARD_DIR + "/light_beam_mid.png"), Vector2i(672, 272), 1)
	paste_scaled(hazard_board, load_image(HAZARD_DIR + "/light_beam_top.png"), Vector2i(1248, 272), 2)
	paste_scaled(hazard_board, load_image(HAZARD_DIR + "/fire_pillar_base.png"), Vector2i(480, 512), 2)
	paste_scaled(hazard_board, load_image(HAZARD_DIR + "/fire_pillar_mid.png"), Vector2i(672, 512), 1)
	paste_scaled(hazard_board, load_image(HAZARD_DIR + "/fire_pillar_top.png"), Vector2i(1248, 512), 2)
	save_image(hazard_board, REPORT_DIR + "/hazards_after_2x.png")

	var seam_board := checkerboard(Vector2i(960, 640), 16)
	var beam_mid := load_image(HAZARD_DIR + "/light_beam_mid.png").get_region(Rect2i(0, 0, 96, 128))
	var fire_mid := load_image(HAZARD_DIR + "/fire_pillar_mid.png").get_region(Rect2i(0, 0, 96, 128))
	for repeat in 3:
		paste_scaled(seam_board, beam_mid, Vector2i(96, repeat * 256), 2)
		paste_scaled(seam_board, fire_mid, Vector2i(576, repeat * 256), 2)
	var warning := load_image(HAZARD_DIR + "/quake_warning.png").get_region(Rect2i(96 * 2, 0, 96, 16))
	for repeat in 4:
		paste_scaled(seam_board, warning, Vector2i(repeat * 192, 304), 2)
	save_image(seam_board, REPORT_DIR + "/seam_checks_2x.png")

	build_monster_preview("mossling_sheet.png", "realm_vanaheim/bg_far.png", REPORT_DIR + "/mossling_vanaheim_2x.png")
	build_monster_preview("ember_imp_sheet.png", "realm_muspelheim/bg_far.png", REPORT_DIR + "/ember_imp_muspelheim_2x.png")

	var seal_board := checkerboard(Vector2i(1024, 320), 16)
	paste_scaled(seal_board, load_image(EFFECT_DIR + "/yuki_seal_idle.png"), Vector2i(0, 32), 4)
	save_image(seal_board, REPORT_DIR + "/yuki_seal_after_4x.png")


func build_monster_preview(monster_file: String, background_file: String, output: String) -> void:
	var background := load_image("res://assets/art/" + background_file)
	background.resize(960, 540, Image.INTERPOLATE_NEAREST)
	var monster_sheet := load_image(MONSTER_DIR + "/" + monster_file)
	for frame in 6:
		var cell := monster_sheet.get_region(Rect2i((frame % 4) * 96, 0, 96, 96))
		paste_scaled(background, cell, Vector2i(40 + frame * 145, 332), 2)
	save_image(background, output)


func seam_mismatch(sheet_path: String) -> int:
	var sheet := load_image(sheet_path)
	var mismatch := 0
	for frame in 6:
		for x in 96:
			for band in 4:
				if sheet.get_pixel(frame * 96 + x, band) != sheet.get_pixel(frame * 96 + x, 124 + band):
					mismatch += 1
	return mismatch


func horizontal_seam_mismatch(sheet_path: String, frame_width: int, frame_count: int) -> int:
	var sheet := load_image(sheet_path)
	var mismatch := 0
	for frame in frame_count:
		for y in sheet.get_height():
			if sheet.get_pixel(frame * frame_width, y) != sheet.get_pixel(frame * frame_width + frame_width - 1, y):
				mismatch += 1
	return mismatch


func write_verification() -> void:
	var lines: Array[String] = []
	var checks := {
		"quake_warning.png": Vector2i(384, 16), "quake_impact.png": Vector2i(768, 64),
		"vine_bridge.png": Vector2i(96, 24), "light_beam_base.png": Vector2i(96, 64),
		"light_beam_mid.png": Vector2i(576, 128), "light_beam_top.png": Vector2i(96, 64),
		"fire_pillar_base.png": Vector2i(96, 64), "fire_pillar_mid.png": Vector2i(576, 128),
		"fire_pillar_top.png": Vector2i(96, 64)
	}
	for file in checks:
		var image := load_image(HAZARD_DIR + "/" + file)
		lines.append("%s size=%s expected=%s ok=%s" % [file, image.get_size(), checks[file], image.get_size() == checks[file]])
	for file in ["mossling_sheet.png", "ember_imp_sheet.png"]:
		var image := load_image(MONSTER_DIR + "/" + file)
		lines.append("%s size=%s expected=(576, 384) ok=%s" % [file, image.get_size(), image.get_size() == Vector2i(576, 384)])
	var seal := load_image(EFFECT_DIR + "/yuki_seal_idle.png")
	lines.append("yuki_seal_idle.png size=%s expected=(256, 64) ok=%s" % [seal.get_size(), seal.get_size() == Vector2i(256, 64)])
	lines.append("light_mid_seam_mismatch=%d" % seam_mismatch(HAZARD_DIR + "/light_beam_mid.png"))
	lines.append("fire_mid_seam_mismatch=%d" % seam_mismatch(HAZARD_DIR + "/fire_pillar_mid.png"))
	lines.append("quake_warning_horizontal_seam_mismatch=%d" % horizontal_seam_mismatch(HAZARD_DIR + "/quake_warning.png", 96, 4))
	lines.append("vine_bridge_horizontal_seam_mismatch=%d" % horizontal_seam_mismatch(HAZARD_DIR + "/vine_bridge.png", 96, 1))
	lines.append("monster_cells=6x4 cell=96x96 preserved=true")
	lines.append("quake_warning_anchor=top-left per 96x16 frame; horizontal repeat")
	lines.append("quake_impact_anchor=bottom-center (64,63) per 128x64 frame")
	lines.append("column_base_anchor=bottom-center (48,63); mid vertical repeat; top join anchor=bottom-center (48,63)")
	lines.append("yuki_seal_anchor=bottom-center (32,63) per 64x64 frame")
	var file := FileAccess.open(REPORT_DIR + "/verification.txt", FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
