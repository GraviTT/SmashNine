extends "res://characters/common/PlayerBase.gd"

const ANIMATION := preload("res://characters/common/CharacterAnimation.gd")
const VFX := preload("res://scripts/Vfx.gd")
const COMBO_RESET_TIME := 0.46
const DASH_HOLD_TIME := 0.13
const DASH_SPEED := 760.0
const DASH_TIME := 0.18
const RISING_FOLLOWUP_WINDOW := 0.18
## Valkyrie Descent (tuned 2026-10-08: 4.5 -> ~12 damage per cast after the match scale).
const ULTIMATE_WAVE_DAMAGE := 26.0
const ULTIMATE_WAVE_REACH := 240.0
const ULTIMATE_AFTERSHOCK_DELAY := 0.28
const ULTIMATE_AFTERSHOCK_DAMAGE := 10.0

var combo_step := 0
var combo_timer := 0.0
var rising_followup_timer := 0.0
var ultimate_diving := false

## Original sheet only (third-party prototype art removed 2026-10-07, user).
func configure_character_sprite() -> void:
	_configure_original_sheet("frey")

func perform_basic_attack(attack_type: String, direction: Vector2) -> void:
	match attack_type:
		"up", "air_up":
			_reset_combo()
			_start_attack(0.12, 0.23, Callable(self, "_up_slash"))
		"down", "air_down":
			_reset_combo()
			_start_attack(0.17, 0.29, Callable(self, "_down_cut"))
		"air_side":
			_reset_combo()
			_start_attack(0.08, 0.17, Callable(self, "_air_slash"))
		_:
			match _consume_combo_step():
				0:
					_start_attack(0.07, 0.16, Callable(self, "_combo_slash_one"))
				1:
					_start_attack(0.08, 0.18, Callable(self, "_combo_slash_two"))
				_:
					_start_attack(0.11, 0.26, Callable(self, "_combo_slash_three"))

func perform_skill_one() -> void:
	_dash_strike_start()

func perform_skill_two() -> void:
	_rising_cleave_start()

func perform_ultimate() -> void:
	_ultimate_start()

func try_skill_two_followup() -> bool:
	if rising_followup_timer <= 0.0 or not _can_start_attack():
		return false
	_spike_start()
	return true

func character_physics_process(delta: float) -> void:
	rising_followup_timer = maxf(rising_followup_timer - delta, 0.0)
	combo_timer = maxf(combo_timer - delta, 0.0)
	if combo_timer <= 0.0:
		combo_step = 0

func character_landing_state() -> void:
	if ultimate_diving and is_on_floor():
		_ultimate_impact()

func character_on_hit() -> void:
	rising_followup_timer = 0.0
	ultimate_diving = false
	_reset_combo()

func character_on_respawn() -> void:
	character_on_hit()

func character_cleanup() -> void:
	character_on_hit()

func character_on_tagged_attack_landed(hit_tag: String) -> void:
	if hit_tag != "frey_rising_cleave":
		return
	rising_followup_timer = RISING_FOLLOWUP_WINDOW
	_play_followup_flash()

func _combo_slash_one() -> void:
	velocity.x += facing * 95.0
	_spawn_sweeping_attack(Vector2(42, 34), [
		Vector2(14 * facing, -34),
		Vector2(58 * facing, -32),
		Vector2(100 * facing, -30)
	], 8, 235, Vector2(facing, -0.06), Color(1.0, 0.72, 0.34, 0.55), 0.085)

func _combo_slash_two() -> void:
	velocity.x += facing * 125.0
	_spawn_sweeping_attack(Vector2(44, 36), [
		Vector2(12 * facing, -42),
		Vector2(62 * facing, -34),
		Vector2(108 * facing, -24)
	], 9, 275, Vector2(facing, -0.1), Color(1.0, 0.78, 0.36, 0.58), 0.095)

func _combo_slash_three() -> void:
	velocity.x += facing * 75.0
	_spawn_sweeping_attack(Vector2(52, 42), [
		Vector2(18 * facing, -48),
		Vector2(70 * facing, -34),
		Vector2(118 * facing, -18)
	], 13, 430, Vector2(facing, -0.18), Color(1.0, 0.62, 0.24, 0.64), 0.12)

func _up_slash() -> void:
	velocity.y = minf(velocity.y, -120.0 * GAME_SCALE.JUMP_SPEED)
	_spawn_sweeping_attack(Vector2(40, 44), [
		Vector2(14 * facing, -28),
		Vector2(8 * facing, -68),
		Vector2(0, -114)
	], 10, 310, Vector2(0.12 * facing, -1), Color(1.0, 0.82, 0.4, 0.56), 0.105)

