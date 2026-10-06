extends Node
## Owns the match rules (design/DECISIONS.md D1-D3): the wave timeline, realm
## states, collapse penalty, ring-out damage per phase, sudden death, elimination
## order and the winner. Time only moves through advance(delta), so tests can
## drive it with virtual time.

signal realm_state_changed(realm_index: int, state: String)
signal announcement(text: String)
signal phase_changed(phase: String)
signal combatant_relocated(combatant: Node, realm_index: int)
signal match_finished(winner: Node, reason: String)

const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")

const STATE_STABLE := "stable"
const STATE_WARNING := "warning"
const STATE_COLLAPSED := "collapsed"
const STATE_LOCKED := "locked"

const PHASE_EXPLORATION := "Exploration"
const PHASE_CORNER_WARNING := "Corner collapse warning"
const PHASE_CONVERGENCE := "Convergence"
const PHASE_CENTRAL := "Central brawl"
const PHASE_SUDDEN_DEATH := "Sudden death"
const PHASE_OVER := "Match over"

const WAVE_ONE_WARNING := 120.0
const WAVE_ONE_COLLAPSE := 150.0
const CENTRAL_OPEN := 210.0
const WAVE_TWO_WARNING := 210.0
const WAVE_TWO_COLLAPSE := 240.0
const SUDDEN_DEATH_START := 360.0
const FINAL_JUDGMENT := 420.0

const RINGOUT_DAMAGE := {
	PHASE_EXPLORATION: 20.0,
	PHASE_CORNER_WARNING: 20.0,
	PHASE_CONVERGENCE: 25.0,
	PHASE_CENTRAL: 30.0,
	PHASE_SUDDEN_DEATH: 40.0,
	PHASE_OVER: 40.0
}
## Combat damage multiplier for a permanent-elimination match. Character numbers were
## tuned for respawning; fixed ring-out damage is not scaled, so position matters more.
const COMBAT_DAMAGE_SCALE := 0.26
## Out-of-combat HP regeneration per second, by phase ("early phases allow more recovery").
const RECOVERY_RATE := {
	PHASE_EXPLORATION: 3.0,
	PHASE_CORNER_WARNING: 3.0,
	PHASE_CONVERGENCE: 1.5,
	PHASE_CENTRAL: 0.0,
	PHASE_SUDDEN_DEATH: 0.0,
	PHASE_OVER: 0.0
}
## How eagerly bots pick fights with players (0..1). Early on they farm souls and only retaliate.
const BOT_AGGRESSION := {
	PHASE_EXPLORATION: 0.3,
	PHASE_CORNER_WARNING: 0.45,
	PHASE_CONVERGENCE: 0.7,
	PHASE_CENTRAL: 1.0,
	PHASE_SUDDEN_DEATH: 1.0,
	PHASE_OVER: 1.0
}
const COLLAPSE_PENALTY := 30.0
const SUDDEN_DEATH_MIN_FRACTION := 0.2
const SUDDEN_DEATH_DAMAGE_PER_SECOND := 8.0

var layout: REALM_LAYOUT
var central_index := -1
var realm_states: Array[String] = []
var match_elapsed := 0.0
var phase := PHASE_EXPLORATION
var events: Array[Dictionary] = []
var next_event_index := 0
var warning_realms: Array[int] = []
var warning_ends_at := 0.0
var combatants: Array[Node] = []
var elimination_order: Array[Node] = []
var match_over := false
var winner: Node
var finish_reason := ""
var _batch_depth := 0
var _survivor_check_queued := false
var _eliminated_since_check: Array[Node] = []

