extends SceneTree

const OUTPUT_ROOT := "res://assets/art"
const REPORT_DIR := "res://../reports/codex-art-04b"
const FAR_SIZE := Vector2i(1280, 720)
const WORK_SIZE := Vector2i(640, 360)
const MIDDLE_WIDTH := 96
const SUB_HEIGHT := 32
const SUB_CAP := 32

const REALMS := [
	{
		"slug": "muspelheim",
		"far_source": "C:/Users/TH/.codex/generated_images/01a1142e-b18c-7832-bc7f-bac8ef2601e1/exec-7b268e05-9eea-404a-abc0-9ac794452ae9.png",
		"platform_source": "C:/Users/TH/.codex/generated_images/01a1142e-b18c-7832-bc7f-bac8ef2601e1/exec-1b67da9a-7c20-477a-8ff9-12e03f56ad44.png",
		"main_height": 52,
		"main_cap": 52,
		"accent": "ff5c29",
		"palette": ["10070a", "19090c", "250d10", "321116", "43151a", "581b1d", "702321", "8b2d24", "a83a27", "c64a29", "e35e2c", "f47b35", "ff9a45", "2a1b22", "3c2730", "56333a", "704149", "8e5154", "bd6a5e", "e99170"]
	},
	{
		"slug": "svartalfheim",
		"far_source": "C:/Users/TH/.codex/generated_images/01a1142e-b18c-7832-bc7f-bac8ef2601e1/exec-7f16b7e1-07ca-488a-8f39-6a0b3b0c7152.png",
		"platform_source": "C:/Users/TH/.codex/generated_images/01a1142e-b18c-7832-bc7f-bac8ef2601e1/exec-28be318c-b468-456a-afc3-d12c4240b980.png",
		"main_height": 44,
		"main_cap": 44,
		"accent": "f29e40",
		"palette": ["090c10", "11161c", "19212a", "222d37", "2d3943", "394751", "485760", "586870", "263c43", "31515a", "3e6870", "745438", "8b6440", "a97945", "c5904e", "e0aa5b", "f2c26d", "6f4930", "9a5f32", "ca7734"]
	},
	{
		"slug": "vanaheim",
		"far_source": "C:/Users/TH/.codex/generated_images/01a1142e-b18c-7832-bc7f-bac8ef2601e1/exec-8a0a775d-0e33-4fe2-a184-4560a5ac3afe.png",
		"platform_source": "C:/Users/TH/.codex/generated_images/01a1142e-b18c-7832-bc7f-bac8ef2601e1/exec-b02c8cf4-f34c-4190-9ce8-fcb2c3c9b376.png",
		"main_height": 46,
		"main_cap": 46,
		"accent": "6bf28c",
		"palette": ["04110e", "071a16", "0b251e", "103129", "153e32", "1b4d3b", "235d45", "2d6f4f", "39825a", "489565", "5ba972", "70bd7e", "88cf91", "17383b", "235057", "326a6e", "4b817c", "78965c", "a3ad62", "d4c46f"]
	},
	{
		"slug": "jotunheim",
		"far_source": "C:/Users/TH/.codex/generated_images/01a1142e-b18c-7832-bc7f-bac8ef2601e1/exec-b3f894e5-00d6-42c8-a706-a407366c08fd.png",
		"platform_source": "C:/Users/TH/.codex/generated_images/01a1142e-b18c-7832-bc7f-bac8ef2601e1/exec-5c37145a-8fd4-4c9b-94fa-57b5f1368fba.png",
		"main_height": 46,
		"main_cap": 46,
		"accent": "9eb8f2",
		"palette": ["080b18", "0d1224", "131a31", "1a2340", "222d50", "2c3961", "374672", "455584", "566696", "6978a8", "7e8cba", "95a3cb", "adb9dc", "c6d0ea", "252741", "343650", "484965", "5f5d7d", "777494", "9691ad"]
	}
]


func _initialize() -> void:
	call_deferred("_build")


