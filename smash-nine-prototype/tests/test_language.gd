extends SceneTree
## CODEX-LANG-01: real imported translations, source coverage, menu reloads and no-save tests.
## Windowed only: -- --capture writes the Korean/English review captures to the report.

const LANGUAGE := preload("res://scripts/Language.gd")
const MENU := preload("res://scripts/ui/FrontendMenu.gd")
const CARDS := preload("res://scripts/match/SoulCards.gd")
const CATALOG := preload("res://scripts/realms/RealmCatalog.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const ARCHETYPES := preload("res://scripts/monsters/MonsterArchetypes.gd")
const MONSTER := preload("res://scripts/RealmMonster.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
const DIRECTOR := preload("res://scripts/match/MatchDirector.gd")
var failed := false
var capture := false
var keys: Dictionary = {}
var checked_literals := 0
var report_dir := ""

func _initialize() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	report_dir = ProjectSettings.globalize_path("res://../reports/codex-lang-01")
	create_timer(90.0).timeout.connect(func() -> void:
		push_error("Language test timed out")
		quit(1))
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _read_choice() -> String:
	return FileAccess.get_file_as_string(LANGUAGE.SAVE_PATH) if FileAccess.file_exists(LANGUAGE.SAVE_PATH) else "<missing>"

func _run() -> void:
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	var choice_before := _read_choice()
	var choice_mtime := FileAccess.get_modified_time(LANGUAGE.SAVE_PATH) if FileAccess.file_exists(LANGUAGE.SAVE_PATH) else 0
	_read_table()
	_check_source_literals("res://scripts")
	_check_source_literals("res://characters")
	_check_menu_literals()
	_check_data_keys()
	LANGUAGE.set_locale("en")
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(6)
	var main: Node = current_scene
	var menu: Control = main.hud.frontend
	_check(_has_text(menu, "Battle Royale"), "English title must retain Play")
	_check(menu.session_status.text.contains("Language: English"), "Title footer must show current language")
	await _capture("01-title-en")
	menu.show_options()
	_check(menu.language_button.text == "Language: English", "English language option missing")
	# Use the real button/action/reload route, not just TranslationServer.set_locale().
	menu.language_button.pressed.emit()
	await _frames(7)
	main = current_scene
	menu = main.hud.frontend
	_check(LANGUAGE.locale == "ko" and menu.screen == "options", "Language option must reload Options in Korean")
	_check(root.title == "스매시 나인 렐름즈 프로토타입", "Window title must follow the selected language without changing project identity")
	_check(menu.language_button.text == "언어: 한국어", "Korean option must use imported table")
	_check(_has_text(menu, "게임 속도", true), "Options values must translate before formatting")
	_check_menu_fit(menu)
	await _capture("04-options-ko")
	menu.show_title()
	_check(_has_text(menu, "배틀로얄") and not _has_text(menu, "Battle Royale"), "Korean title must change button text")
	_check(menu.session_status.text.contains("한국어"), "Korean footer must show selected language")
	_check_menu_fit(menu)
	await _capture("02-title-ko")
	menu.show_select()
	var roster: Dictionary = REGISTRY.get_characters()
	for id in REGISTRY.get_character_ids():
		menu.selected_id = id
		menu._refresh_fighter()
		_check(menu.fighter_name.text == tr(str(roster[id].name)).to_upper(), "Fighter name missing: " + id)
		_check(menu.fighter_role.text != str(roster[id].role), "Fighter role not translated: " + id)
		_check(menu.description.text == tr(MENU.KITS[id][0]), "Description not translated: " + id)
		_check_menu_fit(menu)
	menu.selected_id = "frey"
	menu._refresh_fighter()
	_check(menu.fighter_name.text == "프레이", "Korean character selection must show Frey in Korean")
	await _capture("03-select-ko")
	# New story screens use the same Korean fit checks as the existing menus.
	menu.show_story_select()
	_check_menu_fit(menu)
	menu.show_story_map(1)
	_check_menu_fit(menu)
	menu.show_stage_card(preload("res://scripts/story/StoryCatalog.gd").stage(2))
	_check_menu_fit(menu)
	menu.show_story_pause()
	_check_menu_fit(menu)
	menu.show_story_result({"clear": true, "stage": 4, "seconds": 91, "damage": 42, "cards": ["sky_step", "last_stand"]})
	_check_menu_fit(menu)
	for id in REGISTRY.get_character_ids():
		menu.selected_id = id
		menu.show_story_ending()
		_check_menu_fit(menu)
		_check(_has_text(menu, tr("STORY COMPLETE")), "Ending title uses the imported translation")
	menu.selected_id = "frey"
	menu.show_controls()
	_check(_has_text(menu, "조작법"), "Controls heading must translate")
	_check_menu_fit(menu)
	await _capture("07-controls-ko")
	menu.show_select()
	main._on_frontend_action("start", "")
	await _frames(5)
	var human: Node = main._get_human_player()
	_check(main.match_started, "Korean selection must start a match")
	_check(main.hud.status_label.text.contains("생존") and main.hud.status_label.text.contains("프레이"), "Next match HUD must use Korean")
	_check(main.hud.clock_label.text.contains("탐색"), "Phase label must translate without changing internal phase")
	Input.action_press("game_speed")
	await _frames(2)
	Input.action_release("game_speed")
	_check(main.hud.info_label.text == "게임 속도 90%", "In-match speed message must translate its format")
	SPEED.factor = 1.0
	SPEED.apply_to_match()
	_check(main.director.get_phase_name() == "Exploration", "Locale must not change AI/rule phase identifiers")
	_check(_has_text(main.world, "Q LEFT: Asgard"), "World portal source label must remain an English identifier")
	_check(tr("Q LEFT: Asgard") == "Q 왼쪽: 아스가르드", "Read-only world labels must auto-translate their complete source string")
	# A real realm hazard, triggered through its existing test hook. No product timing changes.
	main.layout.assign_combatant(human, 4)
	human.reset_for_map(main.layout.pick_spawn(4), main.layout.get_spawn_points(4))
	main._set_map(4)
	main.hud.bot_panel.visible = false
	main.hazards.trigger(4)
	await _frames(3)
	main._update_hud()
	_check(main.hud.warning_label.text.contains("마그마"), "Realm hazard warning must translate")
	_check(main.hud.realm_label.text.contains("무스펠헤임"), "Realm title and subtitle must translate independently")
	await _capture("05-hazard-hud-ko")
	main.hud.show_card_offer(CARDS.CARDS.slice(0, 3), 5.0)
	_check(main.hud.card_labels[0].text.contains("공격력 +12%"), "Card title/description/kind must translate")
	_check_card_fit(main.hud)
	await _capture("08-soul-cards-ko")
	main.hud.show_card_offer(CARDS.CARDS.slice(3, 6), 5.0)
	_check_card_fit(main.hud)
	await _capture("09-soul-cards-action-ko")
	main.hud.hide_card_offer()
	# Cover every generated monster name, including elite formatting.
	for skin in ARCHETYPES.SKINS:
		var title: String = ARCHETYPES.title_for(skin)
		_check(keys.has(title), "Generated monster name absent: " + title)
	var monster := MONSTER.new()
	monster.setup("mossling", 4, human.global_position, "asgard_aegis_ram")
	monster.make_elite()
	root.add_child(monster)
	monster._update_visuals()
	_check(monster.name_label.text.contains("정예 방패 숫양"), "Elite monster pattern must translate its nested name")
	_check(monster.display_name == "Elite Aegis Ram", "Elite source name must remain stable for other consumers")
	monster.free()
	# Results exercise translated names, reason, columns, awards and soul cards.
	human.upgrades.assign(["sky_step", "last_stand"])
	main.director._finish(human, "last survivor")
	await _frames(3)
	menu = main.hud.frontend
	_check(_has_text(menu, "프레이 승리"), "Korean winner heading missing")
	_check(_has_text(menu, "승부 판정: 최후의 생존자"), "Result reason must translate")
	_check(_has_text(menu, "2  공중 도약, 최후의 저항"), "Result card names must translate")
	_check_menu_fit(menu)
	await _capture("06-results-ko")
	main.hud.show_results(null, "double KO", main.director.get_standings(), human)
	_check(_has_text(menu, "무승부"), "Korean draw heading missing")
	var draw_messages: Array[String] = []
	var draw_director := DIRECTOR.new()
	draw_director.announcement.connect(func(message: String) -> void: draw_messages.append(message))
	draw_director._finish(null, "double KO")
	_check(draw_messages == ["승자 없음 (동시 탈락)."], "A draw announcement must not claim that Nobody won in Korean")
	draw_director.free()
	# The same option returns to English and updates the next screen/match.
	menu.show_options()
	menu.language_button.pressed.emit()
	await _frames(7)
	main = current_scene
	menu = main.hud.frontend
	_check(menu.language_button.text == "Language: English", "Switching back must restore exact English option text")
	_check(root.title == "Smash Nine Realms Prototype", "Switching back must restore the exact English window title")
	menu.show_title()
	_check(_has_text(menu, "Battle Royale"), "Switching back must restore English title")
	menu.show_select()
	_check(menu.fighter_name.text == "FREY", "Switching back must restore exact uppercase English name")
	main._on_frontend_action("start", "")
	await _frames(4)
	human = main._get_human_player()
	main.director._finish(human, "last survivor")
	await _frames(3)
	_check(_has_text(main.hud.frontend, "FREY WINS"), "Switching back must restore exact English results")
	draw_messages.clear()
	draw_director = DIRECTOR.new()
	draw_director.announcement.connect(func(message: String) -> void: draw_messages.append(message))
	draw_director._finish(null, "double KO")
	_check(draw_messages == ["Nobody wins (double KO)."], "English draw announcement must exactly retain the original output")
	draw_director.free()
	_check(_read_choice() == choice_before, "Test/headless language switching must not write saved preference")
	_check((FileAccess.get_modified_time(LANGUAGE.SAVE_PATH) if FileAccess.file_exists(LANGUAGE.SAVE_PATH) else 0) == choice_mtime, "Language test must not rewrite an existing saved choice")
	_check(not LANGUAGE._uses_saved_choice(), "Script/headless tests must not use saved language")
	LANGUAGE.set_locale("en")
	if not failed:
		print("Language tests passed (%d keys, %d tr literals; Korean/English reload, all fighters, HUD/hazard/cards/results, no saved-choice writes)" % [keys.size(), checked_literals])
	quit(1 if failed else 0)

func _read_table() -> void:
	var format_regex := RegEx.new()
	format_regex.compile("%(?:[-+0 ]*\\d*(?:\\.\\d+)?)?[sdif]|%%")
	var file := FileAccess.open("res://assets/i18n/strings.csv", FileAccess.READ)
	_check(file != null, "Cannot read strings.csv")
	if file == null:
		return
	_check(file.get_csv_line() == PackedStringArray(["keys", "en", "ko"]), "Translation CSV header changed")
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 1 and row[0].is_empty():
			continue
		_check(row.size() == 3, "Malformed translation row: " + str(row))
		if row.size() != 3:
			continue
		_check(not keys.has(row[0]), "Duplicate translation key: " + row[0])
		_check(row[0] == row[1], "English translation must exactly match source: " + row[0])
		_check(not row[2].strip_edges().is_empty(), "Empty Korean translation: " + row[0])
		var formats: Array[String] = []
		var translated_formats: Array[String] = []
		for result in format_regex.search_all(row[0]):
			formats.append(result.get_string())
		for result in format_regex.search_all(row[2]):
			translated_formats.append(result.get_string())
		_check(formats == translated_formats, "Translation changed format placeholders: " + row[0])
		keys[row[0]] = row[2]
	# Imported resources, not just the CSV, must contain the current copy.
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		for key: String in keys:
			_check(tr(key) == (keys[key] if locale == "ko" else key), "Re-import needed or translation differs: " + key)

func _check_source_literals(path: String) -> void:
	var directory := DirAccess.open(path)
	for child in directory.get_directories():
		_check_source_literals(path.path_join(child))
	var regex := RegEx.new()
	regex.compile('\\btr\\(\\s*"((?:[^"\\\\]|\\\\.)*)"')
	for filename in directory.get_files():
		if not filename.ends_with(".gd"):
			continue
		var source := FileAccess.get_file_as_string(path.path_join(filename))
		for result in regex.search_all(source):
			var key := result.get_string(1).c_unescape()
			checked_literals += 1
			_check(keys.has(key), "tr literal missing Korean key: %s in %s" % [key, path.path_join(filename)])

func _check_data_keys() -> void:
	for kit: Array in MENU.KITS.values():
		for text: String in kit:
			_check(keys.has(text), "Kit string missing: " + text)
	for row: Array in MENU.CONTROLS:
		for text: String in row:
			# Key glyphs such as J, K / L and 1 / 2 / 3 intentionally stay unchanged.
			if text.length() > 8 or text == "Space":
				_check(keys.has(text), "Control string missing: " + text)
	for data: Dictionary in REGISTRY.get_characters().values():
		for field in ["name", "role", "ultimate_name"]:
			_check(keys.has(str(data[field])), "Character data string missing: " + str(data[field]))
	for realm: Dictionary in CATALOG.build_maps():
		for field in ["name", "subtitle", "identity"]:
			_check(keys.has(str(realm[field])), "Realm string missing: " + str(realm[field]))
		var hazard: Dictionary = realm.get("hazard", {})
		for field in ["text", "warn_text"]:
			if hazard.has(field):
				_check(keys.has(str(hazard[field])), "Hazard string missing: " + str(hazard[field]))
	for card: Dictionary in CARDS.CARDS:
		for field in ["title", "text", "kind"]:
			_check(keys.has(str(card[field])), "Card string missing: " + str(card[field]))
	for text in ["Battle Royale", "Story", "Watch bots", "Options", "Controls", "Fighter", "KOs", "Damage", "Souls", "Cards", "Survived", "MOST DAMAGE", "MOST KOs", "LONGEST SURVIVAL", "Male", "Female", "Original art", "Prototype art", "On", "Off", "last survivor", "double KO", "no survivors", "final judgment", "Exploration", "Corner collapse warning", "Convergence", "Central brawl", "Sudden death", "Match over"]:
		_check(keys.has(text), "Dynamic menu/phase string missing: " + text)

func _check_menu_literals() -> void:
	var regex := RegEx.new()
	regex.compile('\\b_(?:label|button|finish)\\(\\s*"((?:[^"\\\\]|\\\\.)*)"')
	var source := FileAccess.get_file_as_string("res://scripts/ui/FrontendMenu.gd") + FileAccess.get_file_as_string("res://scripts/ui/StoryScreens.gd") + FileAccess.get_file_as_string("res://scripts/ui/StoryDialogue.gd")
	for result in regex.search_all(source):
		var key := result.get_string(1).c_unescape()
		if not key.is_empty() and not key.begins_with("%"):
			_check(keys.has(key), "Menu helper literal missing: " + key)

func _has_text(node: Node, expected: String, substring := false) -> bool:
	if node is Label or node is Button:
		if node.text.contains(expected) if substring else node.text == expected:
			return true
	for child in node.get_children():
		if _has_text(child, expected, substring):
			return true
	return false

func _check_menu_fit(menu: Control) -> void:
	for child in menu.content.get_children():
		if child is Label:
			_check(child.position.x + child.size.x <= 1281 and child.position.y + child.size.y <= 721, "Menu label outside viewport: " + child.text)
		elif child is Button:
			var font: Font = child.get_theme_font("font")
			var width := font.get_string_size(child.text, HORIZONTAL_ALIGNMENT_LEFT, -1, child.get_theme_font_size("font_size")).x
			_check(width <= child.size.x - 24, "Button text does not fit: " + child.text)

func _check_card_fit(hud: Node) -> void:
	for label: Label in hud.card_labels:
		# The pre-existing offer panel is 152 x 80 inside each card frame. Copy must fit
		# that space; LANG-01 must not resize/rewrite this panel (another branch owns it).
		_check(label.get_line_count() * label.get_line_height() <= 80, "Korean card copy overflows its unchanged box: " + label.text)

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _capture(stem: String) -> void:
	if not capture:
		return
	_check(DisplayServer.get_name() != "headless", "Captures must be windowed")
	await _frames(3)
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(report_dir.path_join(stem + ".png"))
	_check(result == OK, "Could not save capture " + stem)
