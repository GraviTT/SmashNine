extends "res://characters/common/PlayerBase.gd"

const ANIMATION := preload("res://characters/common/CharacterAnimation.gd")
const COMET_SCRIPT := preload("res://characters/luna/LunaComet.gd")
const VFX := preload("res://scripts/Vfx.gd")
const HEART_LASER_SCRIPT := preload("res://characters/luna/LunaHeartLaser.gd")

const BRAVE_SHEET_ART := "res://assets/art/luna/luna_brave_sheet.png"
const MOVE_SHEET_ROWS := [
	["star_up", 4, 14.0, false],
	["star_down", 4, 14.0, false],
	["star_comet", 4, 14.0, false],
	["moon_ring", 5, 14.0, false],
	["transform", 6, 14.0, false],
	["tumble", 4, 14.0, true],
]
const BRAVE_MOVE_SHEET_ROWS := [
	["brave_combo", 6, 16.0, false],
	["brave_upper", 4, 16.0, false],
	["brave_low", 4, 16.0, false],
	["brave_air_side", 4, 16.0, false],
	["brave_dive", 4, 16.0, false],
	["comet_drive", 4, 16.0, false],
	["luna_breaker", 6, 16.0, false],
	["heart_laser", 6, 12.0, false],
	["tumble", 4, 14.0, true],
]
const TRANSFORMATION_DURATION := 6.0
const TRANSFORM_BURST_RADIUS := 120.0
const TRANSFORM_BURST_DAMAGE := 14.0
const TRANSFORMATION_MOVEMENT_MULTIPLIER := 1.16
const BRAVE_COMBO_RESET_TIME := 0.42
const STAR_TRAIL_COLOR := Color(1.0, 0.48, 0.9, 0.52)
const STAR_BLOOM_COLOR := Color(0.44, 0.92, 1.0, 0.66)
const BRAVE_IMPACT_COLOR := Color(1.0, 0.84, 0.28, 0.76)
## Passive "별빛 충전" (2026-10-10 night; lead's design with Codex QA-17's precise-echo idea):
## a precise star echo (its trail and its bloom both hit the same target), a comet burst or a
## moon ring hit each gives one star (up to STAR_CHARGE_MAX, circling her). A full set cuts the
## ultimate's remaining cooldown by STAR_CHARGE_COOLDOWN_CUT; while the ultimate is ready the stars
## wait and are spent on the next cooldown. Normal-form play that lands earns Brave Luna sooner.
const STAR_CHARGE_MAX := 5
const STAR_CHARGE_COOLDOWN_CUT := 6.0
const STAR_ORBIT_RADIUS := 44.0
## The side star echo's bloom opens on the body its trail struck (2026-10-10 night: Codex QA-17
## measured the fixed bloom missing 7 of 8 times when Luna walked in from 110 px — it bloomed past
## the target). Only a body at least ECHO_HOME_MIN ahead of her (scaled px, body centre to body
## centre) is followed, and never farther than the bloom's own place, so a foe hugging Normal Luna
## still slips under the bloom.
## Star-charge art (Codex ART-22); the drawn star stays as the fallback while the file is missing.
const STAR_CHARGE_ART := "res://assets/art/effects/passive/luna_star_charge.png"
const ECHO_HOME_MIN := 75.0
const ECHO_HOME_RISE := 48.0

var transformed := false
var has_brave_sheet := false
var transformation_timer := 0.0
var transformation_finishing := false
var transformation_aura: Node2D
var transformation_visual_time := 0.0
var brave_combo_step := 0
var brave_combo_timer := 0.0
var heart_laser: Node
var heart_laser_cast_id := 0
var heart_laser_duration := 0.0
var star_charge := 0
var star_swing_id := 0
## swing id -> {"trail": [bodies], "bloom": [bodies], "done": bool}
var star_swing_hits: Dictionary = {}
## Comet and moon-ring casts that already gave their star.
var star_charged_casts: Dictionary = {}
var star_charge_orbit: Node2D
var star_charge_spin := 0.0

