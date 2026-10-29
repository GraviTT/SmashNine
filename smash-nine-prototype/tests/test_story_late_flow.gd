extends SceneTree
## SYS-04: stages 5-9 through the real scene, hero/home matrix, time-up, boss, shadows, ending.
## -- --capture uses one brief window, Korean, and never reads/writes the real story save.
const MAIN := preload("res://scripts/Main.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const CARDS := preload("res://scripts/match/SoulCards.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
const ART := preload("res://scripts/ArtSettings.gd")
var failed := false
var checks := 0
var capture := false
var report_dir := ""

func _initialize() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	report_dir = ProjectSettings.globalize_path("res://../reports/codex-sys-04")
	create_timer(240.0, true, false, true).timeout.connect(func() -> void:
		push_error("Late story flow timed out")
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
	LANGUAGE.set_locale("ko" if capture else "en")
	SPEED.factor = 1.0
	ART.style = "original"
	MAIN.next_screen = "title"
	MAIN.session_mode = "battle_royale"
	MAIN.story_art_state = {}
	MAIN.last_character_id = "frey"
	MAIN.human_body = "female"
	PROGRESS.runs.clear()
	var save_before := _save_stamp()
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(6)
	var baseline := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphan_baseline := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var heroes: Array = REGISTRY.get_character_ids() if OS.get_cmdline_user_args().has("--heroes=all") else ["nova", "yuki"]
	for id in heroes:
		PROGRESS.new_journey(id, "normal")
		# Earlier stages are covered by test_story_flow (five heroes x four stages).
		for number in range(1, 5):
			PROGRESS.complete_stage(id, number, 0, [])
		MAIN.story_hero = id
		MAIN.story_stage = 5
		MAIN.story_difficulty = "normal"
		MAIN.next_screen = "story_map"
		change_scene_to_file("res://scenes/Main.tscn")
		await _frames(6)
		var main: Node = current_scene
		_check(not main.hud.frontend.start_button.disabled and main.hud.frontend.map_stage == 5, "Stage 5 unlocked after stage 4")
		main.hud.frontend.start_button.pressed.emit()
		await _frames(6)
		main = current_scene
		_check(main.story_stage == 5 and main.story_session.crystals.size() == 3, "Stage 5 has exactly three soul crystals")
		_check(main.director.warning_realms.is_empty(), "Collapse clock waits for combat, not the start card or scene")
		await _begin(main)
		_check(main.director.is_warning(6) and main.director.get_warning_seconds_left() == 60, "Stage 5 begins 60-second collapse warning")
		_check(main.story_session.enemies.size() == 2 and main.story_session.enemies.all(func(enemy: Node) -> bool: return enemy.hostile), "Two hostile stage 5 monsters")
		_check(main.hazards._realms[6].hazard.bridges.size() == 1, "Stage 5 guarantees the authored upper bridge instead of a random unreachable route")
		if id == "nova":
			main.director.advance(60.0)
			await _frames(3)
			_check(main.match_over and main.director.finish_reason == "time up" and not main.hud.frontend.stage_result.clear, "Unbroken crystals at deadline fail with time up")
			_check(PROGRESS.get_run(id).cleared == 4, "Time-up does not clear or advance the save")
			await _tap(KEY_R)
			await _frames(6)
			main = current_scene
			_check(main.story_session.crystals.size() == 3 and main.story_session.hero.souls == 0, "Time-up retry restores crystals and stage checkpoint")
			await _begin(main)
		main.story_session.hero.grant_protection(1000.0)
		main.director.match_elapsed = 18.0
		main.hazards.advance(1.3)
		main._update_hud()
		_check(main.hud.warning_label.visible and main.hud.clock_label.text.contains("0:42"), "Warning banner and objective share the 42-second countdown")
		_check(main.hazards.get_phase(6) == "active" and get_nodes_in_group("vine_bridges").size() == 1, "Existing vine hazard creates the required actual bridge")
		var crystal: Node = main.story_session.crystals[0]
		for hit in 3:
			crystal.apply_hit(main.story_session.hero, 1.0, 0.0, Vector2.RIGHT)
		await _frames(3)
		_check(main.story_session.crystals_broken == 1 and main.story_session.hero.souls == 10, "Crystal pays the ordinary ten souls exactly once")
		if id == "nova":
			if capture:
				var bridge: Rect2 = main.layout.get_realm(6).hazard.bridges[0]
				main.story_session.hero.global_position = main.layout.get_origin(6) + Vector2(bridge.get_center().x, bridge.position.y - 2.0)
				main.story_session.hero.velocity = Vector2.ZERO
				main._update_camera_follow()
				main.camera.reset_smoothing()
			await _capture("01-stage-five-crystals-ko")
			main = await _art_round_trip(main, "combat")
			_check(main.story_session.crystals_broken == 1 and main.story_session.crystals.size() == 2 and main.director.get_warning_seconds_left() <= 42, "F2 retains broken crystal and remaining time")
		for item: Variant in main.story_session.crystals.duplicate():
			if is_instance_valid(item):
				for hit in 3:
					item.apply_hit(main.story_session.hero, 1.0, 0.0, Vector2.RIGHT)
		await _frames(4)
		_check(main.story_session.phase == "post" and main.story_session.hero.souls == 30, "Three crystals complete the objective even with both monsters alive")
		_check(main.director.warning_realms.is_empty() and not main.director.is_warning(6), "Success stops the collapse countdown")
		await _dialogue(main)
		_check(main.story_session.phase == "exit" and main.director.exit_realm == 7, "Crystal success opens right exit to Jotunheim")
		await _use_exit(main)
		_check(main.match_over and PROGRESS.get_run(id).cleared == 5, "Stage 5 exit Q saves clear")
		main = await _next(main, 6)
		await _begin(main)
		await _check_duel(main, id, 6)
		await _defeat(main)
		await _dialogue(main)
		await _use_exit(main)
		_check(PROGRESS.get_run(id).cleared == 6, "Stage 6 clears through its actual upward exit")
		main = await _next(main, 7)
		await _begin(main)
		main.story_session.hero.grant_protection(1000.0)
		var boss: Node = main.story_session.rival
		_check(boss.is_boss and boss.hostile and boss.skin_id == "muspelheim_magma_boar", "Stage 7 objective is hostile giant magma boar")
		_check(main.hazards.enabled and main.hazards._realms[4].hazard.type == "eruption", "Boss stage retains volcanic eruptions")
		_check(main.story_session.reinforcements.is_empty(), "No reinforcement before the first 20 seconds")
		main.director.match_elapsed = 19.0
		main.story_session._tick_reinforcements()
		_check(main.story_session.reinforcements.is_empty(), "Reinforcement waits until deadline")
		main.director.advance(1.1)
		main.story_session._tick_reinforcements()
		_check(main.story_session.reinforcements.size() == 2, "Two ember imps arrive at 20 seconds")
		main.director.advance(20.0)
		main.story_session._tick_reinforcements()
		_check(main.story_session.reinforcements.size() == 4, "Second batch reaches four living imps")
		main.director.advance(20.0)
		main.story_session._tick_reinforcements()
		_check(main.story_session.reinforcements.size() == 4, "Further batches obey the four-alive cap")
		_check(main.story_session.reinforcements.all(func(enemy: Node) -> bool: return enemy.hostile and enemy.monster_type == "ember_imp"), "All boss reinforcements are hostile ember imps")
		main._update_hud()
		_check(main.story_session.rival_bar.visible and main.story_session.rival_name.text.contains(tr("Boss %s") % tr("Magma Boar")), "Rival bar presents the boss name and HP")
		if id == "nova":
			await _capture("02-stage-seven-boss-ko")
			main = await _art_round_trip(main, "combat")
			_check(main.story_session.rival.is_boss and main.story_session.reinforcements.size() == 4, "F2 restores boss and living reinforcement batch")
		boss = main.story_session.rival
		boss.apply_hit(main.story_session.hero, 100000.0, 0.0, Vector2.RIGHT, "fixed")
		await _frames(4)
		_check(main.story_session.phase == "post" and not main.story_session.reinforcements.is_empty(), "Boss alone is the objective; living minions do not block clear")
		await _dialogue(main)
		_check(main.story_session.reinforcements.all(func(enemy: Node) -> bool: return enemy.process_mode == Node.PROCESS_MODE_DISABLED), "Remaining imps stop attacking after the post scene")
		await _use_exit(main)
		main = await _next(main, 8)
		await _begin(main)
		await _check_duel(main, id, 8)
		await _defeat(main)
		_check(main.story_session.phase == "post" and main.story_session.dialogue.cg_picture.visible, "Stage 8 victory scene retains root picture")
		await _dialogue(main)
		_check(main.match_over and main.hud.frontend.screen == "story_result" and PROGRESS.get_run(id).cleared == 8, "Root scene completes stage 8 without an impossible grid portal")
		main = await _next(main, 9)
		await _begin(main)
		main.story_session.hero.grant_protection(1000.0)
		_check(main.story_session.enemies.size() == 4 and main.players.size() == 5, "Final wave 1 is four rivals plus the hero")
		_check(main.director.band_started_at < 0.0 and not is_finite(main.director.get_sudden_death_band().x), "No shrinking band in wave 1")
		for enemy: Node in main.story_session.enemies:
			_check(enemy.character_id != id and enemy.get_meta("story_shadow", false) and enemy.modulate.r < 0.5, "Rivals have shadow bodies/tint")
			_check(is_equal_approx(enemy.max_hp, enemy.base_max_hp * 0.6) and enemy.ai_aggression == 1.0, "Wave 1 HP x0.6 and full aggression")
			_check(enemy.get_node_or_null("Vfx_shadow_aura") != null, "Every rival has looping ART-70 aura")
		_check(main._get_all_combatants().size() == 5, "Existing FFA target list includes every shadow and the hero")
		if id == "nova":
			if capture:
				var floor_rect: Rect2 = main.layout.get_platform_rects(8)[0]
				var center := Vector2(floor_rect.get_center().x, floor_rect.position.y - 2.0)
				main.story_session.hero.global_position = center
				for index in main.story_session.enemies.size():
					main.story_session.enemies[index].global_position = center + Vector2([-460, -230, 230, 460][index], 0)
					main.story_session.enemies[index].velocity = Vector2.ZERO
				main._update_camera_follow()
				main.camera.reset_smoothing()
			await _capture("03-stage-nine-rivals-ko")
		main.story_session.hero.hp = main.story_session.hero.max_hp * 0.4
		await _defeat(main)
		_check(main.story_session.phase == "mid" and main.story_session.wave_index == 1 and not main.director.running, "Last rival starts frozen mid scene before own shadow spawns")
		_check(is_equal_approx(main.story_session.hero.hp, main.story_session.hero.max_hp * 0.7), "Intermission heals exactly 30 percent max HP")
		_check(not main.hud.minimap_root.visible and not main.hud.clock_label.visible, "Mid scene hides the complete match HUD")
		main.story_session.dialogue.line_index = 1
		main.story_session.dialogue._show_line()
		main.story_session.dialogue.line_label.visible_characters = -1
		main.story_session.dialogue._characters = main.story_session.dialogue.line_label.get_total_character_count()
		_check(main.story_session.dialogue.speaker_label.text == tr("Shadow %s") % tr(str(main.characters[id].name)), "New shadow speaker uses translated hero name")
		# A drawn shadow face (applied 2026-10-29 for every form) shows in its own colours; without one
		# the same-body portrait is tinted violet.
		var shadow_face := ART.character_portrait(id, main.story_session.hero.body_type, "shadow")
		var drawn_shadow: bool = shadow_face != null and shadow_face.resource_path.ends_with("_face_shadow.png")
		var right_face: TextureRect = main.story_session.dialogue.right_face
		_check(right_face.texture == shadow_face and (right_face.modulate == Color.WHITE if drawn_shadow else right_face.modulate.r < 0.5), "Shadow speaker uses the shadow face (drawn, or the violet same-body portrait), right-aligned")
		if id == "nova":
			main = await _art_round_trip(main, "mid")
			_check(main.players.size() == 1, "F2 during mid scene cannot spawn the own shadow early")
			await _capture("04-stage-nine-shadow-dialogue-ko")
		await _dialogue(main)
		_check(main.story_session.phase == "combat" and main.story_session.enemies.size() == 1, "Mid scene resumes into exactly one own shadow")
		var shadow: Node = main.story_session.rival
		var hero: Node = main.story_session.hero
		_check(shadow.character_id == id and shadow.body_type == hero.body_type and shadow.upgrades.size() == 3, "Own shadow copies hero/body with three random cards")
		var plain_max: float = shadow.base_max_hp + shadow.hp_growth * 9.0 + float(shadow.upgrade_modifiers.bonus_max_hp)
		_check(is_equal_approx(shadow.max_hp, plain_max * 1.5), "Own shadow HP x1.5 applies after its three cards")
		_check(main.director.band_started_at >= 0.0 and is_equal_approx(main.director.get_ringout_damage(), 30.0), "Wave 2 starts the shrinking band and ring-out 30")
		var bounds: Rect2 = main.layout.get_bounds(8)
		var band: Vector2 = main.director.get_sudden_death_band()
		_check(absf((band.y - band.x) / bounds.size.x - 1.0) < 0.02, "Band starts at the full arena width")
		hero.global_position.x = bounds.get_center().x
		shadow.global_position.x = bounds.position.x + 10.0
		var shadow_hp: float = shadow.hp
		main.director.advance(60.0)
		band = main.director.get_sudden_death_band()
		_check(is_equal_approx((band.y - band.x) / bounds.size.x, 0.2), "Band reaches 20 percent width after 60 seconds")
		_check(is_equal_approx(shadow.hp, shadow_hp), "Band never damages a shadow, even outside")
		hero.global_position.x = bounds.position.x + 10.0
		var before_hp: float = hero.hp
		main.director.advance(1.0)
		_check(is_equal_approx(hero.hp, before_hp - 8.0), "Band deals 8 HP/s to hero outside, ignoring combat protection")
		_check(is_equal_approx(shadow.hp, shadow_hp), "Same band tick leaves the bot HP untouched")
		hero.global_position = main.layout.get_spawn_points(8)[0]
		hero.global_position.x = bounds.get_center().x
		shadow.global_position = hero.global_position + Vector2(150, 0)
		main._apply_phase_rules()
		if id == "nova":
			await _capture("05-stage-nine-band-ko")
			var cards_before: Array = shadow.upgrades.duplicate()
			main = await _art_round_trip(main, "combat")
			shadow = main.story_session.rival
			hero = main.story_session.hero
			_check(shadow.upgrades == cards_before and is_equal_approx((main.director.get_sudden_death_band().y - main.director.get_sudden_death_band().x) / bounds.size.x, 0.2), "F2 retains random cards and elapsed shrinking band")
		shadow.invulnerable_timer = 0.0
		shadow.apply_environment_damage(shadow.hp, hero)
		await _frames(4)
		_check(main.story_session.phase == "post" and main.story_session.dialogue.cg_picture.visible, "Own-shadow defeat plays the existing epilogue picture and post lines")
		await _dialogue(main)
		_check(main.match_over and main.story_session.phase == "ending" and main.hud.frontend.screen == "story_ending", "Final post scene opens ending screen")
		_check(PROGRESS.get_run(id).done and PROGRESS.get_run(id).cleared == 9, "Stage 9 marks hero done/CLEAR")
		_check(main.hud.frontend.buttons.size() == 2 and _has_text(main.hud.frontend, tr("STORY COMPLETE")), "Ending offers Story map and Title")
		for line in STORY.ending_ids(id):
			_check(_has_text(main.hud.frontend, tr(line)), "Ending presents existing script line: " + line)
		if id == "nova":
			await _capture("06-story-ending-ko")
			main = await _art_round_trip(main, "ending")
		await _tap(KEY_R)
		_check(main.hud.frontend.screen == "story_ending", "R on ending cannot fall through to battle-royale rematch")
		main.hud.frontend.buttons[0].pressed.emit()
		await _frames(6)
		main = current_scene
		_check(main.hud.frontend.screen == "story_map" and not main.hud.frontend.start_button.disabled, "Ending Story map returns to all-nine replayable map")
		await _tap(KEY_ESCAPE)
		await _frames(6)
		_check(_has_text(current_scene.hud.frontend, tr("CLEAR"), true), "Hero select shows CLEAR for completed hero")
	var main: Node = current_scene
	main._on_story_action("story_title")
	await _frames(8)
	_check(current_scene.hud.frontend.screen == "title" and not current_scene.match_started, "Late-story round trip returns to title")
	_check(absi(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) - baseline) <= 5, "Late-story node baseline stable")
	_check(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == orphan_baseline, "Late-story has no orphan nodes")
	_check(_save_stamp() == save_before, "Late flow never creates or changes real story.cfg")
	MAIN.story_art_state = {}
	MAIN.session_mode = "battle_royale"
	MAIN.story_hero = "frey"
	MAIN.story_stage = 1
	PROGRESS.runs.clear()
	LANGUAGE.set_locale("en")
	if not failed:
		print("Late story flow tests passed (%d checks; %d heroes stages 5-9, home variants, time-up/crystals/boss/reinforcements/mid/band/ending, no real save)" % [checks, heroes.size()])
	quit(1 if failed else 0)

func _check_duel(main: Node, hero_id: String, number: int) -> void:
	var session: Node = main.story_session
	var data := STORY.stage(number)
	_check(main.hazards.enabled and main.hazards._realms[data.realm].hazard.type == ("quake" if number == 6 else "ice"), "Duel retains its realm gimmick")
	if STORY.is_home(data, hero_id):
		_check(not is_instance_valid(session.rival) and session.enemies.size() == 3 and session.enemies[0].is_elite, "Later home stage uses elite plus two monsters")
	else:
		_check(session.rival.character_id == data.rival and session.rival.upgrades == data.rival_mods.cards, "Later duel has catalog rival and one/two initial cards")
		var enemy: Node = session.rival
		var plain_max: float = enemy.base_max_hp + enemy.hp_growth * enemy.upgrades.size() * 3.0 + float(enemy.upgrade_modifiers.bonus_max_hp)
		_check(is_equal_approx(enemy.max_hp, plain_max * float(data.rival_mods.hp)), "Later rival HP multiplier survives its initial cards")
		_check(session.rival_bar.visible, "Duel rival HP bar visible")
	_check(is_equal_approx(main.director.get_ringout_damage(), 25.0), "Later duel ring-out damage 25")
	await _frames(1)

func _has_text(node: Node, text: String, substring := false) -> bool:
	if node is Label or node is Button:
		if node.text.contains(text) if substring else node.text == text:
			return true
	for child in node.get_children():
		if _has_text(child, text, substring):
			return true
	return false

func _begin(main: Node) -> void:
	await _tap(KEY_J)
	await _dialogue(main)
	_check(main.story_session.phase == "combat", "Pre scene enters combat")

func _dialogue(main: Node) -> void:
	for attempt in 18:
		if not main.story_session.dialogue.visible:
			return
		await _tap(KEY_J)
	_check(not main.story_session.dialogue.visible, "Dialogue advances within its script length")

func _defeat(main: Node) -> void:
	for enemy: Variant in main.story_session.enemies.duplicate():
		if is_instance_valid(enemy) and enemy.hp > 0.0:
			if enemy.has_method("apply_environment_damage"):
				enemy.apply_environment_damage(enemy.hp, main.story_session.hero)
			else:
				enemy.apply_hit(main.story_session.hero, 100000.0, 0.0, Vector2.RIGHT, "fixed")
	await _frames(4)

func _use_exit(main: Node) -> void:
	for attempt in 4:
		if main.soul_growth.get_offer(main.story_session.hero).is_empty():
			break
		await _tap(KEY_1)
	var point: Vector2 = main.layout.get_portal_stand_point(main.story_session.hero.realm_index, STORY.stage(main.story_stage).exit)
	main.story_session.hero.global_position = point + Vector2(0, -2)
	main.story_session.hero.velocity = Vector2.ZERO
	await _frames(6)
	await _tap(KEY_Q)
	await _frames(4)
	_check(main.match_over and main.hud.frontend.stage_result.clear, "Q at the authored exit clears the stage")

func _next(main: Node, number: int) -> Node:
	main.hud.frontend.buttons[0].pressed.emit()
	await _frames(6)
	main = current_scene
	_check(main.story_stage == number and main.hud.frontend.screen == "story_start", "Next starts ready stage %d" % number)
	return main

func _art_round_trip(main: Node, expected_phase: String) -> Node:
	var souls: int = main.story_session.hero.souls
	for toggle in 2:
		await _tap(KEY_F2)
		await _frames(6)
		main = current_scene
		_check(main.story_session.phase == expected_phase and main.story_session.hero.souls == souls, "F2 preserves late-stage phase and souls: " + expected_phase)
	return main

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

func _capture(stem: String) -> void:
	if not capture:
		return
	_check(DisplayServer.get_name() != "headless", "Capture is windowed")
	current_scene.hud.bot_panel_wanted = false
	current_scene.hud.bot_panel.visible = false
	await _frames(3)
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(report_dir.path_join(stem + ".png")) == OK, "Save screenshot: " + stem)