func _down_cut() -> void:
	velocity.y += 130.0
	velocity.x += facing * 55.0
	_spawn_sweeping_attack(Vector2(44, 40), [
		Vector2(12 * facing, -26),
		Vector2(36 * facing, 2),
		Vector2(54 * facing, 38)
	], 12, 380, Vector2(0.3 * facing, 1), Color(1.0, 0.55, 0.24, 0.56), 0.115)

func _air_slash() -> void:
	velocity.x += facing * 120.0
	velocity.y *= 0.82
	_spawn_sweeping_attack(Vector2(40, 32), [
		Vector2(16 * facing, -36),
		Vector2(60 * facing, -32),
		Vector2(104 * facing, -28)
	], 8, 260, Vector2(facing, -0.04), Color(1.0, 0.72, 0.34, 0.52), 0.095)

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

func _dash_strike_start() -> void:
	character_on_hit()
	attack_lock_timer = DASH_HOLD_TIME + 0.34
	_play_sprite_action(&"attack", DASH_HOLD_TIME + 0.34)
	current_attack_started_airborne = not is_on_floor()
	_freeze_movement(DASH_HOLD_TIME)
	var held_facing := facing
	velocity.x = 0.0
	_play_dash_hold()
	if not await _wait_action(DASH_HOLD_TIME):
		return
	if is_defeated or hitstun_timer > 0.0:
		return
	var dash_direction := _get_late_skill_direction()
	if absf(dash_direction.x) > 0.2:
		facing = signi(int(dash_direction.x))
	else:
		facing = held_facing
	movement_freeze_timer = 0.0
	_dash_strike(dash_direction)

func _play_dash_hold() -> void:
	var tween := create_tween()
	tween.tween_property(body, "scale", Vector2(0.82, 1.12), 0.055)
	tween.tween_property(body, "scale", Vector2(1.08, 0.94), 0.055)
	tween.tween_property(body, "scale", Vector2.ONE, 0.045)

func _dash_strike(dash_direction: Vector2) -> void:
	velocity = dash_direction * 180.0
	skill_dash_velocity = dash_direction * DASH_SPEED * GAME_SCALE.WORLD
	skill_dash_timer = DASH_TIME
	body.rotation = dash_direction.angle()
	_spawn_sweeping_attack(Vector2(58, 42), [
		Vector2(0, -34) + dash_direction * 20.0,
		Vector2(0, -34) + dash_direction * 92.0,
		Vector2(0, -34) + dash_direction * 172.0
	], 16, 470, dash_direction, Color(1.0, 0.42, 0.2, 0.64), 0.16)

func _end_skill_dash() -> void:
	ultimate_diving = false
	super._end_skill_dash()

func _rising_cleave_start() -> void:
	character_on_hit()
	var horizontal := _get_late_horizontal_direction()
	if horizontal != 0:
		facing = horizontal
	_start_attack(0.22, 0.38, Callable(self, "_rising_cleave"))

func _rising_cleave() -> void:
	velocity.y = minf(velocity.y, -560.0 * GAME_SCALE.JUMP_SPEED)
	velocity.x += facing * 45.0
	_spawn_sweeping_launch_attack(Vector2(58, 58), [
		Vector2(24 * facing, -20),
		Vector2(44 * facing, -76),
		Vector2(62 * facing, -136)
	], 15, 510, Vector2(0.16 * facing, -1), Color(1.0, 0.9, 0.45, 0.62), 0.16, Vector2(105 * facing, -760), 0.32, "frey_rising_cleave")

func _ultimate_start() -> void:
	_reset_combo()
	current_attack_started_airborne = false
	if is_on_floor():
		attack_lock_timer = 0.95
		_play_sprite_action(&"attack", 0.95)
		_freeze_movement(0.22)
		velocity = Vector2.ZERO
		_play_ultimate_charge()
		if not await _wait_action(0.22):
			return
		movement_freeze_timer = 0.0
		if is_defeated or hitstun_timer > 0.0 or not is_on_floor():
			return
		_ultimate_impact()
	else:
		attack_lock_timer = 1.45
		_play_sprite_action(&"attack", 1.45)
		_ultimate_dive()

func _ultimate_dive() -> void:
	VFX.spawn(get_parent(), "frey_ult_charge", global_position, Vector2.ONE * 1.3 * sqrt(GAME_SCALE.COMBAT))
	ultimate_diving = true
	velocity = Vector2.ZERO
	skill_dash_velocity = Vector2(0.0, 1050.0)
	skill_dash_timer = 1.2
	body.rotation = 0.0
	body.scale = Vector2(0.78, 1.18)
	body.color = Color(1.0, 0.88, 0.32)