## Original sheet only (third-party prototype art removed 2026-10-07, user).
func configure_character_sprite() -> void:
	if _configure_original_sheet("luna"):
		_add_brave_sheet()

func get_move_sheet_rows() -> Array:
	return MOVE_SHEET_ROWS

## Brave Luna's own sheet (CODEX-ART-06), cut like the normal one into luna_brave_*.
func _add_brave_sheet() -> void:
	if not ResourceLoader.exists(BRAVE_SHEET_ART):
		return
	has_brave_sheet = _add_sheet_animations(character_sprite.sprite_frames, "luna_brave", load(BRAVE_SHEET_ART) as Texture2D)
	var moves := SHEET_ART.original_character_moves_sheet("luna", body_type, "luna_brave")
	_add_move_sheet_animations(character_sprite.sprite_frames, "luna_brave", moves, BRAVE_MOVE_SHEET_ROWS)

## While transformed, every animation comes from the Brave sheet when there is one.
func _get_sprite_animation_name(base_name: StringName) -> StringName:
	var luna := super._get_sprite_animation_name(base_name)
	if not has_brave_sheet:
		return luna
	var brave := StringName("luna_brave_%s" % base_name)
	var wanted := brave if transformed else luna
	var other := luna if transformed else brave
	# A row only one form has (Luna's transform, Brave's heart laser) keeps playing when the
	# form switches under it.
	var frames: SpriteFrames = character_sprite.sprite_frames if is_instance_valid(character_sprite) else null
	if frames != null and not frames.has_animation(wanted) and frames.has_animation(other):
		return other
	return wanted

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
		_start_attack(0.12, 0.3, Callable(self, "_brave_luna_breaker"), Vector2i(-1, -1), &"luna_breaker")
	else:
		_start_attack(0.21, 0.4, Callable(self, "_moon_ring"), Vector2i(-1, -1), &"moon_ring")

func perform_ultimate() -> void:
	_transformation_start()

## While transformed, the ultimate button fires the heart laser instead of starting a new cooldown.
func try_ultimate_followup() -> bool:
	if not transformed:
		return false
	if not transformation_finishing and _can_start_attack():
		_heart_laser_start()
		ultimate_followup_started = true
	return true

func character_physics_process(delta: float) -> void:
	_spend_full_charge()
	if is_instance_valid(star_charge_orbit):
		star_charge_spin += delta * 2.2
		star_charge_orbit.rotation = star_charge_spin
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

func character_on_attack_hit_body(body: Node, attack: Node) -> void:
	if attack.has_meta("luna_star"):
		_record_star_echo_hit(body, attack.get_meta("luna_star") as Vector2i)
	var cast: Variant = attack.get_meta("luna_charge") if attack.has_meta("luna_charge") else null
	if cast != null and not star_charged_casts.has(cast):
		star_charged_casts[cast] = true
		_gain_star()

## A new star echo swing; books of swings and casts long finished are dropped.
func _next_star_swing() -> void:
	star_swing_id += 1
	for key in star_swing_hits.keys():
		if int(key) < star_swing_id - 6:
			star_swing_hits.erase(key)
	if star_charged_casts.size() > 48:
		star_charged_casts.clear()

func _record_star_echo_hit(body: Node, star: Vector2i) -> void:
	var entry: Dictionary = star_swing_hits.get(star.x, {"trail": [], "bloom": [], "done": false})
	if bool(entry.done):
		return
	var part := "trail" if star.y == 0 else "bloom"
	(entry[part] as Array).append(body)
	star_swing_hits[star.x] = entry
	if (entry.trail as Array).has(body) and (entry.bloom as Array).has(body):
		entry.done = true
		_gain_star()

func _gain_star() -> void:
	star_charge = mini(star_charge + 1, STAR_CHARGE_MAX)
	_update_star_orbit()
	_spend_full_charge()

## A full set cuts the cooldown at once; while the ultimate is ready it waits for the next one.
func _spend_full_charge() -> void:
	if star_charge < STAR_CHARGE_MAX or ultimate_cooldown_timer <= 0.0:
		return
	star_charge = 0
	ultimate_cooldown_timer = maxf(ultimate_cooldown_timer - STAR_CHARGE_COOLDOWN_CUT, 0.0)
	_update_star_orbit()
	_play_star_bloom(Vector2(0, -40), 46.0, Color(1.0, 0.92, 0.45, 0.9), 0.22)

