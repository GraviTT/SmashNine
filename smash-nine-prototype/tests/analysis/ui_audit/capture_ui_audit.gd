extends SceneTree
## UI audit captures (UI and design session, 2026-11-25, D53): every screen of the game in one
## language and one window size, as PNG. Windowed (not --headless). A script run never reads or
## writes the real saves (Language, StoryProgress and GameSpeed skip user:// under -s).
## Usage, from smash-nine-prototype/:
##   <godot> --audio-driver Dummy --path . -s tests/analysis/ui_audit/capture_ui_audit.gd -- \
##       --lang=ko --size=1280x720 --out=<absolute dir> [--only=menu,match,brawl,story]
## Shots are named <nn>_<what>.png; the same name means the same moment in every run.

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAIN := preload("res://scripts/Main.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const FOREVER := 9223372036854775807

var out_dir := ""
var lang := "en"
var window := Vector2i(1280, 720)
var only: Array = []
var main: Node
var failed := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):
			lang = arg.get_slice("=", 1)
		elif arg.begins_with("--size="):
			var parts := arg.get_slice("=", 1).split("x")
			window = Vector2i(int(parts[0]), int(parts[1]))
		elif arg.begins_with("--out="):
			out_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--only="):
			only = Array(arg.get_slice("=", 1).split(","))
	if out_dir == "":
		push_error("--out=<dir> is required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _wants(group: String) -> bool:
	return only.is_empty() or only.has(group)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Captures must be windowed")
		quit(1)
		return
	DisplayServer.window_set_size(window)
	root.size = window
	# The menus load the saved language once on creation; load first so the choice below stays.
	LANGUAGE.load_saved()
	LANGUAGE.set_locale(lang)
	await _frames(4)
	if _wants("menu"):
		await _menu_screens()
	if _wants("match"):
		await _match_screens()
	if _wants("brawl"):
		await _brawl_screens()
	if _wants("story"):
		await _story_screens()
	if _wants("bars"):
		await _skill_bars()
	await _close()
	LANGUAGE.set_locale("en")
	print("UI audit captures (%s, %dx%d) in %s" % [lang, window.x, window.y, out_dir])
	quit(1 if failed else 0)

# --- Helpers ---

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _shot(shot_name: String) -> void:
	await _frames(2)
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join(shot_name + ".png")
	if root.get_texture().get_image().save_png(path) != OK:
		failed = true
		push_error("Save capture: " + path)
	print("saved ", shot_name)

func _close() -> void:
	if is_instance_valid(main):
		paused = false
		Engine.time_scale = 1.0
		main.queue_free()
		await _frames(3)
	main = null

## A fresh Main on `destination` (Main.next_screen), with a fixed seed.
func _open(destination: String, seed_value := 4242, bots := false) -> void:
	await _close()
	MAIN.next_screen = destination
	main = load(MAIN_SCENE).instantiate()
	main.match_seed = seed_value
	main.bots_only = bots
	root.add_child(main)
	current_scene = main
	await _frames(6)

func _skip_to(time: float) -> void:
	while main.director.match_elapsed < time and not main.director.match_over:
		main.director.advance(minf(0.5, time - main.director.match_elapsed + 0.001))
		main._apply_phase_rules()
		await process_frame

func _move_to_realm(player: Node, realm: int, point_index := 0) -> void:
	var points: Array[Vector2] = main.layout.get_spawn_points(realm)
	main.layout.assign_combatant(player, realm)
	player.reset_for_map(points[point_index % points.size()], points)
	main._sync_combatant_visibility()

func _show_whole_line(dialogue: Node) -> void:
	dialogue._characters = dialogue.line_label.get_total_character_count()
	dialogue.line_label.visible_characters = -1

## To the next line, fully typed out (advance_line only finishes a line that is still typing).
func _next_line(dialogue: Node) -> void:
	_show_whole_line(dialogue)
	dialogue.advance_line()
	await _frames(2)
	_show_whole_line(dialogue)

func _bot_panel(shown: bool) -> void:
	main.hud.bot_panel_wanted = shown
	main.hud.bot_panel.visible = shown

# --- Menus ---

func _menu_screens() -> void:
	MAIN.human_body = "male"
	MAIN.last_character_id = "frey"
	await _open("title")
	await _shot("01_title")
	var menu: Control = main.hud.frontend
	menu.show_select()
	await _frames(2)
	await _shot("02_select_frey")
	for entry in [["nova", "03_select_nova"], ["xion", "04_select_xion"], ["luna", "05_select_luna"]]:
		menu.portrait_buttons[menu.select_ids.find(str(entry[0]))].grab_focus()
		await _frames(2)
		await _shot(str(entry[1]))
	menu.show_options()
	await _frames(2)
	await _shot("06_options")
	menu.show_controls()
	await _frames(2)
	await _shot("07_controls")

# --- A match as P1 (Frey), HUD states one by one ---

func _match_screens() -> void:
	MAIN.human_body = "male"
	MAIN.session_bot_panel = true
	await _open("title")
	main._start_match("frey")
	await _frames(100)
	var human: Node = main.players[0]
	human.grant_protection(10000.0)
	# The state a new player sees: the bot panel is on by default while the game is tested.
	await _shot("10_match_start_bot_panel")
	main.hud.toggle_debug()
	main._update_hud()
	await _shot("11_match_debug_f3")
	main.hud.toggle_debug()
	_bot_panel(false)
	await _shot("12_match_hud_plain")
	# A neighbour steps in: a fight next to P1.
	var rival: Node = null
	for player in main.players:
		if player != human and player.realm_index == human.realm_index:
			rival = player
	if rival == null:
		rival = main.players[1]
		_move_to_realm(rival, human.realm_index, 1)
	rival.global_position = human.global_position + Vector2(150, 0)
	rival.velocity = Vector2.ZERO
	await _frames(50)
	await _shot("13_match_fight")
	main._show_message(tr("%s was eliminated by %s. %d left.") % [tr("Luna"), tr("Rio"), 6])
	await _shot("14_match_message")
	human.add_souls(25)
	await _frames(20)
	await _shot("15_match_card_offer")
	main.soul_growth.choose(human, 0)
	await _frames(6)
	await _shot("16_match_card_picked")
	main.hud.show_ultimate_cutin(human)
	await _frames(14)
	await _shot("17_match_ult_cutin")
	await _frames(60)
	human.ultimate_cooldown_timer = 23.4
	human.hp = human.max_hp * 0.24
	await _frames(4)
	await _shot("18_match_low_hp_cooldown")
	human.hp = human.max_hp
	# A fighter of this realm outside the view: the edge arrow.
	var bounds: Rect2 = main.layout.get_bounds(human.realm_index)
	var floor_points: Array[Vector2] = main.layout.get_spawn_points(human.realm_index)
	var far_point: Vector2 = floor_points[0]
	for point in floor_points:
		if absf(point.x - human.global_position.x) > absf(far_point.x - human.global_position.x):
			far_point = point
	rival.global_position = far_point
	rival.process_mode = Node.PROCESS_MODE_DISABLED
	await _frames(8)
	await _shot("19_match_offscreen_arrow")
	rival.process_mode = Node.PROCESS_MODE_INHERIT
	# A timed realm hazard: its warning line (Asgard's light columns).
	_move_to_realm(human, 0)
	await _frames(8)
	main.hazards.trigger(0)
	main._update_hud()
	await _frames(6)
	await _shot("20_match_hazard_warning")
	# Timeline: corner collapse warning, thrown out by the collapse, centre open, sudden death.
	await _skip_to(121.0)
	await _frames(20)
	await _shot("21_match_collapse_warning")
	await _skip_to(151.0)
	await _frames(20)
	await _shot("22_match_after_collapse")
	await _skip_to(214.0)
	await _frames(20)
	await _shot("23_match_centre_open")
	await _skip_to(246.0)
	await _frames(40)
	await _shot("24_match_central_brawl")
	await _skip_to(372.0)
	await _frames(30)
	await _shot("25_match_sudden_death")
	# P1 is out: the HUD follows a bot.
	human.invulnerable_timer = 0.0
	human.apply_environment_damage(human.max_hp * 4.0, null)
	await _frames(40)
	await _shot("26_match_spectating")
	await _skip_to(421.0)
	await _frames(30)
	await _shot("27_results_lost")
	# A second, short match that P1 wins: the winner's side of the results screen.
	MAIN.session_bot_panel = false
	await _open("title", 4243)
	main._start_match("xion")
	await _frames(60)
	human = main.players[0]
	human.grant_protection(10000.0)
	await _shot("28_match_xion_skill_bar")
	human.add_souls(25)
	await _frames(10)
	main.soul_growth.choose(human, 0)
	human.add_souls(40)
	await _frames(10)
	main.soul_growth.choose(human, 1)
	await _frames(4)
	for player in main.players:
		if player != human:
			player.invulnerable_timer = 0.0
			player.apply_environment_damage(player.max_hp * 4.0, human)
			await _frames(3)
	await _frames(40)
	await _shot("29_results_won")
	MAIN.session_bot_panel = true

# --- The skill bar of every fighter (the report crops the bottom-right corner) ---

func _skill_bars() -> void:
	MAIN.human_body = "male"
	MAIN.session_bot_panel = false
	for id in ["frey", "yuki", "luna", "nova", "rio", "xion"]:
		await _open("title", 4242)
		main._start_match(id)
		await _frames(40)
		await _shot("60_skill_bar_%s" % id)
	MAIN.session_bot_panel = true

# --- Eight bots in the centre: how readable a crowded fight is ---

func _brawl_screens() -> void:
	MAIN.session_bot_panel = true
	await _open("title", 2001, true)
	await _frames(30)
	await _skip_to(246.0)
	for player in main.players:
		if not player.is_defeated and player.realm_index != main.CENTRAL_REALM_INDEX:
			_move_to_realm(player, main.CENTRAL_REALM_INDEX, main.players.find(player))
	await _frames(150)
	await _shot("30_brawl_bot_panel")
	_bot_panel(false)
	for index in 5:
		await _frames(50)
		await _shot("3%d_brawl" % (index + 1))

# --- Story mode ---

func _story_screens() -> void:
	PROGRESS.runs.clear()
	PROGRESS.new_journey("luna", "normal")
	for number in [1, 2, 3]:
		PROGRESS.complete_stage("luna", number, 30, ["power"])
	PROGRESS.new_journey("frey", "easy")
	for number in range(1, 10):
		PROGRESS.complete_stage("frey", number, 0, [])
	MAIN.human_body = "male"
	MAIN.session_bot_panel = false
	MAIN.story_hero = "luna"
	MAIN.story_difficulty = "normal"
	MAIN.story_art_state = {}
	await _open("story_select")
	await _shot("40_story_select")
	MAIN.story_stage = 4
	await _open("story_map")
	await _shot("41_story_map")
	main.hud.frontend.stage_buttons[7].grab_focus()
	await _frames(2)
	await _shot("42_story_map_locked_stage")
	# Stage 1: start card, narration over a scene picture, the hero's line, the fight, pause, fail.
	MAIN.story_stage = 1
	await _open("story_stage")
	main.hud.frontend.card_deadline = FOREVER
	await _shot("43_story_card_monsters")
	main.story_session.begin_dialogue()
	var dialogue: Node = main.story_session.dialogue
	await _frames(2)
	_show_whole_line(dialogue)
	await _shot("44_story_dialogue_narrator_cg")
	for step in 3:
		await _next_line(dialogue)
	await _shot("45_story_dialogue_hero")
	dialogue._activate("dialogue_skip", "")
	var hero: Node = main.story_session.hero
	hero.grant_protection(10000.0)
	await _frames(70)
	await _shot("46_story_hud_monsters")
	main.story_session.pause_stage()
	await _frames(4)
	await _shot("47_story_pause")
	main.story_session.resume_stage()
	await _frames(4)
	hero.invulnerable_timer = 0.0
	hero.apply_environment_damage(hero.max_hp * 4.0, null)
	await _frames(40)
	await _shot("48_story_result_failed")
	# Stage 2: a rival. VS card, the rival's line, the rival's HP bar, the exit, clear.
	MAIN.story_stage = 2
	await _open("story_stage")
	main.hud.frontend.card_deadline = FOREVER
	await _shot("49_story_card_rival")
	main.story_session.begin_dialogue()
	dialogue = main.story_session.dialogue
	await _frames(2)
	_show_whole_line(dialogue)
	await _shot("50_story_dialogue_rival")
	await _next_line(dialogue)
	await _shot("51_story_dialogue_hero_angry")
	dialogue._activate("dialogue_skip", "")
	hero = main.story_session.hero
	hero.grant_protection(10000.0)
	var story_rival: Node = main.story_session.rival
	story_rival.global_position = hero.global_position + Vector2(170, 0)
	await _frames(60)
	await _shot("52_story_hud_rival")
	hero.add_souls(25)
	await _frames(12)
	await _shot("53_story_card_offer")
	main.soul_growth.choose(hero, 0)
	await _frames(4)
	story_rival.invulnerable_timer = 0.0
	story_rival.apply_environment_damage(story_rival.max_hp * 4.0, hero)
	await _frames(30)
	dialogue = main.story_session.dialogue
	if dialogue.visible:
		dialogue._activate("dialogue_skip", "")
	await _frames(20)
	while not main.soul_growth.get_offer(hero).is_empty():
		main.soul_growth.choose(hero, 0)
		await _frames(4)
	await _shot("54_story_exit_open")
	main.director.use_exit()
	await _frames(30)
	await _shot("55_story_result_clear")
	main.hud.frontend.show_story_ending()
	await _frames(4)
	await _shot("56_story_ending")
	# Stage 5: the escape timer and crystal count with the collapse banner.
	MAIN.story_stage = 5
	await _open("story_stage")
	main.hud.frontend.card_deadline = FOREVER
	main.story_session.begin_dialogue()
	main.story_session.dialogue._activate("dialogue_skip", "")
	main.story_session.hero.grant_protection(10000.0)
	await _frames(90)
	await _shot("57_story_hud_escape")
	# Stage 9: the shadow speaks (the middle scene).
	MAIN.story_stage = 9
	await _open("story_stage")
	main.hud.frontend.card_deadline = FOREVER
	main.story_session.begin_dialogue()
	main.story_session.dialogue._activate("dialogue_skip", "")
	main.story_session.hero.grant_protection(10000.0)
	await _frames(60)
	await _shot("58_story_hud_shadows")
	main.story_session._play_scene("mid")
	dialogue = main.story_session.dialogue
	await _frames(2)
	await _next_line(dialogue)
	await _shot("59_story_dialogue_shadow")
	PROGRESS.runs.clear()
	MAIN.session_bot_panel = true
