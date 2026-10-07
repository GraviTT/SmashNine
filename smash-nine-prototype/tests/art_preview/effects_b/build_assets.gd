extends SceneTree

const PREVIEW_DIR := "res://tests/art_preview/effects_b/"
const EFFECT_DIR := "res://assets/art/effects/"
const UI_DIR := "res://assets/art/ui/"
const REPORT_PREVIEW := "res://../reports/codex-art-05b/preview.png"
const ALPHA_CUTOFF := 0.34

const EFFECT_SPECS := [
	{"id": "yuki_talisman", "size": Vector2i(32, 16), "work": Vector2i(30, 14), "palette": "yuki"},
	{"id": "luna_star", "size": Vector2i(24, 24), "work": Vector2i(21, 21), "palette": "luna"},
	{"id": "rio_mana_wave", "size": Vector2i(24, 56), "work": Vector2i(22, 54), "palette": "rio"},
	{"id": "rio_gem_sword", "size": Vector2i(48, 16), "work": Vector2i(46, 14), "palette": "grey"},
	{"id": "nova_gravity_orb", "size": Vector2i(32, 32), "work": Vector2i(29, 29), "palette": "nova"},
]

const CARD_IDS := ["power", "vitality", "swiftness", "anchor", "sky_step", "last_stand"]

const PALETTES := {
	"spark": ["#0B1026", "#654219", "#A86C20", "#E4A72B", "#FFD86B", "#FFF0B0", "#FFFFFF"],
	"yuki": ["#10132C", "#3A2032", "#7B2832", "#C63B32", "#D99B43", "#E8D1A5", "#FFF4D7", "#FFFFFF"],
	"luna": ["#171631", "#4A207A", "#8C2CB2", "#E34B9C", "#FF78BE", "#75D7F4", "#C9F4FF", "#FFE067", "#FFFFFF"],
	"rio": ["#10172A", "#15295B", "#164E8B", "#147FB2", "#28BCE0", "#5BEAFF", "#BDEFFF", "#FFFFFF"],
	"grey": ["#0D1326", "#263047", "#465269", "#727F93", "#AAB4C2", "#DDE5ED", "#FFFFFF"],
	"nova": ["#0A1027", "#171A53", "#2F2D8C", "#0A6479", "#12B5B7", "#78E8DE", "#C99025", "#F4C84E", "#FFFFFF"],
	"power": ["#0D1328", "#303B51", "#657187", "#B7C0CA", "#F2E9D4", "#8F251E", "#D43C24", "#F08C24", "#FFD36A"],
	"vitality": ["#0D1328", "#5A1527", "#9E2034", "#E33D50", "#FF776B", "#244A35", "#4D7B3C", "#9DBC4D", "#F4C64E", "#FFF3D1"],
	"swiftness": ["#0D1632", "#33445F", "#687993", "#A8B6C7", "#E9EEF4", "#147CB0", "#25C1E8", "#9BE9F4", "#FFFFFF"],
	"anchor": ["#0B1026", "#273247", "#4A586D", "#78879A", "#B8C3CE", "#20256E", "#4A43C5", "#4CBAD3", "#EAF5F4"],
	"sky_step": ["#0D1531", "#49367B", "#8E7CC7", "#287DBF", "#53B9E5", "#A7E8F5", "#EAF7F8", "#FFFFFF"],
	"last_stand": ["#0C1027", "#30384E", "#535E72", "#7E8999", "#BBC4CE", "#58208C", "#9A2FC5", "#E34BD3", "#FFF0FA"],
}

func _init() -> void:
	if not _build_hit_spark():
		quit(1)
		return
	for spec in EFFECT_SPECS:
		if not _build_single_effect(spec):
			quit(1)
			return
	for card_id in CARD_IDS:
		if not _build_card(card_id):
			quit(1)
			return
	if not _build_preview() or not _verify_outputs():
		quit(1)
		return
	print("[effects-b] PASS effects=6 cards=6 preview=960x600")
	quit()

func _build_hit_spark() -> bool:
	var source := Image.load_from_file(PREVIEW_DIR + "source_hit_spark.png")
	if source.is_empty():
		push_error("Could not load hit spark source")
		return false
	var strip := Image.create(192, 48, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0, 0, 0, 0))
	for frame_index in range(4):
		var x0 := roundi(float(frame_index) * source.get_width() / 4.0)
		var x1 := roundi(float(frame_index + 1) * source.get_width() / 4.0)
		var frame := source.get_region(Rect2i(x0, 0, x1 - x0, source.get_height()))
		frame = _fit_pixel_asset(frame, Vector2i(48, 48), Vector2i(42, 42), _palette("spark"))
		strip.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(frame_index * 48, 0))
	return _save(strip, EFFECT_DIR + "hit_spark.png")

func _build_single_effect(spec: Dictionary) -> bool:
	var asset_id := String(spec.id)
	var source := Image.load_from_file(PREVIEW_DIR + "source_" + asset_id + ".png")
	if source.is_empty():
		push_error("Could not load source for %s" % asset_id)
		return false
	var output := _fit_pixel_asset(source, spec.size, spec.work, _palette(String(spec.palette)))
	return _save(output, EFFECT_DIR + asset_id + ".png")

func _build_card(card_id: String) -> bool:
	var source := Image.load_from_file(PREVIEW_DIR + "source_card_" + card_id + ".png")
	if source.is_empty():
		push_error("Could not load card source for %s" % card_id)
		return false
	var output := _fit_pixel_asset(source, Vector2i(48, 48), Vector2i(42, 42), _palette(card_id))
	return _save(output, UI_DIR + "card_" + card_id + ".png")

