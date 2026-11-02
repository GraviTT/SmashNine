extends "res://characters/common/PlayerBase.gd"

const ANIMATION := preload("res://characters/common/CharacterAnimation.gd")
const VFX := preload("res://scripts/Vfx.gd")
const COMBO_RESET_TIME := 0.46
## Passive "발키리의 날개" (user 2026-11-03): in the air, hold jump to stop for a moment, then
## dash-slash a short way in one of eight directions (no direction held: she just drops). It is
## its own move but spends an air jump; after the dash, no jump or attack until she lands. Not
## while she is flying from a hit. A tap in the air is still the air jump (on release). Players only.
const WING_HOLD_TIME := 0.15
const WING_HOVER_TIME := 0.3
const WING_DASH_SPEED := 760.0
const WING_DASH_TIME := 0.12
const WING_DASH_REACH := 124.0
## Knockback she can still use the wings through (px/s): above it she is flying from a hit.
const WING_KNOCKBACK_LIMIT := 120.0
## K "검기" (user 2026-11-03, replaces the dash strike): one spin, then a sword wave flies ahead;
## a hit slows for WAVE_SLOW_TIME. Up or down tilts it a little. In the air too.
const WAVE_SLOW_TIME := 2.0
const WAVE_TILT := 0.3
const WAVE_SPEED := 640.0
const WAVE_LIFETIME := 0.36
## L: the rising cleave launches; pressing L again in this window, hit or not (user 2026-11-03),
## swings the big air slash (spike). After the spike she is open until she lands.
const RISING_FOLLOWUP_WINDOW := 0.45
## Spike start-up: two drawings before the strike at the row's adopted 15.75 fps (D39; was 0.055).
const SPIKE_STARTUP := 0.127
## I "강림" (user 2026-11-03): light spreads around her; foes it touches are pulled to her (not
## while guarding), then she slams the floor (in the air: dives to the floor below first). The
## slam comes whether or not the light caught anyone. Waves tuned 2026-10-08.
const ULTIMATE_LIGHT_TIME := 0.45
const ULTIMATE_LIGHT_RADIUS := 220.0
const ULTIMATE_PULL_SPEED := 900.0
const ULTIMATE_WAVE_DAMAGE := 26.0
const ULTIMATE_WAVE_REACH := 240.0
const ULTIMATE_AFTERSHOCK_DELAY := 0.28
const ULTIMATE_AFTERSHOCK_DAMAGE := 10.0
## Redrawn 2026-10-13/14 (D33-D35): every motion is 6 frames and keeps its old length
## (fps x 6 / old frames), the idle at 6.3 fps (D37). The base `attack` row is the J chain's
## 128-px fallback. The walk is 8 frames at 13.3 fps and fills two sheet rows (user 2026-10-15).
const SHEET_ROWS := [["idle", 6, 6.3, true], ["walk", 8, 13.3, true], ["jump", 1, 1.0, false], ["fall", 1, 1.0, false], ["attack", 6, 21.0, false], ["shield", 6, 12.0, false], ["hurt", 1, 1.0, false]]
## 192-px cells (D34): big poses keep the idle head size. The J chain lives here as attack_chain.
const MOVE_SHEET_ROWS := [
	["attack_up", 6, 21.0, false],
	["attack_down", 6, 21.0, false],
	["attack_air_side", 6, 21.0, false],
	["dash_strike", 6, 21.0, false],
	["rising_cleave", 6, 16.8, false],
	["spike_followup", 6, 21.0, false],
	["descent", 6, 14.0, false],
	["tumble", 6, 21.0, true],
	["attack_chain", 6, 21.0, false],
]

var combo_step := 0
var combo_timer := 0.0
var rising_followup_timer := 0.0
var ultimate_diving := false
## >= 0 while a jump press in the air is held to see whether it becomes the wing hover.
var wing_hold_timer := -1.0
var wing_hovering := false
## Fighters the descent light touched, dragged to her until the slam.
var ultimate_caught: Array[Node] = []
var ultimate_pulling := false

## Original sheet only (third-party prototype art removed 2026-10-07, user).
func configure_character_sprite() -> void:
	_configure_original_sheet("frey")

func get_move_sheet_rows() -> Array:
	return MOVE_SHEET_ROWS

func get_sheet_rows() -> Array:
	return SHEET_ROWS

