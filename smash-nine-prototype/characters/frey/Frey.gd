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
## Passive "발키리의 추격" (2026-10-10 night; Codex QA-17 blind proposal 1, lead's numbers): a
## launcher that lands (L rising cleave, up J) marks its target for PURSUIT_TIME; airborne and
## moving toward it, Frey flies PURSUIT_SPEED times faster. Ends on her next attack, on landing,
## or when she is hit. No damage or knockback change (her balance is on hold: identity, not power).
## Air acceleration alone would not show: she reaches full air speed in 0.07 s.
const PURSUIT_TIME := 1.0
const PURSUIT_SPEED := 1.15
const PURSUIT_MARK_RISE := 118.0
const MOVE_SHEET_ROWS := [
	["attack_up", 4, 14.0, false],
	["attack_down", 4, 14.0, false],
	["attack_air_side", 4, 14.0, false],
	["dash_strike", 4, 14.0, false],
	["rising_cleave", 5, 14.0, false],
	["spike_followup", 4, 14.0, false],
	["descent", 6, 14.0, false],
	["tumble", 4, 14.0, true],
]

var combo_step := 0
var combo_timer := 0.0
var rising_followup_timer := 0.0
var ultimate_diving := false
var pursuit_target: Node2D
var pursuit_timer := 0.0
var pursuit_mark: Node2D

## Original sheet only (third-party prototype art removed 2026-10-07, user).
func configure_character_sprite() -> void:
	_configure_original_sheet("frey")

func get_move_sheet_rows() -> Array:
	return MOVE_SHEET_ROWS

func perform_basic_attack(attack_type: String, direction: Vector2) -> void:
	_end_pursuit()
	match attack_type:
		"up", "air_up":
			_reset_combo()
			_start_attack(0.12, 0.23, Callable(self, "_up_slash"), Vector2i(1, 3), &"attack_up")
		"down", "air_down":
			_reset_combo()
			_start_attack(0.17, 0.29, Callable(self, "_down_cut"), Vector2i(2, 3), &"attack_down")
		"air_side":
			_reset_combo()
			_start_attack(0.08, 0.17, Callable(self, "_air_slash"), Vector2i(1, 2), &"attack_air_side")
		_:
			# Each hit plays its own part of the attack row: a quick cut, a second cut, the wide
			# finisher (they all replayed the whole row before).
			match _consume_combo_step():
				0:
					_start_attack(0.07, 0.16, Callable(self, "_combo_slash_one"), Vector2i(0, 1))
				1:
					_start_attack(0.08, 0.18, Callable(self, "_combo_slash_two"), Vector2i(1, 2))
				_:
					_play_finisher_glint()
					_start_attack(0.11, 0.26, Callable(self, "_combo_slash_three"), Vector2i(2, 3))

func perform_skill_one() -> void:
	_dash_strike_start()

func perform_skill_two() -> void:
	_rising_cleave_start()

func perform_ultimate() -> void:
	_ultimate_start()

## The spike cancels the rising cleave's recovery: the window opens while that recovery still
## locks attacks, so with the plain attack check it could never be pressed (lead's trace
## 2026-10-10: hit at 0.22 s, window 0.18 s, lock until 0.6 s).
func try_skill_two_followup() -> bool:
	if rising_followup_timer <= 0.0 or hitstun_timer > 0.0 or is_guarding or action_locked_until_land:
		return false
	_spike_start()
	return true

func character_physics_process(delta: float) -> void:
	rising_followup_timer = maxf(rising_followup_timer - delta, 0.0)
	_update_pursuit(delta)
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
	_end_pursuit()

func character_on_attack_hit_body(body: Node, attack: Node) -> void:
	if attack.has_meta("frey_launcher") and body is Node2D:
		_mark_pursuit(body as Node2D)

func get_character_movement_multiplier() -> float:
	if pursuit_timer <= 0.0 or is_on_floor() or not is_instance_valid(pursuit_target) or absf(move_input) <= 0.1:
		return 1.0
	var toward := signf(pursuit_target.global_position.x - global_position.x)
	return PURSUIT_SPEED if toward != 0.0 and signf(move_input) == toward else 1.0

func _mark_pursuit(target: Node2D) -> void:
	pursuit_target = target
	pursuit_timer = PURSUIT_TIME
	if not is_instance_valid(pursuit_mark):
		pursuit_mark = _make_pursuit_mark()
		get_parent().add_child(pursuit_mark)
	pursuit_mark.global_position = target.global_position + Vector2(0, -PURSUIT_MARK_RISE)

func _update_pursuit(delta: float) -> void:
	if pursuit_timer <= 0.0:
		return
	pursuit_timer -= delta
	var landed := is_on_floor() and pursuit_timer < PURSUIT_TIME - 0.1
	if pursuit_timer <= 0.0 or landed or not is_instance_valid(pursuit_target) or pursuit_target.get("is_defeated") == true:
		_end_pursuit()
		return
	if is_instance_valid(pursuit_mark):
		pursuit_mark.global_position = pursuit_target.global_position + Vector2(0, -PURSUIT_MARK_RISE)
		pursuit_mark.modulate.a = 0.55 + 0.45 * absf(sin(pursuit_timer * 14.0))

