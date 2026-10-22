extends SceneTree
## CODEX-SYS-02: real keyboard/mouse flow, retained shortcuts, reload/session invariants.
## -- --capture also saves the six requested windowed screen captures.

const MAIN_SCENE := "res://scenes/Main.tscn"
const SPEED := preload("res://scripts/GameSpeed.gd")
const ART := preload("res://scripts/ArtSettings.gd")
var failed := false
var capture := false
var report_dir := ""

func _initialize() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	report_dir = ProjectSettings.globalize_path("res://../reports/codex-sys-02")
	create_timer(90.0).timeout.connect(func() -> void:
		push_error("Frontend flow timed out")
		quit(1))
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	change_scene_to_file(MAIN_SCENE)
	await _frames(5)
	var main: Node = current_scene
	main.session_player_count = 8
	main.session_bot_panel = true
	main.last_character_id = "frey"
	main.human_body = "male"
	main.next_screen = "title"
	SPEED.factor = 1.0
	var baseline := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphan_baseline := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_check(main.hud.frontend.screen == "title" and not main.match_started, "Initial screen must be title")
	# Regression: imported textures must not force controls back to their native size.
	for node in main.hud.frontend.content.get_children():
		if node is TextureRect:
			_check(node.size.x <= 380 and node.size.y <= 126, "Logo must fit its menu slot rather than native texture dimensions")
	await _capture("01-title")
	# Repeat all three result destinations, with a clean title node baseline each time.
	for cycle in 2:
		main = current_scene
		await _tap(KEY_ENTER)
		_check(main.hud.frontend.screen == "select" and not main.match_started, "Play must open selection without starting")
		for portrait_button in main.hud.frontend.portrait_buttons:
			var picture: Control = main.hud.frontend.content.get_child(portrait_button.get_index() + 1)
			_check(picture.size.x <= 126 and picture.size.y <= 94, "Portrait must fit within its grid cell")
		await _capture("02-select-frey" if cycle == 0 else "")
		await _tap(KEY_D)
		_check(main.hud.frontend.selected_id == "yuki", "Keyboard browsing must change the selected fighter")
		await _tap(KEY_A)
		_check(main.hud.frontend.selected_id == "frey", "Keyboard browsing must work in both directions")
		await _tap(KEY_DOWN)
		_check(main.hud.frontend.selected_id == "luna", "Down must follow the portrait grid to the next row")
		await _tap(KEY_UP)
		_check(main.hud.frontend.selected_id == "frey", "Up must return to the previous portrait row")
		await _tap(KEY_TAB)
		_check(main.hud.frontend.selected_id == "yuki", "Tab focus must also update the fighter preview")
		await _tap(KEY_A)
		await _click(main.hud.frontend.buttons[5])
		_check(main.characters.has(main.hud.frontend.selected_id) and not main.match_started, "Random must choose a valid preview without starting")
		# Mouse chooses Nova; V changes its art and the actual spawned body.
		await _click(main.hud.frontend.portrait_buttons[3])
		_check(main.hud.frontend.selected_id == "nova", "Clicking portrait must select Nova")
		await _tap(KEY_V)
		_check(main.human_body == "female", "V must change the selected body")
		await _click(main.hud.frontend.body_button)
		_check(main.human_body == "male", "Body button must switch to male")
		await _click(main.hud.frontend.body_button)
		_check(main.hud.frontend.hero_art.texture.resource_path.ends_with("nova_female_illustration.png"), "Selected main art must follow the body")
		await _capture("03-select-nova-female" if cycle == 0 else "")
		await _click(main.hud.frontend.portrait_buttons[3])
		await _tap(KEY_J)
		await _frames(5)
		_check(main.match_started and not main.bots_only, "J must confirm selected fighter")
		var human: Node = main._get_human_player()
		_check(is_instance_valid(human) and human.character_id == "nova" and human.body_type == "female", "Selection must spawn the chosen fighter and body")
		_check(main.players.size() == 8, "Default match must have eight fighters")
		# Existing development inputs still reach their owners.
		await _tap(KEY_F3)
		_check(main.hud.debug_label.visible, "F3 must toggle debug")
		await _tap(KEY_F4)
		_check(not main.hud.bot_panel.visible, "F4 must toggle bot panel")
		await _tap(KEY_F4)
		await _tap(KEY_H)
		_check(is_instance_valid(main.dummy), "H must spawn a dummy")
		await _tap(KEY_H)
		_check(not is_instance_valid(main.dummy), "H must remove a dummy")
		main.director._finish(human, "frontend test")
		await _frames(4)
		_check(main.hud.frontend.screen == "results" and main.match_over, "Finished match must show results")
		if cycle == 0:
			_verify_result_values(main, human)
		await _capture("06-results" if cycle == 0 else "")
		# R rematches a human with the same fighter/body, no re-selection.
		await _tap(KEY_R)
		await _frames(6)
		main = current_scene
		_check(main.match_started and not main.match_over, "R must immediately rematch a human")
		human = main._get_human_player()
		_check(human.character_id == "nova" and human.body_type == "female", "Rematch must retain fighter and body")
		main.director._finish(human, "frontend test")
		await _frames(3)
		# The mouse Rematch button uses the same route.
		await _click(main.hud.frontend.buttons[0])
		await _frames(6)
		main = current_scene
		_check(main.match_started and main._get_human_player().character_id == "nova", "Mouse Rematch must restart chosen fighter")
		main.director._finish(main.players[0], "frontend test")
		await _frames(3)
		await _click(main.hud.frontend.buttons[1])
		await _frames(6)
		main = current_scene
		_check(not main.match_started and main.hud.frontend.screen == "select", "Results Character select must return to selection")
		await _tap(KEY_ESCAPE)
		await _frames(4)
		_check(main.hud.frontend.screen == "title", "Esc must return selection to title")
		await _tap(KEY_1)
		await _frames(4)
		_check(main.match_started and main.players[0].character_id == "frey", "1 must still start Frey immediately")
		main.director._finish(main.players[0], "frontend test")
		await _frames(3)
		await _click(main.hud.frontend.buttons[2])
		await _frames(6)
		main = current_scene
		_check(not main.match_started and main.hud.frontend.screen == "title", "Results Title must return to clean title")
		var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		_check(absi(nodes - baseline) <= 5, "Title node baseline drifted: %d -> %d (cycle %d)" % [baseline, nodes, cycle])
		_check(orphans == orphan_baseline, "Orphan nodes increased: %d -> %d" % [orphan_baseline, orphans])
		main.human_body = "male"
		main.hud.frontend.refresh_body("male")
	# All remaining number shortcuts work from both title and select.
	for index in 4:
		main = current_scene
		if index % 2 == 0:
			await _tap(KEY_ENTER)
		await _tap(KEY_2 + index)
		await _frames(4)
		var expected: String = ["yuki", "luna", "nova", "rio"][index]
		_check(main.match_started and main.players[0].character_id == expected, "Number shortcut did not start %s" % expected)
		main.director._finish(main.players[0], "shortcut test")
		await _frames(2)
		await _click(main.hud.frontend.buttons[2])
		await _frames(6)
	main = current_scene
	await _tap(KEY_ENTER)
	for index in 5:
		await _click(main.hud.frontend.portrait_buttons[index])
		_check(main.hud.frontend.hero_art.texture != null, "Every fighter must have main art")
		_check(main.hud.frontend.skill_labels.size() == 5, "Every fighter must show J/K/L/I and passive guidance")
	await _tap(KEY_V)
	_check(main.hud.frontend.hero_art.texture.resource_path.ends_with("rio_female_illustration.png"), "Rio body must also switch its main art")
	await _tap(KEY_ESCAPE)
	# Title keyboard navigation: Play -> Watch -> Options.
	await _tap(KEY_DOWN)
	await _tap(KEY_S)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	_check(main.hud.frontend.screen == "options", "Arrow/W-S navigation must open Options")
	await _capture("04-options")
	await _tap(KEY_T)
	_check(SPEED.percent() == 90 and Engine.time_scale == 1.0, "T must change chosen speed while menus remain at 100%")
	await _click(main.hud.frontend.count_button)
	_check(main.player_count == 4, "Options must set next match fighter count to four")
	for expected in [6, 8, 4]:
		await _click(main.hud.frontend.count_button)
		_check(main.player_count == expected, "Fighter-count option must cycle 4 / 6 / 8")
	for expected in [80, 70, 100, 90]:
		await _click(main.hud.frontend.speed_button)
		_check(SPEED.percent() == expected, "Speed button must use the same cycle as T")
	await _click(main.hud.frontend.panel_button)
	_check(not main.session_bot_panel, "Options must disable bot panel at start")
	var old_style := ART.style
	await _tap(KEY_F2)
	await _frames(6)
	main = current_scene
	_check(ART.style != old_style and main.hud.frontend.screen == "options", "F2 must change art and retain current menu")
	_check(main.player_count == 4 and not main.session_bot_panel and SPEED.percent() == 90, "Options must survive art reload")
	await _tap(KEY_F2)
	await _frames(6)
	main = current_scene
	await _tap(KEY_ESCAPE)
	# Controls opens with a real mouse click.
	await _click(main.hud.frontend.buttons[4])
	_check(main.hud.frontend.screen == "controls", "Mouse Controls must open the key table")
	await _capture("05-controls")
	await _tap(KEY_ESCAPE)
	await _tap(KEY_B)
	await _frames(5)
	_check(main.match_started and main.bots_only and main.players.size() == 4, "B must start bots using fighter-count option")
	_check(not main.hud.bot_panel.visible, "Bot panel option must apply at match start")
	_check(is_equal_approx(Engine.time_scale, 0.9), "Chosen speed must apply to a match")
	main.director._finish(main.players[0], "watch test")
	await _frames(3)
	# Button replays watch mode; R intentionally retains legacy clean-title behavior.
	await _click(main.hud.frontend.buttons[0])
	await _frames(6)
	main = current_scene
	_check(main.match_started and main.bots_only and main.players.size() == 4, "Watch Rematch button must replay watch mode")
	main.director._finish(main.players[0], "watch test")
	await _frames(3)
	await _tap(KEY_R)
	await _frames(6)
	main = current_scene
	_check(not main.match_started and main.hud.frontend.screen == "title", "Watch R must retain legacy restart baseline")
	for window_size in [Vector2i(1600, 720), Vector2i(960, 720), Vector2i(720, 960)]:
		root.size = window_size
		await _frames(3)
		var bounds: Rect2 = main.hud.frontend.get_global_rect()
		_check(root.get_visible_rect().encloses(bounds), "Menu must fit after viewport resizing to %s" % window_size)
	root.size = Vector2i(1280, 720)
	main.session_player_count = 8
	main.session_bot_panel = true
	main.human_body = "male"
	main.last_character_id = "frey"
	main.next_screen = "title"
	SPEED.factor = 1.0
	SPEED.reset_engine()
	if not failed:
		print("Frontend flow tests passed (keyboard + mouse, 5 shortcuts, bodies, options, 3 result routes, 2 node/orphan cycles; nodes %d, orphans %d)" % [baseline, orphan_baseline])
	quit(1 if failed else 0)

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _verify_result_values(main: Node, human: Node) -> void:
	# Verify distinct data winners, card names and draw text, then restore live data
	# before capturing. These fixtures never change the delivered screenshot's stats.
	var backup: Array[Dictionary] = []
	var survival := {}
	for player in main.players:
		backup.append({"score": player.score, "damage": player.damage_dealt, "souls": player.souls, "cards": player.upgrades.duplicate()})
		survival[player] = 60.0
	main.players[0].souls = 75
	main.players[0].upgrades.assign(["sky_step", "last_stand"])
	main.players[1].damage_dealt = 900
	main.players[2].score = 7
	survival[main.players[3]] = 180.0
	var standings: Array[Node] = main.director.get_standings()
	main.hud.show_results(human, "stat fixture", standings, human, survival)
	var content: Control = main.hud.frontend.content
	_check(_has_label(content, "900") and _has_label(content, "75") and _has_label(content, "7"), "Results must display damage, souls and KOs")
	_check(_has_label(content, "%s  /  900" % main.players[1].display_name), "Damage award must go to the damage leader")
	_check(_has_label(content, "%s  /  7" % main.players[2].display_name), "KO award must go to the KO leader")
	_check(_has_label(content, "%s  /  3:00" % main.players[3].display_name), "Survival award must use survival times")
	_check(_has_label(content, "2  Sky Step, Last Stand"), "Results must keep card counts and human-readable names")
	main.hud.show_results(null, "double KO", standings, human, survival)
	_check(_has_label(main.hud.frontend.content, "DRAW"), "A result without a winner must show DRAW")
	for index in main.players.size():
		var player: Node = main.players[index]
		player.score = backup[index].score
		player.damage_dealt = backup[index].damage
		player.souls = backup[index].souls
		player.upgrades.assign(backup[index].cards)
		survival[player] = main.director.get_survival_time(player)
	main.hud.show_results(human, "frontend test", main.director.get_standings(), human, survival)

func _has_label(node: Node, text: String) -> bool:
	if node is Label and node.text == text:
		return true
	for child in node.get_children():
		if _has_label(child, text):
			return true
	return false

func _tap(keycode: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		event.keycode = keycode
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)

func _click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await _frames(2)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await _frames(2)

func _capture(stem: String) -> void:
	if not capture or stem == "":
		return
	await _frames(3)
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(report_dir.path_join(stem + ".png"))
	_check(result == OK, "Could not save capture " + stem)