func perform_basic_attack(attack_type: String, direction: Vector2) -> void:
	match attack_type:
		"up", "air_up":
			_reset_combo()
			_start_attack(0.12, 0.23, Callable(self, "_up_slash"), Vector2i(1, 3), &"attack_up")
		"down", "air_down":
			_reset_combo()
			_start_attack(0.17, 0.29, Callable(self, "_down_cut"), Vector2i(2, 3), &"attack_down")
		"air_side":
			_reset_combo()
			_start_attack(0.106, 0.17, Callable(self, "_air_slash"), Vector2i(1, 2), &"attack_air_side")
		_:
			# Each hit plays its own two frames of the chain row (wind-up, cut): a quick cut, a
			# second cut, the wide finisher. The base attack row holds the same frames at 128 px.
			match _consume_combo_step():
				0:
					_start_attack(0.07, 0.16, Callable(self, "_combo_slash_one"), Vector2i(0, 1), &"attack_chain", Vector2i(0, 1))
				1:
					_start_attack(0.08, 0.18, Callable(self, "_combo_slash_two"), Vector2i(2, 3), &"attack_chain", Vector2i(2, 3))
				_:
					_play_finisher_glint()
					_start_attack(0.11, 0.26, Callable(self, "_combo_slash_three"), Vector2i(4, 5), &"attack_chain", Vector2i(4, 5))

func perform_skill_one() -> void:
	_sword_wave_start()

func perform_skill_two() -> void:
	_rising_cleave_start()

func perform_ultimate() -> void:
	_ultimate_start()

## The spike cancels the rising cleave's recovery: the window opens while that recovery still
## locks attacks, so with the plain attack check it could never be pressed.
func try_skill_two_followup() -> bool:
	if rising_followup_timer <= 0.0 or hitstun_timer > 0.0 or is_guarding or action_locked_until_land:
		return false
	_spike_start()
	return true

func character_physics_process(delta: float) -> void:
	rising_followup_timer = maxf(rising_followup_timer - delta, 0.0)
	combo_timer = maxf(combo_timer - delta, 0.0)
	if combo_timer <= 0.0:
		combo_step = 0
	_update_wing(delta)
	if ultimate_pulling:
		_pull_caught()

func character_landing_state() -> void:
	if ultimate_diving and is_on_floor():
		_ultimate_impact()

func character_on_hit() -> void:
	rising_followup_timer = 0.0
	ultimate_diving = false
	wing_hold_timer = -1.0
	wing_hovering = false
	_release_caught()
	_reset_combo()

func character_on_respawn() -> void:
	character_on_hit()

func character_cleanup() -> void:
	character_on_hit()

# --- Passive: Valkyrie wings ---

## A held press in the air is hers to read; a tap still becomes the air jump.
func character_defers_air_jump() -> bool:
	return is_human and coyote_timer <= 0.0 and _wing_usable()

func _wing_usable() -> bool:
	return not is_on_floor() and air_jumps_left > 0 and hitstun_timer <= 0.0 \
		and knockback_velocity.length() < WING_KNOCKBACK_LIMIT and attack_lock_timer <= 0.0 \
		and not action_locked_until_land and skill_dash_timer <= 0.0 and movement_freeze_timer <= 0.0 \
		and not wing_hovering and not is_guarding

func _jump_held() -> bool:
	return Input.is_action_pressed("jump") or Input.is_action_pressed("move_up")

func _update_wing(delta: float) -> void:
	if not is_human:
		return
	if wing_hold_timer < 0.0:
		if jump_buffer_timer > 0.0 and coyote_timer <= 0.0 and _wing_usable():
			wing_hold_timer = 0.0
			jump_buffer_timer = 0.0
		return
	if not _wing_usable():
		wing_hold_timer = -1.0
		return
	if _jump_held():
		wing_hold_timer += delta
		if wing_hold_timer >= WING_HOLD_TIME:
			_start_wing_hover()
		return
	# Released before the hover: a plain air jump.
	wing_hold_timer = -1.0
	_perform_air_jump()

func _start_wing_hover() -> void:
	wing_hold_timer = -1.0
	air_jumps_left -= 1
	wing_hovering = true
	_reset_combo()
	rising_followup_timer = 0.0
	attack_lock_timer = WING_HOVER_TIME
	current_attack_started_airborne = true
	_freeze_movement(WING_HOVER_TIME)
	velocity = Vector2.ZERO
	# The dash row's aim frames (1-2) held while she hangs in the air.
	_play_move_sprite_pose(&"dash_strike", 0, 0, WING_HOVER_TIME, 0, 1)
	_play_dash_hold()
	_play_wing_spread()
	var held_facing := facing
	if not await _wait_action(WING_HOVER_TIME):
		wing_hovering = false
		return
	wing_hovering = false
	if is_defeated or hitstun_timer > 0.0:
		return
	movement_freeze_timer = 0.0
	var direction := _wing_direction()
	if direction == Vector2.ZERO:
		return
	if absf(direction.x) > 0.2:
		facing = signi(int(signf(direction.x)))
	else:
		facing = held_facing
	_wing_dash(direction)

