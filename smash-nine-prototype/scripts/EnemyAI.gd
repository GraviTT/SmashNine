extends RefCounted

## Realm, movement and attack scales (routine 2026-10-08): navigation distances follow the
## realms (WORLD, jump heights JUMP_HEIGHT), fighting distances follow attack reach (COMBAT).
const GAME_SCALE := preload("res://scripts/GameScale.gd")

const STATE_WANDER := "wander"
const STATE_PURSUE := "pursue"
const STATE_ENGAGE := "engage"
const STATE_PORTAL := "portal"
const STATE_RECOVER := "recover"

const WORLD_LAYER := 1
const PLAYER_TARGET_RANGE := 5200.0 * GAME_SCALE.WORLD
const MONSTER_TARGET_RANGE := 1500.0 * GAME_SCALE.WORLD
const TARGET_LOCK_TIME := 1.6
const DECISION_TIME_MIN := 0.35
const DECISION_TIME_MAX := 0.7
const ACTION_TIME_MIN := 0.42
const ACTION_TIME_MAX := 0.9
const ATTACK_COOLDOWN_MIN := 0.48
const ATTACK_COOLDOWN_MAX := 1.05
## After any portal move (also off screen) a bot stays this long (Codex QA-14: 94 portal
## moves per match, because a move reset the cooldown and off-screen hops ignored it).
const PORTAL_COOLDOWN := 8.0
## Roaming through a portal only after this long without a target, at this chance per decision.
const ROAM_AFTER := 4.0
const ROAM_CHANCE := 0.05
const PORTAL_REACHED := 58.0
const JUMP_BUFFER := 0.12

const FLOOR_PROBE_AHEAD := 44.0
const FLOOR_PROBE_DEPTH := 94.0 * GAME_SCALE.WORLD
const SHORT_LANDING_DISTANCE := 118.0 * GAME_SCALE.WORLD
const LONG_LANDING_DISTANCE := 160.0 * GAME_SCALE.WORLD
const LANDING_PATCH_HALF_WIDTH := 24.0
const EDGE_BRAKE_LOOKAHEAD := 0.14
const BLOCKED_PATH_TIME := 0.65
const WAYPOINT_REACHED := 58.0
const STUCK_CHECK_TIME := 1.1
const STUCK_DISTANCE := 20.0
const JUMP_RETRY_TIME := 0.48
const NAV_REPLAN_DISTANCE := 240.0 * GAME_SCALE.WORLD
const NAV_SAME_LEVEL := 92.0 * GAME_SCALE.WORLD
const NAV_HORIZONTAL_REACH := 470.0 * GAME_SCALE.WORLD
## Routes only use rises one ground jump clears (debate D1: the air jump stays for recovery);
## 125 x JUMP_HEIGHT = 187.5 px, under every fighter's single jump (198-234 px).
const NAV_JUMP_RISE := 125.0 * GAME_SCALE.JUMP_HEIGHT
const NAV_JUMP_REACH := 470.0 * GAME_SCALE.WORLD
const NAV_DROP_DEPTH := 360.0 * GAME_SCALE.WORLD
const NAV_DROP_REACH := 470.0 * GAME_SCALE.WORLD
const NAV_DROP_MIN_HORIZONTAL := 86.0 * GAME_SCALE.WORLD
const DROP_PROBE_DEPTH := 390.0 * GAME_SCALE.WORLD

## Realm geometry comes from the player (PlayerBase.realm_size); offsets below are relative to it.
const ROW_HEIGHT := 720.0 * GAME_SCALE.WORLD
const RECOVER_SIDE_SLACK := 20.0
const RECOVER_START_FROM_BOTTOM := 40.0
const RECOVER_EXIT_FROM_BOTTOM := 60.0
const RECOVER_JUMP_RETRY := 0.3
const VOID_PROBE_DEPTH := 700.0 * GAME_SCALE.WORLD
## Extra ultimate presses after the first one: Nova's slingshot stages, Luna's heart laser.
## Fixed extra ultimate presses (Luna's heart laser). Nova's slingshot is driven by aim
## instead (_drive_nova_slingshot).
const ULTIMATE_FOLLOWUPS := {"luna": [4.4]}
## Guarding (2026-10-08, bots never guarded before): when an opponent in reach starts an
## attack, guard after a human-like delay, some of the time, for a short hold.
const GUARD_CHANCE := 0.55
const GUARD_REACTION_MIN := 0.14
const GUARD_REACTION_MAX := 0.24
const GUARD_HOLD_MIN := 0.28
const GUARD_HOLD_MAX := 0.5
## No guard once the swing it reacts to is this far past its wind-up: the hit is over (round 2:
## at least 26 reactions began while the attack was already in recovery).
const GUARD_LATE_GRACE := 0.1
## Anticipatory guard (debate D3): an opponent within its reach, facing us, while we are not
## attacking: this chance per decision to raise guard for a moment, as a human would.
const GUARD_ANTICIPATE_CHANCE := 0.15
const GUARD_ANTICIPATE_MIN := 0.25
const GUARD_ANTICIPATE_MAX := 0.4
## Guard when the attacker's own reach (its profile) plus this margin covers us, and the height
## gap is under GUARD_HEIGHT (both x GameScale.COMBAT).
const GUARD_REACH_MARGIN := 40.0
const GUARD_HEIGHT := 90.0
## Aiming: up or down when the target is at least AIM_VERTICAL_MIN px above or below and the
## slope is at least AIM_VERTICAL_SLOPE (|dy| >= 0.65 |dx|, about 33 degrees).
const AIM_VERTICAL_MIN := 48.0
const AIM_VERTICAL_SLOPE := 0.65
## Progress check: a target that is on another level and not 60 px (x WORLD) closer after
## 2.5 s is dropped and ignored for 5 s.
const PROGRESS_TIME := 2.5
const PROGRESS_DISTANCE := 60.0
const IGNORE_TIME := 5.0
## "Another level" is judged by where a body stands (the floor under it while airborne), probed
## this far down (Codex QA-14 round 2: jumping or launched targets read as another level, so
## close fights were dropped and no-target time rose from 2-3% to 8-11%).
const STANDING_PROBE_DEPTH := 900.0 * GAME_SCALE.WORLD
## Once players come first (central brawl, or few left) monsters and crystals sort after every
## player (round 2: central-brawl player targets fell to 75%, monsters rose to 17%).
const LATE_NON_PLAYER_PENALTY := 1000000.0
## A kiting fighter does not back into a ledge closer than this; it jumps past the opponent
## (round 2: Yuki, who retreats 38% of its engage time, had 44 of 135 ring-outs).
const RETREAT_EDGE_MARGIN := 150.0 * GAME_SCALE.WORLD
const ESCAPE_JUMP_DISTANCE := 140.0 * GAME_SCALE.COMBAT
## Round 4 (Codex QA-14 round 3): Yuki chose the escape 701 times in 12 matches; at most one
## per this many seconds, and only with floor beyond the opponent to land on.
const ESCAPE_COOLDOWN := 2.5
const ESCAPE_LANDING_PAST := 90.0
## A hit on the target within this long counts as progress (round 3: 146 of 325 drops were
## targets within 300 px or hit in the last 3 s).
const TRADE_MEMORY := 3.0
## A target this close is kept while a route to where it stands exists.
const PROGRESS_KEEP_NEAR := 300.0
## Cornered with the escape still cooling down, a kiting bot guards ahead this often per
## decision (round 4: Yuki's ring-outs from hits near a ledge rose 8 -> 13 once it held there).
const CORNERED_GUARD_CHANCE := 0.5
## A fighter's attacker memory counts down from this (PlayerBase.LAST_ATTACKER_MEMORY).
const FIGHTER_ATTACKER_MEMORY := 8.0
## Out of jumps, a directional recovery skill only once the ledge is this close (px; round 3:
## Rio reached a floor 2 of 10 times, 2 of 4 with the limit in round 4), aimed a little above
## it; the last chance near the bottom of the realm still takes it. Frey (18 of 19) and Nova
## go from anywhere (Nova with the limit: 3 of 21 instead of 3 of 15, round 4).
const RECOVERY_SKILL_REACH := {"frey": 100000.0, "nova": 100000.0, "rio": 290.0}
const RECOVERY_SKILL_AIM_ABOVE := 60.0
const RECOVERY_LAST_CHANCE := 140.0
## Ultimate use by an opportunity score (debate 2026-10-08): reach per fighter (px, already at
## the combat scale), score >= 3 fires 70% of the time, >= 2 once it has been ready 12 s.
const ULTIMATE_REACH := {"frey": 480.0, "yuki": 820.0, "luna": 420.0, "nova": 460.0, "rio": 900.0}
const ULTIMATE_FIRE_CHANCE := 0.7
const ULTIMATE_PATIENCE := 12.0
## Low-HP retreat (debate): never in a final duel or late (aggression >= 0.8); otherwise under
## 30% HP, toward a safe realm, at most every 10 s.
const DISENGAGE_LATE_AGGRESSION := 0.8
const DISENGAGE_COOLDOWN := 10.0
const BACK_OFF_TIME := 4.0
## Players outrank monsters once this few fighters remain (QA-14: 4).
const FEW_LEFT := 4
## Nova's slingshot (debate): orbit after 0.25-0.4 s, launch when the orbit's tangent points
## within 20 degrees of where the target will be (0.15 s ahead), forced at 0.8 s; 0.12-0.2 s
## after launch, redirect with skill one (75%) if still more than 25 degrees off.
const NOVA_ORBIT_DELAY_MIN := 0.25
const NOVA_ORBIT_DELAY_MAX := 0.4
const NOVA_LAUNCH_ANGLE := 20.0
const NOVA_LAUNCH_LATEST := 0.8
const NOVA_REDIRECT_DELAY_MIN := 0.12
const NOVA_REDIRECT_DELAY_MAX := 0.2
const NOVA_REDIRECT_ANGLE := 25.0
const NOVA_REDIRECT_CHANCE := 0.75
const TARGET_LEAD_TIME := 0.15
const PASSIVE_PLAYER_PENALTY := 900.0 * GAME_SCALE.WORLD
const DISENGAGE_HP_RATIO := 0.3
const HAZARD_REACTION_CHANCE := 0.8
const QUAKE_JUMP_LEAD := 0.35
const VENT_MARGIN := 40.0
## Engagement distances per fighter, from each kit's reach (CODEX-ANALYST-01: one 235 px
## profile for everyone erased Yuki's range). "kite" fighters back off when crowded.
const COMBAT_PROFILES := {
	"frey": {"min_range": 45.0, "max_range": 170.0, "attack_range": 200.0, "kite": false, "recovery_skill": true},
	"nova": {"min_range": 60.0, "max_range": 230.0, "attack_range": 260.0, "kite": false, "recovery_skill": true},
	"luna": {"min_range": 110.0, "max_range": 290.0, "attack_range": 330.0, "kite": false},
	"yuki": {"min_range": 190.0, "max_range": 420.0, "attack_range": 470.0, "kite": true},
	"rio": {"min_range": 50.0, "max_range": 200.0, "attack_range": 230.0, "kite": false, "recovery_skill": true, "reactive_skill_2": true, "basic_reach": 120.0}
}
const BUSH_NOTICE_RANGE := 140.0 * GAME_SCALE.WORLD
const DEFAULT_COMBAT_PROFILE := {"min_range": 65.0, "max_range": 215.0, "attack_range": 235.0, "kite": false}

