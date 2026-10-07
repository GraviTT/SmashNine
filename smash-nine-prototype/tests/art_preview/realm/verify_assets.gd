extends SceneTree

const ASSET_DIR := "res://assets/art/realm_center"

const EXPECTED := {
	"bg_far.png": Vector2i(1920, 1080),
	"bg_mid.png": Vector2i(1920, 1080),
	"platform_main.png": Vector2i(236, 54),
	"platform_sub.png": Vector2i(160, 32),
	"portal.png": Vector2i(96, 96),
	"contact_sheet.png": Vector2i(1920, 1520)
}


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var failed := false
	for file_name in EXPECTED:
		var image := Image.load_from_file(ProjectSettings.globalize_path(ASSET_DIR + "/" + file_name))
		if image == null or image.is_empty():
			push_error("Missing image: " + file_name)
			failed = true
			continue
		image.convert(Image.FORMAT_RGBA8)
		var stats := _stats(image)
		var size_ok: bool = image.get_size() == EXPECTED[file_name]
		var grid_ok := _is_two_pixel_grid(image) if file_name != "contact_sheet.png" else true
		print("ART_VERIFY file=", file_name, " size=", image.get_size(), " size_ok=", size_ok, " rgba_colours=", stats.colours, " transparent=", stats.transparent, " translucent=", stats.translucent, " opaque=", stats.opaque, " grid_2x=", grid_ok)
		if not size_ok or not grid_ok:
			failed = true

	var far := Image.load_from_file(ProjectSettings.globalize_path(ASSET_DIR + "/bg_far.png"))
	if _stats(far).transparent != 0 or _stats(far).translucent != 0:
		push_error("bg_far.png must be fully opaque")
		failed = true

	var main := Image.load_from_file(ProjectSettings.globalize_path(ASSET_DIR + "/platform_main.png"))
	var sub := Image.load_from_file(ProjectSettings.globalize_path(ASSET_DIR + "/platform_sub.png"))
	var main_seam := _columns_equal(main, 54, 54 + 128 - 1)
	var sub_seam := _columns_equal(sub, 32, 32 + 96 - 1)
	print("ART_VERIFY seam_main=", main_seam, " seam_sub=", sub_seam)
	if not main_seam or not sub_seam:
		failed = true

	var preview := Image.load_from_file(ProjectSettings.globalize_path("../reports/codex-art-01/realm_preview.png"))
	var preview_ok := preview != null and preview.get_size() == Vector2i(1920, 1080)
	print("ART_VERIFY preview_size=", preview.get_size() if preview != null else Vector2i.ZERO, " preview_ok=", preview_ok)
	if not preview_ok:
		failed = true

	if failed:
		quit(1)
		return
	print("ART_VERIFY_OK")
	quit()


func _stats(image: Image) -> Dictionary:
	var colours: Dictionary = {}
	var transparent := 0
	var translucent := 0
	var opaque := 0
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			var red := clampi(int(round(color.r * 255.0)), 0, 255)
			var green := clampi(int(round(color.g * 255.0)), 0, 255)
			var blue := clampi(int(round(color.b * 255.0)), 0, 255)
			var alpha := clampi(int(round(color.a * 255.0)), 0, 255)
			var key := (red << 24) | (green << 16) | (blue << 8) | alpha
			colours[key] = true
			if alpha == 0:
				transparent += 1
			elif alpha == 255:
				opaque += 1
			else:
				translucent += 1
	return {"colours": colours.size(), "transparent": transparent, "translucent": translucent, "opaque": opaque}


func _is_two_pixel_grid(image: Image) -> bool:
	if image.get_width() % 2 != 0 or image.get_height() % 2 != 0:
		return false
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			var color := image.get_pixel(x, y)
			if image.get_pixel(x + 1, y) != color or image.get_pixel(x, y + 1) != color or image.get_pixel(x + 1, y + 1) != color:
				return false
	return true


func _columns_equal(image: Image, left_x: int, right_x: int) -> bool:
	for y in image.get_height():
		if image.get_pixel(left_x, y) != image.get_pixel(right_x, y):
			return false
	return true
