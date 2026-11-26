extends "res://characters/common/PlayerBase.gd"
## Rio, spellblade assassin. Play style (D46): an assassin who toys with foes through varied
## movement. Kit v3 (2026-11-18, D50; the user's "제안대로 넣기" on reports/rio-concepts-2026-11-04/):
## three moves that go to different places - K to his thrown sword, L behind whoever hits him,
## U to the decoy he left - and hits from behind deal 1.5x (passive). J's third hit dashes through
## to the target's back; I sticks six gem swords in nearby foes and the second press cuts through
## them all. Two air jumps come from RioData ("air_jumps"); the mana steps stay.

const VFX := preload("res://scripts/Vfx.gd")
const SWORD_SCRIPT := preload("res://characters/rio/RioSword.gd")
const DECOY_SCRIPT := preload("res://characters/rio/RioDecoy.gd")
const COMBO_RESET_TIME := 0.4
## Passive "급소": a hit landed from behind the target (the side it does not face, more than
## BACKSTAB_MARGIN px off its centre) deals 1.5x; a blue X marks it on the target.
const BACKSTAB_SCALE := 1.5
const BACKSTAB_MARGIN := 4.0
const BACKSTAB_COLOR := Color(0.45, 0.82, 1.0, 0.95)
## J third hit "관통 베기": a dash through whoever is ahead that ends behind them (150 px at
## GameScale.WORLD); a ledge or a wall stops it. The hit throws the target back the way he came.
const PIERCE_DISTANCE := 100.0
const PIERCE_TIME := 0.1
const PIERCE_DAMAGE := 9.0
const PIERCE_KNOCKBACK := 260.0
## K "마검 투척": the sword flies 0.4 s at 700 x COMBAT (about 420 px), sticks in the first body
## (4 damage), a wall or the floor, or stops at the end; the second K within SWORD_WAIT blinks him
## to it, behind its target when it sticks in one, and slashes. One throw per airtime.
const SWORD_STARTUP := 0.1
const SWORD_RECOVERY := 0.2
const SWORD_SIZE := Vector2(30, 12)
const SWORD_SPEED := 700.0
const SWORD_FLIGHT := 0.4
const SWORD_WAIT := 3.0
const SWORD_DAMAGE := 4.0
const SWORD_KNOCKBACK := 60.0
const SWORD_COLOR := Color(0.55, 0.85, 1.0)
const BLINK_SLASH_DAMAGE := 10.0
const BLINK_SLASH_KNOCKBACK := 340.0
const BLINK_RECOVERY := 0.2
## Where he appears behind a target: this far past its centre on the side it does not face
## (x GameScale.COMBAT, 60 px).
const BEHIND_OFFSET := 40.0
## L "그림자 받아치기": a 0.4 s stance; the first hit in it does nothing to him, he vanishes and
## appears behind the attacker (when it is within COUNTER_REACH px) with a slash. A whiff leaves
## him open.
const COUNTER_TIME := 0.4
const COUNTER_COOLDOWN := 3.0
const COUNTER_WHIFF_RECOVERY := 0.3
const COUNTER_VANISH := 0.1
const COUNTER_DAMAGE := 12.0
const COUNTER_KNOCKBACK := 380.0
const COUNTER_REACH := 500.0
const SHADOW_TINT := Color(0.45, 0.52, 1.0)
## U "분신 바꿔치기": a decoy where he stands and a step back (150 px, or the held direction); the
## second U swaps places with it once. It lasts DECOY_TIME and bursts on the first foe's hit.
const DECOY_TIME := 4.0
const DECOY_COOLDOWN := 5.0
const DECOY_STEP := 100.0
const DECOY_RECOVERY := 0.16
const DECOY_BURST_DAMAGE := 6.0
const DECOY_BURST_KNOCKBACK := 300.0
const DECOY_BURST_SIZE := Vector2(80, 80)
## I "마검 난무": six gem swords fly at the nearest foes within FLURRY_RANGE x COMBAT (taking turns)
## and stick; the second I within FLURRY_WAIT blinks him behind each struck foe in turn and cuts
## (the old Infinity Overdrive's damage), then back to where he pressed it. Without it they burst.
const FLURRY_SWORDS := 6
const FLURRY_RANGE := 340.0
const FLURRY_FIRE_GAP := 0.05
const FLURRY_WAIT := 3.0
const FLURRY_GAP := 0.12
const FLURRY_STICK_DAMAGE := 2.0
const FLURRY_SLASH_DAMAGE := 11.0
const FLURRY_LAST_DAMAGE := 18.0
const FLURRY_SLASH_KNOCKBACK := 320.0
const FLURRY_LAST_KNOCKBACK := 520.0
const FLURRY_BURST_DAMAGE := 6.0
const FLURRY_SWORD_SPEED := 980.0
const FLURRY_SWORD_FLIGHT := 0.62
## A bot cuts this long after its swords are out (people press I again).
const FLURRY_BOT_DELAY := 0.4
enum Flurry { NONE, THROWING, WAITING, CUTTING }
## Cast pose: its strike drawing at two drawings of the male row's adopted 7.15 fps (D39).
const OVERDRIVE_POSE_STRIKE := 0.28
## Plunge start-up before the dive: two drawings at the female row's adopted 8.4 fps (D39; was 0.08).
const PLUNGE_STARTUP := 0.238
const OVERDRIVE_RADIUS := 58.0
## Extra air jump (sprite audit D40 B8, CODEX-VFX-01 candidate a, user 2026-10-29): a mana step
## plate breaks under his soles, brighter on the last jump. Rise from the feet line to the soles
## in the jump drawing shown at that moment: soles at y=112 of the 128 cell, feet line y=120, in
## both `rio_male_jump.png` frame 0 and the female base-sheet jump row (row 3; walk takes rows 1-2).
const AIR_STEP_SOLE_RISE := {"male": 8.0, "female": 8.0}
const MANA_COLOR := Color(0.45, 0.78, 1.0, 0.6)
const RUNE_COLOR := Color(0.35, 0.72, 1.0, 0.9)
const GEM_COLORS: Array[Color] = [
	Color(1.0, 0.35, 0.45), Color(1.0, 0.75, 0.3), Color(0.5, 1.0, 0.5),
	Color(0.35, 0.85, 1.0), Color(0.6, 0.5, 1.0), Color(1.0, 0.5, 0.95)
]
## Redrawn 2026-10-15 for both bodies (D33-D37): every motion is 6 frames with its old length
## (fps x 6 / old frames), the idle at 6.3 fps (D37), the walk 8 frames at 13.3 fps (two sheet rows).
## The base `attack` row is only a fallback (J plays mana_combo).
const SHEET_ROWS := [["idle", 6, 6.3, true], ["walk", 8, 13.3, true], ["jump", 1, 1.0, false], ["fall", 1, 1.0, false], ["attack", 6, 21.0, false], ["shield", 6, 12.0, false], ["hurt", 1, 1.0, false]]
## 192-px cells (D34). `tumble` is new for Rio: strong launches play it instead of the hurt frame.
## Kit v3 borrows rows until its own are drawn: the throw dimension_slash 1-3 and the blink slash
## 4-6, the counter stance rune_shield, the decoy dimension_slash 5-6, the cast
## infinity_overdrive, the flurry cuts mana_combo; the pierce is mana_combo 5-6 as before.
const MOVE_SHEET_ROWS := [
	["mana_combo", 6, 18.0, false],
	["rising_slash", 6, 30.0, false],
	["low_sweep", 6, 30.0, false],
	["air_slash", 6, 40.0, false],
	["plunge", 6, 12.0, false],
	["dimension_slash", 6, 23.0, false],
	["rune_shield", 6, 12.0, false],
	["infinity_overdrive", 6, 11.0, false],
	["tumble", 6, 21.0, true],
]