const OFFSCREEN_THINK_MIN := 3.0
const OFFSCREEN_THINK_MAX := 7.0
const OFFSCREEN_STAY_CHANCE := 0.92
const OFFSCREEN_CHASE_CHANCE := 0.3
const OFFSCREEN_WANDER_CHANCE := 0.05

var state: String = STATE_WANDER
var target: Node
var target_lock_timer: float = 0.0
var decision_timer: float = 0.0
var action_timer: float = 0.0
var attack_cooldown: float = 0.0
var portal_cooldown: float = 0.0
var offscreen_timer: float = 0.0

var action: String = "hold"
var last_action: String = ""
var action_direction: float = 1.0
var wander_target: Vector2 = Vector2.ZERO
var waypoint: Vector2 = Vector2.ZERO
var portal_target: Dictionary = {}
var recovery_target: Vector2 = Vector2.ZERO
var recovery_jump_used: bool = false
var ultimate_followup_delays: Array[float] = []
var ultimate_followup_timer: float = 0.0
var hazard_reaction: int = -1

var stuck_anchor: Vector2 = Vector2.ZERO
var stuck_timer: float = 0.0
var last_commanded_move: float = 0.0
var blocked_direction: float = 0.0
var blocked_timer: float = 0.0
var jump_retry_timer: float = 0.0
var navigation_path: Array[Vector2] = []
var navigation_index: int = 0
var navigation_goal: Vector2 = Vector2.INF
var planned_drop_direction: float = 0.0
var planned_drop_target: Vector2 = Vector2.INF
var row_transition_direction: float = 0.0
var row_transition_target: int = -1
## Direction for a directed skill (Rio's dimension slash back to a platform); zero = facing.
var aim_direction: Vector2 = Vector2.ZERO
## Dev view (the F4 bot panel and analysis probes): the last intent sent to the fighter and
## why the bot is doing what it does, in a few words.
var last_intent: Dictionary = {}
var guard_hold_timer: float = 0.0
var guard_delay_timer: float = -1.0
var watched_attack_locks: Dictionary = {}
## The swing seen starting this frame (watched every frame, also in hitstun, so a swing that
## began meanwhile is not mistaken for a new one afterwards).
var pending_threat: Node
## Direction to guard toward (read by PlayerBase when the guard starts).
var guard_aim: Vector2 = Vector2.ZERO
var guard_threat_from: Node
var ignored_targets: Dictionary = {}
var progress_target: Node
## The target that already got its one extra progress window (round 4: keeping close targets
## with a route every time made no-progress time 647 -> 1,104 s).
var progress_extended: Node
## The recovery skill is asked for once per recovery (round 4: Nova and Rio asked 2,200 and
## 1,148 times for 21 and 4 uses).
var recovery_skill_asked: bool = false
var progress_best: float = INF
var progress_timer: float = 0.0
var ultimate_ready_time: float = 0.0
var disengage_cooldown: float = 0.0
var no_target_time: float = 0.0
var escape_cooldown: float = 0.0
var back_off_timer: float = 0.0
var nova_stage_timer: float = -1.0
var nova_redirect_timer: float = -1.0
var debug_reason: String = ""

func update(player, delta: float) -> void:
	pending_threat = _new_attack_threat(player)
	if player.is_dummy or player.hitstun_timer > 0.0:
		_apply_intent(player, _intent())
		return

	_target_timers(delta)
	_update_ultimate_followups(player, delta)
	_drive_nova_slingshot(player, delta)
	_update_stuck(player, delta)
	_update_target_progress(player, delta)
	ultimate_ready_time = ultimate_ready_time + delta if player.is_ultimate_ready() else 0.0
	disengage_cooldown = maxf(disengage_cooldown - delta, 0.0)
	back_off_timer = maxf(back_off_timer - delta, 0.0)
	escape_cooldown = maxf(escape_cooldown - delta, 0.0)
	no_target_time = 0.0 if is_instance_valid(target) else no_target_time + delta

	if _needs_recovery(player):
		if state != STATE_RECOVER:
			debug_reason = "off the stage: getting back"
		_enter_state(STATE_RECOVER)

	if decision_timer <= 0.0 or _must_replan(player):
		_select_state(player)

	if _update_guard(player, delta):
		# A neutral intent: the last move input must not keep pushing the fighter (debate N2).
		_apply_intent(player, _intent())
		last_intent = {"move": 0.0, "jump": false, "attack": "", "guard": true}
		return

	var intent: Dictionary = _build_intent(player, delta)
	intent = _avoid_hazards(player, intent)
	last_commanded_move = float(intent.get("move", 0.0))
	last_intent = intent
	_apply_intent(player, intent)

## Realm hazards (RealmHazards.get_threat via the parent): jump just before a quake lands,
## step out of eruption vents. Each warning gets one reaction roll so bots are not perfect.
func _avoid_hazards(player, intent: Dictionary) -> Dictionary:
	var parent: Node = player.get_parent()
	if parent == null or not parent.has_method("get_ai_hazard"):
		return intent
	var threat: Dictionary = parent.get_ai_hazard(player.realm_index)
	if threat.is_empty():
		hazard_reaction = -1
		return intent
	if hazard_reaction < 0:
		hazard_reaction = 1 if randf() < HAZARD_REACTION_CHANCE else 0
	if hazard_reaction == 0:
		return intent
	match str(threat.type):
		"quake":
			if threat.phase == "warning" and float(threat.time_left) < QUAKE_JUMP_LEAD and player.is_on_floor():
				intent["jump"] = true
		"eruption", "beams":
			var body: Vector2 = player.global_position + Vector2(0.0, -32.0)
			for column in threat.columns:
				var danger: Rect2 = (column as Rect2).grow_individual(VENT_MARGIN, 0.0, VENT_MARGIN, 0.0)
				if danger.has_point(body):
					intent["move"] = -1.0 if body.x < danger.get_center().x else 1.0
					intent["attack"] = ""
					break
	return intent

func reset(position: Vector2) -> void:
	guard_hold_timer = 0.0
	guard_delay_timer = -1.0
	watched_attack_locks.clear()
	ignored_targets.clear()
	progress_target = null
	progress_timer = 0.0
	nova_stage_timer = -1.0
	nova_redirect_timer = -1.0
	state = STATE_WANDER
	target = null
	target_lock_timer = 0.0
	decision_timer = 0.0
	action_timer = 0.0
	attack_cooldown = 0.0
	# Just arrived (portal, relocation, respawn, start): stay a while.
	portal_cooldown = PORTAL_COOLDOWN
	offscreen_timer = randf_range(OFFSCREEN_THINK_MIN, OFFSCREEN_THINK_MAX)
	action = "hold"
	last_action = ""
	action_direction = 1.0
	wander_target = Vector2.ZERO
	waypoint = Vector2.ZERO
	portal_target = {}
	recovery_target = Vector2.ZERO
	recovery_jump_used = false
	stuck_anchor = position
	ultimate_followup_delays.clear()
	ultimate_followup_timer = 0.0
	stuck_timer = 0.0
	last_commanded_move = 0.0
	blocked_direction = 0.0
	blocked_timer = 0.0
	jump_retry_timer = 0.0
	navigation_path.clear()
	navigation_index = 0
	navigation_goal = Vector2.INF
	planned_drop_direction = 0.0
	planned_drop_target = Vector2.INF
	row_transition_direction = 0.0
	row_transition_target = -1
	aim_direction = Vector2.ZERO

func _target_timers(delta: float) -> void:
	decision_timer = maxf(decision_timer - delta, 0.0)
	target_lock_timer = maxf(target_lock_timer - delta, 0.0)
	action_timer = maxf(action_timer - delta, 0.0)
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	portal_cooldown = maxf(portal_cooldown - delta, 0.0)
	blocked_timer = maxf(blocked_timer - delta, 0.0)
	jump_retry_timer = maxf(jump_retry_timer - delta, 0.0)
	for ignored in ignored_targets.keys():
		ignored_targets[ignored] = float(ignored_targets[ignored]) - delta
		if float(ignored_targets[ignored]) <= 0.0 or not is_instance_valid(ignored):
			ignored_targets.erase(ignored)

