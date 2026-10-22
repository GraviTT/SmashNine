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
	for frame in 4:
		await physics_frame
		await process_frame
	var main: Node = current_scene
	main.story_session.begin_dialogue()
	var dialogue: Node = main.story_session.dialogue
	dialogue.advance_line() # reveal narrator
	dialogue.advance_line() # hero
	dialogue.advance_line() # reveal hero
	await _capture("15-dialogue-hero-ko.png")
	var hero_ok: bool = dialogue.left_face.modulate == Color.WHITE and dialogue.right_face.modulate != Color.WHITE
	dialogue.advance_line() # rival
	dialogue.advance_line() # reveal rival
	await _capture("16-dialogue-rival-ko.png")
	var rival_ok: bool = dialogue.right_face.modulate == Color.WHITE and dialogue.left_face.modulate != Color.WHITE
	print("Dialogue portrait sides/dimming: hero=", hero_ok, " rival=", rival_ok)
	quit(0 if hero_ok and rival_ok else 1)

func _capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../reports/codex-sys-03/" + filename))
