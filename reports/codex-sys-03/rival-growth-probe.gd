extends SceneTree
const MAIN := preload("res://scripts/Main.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	MAIN.next_screen = "story_stage"
	MAIN.story_hero = "luna"
	MAIN.story_stage = 2
	MAIN.story_difficulty = "easy"
	MAIN.story_art_state = {}
	PROGRESS.new_journey("luna", "easy")
	change_scene_to_file("res://scenes/Main.tscn")
	for frame in 4:
		await physics_frame
		await process_frame
	var main: Node = current_scene
	main.story_session.begin_dialogue()
	main.story_session.dialogue._activate("dialogue_skip", "")
	if OS.get_cmdline_user_args().has("--baseline"):
		main.soul_growth.offer_closed.disconnect(Callable(main.story_session, "_on_rival_card_chosen"))
	var rival: Node = main.story_session.rival
	rival.add_souls(25)
	main.soul_growth.choose(rival, 0)
	var expected: float = (rival.base_max_hp + rival.hp_growth * 3.0 + float(rival.upgrade_modifiers.bonus_max_hp)) * 0.8 * 0.8
	print("Rival growth HP: ", rival.max_hp, " expected: ", expected, " current HP: ", rival.hp)
	quit(0 if is_equal_approx(rival.max_hp, expected) else 1)
