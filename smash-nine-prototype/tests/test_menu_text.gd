extends SceneTree
## Menu text (UI audit 2026-11-25, reports/ui-audit-2026-11-25): hints that name the quick-start
## number keys follow the roster (B3: the controls row still said "1 - 5" with six fighters), the
## "most damage" award shows the damage the table shows (B4: the table rounded, the award cut the
## decimals), and the select screen's kit rows keep clear of each other and of the panel in both
## languages (B6: a wrapped line sat 5 px above the next row).

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAIN := preload("res://scripts/Main.gd")
const MENU := preload("res://scripts/ui/FrontendMenu.gd")
const STORY_MENU := preload("res://scripts/ui/StoryScreens.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
## The select screen's right panel is Rect2(742, 128, 502, 510).
const PANEL_BOTTOM := 638.0
const PANEL_PADDING := 12.0
const MIN_ROW_GAP := 10.0

var failed := false
var rows_checked := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	await _quick_start_hints()
	await _kit_rows()
	await _award_matches_table()
	LANGUAGE.set_locale("en")
	if not failed:
		print("Menu text tests passed (number-key hints follow the roster on four screens in en/ko; %d kit rows clear of each other; the damage award matches the table)" % rows_checked)
	quit(1 if failed else 0)

func _texts(node: Node, into: Array[String]) -> void:
	if node is Label or node is Button:
		into.append(str(node.text))
	for child in node.get_children():
		_texts(child, into)

func _quick_start_hints() -> void:
	var roster := REGISTRY.get_character_ids().size()
	var keys := mini(roster, MAIN.CHOOSE_ACTIONS.size())
	_check(int((MENU as Script).get_script_constant_map().get("QUICK_START_KEYS", -1)) == MAIN.CHOOSE_ACTIONS.size(), "FrontendMenu.QUICK_START_KEYS should be the number of Main.CHOOSE_ACTIONS")
	var menu: Control = STORY_MENU.new()
	root.add_child(menu)
	await process_frame
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		var range_text := ("1-%d" if locale == "en" else "1~%d") % keys
		for screen in ["title", "select", "controls", "story_select"]:
			match screen:
				"title": menu.show_title()
				"select": menu.show_select()
				"controls": menu.show_controls()
				"story_select": menu.show_story_select()
			await process_frame
			var texts: Array[String] = []
			_texts(menu.content, texts)
			var expected := range_text
			if screen == "controls":
				expected = ("1 - %d" if locale == "en" else "1~%d") % keys
			elif screen == "story_select":
				expected = ("1-%d" if locale == "en" else "1~%d") % menu.select_ids.size()
			var found := false
			for text in texts:
				_check(not text.contains("%d"), "An unfilled number on the %s screen (%s): %s" % [screen, locale, text])
				if text.contains(expected + ":") or text.begins_with(expected + " /"):
					found = true
			_check(found, "The %s screen (%s) should name the number keys as %s" % [screen, locale, expected])
	menu.queue_free()
	await process_frame

func _kit_rows() -> void:
	var menu: Control = MENU.new()
	root.add_child(menu)
	await process_frame
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		menu.show_select()
		await process_frame
		for id in REGISTRY.get_character_ids():
			menu.selected_id = id
			menu._refresh_fighter()
			await process_frame
			var where := "%s %s" % [locale, id]
			var bottom: float = menu.description.position.y + menu.description.get_line_count() * menu.description.get_line_height()
			for index in menu.skill_labels.size():
				var line: Label = menu.skill_labels[index]
				if not line.visible:
					continue
				rows_checked += 1
				_check(line.position.y >= bottom + MIN_ROW_GAP - 0.5, "%s: kit row %d starts %.0f px under the text above it (needs %.0f)" % [where, index + 1, line.position.y - bottom, MIN_ROW_GAP])
				_check(absf(menu.skill_keys[index].position.y - line.position.y) <= 6.0, "%s: the key of kit row %d is not level with its text" % [where, index + 1])
				bottom = line.position.y + line.get_line_count() * line.get_line_height()
			_check(bottom <= PANEL_BOTTOM - PANEL_PADDING, "%s: the kit text runs down to y %.0f, past the panel (%.0f)" % [where, bottom, PANEL_BOTTOM - PANEL_PADDING])
	menu.queue_free()
	await process_frame

func _award_matches_table() -> void:
	LANGUAGE.set_locale("en")
	var main: Node = load(MAIN_SCENE).instantiate()
	root.add_child(main)
	for frame in 5:
		await process_frame
	main._start_match("frey")
	for frame in 5:
		await process_frame
	var players: Array[Node] = main.players
	var survival := {}
	for player in players:
		player.damage_dealt = 3.0
		survival[player] = 60.0
	var best: Node = players[2]
	best.damage_dealt = 27.6
	main.hud.frontend.show_results(players[0], "last_survivor", players, players[0], survival)
	await process_frame
	var texts: Array[String] = []
	_texts(main.hud.frontend.content, texts)
	_check(texts.has("28"), "The standings should show 27.6 damage as 28")
	var award := "%s  /  28" % str(best.display_name)
	var shown := ""
	for text in texts:
		if text.begins_with(str(best.display_name) + "  /  "):
			shown = text
	_check(shown == award, "The most damage award should read '%s' as the table does, got '%s'" % [award, shown])
	main.queue_free()
	await process_frame
