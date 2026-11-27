extends SceneTree
## Same fighters told apart by a number after the name (2026-11-27, the lead's pick A of the three
## ways in reports/ui-nine-sixteen-2026-11-27): a name two or more fighters share takes 1, 2, 3 in
## seat order; P1 counts in that order but shows as "P1 Frey" without a number, so its character's
## bots start at 2; a name of its own takes none. The overhead names, the bot panel and its targets,
## the elimination and winner lines, the spectating plate, the ultimate cut-in, the victory title and
## the results (rows, heading, awards) all show the same number, in English and in Korean. P1's
## overhead name is put together from the translated name, so a character without a "P1 <name>"
## string (Xion) reads "P1 시온" in Korean too. The overhead name and bars draw above the
## character's picture, so a tall pose cannot hide the number.

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAIN := preload("res://scripts/Main.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const NAMES := preload("res://scripts/ui/FighterNames.gd")
const CATCHER := preload("res://tests/support/error_catcher.gd")

var failures: Array[String] = []
var catcher := CATCHER.new()

func _initialize() -> void:
	OS.add_logger(catcher)
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _texts(node: Node, into: Array[String]) -> void:
	if node is Label:
		into.append((node as Label).text)
	for child in node.get_children():
		_texts(child, into)

func _run() -> void:
	_rules()
	await _match("en", "frey", 16)
	await _match("ko", "xion", 8)
	MAIN.session_player_count = 8
	LANGUAGE.set_locale("en")
	for line in catcher.take():
		_check(false, "Script or engine error: %s" % line)
	OS.remove_logger(catcher)
	if not failures.is_empty():
		print("Fighter name tests FAILED (%d)" % failures.size())
		quit(1)
		return
	print("Fighter name tests passed (numbers in seat order, P1 unnumbered, every name display, English and Korean)")
	quit(0)

func _fake(script: GDScript, name: String, human := false) -> Node:
	var node := Node.new()
	node.set_script(script)
	node.display_name = name
	node.is_human = human
	root.add_child(node)
	return node

func _plain(fighters: Array) -> Array[String]:
	var names: Array[String] = []
	for fighter in fighters:
		names.append(NAMES.plain(fighter))
	return names

## The rule on its own, with stand-in fighters.
func _rules() -> void:
	var script := GDScript.new()
	script.source_code = "extends Node\nvar display_name := \"\"\nvar is_human := false\n"
	script.reload()
	var made: Array[Node] = []
	var seats: Array = []
	for name in ["Frey", "Luna", "Luna", "Nova", "Nova", "Rio", "Rio", "Yuki"]:
		seats.append(_fake(script, name, seats.is_empty()))
	made.append_array(seats)
	var changed: Array = NAMES.number_doubles(seats)
	var names := _plain(seats)
	_check(names == ["Frey", "Luna 1", "Luna 2", "Nova 1", "Nova 2", "Rio 1", "Rio 2", "Yuki"], "Eight seats: shared names take 1, 2 in seat order and names of their own none (%s)" % [names])
	_check(changed.size() == 6, "The first numbering should report the six numbered fighters (%d)" % changed.size())
	_check(NAMES.number_doubles(seats).is_empty(), "Numbering the same seats again should change nobody")
	# P1's character: P1 counts as 1 but shows no number, so its bots start at 2.
	var mirror: Array = [_fake(script, "Frey", true), _fake(script, "Frey"), _fake(script, "Luna"), _fake(script, "Frey")]
	made.append_array(mirror)
	NAMES.number_doubles(mirror)
	names = _plain(mirror)
	_check(names == ["Frey", "Frey 2", "Luna", "Frey 3"], "P1 should count first and show no number, its bots 2 and 3 (%s)" % [names])
	_check(NAMES.number_of(mirror[0]) == 1, "P1 should hold number 1 behind its plain name (%d)" % NAMES.number_of(mirror[0]))
	# Bots only: the first of a kind is 1.
	var bots: Array = [_fake(script, "Nova"), _fake(script, "Rio"), _fake(script, "Nova")]
	made.append_array(bots)
	NAMES.number_doubles(bots)
	names = _plain(bots)
	_check(names == ["Nova 1", "Rio", "Nova 2"], "Without P1 the first of a kind should be 1 (%s)" % [names])
	# Korean: the translated name with the same number; the plain name stays English.
	LANGUAGE.set_locale("ko")
	_check(NAMES.shown(seats[2]) == "루나 2", "Korean should read 루나 2 (%s)" % NAMES.shown(seats[2]))
	_check(NAMES.shown(mirror[0]) == "프레이", "P1 should read its name alone in Korean (%s)" % NAMES.shown(mirror[0]))
	_check(NAMES.plain(seats[2]) == "Luna 2", "The plain name should stay English in Korean (%s)" % NAMES.plain(seats[2]))
	LANGUAGE.set_locale("en")
	_check(NAMES.shown(seats[2]) == "Luna 2", "English should read Luna 2 (%s)" % NAMES.shown(seats[2]))
	# A fighter that has left is passed over; a monster has no number.
	var gone := _fake(script, "Rio")
	var stays := _fake(script, "Rio")
	made.append(stays)
	gone.free()
	_check(NAMES.number_doubles([gone, stays]).size() == 0 and NAMES.number_of(stays) == 0, "A freed fighter should not count")
	_check(NAMES.shown(gone) == "" and NAMES.plain(gone) == "", "A freed fighter should have no name")
	var beast := GDScript.new()
	beast.source_code = "extends Node\nvar display_name := \"Mossling\"\n"
	beast.reload()
	var monster := Node.new()
	monster.set_script(beast)
	root.add_child(monster)
	made.append(monster)
	_check(NAMES.plain(monster) == "Mossling" and NAMES.suffix(monster) == "", "A monster should keep its name without a number")
	for node in made:
		node.free()

## A real match: every place that shows a fighter's name.
func _match(lang: String, hero: String, count: int) -> void:
	MAIN.session_player_count = count
	seed(4242)
	var main: Node = load(MAIN_SCENE).instantiate()
	root.add_child(main)
	await _frames(5)
	LANGUAGE.set_locale(lang)
	# Everything below is read when it is set: the seats and their names once the match has
	# started (a fighter's setup draws its overhead name at the end of that frame; Main draws the
	# numbered ones again at once), the lines and plates when they are shown, the results when the
	# match ends.
	main._start_match(hero)
	await process_frame
	var where := "%s, %d fighters, P1 %s" % [lang, count, hero]
	var players: Array = main.players
	_check(players.size() == count, "%s: the match should seat %d (%d)" % [where, count, players.size()])
	var totals := {}
	for player in players:
		totals[str(player.display_name)] = int(totals.get(str(player.display_name), 0)) + 1
	var seen := {}
	var numbered: Array = []
	for seat in players.size():
		var player: Node = players[seat]
		var key := str(player.display_name)
		var expected := 0
		if int(totals[key]) > 1:
			expected = int(seen.get(key, 0)) + 1
			seen[key] = expected
		_check(NAMES.number_of(player) == expected, "%s: %s in seat %d should be number %d (%d)" % [where, key, seat + 1, expected, NAMES.number_of(player)])
		var overhead := ("P1 " if player.is_human else "") + NAMES.shown(player)
		_check(player.name_label.text == overhead, "%s: seat %d's overhead name should read %s (%s)" % [where, seat + 1, overhead, player.name_label.text])
		if expected > 0 and not player.is_human:
			numbered.append(player)
			_check(player.name_label.text.ends_with(" %d" % expected), "%s: seat %d's overhead name should end with its number (%s)" % [where, seat + 1, player.name_label.text])
	_check(numbered.size() >= 2, "%s: the match should have numbered bots to look at (%d)" % [where, numbered.size()])
	_check(NAMES.number_doubles(players).is_empty(), "%s: numbering the seats again should change nobody" % where)
	# The overhead name and the HP and soul bars draw above the character's picture (a higher
	# layer, or the same layer and later in order), so a jump or a tall pose never hides a number,
	# and below the effects (layer 2 and up). The lead's check, 2026-11-27.
	for part_name in ["NameLabel", "HpBar", "SoulBar"]:
		for seat in players.size():
			var sprite := players[seat].get_node_or_null("CharacterSprite") as CanvasItem
			var part := players[seat].get_node_or_null(part_name) as CanvasItem
			var above := sprite != null and part != null and (part.z_index > sprite.z_index or (part.z_index == sprite.z_index and part.get_index() > sprite.get_index()))
			if not above or part.z_index >= 2:
				_check(false, "%s: seat %d's %s should draw above its picture and below the effects (layer %d, order %d; picture layer %d, order %d)" % [where, seat + 1, part_name, part.z_index if part != null else -1, part.get_index() if part != null else -1, sprite.z_index if sprite != null else -1, sprite.get_index() if sprite != null else -1])
				break
	var human: Node = main._get_human_player()
	if hero == "frey":
		# Sixteen seats give P1's character two more seats.
		var freys: Array[String] = []
		var want: Array[String] = []
		for player in players:
			if player.character_id == "frey":
				freys.append(player.name_label.text)
				want.append("P1 Frey" if want.is_empty() else "Frey %d" % (want.size() + 1))
		_check(freys.size() >= 2 and freys == want, "%s: P1's character should read P1 Frey, then Frey 2, 3 (%s)" % [where, freys])
	if lang == "ko" and hero == "xion":
		_check(human.name_label.text == "P1 시온", "%s: P1 Xion's overhead name should be Korean (%s)" % [where, human.name_label.text])
	# The bot panel (English) and a bot's target there.
	var rows: Array = main._bot_panel_rows()
	for seat in players.size():
		var player: Node = players[seat]
		var start := ("P1 " if player.is_human else "") + NAMES.plain(player) + "  "
		_check(str(rows[seat].title).begins_with(start), "%s: bot panel row %d should start with %s (%s)" % [where, seat + 1, start, rows[seat].title])
	var victim: Node = numbered[0]
	var killer: Node = numbered[1]
	victim.ai_controller.target = killer
	var plan: Dictionary = victim.ai_controller.debug_snapshot(victim)
	_check(str(plan.target) == NAMES.plain(killer), "%s: the bot panel target should be %s (%s)" % [where, NAMES.plain(killer), plan.target])
	# The elimination line, the spectating plate and the ultimate cut-in.
	main._on_player_defeated(victim, killer)
	var line := tr("%s was eliminated by %s. %d left.") % [NAMES.shown(victim), NAMES.shown(killer), main.director.get_alive_combatants().size()]
	_check(main.hud.info_label.text == line, "%s: the elimination line should read %s (%s)" % [where, line, main.hud.info_label.text])
	main.hud._fill_focus(killer)
	var plate := tr("Spectating") + "  " + NAMES.shown(killer)
	_check(main.hud.focus_name.text == plate, "%s: the spectating plate should read %s (%s)" % [where, plate, main.hud.focus_name.text])
	main.hud._fill_focus(human)
	main.hud.show_ultimate_cutin(killer)
	_check(main.hud.cutin_name.text == NAMES.shown(killer), "%s: the cut-in should read %s (%s)" % [where, NAMES.shown(killer), main.hud.cutin_name.text])
	main.hud.show_ultimate_cutin(human)
	_check(main.hud.cutin_name.text == "P1  " + NAMES.shown(human), "%s: P1's cut-in should read P1 and its name (%s)" % [where, main.hud.cutin_name.text])
	# The winner's line, the victory title and the results.
	var said: Array[String] = []
	main.director.announcement.connect(func(text): said.append(str(text)))
	killer.score = 9
	human.damage_dealt = 999.0
	main.director._finish(killer, "last survivor")
	var wins :=tr("%s wins (%s).") % [NAMES.shown(killer), tr("last survivor")]
	_check(said.has(wins), "%s: the winner's line should read %s (%s)" % [where, wins, said])
	var title := tr("%s WINS") % NAMES.shown(killer).to_upper()
	_check(main.hud.overlay_title.text == title, "%s: the victory title should read %s (%s)" % [where, title, main.hud.overlay_title.text])
	var menu: Control = main.hud.frontend
	var texts: Array[String] = []
	_texts(menu.content, texts)
	_check(texts.has(title), "%s: the results heading should read %s" % [where, title])
	_check(texts.has("%s  /  9" % NAMES.shown(killer)), "%s: the KO award should name %s" % [where, NAMES.shown(killer)])
	# P1 reads as in its row, so it is not taken for one of its bots.
	_check(texts.has("P1 %s  /  999" % NAMES.shown(human)), "%s: the damage award should name P1 %s" % [where, NAMES.shown(human)])
	var grid := menu.content.get_node("Standings") as GridContainer
	var standings: Array = main.director.get_standings()
	for index in standings.size():
		var player: Node = standings[index]
		var cell := grid.get_child((index + 1) * 8 + 2) as Label
		var want := ("P1 " if player == human else "") + NAMES.shown(player)
		_check(cell != null and cell.text == want, "%s: results row %d should read %s (%s)" % [where, index + 1, want, cell.text if cell != null else "no cell"])
	main.queue_free()
	await _frames(3)