func _end_pursuit() -> void:
	pursuit_timer = 0.0
	pursuit_target = null
	if is_instance_valid(pursuit_mark):
		pursuit_mark.queue_free()
	pursuit_mark = null

## Two small gold wings over the marked target.
## Passive-mark art (Codex ART-22); the drawn shapes stay as the fallback while a file is missing.
const PURSUIT_MARK_ART := "res://assets/art/effects/passive/frey_pursuit_mark.png"
const SPIKE_RING_ART := "res://assets/art/effects/passive/frey_spike_ring.png"

func _make_pursuit_mark() -> Node2D:
	var mark := Node2D.new()
	mark.name = "FreyPursuitMark"
	mark.z_index = 6
	if ResourceLoader.exists(PURSUIT_MARK_ART):
		var art := Sprite2D.new()
		art.texture = load(PURSUIT_MARK_ART)
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mark.add_child(art)
		return mark
	for side in [-1.0, 1.0]:
		var wing := Polygon2D.new()
		wing.polygon = PackedVector2Array([Vector2(0, 0), Vector2(22 * side, -12), Vector2(30 * side, -2), Vector2(18 * side, 2), Vector2(26 * side, 8), Vector2(6 * side, 6)])
		wing.color = Color(1.0, 0.86, 0.36, 0.95)
		mark.add_child(wing)
		var edge := Line2D.new()
		edge.points = wing.polygon
		edge.closed = true
		edge.width = 2.0
		edge.default_color = Color(0.32, 0.2, 0.06, 0.9)
		mark.add_child(edge)
	return mark

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
	# On hit, J2 can start at once (after the hitstop) and lands inside the target's hitstun.
	last_attack.set_meta("chain_cancel", 0.0)

func _combo_slash_two() -> void:
	velocity.x += facing * 125.0
	_spawn_sweeping_attack(Vector2(44, 36), [
		Vector2(12 * facing, -42),
		Vector2(62 * facing, -34),
		Vector2(108 * facing, -24)
	], 9, 275, Vector2(facing, -0.1), Color(1.0, 0.78, 0.36, 0.58), 0.095)
	# On hit, J3 can start at once and lands inside the hitstun.
	last_attack.set_meta("chain_cancel", 0.0)

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
	last_attack.set_meta("frey_launcher", true)

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
	# Wind-up frame held while she aims, then the thrust frame for the dash.
	_play_move_sprite_pose(&"dash_strike", 0, 0, DASH_HOLD_TIME)
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
	_play_move_sprite_pose(&"dash_strike", 3, 3, 0.34)
	_dash_strike(dash_direction)

## A white glint before the third hit: the finisher is coming.
func _play_finisher_glint() -> void:
	if not is_instance_valid(character_sprite):
		return
	character_sprite.self_modulate = Color(1.8, 1.8, 1.8)
	var tween := character_sprite.create_tween()
	tween.tween_property(character_sprite, "self_modulate", Color.WHITE, 0.1)

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
	# Dash strike draws its own streak (frey_k) instead of the generic slash.
	attack_art_enabled = false
	_spawn_sweeping_attack(Vector2(58, 42), [
		Vector2(0, -34) + dash_direction * 20.0,
		Vector2(0, -34) + dash_direction * 92.0,
		Vector2(0, -34) + dash_direction * 172.0
	], 16, 470, dash_direction, Color(1.0, 0.42, 0.2, 0.64), 0.16)
	attack_art_enabled = true
	_draw_skill_art("frey_k", global_position + GAME_SCALE.BODY_CENTRE, dash_direction, (172.0 * GAME_SCALE.COMBAT + 58.0) / 224.0)

func _end_skill_dash() -> void:
	ultimate_diving = false
	super._end_skill_dash()

func _rising_cleave_start() -> void:
	character_on_hit()
	var horizontal := _get_late_horizontal_direction()
	if horizontal != 0:
		facing = horizontal
	_end_pursuit()
	_start_attack(0.22, 0.38, Callable(self, "_rising_cleave"), Vector2i(1, 3), &"rising_cleave")

func _rising_cleave() -> void:
	velocity.y = minf(velocity.y, -560.0 * GAME_SCALE.JUMP_SPEED)
	velocity.x += facing * 45.0
	attack_art_enabled = false
	_spawn_sweeping_launch_attack(Vector2(58, 58), [
		Vector2(24 * facing, -20),
		Vector2(44 * facing, -76),
		Vector2(62 * facing, -136)
	], 15, 510, Vector2(0.16 * facing, -1), Color(1.0, 0.9, 0.45, 0.62), 0.16, Vector2(105 * facing, -760), 0.32, "frey_rising_cleave")
	last_attack.set_meta("frey_launcher", true)
	attack_art_enabled = true
	# Rising arc (frey_l, drawn upward from the feet) in front of her.
	var cleave := EFFECT_STRIPS.spawn(get_parent(), "frey_l", global_position + Vector2(44.0 * GAME_SCALE.COMBAT * facing, 0), Vector2.ONE * (136.0 * GAME_SCALE.COMBAT + 58.0) / 192.0, false, 5)
	if cleave != null:
		cleave.flip_h = facing < 0

