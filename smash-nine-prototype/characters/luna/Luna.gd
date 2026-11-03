extends "res://characters/common/PlayerBase.gd"

const VFX := preload("res://scripts/Vfx.gd")
const HEART_LASER_SCRIPT := preload("res://characters/luna/LunaHeartLaser.gd")
const STAR_SCRIPT := preload("res://characters/luna/LunaStar.gd")
const BARRIER_SCRIPT := preload("res://characters/luna/LunaBarrier.gd")
const CYCLONE_SCRIPT := preload("res://characters/luna/LunaCyclone.gd")

const BRAVE_SHEET_ART := "res://assets/art/luna/luna_brave_sheet.png"
## Redrawn 2026-10-14 (D33-D37, Brave design D36): every motion is 6 frames with its old length
## (fps x 6 / old frames), the idle at 6.3 fps (D37). The base `attack` row is only a fallback
## (side J plays star_side, Brave J plays brave_combo). The walk is 8 frames at 13.3 fps and fills
## two sheet rows (user 2026-10-15). Both forms share this base table.
const SHEET_ROWS := [["idle", 6, 6.3, true], ["walk", 8, 13.3, true], ["jump", 1, 1.0, false], ["fall", 1, 1.0, false], ["attack", 6, 21.0, false], ["shield", 6, 12.0, false], ["hurt", 1, 1.0, false]]
## 192-px cells (D34). `transform` is the special 12-frame transformation and fills two sheet rows.
const MOVE_SHEET_ROWS := [
	["star_up", 6, 21.0, false],
	["star_down", 6, 21.0, false],
	["star_comet", 6, 21.0, false],
	["moon_ring", 6, 16.8, false],
	["transform", 12, 12.0, false],
	["tumble", 6, 21.0, true],
	["star_side", 6, 21.0, false],
]
const BRAVE_MOVE_SHEET_ROWS := [
	["brave_combo", 6, 16.0, false],
	["brave_upper", 6, 24.0, false],
	["brave_low", 6, 24.0, false],
	["brave_air_side", 6, 24.0, false],
	["brave_dive", 6, 24.0, false],
	["comet_drive", 6, 24.0, false],
	["luna_breaker", 6, 16.0, false],
	["heart_laser", 6, 12.0, false],
	["tumble", 6, 21.0, true],
]
## The special transformation (user 2026-10-14): the 12-frame row at its own speed. She becomes
## Brave Luna, with the burst, as she lands on frame 9; the ultimate's super armour covers the motion.
## Drawn for 12 fps (1 s, burst at 0.67 s); the user adopted 7.8 fps in the motion viewer
## (2026-10-15, MotionSpeeds), so the lock, the armour and the burst follow the row: 1.54 s, 1.03 s.
const TRANSFORM_FRAMES := 12
const TRANSFORM_BURST_FRAME := 8
const TRANSFORMATION_DURATION := 6.0
const TRANSFORM_BURST_RADIUS := 120.0
const TRANSFORM_BURST_DAMAGE := 14.0
const TRANSFORMATION_MOVEMENT_MULTIPLIER := 1.16
const BRAVE_COMBO_RESET_TIME := 0.42
const STAR_BLOOM_COLOR := Color(0.44, 0.92, 1.0, 0.66)
const BRAVE_IMPACT_COLOR := Color(1.0, 0.84, 0.28, 0.76)

