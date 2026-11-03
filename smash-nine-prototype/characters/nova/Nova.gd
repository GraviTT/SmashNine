extends "res://characters/common/PlayerBase.gd"

const ANIMATION := preload("res://characters/common/CharacterAnimation.gd")
const GRAVITY_BURST_SCRIPT := preload("res://characters/nova/NovaGravityBurst.gd")
const VFX := preload("res://scripts/Vfx.gd")
const BODY_HITBOX_SCRIPT := preload("res://characters/nova/NovaBodyHitbox.gd")
const ORB_SCRIPT := preload("res://characters/nova/NovaOrb.gd")
const BEAM_SCRIPT := preload("res://characters/nova/NovaBeam.gd")
const FIELD_SCRIPT := preload("res://characters/nova/NovaField.gd")

## The kit (user 2026-11-03, D47; the user's concept and the lead's filled gaps are in
## reports/nova-rio-concepts-2026-11-03/nova-user-concept-review.md). Play style: enemy and
## gravity control (D46). Her stacking hits add gravity stacks (passive "중력 중첩",
## PlayerBase.add_gravity_stack): the J chain's last hit, the orb, the beam, the ultimate's launch
## and its sphere. The momentum passive is gone: strikes use what was the middle of its scale.
const STRIKE_POWER := 0.5
const STRIKE_COLOR := Color(0.62, 0.76, 1.0, 0.64)
const COMBO_RESET_TIME := 0.46
## K "중력 구체" (Gravity Orb): flies where she aims (ahead when nothing is held) and bursts on the
## first body or at its range; whoever the burst reaches is pulled to its centre for
## ORB_PULL_TIME, then gets a stack.
const ORB_STARTUP := 0.12
const ORB_RECOVERY := 0.22
const ORB_SIZE := Vector2(30, 30)
const ORB_SPEED := 520.0
const ORB_LIFETIME := 0.5
const ORB_BURST_RADIUS := 90.0
const ORB_DAMAGE := 8.0
const ORB_PULL_TIME := 0.35
const ORB_PULL_SPEED := 760.0
## L "중력 필드" (Gravity Field): FIELD_RADIUS where she casts it, for FIELD_TIME. Inside she
## flies with W/A/S/D in eight directions (W is also the jump, so the field has no jump), other
## fighters move as at stage 1 (no stack) and neutral monsters float helpless (NovaField).
const FIELD_STARTUP := 0.14
const FIELD_RECOVERY := 0.2
const FIELD_RADIUS := 200.0
const FIELD_TIME := 6.0
const FIELD_COOLDOWN := 12.0
const FIELD_FLY_SPEED := 470.0
const FIELD_FLY_ACCEL := 3200.0
## U "중력 광선" (Gravity Beam): where she aims; the first body it reaches is dragged to just in
## front of her (a short daze on arrival), then gets a stack. A body in the air is slammed down
## instead, with more damage.
const BEAM_STARTUP := 0.1
const BEAM_RECOVERY := 0.24
const BEAM_SIZE := Vector2(26, 18)
const BEAM_SPEED := 1150.0
const BEAM_LIFETIME := 0.36
const BEAM_DAMAGE := 5.0
const BEAM_SLAM_DAMAGE := 11.0
const BEAM_SLAM_SPEED := 1000.0
const BEAM_SLAM_HITSTUN := 0.45
const BEAM_PULL_SPEED := 1100.0
const BEAM_PULL_TIME := 0.45
const BEAM_HOLD_OFFSET := 46.0
const BEAM_ARRIVAL_DAZE := 0.3
## I "사건의 지평선" (Event Horizon): a big sphere above her head; fighters and monsters within
## ULTIMATE_CATCH_RADIUS of it circle it for up to ULTIMATE_SPHERE_TIME. I again, held: she circles
## it too; letting go shoots her off the way she holds (along the orbit when nothing is held),
## hurting and stacking whoever she meets. Then (or when its time runs out, or when she is hit
## while circling) the sphere drops to the floor below (at most ULTIMATE_FALL_TIME) and bursts on
## everyone it carried: damage and a stack. Bots press I again instead of letting go (EnemyAI).
const SLINGSHOT_POSE_STRIKE := 0.22
const ULTIMATE_NONE := 0
const ULTIMATE_SPHERE := 1
const ULTIMATE_ORBIT := 2
const ULTIMATE_LAUNCH := 3
const ULTIMATE_SPHERE_HEIGHT := 150.0
const ULTIMATE_SPHERE_TIME := 3.0
const ULTIMATE_CATCH_RADIUS := 230.0
const ULTIMATE_FOE_ORBIT := 75.0
const ULTIMATE_FOE_SPIN := 3.2
const ULTIMATE_MIN_ORBIT_RADIUS := 60.0
const ULTIMATE_MAX_ORBIT_RADIUS := 200.0
const ULTIMATE_ORBIT_SPEED := 900.0
const ULTIMATE_LAUNCH_SPEED := 1150.0 * GAME_SCALE.WORLD
const ULTIMATE_LAUNCH_DURATION := 0.4
const ULTIMATE_LAUNCH_DAMAGE := 14.0
const ULTIMATE_LAUNCH_KNOCKBACK := 520.0
const ULTIMATE_FALL_ACCEL := 2600.0
const ULTIMATE_FALL_MAX_SPEED := 1100.0
const ULTIMATE_FALL_TIME := 1.0
## The sphere's burst (bots read the radius to aim the launch away from it).
const ULTIMATE_COLLAPSE_RADIUS := 120.0
const ULTIMATE_COLLAPSE_DAMAGE := 16.0
const ULTIMATE_COLLAPSE_KNOCKBACK := 600.0
## Redrawn 2026-10-14 for both bodies (D33-D37): every motion is 6 frames with its old length
## (fps x 6 / old frames), the idle at 6.3 fps (D37). The base `attack` row is only a fallback.
const SHEET_ROWS := [["idle", 6, 6.3, true], ["walk", 8, 13.3, true], ["jump", 1, 1.0, false], ["fall", 1, 1.0, false], ["attack", 6, 35.25, false], ["shield", 6, 12.0, false], ["hurt", 1, 1.0, false]]
## 192-px cells (D34). `tumble` is new for Nova: strong launches play it instead of the hurt frame.
## The new skills borrow rows until theirs are drawn: the orb `gravity_brake`, the field
## `slingshot_start`, the beam `vector_side` 5-6, the J chain `vector_side` two drawings a hit.
const MOVE_SHEET_ROWS := [
	["vector_side", 6, 35.25, false],
	["vector_upper", 6, 33.0, false],
	["compression_stomp", 6, 26.1, false],
	["air_side", 6, 40.0, false],
	["meteor_kick", 6, 30.0, false],
	["vector_shift", 6, 27.3, false],
	["gravity_brake", 6, 14.3, false],
	["slingshot_start", 6, 14.0, false],
	["tumble", 6, 21.0, true],
]

