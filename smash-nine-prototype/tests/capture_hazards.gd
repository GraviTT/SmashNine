extends SceneTree
## Visual check of the realm gimmicks (windowed, not headless): eruption warning and
## pillars in Muspelheim, quake warning in Jotunheim, the ice realm title in Niflheim,
## a bot hidden in a Midgard bush.
## Usage: godot --path . -s tests/capture_hazards.gd -- --out=../reports/screens-hazards

const MAIN_SCENE := "res://scenes/Main.tscn"

var out_dir := ""
var main: Node

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://").path_join("../reports/screens-hazards")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = ProjectSettings.globalize_path("res://").path_join(arg.get_slice("=", 1))
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _run() -> void:
	main = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.match_seed = 77
	root.add_child(main)
	await _frames(30)
	for spec in [["Muspelheim", "eruption"], ["Jotunheim", "quake"], ["Niflheim", "ice"]]:
		var realm_index := _realm(spec[0])
		_show(realm_index)
		await _frames(10)
		if spec[1] != "ice":
			main.hazards.trigger(realm_index)
			await _seconds(0.6)
			await _shot("%s_warning" % spec[1])
			if spec[1] == "eruption":
				await _seconds(0.7)
				await _shot("eruption_active")
		else:
			await _shot("ice_realm")
	var midgard := _realm("Midgard")
	_show(midgard)
	await _frames(10)
	var bush: Rect2 = main.hazards.get_bushes(midgard)[0]
	main.players[0].global_position = Vector2(bush.get_center().x, bush.end.y - 4.0)
	await _frames(6)
	await _shot("midgard_bushes")
	print("Hazard screens saved to ", out_dir)
	quit(0)

## Points the camera at a realm by moving the spectated bot there.
func _show(realm_index: int) -> void:
	var focus: Node = main.players[0]
	main.layout.assign_combatant(focus, realm_index)
	focus.reset_for_map(main.layout.pick_spawn(realm_index), main.layout.get_spawn_points(realm_index))
	main.spectate_target = focus
	main._sync_combatant_visibility()
	main._set_map(realm_index)

func _realm(realm_name: String) -> int:
	for i in main.layout.realm_count():
		if main.layout.get_realm(i).name == realm_name:
			return i
	return -1

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _seconds(duration: float) -> void:
	await create_timer(duration).timeout

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join("%s.png" % shot_name)
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
