extends SceneTree

const EFFECT_DIR := "res://assets/art/effects/"
const VFX_DIR := "res://assets/art/vfx/"
const SOURCE_DIR := "res://tests/art_preview/fx_1x_b/"
const REPORT_DIR := "res://../reports/codex-art-14/"
const OLD_DIR := REPORT_DIR + "old/"
const ALPHA_CUTOFF := 0.18

const PALETTES := {
	"spark": ["#0B1026", "#654219", "#A86C20", "#E4A72B", "#FFD86B", "#FFF0B0", "#FFFFFF"],
	"yuki_effect": ["#10132C", "#3A2032", "#7B2832", "#C63B32", "#E94135", "#D99B43", "#E8D1A5", "#FFF4D7", "#FFFFFF"],
	"yuki": ["#071934", "#0C3F73", "#126DA1", "#20A9D0", "#75D8EB", "#C6F5F5", "#E94135", "#FFFFFF"],
	"luna": ["#171631", "#4A207A", "#8C2CB2", "#E34B9C", "#FF78BE", "#FFC4E7", "#75D7F4", "#C9F4FF", "#FFE067", "#FFFFFF"],
	"rio": ["#10172A", "#15295B", "#164E8B", "#147FB2", "#28BCE0", "#5BEAFF", "#BDEFFF", "#FFFFFF"],
	"frey": ["#3A1909", "#78360D", "#B96012", "#E99B22", "#FFD34F", "#FFF0A1", "#FFFFFF"],
	"nova": ["#02070C", "#072630", "#07515D", "#078C92", "#25D7D0", "#8CF8EA", "#9B681A", "#E4AC2E", "#FFE77B", "#FFFFFF"],
	"grey": ["#171A20", "#383D47", "#646B77", "#9299A4", "#C6CBD2", "#EBEDF0", "#FFFFFF"],
}

const EFFECT_SPECS := [
	{"id": "yuki_talisman", "cell": Vector2i(0, 0), "frame": Vector2i(128, 64), "work": Vector2i(120, 56), "palette": "yuki_effect"},
	{"id": "luna_star", "cell": Vector2i(1, 0), "frame": Vector2i(96, 96), "work": Vector2i(86, 86), "palette": "luna"},
	{"id": "rio_mana_wave", "cell": Vector2i(0, 1), "frame": Vector2i(48, 112), "work": Vector2i(42, 104), "palette": "rio"},
	{"id": "rio_gem_sword", "cell": Vector2i(1, 1), "frame": Vector2i(96, 32), "work": Vector2i(88, 26), "palette": "grey"},
]

const VFX_SPECS := [
	{"id": "frey_ult_charge", "grid": Vector2i(3, 2), "frames": 6, "old": Vector2i(128, 128), "frame": Vector2i(256, 256), "margin": Vector2i(8, 8), "align": "bottom_center", "palette": "frey"},
	{"id": "frey_ult_wave", "grid": Vector2i(4, 2), "frames": 8, "old": Vector2i(256, 96), "frame": Vector2i(512, 192), "margin": Vector2i(6, 6), "align": "bottom_left", "palette": "frey"},
	{"id": "yuki_ult_seal", "grid": Vector2i(4, 2), "frames": 8, "old": Vector2i(256, 256), "frame": Vector2i(512, 512), "margin": Vector2i(10, 10), "align": "center", "palette": "yuki"},
	{"id": "yuki_ult_burst", "grid": Vector2i(3, 2), "frames": 6, "old": Vector2i(256, 256), "frame": Vector2i(512, 512), "margin": Vector2i(10, 10), "align": "center", "palette": "yuki"},
	{"id": "luna_ult_transform", "grid": Vector2i(4, 2), "frames": 8, "old": Vector2i(192, 192), "frame": Vector2i(384, 384), "margin": Vector2i(8, 8), "align": "center", "palette": "luna"},
	{"id": "luna_ult_laser", "grid": Vector2i(2, 2), "frames": 4, "old": Vector2i(128, 96), "frame": Vector2i(256, 192), "margin": Vector2i(0, 8), "align": "tile_x", "palette": "luna"},
	{"id": "luna_ult_laser_head", "grid": Vector2i(2, 2), "frames": 4, "old": Vector2i(96, 96), "frame": Vector2i(192, 192), "margin": Vector2i(8, 8), "align": "center", "palette": "luna"},
	{"id": "nova_ult_core", "grid": Vector2i(3, 2), "frames": 6, "old": Vector2i(128, 128), "frame": Vector2i(256, 256), "margin": Vector2i(8, 10), "align": "center", "palette": "nova"},
	{"id": "nova_ult_burst", "grid": Vector2i(4, 2), "frames": 8, "old": Vector2i(256, 256), "frame": Vector2i(512, 512), "margin": Vector2i(10, 10), "align": "center", "palette": "nova"},
	{"id": "rio_ult_circle", "grid": Vector2i(3, 2), "frames": 6, "old": Vector2i(192, 192), "frame": Vector2i(384, 384), "margin": Vector2i(8, 8), "align": "center", "palette": "rio"},
	{"id": "rio_ult_impact", "grid": Vector2i(3, 2), "frames": 6, "old": Vector2i(64, 64), "frame": Vector2i(128, 128), "margin": Vector2i(8, 8), "align": "center", "palette": "grey"},
]

