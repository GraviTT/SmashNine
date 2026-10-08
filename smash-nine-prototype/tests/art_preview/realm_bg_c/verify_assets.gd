extends SceneTree

const EXPECTED := {
	"center": Vector2i(2880, 1620),
	"asgard": Vector2i(1920, 1080),
	"midgard": Vector2i(1920, 1080),
	"niflheim": Vector2i(1920, 1080),
	"alfheim": Vector2i(1920, 1080),
	"muspelheim": Vector2i(1920, 1080),
	"svartalfheim": Vector2i(1920, 1080),
	"vanaheim": Vector2i(1920, 1080),
	"jotunheim": Vector2i(1920, 1080),
}

func _init() -> void:
	var failures: Array[String] = []
	for realm in EXPECTED:
		var expected: Vector2i = EXPECTED[realm]
		var dir := "res://assets/art/realm_%s" % realm
		var far := Image.load_from_file(dir + "/bg_far.png")
		var mid := Image.load_from_file(dir + "/bg_mid.png")
		if far.get_size() != expected or mid.get_size() != expected:
			failures.append("%s size: far=%s mid=%s expected=%s" % [realm, far.get_size(), mid.get_size(), expected])
		if not _grid_2(far) or not _grid_2(mid):
			failures.append("%s does not use a strict 2x2 pixel grid" % realm)
		if not _opaque(far):
			failures.append("%s bg_far is not fully opaque" % realm)
		var center_clear := _center_clear(mid)
		if center_clear < 95.0:
			failures.append("%s bg_mid center clear %.2f%% < 95%%" % [realm, center_clear])
		print("VERIFY ", realm, " size=", expected, " center_clear=", snapped(center_clear, 0.01), "%")
	if failures.is_empty():
		print("REALM_BG_C_VERIFY PASS (9 realms, 18 PNGs)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _grid_2(image: Image) -> bool:
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			var c := image.get_pixel(x, y)
			if c != image.get_pixel(x + 1, y) or c != image.get_pixel(x, y + 1) or c != image.get_pixel(x + 1, y + 1):
				return false
	return true

func _opaque(image: Image) -> bool:
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.999:
				return false
	return true

func _center_clear(image: Image) -> float:
	var x0 := int(image.get_width() * 0.25)
	var x1 := int(image.get_width() * 0.75)
	var y0 := int(image.get_height() * 0.20)
	var y1 := int(image.get_height() * 0.90)
	var clear := 0
	for y in range(y0, y1):
		for x in range(x0, x1):
			if image.get_pixel(x, y).a == 0.0:
				clear += 1
	return 100.0 * float(clear) / float((x1 - x0) * (y1 - y0))