var combo_step := 0
var combo_timer := 0.0
var pierce_target: Node2D
var pierce_turn_pending := false
var air_throw_available := true
var thrown_sword: Node2D
## >= 0 while a bot waits to blink to its stuck sword.
var sword_bot_timer := -1.0
var counter_timer := 0.0
var counter_cooldown_timer := 0.0
var counter_triggered := false
var shadow_vanished := false
var stance_visual: Line2D
var decoy: Node2D
var decoy_cooldown_timer := 0.0
var decoy_swap_ready := false
## Swaps left with the decoy that stands: one, or two with Second Decoy (his soul card, D54).
var decoy_swaps_left := 0
var flurry_phase := Flurry.NONE
var flurry_swords: Array[Node2D] = []
var flurry_timer := 0.0
var flurry_bot_timer := 0.0
var flurry_circle: AnimatedSprite2D

func configure_character_sprite() -> void:
	_configure_original_sheet("rio")

func get_move_sheet_rows() -> Array:
	return MOVE_SHEET_ROWS

func get_sheet_rows() -> Array:
	return SHEET_ROWS

func perform_basic_attack(attack_type: String, _direction: Vector2) -> void:
	match attack_type:
		"up", "air_up":
			_reset_combo()
			_start_attack(0.103, 0.2, Callable(self, "_rising_slash").bind(attack_type == "air_up"), Vector2i(-1, -1), &"rising_slash")
		"down":
			_reset_combo()
			_start_attack(0.111, 0.2, Callable(self, "_low_sweep"), Vector2i(-1, -1), &"low_sweep")
		"air_down":
			_reset_combo()
			_plunge_start()
		"air_side":
			_reset_combo()
			_start_attack(0.077, 0.15, Callable(self, "_air_slash"), Vector2i(-1, -1), &"air_slash")
		_:
			match _consume_combo_step():
				0:
					_start_attack(0.079, 0.12, Callable(self, "_mana_slash_one"), Vector2i(-1, -1), &"mana_combo", Vector2i(0, 1))
				1:
					_start_attack(0.079, 0.13, Callable(self, "_mana_slash_two"), Vector2i(-1, -1), &"mana_combo", Vector2i(2, 3))
				_:
					_start_attack(0.08, 0.22, Callable(self, "_pierce_slash"), Vector2i(-1, -1), &"mana_combo", Vector2i(4, 5))

