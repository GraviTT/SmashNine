extends SceneTree
## The gamepad's names on the match HUD and the screens that name pad buttons (2026-11-27): a
## match as Nova (all five skill slots) with the pad's names applied as PadGlyphs applies them, then
## the controls screen's pad table and the practice menu. Run windowed and silent:
##   <godot> --audio-driver Dummy --path smash-nine-prototype -s tests/analysis/ui_audit/pad_badges_capture.gd -- --out=<dir> [--lang=ko]
## Nothing is saved to the player's settings.

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAIN := preload("res://scripts/Main.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const GLYPHS := preload("res://scripts/input/PadGlyphs.gd")

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
	LANGUAGE.load_saved()
	LANGUAGE.set_locale(lang)
	change_scene_to_file(MAIN_SCENE)
	await _frames(10)
	var main: Node = current_scene
	var menu: Control = main.hud.frontend
	if menu.has_method("show_controls"):
		menu.show_controls()
		await _save("01-controls")
		if menu.has_method("show_controls_tab"):
			menu.show_controls_tab("pad")
			await _save("02-controls-pad")
	main._start_match("nova")
	await _frames(30)
	GLYPHS.apply(main.hud, true)
	await _frames(3)
	GLYPHS.apply(main.hud, true)
	await _save("03-hud-pad")
	GLYPHS.apply(main.hud, false)
	await _frames(3)
	await _save("04-hud-keys")
	# Practice: the menu and the skill list, with the keyboard's caps and with a pad's badges.
	MAIN.next_screen = "practice"
	MAIN.last_character_id = "nova"
	MAIN.human_body = "male"
	change_scene_to_file(MAIN_SCENE)
	await _frames(40)
	main = current_scene
	var session: Node = main.practice_session
	if session == null:
		push_error("practice did not start")
		quit(1)
		return
	session.menu_index = 0
	session.open_menu()
	session.menu_index = 2
	session._show_menu()
	await _save("05-practice-menu")
	GLYPHS.pad_in_use = true
	session._show_menu()
	await _save("06-practice-menu-pad")
	session.close_panel()
	GLYPHS.pad_in_use = false
	session.open_panel("skills")
	await _save("07-practice-skills")
	GLYPHS.pad_in_use = true
	session._show_skills()
	await _save("08-practice-skills-pad")
	GLYPHS.pad_in_use = false
	session.close_panel()
	MAIN.next_screen = "title"
	quit()