func _update_star_orbit() -> void:
	if star_charge <= 0:
		if is_instance_valid(star_charge_orbit):
			star_charge_orbit.queue_free()
		star_charge_orbit = null
		return
	if not is_instance_valid(star_charge_orbit):
		star_charge_orbit = Node2D.new()
		star_charge_orbit.name = "LunaStarCharge"
		star_charge_orbit.position = Vector2(0, -44)
		star_charge_orbit.z_index = 5
		add_child(star_charge_orbit)
	for child in star_charge_orbit.get_children():
		child.queue_free()
	var art: Texture2D = load(STAR_CHARGE_ART) if ResourceLoader.exists(STAR_CHARGE_ART) else null
	for index in star_charge:
		var star: Node2D
		if art != null:
			var icon := Sprite2D.new()
			icon.texture = art
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			star = icon
		else:
			var shape := Polygon2D.new()
			shape.polygon = _make_star_points(7.0, 3.0)
			shape.color = Color(1.0, 0.9, 0.42, 0.95)
			star = shape
		var angle := TAU * float(index) / float(STAR_CHARGE_MAX)
		star.position = Vector2(cos(angle), sin(angle)) * STAR_ORBIT_RADIUS
		star_charge_orbit.add_child(star)

func _reset_star_charge() -> void:
	star_charge = 0
	star_swing_hits.clear()
	star_charged_casts.clear()
	_update_star_orbit()

func character_on_respawn() -> void:
	_end_transformation(true)
	_reset_star_charge()

func character_cleanup() -> void:
	_end_transformation(true)
	_reset_star_charge()

func _perform_star_basic(attack_type: String, _direction: Vector2) -> void:
	if not is_on_floor():
		velocity.y *= 0.72
	match attack_type:
		"up":
			_start_attack(0.12, 0.27, Callable(self, "_star_up_arc").bind(false), Vector2i(-1, -1), &"star_up")
		"air_up":
			_start_attack(0.1, 0.24, Callable(self, "_star_up_arc").bind(true), Vector2i(-1, -1), &"star_up")
		"down":
			_start_attack(0.15, 0.31, Callable(self, "_star_down_arc").bind(false), Vector2i(-1, -1), &"star_down")
		"air_down":
			_start_attack(0.13, 0.28, Callable(self, "_star_down_arc").bind(true), Vector2i(-1, -1), &"star_down")
		"air_side":
			_start_attack(0.09, 0.23, Callable(self, "_star_side_arc").bind(true))
		_:
			_start_attack(0.1, 0.25, Callable(self, "_star_side_arc").bind(false))

func _star_side_arc(airborne: bool) -> void:
	_next_star_swing()
	if airborne:
		velocity.x += facing * 65.0
		velocity.y *= 0.55
	_spawn_sweeping_attack(Vector2(38, 30), [
		Vector2(10 * facing, -42),
		Vector2(52 * facing, -37),
		Vector2(92 * facing, -30)
	], 3.5, 95, Vector2(facing, -0.04), STAR_TRAIL_COLOR, 0.1)
	last_attack.set_meta("luna_star", Vector2i(star_swing_id, 0))
	_spawn_delayed_bloom(Vector2(108 * facing, -30), Vector2(74, 64), 6.5 if airborne else 7.0, 275 if airborne else 305, Vector2(facing, -0.1), 0.065, star_swing_id, true)

func _star_up_arc(airborne: bool) -> void:
	_next_star_swing()
	velocity.y = minf(velocity.y, (-90.0 if airborne else -45.0) * GAME_SCALE.JUMP_SPEED)
	_spawn_sweeping_attack(Vector2(36, 38), [
		Vector2(18 * facing, -28),
		Vector2(12 * facing, -72),
		Vector2(0, -112)
	], 3.5, 90, Vector2(0.1 * facing, -1), STAR_TRAIL_COLOR, 0.11)
	last_attack.set_meta("luna_star", Vector2i(star_swing_id, 0))
	_spawn_delayed_bloom(Vector2(0, -126), Vector2(68, 74), 7.0, 325, Vector2(0.08 * facing, -1), 0.07, star_swing_id)

