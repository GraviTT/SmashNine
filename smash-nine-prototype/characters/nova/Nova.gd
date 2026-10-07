extends "res://characters/common/PlayerBase.gd"

const ANIMATION := preload("res://characters/common/CharacterAnimation.gd")
const GRAVITY_BURST_SCRIPT := preload("res://characters/nova/NovaGravityBurst.gd")
const BODY_HITBOX_SCRIPT := preload("res://characters/nova/NovaBodyHitbox.gd")

const MOMENTUM_START_SPEED := 170.0
const MOMENTUM_MAX_SPEED := 700.0
const VECTOR_SHIFT_DURATION := 0.22
const VECTOR_SHIFT_ACCELERATION := 5400.0
const VECTOR_SHIFT_MAX_SPEED := 760.0
const ULTIMATE_CORE_DISTANCE := 105.0
const ULTIMATE_MIN_ORBIT_RADIUS := 52.0
const ULTIMATE_MAX_TUNING_RADIUS := 260.0
const ULTIMATE_NEAR_ORBIT_SPEED := 1080.0
const ULTIMATE_FAR_ORBIT_SPEED := 560.0
const ULTIMATE_FAST_LAUNCH_SPEED := 1460.0
const ULTIMATE_SLOW_LAUNCH_SPEED := 860.0
const ULTIMATE_FAST_LAUNCH_DURATION := 0.46
const ULTIMATE_SLOW_LAUNCH_DURATION := 0.3
const ULTIMATE_NONE := 0
const ULTIMATE_CORE := 1
const ULTIMATE_ORBIT := 2
const ULTIMATE_LAUNCH := 3

var vector_shift_active := false
var vector_shift_timer := 0.0
var vector_shift_direction := Vector2.RIGHT
var air_vector_shift_available := true
var momentum_trail_timer := 0.0
var meteor_diving := false
var meteor_momentum_ratio := 0.0
var brake_restore_consumed := false

var ultimate_phase := ULTIMATE_NONE
var ultimate_center := Vector2.ZERO
var ultimate_entry_direction := Vector2.RIGHT
var ultimate_entry_momentum := 0.0
var ultimate_elapsed := 0.0
var ultimate_orbit_sign := 1.0
var ultimate_orbit_radius := ULTIMATE_CORE_DISTANCE
var ultimate_orbit_speed := ULTIMATE_FAR_ORBIT_SPEED
var ultimate_launch_speed := ULTIMATE_SLOW_LAUNCH_SPEED
var ultimate_launch_duration := ULTIMATE_SLOW_LAUNCH_DURATION
var ultimate_launch_power := 0.0
var ultimate_launch_shift_available := false
var ultimate_contact_requested := false
var ultimate_launch_direction := Vector2.RIGHT
var ultimate_saved_collision_mask := 0
var singularity_visual: Node2D
var ultimate_body_hitbox: Node
var ultimate_launch_preview: Node2D
var ultimate_preview_line: Line2D
var ultimate_preview_target: Line2D

## Original sheet only (third-party prototype art removed 2026-10-07, user).
func configure_character_sprite() -> void:
	_configure_original_sheet("nova")

func perform_basic_attack(attack_type: String, input_direction: Vector2) -> void:
	var momentum := _get_momentum_ratio()
	var impact_direction := _get_impact_direction(input_direction)
	_cancel_vector_shift()
	match attack_type:
		"up":
			_start_attack(0.07, 0.19, Callable(self, "_vector_uppercut").bind(momentum, false))
		"air_up":
			_start_attack(0.06, 0.17, Callable(self, "_vector_uppercut").bind(momentum, true))
		"down":
			_start_attack(0.1, 0.23, Callable(self, "_compression_stomp").bind(momentum))
		"air_down":
			_start_attack(0.07, 0.2, Callable(self, "_meteor_kick_start").bind(momentum))
		"air_side":
			_start_attack(0.05, 0.15, Callable(self, "_vector_side_strike").bind(momentum, true, impact_direction))
		_:
			_start_attack(0.065, 0.17, Callable(self, "_vector_side_strike").bind(momentum, false, Vector2(facing, -0.04)))

