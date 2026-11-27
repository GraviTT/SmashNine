extends SceneTree
## Ways to tell the same fighter apart on the results (UI audit 13-6; nine fighters and sixteen-fighter
## matches make doubles common), drawn over the real results of a sixteen-fighter match for a
## comparison only: nothing here is in the game. "now" is the screen as it is; "number" puts a
## number after a doubled name (Nova 1, Nova 2); "stripe" gives each seat a colour, a stripe at its
## row and a ring round its face; "badge" puts the seat's number on a cap at the face's corner.
## Run windowed (the window may stand off screen):
##   <godot> --audio-driver Dummy --position -4000,-4000 --path smash-nine-prototype -s tests/analysis/ui_audit/duplicate_marks_capture.gd -- --out=<dir> [--lang=ko]

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAIN := preload("res://scripts/Main.gd")
const LANGUAGE := preload("res://scripts/Language.gd")

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
	await _frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(out_dir.path_join("%s-%s.jpg" % [stem, lang]), 0.95)

## Sixteen seat colours round the wheel, light and darker by turns.
func _seat_color(seat: int) -> Color:
	return Color.from_hsv(fmod(seat * 0.381966, 1.0), 0.55 if seat % 2 == 0 else 0.75, 0.95 if seat % 2 == 0 else 0.8)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	LANGUAGE.set_locale(lang)
	MAIN.session_player_count = 16
	seed(3001)
	change_scene_to_file(MAIN_SCENE)
	await _frames(10)
	var main: Node = current_scene
	main._start_match("frey")
	await _frames(240)
	var human: Node = main._get_human_player()
	main.director._finish(human, "last survivor")
	await _frames(20)
	var menu: Control = main.hud.frontend
	var standings: Array = main.director.get_standings()
	var grid := menu.content.get_node("Standings") as GridContainer
	await _save("00-now")
	# Rows: eight cells each after the header's eight (#, face, name, KOs, damage, souls, cards, time).
	var rows: Array[Dictionary] = []
	var seen := {}
	for index in standings.size():
		var player: Node = standings[index]
		var face := grid.get_child((index + 1) * 8 + 1) as Control
		var name := grid.get_child((index + 1) * 8 + 2) as Label
		var kind := str(player.character_id)
		seen[kind] = int(seen.get(kind, 0)) + 1
		rows.append({"player": player, "face": face, "name": name, "kind": kind, "nth": seen[kind], "seat": main.players.find(player) + 1, "text": name.text})
	# number: a doubled fighter's name takes its count among its kind.
	for row in rows:
		if int(seen[row.kind]) > 1:
			(row.name as Label).text = "%s %d" % [row.text, row.nth]
	await _save("01-number")
	for row in rows:
		(row.name as Label).text = row.text
	# stripe: each seat's colour at its row's left end and round its face.
	var added: Array[Node] = []
	for row in rows:
		var face: Control = row.face
		var at := face.get_global_rect()
		var stripe := ColorRect.new()
		stripe.color = _seat_color(int(row.seat))
		stripe.position = Vector2(366, at.position.y - 1)
		stripe.size = Vector2(6, at.size.y + 2)
		menu.content.add_child(stripe)
		added.append(stripe)
		var ring := Panel.new()
		var box := StyleBoxFlat.new()
		box.bg_color = Color.TRANSPARENT
		box.border_color = _seat_color(int(row.seat))
		box.set_border_width_all(2)
		box.set_corner_radius_all(4)
		ring.add_theme_stylebox_override("panel", box)
		ring.position = at.position - Vector2(2, 2)
		ring.size = at.size + Vector2(4, 4)
		menu.content.add_child(ring)
		added.append(ring)
	await _save("02-stripe")
	for node in added:
		node.queue_free()
	await _frames(2)
	# badge: the seat's number on a light cap at the face's lower right.
	for row in rows:
		var at := (row.face as Control).get_global_rect()
		var cap := Panel.new()
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.93, 0.95, 0.98, 0.95)
		box.set_corner_radius_all(3)
		cap.add_theme_stylebox_override("panel", box)
		cap.position = at.end - Vector2(9, 12)
		cap.size = Vector2(17, 14)
		var words := Label.new()
		words.text = str(row.seat)
		words.size = cap.size
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		words.add_theme_font_size_override("font_size", 11)
		words.add_theme_color_override("font_color", Color("101827"))
		cap.add_child(words)
		menu.content.add_child(cap)
	await _save("03-badge")
	MAIN.session_player_count = 8
	quit()
