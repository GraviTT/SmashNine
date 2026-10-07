extends SceneTree
## Visual check (needs a window, not --headless): saves PNGs of the start screen,
## a fight, a soul card offer, a collapse warning, the open center, sudden death
## and the result screen. Match time is skipped forward through MatchDirector.
## Usage: godot --path . -s tests/capture_screens.gd -- --out=../reports/screens-m1 [--art=prototype] [--pick=rio] [--body=female]

const MAIN_SCENE := "res://scenes/Main.tscn"
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")

var out_dir := ""
var pick := "frey"
var main: Node

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://").path_join("../reports/screens")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--art="):
			ART_SETTINGS.style = arg.get_slice("=", 1)
		if arg.begins_with("--pick="):
			pick = arg.get_slice("=", 1)
		if arg.begins_with("--body="):
			main_script().human_body = arg.get_slice("=", 1)
		if arg.begins_with("--out="):
			out_dir = ProjectSettings.globalize_path("res://").path_join(arg.get_slice("=", 1))
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _run() -> void:
	main = load(MAIN_SCENE).instantiate()
	main.match_seed = 4242
	root.add_child(main)
	await _settle(10)
	await _shot("01_start_screen")
	main._start_match(pick)
	await _settle(150)
	await _shot("02_corner_fight")
	var human: Node = main.players[0]
	human.add_souls(25)
	await _settle(20)
	await _shot("03_soul_card_offer")
	await _skip_to(121.0)
	await _settle(30)
	await _shot("04_collapse_warning")
	await _skip_to(212.0)
	main._set_map(main.CENTRAL_REALM_INDEX)
	await _settle(30)
	await _shot("05_center_open")
	await _skip_to(380.0)
	main._set_map(main.CENTRAL_REALM_INDEX)
	await _settle(30)
	await _shot("06_sudden_death")
	await _skip_to(421.0)
	await _settle(20)
	await _shot("07_results")
	print("Screens saved to ", out_dir)
	quit(0)

func _skip_to(time: float) -> void:
	while main.director.match_elapsed < time and not main.director.match_over:
		main.director.advance(minf(0.5, time - main.director.match_elapsed + 0.001))
		main._apply_phase_rules()
		await process_frame

func _settle(frames: int) -> void:
	for frame in frames:
		await process_frame

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := out_dir.path_join("%s.png" % shot_name)
	image.save_png(path)
	print("saved ", path)

func main_script() -> Script:
	return load("res://scripts/Main.gd")