func _ultimate_start() -> void:
	_reset_combo()
	current_attack_started_airborne = false
	if is_on_floor():
		attack_lock_timer = 0.95
		_play_move_sprite_pose(&"descent", -1, -1, 0.95)
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
		_play_move_sprite_pose(&"descent", -1, -1, 1.45)
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
	# The waves have their own art: no generic slash on them.
	attack_art_enabled = false
	for side in [-1.0, 1.0]:
		_spawn_sweeping_stun_attack(Vector2(76, 54), [
			Vector2(42 * side, -18),
			Vector2(130 * side, -14),
			Vector2(ULTIMATE_WAVE_REACH * side, -10)
		], ULTIMATE_WAVE_DAMAGE, 420, Vector2(side, -0.12), Color(1.0, 0.72, 0.18, wave_alpha), 0.24, 2.0)
		VFX.spawn(get_parent(), "frey_ult_wave", global_position + Vector2(18 * side, 2), Vector2(side, 1.0) * GAME_SCALE.COMBAT)
	attack_art_enabled = true
	_play_ultimate_release()
	# Aftershock: a second, launching ring once the stun has landed.
	var epoch := action_epoch
	await get_tree().create_timer(ULTIMATE_AFTERSHOCK_DELAY).timeout
	if epoch != action_epoch or is_defeated:
		return
	attack_art_enabled = false
	for side in [-1.0, 1.0]:
		_spawn_sweeping_launch_attack(Vector2(84, 70), [
			Vector2(30 * side, -30),
			Vector2(120 * side, -26),
			Vector2(200 * side, -22)
		], ULTIMATE_AFTERSHOCK_DAMAGE, 560, Vector2(0.5 * side, -1.0), Color(1.0, 0.86, 0.36, wave_alpha), 0.18, Vector2(260 * side, -720), 0.3)
		VFX.spawn(get_parent(), "frey_ult_wave", global_position + Vector2(10 * side, 2), Vector2(0.85 * side, 1.45) * GAME_SCALE.COMBAT, false, 4, Color(1.0, 1.0, 0.8))
	attack_art_enabled = true

func _play_ultimate_charge() -> void:
	VFX.spawn(get_parent(), "frey_ult_charge", global_position, Vector2.ONE * 1.3 * sqrt(GAME_SCALE.COMBAT))
	body.color = Color(1.0, 0.92, 0.42)
	var body_tween := body.create_tween()
	body_tween.tween_property(body, "scale", Vector2(0.82, 1.16), 0.1)
	body_tween.tween_property(body, "scale", Vector2(1.12, 0.9), 0.08)
	body_tween.tween_property(body, "scale", Vector2.ONE, 0.08)
	body_tween.parallel().tween_property(body, "color", body_color, 0.08)
	# The charge art above is the glow; the rectangle only without it (2026-10-09).
	if VFX.available("frey_ult_charge"):
		return
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
	# The wave art spawned with it shows the release; the flat flash only without it (2026-10-09).
	if VFX.available("frey_ult_wave"):
		return
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
	_end_pursuit()
	attack_lock_timer = 0.22
	_play_move_sprite_pose(&"spike_followup", 2, 3, 0.22)
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

## The spike window: a gold ring around Frey and a bright flash on her (the body rectangle this
## used to colour is hidden behind the sprite).
func _play_followup_flash() -> void:
	var ring: Node2D
	if ResourceLoader.exists(SPIKE_RING_ART):
		var art := Sprite2D.new()
		art.texture = load(SPIKE_RING_ART)
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ring = art
	else:
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = Color(1.0, 0.9, 0.42, 0.95)
		line.closed = true
		var points := PackedVector2Array()
		for index in 24:
			var angle := TAU * float(index) / 24.0
			points.append(Vector2(cos(angle), sin(angle)) * 46.0)
		line.points = points
		ring = line
	ring.position = Vector2(0, -40)
	ring.z_index = 6
	add_child(ring)
	var ring_tween := ring.create_tween()
	ring_tween.tween_property(ring, "scale", Vector2(1.5, 1.5), RISING_FOLLOWUP_WINDOW)
	ring_tween.parallel().tween_property(ring, "modulate:a", 0.0, RISING_FOLLOWUP_WINDOW)
	ring_tween.tween_callback(ring.queue_free)
	if is_instance_valid(character_sprite):
		character_sprite.self_modulate = Color(1.6, 1.5, 0.85)
		var sprite_tween := character_sprite.create_tween()
		sprite_tween.tween_property(character_sprite, "self_modulate", Color.WHITE, RISING_FOLLOWUP_WINDOW)
	body.color = Color(1.0, 1.0, 0.58)
	var tween := create_tween()
	tween.tween_property(body, "color", Color(1.0, 0.75, 0.32), 0.045)
	tween.tween_property(body, "color", Color(1.0, 1.0, 0.72), 0.045)
	tween.tween_property(body, "color", body_color, 0.07)
