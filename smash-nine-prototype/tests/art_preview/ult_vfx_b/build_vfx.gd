extends SceneTree

const VFX_DIR := "res://assets/art/vfx/"
const REPORT_DIR := "res://../reports/codex-art-10/"
const ALPHA_CUTOFF := 0.16

const PALETTES := {
	"frey": ["#3A1909", "#78360D", "#B96012", "#E99B22", "#FFD34F", "#FFF0A1", "#FFFFFF"],
	"yuki": ["#071934", "#0C3F73", "#126DA1", "#20A9D0", "#75D8EB", "#C6F5F5", "#E94135", "#FFFFFF"],
	"luna": ["#24103F", "#5B207F", "#982CA2", "#E2349A", "#FF6FC6", "#FFC4E7", "#55DFF2", "#FFE278", "#FFFFFF"],
	"nova": ["#02070C", "#072630", "#07515D", "#078C92", "#25D7D0", "#8CF8EA", "#9B681A", "#E4AC2E", "#FFE77B", "#FFFFFF"],
	"rio": ["#07152E", "#0A2F62", "#0C5BA3", "#138ED0", "#2CC8F0", "#91EBFF", "#D7F8FF", "#FFFFFF"],
	"grey": ["#171A20", "#383D47", "#646B77", "#9299A4", "#C6CBD2", "#EBEDF0", "#FFFFFF"],
}

const SPECS := [
	{"id": "frey_ult_charge", "grid": Vector2i(3, 2), "frames": 6, "frame": Vector2i(128, 128), "margin": Vector2i(4, 4), "align": "bottom_center", "palette": "frey"},
	{"id": "frey_ult_wave", "grid": Vector2i(4, 2), "frames": 8, "frame": Vector2i(256, 96), "margin": Vector2i(3, 3), "align": "bottom_left", "palette": "frey"},
	{"id": "yuki_ult_seal", "grid": Vector2i(4, 2), "frames": 8, "frame": Vector2i(256, 256), "margin": Vector2i(5, 5), "align": "center", "palette": "yuki"},
	{"id": "yuki_ult_burst", "grid": Vector2i(3, 2), "frames": 6, "frame": Vector2i(256, 256), "margin": Vector2i(5, 5), "align": "center", "palette": "yuki"},
	{"id": "luna_ult_transform", "grid": Vector2i(4, 2), "frames": 8, "frame": Vector2i(192, 192), "margin": Vector2i(4, 4), "align": "center", "palette": "luna"},
	{"id": "luna_ult_laser", "grid": Vector2i(2, 2), "frames": 4, "frame": Vector2i(128, 96), "margin": Vector2i(0, 4), "align": "tile_x", "palette": "luna"},
	{"id": "luna_ult_laser_head", "grid": Vector2i(2, 2), "frames": 4, "frame": Vector2i(96, 96), "margin": Vector2i(4, 4), "align": "center", "palette": "luna"},
	{"id": "nova_ult_core", "grid": Vector2i(3, 2), "frames": 6, "frame": Vector2i(128, 128), "margin": Vector2i(4, 4), "align": "center", "palette": "nova"},
	{"id": "nova_ult_burst", "grid": Vector2i(4, 2), "frames": 8, "frame": Vector2i(256, 256), "margin": Vector2i(5, 5), "align": "center", "palette": "nova"},
	{"id": "rio_ult_circle", "grid": Vector2i(3, 2), "frames": 6, "frame": Vector2i(192, 192), "margin": Vector2i(4, 4), "align": "center", "palette": "rio"},
	{"id": "rio_ult_impact", "grid": Vector2i(3, 2), "frames": 6, "frame": Vector2i(64, 64), "margin": Vector2i(4, 4), "align": "center", "palette": "grey"},
]

const FIGHTER_SHEETS := {
	"frey": "res://assets/art/frey/frey_sheet.png",
	"yuki": "res://assets/art/yuki/yuki_sheet.png",
	"luna": "res://assets/art/luna/luna_brave_sheet.png",
	"nova": "res://assets/art/nova/nova_female_sheet.png",
	"rio": "res://assets/art/rio/rio_female_sheet.png",
}

func _init() -> void:
	for spec in SPECS:
		if not _build_strip(spec):
			quit(1)
			return
	if not _build_cutin_band():
		quit(1)
		return
	if not _build_contact_sheet():
		quit(1)
		return
	print("[ult-vfx-build] PASS effects=%d optional_cutin=1" % SPECS.size())
	quit()

func _build_strip(spec: Dictionary) -> bool:
	var asset_id := String(spec.id)
	var source := Image.load_from_file(VFX_DIR + asset_id + "_source.png")
	if source.is_empty():
		push_error("Could not load source for %s" % asset_id)
		return false
	var frame_size: Vector2i = spec.frame
	var grid: Vector2i = spec.grid
	var strip := Image.create(frame_size.x * int(spec.frames), frame_size.y, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0, 0, 0, 0))
	var palette := _palette(String(spec.palette))
	for frame_index in int(spec.frames):
		var column := frame_index % grid.x
		var row := frame_index / grid.x
		var x0 := roundi(float(column) * source.get_width() / grid.x)
		var x1 := roundi(float(column + 1) * source.get_width() / grid.x)
		var y0 := roundi(float(row) * source.get_height() / grid.y)
		var y1 := roundi(float(row + 1) * source.get_height() / grid.y)
		var source_frame := source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
		var frame := _fit_frame(source_frame, frame_size, spec.margin, String(spec.align), palette)
		strip.blit_rect(frame, Rect2i(Vector2i.ZERO, frame_size), Vector2i(frame_index * frame_size.x, 0))
	var path := VFX_DIR + asset_id + ".png"
	if strip.save_png(path) != OK:
		push_error("Could not save %s" % path)
		return false
	print("[ult-vfx-build] %s %dx%d frames=%d" % [asset_id, strip.get_width(), strip.get_height(), int(spec.frames)])
	return true