## The new kit (user 2026-11-03, D45; the user's concept is quoted in routine/2026-11-03-night).
## Normal J "별빛 연사" (Star Volley): one star per press, three small ones and then a big one that
## bursts where it hits or where its flight ends. Every star that lands marks the target for
## STAR_MARK_TIME (passive "별의 마법": a marked fighter takes 10% more damage, PlayerBase.STAR_MARK_*).
const STAR_VOLLEY_RESET_TIME := 0.6
const STAR_SHOT_SIZE := Vector2(22, 22)
const STAR_SHOT_DAMAGE := 3.0
const STAR_SHOT_KNOCKBACK := 120.0
const STAR_SHOT_SPEED := 700.0
const STAR_SHOT_LIFETIME := 0.3
const STAR_BIG_SIZE := Vector2(40, 40)
const STAR_BIG_DAMAGE := 2.0
const STAR_BIG_SPEED := 620.0
const STAR_BIG_LIFETIME := 0.36
const STAR_BURST_SIZE := Vector2(120, 120)
const STAR_BURST_DAMAGE := 8.0
const STAR_BURST_KNOCKBACK := 420.0
const STAR_MARK_TIME := 10.0
## K "반짝 도약" (Twinkle Warp): she vanishes and reappears WARP_DISTANCE away in the held direction
## (ahead when none; solid ground stops her), and a star burst around her hits whoever is close.
## Once per airtime.
const WARP_STARTUP := 0.14
const WARP_RECOVERY := 0.24
const WARP_DISTANCE := 170.0
## One half of the burst (two halves push outward): together 130x110 around her body centre.
const WARP_BURST_SIZE := Vector2(65, 110)
const WARP_BURST_DAMAGE := 9.0
const WARP_BURST_KNOCKBACK := 360.0
## L "별의 방어막" (Star Barrier): a circle of BARRIER_RADIUS around her for BARRIER_TIME that stops
## other fighters' projectiles and takes the hits meant for her until it has taken BARRIER_HP;
## whoever touches it takes a small hit and is pushed out. BARRIER_COOLDOWN from the moment it rises.
const BARRIER_RADIUS := 70.0
const BARRIER_TIME := 5.0
const BARRIER_HP := 30.0
const BARRIER_CONTACT_DAMAGE := 3.0
const BARRIER_CONTACT_KNOCKBACK := 280.0
const BARRIER_COOLDOWN := 8.0
## I: the transformation also bursts every star mark this Luna placed in her realm, at any
## distance: MARK_BURST_DAMAGE and a MARK_BURST_STUN stun.
const MARK_BURST_DAMAGE := 10.0
const MARK_BURST_STUN := 3.0
## Brave J "브레이브 러시" (Brave Rush): each hit starts with a short dash ahead; a foe met on the way
## (BRAVE_RUSH_REACH ahead, body to body) stops her in front of it and she strikes at once: jab,
## body kick, then a launching spin kick. Never sooner than BRAVE_RUSH_MIN_TIME after the press.
const BRAVE_RUSH_SPEED := 620.0
const BRAVE_RUSH_TIME := 0.14
const BRAVE_RUSH_MIN_TIME := 0.05
const BRAVE_RUSH_REACH := 72.0
const BRAVE_RUSH_GAP := 50.0
const BRAVE_RUSH_RECOVERY := [0.1, 0.11, 0.18]
## Brave passive "별의 정화" (Star Purification): after a Brave skill (K or L) damages a foe, the
## next J within PURIFY_WINDOW takes her in front of that foe (up to PURIFY_RANGE away) and strikes.
const PURIFY_WINDOW := 3.0
const PURIFY_RANGE := 560.0
## Brave K "혜성 붙잡기" (Comet Catch): a dash in the held direction that grabs the first foe it
## meets (GRAB_REACH, body centre to body centre), holds it GRAB_HOLD_TIME and throws it: up when up
## is held, else left or right as held, else ahead.
const GRAB_STARTUP := 0.08
const GRAB_DASH_SPEED := 760.0
const GRAB_DASH_TIME := 0.18
const GRAB_REACH := 64.0
const GRAB_HOLD_TIME := 0.3
const GRAB_HOLD_OFFSET := 46.0
const GRAB_WHIFF_RECOVERY := 0.28
const THROW_DAMAGE := 12.0
const THROW_SIDE := Vector2(820, -420)
const THROW_UP := Vector2(60, -1050)
const THROW_HITSTUN := 0.5
const THROW_RECOVERY := 0.3
## Brave L "별의 회오리" (Star Cyclone): she spins in a whirlwind of CYCLONE_RADIUS for up to
## CYCLONE_TIME (it stops other fighters' projectiles; she can walk); L again or the end of the spin
## fires it ahead. Whoever it reaches is stunned CYCLONE_STUN, then thrown up.
const CYCLONE_STARTUP := 0.1
const CYCLONE_TIME := 3.0
const CYCLONE_RADIUS := 80.0
const CYCLONE_SHOT_SIZE := Vector2(70, 100)
const CYCLONE_SHOT_SPEED := 520.0
const CYCLONE_SHOT_LIFETIME := 0.6
const CYCLONE_DAMAGE := 6.0
const CYCLONE_STUN := 2.0
const CYCLONE_LAUNCH := Vector2(0, -900)
const CYCLONE_LAUNCH_DAMAGE := 6.0
const CYCLONE_FIRE_RECOVERY := 0.22
## Brave I "별의 광선" (Star Beam, on the heart laser's script and art): a BEAM_TIME beam ahead;
## whoever it holds stays in hitstun and is pushed a little each tick, then a final blast throws
## them, and she is normal Luna again.
const BEAM_TIME := 3.0
const BEAM_TICK := 0.15
const BEAM_TICK_DAMAGE := 2.2
const BEAM_TICK_KNOCKBACK := 70.0
const BEAM_HOLD_HITSTUN := 0.2
const BEAM_FINAL_DAMAGE := 14.0
const BEAM_FINAL_KNOCKBACK := 760.0

var transformed := false
var has_brave_sheet := false
var transformation_timer := 0.0
var transformation_finishing := false
var transformation_aura: Node2D
var transformation_visual_time := 0.0
var brave_combo_step := 0
var brave_combo_timer := 0.0
## The star beam (it runs on the heart laser's script).
var heart_laser: Node
var heart_laser_cast_id := 0
var heart_laser_duration := 0.0
var star_volley_step := 0
var star_volley_timer := 0.0
var warp_air_available := true
var barrier: Node2D
var barrier_cooldown_timer := 0.0
## The Brave Rush hit under way (0-2) and the seconds since its press, -1 when none.
var brave_rush_step := -1
var brave_rush_time := 0.0
var purify_target: Node2D
var purify_timer := 0.0
var grab_dash_timer := 0.0
var grabbed: Node2D
var grab_hold_timer := 0.0
var cyclone: Node2D
var cyclone_timer := 0.0

