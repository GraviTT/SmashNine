extends SceneTree
## Match HUD layout (pick cup round 2026-11-25-ui, reports/ui-direction-2026-11-25): at 1280 x 720,
## 1470 x 720 and 1280 x 960, in English and Korean, for a fighter with four skill slots and one
## with five, every block of the HUD stays on screen and off the others: the clock and the next
## event, the realm map, three messages, a collapse warning, the player's plate, the skill slots,
## the control hints, the soul card column with the longest cards, practice's lines. No HUD text
## is under 16 px (the bot panel and the debug text are test aids). Faces of fighters off screen
## keep off the plates and each other, the P1 tag rises over a portal's words, the HP number and
## its maximum stay left of the HP bar, and a minimap cell shows its count whole.
## Until 2026-11-26 this held the UI audit's B1, B2 and B7 for the HUD before the pick.

const MAIN_SCENE := "res://scenes/Main.tscn"
const MATCH_HUD := preload("res://scripts/ui/MatchHud.gd")
const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const CARDS := preload("res://scripts/match/SoulCards.gd")
const PRACTICE := preload("res://scripts/practice/PracticeSession.gd")
const WINDOWS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1470, 720), Vector2i(1280, 960)]
const FIGHTERS := {"frey": 4, "rio": 5}
## Main's inset for the faces at the screen edge (Main.OFFSCREEN_MARKER_INSET).
const EDGE := 34.0

var failed := false
var checked := 0

## Realm states for the minimap, without a match.
class FakeDirector extends Node:
	var states: Array[String] = []
	func get_state(index: int) -> String:
		return states[index]
	func get_warning_seconds_left() -> int:
		return 29

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checked += 1
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	LANGUAGE.load_saved()
	var start_locale := TranslationServer.get_locale()
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		for window in WINDOWS:
			for character: String in FIGHTERS:
				await _match_hud(window, character, locale)
	await _minimap_counts()
	LANGUAGE.set_locale(start_locale)
	root.size = WINDOWS[0]
	if not failed:
		print("HUD layout tests passed (%d checks; blocks on screen and apart at 1280x720, 1470x720 and 1280x960 in en/ko with four and five slots, card column and practice lines included; no text under 16 px; faces off the plates and each other; P1 tag over portal words; HP number left of its bar; minimap counts whole)" % checked)
	quit(1 if failed else 0)

