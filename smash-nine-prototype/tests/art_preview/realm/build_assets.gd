extends SceneTree

const OUTPUT_DIR := "res://assets/art/realm_center"
const REPORT_DIR := "../reports/codex-art-01"

const FAR_SOURCE := "C:/Users/TH/.codex/generated_images/01a113db-a740-7ec2-9a7a-4e227ca6fbd0/exec-278680b8-1431-4361-8e59-aae55c5cb940.png"
const MID_SOURCE := "C:/Users/TH/.codex/generated_images/01a113db-a740-7ec2-9a7a-4e227ca6fbd0/exec-71483bf4-b3ae-4835-a427-0f8a673ef345.png"
const MAIN_SOURCE := "C:/Users/TH/.codex/generated_images/01a113db-a740-7ec2-9a7a-4e227ca6fbd0/exec-4ee7566d-96d0-4cfc-a475-c3ec04c5b13c.png"
const SUB_SOURCE := "C:/Users/TH/.codex/generated_images/01a113db-a740-7ec2-9a7a-4e227ca6fbd0/exec-df2b9b5c-432d-4623-bced-a2134493e2c8.png"
const PORTAL_SOURCE := "C:/Users/TH/.codex/generated_images/01a113db-a740-7ec2-9a7a-4e227ca6fbd0/exec-32e57ce3-e2d6-4abc-b7ee-edd988ba511b.png"

const MAIN_LEFT := 54
const MAIN_MIDDLE := 128
const MAIN_RIGHT := 54
const SUB_LEFT := 32
const SUB_MIDDLE := 96
const SUB_RIGHT := 32

const PLATFORMS := [
	[Vector2i(960, 940), Vector2i(1500, 54), true],
	[Vector2i(420, 800), Vector2i(300, 34), false],
	[Vector2i(1500, 800), Vector2i(300, 34), false],
	[Vector2i(960, 790), Vector2i(360, 34), false],
	[Vector2i(300, 650), Vector2i(220, 30), false],
	[Vector2i(1620, 650), Vector2i(220, 30), false],
	[Vector2i(640, 660), Vector2i(280, 32), false],
	[Vector2i(1280, 660), Vector2i(280, 32), false],
	[Vector2i(960, 520), Vector2i(340, 32), false],
	[Vector2i(560, 400), Vector2i(240, 28), false],
	[Vector2i(1360, 400), Vector2i(240, 28), false],
	[Vector2i(960, 280), Vector2i(260, 28), false]
]

const PORTALS := [Vector2i(270, 913), Vector2i(1650, 913), Vector2i(960, 263), Vector2i(960, 913)]


func _initialize() -> void:
	call_deferred("_build")


func _build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))

	var far := _pixelize_background(_load_image(FAR_SOURCE), false)
	var mid := _pixelize_background(_load_image(MID_SOURCE), true)
	var main_strip := _build_strip(_load_image(MAIN_SOURCE), 27, 27, 64, 27)
	var sub_strip := _build_strip(_load_image(SUB_SOURCE), 16, 16, 48, 16)
	var portal := _build_portal(_load_image(PORTAL_SOURCE))

	_save(far, OUTPUT_DIR + "/bg_far.png")
	_save(mid, OUTPUT_DIR + "/bg_mid.png")
	_save(main_strip, OUTPUT_DIR + "/platform_main.png")
	_save(sub_strip, OUTPUT_DIR + "/platform_sub.png")
	_save(portal, OUTPUT_DIR + "/portal.png")

	var mock := _compose_mock(far, mid, main_strip, sub_strip, portal)
	_save(_compose_contact_sheet(mock, far, mid, main_strip, sub_strip, portal), OUTPUT_DIR + "/contact_sheet.png")

	print("ART_BUILD_OK far=", far.get_size(), " mid=", mid.get_size(), " main=", main_strip.get_size(), " sub=", sub_strip.get_size(), " portal=", portal.get_size())
	quit()


func _load_image(path: String) -> Image:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_error("Unable to load source image: " + path)
		quit(1)
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _pixelize_background(source: Image, preserve_alpha: bool) -> Image:
	var cropped := _crop_to_ratio(source, 16.0 / 9.0)
	cropped.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	_reduce_palette(cropped, preserve_alpha)
	cropped.resize(1920, 1080, Image.INTERPOLATE_NEAREST)
	return cropped


func _crop_to_ratio(source: Image, ratio: float) -> Image:
	var size := source.get_size()
	var current_ratio := float(size.x) / float(size.y)
	if is_equal_approx(current_ratio, ratio):
		return source.duplicate()
	if current_ratio > ratio:
		var width := int(round(float(size.y) * ratio))
		var x := (size.x - width) / 2
		return source.get_region(Rect2i(x, 0, width, size.y))
	var height := int(round(float(size.x) / ratio))
	var y := (size.y - height) / 2
	return source.get_region(Rect2i(0, y, size.x, height))