## Original sheet only (third-party prototype art removed 2026-10-07, user).
func configure_character_sprite() -> void:
	if _configure_original_sheet("luna"):
		_add_brave_sheet()

func get_move_sheet_rows() -> Array:
	return MOVE_SHEET_ROWS

func get_sheet_rows() -> Array:
	return SHEET_ROWS

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

func perform_basic_attack(attack_type: String, _direction: Vector2) -> void:
	if transformed:
		_perform_brave_basic(attack_type)
	else:
		_perform_star_basic(attack_type)

func perform_skill_one() -> void:
	if transformed:
		_brave_grab_start()
	else:
		_warp_start()

func can_use_skill_one() -> bool:
	return super() and (transformed or is_on_floor() or warp_air_available)

func perform_skill_two() -> void:
	if transformed:
		_cyclone_start()
	else:
		_barrier_start()

## L again while the cyclone spins fires it.
func try_skill_two_followup() -> bool:
	if transformed and cyclone_timer > 0.0:
		_fire_cyclone()
		return true
	return false

func skill_cooldown(slot: String) -> Vector2:
	if slot == "l" and not transformed:
		return Vector2(barrier_cooldown_timer, BARRIER_COOLDOWN)
	return super(slot)

func perform_ultimate() -> void:
	_transformation_start()

## While transformed, the ultimate button fires the star beam instead of starting a new cooldown.
func try_ultimate_followup() -> bool:
	if not transformed:
		return false
	if not transformation_finishing and _can_start_attack():
		_star_beam_start()
		ultimate_followup_started = true
	return true

func character_physics_process(delta: float) -> void:
	brave_combo_timer = maxf(brave_combo_timer - delta, 0.0)
	if brave_combo_timer <= 0.0:
		brave_combo_step = 0
	star_volley_timer = maxf(star_volley_timer - delta, 0.0)
	if star_volley_timer <= 0.0:
		star_volley_step = 0
	barrier_cooldown_timer = maxf(barrier_cooldown_timer - delta, 0.0)
	purify_timer = maxf(purify_timer - delta, 0.0)
	if is_on_floor():
		warp_air_available = true
	_update_brave_rush(delta)
	_update_grab(delta)
	_update_cyclone(delta)
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
	star_volley_step = 0
	brave_rush_step = -1
	_release_grab()
	_stop_cyclone()

## The star barrier takes the whole hit in her place (its damage is PlayerBase.last_incoming_damage).
func character_hit_absorption() -> float:
	return 0.0 if _barrier_up() else -1.0

func character_on_hit_absorbed(_attacker: Node, _knockback: float, _direction: Vector2) -> void:
	if _barrier_up():
		barrier.take_damage(last_incoming_damage)

func character_on_attack_hit_body(body: Node, attack: Node) -> void:
	if attack.has_meta("luna_mark"):
		_mark(body)

func character_on_respawn() -> void:
	_end_transformation(true)
	_reset_kit()

func character_cleanup() -> void:
	_end_transformation(true)
	_reset_kit()

func _reset_kit() -> void:
	star_volley_step = 0
	star_volley_timer = 0.0
	warp_air_available = true
	barrier_cooldown_timer = 0.0
	_clear_barrier()

func attack_effect_name() -> String:
	return "luna_brave_slash" if transformed else "luna_slash"

# --- Normal J: star volley ---

func _perform_star_basic(attack_type: String) -> void:
	if not is_on_floor():
		velocity.y *= 0.72
	var big := _consume_star_volley_step() == 3
	var aim := Vector2(facing, 0.0)
	var low := false
	var row := &"star_side"
	match attack_type:
		"up", "air_up":
			aim = Vector2(0.5 * facing, -0.866)
			row = &"star_up"
		"air_down":
			aim = Vector2(0.5 * facing, 0.866)
			row = &"star_down"
		"down":
			low = true
			row = &"star_down"
	_start_attack(0.14 if big else 0.1, 0.3 if big else 0.2, Callable(self, "_fire_star").bind(aim, big, low), Vector2i(-1, -1), row)

## 0, 1, 2: a small star; 3: the big one. A pause longer than STAR_VOLLEY_RESET_TIME starts over.
func _consume_star_volley_step() -> int:
	if star_volley_timer <= 0.0:
		star_volley_step = 0
	var step := star_volley_step
	star_volley_step = (step + 1) % 4
	star_volley_timer = STAR_VOLLEY_RESET_TIME
	return step

