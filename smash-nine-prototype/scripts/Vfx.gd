extends RefCounted
## Ultimate effect strips (assets/art/vfx/, CODEX-ART-10): each file is a horizontal strip of
## equal frames. spawn() turns one into an AnimatedSprite2D whose anchor point (from the art's
## README) sits on the given position; a one-shot effect frees itself after its last frame.
## Missing art, or the plain procedural style (F2), returns null so callers keep their shapes.
## Basic attack and skill strips (assets/art/attack_vfx/, CODEX-ART-13) use the same calls.

const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const DIR := "res://assets/art/vfx/%s.png"
const ATTACK_DIR := "res://assets/art/attack_vfx/%s.png"
## name: [frames, fps, anchor in the frame, additive(, folder pattern when not DIR)]
const SPECS := {
	"frey_ult_charge": [6, 24.0, Vector2(64, 124), true],
	"frey_ult_wave": [8, 30.0, Vector2(0, 96), true],
	"yuki_ult_seal": [8, 12.0, Vector2(128, 128), false],
	"yuki_ult_burst": [6, 30.0, Vector2(128, 128), true],
	"luna_ult_transform": [8, 24.0, Vector2(96, 96), true],
	"luna_ult_laser": [4, 24.0, Vector2(0, 48), true],
	"luna_ult_laser_head": [4, 24.0, Vector2(48, 48), true],
	"nova_ult_core": [6, 18.0, Vector2(64, 64), false],
	"nova_ult_burst": [8, 48.0, Vector2(128, 128), false],
	"rio_ult_circle": [6, 18.0, Vector2(96, 96), true],
	"rio_ult_impact": [6, 36.0, Vector2(32, 32), true],
	"frey_slash": [6, 36.0, Vector2(0, 64), true, ATTACK_DIR],
	"frey_k": [6, 30.0, Vector2(0, 48), true, ATTACK_DIR],
	"frey_l": [6, 30.0, Vector2(64, 188), true, ATTACK_DIR],
	"yuki_slash": [6, 30.0, Vector2(0, 64), true, ATTACK_DIR],
	"yuki_k": [6, 18.0, Vector2(64, 64), false, ATTACK_DIR],
	"yuki_l": [6, 24.0, Vector2(96, 96), true, ATTACK_DIR],
	"luna_slash": [6, 30.0, Vector2(0, 64), true, ATTACK_DIR],
	"luna_k": [6, 30.0, Vector2(0, 48), true, ATTACK_DIR],
	"luna_l": [6, 24.0, Vector2(96, 96), true, ATTACK_DIR],
	"luna_brave_slash": [6, 36.0, Vector2(0, 64), true, ATTACK_DIR],
	"nova_slash": [6, 36.0, Vector2(0, 64), true, ATTACK_DIR],
	"nova_k": [6, 30.0, Vector2(0, 48), true, ATTACK_DIR],
	"nova_l": [6, 24.0, Vector2(96, 188), false, ATTACK_DIR],
	"rio_slash": [6, 36.0, Vector2(0, 64), true, ATTACK_DIR],
	"rio_k": [6, 30.0, Vector2(0, 48), true, ATTACK_DIR],
	"rio_l": [6, 18.0, Vector2(0, 80), false, ATTACK_DIR],
}

## Frame widths the anchors and callers' scales were written for. A strip redrawn bigger
## (CODEX-ART-14/16: frames twice as large at 1x density) is drawn smaller by the ratio, so
## the same call shows it at the same size with finer pixels.
const AUTHORED_WIDTH := {
	"frey_ult_charge": 128, "frey_ult_wave": 256, "yuki_ult_seal": 256, "yuki_ult_burst": 256,
	"luna_ult_transform": 192, "luna_ult_laser": 128, "luna_ult_laser_head": 96, "nova_ult_core": 128,
	"nova_ult_burst": 256, "rio_ult_circle": 192, "rio_ult_impact": 64,
	"frey_slash": 192, "frey_k": 224, "frey_l": 128, "yuki_slash": 192, "yuki_k": 128, "yuki_l": 192,
	"luna_slash": 192, "luna_k": 160, "luna_l": 192, "luna_brave_slash": 224, "nova_slash": 160,
	"nova_k": 224, "nova_l": 192, "rio_slash": 192, "rio_k": 256, "rio_l": 128,
}