func _select_state(player) -> void:
	decision_timer = randf_range(DECISION_TIME_MIN, DECISION_TIME_MAX)

	if state == STATE_RECOVER and not _recovery_complete(player):
		debug_reason = "off the stage: getting back"
		return

	if _realm_is_warning(player) or _should_disengage(player):
		var escape_portal: Dictionary = _find_portal_target(player)
		if not escape_portal.is_empty():
			portal_target = escape_portal
			debug_reason = "realm collapsing: leaving" if _realm_is_warning(player) else "low HP: leaving the fight"
			_enter_state(STATE_PORTAL)
			return

	_refresh_target(player)
	if is_instance_valid(target):
		var offset: Vector2 = target.global_position - player.global_position
		if _is_in_engage_band(player, offset):
			debug_reason = "in fighting range"
			_enter_state(STATE_ENGAGE)
		else:
			debug_reason = "target out of range: chasing"
			_enter_state(STATE_PURSUE)
		return

	if portal_cooldown <= 0.0 and no_target_time >= ROAM_AFTER and randf() < ROAM_CHANCE:
		var roaming_portal: Dictionary = _find_portal_target(player)
		if not roaming_portal.is_empty():
			portal_target = roaming_portal
			debug_reason = "nobody here: roaming"
			_enter_state(STATE_PORTAL)
			return

	debug_reason = "no target: wandering"
	_enter_state(STATE_WANDER)

func _enter_state(next_state: String) -> void:
	if state == next_state:
		return
	state = next_state
	action_timer = 0.0
	waypoint = Vector2.ZERO
	_clear_navigation_path()
	stuck_timer = 0.0
	if next_state != STATE_PORTAL:
		portal_target = {}
	if next_state == STATE_RECOVER:
		recovery_target = Vector2.ZERO
		recovery_jump_used = false
		recovery_skill_asked = false

func _must_replan(player) -> bool:
	if state == STATE_RECOVER:
		return _recovery_complete(player)
	if state == STATE_PORTAL:
		return portal_target.is_empty()
	if is_instance_valid(target) and _target_invalid(player):
		return true
	if stuck_timer >= STUCK_CHECK_TIME:
		_clear_navigation_path()
		return true
	return false

func _build_intent(player, delta: float) -> Dictionary:
	match state:
		STATE_RECOVER:
			return _recover_intent(player)
		STATE_PORTAL:
			return _portal_intent(player)
		STATE_ENGAGE:
			return _engage_intent(player, delta)
		STATE_PURSUE:
			return _pursue_intent(player)
		_:
			return _wander_intent(player)

func _intent(move: float = 0.0, jump: bool = false, attack: String = "") -> Dictionary:
	return {"move": move, "jump": jump, "attack": attack}

func _apply_intent(player, intent: Dictionary) -> void:
	player.move_input = float(intent.get("move", 0.0))
	# The aim holds through an attack's start-up: skills read it when they fire.
	aim_direction = intent.get("aim", aim_direction if player.attack_lock_timer > 0.0 else Vector2.ZERO)
	if bool(intent.get("jump", false)):
		player.jump_buffer_timer = JUMP_BUFFER
	var attack_name: String = str(intent.get("attack", ""))
	if attack_name == "" or player.attack_lock_timer > 0.0:
		return
	match attack_name:
		"basic":
			player.basic_attack()
		"skill_1":
			player.skill_one()
		"skill_2":
			player.skill_two()
		"ultimate":
			var was_ready: bool = player.is_ultimate_ready()
			player.ultimate()
			if was_ready and not player.is_ultimate_ready():
				_schedule_ultimate_followups(player)

func _schedule_ultimate_followups(player) -> void:
	ultimate_followup_delays.clear()
	for delay in ULTIMATE_FOLLOWUPS.get(player.character_id, []):
		ultimate_followup_delays.append(float(delay))
	ultimate_followup_timer = ultimate_followup_delays.pop_front() if not ultimate_followup_delays.is_empty() else 0.0

func _update_ultimate_followups(player, delta: float) -> void:
	if ultimate_followup_timer <= 0.0:
		return
	ultimate_followup_timer -= delta
	if ultimate_followup_timer > 0.0:
		return
	player.ultimate()
	ultimate_followup_timer = ultimate_followup_delays.pop_front() if not ultimate_followup_delays.is_empty() else 0.0

func _wander_intent(player) -> Dictionary:
	if wander_target == Vector2.ZERO or player.global_position.distance_to(wander_target) <= WAYPOINT_REACHED:
		wander_target = _choose_wander_point(player)
	var destination: Vector2 = _navigation_destination(player, wander_target)
	return _navigate_to_intent(player, destination)

func _pursue_intent(player) -> Dictionary:
	if not is_instance_valid(target):
		return _wander_intent(player)
	var row_transition_intent: Dictionary = _downward_row_transition_intent(player, target.global_position)
	if not row_transition_intent.is_empty():
		return row_transition_intent
	var destination: Vector2 = _choose_pursuit_destination(player, target.global_position)
	return _navigate_to_intent(player, destination)

## Only for realms made of stacked 720 px rows (tiled realms); single arenas never need it.
func _downward_row_transition_intent(player, target_position: Vector2) -> Dictionary:
	if player.realm_size.y <= ROW_HEIGHT * 1.5:
		return {}
	var realm_width: float = player.realm_size.x
	var local_y: float = player.global_position.y - player.realm_origin.y
	var target_local_y: float = target_position.y - player.realm_origin.y
	var current_row: int = clampi(floori(local_y / ROW_HEIGHT), 0, 2)
	var target_row: int = clampi(floori(target_local_y / ROW_HEIGHT), 0, 2)
	if target_row <= current_row:
		row_transition_direction = 0.0
		row_transition_target = -1
		return {}
	if row_transition_target != target_row or is_zero_approx(row_transition_direction):
		var local_x: float = player.global_position.x - player.realm_origin.x
		row_transition_direction = -1.0 if local_x <= realm_width * 0.5 else 1.0
		row_transition_target = target_row
		_clear_navigation_path()
	if player.is_on_floor():
		var step_jump: bool = stuck_timer >= 0.45 and jump_retry_timer <= 0.0
		if step_jump:
			jump_retry_timer = JUMP_RETRY_TIME
		return _intent(row_transition_direction, step_jump)
	var local_x: float = player.global_position.x - player.realm_origin.x
	var crossed_outer_edge: bool = local_x < 145.0 * GAME_SCALE.WORLD or local_x > realm_width - 145.0 * GAME_SCALE.WORLD
	var crossed_row_boundary: bool = local_y > float(current_row + 1) * ROW_HEIGHT + 80.0 * GAME_SCALE.WORLD
	var recovery_jump: bool = player.air_jumps_left > 0 and player.velocity.y > 320.0 * GAME_SCALE.JUMP_SPEED and local_y > float(current_row + 1) * ROW_HEIGHT + 260.0 * GAME_SCALE.WORLD
	var air_direction: float = -row_transition_direction if crossed_outer_edge or crossed_row_boundary else row_transition_direction
	return _intent(air_direction, recovery_jump)

func _engage_intent(player, delta: float) -> Dictionary:
	if not is_instance_valid(target):
		return _wander_intent(player)

	var offset: Vector2 = target.global_position - player.global_position
	var distance_x: float = absf(offset.x)
	var distance_y: float = absf(offset.y)
	var target_direction: float = signf(offset.x)
	if is_zero_approx(target_direction):
		target_direction = float(player.facing)
	else:
		player.facing = signi(int(target_direction))

	if action_timer <= 0.0:
		_choose_engage_action(player, distance_x, distance_y, target_direction)

	var move: float = 0.0
	var jump: bool = false
	match action:
		"approach":
			move = target_direction
		"retreat":
			move = -target_direction
		"cross":
			move = action_direction
		"jump_in":
			move = target_direction
			jump = player.is_on_floor() and (offset.y < -55.0 or not _has_floor_ahead(player, target_direction, FLOOR_PROBE_AHEAD))
		"hold":
			move = 0.0
		"escape":
			# Toward the opponent and over it, to open floor behind it.
			move = target_direction
			jump = player.is_on_floor() and distance_x < ESCAPE_JUMP_DISTANCE

	# A target on a lower level: step off the ledge toward it when there is a landing (the
	# engage band reaches farther down since attacks doubled; it used to stand on the edge).
	var drop_down: bool = offset.y > NAV_SAME_LEVEL and move != 0.0 and signf(move) == target_direction and _has_drop_landing(player, target_direction)
	var terrain_intent: Dictionary = _terrain_move_intent(player, move, jump, action == "approach" or action == "jump_in" or action == "escape", drop_down)
	var attack_name: String = _choose_attack(player, distance_x, distance_y)
	terrain_intent["attack"] = attack_name
	if attack_name != "":
		terrain_intent["aim"] = _attack_aim(player, attack_name)
	return terrain_intent

