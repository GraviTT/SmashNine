extends SceneTree

const ROOT := "res://"
const MONSTERS := ROOT + "assets/art/monsters/"
const OBJECTS := ROOT + "assets/art/objects/"
const REPORT := ROOT + "../reports/codex-art-11/"

const TARGETS := [
	{"name": "mossling", "source": REPORT + "old_mossling_sheet.png", "path": MONSTERS + "mossling_sheet.png", "cols": 6, "rows": 4, "src_cell": Vector2i(64, 64), "dst_cell": Vector2i(96, 96), "palette": 28},
	{"name": "ember_imp", "source": REPORT + "old_ember_imp_sheet.png", "path": MONSTERS + "ember_imp_sheet.png", "cols": 6, "rows": 4, "src_cell": Vector2i(64, 64), "dst_cell": Vector2i(96, 96), "palette": 26},
	{"name": "fireball", "source": REPORT + "old_ember_fireball.png", "path": MONSTERS + "ember_fireball.png", "cols": 1, "rows": 1, "src_cell": Vector2i(24, 24), "dst_cell": Vector2i(36, 36), "palette": 12},
	{"name": "soul_crystal", "source": REPORT + "old_soul_crystal.png", "path": OBJECTS + "soul_crystal.png", "cols": 4, "rows": 1, "src_cell": Vector2i(48, 64), "dst_cell": Vector2i(72, 96), "palette": 24},
	{"name": "soul_crystal_shatter", "source": REPORT + "old_soul_crystal_shatter.png", "path": OBJECTS + "soul_crystal_shatter.png", "cols": 4, "rows": 1, "src_cell": Vector2i(48, 64), "dst_cell": Vector2i(72, 96), "palette": 24},
]


func _init() -> void:
	for spec: Dictionary in TARGETS:
		_rebuild(spec)
	_make_preview()
	quit()


func _rebuild(spec: Dictionary) -> void:
	var path: String = spec.path
	var source := Image.load_from_file(spec.source)
	if source.is_empty():
		push_error("Could not load: %s" % path)
		return
	var palette := _dominant_palette(source, spec.palette)
	var cols: int = spec.cols
	var rows: int = spec.rows
	var src_cell: Vector2i = spec.src_cell
	var dst_cell: Vector2i = spec.dst_cell
	var output := Image.create(dst_cell.x * cols, dst_cell.y * rows, false, Image.FORMAT_RGBA8)
	output.fill(Color(0, 0, 0, 0))
	for row in rows:
		for col in cols:
			var frame := source.get_region(Rect2i(col * src_cell.x, row * src_cell.y, src_cell.x, src_cell.y))
			frame.resize(dst_cell.x, dst_cell.y, Image.INTERPOLATE_LANCZOS)
			_quantize_frame(frame, palette)
			frame = _normalize_frame(frame, spec.name)
			output.blit_rect(frame, Rect2i(Vector2i.ZERO, dst_cell), Vector2i(col * dst_cell.x, row * dst_cell.y))
	var err := output.save_png(path)
	if err != OK:
		push_error("Could not save %s: %s" % [path, err])
	else:
		print("BUILT %s %dx%d palette=%d" % [path, output.get_width(), output.get_height(), palette.size()])


func _dominant_palette(image: Image, maximum: int) -> Array[Color]:
	var counts: Dictionary = {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := color.to_rgba32()
			counts[key] = counts.get(key, 0) + 1
	var keys := counts.keys()
	keys.sort_custom(func(a: int, b: int) -> bool: return counts[a] > counts[b])
	var palette: Array[Color] = []
	for i in mini(maximum, keys.size()):
		palette.append(Color.hex(keys[i]))
	return palette


func _quantize_frame(image: Image, palette: Array[Color]) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.42:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var best := palette[0]
			var best_distance := INF
			for candidate: Color in palette:
				var dr := color.r - candidate.r
				var dg := color.g - candidate.g
				var db := color.b - candidate.b
				var distance := dr * dr * 0.28 + dg * dg * 0.56 + db * db * 0.16
				if distance < best_distance:
					best_distance = distance
					best = candidate
			image.set_pixel(x, y, Color(best.r, best.g, best.b, 1.0))


func _normalize_frame(frame: Image, name: String) -> Image:
	var rect := frame.get_used_rect()
	if rect.size == Vector2i.ZERO:
		return frame
	var content := frame.get_region(rect)
	var max_width := frame.get_width() - 8
	var max_height := frame.get_height() - 8
	var baseline := frame.get_height() - 5
	if name == "mossling" or name == "ember_imp":
		max_height = 69
		baseline = 72
	elif name.begins_with("soul_crystal"):
		max_height = 81
		baseline = 84
	var scale := minf(1.0, minf(float(max_width) / content.get_width(), float(max_height) / content.get_height()))
	if scale < 1.0:
		content.resize(maxi(1, roundi(content.get_width() * scale)), maxi(1, roundi(content.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
		_quantize_frame(content, _dominant_palette(frame, 32))
	var result := Image.create(frame.get_width(), frame.get_height(), false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	var x := (frame.get_width() - content.get_width()) / 2
	var y := baseline - content.get_height() + 1
	result.blit_rect(content, Rect2i(Vector2i.ZERO, content.get_size()), Vector2i(x, y))
	return result


func _make_preview() -> void:
	var canvas := Image.create(1800, 1200, false, Image.FORMAT_RGBA8)
	canvas.fill(Color("09131f"))
	var old_moss := Image.load_from_file(REPORT + "old_mossling_sheet.png")
	var old_imp := Image.load_from_file(REPORT + "old_ember_imp_sheet.png")
	old_moss.resize(576, 384, Image.INTERPOLATE_NEAREST)
	old_imp.resize(576, 384, Image.INTERPOLATE_NEAREST)
	var new_moss := Image.load_from_file(MONSTERS + "mossling_sheet.png")
	var new_imp := Image.load_from_file(MONSTERS + "ember_imp_sheet.png")
	_blit_with_panel(canvas, old_moss, Vector2i(24, 24), Vector2i(600, 408))
	_blit_with_panel(canvas, new_moss, Vector2i(624, 24), Vector2i(600, 408))
	_blit_with_panel(canvas, old_imp, Vector2i(24, 432), Vector2i(600, 408))
	_blit_with_panel(canvas, new_imp, Vector2i(624, 432), Vector2i(600, 408))

	var frey := Image.load_from_file(ROOT + "assets/art/frey/frey_sheet.png")
	var frey_frame := frey.get_region(Rect2i(0, 0, 96, 96))
	_blit_with_panel(canvas, frey_frame, Vector2i(1248, 24), Vector2i(120, 120))

	var crystal := Image.load_from_file(OBJECTS + "soul_crystal.png")
	var shatter := Image.load_from_file(OBJECTS + "soul_crystal_shatter.png")
	var fireball := Image.load_from_file(MONSTERS + "ember_fireball.png")
	_blit_with_panel(canvas, crystal, Vector2i(1248, 168), Vector2i(312, 120))
	_blit_with_panel(canvas, shatter, Vector2i(1248, 312), Vector2i(312, 120))
	fireball.resize(108, 108, Image.INTERPOLATE_NEAREST)
	_blit_with_panel(canvas, fireball, Vector2i(1248, 456), Vector2i(132, 132))
	canvas.save_png(REPORT + "preview.png")


func _blit_with_panel(canvas: Image, image: Image, position: Vector2i, panel_size: Vector2i) -> void:
	canvas.fill_rect(Rect2i(position, panel_size), Color("102132"))
	canvas.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), position + Vector2i(12, 12))
