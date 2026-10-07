extends SceneTree

const SOURCE := "res://tests/art_preview/hazards_a/source_hazards.png"
const OUTPUT_DIR := "res://assets/art/hazards"
const REPORT_DIR := "res://../reports/codex-art-07"
const PREVIEW_SIZE := Vector2i(2560, 1440)

const VANA_PALETTE := [
	"04110e", "071a16", "0b251e", "103129", "153e32", "1b4d3b", "235d45",
	"2d6f4f", "39825a", "489565", "5ba972", "70bd7e", "88cf91", "78965c",
	"a3ad62", "d4c46f"
]
const ASGARD_PALETTE := [
	"07101b", "0d1928", "142438", "1d3045", "263b51", "314b62", "45627a",
	"59758b", "71899b", "8da9b8", "a9b8bf", "d1d5cf", "805b2e", "a87534",
	"c88d3d", "d69a42", "e3ad55", "f0c06c", "ffe49a", "fff6d2"
]
const FIRE_PALETTE := [
	"10070a", "19090c", "250d10", "321116", "43151a", "581b1d", "702321",
	"8b2d24", "a83a27", "c64a29", "e35e2c", "f47b35", "ff9a45", "ffbd55",
	"ffe07a", "fff2b0", "2a1b22", "3c2730", "56333a"
]


func _initialize() -> void:
	call_deferred("_build")


func _build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	var source := _load(SOURCE)
	var size := source.get_size()
	var vine_source := _extract(source, Rect2i(int(size.x * 0.02), int(size.y * 0.13), int(size.x * 0.48), int(size.y * 0.23)))
	var light_source := _extract(source, Rect2i(int(size.x * 0.52), 0, int(size.x * 0.20), int(size.y * 0.45)))
	var fire_source := _extract(source, Rect2i(int(size.x * 0.10), int(size.y * 0.35), int(size.x * 0.25), int(size.y * 0.48)))
	var glyph_source := _extract(source, Rect2i(int(size.x * 0.39), int(size.y * 0.53), int(size.x * 0.44), int(size.y * 0.17)))
	print("SOURCE_REGIONS sheet=", size, " vine=", vine_source.get_size(), " light=", light_source.get_size(), " fire=", fire_source.get_size(), " glyph=", glyph_source.get_size())

	var vine := _build_vine(vine_source)
	var light := _build_vertical_tile(light_source, _palette(ASGARD_PALETTE), 0.18, 0.78)
	var fire := _build_vertical_tile(fire_source, _palette(FIRE_PALETTE), 0.16, 0.78)
	var glyph := _build_glyph(glyph_source)

	_save(vine, OUTPUT_DIR + "/vine_bridge.png")
	_save(light, OUTPUT_DIR + "/light_beam.png")
	_save(fire, OUTPUT_DIR + "/fire_pillar.png")
	_save(glyph, OUTPUT_DIR + "/vent_glyph.png")
	_save(_compose_preview(vine, light, fire, glyph), REPORT_DIR + "/hazards_preview.png")
	print("HAZARD_BUILD_OK vine=", vine.get_size(), " light=", light.get_size(), " fire=", fire.get_size(), " glyph=", glyph.get_size(), " preview=", PREVIEW_SIZE)
	quit()


func _load(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		push_error("Unable to load: " + path)
		quit(1)
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _extract(source: Image, rect: Rect2i) -> Image:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, source.get_size()))
	var region := source.get_region(clipped)
	var used := region.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		push_error("Generated source region is empty: " + str(rect))
		quit(1)
		return region
	return region.get_region(used)