func _build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	var previews: Array[Image] = []
	for config in REALMS:
		var output_dir := "%s/realm_%s" % [OUTPUT_ROOT, config.slug]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
		var source := _load_image(config.far_source)
		var palette := _make_palette(config.palette)
		var far := _build_far(source, palette)
		var mid := _build_mid(source, palette, config.slug)
		var platform_source := _load_image(config.platform_source)
		var main_strip := _build_strip(platform_source, true, config.main_height, config.main_cap, palette)
		var sub_strip := _build_strip(platform_source, false, SUB_HEIGHT, SUB_CAP, palette)
		_save(far, output_dir + "/bg_far.png")
		_save(mid, output_dir + "/bg_mid.png")
		_save(main_strip, output_dir + "/platform_main.png")
		_save(sub_strip, output_dir + "/platform_sub.png")
		var preview := _compose_preview(config, far, mid, main_strip, sub_strip)
		previews.append(preview)
		_save(preview, REPORT_DIR + "/%s_preview.png" % config.slug)
		print("REALM_ART_OK ", config.slug, " far=", far.get_size(), " mid=", mid.get_size(), " main=", main_strip.get_size(), " sub=", sub_strip.get_size(), " caps=", config.main_cap, "/", SUB_CAP)
	_save(_compose_contact_sheet(previews), REPORT_DIR + "/contact_sheet.png")
	print("ART_BUILD_OK realms=", previews.size())
	quit()


func _load_image(path: String) -> Image:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_error("Unable to load source image: " + path)
		quit(1)
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _make_palette(hex_values: Array) -> Array[Color]:
	var palette: Array[Color] = []
	for value in hex_values:
		palette.append(Color(str(value)))
	return palette


func _build_far(source: Image, palette: Array[Color]) -> Image:
	var image := _crop_to_ratio(source, 16.0 / 9.0)
	image.resize(WORK_SIZE.x, WORK_SIZE.y, Image.INTERPOLATE_LANCZOS)
	_reduce_palette(image, palette, false)
	image.resize(FAR_SIZE.x, FAR_SIZE.y, Image.INTERPOLATE_NEAREST)
	return image


func _build_mid(source: Image, palette: Array[Color], slug: String) -> Image:
	var sampled := _crop_to_ratio(source, 16.0 / 9.0)
	sampled.resize(WORK_SIZE.x, WORK_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var mid := Image.create(WORK_SIZE.x, WORK_SIZE.y, false, Image.FORMAT_RGBA8)
	mid.fill(Color(0.0, 0.0, 0.0, 0.0))
	for y in WORK_SIZE.y:
		var side_depth := 42 + int(float(y) / float(WORK_SIZE.y) * 82.0) + int(7.0 * sin(float(y) * 0.085))
		var floor_line := 338 + int(5.0 * sin(float(y) * 0.13))
		for x in WORK_SIZE.x:
			var keep := x < side_depth or x >= WORK_SIZE.x - side_depth or y >= floor_line
			if slug == "vanaheim" and y < 48:
				keep = keep or x < 180 - y * 2 or x > WORK_SIZE.x - 180 + y * 2
			if not keep:
				continue
			var color := _nearest_colour(sampled.get_pixel(x, y), palette, mini(9, palette.size()))
			color = color.darkened(0.12)
			color.a = 1.0
			mid.set_pixel(x, y, color)
	mid.resize(FAR_SIZE.x, FAR_SIZE.y, Image.INTERPOLATE_NEAREST)
	return mid


func _crop_to_ratio(source: Image, ratio: float) -> Image:
	var size := source.get_size()
	var current_ratio := float(size.x) / float(size.y)
	if is_equal_approx(current_ratio, ratio):
		return source.duplicate()
	if current_ratio > ratio:
		var width := int(round(float(size.y) * ratio))
		return source.get_region(Rect2i((size.x - width) / 2, 0, width, size.y))
	var height := int(round(float(size.x) / ratio))
	return source.get_region(Rect2i(0, (size.y - height) / 2, size.x, height))


func _build_strip(source: Image, upper: bool, final_height: int, final_cap: int, palette: Array[Color]) -> Image:
	var sprite := _extract_sheet_sprite(source, upper)
	var source_width := sprite.get_width()
	var source_height := sprite.get_height()
	var cap_source_width := maxi(1, int(round(float(source_width) * 0.12)))
	var middle_source_width := maxi(1, int(round(float(source_width) * 0.28)))
	var middle_source_x := (source_width - middle_source_width) / 2
	var base_height := final_height / 2
	var base_cap := final_cap / 2
	var base_middle := MIDDLE_WIDTH / 2
	var left := sprite.get_region(Rect2i(0, 0, cap_source_width, source_height))
	var middle := sprite.get_region(Rect2i(middle_source_x, 0, middle_source_width, source_height))
	var right := sprite.get_region(Rect2i(source_width - cap_source_width, 0, cap_source_width, source_height))
	left.resize(base_cap, base_height, Image.INTERPOLATE_LANCZOS)
	middle.resize(base_middle, base_height, Image.INTERPOLATE_LANCZOS)
	right.resize(base_cap, base_height, Image.INTERPOLATE_LANCZOS)
	_reduce_palette(left, palette, true)
	_reduce_palette(middle, palette, true)
	_reduce_palette(right, palette, true)
	_make_middle_seamless(middle)
	_match_inner_edge(left, middle, true)
	_match_inner_edge(right, middle, false)
	var strip := Image.create(base_cap * 2 + base_middle, base_height, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0.0, 0.0, 0.0, 0.0))
	strip.blend_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), Vector2i.ZERO)
	strip.blend_rect(middle, Rect2i(Vector2i.ZERO, middle.get_size()), Vector2i(base_cap, 0))
	strip.blend_rect(right, Rect2i(Vector2i.ZERO, right.get_size()), Vector2i(base_cap + base_middle, 0))
	strip.resize(final_cap * 2 + MIDDLE_WIDTH, final_height, Image.INTERPOLATE_NEAREST)
	return strip


