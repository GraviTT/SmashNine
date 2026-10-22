extends SceneTree
## Windowed presentation fixtures only: in-memory completed journey and a real timeout.
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
	MAIN.last_character_id = "nova"
	MAIN.human_body = "female"
	MAIN.story_difficulty = "normal"
	MAIN.story_stage = 9
	MAIN.story_art_state = {}
	MAIN.next_screen = "story_map"
	PROGRESS.runs.clear()
	PROGRESS.new_journey("nova", "normal")
	for number in range(1, 10):
		PROGRESS.complete_stage("nova", number, 288, ["power", "vitality", "sky_step"])
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(6)
	var main: Node = current_scene
	if main.hud.frontend.stage_buttons.size() != 9 or main.hud.frontend.stage_buttons.any(func(button: Button) -> bool: return button.disabled):
		push_error("All nine stages must be selectable in the completed-journey fixture")
		quit(1)
		return
	await _capture("08-story-map-all-ready-ko.png")
	main._on_story_action("story_select")
	await _frames(6)
	main = current_scene
	main.hud.frontend.selected_id = "nova"
	main.hud.frontend.refresh_body("female")
	var has_clear := false
	for label: Node in main.hud.frontend.content.get_children():
		if label is Label and tr("CLEAR") in label.text:
			has_clear = true
	if not has_clear or not PROGRESS.get_run("nova").done:
		push_error("Completed hero must display CLEAR")
		quit(1)
		return
	await _capture("09-story-clear-select-ko.png")
	PROGRESS.new_journey("nova", "normal")
	MAIN.story_stage = 5
	main._on_story_action("story_retry")
	await _frames(6)
	main = current_scene
	main.story_session.begin_dialogue()
	main.story_session.dialogue._activate("dialogue_skip", "")
	main.director.advance(60.0)
	await _frames(3)
	if not main.match_over or main.director.finish_reason != "time up":
		push_error("Unbroken crystals must show the real time-up result")
		quit(1)
		return
	await _capture("10-stage-five-time-up-ko.png")
	PROGRESS.runs.clear()
	print("Completion captures passed (all-nine map, CLEAR selection, real time-up; memory fixtures, no user save)")
	quit(0)

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() == "headless" or root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../reports/codex-sys-04/" + name)) != OK:
		push_error("Windowed completion capture failed: " + name)
		quit(1)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