func perform_skill_one() -> void:
	_start_vector_shift()

func perform_skill_two() -> void:
	_gravity_brake_start()

func perform_ultimate() -> void:
	_gravity_slingshot_start()

func try_skill_one_followup() -> bool:
	if ultimate_phase != ULTIMATE_LAUNCH:
		return false
	if ultimate_launch_shift_available:
		_redirect_ultimate_launch_with_vector_shift()
	return true

func try_ultimate_followup() -> bool:
	if ultimate_phase == ULTIMATE_CORE:
		_begin_ultimate_orbit()
		return true
	if ultimate_phase == ULTIMATE_ORBIT:
		_begin_ultimate_launch(_get_ultimate_tangent())
		return true
	return ultimate_phase != ULTIMATE_NONE

func character_physics_process(delta: float) -> void:
	momentum_trail_timer = maxf(momentum_trail_timer - delta, 0.0)
	if vector_shift_active:
		vector_shift_timer = maxf(vector_shift_timer - delta, 0.0)
		if vector_shift_timer <= 0.0:
			vector_shift_active = false
	if meteor_diving:
		velocity.y = minf(velocity.y + 2600.0 * delta, 1120.0)
	_update_ultimate(delta)
	_update_momentum_visual()

func character_landing_state() -> void:
	if is_on_floor():
		air_vector_shift_available = true
	if meteor_diving and is_on_floor():
		meteor_diving = false
		var radius := lerpf(68.0, 98.0, meteor_momentum_ratio)
		var damage := lerpf(9.0, 14.0, meteor_momentum_ratio)
		var knockback := lerpf(350.0, 610.0, meteor_momentum_ratio)
		_spawn_gravity_burst(radius, damage, knockback, meteor_momentum_ratio, Color(0.26, 0.9, 1.0, 0.56), "meteor")
		_play_impact_flash(global_position + Vector2(0, -8), radius, Color(0.36, 0.95, 1.0, 0.78))

func character_on_hit() -> void:
	_cancel_vector_shift()
	meteor_diving = false
	_cancel_ultimate()

func character_on_respawn() -> void:
	_reset_nova_state()

func character_cleanup() -> void:
	_reset_nova_state()

func apply_character_gravity(delta: float) -> bool:
	if not vector_shift_active:
		return false
	if is_on_floor() and vector_shift_direction.y < -0.1:
		velocity.y = minf(velocity.y, -110.0)
	velocity += vector_shift_direction * VECTOR_SHIFT_ACCELERATION * delta
	if velocity.length() > VECTOR_SHIFT_MAX_SPEED:
		velocity = velocity.normalized() * VECTOR_SHIFT_MAX_SPEED
	return true

func get_nova_impact_direction() -> Vector2:
	if ultimate_phase == ULTIMATE_ORBIT:
		var offset := global_position - ultimate_center
		if offset.length() > 0.01:
			return Vector2(-offset.y, offset.x).normalized() * ultimate_orbit_sign
	if ultimate_phase == ULTIMATE_LAUNCH:
		return ultimate_launch_direction
	if velocity.length() > 0.01:
		return velocity.normalized()
	return Vector2(facing, -0.05).normalized()

func _vector_side_strike(momentum: float, airborne: bool, travel_direction: Vector2) -> void:
	var direction := travel_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2(facing, 0.0)
	if absf(direction.x) > 0.16:
		facing = signi(int(direction.x))
	var travel := lerpf(76.0, 138.0, momentum)
	var size := Vector2(lerpf(38.0, 54.0, momentum), lerpf(30.0, 42.0, momentum))
	var damage := lerpf(7.0, 11.0, momentum)
	var knockback := lerpf(235.0, 510.0, momentum)
	velocity += direction * lerpf(65.0, 165.0, momentum)
	if airborne:
		velocity.y *= 0.82
	_spawn_sweeping_attack(size, [
		Vector2(0, -32) + direction * 10.0,
		Vector2(0, -32) + direction * travel * 0.55,
		Vector2(0, -32) + direction * travel
	], damage, knockback, direction, _momentum_color(momentum), lerpf(0.075, 0.12, momentum))
	_play_vector_flash(direction, travel, momentum)

