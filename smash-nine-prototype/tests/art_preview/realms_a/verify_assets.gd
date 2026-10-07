extends SceneTree

const EXPECTED := {
	"asgard": {"main": Vector2i(232, 52), "sub": Vector2i(160, 32)},
	"midgard": {"main": Vector2i(220, 46), "sub": Vector2i(160, 32), "bush": Vector2i(160, 72)},
	"niflheim": {"main": Vector2i(216, 44), "sub": Vector2i(160, 32)},
	"alfheim": {"main": Vector2i(220, 46), "sub": Vector2i(160, 32)}
}


func _initialize() -> void:
	var failures: Array[String] = []
	for realm: String in EXPECTED:
		var directory := "res://assets/art/realm_%s" % realm
		_check_image(directory + "/bg_far.png", Vector2i(1280, 720), false, failures)
		_check_image(directory + "/bg_mid.png", Vector2i(1280, 720), true, failures)
		_check_image(directory + "/platform_main.png", EXPECTED[realm].main, true, failures)
		_check_image(directory + "/platform_sub.png", EXPECTED[realm].sub, true, failures)
		if EXPECTED[realm].has("bush"):
			_check_image(directory + "/bush.png", EXPECTED[realm].bush, true, failures)
		print("VERIFY_REALM ", realm, " expected=", EXPECTED[realm])
	for realm: String in EXPECTED:
		_check_image("../reports/codex-art-04a/%s_preview.png" % realm, Vector2i(1280, 720), false, failures)
	_check_image("../reports/codex-art-04a/contact_sheet.png", Vector2i(1280, 720), false, failures)
	if failures.is_empty():
		print("ART04A_VERIFY_OK realms=4 previews=4 contact_sheet=1")
		quit()
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _check_image(path: String, expected_size: Vector2i, needs_transparency: bool, failures: Array[String]) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		failures.append("Missing or unreadable: " + path)
		return
	if image.get_size() != expected_size:
		failures.append("Wrong size %s: got %s expected %s" % [path, image.get_size(), expected_size])
	if image.get_format() != Image.FORMAT_RGBA8:
		failures.append("Wrong format %s: got %s expected RGBA8" % [path, image.get_format()])
	var has_transparent := false
	var has_opaque := false
	for y in image.get_height():
		for x in image.get_width():
			var alpha := image.get_pixel(x, y).a
			has_transparent = has_transparent or alpha < 0.01
			has_opaque = has_opaque or alpha > 0.99
			if has_transparent and has_opaque:
				break
		if has_transparent and has_opaque:
			break
	if needs_transparency and not has_transparent:
		failures.append("Transparency missing: " + path)
	if not needs_transparency and has_transparent:
		failures.append("Unexpected transparency: " + path)
	if not has_opaque:
		failures.append("No opaque pixels: " + path)
