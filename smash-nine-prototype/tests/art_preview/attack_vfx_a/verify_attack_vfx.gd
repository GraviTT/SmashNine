extends SceneTree

const FRAME_COUNT := 6
const OUTPUT_DIR := "res://assets/art/attack_vfx"
const SPECS := {
	"frey_slash": Vector2i(192, 128), "frey_k": Vector2i(224, 96), "frey_l": Vector2i(128, 192),
	"yuki_slash": Vector2i(192, 128), "yuki_k": Vector2i(128, 128), "yuki_l": Vector2i(192, 192),
	"luna_slash": Vector2i(192, 128), "luna_k": Vector2i(160, 96), "luna_l": Vector2i(192, 192),
	"luna_brave_slash": Vector2i(224, 128),
	"nova_slash": Vector2i(160, 128), "nova_k": Vector2i(224, 96), "nova_l": Vector2i(192, 192),
	"rio_slash": Vector2i(192, 128), "rio_k": Vector2i(256, 96), "rio_l": Vector2i(128, 160),
}


func _init() -> void:
	var failures: Array[String] = []
	for effect_name in SPECS:
		_verify(effect_name, SPECS[effect_name], failures)
	if failures.is_empty():
		print("ATTACK_VFX_VERIFY_OK files=%d frames=%d" % [SPECS.size(), SPECS.size() * FRAME_COUNT])
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _verify(effect_name: String, frame_size: Vector2i, failures: Array[String]) -> void:
	var path := "%s/%s.png" % [OUTPUT_DIR, effect_name]
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		failures.append("missing or unreadable: %s" % path)
		return
	var expected := Vector2i(frame_size.x * FRAME_COUNT, frame_size.y)
	if image.get_size() != expected:
		failures.append("wrong size %s: got %s expected %s" % [effect_name, image.get_size(), expected])
		return
	if image.get_format() != Image.FORMAT_RGBA8:
		failures.append("wrong format %s: %s" % [effect_name, image.get_format()])
	var rgb_colors := {}
	var alpha_levels := {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.12:
				continue
			var rgb_key := (int(round(color.r * 255.0)) << 16) | (int(round(color.g * 255.0)) << 8) | int(round(color.b * 255.0))
			rgb_colors[rgb_key] = true
			alpha_levels[int(round(color.a * 255.0))] = true
	if rgb_colors.size() > 6:
		failures.append("palette over 6 colors %s: %d" % [effect_name, rgb_colors.size()])
	if alpha_levels.size() > 2:
		failures.append("alpha over 2 non-zero levels %s: %d" % [effect_name, alpha_levels.size()])
	var frame_summaries: Array[String] = []
	for frame_index in FRAME_COUNT:
		var frame := image.get_region(Rect2i(frame_index * frame_size.x, 0, frame_size.x, frame_size.y))
		var used := frame.get_used_rect()
		if used.size.x <= 0 or used.size.y <= 0:
			failures.append("empty frame %s[%d]" % [effect_name, frame_index])
			continue
		var margins := Vector4i(used.position.x, used.position.y, frame_size.x - used.end.x, frame_size.y - used.end.y)
		if margins.x < 3 or margins.y < 3 or margins.z < 3 or margins.w < 3:
			failures.append("margin under 3px %s[%d]: %s" % [effect_name, frame_index, margins])
		frame_summaries.append("%dx%d@%d,%d m=%d/%d/%d/%d" % [used.size.x, used.size.y, used.position.x, used.position.y, margins.x, margins.y, margins.z, margins.w])
	print("MEASURED %s strip=%dx%d frame=%dx%d palette=%d alpha_levels=%d | %s" % [effect_name, image.get_width(), image.get_height(), frame_size.x, frame_size.y, rgb_colors.size(), alpha_levels.size(), "; ".join(frame_summaries)])
