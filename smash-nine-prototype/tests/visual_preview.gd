extends SceneTree

const MAIN_SCRIPT := preload("res://scripts/Main.gd")
func _initialize() -> void:
	call_deferred("_run_preview")

func _run_preview() -> void:
	var main := MAIN_SCRIPT.new()
	root.add_child(main)
	await process_frame
	for character_id in ["frey", "yuki", "luna", "nova"]:
		main._replace_human_character(character_id)
		for frame in 8:
			await process_frame
	main.director.realm_states[main.CENTRAL_REALM_INDEX] = "stable"
	for realm_index in 9:
		main._set_map(realm_index)
		for frame in 8:
			await process_frame
	quit(0)