const FIGHTER_SHEETS := {
	"frey": "res://assets/art/frey/frey_sheet.png",
	"yuki": "res://assets/art/yuki/yuki_sheet.png",
	"luna": "res://assets/art/luna/luna_brave_sheet.png",
	"nova": "res://assets/art/nova/nova_female_sheet.png",
	"rio": "res://assets/art/rio/rio_female_sheet.png",
}

func _init() -> void:
	var ok := _build_hit_spark()
	ok = _build_projectiles() and ok
	for spec in VFX_SPECS:
		ok = _build_vfx(spec) and ok
	ok = _build_comparison() and ok
	if ok:
		print("[fx-1x-build] PASS effects=5 vfx=11 frames=70")
	quit(0 if ok else 1)

func _build_hit_spark() -> bool:
	var source := Image.load_from_file(SOURCE_DIR + "source_hit_spark_1x.png")
	if source.is_empty():
		push_error("missing generated hit spark source")
		return false
	var strip := Image.create(384, 96, false, Image.FORMAT_RGBA8)
	strip.fill(Color.TRANSPARENT)
	for index in 4:
		var cell := _grid_cell(source, Vector2i(4, 1), Vector2i(index, 0))
		var frame := _fit_frame(cell, Vector2i(96, 96), Vector2i(6, 6), "center", _palette("spark"))
		strip.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(index * 96, 0))
	return _save(strip, EFFECT_DIR + "hit_spark.png")

func _build_projectiles() -> bool:
	var source := Image.load_from_file(SOURCE_DIR + "source_projectiles_1x.png")
	if source.is_empty():
		push_error("missing generated projectile source")
		return false
	var ok := true
	for spec in EFFECT_SPECS:
		var cell: Image
		if String(spec.id).begins_with("rio_"):
			# The separate retained sources have clean tall/wide silhouettes; the new
			# composite source's broad glow would shrink these two into their canvases.
			cell = Image.load_from_file("res://tests/art_preview/effects_b/source_" + String(spec.id) + ".png")
		else:
			cell = _grid_cell(source, Vector2i(2, 2), spec.cell)
		var frame := _fit_frame(cell, spec.frame, (spec.frame - spec.work) / 2, "center", _palette(String(spec.palette)))
		ok = _save(frame, EFFECT_DIR + String(spec.id) + ".png") and ok
	return ok

func _build_vfx(spec: Dictionary) -> bool:
	var source := Image.load_from_file(VFX_DIR + String(spec.id) + "_source.png")
	if source.is_empty():
		push_error("missing retained high-resolution source: %s" % spec.id)
		return false
	var frame_size: Vector2i = spec.frame
	var strip := Image.create(frame_size.x * int(spec.frames), frame_size.y, false, Image.FORMAT_RGBA8)
	strip.fill(Color.TRANSPARENT)
	for index in int(spec.frames):
		var cell := _grid_cell(source, spec.grid, Vector2i(index % int(spec.grid.x), index / int(spec.grid.x)))
		var frame := _fit_frame(cell, frame_size, spec.margin, String(spec.align), _palette(String(spec.palette)))
		strip.blit_rect(frame, Rect2i(Vector2i.ZERO, frame_size), Vector2i(index * frame_size.x, 0))
	return _save(strip, VFX_DIR + String(spec.id) + ".png")

