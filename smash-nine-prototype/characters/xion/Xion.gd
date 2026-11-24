extends "res://characters/common/PlayerBase.gd"
## Xion, gun-kata gunslinger (2026-11-18, the user's own kit; lead's review with the user's
## corrections, reports/xion-concept-2026-11-18/user-kit-review.md, "이대로 넣기"). Play style:
## mid-range harassment and assassination. Passive 더블 샷건: her shots push foes away, and every
## hit of hers deals up to 2x the closer the foe is (measured from the muzzle). J fires twin
## shotguns, two shots a second, ten rounds; empty means a 3 s reload, and 6 s without a shot fills
## the magazine. K rolls (invulnerable at first) and loads two rounds. L fires every round down at
## once and she rises; the damage follows the rounds. U leaves a doppelganger (XionDouble) that
## hunts the foe she hit last and pins the first foe it touches for 3 s; U again dives to it. I
## "이퀄리브리엄": shots all round from her and the doppelganger, a slow walk, full magazine before
## and after. Stand-in art: Nova's female body recoloured (assets/art/xion/README.md).

const VFX := preload("res://scripts/Vfx.gd")
const DOUBLE_SCRIPT := preload("res://characters/xion/XionDouble.gd")
const BULLET_SCRIPT := preload("res://characters/xion/XionBullet.gd")

# --- Passive: 더블 샷건 ---
## 2x at this distance or closer (px, muzzle or body centre to the foe's body centre) ...
const CLOSE_RANGE := 60.0
## ... falling evenly to 1x at the end of J's reach.
const FAR_RANGE := 250.0
const CLOSE_SCALE := 2.0
## A hit at this scale or more shows the point-blank burst.
const POINT_BLANK_SHOWN := 1.6

# --- J: twin shotguns ---
const MAGAZINE := 10
## Two shots a second at most.
const SHOT_GAP := 0.5
const SHOT_STARTUP := 0.06
const SHOT_RECOVERY := 0.18
const SHOT_DAMAGE := 6.0
const SHOT_KNOCKBACK := 220.0
## The blast: a box swept from the muzzle to the reach (before GameScale.COMBAT): 250 px from her
## centre on screen, past Frey's sword (about 180) and short of Luna's stars (about 315).
const SHOT_SIZE := Vector2(60, 46)
const SHOT_NEAR := 30.0
const SHOT_FAR := 137.0
const SHOT_SWEEP_TIME := 0.06
## A press this close to the next shot waits for it.
const SHOT_BUFFER := 0.15
const RELOAD_TIME := 3.0
const IDLE_RELOAD := 6.0
const SHOT_COLOR := Color(1.0, 0.5, 0.3, 0.45)
const PELLET_COLOR := Color(1.0, 0.86, 0.55, 0.95)
const CRIMSON := Color(0.92, 0.2, 0.3)

# --- K: reload roll ---
const ROLL_DISTANCE := 180.0
const ROLL_TIME := 0.35
const ROLL_INVULNERABLE := 0.2
const ROLL_COOLDOWN := 1.5
const ROLL_LOAD := 2

# --- L: recoil jump ---
const RECOIL_STARTUP := 0.05
const RECOIL_RECOVERY := 0.15
const RECOIL_DAMAGE_PER_ROUND := 2.0
const RECOIL_KNOCKBACK := 300.0
## Under her feet: 140 x 84 px on screen from her knees down.
const RECOIL_SIZE := Vector2(93, 56)
const RECOIL_RISE := 1.0

# --- U: doppelganger ---
const DOUBLE_LIFETIME := 30.0
const DOUBLE_COOLDOWN := 10.0
## Half the fighters' runs (366-432 px/s), whoever it hunts.
const DOUBLE_SPEED := 200.0
const DOUBLE_HIT_SLOW := 2.0
const PIN_TIME := 3.0
const DIVE_RANGE := 500.0
const DIVE_TIME := 0.2
const CAST_RECOVERY := 0.2
const DIVE_BOT_DELAY := 0.3

