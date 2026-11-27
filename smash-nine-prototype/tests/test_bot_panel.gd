extends SceneTree
## Live bot panel (F4, 2026-10-08): one row per fighter with what its bot is doing; the HUD
## clock and status keep updating next to it; F4 hides it. The results table hides it and the
## rest of the match HUD (QA-15), an ultimate cut-in still playing included (QA-21); the next
## match brings back what F4 chose. Main keeps the faces it found for the panel and the
## off-screen arrows (quality track 4, 2026-11-27), but a face swapped in while the game runs
## (take_over_path, as the story face test does) is looked up again.

const MAIN_SCENE := "res://scenes/Main.tscn"
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	root.add_child(main)
	for frame in 30:
		await process_frame
	var failed := false
	var hud: Node = main.hud
	var shown := 0
	for nodes: Dictionary in hud.bot_row_nodes:
		if nodes.row.visible:
			shown += 1
	if not hud.bot_panel.visible or shown != main.players.size():
		push_error("The bot panel should list every fighter (%d of %d)" % [shown, main.players.size()])
		failed = true
	var first: Label = hud.bot_row_nodes[0].text if not hud.bot_row_nodes.is_empty() else null
	var states := ["WANDER", "CHASE", "FIGHT", "PORTAL", "RECOVER"]
	var has_state := false
	for state in states:
		if first != null and first.text.contains(state):
			has_state = true
	if not has_state:
		push_error("A bot row should say what the bot is doing (got %s)" % (first.text if first != null else "nothing"))
		failed = true
	if hud.clock_label.text == "" or hud.focus_name.text == "":
		push_error("The HUD clock and the focus fighter's plate should keep updating with the panel on")
		failed = true
	hud.toggle_bot_panel()
	if hud.bot_panel.visible:
		push_error("F4 should hide the bot panel")
		failed = true
	hud.toggle_bot_panel()
	var fighter: Node = main.players[0]
	var kept: Texture2D = main._face(fighter)
	if kept == null or kept != ART_SETTINGS.character_portrait(fighter.character_id, fighter.body_type):
		push_error("Main's face for %s should be the ArtSettings portrait (got %s)" % [fighter.display_name, kept])
		failed = true
	elif kept.resource_path == "":
		push_error("The face for %s should come from a file (got a made-up texture)" % fighter.display_name)
		failed = true
	else:
		var path := kept.resource_path
		var swapped := ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8))
		swapped.take_over_path(path)
		var now_face: Texture2D = main._face(fighter)
		var row_face: Texture2D = main._bot_panel_rows()[0].face
		if now_face != swapped or row_face != swapped:
			push_error("A face swapped in at %s should replace the kept one (face %s, panel row %s)" % [path, now_face, row_face])
			failed = true
		kept.take_over_path(path)
		if main._face(fighter) != kept:
			push_error("The face put back at %s should come back" % path)
			failed = true
	# An ultimate cut-in still playing when the match view hides goes with it (QA-21 S1).
	hud.show_ultimate_cutin(main.players[0])
	var standings: Array[Node] = []
	standings.assign(main.players)
	hud.show_results(main.players[0], "test", standings, null)
	for node in [hud.bot_panel, hud.clock_label, hud.player_root, hud.minimap_root, hud.offscreen_root, hud.hazard_label, hud.cutin_root]:
		if node.visible:
			push_error("The results table should hide %s" % node.name)
			failed = true
	if hud.flash_rect.color.a > 0.0:
		push_error("The results table should clear the ultimate flash")
		failed = true
	hud._set_match_hud_visible(true)
	if not hud.bot_panel.visible or not hud.offscreen_root.visible:
		push_error("The next match should bring back the bot panel and the off-screen arrows")
		failed = true
	main.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Bot panel tests passed")
	quit(0)