var combo_step := 0
var combo_timer := 0.0
var meteor_diving := false
var field: Node2D
var field_cooldown_timer := 0.0
var orb_pull_targets: Array[Node] = []
var orb_pull_centre := Vector2.ZERO
var orb_pull_timer := 0.0
var beam_target: Node
var beam_pull_timer := 0.0
var beam_wrap: Node2D

var ultimate_phase := ULTIMATE_NONE
## The sphere's centre (a world point; bots aim from it).
var ultimate_center := Vector2.ZERO
var ultimate_elapsed := 0.0
var ultimate_orbit_sign := 1.0
var ultimate_orbit_radius := ULTIMATE_MIN_ORBIT_RADIUS
var ultimate_launch_direction := Vector2.RIGHT
var ultimate_saved_collision_mask := 0
var sphere_active := false
var sphere_timer := 0.0
var sphere_falling := false
var sphere_fall_speed := 0.0
var sphere_fall_elapsed := 0.0
var sphere_caught: Array[Node] = []
var sphere_angles: Dictionary = {}
var singularity_visual: Node2D
var ultimate_body_hitbox: Node
var ultimate_launch_preview: Node2D
var ultimate_preview_line: Line2D
var ultimate_preview_target: Line2D

## Original sheet only (third-party prototype art removed 2026-10-07, user).
func configure_character_sprite() -> void:
	_configure_original_sheet("nova")

func get_move_sheet_rows() -> Array:
	return MOVE_SHEET_ROWS

func get_sheet_rows() -> Array:
	return SHEET_ROWS

func perform_basic_attack(attack_type: String, input_direction: Vector2) -> void:
	match attack_type:
		"up", "air_up":
			_reset_combo()
			_start_attack(0.087, 0.19 if attack_type == "up" else 0.17, Callable(self, "_vector_uppercut").bind(attack_type == "air_up"), Vector2i(-1, -1), &"vector_upper")
		"down":
			_reset_combo()
			_start_attack(0.102, 0.23, Callable(self, "_compression_stomp"), Vector2i(-1, -1), &"compression_stomp")
		"air_down":
			_reset_combo()
			_start_attack(0.089, 0.2, Callable(self, "_meteor_kick_start"), Vector2i(-1, -1), &"meteor_kick")
		"air_side":
			_reset_combo()
			_start_attack(0.077, 0.15, Callable(self, "_vector_side_strike").bind(true, input_direction), Vector2i(-1, -1), &"air_side")
		_:
			# The chain: two drawings of the vector_side row a hit; the third adds a stack.
			match _consume_combo_step():
				0:
					_start_attack(0.07, 0.15, Callable(self, "_chain_strike").bind(0), Vector2i(-1, -1), &"vector_side", Vector2i(0, 1))
				1:
					_start_attack(0.07, 0.16, Callable(self, "_chain_strike").bind(1), Vector2i(-1, -1), &"vector_side", Vector2i(2, 3))
				_:
					_start_attack(0.09, 0.24, Callable(self, "_chain_strike").bind(2), Vector2i(-1, -1), &"vector_side", Vector2i(4, 5))

func perform_skill_one() -> void:
	_reset_combo()
	_start_attack(ORB_STARTUP, ORB_RECOVERY, Callable(self, "_fire_orb"), Vector2i(-1, -1), &"gravity_brake")

func perform_skill_two() -> void:
	if field_cooldown_timer > 0.0:
		return
	_reset_combo()
	_start_attack(FIELD_STARTUP, FIELD_RECOVERY, Callable(self, "_cast_field"), Vector2i(-1, -1), &"slingshot_start")

func has_skill_three() -> bool:
	return true

func perform_skill_three() -> void:
	_reset_combo()
	_start_attack(BEAM_STARTUP, BEAM_RECOVERY, Callable(self, "_fire_beam"), Vector2i(-1, -1), &"vector_side", Vector2i(4, 5))

func skill_cooldown(slot: String) -> Vector2:
	if slot == "l":
		return Vector2(field_cooldown_timer, FIELD_COOLDOWN)
	return super(slot)

func perform_ultimate() -> void:
	_sphere_start()

func try_ultimate_followup() -> bool:
	if ultimate_phase == ULTIMATE_SPHERE:
		_begin_ultimate_orbit()
		ultimate_followup_started = true
		return true
	if ultimate_phase == ULTIMATE_ORBIT:
		# A bot (or a test) presses again to let go; a player lets go of the key.
		_begin_ultimate_launch(_get_ultimate_tangent())
		return true
	return ultimate_phase != ULTIMATE_NONE

func character_physics_process(delta: float) -> void:
	combo_timer = maxf(combo_timer - delta, 0.0)
	if combo_timer <= 0.0:
		combo_step = 0
	field_cooldown_timer = maxf(field_cooldown_timer - delta, 0.0)
	if meteor_diving:
		velocity.y = minf(velocity.y + 2600.0 * GAME_SCALE.JUMP_SPEED * delta, 1120.0 * GAME_SCALE.JUMP_SPEED)
	_update_orb_pull(delta)
	_update_beam_pull(delta)
	_update_ultimate(delta)
	_update_sphere(delta)

func character_landing_state() -> void:
	if meteor_diving and is_on_floor():
		meteor_diving = false
		var radius := lerpf(68.0, 98.0, STRIKE_POWER)
		_spawn_gravity_burst(radius, lerpf(9.0, 14.0, STRIKE_POWER), lerpf(350.0, 610.0, STRIKE_POWER), STRIKE_POWER, Color(0.26, 0.9, 1.0, 0.56), "meteor")
		_play_impact_flash(global_position + Vector2(0, -8), radius, Color(0.36, 0.95, 1.0, 0.78))

