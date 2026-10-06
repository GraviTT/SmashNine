extends CharacterBody2D

signal hp_changed(player: Node)
signal defeated(player: Node, attacker: Node)
signal respawned(player: Node)
signal experience_changed(player: Node)
signal leveled_up(player: Node, new_level: int)

const GRAVITY := 1850.0
const FLOOR_ACCEL := 5500.0
const AIR_ACCEL := 4300.0
const FRICTION := 5200.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const ATTACK_BUFFER := 0.11
const JUMP_CUT_MULTIPLIER := 0.42
const FALL_GRAVITY_MULTIPLIER := 1.18
const MAX_FALL_SPEED := 980.0
const KNOCKBACK_SCALE := 1.05
const KNOCKBACK_DECAY := 1150.0
const KNOCKBACK_GROUND_DECAY := 1480.0
const KNOCKBACK_AIR_DECAY := 980.0
const STRONG_KNOCKBACK_DECAY_SCALE := 0.82
const LOW_HP_KNOCKBACK_BONUS := 0.75
const HITSTUN_MIN := 0.095
const HITSTUN_MAX := 0.34
const AIR_HITSTUN_BONUS := 0.035
const STRONG_HITSTUN_BONUS := 0.025
const GROUNDED_HIT_LIFT := -0.28
const ATTACK_GROUND_MOBILITY := 0.48
const ATTACK_AIR_MOBILITY := 0.72
const ATTACKER_HITSTOP := 0.045
const VICTIM_HITSTOP := 0.065
const AIR_ATTACK_LANDING_RECOVERY := 0.075
const SKILL_DASH_DECAY := 2100.0
const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const MONSTER_LAYER := 4
const PLAYER_SOFT_RADIUS := 40.0
const PLAYER_SOFT_PUSH := 260.0
const DROP_TAP_WINDOW := 0.28
const DROP_THROUGH_TIME := 0.32
const DROP_THROUGH_SPEED := 240.0
const GUARD_PARRY_WINDOW := 0.1
const GUARD_RECOVERY := 0.26
const GUARD_DECAY_TIME := 5.0
const GUARD_START_REDUCTION := 0.75
const GUARD_MIN_REDUCTION := 0.30
const GUARD_KNOCKBACK_REDUCTION_SCALE := 0.65
const GUARD_NONE := 0
const GUARD_BLOCK := 1
const GUARD_PARRY := 2
const MAX_LEVEL := 10
const DAMAGE_NORMAL := "normal"
const DAMAGE_FIXED := "fixed"
const ENEMY_AI_SCRIPT := preload("res://scripts/EnemyAI.gd")

var player_id := 0
var character_id := "frey"
var display_name := "Frey"
var role := "Bruiser"
var body_color := Color.WHITE
var max_hp := 100.0
var hp := 100.0
var attack_power := 100.0
var defense := 0.0
var speed := 330.0
var jump_velocity := -720.0
var weight := 1.0
var base_max_hp := 100.0
var base_attack_power := 100.0
var base_defense := 0.0
var base_speed := 330.0
var hp_growth := 0.0
var attack_growth := 0.0
var defense_growth := 0.0
var speed_growth := 0.0
var down_tap_timer := 0.0
var drop_through_timer := 0.0
var current_floor_platform: Node
var drop_through_platform: Node
var is_guarding := false
var guard_direction := Vector2.RIGHT
var guard_duration := 0.0
var guard_parry_timer := 0.0
var guard_recovery_timer := 0.0
var guard_recovery_waived := false
var facing := 1
var is_human := false
var is_dummy := false
var is_defeated := false
var knockback_velocity := Vector2.ZERO
var skill_dash_velocity := Vector2.ZERO
var skill_dash_timer := 0.0
var current_knockback_decay := KNOCKBACK_DECAY
var ringout_damage_base := 18.0
var score := 0
var level := 1
var experience := 0
var experience_to_next_level := 24
var respawn_count := 0
var last_attacker: Node
var realm_index := 0
var is_realm_active := true
var realm_origin := Vector2.ZERO
var ringout_y := 900.0
var ai_controller := ENEMY_AI_SCRIPT.new()
var spawn_point := Vector2.ZERO
var spawn_points: Array[Vector2] = []
var match_pressure := 1.0
var move_input := 0.0
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var attack_buffer_timer := 0.0
var attack_lock_timer := 0.0
var hitstun_timer := 0.0
var hitstop_timer := 0.0
var current_attack_started_airborne := false
var was_on_floor_last_frame := false
var movement_freeze_timer := 0.0
var movement_freeze_position := Vector2.ZERO
var last_yuki_activation_hit := -1
var control_slow_timer := 0.0
var control_jump_slow_timer := 0.0
var action_locked_until_land := false
var max_air_jumps := 1
var air_jumps_left := 1
var sprite_action := &""
var sprite_action_timer := 0.0

@onready var body: ColorRect = $Body
@onready var character_sprite: AnimatedSprite2D = get_node_or_null("CharacterSprite") as AnimatedSprite2D
@onready var name_label: Label = $NameLabel
@onready var hp_bar: ColorRect = $HpBar/Fill
@onready var exp_bar: ColorRect = $ExpBar/Fill
@onready var attack_scene := preload("res://scripts/Attack.gd")
@onready var projectile_scene := preload("res://scripts/Projectile.gd")
var guard_visual: Line2D

func _ready() -> void:
	add_to_group("players")
	spawn_point = global_position
	ai_controller.reset(global_position)
	body.pivot_offset = body.size * 0.5
	configure_character_sprite()
	_create_guard_visual()
	was_on_floor_last_frame = is_on_floor()
	_update_visuals()
	_update_character_sprite(true)

func setup(data: Dictionary, new_player_id: int, human := false) -> void:
	player_id = new_player_id
	is_human = human
	is_dummy = false
	_apply_character_data(data)
	hp = max_hp
	call_deferred("_update_visuals")

func inherit_match_state(other: Node) -> void:
	var hp_ratio := 1.0
	if float(other.max_hp) > 0.0:
		hp_ratio = clampf(float(other.hp) / float(other.max_hp), 0.0, 1.0)
	level = int(other.level)
	experience = int(other.experience)
	experience_to_next_level = int(other.experience_to_next_level)
	score = int(other.score)
	respawn_count = int(other.respawn_count)
	match_pressure = float(other.match_pressure)
	_apply_level_stats(false)
	hp = max_hp * hp_ratio
	_update_visuals()

