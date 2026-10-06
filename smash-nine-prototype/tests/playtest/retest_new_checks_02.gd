extends SceneTree
## CODEX-RETEST-02 checks added by the card. Starting the match uses the same
## physical InputEventKey path as a player; state is read only for measurement.

const MAIN_SCENE := "res://scenes/Main.tscn"
const OUT_RELATIVE := "../reports/codex-tester-02"
const KEY_1 := 49

var out_dir := ""
var results: Dictionary = {"driver": "retest_new_checks_02", "screenshots": []}

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://").path_join(OUT_RELATIVE)
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _run() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.match_seed = 4100
	root.add_child(main)
	current_scene = main
	await _frames(12)
	results["start_hud"] = {
		"overlay_visible": main.hud.overlay.visible,
		"clock_hidden": not main.hud.clock_label.visible,
		"realm_hidden": not main.hud.realm_label.visible,
		"status_hidden": not main.hud.status_label.visible,
		"info_hidden": not main.hud.info_label.visible,
		"minimap_hidden": not main.hud.minimap_root.visible,
		"warning_hidden": not main.hud.warning_label.visible,
		"card_hidden": not main.hud.card_panel.visible
	}
	results.start_hud["pass"] = _all_start_hud_hidden(results.start_hud)
	await _shot("01_start_screen_hud_hidden")
	await _tap(KEY_1)
	await _physics_frames(12)
	var p1: Node = main.players[0]
	var partners: Array[String] = []
	for player in main.players:
		if player != p1 and player.realm_index == p1.realm_index:
			partners.append(player.character_id)
	results["opening_pair"] = {
		"p1_character": p1.character_id,
		"p1_realm": p1.realm_index,
		"partner_characters": partners,
		"pass": partners.size() == 1 and partners[0] != p1.character_id
	}
	await _shot("02_mixed_opening_pair")
	_write_json("new_checks.json", results)
	print("PLAYTEST_RESULT ", JSON.stringify(results))
	quit(0)

func _all_start_hud_hidden(data: Dictionary) -> bool:
	return bool(data.overlay_visible) and bool(data.clock_hidden) and bool(data.realm_hidden) and bool(data.status_hidden) and bool(data.info_hidden) and bool(data.minimap_hidden) and bool(data.warning_hidden) and bool(data.card_hidden)

func _tap(keycode: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	event.echo = false
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = false
	event.echo = false
	Input.parse_input_event(event)
	await process_frame
	await physics_frame

func _frames(count: int) -> void:
	for _frame in count:
		await process_frame

func _physics_frames(count: int) -> void:
	for _frame in count:
		await physics_frame

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join("%s.png" % shot_name)
	var error := root.get_texture().get_image().save_png(path)
	results.screenshots.append({"name": shot_name, "path": path, "error": error})

func _write_json(file_name: String, data: Dictionary) -> void:
	var file := FileAccess.open(out_dir.path_join(file_name), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
