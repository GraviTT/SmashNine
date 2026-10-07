extends SceneTree

const ROOT := "res://assets/art"
const SPECS := {
	"muspelheim": {"main": Vector2i(200, 52), "cap": 52},
	"svartalfheim": {"main": Vector2i(184, 44), "cap": 44},
	"vanaheim": {"main": Vector2i(188, 46), "cap": 46},
	"jotunheim": {"main": Vector2i(188, 46), "cap": 46}
}


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var failed := false
	for slug in SPECS:
		var spec: Dictionary = SPECS[slug]
		var dir := "%s/realm_%s" % [ROOT, slug]
		var far := _load(dir + "/bg_far.png")
		var mid := _load(dir + "/bg_mid.png")
		var main := _load(dir + "/platform_main.png")
		var sub := _load(dir + "/platform_sub.png")
		failed = _expect(far.get_size() == Vector2i(1280, 720), slug + " bg_far size") or failed
		failed = _expect(mid.get_size() == Vector2i(1280, 720), slug + " bg_mid size") or failed
		failed = _expect(main.get_size() == spec.main, slug + " main strip size") or failed
		failed = _expect(sub.get_size() == Vector2i(160, 32), slug + " sub strip size") or failed
		failed = _expect(_transparent_pixels(far) == 0, slug + " bg_far opaque") or failed
		var mid_transparent := _transparent_pixels(mid)
		failed = _expect(mid_transparent > 1280 * 720 / 2, slug + " bg_mid majority transparent") or failed
		failed = _expect(_middle_edges_match(main, spec.cap), slug + " main repeat seam") or failed
		failed = _expect(_middle_edges_match(sub, 32), slug + " sub repeat seam") or failed
		print("VERIFY_REALM ", slug, " far_transparent=", _transparent_pixels(far), " mid_transparent=", mid_transparent, " mid_ratio=", snappedf(float(mid_transparent) / float(1280 * 720), 0.001))
	if failed:
		quit(1)
	else:
		print("VERIFY_OK realms=4 files=16")
		quit()


func _load(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		push_error("Unable to load " + path)
		quit(1)
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _transparent_pixels(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.01:
				count += 1
	return count


func _middle_edges_match(strip: Image, cap: int) -> bool:
	var left_x := cap
	var right_x := strip.get_width() - cap - 1
	for y in strip.get_height():
		if strip.get_pixel(left_x, y) != strip.get_pixel(right_x, y):
			return false
	return true


func _expect(condition: bool, label: String) -> bool:
	if condition:
		return false
	push_error("VERIFY_FAIL " + label)
	return true