func _vector_uppercut(momentum: float, airborne: bool) -> void:
	var rise_speed := lerpf(-390.0, -570.0, momentum)
	if airborne:
		rise_speed *= 0.88
	velocity.y = minf(velocity.y, rise_speed)
	velocity.x += facing * lerpf(35.0, 85.0, momentum)
	var launch_velocity := Vector2(facing * lerpf(55.0, 105.0, momentum), lerpf(-470.0, -720.0, momentum))
	_spawn_sweeping_launch_attack(Vector2(lerpf(38.0, 48.0, momentum), lerpf(48.0, 62.0, momentum)), [
		Vector2(10 * facing, -26),
		Vector2(26 * facing, -70),
		Vector2(38 * facing, lerpf(-108.0, -138.0, momentum))
	], lerpf(7.0, 11.0, momentum), lerpf(300.0, 510.0, momentum), Vector2(0.12 * facing, -1), _momentum_color(momentum), 0.11, launch_velocity, lerpf(0.22, 0.32, momentum))
	_play_impact_flash(global_position + Vector2(36 * facing, -112), lerpf(28.0, 42.0, momentum), _momentum_color(momentum))

func _compression_stomp(momentum: float) -> void:
	velocity.x *= 0.55
	var radius := lerpf(48.0, 72.0, momentum)
	_spawn_gravity_burst(radius, lerpf(7.0, 11.0, momentum), lerpf(260.0, 480.0, momentum), momentum, Color(0.3, 0.88, 1.0, 0.5), "stomp")
	_play_impact_flash(global_position + Vector2(0, -10), radius, Color(0.38, 0.94, 1.0, 0.72))

func _meteor_kick_start(momentum: float) -> void:
	meteor_diving = true
	meteor_momentum_ratio = maxf(momentum, 0.35)
	action_locked_until_land = true
	velocity.x += facing * lerpf(45.0, 110.0, momentum)
	velocity.y = maxf(velocity.y, lerpf(560.0, 760.0, momentum))
	_spawn_sweeping_attack(Vector2(40, 46), [
		Vector2(0, -24),
		Vector2(12 * facing, 24),
		Vector2(24 * facing, 72)
	], lerpf(6.0, 9.0, momentum), lerpf(270.0, 430.0, momentum), Vector2(0.12 * facing, 1), _momentum_color(momentum), 0.12)

func _start_vector_shift() -> void:
	if not is_on_floor() and not air_vector_shift_available:
		return
	var direction := _get_attack_direction()
	if direction == Vector2.ZERO:
		direction = Vector2(facing, 0.0)
	vector_shift_active = true
	vector_shift_timer = VECTOR_SHIFT_DURATION
	vector_shift_direction = direction.normalized()
	if not is_on_floor():
		air_vector_shift_available = false
	if absf(vector_shift_direction.x) > 0.18:
		facing = signi(int(vector_shift_direction.x))
	attack_lock_timer = maxf(attack_lock_timer, 0.045)
	current_attack_started_airborne = not is_on_floor()
	_play_sprite_action(&"jump", VECTOR_SHIFT_DURATION)
	_play_shift_flash(vector_shift_direction)

func _cancel_vector_shift() -> void:
	vector_shift_active = false
	vector_shift_timer = 0.0

