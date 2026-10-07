extends "res://characters/common/PlayerBase.gd"

const ANIMATION := preload("res://characters/common/CharacterAnimation.gd")
const COMET_SCRIPT := preload("res://characters/luna/LunaComet.gd")
const HEART_LASER_SCRIPT := preload("res://characters/luna/LunaHeartLaser.gd")
const IDLE_TEXTURE := preload("res://assets/characters/luna/idle.png")
const RUN_TEXTURE := preload("res://assets/characters/luna/run.png")
const JUMP_TEXTURE := preload("res://assets/characters/luna/jump.png")
const ATTACK_TEXTURE := preload("res://assets/characters/luna/attack.png")
const HURT_TEXTURE := preload("res://assets/characters/luna/hurt.png")

const TRANSFORMATION_DURATION := 6.0
const TRANSFORMATION_MOVEMENT_MULTIPLIER := 1.16
const BRAVE_COMBO_RESET_TIME := 0.42
const STAR_TRAIL_COLOR := Color(1.0, 0.48, 0.9, 0.52)
const STAR_BLOOM_COLOR := Color(0.44, 0.92, 1.0, 0.66)
const BRAVE_IMPACT_COLOR := Color(1.0, 0.84, 0.28, 0.76)

var transformed := false
var transformation_timer := 0.0
var transformation_finishing := false
var transformation_aura: Node2D
var transformation_visual_time := 0.0
var brave_combo_step := 0
var brave_combo_timer := 0.0
var heart_laser: Node
var heart_laser_cast_id := 0
var heart_laser_duration := 0.0

func configure_character_sprite() -> void:
	if _configure_original_sheet("luna"):
		return
	var frames := ANIMATION.create_frames()
	ANIMATION.add_strip(frames, &"luna_idle", IDLE_TEXTURE, Vector2i(49, 120), 0, 10, 7.0, true)
	ANIMATION.add_strip(frames, &"luna_walk", RUN_TEXTURE, Vector2i(106, 124), 0, 10, 10.0, true)
	ANIMATION.add_strip(frames, &"luna_jump", JUMP_TEXTURE, Vector2i(86, 125), 0, 5, 10.0, false)
	ANIMATION.add_strip(frames, &"luna_fall", JUMP_TEXTURE, Vector2i(86, 125), 5, 5, 10.0, false)
	ANIMATION.add_strip(frames, &"luna_attack", ATTACK_TEXTURE, Vector2i(70, 126), 0, 15, 16.0, false)
	ANIMATION.add_strip(frames, &"luna_shield", IDLE_TEXTURE, Vector2i(49, 120), 0, 1, 1.0, false)
	ANIMATION.add_strip(frames, &"luna_hurt", HURT_TEXTURE, Vector2i(149, 128), 0, 1, 1.0, false)
	character_sprite.sprite_frames = frames
	character_sprite.play(&"luna_idle")

func get_character_sprite_style() -> Dictionary:
	return {
		"position": Vector2(0, -34),
		"scale": Vector2(0.55, 0.55),
		"filter": CanvasItem.TEXTURE_FILTER_LINEAR
	}

func get_character_movement_multiplier() -> float:
	return TRANSFORMATION_MOVEMENT_MULTIPLIER if transformed else 1.0

func perform_basic_attack(attack_type: String, direction: Vector2) -> void:
	if transformed:
		_perform_brave_basic(attack_type)
	else:
		_perform_star_basic(attack_type, direction)

func perform_skill_one() -> void:
	if transformed:
		_brave_comet_drive_start()
	else:
		_star_comet_start()

func perform_skill_two() -> void:
	if transformed:
		_start_attack(0.12, 0.3, Callable(self, "_brave_luna_breaker"))
	else:
		_start_attack(0.21, 0.4, Callable(self, "_moon_ring"))

func perform_ultimate() -> void:
	_transformation_start()

## While transformed, the ultimate button fires the heart laser instead of starting a new cooldown.
func try_ultimate_followup() -> bool:
	if not transformed:
		return false
	if not transformation_finishing and _can_start_attack():
		_heart_laser_start()
	return true