func _fire_star(aim: Vector2, big: bool, low: bool) -> void:
	var star := Area2D.new()
	star.set_script(STAR_SCRIPT)
	star.collision_layer = 0
	star.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var visual := ColorRect.new()
	visual.name = "Visual"
	star.add_child(shape)
	star.add_child(visual)
	get_parent().add_child(star)
	star.global_position = global_position + Vector2(0, -14 if low else -38) + aim * 30.0 * GAME_SCALE.COMBAT
	star.art_scale_multiplier = GAME_SCALE.COMBAT
	var size := STAR_BIG_SIZE if big else STAR_SHOT_SIZE
	var color := Color(1.0, 0.86, 0.42, 0.9) if big else Color(1.0, 0.6, 0.9, 0.85)
	star.configure(self, size * GAME_SCALE.COMBAT, STAR_BIG_DAMAGE if big else STAR_SHOT_DAMAGE, 90.0 if big else STAR_SHOT_KNOCKBACK, aim, color, (STAR_BIG_SPEED if big else STAR_SHOT_SPEED) * GAME_SCALE.COMBAT, STAR_BIG_LIFETIME if big else STAR_SHOT_LIFETIME)
	star.big = big
	# The J stars (CODEX-VFX-04); the coloured rect without the art.
	star.set_effect_art("luna_star_big" if big else "luna_star_shot")
	_play_star_bloom(Vector2(20 * facing, -38) + aim * 6.0, 18.0 if big else 12.0, Color(1.0, 0.8, 0.95, 0.8), 0.1)

## A star that landed (LunaStar).
func on_star_hit(body: Node) -> void:
	_mark(body)

## The big star's burst at `at` (LunaStar): it marks what it hits too.
func star_burst_at(at: Vector2, direction: Vector2) -> void:
	if is_defeated or not is_instance_valid(get_parent()):
		return
	attack_art_enabled = false
	_spawn_attack(STAR_BURST_SIZE, _offset_to(at), STAR_BURST_DAMAGE, STAR_BURST_KNOCKBACK, Vector2(direction.x, direction.y - 0.3), STAR_BLOOM_COLOR, 0.12)
	attack_art_enabled = true
	last_attack.set_meta("luna_mark", true)
	if VFX.spawn(get_parent(), "luna_comet_burst", at, Vector2.ONE * 1.25, false, 6) == null:
		_play_star_bloom(_offset_to(at), STAR_BURST_SIZE.x * 0.42, STAR_BLOOM_COLOR, 0.14)

func _mark(body: Node) -> void:
	if body != self and body.has_method("apply_star_mark"):
		body.apply_star_mark(self, STAR_MARK_TIME)

## The attack offset (before GameScale.COMBAT) that puts a hit at the world point `at`.
func _offset_to(at: Vector2) -> Vector2:
	return GAME_SCALE.BODY_CENTRE + (at - global_position - GAME_SCALE.BODY_CENTRE) / GAME_SCALE.COMBAT

# --- Normal K: twinkle warp ---

func _warp_start() -> void:
	if not is_on_floor():
		if not warp_air_available:
			return
		warp_air_available = false
	_start_attack(WARP_STARTUP, WARP_RECOVERY, Callable(self, "_warp"), Vector2i(-1, -1), &"star_comet")
	_freeze_movement(WARP_STARTUP)
	velocity = Vector2(velocity.x * 0.3, minf(velocity.y, 0.0) * 0.3)

func _warp() -> void:
	movement_freeze_timer = 0.0
	var direction := _get_late_skill_direction()
	if absf(direction.x) > 0.2:
		facing = 1 if direction.x > 0.0 else -1
	_play_star_bloom(Vector2(0, -34), 30.0, Color(1.0, 0.8, 0.95, 0.85), 0.18)
	var start := global_position
	var travel := direction * WARP_DISTANCE * GAME_SCALE.WORLD
	var collision := move_and_collide(travel, true)
	if collision != null:
		travel = collision.get_travel()
	global_position = start + travel
	velocity = Vector2(direction.x * 120.0, minf(direction.y, 0.0) * 200.0)
	attack_art_enabled = false
	_spawn_attack(WARP_BURST_SIZE, Vector2(WARP_BURST_SIZE.x * 0.5, -34), WARP_BURST_DAMAGE, WARP_BURST_KNOCKBACK, Vector2(1, -0.35), STAR_BLOOM_COLOR, 0.12)
	_spawn_attack(WARP_BURST_SIZE, Vector2(-WARP_BURST_SIZE.x * 0.5, -34), WARP_BURST_DAMAGE, WARP_BURST_KNOCKBACK, Vector2(-1, -0.35), STAR_BLOOM_COLOR, 0.12)
	attack_art_enabled = true
	# The warp burst (CODEX-VFX-04 b); a bloom without the art.
	if VFX.spawn(get_parent(), "luna_warp", global_position + GAME_SCALE.attack_point(Vector2(0, -34)), Vector2.ONE, false, 5) == null:
		_play_star_bloom(Vector2(0, -34), 62.0, Color(0.6, 0.95, 1.0, 0.85), 0.2)

# --- Normal L: star barrier ---

func _barrier_start() -> void:
	if barrier_cooldown_timer > 0.0:
		return
	_start_attack(0.12, 0.2, Callable(self, "_raise_barrier"), Vector2i(-1, -1), &"moon_ring")

func _raise_barrier() -> void:
	_clear_barrier()
	barrier_cooldown_timer = BARRIER_COOLDOWN
	barrier = Node2D.new()
	barrier.set_script(BARRIER_SCRIPT)
	barrier.name = "StarBarrier"
	barrier.position = GAME_SCALE.attack_point(Vector2(0, -34))
	barrier.z_index = 2
	add_child(barrier)
	barrier.configure(self, "barrier", BARRIER_RADIUS * GAME_SCALE.COMBAT, BARRIER_TIME, BARRIER_HP, BARRIER_CONTACT_DAMAGE, BARRIER_CONTACT_KNOCKBACK)
	_play_moon_ring_flash(BARRIER_RADIUS)