func _choose_engage_action(player, distance_x: float, distance_y: float, target_direction: float) -> void:
	var profile: Dictionary = _combat_profile(player)
	var min_range: float = float(profile.min_range)
	var max_range: float = float(profile.max_range)
	var candidates: Array[String] = []

	if distance_x > max_range:
		candidates = ["approach", "approach", "jump_in"]
		debug_reason = "too far to hit"
	elif distance_x < min_range:
		if bool(profile.kite):
			candidates = ["retreat", "retreat", "hold"]
			debug_reason = "too close: keeping range"
		else:
			candidates = ["hold", "hold", "cross", "approach"]
			debug_reason = "close in"
	else:
		candidates = ["hold", "cross", "approach", "jump_in"]
		debug_reason = "in range: mixing up"

	if distance_y > 120.0 * GAME_SCALE.COMBAT:
		candidates = ["approach", "jump_in"]
		debug_reason = "target on another level"
	if back_off_timer > 0.0:
		candidates = ["retreat"]
		debug_reason = "low HP: backing off"
	if candidates.has("retreat") and _cornered(player, target_direction):
		# Past an opponent on our level; one on another level is held off from here (walking
		# toward it would drop a kiting fighter right next to it).
		if distance_y <= NAV_SAME_LEVEL and escape_cooldown <= 0.0 and _has_floor_ahead(player, target_direction, distance_x + ESCAPE_LANDING_PAST):
			candidates = ["escape"]
			escape_cooldown = ESCAPE_COOLDOWN
			debug_reason = "cornered: jumping past"
		else:
			candidates = ["hold"]
			debug_reason = "cornered: holding the ledge"
			if escape_cooldown > 0.0 and randf() < CORNERED_GUARD_CHANCE:
				_maybe_anticipate_guard(player, 1.0)

	action = _pick_non_repeating_action(candidates)
	last_action = action
	_maybe_anticipate_guard(player)
	action_timer = randf_range(ACTION_TIME_MIN, ACTION_TIME_MAX)
	action_direction = target_direction if randf() < 0.5 else -target_direction

func _pick_non_repeating_action(candidates: Array[String]) -> String:
	var filtered: Array[String] = []
	for candidate in candidates:
		if candidate != last_action:
			filtered.append(candidate)
	if filtered.is_empty():
		filtered = candidates.duplicate()
	var index: int = randi_range(0, filtered.size() - 1)
	return filtered[index]

func _choose_attack(player, distance_x: float, distance_y: float) -> String:
	if attack_cooldown > 0.0 or player.attack_lock_timer > 0.0:
		return ""
	var profile: Dictionary = _combat_profile(player)
	if distance_x > float(profile.attack_range) or distance_y > 115.0 * GAME_SCALE.COMBAT:
		return ""

	attack_cooldown = randf_range(ATTACK_COOLDOWN_MIN, ATTACK_COOLDOWN_MAX)
	if player.is_ultimate_ready() and is_instance_valid(target) and target.is_in_group("players"):
		var score := _ultimate_score(player)
		if (score >= 3 or (score >= 2 and ultimate_ready_time >= ULTIMATE_PATIENCE)) and randf() < ULTIMATE_FIRE_CHANCE:
			debug_reason = "ultimate: good moment (score %d)" % score
			return "ultimate"
	var roll: float = randf()
	var attack_name: String
	if distance_x < 88.0 * GAME_SCALE.COMBAT:
		attack_name = "basic" if roll < 0.82 else "skill_1"
	elif roll < 0.62:
		attack_name = "basic"
	elif roll < 0.88:
		attack_name = "skill_1"
	else:
		attack_name = "skill_2"
	if attack_name == "skill_1" and not _mobility_skill_is_safe(player):
		attack_name = "basic" if distance_x <= 195.0 * GAME_SCALE.COMBAT else "skill_2"
	# Nova's vector shift closes distance; Yuki's binding talisman needs a target close and on
	# the same level (QA-14: 2.4% and 5.7% hit rates when thrown at any range).
	if attack_name == "skill_1" and player.character_id == "nova" and distance_x < float(profile.attack_range) * 0.5:
		attack_name = "basic"
	if attack_name == "skill_1" and player.character_id == "yuki" and (distance_x > float(profile.attack_range) * 0.7 or distance_y > NAV_SAME_LEVEL):
		attack_name = "basic"
	# A counter skill (Rio's rune shield) only when the target is swinging right now.
	if bool(profile.get("reactive_skill_2", false)):
		var target_swinging: bool = is_instance_valid(target) and float(target.get("attack_lock_timer") if target.get("attack_lock_timer") != null else 0.0) > 0.0
		if attack_name == "skill_2" and not target_swinging:
			attack_name = "basic"
		elif target_swinging and distance_x < 150.0 * GAME_SCALE.COMBAT and randf() < 0.45:
			attack_name = "skill_2"
	# A basic thrown from beyond its reach only misses (round 3: Rio's side basics missed 89%
	# from 240 px and 92% beyond 360 px); keep closing in instead.
	if attack_name == "basic" and profile.has("basic_reach") and distance_x > float(profile.basic_reach):
		attack_name = ""
	return attack_name

func _mobility_skill_is_safe(player) -> bool:
	if not ["frey", "nova", "rio"].has(player.character_id):
		return true
	if not player.is_on_floor():
		return false
	var direction: float = float(player.facing)
	var local_x: float = player.global_position.x - player.realm_origin.x
	if direction < 0.0 and local_x < 220.0 * GAME_SCALE.WORLD:
		return false
	if direction > 0.0 and local_x > player.realm_size.x - 220.0 * GAME_SCALE.WORLD:
		return false
	if _has_floor_ahead(player, direction, 90.0 * GAME_SCALE.WORLD) and _has_floor_ahead(player, direction, 155.0 * GAME_SCALE.WORLD):
		return true
	return _has_landing_patch(player, direction, LONG_LANDING_DISTANCE)

func _combat_profile(player) -> Dictionary:
	return _scaled_profile(COMBAT_PROFILES.get(player.character_id, DEFAULT_COMBAT_PROFILE))

func _navigate_to_intent(player, destination: Vector2) -> Dictionary:
	var offset: Vector2 = destination - player.global_position
	var direction: float = _direction_to(player.global_position.x, destination.x)
	var wants_jump: bool = offset.y < -48.0
	var allow_drop: bool = offset.y > 72.0
	if allow_drop and player.is_on_floor():
		if planned_drop_target == Vector2.INF or planned_drop_target.distance_to(destination) > WAYPOINT_REACHED:
			planned_drop_direction = 0.0
			planned_drop_target = destination
		if is_zero_approx(planned_drop_direction):
			planned_drop_direction = _choose_drop_direction(player, destination.x)
		if not is_zero_approx(planned_drop_direction):
			direction = planned_drop_direction
	else:
		planned_drop_direction = 0.0
		planned_drop_target = Vector2.INF
	return _terrain_move_intent(player, direction, wants_jump, true, allow_drop)

func _terrain_move_intent(player, direction: float, wants_jump: bool, allow_gap_jump: bool, allow_drop: bool = false) -> Dictionary:
	if is_zero_approx(direction):
		if wants_jump and player.is_on_floor() and jump_retry_timer <= 0.0:
			jump_retry_timer = JUMP_RETRY_TIME
			return _intent(0.0, true)
		return _intent()
	if not player.is_on_floor():
		# A rise taller than one jump: jump again near the top while the destination is still
		# above, only with an air jump to spare and over solid ground (the last one is kept
		# for recovery; debate D1).
		if wants_jump and player.air_jumps_left >= 2 and player.velocity.y > -120.0 and jump_retry_timer <= 0.0 and not _over_void(player):
			jump_retry_timer = JUMP_RETRY_TIME
			return _intent(direction, true)
		return _intent(direction, false)
	if blocked_timer > 0.0 and signf(direction) == signf(blocked_direction):
		return _intent()
	if stuck_timer >= 0.45 and jump_retry_timer <= 0.0:
		jump_retry_timer = JUMP_RETRY_TIME
		return _intent(direction, true)
	var speed_lookahead: float = absf(player.velocity.x) * EDGE_BRAKE_LOOKAHEAD
	var probe_distance: float = FLOOR_PROBE_AHEAD + speed_lookahead
	if _has_floor_ahead(player, direction, probe_distance):
		if wants_jump and jump_retry_timer <= 0.0:
			jump_retry_timer = JUMP_RETRY_TIME
			return _intent(direction, true)
		return _intent(direction)
	if allow_drop:
		return _intent(direction)
	if allow_gap_jump and _has_jump_landing(player, direction):
		if jump_retry_timer <= 0.0:
			jump_retry_timer = JUMP_RETRY_TIME
			return _intent(direction, true)
		return _intent()
	blocked_direction = direction
	blocked_timer = BLOCKED_PATH_TIME
	decision_timer = 0.0
	waypoint = Vector2.ZERO
	_clear_navigation_path()
	if absf(player.velocity.x) > 35.0 and signf(player.velocity.x) == signf(direction):
		return _intent(-direction)
	return _intent()

func _choose_drop_direction(player, destination_x: float) -> float:
	var preferred: float = signf(destination_x - player.global_position.x)
	if is_zero_approx(preferred):
		preferred = float(player.facing)
	var preferred_edge: float = _floor_edge_distance(player, preferred)
	var opposite_edge: float = _floor_edge_distance(player, -preferred)
	if preferred_edge <= opposite_edge + 100.0 * GAME_SCALE.WORLD:
		return preferred
	return -preferred

func _floor_edge_distance(player, direction: float) -> float:
	var foot: Vector2 = player.global_position
	for distance in range(60, 3901, 80):
		var ray_x: float = direction * float(distance)
		if not _ray_hits_world(player, foot + Vector2(ray_x, -55.0), foot + Vector2(ray_x, FLOOR_PROBE_DEPTH)):
			return float(distance)
	return INF

func _has_drop_landing(player, direction: float) -> bool:
	if is_zero_approx(direction):
		return false
	var foot: Vector2 = player.global_position
	for distance in [72.0 * GAME_SCALE.WORLD, 118.0 * GAME_SCALE.WORLD]:
		var ray_x: float = direction * float(distance)
		if _ray_hits_world(player, foot + Vector2(ray_x, 12.0), foot + Vector2(ray_x, DROP_PROBE_DEPTH)):
			return true
	return false

func _has_floor_ahead(player, direction: float, distance: float) -> bool:
	var foot: Vector2 = player.global_position
	var ray_x: float = direction * distance
	return _ray_hits_world(player, foot + Vector2(ray_x, -8.0), foot + Vector2(ray_x, FLOOR_PROBE_DEPTH))

