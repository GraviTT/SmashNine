extends SceneTree
## Lead capture (2026-11-24, pick cup round 2026-11-24 applied): Xion's five new icons on the HUD skill bar with
## her counts on top (J: rounds left after two shots; U: the double's seconds). Saves the whole screen and the
## bar enlarged 3x.
## Windowed run (not headless): <godot> --path . -s tests/analysis/lead/xion_skill_bar_capture.gd -- --out=<dir>

const MAIN_SCENE := "res://scenes/Main.tscn"

var out_dir := "user://xion_skill_bar"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _run() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.match_seed = 4242
	root.add_child(main)
	for frame in 10:
		await process_frame
	main._start_match("xion")
	for frame in 60:
		await process_frame
	var xion: Node = main.players[0]
	for shot in 2:
		xion.basic_attack()
		for frame in 40:
			await process_frame
	xion.skill_three()
	for frame in 40:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("%s/xion_screen.png" % out_dir)
	var size := image.get_size()
	var bar := image.get_region(Rect2i(size.x - 300, size.y - 110, 300, 110))
	bar.resize(900, 330, Image.INTERPOLATE_NEAREST)
	bar.save_png("%s/xion_skill_bar_3x.png" % out_dir)
	print("ammo=", xion.get("ammo"), " J=", xion.skill_counter("j"), " U=", xion.skill_counter("u"), " saved ", out_dir)
	quit(0)