func _barrier_up() -> bool:
	return is_instance_valid(barrier) and barrier.is_active()

func _clear_barrier() -> void:
	if is_instance_valid(barrier):
		barrier.queue_free()
	barrier = null

# --- I: transformation ---

## Seconds that `frames` drawings of the transformation row take at the speed it plays (12 fps,
## as drawn, when there is no such row).
func transform_time(frames: int) -> float:
	var fps := 12.0
	if _uses_character_sprite():
		var row := _get_sprite_animation_name(&"transform")
		if character_sprite.sprite_frames.has_animation(row):
			fps = character_sprite.sprite_frames.get_animation_speed(row)
	return float(frames) / maxf(fps, 1.0)

func _transformation_start() -> void:
	_reset_brave_combo()
	var motion_time := transform_time(TRANSFORM_FRAMES)
	var burst_time := transform_time(TRANSFORM_BURST_FRAME)
	attack_lock_timer = motion_time
	# The 12 frames at the row's own speed; the row stays on after the form switches (Luna-only row).
	_play_sprite_action(&"transform", motion_time)
	current_attack_started_airborne = not is_on_floor()
	_freeze_movement(burst_time)
	velocity = Vector2.ZERO
	ultimate_armor_timer = maxf(ultimate_armor_timer, motion_time)
	_play_transformation_charge()
	if not await _wait_action(burst_time):
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
	VFX.spawn(self, "luna_ult_transform", Vector2(0, -42), Vector2.ONE * 1.4 * GAME_SCALE.COMBAT, false, 5, Color(1, 1, 1, VFX.ULTIMATE_FLASH_ALPHA), true)
	# The transformation itself bursts: everyone close is thrown up (added 2026-10-08).
	attack_art_enabled = false
	_spawn_sweeping_launch_attack(Vector2(TRANSFORM_BURST_RADIUS * 2.0, TRANSFORM_BURST_RADIUS * 1.6), [Vector2(0, -40), Vector2(0, -42)], TRANSFORM_BURST_DAMAGE, 460, Vector2(0, -1), Color(1.0, 0.7, 0.9, 0.4), 0.16, Vector2(0, -560), 0.3)
	attack_art_enabled = true
	_burst_star_marks()

## Every fighter carrying this Luna's star mark in her realm: the mark bursts with damage and a stun.
func _burst_star_marks() -> void:
	for target in get_tree().get_nodes_in_group("players"):
		if target == self or target.star_mark_source != self or target.star_mark_timer <= 0.0:
			continue
		if target.is_defeated or target.realm_index != realm_index:
			continue
		target.clear_star_mark()
		var side := signf(target.global_position.x - global_position.x)
		VFX.spawn(get_parent(), "luna_comet_burst", target.global_position + GAME_SCALE.BODY_CENTRE, Vector2.ONE, false, 6)
		target.apply_stun_hit(self, MARK_BURST_DAMAGE, 140.0, Vector2(side, -0.2), MARK_BURST_STUN)

# --- Brave J: brave rush (and the passive star purification) ---

func _perform_brave_basic(attack_type: String) -> void:
	if attack_type in ["neutral", "side", "air_side"] and _purify_ready():
		_purify_warp()
		_brave_rush_start(_consume_brave_combo_step())
		return
	match attack_type:
		"up", "air_up":
			_reset_brave_combo()
			_start_attack(0.098, 0.14, Callable(self, "_brave_uppercut").bind(attack_type == "air_up"), Vector2i(-1, -1), &"brave_upper")
		"down":
			_reset_brave_combo()
			_start_attack(0.111, 0.14, Callable(self, "_brave_low_sweep"), Vector2i(-1, -1), &"brave_low")
		"air_down":
			_reset_brave_combo()
			_start_attack(0.111, 0.18, Callable(self, "_brave_dive_kick"), Vector2i(-1, -1), &"brave_dive")
		"air_side":
			_reset_brave_combo()
			_start_attack(0.104, 0.12, Callable(self, "_brave_flying_kick"), Vector2i(-1, -1), &"brave_air_side")
		_:
			_brave_rush_start(_consume_brave_combo_step())

## The Brave attack row reads jab, body kick, spinning kick: each hit plays its own two frames.
func _brave_rush_start(step: int) -> void:
	var recovery: float = BRAVE_RUSH_RECOVERY[step]
	attack_serial += 1
	attack_elapsed = 0.0
	attack_startup = BRAVE_RUSH_TIME
	attack_lock_timer = BRAVE_RUSH_TIME + recovery
	current_attack_started_airborne = not is_on_floor()
	_play_move_sprite_pose(&"brave_combo", step * 2, step * 2 + 1, BRAVE_RUSH_TIME + recovery, step * 2, step * 2 + 1, BRAVE_RUSH_TIME)
	_play_attack_windup()
	brave_rush_step = step
	brave_rush_time = 0.0
	if _rush_foe_ahead() != null:
		return
	skill_dash_velocity = Vector2(facing * BRAVE_RUSH_SPEED * GAME_SCALE.WORLD, 0.0)
	skill_dash_timer = BRAVE_RUSH_TIME

