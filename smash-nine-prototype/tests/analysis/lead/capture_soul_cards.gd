extends SceneTree
## Soul card captures (D54, 2026-11-26): the offer panel with the new cards and two of the new
## moves, as PNG. Windowed (not --headless). Meant for the exported pack, so that what is seen is
## what the web build holds (a window run from the project folder is not the web build):
##   <godot> --audio-driver Dummy --main-pack <index.pck> -s <absolute path to this file> -- \
##       --lang=ko --out=<absolute dir>
## A script run never reads or writes the real saves (Language skips user:// under -s).

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAIN := preload("res://scripts/Main.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const CARDS := preload("res://scripts/match/SoulCards.gd")

var out_dir := ""
var lang := "ko"
var main: Node
var failed := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):
			lang = arg.get_slice("=", 1)
		elif arg.begins_with("--out="):
			out_dir = arg.get_slice("=", 1)
	if out_dir == "":
		push_error("--out=<dir> is required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _shot(shot_name: String) -> void:
	await _frames(2)
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join("%s_%s.png" % [shot_name, lang])
	if root.get_texture().get_image().save_png(path) != OK:
		failed = true
		push_error("Save capture: " + path)
	print("saved ", shot_name)

func _cards(ids: Array) -> Array:
	var cards: Array = []
	for id in ids:
		cards.append(CARDS.find(str(id)))
	return cards

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Captures must be windowed")
		quit(1)
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	LANGUAGE.set_locale(lang)
	await _frames(4)
	MAIN.human_body = "male"
	MAIN.session_bot_panel = false
	MAIN.next_screen = "title"
	main = load(MAIN_SCENE).instantiate()
	main.match_seed = 4242
	root.add_child(main)
	current_scene = main
	await _frames(6)
	main._start_match("frey")
	await _frames(100)
	var human: Node = main.players[0]
	human.grant_protection(10000.0)
	main.hud.bot_panel_wanted = false
	main.hud.bot_panel.visible = false
	# The first offer as a match gives it: 25 souls.
	human.add_souls(25)
	await _frames(4)
	await _shot("01_first_offer")
	var first: Dictionary = main.soul_growth.get_offer(human)
	print("first offer: ", first.cards.map(func(card: Dictionary) -> String: return str(card.id)), " time ", first.time_left, " of ", first.time_total)
	# Not her own card, so that the second offer still has it to give.
	var pick := 0
	for index in first.cards.size():
		if first.cards[index].kind != "character":
			pick = index
			break
	main.soul_growth.choose(human, pick)
	await _frames(4)
	# The second offer holds her own card (Second Wingbeat).
	human.add_souls(25)
	await _frames(4)
	await _shot("02_second_offer_own_card")
	var second: Dictionary = main.soul_growth.get_offer(human)
	print("second offer: ", second.cards.map(func(card: Dictionary) -> String: return str(card.id)))
	for index in second.cards.size():
		if second.cards[index].kind == "character":
			main.soul_growth.choose(human, index)
			break
	await _frames(4)
	# Every new card on the panel, three at a time (the match stands still meanwhile).
	paused = true
	var rows := [["air_dash", "meteor_landing", "riposte"], ["soul_drain", "last_flame", "chaser"], ["hunter", "overcharge", "second_wingbeat"], ["twin_stars", "deep_gravity", "second_decoy"], ["extended_magazine", "sky_step", "last_stand"]]
	for index in rows.size():
		main.hud.show_card_offer(_cards(rows[index]), 8.0)
		await _shot("0%d_cards_%s" % [index + 3, str(rows[index][0])])
	main.hud.hide_card_offer()
	paused = false
	# Air Dash: in the air, the guard key (here the same call the key makes).
	human.apply_upgrade(CARDS.find("air_dash"))
	await _frames(30)
	human.global_position.y -= 260.0
	human.velocity = Vector2.ZERO
	await _frames(4)
	human.try_air_dash()
	await _frames(5)
	await _shot("08_air_dash")
	# Down to the floor again.
	for frame in 200:
		await physics_frame
		if frame > 6 and human.is_on_floor():
			break
	await _frames(30)
	# Meteor Landing: a landing from 380 px.
	human.apply_upgrade(CARDS.find("meteor_landing"))
	await _frames(30)
	human.global_position.y -= 380.0
	human.velocity = Vector2.ZERO
	# A body just moved still reports the floor it stood on: a few frames before asking.
	for frame in 300:
		await physics_frame
		if frame > 6 and human.is_on_floor():
			break
	await _frames(1)
	await _shot("09_meteor_landing")
	main.queue_free()
	await _frames(3)
	LANGUAGE.set_locale("en")
	print("Soul card captures (%s) in %s" % [lang, out_dir])
	quit(1 if failed else 0)
