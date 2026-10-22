extends SceneTree
const MAIN := preload("res://scripts/Main.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")

func _initialize() -> void:
	create_timer(6.0, true, false, true).timeout.connect(func() -> void: quit(2))
	call_deferred("_run")

func _areas(main: Node) -> int:
	var count := 0
	for node in main.get_children():
		if node is Area2D:
			count += 1
	return count

func _run() -> void:
	MAIN.next_screen = "story_stage"
	MAIN.story_hero = "luna"
	MAIN.story_stage = 2
	MAIN.story_difficulty = "normal"
	MAIN.story_art_state = {}
	PROGRESS.new_journey("luna", "normal")
	change_scene_to_file("res://scenes/Main.tscn")
	for frame in 4:
		await physics_frame
		await process_frame
	var main: Node = current_scene
	main.story_session.begin_dialogue()
	main.story_session.dialogue._activate("dialogue_skip", "")
	main.story_session.rival.perform_basic_attack("neutral", Vector2.LEFT)
	main.story_session.pause_stage()
	var zero_scale := OS.get_cmdline_user_args().has("--zero-scale")
	if zero_scale:
		Engine.time_scale = 0.0
		for frame in 3:
			await physics_frame
		print("Physics frame signals still advance at zero scale")
	await create_timer(0.25, true, false, true).timeout
	var while_paused := _areas(main)
	print("Paused pending attack areas: ", while_paused, " zero_scale=", zero_scale)
	main.story_session.resume_stage()
	SPEED.apply_to_match()
	await create_timer(0.09, true, false, true).timeout
	print("Resumed pending attack areas: ", _areas(main))
	SPEED.reset_engine()
	quit(0 if zero_scale and while_paused == 0 else 1)