func _match_hud(window: Vector2i, character: String, locale: String) -> void:
	root.size = window
	var main: Node = load(MAIN_SCENE).instantiate()
	root.add_child(main)
	for frame in 5:
		await process_frame
	main._start_match(character)
	for frame in 10:
		await process_frame
	# From here the test drives the HUD itself: Main would redraw it every frame. The game pauses
	# (a disabled Main took its bodies out of the physics space, and a timer that runs through
	# pauses once found one there: "body->get_space() is null").
	paused = true
	var hud: Node = main.hud
	var view: Vector2 = root.get_visible_rect().size
	var where := "%s, %s, %dx%d" % [character, locale, window.x, window.y]
	_check(view.is_equal_approx(Vector2(window)), "The test window should be %s (%s)" % [Vector2(window), view])
	var human: Node = main._get_human_player()
	hud.set_status(8, 8, human)
	hud.update_skill_bar(human, 0.016)
	hud.set_clock(tr("Exploration"), 6.0, tr("Corner collapse warning"), 114.0)
	_check_slots(hud, view, character, where)
	_check_hp_number(hud, where)
	_check_font_sizes(hud, where)
	# The match with its news: three long messages and a collapse warning.
	# The news as the game words it (MatchDirector, SoulGrowth, Main), the longest realm list first.
	var realms := ", ".join([tr("Asgard"), tr("Niflheim"), tr("Svartalfheim"), tr("Jotunheim")])
	hud.show_message(tr("Collapse warning: %s will fall in %ds. Reach a safe realm.") % [realms, 30])
	hud.show_message(tr("Soul card: %s%s.") % [tr("Sky Step"), ""])
	hud.show_message(tr("%s was eliminated by %s. %d left.") % [tr("Luna"), tr("Rio"), 6])
	hud.set_warning_banner(29)
	_check(hud.warning_root.visible, "The collapse warning should show (%s)" % where)
	for entry: Dictionary in hud.feed_rows:
		_check_all_lines(entry.row.get_child(2) as Label, 3, "message", where)
	_check_blocks(hud, view, "match with news, " + where)
	await _faces(hud, view, where)
	await _player_tag(main, hud, human, where)
	# The soul card offer with the three cards of longest text.
	hud.show_card_offer(_longest_cards(), 8.0, 8.0)
	_check(hud.card_panel.visible and not hud.controls_label.visible, "The card column should take the corner from the control hints (%s)" % where)
	for label: Label in hud.card_labels:
		_check_all_lines(label, 3, "card", where)
	_check_blocks(hud, view, "card offer, " + where)
	hud.hide_card_offer()
	# Practice's places: its lines over the control hints, the soul row with the cards held.
	hud.set_warning_banner(-1)
	hud.set_practice_layout()
	var lines: Label = hud.build_practice_lines()
	hud.set_practice_lines(tr("Target: %s    Last hit %.1f HP    Total %.1f HP") % ["%s (%s)" % [tr("Fighting bot"), tr("Valkyrie")], 123.4, 1234.5] + "\n" + tr(PRACTICE.KEY_HELP))
	hud.set_practice_status(15, human)
	var font: Font = lines.get_theme_font("font")
	for line in lines.text.split("\n"):
		var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, lines.get_theme_font_size("font_size")).x
		_check(width <= lines.size.x - 24.0 + 0.5, "A practice line should fit its block (%.0f px of %.0f, %s): %s" % [width, lines.size.x - 24.0, where, line])
	_check(lines.text.contains(tr(PRACTICE.KEY_HELP).get_slice("   ", 0)), "The practice block should hold the keys (%s)" % where)
	_check(hud.status_label.visible and hud.status_label.text == tr("Cards held %d") % 15, "The soul row should count the cards held in practice (%s)" % where)
	_check(not hud.alive_label.visible, "Practice's clock should drop the survivors (%s)" % where)
	_check_fits(hud.status_label, "cards held", where)
	_check_blocks(hud, view, "practice, " + where)
	_check_font_sizes(hud, "practice, " + where)
	# Words written straight into the hints and practice's lines (the gamepad's, from outside the
	# HUD) get the same layout at the HUD's next frame.
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	var pad_items := "   ".join(["LB / RB  move", "A  jump", "B  guard", "X  attack", "Y  skill", "RT  ultimate", "Back  portal", "Start  pause"])
	hud.controls_label.text = pad_items
	lines.text = lines.text.get_slice("\n", 0) + "\n" + pad_items
	await process_frame
	hud.process_mode = Node.PROCESS_MODE_INHERIT
	for label: Label in [hud.controls_label, lines]:
		for line in label.text.split("\n"):
			var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, hud.MIN_FONT_SIZE).x
			_check(width <= hud.CARD_WIDTH - 22.0 + 0.5, "A line written from outside should be laid out to fit (%.0f px, %s): %s" % [width, where, line])
	_check(hud.controls_label.text.contains("Start  pause") and lines.text.contains("Start  pause"), "The words written from outside should stay (%s)" % where)
	_check_blocks(hud, view, "gamepad words, " + where)
	paused = false
	main.queue_free()
	await process_frame
	await process_frame

## Every visible skill slot inside its bar, as many as the fighter has.
func _check_slots(hud: Node, view: Vector2, character: String, where: String) -> void:
	var bar: Rect2 = hud.skill_bar.get_global_rect()
	var shown := 0
	for slot: String in hud.SKILL_SLOTS:
		var panel := hud.skill_bar.get_node("SkillSlot%s" % slot.to_upper()) as Control
		if not panel.visible:
			continue
		shown += 1
		var rect := panel.get_global_rect()
		_check(bar.grow(0.5).encloses(rect), "Skill slot %s hangs out of its bar (%s in %s, %s)" % [slot, rect, bar, where])
	_check(shown == int(FIGHTERS[character]), "%s should show %d skill slots, got %d" % [character, FIGHTERS[character], shown])
	_check(Rect2(Vector2.ZERO, view).encloses(bar), "The skill bar should be on screen (%s)" % where)