func setup(new_layout: REALM_LAYOUT) -> void:
	layout = new_layout
	central_index = REALM_LAYOUT.CENTRAL_REALM_INDEX
	match_elapsed = 0.0
	phase = PHASE_EXPLORATION
	next_event_index = 0
	warning_realms.clear()
	combatants.clear()
	elimination_order.clear()
	_eliminated_since_check.clear()
	_batch_depth = 0
	match_over = false
	winner = null
	finish_reason = ""
	realm_states.clear()
	for i in layout.realm_count():
		realm_states.append(STATE_LOCKED if i == central_index else STATE_STABLE)
	var corners := layout.get_corner_indices()
	var edges := layout.get_edge_indices()
	events = [
		{"time": WAVE_ONE_WARNING, "kind": "warn", "realms": corners, "phase": PHASE_CORNER_WARNING},
		{"time": WAVE_ONE_COLLAPSE, "kind": "collapse", "realms": corners, "phase": PHASE_CONVERGENCE},
		{"time": CENTRAL_OPEN, "kind": "open", "realms": [central_index]},
		{"time": WAVE_TWO_WARNING, "kind": "warn", "realms": edges},
		{"time": WAVE_TWO_COLLAPSE, "kind": "collapse", "realms": edges, "phase": PHASE_CENTRAL},
		{"time": SUDDEN_DEATH_START, "kind": "sudden_death", "realms": [], "phase": PHASE_SUDDEN_DEATH},
		{"time": FINAL_JUDGMENT, "kind": "judgment", "realms": []}
	]

func register_combatant(combatant: Node) -> void:
	if combatants.has(combatant):
		return
	combatants.append(combatant)
	combatant.defeated.connect(_on_combatant_defeated)

func advance(delta: float) -> void:
	if match_over:
		return
	match_elapsed += delta
	while not match_over and next_event_index < events.size() and match_elapsed >= float(events[next_event_index].time):
		var event: Dictionary = events[next_event_index]
		next_event_index += 1
		_run_event(event)
	if phase == PHASE_SUDDEN_DEATH and not match_over:
		_apply_sudden_death(delta)

func _run_event(event: Dictionary) -> void:
	var realms: Array = event.realms
	match str(event.kind):
		"warn":
			warning_realms.clear()
			for realm_index in realms:
				warning_realms.append(int(realm_index))
			warning_ends_at = match_elapsed + _seconds_until_next("collapse")
			for realm_index in realms:
				_set_state(int(realm_index), STATE_WARNING)
			announcement.emit("Collapse warning: %s will fall in %ds. Reach a safe realm." % [_realm_names(realms), int(round(warning_ends_at - match_elapsed))])
		"collapse":
			warning_realms.clear()
			for realm_index in realms:
				_set_state(int(realm_index), STATE_COLLAPSED)
			_relocate_trapped_combatants(realms)
			announcement.emit("%s collapsed." % _realm_names(realms))
		"open":
			for realm_index in realms:
				_set_state(int(realm_index), STATE_STABLE)
			announcement.emit("%s has opened. Every path now leads to the center." % layout.get_realm(central_index).name)
		"sudden_death":
			announcement.emit("Sudden death: the heart of Yggdrasil is closing in.")
		"judgment":
			_judge_survivors()
	if event.has("phase"):
		_set_phase(str(event.phase))

func _seconds_until_next(kind: String) -> float:
	for index in range(next_event_index, events.size()):
		if str(events[index].kind) == kind:
			return float(events[index].time) - match_elapsed
	return 0.0

func _set_phase(new_phase: String) -> void:
	if phase == new_phase:
		return
	phase = new_phase
	phase_changed.emit(phase)

func _set_state(realm_index: int, state: String) -> void:
	realm_states[realm_index] = state
	realm_state_changed.emit(realm_index, state)

func _realm_names(realms: Array) -> String:
	var names: Array[String] = []
	for realm_index in realms:
		names.append(str(layout.get_realm(int(realm_index)).name))
	return ", ".join(names)

# --- Collapse and hazards ---