func perform_skill_one() -> void:
	# No throwing out of a gravity root (Nova, D47).
	if is_gravity_rooted() or (not is_on_floor() and not air_throw_available):
		return
	_reset_combo()
	_clear_sword()
	if not is_on_floor():
		air_throw_available = false
	_start_attack(SWORD_STARTUP, SWORD_RECOVERY, Callable(self, "_throw_sword"), Vector2i(-1, -1), &"dimension_slash", Vector2i(0, 2))

## The second K: to the sword, even while it still flies.
func try_skill_one_followup() -> bool:
	if not _sword_ready() or hitstun_timer > 0.0 or is_defeated:
		return false
	if not is_gravity_rooted():
		_sword_blink()
	return true

func can_use_skill_one() -> bool:
	return super() and (is_on_floor() or air_throw_available)

func perform_skill_two() -> void:
	if counter_cooldown_timer > 0.0:
		return
	_counter_start()

func has_skill_three() -> bool:
	return true

func perform_skill_three() -> void:
	if decoy_cooldown_timer > 0.0 or is_gravity_rooted():
		return
	_decoy_cast()

## The second U: swap places with the decoy, once (twice with Second Decoy).
func try_skill_three_followup() -> bool:
	if not decoy_swap_ready or not is_instance_valid(decoy) or decoy.get("burst") == true:
		return false
	if hitstun_timer > 0.0 or is_defeated or is_gravity_rooted():
		return false
	_decoy_swap()
	return true

func skill_cooldown(slot: String) -> Vector2:
	match slot:
		"l":
			return Vector2(counter_cooldown_timer, COUNTER_COOLDOWN)
		"u":
			return Vector2(decoy_cooldown_timer, DECOY_COOLDOWN)
	return super(slot)

func perform_ultimate() -> void:
	_flurry_start()

## The second I cuts through the stuck swords; presses while they fly or while he cuts are part of
## the same ultimate.
func try_ultimate_followup() -> bool:
	match flurry_phase:
		Flurry.THROWING, Flurry.CUTTING:
			return true
		Flurry.WAITING:
			if hitstun_timer <= 0.0 and not is_defeated:
				_start_flurry()
				ultimate_followup_started = true
			return true
	return false

func is_invulnerable() -> bool:
	return super() or shadow_vanished or flurry_phase == Flurry.CUTTING

func character_on_air_jump() -> void:
	var effect := "rio_air_step_last" if air_jumps_left <= 0 else "rio_air_step"
	var soles := global_position - Vector2(0.0, float(AIR_STEP_SOLE_RISE.get(body_type, 0.0)))
	VFX.spawn(get_parent(), effect, soles, Vector2.ONE, false, 2)

func character_physics_process(delta: float) -> void:
	combo_timer = maxf(combo_timer - delta, 0.0)
	if combo_timer <= 0.0:
		combo_step = 0
	counter_cooldown_timer = maxf(counter_cooldown_timer - delta, 0.0)
	decoy_cooldown_timer = maxf(decoy_cooldown_timer - delta, 0.0)
	if counter_timer > 0.0:
		counter_timer = maxf(counter_timer - delta, 0.0)
	if is_on_floor():
		air_throw_available = true
	_finish_pierce()
	if sword_bot_timer >= 0.0:
		sword_bot_timer -= delta
		if sword_bot_timer < 0.0 and _sword_ready() and hitstun_timer <= 0.0 and not is_gravity_rooted():
			_sword_blink()
			count_move("k2")
	_update_flurry_wait(delta)

func character_on_hit() -> void:
	_reset_combo()
	pierce_turn_pending = false
	pierce_target = null
	counter_timer = 0.0
	_show_stance(false)
	# Hit while the gem swords fly: those out stay and wait for the second I.
	if flurry_phase == Flurry.THROWING:
		_flurry_thrown()

func character_on_respawn() -> void:
	character_on_hit()
	_clear_sword()
	_clear_decoy()
	_clear_flurry()
	_set_vanished(false)
	shadow_vanished = false
	air_throw_available = true
	counter_cooldown_timer = 0.0
	decoy_cooldown_timer = 0.0

func character_cleanup() -> void:
	character_on_respawn()

func character_refill() -> void:
	counter_cooldown_timer = 0.0
	decoy_cooldown_timer = 0.0

func character_hit_absorption() -> float:
	return 0.0 if counter_timer > 0.0 else -1.0

func character_on_hit_absorbed(attacker: Node, _knockback: float, _direction: Vector2) -> void:
	if counter_triggered:
		return
	counter_triggered = true
	counter_timer = 0.0
	shadow_vanished = true
	_show_stance(false)
	# Not inside the attacker's hit: the counter moves him and spawns a hit of its own.
	_shadow_counter.call_deferred(attacker)

func character_on_attack_hit_body(body: Node, attack: Node) -> void:
	if attack.has_meta("rio_pierce") and body is Node2D:
		pierce_target = body as Node2D

# --- Passive: 급소 (backstab) ---

