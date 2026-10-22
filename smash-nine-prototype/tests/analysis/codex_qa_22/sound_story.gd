extends "res://tests/analysis/codex_qa_21/story_edges.gd"
## QA-21 journey fixture: protected Frey, public defeat/crystal APIs, same 3-frame
## wave waits and real Q exit. This measures progression hooks, not human fights.
const RECORDER := preload("res://tests/analysis/codex_qa_22/audio_recorder.gd")
var recorder: Node
var stage_number := 1

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stage="):
			stage_number = int(arg.get_slice("=", 1))
	recorder = RECORDER.new()
	recorder.name = "AudioManager"
	recorder.probe_enabled = true
	call_deferred("_install_recorder")
	super._initialize()

func _install_recorder() -> void:
	root.add_child(recorder)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var main: Node = await _start(stage_number)
	var session: Node = main.story_session
	var hero: Node = session.hero
	recorder.mark("combat_start")
	if stage_number == 9:
		hero.hp = hero.max_hp * 0.5
	for wave in 6:
		if session.phase == "mid":
			recorder.mark("mid_dialogue")
			session.dialogue._activate("dialogue_skip", "")
		if session.phase != "combat":
			break
		if stage_number == 5:
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
	var post_reached: bool = session.phase == "post"
	recorder.mark("post_dialogue")
	session.dialogue._activate("dialogue_skip", "")
	if stage_number <= 7:
		for attempt in 4:
			if main.soul_growth.get_offer(hero).is_empty():
				break
			await _tap(KEY_1)
		var point: Vector2 = main.layout.get_portal_stand_point(hero.realm_index, session.data.exit)
		hero.global_position = point + Vector2(0, -2)
		hero.velocity = Vector2.ZERO
		await _frames(6)
		await _tap(KEY_Q)
	await _frames(3)
	recorder.mark("story_result_or_ending")
	var stats := {"seed": 2101, "stage": stage_number, "driver": "QA21 protected progression fixture", "post_reached": post_reached, "phase": session.phase, "match_over": main.match_over, "seconds_simulated": main.director.match_elapsed, "screen": main.hud.frontend.screen}
	recorder.save_capture("res://../reports/codex-qa-22/sound-story-%d.json" % stage_number, stats)
	print("QA22_STORY_SOUND ", JSON.stringify(stats))
	main._on_story_action("story_title")
	await _frames(6)
	quit(0 if post_reached and bool(stats.match_over) else 1)

func _tap(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)
