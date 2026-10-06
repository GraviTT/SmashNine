extends SceneTree
## Smoke-renders the match: bots-only start, then the camera visits every realm.

const MAIN_SCENE := "res://scenes/Main.tscn"

func _initialize() -> void:
	call_deferred("_run_preview")

func _run_preview() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	root.add_child(main)
	await process_frame
	main.director.realm_states[main.CENTRAL_REALM_INDEX] = "stable"
	for realm_index in 9:
		main._set_map(realm_index)
		for frame in 8:
			await process_frame
	main.queue_free()
	await process_frame
	quit(0)