func _has_jump_landing(player, direction: float) -> bool:
	for distance in [SHORT_LANDING_DISTANCE, LONG_LANDING_DISTANCE]:
		if _has_landing_patch(player, direction, float(distance)):
			return true
	return false

func _has_landing_patch(player, direction: float, distance: float) -> bool:
	var foot: Vector2 = player.global_position
	var center_x: float = direction * distance
	var inner_x: float = center_x - direction * LANDING_PATCH_HALF_WIDTH
	var outer_x: float = center_x + direction * LANDING_PATCH_HALF_WIDTH
	var center_hit: bool = _ray_hits_world(player, foot + Vector2(center_x, -90.0), foot + Vector2(center_x, 145.0))
	var inner_hit: bool = _ray_hits_world(player, foot + Vector2(inner_x, -90.0), foot + Vector2(inner_x, 145.0))
	var outer_hit: bool = _ray_hits_world(player, foot + Vector2(outer_x, -90.0), foot + Vector2(outer_x, 145.0))
	return center_hit and inner_hit and outer_hit

func _ray_hits_world(player, from: Vector2, to: Vector2) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	query.from = from
	query.to = to
	query.collision_mask = WORLD_LAYER
	query.exclude = [player.get_rid()]
	var result: Dictionary = player.get_world_2d().direct_space_state.intersect_ray(query)
	return not result.is_empty()

func _needs_recovery(player) -> bool:
	if state == STATE_RECOVER:
		return not _recovery_complete(player)
	var local_position: Vector2 = player.global_position - player.realm_origin
	if local_position.x < -RECOVER_SIDE_SLACK or local_position.x > player.realm_size.x + RECOVER_SIDE_SLACK:
		return true
	if player.is_on_floor() or player.velocity.y <= 0.0:
		return false
	# Falling with nothing below: start heading back now, not near the blast line.
	return local_position.y > player.realm_size.y - RECOVER_START_FROM_BOTTOM or _over_void(player)

func _over_void(player) -> bool:
	var foot: Vector2 = player.global_position
	return not _ray_hits_world(player, foot, foot + Vector2(0.0, VOID_PROBE_DEPTH))

func _recovery_complete(player) -> bool:
	var local_position: Vector2 = player.global_position - player.realm_origin
	return player.is_on_floor() and local_position.y < player.realm_size.y - RECOVER_EXIT_FROM_BOTTOM and local_position.x >= 0.0 and local_position.x <= player.realm_size.x

## Steer back toward a platform and spend air jumps as soon as we drop below it.
func _recover_intent(player) -> Dictionary:
	if recovery_target == Vector2.ZERO:
		recovery_target = _choose_recovery_point(player)
	var direction: float = _direction_to(player.global_position.x, recovery_target.x)
	var jump: bool = false
	var below_target: bool = player.global_position.y > recovery_target.y + 20.0
	if below_target and player.velocity.y > 60.0 and player.air_jumps_left > 0 and jump_retry_timer <= 0.0:
		jump = true
		jump_retry_timer = RECOVER_JUMP_RETRY
	var intent: Dictionary = _intent(direction, jump)
	# Out of jumps: a recovery skill aimed at the platform (Rio's dimension slash, Frey's dash
	# strike, Nova's vector shift; Codex QA-14: 78% of ring-outs had no air jump left).
	if below_target and player.air_jumps_left <= 0 and player.velocity.y > 60.0 and bool(_combat_profile(player).get("recovery_skill", false)):
		var aim_point: Vector2 = recovery_target + Vector2(0.0, -RECOVERY_SKILL_AIM_ABOVE)
		var reach: float = float(RECOVERY_SKILL_REACH.get(player.character_id, 100000.0))
		var local_y: float = player.global_position.y - player.realm_origin.y
		var last_chance: bool = local_y > player.realm_size.y - RECOVERY_LAST_CHANCE
		if not recovery_skill_asked and player.attack_lock_timer <= 0.0 and (player.global_position.distance_to(aim_point) <= reach or last_chance):
			recovery_skill_asked = true
			intent["aim"] = (aim_point - player.global_position).normalized()
			intent["attack"] = "skill_1"
			debug_reason = "off the stage: recovery skill"
	return intent

## Nearest platform top we can still reach: close horizontally, and preferably not above us.
func _choose_recovery_point(player) -> Vector2:
	var best: Vector2 = player.realm_origin + Vector2(player.realm_size.x * 0.5, player.realm_size.y * 0.75)
	var best_score: float = INF
	var parent: Node = player.get_parent()
	var candidates: Array[Vector2] = player.spawn_points
	if parent != null and parent.has_method("get_ai_navigation_points_for_realm"):
		candidates = parent.get_ai_navigation_points_for_realm(player.realm_index)
	for point in candidates:
		var rise: float = player.global_position.y - point.y
		var score: float = absf(point.x - player.global_position.x) + maxf(rise, 0.0) * 1.5 + maxf(-rise, 0.0) * 0.4
		if score < best_score:
			best_score = score
			best = point
	return best

func _portal_intent(player) -> Dictionary:
	if portal_target.is_empty():
		return _intent()
	if _try_use_portal(player):
		portal_target = {}
		portal_cooldown = PORTAL_COOLDOWN
		_enter_state(STATE_WANDER)
		return _intent()
	var center: Vector2 = portal_target.rect.get_center()
	var destination: Vector2 = _navigation_destination(player, center)
	return _navigate_to_intent(player, destination)

func _refresh_target(player) -> void:
	if is_instance_valid(target) and target_lock_timer > 0.0 and not _target_invalid(player):
		return
	target = _find_target(player)
	target_lock_timer = TARGET_LOCK_TIME if is_instance_valid(target) else 0.0

func _find_target(player) -> Node:
	var scored: Array = _scored_targets(player)
	scored.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	# The best few candidates are checked for a route (one path search each, only for
	# targets on another level); unreachable ones are skipped (debate 2026-10-08).
	var checks := 0
	var own_floor: Vector2 = _standing_point(player, player)
	for entry: Array in scored:
		var candidate: Node = entry[1]
		var stands: Vector2 = _standing_point(player, candidate)
		# Over the void (falling or recovering): neither reachable nor worth ignoring.
		if stands == Vector2.INF:
			continue
		if own_floor == Vector2.INF or absf(stands.y - own_floor.y) <= NAV_SAME_LEVEL or checks >= 3:
			return candidate
		checks += 1
		if _has_route_to(player, stands):
			return candidate
		ignored_targets[candidate] = IGNORE_TIME
	return null

## [score, candidate] for every valid target, lower is better.
func _scored_targets(player) -> Array:
	var result: Array = []
	var few_left := _alive_fighters(player) <= FEW_LEFT
	var players_first: bool = few_left or float(player.ai_aggression) >= 1.0
	for candidate in player.get_tree().get_nodes_in_group("players"):
		if not _is_valid_target_candidate(player, candidate) or float(ignored_targets.get(candidate, 0.0)) > 0.0:
			continue
		var offset: Vector2 = candidate.global_position - player.global_position
		var distance: float = offset.length()
		if distance > PLAYER_TARGET_RANGE:
			continue
		var score: float = distance + absf(offset.y) * 0.12
		# Low aggression (early phases): prefer monsters unless this player hit us recently,
		# or only a few fighters are left (then players come first).
		if not _is_recent_attacker(player, candidate) and not few_left:
			score += (1.0 - float(player.ai_aggression)) * PASSIVE_PLAYER_PENALTY
		result.append([score, candidate])
	for candidate in player.get_tree().get_nodes_in_group("realm_monsters"):
		if not _is_valid_target_candidate(player, candidate) or float(ignored_targets.get(candidate, 0.0)) > 0.0:
			continue
		var offset: Vector2 = candidate.global_position - player.global_position
		var distance: float = offset.length()
		if distance > MONSTER_TARGET_RANGE:
			continue
		var score: float = distance + 320.0 * GAME_SCALE.WORLD + absf(offset.y) * 0.12
		if players_first:
			score += LATE_NON_PLAYER_PENALTY
		result.append([score, candidate])
	# Soul crystals: worth more than a monster and they do not fight back.
	for candidate in player.get_tree().get_nodes_in_group("soul_crystals"):
		if not _is_valid_target_candidate(player, candidate) or float(ignored_targets.get(candidate, 0.0)) > 0.0:
			continue
		var offset: Vector2 = candidate.global_position - player.global_position
		var distance: float = offset.length()
		if distance > MONSTER_TARGET_RANGE:
			continue
		var score: float = distance + 260.0 * GAME_SCALE.WORLD + absf(offset.y) * 0.12
		if players_first:
			score += LATE_NON_PLAYER_PENALTY
		result.append([score, candidate])
	return result

func _is_recent_attacker(player, candidate: Node) -> bool:
	return candidate == player.last_attacker and float(player.last_attacker_timer) > 0.0

## Hurt bots leave the realm while the match is still forgiving (aggression below 0.9).
func _should_disengage(player) -> bool:
	if float(player.ai_aggression) >= DISENGAGE_LATE_AGGRESSION or portal_cooldown > 0.0 or disengage_cooldown > 0.0:
		return false
	if _alive_fighters(player) <= 2 or player.hp / player.max_hp >= DISENGAGE_HP_RATIO:
		return false
	disengage_cooldown = DISENGAGE_COOLDOWN
	var portal: Dictionary = _find_portal_target(player)
	# Only to a stable realm with nobody in it (QA-14: retreats into company were hit again
	# 89% of the time); otherwise back off where we are for a few seconds.
	if portal.is_empty() or str(portal.get("destination_state", "")) != "stable" or _opponents_in_realm(player, int(portal.get("destination", -1))) > 0:
		back_off_timer = BACK_OFF_TIME
		debug_reason = "low HP: backing off"
		return false
	return true

