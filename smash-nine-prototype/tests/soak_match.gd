extends SceneTree
## Runs the real Main scene with bots only and reports match health.
## Usage: godot --headless --path . --fixed-fps 60 -s tests/soak_match.gd -- --seconds=480 --seed=7
## Prints status lines every 30 in-game seconds and one final "SOAK_RESULT {json}" line.

const MAIN_SCENE := "res://scenes/Main.tscn"
const STATUS_INTERVAL := 30.0
const FRAME_TIME := 1.0 / 60.0

var main: Node
var seconds := 480.0
var seed_value := -1
var defeats := 0
var defeats_by_player: Dictionary = {}
var nan_positions := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):
			seconds = float(arg.get_slice("=", 1))
		elif arg.begins_with("--seed="):
			seed_value = int(arg.get_slice("=", 1))
	call_deferred("_run")

func _run() -> void:
	if seed_value >= 0:
		seed(seed_value)
	main = load(MAIN_SCENE).instantiate()
	main.set("bots_only", true)
	root.add_child(main)
	await process_frame
	for player in main.players:
		player.defeated.connect(_on_defeated)
	var frames := int(seconds / FRAME_TIME)
	var next_status := STATUS_INTERVAL
	var finished_early := false
	for frame in frames:
		await physics_frame
		var elapsed: float = main.director.match_elapsed
		if elapsed >= next_status:
			next_status += STATUS_INTERVAL
			_print_status(elapsed)
		_check_positions()
		if main.get("match_over") == true:
			finished_early = true
			break
	_print_status(main.director.match_elapsed)
	var result := _collect_result(finished_early)
	print("SOAK_RESULT ", JSON.stringify(result))
	main.queue_free()
	await process_frame
	quit(0)

func _on_defeated(player: Node, _attacker: Node) -> void:
	defeats += 1
	var key: String = player.display_name
	defeats_by_player[key] = int(defeats_by_player.get(key, 0)) + 1

func _check_positions() -> void:
	for player in main.players:
		if is_instance_valid(player) and (is_nan(player.global_position.x) or is_nan(player.global_position.y)):
			nan_positions += 1

func _print_status(elapsed: float) -> void:
	var alive := 0
	var realms: Array[String] = []
	for player in main.players:
		if is_instance_valid(player) and not player.is_defeated:
			alive += 1
		realms.append("%s@%d" % [player.display_name, player.realm_index + 1])
	print("[soak] t=%3.0fs phase=%s playable=%d alive=%d/%d nodes=%d defeats=%d %s" % [
		elapsed,
		main.director.get_phase_name(),
		main.director.get_playable_indices().size(),
		alive,
		main.players.size(),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		defeats,
		" ".join(realms)
	])

func _collect_result(finished_early: bool) -> Dictionary:
	var winner := ""
	if main.has_method("get_winner"):
		var winner_node: Node = main.get_winner()
		if is_instance_valid(winner_node):
			winner = winner_node.display_name
	return {
		"seconds_simulated": snappedf(main.director.match_elapsed, 0.1),
		"match_over": finished_early,
		"winner": winner,
		"players": main.players.size(),
		"defeats": defeats,
		"defeats_by_player": defeats_by_player,
		"playable_realms": main.director.get_playable_indices().size(),
		"nan_positions": nan_positions,
		"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	}