func damage_scale_against(target: Node) -> float:
	# The common scale (Hunter, a soul card, against monsters) under his own.
	var common := super(target)
	if not _is_behind(target):
		return common
	_mark_backstab.call_deferred(target)
	if target.is_in_group("players"):
		count_move("back_hits")
	return BACKSTAB_SCALE * common

## Rio stands on the side `target` does not face.
func _is_behind(target: Node) -> bool:
	if not target is Node2D or target.get("facing") == null:
		return false
	var side := (global_position.x - (target as Node2D).global_position.x) * float(target.get("facing"))
	return side < -BACKSTAB_MARGIN

## A blue X over the target's body (stand-in for the backstab art).
func _mark_backstab(target: Node) -> void:
	if not is_instance_valid(target) or not target is Node2D or not is_inside_tree():
		return
	var mark := Node2D.new()
	mark.name = "RioBackstab"
	mark.z_index = 8
	for side in [-1.0, 1.0]:
		var stroke := Line2D.new()
		stroke.width = 5.0
		stroke.default_color = BACKSTAB_COLOR
		stroke.points = PackedVector2Array([Vector2(-16, -16 * side), Vector2(16, 16 * side)])
		mark.add_child(stroke)
	get_parent().add_child(mark)
	mark.global_position = (target as Node2D).global_position + GAME_SCALE.BODY_CENTRE
	mark.scale = Vector2.ONE * 0.6
	var tween := mark.create_tween()
	tween.tween_property(mark, "scale", Vector2.ONE * 1.4, 0.1)
	tween.tween_property(mark, "modulate:a", 0.0, 0.22)
	tween.tween_callback(mark.queue_free)

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

## Third swing: dashes through whoever is ahead and stands behind them, turned to face them. The cut
## rides along the dash; a ledge or a wall ends the dash early.
func _pierce_slash() -> void:
	var travel := Vector2(facing * _ground_ahead(PIERCE_DISTANCE * GAME_SCALE.WORLD), 0.0)
	var collision := move_and_collide(travel, true)
	if collision != null and collision.get_normal().y > -0.7:
		travel = collision.get_travel()
	pierce_target = null
	_spawn_sweeping_attack(Vector2(48, 44), [
		Vector2(0, -34),
		Vector2(travel.x * 0.5 / GAME_SCALE.COMBAT, -34),
		Vector2(travel.x / GAME_SCALE.COMBAT, -34)
	], PIERCE_DAMAGE, PIERCE_KNOCKBACK, Vector2(-facing, -0.3), Color(0.55, 0.85, 1.0, 0.66), PIERCE_TIME)
	last_attack.set_meta("rio_pierce", true)
	# The dash ends on its own timer (the hit's hitstop pauses it, not a wall clock); then he turns.
	pierce_turn_pending = true
	if travel.length() > 1.0:
		skill_dash_velocity = travel / PIERCE_TIME
		skill_dash_timer = PIERCE_TIME

## After the dash: turn to the foe it passed through.
func _finish_pierce() -> void:
	if not pierce_turn_pending or skill_dash_timer > 0.0:
		return
	pierce_turn_pending = false
	velocity.x = 0.0
	if is_instance_valid(pierce_target):
		_face(pierce_target)
	pierce_target = null

## How far ahead the floor goes, up to `distance` (all of it in the air).
func _ground_ahead(distance: float) -> float:
	if not is_on_floor():
		return distance
	var space := get_world_2d().direct_space_state
	var reach := 0.0
	while reach + 12.0 <= distance:
		var from := Vector2(global_position.x + facing * (reach + 12.0), global_position.y - 8.0)
		var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 40.0), WORLD_LAYER)
		if space.intersect_ray(query).is_empty():
			break
		reach += 12.0
	return reach

func _rising_slash(airborne: bool) -> void:
	velocity.y = minf(velocity.y, (-300.0 if airborne else -140.0) * GAME_SCALE.JUMP_SPEED)
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
	attack_lock_timer = PLUNGE_STARTUP + 0.42
	_play_move_sprite_pose(&"plunge", -1, -1, PLUNGE_STARTUP + 0.42, -1, -1, PLUNGE_STARTUP)
	action_locked_until_land = true
	current_attack_started_airborne = true
	velocity = Vector2(facing * 60.0, -80.0 * GAME_SCALE.JUMP_SPEED)
	_play_attack_windup()
	if not await _wait_action(PLUNGE_STARTUP):
		return
	if is_defeated or hitstun_timer > 0.0:
		return
	var dive := Vector2(0.45 * facing, 1.0).normalized()
	skill_dash_velocity = dive * 820.0 * GAME_SCALE.WORLD
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

# --- K: mana sword throw ---

func _throw_sword() -> void:
	var aim := _get_attack_direction()
	var sword := _make_sword(aim, SWORD_SIZE, SWORD_DAMAGE, SWORD_KNOCKBACK, SWORD_SPEED, SWORD_FLIGHT, SWORD_COLOR)
	sword.wait_time = SWORD_WAIT
	thrown_sword = sword
	sword_bot_timer = -1.0

