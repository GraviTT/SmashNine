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
const AUDIO_SETTINGS := preload("res://scripts/audio/AudioSettings.gd")
const FIGHTER_NAMES := preload("res://scripts/ui/FighterNames.gd")
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
	await _audit_batch_two()
	await _nine_and_sixteen()
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
	# The name as the results show it: seat 3 shares its character with seat 2, so it reads "Yuki 2".
	var name := FIGHTER_NAMES.shown(best)
	var award := "%s  /  28" % name
	var shown := ""
	for text in texts:
		if text.begins_with(name + "  /  "):
			shown = text
	_check(shown == award, "The most damage award should read '%s' as the table does, got '%s'" % [award, shown])
	# The player's place, large at the top right (UI audit 13-5): first, then fourth, none when
	# watching bots.
	for case in [[players[0], "1 / %d" % players.size()], [players[3], "4 / %d" % players.size()], [null, ""]]:
		main.hud.frontend.show_results(players[0], "last_survivor", players, case[0], survival)
		await process_frame
		var place_texts: Array[String] = []
		_texts(main.hud.frontend.content, place_texts)
		if case[0] == null:
			_check(not place_texts.has(tr("YOUR PLACE")), "Watching bots should show no place")
		else:
			_check(place_texts.has(tr("YOUR PLACE")) and place_texts.has(case[1]), "The results should show the player's place %s" % case[1])
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
		for screen in ["options", "controls", "controls_pad", "story_map", "story_card", "story_pause", "story_clear", "story_failed"]:
			match screen:
				"options": menu.show_options()
				"controls": menu.show_controls_tab("keys")
				"controls_pad": menu.show_controls_tab("pad")
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

## The UI audit's second batch (2026-11-27): Left / Right lower and raise a volume in steps of 10,
## held at 0 and 100 (3-3); the keyboard's table keeps the match's keys apart from the menus and
## tools (4-1); the start card's bar runs down over the card's own CARD_SECONDS (16-1).
func _audit_batch_two() -> void:
	LANGUAGE.set_locale("en")
	var menu: Control = STORY_MENU.new()
	root.add_child(menu)
	await process_frame
	menu.show_options()
	var master: Button = menu.audio_buttons.master
	menu.focus_index = menu.buttons.find(master)
	master.grab_focus()
	var before: int = int(AUDIO_SETTINGS.values.master)
	AUDIO_SETTINGS.values.master = 10
	for step: Array in [[KEY_LEFT, 0], [KEY_LEFT, 0], [KEY_RIGHT, 10], [KEY_D, 20], [KEY_A, 10]]:
		_key(menu, step[0])
		_check(int(AUDIO_SETTINGS.values.master) == step[1], "Left / Right on the master volume should give %d, got %d" % [step[1], AUDIO_SETTINGS.values.master])
	AUDIO_SETTINGS.values.master = 100
	_key(menu, KEY_RIGHT)
	_check(int(AUDIO_SETTINGS.values.master) == 100, "Right should hold the volume at 100")
	_check(master.text == tr("Master volume: %d%%") % 100, "The row should show the new volume (%s)" % master.text)
	AUDIO_SETTINGS.values.master = before
	# On a row that is not sound, Left / Right still move the focus.
	var speed_index: int = menu.buttons.find(menu.speed_button)
	menu.focus_index = speed_index
	menu.speed_button.grab_focus()
	_key(menu, KEY_RIGHT)
	_check(menu.focus_index != speed_index, "Right on the speed row should move the focus")
	# The keyboard's table: the match's keys on the left sheet, menus and tools on the right.
	menu.show_controls_tab("keys")
	await process_frame
	var texts: Array[String] = []
	_texts(menu.content, texts)
	_check(texts.has(tr("IN A MATCH")) and texts.has(tr("MENUS AND TOOLS")), "The keyboard's table should name its two groups")
	for child in menu.content.get_children():
		if child is Label and child.text in ["H", "F3 / F4", "T", tr("F2 (before a match)")]:
			_check(child.position.x > 640.0, "%s belongs with the menus and tools (x %.0f)" % [child.text, child.position.x])
		elif child is Label and child.text in [tr("A / D  or  Left / Right"), "Space", "Q"]:
			_check(child.position.x < 640.0, "%s belongs with the match's keys (x %.0f)" % [child.text, child.position.x])
	# The start card's bar: the card's own seconds, running down.
	menu.selected_id = "frey"
	menu.body = "male"
	menu.show_stage_card(STORY.stage(2))
	var left: int = menu.card_deadline - Time.get_ticks_msec()
	_check(absi(left - int(STORY_MENU.CARD_SECONDS * 1000.0)) <= 100, "The card should go on after CARD_SECONDS (%d ms left)" % left)
	await create_timer(0.3).timeout
	var bar: ColorRect = menu.card_bar
	_check(is_instance_valid(bar) and bar.scale.x < 1.0 and bar.scale.x > 0.5, "The card's bar should run down with its seconds (%s)" % (bar.scale.x if is_instance_valid(bar) else -1.0))
	menu.card_deadline = 9223372036854775807
	menu.queue_free()
	await process_frame

