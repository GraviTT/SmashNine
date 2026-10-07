extends "res://characters/common/PlayerBase.gd"
## Rio, spellblade assassin (design/CHARACTER-05.md, plan A): a fast sword whose third
## swing throws a mana wave, a short teleport slash that doubles as recovery, a rune
## shield that takes hits without knockback and throws them back, and six gem swords.
## Two air jumps come from RioData ("air_jumps").

const COMBO_RESET_TIME := 0.4
const BLINK_DISTANCE := 200.0
const BLINK_HOLD := 0.06
const BLINK_RECOVERY := 0.2
const RUNE_DURATION := 0.5
const RUNE_COOLDOWN := 3.0
const RUNE_DAMAGE_SCALE := 0.5
const RUNE_WHIFF_RECOVERY := 0.32
const RUNE_RETURN_DAMAGE_MAX := 15.0
const RUNE_RETURN_KNOCKBACK_MAX := 820.0
const OVERDRIVE_SWORDS := 6
const OVERDRIVE_ORBIT_TIME := 0.55
const OVERDRIVE_FIRE_GAP := 0.07
const OVERDRIVE_RADIUS := 58.0
const OVERDRIVE_SPIN := 7.0
const OVERDRIVE_AIM_RANGE := 720.0
const MANA_COLOR := Color(0.45, 0.78, 1.0, 0.6)
const MANA_WAVE_ART := "res://assets/art/effects/rio_mana_wave.png"
const GEM_SWORD_ART := "res://assets/art/effects/rio_gem_sword.png"
const RUNE_COLOR := Color(0.35, 0.72, 1.0, 0.9)
const GEM_COLORS: Array[Color] = [
	Color(1.0, 0.35, 0.45), Color(1.0, 0.75, 0.3), Color(0.5, 1.0, 0.5),
	Color(0.35, 0.85, 1.0), Color(0.6, 0.5, 1.0), Color(1.0, 0.5, 0.95)
]

var combo_step := 0
var combo_timer := 0.0
var air_blink_available := true
var rune_timer := 0.0
var rune_cooldown_timer := 0.0
var rune_absorbed_hits := 0
var rune_absorbed_knockback := 0.0
var rune_visual: Line2D
var overdrive_swords: Array[Node2D] = []
var overdrive_time := 0.0

func configure_character_sprite() -> void:
	_configure_original_sheet("rio")

func perform_basic_attack(attack_type: String, _direction: Vector2) -> void:
	match attack_type:
		"up", "air_up":
			_reset_combo()
			_start_attack(0.07, 0.2, Callable(self, "_rising_slash").bind(attack_type == "air_up"))
		"down":
			_reset_combo()
			_start_attack(0.08, 0.2, Callable(self, "_low_sweep"))
		"air_down":
			_reset_combo()
			_plunge_start()
		"air_side":
			_reset_combo()
			_start_attack(0.05, 0.15, Callable(self, "_air_slash"))
		_:
			match _consume_combo_step():
				0:
					_start_attack(0.05, 0.12, Callable(self, "_mana_slash_one"))
				1:
					_start_attack(0.05, 0.13, Callable(self, "_mana_slash_two"))
				_:
					_start_attack(0.08, 0.22, Callable(self, "_mana_wave"))

func perform_skill_one() -> void:
	if not is_on_floor() and not air_blink_available:
		return
	_dimension_slash_start()

func perform_skill_two() -> void:
	if rune_cooldown_timer > 0.0:
		return
	_rune_shield_start()

func perform_ultimate() -> void:
	_overdrive_start()

func character_physics_process(delta: float) -> void:
	combo_timer = maxf(combo_timer - delta, 0.0)
	if combo_timer <= 0.0:
		combo_step = 0
	rune_cooldown_timer = maxf(rune_cooldown_timer - delta, 0.0)
	if rune_timer > 0.0:
		rune_timer = maxf(rune_timer - delta, 0.0)
		if rune_timer <= 0.0:
			_show_rune(false)
	if is_on_floor():
		air_blink_available = true
	_update_overdrive_orbit(delta)

func character_on_hit() -> void:
	_reset_combo()
	_clear_overdrive()
	rune_timer = 0.0
	_show_rune(false)

func character_on_respawn() -> void:
	character_on_hit()
	air_blink_available = true
	rune_cooldown_timer = 0.0

func character_cleanup() -> void:
	character_on_respawn()