func _target_invalid(player) -> bool:
	if not _is_valid_target_candidate(player, target):
		return true
	var max_range: float = MONSTER_TARGET_RANGE * 1.25 if target.is_in_group("realm_monsters") or target.is_in_group("soul_crystals") else PLAYER_TARGET_RANGE * 1.1
	return player.global_position.distance_to(target.global_position) > max_range

func _is_valid_target_candidate(player, candidate: Node) -> bool:
	if not is_instance_valid(candidate) or candidate == player:
		return false
	if candidate.is_in_group("players"):
		if bool(candidate.get("is_dummy")) or bool(candidate.get("is_defeated")):
			return false
		# Hidden in a bush: noticed only up close (RealmHazards bushes).
		if bool(candidate.get("concealed")) and player.global_position.distance_to(candidate.global_position) > BUSH_NOTICE_RANGE:
			return false
	elif candidate.is_in_group("realm_monsters") or candidate.is_in_group("soul_crystals"):
		var hp_value: Variant = candidate.get("hp")
		if hp_value == null or float(hp_value) <= 0.0:
			return false
	else:
		return false
	return int(candidate.get("realm_index")) == player.realm_index and bool(candidate.get("is_realm_active"))

func _is_in_engage_band(player, offset: Vector2) -> bool:
	var profile: Dictionary = _combat_profile(player)
	return absf(offset.x) <= float(profile.max_range) + 70.0 * GAME_SCALE.COMBAT and absf(offset.y) <= 150.0 * GAME_SCALE.COMBAT

func _choose_pursuit_destination(player, target_position: Vector2) -> Vector2:
	if absf(target_position.y - player.global_position.y) <= NAV_SAME_LEVEL:
		_clear_navigation_path()
		return target_position
	return _navigation_destination(player, target_position)

func _navigation_destination(player, desired_goal: Vector2) -> Vector2:
	var needs_plan: bool = navigation_path.is_empty() or navigation_index >= navigation_path.size()
	if navigation_goal == Vector2.INF or navigation_goal.distance_to(desired_goal) > NAV_REPLAN_DISTANCE:
		needs_plan = true
	if player.is_on_floor() and navigation_index < navigation_path.size():
		var current_waypoint: Vector2 = navigation_path[navigation_index]
		if current_waypoint.y < player.global_position.y - NAV_JUMP_RISE - 24.0:
			needs_plan = true
	if needs_plan:
		navigation_path = _plan_navigation_path(player, desired_goal)
		navigation_index = 0
		navigation_goal = desired_goal
	while navigation_index < navigation_path.size() and player.global_position.distance_to(navigation_path[navigation_index]) <= WAYPOINT_REACHED:
		navigation_index += 1
	if navigation_index < navigation_path.size():
		return navigation_path[navigation_index]
	return desired_goal

func _plan_navigation_path(player, desired_goal: Vector2) -> Array[Vector2]:
	var parent: Node = player.get_parent()
	if parent == null or not parent.has_method("get_ai_navigation_points_for_realm"):
		return []
	var navigation_points: Array[Vector2] = parent.get_ai_navigation_points_for_realm(player.realm_index)
	if navigation_points.is_empty():
		return []

	var nodes: Array[Vector2] = [player.global_position]
	nodes.append_array(navigation_points)
	var goal_index: int = 1
	var best_goal_score: float = INF
	for index in range(1, nodes.size()):
		var goal_offset: Vector2 = nodes[index] - desired_goal
		var goal_score: float = absf(goal_offset.x) + absf(goal_offset.y) * 1.7
		if goal_score < best_goal_score:
			best_goal_score = goal_score
			goal_index = index

	var open_nodes: Array[int] = [0]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {0: 0.0}
	var f_score: Dictionary = {0: player.global_position.distance_to(nodes[goal_index])}
	while not open_nodes.is_empty():
		var current: int = _lowest_score_node(open_nodes, f_score)
		if current == goal_index:
			return _reconstruct_navigation_path(nodes, came_from, current)
		open_nodes.erase(current)
		for neighbor in nodes.size():
			if neighbor == current or not _navigation_link_is_reachable(nodes[current], nodes[neighbor]):
				continue
			var tentative_score: float = float(g_score.get(current, INF)) + _navigation_link_cost(nodes[current], nodes[neighbor])
			if tentative_score >= float(g_score.get(neighbor, INF)):
				continue
			came_from[neighbor] = current
			g_score[neighbor] = tentative_score
			f_score[neighbor] = tentative_score + nodes[neighbor].distance_to(nodes[goal_index])
			if not open_nodes.has(neighbor):
				open_nodes.append(neighbor)
	return []

func _lowest_score_node(open_nodes: Array[int], scores: Dictionary) -> int:
	var best_node: int = open_nodes[0]
	var best_score: float = float(scores.get(best_node, INF))
	for node in open_nodes:
		var score: float = float(scores.get(node, INF))
		if score < best_score:
			best_score = score
			best_node = node
	return best_node

