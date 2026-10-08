extends SceneTree
## QA-15 supplemental visual capture. Captures the nine live realms at several camera
## positions, representative objects, the F4 bot panel, and every timed realm hazard.
## Usage (windowed):
## godot --path . -s tests/analysis/codex_qa_15/capture_art_qa.gd -- --out=../reports/codex-qa-15/screens/supplemental

const MAIN_SCENE := "res://scenes/Main.tscn"
const CAMERA_EDGE_PADDING := 80.0

var out_dir := ""
var main: Node

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://").path_join("../reports/codex-qa-15/screens/supplemental")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = ProjectSettings.globalize_path("res://").path_join(arg.get_slice("=", 1))
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _run() -> void:
	main = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.match_seed = 1515
	main.realm_hazards = true
	root.add_child(main)
	await _seconds(1.0)
	main.set_process(false)
	for player in main.players:
		player.process_mode = Node.PROCESS_MODE_DISABLED

	# The requested development HUD view; subsequent art shots hide it so it cannot cover art.
	main._set_map(main.players[0].realm_index)
	main._update_hud()
	await _frames(3)
	await _shot("00_hud_bot_panel")
	main.hud.bot_panel.visible = false

	# Each outer realm is 1920x1080 after D27; the centre is larger. Three positions expose
	# both edges and the middle at actual gameplay zoom instead of shrinking the whole realm.
	for realm_index in main.layout.realm_count():
		main._set_map(realm_index)
		main._update_hud()
		var bounds: Rect2 = main.layout.get_bounds(realm_index).grow(CAMERA_EDGE_PADDING)
		var half_view: Vector2 = main.get_viewport().get_visible_rect().size / main.camera.zoom * 0.5
		var positions: Array[Vector2] = [
			Vector2(bounds.position.x + half_view.x, bounds.position.y + half_view.y),
			bounds.get_center(),
			Vector2(bounds.end.x - half_view.x, bounds.end.y - half_view.y),
		]
		for spot_index in positions.size():
			main.camera.global_position = positions[spot_index]
			main.camera.reset_smoothing()
			await _frames(2)
			await _shot("realm_%02d_%d" % [realm_index + 1, spot_index])

	# Close live examples of the three repeated world-object families.
	var object_realm := 0
	main._set_map(object_realm)
	main._update_hud()
	var portals: Array = main.layout.get_portals(object_realm, Callable(main.director, "get_state"))
	if not portals.is_empty():
		main.camera.global_position = _clamped_camera(object_realm, portals[0].layout.position)
		await _frames(2)
		await _shot("object_portal")
	var crystal: Node = main.soul_crystal_spawner.get_crystal(object_realm)
	if is_instance_valid(crystal):
		main.camera.global_position = _clamped_camera(object_realm, crystal.global_position + Vector2(0.0, -120.0))
		await _frames(2)
		await _shot("object_soul_crystal")
	var monsters: Array = main.realm_monster_spawner.monsters_by_realm.get(object_realm, [])
	if not monsters.is_empty() and is_instance_valid(monsters[0]):
		main.camera.global_position = _clamped_camera(object_realm, monsters[0].global_position + Vector2(0.0, -120.0))
		await _frames(2)
		await _shot("object_monster")

	# Timed hazards: warning and active frames. Bushes and ice are already visible/legible in
	# the realm sweep, while these four have distinct transient visuals.
	# RealmCatalog stores the centre last, so the timed hazards are Asgard 0,
	# Muspelheim 4, Vanaheim 6, and Jotunheim 7.
	for realm_index in [0, 4, 6, 7]:
		main._set_map(realm_index)
		main._update_hud()
		main.camera.global_position = main.layout.get_bounds(realm_index).get_center()
		main.hazards.trigger(realm_index)
		main._update_hud()
		await _frames(3)
		await _shot("hazard_%02d_warning" % [realm_index + 1])
		var entry: Dictionary = main.hazards._realms[realm_index]
		main.hazards.advance(float(entry.hazard.get("warning", 1.0)) + 0.02)
		main._update_hud()
		await _frames(3)
		await _shot("hazard_%02d_active" % [realm_index + 1])

	print("QA-15 supplemental screens saved to ", out_dir)
	quit(0)

func _seconds(duration: float) -> void:
	await create_timer(duration).timeout

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

## Same bounds and zoom math as Main._get_camera_target(), but around an explicit QA point.
func _clamped_camera(realm_index: int, point: Vector2) -> Vector2:
	var bounds: Rect2 = main.layout.get_bounds(realm_index).grow(CAMERA_EDGE_PADDING)
	var view: Vector2 = main.get_viewport().get_visible_rect().size / main.camera.zoom
	return Vector2(
		clampf(point.x, bounds.position.x + view.x * 0.5, bounds.end.x - view.x * 0.5),
		clampf(point.y, bounds.position.y + view.y * 0.5, bounds.end.y - view.y * 0.5)
	)

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join("%s.png" % shot_name)
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