func character_hit_absorption() -> float:
	return RUNE_DAMAGE_SCALE if rune_timer > 0.0 else -1.0

func character_on_hit_absorbed(attacker: Node, knockback: float, _direction: Vector2) -> void:
	rune_absorbed_hits += 1
	rune_absorbed_knockback += knockback
	if is_instance_valid(attacker) and attacker is Node2D:
		var side := signf((attacker as Node2D).global_position.x - global_position.x)
		if side != 0.0:
			facing = int(side)
	_flash_rune()

# --- J ---

func _mana_slash_one() -> void:
	velocity.x += facing * 80.0
	_spawn_sweeping_attack(Vector2(38, 30), [
		Vector2(12 * facing, -40),
		Vector2(52 * facing, -34),
		Vector2(90 * facing, -26)
	], 7, 200, Vector2(facing, -0.06), MANA_COLOR, 0.075)

func _mana_slash_two() -> void:
	velocity.x += facing * 100.0
	_spawn_sweeping_attack(Vector2(40, 32), [
		Vector2(10 * facing, -22),
		Vector2(54 * facing, -34),
		Vector2(94 * facing, -46)
	], 8, 230, Vector2(facing, -0.12), MANA_COLOR, 0.08)

## Third swing: a short slash plus a mana wave that flies about 150 px.
func _mana_wave() -> void:
	velocity.x += facing * 60.0
	_spawn_sweeping_attack(Vector2(44, 40), [
		Vector2(16 * facing, -50),
		Vector2(62 * facing, -34),
		Vector2(100 * facing, -16)
	], 7, 260, Vector2(facing, -0.14), Color(0.55, 0.85, 1.0, 0.66), 0.1)
	var wave := _spawn_projectile(Vector2(24, 54), 6, 300, Vector2(facing, 0), Color(0.5, 0.85, 1.0, 0.7), 640.0, 0.24)
	wave.set_art(MANA_WAVE_ART, Color.WHITE, 1.0)

func _rising_slash(airborne: bool) -> void:
	velocity.y = minf(velocity.y, -300.0 if airborne else -140.0)
	_spawn_sweeping_launch_attack(Vector2(40, 46), [
		Vector2(16 * facing, -24),
		Vector2(10 * facing, -70),
		Vector2(0, -112)
	], 8, 300, Vector2(0.1 * facing, -1), MANA_COLOR, 0.1, Vector2(70 * facing, -640), 0.26)

func _low_sweep() -> void:
	velocity.x += facing * 70.0
	_spawn_sweeping_attack(Vector2(52, 26), [
		Vector2(10 * facing, -10),
		Vector2(56 * facing, -8),
		Vector2(100 * facing, -8)
	], 7, 300, Vector2(facing, -0.35), MANA_COLOR, 0.09)

func _air_slash() -> void:
	velocity.x += facing * 110.0
	velocity.y *= 0.8
	_spawn_sweeping_attack(Vector2(40, 30), [
		Vector2(14 * facing, -40),
		Vector2(56 * facing, -34),
		Vector2(98 * facing, -24)
	], 7, 250, Vector2(facing, -0.05), MANA_COLOR, 0.085)

## Air down: a diagonal plunge. Locked until landing, so a whiff is punishable.
func _plunge_start() -> void:
	attack_lock_timer = 0.5
	_play_sprite_action(&"attack", 0.5)
	action_locked_until_land = true
	current_attack_started_airborne = true
	velocity = Vector2(facing * 60.0, -80.0)
	_play_attack_windup()
	if not await _wait_action(0.08):
		return
	if is_defeated or hitstun_timer > 0.0:
		return
	var dive := Vector2(0.45 * facing, 1.0).normalized()
	skill_dash_velocity = dive * 820.0
	skill_dash_timer = 0.22
	_spawn_sweeping_attack(Vector2(38, 50), [
		Vector2(0, -30),
		Vector2(0, -30) + dive * 90.0,
		Vector2(0, -30) + dive * 180.0
	], 10, 380, Vector2(0.35 * facing, 1.0), Color(0.4, 0.7, 1.0, 0.68), 0.2)

func _consume_combo_step() -> int:
	if combo_timer <= 0.0:
		combo_step = 0
	var step := combo_step
	if step >= 2:
		_reset_combo()
	else:
		combo_step = step + 1
		combo_timer = COMBO_RESET_TIME
	return step