# --- I: Equilibrium ---
const BARRAGE_TIME := 2.5
const BARRAGE_GAP := 0.05
## The golden angle: shot after shot spreads evenly all round.
const BARRAGE_TURN := 2.39996
const BULLET_SPEED := 900.0
const BULLET_LIFETIME := 0.3
const BULLET_SIZE := Vector2(16, 5)
const BULLET_DAMAGE := 3.0
const BULLET_KNOCKBACK := 120.0
const BULLET_COLOR := Color(1.0, 0.62, 0.42, 0.95)
const BARRAGE_MOVE := 0.4

## Stand-in rows (Nova's female drawings recoloured, reports/xion-kit-2026-11-18/make_standin_art.py).
const SHEET_ROWS := [["idle", 6, 6.3, true], ["walk", 8, 13.3, true], ["jump", 1, 1.0, false], ["fall", 1, 1.0, false], ["attack", 6, 35.25, false], ["shield", 6, 12.0, false], ["hurt", 1, 1.0, false]]
const MOVE_SHEET_ROWS := [
	["shot", 6, 18.0, false],
	["shot_alt", 6, 16.0, false],
	["shot_up", 6, 13.0, false],
	["shot_down", 6, 26.1, false],
	["shot_air_down", 6, 30.0, false],
	["tumble", 6, 21.0, true],
	["recoil_jump", 6, 33.0, false],
	["double_cast", 6, 14.0, false],
	["dive", 6, 27.3, false],
	["barrage", 6, 14.3, false],
	["double_float", 6, 10.0, true],
]

var ammo := MAGAZINE
var reload_timer := 0.0
var since_shot := 0.0
var shot_timer := 0.0
var shot_hand := 0
var roll_cooldown_timer := 0.0
var roll_invulnerable_timer := 0.0
var air_roll_available := true
var recoil_available := true
var double: Node2D
var double_cooldown_timer := 0.0
var last_hit_foe: Node2D
var dive_timer := 0.0
var dive_from := Vector2.ZERO
var dive_to := Vector2.ZERO
var dive_mask := 0
var bot_pin_time := 0.0
var barrage_timer := 0.0
var barrage_tick := 0.0
var barrage_angle := 0.0
var shot_origin := Vector2.ZERO
var has_shot_origin := false
var point_blank_shown_at := -1.0
var reload_ring: Node2D
var reload_arc: Line2D
var reload_art: Sprite2D
## A reload-mark strip (CODEX-VFX-10 contract): 8 frames of 24x24, frame k at k/8 of the reload. The user picked
## the code ring in the pick cup (2026-11-24), so no file is there and the ring draws.
const RELOAD_ART := "res://assets/art/ui/status/xion_reload.png"
const RELOAD_ART_FRAMES := 8
## A reload-mark strip set at runtime instead of the file (the pick cup capture shows candidates with it).
var reload_art_override: Texture2D

func configure_character_sprite() -> void:
	_configure_original_sheet("xion")

func get_move_sheet_rows() -> Array:
	return MOVE_SHEET_ROWS

func get_sheet_rows() -> Array:
	return SHEET_ROWS

func has_skill_three() -> bool:
	return true

# --- J ---

## The rhythm and the magazine come first: a press inside the gap waits for the next shot if it is
## close, and an empty press only shows the reload over her head.
func basic_attack() -> void:
	if not _can_start_attack():
		return
	if shot_timer > 0.0:
		if shot_timer <= SHOT_BUFFER and is_human:
			attack_buffer_timer = maxf(attack_buffer_timer, shot_timer + 0.02)
		return
	if ammo <= 0:
		_pop_reload_ring()
		return
	super()

func perform_basic_attack(attack_type: String, direction: Vector2) -> void:
	var aim := _shot_aim(attack_type, direction)
	# Every shot row (CODEX-SKM-06 card): (1) stance, (2) aim, (3) the shot, (4) recover, (5) pump or
	# rise. Drawings 1-5: the timeline puts the third on the shot.
	var row := &"shot" if shot_hand == 0 else &"shot_alt"
	match attack_type:
		"up", "air_up":
			row = &"shot_up"
		"down":
			row = &"shot_down"
		"air_down":
			row = &"shot_air_down"
	shot_hand = 1 - shot_hand
	shot_timer = SHOT_GAP
	_start_attack(SHOT_STARTUP, SHOT_RECOVERY, Callable(self, "_fire_shot").bind(aim), Vector2i(-1, -1), row, Vector2i(0, 4))

