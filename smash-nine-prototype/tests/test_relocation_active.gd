extends SceneTree
## A fighter thrown out of a collapsing realm must keep playing in the realm it lands in.
## The collapse marks the fighters still inside inactive before moving them, and nothing
## marked them active again, so a fighter caught at 4:00 froze until the end (found
## 2026-10-08 when the bigger realms made bots get caught more often).

const MAIN_SCENE := "res://scenes/Main.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.realm_hazards = false
	root.add_child(main)
	await process_frame
	var corner: int = main.layout.get_corner_indices()[0]
	var caught: Node = main.players[0]
	main.layout.assign_combatant(caught, corner)
	caught.reset_for_map(main.layout.pick_spawn(corner), main.layout.get_spawn_points(corner))
	caught.hp = caught.max_hp
	# Skip to just past the first collapse (the corners fall at 2:30).
	main.director.advance(151.0)
	await process_frame
	var failed := false
	if caught.realm_index == corner or not main.director.is_playable(caught.realm_index):
		push_error("Test setup: the fighter should have been moved out of the collapsed corner")
		failed = true
	elif not caught.is_realm_active:
		push_error("A fighter moved out of a collapsing realm should stay active in its new realm")
		failed = true
	main.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Relocation tests passed")
	quit(0)
