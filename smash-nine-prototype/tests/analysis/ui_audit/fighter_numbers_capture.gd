extends SceneTree
## Same fighters numbered (2026-11-27, the lead's pick A): an eight-fighter match (three characters
## take two seats each) with one numbered pair brought into P1's realm for the picture, so both
## overhead names show next to P1's, an elimination line between the two and the bot panel; the
## results of that match, won by the second of the pair; then the results of a sixteen-fighter
## match, where P1's character takes two more seats (Frey 2, Frey 3). Also, at one held moment, the
## pair's overhead names drawn under the picture (before 2026-11-27) and over it (now), cut out
## round each name. Run windowed (the window may stand off screen):
##   <godot> --audio-driver Dummy --position -4000,-4000 --path smash-nine-prototype -s tests/analysis/ui_audit/fighter_numbers_capture.gd -- --out=<dir> [--lang=ko]

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAIN := preload("res://scripts/Main.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const NAMES := preload("res://scripts/ui/FighterNames.gd")

var out_dir := ""
var lang := "ko"

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

func _start(count: int) -> Node:
	MAIN.session_player_count = count
	seed(3001)
	change_scene_to_file(MAIN_SCENE)
	await _frames(10)
	var main: Node = current_scene
	main._start_match("frey")
	return main

func _run() -> void:
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	LANGUAGE.set_locale(lang)
	var main: Node = await _start(8)
	await _frames(60)
	var human: Node = main._get_human_player()
	# The first character that two bots share.
	var pair: Array = []
	for player in main.players:
		if pair.size() < 2 and not player.is_human and NAMES.number_of(player) > 0:
			if pair.is_empty() or str(pair[0].display_name) == str(player.display_name):
				pair.append(player)
	for index in pair.size():
		var bot: Node = pair[index]
		main.layout.assign_combatant(bot, human.realm_index)
		bot.global_position = human.global_position + Vector2(-260.0 if index == 0 else 260.0, -40.0)
		bot.velocity = Vector2.ZERO
	main._sync_combatant_visibility()
	await _frames(20)
	# Only the line: nobody leaves the match.
	main._on_player_defeated(pair[0], pair[1])
	# Held still, the same moment twice: the overhead names and bars under the picture as they
	# were (layer 0), then over it as they are now (layer 1, after the picture).
	paused = true
	await _save("01-match-8")
	for layer in [0, 1]:
		for player in main.players:
			for part_name in ["NameLabel", "HpBar", "SoulBar"]:
				(player.get_node(part_name) as CanvasItem).z_index = layer
		await _frames(4)
		await RenderingServer.frame_post_draw
		for index in pair.size():
			var at: Vector2 = (pair[index].name_label as CanvasItem).get_global_transform_with_canvas().origin
			var box := Rect2i(Vector2i(at) + Vector2i(-40, -24), Vector2i(172, 150)).intersection(Rect2i(Vector2i.ZERO, root.size))
			root.get_texture().get_image().get_region(box).save_png(out_dir.path_join("04-layer-%s-%d-%s.png" % ["before" if layer == 0 else "after", index + 1, lang]))
	paused = false
	pair[1].score = 4
	main.director._finish(pair[1], "last survivor")
	await _frames(20)
	await _save("02-results-8")
	main = await _start(16)
	await _frames(60)
	main.director._finish(main._get_human_player(), "last survivor")
	await _frames(20)
	await _save("03-results-16")
	MAIN.session_player_count = 8
	quit()