## The held direction snapped to 45 degrees; on the ground a down shot goes low and ahead.
func _shot_aim(attack_type: String, direction: Vector2) -> Vector2:
	var aim := direction if direction.length() > 0.2 else Vector2(facing, 0.0)
	aim = Vector2.RIGHT.rotated(snappedf(aim.angle(), PI / 4.0))
	if attack_type == "down":
		var side := signf(aim.x) if absf(aim.x) > 0.2 else float(facing)
		return Vector2(side, 0.45).normalized()
	if attack_type in ["neutral", "side", "air_side"]:
		return Vector2(signf(aim.x) if absf(aim.x) > 0.2 else float(facing), 0.0)
	return aim.normalized()

func _fire_shot(aim: Vector2) -> void:
	if ammo <= 0:
		return
	_use_rounds(1)
	var points: Array[Vector2] = [GAME_SCALE.BODY_CENTRE + aim * SHOT_NEAR, GAME_SCALE.BODY_CENTRE + aim * SHOT_FAR]
	var push := aim if absf(aim.y) > 0.3 else Vector2(aim.x, -0.18).normalized()
	_spawn_sweeping_attack(_dir_size(aim, SHOT_SIZE), points, SHOT_DAMAGE, SHOT_KNOCKBACK, push, SHOT_COLOR, SHOT_SWEEP_TIME)
	_hide_attack_box()
	_shot_effect(global_position + GAME_SCALE.BODY_CENTRE + aim * 20.0, aim, (SHOT_FAR + SHOT_SIZE.x * 0.5) * GAME_SCALE.COMBAT - 20.0)

## The J blast: the picked strip (Vfx "xion_blast", candidate B, turned to the aim, mirrored to the left), else
## the code pellets.
func _shot_effect(muzzle: Vector2, aim: Vector2, reach: float) -> void:
	var art := VFX.spawn(get_parent(), "xion_blast", muzzle, Vector2.ONE, false, 5)
	if art != null:
		art.rotation = aim.angle()
		art.flip_v = aim.x < 0.0
		return
	_play_shotgun_blast(muzzle, aim, reach, 5)

## The blast draws pellets instead of the prototype box (no trail either).
func _hide_attack_box() -> void:
	if not is_instance_valid(last_attack):
		return
	last_attack.set("art_drawn", true)
	var visual := last_attack.get_node_or_null("Visual") as CanvasItem
	if visual != null:
		visual.visible = false

func _use_rounds(count: int) -> void:
	ammo = maxi(ammo - count, 0)
	since_shot = 0.0
	if ammo <= 0 and reload_timer <= 0.0:
		reload_timer = RELOAD_TIME
		_pop_reload_ring()

func _load_rounds(count: int) -> void:
	var before := ammo
	ammo = mini(ammo + count, MAGAZINE)
	if ammo > before:
		_play_float_text("+%d" % (ammo - before), Color(1.0, 0.86, 0.6))

func _update_magazine(delta: float) -> void:
	shot_timer = maxf(shot_timer - delta, 0.0)
	if reload_timer > 0.0:
		reload_timer = maxf(reload_timer - delta, 0.0)
		if reload_timer <= 0.0:
			ammo = MAGAZINE
			since_shot = 0.0
	elif ammo < MAGAZINE:
		since_shot += delta
		if since_shot >= IDLE_RELOAD:
			ammo = MAGAZINE
			since_shot = 0.0
	_update_reload_ring()

## The rounds on the skill bar's J slot; the doppelganger's seconds on U ("!" when she can dive).
func skill_counter(slot: String) -> String:
	match slot:
		"j":
			return "" if ammo <= 0 and reload_timer > 0.0 else str(ammo)
		"u":
			if is_instance_valid(double) and double.get("gone") != true:
				return "!" if _dive_ready() else str(ceili(double.time_left()))
	return ""