func _palette() -> Array[Color]:
	return [
		Color("080611"), Color("0d0a19"), Color("121026"), Color("18132f"),
		Color("20163a"), Color("291b46"), Color("342252"), Color("412a61"),
		Color("513270"), Color("65417e"), Color("79518d"), Color("91609a"),
		Color("a64aa4"), Color("bd5fba"), Color("d47bce"), Color("e79cdd"),
		Color("29466d"), Color("376486"), Color("4f83a0"), Color("68a7b9"),
		Color("7b633f"), Color("a47d4d"), Color("c79b61"), Color("e0bd7b")
	]


func _reduce_palette(image: Image, preserve_alpha: bool) -> void:
	var palette := _palette()
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
				mapped = _nearest_colour(source, palette)
				cache[key] = mapped
			mapped.a = 1.0 if not preserve_alpha or source.a >= 0.58 else 0.5
			image.set_pixel(x, y, mapped)


func _nearest_colour(source: Color, palette: Array[Color]) -> Color:
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


func _used_region(source: Image) -> Image:
	var used := source.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		push_error("Generated source has no opaque pixels")
		quit(1)
		return source.duplicate()
	return source.get_region(used)


func _build_strip(source: Image, base_height: int, cap_width: int, middle_width: int, _right_width: int) -> Image:
	var used := _used_region(source)
	var source_width := used.get_width()
	var source_height := used.get_height()
	var cap_source_width := maxi(1, int(round(float(source_width) * 0.115)))
	var middle_source_width := maxi(1, int(round(float(source_width) * 0.25)))
	var middle_source_x := (source_width - middle_source_width) / 2

	var left := used.get_region(Rect2i(0, 0, cap_source_width, source_height))
	var middle := used.get_region(Rect2i(middle_source_x, 0, middle_source_width, source_height))
	var right := used.get_region(Rect2i(source_width - cap_source_width, 0, cap_source_width, source_height))
	left.resize(cap_width, base_height, Image.INTERPOLATE_LANCZOS)
	middle.resize(middle_width, base_height, Image.INTERPOLATE_LANCZOS)
	right.resize(cap_width, base_height, Image.INTERPOLATE_LANCZOS)
	_reduce_palette(left, true)
	_reduce_palette(middle, true)
	_reduce_palette(right, true)
	_make_middle_seamless(middle)
	_match_inner_edge(left, middle, true)
	_match_inner_edge(right, middle, false)

	var strip := Image.create(cap_width + middle_width + cap_width, base_height, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0.0, 0.0, 0.0, 0.0))
	strip.blit_rect(left, left.get_used_rect(), Vector2i.ZERO)
	strip.blit_rect(middle, Rect2i(Vector2i.ZERO, middle.get_size()), Vector2i(cap_width, 0))
	strip.blit_rect(right, right.get_used_rect(), Vector2i(cap_width + middle_width, 0))
	strip.resize(strip.get_width() * 2, strip.get_height() * 2, Image.INTERPOLATE_NEAREST)
	return strip


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


func _build_portal(source: Image) -> Image:
	var used := _used_region(source)
	var side := maxi(used.get_width(), used.get_height())
	var square := Image.create(side, side, false, Image.FORMAT_RGBA8)
	square.fill(Color(0.0, 0.0, 0.0, 0.0))
	square.blend_rect(used, Rect2i(Vector2i.ZERO, used.get_size()), Vector2i((side - used.get_width()) / 2, (side - used.get_height()) / 2))
	square.resize(48, 48, Image.INTERPOLATE_LANCZOS)
	_reduce_palette(square, true)
	square.resize(96, 96, Image.INTERPOLATE_NEAREST)
	return square


func _compose_mock(far: Image, mid: Image, main_strip: Image, sub_strip: Image, portal: Image) -> Image:
	var mock := far.duplicate()
	mock.blend_rect(mid, Rect2i(Vector2i.ZERO, mid.get_size()), Vector2i.ZERO)
	for point in PORTALS:
		mock.blend_rect(portal, Rect2i(Vector2i.ZERO, portal.get_size()), point - Vector2i(48, 96))
	for platform in PLATFORMS:
		var center: Vector2i = platform[0]
		var size: Vector2i = platform[1]
		var is_main: bool = platform[2]
		var strip := main_strip if is_main else sub_strip
		var margins := Vector3i(MAIN_LEFT, MAIN_MIDDLE, MAIN_RIGHT) if is_main else Vector3i(SUB_LEFT, SUB_MIDDLE, SUB_RIGHT)
		_draw_three_slice(mock, strip, Rect2i(center - size / 2, size), margins)
	_add_fighters(mock)
	return mock