## The big HP number and "/ max" end before the bar starts (the audit's B7 for the new plate).
func _check_hp_number(hud: Node, where: String) -> void:
	for label: Label in [hud.hp_label, hud.hp_max_label]:
		var width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		_check(label.global_position.x + width <= hud.hp_bar.global_position.x + 0.5, "'%s' runs into the HP bar (%s)" % [label.text, where])
	for label: Label in [hud.focus_name, hud.kos_label, hud.soul_label]:
		_check_fits(label, "player plate", where)

## A wrapped text shows every line it has, at most `most` (no "..." on a line cut short).
func _check_all_lines(label: Label, most: int, what: String, where: String) -> void:
	var count := label.get_line_count()
	_check(count <= most and label.get_visible_line_count() == count, "The %s text shows %d of its %d lines (at most %d, %s): %s" % [what, label.get_visible_line_count(), count, most, where, label.text.replace(String.chr(0x2060), "")])

func _check_fits(label: Label, what: String, where: String) -> void:
	var width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
	_check(width <= label.size.x + 0.5, "The %s text '%s' is cut (%.0f px of %.0f, %s)" % [what, label.text, width, label.size.x, where])

## The HUD's plates on screen, by name.
func _blocks(hud: Node) -> Dictionary:
	var named := {"clock": hud.clock_plate, "next event": hud.next_plate, "warning": hud.warning_plate, "map": hud.minimap_plate, "player": hud.player_root, "skills": hud.skill_bar, "controls": hud.controls_label, "cards": hud.card_panel}
	if hud.practice_label != null:
		named["practice"] = hud.practice_label
	var blocks := {}
	for key: String in named:
		var node: Control = named[key]
		if node.is_visible_in_tree():
			blocks[key] = node.get_global_rect()
	for index in hud.feed_rows.size():
		blocks["message %d" % (index + 1)] = (hud.feed_rows[index].row.get_child(0) as Control).get_global_rect()
	return blocks

func _check_blocks(hud: Node, view: Vector2, where: String) -> void:
	var blocks := _blocks(hud)
	var screen := Rect2(Vector2.ZERO, view)
	var keys := blocks.keys()
	for key: String in keys:
		var rect: Rect2 = blocks[key]
		_check(screen.encloses(rect), "The %s block %s should be on screen (%s)" % [key, rect, where])
	for i in keys.size():
		for j in range(i + 1, keys.size()):
			var a: Rect2 = blocks[keys[i]]
			var b: Rect2 = blocks[keys[j]]
			_check(not a.intersects(b), "The %s block %s and the %s block %s overlap (%s)" % [keys[i], a, keys[j], b, where])

## Every Label of the match HUD at 16 px or more, apart from the test aids and the screens.
func _check_font_sizes(hud: Node, where: String) -> void:
	var skip: Array[Node] = [hud.bot_panel, hud.debug_label, hud.overlay, hud.info_label]
	var small: Array[String] = []
	for label in _labels(hud, skip):
		var size: int = label.get_theme_font_size("font_size")
		if size < hud.MIN_FONT_SIZE:
			small.append("%s (%d px)" % [label.get_path(), size])
	_check(small.is_empty(), "HUD text under %d px (%s): %s" % [hud.MIN_FONT_SIZE, where, ", ".join(small)])

func _labels(node: Node, skip: Array[Node]) -> Array[Label]:
	var found: Array[Label] = []
	for child in node.get_children():
		if skip.has(child):
			continue
		if child is Label:
			found.append(child)
		found.append_array(_labels(child, skip))
	return found

