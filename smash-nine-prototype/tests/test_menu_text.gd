extends SceneTree
## Menu text (UI audit 2026-11-25, reports/ui-audit-2026-11-25): hints that name the quick-start
## number keys follow the roster (B3: the controls row still said "1 - 5" with six fighters), the
## "most damage" award shows the damage the table shows (B4: the table rounded, the award cut the
## decimals), and the select screen's kit rows keep clear of each other and of the panel in both
## languages (B6: a wrapped line sat 5 px above the next row). Since the menu round's pick (B,
## 2026-11-27) the kit stands in two columns: each row is the move's slot, its name on one line and
## what it does in at most two lines, every line shown.

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAIN := preload("res://scripts/Main.gd")
const MENU := preload("res://scripts/ui/FrontendMenu.gd")
const STORY_MENU := preload("res://scripts/ui/StoryScreens.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
## The select screen's info panel (the fighter's name band, description and kit).
const INFO_PANEL := Rect2(548, 72, 696, 432)
const PANEL_PADDING := 12.0
const MIN_ROW_GAP := 6.0

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
			var description: Label = menu.description
			_check(description.get_visible_line_count() == description.get_line_count(), "%s: the description should show all its lines" % where)
			var bottom: float = description.position.y + _text_height(description)
			var inside := INFO_PANEL.grow(-PANEL_PADDING)
			var rows: Array[Rect2] = []
			for index in menu.skill_labels.size():
				var detail: Label = menu.skill_labels[index]
				if not detail.visible:
					continue
				rows_checked += 1
				var title: Label = menu.skill_titles[index]
				var slot: Control = menu.skill_rows[index].slot
				var title_width := title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x
				_check(title.text != "" and title_width <= title.size.x + 0.5, "%s: the name of kit row %d is cut (%.0f px of %.0f): %s" % [where, index + 1, title_width, title.size.x, title.text])
				_check(detail.text != "" and detail.get_line_count() <= 2 and detail.get_visible_line_count() == detail.get_line_count(), "%s: kit row %d shows %d of its %d lines (at most 2): %s" % [where, index + 1, detail.get_visible_line_count(), detail.get_line_count(), detail.text.replace(String.chr(0x2060), "")])
				var row := slot.get_rect().merge(title.get_rect()).merge(Rect2(detail.position, Vector2(detail.size.x, _text_height(detail))))
				_check(row.position.y >= bottom + MIN_ROW_GAP - 0.5, "%s: kit row %d starts %.0f px under the description (needs %.0f)" % [where, index + 1, row.position.y - bottom, MIN_ROW_GAP])
				_check(inside.encloses(row), "%s: kit row %d %s runs out of the panel %s" % [where, index + 1, row, inside])
				for other in rows:
					_check(not other.intersects(row), "%s: kit row %d %s runs into another row %s" % [where, index + 1, row, other])
				rows.append(row)
				# The key's cap sits on the move's slot (none on the passive).
				var cap := menu.skill_keys[index].get_parent() as Control
				_check(cap.visible == (index < rows_wanted(menu) - 1) and (not cap.visible or Rect2(Vector2(-16, -16), slot.size + Vector2(32, 32)).encloses(cap.get_rect())), "%s: the key cap of kit row %d should sit on its slot" % [where, index + 1])
	menu.queue_free()
	await process_frame

## A label's lines as drawn: each line's height and the spacing between them.
func _text_height(label: Label) -> float:
	var lines := label.get_line_count()
	return lines * label.get_line_height() + (lines - 1) * label.get_theme_constant("line_spacing")

## The kit rows the fighter shown has (five, six with a third skill); the passive is the last.
func rows_wanted(menu: Control) -> int:
	return menu.skill_labels.filter(func(label: Label) -> bool: return label.visible).size()

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
