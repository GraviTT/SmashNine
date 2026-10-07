extends SceneTree

const ASSETS := {
	"vine_bridge.png": Vector2i(96, 24),
	"light_beam.png": Vector2i(64, 128),
	"fire_pillar.png": Vector2i(64, 128),
	"vent_glyph.png": Vector2i(80, 16)
}


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var failures: Array[String] = []
	for filename in ASSETS:
		var image := _load("res://assets/art/hazards/" + filename, failures)
		if image == null:
			continue
		print("VERIFY_ASSET ", filename, " size=", image.get_size(), " alpha=", _alpha_stats(image))
		if image.get_size() != ASSETS[filename]:
			failures.append("Wrong size %s: %s" % [filename, image.get_size()])
		if image.get_format() != Image.FORMAT_RGBA8:
			failures.append("Not RGBA8: " + filename)
		if not _has_alpha_range(image):
			failures.append("Missing transparent or opaque pixels: " + filename)
		if not _uses_two_pixel_grid(image):
			failures.append("Broken 2x pixel grid: " + filename)
	if not _horizontal_seam(_load("res://assets/art/hazards/vine_bridge.png", failures), 24, 48):
		failures.append("Vine middle is not horizontally seamless")
	for filename in ["light_beam.png", "fire_pillar.png"]:
		if not _vertical_seam(_load("res://assets/art/hazards/" + filename, failures)):
			failures.append("Vertical seam mismatch: " + filename)
	var preview := _load("res://../reports/codex-art-07/hazards_preview.png", failures)
	if preview != null and preview.get_size() != Vector2i(2560, 1440):
		failures.append("Wrong preview size: " + str(preview.get_size()))
	if failures.is_empty():
		print("HAZARD_VERIFY_OK assets=4 sizes=96x24,64x128,64x128,80x16 seams=3 grid=2x preview=2560x1440")
		quit()
		return
	for failure in failures:
		push_error("HAZARD_VERIFY_FAIL " + failure)
	quit(1)


func _load(path: String, failures: Array[String]) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		failures.append("Missing or unreadable: " + path)
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image


func _has_alpha_range(image: Image) -> bool:
	var transparent := false
	var opaque := false
	for y in image.get_height():
		for x in image.get_width():
			var alpha := image.get_pixel(x, y).a
			transparent = transparent or alpha < 0.01
			opaque = opaque or alpha > 0.99
			if transparent and opaque:
				return true
	return false


func _alpha_stats(image: Image) -> Dictionary:
	var result := {"transparent": 0, "partial": 0, "opaque": 0}
	for y in image.get_height():
		for x in image.get_width():
			var alpha := image.get_pixel(x, y).a
			if alpha < 0.01:
				result.transparent += 1
			elif alpha > 0.99:
				result.opaque += 1
			else:
				result.partial += 1
	return result


func _uses_two_pixel_grid(image: Image) -> bool:
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			var sample := image.get_pixel(x, y)
			for offset_y in mini(2, image.get_height() - y):
				for offset_x in mini(2, image.get_width() - x):
					if image.get_pixel(x + offset_x, y + offset_y) != sample:
						return false
	return true


func _horizontal_seam(image: Image, cap: int, middle: int) -> bool:
	if image == null:
		return false
	for y in image.get_height():
		if image.get_pixel(cap, y) != image.get_pixel(cap + middle - 1, y):
			return false
	return true


func _vertical_seam(image: Image) -> bool:
	if image == null:
		return false
	for x in image.get_width():
		if image.get_pixel(x, 0) != image.get_pixel(x, image.get_height() - 1):
			return false
	return true
