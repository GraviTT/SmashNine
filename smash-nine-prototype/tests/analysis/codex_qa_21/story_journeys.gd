extends SceneTree
## Fourteen uninterrupted title-to-ending journeys: every registered body, Normal/Easy.
## Protected hero + public defeat/crystal APIs isolate progression from human difficulty.
const MAIN := preload("res://scripts/Main.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const ART := preload("res://scripts/ArtSettings.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
var failed := false
var checks := 0
var rows: Array[Dictionary] = []
var reload_stress := false

func _initialize() -> void:
	reload_stress = OS.get_cmdline_user_args().has("--reload")
	create_timer(850.0 if reload_stress else 600.0, true, false, true).timeout.connect(func() -> void:
		push_error("Continuous journeys timed out")
		quit(1))
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	ART.style = ART.STYLE_ORIGINAL
	SPEED.factor = 1.0
	var save_before := _save_stamp()
	for id in REGISTRY.get_character_ids():
		for body in REGISTRY.get_bodies(id):
			for difficulty in ["normal", "easy"]:
				PROGRESS.runs.clear()
				MAIN.next_screen = "title"
				MAIN.session_mode = "battle_royale"
				MAIN.story_art_state = {}
				LANGUAGE.set_locale("ko" if difficulty == "easy" else "en")
				change_scene_to_file("res://scenes/Main.tscn")
				await _frames(6)
				var main: Node = current_scene
				main.hud.frontend.buttons[1].pressed.emit()
				await _frames(6)
				main = current_scene
				await _tap(KEY_1 + REGISTRY.get_character_ids().find(id))
				if MAIN.human_body != body:
					await _tap(KEY_V)
				if main.hud.frontend.difficulty != difficulty:
					main.hud.frontend.difficulty_button.pressed.emit()
				main.hud.frontend.buttons[8].pressed.emit()
				await _frames(6)
				main = current_scene
				_check(main.hud.frontend.screen == "story_map" and main.hud.frontend.map_stage == 1, "New journey reaches the first map")
				main.hud.frontend.start_button.pressed.emit()
				await _frames(6)
				var previous_souls := 0
				var previous_cards: Array = []
				for number in range(1, 10):
					main = current_scene
					if reload_stress:
						main = await _reload(main, "start")
					var session: Node = main.story_session
					var hero: Node = session.hero
					_check(main.story_stage == number and session.phase == "start", "Continuous Next reaches stage %d" % number)
					_check(hero.character_id == id and hero.body_type == body and MAIN.story_difficulty == difficulty, "Hero/body/difficulty stay selected throughout the journey")
					_check(hero.souls == previous_souls and hero.upgrades == previous_cards, "Stage starts with exact previous souls/cards")
					_check(is_equal_approx(hero.hp, hero.max_hp), "Stage checkpoint restores full HP with carried growth")
					await _tap(KEY_J)
					if reload_stress:
						main = await _reload(main, "pre")
						session = main.story_session
						hero = session.hero
					session.dialogue._activate("dialogue_skip", "")
					hero.grant_protection(1000.0)
					if reload_stress:
						main = await _reload(main, "combat")
						session = main.story_session
						hero = session.hero
						hero.grant_protection(1000.0)
					if number == 9:
						hero.hp = hero.max_hp * 0.5
					for wave in 6:
						if session.phase == "mid":
							_check(is_equal_approx(hero.hp, hero.max_hp * 0.8), "Final intermission uses the carried max HP for 30-percent healing")
							if reload_stress:
								main = await _reload(main, "mid")
								session = main.story_session
								hero = session.hero
							session.dialogue._activate("dialogue_skip", "")
							_check(session.rival.character_id == id and session.rival.body_type == body and session.rival.upgrades.size() == 3, "Final shadow matches every registered body")
							if reload_stress:
								main = await _reload(main, "combat")
								session = main.story_session
								hero = session.hero
								hero.grant_protection(1000.0)
						if session.phase != "combat":
							break
						if number == 5:
							for crystal: Variant in session.crystals.duplicate():
								if is_instance_valid(crystal):
									for hit in 3:
										crystal.apply_hit(hero, 1.0, 0.0, Vector2.RIGHT)
						else:
							for enemy: Variant in session.enemies.duplicate():
								if is_instance_valid(enemy) and enemy.hp > 0.0:
									if enemy.has_method("apply_environment_damage"):
										enemy.apply_environment_damage(enemy.hp, hero)
									else:
										enemy.apply_hit(hero, 100000.0, 0.0, Vector2.RIGHT, "fixed")
						await _frames(3)
					_check(session.phase == "post", "Continuous objective completes stage %d" % number)
					if reload_stress:
						main = await _reload(main, "post")
						session = main.story_session
						hero = session.hero
					session.dialogue._activate("dialogue_skip", "")
					if number <= 7:
						if reload_stress:
							main = await _reload(main, "exit")
							session = main.story_session
							hero = session.hero
						await _choose_cards(main)
						var point: Vector2 = main.layout.get_portal_stand_point(hero.realm_index, session.data.exit)
						hero.global_position = point + Vector2(0, -2)
						hero.velocity = Vector2.ZERO
						await _frames(6)
						await _tap(KEY_Q)
					elif number == 8 and session.phase == "root":
						await _choose_cards(main)
					await _frames(3)
					if reload_stress:
						main = await _reload(main, "ending" if number == 9 else "result")
						session = main.story_session
						hero = session.hero
					_check(main.match_over and PROGRESS.get_run(id).cleared == number, "Every completed stage advances this hero's actual run")
					previous_souls = hero.souls
					previous_cards = hero.upgrades.duplicate()
					_check(previous_cards.size() <= 3, "Continuous growth respects the three-card cap")
					if number < 9:
						_check(PROGRESS.checkpoint(id, number + 1).souls == previous_souls and PROGRESS.checkpoint(id, number + 1).cards == previous_cards, "Next checkpoint stores exact selected growth")
						main.hud.frontend.buttons[0].pressed.emit()
						await _frames(6)
					else:
						_check(main.hud.frontend.screen == "story_ending" and PROGRESS.get_run(id).done, "Continuous title-to-ending journey marks CLEAR")
				rows.append({"hero": id, "body": body, "difficulty": difficulty, "cleared": PROGRESS.get_run(id).cleared, "done": PROGRESS.get_run(id).done, "final_souls": previous_souls, "final_cards": previous_cards})
				print("CONTINUOUS_JOURNEY_RESULT ", JSON.stringify(rows.back()))
				main._on_story_action("story_title")
				await _frames(6)
	_check(_save_stamp() == save_before, "Fourteen journeys leave the actual user save untouched")
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../reports/codex-qa-21/continuous-journeys%s.json" % ("-reload" if reload_stress else "")), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failed": failed, "note": "Protected hero and forced enemy defeats; validates continuous UI/progression, not difficulty.", "journeys": rows}, "\t") + "\n")
	file.close()
	PROGRESS.runs.clear()
	LANGUAGE.set_locale("en")
	MAIN.story_art_state = {}
	if not failed:
		print("Continuous journey tests passed (%d checks, %d complete journeys, reload stress %s, every registered hero/body and Normal/Easy, actual title/select/map/Q/ending)" % [checks, rows.size(), str(reload_stress)])
	quit(1 if failed else 0)