## Hit while circling or launching: she stops and the sphere drops on whoever it holds.
func character_on_hit() -> void:
	meteor_diving = false
	_reset_combo()
	beam_target = null
	beam_pull_timer = 0.0
	_clear_beam_wrap()
	if ultimate_phase == ULTIMATE_ORBIT or ultimate_phase == ULTIMATE_LAUNCH:
		_stop_ultimate_motion()
		_drop_sphere()

func character_on_respawn() -> void:
	_reset_nova_state()

func character_cleanup() -> void:
	_reset_nova_state()

func character_on_attack_hit_body(body: Node, attack: Node) -> void:
	if attack.has_meta("nova_gravity"):
		_stack(body)

## A body the ultimate's launch hit (NovaBodyHitbox).
func on_nova_body_hit(body: Node) -> void:
	if ultimate_phase == ULTIMATE_LAUNCH:
		_stack(body)

## In her own field she flies: no gravity, no jump, W/A/S/D in eight directions.
func apply_character_gravity(delta: float) -> bool:
	if not _in_own_field():
		return false
	var wanted := _flight_input() * FIELD_FLY_SPEED * GAME_SCALE.MOVE
	velocity = velocity.move_toward(wanted, FIELD_FLY_ACCEL * GAME_SCALE.MOVE * delta)
	if absf(wanted.x) > 1.0:
		facing = 1 if wanted.x > 0.0 else -1
	jump_buffer_timer = 0.0
	return true

func get_nova_impact_direction() -> Vector2:
	if ultimate_phase == ULTIMATE_LAUNCH:
		return ultimate_launch_direction
	if velocity.length() > 0.01:
		return velocity.normalized()
	return Vector2(facing, -0.05).normalized()

# --- J ---

func _chain_strike(step: int) -> void:
	var direction := Vector2(facing, -0.04 if step < 2 else -0.3).normalized()
	var travel: float = [70.0, 80.0, 104.0][step]
	var size: Vector2 = [Vector2(40, 32), Vector2(42, 34), Vector2(48, 38)][step]
	velocity.x += facing * [70.0, 90.0, 110.0][step]
	attack_art_enabled = false
	_spawn_sweeping_attack(size, [
		Vector2(0, -32) + Vector2(facing, 0) * 10.0,
		Vector2(0, -32) + Vector2(facing, 0) * travel * 0.55,
		Vector2(0, -32) + Vector2(facing, 0) * travel
	], [6.0, 7.0, 9.0][step], [200.0, 230.0, 400.0][step], direction, STRIKE_COLOR, [0.08, 0.085, 0.1][step])
	attack_art_enabled = true
	if step < 2:
		# On hit the next hit starts at once and lands inside the hitstun.
		last_attack.set_meta("chain_cancel", 0.0)
	else:
		last_attack.set_meta("nova_gravity", true)
	_play_vector_flash(Vector2(facing, 0), travel, 0.3 + 0.2 * step)

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

func _vector_side_strike(airborne: bool, travel_direction: Vector2) -> void:
	var direction := travel_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2(facing, 0.0)
	if absf(direction.x) > 0.16:
		facing = signi(int(direction.x))
	var travel := lerpf(76.0, 138.0, STRIKE_POWER)
	velocity += direction * lerpf(65.0, 165.0, STRIKE_POWER)
	if airborne:
		velocity.y *= 0.82
	# The vector streak is this strike's own effect; the shared slash doubled it into one white
	# blot (sprite audit 2026-10-16, CODEX-QA-19 B5).
	attack_art_enabled = false
	_spawn_sweeping_attack(Vector2(lerpf(38.0, 54.0, STRIKE_POWER), lerpf(30.0, 42.0, STRIKE_POWER)), [
		Vector2(0, -32) + direction * 10.0,
		Vector2(0, -32) + direction * travel * 0.55,
		Vector2(0, -32) + direction * travel
	], lerpf(7.0, 11.0, STRIKE_POWER), lerpf(235.0, 510.0, STRIKE_POWER), direction, STRIKE_COLOR, lerpf(0.075, 0.12, STRIKE_POWER))
	attack_art_enabled = true
	_play_vector_flash(direction, travel, STRIKE_POWER)

func _vector_uppercut(airborne: bool) -> void:
	var rise_speed := lerpf(-390.0, -570.0, STRIKE_POWER)
	if airborne:
		rise_speed *= 0.88
	velocity.y = minf(velocity.y, rise_speed * GAME_SCALE.JUMP_SPEED)
	velocity.x += facing * lerpf(35.0, 85.0, STRIKE_POWER)
	var launch_velocity := Vector2(facing * lerpf(55.0, 105.0, STRIKE_POWER), lerpf(-470.0, -720.0, STRIKE_POWER))
	# The impact star marks this launcher; no shared slash under it (CODEX-QA-19 B5).
	attack_art_enabled = false
	_spawn_sweeping_launch_attack(Vector2(lerpf(38.0, 48.0, STRIKE_POWER), lerpf(48.0, 62.0, STRIKE_POWER)), [
		Vector2(10 * facing, -26),
		Vector2(26 * facing, -70),
		Vector2(38 * facing, lerpf(-108.0, -138.0, STRIKE_POWER))
	], lerpf(7.0, 11.0, STRIKE_POWER), lerpf(300.0, 510.0, STRIKE_POWER), Vector2(0.12 * facing, -1), STRIKE_COLOR, 0.11, launch_velocity, lerpf(0.22, 0.32, STRIKE_POWER))
	attack_art_enabled = true
	_play_impact_flash(global_position + GAME_SCALE.attack_point(Vector2(36 * facing, -112)), lerpf(28.0, 42.0, STRIKE_POWER), STRIKE_COLOR)

func _compression_stomp() -> void:
	velocity.x *= 0.55
	var radius := lerpf(48.0, 72.0, STRIKE_POWER)
	_spawn_gravity_burst(radius, lerpf(7.0, 11.0, STRIKE_POWER), lerpf(260.0, 480.0, STRIKE_POWER), STRIKE_POWER, Color(0.3, 0.88, 1.0, 0.5), "stomp")
	_play_impact_flash(global_position + Vector2(0, -10), radius, Color(0.38, 0.94, 1.0, 0.72))