func _fit_pixel_asset(source: Image, canvas_size: Vector2i, work_size: Vector2i, palette: Array[Color]) -> Image:
	var cleaned: Image = source.duplicate()
	_cleanup_alpha(cleaned)
	var used: Rect2i = cleaned.get_used_rect()
	var output := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	output.fill(Color(0, 0, 0, 0))
	if used.size == Vector2i.ZERO:
		return output
	var crop: Image = cleaned.get_region(used)
	var factor := minf(float(work_size.x) / crop.get_width(), float(work_size.y) / crop.get_height())
	var fitted := Vector2i(maxi(1, roundi(crop.get_width() * factor)), maxi(1, roundi(crop.get_height() * factor)))
	crop.resize(fitted.x, fitted.y, Image.INTERPOLATE_NEAREST)
	_quantize(crop, palette)
	var offset := Vector2i((canvas_size.x - fitted.x) / 2, (canvas_size.y - fitted.y) / 2)
	output.blit_rect(crop, Rect2i(Vector2i.ZERO, fitted), offset)
	return output

func _cleanup_alpha(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_CUTOFF or maxf(color.r, maxf(color.g, color.b)) < 0.025:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				color.a = 1.0
				image.set_pixel(x, y, color)

func _quantize(image: Image, palette: Array[Color]) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var source_color := image.get_pixel(x, y)
			if source_color.a == 0.0:
				continue
			var best := palette[0]
			var best_distance := INF
			for candidate in palette:
				var dr := source_color.r - candidate.r
				var dg := source_color.g - candidate.g
				var db := source_color.b - candidate.b
				var distance := dr * dr + dg * dg + db * db
				if distance < best_distance:
					best_distance = distance
					best = candidate
			image.set_pixel(x, y, Color(best.r, best.g, best.b, 1.0))

func _palette(palette_id: String) -> Array[Color]:
	var colors: Array[Color] = []
	for html in PALETTES[palette_id]:
		colors.append(Color(String(html)))
	return colors

func _build_preview() -> bool:
	var preview := Image.create(960, 600, false, Image.FORMAT_RGBA8)
	preview.fill(Color("#080B15"))
	_draw_checker(preview, Rect2i(20, 20, 920, 560), 16)
	var frey_sheet := Image.load_from_file("res://assets/art/frey/frey_sheet.png")
	var frey := frey_sheet.get_region(Rect2i(0, 0, 64, 64))
	frey.resize(128, 128, Image.INTERPOLATE_NEAREST)
	preview.blend_rect(frey, Rect2i(0, 0, 128, 128), Vector2i(30, 52))

	var spark := Image.load_from_file(EFFECT_DIR + "hit_spark.png")
	for index in range(4):
		var frame := spark.get_region(Rect2i(index * 48, 0, 48, 48))
		frame.resize(96, 96, Image.INTERPOLATE_NEAREST)
		preview.blend_rect(frame, Rect2i(0, 0, 96, 96), Vector2i(180 + index * 118, 58))

	var effect_x := 58
	for spec in EFFECT_SPECS:
		var effect := Image.load_from_file(EFFECT_DIR + String(spec.id) + ".png")
		effect.resize(effect.get_width() * 2, effect.get_height() * 2, Image.INTERPOLATE_NEAREST)
		var y := 250 + (112 - effect.get_height()) / 2
		preview.blend_rect(effect, Rect2i(Vector2i.ZERO, effect.get_size()), Vector2i(effect_x, y))
		effect_x += maxi(effect.get_width() + 72, 145)

	var card_x := 170
	for card_id in CARD_IDS:
		var card := Image.load_from_file(UI_DIR + "card_" + card_id + ".png")
		preview.blend_rect(card, Rect2i(0, 0, 48, 48), Vector2i(card_x, 462))
		card_x += 112
	return _save(preview, REPORT_PREVIEW)

func _draw_checker(image: Image, rect: Rect2i, cell_size: int) -> void:
	for y in range(rect.position.y, rect.end.y, cell_size):
		for x in range(rect.position.x, rect.end.x, cell_size):
			var column := (x - rect.position.x) / cell_size
			var row := (y - rect.position.y) / cell_size
			var color := Color("#11182A") if int(column + row) % 2 == 0 else Color("#0D1322")
			image.fill_rect(Rect2i(x, y, mini(cell_size, rect.end.x - x), mini(cell_size, rect.end.y - y)), color)

func _verify_outputs() -> bool:
	var expected := {
		EFFECT_DIR + "hit_spark.png": Vector2i(192, 48),
		EFFECT_DIR + "yuki_talisman.png": Vector2i(32, 16),
		EFFECT_DIR + "luna_star.png": Vector2i(24, 24),
		EFFECT_DIR + "rio_mana_wave.png": Vector2i(24, 56),
		EFFECT_DIR + "rio_gem_sword.png": Vector2i(48, 16),
		EFFECT_DIR + "nova_gravity_orb.png": Vector2i(32, 32),
	}
	for card_id in CARD_IDS:
		expected[UI_DIR + "card_" + card_id + ".png"] = Vector2i(48, 48)
	for path in expected:
		var image := Image.load_from_file(path)
		if image.is_empty() or image.get_size() != expected[path] or image.get_format() != Image.FORMAT_RGBA8:
			push_error("Verification failed: %s size=%s format=%s" % [path, image.get_size(), image.get_format()])
			return false
		var used := image.get_used_rect()
		if used.size == Vector2i.ZERO or used.position.x < 1 or used.position.y < 1 or used.end.x >= image.get_width() or used.end.y >= image.get_height():
			push_error("Unsafe transparent padding: %s used=%s" % [path, used])
			return false
		print("[effects-b-verify] %s size=%dx%d used=%s" % [path.get_file(), image.get_width(), image.get_height(), used])
	return true

func _save(image: Image, path: String) -> bool:
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error_string(error)])
		return false
	return true