func _make_sword(aim: Vector2, size: Vector2, damage: float, knockback: float, flight_speed: float, flight: float, tint: Color) -> Area2D:
	var sword := Area2D.new()
	sword.set_script(SWORD_SCRIPT)
	sword.collision_layer = 0
	sword.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var visual := ColorRect.new()
	visual.name = "Visual"
	sword.add_child(shape)
	sword.add_child(visual)
	get_parent().add_child(sword)
	sword.set("art_scale_multiplier", GAME_SCALE.COMBAT)
	sword.global_position = global_position + GAME_SCALE.BODY_CENTRE + aim * 24.0 * GAME_SCALE.COMBAT
	sword.configure(self, size * GAME_SCALE.COMBAT, damage, knockback, aim, Color(tint, 0.8), flight_speed * GAME_SCALE.COMBAT, flight)
	sword.dress(tint)
	return sword

func _sword_ready() -> bool:
	return is_instance_valid(thrown_sword) and not thrown_sword.gone

## A sword settled (RioSword): bots blink to one in a foe, or to any while they are in the air
## (recovering toward a platform); people press K again.
func on_sword_stuck(sword: Node2D) -> void:
	if is_human or sword != thrown_sword:
		return
	if sword.has_target():
		sword_bot_timer = 0.15
	elif not is_on_floor():
		sword_bot_timer = 0.0

## Blinks to the sword (stopped by solid ground on the way): behind its target when it sticks in
## one, else where it is, and slashes.
func _sword_blink() -> void:
	var sword := thrown_sword
	thrown_sword = null
	sword_bot_timer = -1.0
	_reset_combo()
	var target: Node2D = sword.stuck_body if sword.has_target() else null
	var start := global_position
	var spot: Vector2 = _behind(target) if target != null else sword.global_position - GAME_SCALE.BODY_CENTRE - sword.direction * 10.0
	_blink_to(spot, true)
	if target != null:
		_face(target)
	elif absf(sword.direction.x) > 0.2:
		facing = 1 if sword.direction.x > 0.0 else -1
	sword.expire()
	skill_dash_timer = 0.0
	_end_skill_dash()
	velocity = Vector2.ZERO
	attack_lock_timer = BLINK_RECOVERY
	current_attack_started_airborne = not is_on_floor()
	_play_move_sprite_pose(&"dimension_slash", -1, -1, BLINK_RECOVERY, 3, 5)
	_spawn_sweeping_attack(Vector2(56, 44), [
		Vector2(10 * facing, -44),
		Vector2(50 * facing, -34),
		Vector2(90 * facing, -22)
	], BLINK_SLASH_DAMAGE, BLINK_SLASH_KNOCKBACK, Vector2(facing, -0.25), Color(0.62, 0.55, 1.0, 0.7), 0.1)
	_play_blink_trail(start, global_position)

func _clear_sword() -> void:
	if is_instance_valid(thrown_sword):
		thrown_sword.expire()
	thrown_sword = null
	sword_bot_timer = -1.0

# --- L: shadow counter ---

func _counter_start() -> void:
	_reset_combo()
	counter_cooldown_timer = COUNTER_COOLDOWN
	counter_timer = COUNTER_TIME
	counter_triggered = false
	attack_lock_timer = COUNTER_TIME
	if character_sprite.sprite_frames.has_animation(_get_sprite_animation_name(&"rune_shield")):
		_play_move_sprite_pose(&"rune_shield", -1, -1, COUNTER_TIME)
	else:
		_play_sprite_action(&"shield", COUNTER_TIME)
	current_attack_started_airborne = false
	_freeze_movement(COUNTER_TIME)
	velocity = Vector2.ZERO
	_show_stance(true)
	if not await _wait_action(COUNTER_TIME):
		_show_stance(false)
		return
	if counter_triggered or is_defeated:
		return
	# Nothing came: a punishable whiff.
	counter_timer = 0.0
	_show_stance(false)
	movement_freeze_timer = 0.0
	attack_lock_timer = COUNTER_WHIFF_RECOVERY

## Vanishes, then appears behind the attacker and cuts (an attacker out of reach: he only dodged).
func _shadow_counter(attacker: Node) -> void:
	var start := global_position
	_set_vanished(true)
	if not await _wait_action(COUNTER_VANISH):
		shadow_vanished = false
		_set_vanished(false)
		return
	shadow_vanished = false
	_set_vanished(false)
	movement_freeze_timer = 0.0
	if is_defeated:
		return
	# The attacker can be freed while he is vanished (a monster that dies): he only dodged. Casting
	# a freed object is a script error.
	var foe: Node2D = attacker as Node2D if is_instance_valid(attacker) else null
	if not _can_reach(foe, COUNTER_REACH):
		attack_lock_timer = 0.1
		return
	_blink_to(_behind(foe), true)
	_face(foe)
	velocity = Vector2.ZERO
	attack_lock_timer = 0.2
	current_attack_started_airborne = not is_on_floor()
	_play_move_sprite_pose(&"dimension_slash", -1, -1, 0.2, 3, 5)
	_spawn_sweeping_attack(Vector2(56, 48), [
		Vector2(10 * facing, -46),
		Vector2(50 * facing, -34),
		Vector2(90 * facing, -20)
	], COUNTER_DAMAGE, COUNTER_KNOCKBACK, Vector2(facing, -0.3), Color(0.5, 0.55, 1.0, 0.75), 0.1)
	_play_blink_trail(start, global_position)