func _build_vine(source: Image) -> Image:
	var width := source.get_width()
	var height := source.get_height()
	var left := source.get_region(Rect2i(0, 0, maxi(1, int(width * 0.19)), height))
	var middle_width := maxi(1, int(width * 0.26))
	var middle := source.get_region(Rect2i((width - middle_width) / 2, 0, middle_width, height))
	var right := source.get_region(Rect2i(width - maxi(1, int(width * 0.19)), 0, maxi(1, int(width * 0.19)), height))
	left.resize(12, 12, Image.INTERPOLATE_LANCZOS)
	middle.resize(24, 12, Image.INTERPOLATE_LANCZOS)
	right.resize(12, 12, Image.INTERPOLATE_LANCZOS)
	_reduce_palette(left, _palette(VANA_PALETTE))
	_reduce_palette(middle, _palette(VANA_PALETTE))
	_reduce_palette(right, _palette(VANA_PALETTE))
	_make_horizontal_seamless(middle)
	_match_cap(left, middle, true)
	_match_cap(right, middle, false)
	var strip := Image.create(48, 12, false, Image.FORMAT_RGBA8)
	strip.fill(Color.TRANSPARENT)
	strip.blend_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), Vector2i.ZERO)
	strip.blend_rect(middle, Rect2i(Vector2i.ZERO, middle.get_size()), Vector2i(12, 0))
	strip.blend_rect(right, Rect2i(Vector2i.ZERO, right.get_size()), Vector2i(36, 0))
	strip.resize(96, 24, Image.INTERPOLATE_NEAREST)
	return strip


func _build_vertical_tile(source: Image, palette: Array[Color], start_ratio: float, end_ratio: float) -> Image:
	var start_y := int(source.get_height() * start_ratio)
	var region_height := maxi(1, int(source.get_height() * (end_ratio - start_ratio)))
	var core := source.get_region(Rect2i(0, start_y, source.get_width(), mini(region_height, source.get_height() - start_y)))
	core.resize(32, 64, Image.INTERPOLATE_LANCZOS)
	_reduce_palette(core, palette)
	_make_vertical_seamless(core)
	core.resize(64, 128, Image.INTERPOLATE_NEAREST)
	return core


func _build_glyph(_source: Image) -> Image:
	var glyph := Image.create(40, 8, false, Image.FORMAT_RGBA8)
	glyph.fill(Color.TRANSPARENT)
	var shadow := Color("43151a")
	var ember := Color("a83a27")
	var orange := Color("f47b35")
	var gold := Color("ffbd55")
	for x in range(3, 37):
		glyph.set_pixel(x, 3, shadow)
		glyph.set_pixel(x, 4, shadow)
	for x in range(5, 35):
		glyph.set_pixel(x, 3, orange)
	for x in range(7, 33):
		glyph.set_pixel(x, 4, ember)
	_draw_diamond(glyph, Vector2i(20, 3), 3, gold, orange)
	_draw_diamond(glyph, Vector2i(12, 3), 2, orange, gold)
	_draw_diamond(glyph, Vector2i(28, 3), 2, orange, gold)
	for offset in 4:
		glyph.set_pixel(3 + offset, 3 - mini(offset, 2), orange)
		glyph.set_pixel(3 + offset, 4 + mini(offset, 2), ember)
		glyph.set_pixel(36 - offset, 3 - mini(offset, 2), orange)
		glyph.set_pixel(36 - offset, 4 + mini(offset, 2), ember)
	for point in [Vector2i(1, 3), Vector2i(38, 3), Vector2i(20, 0), Vector2i(20, 7)]:
		var glow := gold
		glow.a = 0.5
		glyph.set_pixelv(point, glow)
	glyph.resize(80, 16, Image.INTERPOLATE_NEAREST)
	return glyph


func _draw_diamond(image: Image, center: Vector2i, radius: int, border: Color, core: Color) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			var distance := absi(x - center.x) + absi(y - center.y)
			if distance == radius:
				image.set_pixel(x, y, border)
			elif distance < radius:
				image.set_pixel(x, y, core)


func _palette(values: Array) -> Array[Color]:
	var result: Array[Color] = []
	for value in values:
		result.append(Color(str(value)))
	return result


func _reduce_palette(image: Image, palette: Array[Color]) -> void:
	var cache: Dictionary = {}
	for y in image.get_height():
		for x in image.get_width():
			var source := image.get_pixel(x, y)
			if source.a < 0.12:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
			var key := (int(source.r * 255.0) << 16) | (int(source.g * 255.0) << 8) | int(source.b * 255.0)
			var mapped: Color = cache.get(key, Color.TRANSPARENT)
			if mapped == Color.TRANSPARENT:
				mapped = _nearest(source, palette)
				cache[key] = mapped
			mapped.a = 1.0 if source.a >= 0.62 else 0.5
			image.set_pixel(x, y, mapped)