func skill_cooldown(slot: String) -> Vector2:
	match slot:
		"j":
			return Vector2(reload_timer, RELOAD_TIME) if ammo <= 0 else Vector2.ZERO
		"k":
			return Vector2(roll_cooldown_timer, ROLL_COOLDOWN)
		"u":
			return Vector2(double_cooldown_timer, DOUBLE_COOLDOWN)
	return super(slot)

# --- K: reload roll ---

func perform_skill_one() -> void:
	if roll_cooldown_timer > 0.0 or is_gravity_rooted() or (not is_on_floor() and not air_roll_available):
		return
	if not is_on_floor():
		air_roll_available = false
	var side := _get_late_horizontal_direction()
	facing = side
	roll_cooldown_timer = ROLL_COOLDOWN
	roll_invulnerable_timer = ROLL_INVULNERABLE
	velocity = Vector2.ZERO
	# A skill dash keeps its speed until its timer ends: an even roll over ROLL_DISTANCE.
	skill_dash_velocity = Vector2(side * ROLL_DISTANCE / ROLL_TIME, 0.0)
	skill_dash_timer = ROLL_TIME
	attack_lock_timer = ROLL_TIME
	current_attack_started_airborne = not is_on_floor()
	_load_rounds(ROLL_LOAD)
	_play_move_sprite_pose(&"tumble", -1, -1, ROLL_TIME, 0, 5)

func can_use_skill_one() -> bool:
	return super() and roll_cooldown_timer <= 0.0 and (is_on_floor() or air_roll_available)

## The bots' recovery move (EnemyAI): L's recoil while she has rounds, else K in the air to load two.
func recovery_attack() -> String:
	if not _can_start_attack() or is_gravity_rooted():
		return ""
	if ammo > 0 and recoil_available:
		return "skill_2"
	if ammo <= 0 and not is_on_floor() and air_roll_available and roll_cooldown_timer <= 0.0:
		return "skill_1"
	return ""

func is_invulnerable() -> bool:
	return super() or roll_invulnerable_timer > 0.0

# --- L: recoil jump ---

func perform_skill_two() -> void:
	if ammo <= 0:
		_pop_reload_ring()
		return
	if not recoil_available or is_gravity_rooted():
		return
	recoil_available = false
	_start_attack(RECOIL_STARTUP, RECOIL_RECOVERY, Callable(self, "_recoil_blast"), Vector2i(-1, -1), &"recoil_jump", Vector2i(0, 3))

func _recoil_blast() -> void:
	var rounds := ammo
	if rounds <= 0:
		return
	_use_rounds(rounds)
	var points: Array[Vector2] = [Vector2(0, 0), Vector2(0, 29)]
	_spawn_sweeping_attack(RECOIL_SIZE, points, RECOIL_DAMAGE_PER_ROUND * rounds, RECOIL_KNOCKBACK, Vector2(0, 1), SHOT_COLOR, SHOT_SWEEP_TIME)
	_hide_attack_box()
	velocity.y = jump_velocity * RECOIL_RISE
	knockback_velocity.y = minf(knockback_velocity.y, 0.0)
	if VFX.spawn(get_parent(), "xion_recoil_blast", global_position, Vector2.ONE, false, 5) == null:
		_play_shotgun_blast(global_position + Vector2(0, -6), Vector2.DOWN, 150.0, 4 + rounds)

# --- U: doppelganger ---

func perform_skill_three() -> void:
	if is_instance_valid(double) or double_cooldown_timer > 0.0 or is_gravity_rooted():
		return
	_double_cast()

## U while the doppelganger is out: the dive when it pins a foe near her; one at a time either way.
func try_skill_three_followup() -> bool:
	if not is_instance_valid(double) or double.get("gone") == true:
		return false
	if _dive_ready() and hitstun_timer <= 0.0 and dive_timer <= 0.0 and not is_defeated and not is_gravity_rooted():
		_dive_start()
	return true