func setup_dummy(new_player_id: int) -> void:
	player_id = new_player_id
	is_human = false
	is_dummy = true
	character_id = "dummy"
	display_name = "Dummy"
	role = "Training Dummy"
	body_color = Color(0.7, 0.7, 0.72)
	max_hp = 999.0
	hp = max_hp
	attack_power = 100.0
	defense = 0.0
	speed = 0.0
	jump_velocity = -650.0
	weight = 1.25
	call_deferred("_update_visuals")

func _apply_character_data(data: Dictionary) -> void:
	character_id = data.id
	display_name = data.name
	role = data.role
	body_color = data.color
	base_max_hp = float(data.max_hp)
	base_attack_power = float(data.get("attack", 100.0))
	base_defense = float(data.get("defense", 0.0))
	base_speed = float(data.speed)
	var growth: Dictionary = data.get("growth", {})
	hp_growth = float(growth.get("max_hp", 0.0))
	attack_growth = float(growth.get("attack", 0.0))
	defense_growth = float(growth.get("defense", 0.0))
	speed_growth = float(growth.get("speed", 0.0))
	jump_velocity = data.jump
	weight = data.weight
	_apply_level_stats(false)

func _apply_level_stats(restore_gained_hp: bool) -> void:
	var previous_max_hp := max_hp
	var gained_levels := float(maxi(level - 1, 0))
	max_hp = base_max_hp + hp_growth * gained_levels
	attack_power = base_attack_power + attack_growth * gained_levels
	defense = base_defense + defense_growth * gained_levels
	speed = base_speed + speed_growth * gained_levels
	if restore_gained_hp and max_hp > previous_max_hp:
		hp = minf(hp + max_hp - previous_max_hp, max_hp)

func _physics_process(delta: float) -> void:
	if is_defeated or not is_realm_active:
		return
	if hitstop_timer > 0.0:
		hitstop_timer = maxf(hitstop_timer - delta, 0.0)
		return
	attack_lock_timer = maxf(attack_lock_timer - delta, 0.0)
	control_slow_timer = maxf(control_slow_timer - delta, 0.0)
	control_jump_slow_timer = maxf(control_jump_slow_timer - delta, 0.0)
	guard_recovery_timer = maxf(guard_recovery_timer - delta, 0.0)
	_update_guard_state(delta)
	attack_buffer_timer = maxf(attack_buffer_timer - delta, 0.0)
	down_tap_timer = maxf(down_tap_timer - delta, 0.0)
	_update_drop_through(delta)
	movement_freeze_timer = maxf(movement_freeze_timer - delta, 0.0)
	sprite_action_timer = maxf(sprite_action_timer - delta, 0.0)
	if sprite_action_timer <= 0.0:
		sprite_action = &""
	var was_skill_dashing := skill_dash_timer > 0.0
	skill_dash_timer = maxf(skill_dash_timer - delta, 0.0)
	if was_skill_dashing and skill_dash_timer <= 0.0:
		_end_skill_dash()
	character_physics_process(delta)
	hitstun_timer = maxf(hitstun_timer - delta, 0.0)
	if hitstun_timer > 0.0:
		move_input = 0.0
	elif is_dummy:
		move_input = 0.0
	elif is_human:
		_read_human_input(delta)
	else:
		_read_ai_input(delta)
	_try_buffered_attack()
	_apply_movement(delta)
	_handle_landing_state()
	_update_character_sprite()
	if global_position.y > ringout_y:
		_ringout()

func _unhandled_input(event: InputEvent) -> void:
	if not is_human or is_defeated:
		return
	if event.is_action_released("guard"):
		_stop_guard(true)
		return
	if hitstun_timer > 0.0:
		return
	if event.is_action_pressed("guard") and not event.is_echo():
		_try_start_guard()
		return
	if is_guarding or guard_recovery_timer > 0.0:
		return
	if event.is_action_pressed("move_down") and not event.is_echo():
		_handle_down_tap()
	if event.is_action_pressed("basic_attack"):
		if _can_start_attack():
			basic_attack()
		else:
			attack_buffer_timer = ATTACK_BUFFER
	if event.is_action_pressed("skill_1"):
		skill_one()
	if event.is_action_pressed("skill_2"):
		if try_skill_two_followup():
			return
		skill_two()
	if event.is_action_pressed("ultimate"):
		ultimate()

func _read_human_input(delta: float) -> void:
	if hitstun_timer > 0.0:
		move_input = 0.0
		return
	if is_guarding:
		_update_guard_direction_from_input()
		move_input = 0.0
		jump_buffer_timer = 0.0
		return
	if guard_recovery_timer > 0.0:
		move_input = 0.0
		jump_buffer_timer = 0.0
		return
	move_input = Input.get_axis("move_left", "move_right")
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_up"):
		jump_buffer_timer = JUMP_BUFFER
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	if (Input.is_action_just_released("jump") or Input.is_action_just_released("move_up")) and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

func _read_ai_input(delta: float) -> void:
	ai_controller.update(self, delta)

func _try_start_guard() -> void:
	if not is_on_floor() or attack_lock_timer > 0.0 or guard_recovery_timer > 0.0:
		return
	if movement_freeze_timer > 0.0 or skill_dash_timer > 0.0 or action_locked_until_land:
		return
	is_guarding = true
	guard_duration = 0.0
	guard_parry_timer = GUARD_PARRY_WINDOW
	guard_recovery_waived = false
	velocity.x = 0.0
	jump_buffer_timer = 0.0
	attack_buffer_timer = 0.0
	_update_guard_direction_from_input()
	_update_guard_visual()

func _stop_guard(use_recovery: bool) -> void:
	if not is_guarding:
		return
	is_guarding = false
	guard_parry_timer = 0.0
	guard_duration = 0.0
	if use_recovery and not guard_recovery_waived:
		guard_recovery_timer = maxf(guard_recovery_timer, GUARD_RECOVERY)
	guard_recovery_waived = false
	if is_instance_valid(guard_visual):
		guard_visual.visible = false

func _reset_guard_state() -> void:
	is_guarding = false
	guard_duration = 0.0
	guard_parry_timer = 0.0
	guard_recovery_timer = 0.0
	guard_recovery_waived = false
	if is_instance_valid(guard_visual):
		guard_visual.visible = false
		guard_visual.scale = Vector2.ONE

func _update_guard_state(delta: float) -> void:
	if not is_guarding:
		return
	if is_human and not Input.is_action_pressed("guard"):
		_stop_guard(true)
		return
	guard_duration += delta
	guard_parry_timer = maxf(guard_parry_timer - delta, 0.0)
	_update_guard_visual()