func _meteor_kick_start() -> void:
	meteor_diving = true
	action_locked_until_land = true
	velocity.x += facing * lerpf(45.0, 110.0, STRIKE_POWER)
	velocity.y = maxf(velocity.y, lerpf(560.0, 760.0, STRIKE_POWER) * GAME_SCALE.JUMP_SPEED)
	_spawn_sweeping_attack(Vector2(40, 46), [
		Vector2(0, -24),
		Vector2(12 * facing, 24),
		Vector2(24 * facing, 72)
	], lerpf(6.0, 9.0, STRIKE_POWER), lerpf(270.0, 430.0, STRIKE_POWER), Vector2(0.12 * facing, 1), STRIKE_COLOR, 0.12)

# --- K: gravity orb ---

func _fire_orb() -> void:
	var aim := _get_attack_direction()
	var orb := _make_shot(ORB_SCRIPT)
	orb.global_position = global_position + GAME_SCALE.BODY_CENTRE + aim * 30.0 * GAME_SCALE.COMBAT
	orb.configure(self, ORB_SIZE * GAME_SCALE.COMBAT, 0.0, 0.0, aim, Color(0.5, 0.3, 0.9, 0.85), ORB_SPEED * GAME_SCALE.COMBAT, ORB_LIFETIME)
	orb.dress(ORB_SIZE.x * GAME_SCALE.COMBAT * 0.5)

## The orb's burst at `at` (NovaOrb): it hurts and starts the pull.
func orb_burst_at(at: Vector2) -> void:
	if is_defeated or not is_instance_valid(get_parent()):
		return
	var radius := ORB_BURST_RADIUS * GAME_SCALE.COMBAT
	if VFX.spawn(get_parent(), "nova_gravity_burst", at, Vector2.ONE * (radius * 2.0 / 232.0), false, 6, Color(0.86, 0.72, 1.0, 0.9)) == null:
		_play_impact_flash(at, ORB_BURST_RADIUS, Color(0.6, 0.4, 1.0, 0.7))
	orb_pull_targets.clear()
	for target in _foes_near(at, radius):
		var inward: Vector2 = (at - (target as Node2D).global_position).normalized()
		if target.apply_hit(self, ORB_DAMAGE, 60.0, inward) != false:
			orb_pull_targets.append(target)
	orb_pull_centre = at
	orb_pull_timer = ORB_PULL_TIME if not orb_pull_targets.is_empty() else 0.0

func _update_orb_pull(delta: float) -> void:
	if orb_pull_timer <= 0.0:
		return
	orb_pull_timer = maxf(orb_pull_timer - delta, 0.0)
	for target in orb_pull_targets:
		if is_instance_valid(target) and target.get("is_defeated") != true:
			_drag(target, orb_pull_centre - GAME_SCALE.BODY_CENTRE, ORB_PULL_SPEED, delta)
	if orb_pull_timer <= 0.0:
		for target in orb_pull_targets:
			_stack(target)
		orb_pull_targets.clear()

# --- L: gravity field ---

func _cast_field() -> void:
	_clear_field()
	field_cooldown_timer = FIELD_COOLDOWN
	field = Node2D.new()
	field.set_script(FIELD_SCRIPT)
	field.name = "NovaField"
	field.z_index = -1
	get_parent().add_child(field)
	field.global_position = global_position + GAME_SCALE.BODY_CENTRE
	field.configure(self, FIELD_RADIUS * GAME_SCALE.COMBAT, FIELD_TIME)
	_play_impact_flash(global_position + GAME_SCALE.BODY_CENTRE, 46.0, Color(0.6, 0.4, 1.0, 0.7))

func _in_own_field() -> bool:
	return is_instance_valid(field) and field.contains(global_position + GAME_SCALE.BODY_CENTRE)

## W/A/S/D for a player; a bot steers toward its aim.
func _flight_input() -> Vector2:
	if hitstun_timer > 0.0 or is_dummy:
		return Vector2.ZERO
	if is_human:
		var held := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
		return held.normalized() if held.length() > 0.2 else Vector2.ZERO
	var aim: Vector2 = ai_controller.aim_direction
	return Vector2(move_input, clampf(aim.y, -1.0, 1.0)).limit_length(1.0)

func _clear_field() -> void:
	if is_instance_valid(field):
		field.end_field()
	field = null

# --- U: gravity beam ---

func _fire_beam() -> void:
	var aim := _get_attack_direction()
	var beam := _make_shot(BEAM_SCRIPT)
	beam.global_position = global_position + GAME_SCALE.BODY_CENTRE + aim * 24.0 * GAME_SCALE.COMBAT
	beam.configure(self, BEAM_SIZE * GAME_SCALE.COMBAT, 0.0, 0.0, aim, Color(0.74, 0.5, 1.0, 0.8), BEAM_SPEED * GAME_SCALE.COMBAT, BEAM_LIFETIME)
	beam.dress()

## The body the beam reached (NovaBeam): slammed down from the air, else dragged to her.
func on_beam_hit(body: Node, direction: Vector2) -> void:
	if is_defeated or not is_instance_valid(body):
		return
	if _is_airborne(body):
		if body.has_method("end_gravity_float"):
			body.end_gravity_float()
		if body.apply_forced_launch_hit(self, BEAM_SLAM_DAMAGE, Vector2(0.0, BEAM_SLAM_SPEED), BEAM_SLAM_HITSTUN, 420.0, Vector2.DOWN) != false:
			_stack(body)
		_play_impact_flash((body as Node2D).global_position + GAME_SCALE.BODY_CENTRE, 34.0, Color(0.74, 0.5, 1.0, 0.8))
		return
	if body.apply_hit(self, BEAM_DAMAGE, 0.0, -direction) != false:
		beam_target = body
		beam_pull_timer = BEAM_PULL_TIME
		_start_beam_wrap(body as Node2D)

func _update_beam_pull(delta: float) -> void:
	if beam_pull_timer <= 0.0:
		return
	beam_pull_timer = maxf(beam_pull_timer - delta, 0.0)
	if not is_instance_valid(beam_target) or beam_target.get("is_defeated") == true:
		beam_target = null
		beam_pull_timer = 0.0
		_clear_beam_wrap()
		return
	var spot := global_position + Vector2(facing * BEAM_HOLD_OFFSET * GAME_SCALE.COMBAT, 0.0)
	var arrived := (beam_target as Node2D).global_position.distance_to(spot) < 30.0
	_drag(beam_target, spot, BEAM_PULL_SPEED, delta)
	_update_beam_wrap(beam_target as Node2D)
	if arrived or beam_pull_timer <= 0.0:
		_stack(beam_target)
		if beam_target.get("hitstun_timer") != null:
			beam_target.hitstun_timer = maxf(float(beam_target.hitstun_timer), BEAM_ARRIVAL_DAZE)
		beam_target = null
		beam_pull_timer = 0.0
		_clear_beam_wrap()

