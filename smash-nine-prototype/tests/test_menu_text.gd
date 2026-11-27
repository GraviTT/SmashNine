extends SceneTree
## Menu text (UI audit 2026-11-25, reports/ui-audit-2026-11-25): hints that name the quick-start
## number keys follow the roster (B3: the controls row still said "1 - 5" with six fighters), the
## "most damage" award shows the damage the table shows (B4: the table rounded, the award cut the
## decimals), and the select screen's kit rows keep clear of each other and of the panel in both
## languages (B6: a wrapped line sat 5 px above the next row). Since the menu round's pick (B,
## 2026-11-27) the kit stands in two columns: each row is the move's slot, its name on one line and
## what it does in at most two lines, every line shown. The screens after the menus took the same
## look the same day (options, controls, results, the story map, card, pause, result and ending): on
## each, in both languages, every text and button lies inside the screen with all its lines shown, no
## text runs over another or onto a button (a tile's own captions excepted), buttons keep apart, and
## a button's words end before its Enter cap.

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAIN := preload("res://scripts/Main.gd")
const MENU := preload("res://scripts/ui/FrontendMenu.gd")
const STORY_MENU := preload("res://scripts/ui/StoryScreens.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")
## The select screen's info panel (the fighter's name band, description and kit).
const INFO_PANEL := Rect2(548, 72, 696, 432)
const PANEL_PADDING := 12.0
const MIN_ROW_GAP := 6.0

var failed := false
var rows_checked := 0
var screens_checked := 0

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
	await _later_screens()
	LANGUAGE.set_locale("en")
	if not failed:
		print("Menu text tests passed (number-key hints follow the roster on four screens in en/ko; %d kit rows clear of each other; the damage award matches the table; %d later screens clear in en/ko)" % [rows_checked, screens_checked])
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
	# The results in the picked look, a winner and a draw, in both languages.
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		main.hud.frontend.show_results(players[0], "last_survivor", players, players[0], survival)
		await process_frame
		_screen_clear(main.hud.frontend, "%s results" % locale)
		main.hud.frontend.show_results(null, "double KO", players, players[0], survival)
		await process_frame
		_screen_clear(main.hud.frontend, "%s draw" % locale)
	LANGUAGE.set_locale("en")
	main.queue_free()
	await process_frame

func _later_screens() -> void:
	var menu: Control = STORY_MENU.new()
	root.add_child(menu)
	await process_frame
	menu.selected_id = "frey"
	menu.body = "male"
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		for screen in ["options", "controls", "story_map", "story_card", "story_pause", "story_clear", "story_failed"]:
			match screen:
				"options": menu.show_options()
				"controls": menu.show_controls()
				"story_map": menu.show_story_map(1)
				"story_card": menu.show_stage_card(STORY.stage(2))
				"story_pause": menu.show_story_pause()
				"story_clear": menu.show_story_result({"clear": true, "stage": 4, "seconds": 91, "damage": 42, "cards": ["sky_step", "last_stand"]})
				"story_failed": menu.show_story_result({"clear": false, "stage": 7, "seconds": 300, "damage": 120, "cards": [], "reason": "time up"})
			await process_frame
			_screen_clear(menu, "%s %s" % [locale, screen])
		for id in REGISTRY.get_story_character_ids():
			menu.selected_id = id
			menu.body = REGISTRY.get_bodies(id)[0]
			menu.show_story_ending()
			await process_frame
			_screen_clear(menu, "%s ending %s" % [locale, id])
	menu.queue_free()
	await process_frame

func _screen_clear(menu: Control, where: String) -> void:
	screens_checked += 1
	var texts: Array[Label] = []
	var buttons: Array[Button] = []
	for child in menu.content.get_children():
		if child is Label and child.visible and child.text.strip_edges() != "":
			texts.append(child)
		elif child is Button and child.visible:
			buttons.append(child)
	for label in texts:
		var rect := _drawn_rect(label)
		_check(rect.position.x >= -0.5 and rect.position.y >= -0.5 and rect.end.x <= 1280.5 and rect.end.y <= 720.5, "%s: words outside the screen %s: %s" % [where, rect, label.text])
		_check(label.get_visible_line_count() == label.get_line_count(), "%s: %d of %d lines shown: %s" % [where, label.get_visible_line_count(), label.get_line_count(), label.text])
		if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
			var box: StyleBox = label.get_theme_stylebox("normal")
			var room := label.size.x - box.get_margin(SIDE_LEFT) - box.get_margin(SIDE_RIGHT)
			var widest := 0.0
			for line in label.text.split("\n"):
				widest = maxf(widest, label.get_theme_font("font").get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x)
			_check(widest <= room + 0.5, "%s: an unwrapped line is wider than its label (%.0f px of %.0f): %s" % [where, widest, room, label.text])
		for button in buttons:
			var area := button.get_rect()
			if not area.encloses(Rect2(label.position, label.size)):
				_check(not rect.grow(-1).intersects(area), "%s: words '%s' %s run onto the button '%s' %s" % [where, label.text, rect, button.text, area])
	for i in texts.size():
		for j in range(i + 1, texts.size()):
			var a := _drawn_rect(texts[i])
			var b := _drawn_rect(texts[j])
			_check(not a.grow(-1).intersects(b.grow(-1)), "%s: words overlap: '%s' %s and '%s' %s" % [where, texts[i].text, a, texts[j].text, b])
	for i in buttons.size():
		var a := buttons[i].get_rect()
		_check(Rect2(0, 0, 1280, 720).encloses(a), "%s: the button '%s' %s leaves the screen" % [where, buttons[i].text, a])
		for j in range(i + 1, buttons.size()):
			_check(not a.intersects(buttons[j].get_rect()), "%s: the buttons '%s' and '%s' overlap" % [where, buttons[i].text, buttons[j].text])
		_words_clear_of_cap(buttons[i], where)

## Where a label's words are drawn: its widest line (the label's width once it wraps) by its lines'
## height, placed by its alignment inside its plate's margins.
func _drawn_rect(label: Label) -> Rect2:
	var font: Font = label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var box: StyleBox = label.get_theme_stylebox("normal")
	var inner := Rect2(label.position + Vector2(box.get_margin(SIDE_LEFT), box.get_margin(SIDE_TOP)), label.size - Vector2(box.get_margin(SIDE_LEFT) + box.get_margin(SIDE_RIGHT), box.get_margin(SIDE_TOP) + box.get_margin(SIDE_BOTTOM)))
	var width := 0.0
	for line in label.text.split("\n"):
		width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	width = minf(width, inner.size.x)
	var height := _text_height(label)
	var x := inner.position.x
	if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x += (inner.size.x - width) * 0.5
	elif label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x += inner.size.x - width
	var y := inner.position.y
	if label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER:
		y += (inner.size.y - height) * 0.5
	elif label.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM:
		y += inner.size.y - height
	return Rect2(x, y, width, height)

## A slanted button's words end before its Enter cap (shown with the focus, or always on gold).
func _words_clear_of_cap(button: Button, where: String) -> void:
	for child in button.get_children():
		if child is Panel and child.get_child_count() > 0 and child.get_child(0) is Label and (child.get_child(0) as Label).text == "Enter":
			var words := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
			var end := button.get_theme_stylebox("normal").get_margin(SIDE_LEFT) + words
			_check(end <= (child as Control).position.x - 6.0, "%s: '%s' runs into its Enter cap (words end %.0f px in, the cap at %.0f)" % [where, button.text, end, (child as Control).position.x])