func _update_guard_direction_from_input() -> void:
	var direction := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if direction.length() < 0.2:
		direction = Vector2(facing, 0.0)
	guard_direction = _to_cardinal_direction(direction)
	if absf(guard_direction.x) > 0.0:
		facing = signi(int(guard_direction.x))

func _to_cardinal_direction(direction: Vector2) -> Vector2:
	if absf(direction.x) >= absf(direction.y):
		return Vector2(signf(direction.x) if absf(direction.x) > 0.01 else float(facing), 0.0)
	return Vector2(0.0, signf(direction.y))

func _create_guard_visual() -> void:
	guard_visual = Line2D.new()
	guard_visual.name = "GuardVisual"
	guard_visual.z_index = 5
	guard_visual.width = 6.0
	guard_visual.antialiased = true
	guard_visual.visible = false
	add_child(guard_visual)

func _update_guard_visual() -> void:
	if not is_instance_valid(guard_visual):
		return
	guard_visual.visible = is_guarding
	if not is_guarding:
		return
	var reduction := _get_guard_reduction()
	guard_visual.default_color = Color(0.35, 0.88, 1.0, 0.28 + reduction * 0.62)
	guard_visual.width = 3.5 + reduction * 4.0
	var start_angle := -70.0
	if guard_direction == Vector2.RIGHT:
		start_angle = -70.0
	elif guard_direction == Vector2.LEFT:
		start_angle = 110.0
	elif guard_direction == Vector2.UP:
		start_angle = 200.0
	else:
		start_angle = 20.0
	var arc_points := PackedVector2Array()
	for index in 9:
		var angle := deg_to_rad(start_angle + 140.0 * float(index) / 8.0)
		arc_points.append(Vector2(cos(angle) * 36.0, -32.0 + sin(angle) * 42.0))
	guard_visual.points = arc_points

func _get_guard_reduction() -> float:
	var decay_ratio := clampf(guard_duration / GUARD_DECAY_TIME, 0.0, 1.0)
	return lerpf(GUARD_START_REDUCTION, GUARD_MIN_REDUCTION, decay_ratio)

func _handle_down_tap() -> void:
	if down_tap_timer > 0.0:
		down_tap_timer = 0.0
		_try_drop_through_platform()
	else:
		down_tap_timer = DROP_TAP_WINDOW

func _try_drop_through_platform() -> void:
	if not is_on_floor() or jump_buffer_timer > 0.0:
		return
	if movement_freeze_timer > 0.0 or skill_dash_timer > 0.0:
		return
	if Input.is_action_pressed("jump") or Input.is_action_pressed("move_up"):
		return
	if not is_instance_valid(current_floor_platform):
		_update_current_floor_platform()
	if not _platform_allows_drop_through(current_floor_platform):
		return
	drop_through_platform = current_floor_platform
	add_collision_exception_with(drop_through_platform)
	drop_through_timer = DROP_THROUGH_TIME
	current_floor_platform = null
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	global_position.y += 4.0
	velocity.y = maxf(velocity.y, DROP_THROUGH_SPEED)

func _platform_allows_drop_through(platform: Node) -> bool:
	return is_instance_valid(platform) \
		and platform.is_in_group("sub_platforms") \
		and bool(platform.get_meta("allows_drop_through", false))

func _update_drop_through(delta: float) -> void:
	if drop_through_timer <= 0.0:
		return
	drop_through_timer = maxf(drop_through_timer - delta, 0.0)
	if drop_through_timer <= 0.0:
		_clear_drop_through_exception()

func _clear_drop_through_exception() -> void:
	if is_instance_valid(drop_through_platform):
		remove_collision_exception_with(drop_through_platform)
	drop_through_platform = null
	drop_through_timer = 0.0

func _update_current_floor_platform() -> void:
	current_floor_platform = null
	if not is_on_floor():
		return
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		if collision.get_normal().dot(up_direction) < 0.7:
			continue
		var collider := collision.get_collider()
		if collider is Node and collider.is_in_group("platforms"):
			current_floor_platform = collider
			return

func _apply_movement(delta: float) -> void:
	if movement_freeze_timer > 0.0:
		global_position = movement_freeze_position
		velocity = Vector2.ZERO
		knockback_velocity = Vector2.ZERO
		skill_dash_velocity = Vector2.ZERO
		return
	if skill_dash_timer > 0.0:
		velocity = skill_dash_velocity + knockback_velocity
		move_and_slide()
		velocity -= skill_dash_velocity
		velocity -= knockback_velocity
		_apply_player_soft_collision(delta)
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, current_knockback_decay * delta)
		return
	var custom_gravity_applied := apply_character_gravity(delta)
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		air_jumps_left = max_air_jumps
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)
		if not custom_gravity_applied:
			var gravity_scale := FALL_GRAVITY_MULTIPLIER if velocity.y > 0.0 else 1.0
			velocity.y = minf(velocity.y + GRAVITY * gravity_scale * delta, MAX_FALL_SPEED)

	var accel := FLOOR_ACCEL if is_on_floor() else AIR_ACCEL
	var control_speed_scale := 0.55 if control_slow_timer > 0.0 else 1.0
	var character_movement_multiplier := get_character_movement_multiplier()
	var mobility_scale := 1.0
	if attack_lock_timer > 0.0:
		mobility_scale = ATTACK_GROUND_MOBILITY if is_on_floor() else ATTACK_AIR_MOBILITY
	if not custom_gravity_applied:
		if absf(move_input) > 0.01:
			facing = signi(int(move_input))
			velocity.x = move_toward(velocity.x, move_input * speed * control_speed_scale * mobility_scale * character_movement_multiplier, accel * mobility_scale * character_movement_multiplier * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

		if attack_lock_timer <= 0.0 and jump_buffer_timer > 0.0 and coyote_timer > 0.0:
			velocity.y = jump_velocity * (0.78 if control_jump_slow_timer > 0.0 else 1.0)
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
		elif attack_lock_timer <= 0.0 and jump_buffer_timer > 0.0 and air_jumps_left > 0:
			velocity.y = jump_velocity * 0.86 * (0.78 if control_jump_slow_timer > 0.0 else 1.0)
			air_jumps_left -= 1
			jump_buffer_timer = 0.0

	var input_velocity := velocity
	velocity = input_velocity + knockback_velocity + skill_dash_velocity
	move_and_slide()
	_update_current_floor_platform()
	velocity -= knockback_velocity
	velocity -= skill_dash_velocity
	_apply_player_soft_collision(delta)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, current_knockback_decay * delta)
	skill_dash_velocity = skill_dash_velocity.move_toward(Vector2.ZERO, SKILL_DASH_DECAY * delta)