func _double_cast() -> void:
	var copy := CharacterBody2D.new()
	copy.set_script(DOUBLE_SCRIPT)
	copy.name = "XionDouble"
	get_parent().add_child(copy)
	copy.global_position = global_position
	copy.configure(self, DOUBLE_LIFETIME, DOUBLE_SPEED, PIN_TIME, DOUBLE_HIT_SLOW, character_sprite if _uses_character_sprite() else null)
	double = copy
	bot_pin_time = 0.0
	attack_lock_timer = maxf(attack_lock_timer, CAST_RECOVERY)
	current_attack_started_airborne = not is_on_floor()
	# (2)-(3) the arm swept back as she calls her double, (4)-(5) guns ready again.
	_play_move_sprite_pose(&"double_cast", -1, -1, CAST_RECOVERY, 1, 4)
	if VFX.spawn(get_parent(), "xion_double_in", global_position, Vector2.ONE, false, 3) == null:
		_play_ring(global_position + GAME_SCALE.BODY_CENTRE, CRIMSON, 0.2)

func on_double_pinned(copy: Node2D, _foe: Node2D) -> void:
	if copy == double:
		bot_pin_time = 0.0

func on_double_gone(copy: Node2D) -> void:
	if copy != double:
		return
	double = null
	double_cooldown_timer = DOUBLE_COOLDOWN
	bot_pin_time = 0.0

func _dive_ready() -> bool:
	if not is_instance_valid(double) or double.get("gone") == true or not double.is_pinning():
		return false
	var foe: Node2D = double.pinned
	return is_instance_valid(foe) and foe.global_position.distance_to(global_position) <= DIVE_RANGE

## U again: through walls and floors to the doppelganger on the pinned foe's head, in 0.2 s.
func _dive_start() -> void:
	dive_from = global_position
	dive_to = double.global_position
	dive_timer = DIVE_TIME
	dive_mask = collision_mask
	collision_mask = 0
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	skill_dash_timer = 0.0
	_end_skill_dash()
	attack_lock_timer = maxf(attack_lock_timer, DIVE_TIME)
	if absf(dive_to.x - dive_from.x) > 0.5:
		facing = 1 if dive_to.x > dive_from.x else -1
	_play_move_sprite_pose(&"dive", -1, -1, DIVE_TIME, 1, 4)
	_play_dive_trail(dive_from, dive_to)

func _update_dive(delta: float) -> void:
	if dive_timer <= 0.0:
		return
	dive_timer = maxf(dive_timer - delta, 0.0)
	global_position = dive_from.lerp(dive_to, 1.0 - dive_timer / DIVE_TIME)
	velocity = Vector2.ZERO
	if dive_timer <= 0.0:
		_dive_end(true)

## Arrived (or cut short by a hit): solid again, and the doppelganger is spent, freeing the foe.
func _dive_end(arrived: bool) -> void:
	dive_timer = 0.0
	collision_mask = dive_mask if dive_mask != 0 else WORLD_LAYER
	velocity = Vector2.ZERO
	if is_instance_valid(double):
		double.spend()
	if arrived:
		_play_ring(global_position + GAME_SCALE.BODY_CENTRE, CRIMSON, 0.16)

# --- I: Equilibrium ---

func perform_ultimate() -> void:
	ammo = MAGAZINE
	reload_timer = 0.0
	since_shot = 0.0
	barrage_timer = BARRAGE_TIME
	barrage_tick = 0.0
	barrage_angle = randf() * TAU
	attack_lock_timer = BARRAGE_TIME
	current_attack_started_airborne = not is_on_floor()
	# The gun-kata turn loops for the whole barrage.
	_play_sprite_action(&"barrage", BARRAGE_TIME)

func _update_barrage(delta: float) -> void:
	if barrage_timer <= 0.0:
		return
	barrage_timer = maxf(barrage_timer - delta, 0.0)
	barrage_tick -= delta
	while barrage_tick <= 0.0:
		barrage_tick += BARRAGE_GAP
		barrage_angle = fmod(barrage_angle + BARRAGE_TURN, TAU)
		var aim := Vector2.RIGHT.rotated(barrage_angle)
		_fire_bullet(global_position + GAME_SCALE.BODY_CENTRE, aim)
		if is_instance_valid(double) and double.get("gone") != true:
			_fire_bullet(double.global_position + GAME_SCALE.BODY_CENTRE, -aim)
	if barrage_timer <= 0.0:
		_end_barrage()