func _ultimate_impact() -> void:
	ultimate_diving = false
	skill_dash_timer = 0.0
	_end_skill_dash()
	velocity = Vector2.ZERO
	body.color = body_color
	# With the wave art the hitbox rectangle only needs to hint where it is.
	var wave_alpha := 0.16 if VFX.available("frey_ult_wave") else 0.72
	for side in [-1.0, 1.0]:
		_spawn_sweeping_stun_attack(Vector2(76, 54), [
			Vector2(42 * side, -18),
			Vector2(130 * side, -14),
			Vector2(ULTIMATE_WAVE_REACH * side, -10)
		], ULTIMATE_WAVE_DAMAGE, 420, Vector2(side, -0.12), Color(1.0, 0.72, 0.18, wave_alpha), 0.24, 2.0)
		VFX.spawn(get_parent(), "frey_ult_wave", global_position + Vector2(18 * side, 2), Vector2(side, 1.0) * GAME_SCALE.COMBAT)
	_play_ultimate_release()
	# Aftershock: a second, launching ring once the stun has landed.
	var epoch := action_epoch
	await get_tree().create_timer(ULTIMATE_AFTERSHOCK_DELAY).timeout
	if epoch != action_epoch or is_defeated:
		return
	for side in [-1.0, 1.0]:
		_spawn_sweeping_launch_attack(Vector2(84, 70), [
			Vector2(30 * side, -30),
			Vector2(120 * side, -26),
			Vector2(200 * side, -22)
		], ULTIMATE_AFTERSHOCK_DAMAGE, 560, Vector2(0.5 * side, -1.0), Color(1.0, 0.86, 0.36, wave_alpha), 0.18, Vector2(260 * side, -720), 0.3)
		VFX.spawn(get_parent(), "frey_ult_wave", global_position + Vector2(10 * side, 2), Vector2(0.85 * side, 1.45) * GAME_SCALE.COMBAT, false, 4, Color(1.0, 1.0, 0.8))

func _play_ultimate_charge() -> void:
	VFX.spawn(get_parent(), "frey_ult_charge", global_position, Vector2.ONE * 1.3 * sqrt(GAME_SCALE.COMBAT))
	body.color = Color(1.0, 0.92, 0.42)
	var body_tween := body.create_tween()
	body_tween.tween_property(body, "scale", Vector2(0.82, 1.16), 0.1)
	body_tween.tween_property(body, "scale", Vector2(1.12, 0.9), 0.08)
	body_tween.tween_property(body, "scale", Vector2.ONE, 0.08)
	body_tween.parallel().tween_property(body, "color", body_color, 0.08)
	var glow := ColorRect.new()
	glow.size = Vector2(70, 86)
	glow.position = global_position + Vector2(-35, -76)
	glow.pivot_offset = glow.size * 0.5
	glow.color = Color(1.0, 0.86, 0.24, 0.58)
	glow.z_index = 4
	get_parent().add_child(glow)
	var glow_tween := glow.create_tween()
	glow_tween.tween_property(glow, "scale", Vector2(1.45, 1.45), 0.24)
	glow_tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.24)
	glow_tween.tween_callback(glow.queue_free)

func _play_ultimate_release() -> void:
	var flash := ColorRect.new()
	flash.size = Vector2(150, 24)
	flash.position = global_position + Vector2(-75, -18)
	flash.pivot_offset = flash.size * 0.5
	flash.color = Color(1.0, 0.9, 0.36, 0.78)
	flash.z_index = 5
	get_parent().add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector2(2.2, 0.45), 0.12)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.12)
	tween.tween_callback(flash.queue_free)

func _spike_start() -> void:
	rising_followup_timer = 0.0
	_reset_combo()
	attack_lock_timer = 0.22
	_play_sprite_action(&"attack", 0.22)
	action_locked_until_land = true
	current_attack_started_airborne = true
	velocity.x += facing * 150.0
	velocity.y = minf(velocity.y, -110.0 * GAME_SCALE.JUMP_SPEED)
	_play_attack_windup()
	if not await _wait_action(0.055):
		return
	if is_defeated or hitstun_timer > 0.0:
		return
	_spawn_sweeping_attack(Vector2(76, 48), [
		Vector2(22 * facing, -46),
		Vector2(88 * facing, -30),
		Vector2(150 * facing, -8)
	], 18, 700, Vector2(facing, 0.18), Color(1.0, 0.38, 0.12, 0.7), 0.14)

func _play_followup_flash() -> void:
	body.color = Color(1.0, 1.0, 0.58)
	var tween := create_tween()
	tween.tween_property(body, "color", Color(1.0, 0.75, 0.32), 0.045)
	tween.tween_property(body, "color", Color(1.0, 1.0, 0.72), 0.045)
	tween.tween_property(body, "color", body_color, 0.07)
