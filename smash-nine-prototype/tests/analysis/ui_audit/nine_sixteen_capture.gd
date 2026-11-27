extends SceneTree
## Screens ready for nine fighters and sixteen-fighter matches (2026-11-27, D58): the select screen
## and the story select with three stand-in fighters (copies of Frey's data under new ids, no art),
## then a real sixteen-fighter match: the HUD a few seconds in and later (bot panel, minimap,
## off-screen faces), and its results. Run windowed (the window may stand off screen):
##   <godot> --audio-driver Dummy --position -4000,-4000 --path smash-nine-prototype -s tests/analysis/ui_audit/nine_sixteen_capture.gd -- --out=<dir> [--lang=ko]

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAIN := preload("res://scripts/Main.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const STAND_INS := {"borok": ["Borok", Color("c8743c")], "doron": ["Doron", Color("6c9a4a")], "jupi": ["Jupi", Color("d36fb5")]}

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
	MAIN.session_player_count = 16
	change_scene_to_file(MAIN_SCENE)
	await _frames(10)
	var main: Node = current_scene
	var menu: Control = main.hud.frontend
	var ids: Array[String] = REGISTRY.get_character_ids()
	for id: String in STAND_INS:
		var data: Dictionary = (menu._roster["frey"] as Dictionary).duplicate()
		data.name = STAND_INS[id][0]
		data.color = STAND_INS[id][1]
		menu._roster[id] = data
		ids.append(id)
	menu.show_select(ids)
	await _save("01-select-nine")
	menu.show_story_select(ids)
	await _save("02-story-select-nine")
	menu.show_title()
	main._start_match("frey")
	await _frames(90)
	await _save("03-match-16-start")
	await _frames(600)
	await _save("04-match-16-later")
	var human: Node = main._get_human_player()
	main.director._finish(human, "last survivor")
	await _frames(20)
	await _save("05-results-16")
	MAIN.session_player_count = 8
	quit()
