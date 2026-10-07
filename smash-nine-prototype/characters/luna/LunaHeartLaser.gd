extends Area2D

const HIT_INTERVAL := 0.22
const VFX := preload("res://scripts/Vfx.gd")

var source: Node
var direction := Vector2.RIGHT
var duration := 1.0
var elapsed := 0.0
var damage_per_tick := 3.4
var knockback_per_tick := 95.0
var beam_length := 560.0
var beam_height := 112.0
var target_cooldowns: Dictionary = {}
## Original beam art: a tiled strip whose frame advances, plus the heart head at the far end.
var beam_art: TextureRect
var beam_frames: Array[Texture2D] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var outer_visual: Polygon2D = $OuterVisual
@onready var core_visual: Polygon2D = $CoreVisual
@onready var outline: Line2D = $Outline

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)

func configure(new_source: Node, cast_direction: Vector2, beam_duration: float) -> void:
	source = new_source
	direction = cast_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	duration = maxf(beam_duration, 0.05)
	rotation = direction.angle()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(beam_length, beam_height)
	collision_shape.shape = shape
	outer_visual.polygon = _make_beam_polygon(beam_length, beam_height)
	outer_visual.color = Color(1.0, 0.32, 0.78, 0.72)
	core_visual.polygon = _make_beam_polygon(beam_length, beam_height * 0.42)
	core_visual.color = Color(1.0, 0.94, 0.52, 0.94)
	outline.points = PackedVector2Array([
		Vector2(-beam_length * 0.5, -beam_height * 0.5),
		Vector2(beam_length * 0.5, -beam_height * 0.5),
		Vector2(beam_length * 0.5, beam_height * 0.5),
		Vector2(-beam_length * 0.5, beam_height * 0.5)
	])
	outline.closed = true
	outline.width = 5.0
	outline.default_color = Color(0.52, 0.94, 1.0, 0.86)
	outline.antialiased = true
	beam_frames = VFX.frame_textures("luna_ult_laser")
	if not beam_frames.is_empty():
		var art_scale := beam_height / 96.0
		beam_art = TextureRect.new()
		beam_art.texture = beam_frames[0]
		beam_art.stretch_mode = TextureRect.STRETCH_TILE
		beam_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		beam_art.size = Vector2(beam_length, 96.0)
		beam_art.scale = Vector2(1.0, art_scale)
		beam_art.position = Vector2(-beam_length * 0.5, -48.0 * art_scale)
		beam_art.material = CanvasItemMaterial.new()
		beam_art.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		beam_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(beam_art)
		VFX.spawn(self, "luna_ult_laser_head", Vector2(beam_length * 0.5, 0), Vector2(1.3, 1.3), true, 1, Color.WHITE, true)
		outer_visual.visible = false
		outline.visible = false
		core_visual.color.a = 0.35
	scale = Vector2(1.0, 0.14)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, minf(0.1, duration * 0.35))
	_update_position()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(source):
		queue_free()
		return
	elapsed += delta
	_update_position()
	_update_target_cooldowns(delta)
	if beam_art != null:
		beam_art.texture = beam_frames[int(elapsed * VFX.fps("luna_ult_laser")) % beam_frames.size()]
	var pulse := 0.9 + sin(elapsed * 34.0) * 0.1
	outer_visual.modulate.a = 0.7 + pulse * 0.22
	core_visual.scale.y = pulse
	for body in get_overlapping_bodies():
		_try_hit_body(body)
	if elapsed >= duration:
		queue_free()

func _update_position() -> void:
	global_position = source.global_position + Vector2(0, -38) + direction * (beam_length * 0.5 + 28.0)

func _update_target_cooldowns(delta: float) -> void:
	for target_id in target_cooldowns.keys():
		var remaining: float = target_cooldowns[target_id] - delta
		if remaining <= 0.0:
			target_cooldowns.erase(target_id)
		else:
			target_cooldowns[target_id] = remaining

func _on_body_entered(body: Node) -> void:
	_try_hit_body(body)

func _try_hit_body(body: Node) -> void:
	if body == source or not body.has_method("apply_hit"):
		return
	var target_id := body.get_instance_id()
	if target_cooldowns.has(target_id):
		return
	var landed = body.apply_hit(source, damage_per_tick, knockback_per_tick, direction)
	if landed == false:
		target_cooldowns[target_id] = HIT_INTERVAL * 0.55
		return
	target_cooldowns[target_id] = HIT_INTERVAL
	if is_instance_valid(source) and source.has_method("on_attack_landed"):
		source.on_attack_landed(global_position + direction * beam_length * 0.35, damage_per_tick, knockback_per_tick)

func _make_beam_polygon(length: float, height: float) -> PackedVector2Array:
	var half_length := length * 0.5
	var half_height := height * 0.5
	return PackedVector2Array([
		Vector2(-half_length, -half_height * 0.7),
		Vector2(half_length - 24.0, -half_height),
		Vector2(half_length, 0.0),
		Vector2(half_length - 24.0, half_height),
		Vector2(-half_length, half_height * 0.7)
	])