func character_physics_process(delta: float) -> void:
	brave_combo_timer = maxf(brave_combo_timer - delta, 0.0)
	if brave_combo_timer <= 0.0:
		brave_combo_step = 0
	if not transformed:
		return
	transformation_visual_time += delta
	if not transformation_finishing:
		transformation_timer = maxf(transformation_timer - delta, 0.0)
	elif is_instance_valid(heart_laser):
		movement_freeze_timer = maxf(movement_freeze_timer, 0.06)
		attack_lock_timer = maxf(attack_lock_timer, 0.12)
	_update_transformation_visual(delta)
	if transformation_timer <= 0.0 and not transformation_finishing and attack_lock_timer <= 0.0 and skill_dash_timer <= 0.0:
		_end_transformation()

func character_on_hit() -> void:
	_reset_brave_combo()

func character_on_respawn() -> void:
	_end_transformation(true)

func character_cleanup() -> void:
	_end_transformation(true)

func _perform_star_basic(attack_type: String, _direction: Vector2) -> void:
	if not is_on_floor():
		velocity.y *= 0.72
	match attack_type:
		"up":
			_start_attack(0.12, 0.27, Callable(self, "_star_up_arc").bind(false))
		"air_up":
			_start_attack(0.1, 0.24, Callable(self, "_star_up_arc").bind(true))
		"down":
			_start_attack(0.15, 0.31, Callable(self, "_star_down_arc").bind(false))
		"air_down":
			_start_attack(0.13, 0.28, Callable(self, "_star_down_arc").bind(true))
		"air_side":
			_start_attack(0.09, 0.23, Callable(self, "_star_side_arc").bind(true))
		_:
			_start_attack(0.1, 0.25, Callable(self, "_star_side_arc").bind(false))

func _star_side_arc(airborne: bool) -> void:
	if airborne:
		velocity.x += facing * 65.0
		velocity.y *= 0.55
	_spawn_sweeping_attack(Vector2(38, 30), [
		Vector2(10 * facing, -42),
		Vector2(52 * facing, -37),
		Vector2(92 * facing, -30)
	], 3.5, 95, Vector2(facing, -0.04), STAR_TRAIL_COLOR, 0.1)
	_spawn_delayed_bloom(Vector2(108 * facing, -30), Vector2(74, 64), 6.5 if airborne else 7.0, 275 if airborne else 305, Vector2(facing, -0.1), 0.065)

func _star_up_arc(airborne: bool) -> void:
	velocity.y = minf(velocity.y, -90.0 if airborne else -45.0)
	_spawn_sweeping_attack(Vector2(36, 38), [
		Vector2(18 * facing, -28),
		Vector2(12 * facing, -72),
		Vector2(0, -112)
	], 3.5, 90, Vector2(0.1 * facing, -1), STAR_TRAIL_COLOR, 0.11)
	_spawn_delayed_bloom(Vector2(0, -126), Vector2(68, 74), 7.0, 325, Vector2(0.08 * facing, -1), 0.07)

func _star_down_arc(airborne: bool) -> void:
	if airborne:
		velocity.y = maxf(velocity.y, 90.0)
	else:
		velocity.x += facing * 35.0
	var bloom_offset := Vector2(42 * facing, 58) if airborne else Vector2(58 * facing, 20)
	_spawn_sweeping_attack(Vector2(40, 34), [
		Vector2(10 * facing, -28),
		Vector2(32 * facing, 4),
		bloom_offset
	], 4.0, 110, Vector2(0.18 * facing, 1), STAR_TRAIL_COLOR, 0.12)
	_spawn_delayed_bloom(bloom_offset, Vector2(78, 62), 8.0, 355, Vector2(0.2 * facing, 1), 0.075)

func _spawn_delayed_bloom(offset: Vector2, size: Vector2, damage: float, knockback: float, direction: Vector2, delay: float) -> void:
	if not await _wait_action(delay):
		return
	if is_defeated or hitstun_timer > 0.0 or transformed:
		return
	_spawn_attack(size, offset, damage, knockback, direction, STAR_BLOOM_COLOR, 0.12)
	_play_star_bloom(offset, maxf(size.x, size.y) * 0.42, Color(0.5, 0.96, 1.0, 0.82))

