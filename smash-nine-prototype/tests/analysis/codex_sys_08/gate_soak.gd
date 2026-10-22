extends "res://tests/soak_match.gd"
## Read-only observer on the existing unmodified bot match driver.
var gate_events: Array = []
var last_positions: Dictionary = {}
var gate_window := 0
var previous_gate_phase := "idle"
var per_window: Dictionary = {}

func _check_positions() -> void:
	super._check_positions()
	var phase: String = main.hazards.get_phase(3)
	if phase == "active" and previous_gate_phase != "active":
		gate_window += 1
	previous_gate_phase = phase
	var gates: Array = main.hazards.get_gates(3)
	for player: Node in main.players:
		if not is_instance_valid(player):
			continue
		var id: int = player.get_instance_id()
		var now: Vector2 = player.global_position
		var old: Dictionary = last_positions.get(id, {})
		if not old.is_empty() and int(old.realm) == 3 and player.realm_index == 3 and phase == "active" and gates.size() == 2 and now.distance_to(old.position) > 350:
			for source in 2:
				if (old.position as Vector2).distance_to(gates[source]) < 100 and now.distance_to(gates[1-source]) < 100:
					var key := "%s:%s" % [gate_window, id]
					per_window[key] = int(per_window.get(key, 0)) + 1
					var row := {"t": main.director.match_elapsed, "frame": Engine.get_physics_frames(), "window": gate_window, "player": player.player_id, "hero": player.character_id, "from": str(old.position), "to": str(now), "hp": player.hp, "damage_dealt": player.damage_dealt, "visits_this_window": per_window[key]}
					gate_events.append(row)
					print("QA21_GATE_BOT ", JSON.stringify(row))
					break
		last_positions[id] = {"realm": player.realm_index, "position": now}

func _collect_result(finished_early: bool) -> Dictionary:
	var result := super._collect_result(finished_early)
	result.seed = seed_value
	result.gate_windows = gate_window
	result.gate_events = gate_events
	result.max_transports_per_actor_window = 0
	for count: int in per_window.values():
		result.max_transports_per_actor_window = maxi(result.max_transports_per_actor_window, count)
	var file := FileAccess.open("res://../reports/codex-sys-08/gate-soak-%d.json" % seed_value, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t") + "\n")
	return result
