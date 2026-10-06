extends SceneTree
## Real-input collapse and post-elimination spectating playtest.

const MAIN_SCENE := "res://scenes/Main.tscn"
const OUT_RELATIVE := "../reports/codex-tester-01"
const KEY_A := 65
const KEY_D := 68
const KEY_SPACE := 32
const KEY_W := 87
const KEY_1 := 49

var out_dir := ""
var main: Node
var held: Dictionary = {}
var results: Dictionary = {"driver": "real_input_collapse", "time_scale": 10.0, "screenshots": []}

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://").path_join(OUT_RELATIVE)
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _run() -> void:
	main = load(MAIN_SCENE).instantiate()
	main.match_seed = 6103
	root.add_child(main)
	await _process_frames(10)
	await _tap(KEY_1)
	await _physics_frames(15)
	var player: Node = main.players[0]
	var initial_realm: int = player.realm_index
	results["seed"] = main.match_seed
	results["initial_realm"] = initial_realm
	results["initial_realm_name"] = main.layout.get_realm(initial_realm).name
	_set_key(KEY_SPACE, true)
	Engine.time_scale = 10.0
	while main.director.match_elapsed < 121.0 and not player.is_defeated and not main.match_over:
		await physics_frame
	await _shot("17_collapse_warning_idle")
	while main.director.match_elapsed < 149.7 and not player.is_defeated and not main.match_over:
		await physics_frame
	var before_time: float = main.director.match_elapsed
	var before_hp: float = player.hp
	var before_realm: int = player.realm_index
	var before_position: Vector2 = player.global_position
	while player.realm_index == before_realm and main.director.match_elapsed < 151.0 and not player.is_defeated and not main.match_over:
		await physics_frame
	var after_time: float = main.director.match_elapsed
	var after_hp: float = player.hp
	var after_realm: int = player.realm_index
	var after_position: Vector2 = player.global_position
	_set_key(KEY_SPACE, false)
	Engine.time_scale = 1.0
	await _physics_frames(8)
	await _shot("18_after_corner_collapse")
	results["collapse"] = {
		"before_time": snappedf(before_time, 0.01),
		"after_time": snappedf(after_time, 0.01),
		"before_hp": snappedf(before_hp, 0.1),
		"after_hp": snappedf(after_hp, 0.1),
		"hp_delta": snappedf(before_hp - after_hp, 0.1),
		"before_realm": before_realm,
		"after_realm": after_realm,
		"before_position": _vec(before_position),
		"after_position": _vec(after_position),
		"old_realm_state": main.director.get_state(before_realm),
		"protection_s": snappedf(player.invulnerable_timer, 0.01),
		"survived": not player.is_defeated,
		"relocated": after_realm != before_realm
	}

	var hp_steps: Array = []
	var last_hp: float = player.hp
	var last_respawns: int = player.respawn_count
	Engine.time_scale = 3.0
	var self_elim_frames := 0
	while not player.is_defeated and not main.match_over and self_elim_frames < 5400:
		var blast: Vector2 = main.layout.get_side_blast_lines(player.realm_index)
		var go_left: bool = player.global_position.x - blast.x < blast.y - player.global_position.x
		_set_key(KEY_A, go_left)
		_set_key(KEY_D, not go_left)
		if player.is_on_floor() and self_elim_frames % 38 == 0:
			await _tap(KEY_W)
		else:
			await physics_frame
		if player.hp != last_hp or player.respawn_count != last_respawns:
			hp_steps.append({
				"frame": self_elim_frames,
				"hp": snappedf(player.hp, 0.1),
				"respawns": player.respawn_count,
				"realm": player.realm_index
			})
			last_hp = player.hp
			last_respawns = player.respawn_count
		self_elim_frames += 1
	_release_all()
	Engine.time_scale = 1.0
	await _physics_frames(20)
	var focus: Node = main._get_focus_player()
	results["elimination"] = {
		"input_policy": "nearest side blast line; hold A/D and jump with W",
		"frames_at_3x": self_elim_frames,
		"hp_steps": hp_steps,
		"p1_eliminated": player.is_defeated,
		"living_count": main.director.get_alive_combatants().size(),
		"spectate_valid": is_instance_valid(focus) and focus != player and not focus.is_defeated,
		"spectate_name": focus.display_name if is_instance_valid(focus) else "",
		"spectate_realm": focus.realm_index if is_instance_valid(focus) else -1,
		"camera_realm": main.current_map_index,
		"camera_matches_spectate": is_instance_valid(focus) and main.current_map_index == focus.realm_index
	}
	await _shot("19_eliminated_spectating")
	_write_json("real_input_collapse.json", results)
	print("PLAYTEST_RESULT ", JSON.stringify(results))
	quit(0)

func _tap(keycode: int) -> void:
	_set_key(keycode, true)
	await process_frame
	_set_key(keycode, false)
	await process_frame
	await physics_frame

func _set_key(keycode: int, pressed: bool) -> void:
	if bool(held.get(keycode, false)) == pressed:
		return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	event.echo = false
	Input.parse_input_event(event)
	held[keycode] = pressed

func _release_all() -> void:
	for keycode in held.keys():
		if bool(held[keycode]):
			var event := InputEventKey.new()
			event.physical_keycode = int(keycode)
			event.pressed = false
			Input.parse_input_event(event)
	held.clear()

func _physics_frames(count: int) -> void:
	for _frame in count:
		await physics_frame

func _process_frames(count: int) -> void:
	for _frame in count:
		await process_frame

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join("%s.png" % shot_name)
	var error := root.get_texture().get_image().save_png(path)
	results.screenshots.append({"name": shot_name, "path": path, "error": error})
	print("saved ", path)

func _write_json(file_name: String, data: Dictionary) -> void:
	var file := FileAccess.open(out_dir.path_join(file_name), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _vec(value: Vector2) -> Array:
	return [snappedf(value.x, 0.1), snappedf(value.y, 0.1)]
