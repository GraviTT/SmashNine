extends SceneTree
## The menu tour for the next UI direction round (prepared 2026-11-25, taken again 2026-11-26 for
## the title's sixth row): the title, where the focus walks down the six entries and back, then
## the character select, where the choice walks
## through the six fighters and the body flips once on Nova. "now" drives the game's own menu;
## "a" and "b" draw menu_proto.gd in its place, fed the same steps at the same frames.
## Run it on the exported pack, so "now" is what a player of the web build sees (a run from the
## project folder also finds files the export leaves out; UI audit 2026-11-25, B9):
##   cat build/web/index.pck.part* | gunzip > <dir>/index.pck   (copy this script and menu_proto.gd beside it)
##   <godot> --audio-driver Dummy --fixed-fps 60 --main-pack <dir>/index.pck -s <dir>/menu_direction_capture.gd -- --variant=now|a|b --out=<dir>/out [--stills] [--lang=ko]
## A JPG every second frame (30 fps) goes to <out>/title/####.jpg and <out>/select/####.jpg;
## --stills saves one frame per step instead.

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAIN := preload("res://scripts/Main.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const TITLE_STEP := 36
const SELECT_STEP := 48
## Title: the focus on each entry in turn (six since Practice, 2026-11-26), then back to the first.
const TITLE_FOCUS := [0, 1, 2, 3, 4, 5, 0]
## Select: [fighter, body] per step. Nova shows both bodies; the body then stays for Rio.
const SELECT_STEPS := [["frey", "male"], ["yuki", "male"], ["luna", "male"], ["nova", "male"], ["nova", "female"], ["rio", "female"], ["xion", "female"], ["frey", "female"]]

var variant := "now"
var out_dir := ""
var lang := "ko"
var stills := false
var main: Node
var proto: Control
var saved := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--variant="):
			variant = arg.get_slice("=", 1)
		elif arg.begins_with("--out="):
			out_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--lang="):
			lang = arg.get_slice("=", 1)
		elif arg == "--stills":
			stills = true
	if out_dir == "":
		push_error("--out=<dir> is required")
		quit(1)
		return
	for part in ["title", "select"]:
		DirAccess.make_dir_recursive_absolute(out_dir.path_join(part))
	call_deferred("_run")

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	saved += 1
	root.get_texture().get_image().save_jpg(path, 0.95)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("The tour must be windowed")
		quit(1)
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	LANGUAGE.set_locale(lang)
	MAIN.human_body = "male"
	MAIN.last_character_id = "frey"
	MAIN.next_screen = "title"
	main = load(MAIN_SCENE).instantiate()
	main.match_seed = 4242
	root.add_child(main)
	current_scene = main
	await _frames(8)
	if variant != "now":
		# The prototype stands on its own layer over the game's menu, with its own backdrop.
		var here := (get_script() as Script).resource_path.get_base_dir()
		var layer := CanvasLayer.new()
		layer.layer = 20
		root.add_child(layer)
		proto = (load(here.path_join("menu_proto.gd")) as Script).new()
		layer.add_child(proto)
		proto.setup(variant)
	await _tour("title", TITLE_FOCUS.size(), TITLE_STEP)
	if variant == "now":
		main.hud.frontend.show_select()
	await _tour("select", SELECT_STEPS.size(), SELECT_STEP)
	LANGUAGE.set_locale("en")
	print("Menu tour '%s': %d frames in %s" % [variant, saved, out_dir])
	quit(0)

func _tour(part: String, steps: int, step_frames: int) -> void:
	for frame in steps * step_frames:
		if frame % step_frames == 0:
			_step(part, frame / step_frames)
		await process_frame
		if stills:
			if frame % step_frames == step_frames / 2:
				await _save(out_dir.path_join(part).path_join("still_%02d.jpg" % (frame / step_frames)))
		elif frame % 2 == 0:
			await _save(out_dir.path_join(part).path_join("%04d.jpg" % (frame / 2 + 1)))

func _step(part: String, index: int) -> void:
	if part == "title":
		var focus: int = TITLE_FOCUS[index]
		if variant == "now":
			main.hud.frontend.buttons[focus].grab_focus()
		else:
			proto.show_title(focus)
		return
	var id := str(SELECT_STEPS[index][0])
	var body := str(SELECT_STEPS[index][1])
	if variant == "now":
		var menu: Control = main.hud.frontend
		if MAIN.human_body != body:
			MAIN.human_body = body
			menu.refresh_body(body)
		menu.portrait_buttons[REGISTRY.get_character_ids().find(id)].grab_focus()
	else:
		proto.show_select(id, body)
