extends SceneTree
## One windowed overview of the actual stage, with the camera widened for all three crystals.
const MAIN := preload("res://scripts/Main.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const LANGUAGE := preload("res://scripts/Language.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	LANGUAGE.set_locale("ko")
	MAIN.story_hero = "nova"
	MAIN.human_body = "female"
	MAIN.story_stage = 5
	MAIN.story_difficulty = "normal"
	MAIN.story_art_state = {}
	MAIN.next_screen = "story_stage"
	PROGRESS.runs.clear()
	PROGRESS.new_journey("nova", "normal")
	change_scene_to_file("res://scenes/Main.tscn")
	for frame in 6:
		await physics_frame
		await process_frame
	var main: Node = current_scene
	main.story_session.begin_dialogue()
	main.story_session.dialogue._activate("dialogue_skip", "")
	main.story_session.hero.grant_protection(1000.0)
	for frame in 40:
		await physics_frame
		await process_frame
	main.director.match_elapsed = 18.0
	main.hazards.advance(1.3)
	main._update_hud()
	main.hud.bot_panel_wanted = false
	main.hud.bot_panel.visible = false
	main.story_session.hero.global_position.x -= 150.0
	main.set_process(false)
	main.camera.zoom = Vector2.ONE * 0.62
	main.camera.global_position = main.layout.get_bounds(6).get_center()
	main.camera.reset_smoothing()
	for frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../reports/codex-sys-04/00-stage-five-overview-ko.png")
	var result := root.get_texture().get_image().save_png(path)
	if result != OK or DisplayServer.get_name() == "headless":
		push_error("Windowed escape overview capture failed")
		quit(1)
		return
	print("Escape overview capture passed (real stage, three crystals, camera zoom 0.62 for overview only)")
	quit(0)