func _can_reach(foe: Node2D, reach: float) -> bool:
	if not is_instance_valid(foe) or foe.get("is_defeated") == true:
		return false
	if foe.has_method("is_down") and foe.is_down():
		return false
	var realm = foe.get("realm_index")
	if realm != null and int(realm) != realm_index:
		return false
	return foe.global_position.distance_to(global_position) <= reach

## The stance: his drawing in shadow blue inside the rune ring (stand-ins until its art).
func _show_stance(active: bool) -> void:
	if is_instance_valid(character_sprite):
		character_sprite.modulate = SHADOW_TINT if active else Color.WHITE
	if active and not is_instance_valid(stance_visual):
		stance_visual = Line2D.new()
		stance_visual.name = "CounterStance"
		stance_visual.width = 3.0
		stance_visual.closed = true
		stance_visual.default_color = Color(SHADOW_TINT, 0.9)
		stance_visual.z_index = 3
		for corner in 6:
			var angle := TAU * corner / 6.0 + PI / 6.0
			stance_visual.add_point(Vector2(0, -34) + Vector2(cos(angle), sin(angle)) * 48.0)
		add_child(stance_visual)
	if is_instance_valid(stance_visual):
		stance_visual.visible = active

func _set_vanished(vanished: bool) -> void:
	if is_instance_valid(character_sprite):
		character_sprite.modulate = Color(1, 1, 1, 0.0) if vanished else Color.WHITE

# --- U: decoy swap ---

func _decoy_cast() -> void:
	_reset_combo()
	_clear_decoy()
	decoy_cooldown_timer = DECOY_COOLDOWN
	var copy: AnimatableBody2D = DECOY_SCRIPT.new()
	copy.name = "RioDecoy"
	# Placed before it enters the tree (same parent, so his own position): its physics body then
	# starts there too, for the swing already on its way. Placed after, it stood at the parent's
	# origin, (0, 0) in a match (RioDecoy._init).
	copy.position = position
	get_parent().add_child(copy)
	copy.configure(self, DECOY_TIME, character_sprite if _uses_character_sprite() else null)
	decoy = copy
	decoy_swaps_left = 2 if has_card("second_decoy") else 1
	decoy_swap_ready = true
	var start := global_position
	_blink_to(start + _step_direction() * DECOY_STEP * GAME_SCALE.WORLD, true)
	velocity = Vector2.ZERO
	skill_dash_timer = 0.0
	_end_skill_dash()
	attack_lock_timer = DECOY_RECOVERY
	current_attack_started_airborne = not is_on_floor()
	_play_move_sprite_pose(&"dimension_slash", -1, -1, DECOY_RECOVERY, 4, 5)
	_play_blink_trail(start, global_position)

## The held direction, else straight back.
func _step_direction() -> Vector2:
	if is_human:
		var held := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
		if held.length() > 0.2:
			return held.normalized()
	return Vector2(-facing, 0.0)

func _decoy_swap() -> void:
	decoy_swaps_left -= 1
	decoy_swap_ready = decoy_swaps_left > 0
	var mine := global_position
	global_position = decoy.global_position
	decoy.global_position = mine
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	skill_dash_timer = 0.0
	_end_skill_dash()
	attack_lock_timer = maxf(attack_lock_timer, 0.08)
	_play_blink_trail(mine, global_position)

## A foe hit the decoy (RioDecoy): it bursts and knocks whoever stands at it up.
func decoy_burst(copy: Node2D) -> void:
	count_move("decoy_burst")
	if copy == decoy:
		decoy = null
		decoy_swaps_left = 0
		decoy_swap_ready = false
	var at: Vector2 = copy.global_position + GAME_SCALE.BODY_CENTRE
	if VFX.spawn(get_parent(), "rio_rune_burst", at, Vector2.ONE * 0.6, false, 4) == null:
		_play_ring(at, RUNE_COLOR)
	# A swing reports its hit from inside the physics step, where a new attack area cannot be set
	# up (engine errors, 2026-11-24): the burst's own hit comes right after it.
	_burst_decoy_at.call_deferred(at)

func _burst_decoy_at(at: Vector2) -> void:
	if is_defeated or not is_inside_tree():
		return
	attack_art_enabled = false
	_spawn_attack(DECOY_BURST_SIZE, _offset_to(at), DECOY_BURST_DAMAGE, DECOY_BURST_KNOCKBACK, Vector2(0, -1), RUNE_COLOR, 0.12)
	# The burst is where the decoy stood, not a swing of his (HitContext; Riposte).
	last_attack.set_meta("ranged", true)
	attack_art_enabled = true

func _clear_decoy() -> void:
	if is_instance_valid(decoy):
		decoy.queue_free()
	decoy = null
	decoy_swaps_left = 0
	decoy_swap_ready = false

# --- I: gem sword flurry ---