func _star_comet_start() -> void:
	var direction := _get_attack_direction()
	if not is_on_floor():
		velocity *= 0.7
	_start_attack(0.17, 0.34, Callable(self, "_spawn_star_comet").bind(direction))

func _spawn_star_comet(direction: Vector2) -> void:
	var comet := Area2D.new()
	comet.set_script(COMET_SCRIPT)
	comet.collision_layer = 0
	comet.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var visual := Polygon2D.new()
	visual.name = "Visual"
	comet.add_child(shape)
	comet.add_child(visual)
	get_parent().add_child(comet)
	comet.global_position = global_position + Vector2(0, -34) + direction.normalized() * 38.0
	comet.configure(self, direction, 12.0, 390.0)

func _moon_ring() -> void:
	if not is_on_floor():
		velocity.y *= 0.5
	var right_points := _make_arc_points(90.0, -PI * 0.5, PI * 0.5, 7)
	var left_points := _make_arc_points(90.0, -PI * 0.5, -PI * 1.5, 7)
	_spawn_sweeping_attack(Vector2(44, 38), right_points, 12, 405, Vector2(1, -0.08), Color(0.46, 0.94, 1.0, 0.58), 0.24)
	_spawn_sweeping_attack(Vector2(44, 38), left_points, 12, 405, Vector2(-1, -0.08), Color(1.0, 0.5, 0.92, 0.58), 0.24)
	_play_moon_ring_flash(90.0)

func _perform_brave_basic(attack_type: String) -> void:
	match attack_type:
		"up", "air_up":
			_reset_brave_combo()
			_start_attack(0.06, 0.14, Callable(self, "_brave_uppercut").bind(attack_type == "air_up"))
		"down":
			_reset_brave_combo()
			_start_attack(0.06, 0.14, Callable(self, "_brave_low_sweep"))
		"air_down":
			_reset_brave_combo()
			_start_attack(0.07, 0.18, Callable(self, "_brave_dive_kick"))
		"air_side":
			_reset_brave_combo()
			_start_attack(0.05, 0.12, Callable(self, "_brave_flying_kick"))
		_:
			match _consume_brave_combo_step():
				0:
					_start_attack(0.045, 0.1, Callable(self, "_brave_jab"))
				1:
					_start_attack(0.055, 0.11, Callable(self, "_brave_body_kick"))
				_:
					_start_attack(0.075, 0.18, Callable(self, "_brave_spin_kick"))

func _brave_jab() -> void:
	velocity.x += facing * 90.0
	_spawn_sweeping_attack(Vector2(34, 28), [Vector2(8 * facing, -38), Vector2(42 * facing, -36), Vector2(70 * facing, -34)], 5, 150, Vector2(facing, -0.02), BRAVE_IMPACT_COLOR, 0.075)
	_play_star_bloom(Vector2(68 * facing, -34), 24.0, BRAVE_IMPACT_COLOR, 0.1)

func _brave_body_kick() -> void:
	velocity.x += facing * 120.0
	_spawn_sweeping_attack(Vector2(38, 30), [Vector2(10 * facing, -32), Vector2(48 * facing, -28), Vector2(80 * facing, -22)], 6, 205, Vector2(facing, -0.06), BRAVE_IMPACT_COLOR, 0.085)
	_play_star_bloom(Vector2(78 * facing, -22), 27.0, BRAVE_IMPACT_COLOR, 0.11)

func _brave_spin_kick() -> void:
	velocity.x += facing * 145.0
	_spawn_sweeping_attack(Vector2(48, 38), [Vector2(-18 * facing, -44), Vector2(34 * facing, -50), Vector2(88 * facing, -30)], 10, 455, Vector2(facing, -0.16), Color(1.0, 0.5, 0.82, 0.72), 0.12)
	_play_star_bloom(Vector2(88 * facing, -30), 35.0, BRAVE_IMPACT_COLOR, 0.14)

func _brave_uppercut(airborne: bool) -> void:
	velocity.y = minf(velocity.y, -430.0 if not airborne else -330.0)
	velocity.x += facing * 45.0
	_spawn_sweeping_launch_attack(Vector2(42, 46), [Vector2(12 * facing, -28), Vector2(30 * facing, -68), Vector2(44 * facing, -108)], 10, 430, Vector2(0.12 * facing, -1), BRAVE_IMPACT_COLOR, 0.12, Vector2(72 * facing, -620), 0.28)
	_play_star_bloom(Vector2(42 * facing, -106), 31.0, BRAVE_IMPACT_COLOR, 0.13)