func _update_brave_rush(delta: float) -> void:
	if brave_rush_step < 0:
		return
	brave_rush_time += delta
	var foe := _rush_foe_ahead()
	if foe != null and skill_dash_timer > 0.0:
		skill_dash_timer = 0.0
		_end_skill_dash()
	if brave_rush_time < BRAVE_RUSH_MIN_TIME:
		return
	if foe != null or brave_rush_time >= BRAVE_RUSH_TIME:
		_brave_rush_strike(foe)

func _brave_rush_strike(foe: Node2D) -> void:
	var step := brave_rush_step
	brave_rush_step = -1
	skill_dash_timer = 0.0
	_end_skill_dash()
	if foe != null:
		_close_in_on(foe)
	attack_lock_timer = BRAVE_RUSH_RECOVERY[step]
	match step:
		0:
			_brave_jab()
		1:
			_brave_body_kick()
		_:
			_brave_spin_kick()

## The nearest foe straight ahead within BRAVE_RUSH_REACH (feet to feet), or null.
func _rush_foe_ahead() -> Node2D:
	var best: Node2D = null
	var best_ahead := INF
	for target in _foes():
		var offset := target.global_position - global_position
		var ahead := offset.x * float(facing)
		if ahead < -8.0 or ahead > BRAVE_RUSH_REACH or absf(offset.y) > 60.0:
			continue
		if ahead < best_ahead:
			best = target
			best_ahead = ahead
	return best

## Steps up to BRAVE_RUSH_GAP in front of the foe (never back, never through solid ground).
func _close_in_on(foe: Node2D) -> void:
	var ahead := (foe.global_position.x - global_position.x) * float(facing)
	if ahead <= BRAVE_RUSH_GAP:
		return
	var travel := Vector2((ahead - BRAVE_RUSH_GAP) * float(facing), 0.0)
	var collision := move_and_collide(travel, true)
	if collision != null:
		travel = collision.get_travel()
	global_position += travel

func _foes() -> Array[Node2D]:
	var found: Array[Node2D] = []
	for group in ["players", "realm_monsters"]:
		for target in get_tree().get_nodes_in_group(group):
			if target == self or not target is Node2D or target.get("is_defeated") == true:
				continue
			var realm = target.get("realm_index")
			if realm != null and int(realm) != realm_index:
				continue
			found.append(target)
	return found

func _remember_purify(body: Node) -> void:
	if transformed and body is Node2D:
		purify_target = body
		purify_timer = PURIFY_WINDOW

func _purify_ready() -> bool:
	if purify_timer <= 0.0 or not is_instance_valid(purify_target) or purify_target.get("is_defeated") == true:
		return false
	return purify_target.global_position.distance_to(global_position) <= PURIFY_RANGE

## In front of the foe her last skill hit, on the side she comes from (solid ground stops her).
func _purify_warp() -> void:
	var target := purify_target
	purify_timer = 0.0
	purify_target = null
	var side := signf(global_position.x - target.global_position.x)
	if side == 0.0:
		side = -float(facing)
	_play_star_bloom(Vector2(0, -34), 28.0, BRAVE_IMPACT_COLOR, 0.14)
	var start := global_position
	var travel := target.global_position + Vector2(side * BRAVE_RUSH_GAP, 0.0) - start
	var collision := move_and_collide(travel, true)
	if collision != null:
		travel = collision.get_travel()
	global_position = start + travel
	facing = -int(side)
	velocity = Vector2.ZERO
	_play_star_bloom(Vector2(0, -34), 36.0, BRAVE_IMPACT_COLOR, 0.16)

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

## The third hit sends the foe flying (D45: "마지막 공격 시 날려버림").
func _brave_spin_kick() -> void:
	velocity.x += facing * 145.0
	_spawn_sweeping_launch_attack(Vector2(48, 38), [Vector2(-18 * facing, -44), Vector2(34 * facing, -50), Vector2(88 * facing, -30)], 10, 520, Vector2(facing, -0.4), Color(1.0, 0.5, 0.82, 0.72), 0.12, Vector2(560 * facing, -480), 0.32)
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

# --- Brave K: comet catch ---

func _brave_grab_start() -> void:
	_reset_brave_combo()
	_start_attack(GRAB_STARTUP, GRAB_DASH_TIME + GRAB_WHIFF_RECOVERY, Callable(self, "_brave_grab_dash"), Vector2i(1, 1), &"comet_drive")

func _brave_grab_dash() -> void:
	var direction := _get_late_skill_direction()
	if absf(direction.x) > 0.2:
		facing = 1 if direction.x > 0.0 else -1
	velocity = direction * 120.0
	skill_dash_velocity = direction * GRAB_DASH_SPEED * GAME_SCALE.WORLD
	skill_dash_timer = GRAB_DASH_TIME
	grab_dash_timer = GRAB_DASH_TIME
	body.rotation = direction.angle() if direction.x >= 0.0 else direction.angle() - PI
	_play_star_bloom(Vector2(0, -34), 22.0, BRAVE_IMPACT_COLOR, 0.12)

