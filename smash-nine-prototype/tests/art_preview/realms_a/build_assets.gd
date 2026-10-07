extends SceneTree

const REPORT_DIR := "../reports/codex-art-04a"
const FREY_SHEET := "res://assets/art/frey/frey_sheet.png"

const REALMS := [
	{
		"name": "asgard",
		"far": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-4a7cada6-a49c-4fa9-af26-f1aa33ee4549.png",
		"mid": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-9a62f291-07ab-4f6f-9e0d-99fd9489f301.png",
		"main": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-22510c67-b793-45cf-b9b5-969c0dc058ad.png",
		"sub": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-0f1d7eb4-625d-4884-8e62-a18023eb6fda.png",
		"main_height": 52,
		"main_cap": 52,
		"sub_cap": 32,
		"accent": Color("ffb857"),
		"palette": ["07101b", "0d1928", "142438", "1d3045", "263b51", "314b62", "45627a", "59758b", "71899b", "8da9b8", "a9b8bf", "d1d5cf", "805b2e", "a87534", "c88d3d", "d69a42", "e3ad55", "f0c06c"],
		"platforms": [
			[Vector2i(640, 620), Vector2i(1060, 52), true],
			[Vector2i(230, 475), Vector2i(270, 34), false],
			[Vector2i(1050, 475), Vector2i(270, 34), false],
			[Vector2i(640, 345), Vector2i(370, 34), false],
			[Vector2i(420, 240), Vector2i(210, 30), false],
			[Vector2i(860, 240), Vector2i(210, 30), false]
		]
	},
	{
		"name": "midgard",
		"far": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-b04d042e-7d46-45ec-b29d-73427bce4333.png",
		"mid": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-fa2c2860-80c8-42ea-bb9d-7846f3462991.png",
		"main": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-e62485db-536d-4043-a039-8e653e65693f.png",
		"sub": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-8bff4bc9-1706-4cee-a899-e5cf0bdc8fed.png",
		"bush": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-9b116a10-5c73-4730-ac60-a92f28fc12fe.png",
		"main_height": 46,
		"main_cap": 46,
		"sub_cap": 32,
		"accent": Color("f2b86b"),
		"palette": ["140f0b", "211611", "2a1d16", "38261d", "493126", "5d3a2b", "744638", "91583b", "ad6d3d", "c78447", "d99b52", "e3ad62", "34444a", "4d6065", "687a80", "89979a", "102016", "1b3421", "2d4a2c", "45633a", "658052", "b19a55"],
		"platforms": [
			[Vector2i(340, 615), Vector2i(470, 46), true],
			[Vector2i(930, 590), Vector2i(430, 46), true],
			[Vector2i(185, 440), Vector2i(220, 32), false],
			[Vector2i(560, 450), Vector2i(270, 32), false],
			[Vector2i(1010, 375), Vector2i(250, 32), false],
			[Vector2i(405, 280), Vector2i(190, 28), false],
			[Vector2i(760, 240), Vector2i(210, 28), false]
		]
	},
	{
		"name": "niflheim",
		"far": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-41c4510b-5d65-4398-b77a-73a28acb7033.png",
		"mid": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-706b8e39-223f-470a-9797-ddaf04b536d9.png",
		"main": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-a9fcb2e7-0a78-4079-8f7a-e893134bd213.png",
		"sub": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-0a9066ed-440a-428a-a45a-4131ab4f706e.png",
		"main_height": 44,
		"main_cap": 44,
		"sub_cap": 32,
		"accent": Color("a8f2ff"),
		"palette": ["06131a", "081d27", "0c2733", "123442", "174052", "205268", "2f6577", "417b8b", "5793a1", "6fa8b4", "89bac2", "a9cdd2", "c6e1e2", "296c70", "3b8b82", "55a999", "77c7b8"],
		"platforms": [
			[Vector2i(280, 620), Vector2i(360, 44), true],
			[Vector2i(1000, 620), Vector2i(360, 44), true],
			[Vector2i(520, 505), Vector2i(260, 34), false],
			[Vector2i(760, 390), Vector2i(260, 34), false],
			[Vector2i(360, 275), Vector2i(230, 30), false],
			[Vector2i(920, 275), Vector2i(230, 30), false],
			[Vector2i(640, 170), Vector2i(190, 28), false]
		]
	},
	{
		"name": "alfheim",
		"far": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-133fc26f-fb8e-4b58-a43b-1104f30dc112.png",
		"mid": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-42c7a29f-0d3b-4a83-a6ce-d50988417b38.png",
		"main": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-df4dd4be-2d0b-4912-ace6-d19e6ae5e07c.png",
		"sub": "C:/Users/TH/.codex/generated_images/01a1142a-fd6d-77f2-ad57-91d02d8563d6/exec-db158b69-b5bb-4a9e-a09e-ba570fc59ae9.png",
		"main_height": 46,
		"main_cap": 46,
		"sub_cap": 32,
		"accent": Color("b3d1ff"),
		"palette": ["090c22", "0f132d", "151a3b", "1e2448", "292d57", "353b67", "414a76", "53608b", "66749d", "7185ae", "879bc0", "9eadd0", "b8c9dd", "d2ddec", "594c82", "7562a1", "9b83c6", "b29dd5"],
		"platforms": [
			[Vector2i(640, 600), Vector2i(900, 46), true],
			[Vector2i(210, 420), Vector2i(240, 32), false],
			[Vector2i(1070, 420), Vector2i(240, 32), false],
			[Vector2i(640, 315), Vector2i(310, 30), false],
			[Vector2i(410, 215), Vector2i(170, 28), false],
			[Vector2i(870, 215), Vector2i(170, 28), false]
		]
	}
]