func _nearest(source: Color, palette: Array[Color]) -> Color:
	var best := palette[0]
	var best_distance := INF
	for candidate in palette:
		var dr := source.r - candidate.r
		var dg := source.g - candidate.g
		var db := source.b - candidate.b
		var distance := dr * dr * 0.30 + dg * dg * 0.59 + db * db * 0.11
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


func _make_horizontal_seamless(image: Image) -> void:
	for y in image.get_height():
		var seam := image.get_pixel(0, y).lerp(image.get_pixel(image.get_width() - 1, y), 0.5)
		image.set_pixel(0, y, seam)
		image.set_pixel(image.get_width() - 1, y, seam)
		var near := image.get_pixel(1, y).lerp(image.get_pixel(image.get_width() - 2, y), 0.5)
		image.set_pixel(1, y, near)
		image.set_pixel(image.get_width() - 2, y, near)


func _make_vertical_seamless(image: Image) -> void:
	for x in image.get_width():
		var seam := image.get_pixel(x, 0).lerp(image.get_pixel(x, image.get_height() - 1), 0.5)
		image.set_pixel(x, 0, seam)
		image.set_pixel(x, image.get_height() - 1, seam)
		var near := image.get_pixel(x, 1).lerp(image.get_pixel(x, image.get_height() - 2), 0.5)
		image.set_pixel(x, 1, near)
		image.set_pixel(x, image.get_height() - 2, near)


func _match_cap(cap: Image, middle: Image, is_left: bool) -> void:
	var cap_x := cap.get_width() - 1 if is_left else 0
	var middle_x := 0 if is_left else middle.get_width() - 1
	for y in cap.get_height():
		cap.set_pixel(cap_x, y, middle.get_pixel(middle_x, y))


func _compose_preview(vine: Image, light: Image, fire: Image, glyph: Image) -> Image:
	var preview := Image.create(PREVIEW_SIZE.x, PREVIEW_SIZE.y, false, Image.FORMAT_RGBA8)
	preview.fill(Color("05080d"))
	var vana := _realm_panel("vanaheim")
	var asgard := _realm_panel("asgard")
	var muspel := _realm_panel("muspelheim")
	_draw_realm_platform(vana, "vanaheim", Rect2i(150, 620, 980, 46))
	_draw_three_slice(vana, vine, Rect2i(430, 430, 420, 24), 24, 48)
	_draw_realm_platform(asgard, "asgard", Rect2i(150, 620, 980, 52))
	asgard.blend_rect(glyph, Rect2i(Vector2i.ZERO, glyph.get_size()), Vector2i(600, 604))
	_draw_vertical(asgard, light, Rect2i(605, 144, 70, 460))
	_draw_realm_platform(muspel, "muspelheim", Rect2i(150, 620, 980, 52))
	muspel.blend_rect(glyph, Rect2i(Vector2i.ZERO, glyph.get_size()), Vector2i(600, 604))
	_draw_vertical(muspel, fire, Rect2i(600, 144, 80, 460))
	preview.blit_rect(vana, Rect2i(Vector2i.ZERO, vana.get_size()), Vector2i.ZERO)
	preview.blit_rect(asgard, Rect2i(Vector2i.ZERO, asgard.get_size()), Vector2i(1280, 0))
	preview.blit_rect(muspel, Rect2i(Vector2i.ZERO, muspel.get_size()), Vector2i(0, 720))
	_draw_asset_panel(preview, Rect2i(1280, 720, 1280, 720), vine, light, fire, glyph)
	return preview


func _realm_panel(slug: String) -> Image:
	var far := _load("res://assets/art/realm_%s/bg_far.png" % slug)
	var mid := _load("res://assets/art/realm_%s/bg_mid.png" % slug)
	far.blend_rect(mid, Rect2i(Vector2i.ZERO, mid.get_size()), Vector2i.ZERO)
	return far