func _extract_sheet_sprite(source: Image, upper: bool) -> Image:
	var half_height := source.get_height() / 2
	var region := source.get_region(Rect2i(0, 0 if upper else half_height, source.get_width(), half_height))
	var used := region.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		push_error("Generated platform half contains no opaque pixels")
		quit(1)
		return region
	return region.get_region(used)


func _reduce_palette(image: Image, palette: Array[Color], preserve_alpha: bool) -> void:
	var cache: Dictionary = {}
	for y in image.get_height():
		for x in image.get_width():
			var source := image.get_pixel(x, y)
			if preserve_alpha and source.a < 0.18:
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
				continue
			var red := clampi(int(round(source.r * 255.0)), 0, 255)
			var green := clampi(int(round(source.g * 255.0)), 0, 255)
			var blue := clampi(int(round(source.b * 255.0)), 0, 255)
			var key := (red << 16) | (green << 8) | blue
			var mapped: Color
			if cache.has(key):
				mapped = cache[key]
			else:
				mapped = _nearest_colour(source, palette, palette.size())
				cache[key] = mapped
			mapped.a = 1.0 if not preserve_alpha or source.a >= 0.58 else 0.5
			image.set_pixel(x, y, mapped)


func _nearest_colour(source: Color, palette: Array[Color], count: int) -> Color:
	var best := palette[0]
	var best_distance := INF
	for index in mini(count, palette.size()):
		var candidate := palette[index]
		var dr := source.r - candidate.r
		var dg := source.g - candidate.g
		var db := source.b - candidate.b
		var distance := dr * dr * 0.30 + dg * dg * 0.59 + db * db * 0.11
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


func _make_middle_seamless(middle: Image) -> void:
	for y in middle.get_height():
		var seam := middle.get_pixel(0, y).lerp(middle.get_pixel(middle.get_width() - 1, y), 0.5)
		middle.set_pixel(0, y, seam)
		middle.set_pixel(middle.get_width() - 1, y, seam)
		if middle.get_width() >= 4:
			var near_seam := middle.get_pixel(1, y).lerp(middle.get_pixel(middle.get_width() - 2, y), 0.5)
			middle.set_pixel(1, y, near_seam)
			middle.set_pixel(middle.get_width() - 2, y, near_seam)


func _match_inner_edge(cap: Image, middle: Image, is_left: bool) -> void:
	var cap_x := cap.get_width() - 1 if is_left else 0
	var middle_x := 0 if is_left else middle.get_width() - 1
	for y in mini(cap.get_height(), middle.get_height()):
		cap.set_pixel(cap_x, y, middle.get_pixel(middle_x, y))


func _compose_preview(config: Dictionary, far: Image, mid: Image, main_strip: Image, sub_strip: Image) -> Image:
	var preview := far.duplicate()
	preview.blend_rect(mid, Rect2i(Vector2i.ZERO, mid.get_size()), Vector2i.ZERO)
	for platform in _platforms_for(config.slug):
		var center: Vector2i = platform[0]
		var size: Vector2i = platform[1]
		var is_main: bool = platform[2]
		var strip := main_strip if is_main else sub_strip
		var cap: int = config.main_cap if is_main else SUB_CAP
		_draw_three_slice(preview, strip, Rect2i(center - size / 2, size), cap)
		var edge_height := 5 if is_main else 3
		var accent := Color(config.accent)
		accent.a = 0.72 if is_main else 0.5
		preview.fill_rect(Rect2i(center.x - size.x / 2, center.y - size.y / 2, size.x, edge_height), accent)
	_add_fighter_scale(preview, _platforms_for(config.slug))
	return preview