func _brave_low_sweep() -> void:
	velocity.x += facing * 85.0
	_spawn_sweeping_attack(Vector2(48, 28), [Vector2(-12 * facing, -14), Vector2(36 * facing, -10), Vector2(82 * facing, -8)], 8, 315, Vector2(facing, -0.06), BRAVE_IMPACT_COLOR, 0.1)
	_play_star_bloom(Vector2(80 * facing, -8), 28.0, BRAVE_IMPACT_COLOR, 0.12)

func _brave_flying_kick() -> void:
	velocity.x += facing * 230.0
	velocity.y *= 0.45
	_spawn_sweeping_attack(Vector2(44, 30), [Vector2(8 * facing, -36), Vector2(50 * facing, -32), Vector2(92 * facing, -28)], 8, 330, Vector2(facing, -0.08), BRAVE_IMPACT_COLOR, 0.095)
	_play_star_bloom(Vector2(92 * facing, -28), 29.0, BRAVE_IMPACT_COLOR, 0.12)

func _brave_dive_kick() -> void:
	action_locked_until_land = true
	velocity.x += facing * 125.0
	velocity.y = maxf(velocity.y, 610.0)
	_spawn_sweeping_attack(Vector2(42, 38), [Vector2(8 * facing, -22), Vector2(26 * facing, 24), Vector2(48 * facing, 78)], 10, 475, Vector2(0.16 * facing, 1), BRAVE_IMPACT_COLOR, 0.13)
	_play_star_bloom(Vector2(46 * facing, 74), 32.0, BRAVE_IMPACT_COLOR, 0.13)

func _brave_comet_drive_start() -> void:
	var direction := _get_attack_direction()
	_start_attack(0.07, 0.16, Callable(self, "_brave_comet_drive").bind(direction))

func _brave_comet_drive(direction: Vector2) -> void:
	if absf(direction.x) > 0.2:
		facing = signi(int(direction.x))
	velocity = direction * 120.0
	skill_dash_velocity = direction * 650.0
	skill_dash_timer = 0.14
	body.rotation = direction.angle()
	_spawn_sweeping_attack(Vector2(46, 34), [
		Vector2(0, -34) + direction * 10.0,
		Vector2(0, -34) + direction * 58.0,
		Vector2(0, -34) + direction * 112.0
	], 11, 425, direction, BRAVE_IMPACT_COLOR, 0.12)
	_play_star_bloom(Vector2(0, -34) + direction * 108.0, 31.0, BRAVE_IMPACT_COLOR, 0.12)

func _brave_luna_breaker() -> void:
	_reset_brave_combo()
	if is_on_floor():
		velocity.x += facing * 155.0
		_spawn_sweeping_attack(Vector2(56, 44), [Vector2(-16 * facing, -48), Vector2(42 * facing, -58), Vector2(106 * facing, -30)], 16, 650, Vector2(facing, -0.18), Color(1.0, 0.42, 0.78, 0.78), 0.14)
		_play_star_bloom(Vector2(104 * facing, -30), 42.0, BRAVE_IMPACT_COLOR, 0.15)
	else:
		velocity.x += facing * 130.0
		velocity.y += 170.0
		_spawn_sweeping_attack(Vector2(56, 44), [Vector2(-8 * facing, -46), Vector2(48 * facing, -14), Vector2(104 * facing, 32)], 16, 690, Vector2(facing, 0.34), Color(1.0, 0.42, 0.78, 0.78), 0.14)
		_play_star_bloom(Vector2(102 * facing, 30), 42.0, BRAVE_IMPACT_COLOR, 0.15)

func _consume_brave_combo_step() -> int:
	if brave_combo_timer <= 0.0:
		brave_combo_step = 0
	var step := brave_combo_step
	if step >= 2:
		_reset_brave_combo()
	else:
		brave_combo_step = step + 1
		brave_combo_timer = BRAVE_COMBO_RESET_TIME
	return step