func _star_down_arc(airborne: bool) -> void:
	_next_star_swing()
	if airborne:
		velocity.y = maxf(velocity.y, 90.0 * GAME_SCALE.JUMP_SPEED)
	else:
		velocity.x += facing * 35.0
	var bloom_offset := Vector2(42 * facing, 58) if airborne else Vector2(58 * facing, 20)
	_spawn_sweeping_attack(Vector2(40, 34), [
		Vector2(10 * facing, -28),
		Vector2(32 * facing, 4),
		bloom_offset
	], 4.0, 110, Vector2(0.18 * facing, 1), STAR_TRAIL_COLOR, 0.12)
	last_attack.set_meta("luna_star", Vector2i(star_swing_id, 0))
	_spawn_delayed_bloom(bloom_offset, Vector2(78, 62), 8.0, 355, Vector2(0.2 * facing, 1), 0.075, star_swing_id)

func _spawn_delayed_bloom(offset: Vector2, size: Vector2, damage: float, knockback: float, direction: Vector2, delay: float, swing_id := -1, follow_struck := false) -> void:
	if not await _wait_action(delay):
		return
	if is_defeated or hitstun_timer > 0.0 or transformed:
		return
	if follow_struck:
		offset = _echo_bloom_offset(offset, swing_id)
	_spawn_attack(size, offset, damage, knockback, direction, STAR_BLOOM_COLOR, 0.12)
	if swing_id >= 0:
		last_attack.set_meta("luna_star", Vector2i(swing_id, 1))
	_play_star_bloom(offset, maxf(size.x, size.y) * 0.42, Color(0.5, 0.96, 1.0, 0.82))

## Where the bloom opens: on the first body this swing's trail struck if it stands between
## ECHO_HOME_MIN and the bloom's own place (within ECHO_HOME_RISE up or down), else its own place.
func _echo_bloom_offset(offset: Vector2, swing_id: int) -> Vector2:
	var entry: Dictionary = star_swing_hits.get(swing_id, {})
	var placed := GAME_SCALE.attack_point(offset)
	for body in entry.get("trail", []):
		if not is_instance_valid(body) or not body is Node2D:
			continue
		var centre: Vector2 = (body as Node2D).global_position + GAME_SCALE.BODY_CENTRE - global_position
		var ahead := centre.x * float(facing)
		if ahead < ECHO_HOME_MIN or ahead > placed.x * float(facing):
			continue
		centre.y = clampf(centre.y, placed.y - ECHO_HOME_RISE, placed.y + ECHO_HOME_RISE)
		return GAME_SCALE.BODY_CENTRE + (centre - GAME_SCALE.BODY_CENTRE) / GAME_SCALE.COMBAT
	return offset

func _star_comet_start() -> void:
	var direction := _get_attack_direction()
	if not is_on_floor():
		velocity *= 0.7
	_start_attack(0.17, 0.34, Callable(self, "_spawn_star_comet").bind(direction), Vector2i(-1, -1), &"star_comet")

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
	comet.global_position = global_position + Vector2(0, -34) + direction.normalized() * 38.0 * GAME_SCALE.COMBAT * 0.75
	comet.configure(self, direction, 12.0, 390.0)
	_draw_skill_art("luna_k", comet.global_position, direction, GAME_SCALE.COMBAT * 0.75)

func attack_effect_name() -> String:
	return "luna_brave_slash" if transformed else "luna_slash"