## The eight-way input when the hover ends, or none (she drops).
func _wing_direction() -> Vector2:
	var direction := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	return direction.normalized() if direction.length() > 0.2 else Vector2.ZERO

func _wing_dash(direction: Vector2) -> void:
	action_locked_until_land = true
	air_jumps_left = 0
	attack_lock_timer = WING_DASH_TIME + 0.18
	_play_move_sprite_pose(&"dash_strike", 3, 3, 0.3, 2, 5)
	velocity = direction * 160.0
	skill_dash_velocity = direction * WING_DASH_SPEED * GAME_SCALE.WORLD
	skill_dash_timer = WING_DASH_TIME
	body.rotation = direction.angle()
	# The dash draws its own streak (frey_k) instead of the generic slash.
	attack_art_enabled = false
	_spawn_sweeping_attack(Vector2(54, 40), [
		Vector2(0, -34) + direction * 20.0,
		Vector2(0, -34) + direction * 72.0,
		Vector2(0, -34) + direction * WING_DASH_REACH
	], 12, 420, direction, Color(1.0, 0.42, 0.2, 0.64), WING_DASH_TIME + 0.02)
	attack_art_enabled = true
	_draw_skill_art("frey_k", global_position + GAME_SCALE.BODY_CENTRE, direction, (WING_DASH_REACH * GAME_SCALE.COMBAT + 54.0) / 224.0)

## Gold wings behind her while she hangs (the ultimate's wing glow, small, until the passive has
## its own art).
func _play_wing_spread() -> void:
	var wings := VFX.spawn(self, "frey_ult_charge", Vector2.ZERO, Vector2.ONE * 1.15, false, -1, Color.WHITE, true)
	if wings != null:
		return
	_play_ultimate_charge()

const SPIKE_RING_ART := "res://assets/art/effects/passive/frey_spike_ring.png"

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

func _end_skill_dash() -> void:
	ultimate_diving = false
	super._end_skill_dash()

# --- K: sword wave ---

## One spin (the spike row's sweep until the spin has its own drawing), then the wave.
func _sword_wave_start() -> void:
	_reset_combo()
	rising_followup_timer = 0.0
	var horizontal := _get_late_horizontal_direction()
	if horizontal != 0:
		facing = horizontal
	_start_attack(0.16, 0.26, Callable(self, "_sword_wave"), Vector2i(4, 5), &"spike_followup")

func _sword_wave() -> void:
	var direction := Vector2(facing, _wave_tilt() * WAVE_TILT).normalized()
	var wave: Node = _spawn_projectile(Vector2(30, 64), 10, 300, direction, Color(1.0, 0.82, 0.32, 0.8), WAVE_SPEED, WAVE_LIFETIME)
	wave.hit_slow_time = WAVE_SLOW_TIME
	_dress_wave(wave, direction)

## Up (-1), down (+1) or level (0) at the moment the wave leaves.
func _wave_tilt() -> float:
	if is_human:
		return signf(Input.get_axis("move_up", "move_down"))
	var aim: Vector2 = ai_controller.aim_direction
	return signf(aim.y) if absf(aim.y) > 0.35 else 0.0

## The gold crescent of her slash art (frame 2 of frey_slash) flying as the wave, until the wave
## has its own drawing; the coloured rectangle stays without the art.
func _dress_wave(wave: Node, direction: Vector2) -> void:
	var frames := VFX.frame_textures("frey_slash")
	if frames.size() < 2:
		return
	var sprite := Sprite2D.new()
	sprite.name = "WaveArt"
	sprite.texture = frames[1]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.rotation = direction.angle()
	sprite.scale = Vector2.ONE * 0.5
	wave.add_child(sprite)
	wave.get_node("Visual").visible = false

# --- L: rising cleave, then the spike ---