## The beam's tip split round the foe it drags (user 2026-11-03: "끝에서 갈라지며 적을 감싼 뒤"):
## the curved tendrils split open round the body, then bind it while the cord drags it in
## (CODEX-VFX-06 a, drawn with the cord coming from the left: mirrored when she is on the right).
## Four code claws stand in without the art.
func _start_beam_wrap(target: Node2D) -> void:
	_clear_beam_wrap()
	beam_wrap = Node2D.new()
	beam_wrap.name = "NovaBeamWrap"
	beam_wrap.z_index = 6
	get_parent().add_child(beam_wrap)
	var cord := BEAM_SCRIPT.make_cord()
	cord.name = "Cord"
	beam_wrap.add_child(cord)
	var claws := Node2D.new()
	claws.name = "Claws"
	beam_wrap.add_child(claws)
	var split := VFX.spawn(claws, "nova_beam_split", Vector2.ZERO, Vector2.ONE, false, 0, Color.WHITE, true)
	if split != null:
		claws.scale.x = -1.0 if global_position.x > target.global_position.x else 1.0
		split.animation_finished.connect(_bind_beam_wrap.bind(claws))
		_update_beam_wrap(target)
		return
	for index in 4:
		var claw := Line2D.new()
		var points := PackedVector2Array()
		var from := -PI * 0.85 + float(index) * PI * 0.5
		for step in 7:
			var angle := from + float(step) * PI * 0.35 / 6.0
			points.append(Vector2(cos(angle) * 30.0, sin(angle) * 46.0))
		claw.points = points
		claw.width = 4.0
		claw.default_color = Color(0.88, 0.76, 1.0, 0.95)
		claw.antialiased = true
		claws.add_child(claw)
	# The tip springs open, then closes on the body.
	claws.scale = Vector2.ONE * 1.8
	claws.modulate.a = 0.0
	var tween := claws.create_tween()
	tween.tween_property(claws, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(claws, "modulate:a", 1.0, 0.1)
	_update_beam_wrap(target)

## After the split the tendrils hold the body (looping) until the wrap is cleared.
func _bind_beam_wrap(claws: Node2D) -> void:
	if is_instance_valid(claws):
		VFX.spawn(claws, "nova_beam_bind", Vector2.ZERO, Vector2.ONE, true, 0, Color.WHITE, true)

func _update_beam_wrap(target: Node2D) -> void:
	if not is_instance_valid(beam_wrap) or not is_instance_valid(target):
		return
	beam_wrap.global_position = target.global_position + GAME_SCALE.BODY_CENTRE
	var hand := global_position + GAME_SCALE.BODY_CENTRE + Vector2(facing * 20.0, 0.0)
	(beam_wrap.get_node("Cord") as Line2D).points = PackedVector2Array([beam_wrap.to_local(hand), Vector2.ZERO])

func _clear_beam_wrap() -> void:
	if is_instance_valid(beam_wrap):
		beam_wrap.queue_free()
	beam_wrap = null

func _is_airborne(body: Node) -> bool:
	if body.has_method("is_floating") and body.is_floating():
		return true
	return body is CharacterBody2D and not (body as CharacterBody2D).is_on_floor()

# --- I: event horizon ---

func _sphere_start() -> void:
	_reset_combo()
	_end_sphere(false)
	ultimate_phase = ULTIMATE_SPHERE
	ultimate_center = global_position + GAME_SCALE.BODY_CENTRE + Vector2(0, -ULTIMATE_SPHERE_HEIGHT)
	ultimate_orbit_sign = 1.0 if facing >= 0 else -1.0
	ultimate_saved_collision_mask = collision_mask
	sphere_active = true
	sphere_timer = ULTIMATE_SPHERE_TIME
	sphere_falling = false
	attack_lock_timer = maxf(attack_lock_timer, 0.16)
	# The sphere appears at once; only the body's cast pose is longer, so its drawings play at the
	# row's adopted speed (D39): the strike drawing at SLINGSHOT_POSE_STRIKE.
	_play_move_sprite_pose(&"slingshot_start", -1, -1, SLINGSHOT_POSE_STRIKE + 0.107, -1, -1, SLINGSHOT_POSE_STRIKE)
	_create_singularity_visual()

func _begin_ultimate_orbit() -> void:
	meteor_diving = false
	ultimate_phase = ULTIMATE_ORBIT
	ultimate_elapsed = 0.0
	var offset := global_position + GAME_SCALE.BODY_CENTRE - ultimate_center
	ultimate_orbit_radius = clampf(offset.length(), ULTIMATE_MIN_ORBIT_RADIUS * GAME_SCALE.COMBAT, ULTIMATE_MAX_ORBIT_RADIUS * GAME_SCALE.COMBAT)
	if offset.length() > 0.01 and velocity.length() > 80.0:
		var clockwise := Vector2(-offset.normalized().y, offset.normalized().x)
		ultimate_orbit_sign = 1.0 if clockwise.dot(velocity.normalized()) >= 0.0 else -1.0
	collision_mask = 0
	_create_ultimate_launch_preview()
	_update_ultimate_launch_preview(_get_ultimate_tangent())

func _update_ultimate(delta: float) -> void:
	if ultimate_phase == ULTIMATE_ORBIT:
		ultimate_elapsed += delta
		attack_lock_timer = maxf(attack_lock_timer, 0.12)
		var offset := global_position + GAME_SCALE.BODY_CENTRE - ultimate_center
		if offset.length() < 10.0:
			offset = Vector2(-facing, 0.0) * ultimate_orbit_radius
		var radial := offset.normalized()
		var tangent := Vector2(-radial.y, radial.x) * ultimate_orbit_sign
		skill_dash_velocity = tangent * ULTIMATE_ORBIT_SPEED + radial * (ultimate_orbit_radius - offset.length()) * 10.0
		skill_dash_timer = 0.06
		_set_character_rotation(tangent.angle())
		var launch := _held_launch_direction(tangent)
		_update_ultimate_launch_preview(launch)
		if is_human and not Input.is_action_pressed("ultimate"):
			_begin_ultimate_launch(launch)
	elif ultimate_phase == ULTIMATE_LAUNCH:
		ultimate_elapsed += delta
		attack_lock_timer = maxf(attack_lock_timer, 0.12)
		skill_dash_velocity = ultimate_launch_direction * ULTIMATE_LAUNCH_SPEED
		skill_dash_timer = 0.06
		_set_character_rotation(ultimate_launch_direction.angle())
		var collided_with_world := ultimate_elapsed > 0.04 and get_slide_collision_count() > 0
		if collided_with_world or ultimate_elapsed >= ULTIMATE_LAUNCH_DURATION:
			_finish_ultimate_launch()

## The way a player holds (eight directions), or along the orbit.
func _held_launch_direction(tangent: Vector2) -> Vector2:
	if is_human:
		var held := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
		if held.length() > 0.2:
			return held.normalized()
	return tangent

func _begin_ultimate_launch(direction: Vector2) -> void:
	if ultimate_phase != ULTIMATE_ORBIT:
		return
	ultimate_phase = ULTIMATE_LAUNCH
	ultimate_elapsed = 0.0
	ultimate_launch_direction = direction.normalized() if direction.length() > 0.01 else Vector2(facing, 0.0)
	if absf(ultimate_launch_direction.x) > 0.18:
		facing = signi(int(signf(ultimate_launch_direction.x)))
	collision_mask = ultimate_saved_collision_mask
	_clear_ultimate_launch_preview()
	_spawn_ultimate_body_hitbox(42.0, ULTIMATE_LAUNCH_DAMAGE, ULTIMATE_LAUNCH_KNOCKBACK, ULTIMATE_LAUNCH_DURATION + 0.08, false, Color(0.62, 0.42, 1.0, 0.6))
	_play_launch_flash(ultimate_launch_direction)
	_drop_sphere()

func _finish_ultimate_launch() -> void:
	_stop_ultimate_motion()
	velocity = ultimate_launch_direction * 180.0
	attack_lock_timer = maxf(attack_lock_timer, 0.3)

## Her orbit or launch ends (the sphere carries on).
func _stop_ultimate_motion() -> void:
	ultimate_phase = ULTIMATE_NONE
	if ultimate_saved_collision_mask != 0:
		collision_mask = ultimate_saved_collision_mask
	skill_dash_timer = 0.0
	_end_skill_dash()
	_clear_ultimate_body_hitbox()
	_clear_ultimate_launch_preview()
	_reset_character_rotation()

func _update_sphere(delta: float) -> void:
	if not sphere_active:
		return
	if sphere_falling:
		sphere_fall_elapsed += delta
		sphere_fall_speed = minf(sphere_fall_speed + ULTIMATE_FALL_ACCEL * delta, ULTIMATE_FALL_MAX_SPEED)
		var step := sphere_fall_speed * delta
		var floor_point = _floor_below(ultimate_center, step + 24.0)
		if floor_point != null:
			ultimate_center = floor_point - Vector2(0, 24.0)
			_spin_caught(delta)
			_sphere_burst()
			return
		ultimate_center.y += step
		if sphere_fall_elapsed >= ULTIMATE_FALL_TIME:
			_spin_caught(delta)
			_sphere_burst()
			return
	else:
		sphere_timer = maxf(sphere_timer - delta, 0.0)
		_catch_into_sphere()
		if sphere_timer <= 0.0:
			_drop_sphere()
	_spin_caught(delta)
	if is_instance_valid(singularity_visual):
		singularity_visual.global_position = ultimate_center
		# The sphere art turns in its own frames; the stand-in core is spun here.
		if singularity_visual.get_node_or_null("Vfx_nova_sphere") == null:
			singularity_visual.rotation += delta * 4.5 * ultimate_orbit_sign

## Starts the sphere's fall (once): when she launches, when its time runs out, when she is hit
## while circling. Still circling then: she launches with it.
func _drop_sphere() -> void:
	if not sphere_active or sphere_falling:
		return
	sphere_falling = true
	sphere_fall_speed = 0.0
	sphere_fall_elapsed = 0.0
	if ultimate_phase == ULTIMATE_ORBIT:
		_begin_ultimate_launch(_held_launch_direction(_get_ultimate_tangent()))
	elif ultimate_phase == ULTIMATE_SPHERE:
		ultimate_phase = ULTIMATE_NONE

func _catch_into_sphere() -> void:
	for target in _foes_near(ultimate_center, ULTIMATE_CATCH_RADIUS * GAME_SCALE.COMBAT):
		if sphere_caught.has(target):
			continue
		if target.has_method("is_gravity_rooted") and target.is_gravity_rooted():
			continue
		var offset: Vector2 = (target as Node2D).global_position + GAME_SCALE.BODY_CENTRE - ultimate_center
		var angle := offset.angle() if offset.length() > 0.01 else 0.0
		var spot := ultimate_center + Vector2.RIGHT.rotated(angle) * ULTIMATE_FOE_ORBIT * GAME_SCALE.COMBAT - GAME_SCALE.BODY_CENTRE
		if target.has_method("apply_grab_hold"):
			if not target.apply_grab_hold(self, spot, 0.2):
				continue
		elif target.has_method("apply_gravity_hold"):
			target.apply_gravity_hold(spot, 0.2)
		sphere_caught.append(target)
		sphere_angles[target.get_instance_id()] = angle

## Swings everyone caught round the sphere (players pinned like Luna's grab, monsters held).
func _spin_caught(delta: float) -> void:
	for target in sphere_caught.duplicate():
		if not is_instance_valid(target) or target.get("is_defeated") == true:
			sphere_caught.erase(target)
			continue
		var key: int = target.get_instance_id()
		var angle: float = float(sphere_angles.get(key, 0.0)) + ULTIMATE_FOE_SPIN * ultimate_orbit_sign * delta
		sphere_angles[key] = angle
		var spot := ultimate_center + Vector2.RIGHT.rotated(angle) * ULTIMATE_FOE_ORBIT * GAME_SCALE.COMBAT - GAME_SCALE.BODY_CENTRE
		if target.has_method("apply_grab_hold"):
			target.movement_freeze_position = spot
			target.movement_freeze_timer = maxf(target.movement_freeze_timer, 0.05)
			target.hitstun_timer = maxf(target.hitstun_timer, 0.1)
		elif target.has_method("apply_gravity_hold"):
			target.apply_gravity_hold(spot, 0.05)

func _sphere_burst() -> void:
	var at := ultimate_center
	var radius := ULTIMATE_COLLAPSE_RADIUS * GAME_SCALE.COMBAT
	if is_instance_valid(get_parent()):
		VFX.spawn(get_parent(), "nova_ult_burst", at, Vector2.ONE * (radius * 2.2 / 256.0), false, 6, Color(0.82, 0.72, 1.0, VFX.ULTIMATE_FLASH_ALPHA))
	_play_impact_flash(at, ULTIMATE_COLLAPSE_RADIUS * 0.6, Color(0.62, 0.42, 1.0, 0.8))
	for target in sphere_caught:
		if not is_instance_valid(target) or target.get("is_defeated") == true:
			continue
		if target.get("movement_freeze_timer") != null:
			target.movement_freeze_timer = 0.0
		var outward: Vector2 = ((target as Node2D).global_position + GAME_SCALE.BODY_CENTRE - at).normalized()
		if outward == Vector2.ZERO:
			outward = Vector2.UP
		if target.apply_hit(self, ULTIMATE_COLLAPSE_DAMAGE, ULTIMATE_COLLAPSE_KNOCKBACK, (outward + Vector2.UP * 0.6).normalized()) != false:
			_stack(target)
	_end_sphere(false)

## Clears the sphere; `release` lets go of whoever it held without the burst.
func _end_sphere(release: bool) -> void:
	if release:
		for target in sphere_caught:
			if is_instance_valid(target) and target.get("movement_freeze_timer") != null:
				target.movement_freeze_timer = 0.0
	sphere_caught.clear()
	sphere_angles.clear()
	sphere_active = false
	sphere_falling = false
	_clear_singularity_visual()

## The first floor top straight below `from` within `distance`, or null.
func _floor_below(from: Vector2, distance: float) -> Variant:
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, distance), WORLD_LAYER)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else null