## Combatants still inside a collapsing realm lose COLLAPSE_PENALTY HP and are
## moved to the nearest playable realm with brief protection (D1: not instant death).
## One batch for the whole wave: every fighter caught in any collapsing realm loses
## COLLAPSE_PENALTY HP and is moved to the nearest playable realm with brief protection
## (D1: not instant death). Fighters are processed from lowest to highest HP so the
## last-standing rule below always spares the healthiest one.
func _relocate_trapped_combatants(collapsed_realms: Array) -> void:
	var trapped: Array[Node] = []
	for combatant in combatants:
		if _is_alive(combatant) and collapsed_realms.has(combatant.realm_index):
			trapped.append(combatant)
	trapped.sort_custom(_has_less_hp)
	_begin_batch()
	for combatant in trapped:
		var destination := find_safe_realm(combatant.realm_index)
		layout.assign_combatant(combatant, destination)
		combatant.reset_for_map(layout.pick_spawn(destination), layout.get_spawn_points(destination))
		combatant_relocated.emit(combatant, destination)
		combatant.apply_environment_damage(_spare_last_standing(combatant, COLLAPSE_PENALTY))
		if _is_alive(combatant):
			combatant.grant_protection()
	_end_batch()

## Rule (CODEX-ANALYST-02): the environment never eliminates the last fighter standing.
## If this damage would leave nobody alive, the fighter keeps 1 HP instead.
func _spare_last_standing(combatant: Node, damage: float) -> float:
	if combatant.hp - damage > 0.0 or get_alive_combatants().size() > 1:
		return damage
	return maxf(combatant.hp - 1.0, 0.0)

func _has_less_hp(a: Node, b: Node) -> bool:
	if not is_equal_approx(a.hp, b.hp):
		return a.hp < b.hp
	return _ranks_higher(b, a)

## Nearest playable realm by grid distance; the center wins ties once it is open.
func find_safe_realm(from_index := -1) -> int:
	var best := -1
	var best_score := INF
	for i in get_playable_indices():
		var score := 0.0 if from_index < 0 else float(layout.grid_distance(from_index, i))
		if i == central_index:
			score -= 0.5
		if score < best_score:
			best_score = score
			best = i
	return best if best >= 0 else central_index

## Safe band of the central realm in world x; outside it combatants take damage.
func get_sudden_death_band() -> Vector2:
	var bounds: Rect2 = layout.get_bounds(central_index)
	if phase != PHASE_SUDDEN_DEATH:
		return Vector2(bounds.position.x - INF, bounds.end.x + INF)
	var progress := clampf((match_elapsed - SUDDEN_DEATH_START) / (FINAL_JUDGMENT - SUDDEN_DEATH_START), 0.0, 1.0)
	var half_width := bounds.size.x * 0.5 * lerpf(1.0, SUDDEN_DEATH_MIN_FRACTION, progress)
	var center_x := bounds.get_center().x
	return Vector2(center_x - half_width, center_x + half_width)

func _apply_sudden_death(delta: float) -> void:
	var band := get_sudden_death_band()
	var outside: Array[Node] = []
	for combatant in combatants:
		if not _is_alive(combatant) or combatant.realm_index != central_index:
			continue
		var x: float = combatant.global_position.x
		if x < band.x or x > band.y:
			outside.append(combatant)
	outside.sort_custom(_has_less_hp)
	_begin_batch()
	for combatant in outside:
		combatant.apply_environment_damage(_spare_last_standing(combatant, SUDDEN_DEATH_DAMAGE_PER_SECOND * delta))
	_end_batch()

# --- Elimination and result ---

## Eliminations are judged together (CODEX-ANALYST-01 P0): director-run damage
## (collapse, sudden death) is batched and judged when the batch ends; combat
## eliminations are judged at the end of the frame, so a double KO never crowns
## someone who is about to fall in the same step.
func _on_combatant_defeated(combatant: Node, _attacker: Node) -> void:
	if match_over or elimination_order.has(combatant):
		return
	elimination_order.append(combatant)
	_eliminated_since_check.append(combatant)
	if _batch_depth > 0 or _survivor_check_queued:
		return
	_survivor_check_queued = true
	call_deferred("_check_survivors")

func _begin_batch() -> void:
	_batch_depth += 1

func _end_batch() -> void:
	_batch_depth -= 1
	if _batch_depth == 0 and not _eliminated_since_check.is_empty():
		_check_survivors()