func _draw_realm_platform(target: Image, slug: String, rect: Rect2i) -> void:
	var strip := _load("res://assets/art/realm_%s/platform_main.png" % slug)
	var cap := 46 if slug == "vanaheim" else 52
	_draw_three_slice(target, strip, rect, cap, strip.get_width() - cap * 2)


func _draw_three_slice(target: Image, strip: Image, rect: Rect2i, cap: int, middle_width: int) -> void:
	var left := strip.get_region(Rect2i(0, 0, cap, strip.get_height()))
	var middle := strip.get_region(Rect2i(cap, 0, middle_width, strip.get_height()))
	var right := strip.get_region(Rect2i(cap + middle_width, 0, cap, strip.get_height()))
	left.resize(cap, rect.size.y, Image.INTERPOLATE_NEAREST)
	middle.resize(middle_width, rect.size.y, Image.INTERPOLATE_NEAREST)
	right.resize(cap, rect.size.y, Image.INTERPOLATE_NEAREST)
	target.blend_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), rect.position)
	var filled := 0
	var fill_width := rect.size.x - cap * 2
	while filled < fill_width:
		var take := mini(middle.get_width(), fill_width - filled)
		target.blend_rect(middle, Rect2i(0, 0, take, middle.get_height()), rect.position + Vector2i(cap + filled, 0))
		filled += take
	target.blend_rect(right, Rect2i(Vector2i.ZERO, right.get_size()), rect.position + Vector2i(rect.size.x - cap, 0))


func _draw_vertical(target: Image, tile: Image, rect: Rect2i) -> void:
	var scaled := tile.duplicate()
	scaled.resize(rect.size.x, tile.get_height(), Image.INTERPOLATE_NEAREST)
	var filled := 0
	while filled < rect.size.y:
		var take := mini(scaled.get_height(), rect.size.y - filled)
		target.blend_rect(scaled, Rect2i(0, 0, scaled.get_width(), take), rect.position + Vector2i(0, filled))
		filled += take


func _draw_asset_panel(target: Image, rect: Rect2i, vine: Image, light: Image, fire: Image, glyph: Image) -> void:
	_draw_checker(target, rect, 24)
	var vine_big := vine.duplicate()
	vine_big.resize(vine.get_width() * 4, vine.get_height() * 4, Image.INTERPOLATE_NEAREST)
	target.blend_rect(vine_big, Rect2i(Vector2i.ZERO, vine_big.get_size()), rect.position + Vector2i(70, 80))
	var light_big := light.duplicate()
	light_big.resize(light.get_width() * 2, light.get_height() * 2, Image.INTERPOLATE_NEAREST)
	target.blend_rect(light_big, Rect2i(Vector2i.ZERO, light_big.get_size()), rect.position + Vector2i(530, 50))
	var fire_big := fire.duplicate()
	fire_big.resize(fire.get_width() * 2, fire.get_height() * 2, Image.INTERPOLATE_NEAREST)
	target.blend_rect(fire_big, Rect2i(Vector2i.ZERO, fire_big.get_size()), rect.position + Vector2i(750, 50))
	var glyph_big := glyph.duplicate()
	glyph_big.resize(glyph.get_width() * 5, glyph.get_height() * 5, Image.INTERPOLATE_NEAREST)
	target.blend_rect(glyph_big, Rect2i(Vector2i.ZERO, glyph_big.get_size()), rect.position + Vector2i(70, 360))


func _draw_checker(target: Image, rect: Rect2i, cell: int) -> void:
	for y in range(rect.position.y, rect.end.y, cell):
		for x in range(rect.position.x, rect.end.x, cell):
			var index := ((x - rect.position.x) / cell + (y - rect.position.y) / cell) as int
			var color := Color("17202b") if index % 2 == 0 else Color("253342")
			target.fill_rect(Rect2i(x, y, mini(cell, rect.end.x - x), mini(cell, rect.end.y - y)), color)


func _save(image: Image, path: String) -> void:
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Unable to save %s: %s" % [path, error_string(error)])
		quit(1)