func _get_ultimate_tangent() -> Vector2:
	var offset := global_position + GAME_SCALE.BODY_CENTRE - ultimate_center
	if offset.length() < 0.01:
		offset = Vector2(-facing, 0.0)
	return Vector2(-offset.y, offset.x).normalized() * ultimate_orbit_sign

# --- Shared helpers ---

## Fighters (not her) and monsters in her realm whose body centre is within `radius` of `point`.
func _foes_near(point: Vector2, radius: float) -> Array[Node]:
	var found: Array[Node] = []
	for target in get_tree().get_nodes_in_group("players"):
		if target == self or target.is_defeated or target.realm_index != realm_index:
			continue
		if target.global_position.distance_to(point - GAME_SCALE.BODY_CENTRE) <= radius:
			found.append(target)
	for monster in get_tree().get_nodes_in_group("realm_monsters"):
		if int(monster.get("realm_index")) != realm_index or not monster.has_method("apply_hit"):
			continue
		if (monster as Node2D).global_position.distance_to(point) <= radius:
			found.append(monster)
	return found

## Moves a fighter (pulled) or a monster (held a step closer) toward `spot` this frame.
func _drag(target: Node, spot: Vector2, speed: float, delta: float) -> void:
	if target.has_method("apply_grab_pull"):
		target.apply_grab_pull(spot, speed)
	elif target.has_method("apply_gravity_hold"):
		target.apply_gravity_hold((target as Node2D).global_position.move_toward(spot, speed * delta), 0.05)