func _check_survivors() -> void:
	_survivor_check_queued = false
	var fallen := _eliminated_since_check.duplicate()
	_eliminated_since_check.clear()
	if match_over or _batch_depth > 0:
		return
	var alive := get_alive_combatants()
	if alive.size() == 1:
		_finish(alive[0], "last survivor")
	elif alive.is_empty() and not fallen.is_empty():
		# Only combat can get here (environment damage spares the last fighter):
		# the last fighters knocked each other out in the same frame. Nobody wins.
		_finish(null, "double KO")

## At FINAL_JUDGMENT the survivor with the most HP wins (prototype safety net, D3).
func _judge_survivors() -> void:
	var alive := get_alive_combatants()
	if alive.is_empty():
		_finish(null, "no survivors")
		return
	alive.sort_custom(_ranks_higher)
	_finish(alive[0], "final judgment")

func _ranks_higher(a: Node, b: Node) -> bool:
	if not is_equal_approx(a.hp, b.hp):
		return a.hp > b.hp
	if a.score != b.score:
		return a.score > b.score
	return a.player_id < b.player_id

func _finish(new_winner: Node, reason: String) -> void:
	if match_over:
		return
	match_over = true
	winner = new_winner
	finish_reason = reason
	_set_phase(PHASE_OVER)
	var winner_name: String = new_winner.display_name if is_instance_valid(new_winner) else "Nobody"
	announcement.emit("%s wins (%s)." % [winner_name, reason])
	match_finished.emit(new_winner, reason)

## Final standings, best first: winner, other survivors by rank, then eliminated in reverse order.
func get_standings() -> Array[Node]:
	var standings: Array[Node] = []
	if is_instance_valid(winner):
		standings.append(winner)
	var alive := get_alive_combatants()
	alive.sort_custom(_ranks_higher)
	for combatant in alive:
		if combatant != winner:
			standings.append(combatant)
	for index in range(elimination_order.size() - 1, -1, -1):
		var combatant: Node = elimination_order[index]
		if is_instance_valid(combatant) and not standings.has(combatant):
			standings.append(combatant)
	return standings

func get_alive_combatants() -> Array[Node]:
	var alive: Array[Node] = []
	for combatant in combatants:
		if _is_alive(combatant):
			alive.append(combatant)
	return alive

func _is_alive(combatant: Node) -> bool:
	return is_instance_valid(combatant) and not combatant.is_defeated

# --- Queries ---

func get_state(realm_index: int) -> String:
	if realm_index < 0 or realm_index >= realm_states.size():
		return STATE_STABLE
	return realm_states[realm_index]

func is_warning(realm_index: int) -> bool:
	return get_state(realm_index) == STATE_WARNING

func is_playable(realm_index: int) -> bool:
	var state := get_state(realm_index)
	return state == STATE_STABLE or state == STATE_WARNING

func get_playable_indices() -> Array[int]:
	var playable: Array[int] = []
	for i in realm_states.size():
		if is_playable(i):
			playable.append(i)
	return playable

func get_warning_seconds_left() -> int:
	if warning_realms.is_empty():
		return 0
	return maxi(0, int(ceil(warning_ends_at - match_elapsed)))

func get_ringout_damage() -> float:
	return float(RINGOUT_DAMAGE.get(phase, 20.0))

func get_combat_damage_scale() -> float:
	return COMBAT_DAMAGE_SCALE

func get_bot_aggression() -> float:
	return float(BOT_AGGRESSION.get(phase, 1.0))

func get_recovery_rate() -> float:
	return float(RECOVERY_RATE.get(phase, 0.0))

func get_phase_name() -> String:
	return phase

## Seconds until the next scheduled event, for the HUD clock.
func get_next_event_in() -> float:
	if next_event_index >= events.size():
		return 0.0
	return maxf(float(events[next_event_index].time) - match_elapsed, 0.0)

func get_next_event_label() -> String:
	if next_event_index >= events.size():
		return ""
	match str(events[next_event_index].kind):
		"warn":
			return "Collapse warning"
		"collapse":
			return "Collapse"
		"open":
			return "Center opens"
		"sudden_death":
			return "Sudden death"
		"judgment":
			return "Final judgment"
	return ""