func _flurry_start() -> void:
	_reset_combo()
	_clear_flurry()
	attack_lock_timer = 0.3
	# The cast pose plays at the row's adopted speed (D39): the strike drawing at OVERDRIVE_POSE_STRIKE.
	_play_move_sprite_pose(&"infinity_overdrive", -1, -1, OVERDRIVE_POSE_STRIKE + 0.121, -1, -1, OVERDRIVE_POSE_STRIKE)
	_play_attack_windup()
	flurry_circle = VFX.spawn(self, "rio_ult_circle", Vector2(0, -36), Vector2.ONE * 0.85 * GAME_SCALE.COMBAT, true, -1, Color.WHITE, true)
	flurry_phase = Flurry.THROWING
	var targets := _flurry_targets()
	for index in FLURRY_SWORDS:
		# A foe can be freed between two throws (a monster that dies): the swords left go to the
		# foes still there. Handing a freed one on was a script error that stopped the cast (soak
		# seed 2002, 2026-11-25).
		var standing: Array[Node2D] = []
		for foe in targets:
			if is_instance_valid(foe):
				standing.append(foe)
		targets = standing
		var target: Node2D = targets[index % targets.size()] if not targets.is_empty() else null
		_throw_gem_sword(index, target)
		if index == FLURRY_SWORDS - 1:
			break
		if not await _wait_action(FLURRY_FIRE_GAP):
			_clear_flurry()
			return
		if flurry_phase != Flurry.THROWING:
			return
	_flurry_thrown()

func _flurry_thrown() -> void:
	flurry_phase = Flurry.WAITING
	flurry_timer = FLURRY_WAIT
	flurry_bot_timer = FLURRY_BOT_DELAY
	if is_instance_valid(flurry_circle):
		flurry_circle.queue_free()
	flurry_circle = null

## Foes within reach, nearest first.
func _flurry_targets() -> Array[Node2D]:
	var centre := global_position + GAME_SCALE.BODY_CENTRE
	var found: Array[Node2D] = []
	for foe in _foes():
		if (foe.global_position + GAME_SCALE.BODY_CENTRE).distance_to(centre) <= FLURRY_RANGE * GAME_SCALE.COMBAT:
			found.append(foe)
	found.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.distance_to(centre) < b.global_position.distance_to(centre))
	return found

func _throw_gem_sword(index: int, target: Node2D) -> void:
	var from := global_position + Vector2(0, -36) + Vector2.RIGHT.rotated(TAU * index / float(FLURRY_SWORDS)) * OVERDRIVE_RADIUS * GAME_SCALE.COMBAT
	var aim := Vector2(facing, 0.0).rotated(-0.3 + 0.12 * index)
	if is_instance_valid(target):
		aim = (target.global_position + GAME_SCALE.BODY_CENTRE - from).normalized()
	var color := GEM_COLORS[index % GEM_COLORS.size()]
	var sword := _make_sword(aim, Vector2(28, 28), FLURRY_STICK_DAMAGE, 0.0, FLURRY_SWORD_SPEED, FLURRY_SWORD_FLIGHT, color)
	sword.global_position = from
	# The flurry's own timer decides; the swords wait past it.
	sword.wait_time = FLURRY_WAIT + 1.0
	sword.homing_target = target
	flurry_swords.append(sword)

func _update_flurry_wait(delta: float) -> void:
	if flurry_phase != Flurry.WAITING:
		return
	flurry_timer -= delta
	if not is_human:
		flurry_bot_timer -= delta
		if flurry_bot_timer <= 0.0 and hitstun_timer <= 0.0 and _stuck_flurry_swords() > 0:
			_start_flurry()
			ultimate_followup_started = true
			count_move("i2")
			return
	if flurry_timer <= 0.0:
		_burst_flurry_swords()

func _stuck_flurry_swords() -> int:
	var count := 0
	for sword in flurry_swords:
		if is_instance_valid(sword) and sword.has_target():
			count += 1
	return count

## Blinks behind each struck foe in the order the swords flew and cuts (invulnerable meanwhile),
## then returns to where he pressed I.
func _start_flurry() -> void:
	flurry_phase = Flurry.CUTTING
	ultimate_window_timer = ultimate_window
	var start := global_position
	var cuts: Array[Node2D] = []
	for sword in flurry_swords:
		if not is_instance_valid(sword):
			continue
		if sword.has_target():
			cuts.append(sword)
		else:
			sword.expire()
	flurry_swords.clear()
	attack_lock_timer = FLURRY_GAP * cuts.size() + 0.2
	for index in cuts.size():
		var sword := cuts[index]
		if not is_instance_valid(sword) or not sword.has_target():
			continue
		var target: Node2D = sword.stuck_body
		var from := global_position
		_blink_to(_behind(target), false)
		_face(target)
		_freeze_movement(FLURRY_GAP)
		var last := index == cuts.size() - 1
		_play_move_sprite_pose(&"mana_combo", -1, -1, FLURRY_GAP, 4 if index % 2 == 0 else 2, 5 if index % 2 == 0 else 3)
		_spawn_sweeping_attack(Vector2(56, 48), [
			Vector2(8 * facing, -46),
			Vector2(46 * facing, -34),
			Vector2(84 * facing, -20)
		], FLURRY_LAST_DAMAGE if last else FLURRY_SLASH_DAMAGE, FLURRY_LAST_KNOCKBACK if last else FLURRY_SLASH_KNOCKBACK, Vector2(facing, -0.3 if last else -0.12), Color(sword.tint, 0.75), 0.08)
		VFX.spawn(get_parent(), "rio_ult_impact", target.global_position + GAME_SCALE.BODY_CENTRE, Vector2.ONE * 1.4 * GAME_SCALE.COMBAT, false, 5, sword.tint.lightened(0.3))
		_play_blink_trail(from, global_position)
		sword.queue_free()
		if not await _wait_action(FLURRY_GAP):
			# Cut short. Held or stunned, the flurry is still his and he returns to where he pressed I.
			# Moved meanwhile (a collapse, a respawn, practice mode's R: each clears the flurry), he
			# stays where he was put: going back took him into the realm that fell (2026-11-26).
			if flurry_phase == Flurry.CUTTING:
				_end_flurry(start)
			return
	_end_flurry(start)