func _reset_brave_combo() -> void:
	brave_combo_step = 0
	brave_combo_timer = 0.0

func _transformation_start() -> void:
	_reset_brave_combo()
	attack_lock_timer = 0.52
	_play_sprite_action(&"attack", 0.52)
	current_attack_started_airborne = not is_on_floor()
	_freeze_movement(0.26)
	velocity = Vector2.ZERO
	_play_transformation_charge()
	if not await _wait_action(0.26):
		return
	movement_freeze_timer = 0.0
	if is_defeated or hitstun_timer > 0.0:
		return
	_enter_transformation()

func _enter_transformation() -> void:
	transformed = true
	transformation_finishing = false
	transformation_timer = TRANSFORMATION_DURATION
	transformation_visual_time = 0.0
	attack_lock_timer = minf(attack_lock_timer, 0.12)
	_create_transformation_aura()
	_play_star_bloom(Vector2(0, -34), 62.0, Color(1.0, 0.86, 0.32, 0.92), 0.22)

func _heart_laser_start() -> void:
	heart_laser_duration = maxf(transformation_timer, 0.05)
	heart_laser_cast_id += 1
	var cast_id := heart_laser_cast_id
	transformation_finishing = true
	transformation_timer = 0.0
	_reset_brave_combo()
	attack_lock_timer = 0.16 + heart_laser_duration
	_play_sprite_action(&"attack", 0.16 + heart_laser_duration)
	_freeze_movement(0.14)
	velocity = Vector2.ZERO
	_play_finale_charge()
	if not await _wait_action(0.14):
		return
	if cast_id != heart_laser_cast_id:
		return
	if is_defeated or hitstun_timer > 0.0:
		_end_transformation(true)
		return
	var horizontal := _get_late_horizontal_direction()
	if horizontal != 0:
		facing = horizontal
	movement_freeze_position = global_position
	movement_freeze_timer = heart_laser_duration
	_spawn_heart_laser(Vector2(facing, 0.0), heart_laser_duration)
	_play_star_bloom(Vector2(34 * facing, -38), 74.0, Color(1.0, 0.82, 0.24, 0.94), 0.22)
	await get_tree().create_timer(heart_laser_duration).timeout
	if cast_id != heart_laser_cast_id:
		return
	_end_transformation(true)

func _spawn_heart_laser(direction: Vector2, duration: float) -> void:
	_clear_heart_laser()
	var laser := Area2D.new()
	laser.set_script(HEART_LASER_SCRIPT)
	laser.collision_layer = 0
	laser.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var outer := Polygon2D.new()
	outer.name = "OuterVisual"
	var core := Polygon2D.new()
	core.name = "CoreVisual"
	var outline := Line2D.new()
	outline.name = "Outline"
	laser.add_child(shape)
	laser.add_child(outer)
	laser.add_child(core)
	laser.add_child(outline)
	get_parent().add_child(laser)
	laser.configure(self, direction, duration)
	heart_laser = laser

func _clear_heart_laser() -> void:
	if is_instance_valid(heart_laser):
		heart_laser.queue_free()
	heart_laser = null

func _end_transformation(stop_motion := false) -> void:
	heart_laser_cast_id += 1
	transformed = false
	transformation_finishing = false
	transformation_timer = 0.0
	heart_laser_duration = 0.0
	transformation_visual_time = 0.0
	_reset_brave_combo()
	_clear_heart_laser()
	if is_instance_valid(transformation_aura):
		transformation_aura.queue_free()
	transformation_aura = null
	if is_instance_valid(character_sprite):
		character_sprite.modulate = Color.WHITE
	if is_instance_valid(body):
		body.color = body_color
		body.scale = Vector2.ONE
		body.rotation = 0.0
	if stop_motion:
		skill_dash_timer = 0.0
		_end_skill_dash()

func _update_transformation_visual(delta: float) -> void:
	if is_instance_valid(transformation_aura):
		transformation_aura.rotation += delta * 1.8
	var warning_pulse := transformation_timer <= 1.0 and not transformation_finishing
	var pulse := 0.5 + 0.5 * sin(transformation_visual_time * (24.0 if warning_pulse else 8.0))
	if is_instance_valid(character_sprite):
		character_sprite.modulate = Color(1.0, 0.78 + pulse * 0.18, 0.58 + pulse * 0.28, 1.0)
	if is_instance_valid(body):
		body.color = Color(1.0, 0.72 + pulse * 0.22, 0.34 + pulse * 0.35)

