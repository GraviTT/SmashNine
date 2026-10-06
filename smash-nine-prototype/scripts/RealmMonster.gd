extends CharacterBody2D

signal defeated(monster: Node, attacker: Node, experience_reward: int)

enum State { NEUTRAL, AGGRO, DEFEATED }

const GRAVITY := 1850.0
const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const MONSTER_LAYER := 4
const ATTACK_SCRIPT := preload("res://scripts/Attack.gd")
const PROJECTILE_SCRIPT := preload("res://scripts/Projectile.gd")

var monster_type := "mossling"
var display_name := "Mossling"
var realm_index := 0
var max_hp := 45.0
var hp := 45.0
var move_speed := 105.0
var attack_damage := 7.0
var attack_range := 62.0
var attack_cooldown := 1.1
var experience_reward := 8
var control_slow_timer := 0.0
var last_yuki_activation_hit := -1
var body_color := Color(0.38, 0.82, 0.32)
var state := State.NEUTRAL
var target: Node
var facing := 1
var patrol_center := Vector2.ZERO
var patrol_radius := 230.0
var wander_timer := 0.0
var wander_direction := 0.0
var attack_timer := 0.0
var hitstun_timer := 0.0
var knockback_velocity := Vector2.ZERO
var is_realm_active := true

var body_visual: ColorRect
var name_label: Label
var hp_fill: ColorRect

func setup(type_id: String, new_realm_index: int, spawn_position: Vector2) -> void:
	monster_type = type_id
	realm_index = new_realm_index
	global_position = spawn_position
	patrol_center = spawn_position
	if monster_type == "ember_imp":
		display_name = "Ember Imp"
		max_hp = 34.0
		move_speed = 125.0
		attack_damage = 6.0
		attack_range = 310.0
		attack_cooldown = 1.65
		experience_reward = 10
		body_color = Color(1.0, 0.38, 0.16)
	else:
		display_name = "Mossling"
		max_hp = 52.0
		move_speed = 105.0
		attack_damage = 8.0
		attack_range = 64.0
		attack_cooldown = 1.05
		experience_reward = 8
		body_color = Color(0.38, 0.82, 0.32)
	hp = max_hp

func _ready() -> void:
	add_to_group("realm_monsters")
	collision_layer = MONSTER_LAYER
	collision_mask = WORLD_LAYER
	_build_body()
	wander_timer = randf_range(0.5, 1.8)
	wander_direction = [-1.0, 1.0].pick_random()

func _build_body() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(42, 44) if monster_type == "mossling" else Vector2(36, 52)
	collision.shape = shape
	collision.position = Vector2(0, -shape.size.y * 0.5)
	add_child(collision)

	body_visual = ColorRect.new()
	body_visual.size = shape.size
	body_visual.position = Vector2(-shape.size.x * 0.5, -shape.size.y)
	body_visual.color = body_color
	body_visual.pivot_offset = shape.size * 0.5
	add_child(body_visual)

	if monster_type == "mossling":
		var cap := ColorRect.new()
		cap.size = Vector2(50, 14)
		cap.position = Vector2(-25, -50)
		cap.color = Color(0.62, 0.96, 0.38)
		add_child(cap)
	else:
		var horn_left := Polygon2D.new()
		horn_left.polygon = PackedVector2Array([Vector2(-16, -48), Vector2(-7, -67), Vector2(-3, -45)])
		horn_left.color = Color(1.0, 0.78, 0.22)
		add_child(horn_left)
		var horn_right := Polygon2D.new()
		horn_right.polygon = PackedVector2Array([Vector2(16, -48), Vector2(7, -67), Vector2(3, -45)])
		horn_right.color = Color(1.0, 0.78, 0.22)
		add_child(horn_right)

	name_label = Label.new()
	name_label.position = Vector2(-55, -92)
	name_label.size = Vector2(110, 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	add_child(name_label)

	var hp_back := ColorRect.new()
	hp_back.color = Color(0.08, 0.08, 0.08, 0.92)
	hp_back.size = Vector2(48, 6)
	hp_back.position = Vector2(-24, -68)
	add_child(hp_back)
	hp_fill = ColorRect.new()
	hp_fill.size = hp_back.size
	hp_fill.color = Color(0.3, 1.0, 0.4)
	hp_back.add_child(hp_fill)
	_update_visuals()

func _physics_process(delta: float) -> void:
	if state == State.DEFEATED or not is_realm_active:
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	hitstun_timer = maxf(hitstun_timer - delta, 0.0)
	control_slow_timer = maxf(control_slow_timer - delta, 0.0)
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)

	if hitstun_timer > 0.0:
		velocity.x = knockback_velocity.x
	else:
		_update_behavior(delta)
		if control_slow_timer > 0.0:
			velocity.x *= 0.55
	velocity += knockback_velocity
	move_and_slide()
	velocity -= knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1050.0 * delta)

