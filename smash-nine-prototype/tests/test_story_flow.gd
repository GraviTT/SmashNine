extends SceneTree
## D43 integration: real keyboard/mouse flow, public hits, Q exit, retries, all heroes/home.
## -- --capture: brief windowed Korean captures; no real user save is read or written.
const MAIN := preload("res://scripts/Main.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const CARDS := preload("res://scripts/match/SoulCards.gd")
const ART := preload("res://scripts/ArtSettings.gd")
var failed := false
var capture := false
var assertions := 0
var report_dir := ""

func _initialize() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	report_dir = ProjectSettings.globalize_path("res://../reports/codex-sys-03")
	create_timer(240.0, true, false, true).timeout.connect(func() -> void:
		push_error("Story flow timed out")
		quit(1))
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	LANGUAGE.set_locale("ko" if capture else "en")
	SPEED.factor = 1.0
	MAIN.next_screen = "title"
	MAIN.session_mode = "battle_royale"
	MAIN.story_art_state = {}
	MAIN.last_character_id = "frey"
	MAIN.human_body = "male"
	PROGRESS.runs.clear()
	var save_before := _save_stamp()
	var save_mtime := FileAccess.get_modified_time(PROGRESS.SAVE_PATH) if FileAccess.file_exists(PROGRESS.SAVE_PATH) else 0
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(6)
	var baseline := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphan_baseline := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var main: Node = current_scene
	await _capture("01-title-ko")
	await _click(main.hud.frontend.buttons[1])
	await _frames(6)
	main = current_scene
	_check(main.hud.frontend.screen == "story_select" and not main.match_started, "Title Story opens story select")
	for index in 5:
		await _tap(KEY_1 + index)
		_check(not main.match_started and main.hud.frontend.selected_id == REGISTRY.get_character_ids()[index], "Story number keys only select, never quick-start battle royale")
	await _tap(KEY_4)
	await _tap(KEY_V)
	_check(main.human_body == "female" and main.hud.frontend.hero_art.texture.resource_path.ends_with("nova_female_illustration.png"), "Story V changes Nova body/art")
	await _tap(KEY_3)
	_check(main.hud.frontend.continue_button.disabled, "No saved run means Continue disabled")
	await _click(main.hud.frontend.difficulty_button)
	_check(main.hud.frontend.difficulty == "easy", "Difficulty button selects Easy")
	await _click(main.hud.frontend.difficulty_button)
	_check(main.hud.frontend.difficulty == "normal", "Difficulty button returns to Normal")
	var art_before := ART.style
	await _tap(KEY_F2)
	await _frames(6)
	main = current_scene
	_check(main.hud.frontend.screen == "story_select" and main.hud.frontend.selected_id == "luna" and ART.style != art_before, "F2 retains story select and hero")
	await _tap(KEY_F2)
	await _frames(6)
	main = current_scene
	await _capture("02-story-select-ko")
	await _click(main.hud.frontend.buttons[8])
	await _frames(6)
	main = current_scene
	_check(main.hud.frontend.screen == "story_map" and main.story_stage == 1, "New journey opens stage 1 map")
	_check(not main.hud.frontend.start_button.disabled, "Stage 1 unlocked")
	main.hud.frontend.stage_buttons[4].grab_focus()
	await _frames(2)
	_check(main.hud.frontend.start_button.disabled, "Stage 5 stays locked until earlier stages clear")
	main.hud.frontend.stage_buttons[0].grab_focus()
	await _tap(KEY_F2)
	await _frames(6)
	main = current_scene
	_check(main.hud.frontend.screen == "story_map" and main.hud.frontend.map_stage == 1, "F2 returns to story map")
	await _tap(KEY_F2)
	await _frames(6)
	main = current_scene
	await _capture("03-story-map-ko")
	await _click(main.hud.frontend.start_button)
	await _frames(6)
	main = current_scene
	_check(main.match_started and main.story_session.phase == "start", "Start stage shows start card")
	_check(main.director.get_playable_indices() == [1] and main.active_portals.is_empty(), "Stage realm stable and all exits locked initially")
	_check(not main.realm_monster_spawner.population_started and main.soul_crystal_spawner.get_child_count() == 0, "Automatic battle-royale spawners remain off")
	main = await _art_round_trip(main, "start")
	await _capture("04-stage-start-ko")
	await _tap(KEY_J)
	_check(main.story_session.phase == "pre" and main.story_session.dialogue.visible, "J advances card to dialogue")
	_check(not main.hud.minimap_root.visible and not main.hud.clock_label.visible, "Scenes play without the match HUD")
	var start_point: Vector2 = main.story_session.hero.global_position
	await _frames(8)
	_check(main.story_session.hero.global_position == start_point and not main.director.running, "Dialogue freezes combat and timeline")
	await _tap(KEY_J)
	main = await _art_round_trip(main, "pre")
	await _capture("05-dialogue-ko")
	await _advance_dialogue(main)
	_check(main.story_session.phase == "combat" and main.director.running, "J finishes dialogue and unfreezes combat")
	_check(main.hud.minimap_root.visible and main.hud.clock_label.visible, "The match HUD returns with the fight")
	_check(main.story_session.enemies.size() == 2, "Stage 1 starts with two monsters")
	await _frames(8)
	await _capture("06-stage-one-ko")
	# Story-only Esc pause is a real SceneTree pause; Retry/Map/Title unpause on reload.
	await _tap(KEY_ESCAPE)
	_check(paused and main.hud.frontend.screen == "story_pause", "Esc pauses the stage")
	var elapsed: float = main.director.match_elapsed
	await _frames(8)
	_check(main.director.match_elapsed == elapsed, "Paused stage clock remains frozen")
	main = await _art_round_trip(main, "combat")
	_check(paused and main.hud.frontend.screen == "story_pause", "F2 restores the actual paused screen")
	await _capture("09-pause-ko")
	await _tap(KEY_ESCAPE)
	_check(not paused and not main.hud.overlay.visible, "Esc resumes from pause")
	# A real player rarely defeats a whole wave on the same frame. Let the first
	# corpse finish its fade/free before killing the survivor (freed-node regression).
	var first_monster: Node = main.story_session.enemies[0]
	first_monster.apply_hit(main.story_session.hero, 100000.0, 0.0, Vector2.RIGHT, "fixed")
	await create_timer(1.4).timeout
	_check(not is_instance_valid(first_monster), "First monster corpse frees before the wave ends")
	await _defeat_objective(main)
	_check(main.story_session.defeated_count == 4 and main.story_session.phase == "post", "Both monster waves count toward objective")
	main = await _art_round_trip(main, "post")
	await _advance_dialogue(main)
	_check(main.director.exit_open and main.active_portals.size() == 1 and not main.match_over, "Objective opens a real exit and waits for Q")
	_check(main.story_session.hero.process_mode != Node.PROCESS_MODE_DISABLED and is_finite(main.story_session.hero.invulnerable_timer), "Post dialogue fully restores hero processing/protection")
	var exit_x: float = main.story_session.hero.global_position.x
	await _tap(KEY_D)
	_check(main.story_session.hero.global_position.x > exit_x, "Hero can actually walk toward the exit after the post scene")
	main = await _art_round_trip(main, "exit")
	_check(main.director.exit_open and main.active_portals.size() == 1, "F2 retains completed objective and open exit")
	await _capture("10-exit-open-ko")
	await _use_exit(main)
	_check(main.match_over and main.hud.frontend.screen == "story_result", "Q at exit completes stage")
	_check(PROGRESS.get_run("luna").cleared == 1 and PROGRESS.continue_stage("luna") == 2, "Stage clear advances saved progress")
	main = await _art_round_trip(main, "result")
	_check(main.match_over and main.hud.frontend.screen == "story_result", "F2 returns to result screen")
	await _capture("08-stage-result-ko")
	await _click(main.hud.frontend.buttons[0])
	await _frames(6)
	main = current_scene
	_check(main.story_stage == 2 and main.story_session.rival.character_id == "frey", "Next starts stage 2 versus Frey for Luna")
	var checkpoint := PROGRESS.checkpoint("luna", 2)
	_check(main.story_session.hero.souls == checkpoint.souls and main.story_session.hero.upgrades == checkpoint.cards, "Next restores souls/cards checkpoint")
	await _capture("11-stage-two-start-ko")
	await _begin_combat(main)
	await _frames(6)
	_check(main.story_session.rival_bar.visible, "Rival HP bar visible during duel")
	await _capture("07-stage-two-rival-ko")
	main.hazards.trigger(0)
	await _frames(3)
	main._update_hud()
	_check(main.hud.warning_label.visible and not main.hud.warning_label.get_global_rect().intersects(main.story_session.rival_bar.get_global_rect()), "Story realm warning must not overlap the new rival HP bar")
	await _capture("14-rival-warning-ko")
	# A normal tree pause alone lets process_always attack wind-ups expire. The
	# stage pause must preserve that wait, then allow the attack after resuming.
	var spawned_attacks := [0]
	var count_attack := func(child: Node) -> void:
		if child is Area2D:
			spawned_attacks[0] += 1
	main.child_entered_tree.connect(count_attack)
	main.story_session.rival.perform_basic_attack("neutral", Vector2.LEFT)
	await _tap(KEY_ESCAPE)
	_check(paused and Engine.time_scale == 0.0, "Story pause freezes scaled SceneTreeTimers too")
	await create_timer(0.25, true, false, true).timeout
	_check(spawned_attacks[0] == 0, "Pending rival attack must not spawn during pause")
	await _tap(KEY_ESCAPE)
	_check(not paused and is_equal_approx(Engine.time_scale, SPEED.factor), "Resume restores the chosen game speed")
	await create_timer(0.12, true, false, true).timeout
	_check(spawned_attacks[0] > 0, "Paused attack resumes with its remaining wind-up")
	main.child_entered_tree.disconnect(count_attack)
	# A rival also earns ordinary soul cards. Growth recalculates its stats, but
	# must not remove the stage's x0.8 HP rule or the Easy difficulty multiplier.
	var rival: Node = main.story_session.rival
	rival.add_souls(25)
	_check(main.soul_growth.choose(rival, 0), "Rival earns a real SoulGrowth offer")
	var plain_max: float = rival.base_max_hp + rival.hp_growth * rival.soul_picks * 3.0 + float(rival.upgrade_modifiers.bonus_max_hp)
	_check(is_equal_approx(rival.max_hp, plain_max * 0.8) and rival.hp <= rival.max_hp, "Rival stage HP scale survives soul-card growth")
	var rival_cards: Array = rival.upgrades.duplicate()
	var rival_max: float = rival.max_hp
	main = await _art_round_trip(main, "combat")
	_check(main.story_session.rival.upgrades == rival_cards and is_equal_approx(main.story_session.rival.max_hp, rival_max), "F2 retains rival growth and its scaled maximum HP")
	# A failed retry must discard all growth acquired after entering this stage.
	main.story_session.hero.souls += 9
	var hero: Node = main.story_session.hero
	hero.invulnerable_timer = 0.0
	hero.apply_environment_damage(hero.max_hp + 1000.0)
	await _frames(5)
	_check(main.match_over and not main.hud.frontend.stage_result.clear, "Hero at zero HP fails stage")
	await _tap(KEY_R)
	await _frames(6)
	main = current_scene
	_check(main.story_stage == 2 and not main.match_over and main.story_session.hero.souls == checkpoint.souls and main.story_session.hero.upgrades == checkpoint.cards, "R retries at stage checkpoint")
	_check(is_equal_approx(main.story_session.hero.hp, main.story_session.hero.max_hp), "Retry starts with full HP")
	await _begin_combat(main)
	await _tap(KEY_ESCAPE)
	await _click(main.hud.frontend.buttons[1])
	await _frames(6)
	main = current_scene
	_check(not paused and main.story_session.phase == "start" and main.story_session.hero.souls == checkpoint.souls, "Pause Retry button unpauses and restores checkpoint")
	await _begin_combat(main)
	await _tap(KEY_ESCAPE)
	await _click(main.hud.frontend.buttons[2])
	await _frames(6)
	main = current_scene
	_check(not paused and main.hud.frontend.screen == "story_map", "Pause Story map unpauses and reloads map")
	await _tap(KEY_ESCAPE)
	await _frames(6)
	main = current_scene
	_check(main.hud.frontend.screen == "story_select" and not main.hud.frontend.continue_button.disabled, "Map Back exposes saved Continue")
	await _click(main.hud.frontend.difficulty_button)
	_check(PROGRESS.get_run("luna").difficulty == "easy", "Saved fighter difficulty can change without resetting progress")
	await _click(main.hud.frontend.continue_button)
	await _frames(6)
	main = current_scene
	_check(main.hud.frontend.screen == "story_map" and main.hud.frontend.map_stage == 2, "Continue selects next checkpoint")
	_check(main.story_difficulty == "easy" and PROGRESS.get_run("luna").cleared == 1, "Continue keeps chosen difficulty and cleared progress")
	# Replay a cleared stage; current checkpoint/progress must not change.
	await _click(main.hud.frontend.stage_buttons[0])
	await _frames(6)
	main = current_scene
	_check(main.story_stage == 1 and main.story_session.hero.souls == 0, "Cleared stage replay restores its own start checkpoint")
	await _begin_combat(main)
	await _tap(KEY_ESCAPE)
	await _click(main.hud.frontend.buttons[3])
	await _frames(6)
	main = current_scene
	_check(main.hud.frontend.screen == "title" and not paused, "Pause Title unpauses and returns to title")
	# Exercise stages 1-4 for all five heroes, including all three ready home variants.
	# UI route above proves entry; fixtures only unlock checkpoints to keep the matrix short.
	for id in REGISTRY.get_character_ids():
		PROGRESS.new_journey(id, "easy")
		for number in range(1, 5):
			MAIN.story_hero = id
			MAIN.story_stage = number
			MAIN.story_difficulty = "easy"
			MAIN.next_screen = "story_stage"
			change_scene_to_file("res://scenes/Main.tscn")
			await _frames(6)
			main = current_scene
			await _begin_combat(main)
			_check(main.story_session.hero.character_id == id, "Hero matrix: " + id)
			_check(is_equal_approx(main.director.get_combat_damage_scale_for(main.story_session.hero), (0.3 if number == 1 else 0.4) * 0.7), "Easy incoming multiplier")
			var data := STORY.stage(number)
			if STORY.is_home(data, id):
				_check(main.story_session.enemies.size() == 3 and main.story_session.enemies[0].is_elite and not is_instance_valid(main.story_session.rival), "Home variant replaces rival with elite + two monsters")
				_check(not main.story_session.dialogue.right_face.visible, "Home dialogue never displays a duplicate hero as rival")
				if id == "frey" and number == 2:
					await _capture("12-home-guardian-ko")
			else:
				_check((number == 1 and not is_instance_valid(main.story_session.rival)) or (number > 1 and main.story_session.rival.character_id == data.rival), "Stage rival matrix")
				if number > 1:
					_check(main.story_session.rival.body_type == REGISTRY.get_bodies(data.rival)[0], "Rival body matches VS/dialogue/map portraits")
			await _defeat_objective(main)
			await _advance_dialogue(main)
			await _use_exit(main)
			_check(main.match_over and main.hud.frontend.stage_result.clear, "Playable matrix clear: %s stage %d" % [id, number])
			_check(main.story_session.hero.upgrades.size() <= 3, "Journey never exceeds three cards")
			if number == 4:
				await _click(main.hud.frontend.buttons[0])
				await _frames(6)
				_check(current_scene.hud.frontend.screen == "story_start" and current_scene.story_stage == 5, "Stage 4 Next starts ready stage 5")
				if id == "frey":
					await _capture("13-coming-soon-ko")
	main = current_scene
	main._on_story_action("story_title")
	await _frames(8)
	main = current_scene
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_check(main.hud.frontend.screen == "title" and not main.match_started, "Round trip returns clean title")
	_check(main.hud.frontend.selected_id == "frey", "Story selection does not overwrite the battle-royale fighter selection")
	_check(absi(nodes - baseline) <= 5, "Story title node baseline drift %d -> %d" % [baseline, nodes])
	_check(orphans == orphan_baseline, "Story orphan baseline drift %d -> %d" % [orphan_baseline, orphans])
	_check(_save_stamp() == save_before, "Story flow must not write real save file")
	_check((FileAccess.get_modified_time(PROGRESS.SAVE_PATH) if FileAccess.file_exists(PROGRESS.SAVE_PATH) else 0) == save_mtime, "Real save modification time unchanged")
	MAIN.story_hero = "frey"
	MAIN.story_stage = 1
	MAIN.last_character_id = "frey"
	MAIN.human_body = "male"
	MAIN.session_mode = "battle_royale"
	MAIN.story_art_state = {}
	PROGRESS.runs.clear()
	LANGUAGE.set_locale("en")
	if not failed:
		print("Story flow tests passed (%d assertions; title/select/map/dialogue/card/Q/result/pause/retry/Continue/replay, 5 heroes x 4 stages, home variants, nodes %d, orphans %d, no real save)" % [assertions, nodes, orphans])
	quit(1 if failed else 0)

func _save_stamp() -> String:
	# Inspect metadata only. The test never reads a user's actual story contents.
	return str(FileAccess.get_modified_time(PROGRESS.SAVE_PATH)) if FileAccess.file_exists(PROGRESS.SAVE_PATH) else "<missing>"

func _begin_combat(main: Node) -> void:
	if main.story_session.phase == "start":
		await _tap(KEY_J)
	await _advance_dialogue(main)

func _art_round_trip(main: Node, expected_phase: String) -> Node:
	var souls: int = main.story_session.hero.souls
	var cards: Array = main.story_session.hero.upgrades.duplicate()
	var defeated: int = main.story_session.defeated_count
	var line: int = main.story_session.dialogue.line_index
	for toggle in 2:
		await _tap(KEY_F2)
		await _frames(6)
		main = current_scene
		_check(main.story_session.phase == expected_phase, "F2 preserves story phase: " + expected_phase)
		_check(main.story_session.hero.souls == souls and main.story_session.hero.upgrades == cards and main.story_session.defeated_count == defeated, "F2 preserves souls/cards/objective without rewards duplicated")
		if expected_phase in ["pre", "post"]:
			_check(main.story_session.dialogue.line_index == line, "F2 preserves current dialogue line")
	return main

func _advance_dialogue(main: Node) -> void:
	for attempt in 18:
		if not main.story_session.dialogue.visible:
			return
		await _tap(KEY_J)
	_check(not main.story_session.dialogue.visible, "Dialogue must advance with J")

func _defeat_objective(main: Node) -> void:
	# Represents a projectile already in flight when the last enemy falls.
	var stray_attack := Area2D.new()
	main.add_child(stray_attack)
	for wave in 3:
		if main.story_session.phase != "combat":
			break
		for enemy: Variant in main.story_session.enemies.duplicate():
			if is_instance_valid(enemy) and enemy.hp > 0.0:
				if enemy.get("invulnerable_timer") != null:
					enemy.invulnerable_timer = 0.0
				enemy.apply_hit(main.story_session.hero, 100000.0, 0.0, Vector2.RIGHT, "fixed")
		await _frames(5)
	_check(not is_instance_valid(stray_attack), "Objective clears stray attacks before post dialogue resumes")

func _use_exit(main: Node) -> void:
	# Resolve the existing SoulGrowth panel normally before leaving the stage.
	for attempt in 4:
		if main.soul_growth.get_offer(main.story_session.hero).is_empty():
			break
		await _tap(KEY_1)
	var portals: Array = main._get_portals_for_realm(main.story_session.hero.realm_index)
	_check(not portals.is_empty(), "Exit portal exists")
	if portals.is_empty():
		return
	var point: Vector2 = main.layout.get_portal_stand_point(main.story_session.hero.realm_index, STORY.stage(main.story_stage).exit)
	main.story_session.hero.global_position = point + Vector2(0, -2)
	main.story_session.hero.velocity = Vector2.ZERO
	await _frames(8)
	await _tap(KEY_Q)
	await _frames(5)

func _frames(count: int) -> void:
	for frame in count:
		# Input polls, grounding and collision callbacks live on physics frames. Headless
		# rendering may run many process frames before one physics step, unlike a window.
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
	if not capture:
		return
	_check(DisplayServer.get_name() != "headless", "Capture must be windowed")
	await _frames(3)
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(report_dir.path_join(stem + ".png")) == OK, "Save capture " + stem)