func _gravity_brake_start() -> void:
	var momentum := _get_momentum_ratio()
	_cancel_vector_shift()
	meteor_diving = false
	brake_restore_consumed = false
	attack_lock_timer = 0.42
	_play_sprite_action(&"attack", 0.42)
	_freeze_movement(0.08)
	velocity = Vector2.ZERO
	_play_brake_charge(momentum)
	if not await _wait_action(0.08):
		return
	movement_freeze_timer = 0.0
	if is_defeated or hitstun_timer > 0.0:
		return
	var radius := lerpf(58.0, 112.0, momentum)
	var damage := lerpf(6.0, 15.0, momentum)
	var knockback := lerpf(210.0, 640.0, momentum)
	_spawn_gravity_burst(radius, damage, knockback, momentum, _momentum_color(momentum), "brake")
	_play_impact_flash(global_position + Vector2(0, -30), radius, _momentum_color(momentum))

func _spawn_gravity_burst(radius: float, damage: float, knockback: float, momentum: float, color: Color, hit_tag: String) -> void:
	var burst := Area2D.new()
	burst.set_script(GRAVITY_BURST_SCRIPT)
	burst.collision_layer = 0
	burst.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var visual := Polygon2D.new()
	visual.name = "Visual"
	burst.add_child(shape)
	burst.add_child(visual)
	get_parent().add_child(burst)
	burst.global_position = global_position + Vector2(0, -30)
	burst.configure(self, radius, damage, knockback, momentum, color, hit_tag)

func on_nova_gravity_burst_landed(momentum: float, hit_tag: String) -> void:
	if hit_tag != "brake" or momentum < 0.6 or brake_restore_consumed:
		return
	brake_restore_consumed = true
	air_vector_shift_available = true
	_play_shift_recharge_flash()

func _gravity_slingshot_start() -> void:
	ultimate_phase = ULTIMATE_CORE
	ultimate_launch_shift_available = false
	ultimate_entry_direction = _get_attack_direction().normalized()
	if ultimate_entry_direction == Vector2.ZERO:
		ultimate_entry_direction = Vector2(facing, 0.0)
	ultimate_center = global_position + ultimate_entry_direction * ULTIMATE_CORE_DISTANCE
	ultimate_orbit_sign = 1.0 if facing >= 0 else -1.0
	ultimate_elapsed = 0.0
	ultimate_contact_requested = false
	ultimate_saved_collision_mask = collision_mask
	attack_lock_timer = maxf(attack_lock_timer, 0.16)
	_play_sprite_action(&"attack", 0.16)
	_create_singularity_visual()

func _begin_ultimate_orbit() -> void:
	_cancel_vector_shift()
	meteor_diving = false
	ultimate_phase = ULTIMATE_ORBIT
	ultimate_elapsed = 0.0
	ultimate_entry_momentum = _get_momentum_ratio()
	var offset := global_position - ultimate_center
	if offset.length() < ULTIMATE_MIN_ORBIT_RADIUS:
		offset = -ultimate_entry_direction * ULTIMATE_MIN_ORBIT_RADIUS
		global_position = ultimate_center + offset
	ultimate_orbit_radius = offset.length()
	var radius_ratio := clampf(
		(ultimate_orbit_radius - ULTIMATE_MIN_ORBIT_RADIUS) \
		/ (ULTIMATE_MAX_TUNING_RADIUS - ULTIMATE_MIN_ORBIT_RADIUS),
		0.0,
		1.0
	)
	ultimate_launch_power = clampf((1.0 - radius_ratio) * 0.82 + ultimate_entry_momentum * 0.18, 0.0, 1.0)
	ultimate_orbit_speed = lerpf(ULTIMATE_NEAR_ORBIT_SPEED, ULTIMATE_FAR_ORBIT_SPEED, radius_ratio)
	ultimate_orbit_speed *= 1.0 + ultimate_entry_momentum * 0.08
	ultimate_launch_speed = lerpf(ULTIMATE_SLOW_LAUNCH_SPEED, ULTIMATE_FAST_LAUNCH_SPEED, ultimate_launch_power)
	ultimate_launch_duration = lerpf(ULTIMATE_SLOW_LAUNCH_DURATION, ULTIMATE_FAST_LAUNCH_DURATION, ultimate_launch_power)
	var clockwise_tangent := Vector2(-offset.normalized().y, offset.normalized().x)
	if velocity.length() > 80.0:
		ultimate_orbit_sign = 1.0 if clockwise_tangent.dot(velocity.normalized()) >= 0.0 else -1.0
	collision_mask = 0
	_create_ultimate_launch_preview()
	_update_ultimate_launch_preview(_get_ultimate_tangent())
	_spawn_ultimate_body_hitbox(36.0, lerpf(7.0, 10.0, ultimate_launch_power), lerpf(230.0, 350.0, ultimate_launch_power), 30.0, false, Color(0.38, 0.94, 1.0, 0.52))