func _initialize() -> void:
	call_deferred("_build")


func _build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	var previews: Array[Image] = []
	for realm: Dictionary in REALMS:
		var output_dir := "res://assets/art/realm_%s" % realm.name
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
		var palette := _colors(realm.palette)
		var far := _pixelize_background(_load_image(realm.far), palette, false)
		var mid := _pixelize_background(_load_image(realm.mid), palette, true)
		var main_strip := _build_strip(_load_image(realm.main), int(realm.main_height), int(realm.main_cap), 128, palette)
		var sub_strip := _build_strip(_load_image(realm.sub), 32, int(realm.sub_cap), 96, palette)
		_save(far, output_dir + "/bg_far.png")
		_save(mid, output_dir + "/bg_mid.png")
		_save(main_strip, output_dir + "/platform_main.png")
		_save(sub_strip, output_dir + "/platform_sub.png")
		var bush: Image
		if realm.has("bush"):
			bush = _build_sprite(_load_image(realm.bush), Vector2i(160, 72), palette)
			_save(bush, output_dir + "/bush.png")
		var preview := _compose_preview(realm, far, mid, main_strip, sub_strip, bush)
		_save(preview, REPORT_DIR + "/%s_preview.png" % realm.name)
		previews.append(preview)
		print("REALM_BUILT ", realm.name, " far=", far.get_size(), " mid=", mid.get_size(), " main=", main_strip.get_size(), " sub=", sub_strip.get_size())
	if not previews.is_empty():
		_save(_contact_sheet(previews), REPORT_DIR + "/contact_sheet.png")
	print("ART04A_BUILD_OK realms=", previews.size())
	quit()


func _load_image(path: String) -> Image:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_error("Unable to load source image: " + path)
		quit(1)
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _colors(values: Array) -> Array[Color]:
	var result: Array[Color] = []
	for value: String in values:
		result.append(Color(value))
	return result


func _pixelize_background(source: Image, palette: Array[Color], preserve_alpha: bool) -> Image:
	var cropped := _crop_to_ratio(source, 16.0 / 9.0)
	cropped.resize(640, 360, Image.INTERPOLATE_LANCZOS)
	_reduce_palette(cropped, palette, preserve_alpha)
	cropped.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	return cropped


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


func _reduce_palette(image: Image, palette: Array[Color], preserve_alpha: bool) -> void:
	var cache: Dictionary = {}
	for y in image.get_height():
		for x in image.get_width():
			var source := image.get_pixel(x, y)
			if preserve_alpha and source.a < 0.18:
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
				continue
			var key := (clampi(int(source.r * 255.0), 0, 255) << 16) | (clampi(int(source.g * 255.0), 0, 255) << 8) | clampi(int(source.b * 255.0), 0, 255)
			var mapped: Color = cache.get(key, Color(-1.0, 0.0, 0.0))
			if mapped.r < 0.0:
				mapped = _nearest_colour(source, palette)
				cache[key] = mapped
			mapped.a = (1.0 if source.a >= 0.58 else 0.5) if preserve_alpha else 1.0
			image.set_pixel(x, y, mapped)


