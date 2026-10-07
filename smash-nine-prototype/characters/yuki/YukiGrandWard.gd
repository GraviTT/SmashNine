extends Node2D

const FIELD_RADIUS := 205.0
const VFX := preload("res://scripts/Vfx.gd")
const WARNING_TIME := 0.7
const ACTIVE_TIME := 2.35
const PULSE_INTERVAL := 0.58
## Tuned 2026-10-08 (5.5 -> ~12 damage per cast after the match scale).
const PULSE_DAMAGE := 5.0
const FINAL_PULSE_DAMAGE := 28.0

var owner_node: Node
var realm_index := 0
var warning_timer := WARNING_TIME
var active_timer := 0.0
var pulse_timer := 0.0
var activated := false
var ring: Line2D
var core: ColorRect
var seal: AnimatedSprite2D

func _ready() -> void:
	add_to_group("yuki_grand_wards")
	z_index = 3
	ring = Line2D.new()
	ring.width = 5.0
	ring.default_color = Color(0.62, 0.88, 1.0, 0.72)
	ring.antialiased = true
	var points := PackedVector2Array()
	for index in 33:
		var angle := TAU * float(index) / 32.0
		points.append(Vector2(cos(angle), sin(angle)) * FIELD_RADIUS)
	ring.points = points
	add_child(ring)
	# The seal art spans the field (256 px drawn at 1.6x = 410 px = 2 x FIELD_RADIUS).
	seal = VFX.spawn(self, "yuki_ult_seal", Vector2.ZERO, Vector2.ONE * (FIELD_RADIUS * 2.0 / 256.0), true, -1, Color(1, 1, 1, 0.55), true)
	if seal != null:
		ring.width = 2.0
	core = ColorRect.new()
	core.size = Vector2(56, 56)
	core.position = -core.size * 0.5
	core.pivot_offset = core.size * 0.5
	core.rotation = PI * 0.25
	core.color = Color(0.55, 0.82, 1.0, 0.32)
	add_child(core)
	for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		var talisman := ColorRect.new()
		talisman.size = Vector2(18, 42)
		talisman.position = direction * (FIELD_RADIUS - 12.0) - talisman.size * 0.5
		talisman.rotation = direction.angle() + PI * 0.5
		talisman.color = Color(0.72, 0.94, 1.0, 0.9)
		add_child(talisman)

func configure(new_owner: Node, new_realm_index: int) -> void:
	owner_node = new_owner
	realm_index = new_realm_index

func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_node):
		queue_free()
		return
	if not activated:
		warning_timer = maxf(warning_timer - delta, 0.0)
		var warning_ratio := 1.0 - warning_timer / WARNING_TIME
		ring.default_color.a = 0.35 + warning_ratio * 0.55
		core.scale = Vector2.ONE * (0.65 + warning_ratio * 0.45)
		if warning_timer <= 0.0:
			activated = true
			pulse_timer = 0.0
			if seal != null:
				seal.modulate = Color(1, 1, 1, 0.95)
			core.color = Color(0.7, 0.94, 1.0, 0.5)
		return
	active_timer += delta
	pulse_timer -= delta
	_apply_field_control(delta)
	if pulse_timer <= 0.0:
		pulse_timer = PULSE_INTERVAL
		_pulse(false)
	if active_timer >= ACTIVE_TIME:
		_pulse(true)
		VFX.spawn(get_parent(), "yuki_ult_burst", global_position, Vector2.ONE * (FIELD_RADIUS * 2.0 / 256.0))
		_play_final_effect()
		queue_free()

func _apply_field_control(delta: float) -> void:
	for target in _get_targets():
		if target == owner_node or not _same_realm(target):
			continue
		if global_position.distance_to(target.global_position) <= FIELD_RADIUS and target.has_method("apply_control_pull"):
			target.apply_control_pull(global_position, 190.0, delta, 0.16, true)

func _pulse(final_pulse: bool) -> void:
	for target in _get_targets():
		if target == owner_node or not _same_realm(target):
			continue
		var offset: Vector2 = target.global_position - global_position
		if offset.length() > FIELD_RADIUS:
			continue
		var direction := offset.normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.UP
		if final_pulse and target.has_method("apply_stun_hit"):
			target.apply_stun_hit(owner_node, FINAL_PULSE_DAMAGE, 520.0, direction, 1.2)
		elif not final_pulse and target.has_method("apply_hit"):
			target.apply_hit(owner_node, PULSE_DAMAGE, 90.0, -direction)
	var pulse_scale := 1.22 if final_pulse else 1.08
	var tween := core.create_tween()
	tween.tween_property(core, "scale", Vector2.ONE * pulse_scale, 0.08)
	tween.tween_property(core, "scale", Vector2.ONE, 0.12)

func _get_targets() -> Array[Node]:
	var targets: Array[Node] = []
	targets.append_array(get_tree().get_nodes_in_group("players"))
	targets.append_array(get_tree().get_nodes_in_group("realm_monsters"))
	return targets

func _same_realm(target: Node) -> bool:
	var target_realm = target.get("realm_index")
	return target_realm == null or int(target_realm) == realm_index

func _play_final_effect() -> void:
	var flash := ColorRect.new()
	flash.size = Vector2(FIELD_RADIUS * 2.0, FIELD_RADIUS * 2.0)
	flash.position = global_position - flash.size * 0.5
	flash.pivot_offset = flash.size * 0.5
	flash.color = Color(0.72, 0.94, 1.0, 0.3)
	get_parent().add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector2(1.15, 1.15), 0.16)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.18)
	tween.tween_callback(flash.queue_free)