func _reset_combo() -> void:
	combo_step = 0
	combo_timer = 0.0

# --- K: dimension slash ---

func _dimension_slash_start() -> void:
	_reset_combo()
	if not is_on_floor():
		air_blink_available = false
	attack_lock_timer = BLINK_HOLD + BLINK_RECOVERY
	_play_sprite_action(&"attack", BLINK_HOLD + BLINK_RECOVERY)
	current_attack_started_airborne = not is_on_floor()
	_freeze_movement(BLINK_HOLD)
	velocity = Vector2(velocity.x * 0.3, minf(velocity.y, 0.0) * 0.3)
	if not await _wait_action(BLINK_HOLD):
		return
	if is_defeated or hitstun_timer > 0.0:
		return
	movement_freeze_timer = 0.0
	var direction := _get_late_skill_direction()
	if absf(direction.x) > 0.2:
		facing = 1 if direction.x > 0.0 else -1
	_dimension_slash(direction)

## Teleports up to BLINK_DISTANCE (stopped by solid ground) and cuts along the gap.
func _dimension_slash(direction: Vector2) -> void:
	var start := global_position
	var travel := direction * BLINK_DISTANCE
	var collision := move_and_collide(travel, true)
	if collision != null:
		travel = collision.get_travel()
	global_position = start + travel
	velocity = direction * 160.0
	if direction.y < -0.3:
		velocity.y = minf(velocity.y, -220.0)
	var back := start - global_position
	_spawn_sweeping_attack(Vector2(56, 44), [
		back + Vector2(0, -34),
		back * 0.5 + Vector2(0, -34),
		Vector2(0, -34)
	], 10, 340, Vector2(direction.x, direction.y - 0.15), Color(0.62, 0.55, 1.0, 0.7), 0.08)
	_play_blink_trail(start, global_position)

# --- L: rune shield ---

func _rune_shield_start() -> void:
	_reset_combo()
	rune_cooldown_timer = RUNE_COOLDOWN
	rune_timer = RUNE_DURATION
	rune_absorbed_hits = 0
	rune_absorbed_knockback = 0.0
	attack_lock_timer = RUNE_DURATION
	_play_sprite_action(&"shield", RUNE_DURATION)
	current_attack_started_airborne = false
	_freeze_movement(RUNE_DURATION)
	velocity = Vector2.ZERO
	_show_rune(true)
	if not await _wait_action(RUNE_DURATION):
		return
	if is_defeated:
		return
	_rune_release()

## Throws back what the shield took; nothing taken means a punishable whiff.
func _rune_release() -> void:
	rune_timer = 0.0
	_show_rune(false)
	movement_freeze_timer = 0.0
	if rune_absorbed_hits == 0:
		attack_lock_timer = RUNE_WHIFF_RECOVERY
		return
	var damage := minf(6.0 + 3.0 * rune_absorbed_hits, RUNE_RETURN_DAMAGE_MAX)
	var knockback := minf(320.0 + rune_absorbed_knockback * 0.5, RUNE_RETURN_KNOCKBACK_MAX)
	attack_lock_timer = 0.16
	_play_sprite_action(&"attack", 0.16)
	_spawn_sweeping_attack(Vector2(70, 84), [
		Vector2(10 * facing, -36),
		Vector2(60 * facing, -36),
		Vector2(110 * facing, -36)
	], damage, knockback, Vector2(facing, -0.25), RUNE_COLOR, 0.12)
	_play_rune_burst()

func _show_rune(active: bool) -> void:
	if active and not is_instance_valid(rune_visual):
		rune_visual = Line2D.new()
		rune_visual.name = "RuneShield"
		rune_visual.width = 3.0
		rune_visual.closed = true
		rune_visual.default_color = RUNE_COLOR
		rune_visual.z_index = 3
		for corner in 6:
			var angle := TAU * corner / 6.0 + PI / 6.0
			rune_visual.add_point(Vector2(0, -34) + Vector2(cos(angle), sin(angle)) * 48.0)
		add_child(rune_visual)
	if is_instance_valid(rune_visual):
		rune_visual.visible = active
		rune_visual.modulate = Color.WHITE

func _flash_rune() -> void:
	if not is_instance_valid(rune_visual):
		return
	rune_visual.modulate = Color(2.0, 2.0, 2.0)
	var tween := rune_visual.create_tween()
	tween.tween_property(rune_visual, "modulate", Color.WHITE, 0.12)

