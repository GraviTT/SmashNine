extends SceneTree

## Short runtime-only visual check: capture the four attack atlas frames at their actual 1×
## in-game size without changing product code or waiting through a full match.

const MAIN_SCENE := "res://scenes/Main.tscn"

var pick := "frey"
var out_dir := ""
var brave := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pick="):
			pick = arg.get_slice("=", 1)
		elif arg == "--brave":
			brave = true
		elif arg.begins_with("--out="):
			out_dir = ProjectSettings.globalize_path("res://").path_join(arg.get_slice("=", 1))
	if out_dir.is_empty():
		out_dir = ProjectSettings.globalize_path("res://../reports/codex-art-21/runtime_%s" % pick)
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _run() -> void:
	var main: Node = (load(MAIN_SCENE) as PackedScene).instantiate()
	main.set("match_seed", 4242)
	root.add_child(main)
	for unused in 8:
		await process_frame
	main.call("_start_match", pick)
	for unused in 90:
		await process_frame
	var players: Array = main.get("players")
	var human: Node = players[0]
	paused = true
	var sprite: AnimatedSprite2D = human.character_sprite
	var animation_prefix := "%s_brave" % pick if brave else pick
	var animation := StringName("%s_attack" % animation_prefix)
	sprite.play(animation)
	sprite.pause()
	for frame in 4:
		sprite.frame = frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := out_dir.path_join("attack_frame_%d.png" % (frame + 1))
		image.save_png(path)
		print("saved ", path)
	paused = false
	quit(0)