func _fit_frame(source: Image, canvas_size: Vector2i, margin: Vector2i, align: String, palette: Array[Color]) -> Image:
	var cleaned: Image = source.duplicate()
	_cleanup_alpha(cleaned)
	var output := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	output.fill(Color(0, 0, 0, 0))
	var used: Rect2i = cleaned.get_used_rect()
	if used.size == Vector2i.ZERO:
		return output
	var crop: Image = cleaned.get_region(used)
	var available := canvas_size - margin * 2
	var factor := minf(float(available.x) / crop.get_width(), float(available.y) / crop.get_height())
	var fitted := Vector2i(maxi(1, floori(crop.get_width() * factor)), maxi(1, floori(crop.get_height() * factor)))
	if align == "tile_x":
		fitted.x = canvas_size.x
	crop.resize(fitted.x, fitted.y, Image.INTERPOLATE_NEAREST)
	_quantize(crop, palette)
	var offset := Vector2i((canvas_size.x - fitted.x) / 2, (canvas_size.y - fitted.y) / 2)
	match align:
		"bottom_center":
			offset = Vector2i((canvas_size.x - fitted.x) / 2, canvas_size.y - margin.y - fitted.y)
		"bottom_left":
			offset = Vector2i(margin.x, canvas_size.y - margin.y - fitted.y)
		"tile_x":
			offset = Vector2i(0, (canvas_size.y - fitted.y) / 2)
	output.blit_rect(crop, Rect2i(Vector2i.ZERO, fitted), offset)
	if align == "tile_x":
		_make_horizontal_seam(output)
	return output

func _cleanup_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_CUTOFF:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
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
		var seam := left.lerp(right, 0.5)
		image.set_pixel(0, y, seam)
		image.set_pixel(image.get_width() - 1, y, seam)
		image.set_pixel(1, y, seam)
		image.set_pixel(image.get_width() - 2, y, seam)

func _build_cutin_band() -> bool:
	var source := Image.load_from_file(VFX_DIR + "ult_cutin_band_source.png")
	if source.is_empty():
		return false
	var band := _fit_frame(source, Vector2i(640, 112), Vector2i(4, 4), "center", _palette("grey"))
	return band.save_png(VFX_DIR + "ult_cutin_band.png") == OK

func _build_contact_sheet() -> bool:
	var row_heights: Array[int] = []
	var total_height := 24
	for spec in SPECS:
		var row_height := maxi(144, int(spec.frame.y) + 24)
		row_heights.append(row_height)
		total_height += row_height
	var contact := Image.create(1400, total_height, false, Image.FORMAT_RGBA8)
	contact.fill(Color("#070B14"))
	var y := 12
	for index in SPECS.size():
		var spec: Dictionary = SPECS[index]
		var row_height := row_heights[index]
		_draw_checker(contact, Rect2i(12, y, 1376, row_height - 8), 16)
		var fighter_id := String(spec.id).get_slice("_", 0)
		var fighter_sheet := Image.load_from_file(FIGHTER_SHEETS[fighter_id])
		var fighter := fighter_sheet.get_region(Rect2i(0, 0, 128, 128))
		contact.blend_rect(fighter, Rect2i(0, 0, 128, 128), Vector2i(28, y + (row_height - 128) / 2 - 4))
		var strip := Image.load_from_file(VFX_DIR + String(spec.id) + ".png")
		var frame_size: Vector2i = spec.frame
		var sample_indices := [0, int(spec.frames) / 2, int(spec.frames) - 1]
		var x := 190
		for frame_index in sample_indices:
			var frame := strip.get_region(Rect2i(frame_index * frame_size.x, 0, frame_size.x, frame_size.y))
			contact.blend_rect(frame, Rect2i(Vector2i.ZERO, frame_size), Vector2i(x, y + (row_height - frame_size.y) / 2 - 4))
			x += frame_size.x + 26
		y += row_height
	if contact.save_png(REPORT_DIR + "contact_sheet.png") != OK:
		push_error("Could not save contact sheet")
		return false
	return true

func _draw_checker(image: Image, rect: Rect2i, cell_size: int) -> void:
	for y in range(rect.position.y, rect.end.y, cell_size):
		for x in range(rect.position.x, rect.end.x, cell_size):
			var column := (x - rect.position.x) / cell_size
			var row := (y - rect.position.y) / cell_size
			var color := Color("#10182A") if int(column + row) % 2 == 0 else Color("#0B1220")
			image.fill_rect(Rect2i(x, y, mini(cell_size, rect.end.x - x), mini(cell_size, rect.end.y - y)), color)

func _palette(id: String) -> Array[Color]:
	var colors: Array[Color] = []
	for html in PALETTES[id]:
		colors.append(Color(String(html)))
	return colors
