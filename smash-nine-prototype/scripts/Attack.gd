extends Area2D

var source: Node
var damage := 10.0
var knockback := 450.0
var direction := Vector2.RIGHT
var lifetime := 0.12
var hit_targets: Array[Node] = []
var source_origin := Vector2.ZERO
var motion_points: Array[Vector2] = []
var elapsed := 0.0
var is_sweeping := false
var trail_timer := 0.0
var forced_launch_velocity := Vector2.ZERO
var forced_hitstun_duration := 0.0
var forced_stun_duration := 0.0
var hit_tag := ""
var damage_type := "normal"

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(source):
		_discard_orphaned_attack()
		return
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	if not is_sweeping:
		_hit_overlapping_bodies()
		return
	trail_timer -= delta
	global_position = source_origin + _sample_motion(elapsed / lifetime)
	visual.rotation = _sample_motion_tangent(elapsed / lifetime).angle()
	_hit_overlapping_bodies()
	if trail_timer <= 0.0:
		trail_timer = 0.018
		_spawn_trail_afterimage()

func configure(new_source: Node, size: Vector2, offset: Vector2, new_damage: float, new_knockback: float, new_direction: Vector2, color: Color, new_lifetime := 0.12, new_damage_type := "normal") -> void:
	source = new_source
	damage = new_damage
	knockback = new_knockback
	direction = new_direction.normalized()
	lifetime = new_lifetime
	damage_type = new_damage_type
	elapsed = 0.0
	global_position += offset
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	visual.size = size
	visual.position = -size * 0.5
	visual.pivot_offset = size * 0.5
	visual.color = color

func configure_sweep(new_source: Node, size: Vector2, points: Array[Vector2], new_damage: float, new_knockback: float, new_direction: Vector2, color: Color, new_lifetime := 0.12, new_damage_type := "normal") -> void:
	source = new_source
	damage = new_damage
	knockback = new_knockback
	direction = new_direction.normalized()
	lifetime = new_lifetime
	damage_type = new_damage_type
	elapsed = 0.0
	source_origin = source.global_position if is_instance_valid(source) else global_position
	motion_points = points.duplicate()
	is_sweeping = motion_points.size() >= 2
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	visual.size = size
	visual.position = -size * 0.5
	visual.pivot_offset = size * 0.5
	visual.color = color
	if is_sweeping:
		global_position = source_origin + motion_points[0]
	else:
		global_position = source_origin

func configure_sweep_launch(new_source: Node, size: Vector2, points: Array[Vector2], new_damage: float, new_knockback: float, new_direction: Vector2, color: Color, new_lifetime: float, launch_velocity: Vector2, hitstun_duration: float, new_hit_tag := "", new_damage_type := "normal") -> void:
	configure_sweep(new_source, size, points, new_damage, new_knockback, new_direction, color, new_lifetime, new_damage_type)
	forced_launch_velocity = launch_velocity
	forced_hitstun_duration = hitstun_duration
	hit_tag = new_hit_tag

func configure_sweep_stun(new_source: Node, size: Vector2, points: Array[Vector2], new_damage: float, new_knockback: float, new_direction: Vector2, color: Color, new_lifetime: float, stun_duration: float, new_damage_type := "normal") -> void:
	configure_sweep(new_source, size, points, new_damage, new_knockback, new_direction, color, new_lifetime, new_damage_type)
	forced_stun_duration = stun_duration

func _sample_motion(ratio: float) -> Vector2:
	if motion_points.is_empty():
		return Vector2.ZERO
	if motion_points.size() == 1:
		return motion_points[0]
	var clamped_ratio := clampf(ratio, 0.0, 1.0)
	var segment_count := motion_points.size() - 1
	var scaled := clamped_ratio * segment_count
	var index := mini(int(floor(scaled)), segment_count - 1)
	var segment_t := scaled - float(index)
	return motion_points[index].lerp(motion_points[index + 1], segment_t)

func _sample_motion_tangent(ratio: float) -> Vector2:
	if motion_points.size() < 2:
		return direction
	var clamped_ratio := clampf(ratio, 0.0, 1.0)
	var segment_count := motion_points.size() - 1
	var scaled := clamped_ratio * segment_count
	var index := mini(int(floor(scaled)), segment_count - 1)
	return (motion_points[index + 1] - motion_points[index]).normalized()

func _spawn_trail_afterimage() -> void:
	if not is_instance_valid(get_parent()):
		return
	var trail := ColorRect.new()
	trail.size = visual.size
	trail.position = global_position - trail.size * 0.5
	trail.pivot_offset = trail.size * 0.5
	trail.rotation = visual.rotation
	trail.color = Color(visual.color.r, visual.color.g, visual.color.b, visual.color.a * 0.42)
	get_parent().add_child(trail)
	var tween := trail.create_tween()
	tween.tween_property(trail, "scale", Vector2(0.74, 0.74), 0.07)
	tween.parallel().tween_property(trail, "modulate:a", 0.0, 0.07)
	tween.tween_callback(trail.queue_free)

func _on_body_entered(body: Node) -> void:
	_hit_body(body)

func _hit_overlapping_bodies() -> void:
	for body in get_overlapping_bodies():
		_hit_body(body)

func _hit_body(body: Node) -> void:
	if not is_instance_valid(source):
		_discard_orphaned_attack()
		return
	if body == source or hit_targets.has(body):
		return
	if body.has_method("apply_hit"):
		hit_targets.append(body)
		var hit_landed = true
		if forced_stun_duration > 0.0 and body.has_method("apply_stun_hit"):
			hit_landed = body.apply_stun_hit(source, damage, knockback, direction, forced_stun_duration, damage_type)
		elif forced_hitstun_duration > 0.0 and body.has_method("apply_forced_launch_hit"):
			hit_landed = body.apply_forced_launch_hit(source, damage, forced_launch_velocity, forced_hitstun_duration, knockback, direction, damage_type)
		else:
			hit_landed = body.apply_hit(source, damage, knockback, direction, damage_type)
		if hit_landed != false and is_instance_valid(source) and source.has_method("on_attack_landed"):
			source.on_attack_landed(global_position, damage, knockback)
		if hit_landed != false and hit_tag != "" and is_instance_valid(source) and source.has_method("on_tagged_attack_landed"):
			source.on_tagged_attack_landed(hit_tag)

func _discard_orphaned_attack() -> void:
	monitoring = false
	set_physics_process(false)
	queue_free()