func _reload(main: Node, expected_phase: String) -> Node:
	var hero: Node = main.story_session.hero
	var souls: int = hero.souls
	var cards: Array = hero.upgrades.duplicate()
	var hp: float = hero.hp
	var max_hp: float = hero.max_hp
	var body: String = hero.body_type
	var wave: int = main.story_session.wave_index
	var defeated: int = main.story_session.defeated_count
	var line: int = main.story_session.dialogue.line_index
	main._on_story_action("story_art")
	await _frames(6)
	main = current_scene
	_check(main.story_session.phase == expected_phase, "F2 stress preserves phase " + expected_phase)
	_check(main.story_session.hero.souls == souls and main.story_session.hero.upgrades == cards and main.story_session.hero.body_type == body, "F2 stress preserves carried souls/cards/body")
	_check(main.story_session.wave_index == wave and main.story_session.defeated_count == defeated, "F2 stress preserves wave and objective count")
	_check(is_equal_approx(main.story_session.hero.max_hp, max_hp), "F2 stress preserves carried max HP")
	if expected_phase in ["start", "pre", "mid", "post", "result", "ending"]:
		_check(is_equal_approx(main.story_session.hero.hp, hp), "Frozen-screen F2 stress preserves exact HP")
	if expected_phase in ["pre", "mid", "post"]:
		_check(main.story_session.dialogue.line_index == line, "F2 stress preserves scene line")
	return main

func _choose_cards(main: Node) -> void:
	for attempt in 4:
		if main.soul_growth.get_offer(main.story_session.hero).is_empty():
			break
		await _tap(KEY_1 + rows.size() % 3)

func _save_stamp() -> String:
	return str(FileAccess.get_modified_time(PROGRESS.SAVE_PATH)) if FileAccess.file_exists(PROGRESS.SAVE_PATH) else "<missing>"

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _tap(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)