func basic_attack() -> void:
	if not _can_start_attack():
		return
	var attack_dir := _get_attack_direction()
	var attack_type := _get_basic_attack_type(attack_dir)
	perform_basic_attack(attack_type, attack_dir)

func skill_one() -> void:
	if try_skill_one_followup():
		return
	if not _can_start_attack():
		return
	perform_skill_one()

func skill_two() -> void:
	if not _can_start_attack():
		return
	perform_skill_two()

func ultimate() -> void:
	if try_ultimate_followup():
		return
	if not _can_start_attack():
		return
	perform_ultimate()

func perform_basic_attack(_attack_type: String, _direction: Vector2) -> void:
	pass

func perform_skill_one() -> void:
	pass

func perform_skill_two() -> void:
	pass

func perform_ultimate() -> void:
	pass

func try_skill_two_followup() -> bool:
	return false

func try_skill_one_followup() -> bool:
	return false

func try_ultimate_followup() -> bool:
	return false

func character_physics_process(_delta: float) -> void:
	pass

func character_landing_state() -> void:
	pass

func character_on_hit() -> void:
	pass

func character_on_respawn() -> void:
	pass

func character_cleanup() -> void:
	pass

func character_on_tagged_attack_landed(_hit_tag: String) -> void:
	pass

func configure_character_sprite() -> void:
	pass

func get_character_sprite_style() -> Dictionary:
	return {
		"position": Vector2(0, -32),
		"scale": Vector2(2.0, 2.0),
		"filter": CanvasItem.TEXTURE_FILTER_NEAREST
	}

func get_character_movement_multiplier() -> float:
	return 1.0

func apply_character_gravity(_delta: float) -> bool:
	return false

func _can_start_attack() -> bool:
	return attack_lock_timer <= 0.0 \
		and hitstun_timer <= 0.0 \
		and guard_recovery_timer <= 0.0 \
		and not is_guarding \
		and not action_locked_until_land

func _try_buffered_attack() -> void:
	if attack_buffer_timer <= 0.0 or not is_human:
		return
	if _can_start_attack():
		attack_buffer_timer = 0.0
		basic_attack()

func _get_attack_direction() -> Vector2:
	var x := Input.get_axis("move_left", "move_right") if is_human else float(facing)
	var y := Input.get_axis("move_up", "move_down") if is_human else 0.0
	var direction := Vector2(x, y)
	if direction.length() < 0.2:
		direction = Vector2(facing, 0)
	if absf(direction.x) > 0.2:
		facing = signi(int(direction.x))
	return direction.normalized()

func _get_basic_attack_type(direction: Vector2) -> String:
	if not is_on_floor():
		if direction.y < -0.45:
			return "air_up"
		if direction.y > 0.45:
			return "air_down"
		return "air_side"
	if direction.y < -0.45:
		return "up"
	if direction.y > 0.45:
		return "down"
	if absf(direction.x) > 0.45:
		return "side"
	return "neutral"

func _dir_offset(direction: Vector2, distance: float) -> Vector2:
	return Vector2(direction.x * distance, -16 + direction.y * distance)

func _dir_size(direction: Vector2, base_size: Vector2) -> Vector2:
	if absf(direction.y) > absf(direction.x):
		return Vector2(base_size.y, base_size.x)
	return base_size

func _start_attack(startup: float, recovery: float, action: Callable) -> void:
	attack_lock_timer = startup + recovery
	_play_sprite_action(&"attack", startup + recovery)
	var attack_facing := facing
	current_attack_started_airborne = not is_on_floor()
	_play_attack_windup()
	await get_tree().create_timer(startup).timeout
	if is_defeated or hitstun_timer > 0.0:
		return
	facing = attack_facing
	action.call()

func _play_attack_windup() -> void:
	var tween := create_tween()
	tween.tween_property(body, "scale", Vector2(1.08, 0.94), 0.045)
	tween.tween_property(body, "scale", Vector2.ONE, 0.08)

func _handle_landing_state() -> void:
	character_landing_state()
	if is_guarding and not is_on_floor():
		_stop_guard(true)
	var landed := is_on_floor() and not was_on_floor_last_frame
	if landed and action_locked_until_land:
		action_locked_until_land = false
		attack_lock_timer = 0.0
		_spawn_landing_puff()
	if landed and current_attack_started_airborne and attack_lock_timer > AIR_ATTACK_LANDING_RECOVERY:
		attack_lock_timer = AIR_ATTACK_LANDING_RECOVERY
		current_attack_started_airborne = false
		_spawn_landing_puff()
	if is_on_floor() and attack_lock_timer <= 0.0:
		current_attack_started_airborne = false
	was_on_floor_last_frame = is_on_floor()

func _spawn_landing_puff() -> void:
	var puff := ColorRect.new()
	puff.size = Vector2(44, 8)
	puff.position = global_position + Vector2(-22, -5)
	puff.color = Color(1.0, 0.82, 0.46, 0.34)
	get_parent().add_child(puff)
	var tween := puff.create_tween()
	tween.tween_property(puff, "scale", Vector2(1.45, 0.65), 0.08)
	tween.parallel().tween_property(puff, "modulate:a", 0.0, 0.08)
	tween.tween_callback(puff.queue_free)

func _freeze_movement(duration: float) -> void:
	movement_freeze_timer = duration
	movement_freeze_position = global_position

func _end_skill_dash() -> void:
	skill_dash_velocity = Vector2.ZERO
	body.rotation = 0.0
	body.scale = Vector2.ONE
	body.color = body_color

func _get_late_horizontal_direction() -> int:
	if is_human:
		var horizontal := Input.get_axis("move_left", "move_right")
		if absf(horizontal) > 0.2:
			return signi(int(horizontal))
	return facing

func _get_late_skill_direction() -> Vector2:
	if is_human:
		var direction := Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
		if direction.length() > 0.2:
			return direction.normalized()
	return Vector2(facing, 0)