func _rising_cleave_start() -> void:
	_reset_combo()
	rising_followup_timer = 0.0
	var horizontal := _get_late_horizontal_direction()
	if horizontal != 0:
		facing = horizontal
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
	attack_art_enabled = true
	# Rising arc (frey_l, drawn upward from the feet) in front of her.
	var cleave := EFFECT_STRIPS.spawn(get_parent(), "frey_l", global_position + Vector2(44.0 * GAME_SCALE.COMBAT * facing, 0), Vector2.ONE * (136.0 * GAME_SCALE.COMBAT + 58.0) / 192.0, false, 5)
	if cleave != null:
		cleave.flip_h = facing < 0
	# The second press is open now, hit or not.
	rising_followup_timer = RISING_FOLLOWUP_WINDOW
	_play_followup_flash()

func _spike_start() -> void:
	rising_followup_timer = 0.0
	_reset_combo()
	attack_lock_timer = SPIKE_STARTUP + 0.165
	_play_move_sprite_pose(&"spike_followup", 2, 3, SPIKE_STARTUP + 0.165, -1, -1, SPIKE_STARTUP)
	# Open until she lands.
	action_locked_until_land = true
	current_attack_started_airborne = true
	velocity.x += facing * 150.0
	velocity.y = minf(velocity.y, -110.0 * GAME_SCALE.JUMP_SPEED)
	_play_attack_windup()
	if not await _wait_action(SPIKE_STARTUP):
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

# --- I: descent ---

func _ultimate_start() -> void:
	_reset_combo()
	current_attack_started_airborne = false
	var grounded := is_on_floor()
	var after_light := 0.73 if grounded else 1.45
	attack_lock_timer = ULTIMATE_LIGHT_TIME + after_light
	# On the ground the slam drawing comes with the slam; in the air she holds the charge, then dives.
	_play_move_sprite_pose(&"descent", -1, -1, ULTIMATE_LIGHT_TIME + after_light, -1, -1, ULTIMATE_LIGHT_TIME if grounded else -1.0)
	_freeze_movement(ULTIMATE_LIGHT_TIME)
	velocity = Vector2.ZERO
	_play_ultimate_charge()
	_spread_light()
	if not await _wait_action(ULTIMATE_LIGHT_TIME):
		_release_caught()
		return
	movement_freeze_timer = 0.0
	if is_defeated or hitstun_timer > 0.0:
		_release_caught()
		return
	if is_on_floor():
		_ultimate_impact()
	else:
		_ultimate_dive()

## The light: everyone it reaches while it shines is caught and dragged to her until the slam.
func _spread_light() -> void:
	ultimate_caught.clear()
	ultimate_pulling = true
	_show_light()

func _pull_caught() -> void:
	var radius := ULTIMATE_LIGHT_RADIUS * GAME_SCALE.COMBAT
	var centre := global_position + Vector2(0, -8)
	if movement_freeze_timer > 0.0:
		for target in get_tree().get_nodes_in_group("players"):
			if target == self or target.is_defeated or target.realm_index != realm_index or ultimate_caught.has(target):
				continue
			if target.global_position.distance_to(centre) <= radius and not target.is_guarding:
				ultimate_caught.append(target)
	for target in ultimate_caught:
		if is_instance_valid(target) and not target.is_defeated:
			target.apply_grab_pull(centre, ULTIMATE_PULL_SPEED)

func _release_caught() -> void:
	ultimate_pulling = false
	ultimate_caught.clear()

## A gold disc that grows to the light's reach and fades (until the light has its own art).
func _show_light() -> void:
	var radius := ULTIMATE_LIGHT_RADIUS * GAME_SCALE.COMBAT
	var light := Polygon2D.new()
	light.name = "DescentLight"
	var points := PackedVector2Array()
	for index in 48:
		var angle := TAU * float(index) / 48.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	light.polygon = points
	light.color = Color(1.0, 0.82, 0.32, 0.07)
	light.position = Vector2(0, -40)
	light.scale = Vector2.ONE * 0.2
	light.z_index = -1
	# Added light, so it brightens the realm instead of greying it.
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	light.material = glow
	add_child(light)
	var edge := Line2D.new()
	edge.points = points
	edge.closed = true
	edge.width = 4.0
	edge.default_color = Color(1.0, 0.9, 0.5, 0.9)
	edge.use_parent_material = true
	light.add_child(edge)
	var tween := light.create_tween()
	tween.tween_property(light, "scale", Vector2.ONE, 0.14)
	tween.tween_interval(ULTIMATE_LIGHT_TIME - 0.24)
	tween.tween_property(light, "modulate:a", 0.0, 0.1)
	tween.tween_callback(light.queue_free)

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
	_release_caught()
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
	await get_tree().create_timer(ULTIMATE_AFTERSHOCK_DELAY, true, true).timeout
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