func _end_barrage() -> void:
	barrage_timer = 0.0
	ammo = MAGAZINE
	reload_timer = 0.0
	since_shot = 0.0

func is_barraging() -> bool:
	return barrage_timer > 0.0

func get_character_movement_multiplier() -> float:
	if barrage_timer > 0.0:
		return BARRAGE_MOVE / (ATTACK_GROUND_MOBILITY if is_on_floor() else ATTACK_AIR_MOBILITY)
	return 1.0

func _fire_bullet(from: Vector2, aim: Vector2) -> void:
	var bullet := Area2D.new()
	bullet.set_script(BULLET_SCRIPT)
	bullet.collision_layer = 0
	bullet.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var visual := ColorRect.new()
	visual.name = "Visual"
	bullet.add_child(shape)
	bullet.add_child(visual)
	get_parent().add_child(bullet)
	bullet.global_position = from + aim * 18.0
	bullet.rotation = aim.angle()
	bullet.z_index = 4
	bullet.art_scale_multiplier = GAME_SCALE.COMBAT
	bullet.configure(self, BULLET_SIZE, BULLET_DAMAGE, BULLET_KNOCKBACK, aim, BULLET_COLOR, BULLET_SPEED, BULLET_LIFETIME)
	bullet.muzzle = from
	# A tracer strip would replace the rectangle (the user picked the rectangle, so none is in the folder); the
	# bullet node already points along the flight.
	if bullet.set_effect_art("xion_bullet", 1.0):
		var tracer := bullet.get_node_or_null("Vfx_xion_bullet") as Node2D
		if tracer != null:
			tracer.rotation = 0.0
			tracer.scale.x = absf(tracer.scale.x)

# --- Passive: 더블 샷건, and who the doppelganger hunts ---

func damage_scale_against(target: Node) -> float:
	if not target is Node2D:
		return 1.0
	var origin := shot_origin if has_shot_origin else global_position + GAME_SCALE.BODY_CENTRE
	var distance := origin.distance_to((target as Node2D).global_position + GAME_SCALE.BODY_CENTRE)
	var close_scale := lerpf(CLOSE_SCALE, 1.0, clampf((distance - CLOSE_RANGE) / (FAR_RANGE - CLOSE_RANGE), 0.0, 1.0))
	if close_scale >= POINT_BLANK_SHOWN:
		_mark_point_blank.call_deferred(target)
	return close_scale

## A hit fired from `muzzle` (a bullet of I): the passive measures from there.
func hit_from(muzzle: Vector2, body: Node, amount: float, push: float, direction: Vector2, damage_type: String) -> Variant:
	shot_origin = muzzle
	has_shot_origin = true
	var landed: Variant = body.apply_hit(self, amount, push, direction, damage_type)
	has_shot_origin = false
	return landed

func on_bullet_hit(body: Node, _at: Vector2) -> void:
	_note_foe(body)

func character_on_attack_hit_body(body: Node, _attack: Node) -> void:
	_note_foe(body)

## The doppelganger hunts the foe fighter she hit last (monsters do not count).
func _note_foe(body: Node) -> void:
	if body is Node2D and body != self and body.is_in_group("players") and body.get("is_defeated") != true:
		last_hit_foe = body as Node2D

## A crimson burst on a foe hit from up close (the user picked this code ring over the drawn candidates).
func _mark_point_blank(target: Node) -> void:
	if not is_instance_valid(target) or not target is Node2D:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - point_blank_shown_at < 0.08:
		return
	point_blank_shown_at = now
	var centre := (target as Node2D).global_position + GAME_SCALE.BODY_CENTRE
	if VFX.spawn(get_parent(), "xion_point_blank", centre, Vector2.ONE, false, 6) == null:
		_play_ring(centre, Color(1.0, 0.3, 0.36, 0.95), 0.12)

# --- Frame update, hits, respawn ---