func _spawn_attack(size: Vector2, offset: Vector2, damage: float, knockback: float, direction: Vector2, color: Color, lifetime: float, damage_type := DAMAGE_NORMAL) -> void:
	var attack := Area2D.new()
	attack.set_script(attack_scene)
	attack.collision_layer = 0
	attack.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	var visual := ColorRect.new()
	visual.name = "Visual"
	shape.name = "CollisionShape2D"
	attack.add_child(shape)
	attack.add_child(visual)
	get_parent().add_child(attack)
	attack.global_position = global_position
	attack.configure(self, size, offset, damage, knockback, direction, color, lifetime, damage_type)

func _spawn_sweeping_attack(size: Vector2, points: Array[Vector2], damage: float, knockback: float, direction: Vector2, color: Color, lifetime: float, damage_type := DAMAGE_NORMAL) -> void:
	var attack := Area2D.new()
	attack.set_script(attack_scene)
	attack.collision_layer = 0
	attack.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	var visual := ColorRect.new()
	visual.name = "Visual"
	shape.name = "CollisionShape2D"
	attack.add_child(shape)
	attack.add_child(visual)
	get_parent().add_child(attack)
	attack.global_position = global_position
	attack.configure_sweep(self, size, points, damage, knockback, direction, color, lifetime, damage_type)

func _spawn_sweeping_stun_attack(size: Vector2, points: Array[Vector2], damage: float, knockback: float, direction: Vector2, color: Color, lifetime: float, stun_duration: float, damage_type := DAMAGE_NORMAL) -> void:
	var attack := Area2D.new()
	attack.set_script(attack_scene)
	attack.collision_layer = 0
	attack.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	var visual := ColorRect.new()
	visual.name = "Visual"
	shape.name = "CollisionShape2D"
	attack.add_child(shape)
	attack.add_child(visual)
	get_parent().add_child(attack)
	attack.global_position = global_position
	attack.configure_sweep_stun(self, size, points, damage, knockback, direction, color, lifetime, stun_duration, damage_type)

func _spawn_sweeping_launch_attack(size: Vector2, points: Array[Vector2], damage: float, knockback: float, direction: Vector2, color: Color, lifetime: float, launch_velocity: Vector2, hitstun_duration: float, hit_tag := "", damage_type := DAMAGE_NORMAL) -> void:
	var attack := Area2D.new()
	attack.set_script(attack_scene)
	attack.collision_layer = 0
	attack.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	var visual := ColorRect.new()
	visual.name = "Visual"
	shape.name = "CollisionShape2D"
	attack.add_child(shape)
	attack.add_child(visual)
	get_parent().add_child(attack)
	attack.global_position = global_position
	attack.configure_sweep_launch(self, size, points, damage, knockback, direction, color, lifetime, launch_velocity, hitstun_duration, hit_tag, damage_type)

func _spawn_projectile(size: Vector2, damage: float, knockback: float, direction: Vector2, color: Color, projectile_speed: float, lifetime: float, damage_type := DAMAGE_NORMAL) -> void:
	var projectile := Area2D.new()
	projectile.set_script(projectile_scene)
	projectile.collision_layer = 0
	projectile.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	var visual := ColorRect.new()
	visual.name = "Visual"
	shape.name = "CollisionShape2D"
	projectile.add_child(shape)
	projectile.add_child(visual)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + direction.normalized() * 44 + Vector2(0, -12)
	projectile.configure(self, size, damage, knockback, direction, color, projectile_speed, lifetime, damage_type)

func apply_hit(attacker: Node, damage: float, base_knockback: float, direction: Vector2, damage_type := DAMAGE_NORMAL) -> bool:
	if is_defeated:
		return false
	var guard_result := _get_guard_result(attacker, direction)
	if guard_result == GUARD_PARRY:
		_perform_parry(attacker)
		return false
	if is_guarding and guard_result == GUARD_NONE:
		_stop_guard(true)
	last_attacker = attacker if is_instance_valid(attacker) else null
	var final_damage := _calculate_incoming_damage(attacker, damage, damage_type)
	var guard_reduction := _get_guard_reduction() if guard_result == GUARD_BLOCK else 0.0
	final_damage *= 1.0 - guard_reduction
	hp = maxf(hp - final_damage, 0.0)
	var danger := 1.0 + (1.0 - hp / max_hp) * LOW_HP_KNOCKBACK_BONUS
	var final_knockback := base_knockback * danger * KNOCKBACK_SCALE / weight
	final_knockback *= 1.0 - guard_reduction * GUARD_KNOCKBACK_REDUCTION_SCALE
	var was_grounded := is_on_floor()
	var hit_direction := _get_hit_direction(direction, was_grounded)
	if guard_result == GUARD_BLOCK and was_grounded:
		hit_direction.y = 0.0
		if hit_direction.length() > 0.01:
			hit_direction = hit_direction.normalized()
		velocity.y = 0.0
		knockback_velocity.y = 0.0
	knockback_velocity += hit_direction * final_knockback
	current_knockback_decay = _get_knockback_decay(final_knockback, was_grounded)
	hitstun_timer = _get_hitstun(final_knockback, was_grounded)
	if guard_result == GUARD_BLOCK:
		hitstun_timer *= 0.45
		guard_recovery_waived = false
		_play_guard_block_effect()
	else:
		_play_sprite_action(&"hurt", hitstun_timer)
	hitstop_timer = VICTIM_HITSTOP
	attack_buffer_timer = 0.0
	jump_buffer_timer = 0.0
	movement_freeze_timer = 0.0
	skill_dash_timer = 0.0
	action_locked_until_land = false
	_end_skill_dash()
	character_on_hit()
	_play_hit_feedback(final_damage, hit_direction, final_knockback)
	_spawn_hit_effect(global_position + Vector2(0, -34), final_damage, final_knockback)
	hp_changed.emit(self)
	_update_visuals()
	if hp <= 0.0:
		_defeat(last_attacker)
	return true

