extends SceneTree
## The screens after the menus in the picked look (2026-11-27): options, controls and the story map
## over the title art, then over a running match the story pause, the story results, the start card,
## the ending and the battle results, each saved once as the game draws it. Run windowed (it saves
## the drawn frame), silent, from the project folder:
##   <godot> --audio-driver Dummy --path smash-nine-prototype -s tests/analysis/ui_audit/later_screens_capture.gd -- --out=<dir> [--lang=ko]
## Nothing is saved to the player's settings: the language is set for the run only, no option is
## pressed and no stage is completed.

const MAIN_SCENE := "res://scenes/Main.tscn"
const LANGUAGE := preload("res://scripts/Language.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")

var out_dir := ""
var lang := "en"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--lang="):
			lang = arg.get_slice("=", 1)
	if out_dir == "":
		push_error("--out=<dir> is required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _save(stem: String) -> void:
	await _frames(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(out_dir.path_join("%s-%s.jpg" % [stem, lang]), 0.95)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	# Read the (unused under -s) saved choice first, so the scene's own read keeps this run's language.
	LANGUAGE.load_saved()
	LANGUAGE.set_locale(lang)
	change_scene_to_file(MAIN_SCENE)
	await _frames(10)
	var main: Node = current_scene
	var hud: Node = main.hud
	var menu: Control = hud.frontend
	menu.show_options()
	await _save("01-options")
	menu.show_controls()
	await _save("02-controls")
	menu.selected_id = "frey"
	menu.body = "male"
	menu.show_story_map(1)
	await _save("03-story-map")
	# A match behind the rest, as a story stage stands behind its pause and results.
	main._start_match("frey")
	await _frames(40)
	menu.show_story_pause()
	hud.overlay_background_art.visible = false
	hud.overlay_back.color = Color(0.02, 0.025, 0.05, 0.72)
	hud.overlay.visible = true
	await _save("04-story-pause")
	hud._set_match_hud_visible(false)
	hud.overlay_back.color = Color(0.02, 0.025, 0.05, 0.86)
	menu.show_story_result({"clear": true, "stage": 4, "seconds": 91, "damage": 42, "cards": ["sky_step", "last_stand"]})
	await _save("05-story-clear")
	menu.show_story_result({"clear": false, "stage": 7, "seconds": 300, "damage": 120, "cards": [], "reason": "time up"})
	await _save("06-story-failed")
	menu.show_stage_card(STORY.stage(2))
	await _save("07-story-card")
	menu.show_story_ending()
	await _save("08-story-ending")
	hud.hide_overlay()
	await _frames(20)
	var human: Node = main._get_human_player()
	human.upgrades.assign(["sky_step", "last_stand"])
	main.director._finish(human, "last survivor")
	await _frames(20)
	await _save("09-results")
	quit()