static var _cache: Dictionary = {}
static var _additive: CanvasItemMaterial

## local = true places the effect at `at` in the parent's space (it follows a moving parent).
static func spawn(parent: Node, effect: String, at: Vector2, scale := Vector2.ONE, loop := false, z := 4, tint := Color.WHITE, local := false) -> AnimatedSprite2D:
	var frames := _frames(effect, loop)
	if frames == null or parent == null:
		return null
	var spec: Array = SPECS[effect]
	var ratio := size_ratio(effect)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Vfx_%s" % effect
	sprite.add_to_group("vfx")
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.offset = -spec[2] * ratio
	sprite.scale = scale / ratio
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = z
	sprite.modulate = tint
	if bool(spec[3]):
		sprite.material = _additive_material()
	parent.add_child(sprite)
	if local:
		sprite.position = at
	else:
		sprite.global_position = at
	sprite.play(&"play")
	if not loop:
		sprite.animation_finished.connect(sprite.queue_free)
	return sprite

## True when the effect art will draw (art present and the original style on).
static func available(effect: String) -> bool:
	return _frames(effect, false) != null

## The strip's frames as separate textures (for tiling a beam), or an empty array.
static func frame_textures(effect: String) -> Array[Texture2D]:
	var key := "%s/textures" % effect
	if not ART_SETTINGS.use_original():
		return [] as Array[Texture2D]
	if _cache.has(key):
		return _cache[key]
	var result: Array[Texture2D] = []
	var texture := ART_SETTINGS.original_texture(_path(effect))
	if texture != null:
		var image := texture.get_image()
		var count := int(SPECS[effect][0])
		var width := image.get_width() / count
		for index in count:
			result.append(ImageTexture.create_from_image(image.get_region(Rect2i(index * width, 0, width, image.get_height()))))
	_cache[key] = result
	return result

static func fps(effect: String) -> float:
	return float(SPECS[effect][1])

static func _frames(effect: String, loop: bool) -> SpriteFrames:
	if not SPECS.has(effect):
		push_warning("Unknown effect %s" % effect)
		return null
	var key := "%s/%s" % [effect, loop]
	# The style can change at runtime (F2), so it is checked before the cache.
	if not ART_SETTINGS.use_original():
		return null
	if _cache.has(key):
		return _cache[key]
	var texture := ART_SETTINGS.original_texture(_path(effect))
	if texture == null:
		return null
	var spec: Array = SPECS[effect]
	var count := int(spec[0])
	var size := Vector2i(texture.get_width() / count, texture.get_height())
	var frames := SpriteFrames.new()
	frames.clear_all()
	frames.add_animation(&"play")
	frames.set_animation_speed(&"play", float(spec[1]))
	frames.set_animation_loop(&"play", loop)
	for index in count:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(index * size.x, 0, size.x, size.y)
		frames.add_frame(&"play", frame)
	_cache[key] = frames
	return frames

static func _path(effect: String) -> String:
	var spec: Array = SPECS[effect]
	return (spec[4] if spec.size() > 4 else DIR) % effect

## Frame width of an effect strip as callers measure it (the authored width; 0 when the art
## is missing). spawn() turns that into the file's real size.
static func frame_width(effect: String) -> float:
	var frames := _frames(effect, false)
	if frames == null:
		return 0.0
	return float(AUTHORED_WIDTH.get(effect, frames.get_frame_texture(&"play", 0).get_width()))

## Real frame width over the authored one (2 for a strip redrawn twice as large).
static func size_ratio(effect: String) -> float:
	var frames := _frames(effect, false)
	if frames == null or not AUTHORED_WIDTH.has(effect):
		return 1.0
	return float(frames.get_frame_texture(&"play", 0).get_width()) / float(AUTHORED_WIDTH[effect])

static func _additive_material() -> CanvasItemMaterial:
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive
