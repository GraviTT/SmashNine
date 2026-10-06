extends SceneTree
## Ten real SceneTree reloads with a pending attack on every outgoing match.

const MAIN_SCENE := "res://scenes/Main.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.match_seed = 901
	root.add_child(main)
	current_scene = main
	await process_frame
	var node_counts: Array[int] = []
	var reload_codes: Array[int] = []
	for cycle in 10:
		main.players[cycle % main.players.size()].basic_attack()
		reload_codes.append(int(reload_current_scene()))
		await process_frame
		await process_frame
		main = current_scene
		main.bots_only = true
		main.match_seed = 902 + cycle
		main._start_match("")
		await process_frame
		node_counts.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	print("RESTART_RESULT ", JSON.stringify({
		"cycles": 10,
		"reload_codes": reload_codes,
		"node_counts": node_counts,
		"final_players": main.players.size(),
		"final_match_started": main.match_started
	}))
	main.queue_free()
	await process_frame
	quit(0)