func _update_grab(delta: float) -> void:
	if grab_dash_timer > 0.0:
		grab_dash_timer = maxf(grab_dash_timer - delta, 0.0)
		var foe := _grab_foe()
		if foe != null:
			_grab(foe)
		return
	if grab_hold_timer <= 0.0:
		return
	grab_hold_timer = maxf(grab_hold_timer - delta, 0.0)
	if not is_instance_valid(grabbed) or grabbed.get("is_defeated") == true:
		_release_grab()
		return
	_pin_grabbed()
	if grab_hold_timer <= 0.0:
		_throw()

func _grab_foe() -> Node2D:
	var centre := global_position + GAME_SCALE.BODY_CENTRE
	for target in _foes():
		if target.has_method("is_invulnerable") and target.is_invulnerable():
			continue
		if (target.global_position + GAME_SCALE.BODY_CENTRE).distance_to(centre) <= GRAB_REACH:
			return target
	return null

func _grab(foe: Node2D) -> void:
	grab_dash_timer = 0.0
	skill_dash_timer = 0.0
	_end_skill_dash()
	velocity = Vector2.ZERO
	if not foe.has_method("apply_grab_hold"):
		# A monster cannot be held: the dash just strikes it.
		if foe.apply_hit(self, THROW_DAMAGE, 420.0, Vector2(facing, -0.3)) != false:
			_remember_purify(foe)
		attack_lock_timer = GRAB_WHIFF_RECOVERY
		return
	if not foe.apply_grab_hold(self, _hold_point(), GRAB_HOLD_TIME + 0.1):
		return
	grabbed = foe
	grab_hold_timer = GRAB_HOLD_TIME
	attack_lock_timer = GRAB_HOLD_TIME + THROW_RECOVERY
	_freeze_movement(GRAB_HOLD_TIME)
	_play_move_sprite_pose(&"luna_breaker", 0, 1, GRAB_HOLD_TIME, 0, 1)
	_play_star_bloom(Vector2(30 * facing, -34), 26.0, BRAVE_IMPACT_COLOR, 0.12)

func _hold_point() -> Vector2:
	return global_position + Vector2(GRAB_HOLD_OFFSET * facing, 0.0)

func _pin_grabbed() -> void:
	grabbed.movement_freeze_position = _hold_point()
	grabbed.movement_freeze_timer = maxf(grabbed.movement_freeze_timer, 0.05)
	grabbed.hitstun_timer = maxf(grabbed.hitstun_timer, 0.1)

func _throw() -> void:
	var target := grabbed
	grabbed = null
	var launch := _throw_velocity()
	attack_lock_timer = THROW_RECOVERY
	_play_move_sprite_pose(&"luna_breaker", 2, 5, THROW_RECOVERY, 2, 5)
	if not is_instance_valid(target):
		return
	target.movement_freeze_timer = 0.0
	var landed = target.apply_forced_launch_hit(self, THROW_DAMAGE, launch, THROW_HITSTUN, 520.0, launch.normalized())
	if landed != false:
		_remember_purify(target)
		on_attack_landed(target.global_position + GAME_SCALE.BODY_CENTRE, THROW_DAMAGE, 520.0)
	_play_star_bloom(Vector2(40 * facing, -40), 34.0, BRAVE_IMPACT_COLOR, 0.14)

## Up when up is held, else the held side, else ahead.
func _throw_velocity() -> Vector2:
	var held := Vector2.ZERO
	if is_human:
		held = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	if held.y < -0.5:
		return Vector2(THROW_UP.x * facing, THROW_UP.y)
	if absf(held.x) > 0.2:
		facing = 1 if held.x > 0.0 else -1
	return Vector2(THROW_SIDE.x * facing, THROW_SIDE.y)

func _release_grab() -> void:
	grab_dash_timer = 0.0
	grab_hold_timer = 0.0
	if is_instance_valid(grabbed):
		grabbed.movement_freeze_timer = 0.0
	grabbed = null

# --- Brave L: star cyclone ---

func _cyclone_start() -> void:
	_reset_brave_combo()
	_start_attack(CYCLONE_STARTUP, CYCLONE_TIME, Callable(self, "_spin_cyclone"), Vector2i(-1, -1), &"luna_breaker", Vector2i(0, 1))

func _spin_cyclone() -> void:
	cyclone_timer = CYCLONE_TIME
	attack_lock_timer = CYCLONE_TIME
	# The tumble row loops a spin until the cyclone has its own body row (CODEX-SKM-04).
	_play_sprite_action(&"brave_cyclone" if _has_motion_row(&"brave_cyclone") else &"tumble", CYCLONE_TIME)
	_clear_cyclone()
	cyclone = Node2D.new()
	cyclone.set_script(BARRIER_SCRIPT)
	cyclone.name = "StarCyclone"
	cyclone.position = GAME_SCALE.attack_point(Vector2(0, -34))
	cyclone.z_index = 2
	add_child(cyclone)
	cyclone.configure(self, "cyclone", CYCLONE_RADIUS * GAME_SCALE.COMBAT, CYCLONE_TIME + 0.2)