func _nearest_colour(source: Color, palette: Array[Color]) -> Color:
	var best := palette[0]
	var best_distance := INF
	for candidate: Color in palette:
		var dr := source.r - candidate.r
		var dg := source.g - candidate.g
		var db := source.b - candidate.b
		var distance := dr * dr * 0.30 + dg * dg * 0.59 + db * db * 0.11
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


func _used_region(source: Image) -> Image:
	var used := source.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		push_error("Generated source has no opaque pixels")
		quit(1)
		return source.duplicate()
	return source.get_region(used)


func _build_strip(source: Image, final_height: int, final_cap: int, final_middle: int, palette: Array[Color]) -> Image:
	var used := _used_region(source)
	var source_width := used.get_width()
	var source_height := used.get_height()
	var cap_source_width := maxi(1, int(round(float(source_width) * 0.115)))
	var middle_source_width := maxi(1, int(round(float(source_width) * 0.25)))
	var middle_source_x := (source_width - middle_source_width) / 2
	var half_height := maxi(1, final_height / 2)
	var half_cap := maxi(1, final_cap / 2)
	var half_middle := maxi(1, final_middle / 2)
	var left := used.get_region(Rect2i(0, 0, cap_source_width, source_height))
	var middle := used.get_region(Rect2i(middle_source_x, 0, middle_source_width, source_height))
	var right := used.get_region(Rect2i(source_width - cap_source_width, 0, cap_source_width, source_height))
	left.resize(half_cap, half_height, Image.INTERPOLATE_LANCZOS)
	middle.resize(half_middle, half_height, Image.INTERPOLATE_LANCZOS)
	right.resize(half_cap, half_height, Image.INTERPOLATE_LANCZOS)
	_reduce_palette(left, palette, true)
	_reduce_palette(middle, palette, true)
	_reduce_palette(right, palette, true)
	_make_middle_seamless(middle)
	_match_inner_edge(left, middle, true)
	_match_inner_edge(right, middle, false)
	var strip := Image.create(half_cap * 2 + half_middle, half_height, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0.0, 0.0, 0.0, 0.0))
	strip.blit_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), Vector2i.ZERO)
	strip.blit_rect(middle, Rect2i(Vector2i.ZERO, middle.get_size()), Vector2i(half_cap, 0))
	strip.blit_rect(right, Rect2i(Vector2i.ZERO, right.get_size()), Vector2i(half_cap + half_middle, 0))
	strip.resize(final_cap * 2 + final_middle, final_height, Image.INTERPOLATE_NEAREST)
	return strip


func _build_sprite(source: Image, final_size: Vector2i, palette: Array[Color]) -> Image:
	var used := _used_region(source)
	var target_ratio := float(final_size.x) / float(final_size.y)
	var used_ratio := float(used.get_width()) / float(used.get_height())
	var fitted := used
	if used_ratio > target_ratio:
		var target_height := int(round(float(used.get_width()) / target_ratio))
		var padded := Image.create(used.get_width(), target_height, false, Image.FORMAT_RGBA8)
		padded.fill(Color(0.0, 0.0, 0.0, 0.0))
		padded.blend_rect(used, Rect2i(Vector2i.ZERO, used.get_size()), Vector2i(0, target_height - used.get_height()))
		fitted = padded
	else:
		var target_width := int(round(float(used.get_height()) * target_ratio))
		var padded := Image.create(target_width, used.get_height(), false, Image.FORMAT_RGBA8)
		padded.fill(Color(0.0, 0.0, 0.0, 0.0))
		padded.blend_rect(used, Rect2i(Vector2i.ZERO, used.get_size()), Vector2i((target_width - used.get_width()) / 2, 0))
		fitted = padded
	fitted.resize(final_size.x / 2, final_size.y / 2, Image.INTERPOLATE_LANCZOS)
	_reduce_palette(fitted, palette, true)
	fitted.resize(final_size.x, final_size.y, Image.INTERPOLATE_NEAREST)
	return fitted


func _make_middle_seamless(middle: Image) -> void:
	for y in middle.get_height():
		var seam := middle.get_pixel(0, y).lerp(middle.get_pixel(middle.get_width() - 1, y), 0.5)
		middle.set_pixel(0, y, seam)
		middle.set_pixel(middle.get_width() - 1, y, seam)


func _match_inner_edge(cap: Image, middle: Image, is_left: bool) -> void:
	var cap_x := cap.get_width() - 1 if is_left else 0
	var middle_x := 0 if is_left else middle.get_width() - 1
	for y in mini(cap.get_height(), middle.get_height()):
		cap.set_pixel(cap_x, y, middle.get_pixel(middle_x, y))