func _moon_ring() -> void:
	if not is_on_floor():
		velocity.y *= 0.5
	# The ring has its own art (luna_l) around her instead of two generic slashes.
	attack_art_enabled = false
	var right_points := _make_arc_points(90.0, -PI * 0.5, PI * 0.5, 7)
	var left_points := _make_arc_points(90.0, -PI * 0.5, -PI * 1.5, 7)
	var cast := "ring_%d" % Time.get_ticks_usec()
	_spawn_sweeping_attack(Vector2(44, 38), right_points, 12, 405, Vector2(1, -0.08), Color(0.46, 0.94, 1.0, 0.58), 0.24)
	last_attack.set_meta("luna_charge", cast)
	_spawn_sweeping_attack(Vector2(44, 38), left_points, 12, 405, Vector2(-1, -0.08), Color(1.0, 0.5, 0.92, 0.58), 0.24)
	last_attack.set_meta("luna_charge", cast)
	attack_art_enabled = true
	_play_moon_ring_flash(90.0)
	_draw_skill_art("luna_l", global_position + GAME_SCALE.BODY_CENTRE, Vector2.ZERO, (180.0 + 44.0) * GAME_SCALE.COMBAT / 192.0)

func _perform_brave_basic(attack_type: String) -> void:
	match attack_type:
		"up", "air_up":
			_reset_brave_combo()
			_start_attack(0.06, 0.14, Callable(self, "_brave_uppercut").bind(attack_type == "air_up"), Vector2i(-1, -1), &"brave_upper")
		"down":
			_reset_brave_combo()
			_start_attack(0.06, 0.14, Callable(self, "_brave_low_sweep"), Vector2i(-1, -1), &"brave_low")
		"air_down":
			_reset_brave_combo()
			_start_attack(0.07, 0.18, Callable(self, "_brave_dive_kick"), Vector2i(-1, -1), &"brave_dive")
		"air_side":
			_reset_brave_combo()
			_start_attack(0.05, 0.12, Callable(self, "_brave_flying_kick"), Vector2i(-1, -1), &"brave_air_side")
		_:
			match _consume_brave_combo_step():
				# The Brave attack row reads jab, star punch, body kick, spinning kick: each hit plays
				# its own frames (they all replayed the whole row before).
				0:
					_start_attack(0.045, 0.1, Callable(self, "_brave_jab"), Vector2i(0, 1), &"brave_combo", Vector2i(0, 1))
				1:
					_start_attack(0.055, 0.11, Callable(self, "_brave_body_kick"), Vector2i(2, 2), &"brave_combo", Vector2i(2, 3))
				_:
					_start_attack(0.075, 0.18, Callable(self, "_brave_spin_kick"), Vector2i(3, 3), &"brave_combo", Vector2i(3, 5))

func _brave_jab() -> void:
	velocity.x += facing * 90.0
	_spawn_sweeping_attack(Vector2(34, 28), [Vector2(8 * facing, -38), Vector2(42 * facing, -36), Vector2(70 * facing, -34)], 5, 150, Vector2(facing, -0.02), BRAVE_IMPACT_COLOR, 0.075)
	# On hit the body kick can start at once and lands inside the jab's hitstun.
	last_attack.set_meta("chain_cancel", 0.0)
	_play_star_bloom(Vector2(68 * facing, -34), 24.0, BRAVE_IMPACT_COLOR, 0.1)

func _brave_body_kick() -> void:
	velocity.x += facing * 120.0
	_spawn_sweeping_attack(Vector2(38, 30), [Vector2(10 * facing, -32), Vector2(48 * facing, -28), Vector2(80 * facing, -22)], 6, 205, Vector2(facing, -0.06), BRAVE_IMPACT_COLOR, 0.085)
	# On hit the spinning kick can start at once and lands inside the hitstun.
	last_attack.set_meta("chain_cancel", 0.0)
	_play_star_bloom(Vector2(78 * facing, -22), 27.0, BRAVE_IMPACT_COLOR, 0.11)

func _brave_spin_kick() -> void:
	velocity.x += facing * 145.0
	_spawn_sweeping_attack(Vector2(48, 38), [Vector2(-18 * facing, -44), Vector2(34 * facing, -50), Vector2(88 * facing, -30)], 10, 455, Vector2(facing, -0.16), Color(1.0, 0.5, 0.82, 0.72), 0.12)
	_play_star_bloom(Vector2(88 * facing, -30), 35.0, BRAVE_IMPACT_COLOR, 0.14)