func _draw_three_slice(target: Image, strip: Image, rect: Rect2i, cap: int) -> void:
	var center_width := strip.get_width() - cap * 2
	var left := strip.get_region(Rect2i(0, 0, cap, strip.get_height()))
	var middle := strip.get_region(Rect2i(cap, 0, center_width, strip.get_height()))
	var right := strip.get_region(Rect2i(cap + center_width, 0, cap, strip.get_height()))
	left.resize(cap, rect.size.y, Image.INTERPOLATE_NEAREST)
	middle.resize(center_width, rect.size.y, Image.INTERPOLATE_NEAREST)
	right.resize(cap, rect.size.y, Image.INTERPOLATE_NEAREST)
	target.blend_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), rect.position)
	var fill_width := rect.size.x - cap * 2
	var filled := 0
	while filled < fill_width:
		var take := mini(middle.get_width(), fill_width - filled)
		target.blend_rect(middle, Rect2i(0, 0, take, middle.get_height()), rect.position + Vector2i(cap + filled, 0))
		filled += take
	target.blend_rect(right, Rect2i(Vector2i.ZERO, right.get_size()), rect.position + Vector2i(rect.size.x - cap, 0))


func _add_fighter_scale(target: Image, platforms: Array) -> void:
	var sheet := _load_image(ProjectSettings.globalize_path("res://assets/art/frey/frey_sheet.png"))
	var frame := sheet.get_region(Rect2i(0, 0, 64, 64))
	frame.resize(128, 128, Image.INTERPOLATE_NEAREST)
	var main_platform: Array = platforms[0]
	var center: Vector2i = main_platform[0]
	var size: Vector2i = main_platform[1]
	var foot := Vector2i(center.x, center.y - size.y / 2)
	target.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), foot - Vector2i(64, 96))


func _platforms_for(slug: String) -> Array:
	match slug:
		"muspelheim":
			return [[Vector2i(640, 610), Vector2i(760, 52), true], [Vector2i(370, 455), Vector2i(220, 32), false], [Vector2i(910, 455), Vector2i(220, 32), false], [Vector2i(640, 325), Vector2i(280, 32), false], [Vector2i(190, 315), Vector2i(170, 28), false], [Vector2i(1090, 315), Vector2i(170, 28), false]]
		"svartalfheim":
			return [[Vector2i(640, 640), Vector2i(360, 44), true], [Vector2i(260, 540), Vector2i(250, 34), false], [Vector2i(1020, 540), Vector2i(250, 34), false], [Vector2i(430, 405), Vector2i(230, 30), false], [Vector2i(850, 405), Vector2i(230, 30), false], [Vector2i(640, 270), Vector2i(240, 30), false], [Vector2i(640, 150), Vector2i(160, 26), false]]
		"vanaheim":
			return [[Vector2i(640, 650), Vector2i(520, 46), true], [Vector2i(250, 555), Vector2i(350, 40), true], [Vector2i(1030, 555), Vector2i(350, 40), true], [Vector2i(640, 425), Vector2i(280, 32), false], [Vector2i(315, 300), Vector2i(230, 30), false], [Vector2i(965, 300), Vector2i(230, 30), false]]
		"jotunheim":
			return [[Vector2i(640, 620), Vector2i(360, 46), true], [Vector2i(260, 500), Vector2i(230, 32), false], [Vector2i(1020, 500), Vector2i(230, 32), false], [Vector2i(640, 440), Vector2i(250, 32), false], [Vector2i(430, 300), Vector2i(210, 30), false], [Vector2i(850, 300), Vector2i(210, 30), false], [Vector2i(640, 195), Vector2i(170, 28), false]]
	return []


func _compose_contact_sheet(previews: Array[Image]) -> Image:
	var sheet := Image.create(2560, 1440, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("05070d"))
	for index in previews.size():
		var position := Vector2i((index % 2) * 1280, (index / 2) * 720)
		sheet.blit_rect(previews[index], Rect2i(Vector2i.ZERO, FAR_SIZE), position)
	return sheet


func _save(image: Image, path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	var error := image.save_png(absolute)
	if error != OK:
		push_error("Failed to save %s: %s" % [absolute, error_string(error)])
		quit(1)