func character_physics_process(delta: float) -> void:
	roll_cooldown_timer = maxf(roll_cooldown_timer - delta, 0.0)
	roll_invulnerable_timer = maxf(roll_invulnerable_timer - delta, 0.0)
	double_cooldown_timer = maxf(double_cooldown_timer - delta, 0.0) if not is_instance_valid(double) else double_cooldown_timer
	# Landing gives the air roll and the recoil back (not during a move: L's start-up is on the floor).
	if is_on_floor() and velocity.y >= 0.0 and dive_timer <= 0.0 and attack_lock_timer <= 0.0:
		air_roll_available = true
		recoil_available = true
	_update_magazine(delta)
	_update_dive(delta)
	_update_barrage(delta)
	if not is_human and not is_dummy:
		_bot_double(delta)

## Bots: leave the doppelganger once they have hit a foe, and dive to it 0.3 s after it pins a foe
## near them.
func _bot_double(delta: float) -> void:
	if is_instance_valid(double) and double.get("gone") != true:
		if double.is_pinning():
			bot_pin_time += delta
			if bot_pin_time >= DIVE_BOT_DELAY and _dive_ready() and hitstun_timer <= 0.0 and attack_lock_timer <= 0.0 and dive_timer <= 0.0:
				_dive_start()
		return
	if double_cooldown_timer > 0.0 or not _can_start_attack() or not is_instance_valid(last_hit_foe):
		return
	if last_hit_foe.get("is_defeated") == true or int(last_hit_foe.get("realm_index")) != realm_index:
		return
	_double_cast()

func character_on_hit() -> void:
	if dive_timer > 0.0:
		_dive_end(false)
	if barrage_timer > 0.0:
		_end_barrage()
		attack_lock_timer = 0.0

func character_on_respawn() -> void:
	if dive_timer > 0.0:
		_dive_end(false)
	_clear_double()
	_end_barrage()
	attack_lock_timer = 0.0
	ammo = MAGAZINE
	reload_timer = 0.0
	since_shot = 0.0
	shot_timer = 0.0
	roll_cooldown_timer = 0.0
	roll_invulnerable_timer = 0.0
	double_cooldown_timer = 0.0
	air_roll_available = true
	recoil_available = true
	last_hit_foe = null
	_update_reload_ring()

func character_cleanup() -> void:
	character_on_respawn()

func _clear_double() -> void:
	if is_instance_valid(double):
		double.vanish()
	double = null

# --- Stand-in effects (code-drawn until the pick cup) ---

## The over-head reload ring: only while she reloads (the user's rule: rounds on the skill bar,
## over the head only when empty or reloading).
func _update_reload_ring() -> void:
	if reload_timer <= 0.0:
		if is_instance_valid(reload_ring):
			reload_ring.visible = false
		return
	if not is_instance_valid(reload_ring):
		_make_reload_ring()
	reload_ring.visible = true
	var beside := is_instance_valid(status_icon) and status_icon.visible
	reload_ring.position = Vector2(-24.0 if beside else 0.0, STATUS_ICON_Y)
	var progress := clampf(1.0 - reload_timer / RELOAD_TIME, 0.0, 1.0)
	if is_instance_valid(reload_art):
		var atlas := reload_art.texture as AtlasTexture
		var width := float(atlas.atlas.get_width()) / RELOAD_ART_FRAMES
		atlas.region = Rect2(mini(int(progress * RELOAD_ART_FRAMES), RELOAD_ART_FRAMES - 1) * width, 0, width, atlas.atlas.get_height())
		return
	reload_arc.clear_points()
	var steps := 2 + int(22.0 * progress)
	for index in steps:
		var angle := -PI / 2.0 + TAU * progress * float(index) / float(steps - 1)
		reload_arc.add_point(Vector2(cos(angle), sin(angle)) * 9.0)