func _update_behavior(delta: float) -> void:
	if state == State.NEUTRAL:
		_update_neutral_wander(delta)
		return
	if not _is_valid_target():
		return_to_neutral()
		return
	var offset: Vector2 = target.global_position - global_position
	if absf(offset.x) > 720.0 or absf(offset.y) > 360.0:
		return_to_neutral()
		return
	facing = 1 if offset.x >= 0.0 else -1
	if monster_type == "ember_imp":
		_update_ranged_aggro(offset)
	else:
		_update_melee_aggro(offset)

func _update_neutral_wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(1.0, 2.8)
		wander_direction = [-1.0, 0.0, 1.0].pick_random()
	if absf(global_position.x - patrol_center.x) > patrol_radius:
		wander_direction = -signf(global_position.x - patrol_center.x)
	if wander_direction != 0.0 and not _has_floor_ahead(wander_direction):
		wander_direction *= -1.0
	facing = int(wander_direction) if wander_direction != 0.0 else facing
	velocity.x = move_toward(velocity.x, wander_direction * move_speed * 0.55, 850.0 * delta)

func _update_melee_aggro(offset: Vector2) -> void:
	if absf(offset.x) <= attack_range and absf(offset.y) < 90.0:
		velocity.x = move_toward(velocity.x, 0.0, 1000.0 * get_physics_process_delta_time())
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			_spawn_melee_attack()
		return
	var direction := signf(offset.x)
	if _has_floor_ahead(direction):
		velocity.x = direction * move_speed
	else:
		velocity.x = 0.0

func _update_ranged_aggro(offset: Vector2) -> void:
	var distance := absf(offset.x)
	var direction := signf(offset.x)
	if distance < 145.0 and _has_floor_ahead(-direction):
		velocity.x = -direction * move_speed
	elif distance > 260.0 and _has_floor_ahead(direction):
		velocity.x = direction * move_speed * 0.7
	else:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * get_physics_process_delta_time())
	if distance <= attack_range and absf(offset.y) < 150.0 and attack_timer <= 0.0:
		attack_timer = attack_cooldown
		_spawn_projectile(offset.normalized())

func _has_floor_ahead(direction: float) -> bool:
	if not is_on_floor():
		return true
	var from := global_position + Vector2(direction * 30.0, -8.0)
	var to := from + Vector2(0.0, 82.0)
	var query := PhysicsRayQueryParameters2D.create(from, to, WORLD_LAYER)
	query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _spawn_melee_attack() -> void:
	var attack := Area2D.new()
	attack.set_script(ATTACK_SCRIPT)
	attack.collision_layer = 0
	attack.collision_mask = PLAYER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	attack.add_child(shape)
	var visual := ColorRect.new()
	visual.name = "Visual"
	attack.add_child(visual)
	get_parent().add_child(attack)
	attack.global_position = global_position
	attack.configure(self, Vector2(56, 42), Vector2(42 * facing, -28), attack_damage, 260.0, Vector2(facing, -0.16), Color(0.7, 1.0, 0.36, 0.55), 0.16)

