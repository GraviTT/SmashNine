extends SceneTree
const MAIN := preload("res://scripts/Main.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	LANGUAGE.load_saved()
	LANGUAGE.set_locale("ko")
	root.size = Vector2i(1280, 720)
	MAIN.next_screen = "story_stage"
	MAIN.story_hero = "luna"
	MAIN.story_stage = 2
	MAIN.story_difficulty = "normal"
	MAIN.story_art_state = {}
	PROGRESS.new_journey("luna", "normal")
	change_scene_to_file("res://scenes/Main.tscn")
	for frame in 6:
		await physics_frame
		await process_frame
	var main: Node = current_scene
	main.story_session.begin_dialogue()
	main.story_session.dialogue._activate("dialogue_skip", "")
	main.hazards.trigger(0)
	for frame in 3:
		await physics_frame
		await process_frame
	main._update_hud()
	var overlap: bool = main.hud.warning_label.get_global_rect().intersects(main.story_session.rival_bar.get_global_rect())
	print("Story warning/rival overlap: ", overlap)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../reports/codex-sys-03/14-rival-warning-ko.png"))
	quit(1 if overlap else 0)