func _update_ultimate(delta: float) -> void:
	if ultimate_phase == ULTIMATE_NONE:
		return
	ultimate_elapsed += delta
	if is_instance_valid(singularity_visual):
		singularity_visual.rotation += delta * 4.5 * ultimate_orbit_sign
	if ultimate_phase == ULTIMATE_ORBIT:
		attack_lock_timer = maxf(attack_lock_timer, 0.12)
		var offset := global_position - ultimate_center
		if offset.length() < 10.0:
			offset = -ultimate_entry_direction * ultimate_orbit_radius
		var radial := offset.normalized()
		var tangent := Vector2(-radial.y, radial.x) * ultimate_orbit_sign
		var radial_correction := radial * (ultimate_orbit_radius - offset.length()) * 10.0
		skill_dash_velocity = tangent * ultimate_orbit_speed + radial_correction
		skill_dash_timer = 0.06
		_set_character_rotation(tangent.angle())
		_update_ultimate_launch_preview(tangent)
	elif ultimate_phase == ULTIMATE_LAUNCH:
		attack_lock_timer = maxf(attack_lock_timer, 0.12)
		skill_dash_velocity = ultimate_launch_direction * ultimate_launch_speed
		skill_dash_timer = 0.06
		_set_character_rotation(ultimate_launch_direction.angle())
		var collided_with_world := ultimate_elapsed > 0.04 and get_slide_collision_count() > 0
		if ultimate_contact_requested or collided_with_world or ultimate_elapsed >= ultimate_launch_duration:
			_finish_ultimate_impact()

func _begin_ultimate_launch(tangent: Vector2) -> void:
	if ultimate_phase != ULTIMATE_ORBIT:
		return
	ultimate_phase = ULTIMATE_LAUNCH
	ultimate_elapsed = 0.0
	ultimate_launch_direction = tangent.normalized()
	if ultimate_launch_direction == Vector2.ZERO:
		ultimate_launch_direction = Vector2(facing, 0.0)
	ultimate_launch_shift_available = true
	ultimate_contact_requested = false
	collision_mask = ultimate_saved_collision_mask
	_clear_ultimate_body_hitbox()
	_clear_ultimate_launch_preview()
	_spawn_ultimate_body_hitbox(42.0, lerpf(15.0, 22.0, ultimate_launch_power), lerpf(480.0, 700.0, ultimate_launch_power), ultimate_launch_duration + 0.08, true, Color(1.0, 0.56, 0.24, 0.68))
	_play_launch_flash(ultimate_launch_direction)

func _redirect_ultimate_launch_with_vector_shift() -> void:
	if ultimate_phase != ULTIMATE_LAUNCH or not ultimate_launch_shift_available:
		return
	var direction := _get_attack_direction()
	if direction == Vector2.ZERO:
		direction = ultimate_launch_direction
	ultimate_launch_direction = direction.normalized()
	ultimate_launch_speed = minf(ultimate_launch_speed + 110.0, ULTIMATE_FAST_LAUNCH_SPEED + 110.0)
	ultimate_launch_shift_available = false
	if absf(ultimate_launch_direction.x) > 0.18:
		facing = signi(int(ultimate_launch_direction.x))
	_play_sprite_action(&"jump", 0.14)
	_play_shift_flash(ultimate_launch_direction)

