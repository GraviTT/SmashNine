extends SceneTree
## Practice mode captures (2026-11-26): the title with its sixth row, the select screen opened
## from Practice, the practice HUD against each target, the card list and the skill list, as PNG.
## Windowed (not --headless). Meant for the exported pack, so that what is seen is what the web
## build holds:
##   <godot> --audio-driver Dummy --main-pack <index.pck> -s <absolute path to this file> -- \
##       --lang=ko --out=<absolute dir> [--fighter=frey]
## Keys are real key events. A script run never reads or writes the real saves.

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAIN := preload("res://scripts/Main.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const SESSION := preload("res://scripts/practice/PracticeSession.gd")

var out_dir := ""
var lang := "ko"
var fighter := "frey"
var failed := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):
			lang = arg.get_slice("=", 1)
		elif arg.begins_with("--out="):
			out_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--fighter="):
			fighter = arg.get_slice("=", 1)
	if out_dir == "":
		push_error("--out=<dir> is required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _shot(shot_name: String) -> void:
	await _frames(2)
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join("%s_%s.png" % [shot_name, lang])
	if root.get_texture().get_image().save_png(path) != OK:
		failed = true
		push_error("Save capture: " + path)
	print("saved ", shot_name)

func _tap(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Captures must be windowed")
		quit(1)
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	LANGUAGE.set_locale(lang)
	MAIN.next_screen = "title"
	MAIN.last_character_id = fighter
	SESSION.bot_id = "frey"
	change_scene_to_file(MAIN_SCENE)
	await _frames(10)
	var main: Node = current_scene
	await _shot("01_title")
	# The third row is Practice.
	main.hud.frontend.buttons[2].pressed.emit()
	await _frames(6)
	await _shot("02_select")
	await _tap(KEY_ENTER)
	await _frames(40)
	main = current_scene
	if not is_instance_valid(main.practice_session):
		push_error("Practice did not start")
		quit(1)
		return
	var session: Node = main.practice_session
	await _frames(60)
	await _shot("03_practice_start")
	# A hit on the dummy, so that the damage line shows numbers.
	session.hero.global_position = session.target.global_position + Vector2(-70, 0)
	await _frames(12)
	await _tap(KEY_J)
	await _frames(40)
	await _shot("04_after_a_hit")
	await _tap(KEY_H)
	await _frames(60)
	await _shot("05_walking_dummy")
	await _tap(KEY_H)
	await _frames(80)
	await _shot("06_fighting_bot")
	await _tap(KEY_M)
	await _frames(30)
	await _shot("07_monster")
	await _tap(KEY_R)
	await _frames(20)
	await _tap(KEY_C)
	await _frames(6)
	await _shot("08_cards_page_1")
	await _tap(KEY_1)
	await _tap(KEY_D)
	await _tap(KEY_D)
	await _frames(4)
	await _shot("09_cards_page_3")
	await _tap(KEY_A)
	await _tap(KEY_A)
	await _tap(KEY_A)
	await _frames(4)
	await _shot("10_cards_last_page")
	await _tap(KEY_C)
	await _frames(10)
	await _tap(KEY_TAB)
	await _frames(6)
	await _shot("11_skills")
	await _tap(KEY_TAB)
	await _frames(20)
	await _shot("12_back_in_play")
	quit(1 if failed else 0)