func apply_forced_launch_hit(attacker: Node, damage: float, launch_velocity: Vector2, hitstun_duration: float, effect_knockback: float, direction: Vector2, damage_type := DAMAGE_NORMAL) -> bool:
	if is_defeated:
		return false
	var guard_result := _get_guard_result(attacker, direction)
	if guard_result == GUARD_PARRY:
		_perform_parry(attacker)
		return false
	if is_guarding and guard_result == GUARD_NONE:
		_stop_guard(true)
	last_attacker = attacker if is_instance_valid(attacker) else null
	var final_damage := _calculate_incoming_damage(attacker, damage, damage_type)
	var guard_reduction := _get_guard_reduction() if guard_result == GUARD_BLOCK else 0.0
	final_damage *= 1.0 - guard_reduction
	hp = maxf(hp - final_damage, 0.0)
	var hit_direction := direction.normalized()
	if hit_direction == Vector2.ZERO:
		hit_direction = launch_velocity.normalized()
	var launch_scale := 1.0 - guard_reduction * GUARD_KNOCKBACK_REDUCTION_SCALE
	var applied_launch := launch_velocity * launch_scale
	if guard_result == GUARD_BLOCK:
		applied_launch.y = 0.0
		velocity.y = 0.0
		knockback_velocity.y = 0.0
	knockback_velocity += applied_launch / weight
	current_knockback_decay = KNOCKBACK_GROUND_DECAY if guard_result == GUARD_BLOCK else KNOCKBACK_AIR_DECAY
	hitstun_timer = clampf(hitstun_duration, HITSTUN_MIN, HITSTUN_MAX)
	if guard_result == GUARD_BLOCK:
		hitstun_timer *= 0.45
		guard_recovery_waived = false
		_play_guard_block_effect()
	else:
		_play_sprite_action(&"hurt", hitstun_timer)
	hitstop_timer = VICTIM_HITSTOP
	attack_buffer_timer = 0.0
	jump_buffer_timer = 0.0
	movement_freeze_timer = 0.0
	action_locked_until_land = false
	character_on_hit()
	_play_hit_feedback(final_damage, hit_direction, effect_knockback)
	_spawn_hit_effect(global_position + Vector2(0, -34), final_damage, effect_knockback)
	hp_changed.emit(self)
	_update_visuals()
	if hp <= 0.0:
		_defeat(last_attacker)
	return true

func apply_stun_hit(attacker: Node, damage: float, base_knockback: float, direction: Vector2, stun_duration: float, damage_type := DAMAGE_NORMAL) -> bool:
	var guard_result := _get_guard_result(attacker, direction)
	if not apply_hit(attacker, damage, base_knockback, direction, damage_type):
		return false
	var final_stun := stun_duration * 0.3 if guard_result == GUARD_BLOCK else stun_duration
	hitstun_timer = maxf(hitstun_timer, final_stun)
	_play_stun_effect(final_stun)
	return true

func apply_control_pull(center: Vector2, strength: float, delta: float, slow_duration: float, slow_jump := false) -> void:
	if is_defeated:
		return
	var pull_direction := (center - global_position).normalized()
	knockback_velocity += pull_direction * strength * delta
	current_knockback_decay = KNOCKBACK_AIR_DECAY
	control_slow_timer = maxf(control_slow_timer, slow_duration)
	if slow_jump:
		control_jump_slow_timer = maxf(control_jump_slow_timer, slow_duration)

func apply_yuki_seal_burst(attacker: Node, activation_id: int, damage: float, knockback: float, direction: Vector2) -> bool:
	if last_yuki_activation_hit == activation_id:
		return false
	last_yuki_activation_hit = activation_id
	return apply_hit(attacker, damage, knockback, direction)

func _play_stun_effect(stun_duration: float) -> void:
	var marker := Label.new()
	marker.text = "***"
	marker.position = global_position + Vector2(-22, -116)
	marker.size = Vector2(44, 24)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.add_theme_font_size_override("font_size", 18)
	marker.modulate = Color(1.0, 0.9, 0.2)
	marker.z_index = 7
	get_parent().add_child(marker)
	var tween := marker.create_tween()
	tween.tween_property(marker, "position", marker.position + Vector2(0, -8), minf(stun_duration, 0.2))
	tween.tween_interval(maxf(stun_duration - 0.4, 0.05))
	tween.tween_property(marker, "modulate:a", 0.0, 0.2)
	tween.tween_callback(marker.queue_free)

func _get_guard_result(attacker: Node, attack_direction: Vector2) -> int:
	if not is_guarding or not is_on_floor():
		return GUARD_NONE
	var source_direction := Vector2.ZERO
	if is_instance_valid(attacker) and attacker is Node2D:
		source_direction = attacker.global_position - global_position
	if source_direction.length() < 4.0:
		source_direction = -attack_direction
	if source_direction.length() < 0.01:
		return GUARD_NONE
	if guard_direction != _to_cardinal_direction(source_direction):
		return GUARD_NONE
	return GUARD_PARRY if guard_parry_timer > 0.0 else GUARD_BLOCK

func _perform_parry(attacker: Node) -> void:
	guard_parry_timer = GUARD_PARRY_WINDOW
	guard_recovery_timer = 0.0
	guard_recovery_waived = true
	attack_lock_timer = 0.0
	hitstun_timer = 0.0
	attack_buffer_timer = 0.0
	jump_buffer_timer = 0.0
	if is_instance_valid(attacker) and attacker.has_method("receive_parry_recoil"):
		attacker.receive_parry_recoil(self)
	_play_parry_effect()

func receive_parry_recoil(_defender: Node) -> void:
	hitstop_timer = maxf(hitstop_timer, 0.085)

func _play_guard_block_effect() -> void:
	if not is_instance_valid(guard_visual):
		return
	guard_visual.default_color = Color(0.72, 0.94, 1.0, 0.95)
	guard_visual.scale = Vector2(1.35, 1.35)
	var tween := guard_visual.create_tween()
	tween.tween_property(guard_visual, "scale", Vector2.ONE, 0.1)

func _play_parry_effect() -> void:
	var flash := ColorRect.new()
	flash.size = Vector2(92, 92)
	flash.position = global_position - Vector2(46, 78)
	flash.pivot_offset = flash.size * 0.5
	flash.color = Color(1.0, 0.96, 0.48, 0.92)
	get_parent().add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector2(1.75, 1.75), 0.1)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.13)
	tween.tween_callback(flash.queue_free)
	body.color = Color.WHITE
	var body_tween := body.create_tween()
	body_tween.tween_property(body, "color", Color(1.0, 1.0, 0.65), 0.045)
	body_tween.tween_property(body, "color", body_color, 0.1)

func _calculate_incoming_damage(attacker: Node, base_damage: float, damage_type: String) -> float:
	if damage_type == DAMAGE_FIXED:
		return maxf(base_damage, 0.0)
	var attacker_power := 100.0
	if is_instance_valid(attacker):
		var power_value = attacker.get("attack_power")
		if power_value != null:
			attacker_power = float(power_value)
	return maxf(base_damage * attacker_power / 100.0 * 100.0 / (100.0 + maxf(defense, 0.0)), 1.0)