func on_nova_ultimate_contact(_hit_position: Vector2) -> void:
	if ultimate_phase == ULTIMATE_LAUNCH:
		ultimate_contact_requested = true

func _finish_ultimate_impact() -> void:
	if ultimate_phase != ULTIMATE_LAUNCH:
		return
	ultimate_phase = ULTIMATE_NONE
	ultimate_launch_shift_available = false
	collision_mask = ultimate_saved_collision_mask
	skill_dash_timer = 0.0
	_end_skill_dash()
	velocity = ultimate_launch_direction * 180.0
	_clear_ultimate_body_hitbox()
	_clear_ultimate_launch_preview()
	_clear_singularity_visual()
	_reset_character_rotation()
	var radius := lerpf(108.0, 152.0, ultimate_launch_power)
	_spawn_gravity_burst(radius, lerpf(22.0, 31.0, ultimate_launch_power), lerpf(700.0, 940.0, ultimate_launch_power), ultimate_launch_power, Color(0.48, 0.3, 0.92, 0.68), "ultimate")
	_play_impact_flash(global_position + Vector2(0, -30), radius, Color(1.0, 0.62, 0.24, 0.88))
	attack_lock_timer = maxf(attack_lock_timer, 0.48)

func _spawn_ultimate_body_hitbox(radius: float, damage: float, knockback: float, lifetime: float, end_on_hit: bool, color: Color) -> void:
	_clear_ultimate_body_hitbox()
	var hitbox := Area2D.new()
	hitbox.set_script(BODY_HITBOX_SCRIPT)
	hitbox.collision_layer = 0
	hitbox.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var visual := Polygon2D.new()
	visual.name = "Visual"
	hitbox.add_child(shape)
	hitbox.add_child(visual)
	get_parent().add_child(hitbox)
	hitbox.global_position = global_position + Vector2(0, -32)
	hitbox.configure(self, radius, damage, knockback, lifetime, color, end_on_hit)
	ultimate_body_hitbox = hitbox

func _cancel_ultimate() -> void:
	if ultimate_phase == ULTIMATE_NONE \
		and not is_instance_valid(singularity_visual) \
		and not is_instance_valid(ultimate_body_hitbox) \
		and not is_instance_valid(ultimate_launch_preview):
		return
	ultimate_phase = ULTIMATE_NONE
	ultimate_launch_shift_available = false
	ultimate_contact_requested = false
	if ultimate_saved_collision_mask != 0:
		collision_mask = ultimate_saved_collision_mask
	skill_dash_timer = 0.0
	_end_skill_dash()
	_clear_ultimate_body_hitbox()
	_clear_ultimate_launch_preview()
	_clear_singularity_visual()
	_reset_character_rotation()

func _clear_ultimate_body_hitbox() -> void:
	if is_instance_valid(ultimate_body_hitbox):
		ultimate_body_hitbox.queue_free()
	ultimate_body_hitbox = null

func _get_ultimate_tangent() -> Vector2:
	var offset := global_position - ultimate_center
	if offset.length() < 0.01:
		offset = -ultimate_entry_direction * ultimate_orbit_radius
	return Vector2(-offset.y, offset.x).normalized() * ultimate_orbit_sign