func _compose_preview(realm: Dictionary, far: Image, mid: Image, main_strip: Image, sub_strip: Image, bush: Image) -> Image:
	var preview := far.duplicate()
	preview.blend_rect(mid, Rect2i(Vector2i.ZERO, mid.get_size()), Vector2i.ZERO)
	for platform: Array in realm.platforms:
		var center: Vector2i = platform[0]
		var size: Vector2i = platform[1]
		var is_main: bool = platform[2]
		var strip := main_strip if is_main else sub_strip
		var cap := int(realm.main_cap) if is_main else int(realm.sub_cap)
		var middle := 128 if is_main else 96
		_draw_three_slice(preview, strip, Rect2i(center - size / 2, size), cap, middle)
		preview.fill_rect(Rect2i(center.x - size.x / 2, center.y - size.y / 2, size.x, 2), realm.accent)
	_add_fighters(preview, realm.platforms)
	if bush != null and not bush.is_empty():
		var ground: Array = realm.platforms[0]
		var ground_center: Vector2i = ground[0]
		var ground_size: Vector2i = ground[1]
		var bush_pos := Vector2i(ground_center.x - ground_size.x / 5 - bush.get_width() / 2, ground_center.y - ground_size.y / 2 - bush.get_height())
		preview.blend_rect(bush, Rect2i(Vector2i.ZERO, bush.get_size()), bush_pos)
	return preview


func _draw_three_slice(target: Image, strip: Image, rect: Rect2i, source_cap: int, source_middle: int) -> void:
	var left := strip.get_region(Rect2i(0, 0, source_cap, strip.get_height()))
	var middle := strip.get_region(Rect2i(source_cap, 0, source_middle, strip.get_height()))
	var right := strip.get_region(Rect2i(source_cap + source_middle, 0, source_cap, strip.get_height()))
	var cap_width := mini(source_cap, rect.size.x / 2)
	left.resize(cap_width, rect.size.y, Image.INTERPOLATE_NEAREST)
	right.resize(cap_width, rect.size.y, Image.INTERPOLATE_NEAREST)
	middle.resize(middle.get_width(), rect.size.y, Image.INTERPOLATE_NEAREST)
	target.blend_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), rect.position)
	var fill_width := rect.size.x - cap_width * 2
	var filled := 0
	while filled < fill_width:
		var take := mini(middle.get_width(), fill_width - filled)
		target.blend_rect(middle, Rect2i(0, 0, take, middle.get_height()), rect.position + Vector2i(cap_width + filled, 0))
		filled += take
	target.blend_rect(right, Rect2i(Vector2i.ZERO, right.get_size()), rect.position + Vector2i(rect.size.x - cap_width, 0))


func _add_fighters(target: Image, platforms: Array) -> void:
	var sheet := _load_image(ProjectSettings.globalize_path(FREY_SHEET))
	var frame := sheet.get_region(Rect2i(0, 0, 64, 64))
	frame.resize(128, 128, Image.INTERPOLATE_NEAREST)
	var first: Array = platforms[0]
	var first_center: Vector2i = first[0]
	var first_size: Vector2i = first[1]
	var foot := Vector2i(first_center.x - first_size.x / 5, first_center.y - first_size.y / 2)
	target.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), foot - Vector2i(64, 96))
	if platforms.size() > 3:
		var upper: Array = platforms[3]
		var upper_center: Vector2i = upper[0]
		var upper_size: Vector2i = upper[1]
		var upper_foot := Vector2i(upper_center.x, upper_center.y - upper_size.y / 2)
		target.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), upper_foot - Vector2i(64, 96))


func _contact_sheet(previews: Array[Image]) -> Image:
	var count := previews.size()
	var columns := mini(2, count)
	var rows := ceili(float(count) / float(columns))
	var sheet := Image.create(columns * 640, rows * 360, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("070b12"))
	for index in count:
		var thumb := previews[index].duplicate()
		thumb.resize(640, 360, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(thumb, Rect2i(Vector2i.ZERO, thumb.get_size()), Vector2i((index % columns) * 640, (index / columns) * 360))
	return sheet


func _save(image: Image, path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	var error := image.save_png(absolute)
	if error != OK:
		push_error("Failed to save " + absolute + ": " + error_string(error))
		quit(1)
