extends SceneTree
## Regression for CODEX-TESTER-01: pressing R on the result screen must reload the
## match without the old scene touching a null viewport, and combat must stay frozen
## behind the result screen. Keys go through Input like a player's; the match end
## itself is forced to keep the test short. run_all.ps1 fails on any engine error line.

const MAIN_SCENE := "res://scenes/Main.tscn"
const RESTARTS := 10

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file(MAIN_SCENE)
	await _frames(3)
	var start_nodes := -1
	for round_index in RESTARTS + 1:
		var main: Node = current_scene
		var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		if start_nodes < 0:
			start_nodes = nodes
		elif absi(nodes - start_nodes) > 5:
			_fail("Start screen node count drifted: %d -> %d after %d restarts" % [start_nodes, nodes, round_index])
			break
		await _tap(KEY_B)
		await _frames(30)
		if not main.match_started:
			_fail("B did not start a bots-only match")
			break
		var winner: Node = main.players[0]
		main.director._finish(winner, "test")
		await _frames(2)
		var winner_hp: float = winner.hp
		var alive_at_finish: int = main.director.get_alive_combatants().size()
		await create_timer(1.0).timeout
		if winner.hp < winner_hp or main.director.get_alive_combatants().size() != alive_at_finish:
			_fail("Combat kept running behind the result screen (winner HP %.0f -> %.0f)" % [winner_hp, winner.hp])
			break
		if round_index == RESTARTS:
			break
		await _tap(KEY_R)
		await _frames(5)
		if current_scene == main or not is_instance_valid(current_scene):
			_fail("R did not reload the match scene")
			break
	if not failed:
		print("Restart tests passed (%d restarts, start screen nodes %d)" % [RESTARTS, start_nodes])
	quit(1 if failed else 0)

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _tap(keycode: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		event.keycode = keycode
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)
