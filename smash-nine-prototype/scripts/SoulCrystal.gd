extends CharacterBody2D
## Soul crystal (concept panel 9, ROADMAP M2): floats over a realm spawn point, breaks
## after HITS_TO_BREAK landed attacks from fighters and pays SOUL_REWARD souls to the
## fighter who breaks it. It sits on the monster layer, so every attack can hit it,
## but it blocks no one. A CharacterBody2D that never moves: sweeping attack areas did
## not register a StaticBody2D (CODEX-ANALYST-03 P1, lead probe tests/analysis/lead/).

signal broken(crystal: Node, attacker: Node)

const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const SHEET_PATH := "res://assets/art/objects/soul_crystal.png"
const SHATTER_PATH := "res://assets/art/objects/soul_crystal_shatter.png"
const MONSTER_LAYER := 4
const HITS_TO_BREAK := 3
const SOUL_REWARD := 10
const ART_SCALE := 1.5
const CRYSTAL_COLOR := Color(0.72, 0.45, 1.0)

var realm_index := 0
var is_realm_active := true
var display_name := "Soul Crystal"
## Hits left; bots read "hp" like a monster's to know it is still standing.
var hp := float(HITS_TO_BREAK)
var max_hp := float(HITS_TO_BREAK)
var is_broken := false
var visual: Node2D
var float_time := 0.0

func setup(new_realm_index: int, spawn_position: Vector2) -> void:
	realm_index = new_realm_index
	global_position = spawn_position

func _ready() -> void:
	add_to_group("soul_crystals")
	collision_layer = MONSTER_LAYER
	collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	# The crystal floats over a spawn point (54-80 px above the platform), but its hitbox
	# hangs down to the floor: grounded swings land at about 34 px above the feet.
	shape.size = Vector2(40, 116)
	collision.shape = shape
	collision.position = Vector2(0, 6)
	add_child(collision)
	visual = _build_visual()
	add_child(visual)
	float_time = realm_index * 0.9

func _process(delta: float) -> void:
	float_time += delta
	if is_instance_valid(visual):
		visual.position.y = sin(float_time * 2.4) * 4.0

func _build_visual() -> Node2D:
	var sheet := ART_SETTINGS.original_texture(SHEET_PATH)
	if sheet != null:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = _strip_frames(sheet, &"shimmer", 6.0, true)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(ART_SCALE, ART_SCALE)
		# Strip cells are 48x64 with the crystal's bottom near y=56.
		sprite.position = Vector2(0, -24.0 * ART_SCALE)
		sprite.play(&"shimmer")
		return sprite
	var root := Node2D.new()
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([Vector2(0, -64), Vector2(24, -28), Vector2(0, 4), Vector2(-24, -28)])
	glow.color = Color(CRYSTAL_COLOR, 0.25)
	root.add_child(glow)
	var gem := Polygon2D.new()
	gem.polygon = PackedVector2Array([Vector2(0, -56), Vector2(16, -28), Vector2(0, -2), Vector2(-16, -28)])
	gem.color = CRYSTAL_COLOR
	root.add_child(gem)
	var shine := Polygon2D.new()
	shine.polygon = PackedVector2Array([Vector2(-2, -50), Vector2(6, -32), Vector2(-4, -30)])
	shine.color = Color(1.0, 0.92, 1.0, 0.85)
	root.add_child(shine)
	return root

static func _strip_frames(texture: Texture2D, animation: StringName, fps: float, loops: bool) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.clear_all()
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loops)
	var count := int(texture.get_width() / 48)
	for index in count:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(index * 48, 0, 48, 64)
		frames.add_frame(animation, frame)
	return frames

func apply_hit(attacker: Node, _damage: float, _knockback: float, _direction: Vector2, _damage_type := "normal") -> bool:
	return _take_hit(attacker)

func apply_forced_launch_hit(attacker: Node, _damage: float, _launch_velocity: Vector2, _hitstun: float, _effect_knockback: float, _direction: Vector2, _damage_type := "normal") -> bool:
	return _take_hit(attacker)

func apply_stun_hit(attacker: Node, _damage: float, _knockback: float, _direction: Vector2, _stun: float, _damage_type := "normal") -> bool:
	return _take_hit(attacker)

func apply_yuki_seal_burst(attacker: Node, _activation_id: int, _damage: float, _knockback: float, _direction: Vector2) -> bool:
	return _take_hit(attacker)

func apply_control_pull(_center: Vector2, _strength: float, _delta: float, _slow_duration: float, _slow_jump := false) -> void:
	pass

## Only fighters crack it; the last hit breaks it.
func _take_hit(attacker: Node) -> bool:
	if is_broken or not is_realm_active or is_queued_for_deletion() or not is_instance_valid(attacker) or not attacker.is_in_group("players"):
		return false
	hp -= 1.0
	_flash()
	if hp <= 0.0:
		is_broken = true
		collision_layer = 0
		broken.emit(self, attacker)
		_play_shatter()
		queue_free()
	return true

func set_realm_active(active: bool) -> void:
	is_realm_active = active
	visible = active

func _flash() -> void:
	if not is_instance_valid(visual):
		return
	visual.modulate = Color(2.2, 2.0, 2.4)
	var tween := visual.create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.12)

func _play_shatter() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var sheet := ART_SETTINGS.original_texture(SHATTER_PATH)
	var effect: Node2D
	if sheet != null:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = _strip_frames(sheet, &"shatter", 12.0, false)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(ART_SCALE, ART_SCALE)
		sprite.play(&"shatter")
		effect = sprite
		effect.position = global_position + Vector2(0, -24.0 * ART_SCALE)
	else:
		var burst := Polygon2D.new()
		burst.polygon = PackedVector2Array([Vector2(0, -30), Vector2(30, 0), Vector2(0, 30), Vector2(-30, 0)])
		burst.color = Color(CRYSTAL_COLOR, 0.8)
		effect = burst
		effect.position = global_position + Vector2(0, -28)
	effect.z_index = 4
	parent.add_child(effect)
	var tween := effect.create_tween()
	tween.tween_property(effect, "scale", effect.scale * 1.8, 0.35)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.35)
	tween.tween_callback(effect.queue_free)
	var label := Label.new()
	label.text = "+%d SOULS" % SOUL_REWARD
	label.add_theme_font_size_override("font_size", 14)
	label.modulate = Color(0.85, 0.7, 1.0)
	label.position = global_position + Vector2(-40, -90)
	label.z_index = 5
	parent.add_child(label)
	var rise := label.create_tween()
	rise.tween_property(label, "position:y", label.position.y - 30.0, 0.7)
	rise.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	rise.tween_callback(label.queue_free)