## A gravity stack on a fighter (monsters have none).
func _stack(target: Node) -> void:
	if is_instance_valid(target) and target.has_method("add_gravity_stack"):
		target.add_gravity_stack(self)

func _make_shot(script: Script) -> Area2D:
	var shot := Area2D.new()
	shot.set_script(script)
	shot.collision_layer = 0
	shot.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var visual := ColorRect.new()
	visual.name = "Visual"
	shot.add_child(shape)
	shot.add_child(visual)
	get_parent().add_child(shot)
	shot.set("art_scale_multiplier", GAME_SCALE.COMBAT)
	return shot

func _spawn_gravity_burst(radius: float, damage: float, knockback: float, momentum: float, color: Color, hit_tag: String) -> Area2D:
	var burst := Area2D.new()
	burst.set_script(GRAVITY_BURST_SCRIPT)
	burst.collision_layer = 0
	burst.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var visual := Polygon2D.new()
	visual.name = "Visual"
	burst.add_child(shape)
	burst.add_child(visual)
	get_parent().add_child(burst)
	burst.global_position = global_position + Vector2(0, -30)
	burst.configure(self, radius * GAME_SCALE.COMBAT, damage, knockback, momentum, color, hit_tag)
	return burst

func _spawn_ultimate_body_hitbox(radius: float, damage: float, knockback: float, lifetime: float, end_on_hit: bool, color: Color) -> void:
	_clear_ultimate_body_hitbox()
	var hitbox := Area2D.new()
	hitbox.set_script(BODY_HITBOX_SCRIPT)
	hitbox.collision_layer = 0
	hitbox.collision_mask = PLAYER_LAYER | MONSTER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var visual := Polygon2D.new()
	visual.name = "Visual"
	hitbox.add_child(shape)
	hitbox.add_child(visual)
	get_parent().add_child(hitbox)
	hitbox.global_position = global_position + Vector2(0, -32)
	hitbox.configure(self, radius * GAME_SCALE.COMBAT, damage, knockback, lifetime, color, end_on_hit)
	ultimate_body_hitbox = hitbox

func _clear_ultimate_body_hitbox() -> void:
	if is_instance_valid(ultimate_body_hitbox):
		ultimate_body_hitbox.queue_free()
	ultimate_body_hitbox = null