func _play_rune_burst() -> void:
	var ring := Line2D.new()
	ring.width = 4.0
	ring.closed = true
	ring.default_color = RUNE_COLOR
	ring.z_index = 4
	for corner in 6:
		var angle := TAU * corner / 6.0 + PI / 6.0
		ring.add_point(Vector2(cos(angle), sin(angle)) * 40.0)
	get_parent().add_child(ring)
	ring.global_position = global_position + Vector2(40 * facing, -36)
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector2(2.4, 2.4), 0.16)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.16)
	tween.tween_callback(ring.queue_free)

# --- I: infinity overdrive ---

func _overdrive_start() -> void:
	_reset_combo()
	_clear_overdrive()
	attack_lock_timer = 0.18
	_play_sprite_action(&"attack", 0.18)
	_play_attack_windup()
	overdrive_time = 0.0
	for index in OVERDRIVE_SWORDS:
		var sword := _make_gem_sword(GEM_COLORS[index % GEM_COLORS.size()])
		add_child(sword)
		overdrive_swords.append(sword)
	_update_overdrive_orbit(0.0)
	if not await _wait_action(OVERDRIVE_ORBIT_TIME):
		_clear_overdrive()
		return
	while not overdrive_swords.is_empty():
		_fire_gem_sword()
		if not await _wait_action(OVERDRIVE_FIRE_GAP):
			_clear_overdrive()
			return

func _make_gem_sword(color: Color) -> Node2D:
	var sword := Polygon2D.new()
	sword.polygon = PackedVector2Array([Vector2(-12, 0), Vector2(0, -4), Vector2(18, 0), Vector2(0, 4)])
	sword.color = color
	sword.z_index = 3
	return sword

func _update_overdrive_orbit(delta: float) -> void:
	if overdrive_swords.is_empty():
		return
	overdrive_time += delta
	var count := overdrive_swords.size()
	for index in count:
		var sword := overdrive_swords[index]
		if not is_instance_valid(sword):
			continue
		var angle := overdrive_time * OVERDRIVE_SPIN + TAU * index / float(OVERDRIVE_SWORDS)
		sword.position = Vector2(0, -36) + Vector2(cos(angle), sin(angle)) * OVERDRIVE_RADIUS
		sword.rotation = angle + PI * 0.5

func _fire_gem_sword() -> void:
	var sword: Node2D = overdrive_swords.pop_front()
	if not is_instance_valid(sword):
		return
	var from := sword.global_position
	var direction := _overdrive_aim(from)
	var projectile := _spawn_projectile(Vector2(28, 28), 6, 320, direction, sword.color, 980.0, 0.62)
	projectile.global_position = from
	if not projectile.set_art(GEM_SWORD_ART, sword.color.lightened(0.2), 1.0):
		projectile.rotation = direction.angle()
	sword.queue_free()

## Held direction for a human; otherwise the nearest opponent in this realm; else facing.
func _overdrive_aim(from: Vector2) -> Vector2:
	if is_human:
		var held := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
		if held.length() > 0.2:
			return held.normalized()
	var best_target := Vector2.INF
	var best_distance := OVERDRIVE_AIM_RANGE
	for other in get_tree().get_nodes_in_group("players"):
		if other == self or other.is_defeated or other.realm_index != realm_index:
			continue
		var target_point: Vector2 = other.global_position + Vector2(0, -32)
		var distance := from.distance_to(target_point)
		if distance < best_distance:
			best_distance = distance
			best_target = target_point
	if best_target != Vector2.INF:
		return (best_target - from).normalized()
	return Vector2(facing, 0)

func _clear_overdrive() -> void:
	for sword in overdrive_swords:
		if is_instance_valid(sword):
			sword.queue_free()
	overdrive_swords.clear()

func _play_blink_trail(from: Vector2, to: Vector2) -> void:
	var trail := Line2D.new()
	trail.width = 10.0
	trail.default_color = Color(0.62, 0.55, 1.0, 0.55)
	trail.z_index = 2
	trail.add_point(from + Vector2(0, -34))
	trail.add_point(to + Vector2(0, -34))
	get_parent().add_child(trail)
	var tween := trail.create_tween()
	tween.tween_property(trail, "width", 1.0, 0.16)
	tween.parallel().tween_property(trail, "modulate:a", 0.0, 0.16)
	tween.tween_callback(trail.queue_free)