func _reconstruct_navigation_path(nodes: Array[Vector2], came_from: Dictionary, current: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	while current != 0:
		result.push_front(nodes[current])
		if not came_from.has(current):
			return []
		current = int(came_from[current])
	return result

func _navigation_link_is_reachable(from: Vector2, to: Vector2) -> bool:
	var delta: Vector2 = to - from
	var horizontal: float = absf(delta.x)
	if absf(delta.y) <= NAV_SAME_LEVEL:
		return horizontal <= NAV_HORIZONTAL_REACH
	if delta.y < 0.0:
		return -delta.y <= NAV_JUMP_RISE and horizontal <= NAV_JUMP_REACH
	return delta.y <= NAV_DROP_DEPTH and horizontal >= NAV_DROP_MIN_HORIZONTAL and horizontal <= NAV_DROP_REACH

func _navigation_link_cost(from: Vector2, to: Vector2) -> float:
	var delta: Vector2 = to - from
	var vertical_penalty: float = -delta.y * 0.8 if delta.y < 0.0 else delta.y * 0.25
	return delta.length() + vertical_penalty

func _clear_navigation_path() -> void:
	navigation_path.clear()
	navigation_index = 0
	navigation_goal = Vector2.INF
	planned_drop_direction = 0.0
	planned_drop_target = Vector2.INF

func _choose_wander_point(player) -> Vector2:
	var safe_points: Array[Vector2] = []
	var parent: Node = player.get_parent()
	var available_points: Array[Vector2] = player.spawn_points
	if parent != null and parent.has_method("get_ai_navigation_points_for_realm"):
		available_points = parent.get_ai_navigation_points_for_realm(player.realm_index)
	for point in available_points:
		var local_x: float = point.x - player.realm_origin.x
		var distance: float = player.global_position.distance_to(point)
		if local_x >= 120.0 * GAME_SCALE.WORLD and local_x <= player.realm_size.x - 120.0 * GAME_SCALE.WORLD and distance >= 320.0 * GAME_SCALE.WORLD and distance <= 1250.0 * GAME_SCALE.WORLD:
			safe_points.append(point)
	if safe_points.is_empty():
		return player.realm_origin + Vector2(player.realm_size.x * 0.5, player.realm_size.y * 0.75)
	var index: int = randi_range(0, safe_points.size() - 1)
	return safe_points[index]

func _direction_to(from_x: float, to_x: float) -> float:
	if absf(to_x - from_x) <= 38.0:
		return 0.0
	return signf(to_x - from_x)

func _update_stuck(player, delta: float) -> void:
	if stuck_anchor == Vector2.ZERO:
		stuck_anchor = player.global_position
		return
	if absf(last_commanded_move) > 0.01 and player.global_position.distance_to(stuck_anchor) < STUCK_DISTANCE:
		stuck_timer += delta
	else:
		stuck_timer = 0.0
		stuck_anchor = player.global_position

func _realm_is_warning(player) -> bool:
	var parent: Node = player.get_parent()
	return parent != null and parent.has_method("get_realm_state") and parent.get_realm_state(player.realm_index) == "warning"

func _find_portal_target(player) -> Dictionary:
	var parent: Node = player.get_parent()
	if parent == null or not parent.has_method("get_ai_portals_for_realm"):
		return {}
	var portals: Array = parent.get_ai_portals_for_realm(player.realm_index)
	var best: Dictionary = {}
	var best_score: float = INF
	for portal in portals:
		var score: float = player.global_position.distance_to(portal.rect.get_center())
		if portal.destination_state == "warning":
			score += 800.0
		if score < best_score:
			best_score = score
			best = portal
	return best

func _try_use_portal(player) -> bool:
	if portal_target.is_empty() or not player.is_on_floor():
		return false
	var rect: Rect2 = portal_target.rect
	if not rect.grow(PORTAL_REACHED).has_point(player.global_position):
		return false
	var parent: Node = player.get_parent()
	if parent != null and parent.has_method("move_ai_through_portal"):
		parent.move_ai_through_portal(player, portal_target)
		return true
	return false

func update_offscreen_realm(player, delta: float, combatants: Array[Node], portals: Array[Dictionary], current_state: String, get_realm_state: Callable, get_grid_distance: Callable) -> Dictionary:
	offscreen_timer = maxf(offscreen_timer - delta, 0.0)
	if offscreen_timer > 0.0 or portals.is_empty():
		return {}
	offscreen_timer = randf_range(OFFSCREEN_THINK_MIN, OFFSCREEN_THINK_MAX)
	if current_state == "warning":
		return _pick_escape_portal(portals, get_realm_state)
	if portal_cooldown > 0.0:
		return {}

	var local_opponents: Array[Node] = _offscreen_opponents(player, combatants)
	if not local_opponents.is_empty() and randf() < OFFSCREEN_STAY_CHANCE:
		return {}
	var target_realm: int = _offscreen_target_realm(player, combatants)
	if target_realm >= 0 and randf() < OFFSCREEN_CHASE_CHANCE:
		return _portal_toward_realm(portals, target_realm, get_realm_state, get_grid_distance)
	if randf() < OFFSCREEN_WANDER_CHANCE:
		return _random_safe_portal(portals, get_realm_state)
	return {}

func _offscreen_opponents(player, combatants: Array[Node]) -> Array[Node]:
	var result: Array[Node] = []
	for candidate in combatants:
		if candidate != player and is_instance_valid(candidate) and not candidate.is_dummy and not candidate.is_defeated and candidate.realm_index == player.realm_index:
			result.append(candidate)
	return result

func _offscreen_target_realm(player, combatants: Array[Node]) -> int:
	var candidates: Array[Node] = []
	for candidate in combatants:
		if candidate != player and is_instance_valid(candidate) and not candidate.is_dummy and not candidate.is_defeated and candidate.realm_index != player.realm_index:
			candidates.append(candidate)
	if candidates.is_empty():
		return -1
	var index: int = randi_range(0, candidates.size() - 1)
	return candidates[index].realm_index

func _pick_escape_portal(portals: Array[Dictionary], get_realm_state: Callable) -> Dictionary:
	var stable: Array[Dictionary] = []
	for portal in portals:
		if str(get_realm_state.call(portal.destination)) == "stable":
			stable.append(portal)
	return _random_portal(stable if not stable.is_empty() else portals)

func _portal_toward_realm(portals: Array[Dictionary], target_realm: int, get_realm_state: Callable, get_grid_distance: Callable) -> Dictionary:
	var best: Dictionary = {}
	var best_score: float = INF
	for portal in portals:
		var score: float = float(get_grid_distance.call(portal.destination, target_realm)) * 100.0
		if str(get_realm_state.call(portal.destination)) == "warning":
			score += 300.0
		if score < best_score:
			best_score = score
			best = portal
	return best

func _random_safe_portal(portals: Array[Dictionary], get_realm_state: Callable) -> Dictionary:
	var safe: Array[Dictionary] = []
	for portal in portals:
		if str(get_realm_state.call(portal.destination)) != "warning":
			safe.append(portal)
	return _random_portal(safe if not safe.is_empty() else portals)

func _random_portal(portals: Array[Dictionary]) -> Dictionary:
	if portals.is_empty():
		return {}
	var index: int = randi_range(0, portals.size() - 1)
	return portals[index]

## A combat profile with its distances times the attack reach scale.
static func _scaled_profile(profile: Dictionary) -> Dictionary:
	var scaled := profile.duplicate()
	for key in ["min_range", "max_range", "attack_range", "basic_reach"]:
		if profile.has(key):
			scaled[key] = float(profile[key]) * GAME_SCALE.COMBAT
	return scaled

## One bot's current plan for the dev panel and probes (state, engage action, target, last
## intent, reason). Gap is the target's offset from the fighter.
func debug_snapshot(player) -> Dictionary:
	var target_kind := ""
	var target_name := ""
	var gap := Vector2.ZERO
	if is_instance_valid(target):
		if target.is_in_group("players"):
			target_kind = "player"
			target_name = str(target.get("display_name"))
		elif target.is_in_group("soul_crystals"):
			target_kind = "crystal"
			target_name = "Soul crystal"
		else:
			target_kind = "monster"
			target_name = str(target.get("display_name")) if target.get("display_name") != null else "Monster"
		gap = target.global_position - player.global_position
	return {
		"state": state,
		"action": action if state == STATE_ENGAGE else "",
		"reason": debug_reason,
		"target_kind": target_kind,
		"target": target_name,
		"gap": gap,
		"move": float(last_intent.get("move", 0.0)),
		"jump": bool(last_intent.get("jump", false)),
		"attack": str(last_intent.get("attack", "")),
		"portal_destination": int(portal_target.get("destination", -1)) if state == STATE_PORTAL else -1,
		"stuck": stuck_timer,
	}

## Aim for an attack toward the target's body: steep enough means an up or down attack,
## otherwise sideways. Mobility skills (Frey, Nova, Rio skill 1) never aim down, so a dash
## does not carry the bot off a ledge.
func _attack_aim(player, attack_name: String) -> Vector2:
	if not is_instance_valid(target):
		return Vector2.ZERO
	var offset: Vector2 = _predicted_target_position() - player.global_position
	if offset.length() < 1.0:
		return Vector2(float(player.facing), 0.0)
	var side: float = signf(offset.x) if absf(offset.x) > 1.0 else float(player.facing)
	if attack_name == "skill_1" and ["frey", "nova", "rio"].has(player.character_id):
		var dash := offset.normalized()
		dash.y = minf(dash.y, 0.2)
		return dash.normalized()
	if attack_name != "basic":
		return offset.normalized()
	if absf(offset.y) >= AIM_VERTICAL_MIN and absf(offset.y) >= AIM_VERTICAL_SLOPE * absf(offset.x):
		# A down attack in the air is a dive for some fighters (Nova, Rio): only over floor
		# (debate D7).
		if offset.y > 0.0 and not player.is_on_floor() and (_over_void(player) or not _has_drop_landing(player, side)):
			return Vector2(side, 0.0)
		return Vector2(0.3 * side, signf(offset.y)).normalized()
	return Vector2(side, 0.0)

## Guard against an attack an opponent in reach has just started. Returns true while the
## bot is guarding or about to (the guard takes over its turn).
func _update_guard(player, delta: float) -> bool:
	var threat := pending_threat
	if player.is_guarding:
		guard_hold_timer -= delta
		if guard_hold_timer <= 0.0:
			player._stop_guard(true)
			return false
		return true
	if guard_delay_timer >= 0.0:
		guard_delay_timer -= delta
		if guard_delay_timer < 0.0:
			# Past the wind-up, the guard still goes up while the attacker stays close and faces
			# us: its next swing is coming (round 3: skipping these cut blocks and parries from
			# 463 to 155).
			if not _swing_still_coming(guard_threat_from) and not _attacker_close(player, guard_threat_from):
				debug_reason = "too late to block"
				return false
			if _start_guard_against(player, guard_threat_from):
				guard_hold_timer = randf_range(GUARD_HOLD_MIN, GUARD_HOLD_MAX)
				debug_reason = "blocking an attack"
				return true
		return false
	if threat != null and randf() < GUARD_CHANCE:
		guard_threat_from = threat
		guard_delay_timer = randf_range(GUARD_REACTION_MIN, GUARD_REACTION_MAX)
	return false

## Raises guard toward an opponent (PlayerBase reads guard_aim when the guard starts).
func _start_guard_against(player, opponent: Node) -> bool:
	if is_instance_valid(opponent):
		# Along the main axis toward the attacker, so attacks from straight above or below are
		# guarded too (debate N1; PlayerBase turns it into a cardinal direction).
		var toward: Vector2 = opponent.global_position - player.global_position
		guard_aim = Vector2(0.0, signf(toward.y)) if absf(toward.y) > absf(toward.x) else Vector2(signf(toward.x), 0.0)
	player._try_start_guard()
	guard_aim = Vector2.ZERO
	return bool(player.is_guarding)

## Debate D3: sometimes guard ahead of a swing, when an opponent in reach faces us and we are
## not attacking. Called once per engage decision.
func _maybe_anticipate_guard(player, chance := GUARD_ANTICIPATE_CHANCE) -> void:
	if player.is_guarding or player.attack_lock_timer > 0.0 or not player.is_on_floor() or not is_instance_valid(target) or not target.is_in_group("players"):
		return
	var offset: Vector2 = player.global_position - target.global_position
	var reach: float = float(_scaled_profile(COMBAT_PROFILES.get(target.character_id, DEFAULT_COMBAT_PROFILE)).attack_range)
	var facing_us := signf(offset.x) == float(target.facing)
	if facing_us and absf(offset.x) <= reach and absf(offset.y) <= GUARD_HEIGHT * GAME_SCALE.COMBAT and randf() < chance:
		if _start_guard_against(player, target):
			guard_hold_timer = randf_range(GUARD_ANTICIPATE_MIN, GUARD_ANTICIPATE_MAX)
			debug_reason = "guarding ahead of a swing"

## The opponent who, this frame, starts a swing at this bot from within its reach (or null).
func _new_attack_threat(player) -> Node:
	var threat: Node = null
	for candidate in player.get_tree().get_nodes_in_group("players"):
		if candidate == player:
			continue
		# Every fighter is recorded every frame before any filter, so one that comes into view
		# or into the realm mid-swing is not taken for a fresh swing.
		var lock := float(candidate.attack_lock_timer)
		var serial := int(candidate.get("attack_serial") if candidate.get("attack_serial") != null else 0)
		var seen: Array = watched_attack_locks.get(candidate, [lock, serial])
		watched_attack_locks[candidate] = [lock, serial]
		var started: bool = serial != int(seen[1]) or (lock > 0.0 and float(seen[0]) <= 0.0)
		if not started or not _is_valid_target_candidate(player, candidate):
			continue
		var offset: Vector2 = player.global_position - candidate.global_position
		var facing_us := signf(offset.x) == float(candidate.facing) or absf(offset.x) < 24.0
		var reach: float = float(_scaled_profile(COMBAT_PROFILES.get(candidate.character_id, DEFAULT_COMBAT_PROFILE)).attack_range) + GUARD_REACH_MARGIN * GAME_SCALE.COMBAT
		if facing_us and absf(offset.x) <= reach and absf(offset.y) <= GUARD_HEIGHT * GAME_SCALE.COMBAT and player.is_on_floor():
			threat = candidate
	return threat

func _alive_fighters(player) -> int:
	var count := 0
	for candidate in player.get_tree().get_nodes_in_group("players"):
		if is_instance_valid(candidate) and not bool(candidate.get("is_defeated")) and not bool(candidate.get("is_dummy")):
			count += 1
	return count

## Where the target will be shortly (bodies are aimed at, not where they were).
func _predicted_target_position() -> Vector2:
	if not is_instance_valid(target):
		return Vector2.ZERO
	var motion: Variant = target.get("velocity")
	return target.global_position + (motion as Vector2 if motion is Vector2 else Vector2.ZERO) * TARGET_LEAD_TIME

## A route over the navigation graph ends near the point (same platform level).
func _has_route_to(player, point: Vector2) -> bool:
	var route: Array[Vector2] = _plan_navigation_path(player, point)
	if route.is_empty():
		return false
	var end: Vector2 = route[route.size() - 1]
	return absf(end.y - point.y) <= NAV_SAME_LEVEL * 1.5

## Drops a target that stays on another level without getting closer (debate 2026-10-08).
func _update_target_progress(player, delta: float) -> void:
	if not is_instance_valid(target) or (state != STATE_ENGAGE and state != STATE_PURSUE):
		progress_target = null
		return
	var distance: float = player.global_position.distance_to(target.global_position)
	if target != progress_target:
		progress_target = target
		progress_best = distance
		progress_timer = 0.0
		return
	# Closer, trading hits, or standing on our level (judged by floors, so a jump or a launch
	# is not "another level") all count as progress.
	if distance < progress_best - PROGRESS_DISTANCE * GAME_SCALE.WORLD or _trading_hits(player, target) or not _stands_on_other_level(player, target):
		progress_best = minf(progress_best, distance)
		progress_timer = 0.0
		return
	progress_timer += delta
	if progress_timer >= PROGRESS_TIME and target != progress_extended and distance <= PROGRESS_KEEP_NEAR * GAME_SCALE.WORLD and _has_route_to(player, _standing_point(player, target)):
		# One more window on a fresh route; after that it is dropped like any other.
		progress_extended = target
		progress_timer = 0.0
		progress_best = distance
		_clear_navigation_path()
		return
	if progress_timer >= PROGRESS_TIME:
		ignored_targets[target] = IGNORE_TIME
		debug_reason = "gave up: target out of reach"
		target = null
		target_lock_timer = 0.0
		progress_target = null
		decision_timer = 0.0

## How good a moment this is for the ultimate: +2 target within its reach, +1 target low (35%),
## +1 target stunned or mid-swing, +1 another opponent near it, -3 Nova's launch near a ledge.
func _ultimate_score(player) -> int:
	if not is_instance_valid(target):
		return 0
	var score := 0
	var distance: float = player.global_position.distance_to(target.global_position)
	if distance <= float(ULTIMATE_REACH.get(player.character_id, 400.0)):
		score += 2
	if float(target.hp) / maxf(float(target.max_hp), 1.0) <= 0.35:
		score += 1
	if float(target.hitstun_timer) > 0.0 or float(target.attack_lock_timer) > 0.0:
		score += 1
	for other in player.get_tree().get_nodes_in_group("players"):
		if other != player and other != target and _is_valid_target_candidate(player, other) and other.global_position.distance_to(target.global_position) <= 260.0 * GAME_SCALE.COMBAT:
			score += 1
			break
	if player.character_id == "nova" and not _mobility_skill_is_safe(player):
		score -= 3
	# Luna's ultimate is a 6 s transformation: worth more while she can stay in the fight.
	if player.character_id == "luna" and float(player.hp) / maxf(float(player.max_hp), 1.0) >= 0.5:
		score += 1
	return score

## Nova's three-press slingshot, aimed: orbit shortly after the core, launch when the tangent
## points at the target (or at 0.8 s), then redirect once if the launch is off.
func _drive_nova_slingshot(player, delta: float) -> void:
	if player.character_id != "nova":
		return
	var phase := int(player.get("ultimate_phase"))
	if phase == 0:
		nova_stage_timer = -1.0
		nova_redirect_timer = -1.0
		return
	if phase == 1:
		if nova_stage_timer < 0.0:
			nova_stage_timer = randf_range(NOVA_ORBIT_DELAY_MIN, NOVA_ORBIT_DELAY_MAX)
		nova_stage_timer -= delta
		if nova_stage_timer <= 0.0:
			nova_stage_timer = 0.0
			player.ultimate()
		return
	if phase == 2:
		nova_stage_timer += delta
		var tangent: Vector2 = player._get_ultimate_tangent()
		var core: Vector2 = player.ultimate_center
		var collapse_radius: float = float(player.ULTIMATE_COLLAPSE_RADIUS) * GAME_SCALE.COMBAT
		var wanted: Vector2
		var tolerance := NOVA_LAUNCH_ANGLE
		if is_instance_valid(target) and target.global_position.distance_to(core) > collapse_radius:
			wanted = (_predicted_target_position() - player.global_position).normalized()
		else:
			# A target at the core is the collapse's (debate D4: the tangent is ~90 degrees from
			# it); launch toward the realm's floor centre, a safe landing.
			wanted = (Vector2(player.realm_origin.x + player.realm_size.x * 0.5, player.global_position.y + 40.0) - player.global_position).normalized()
			tolerance = 30.0
		if nova_stage_timer >= NOVA_LAUNCH_LATEST or rad_to_deg(absf(tangent.angle_to(wanted))) <= tolerance:
			player.ultimate()
			nova_redirect_timer = randf_range(NOVA_REDIRECT_DELAY_MIN, NOVA_REDIRECT_DELAY_MAX)
		return
	if phase == 3 and nova_redirect_timer >= 0.0:
		nova_redirect_timer -= delta
		if nova_redirect_timer < 0.0 and is_instance_valid(target):
			var wanted_launch: Vector2 = (_predicted_target_position() - player.global_position).normalized()
			var launch: Vector2 = player.ultimate_launch_direction
			if rad_to_deg(absf(launch.angle_to(wanted_launch))) > NOVA_REDIRECT_ANGLE and randf() < NOVA_REDIRECT_CHANCE:
				aim_direction = wanted_launch
				player.skill_one()

## Living opponents in a realm (for choosing where to retreat).
func _opponents_in_realm(player, realm: int) -> int:
	var count := 0
	for candidate in player.get_tree().get_nodes_in_group("players"):
		if candidate != player and int(candidate.get("realm_index")) == realm and not bool(candidate.get("is_defeated")) and not bool(candidate.get("is_dummy")):
			count += 1
	return count

## Where a body stands: its own position on a floor, the floor under it while airborne, or INF
## over the void.
func _standing_point(player, body: Node) -> Vector2:
	var at: Vector2 = body.global_position
	if not (body is CharacterBody2D) or (body as CharacterBody2D).is_on_floor():
		return at
	var query := PhysicsRayQueryParameters2D.create(at + Vector2(0.0, -4.0), at + Vector2(0.0, STANDING_PROBE_DEPTH), WORLD_LAYER, [player.get_rid()])
	var hit: Dictionary = player.get_world_2d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else Vector2.INF

## Both stand on floors more than a level apart.
func _stands_on_other_level(player, body: Node) -> bool:
	var own: Vector2 = _standing_point(player, player)
	var theirs: Vector2 = _standing_point(player, body)
	if own == Vector2.INF or theirs == Vector2.INF:
		return false
	return absf(theirs.y - own.y) > NAV_SAME_LEVEL

## One of us hit the other within TRADE_MEMORY (fighters keep a countdown from their attacker
## memory; monsters and crystals the physics frame of the last hit), or a monster is after us.
func _trading_hits(player, body: Node) -> bool:
	if _is_recent_attacker(player, body):
		return true
	if body.get("last_attacker") != player:
		return body.is_in_group("realm_monsters") and body.get("target") == player
	var timer: Variant = body.get("last_attacker_timer")
	if timer != null:
		return float(timer) > FIGHTER_ATTACKER_MEMORY - TRADE_MEMORY
	var frame: Variant = body.get("last_hit_frame")
	return frame != null and Engine.get_physics_frames() - int(frame) <= int(TRADE_MEMORY * Engine.physics_ticks_per_second)

## The attacker a guard reacts to is still in reach, facing us, in our realm.
func _attacker_close(player, opponent: Node) -> bool:
	if not is_instance_valid(opponent) or not _is_valid_target_candidate(player, opponent):
		return false
	var offset: Vector2 = player.global_position - opponent.global_position
	var facing_us := signf(offset.x) == float(opponent.facing) or absf(offset.x) < 24.0
	var reach: float = float(_scaled_profile(COMBAT_PROFILES.get(opponent.character_id, DEFAULT_COMBAT_PROFILE)).attack_range) + GUARD_REACH_MARGIN * GAME_SCALE.COMBAT
	return facing_us and absf(offset.x) <= reach and absf(offset.y) <= GUARD_HEIGHT * GAME_SCALE.COMBAT

## On a floor with a ledge (no floor) within RETREAT_EDGE_MARGIN behind, away from the target.
func _cornered(player, target_direction: float) -> bool:
	if not player.is_on_floor():
		return false
	var back := -target_direction
	return not _has_floor_ahead(player, back, RETREAT_EDGE_MARGIN * 0.5) or not _has_floor_ahead(player, back, RETREAT_EDGE_MARGIN)

## The swing a guard reacts to can still land: it is on, and not past its wind-up by more than
## GUARD_LATE_GRACE.
func _swing_still_coming(opponent: Node) -> bool:
	if not is_instance_valid(opponent) or float(opponent.get("attack_lock_timer")) <= 0.0:
		return false
	var elapsed: Variant = opponent.get("attack_elapsed")
	var startup: Variant = opponent.get("attack_startup")
	if elapsed == null or startup == null:
		return true
	return float(elapsed) <= float(startup) + GUARD_LATE_GRACE
