extends SceneTree

const EFFECT_DIR := "res://assets/art/effects/"
const VFX_DIR := "res://assets/art/vfx/"

const SPECS := [
	{"path": EFFECT_DIR + "hit_spark.png", "frame": Vector2i(96,96), "frames": 4},
	{"path": EFFECT_DIR + "luna_star.png", "frame": Vector2i(96,96), "frames": 1},
	{"path": EFFECT_DIR + "yuki_talisman.png", "frame": Vector2i(128,64), "frames": 1},
	{"path": EFFECT_DIR + "rio_gem_sword.png", "frame": Vector2i(96,32), "frames": 1},
	{"path": EFFECT_DIR + "rio_mana_wave.png", "frame": Vector2i(48,112), "frames": 1},
	{"path": VFX_DIR + "frey_ult_charge.png", "frame": Vector2i(256,256), "frames": 6},
	{"path": VFX_DIR + "frey_ult_wave.png", "frame": Vector2i(512,192), "frames": 8},
	{"path": VFX_DIR + "yuki_ult_seal.png", "frame": Vector2i(512,512), "frames": 8},
	{"path": VFX_DIR + "yuki_ult_burst.png", "frame": Vector2i(512,512), "frames": 6},
	{"path": VFX_DIR + "luna_ult_transform.png", "frame": Vector2i(384,384), "frames": 8},
	{"path": VFX_DIR + "luna_ult_laser.png", "frame": Vector2i(256,192), "frames": 4, "tile_x": true},
	{"path": VFX_DIR + "luna_ult_laser_head.png", "frame": Vector2i(192,192), "frames": 4},
	{"path": VFX_DIR + "nova_ult_core.png", "frame": Vector2i(256,256), "frames": 6},
	{"path": VFX_DIR + "nova_ult_burst.png", "frame": Vector2i(512,512), "frames": 8},
	{"path": VFX_DIR + "rio_ult_circle.png", "frame": Vector2i(384,384), "frames": 6},
	{"path": VFX_DIR + "rio_ult_impact.png", "frame": Vector2i(128,128), "frames": 6},
]

func _init() -> void:
	var failures := 0
	for spec in SPECS:
		failures += _verify(spec)
	if failures == 0:
		print("[fx-1x-verify] PASS assets=16 frames=78 rgba8=binary-alpha margins=PASS")
	quit(0 if failures == 0 else 1)

func _verify(spec: Dictionary) -> int:
	var image := Image.load_from_file(String(spec.path))
	var frame_size: Vector2i = spec.frame
	var expected := Vector2i(frame_size.x * int(spec.frames), frame_size.y)
	if image.is_empty() or image.get_size() != expected or image.get_format() != Image.FORMAT_RGBA8:
		push_error("invalid image %s got=%s expected=%s format=%s" % [spec.path, image.get_size(), expected, image.get_format()])
		return 1
	var minimum := Vector4i(9999,9999,9999,9999)
	var colors := {}
	for index in int(spec.frames):
		var frame := image.get_region(Rect2i(index * frame_size.x, 0, frame_size.x, frame_size.y))
		var used := frame.get_used_rect()
		if used.size == Vector2i.ZERO:
			push_error("empty frame %s:%d" % [spec.path, index])
			return 1
		var margins := Vector4i(used.position.x, used.position.y, frame_size.x - used.end.x, frame_size.y - used.end.y)
		minimum.x = mini(minimum.x, margins.x)
		minimum.y = mini(minimum.y, margins.y)
		minimum.z = mini(minimum.z, margins.z)
		minimum.w = mini(minimum.w, margins.w)
		var tile_x := bool(spec.get("tile_x", false))
		if margins.y < 3 or margins.w < 3 or (not tile_x and (margins.x < 3 or margins.z < 3)):
			push_error("unsafe margin %s:%d %s" % [spec.path, index, margins])
			return 1
		if tile_x and not _seam_matches(frame):
			push_error("tile seam mismatch %s:%d" % [spec.path, index])
			return 1
		for y in frame.get_height():
			for x in frame.get_width():
				var color := frame.get_pixel(x, y)
				if color.a != 0.0 and color.a != 1.0:
					push_error("non-binary alpha %s:%d" % [spec.path, index])
					return 1
				if color.a > 0.0:
					colors[color.to_html(false)] = true
	print("[fx-1x-verify] %s size=%dx%d frames=%d margin(LTRB)=%s colors=%d" % [String(spec.path).get_file(), expected.x, expected.y, int(spec.frames), minimum, colors.size()])
	return 0

func _seam_matches(image: Image) -> bool:
	for y in image.get_height():
		if image.get_pixel(0, y) != image.get_pixel(image.get_width() - 1, y):
			return false
	return true
