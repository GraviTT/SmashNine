extends "res://scripts/match/MatchDirector.gd"
## Story owns objective completion; it never executes the battle-royale timeline/survivor rule.
const CATALOG := preload("res://scripts/story/StoryCatalog.gd")
var stage_data: Dictionary = {}
var difficulty := "normal"
var hero: Node
var running := false
var exit_open := false
var exit_realm := -1

func configure(data: Dictionary, level: String) -> void:
	stage_data = data
	difficulty = level

func setup(new_layout: REALM_LAYOUT) -> void:
	super.setup(new_layout)
	events.clear()
	for index in realm_states.size():
		realm_states[index] = STATE_STABLE if index == int(stage_data.realm) else STATE_LOCKED
	phase = "Story"
	var direction: Vector2i = stage_data.exit
	if direction != Vector2i.ZERO:
		exit_realm = layout.find_by_grid(Vector2i(layout.get_realm(stage_data.realm).grid) + direction)

func advance(delta: float) -> void:
	if running and not match_over:
		match_elapsed += delta

func _on_combatant_defeated(combatant: Node, _attacker: Node) -> void:
	if match_over or elimination_order.has(combatant):
		return
	elimination_order.append(combatant)
	elimination_times[combatant] = match_elapsed
	if combatant == hero:
		call_deferred("_fail_hero")

func _fail_hero() -> void:
	if not match_over:
		_finish(null, "stage failed")

func open_exit() -> void:
	if match_over or exit_open or not _is_alive(hero):
		return
	exit_open = true
	if exit_realm >= 0:
		_set_state(exit_realm, STATE_STABLE)
	announcement.emit(tr("The way opens. Use the portal (Q)."))

func use_exit() -> void:
	if exit_open and _is_alive(hero):
		_finish(hero, "stage clear")

func _finish(new_winner: Node, reason: String) -> void:
	if match_over:
		return
	match_over = true
	winner = new_winner
	finish_reason = reason
	running = false
	match_finished.emit(new_winner, reason)

func get_ringout_damage() -> float:
	return float(stage_data.rules.ringout_damage)

func get_combat_damage_scale() -> float:
	return float(stage_data.rules.damage_scale)

func get_combat_damage_scale_for(combatant: Node) -> float:
	return get_combat_damage_scale() * (0.7 if difficulty == "easy" and combatant == hero else 1.0)

func get_recovery_rate() -> float:
	return float(stage_data.rules.recovery)

func get_bot_aggression() -> float:
	return float(stage_data.rules.aggression)

func get_phase_name() -> String:
	return "Story"