func _update_cyclone(delta: float) -> void:
	if cyclone_timer <= 0.0:
		return
	cyclone_timer = maxf(cyclone_timer - delta, 0.0)
	attack_lock_timer = maxf(attack_lock_timer, 0.05)
	if cyclone_timer <= 0.0:
		_fire_cyclone()

func _fire_cyclone() -> void:
	cyclone_timer = 0.0
	_clear_cyclone()
	attack_lock_timer = CYCLONE_FIRE_RECOVERY
	_play_move_sprite_pose(&"luna_breaker", 3, 5, CYCLONE_FIRE_RECOVERY, 3, 5)
	var horizontal := _get_late_horizontal_direction()
	if horizontal != 0:
		facing = horizontal
	var shot := Area2D.new()
	shot.set_script(CYCLONE_SCRIPT)
	shot.collision_layer = 0
	shot.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var visual := ColorRect.new()
	visual.name = "Visual"
	shot.add_child(shape)
	shot.add_child(visual)
	get_parent().add_child(shot)
	shot.global_position = global_position + Vector2(facing * 40.0 * GAME_SCALE.COMBAT, -48)
	shot.art_scale_multiplier = GAME_SCALE.COMBAT
	shot.configure(self, CYCLONE_SHOT_SIZE * GAME_SCALE.COMBAT, CYCLONE_DAMAGE, 0.0, Vector2(facing, 0.0), Color(1.0, 0.7, 0.9, 0.5), CYCLONE_SHOT_SPEED * GAME_SCALE.COMBAT, CYCLONE_SHOT_LIFETIME)
	shot.dress(CYCLONE_SHOT_SIZE.y * GAME_SCALE.COMBAT)

## A body the fired cyclone reached (LunaCyclone): stunned, then thrown up when the stun ends.
func on_cyclone_hit(body: Node, direction: Vector2) -> void:
	if not body.has_method("apply_stun_hit"):
		return
	var landed = body.apply_stun_hit(self, CYCLONE_DAMAGE, 0.0, direction, CYCLONE_STUN)
	if landed == false:
		return
	_remember_purify(body)
	on_attack_landed((body as Node2D).global_position + GAME_SCALE.BODY_CENTRE, CYCLONE_DAMAGE, 0.0)
	await get_tree().create_timer(CYCLONE_STUN, true, true).timeout
	if is_instance_valid(body) and body.get("is_defeated") != true and body.has_method("apply_forced_launch_hit"):
		body.apply_forced_launch_hit(self, CYCLONE_LAUNCH_DAMAGE, CYCLONE_LAUNCH, 0.4, 600.0, Vector2.UP)

func _stop_cyclone() -> void:
	if cyclone_timer <= 0.0 and not is_instance_valid(cyclone):
		return
	cyclone_timer = 0.0
	_clear_cyclone()

func _clear_cyclone() -> void:
	if is_instance_valid(cyclone):
		cyclone.queue_free()
	cyclone = null

# --- Brave I: star beam ---

func _star_beam_start() -> void:
	heart_laser_duration = BEAM_TIME
	heart_laser_cast_id += 1
	var cast_id := heart_laser_cast_id
	transformation_finishing = true
	transformation_timer = 0.0
	_reset_brave_combo()
	attack_lock_timer = 0.16 + BEAM_TIME
	_play_move_sprite_pose(&"heart_laser", -1, -1, 0.16 + BEAM_TIME)
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
	movement_freeze_timer = BEAM_TIME
	_spawn_star_beam(Vector2(facing, 0.0))
	_play_star_bloom(Vector2(34 * facing, -38), 74.0, Color(1.0, 0.82, 0.24, 0.94), 0.22)
	await get_tree().create_timer(BEAM_TIME, true, true).timeout
	if cast_id != heart_laser_cast_id:
		return
	_end_transformation(true)

func _spawn_star_beam(direction: Vector2) -> void:
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
	laser.configure(self, direction, BEAM_TIME)
	laser.hit_interval = BEAM_TICK
	laser.damage_per_tick = BEAM_TICK_DAMAGE
	laser.knockback_per_tick = BEAM_TICK_KNOCKBACK
	laser.hold_hitstun = BEAM_HOLD_HITSTUN
	laser.final_damage = BEAM_FINAL_DAMAGE
	laser.final_knockback = BEAM_FINAL_KNOCKBACK
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
	brave_rush_step = -1
	purify_timer = 0.0
	purify_target = null
	_release_grab()
	_stop_cyclone()
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
	# Behind the fighters (z 0; sprites are at 1): the bloom keeps its size, the hit area's, but
	# no longer merges with the trail into one flash over the target (CODEX-QA-19 B4).
	var art := VFX.spawn(get_parent(), "luna_star_bloom", global_position + offset, Vector2.ONE * art_scale, false, 0, Color(1, 1, 1, color.a))
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
