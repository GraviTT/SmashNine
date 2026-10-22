extends SceneTree
## Actual post-boss scene while the underlying eruption warning is frozen: no match HUD.
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
	MAIN.story_stage = 7
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
	main.hazards.trigger(4)
	main.story_session.rival.apply_hit(main.story_session.hero, 100000.0, 0.0, Vector2.RIGHT, "fixed")
	for frame in 3:
		await physics_frame
		await process_frame
	main._update_hud()
	if main.hud.warning_label.visible or main.hud.hp_bar.visible or main.hazards.get_phase(4) != "warning":
		push_error("Post scene must hide the timed realm warning and match HUD")
		quit(1)
		return
	main.story_session.dialogue.line_label.visible_characters = -1
	main.story_session.dialogue._characters = main.story_session.dialogue.line_label.get_total_character_count()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../reports/codex-sys-04/07-boss-post-warning-hidden-ko.png")
	if root.get_texture().get_image().save_png(path) != OK or DisplayServer.get_name() == "headless":
		push_error("Windowed post-scene capture failed")
		quit(1)
		return
	print("Post-scene capture passed (eruption warning remains frozen underneath; complete match HUD hidden)")
	quit(0)
