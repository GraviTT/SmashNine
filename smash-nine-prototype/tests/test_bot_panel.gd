extends SceneTree
## Live bot panel (F4, 2026-10-08): one row per fighter with what its bot is doing; the HUD
## clock and status keep updating next to it; F4 hides it. The results table hides it and the
## rest of the match HUD (QA-15); the next match brings back what F4 chose.

const MAIN_SCENE := "res://scenes/Main.tscn"

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
	if hud.clock_label.text == "" or hud.status_label.text == "":
		push_error("The HUD clock and status should keep updating with the panel on")
		failed = true
	hud.toggle_bot_panel()
	if hud.bot_panel.visible:
		push_error("F4 should hide the bot panel")
		failed = true
	hud.toggle_bot_panel()
	var standings: Array[Node] = []
	standings.assign(main.players)
	hud.show_results(main.players[0], "test", standings, null)
	for node in [hud.bot_panel, hud.clock_label, hud.status_label, hud.minimap_root, hud.offscreen_root, hud.hazard_label]:
		if node.visible:
			push_error("The results table should hide %s" % node.name)
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
