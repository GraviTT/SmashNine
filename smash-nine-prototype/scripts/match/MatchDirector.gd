extends Node
## Match timeline: realm states, collapse warnings, central realm opening and
## ring-out pressure. Owns the rules; Main reacts to its signals.

signal realm_state_changed(realm_index: int, state: String)
signal announcement(text: String)

const STATE_STABLE := "stable"
const STATE_WARNING := "warning"
const STATE_COLLAPSED := "collapsed"
const STATE_LOCKED := "locked"
const CENTRAL_OPEN_TIME := 210.0
const FIRST_COLLAPSE_WARNING_TIME := 35.0
const COLLAPSE_WARNING_DURATION := 18.0
const COLLAPSE_INTERVAL := 42.0
const MATCH_TARGET_TIME := 360.0

var realm_names: Array[String] = []
var central_index := -1
var realm_states: Array[String] = []
var collapse_order: Array[int] = []
var match_elapsed := 0.0
var next_warning_time := FIRST_COLLAPSE_WARNING_TIME
var warning_realm_index := -1
var warning_timer := 0.0

func setup(names: Array[String], new_central_index: int) -> void:
	realm_names = names.duplicate()
	central_index = new_central_index
	match_elapsed = 0.0
	next_warning_time = FIRST_COLLAPSE_WARNING_TIME
	warning_realm_index = -1
	warning_timer = 0.0
	realm_states.clear()
	collapse_order.clear()
	for i in realm_names.size():
		realm_states.append(STATE_LOCKED if i == central_index else STATE_STABLE)
		if i != central_index:
			collapse_order.append(i)
	collapse_order.shuffle()

func advance(delta: float) -> void:
	match_elapsed += delta
	if get_state(central_index) == STATE_LOCKED and match_elapsed >= CENTRAL_OPEN_TIME:
		_set_state(central_index, STATE_STABLE)
		announcement.emit("Central realm opened: %s. Surviving realms now converge." % realm_names[central_index])
	if warning_realm_index >= 0:
		warning_timer = maxf(warning_timer - delta, 0.0)
		if warning_timer <= 0.0:
			_collapse_warned_realm()
	elif match_elapsed >= next_warning_time and not collapse_order.is_empty():
		_start_realm_warning()

func _start_realm_warning() -> void:
	warning_realm_index = collapse_order.pop_front()
	warning_timer = COLLAPSE_WARNING_DURATION
	_set_state(warning_realm_index, STATE_WARNING)
	announcement.emit("Collapse warning: %s will fall soon. Move to a safer realm." % realm_names[warning_realm_index])

func _collapse_warned_realm() -> void:
	var collapsed_index := warning_realm_index
	warning_realm_index = -1
	next_warning_time = match_elapsed + COLLAPSE_INTERVAL
	_set_state(collapsed_index, STATE_COLLAPSED)
	announcement.emit("%s collapsed. Ring-out pressure is rising." % realm_names[collapsed_index])

func _set_state(realm_index: int, state: String) -> void:
	realm_states[realm_index] = state
	realm_state_changed.emit(realm_index, state)

func get_state(realm_index: int) -> String:
	if realm_index < 0 or realm_index >= realm_states.size():
		return STATE_STABLE
	return realm_states[realm_index]

func is_playable(realm_index: int) -> bool:
	var state := get_state(realm_index)
	return state == STATE_STABLE or state == STATE_WARNING

func get_playable_indices() -> Array[int]:
	var playable: Array[int] = []
	for i in realm_states.size():
		if is_playable(i):
			playable.append(i)
	return playable

func find_safe_realm() -> int:
	var playable := get_playable_indices()
	if playable.is_empty() or playable.has(central_index):
		return central_index
	return playable.pick_random()

func get_warning_seconds_left() -> int:
	return maxi(0, int(ceil(warning_timer)))

func get_ringout_pressure() -> float:
	return 1.0 + clampf(match_elapsed / MATCH_TARGET_TIME, 0.0, 1.0) * 1.4

func get_phase_name() -> String:
	if match_elapsed < FIRST_COLLAPSE_WARNING_TIME:
		return "Early exploration"
	if get_state(central_index) == STATE_LOCKED:
		return "Mid collapse"
	if get_playable_indices().size() <= 3:
		return "Final brawl"
	return "Late convergence"
