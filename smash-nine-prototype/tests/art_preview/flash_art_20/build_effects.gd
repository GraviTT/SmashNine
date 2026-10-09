extends SceneTree
## CODEX-ART-20: ImageGen source strips -> exact-size binary-alpha game strips.
## All pixel transforms use Godot's Image API; no external image package is required.

const REPORT_RELATIVE := "../reports/codex-art-20"
const EFFECT_DIR := "res://assets/art/effects"
const SPECS := {
	"parry_flash": {"frames": 6, "cell": Vector2i(128, 128), "fit": Vector2i(116, 116), "anchor": Vector2i(64, 64), "bottom": false, "palette": ["151B35", "9B5D18", "E7A52A", "FFD85B", "FFF2AE", "FFFFFF"]},
	"landing_dust": {"frames": 5, "cell": Vector2i(96, 32), "fit": Vector2i(84, 25), "anchor": Vector2i(48, 31), "bottom": true, "palette": ["182038", "4C4A50", "77716C", "A9A098", "D7CEC2", "FFF4DF"]},
	"hit_streak": {"frames": 4, "cell": Vector2i(160, 24), "fit": Vector2i(148, 18), "anchor": Vector2i(80, 12), "bottom": false, "palette": ["9B5D18", "E7A52A", "FFD85B", "FFF2AE", "FFFFFF"]},
	"yuki_seal_break": {"frames": 5, "cell": Vector2i(96, 96), "fit": Vector2i(82, 84), "anchor": Vector2i(48, 48), "bottom": false, "palette": ["151B35", "324369", "328BC5", "74D8F2", "9C2D28", "DC4A32", "D8B96B", "F4E5B8", "FFF8DE", "FFFFFF"]},
}

func _initialize() -> void:
	var report_abs := ProjectSettings.globalize_path("res://").path_join(REPORT_RELATIVE)
	DirAccess.make_dir_recursive_absolute(report_abs.path_join("contact"))
	var lines: Array[String] = []
	lines.append("CODEX-ART-20 generated strip verification")
	for name: String in SPECS:
		var spec: Dictionary = SPECS[name]
		var source_path := report_abs.path_join("source/%s_source.png" % name)
		var source := Image.load_from_file(source_path)
		if source == null or source.is_empty():
			push_error("Missing source for %s" % name)
			quit(1)
			return
		var strip := _build_strip(source, spec)
		var out_path := "%s/%s.png" % [EFFECT_DIR, name]
		strip.save_png(out_path)
		_build_contact(strip, spec, report_abs.path_join("contact/%s_contact.png" % name))
		lines.append(_measure(name, strip, spec))
	FileAccess.open(report_abs.path_join("verification.txt"), FileAccess.WRITE).store_string("\n".join(lines) + "\n")
	print("\n".join(lines))
	quit(0)

func _build_strip(source: Image, spec: Dictionary) -> Image:
	var count: int = spec.frames
	var cell: Vector2i = spec.cell
	var result := Image.create(cell.x * count, cell.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	var palette := _palette(spec.palette)
	for frame in count:
		var left := int(floor(float(frame) * source.get_width() / count))
		var right := int(floor(float(frame + 1) * source.get_width() / count))
		var part := source.get_region(Rect2i(left, 0, right - left, source.get_height()))
		var used := _opaque_rect(part, 0.12)
		if used.size == Vector2i.ZERO:
			continue
		part = part.get_region(used)
		var fit: Vector2i = spec.fit
		var scale := minf(float(fit.x) / part.get_width(), float(fit.y) / part.get_height())
		var size := Vector2i(maxi(1, int(round(part.get_width() * scale))), maxi(1, int(round(part.get_height() * scale))))
		part.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
		_quantize(part, palette, 0.18)
		var anchor: Vector2i = spec.anchor
		var pos := Vector2i(frame * cell.x + anchor.x - size.x / 2, anchor.y - size.y / 2)
		if bool(spec.bottom):
			pos.y = anchor.y - size.y
		result.blit_rect(part, Rect2i(Vector2i.ZERO, size), pos)
	return result

func _opaque_rect(image: Image, cutoff: float) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= cutoff:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _palette(hexes: Array) -> Array[Color]:
	var colors: Array[Color] = []
	for value in hexes:
		colors.append(Color.from_string(str(value), Color.WHITE))
	return colors

func _quantize(image: Image, palette: Array[Color], cutoff: float) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var source := image.get_pixel(x, y)
			if source.a < cutoff:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var best: Color = palette[0]
			var distance := INF
			for candidate in palette:
				var d := pow(source.r - candidate.r, 2) + pow(source.g - candidate.g, 2) + pow(source.b - candidate.b, 2)
				if d < distance:
					distance = d
					best = candidate
			image.set_pixel(x, y, Color(best.r, best.g, best.b, 1.0))

func _build_contact(strip: Image, spec: Dictionary, path: String) -> void:
	var bg_colors := [Color("1A1F2E"), Color("7A8899")]
	var one_h := strip.get_height()
	var four := strip.duplicate()
	four.resize(strip.get_width() * 4, strip.get_height() * 4, Image.INTERPOLATE_NEAREST)
	var width: int = four.get_width() + 32
	var panel_h: int = one_h + four.get_height() + 48
	var contact := Image.create(width, panel_h * 2, false, Image.FORMAT_RGBA8)
	for panel in 2:
		contact.fill_rect(Rect2i(0, panel * panel_h, width, panel_h), bg_colors[panel])
		contact.blend_rect(strip, Rect2i(0, 0, strip.get_width(), strip.get_height()), Vector2i(16, panel * panel_h + 12))
		contact.blend_rect(four, Rect2i(0, 0, four.get_width(), four.get_height()), Vector2i(16, panel * panel_h + one_h + 28))
	contact.save_png(path)

func _measure(name: String, strip: Image, spec: Dictionary) -> String:
	var cell: Vector2i = spec.cell
	var margins: Array[String] = []
	var alpha_values := {}
	var colors := {}
	for x in strip.get_width():
		for y in strip.get_height():
			var c := strip.get_pixel(x, y)
			alpha_values[int(round(c.a * 255.0))] = true
			if c.a > 0.0:
				colors[c.to_html(false)] = true
	for frame in int(spec.frames):
		var region := strip.get_region(Rect2i(frame * cell.x, 0, cell.x, cell.y))
		var used := _opaque_rect(region, 0.5)
		margins.append("f%d=%d/%d/%d/%d" % [frame, used.position.x, used.position.y, cell.x - used.end.x, cell.y - used.end.y])
	return "%s size=%dx%d frames=%d cell=%dx%d format=RGBA8 alpha=%s colors=%d margins(L/T/R/B)=%s" % [name, strip.get_width(), strip.get_height(), spec.frames, cell.x, cell.y, str(alpha_values.keys()), colors.size(), ", ".join(margins)]
