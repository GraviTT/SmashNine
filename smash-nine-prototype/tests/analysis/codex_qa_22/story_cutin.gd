extends "res://tests/analysis/codex_qa_21/story_edges.gd"
## Public I key, then public monster-hit API completes the stage inside the cut-in window.
func _run() -> void:
	root.size = Vector2i(1280, 720)
	var main: Node = await _start(2)
	var hero: Node = main.story_session.hero
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = KEY_I
		event.keycode = KEY_I
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)
	var cast_seen: bool = main.hud.cutin_root.visible and hero.ultimate_cooldown_timer > 0.0
	for enemy: Node in main.story_session.enemies.duplicate():
		enemy.apply_hit(hero, 100000.0, 0.0, Vector2.RIGHT, "fixed")
	await _frames(2)
	var entered_phase: String = main.story_session.phase
	var overlap_frames := 0
	var first_frame := -1
	var last_frame := -1
	var cutin_rect: Rect2 = main.hud.cutin_root.get_global_rect()
	for frame in 90:
		if main.story_session.dialogue.visible and main.hud.cutin_root.is_visible_in_tree() and main.hud.cutin_root.modulate.a > 0.01:
			overlap_frames += 1
			if first_frame < 0:
				first_frame = Engine.get_physics_frames()
			last_frame = Engine.get_physics_frames()
		await _frames(1)
	var row := {"seed": 2101, "stage": 2, "cast_seen": cast_seen, "phase": entered_phase, "dialogue": main.story_session.dialogue.visible, "overlap_frames": overlap_frames, "seconds_at_60fps": overlap_frames / 60.0, "first_frame": first_frame, "last_frame": last_frame, "cutin_rect": str(cutin_rect), "clock_visible": main.hud.clock_label.visible}
	print("QA21_STORY_CUTIN ", JSON.stringify(row))
	var file := FileAccess.open("res://../reports/codex-qa-22/story-cutin.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(row, "\t") + "\n")
	main._on_story_action("story_title")
	await _frames(6)
	quit(1 if overlap_frames > 0 else 0)