## Ready for nine fighters (D58: Borok, Doron and Jupi join) and sixteen-fighter matches, with three
## stand-in fighters made here only (copies of others' data under new ids, no art, no kit text): the
## select strip holds nine and Random, the story select nine and the difficulty, every tile inside
## the strip and apart with its number key; a fighter without kit text still draws; the results hold
## nine and sixteen rows above the awards; every screen stays clear (_screen_clear).
func _nine_and_sixteen() -> void:
	var stand_ins := {"borok": ["Borok", Color("c8743c")], "doron": ["Doron", Color("6c9a4a")], "jupi": ["Jupi", Color("d36fb5")]}
	var ids: Array[String] = REGISTRY.get_character_ids()
	for id: String in stand_ins:
		ids.append(id)
	var menu: Control = STORY_MENU.new()
	root.add_child(menu)
	await process_frame
	for id: String in stand_ins:
		var data: Dictionary = (menu._roster["frey"] as Dictionary).duplicate()
		data.name = stand_ins[id][0]
		data.color = stand_ins[id][1]
		menu._roster[id] = data
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		for story in [false, true]:
			if story:
				menu.show_story_select(ids)
			else:
				menu.show_select(ids)
			await process_frame
			var where := "%s %s with nine" % [locale, "story select" if story else "select"]
			var tiles: Array[Rect2] = []
			for button: Button in menu.portrait_buttons:
				tiles.append(button.get_rect())
			tiles.append((menu.difficulty_button as Button).get_rect() if story else menu.buttons[menu.portrait_buttons.size()].get_rect())
			_check(tiles.size() == 10, "%s: nine fighters and one more tile, got %d" % [where, tiles.size()])
			for index in tiles.size():
				_check(menu.SELECT_STRIP.encloses(tiles[index]), "%s: tile %d %s leaves the strip %s" % [where, index + 1, tiles[index], menu.SELECT_STRIP])
				for other in range(index + 1, tiles.size()):
					_check(not tiles[index].intersects(tiles[other]), "%s: tiles %d and %d overlap" % [where, index + 1, other + 1])
			var texts: Array[String] = []
			_texts(menu.content, texts)
			for number in range(1, 10):
				_check(texts.has(str(number)), "%s: tile %d should show its number key" % [where, number])
			menu.selected_id = "jupi"
			menu._refresh_fighter()
			_check(menu.fighter_name.text == "JUPI", "%s: a fighter without kit text should still draw (%s)" % [where, menu.fighter_name.text])
			_screen_clear(menu, where)
	LANGUAGE.set_locale("en")
	# The results with nine fighters, and with sixteen (each kind twice, the stand-ins once more).
	var script := GDScript.new()
	script.source_code = "extends Node\nvar character_id := \"\"\nvar body_type := \"male\"\nvar display_name := \"\"\nvar score := 0\nvar damage_dealt := 0.0\nvar souls := 0\nvar upgrades: Array = []\n"
	script.reload()
	for count in [9, 16]:
		var standings: Array[Node] = []
		var survival := {}
		for index in count:
			var player := Node.new()
			player.set_script(script)
			var id: String = ids[index % ids.size()]
			player.character_id = id
			player.display_name = str(menu._roster[id].name)
			player.score = count - index
			player.damage_dealt = 10.0 * (count - index)
			player.upgrades = ["sky_step", "last_stand"] if index % 3 == 0 else []
			root.add_child(player)
			standings.append(player)
			survival[player] = 300 - index * 10
		menu.show_results(null, "last_survivor", standings, standings[count - 1], survival)
		await process_frame
		await process_frame
		var where := "results with %d" % count
		var grid := menu.content.get_node("Standings") as GridContainer
		_check(grid.get_child_count() == (count + 1) * 8, "%s: every fighter should have a row (%d cells)" % [where, grid.get_child_count()])
		var bottom := grid.position.y + grid.size.y
		_check(bottom <= 570.0, "%s: the table should end above the awards (ends at %.0f)" % [where, bottom])
		var texts: Array[String] = []
		_texts(menu.content, texts)
		_check(texts.has(tr("YOUR PLACE")) and texts.has("%d / %d" % [count, count]), "%s: the last player's place should read %d / %d" % [where, count, count])
		_screen_clear(menu, where)
		for player in standings:
			player.queue_free()
	menu.queue_free()
	await process_frame

func _key(menu: Control, keycode: int) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	event.physical_keycode = keycode
	menu._input(event)

func _screen_clear(menu: Control, where: String) -> void:
	screens_checked += 1
	# The key hints stand on a dark plate as wide as their words (UI audit 1-1), inside their area.
	# Untyped first: on a screen without hints (the results) the last screen's label is freed.
	var hints: Variant = menu.footer
	if is_instance_valid(hints) and hints is Label and hints.get_parent() == menu.content:
		var plate := hints.get_theme_stylebox("normal") as StyleBoxFlat
		var area: Rect2 = hints.get_meta("area", Rect2())
		_check(plate != null and plate.bg_color.a >= 0.5, "%s: the hints should stand on a plate" % where)
		_check(area.has_area() and hints.size.x <= area.size.x + 0.5 and hints.position.x >= area.position.x - 0.5 and hints.position.x + hints.size.x <= area.end.x + 0.5, "%s: the hints' plate should be no wider than its area (%s in %s)" % [where, Rect2(hints.position, hints.size), area])
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
