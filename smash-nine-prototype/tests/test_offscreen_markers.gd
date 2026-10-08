extends SceneTree
## Realms are bigger than the camera view since 2026-10-08 (GameScale.WORLD): a fighter in the
## shown realm who is off screen gets an arrow on the screen edge pointing at them; fighters
## on screen and in other realms get none.

const MAIN_SCENE := "res://scenes/Main.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.player_count = 2
	main.realm_hazards = false
	root.add_child(main)
	await process_frame
	var focus: Node = main.players[0]
	var other: Node = main.players[1]
	main.spectate_target = focus
	main._set_map(focus.realm_index)
	for player in main.players:
		player.set_physics_process(false)
	other.realm_index = focus.realm_index
	var bounds: Rect2 = main.layout.get_bounds(focus.realm_index)
	focus.global_position = Vector2(bounds.position.x + 200.0, bounds.end.y - 200.0)
	other.global_position = Vector2(bounds.end.x - 100.0, bounds.end.y - 200.0)
	main.camera.global_position = main._get_camera_target()
	main.camera.reset_smoothing()
	await process_frame
	await process_frame
	var failed := false
	var markers: Array = main._offscreen_markers()
	var view: Vector2 = main.get_viewport().get_visible_rect().size
	if markers.size() != 1:
		push_error("One fighter off screen in the shown realm should give one arrow (got %d)" % markers.size())
		failed = true
	elif markers[0].position.x < view.x * 0.5 or absf(float(markers[0].angle)) > PI * 0.5:
		push_error("The arrow should sit on the right edge and point right (%s, angle %.2f)" % [markers[0].position, float(markers[0].angle)])
		failed = true
	# On screen: no arrow.
	other.global_position = focus.global_position + Vector2(160, 0)
	await process_frame
	if not main._offscreen_markers().is_empty():
		push_error("A fighter on screen should get no arrow")
		failed = true
	# Another realm: no arrow.
	other.global_position = Vector2(bounds.end.x - 100.0, bounds.end.y - 200.0)
	other.realm_index = (focus.realm_index + 1) % main.layout.realm_count()
	if not main._offscreen_markers().is_empty():
		push_error("A fighter in another realm should get no arrow")
		failed = true
	main.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Off-screen marker tests passed")
	quit(0)