func _create_ultimate_launch_preview() -> void:
	_clear_ultimate_launch_preview()
	ultimate_launch_preview = Node2D.new()
	ultimate_launch_preview.name = "NovaLaunchPreview"
	ultimate_launch_preview.z_index = 5
	get_parent().add_child(ultimate_launch_preview)
	ultimate_preview_line = Line2D.new()
	ultimate_preview_line.name = "Trajectory"
	ultimate_preview_line.width = 4.0
	ultimate_preview_line.default_color = Color(1.0, 0.72, 0.24, 0.58)
	ultimate_preview_line.antialiased = true
	ultimate_launch_preview.add_child(ultimate_preview_line)
	ultimate_preview_target = Line2D.new()
	ultimate_preview_target.name = "Destination"
	ultimate_preview_target.points = _make_circle_points(18.0, 24)
	ultimate_preview_target.closed = true
	ultimate_preview_target.width = 4.5
	ultimate_preview_target.default_color = Color(1.0, 0.54, 0.18, 0.88)
	ultimate_preview_target.antialiased = true
	ultimate_launch_preview.add_child(ultimate_preview_target)

func _update_ultimate_launch_preview(direction: Vector2) -> void:
	if not is_instance_valid(ultimate_launch_preview) or direction == Vector2.ZERO:
		return
	var launch_distance := ultimate_launch_speed * ultimate_launch_duration
	ultimate_launch_preview.global_position = global_position + Vector2(0, -32)
	ultimate_preview_line.points = PackedVector2Array([Vector2.ZERO, direction * launch_distance])
	ultimate_preview_target.position = direction * launch_distance
	ultimate_preview_target.rotation += 0.08 * ultimate_orbit_sign

func _clear_ultimate_launch_preview() -> void:
	if is_instance_valid(ultimate_launch_preview):
		ultimate_launch_preview.queue_free()
	ultimate_launch_preview = null
	ultimate_preview_line = null
	ultimate_preview_target = null

func _create_singularity_visual() -> void:
	_clear_singularity_visual()
	singularity_visual = Node2D.new()
	singularity_visual.name = "NovaSingularity"
	singularity_visual.z_index = 6
	get_parent().add_child(singularity_visual)
	singularity_visual.global_position = ultimate_center + Vector2(0, -32)
	var core := Polygon2D.new()
	core.polygon = _make_star_points(28.0, 17.0)
	core.color = Color(0.12, 0.06, 0.24, 0.94)
	singularity_visual.add_child(core)
	for index in 2:
		var ring := Line2D.new()
		ring.points = _make_circle_points(40.0 + index * 14.0, 24)
		ring.closed = true
		ring.width = 3.5 - index
		ring.default_color = Color(0.34 + index * 0.28, 0.86, 1.0, 0.72 - index * 0.16)
		ring.rotation = index * 0.45
		ring.antialiased = true
		singularity_visual.add_child(ring)

func _clear_singularity_visual() -> void:
	if is_instance_valid(singularity_visual):
		singularity_visual.queue_free()
	singularity_visual = null

func _reset_nova_state() -> void:
	_cancel_vector_shift()
	meteor_diving = false
	air_vector_shift_available = true
	brake_restore_consumed = false
	_cancel_ultimate()
	if is_instance_valid(character_sprite):
		character_sprite.modulate = Color.WHITE

func _get_momentum_ratio() -> float:
	return clampf((velocity.length() - MOMENTUM_START_SPEED) / (MOMENTUM_MAX_SPEED - MOMENTUM_START_SPEED), 0.0, 1.0)

func _get_impact_direction(input_direction: Vector2) -> Vector2:
	if velocity.length() >= MOMENTUM_START_SPEED:
		return velocity.normalized()
	if input_direction.length() > 0.01:
		return input_direction.normalized()
	return Vector2(facing, 0.0)

func _momentum_color(momentum: float) -> Color:
	return Color(
		lerpf(0.24, 1.0, momentum),
		lerpf(0.88, 0.64, momentum),
		lerpf(1.0, 0.24, momentum),
		lerpf(0.5, 0.78, momentum)
	)