func _create_transformation_aura() -> void:
	if is_instance_valid(transformation_aura):
		transformation_aura.queue_free()
	transformation_aura = Node2D.new()
	transformation_aura.name = "BraveLunaAura"
	transformation_aura.position = Vector2(0, -34)
	transformation_aura.z_index = 3
	add_child(transformation_aura)
	var outer := Line2D.new()
	outer.points = _make_star_points(48.0, 28.0)
	outer.closed = true
	outer.width = 3.0
	outer.default_color = Color(1.0, 0.78, 0.22, 0.72)
	outer.antialiased = true
	transformation_aura.add_child(outer)
	var inner := Line2D.new()
	inner.points = _make_circle_points(34.0, 18)
	inner.closed = true
	inner.width = 2.0
	inner.default_color = Color(0.42, 0.94, 1.0, 0.58)
	inner.antialiased = true
	transformation_aura.add_child(inner)

func _play_transformation_charge() -> void:
	body.color = Color(1.0, 0.84, 0.34)
	var tween := body.create_tween()
	tween.tween_property(body, "scale", Vector2(0.78, 1.18), 0.1)
	tween.tween_property(body, "scale", Vector2(1.18, 0.84), 0.1)
	tween.tween_property(body, "scale", Vector2.ONE, 0.08)
	for index in 3:
		var angle := TAU * float(index) / 3.0
		_play_star_bloom(Vector2(cos(angle), sin(angle)) * 48.0 + Vector2(0, -34), 24.0, Color(1.0, 0.55 + index * 0.12, 0.86, 0.72), 0.24)

func _play_finale_charge() -> void:
	_play_star_bloom(Vector2(20 * facing, -36), 44.0, Color(1.0, 0.86, 0.28, 0.9), 0.16)
	body.color = Color.WHITE
	var tween := body.create_tween()
	tween.tween_property(body, "scale", Vector2(0.72, 1.22), 0.07)
	tween.tween_property(body, "scale", Vector2(1.22, 0.8), 0.07)

func _play_star_bloom(offset: Vector2, radius: float, color: Color, duration := 0.16) -> void:
	if not is_instance_valid(get_parent()):
		return
	var star := Polygon2D.new()
	star.polygon = _make_star_points(radius, radius * 0.42)
	star.color = color
	star.z_index = 6
	get_parent().add_child(star)
	star.global_position = global_position + offset
	star.scale = Vector2(0.35, 0.35)
	var tween := star.create_tween()
	tween.tween_property(star, "scale", Vector2(1.25, 1.25), duration)
	tween.parallel().tween_property(star, "rotation", 0.42 * float(facing), duration)
	tween.parallel().tween_property(star, "modulate:a", 0.0, duration)
	tween.tween_callback(star.queue_free)

func _play_moon_ring_flash(radius: float) -> void:
	var ring := Line2D.new()
	ring.points = _make_circle_points(radius, 28)
	ring.closed = true
	ring.width = 7.0
	ring.default_color = Color(0.56, 0.94, 1.0, 0.72)
	ring.antialiased = true
	ring.z_index = 5
	get_parent().add_child(ring)
	ring.global_position = global_position + Vector2(0, -34)
	ring.scale = Vector2(0.72, 0.72)
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector2(1.08, 1.08), 0.24)
	tween.parallel().tween_property(ring, "rotation", PI * float(facing), 0.24)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.24)
	tween.tween_callback(ring.queue_free)

func _make_arc_points(radius: float, start_angle: float, end_angle: float, count: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for index in count:
		var ratio := float(index) / float(maxi(count - 1, 1))
		var angle := lerpf(start_angle, end_angle, ratio)
		points.append(Vector2(cos(angle) * radius, -34 + sin(angle) * radius))
	return points

func _make_star_points(outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 10:
		var radius := outer_radius if index % 2 == 0 else inner_radius
		var angle := -PI * 0.5 + TAU * float(index) / 10.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _make_circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := TAU * float(index) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