func _grid_cell(source: Image, grid: Vector2i, cell: Vector2i) -> Image:
	var x0 := roundi(float(cell.x) * source.get_width() / grid.x)
	var x1 := roundi(float(cell.x + 1) * source.get_width() / grid.x)
	var y0 := roundi(float(cell.y) * source.get_height() / grid.y)
	var y1 := roundi(float(cell.y + 1) * source.get_height() / grid.y)
	return source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))

func _fit_frame(source: Image, canvas: Vector2i, margin: Vector2i, align: String, palette: Array[Color]) -> Image:
	var cleaned: Image = source.duplicate()
	_cleanup_alpha(cleaned)
	var output := Image.create(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	var used: Rect2i = cleaned.get_used_rect()
	if used.size == Vector2i.ZERO:
		return output
	var crop: Image = cleaned.get_region(used)
	var available := canvas - margin * 2
	var factor := minf(float(available.x) / crop.get_width(), float(available.y) / crop.get_height())
	var fitted := Vector2i(maxi(1, floori(crop.get_width() * factor)), maxi(1, floori(crop.get_height() * factor)))
	if align == "tile_x":
		fitted.x = canvas.x
	# The retained/generated source is sampled directly to final density; no finished asset is enlarged.
	crop.resize(fitted.x, fitted.y, Image.INTERPOLATE_NEAREST)
	_quantize(crop, palette)
	var offset := Vector2i((canvas.x - fitted.x) / 2, (canvas.y - fitted.y) / 2)
	match align:
		"bottom_center": offset = Vector2i((canvas.x - fitted.x) / 2, canvas.y - margin.y - fitted.y)
		"bottom_left": offset = Vector2i(margin.x, canvas.y - margin.y - fitted.y)
		"tile_x": offset = Vector2i(0, (canvas.y - fitted.y) / 2)
	output.blit_rect(crop, Rect2i(Vector2i.ZERO, fitted), offset)
	if align == "tile_x":
		_make_horizontal_seam(output)
	return output

func _cleanup_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_CUTOFF or maxf(color.r, maxf(color.g, color.b)) < 0.02:
				image.set_pixel(x, y, Color.TRANSPARENT)
			else:
				color.a = 1.0
				image.set_pixel(x, y, color)

func _quantize(image: Image, palette: Array[Color]) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a == 0.0:
				continue
			var best := palette[0]
			var best_distance := INF
			for candidate in palette:
				var delta := Vector3(color.r - candidate.r, color.g - candidate.g, color.b - candidate.b)
				var distance := delta.length_squared()
				if distance < best_distance:
					best_distance = distance
					best = candidate
			image.set_pixel(x, y, Color(best.r, best.g, best.b, 1.0))

func _make_horizontal_seam(image: Image) -> void:
	for y in image.get_height():
		var left := image.get_pixel(0, y)
		var right := image.get_pixel(image.get_width() - 1, y)
		var seam := left if left.a >= right.a else right
		for x in [0, 1, image.get_width() - 2, image.get_width() - 1]:
			image.set_pixel(x, y, seam)

func _build_comparison() -> bool:
	var width := 2100
	var total_height := 290
	for spec in VFX_SPECS:
		total_height += maxi(280, int(spec.frame.y) + 32)
	var sheet := Image.create(width, total_height, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#070B14"))
	var y := 16
	_draw_checker(sheet, Rect2i(16, y, width - 32, 250), 16)
	var frey := _fighter("frey")
	sheet.blend_rect(frey, Rect2i(Vector2i.ZERO, frey.get_size()), Vector2i(28, y + 58))
	var old_effect_specs := [
		{"id":"hit_spark", "old":Vector2i(48,48), "new":Vector2i(96,96), "frames":4},
		{"id":"yuki_talisman", "old":Vector2i(32,16), "new":Vector2i(128,64), "frames":1},
		{"id":"luna_star", "old":Vector2i(24,24), "new":Vector2i(96,96), "frames":1},
		{"id":"rio_mana_wave", "old":Vector2i(24,56), "new":Vector2i(48,112), "frames":1},
		{"id":"rio_gem_sword", "old":Vector2i(48,16), "new":Vector2i(96,32), "frames":1},
	]
	var x := 180
	for spec in old_effect_specs:
		var old_img := Image.load_from_file(OLD_DIR + String(spec.id) + ".png")
		var new_img := Image.load_from_file(EFFECT_DIR + String(spec.id) + ".png")
		var old_frame := old_img.get_region(Rect2i(0, 0, spec.old.x, spec.old.y))
		old_frame.resize(spec.new.x, spec.new.y, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(old_frame, Rect2i(Vector2i.ZERO, old_frame.get_size()), Vector2i(x, y + 24))
		sheet.blend_rect(new_img.get_region(Rect2i(0, 0, spec.new.x, spec.new.y)), Rect2i(0, 0, spec.new.x, spec.new.y), Vector2i(x, y + 132))
		x += maxi(spec.new.x + 50, 180)
	y += 274
	for spec in VFX_SPECS:
		var row_h := maxi(280, int(spec.frame.y) + 32)
		_draw_checker(sheet, Rect2i(16, y, width - 32, row_h - 8), 16)
		var fighter := _fighter(String(spec.id).get_slice("_", 0))
		sheet.blend_rect(fighter, Rect2i(Vector2i.ZERO, fighter.get_size()), Vector2i(28, y + (row_h - 128) / 2))
		var old_strip := Image.load_from_file(OLD_DIR + String(spec.id) + ".png")
		var new_strip := Image.load_from_file(VFX_DIR + String(spec.id) + ".png")
		var old_size: Vector2i = spec.old
		var new_size: Vector2i = spec.frame
		var sample := int(spec.frames) / 2
		var old_frame := old_strip.get_region(Rect2i(sample * old_size.x, 0, old_size.x, old_size.y))
		old_frame.resize(new_size.x, new_size.y, Image.INTERPOLATE_NEAREST)
		var new_frame := new_strip.get_region(Rect2i(sample * new_size.x, 0, new_size.x, new_size.y))
		var start_x := 180
		sheet.blend_rect(old_frame, Rect2i(Vector2i.ZERO, old_frame.get_size()), Vector2i(start_x, y + (row_h - new_size.y) / 2))
		sheet.blend_rect(new_frame, Rect2i(Vector2i.ZERO, new_frame.get_size()), Vector2i(start_x + new_size.x + 48, y + (row_h - new_size.y) / 2))
		y += row_h
	return _save(sheet, REPORT_DIR + "comparison.png")

func _fighter(id: String) -> Image:
	var sheet := Image.load_from_file(FIGHTER_SHEETS[id])
	return sheet.get_region(Rect2i(0, 0, 128, 128))

func _draw_checker(image: Image, rect: Rect2i, cell_size: int) -> void:
	for py in range(rect.position.y, rect.end.y, cell_size):
		for px in range(rect.position.x, rect.end.x, cell_size):
			var parity := int((px - rect.position.x) / cell_size + (py - rect.position.y) / cell_size) % 2
			var color := Color("#10182A") if parity == 0 else Color("#0B1220")
			image.fill_rect(Rect2i(px, py, mini(cell_size, rect.end.x - px), mini(cell_size, rect.end.y - py)), color)

func _palette(id: String) -> Array[Color]:
	var colors: Array[Color] = []
	for html in PALETTES[id]:
		colors.append(Color(String(html)))
	return colors

func _save(image: Image, path: String) -> bool:
	var error := image.save_png(path)
	if error != OK:
		push_error("save failed: %s (%s)" % [path, error_string(error)])
		return false
	print("[fx-1x-build] %s %dx%d" % [path.get_file(), image.get_width(), image.get_height()])
	return true