func _create_ultimate_launch_preview() -> void:
	_clear_ultimate_launch_preview()
	ultimate_launch_preview = Node2D.new()
	ultimate_launch_preview.name = "NovaLaunchPreview"
	ultimate_launch_preview.z_index = 5
	get_parent().add_child(ultimate_launch_preview)
	ultimate_preview_line = Line2D.new()
	ultimate_preview_line.name = "Trajectory"
	ultimate_preview_line.width = 4.0
	ultimate_preview_line.default_color = Color(0.82, 0.6, 1.0, 0.58)
	ultimate_preview_line.antialiased = true
	ultimate_launch_preview.add_child(ultimate_preview_line)
	ultimate_preview_target = Line2D.new()
	ultimate_preview_target.name = "Destination"
	ultimate_preview_target.points = _make_circle_points(18.0, 24)
	ultimate_preview_target.closed = true
	ultimate_preview_target.width = 4.5
	ultimate_preview_target.default_color = Color(0.86, 0.5, 1.0, 0.88)
	ultimate_preview_target.antialiased = true
	ultimate_launch_preview.add_child(ultimate_preview_target)

func _update_ultimate_launch_preview(direction: Vector2) -> void:
	if not is_instance_valid(ultimate_launch_preview) or direction == Vector2.ZERO:
		return
	var launch_distance := ULTIMATE_LAUNCH_SPEED * ULTIMATE_LAUNCH_DURATION
	ultimate_launch_preview.global_position = global_position + Vector2(0, -32)
	ultimate_preview_line.points = PackedVector2Array([Vector2.ZERO, direction * launch_distance])
	ultimate_preview_target.position = direction * launch_distance
	ultimate_preview_target.rotation += 0.08 * ultimate_orbit_sign

func _clear_ultimate_launch_preview() -> void:
	if is_instance_valid(ultimate_launch_preview):
		ultimate_launch_preview.queue_free()
	ultimate_launch_preview = null
	ultimate_preview_line = null
	ultimate_preview_target = null

## The sphere (CODEX-VFX-05 a: behind the fighters it swings, its own frames spin it); without
## it the ultimate's core art, big, with two rings, in front of them.
func _create_singularity_visual() -> void:
	_clear_singularity_visual()
	singularity_visual = Node2D.new()
	singularity_visual.name = "NovaSingularity"
	get_parent().add_child(singularity_visual)
	singularity_visual.global_position = ultimate_center
	if VFX.spawn(singularity_visual, "nova_sphere", Vector2.ZERO, Vector2.ONE, true, 0, Color.WHITE, true) != null:
		singularity_visual.z_index = -1
		return
	singularity_visual.z_index = 6
	var core_art := VFX.spawn(singularity_visual, "nova_ult_core", Vector2.ZERO, Vector2.ONE * 2.2, true, 0, Color.WHITE, true)
	var core := Polygon2D.new()
	core.visible = core_art == null
	core.polygon = _make_star_points(56.0, 34.0)
	core.color = Color(0.12, 0.06, 0.24, 0.94)
	singularity_visual.add_child(core)
	for index in 2:
		var ring := Line2D.new()
		ring.points = _make_circle_points(ULTIMATE_FOE_ORBIT * GAME_SCALE.COMBAT + index * 18.0, 32)
		ring.closed = true
		ring.width = 3.5 - index
		ring.default_color = Color(0.62 + index * 0.2, 0.5, 1.0, 0.6 - index * 0.16)
		ring.rotation = index * 0.45
		ring.antialiased = true
		singularity_visual.add_child(ring)

func _clear_singularity_visual() -> void:
	if is_instance_valid(singularity_visual):
		singularity_visual.queue_free()
	singularity_visual = null

func _reset_nova_state() -> void:
	meteor_diving = false
	_reset_combo()
	_stop_ultimate_motion()
	_end_sphere(true)
	_clear_field()
	field_cooldown_timer = 0.0
	orb_pull_targets.clear()
	orb_pull_timer = 0.0
	beam_target = null
	beam_pull_timer = 0.0
	_clear_beam_wrap()

func _play_vector_flash(direction: Vector2, length: float, power: float) -> void:
	var art := VFX.spawn(get_parent(), "nova_vector_streak", global_position + Vector2(0, -32) + direction * length * 0.5, Vector2(length / 180.0, lerpf(0.55, 1.0, power)), false, 5, STRIKE_COLOR)
	if art != null:
		art.rotation = direction.angle()
		return
	var line := Line2D.new()
	line.points = PackedVector2Array([Vector2.ZERO, direction * length])
	line.width = lerpf(5.0, 12.0, power)
	line.default_color = STRIKE_COLOR
	line.antialiased = true
	line.z_index = 5
	get_parent().add_child(line)
	line.global_position = global_position + Vector2(0, -32)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.12)
	tween.tween_callback(line.queue_free)

func _play_impact_flash(world_position: Vector2, radius: float, color: Color) -> void:
	radius *= GAME_SCALE.COMBAT
	if VFX.spawn(get_parent(), "nova_impact_star", world_position, Vector2.ONE * (radius * 2.4 / 230.0), false, 7, Color(1, 1, 1, color.a)) != null:
		return
	var flash := Polygon2D.new()
	flash.polygon = _make_star_points(radius, radius * 0.48)
	flash.color = color
	flash.z_index = 7
	get_parent().add_child(flash)
	flash.global_position = world_position
	flash.scale = Vector2(0.4, 0.4)
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector2(1.2, 1.2), 0.15)
	tween.parallel().tween_property(flash, "rotation", 0.5, 0.15)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.15)
	tween.tween_callback(flash.queue_free)

func _play_launch_flash(direction: Vector2) -> void:
	var art := VFX.spawn(get_parent(), "nova_launch_flash", global_position + Vector2(0, -32) + direction * 90.0, Vector2(180.0 / 238.0, 1.0), false, 6)
	if art != null:
		art.rotation = direction.angle()
		return
	var line := Line2D.new()
	line.points = PackedVector2Array([Vector2.ZERO, direction * 180.0])
	line.width = 18.0
	line.default_color = Color(0.82, 0.6, 1.0, 0.82)
	line.antialiased = true
	line.z_index = 6
	get_parent().add_child(line)
	line.global_position = global_position + Vector2(0, -32)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.16)
	tween.tween_callback(line.queue_free)

func _set_character_rotation(angle: float) -> void:
	body.rotation = angle
	if is_instance_valid(character_sprite):
		character_sprite.rotation = angle

func _reset_character_rotation() -> void:
	body.rotation = 0.0
	if is_instance_valid(character_sprite):
		character_sprite.rotation = 0.0

func _make_star_points(outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 12:
		var radius := outer_radius if index % 2 == 0 else inner_radius
		var angle := -PI * 0.5 + TAU * float(index) / 12.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _make_circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := TAU * float(index) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
