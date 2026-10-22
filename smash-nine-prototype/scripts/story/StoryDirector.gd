extends "res://scripts/match/MatchDirector.gd"
## Story owns objective completion; it never executes the battle-royale timeline/survivor rule.
const CATALOG := preload("res://scripts/story/StoryCatalog.gd")
var stage_data: Dictionary = {}
var difficulty := "normal"
var hero: Node
var running := false
var exit_open := false
var exit_realm := -1
var escape_started := false
var band_started_at := -1.0

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
		if not warning_realms.is_empty() and match_elapsed >= warning_ends_at:
			_finish(null, "time up")
		elif band_started_at >= 0.0:
			_apply_sudden_death(delta)

func begin_combat() -> void:
	var seconds := float(stage_data.rules.escape_seconds)
	if seconds > 0.0 and not escape_started:
		escape_started = true
		warning_ends_at = match_elapsed + seconds
		warning_realms.assign([int(stage_data.realm)])
		_set_state(int(stage_data.realm), STATE_WARNING)

func stop_escape() -> void:
	if warning_realms.is_empty():
		return
	warning_realms.clear()
	_set_state(int(stage_data.realm), STATE_STABLE)

func start_shadow_band() -> void:
	if band_started_at < 0.0:
		band_started_at = match_elapsed
		_set_phase(PHASE_SUDDEN_DEATH)

func get_sudden_death_band() -> Vector2:
	var bounds: Rect2 = layout.get_bounds(central_index)
	if band_started_at < 0.0:
		return Vector2(-INF, INF)
	var rule: Dictionary = stage_data.shadow_band
	var progress := clampf((match_elapsed - band_started_at) / float(rule.seconds), 0.0, 1.0)
	var half_width := bounds.size.x * 0.5 * lerpf(1.0, float(rule.fraction), progress)
	return Vector2(bounds.get_center().x - half_width, bounds.get_center().x + half_width)

## D43: bots cannot reason about the shrinking band, so only the hero takes its damage.
func _apply_sudden_death(delta: float) -> void:
	if not _is_alive(hero) or hero.realm_index != central_index:
		return
	var band := get_sudden_death_band()
	if hero.global_position.x < band.x or hero.global_position.x > band.y:
		hero.apply_environment_damage(float(stage_data.shadow_band.damage) * delta)

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