func _update_momentum_visual() -> void:
	var momentum := _get_momentum_ratio()
	if is_instance_valid(character_sprite):
		character_sprite.modulate = Color(1.0, 1.0, lerpf(1.0, 0.7, momentum), 1.0)
	if momentum < 0.34 or momentum_trail_timer > 0.0:
		return
	momentum_trail_timer = lerpf(0.075, 0.035, momentum)
	var trail := Polygon2D.new()
	trail.polygon = PackedVector2Array([Vector2(-24, 0), Vector2(0, -8), Vector2(24, 0), Vector2(0, 8)])
	trail.color = _momentum_color(momentum)
	trail.z_index = 2
	get_parent().add_child(trail)
	trail.global_position = global_position + Vector2(0, -32)
	trail.rotation = get_nova_impact_direction().angle()
	var tween := trail.create_tween()
	tween.tween_property(trail, "scale", Vector2(0.3, 0.3), 0.1)
	tween.parallel().tween_property(trail, "modulate:a", 0.0, 0.1)
	tween.tween_callback(trail.queue_free)

func _play_vector_flash(direction: Vector2, length: float, momentum: float) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([Vector2.ZERO, direction * length])
	line.width = lerpf(5.0, 12.0, momentum)
	line.default_color = _momentum_color(momentum)
	line.antialiased = true
	line.z_index = 5
	get_parent().add_child(line)
	line.global_position = global_position + Vector2(0, -32)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.12)
	tween.tween_callback(line.queue_free)

func _play_shift_flash(direction: Vector2) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([-direction * 52.0, Vector2.ZERO])
	line.width = 7.0
	line.default_color = Color(0.32, 0.96, 1.0, 0.74)
	line.antialiased = true
	line.z_index = 4
	get_parent().add_child(line)
	line.global_position = global_position + Vector2(0, -32)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, VECTOR_SHIFT_DURATION)
	tween.tween_callback(line.queue_free)

func _play_brake_charge(momentum: float) -> void:
	body.color = _momentum_color(momentum)
	var tween := body.create_tween()
	tween.tween_property(body, "scale", Vector2(1.18, 0.82), 0.04)
	tween.tween_property(body, "scale", Vector2(0.86, 1.14), 0.04)
	tween.tween_property(body, "scale", Vector2.ONE, 0.08)

func _play_shift_recharge_flash() -> void:
	var ring := Line2D.new()
	ring.points = _make_circle_points(34.0, 20)
	ring.closed = true
	ring.width = 4.0
	ring.default_color = Color(0.42, 1.0, 0.72, 0.84)
	ring.z_index = 6
	get_parent().add_child(ring)
	ring.global_position = global_position + Vector2(0, -32)
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector2(1.5, 1.5), 0.14)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.14)
	tween.tween_callback(ring.queue_free)

func _play_impact_flash(world_position: Vector2, radius: float, color: Color) -> void:
	var flash := Polygon2D.new()
	flash.polygon = _make_star_points(radius, radius * 0.48)
	flash.color = color
	flash.z_index = 7
	get_parent().add_child(flash)
	flash.global_position = world_position
	flash.scale = Vector2(0.4, 0.4)
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector2(1.2, 1.2), 0.15)
	tween.parallel().tween_property(flash, "rotation", 0.5, 0.15)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.15)
	tween.tween_callback(flash.queue_free)

func _play_launch_flash(direction: Vector2) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([Vector2.ZERO, direction * 180.0])
	line.width = 18.0
	line.default_color = Color(1.0, 0.62, 0.22, 0.82)
	line.antialiased = true
	line.z_index = 6
	get_parent().add_child(line)
	line.global_position = global_position + Vector2(0, -32)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.16)
	tween.tween_callback(line.queue_free)

func _set_character_rotation(angle: float) -> void:
	body.rotation = angle
	if is_instance_valid(character_sprite):
		character_sprite.rotation = angle

func _reset_character_rotation() -> void:
	body.rotation = 0.0
	if is_instance_valid(character_sprite):
		character_sprite.rotation = 0.0

func _make_star_points(outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 12:
		var radius := outer_radius if index % 2 == 0 else inner_radius
		var angle := -PI * 0.5 + TAU * float(index) / 12.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _make_circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := TAU * float(index) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
