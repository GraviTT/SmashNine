extends SceneTree
## A gamepad from the title to a fight (quality track 3, 2026-11-26), by real pad events
## (InputEventJoypadButton and InputEventJoypadMotion through Input.parse_input_event; no pad is
## plugged in). The menus by D-pad, stick, A, B and Y with one step for one press; the fighter by
## stick, D-pad, buttons and triggers; a stick that does not come back to zero; a little up that
## aims and a full up that jumps; down and A through a thin platform; a soul card by the right
## stick; practice mode's menu and card list; the story's cards, dialogue and pause; the HUD's key
## names; and nothing left pressed across a pause or a reload. -- --only=<part> runs one part.

const MAIN := preload("res://scripts/Main.gd")
const PAD := preload("res://scripts/input/PadInput.gd")
const SESSION := preload("res://scripts/practice/PracticeSession.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const HUD := preload("res://scripts/ui/MatchHud.gd")
const GLYPHS := preload("res://scripts/input/PadGlyphs.gd")
const CATCHER := preload("res://tests/support/error_catcher.gd")
const ACTIONS: Array[String] = ["move_left", "move_right", "move_up", "move_down", "jump", "basic_attack", "skill_1", "skill_2", "skill_3", "ultimate", "guard", "use_portal", "choose_1", "choose_2", "choose_3"]

## Counts the physics frames in which an action was just pressed: what Main and the fighters poll.
class Presses extends Node:
	var counts: Dictionary = {}
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
	func _physics_process(_delta: float) -> void:
		for action in ACTIONS:
			if Input.is_action_just_pressed(action):
				counts[action] = int(counts.get(action, 0)) + 1
	func take(action: String) -> int:
		var count := int(counts.get(action, 0))
		counts.erase(action)
		return count

var failed := false
var checks := 0
var only := ""
var catcher := CATCHER.new()
var presses := Presses.new()

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
	create_timer(420.0, true, false, true).timeout.connect(func() -> void:
		push_error("Gamepad test timed out")
		quit(1))
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	LANGUAGE.set_locale("en")
	SPEED.factor = 1.0
	OS.add_logger(catcher)
	root.add_child(presses)
	var parts := {
		"menus": _test_menus,
		"fighter": _test_fighter,
		"stick": _test_stick,
		"platform": _test_drop_through,
		"cards": _test_soul_card,
		"practice": _test_practice,
		"story": _test_story,
		"labels": _test_labels,
		"glyphs": _test_glyphs_alone,
		"held": _test_nothing_stays_pressed,
	}
	for part: String in parts:
		if only == "" or only == part:
			var done = await parts[part].call()
			_check(done == true, "The part '%s' did not run to its end" % part)
			for line in catcher.take():
				_check(false, "The engine logged an error in the part '%s': %s" % [part, line])
			_release_pad()
			await _frames(3)
	OS.remove_logger(catcher)
	if failed:
		quit(1)
		return
	print("Gamepad tests passed (%d checks; menus, fighter, stick, thin platform, soul card, practice, story, HUD names, nothing left pressed)" % checks)
	quit(0)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

# --- The pad ---

func _button(index: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = index as JoyButton
	event.pressed = pressed
	event.pressure = 1.0 if pressed else 0.0
	Input.parse_input_event(event)

func _tap(index: int, held := 2) -> void:
	_button(index, true)
	await _frames(held)
	_button(index, false)
	await _frames(2)

func _axis(axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis as JoyAxis
	event.axis_value = value
	Input.parse_input_event(event)

## A flick of a stick axis: out and back.
func _flick(axis: int, value: float) -> void:
	_axis(axis, value)
	await _frames(2)
	_axis(axis, 0.0)
	await _frames(2)

## Everything on the pad let go, as a hand off it would leave it.
func _release_pad() -> void:
	for index in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_BACK, JOY_BUTTON_START, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
		_button(index, false)
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y, JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
		_axis(axis, 0.0)

func _key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code as Key
	event.keycode = code as Key
	event.pressed = pressed
	Input.parse_input_event(event)

# --- Scenes ---

func _scene(screen: String, character_id := "frey") -> Node:
	_release_pad()
	PAD.reset()
	GLYPHS.pad_in_use = false
	MAIN.next_screen = screen
	MAIN.session_mode = "battle_royale"
	MAIN.last_character_id = character_id
	MAIN.human_body = "male"
	MAIN.session_player_count = 8
	SESSION.bot_id = "frey"
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(8)
	var main: Node = current_scene
	if screen == "practice":
		await _frames(30)
	presses.counts.clear()
	return main

## The words of a text, without the spaces and line breaks a layout puts between them.
func _words(text: String) -> String:
	return RegEx.create_from_string("\\s+").sub(text, " ", true).strip_edges()

## A label on screen with its words inside it (a HUD may break them into lines).
func _fits(label: Label) -> bool:
	var rect := label.get_global_rect()
	var screen := Rect2(Vector2.ZERO, Vector2(root.size))
	var lines := maxi(label.get_line_count(), 1)
	var font: Font = label.get_theme_font("font")
	var widest := 0.0
	for line in label.text.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x)
	return screen.encloses(rect) and (widest <= rect.size.x + 0.5 or label.autowrap_mode != TextServer.AUTOWRAP_OFF) and lines * label.get_line_height() <= rect.size.y + 0.5

func _has_text(node: Node, expected: String) -> bool:
	if (node is Label or node is Button) and node.visible and str(node.text).contains(expected):
		return true
	for child in node.get_children():
		if _has_text(child, expected):
			return true
	return false

# --- Parts ---

## The title, the select screen and the options by pad: one press, one step; then a match.
func _test_menus() -> bool:
	var main: Node = await _scene("title")
	var menu: Control = main.hud.frontend
	_check(menu.focus_index == 0 and main.pad_context() == "menu", "The title should start on its first row, the pad in menu use")
	await _tap(JOY_BUTTON_DPAD_DOWN)
	_check(menu.focus_index == 1, "D-pad down should move one row (row %d)" % menu.focus_index)
	await _flick(JOY_AXIS_LEFT_Y, 0.9)
	_check(menu.focus_index == 2, "The stick down should move one row (row %d)" % menu.focus_index)
	await _flick(JOY_AXIS_LEFT_Y, -0.9)
	await _tap(JOY_BUTTON_DPAD_UP)
	_check(menu.focus_index == 0, "Up twice should come back to the first row (row %d)" % menu.focus_index)
	# Options: A on a row changes it one step, not two (the engine's own pad handling is kept out).
	for step in 4:
		await _tap(JOY_BUTTON_DPAD_DOWN)
	await _tap(JOY_BUTTON_A)
	_check(menu.screen == "options", "A on the fifth row should open Options (%s)" % menu.screen)
	for step in 2:
		await _tap(JOY_BUTTON_DPAD_DOWN)
	var count: int = main.player_count
	await _tap(JOY_BUTTON_A)
	_check(main.player_count == 4 and count == 8, "A on Fighters should change it one step, 8 to 4 (%d -> %d)" % [count, main.player_count])
	await _tap(JOY_BUTTON_A)
	await _tap(JOY_BUTTON_A)
	_check(main.player_count == 8, "Two more presses should bring Fighters back to 8 (%d)" % main.player_count)
	await _tap(JOY_BUTTON_B)
	_check(menu.screen == "title", "B should go back to the title (%s)" % menu.screen)
	# The select screen: the stick browses, Y changes the body, A starts.
	await _tap(JOY_BUTTON_A)
	_check(menu.screen == "select" and not main.match_started, "A on Battle Royale should open the select screen, and only that")
	_check(menu.selected_id == "frey", "Test setup: the select screen should open on Frey (%s)" % menu.selected_id)
	await _flick(JOY_AXIS_LEFT_X, 0.9)
	_check(menu.selected_id == "yuki", "The stick right should step to the next fighter, one step (%s)" % menu.selected_id)
	await _flick(JOY_AXIS_LEFT_X, -0.9)
	await _tap(JOY_BUTTON_DPAD_DOWN)
	_check(menu.selected_id == "nova", "D-pad down from Frey should reach Nova below (%s)" % menu.selected_id)
	_check(main.pad.active, "Menu presses should keep the pad the device in use (the keys it sends are its own)")
	# The game's own wait for a first press before sound (on the web): a pad's press counts.
	var sound: Node = root.get_node_or_null("AudioManager")
	if sound != null:
		sound.unlocked = false
		await _tap(JOY_BUTTON_DPAD_UP)
		await _tap(JOY_BUTTON_DPAD_DOWN)
		_check(bool(sound.unlocked), "A pad press should open the game's wait for a first press before sound")
	else:
		_check(false, "Test setup: the AudioManager should be there")
	# The line a web page shows when a pad was the first press: worded, at the foot, then gone.
	var notice: Label = main.pad.show_sound_notice()
	await _frames(2)
	_check(notice.is_visible_in_tree() and notice.text == tr(PAD.SOUND_NOTICE) and notice.get_global_rect().end.y <= 720.0 and notice.get_global_rect().position.y >= 600.0, "The sound line should show at the foot of the screen (%s)" % notice.get_global_rect())
	PAD.sound_notice_shown = false
	var body: String = main.human_body
	await _tap(JOY_BUTTON_Y)
	_check(main.human_body != body, "Y should change the body (%s -> %s)" % [body, main.human_body])
	await _tap(JOY_BUTTON_Y)
	await _tap(JOY_BUTTON_A)
	await _frames(6)
	_check(main.match_started and not main.bots_only and main.players[0].character_id == "nova" and main.players[0].is_human, "A on a fighter should start the match with it")
	_check(main.pad_context() == "play", "In a match the pad should be the fighter's")
	_check(not main.players[0].is_on_floor() or float(main.players[0].velocity.y) >= 0.0, "The A that started the match should not also jump")
	return true

## Every control of the fighter, in practice mode's quiet realm.
func _test_fighter() -> bool:
	var main: Node = await _scene("practice", "rio")
	var hero: Node = main.practice_session.hero
	var start: float = hero.global_position.x
	_axis(JOY_AXIS_LEFT_X, 0.9)
	await _frames(20)
	_check(hero.global_position.x > start + 30.0 and is_equal_approx(Input.get_axis("move_left", "move_right"), 1.0), "The stick right should walk right (%.0f px)" % (hero.global_position.x - start))
	_axis(JOY_AXIS_LEFT_X, 0.0)
	await _frames(20)
	var rest: float = hero.global_position.x
	await _frames(10)
	_check(absf(hero.global_position.x - rest) < 1.0, "The stick let go should stop the fighter")
	_button(JOY_BUTTON_DPAD_LEFT, true)
	await _frames(20)
	_button(JOY_BUTTON_DPAD_LEFT, false)
	_check(hero.global_position.x < rest - 30.0 and hero.facing == -1, "D-pad left should walk left and turn the fighter")
	await _frames(20)
	# A jumps; D-pad up jumps (as W does).
	for index in [JOY_BUTTON_A, JOY_BUTTON_DPAD_UP]:
		_button(index, true)
		var rose := false
		for frame in 12:
			await physics_frame
			if not hero.is_on_floor() and hero.velocity.y < 0.0:
				rose = true
		_button(index, false)
		_check(rose, "Button %d should jump" % index)
		for frame in 90:
			await physics_frame
			if hero.is_on_floor():
				break
		await _frames(6)
	# The four moves and the ultimate.
	for entry in [[JOY_BUTTON_X, "j"], [JOY_BUTTON_Y, "k"], [JOY_BUTTON_B, "l"], [JOY_BUTTON_RIGHT_SHOULDER, "u"]]:
		main.practice_session.reset_positions(true)
		await _frames(20)
		var before := float(hero.move_counts.get(entry[1], 0.0))
		await _tap(int(entry[0]))
		await _frames(4)
		_check(float(hero.move_counts.get(entry[1], 0.0)) == before + 1.0, "Button %d should use the %s move once (%.0f -> %.0f)" % [entry[0], str(entry[1]).to_upper(), before, hero.move_counts.get(entry[1], 0.0)])
		await _frames(50)
	main.practice_session.reset_positions(true)
	await _frames(20)
	_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _frames(3)
	_check(not hero.is_ultimate_ready() and Input.is_action_pressed("ultimate"), "The right trigger should start the ultimate and hold its action")
	_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _frames(3)
	_check(not Input.is_action_pressed("ultimate"), "The trigger let go should release the ultimate's action")
	main.practice_session.reset_positions(true)
	await _frames(20)
	# Guard while LB is held.
	_button(JOY_BUTTON_LEFT_SHOULDER, true)
	await _frames(4)
	_check(bool(hero.is_guarding), "LB should raise the guard")
	_button(JOY_BUTTON_LEFT_SHOULDER, false)
	await _frames(4)
	_check(not bool(hero.is_guarding), "LB let go should lower the guard")
	# The left trigger is the portal key; the right stick, the three cards. Each press is one press.
	presses.counts.clear()
	_axis(JOY_AXIS_TRIGGER_LEFT, 0.9)
	await _frames(3)
	_axis(JOY_AXIS_TRIGGER_LEFT, 0.6)
	await _frames(3)
	_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	await _frames(3)
	_check(presses.take("use_portal") == 1, "The left trigger should press the portal key once")
	for entry in [[JOY_AXIS_RIGHT_X, -0.9, "choose_1"], [JOY_AXIS_RIGHT_Y, -0.9, "choose_2"], [JOY_AXIS_RIGHT_X, 0.9, "choose_3"]]:
		await _flick(int(entry[0]), float(entry[1]))
		_check(presses.take(str(entry[2])) == 1 and presses.counts.is_empty(), "The right stick should press %s once and nothing else (%s)" % [entry[2], presses.counts])
		presses.counts.clear()
	_axis(JOY_AXIS_RIGHT_Y, 0.9)
	await _frames(3)
	_axis(JOY_AXIS_RIGHT_Y, 0.0)
	await _frames(3)
	_check(presses.counts.is_empty(), "The right stick down should press nothing (%s)" % [presses.counts])
	# Keyboard and pad together: one letting go does not let go for the other.
	_key(KEY_D, true)
	_axis(JOY_AXIS_LEFT_X, 0.9)
	await _frames(4)
	_axis(JOY_AXIS_LEFT_X, 0.0)
	await _frames(4)
	_check(Input.is_action_pressed("move_right"), "The stick let go should not release what the keyboard still holds")
	_key(KEY_D, false)
	await _frames(4)
	_check(not Input.is_action_pressed("move_right"), "The key let go should release the action")
	return true

## The analog stick: one dead zone, a stick that rests off zero, a little up and a full up.
func _test_stick() -> bool:
	var main: Node = await _scene("practice", "frey")
	var hero: Node = main.practice_session.hero
	var pad: Node = main.pad
	_check(is_equal_approx(pad.DEADZONE, 0.3) and pad.JUMP_TILT >= 0.75, "Test setup: the dead zone is 0.3 and a jump takes the stick at least 0.75 up")
	# A worn stick: it rests off zero and shivers there.
	var place: Vector2 = hero.global_position
	presses.counts.clear()
	for frame in 60:
		_axis(JOY_AXIS_LEFT_X, [0.12, 0.18, 0.15, 0.2][frame % 4])
		_axis(JOY_AXIS_LEFT_Y, [-0.14, -0.19, 0.08, -0.22][frame % 4])
		_axis(JOY_AXIS_RIGHT_X, [0.2, 0.25][frame % 2])
		_axis(JOY_AXIS_TRIGGER_RIGHT, 0.1)
		await physics_frame
	await _frames(2)
	_check(hero.global_position.distance_to(place) < 1.0 and presses.counts.is_empty(), "A stick that rests off zero should press nothing and move nobody (%s, %.1f px)" % [presses.counts, hero.global_position.distance_to(place)])
	_check(hero.is_ultimate_ready(), "A trigger that rests off zero should not fire the ultimate")
	# Pressed past the dead zone, let go under a lower value: no flutter at the edge.
	_axis(JOY_AXIS_LEFT_X, 0.28)
	await _frames(2)
	_check(not Input.is_action_pressed("move_right"), "Under the dead zone nothing is pressed")
	_axis(JOY_AXIS_LEFT_X, 0.35)
	await _frames(2)
	_check(Input.is_action_pressed("move_right"), "Past the dead zone the direction is pressed")
	_axis(JOY_AXIS_LEFT_X, 0.25)
	await _frames(2)
	_check(Input.is_action_pressed("move_right"), "Just under the dead zone the direction is still held")
	_axis(JOY_AXIS_LEFT_X, 0.1)
	await _frames(2)
	_check(not Input.is_action_pressed("move_right"), "Well under it the direction is let go")
	main.practice_session.reset_positions(true)
	await _frames(20)
	# A little up: aim up, feet on the floor. Diagonal too.
	presses.counts.clear()
	_axis(JOY_AXIS_LEFT_Y, -0.5)
	await _frames(12)
	_check(hero.is_on_floor() and presses.take("jump") == 0 and Input.is_action_pressed("move_up"), "The stick a little up should aim up without a jump")
	_check(hero._get_basic_attack_type(hero._get_attack_direction()) == "up", "J with the stick a little up should be the up attack (%s)" % hero._get_basic_attack_type(hero._get_attack_direction()))
	_axis(JOY_AXIS_LEFT_X, 0.7)
	_axis(JOY_AXIS_LEFT_Y, -0.7)
	await _frames(12)
	_check(presses.take("jump") == 0 and hero._get_attack_direction().y < -0.45, "A diagonal up should aim up without a jump")
	# Pushed all the way up: a jump, once.
	_axis(JOY_AXIS_LEFT_X, 0.0)
	_axis(JOY_AXIS_LEFT_Y, -1.0)
	var rose := false
	for frame in 12:
		await physics_frame
		if not hero.is_on_floor() and hero.velocity.y < 0.0:
			rose = true
	_check(rose and presses.take("jump") == 1, "The stick pushed all the way up should jump, once")
	_axis(JOY_AXIS_LEFT_Y, 0.0)
	return true

## Down and A on a thin platform: through it. A alone: up.
func _test_drop_through() -> bool:
	var main: Node = await _scene("practice", "frey")
	var hero: Node = main.practice_session.hero
	var thin := Rect2()
	for rect: Rect2 in main.layout.get_platform_rects(main.CENTRAL_REALM_INDEX):
		hero.global_position = Vector2(rect.get_center().x, rect.position.y - 4.0)
		hero.velocity = Vector2.ZERO
		await _frames(12)
		if hero.is_on_floor() and hero._platform_allows_drop_through(hero.current_floor_platform):
			thin = rect
			break
	if thin.size == Vector2.ZERO:
		_check(false, "Test setup: the central realm should have a thin platform to stand on")
		return false
	var height: float = hero.global_position.y
	await _tap(JOY_BUTTON_A)
	var rose := false
	for frame in 10:
		await physics_frame
		rose = rose or hero.global_position.y < height - 10.0
	_check(rose, "A alone should jump from a thin platform")
	hero.global_position = Vector2(thin.get_center().x, thin.position.y - 4.0)
	hero.velocity = Vector2.ZERO
	await _frames(14)
	_axis(JOY_AXIS_LEFT_Y, 0.9)
	await _frames(3)
	presses.counts.clear()
	_button(JOY_BUTTON_A, true)
	var fell := false
	for frame in 20:
		await physics_frame
		fell = fell or hero.global_position.y > height + 20.0
	_button(JOY_BUTTON_A, false)
	_axis(JOY_AXIS_LEFT_Y, 0.0)
	_check(fell and presses.take("jump") == 0, "Down and A should drop through a thin platform without a jump (y %.0f -> %.0f)" % [height, hero.global_position.y])
	# On the realm's main floor down and A is a plain jump.
	main.practice_session.reset_positions(true)
	await _frames(24)
	height = hero.global_position.y
	_axis(JOY_AXIS_LEFT_Y, 0.9)
	await _frames(3)
	_button(JOY_BUTTON_A, true)
	rose = false
	for frame in 10:
		await physics_frame
		rose = rose or hero.global_position.y < height - 10.0
	_button(JOY_BUTTON_A, false)
	_axis(JOY_AXIS_LEFT_Y, 0.0)
	_check(rose, "Down and A on the main floor should jump (there is nothing to drop through)")
	return true

## A soul card in a real match: the right stick takes the card on that side.
func _test_soul_card() -> bool:
	var main: Node = await _scene("rematch", "frey")
	var hero: Node = main.players[0]
	_check(main.match_started and hero.is_human, "Test setup: a match as Frey")
	await _frames(20)
	hero.add_souls(25)
	await _frames(4)
	var offer: Dictionary = main.soul_growth.get_offer(hero)
	if offer.is_empty():
		_check(false, "Test setup: 25 souls should open a soul card offer")
		return false
	var third: String = str(offer.cards[2].id)
	await _flick(JOY_AXIS_RIGHT_X, 0.9)
	await _frames(2)
	_check(hero.upgrades == [third], "The right stick to the right should take the third card (%s, wanted %s)" % [hero.upgrades, third])
	return true

## Practice mode: Start or Back opens its menu; the stick and A pick a row; the card list by pad.
func _test_practice() -> bool:
	var main: Node = await _scene("practice", "frey")
	var session: Node = main.practice_session
	var hero: Node = session.hero
	_axis(JOY_AXIS_LEFT_X, 0.9)
	await _frames(60)
	var walked: float = hero.global_position.x
	_check(walked > session._start_point(session.HERO_SPAWN).x + 150.0, "Test setup: the fighter should have walked well off its start place")
	await _tap(JOY_BUTTON_START)
	_check(session.panel == "menu" and paused and session.skills_panel.visible and _has_text(session.skills_panel, "Practice menu"), "Start should open the practice menu and pause the game")
	_check(main.pad_context() == "menu" and not Input.is_action_pressed("move_right"), "With the menu open the stick still pushed right should hold no action")
	await _tap(JOY_BUTTON_DPAD_DOWN)
	await _tap(JOY_BUTTON_DPAD_DOWN)
	_check(session.menu_index == 2, "D-pad down twice should reach the third row (row %d)" % session.menu_index)
	await _tap(JOY_BUTTON_A)
	await _frames(2)
	_check(session.panel == "" and not paused, "A on a row should close the menu")
	_check(Input.is_action_pressed("move_right"), "Back in play the stick still pushed right should walk again")
	_axis(JOY_AXIS_LEFT_X, 0.0)
	await _frames(2)
	# The stick still pushed walked it a few frames on from where Reset put it.
	var from_start: float = hero.global_position.x - session._start_point(session.HERO_SPAWN).x
	_check(hero.global_position.x < walked - 100.0 and from_start > -5.0 and from_start < 80.0, "The third row is Reset: the fighter should be back by its start place (%.0f px from it, %.0f px back from where it had walked)" % [from_start, walked - hero.global_position.x])
	# Back opens it too; B closes it.
	await _tap(JOY_BUTTON_BACK)
	_check(session.panel == "menu" and session.menu_index == 0, "Back should open the practice menu at its first row")
	await _tap(JOY_BUTTON_A)
	_check(session.panel == "" and session.mode == "walk", "The first row should change the target (%s)" % session.mode)
	await _tap(JOY_BUTTON_START)
	await _tap(JOY_BUTTON_B)
	_check(session.panel == "" and not paused and current_scene == main, "B should close the menu and stay in practice")
	await _tap(JOY_BUTTON_START)
	_check(session.panel == "menu", "Start should open the menu again")
	await _tap(JOY_BUTTON_START)
	_check(session.panel == "" and not paused and session.mode == "walk", "Start again should close the menu and do nothing else")
	# The card list: stick up in the menu wraps to the last rows; right stick takes a card.
	await _tap(JOY_BUTTON_START)
	for step in 5:
		await _flick(JOY_AXIS_LEFT_Y, 0.9)
	await _tap(JOY_BUTTON_A)
	_check(session.panel == "cards" and main.pad_context() == "cards" and main.hud.card_panel.visible, "The sixth row should open the card list")
	var list: Array[Dictionary] = session.card_list()
	await _flick(JOY_AXIS_RIGHT_Y, -0.9)
	_check(hero.upgrades == [str(list[1].id)], "The right stick up should take the middle card (%s)" % [hero.upgrades])
	await _tap(JOY_BUTTON_DPAD_RIGHT)
	_check(session.card_page == 1, "D-pad right should turn the page (%d)" % session.card_page)
	await _flick(JOY_AXIS_LEFT_X, -0.9)
	_check(session.card_page == 0, "The stick left should turn it back (%d)" % session.card_page)
	await _flick(JOY_AXIS_RIGHT_X, -0.9)
	_check(hero.upgrades.size() == 2 and hero.upgrades[1] == str(list[0].id), "The right stick left should take the first card (%s)" % [hero.upgrades])
	await _tap(JOY_BUTTON_B)
	_check(session.panel == "" and not paused, "B should close the card list")
	# The last row leaves; nothing of the pad stays pressed after the reload.
	_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_button(JOY_BUTTON_LEFT_SHOULDER, true)
	await _frames(3)
	_check(Input.is_action_pressed("ultimate") and Input.is_action_pressed("guard"), "Test setup: the trigger and LB should be held")
	await _tap(JOY_BUTTON_START)
	await _tap(JOY_BUTTON_DPAD_UP)
	_check(session.menu_index == session.MENU_ROWS.size() - 1, "Up from the first row should reach the last (row %d)" % session.menu_index)
	await _tap(JOY_BUTTON_A)
	await _frames(8)
	main = current_scene
	_check(not main.match_started and main.hud.frontend.screen == "title", "The last row should leave practice for the title")
	for action in ACTIONS:
		_check(not Input.is_action_pressed(action), "Nothing should stay pressed after leaving (%s)" % action)
	return true

## The story by pad: the stage card and the dialogue with A, the pause with Start.
func _test_story() -> bool:
	_release_pad()
	PAD.reset()
	PROGRESS.runs.clear()
	PROGRESS.new_journey("frey", "normal")
	MAIN.story_hero = "frey"
	MAIN.story_stage = 1
	MAIN.story_difficulty = "normal"
	MAIN.story_art_state = {}
	MAIN.next_screen = "story_stage"
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(8)
	var main: Node = current_scene
	if not is_instance_valid(main.story_session):
		_check(false, "Test setup: the first story stage should start")
		return false
	var story: Node = main.story_session
	_check(story.phase == "start" and main.pad_context() == "menu", "A story stage opens on its card, the pad in menu use")
	await _tap(JOY_BUTTON_A)
	_check(story.phase == "pre" and story.dialogue.visible, "A should go from the stage card to the dialogue (%s)" % story.phase)
	# As with J: a line still being written is shown whole first, then A goes on. A press that
	# counted twice (the pad and the GUI's own pad handling) would do both at once.
	var dialogue: Node = story.dialogue
	var line: int = dialogue.line_index
	var typing: bool = dialogue.line_label.visible_characters >= 0 and dialogue.line_label.visible_characters < dialogue.line_label.get_total_character_count()
	await _tap(JOY_BUTTON_A)
	if typing:
		var shown: int = dialogue.line_label.visible_characters
		_check(dialogue.line_index == line and (shown == -1 or shown >= dialogue.line_label.get_total_character_count()), "A on a line still being written should show it whole, and only that (line %d -> %d)" % [line, dialogue.line_index])
		await _tap(JOY_BUTTON_A)
	_check(dialogue.line_index == line + 1 or story.phase != "pre", "A on a whole line should go to the next, one line a press (%d -> %d)" % [line, dialogue.line_index])
	for press in 40:
		if story.phase == "combat":
			break
		await _tap(JOY_BUTTON_A)
	_check(story.phase == "combat" and main.pad_context() == "play", "The dialogue should end in the fight, the pad the fighter's")
	await _frames(6)
	_check(story.hero.is_on_floor() or story.hero.velocity.y >= 0.0, "The A that ended the dialogue should not also jump")
	await _tap(JOY_BUTTON_START)
	_check(paused and main.hud.frontend.screen == "story_pause", "Start should pause the story stage")
	await _tap(JOY_BUTTON_A)
	_check(not paused and story.phase == "combat", "A on Resume should go on with the stage")
	await _tap(JOY_BUTTON_START)
	await _tap(JOY_BUTTON_B)
	_check(not paused, "B should resume too (Esc does)")
	await _tap(JOY_BUTTON_START)
	await _tap(JOY_BUTTON_START)
	_check(not paused and story.phase == "combat", "Start should pause and Start again resume")
	MAIN.session_mode = "battle_royale"
	PROGRESS.runs.clear()
	return true

## The HUD names a pad's buttons while a pad is in use, and the keys again at the next key.
func _test_labels() -> bool:
	var main: Node = await _scene("practice", "rio")
	var hud: Node = main.hud
	await _frames(10)
	_key(KEY_F3, true)
	await _frames(2)
	_key(KEY_F3, false)
	await _frames(2)
	_check(not main.pad.active and hud.skill_slots["j"].key.text == "J" and _words(hud.controls_label.text) == _words(tr(HUD.CONTROLS_SHORT)), "With the keyboard the HUD should name the keys")
	_check(main.practice_session.info.text.contains("H target"), "With the keyboard the practice lines should list the keys")
	await _tap(JOY_BUTTON_LEFT_SHOULDER)
	await _frames(3)
	_check(main.pad.active, "A pad button should make the pad the device in use")
	var names := {"j": "X", "k": "Y", "l": "B", "u": "RB", "i": "RT"}
	_check(GLYPHS.SLOT_NAMES == names, "The names on the skill bar are X, Y, B, RB, RT (%s)" % [GLYPHS.SLOT_NAMES])
	# The names follow the layout: the button a slot is named after presses that slot's action.
	var buttons := {"X": JOY_BUTTON_X, "Y": JOY_BUTTON_Y, "B": JOY_BUTTON_B, "RB": JOY_BUTTON_RIGHT_SHOULDER}
	for slot: String in names:
		var action: String = GLYPHS.SLOT_ACTIONS[slot]
		if buttons.has(names[slot]):
			_check(PAD.PLAY_BUTTONS.get(buttons[names[slot]], "") == action, "%s should be the button of %s in PadInput's layout" % [names[slot], action])
		else:
			_check(PAD.PLAY_TRIGGERS.get(JOY_AXIS_TRIGGER_RIGHT, "") == action, "RT should be the trigger of %s in PadInput's layout" % action)
	for slot: String in names:
		_check(hud.skill_slots[slot].key.text == names[slot] and hud.skill_slots[slot].glyph.text == names[slot], "The %s slot should read %s with a pad (%s)" % [slot.to_upper(), names[slot], hud.skill_slots[slot].key.text])
		var badge: Label = hud.skill_slots[slot].key
		var width := badge.get_theme_font("font").get_string_size(badge.text, HORIZONTAL_ALIGNMENT_LEFT, -1, badge.get_theme_font_size("font_size")).x
		var slot_rect: Rect2 = (badge.get_parent() as Control).get_global_rect()
		_check(width <= badge.size.x and _fits(badge) and slot_rect.grow(30.0).encloses(badge.get_global_rect()), "The %s badge should hold its name, by its slot (%.0f px in %.0f)" % [slot.to_upper(), width, badge.size.x])
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		GLYPHS.apply(hud, false)
		GLYPHS.apply(hud, true)
		await _frames(2)
		await _frames(2)
		_check(_words(hud.controls_label.text) == _words(tr(GLYPHS.CONTROLS_PAD)) and (locale == "en" or _words(hud.controls_label.text) != _words(GLYPHS.CONTROLS_PAD)), "The hint line should be the pad's (%s): %s" % [locale, hud.controls_label.text])
		var line_width := ThemeDB.fallback_font.get_string_size(hud.controls_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		_check(_fits(hud.controls_label) and not hud.controls_label.get_global_rect().intersects(hud.skill_bar.get_global_rect()) and line_width > 0.0, "The pad's line should fit and keep the skill bar's right edge (%s, %.0f px in %.0f)" % [locale, line_width, hud.controls_label.size.x])
		await _frames(2)
		_check(main.practice_session.info.text.contains(tr(GLYPHS.PRACTICE_PAD)) and not main.practice_session.info.text.contains("H "), "With a pad the practice lines should name the menu button instead of the keys (%s): %s" % [locale, main.practice_session.info.text])
	LANGUAGE.set_locale("en")
	_key(KEY_F3, true)
	await _frames(2)
	_key(KEY_F3, false)
	await _frames(2)
	_check(not main.pad.active and hud.skill_slots["i"].key.text == "I" and _words(hud.controls_label.text) == _words(tr(HUD.CONTROLS_SHORT)), "A key should bring the keyboard's names back")
	_check(_fits(hud.controls_label) and not hud.controls_label.get_global_rect().intersects(hud.skill_bar.get_global_rect()), "The keyboard's line should fit again, clear of the skill bar")
	return true

## The names written into a HUD that lacks some of the labels (the hint line may go), or rewrites
## them on its own update.
func _test_glyphs_alone() -> bool:
	var script := GDScript.new()
	script.source_code = "extends CanvasLayer\nvar skill_slots := {}\nvar controls_label: Label\nvar laid_out := 0\n"
	script.reload()
	var fake := CanvasLayer.new()
	fake.set_script(script)
	root.add_child(fake)
	# No slots, no hint line.
	GLYPHS.apply(fake, true)
	GLYPHS.apply(fake, false)
	# Slots in part, a hint line hidden.
	var key := Label.new()
	key.text = "K"
	key.size = Vector2(16, 16)
	fake.add_child(key)
	fake.skill_slots = {"k": {"key": key}, "j": "not a slot"}
	var hint := Label.new()
	hint.text = "A/D move"
	hint.visible = false
	fake.add_child(hint)
	fake.controls_label = hint
	GLYPHS.apply(fake, true)
	_check(key.text == "Y" and hint.text == tr(GLYPHS.CONTROLS_PAD), "A pad's names should go on the labels there are (%s, %s)" % [key.text, hint.text])
	# The HUD rewrites both on its own update: applied again, the pad's names are back on top.
	key.text = "K"
	hint.text = "A/D move   W jump"
	GLYPHS.apply(fake, true)
	_check(key.text == "Y" and hint.text == tr(GLYPHS.CONTROLS_PAD), "Applied after the HUD's update, the pad's names should be back (%s, %s)" % [key.text, hint.text])
	GLYPHS.apply(fake, false)
	_check(key.text == "K" and hint.text == "A/D move   W jump", "With the keyboard, the HUD's latest text should come back (%s, %s)" % [key.text, hint.text])
	# A HUD text that is neither is left alone.
	hint.text = "something else"
	GLYPHS.apply(fake, false)
	_check(hint.text == "something else", "With the keyboard the HUD's own text should be left alone")
	# A HUD that lays the line out itself: PadGlyphs goes through set_control_hints, and the line
	# broken where three spaces are is the same words, not new ones (no back and forth over frames).
	var laid := GDScript.new()
	laid.source_code = "extends CanvasLayer\nvar skill_slots := {}\nvar controls_label: Label\nvar laid_out := 0\nfunc set_control_hints(text: String) -> void:\n\tlaid_out += 1\n\tcontrols_label.text = text.replace(\"   \", \"\\n\")\n"
	laid.reload()
	var other := CanvasLayer.new()
	other.set_script(laid)
	root.add_child(other)
	var line := Label.new()
	line.text = "A/D move   W jump"
	other.add_child(line)
	other.controls_label = line
	for frame in 5:
		GLYPHS.apply(other, true)
	_check(other.laid_out == 1 and _words(line.text) == _words(tr(GLYPHS.CONTROLS_PAD)) and line.text.contains("\n"), "A HUD's own layout should be used once, and its line breaks kept (%d calls): %s" % [other.laid_out, line.text])
	for frame in 5:
		GLYPHS.apply(other, false)
	_check(other.laid_out == 2 and _words(line.text) == "A/D move W jump", "With the keyboard the HUD's words should come back, once (%d calls): %s" % [other.laid_out, line.text])
	other.queue_free()
	# The hint line freed (a HUD that drops it).
	hint.free()
	GLYPHS.apply(fake, true)
	GLYPHS.apply(fake, false)
	_check(key.text == "K", "The slots should still follow with the hint line gone")
	fake.queue_free()
	GLYPHS.pad_in_use = false
	return true

## Held through a pause, a match's end and a reload: the pad leaves nothing pressed behind.
func _test_nothing_stays_pressed() -> bool:
	var main: Node = await _scene("rematch", "frey")
	_axis(JOY_AXIS_LEFT_X, -0.9)
	_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_button(JOY_BUTTON_X, true)
	await _frames(4)
	_check(Input.is_action_pressed("move_left") and Input.is_action_pressed("basic_attack"), "Test setup: the stick and X should be held")
	main.director._finish(main.players[0], "pad test")
	await _frames(4)
	_check(main.match_over and main.pad_context() == "menu", "The result screen is a menu")
	for action in ACTIONS:
		_check(not Input.is_action_pressed(action), "Nothing should stay pressed on the result screen (%s)" % action)
	# A on the result screen: Rematch (its first button), with the stick still pushed left.
	_button(JOY_BUTTON_X, false)
	await _tap(JOY_BUTTON_A)
	await _frames(8)
	main = current_scene
	_check(main.match_started and not main.match_over, "A on the result screen should rematch")
	await _frames(4)
	_check(Input.is_action_pressed("move_left"), "The stick still pushed left should walk left in the new match")
	_axis(JOY_AXIS_LEFT_X, 0.0)
	_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _frames(3)
	for action in ACTIONS:
		_check(not Input.is_action_pressed(action), "Everything let go should leave nothing pressed (%s)" % action)
	return true