func _end_flurry(start: Vector2) -> void:
	var from := global_position
	global_position = start
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	movement_freeze_timer = 0.0
	flurry_phase = Flurry.NONE
	attack_lock_timer = 0.15
	if from.distance_to(start) > 1.0:
		_play_blink_trail(from, start)

## The second I never came: each stuck sword bursts on its foe.
func _burst_flurry_swords() -> void:
	for sword in flurry_swords:
		if not is_instance_valid(sword):
			continue
		if sword.has_target():
			var target: Node2D = sword.stuck_body
			var away := signf(target.global_position.x - global_position.x)
			target.apply_hit(self, FLURRY_BURST_DAMAGE, 200.0, Vector2(away if away != 0.0 else float(facing), -0.4))
			VFX.spawn(get_parent(), "rio_ult_impact", sword.global_position, Vector2.ONE * 1.4 * GAME_SCALE.COMBAT, false, 5, sword.tint.lightened(0.3))
		sword.expire()
	flurry_swords.clear()
	flurry_phase = Flurry.NONE

func _clear_flurry() -> void:
	if is_instance_valid(flurry_circle):
		flurry_circle.queue_free()
	flurry_circle = null
	for sword in flurry_swords:
		if is_instance_valid(sword):
			sword.expire()
	flurry_swords.clear()
	flurry_phase = Flurry.NONE

# --- Shared helpers ---

## Where he stands behind `target`: past its centre on the side it does not face.
func _behind(target: Node2D) -> Vector2:
	var faced = target.get("facing")
	var looks := float(faced) if faced != null and float(faced) != 0.0 else signf(global_position.x - target.global_position.x)
	if looks == 0.0:
		looks = float(-facing)
	return target.global_position + Vector2(-looks * BEHIND_OFFSET * GAME_SCALE.COMBAT, 0.0)

func _face(target: Node2D) -> void:
	var side := target.global_position.x - global_position.x
	if absf(side) > 0.5:
		facing = 1 if side > 0.0 else -1

## Moves him to `spot` at once; `limited` stops him at solid ground on the way.
func _blink_to(spot: Vector2, limited: bool) -> void:
	var start := global_position
	var travel := spot - start
	if limited:
		var collision := move_and_collide(travel, true)
		if collision != null:
			travel = collision.get_travel()
	global_position = start + travel

## Fighters (not him) and monsters in his realm that are still up.
func _foes() -> Array[Node2D]:
	var found: Array[Node2D] = []
	for group in ["players", "realm_monsters"]:
		for target in get_tree().get_nodes_in_group(group):
			if target == self or not target is Node2D or target.get("is_defeated") == true:
				continue
			if target.has_method("is_down") and target.is_down():
				continue
			var realm = target.get("realm_index")
			if realm != null and int(realm) != realm_index:
				continue
			found.append(target)
	return found

## The attack offset (before GameScale.COMBAT) that puts a hit at the world point `at`.
func _offset_to(at: Vector2) -> Vector2:
	return GAME_SCALE.BODY_CENTRE + (at - global_position - GAME_SCALE.BODY_CENTRE) / GAME_SCALE.COMBAT

func _play_ring(at: Vector2, color: Color) -> void:
	var ring := Line2D.new()
	ring.width = 4.0
	ring.closed = true
	ring.default_color = color
	ring.z_index = 4
	for corner in 6:
		var angle := TAU * corner / 6.0 + PI / 6.0
		ring.add_point(Vector2(cos(angle), sin(angle)) * 40.0 * GAME_SCALE.COMBAT)
	get_parent().add_child(ring)
	ring.global_position = at
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector2(2.4, 2.4), 0.16)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.16)
	tween.tween_callback(ring.queue_free)

func _play_blink_trail(from: Vector2, to: Vector2) -> void:
	var delta := to - from
	if delta.length() < 1.0:
		return
	var art := VFX.spawn(get_parent(), "rio_blink_trail", (from + to) * 0.5 + Vector2(0, -34), Vector2(delta.length() / 238.0, 1.0), false, 2)
	if art != null:
		art.rotation = delta.angle()
		return
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