func _get_hit_direction(direction: Vector2, was_grounded: bool) -> Vector2:
	var hit_direction := direction.normalized()
	if hit_direction == Vector2.ZERO:
		hit_direction = Vector2(facing, GROUNDED_HIT_LIFT).normalized()
	if was_grounded and hit_direction.y > GROUNDED_HIT_LIFT:
		hit_direction.y = GROUNDED_HIT_LIFT
	return hit_direction.normalized()

func _get_knockback_decay(final_knockback: float, was_grounded: bool) -> float:
	var decay := KNOCKBACK_GROUND_DECAY if was_grounded else KNOCKBACK_AIR_DECAY
	if final_knockback >= 480.0:
		decay *= STRONG_KNOCKBACK_DECAY_SCALE
	return decay

func _get_hitstun(final_knockback: float, was_grounded: bool) -> float:
	var stun := final_knockback / 1750.0
	if not was_grounded:
		stun += AIR_HITSTUN_BONUS
	if final_knockback >= 480.0:
		stun += STRONG_HITSTUN_BONUS
	return clampf(stun, HITSTUN_MIN, HITSTUN_MAX)

func _ringout() -> void:
	var phase_multiplier := 1.0 + float(respawn_count) * 0.35
	var attacker := _get_valid_last_attacker()
	apply_hit(attacker, ringout_damage_base * phase_multiplier * match_pressure, 250.0, Vector2(0, -1), DAMAGE_FIXED)
	if not is_defeated:
		respawn_count += 1
		_respawn()

func _get_valid_last_attacker() -> Node:
	if is_instance_valid(last_attacker):
		return last_attacker
	last_attacker = null
	return null

func _defeat(attacker: Node) -> void:
	_clear_drop_through_exception()
	_reset_guard_state()
	_end_skill_dash()
	character_cleanup()
	is_defeated = true
	visible = false
	collision_layer = 0
	collision_mask = 0
	if is_instance_valid(attacker) and attacker != self and attacker.has_method("add_score"):
		attacker.add_score(1)
	defeated.emit(self, attacker)
	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(_respawn_after_defeat)

func _respawn_after_defeat() -> void:
	hp = max_hp
	is_defeated = false
	_apply_realm_active_state()
	respawn_count += 1
	_respawn()

func _respawn() -> void:
	_clear_drop_through_exception()
	_reset_guard_state()
	character_on_respawn()
	if not spawn_points.is_empty():
		global_position = spawn_points.pick_random()
	else:
		global_position = spawn_point
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	skill_dash_velocity = Vector2.ZERO
	skill_dash_timer = 0.0
	body.rotation = 0.0
	movement_freeze_timer = 0.0
	action_locked_until_land = false
	current_knockback_decay = KNOCKBACK_DECAY
	air_jumps_left = max_air_jumps
	ai_controller.reset(global_position)
	_update_visuals()
	respawned.emit(self)

func set_spawn_points(points: Array[Vector2]) -> void:
	spawn_points = points.duplicate()

func set_match_pressure(pressure: float) -> void:
	match_pressure = maxf(pressure, 1.0)

func set_realm(new_realm_index: int, points: Array[Vector2], new_realm_origin := Vector2.ZERO, new_ringout_y := 900.0) -> void:
	realm_index = new_realm_index
	realm_origin = new_realm_origin
	ringout_y = new_ringout_y
	set_spawn_points(points)

func set_realm_active(active: bool) -> void:
	is_realm_active = active
	_apply_realm_active_state()

func _apply_realm_active_state() -> void:
	if is_defeated:
		visible = false
		collision_layer = 0
		collision_mask = 0
		set_physics_process(false)
		return
	visible = true
	collision_layer = PLAYER_LAYER
	collision_mask = WORLD_LAYER
	set_physics_process(true)

func eliminate_by_realm_collapse() -> void:
	if is_defeated:
		return
	hp = 0.0
	_update_visuals()
	_defeat(null)

func reset_for_map(position: Vector2, points: Array[Vector2]) -> void:
	_clear_drop_through_exception()
	_reset_guard_state()
	character_cleanup()
	character_on_respawn()
	control_slow_timer = 0.0
	control_jump_slow_timer = 0.0
	set_spawn_points(points)
	spawn_point = position
	global_position = position
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	skill_dash_velocity = Vector2.ZERO
	skill_dash_timer = 0.0
	attack_lock_timer = 0.0
	hitstun_timer = 0.0
	hitstop_timer = 0.0
	movement_freeze_timer = 0.0
	current_knockback_decay = KNOCKBACK_DECAY
	air_jumps_left = max_air_jumps
	is_defeated = false
	visible = true
	collision_layer = PLAYER_LAYER
	collision_mask = WORLD_LAYER
	if hp <= 0.0:
		hp = max_hp
	body.rotation = 0.0
	action_locked_until_land = false
	ai_controller.reset(global_position)
	_update_visuals()

func add_score(amount: int) -> void:
	score += amount

func add_experience(amount: int) -> void:
	if amount <= 0 or is_dummy or level >= MAX_LEVEL:
		return
	experience += amount
	var gained_level := false
	while level < MAX_LEVEL and experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level += 1
		_apply_level_stats(true)
		experience_to_next_level = 0 if level >= MAX_LEVEL else _get_experience_required(level)
		gained_level = true
		leveled_up.emit(self, level)
	if level >= MAX_LEVEL:
		experience = 0
	experience_changed.emit(self)
	_update_visuals()
	if gained_level:
		_play_level_up_feedback()

func _get_experience_required(target_level: int) -> int:
	return 24 + (target_level - 1) * 14

func _play_level_up_feedback() -> void:
	var level_label := Label.new()
	level_label.text = "LEVEL UP!  Lv.%d" % level
	level_label.position = global_position + Vector2(-62, -132)
	level_label.size = Vector2(124, 30)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.modulate = Color(1.0, 0.9, 0.25)
	get_parent().add_child(level_label)
	var tween := level_label.create_tween()
	tween.tween_property(level_label, "position", level_label.position + Vector2(0, -40), 0.65)
	tween.parallel().tween_property(level_label, "modulate:a", 0.0, 0.65)
	tween.tween_callback(level_label.queue_free)