func _make_reload_ring() -> void:
	reload_ring = Node2D.new()
	reload_ring.name = "ReloadRing"
	reload_ring.z_index = 7
	add_child(reload_ring)
	var strip: Texture2D = reload_art_override if reload_art_override != null else SHEET_ART.original_texture(RELOAD_ART)
	if strip != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = strip
		atlas.region = Rect2(0, 0, float(strip.get_width()) / RELOAD_ART_FRAMES, strip.get_height())
		reload_art = Sprite2D.new()
		reload_art.name = "ReloadArt"
		reload_art.texture = atlas
		reload_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		reload_ring.add_child(reload_art)
		return
	var back := Line2D.new()
	back.width = 3.0
	back.closed = true
	back.default_color = Color(0.08, 0.08, 0.1, 0.75)
	for corner in 16:
		var angle := TAU * corner / 16.0
		back.add_point(Vector2(cos(angle), sin(angle)) * 9.0)
	reload_ring.add_child(back)
	reload_arc = Line2D.new()
	reload_arc.width = 3.0
	reload_arc.default_color = CRIMSON
	reload_ring.add_child(reload_arc)
	var shell := Polygon2D.new()
	shell.polygon = PackedVector2Array([Vector2(-2, -4), Vector2(2, -4), Vector2(2, 4), Vector2(-2, 4)])
	shell.color = Color(1.0, 0.86, 0.6)
	reload_ring.add_child(shell)

func _pop_reload_ring() -> void:
	_update_reload_ring()
	if not is_instance_valid(reload_ring) or not reload_ring.visible:
		return
	reload_ring.scale = Vector2(1.6, 1.6)
	var tween := reload_ring.create_tween()
	tween.tween_property(reload_ring, "scale", Vector2.ONE, 0.14)

## Pellet streaks fanning from the muzzle and a flash at it.
func _play_shotgun_blast(muzzle: Vector2, aim: Vector2, reach: float, pellets: int) -> void:
	var spread_step := deg_to_rad(28.0) / maxf(float(pellets - 1), 1.0)
	for pellet in pellets:
		var angle := -deg_to_rad(14.0) + spread_step * pellet
		var line := Line2D.new()
		line.width = 2.5
		line.default_color = PELLET_COLOR
		line.z_index = 4
		line.add_point(muzzle)
		line.add_point(muzzle + aim.rotated(angle) * reach * randf_range(0.82, 1.0))
		get_parent().add_child(line)
		var tween := line.create_tween()
		tween.tween_property(line, "width", 0.5, 0.1)
		tween.parallel().tween_property(line, "modulate:a", 0.0, 0.1)
		tween.tween_callback(line.queue_free)
	var flash := Polygon2D.new()
	var points := PackedVector2Array()
	for corner in 10:
		var radius := 13.0 if corner % 2 == 0 else 5.0
		var angle := TAU * corner / 10.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	flash.polygon = points
	flash.color = Color(1.0, 0.9, 0.6, 0.95)
	flash.z_index = 5
	get_parent().add_child(flash)
	flash.global_position = muzzle
	var pop := flash.create_tween()
	pop.tween_property(flash, "scale", Vector2(1.5, 1.5), 0.06)
	pop.parallel().tween_property(flash, "modulate:a", 0.0, 0.08)
	pop.tween_callback(flash.queue_free)

func _play_ring(at: Vector2, color: Color, duration: float) -> void:
	var ring := Line2D.new()
	ring.width = 3.0
	ring.closed = true
	ring.default_color = color
	ring.z_index = 5
	for corner in 12:
		var angle := TAU * corner / 12.0
		ring.add_point(Vector2(cos(angle), sin(angle)) * 26.0)
	get_parent().add_child(ring)
	ring.global_position = at
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector2(2.2, 2.2), duration)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, duration)
	tween.tween_callback(ring.queue_free)

func _play_dive_trail(from: Vector2, to: Vector2) -> void:
	var path := to - from
	var art := VFX.spawn(get_parent(), "xion_dive_trail", (from + to) * 0.5 + GAME_SCALE.BODY_CENTRE, Vector2(maxf(path.length(), 1.0) / 240.0, 1.0), false, 2)
	if art != null:
		art.rotation = path.angle()
		return
	var trail := Line2D.new()
	trail.width = 12.0
	trail.default_color = Color(0.86, 0.2, 0.32, 0.5)
	trail.z_index = 2
	trail.add_point(from + GAME_SCALE.BODY_CENTRE)
	trail.add_point(to + GAME_SCALE.BODY_CENTRE)
	get_parent().add_child(trail)
	var tween := trail.create_tween()
	tween.tween_property(trail, "width", 1.0, 0.24)
	tween.parallel().tween_property(trail, "modulate:a", 0.0, 0.24)
	tween.tween_callback(trail.queue_free)