func _draw_three_slice(target: Image, strip: Image, rect: Rect2i, margins: Vector3i) -> void:
	var left := strip.get_region(Rect2i(0, 0, margins.x, strip.get_height()))
	var middle := strip.get_region(Rect2i(margins.x, 0, margins.y, strip.get_height()))
	var right := strip.get_region(Rect2i(margins.x + margins.y, 0, margins.z, strip.get_height()))
	var cap_width := mini(rect.size.y, rect.size.x / 2)
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


func _add_fighters(target: Image) -> void:
	var frey_sheet := _load_image(ProjectSettings.globalize_path("res://assets/characters/frey/frey_prototype.png"))
	var yuki_sheet := _load_image(ProjectSettings.globalize_path("res://assets/characters/yuki/idle.png"))
	var frey := _used_region(frey_sheet.get_region(Rect2i(0, 0, 64, 64)))
	var yuki := _used_region(yuki_sheet.get_region(Rect2i(0, 0, 128, 128)))
	_resize_to_height(frey, 96)
	_resize_to_height(yuki, 96)
	var frey_foot := Vector2i(800, 913)
	var yuki_foot := Vector2i(960, 504)
	target.blend_rect(frey, Rect2i(Vector2i.ZERO, frey.get_size()), frey_foot - Vector2i(frey.get_width() / 2, frey.get_height()))
	target.blend_rect(yuki, Rect2i(Vector2i.ZERO, yuki.get_size()), yuki_foot - Vector2i(yuki.get_width() / 2, yuki.get_height()))


func _resize_to_height(image: Image, height: int) -> void:
	var width := maxi(1, int(round(float(image.get_width()) * float(height) / float(image.get_height()))))
	image.resize(width, height, Image.INTERPOLATE_NEAREST)


func _compose_contact_sheet(mock: Image, far: Image, mid: Image, main_strip: Image, sub_strip: Image, portal: Image) -> Image:
	var sheet := Image.create(1920, 1520, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("090715"))
	sheet.blit_rect(mock, Rect2i(Vector2i.ZERO, mock.get_size()), Vector2i.ZERO)
	var far_thumb := far.duplicate()
	far_thumb.resize(480, 270, Image.INTERPOLATE_NEAREST)
	sheet.blit_rect(far_thumb, Rect2i(Vector2i.ZERO, far_thumb.get_size()), Vector2i(40, 1120))
	_draw_checker(sheet, Rect2i(550, 1120, 480, 270), 16)
	var mid_thumb := mid.duplicate()
	mid_thumb.resize(480, 270, Image.INTERPOLATE_NEAREST)
	sheet.blend_rect(mid_thumb, Rect2i(Vector2i.ZERO, mid_thumb.get_size()), Vector2i(550, 1120))
	var main_preview := main_strip.duplicate()
	main_preview.resize(main_preview.get_width() * 3, main_preview.get_height() * 3, Image.INTERPOLATE_NEAREST)
	sheet.blend_rect(main_preview, Rect2i(Vector2i.ZERO, main_preview.get_size()), Vector2i(1060, 1110))
	var sub_preview := sub_strip.duplicate()
	sub_preview.resize(sub_preview.get_width() * 4, sub_preview.get_height() * 4, Image.INTERPOLATE_NEAREST)
	sheet.blend_rect(sub_preview, Rect2i(Vector2i.ZERO, sub_preview.get_size()), Vector2i(1060, 1300))
	var portal_preview := portal.duplicate()
	portal_preview.resize(192, 192, Image.INTERPOLATE_NEAREST)
	sheet.blend_rect(portal_preview, Rect2i(Vector2i.ZERO, portal_preview.get_size()), Vector2i(1700, 1290))
	return sheet


func _draw_checker(target: Image, rect: Rect2i, cell: int) -> void:
	for y in range(rect.position.y, rect.end.y, cell):
		for x in range(rect.position.x, rect.end.x, cell):
			var index := ((x - rect.position.x) / cell + (y - rect.position.y) / cell) as int
			var color := Color("201b2a") if index % 2 == 0 else Color("332a3f")
			target.fill_rect(Rect2i(x, y, mini(cell, rect.end.x - x), mini(cell, rect.end.y - y)), color)


func _save(image: Image, path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	var error := image.save_png(absolute)
	if error != OK:
		push_error("Failed to save " + absolute + ": " + error_string(error))
		quit(1)