## Faces at the edges, put where Main would put them, on the map, the clock, the player's plate,
## the control hints, the bot panel and each other.
func _faces(hud: Node, view: Vector2, where: String) -> void:
	var points: Array[Vector2] = [
		Vector2(view.x - EDGE, 40), Vector2(view.x - EDGE, 70), Vector2(view.x - EDGE, 120),
		Vector2(view.x - 150, EDGE), Vector2(view.x * 0.5, EDGE),
		Vector2(EDGE, 100), Vector2(EDGE, 104),
		Vector2(300, view.y - EDGE), Vector2(view.x - EDGE, view.y - EDGE),
	]
	var markers: Array = []
	for point in points:
		markers.append({"position": point, "angle": (point - view * 0.5).angle(), "color": Color.WHITE})
	hud.set_offscreen_markers(markers)
	var blocks := _blocks(hud)
	if hud.bot_panel.visible:
		blocks["bot panel"] = hud.bot_panel.get_global_rect()
	var faces: Array[Rect2] = []
	for nodes: Dictionary in hud.offscreen_markers:
		var bubble: Control = nodes.root
		if bubble.visible:
			faces.append(bubble.get_global_rect())
	_check(faces.size() == points.size(), "Every face should show (%d of %d, %s)" % [faces.size(), points.size(), where])
	for index in faces.size():
		var face := faces[index]
		_check(Rect2(Vector2.ZERO, view).encloses(face), "Face %d should be on screen (%s, %s)" % [index + 1, face, where])
		for key: String in blocks:
			_check(not face.intersects(blocks[key]), "Face %d %s sits on the %s block %s (%s)" % [index + 1, face, key, blocks[key], where])
		for other in range(index + 1, faces.size()):
			_check(not face.intersects(faces[other]), "Faces %d and %d overlap (%s)" % [index + 1, other + 1, where])
	hud.set_offscreen_markers([])
	await process_frame

## A portal's words where the P1 tag would be: the tag rises over them.
func _player_tag(main: Node, hud: Node, human: Node, where: String) -> void:
	hud.set_status(8, 8, human)
	_check(hud.player_tag.visible, "The P1 tag should show over the player's fighter (%s)" % where)
	var tag: Rect2 = hud.player_tag.get_global_rect()
	var world := human.get_parent() as CanvasItem
	var words := Label.new()
	words.text = "Q DOWN: Midgard"
	words.size = Vector2(160, 24)
	words.add_theme_font_size_override("font_size", 12)
	words.add_to_group(hud.PORTAL_LABELS)
	world.add_child(words)
	words.position = world.get_global_transform_with_canvas().affine_inverse() * (tag.get_center() + Vector2(-80, 4))
	var xform := words.get_global_transform_with_canvas()
	var spot := Rect2(xform.origin, words.size * xform.get_scale())
	_check(spot.intersects(tag), "Test setup: the words should be under the tag first (%s, %s)" % [spot, tag])
	hud.set_status(8, 8, human)
	var raised: Rect2 = hud.player_tag.get_global_rect()
	_check(not raised.intersects(spot), "The P1 tag %s should rise over a portal's words %s (%s)" % [raised, spot, where])
	_check(raised.position.y < tag.position.y, "The P1 tag should go up, not down (%s)" % where)
	words.queue_free()
	await process_frame

## The three cards whose text is longest in the language on now.
func _longest_cards() -> Array:
	var cards: Array = CARDS.CARDS.duplicate()
	cards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return tr(str(a.text)).length() > tr(str(b.text)).length())
	return cards.slice(0, 3)

## The audit's B2: a cell's count shows whole beside its emblem, in both languages.
func _minimap_counts() -> void:
	root.size = WINDOWS[0]
	var hud: CanvasLayer = MATCH_HUD.new()
	root.add_child(hud)
	var director := FakeDirector.new()
	root.add_child(director)
	await process_frame
	var layout := REALM_LAYOUT.new()
	var counts := {}
	for index in layout.realm_count():
		director.states.append(["stable", "warning", "collapsed", "locked"][index % 4])
		counts[index] = 16
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		hud.rebuild_minimap(layout, director, 0)
		hud.update_minimap_labels(director, counts)
		await process_frame
		var counted := 0
		for index: int in hud.minimap_cells:
			var state := director.states[index]
			var label: Label = hud.minimap_cells[index].count
			if state == "stable" or state == "warning":
				_check(label.text == "16", "A %s cell should show its fighter count (%s: '%s')" % [state, locale, label.text])
				counted += 1
			_check_fits(label, "minimap count", locale)
			_check(label.position.x + label.size.x <= hud.MINIMAP_CELL.x + 0.5, "The count should stay inside its cell (%s)" % locale)
		_check(counted >= 4, "Expected stable and warning cells on the minimap, checked %d" % counted)
	hud.queue_free()
	director.queue_free()
	await process_frame
