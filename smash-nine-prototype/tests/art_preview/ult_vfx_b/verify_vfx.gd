extends SceneTree

const VFX_DIR := "res://assets/art/vfx/"

const SPECS := [
	{"id": "frey_ult_charge", "frames": 6, "frame": Vector2i(128, 128)},
	{"id": "frey_ult_wave", "frames": 8, "frame": Vector2i(256, 96)},
	{"id": "yuki_ult_seal", "frames": 8, "frame": Vector2i(256, 256)},
	{"id": "yuki_ult_burst", "frames": 6, "frame": Vector2i(256, 256)},
	{"id": "luna_ult_transform", "frames": 8, "frame": Vector2i(192, 192)},
	{"id": "luna_ult_laser", "frames": 4, "frame": Vector2i(128, 96), "tile_x": true},
	{"id": "luna_ult_laser_head", "frames": 4, "frame": Vector2i(96, 96)},
	{"id": "nova_ult_core", "frames": 6, "frame": Vector2i(128, 128)},
	{"id": "nova_ult_burst", "frames": 8, "frame": Vector2i(256, 256)},
	{"id": "rio_ult_circle", "frames": 6, "frame": Vector2i(192, 192)},
	{"id": "rio_ult_impact", "frames": 6, "frame": Vector2i(64, 64)},
]

func _init() -> void:
	var failures := 0
	for spec in SPECS:
		failures += _verify_strip(spec)
	var cutin := Image.load_from_file(VFX_DIR + "ult_cutin_band.png")
	if cutin.is_empty() or cutin.get_size() != Vector2i(640, 112):
		push_error("ult_cutin_band.png has invalid size")
		failures += 1
	else:
		print("[ult-vfx-verify] ult_cutin_band.png size=640x112 optional=PASS")
	if failures == 0:
		print("[ult-vfx-verify] PASS assets=%d frames=70 optional=1" % SPECS.size())
	quit(1 if failures > 0 else 0)

func _verify_strip(spec: Dictionary) -> int:
	var id := String(spec.id)
	var frame_size: Vector2i = spec.frame
	var expected := Vector2i(frame_size.x * int(spec.frames), frame_size.y)
	var image := Image.load_from_file(VFX_DIR + id + ".png")
	if image.is_empty() or image.get_size() != expected or image.get_format() != Image.FORMAT_RGBA8:
		push_error("%s invalid size/format: got=%s expected=%s format=%s" % [id, image.get_size(), expected, image.get_format()])
		return 1
	var min_margin := Vector4i(9999, 9999, 9999, 9999)
	for frame_index in int(spec.frames):
		var frame := image.get_region(Rect2i(frame_index * frame_size.x, 0, frame_size.x, frame_size.y))
		var used := frame.get_used_rect()
		if used.size == Vector2i.ZERO:
			push_error("%s frame %d is empty" % [id, frame_index])
			return 1
		var margins := Vector4i(used.position.x, used.position.y, frame_size.x - used.end.x, frame_size.y - used.end.y)
		min_margin.x = mini(min_margin.x, margins.x)
		min_margin.y = mini(min_margin.y, margins.y)
		min_margin.z = mini(min_margin.z, margins.z)
		min_margin.w = mini(min_margin.w, margins.w)
		var tile_x := bool(spec.get("tile_x", false))
		if margins.y < 2 or margins.w < 2 or (not tile_x and (margins.x < 2 or margins.z < 2)):
			push_error("%s frame %d unsafe margins=%s" % [id, frame_index, margins])
			return 1
		if tile_x and not _matching_horizontal_edges(frame):
			push_error("%s frame %d is not horizontally seamless" % [id, frame_index])
			return 1
	print("[ult-vfx-verify] %s frames=%d frame=%dx%d margins(LTRB)=%s" % [id, int(spec.frames), frame_size.x, frame_size.y, min_margin])
	return 0

func _matching_horizontal_edges(image: Image) -> bool:
	for y in image.get_height():
		if image.get_pixel(0, y) != image.get_pixel(image.get_width() - 1, y):
			return false
	return true