func _apply_player_soft_collision(delta: float) -> void:
	if is_dummy or is_defeated:
		return
	for other in get_tree().get_nodes_in_group("players"):
		if other == self or not is_instance_valid(other) or other.is_defeated:
			continue
		if other.realm_index != realm_index or not other.is_realm_active:
			continue
		var offset: Vector2 = global_position - other.global_position
		var horizontal_distance := absf(offset.x)
		var vertical_distance := absf(offset.y)
		if horizontal_distance >= PLAYER_SOFT_RADIUS or vertical_distance >= 58.0:
			continue
		var side := signf(offset.x)
		if is_zero_approx(side):
			side = 1.0 if player_id > other.player_id else -1.0
		var push_strength := (PLAYER_SOFT_RADIUS - horizontal_distance) / PLAYER_SOFT_RADIUS
		global_position.x += side * push_strength * PLAYER_SOFT_PUSH * delta

func on_attack_landed(hit_position: Vector2, damage: float, base_knockback: float) -> void:
	hitstop_timer = ATTACKER_HITSTOP
	_spawn_hit_effect(hit_position, damage, base_knockback)
	_spawn_hit_slash(hit_position, base_knockback)
	var shake := clampf(base_knockback / 8500.0, 0.018, 0.055)
	global_position += Vector2(randf_range(-shake, shake), randf_range(-shake, shake)) * 100.0

func on_tagged_attack_landed(hit_tag: String) -> void:
	character_on_tagged_attack_landed(hit_tag)

func _play_hit_feedback(damage: float, direction: Vector2, final_knockback: float) -> void:
	body.color = Color(1.0, 1.0, 1.0)
	var impact_scale := clampf(final_knockback / 700.0, 0.0, 1.0)
	if absf(direction.x) >= absf(direction.y):
		body.scale = Vector2(0.84 - impact_scale * 0.06, 1.14 + impact_scale * 0.08)
	else:
		body.scale = Vector2(1.16 + impact_scale * 0.08, 0.84 - impact_scale * 0.04)
	var tween := create_tween()
	tween.tween_property(body, "color", body_color, 0.09)
	tween.parallel().tween_property(body, "scale", Vector2.ONE, 0.12)
	var number := Label.new()
	number.text = "-%d" % int(round(damage))
	number.add_theme_font_size_override("font_size", int(clampf(16.0 + damage * 0.35, 18.0, 28.0)))
	number.position = global_position + Vector2(-14, -92)
	number.modulate = Color(1.0, 0.78, 0.34)
	get_parent().add_child(number)
	var number_tween := number.create_tween()
	number_tween.tween_property(number, "position", number.position + Vector2(direction.x * 18.0, -42), 0.42)
	number_tween.parallel().tween_property(number, "modulate:a", 0.0, 0.42)
	number_tween.tween_callback(number.queue_free)

func _spawn_hit_effect(hit_position: Vector2, damage: float, base_knockback: float) -> void:
	var spark := ColorRect.new()
	var spark_size := clampf(18.0 + damage * 1.35 + base_knockback * 0.035, 24.0, 56.0)
	spark.size = Vector2(spark_size, spark_size)
	spark.position = hit_position - spark.size * 0.5
	spark.color = Color(1.0, 0.88, 0.32, clampf(0.68 + base_knockback / 1600.0, 0.72, 0.92))
	get_parent().add_child(spark)
	var tween := spark.create_tween()
	tween.tween_property(spark, "scale", Vector2(1.65, 1.65), 0.09)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.09)
	tween.tween_callback(spark.queue_free)

func _spawn_hit_slash(hit_position: Vector2, base_knockback: float) -> void:
	var slash := ColorRect.new()
	var slash_length := clampf(base_knockback * 0.18, 46.0, 92.0)
	slash.size = Vector2(slash_length, 6.0)
	slash.position = hit_position - slash.size * 0.5
	slash.rotation = randf_range(-0.45, 0.45)
	slash.color = Color(1.0, 1.0, 0.82, 0.86)
	get_parent().add_child(slash)
	var tween := slash.create_tween()
	tween.tween_property(slash, "scale", Vector2(1.25, 0.7), 0.07)
	tween.parallel().tween_property(slash, "modulate:a", 0.0, 0.07)
	tween.tween_callback(slash.queue_free)

func set_character(data: Dictionary) -> void:
	character_cleanup()
	_apply_character_data(data)
	hp = max_hp
	_update_visuals()

func _find_human_player() -> Node:
	for p in get_tree().get_nodes_in_group("players"):
		if p != self and p.is_human and p.realm_index == realm_index and p.is_realm_active:
			return p
	return null

func _update_visuals() -> void:
	if not is_node_ready():
		return
	body.color = body_color
	var use_sprite := _uses_character_sprite()
	body.visible = not use_sprite
	if is_instance_valid(character_sprite):
		character_sprite.visible = use_sprite
		_apply_character_sprite_style()
	name_label.text = "%s  Lv.%d\nHP %.0f" % [display_name, level, hp]
	hp_bar.scale.x = clampf(hp / max_hp, 0.0, 1.0)
	exp_bar.scale.x = 1.0 if level >= MAX_LEVEL else clampf(float(experience) / float(experience_to_next_level), 0.0, 1.0)
	_update_character_sprite(true)

func _uses_character_sprite() -> bool:
	return is_instance_valid(character_sprite) \
		and character_sprite.sprite_frames != null \
		and character_sprite.sprite_frames.has_animation(_get_sprite_animation_name(&"idle"))

func _get_sprite_animation_name(base_name: StringName) -> StringName:
	return StringName("%s_%s" % [character_id, base_name])

func _apply_character_sprite_style() -> void:
	if not is_instance_valid(character_sprite):
		return
	var style := get_character_sprite_style()
	character_sprite.position = style.get("position", Vector2(0, -32))
	character_sprite.scale = style.get("scale", Vector2(2.0, 2.0))
	character_sprite.texture_filter = style.get("filter", CanvasItem.TEXTURE_FILTER_NEAREST)

func _play_sprite_action(animation_name: StringName, duration: float) -> void:
	if not _uses_character_sprite():
		return
	sprite_action = animation_name
	sprite_action_timer = maxf(duration, 0.01)
	character_sprite.play(_get_sprite_animation_name(animation_name))

func _update_character_sprite(force := false) -> void:
	if not _uses_character_sprite():
		return
	character_sprite.flip_h = facing < 0
	var target := &"idle"
	if sprite_action_timer > 0.0 and sprite_action != &"":
		target = sprite_action
	elif is_guarding:
		target = &"shield"
	elif not is_on_floor():
		target = &"jump" if velocity.y < 0.0 else &"fall"
	elif absf(velocity.x) > 20.0 or absf(move_input) > 0.1:
		target = &"walk"
	var target_animation := _get_sprite_animation_name(target)
	if force or character_sprite.animation != target_animation:
		character_sprite.play(target_animation)