func _brave_uppercut(airborne: bool) -> void:
	velocity.y = minf(velocity.y, (-430.0 if not airborne else -330.0) * GAME_SCALE.JUMP_SPEED)
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
	velocity.y = maxf(velocity.y, 610.0 * GAME_SCALE.JUMP_SPEED)
	_spawn_sweeping_attack(Vector2(42, 38), [Vector2(8 * facing, -22), Vector2(26 * facing, 24), Vector2(48 * facing, 78)], 10, 475, Vector2(0.16 * facing, 1), BRAVE_IMPACT_COLOR, 0.13)
	_play_star_bloom(Vector2(46 * facing, 74), 32.0, BRAVE_IMPACT_COLOR, 0.13)

func _brave_comet_drive_start() -> void:
	var direction := _get_attack_direction()
	_start_attack(0.07, 0.16, Callable(self, "_brave_comet_drive").bind(direction), Vector2i(1, 1), &"comet_drive")

func _brave_comet_drive(direction: Vector2) -> void:
	if absf(direction.x) > 0.2:
		facing = signi(int(direction.x))
	velocity = direction * 120.0
	skill_dash_velocity = direction * 650.0 * GAME_SCALE.WORLD
	skill_dash_timer = 0.14
	body.rotation = direction.angle()
	_spawn_sweeping_attack(Vector2(46, 34), [
		Vector2(0, -34) + direction * 10.0,
		Vector2(0, -34) + direction * 58.0,
		Vector2(0, -34) + direction * 112.0
	], 11, 425, direction, BRAVE_IMPACT_COLOR, 0.12)
	last_attack.set_meta("chain_cancel", 0.0)
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
	_play_move_sprite_pose(&"transform", -1, -1, 0.52)
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
	VFX.spawn(self, "luna_ult_transform", Vector2(0, -42), Vector2.ONE * 1.4 * GAME_SCALE.COMBAT, false, 5, Color.WHITE, true)
	# The transformation itself bursts: everyone close is thrown up (added 2026-10-08).
	attack_art_enabled = false
	_spawn_sweeping_launch_attack(Vector2(TRANSFORM_BURST_RADIUS * 2.0, TRANSFORM_BURST_RADIUS * 1.6), [Vector2(0, -40), Vector2(0, -42)], TRANSFORM_BURST_DAMAGE, 460, Vector2(0, -1), Color(1.0, 0.7, 0.9, 0.4), 0.16, Vector2(0, -560), 0.3)
	attack_art_enabled = true

func _heart_laser_start() -> void:
	heart_laser_duration = maxf(transformation_timer, 0.05)
	heart_laser_cast_id += 1
	var cast_id := heart_laser_cast_id
	transformation_finishing = true
	transformation_timer = 0.0
	_reset_brave_combo()
	attack_lock_timer = 0.16 + heart_laser_duration
	_play_move_sprite_pose(&"heart_laser", -1, -1, 0.16 + heart_laser_duration)
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
	var aura_art := VFX.spawn(transformation_aura, "luna_brave_aura", Vector2.ZERO, Vector2.ONE, true, 0, Color.WHITE, true)
	if aura_art != null:
		return
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
	# Blooms mark attacks: placed and sized like them (GameScale.COMBAT).
	offset = GAME_SCALE.attack_point(offset)
	radius *= GAME_SCALE.COMBAT
	# Generated bloom art occupies about 204 px inside its 256 px frame. Match the old
	# polygon's 1.25x terminal radius; keep the polygon below as the missing/F2 fallback.
	var art_scale := radius * 2.5 / 204.0
	var art := VFX.spawn(get_parent(), "luna_star_bloom", global_position + offset, Vector2.ONE * art_scale, false, 6, Color(1, 1, 1, color.a))
	if art != null:
		art.speed_scale = 0.16 / maxf(duration, 0.01)
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
	radius *= GAME_SCALE.COMBAT
	# The painted ring's visible diameter is about 204 px; match the old 1.08x end scale.
	if VFX.spawn(get_parent(), "luna_moon_ring", global_position + Vector2(0, -34), Vector2.ONE * (radius * 2.16 / 204.0), false, 5) != null:
		return
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