func _spawn_projectile(direction: Vector2) -> void:
	var projectile := Area2D.new()
	projectile.set_script(PROJECTILE_SCRIPT)
	projectile.collision_layer = 0
	projectile.collision_mask = PLAYER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	projectile.add_child(shape)
	var visual := ColorRect.new()
	visual.name = "Visual"
	projectile.add_child(visual)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(32 * facing, -34)
	projectile.configure(self, Vector2(24, 18), attack_damage, 210.0, direction, Color(1.0, 0.42, 0.12, 0.82), 390.0, 1.35)

func apply_hit(attacker: Node, damage: float, base_knockback: float, direction: Vector2, damage_type := "normal") -> bool:
	if state == State.DEFEATED:
		return false
	var final_damage := damage
	if damage_type != "fixed" and is_instance_valid(attacker):
		var power_value = attacker.get("attack_power")
		if power_value != null:
			final_damage *= float(power_value) / 100.0
	hp = maxf(hp - final_damage, 0.0)
	if is_instance_valid(attacker) and attacker.is_in_group("players"):
		state = State.AGGRO
		target = attacker
	var hit_direction := direction.normalized()
	if hit_direction == Vector2.ZERO:
		hit_direction = Vector2.RIGHT
	knockback_velocity += hit_direction * base_knockback * 0.55
	hitstun_timer = clampf(base_knockback / 1800.0, 0.08, 0.24)
	_flash_hit()
	_update_visuals()
	if hp <= 0.0:
		_die(attacker)
	return true

func apply_forced_launch_hit(attacker: Node, damage: float, launch_velocity: Vector2, hitstun_duration: float, _effect_knockback: float, direction: Vector2, damage_type := "normal") -> bool:
	if not apply_hit(attacker, damage, launch_velocity.length(), direction, damage_type):
		return false
	knockback_velocity += launch_velocity * 0.35
	hitstun_timer = maxf(hitstun_timer, hitstun_duration)
	return true

func apply_stun_hit(attacker: Node, damage: float, base_knockback: float, direction: Vector2, stun_duration: float, damage_type := "normal") -> bool:
	if not apply_hit(attacker, damage, base_knockback, direction, damage_type):
		return false
	hitstun_timer = maxf(hitstun_timer, stun_duration)
	return true

func apply_control_pull(center: Vector2, strength: float, delta: float, slow_duration: float, _slow_jump := false) -> void:
	if state == State.DEFEATED:
		return
	knockback_velocity += (center - global_position).normalized() * strength * delta
	control_slow_timer = maxf(control_slow_timer, slow_duration)

func apply_yuki_seal_burst(attacker: Node, activation_id: int, damage: float, knockback: float, direction: Vector2) -> bool:
	if last_yuki_activation_hit == activation_id:
		return false
	last_yuki_activation_hit = activation_id
	return apply_hit(attacker, damage, knockback, direction)

func return_to_neutral() -> void:
	state = State.NEUTRAL
	target = null
	patrol_center = global_position
	wander_timer = 0.0

func set_realm_active(active: bool) -> void:
	is_realm_active = active
	visible = active and state != State.DEFEATED
	set_physics_process(active and state != State.DEFEATED)
	collision_layer = MONSTER_LAYER if active and state != State.DEFEATED else 0

func _is_valid_target() -> bool:
	return is_instance_valid(target) and not target.is_defeated and target.realm_index == realm_index and target.is_realm_active

func _die(attacker: Node) -> void:
	state = State.DEFEATED
	visible = false
	collision_layer = 0
	set_physics_process(false)
	defeated.emit(self, attacker, experience_reward)
	queue_free()

func _flash_hit() -> void:
	if not is_instance_valid(body_visual):
		return
	body_visual.color = Color.WHITE
	var tween := create_tween()
	tween.tween_property(body_visual, "color", body_color, 0.1)

func _update_visuals() -> void:
	if not is_instance_valid(name_label) or not is_instance_valid(hp_fill):
		return
	var disposition := "Neutral" if state == State.NEUTRAL else "Hostile"
	name_label.text = "%s · %s" % [display_name, disposition]
	hp_fill.scale.x = clampf(hp / max_hp, 0.0, 1.0)
	hp_fill.color = Color(0.3, 1.0, 0.4) if state == State.NEUTRAL else Color(1.0, 0.25, 0.16)
