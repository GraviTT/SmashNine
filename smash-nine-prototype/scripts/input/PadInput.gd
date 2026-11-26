extends Node
## A gamepad for player one (quality track 3, 2026-11-26).
##
## Everything in the game that reads input takes either an action (the fighters, Main's polled
## keys) or a key event (the menus, the story's screens and dialogue, practice mode). So a pad is
## turned into those two here, and nothing else needs to know that a pad exists:
##  - in play, buttons, triggers and sticks press and release actions, each exactly once. An
##    analog stick sends a stream of values: a direction is pressed when it passes DEADZONE and
##    let go under RELEASE, so a stick that does not come back to zero presses nothing;
##  - in a menu, a dialogue or a list, the pad presses keys (arrows, Enter, Esc, V).
## The pad's own events stop here: the engine's GUI would move focus and press the focused
## button with them, on top of the keys.
##
## The layout is the tables below and nowhere else (Xbox names; the "standard" layout a browser
## gives). The lead settled it on 2026-11-26; the user may change it.
##   left stick, D-pad   move and aim. Up past JUMP_TILT (or D-pad up) also jumps, as W does;
##                       a little up only aims
##   A jump (with down held on a thin platform: through it)      X attack (J)
##   Y skill (K)     B skill (L)     RB third skill (U)     RT ultimate (I)
##   LB guard (Space)     LT portal (Q)     right stick left / up / right: soul card 1 / 2 / 3
##   Start           practice mode's menu, the story's pause; in menus Enter (Main.pad_menu_key)
##   Back            as Start in play; in menus Esc

const AUDIO := preload("res://scripts/audio/AudioManager.gd")
const GLYPHS := preload("res://scripts/input/PadGlyphs.gd")

## One value for moving and aiming.
const DEADZONE := 0.3
const RELEASE := 0.2
## The left stick this far up is a jump as well as an aim; under it, an aim alone.
const JUMP_TILT := 0.75
const JUMP_RELEASE := 0.6
const TRIGGER_ON := 0.5
const TRIGGER_OFF := 0.3
## A soul card is picked with a clear push of the right stick.
const CARD_TILT := 0.6
const CARD_RELEASE := 0.4

const DPAD := {JOY_BUTTON_DPAD_LEFT: "left", JOY_BUTTON_DPAD_RIGHT: "right", JOY_BUTTON_DPAD_UP: "up", JOY_BUTTON_DPAD_DOWN: "down"}
const PLAY_BUTTONS := {
	JOY_BUTTON_A: "jump",
	JOY_BUTTON_X: "basic_attack",
	JOY_BUTTON_Y: "skill_1",
	JOY_BUTTON_B: "skill_2",
	JOY_BUTTON_RIGHT_SHOULDER: "skill_3",
	JOY_BUTTON_LEFT_SHOULDER: "guard",
}
const PLAY_TRIGGERS := {JOY_AXIS_TRIGGER_RIGHT: "ultimate", JOY_AXIS_TRIGGER_LEFT: "use_portal"}
## The cards as they lie on the screen: left, middle, right.
const CARD_ACTIONS := {"left": "choose_1", "up": "choose_2", "right": "choose_3"}
const CARD_KEYS := {"left": KEY_1, "up": KEY_2, "right": KEY_3}
## Buttons that open what the mode has for a pause (Main.pad_menu_key says which key that is).
const MENU_BUTTONS: Array[int] = [JOY_BUTTON_START, JOY_BUTTON_BACK]
const MENU_KEYS := {JOY_BUTTON_A: KEY_ENTER, JOY_BUTTON_B: KEY_ESCAPE, JOY_BUTTON_Y: KEY_V}
## Marks the events this node hands the engine. The engine keeps them and passes them on later,
## through this node's _input too, where a key would otherwise look like the keyboard.
const OWN := &"pad_input"
const ARROWS := {"left": KEY_LEFT, "right": KEY_RIGHT, "up": KEY_UP, "down": KEY_DOWN}

## What is held on the pad outlives a scene reload (a rematch with the stick still pushed).
static var _down: Dictionary = {}

signal device_changed(pad: bool)

var main: Node
## True while the last thing pressed was on a pad: the screen names the pad's buttons then
## (PadGlyphs). It starts as the last scene left it: a rematch does not forget the pad.
var active := GLYPHS.pad_in_use
var _context := "menu"
## action -> {source: true}: an action is held while any source holds it (A and the stick both jump).
var _held: Dictionary = {}
## Keys pressed for a menu, let go a frame later: [key, process frame of the press].
var _key_releases: Array = []

static func reset() -> void:
	_down.clear()

func _init() -> void:
	# Menus and lists are read with the game paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup(owner_main: Node) -> void:
	main = owner_main
	_sync_context()

func _exit_tree() -> void:
	# The Input singleton outlives the scene: nothing may stay pressed in it.
	_release_all()
	_flush_keys(true)

func _process(_delta: float) -> void:
	_sync_context()
	_flush_keys(false)

func _input(event: InputEvent) -> void:
	if event.has_meta(OWN):
		return
	if event is InputEventJoypadButton:
		_sync_context()
		if event.pressed:
			_set_active(true)
			_unlock_audio()
		_button(event.button_index, event.pressed)
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadMotion:
		_sync_context()
		_axis(event.axis, event.axis_value)
		get_viewport().set_input_as_handled()
	elif (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed):
		_set_active(false)

# --- Buttons, sticks, triggers ---

func _button(index: int, pressed: bool) -> void:
	if DPAD.has(index):
		_direction("dpad", str(DPAD[index]), pressed)
		return
	if MENU_BUTTONS.has(index):
		if pressed:
			var key: int = main.pad_menu_key() if index == JOY_BUTTON_START or _context == "play" else KEY_ESCAPE
			if key != KEY_NONE:
				_tap_key(key)
		return
	if _context == "play":
		if PLAY_BUTTONS.has(index):
			var action := str(PLAY_BUTTONS[index])
			# Down and jump on a thin platform: through it, not up (down twice is hard on a stick).
			if pressed and action == "jump" and _direction_held("down") and main.pad_drop_through():
				return
			_set_action(action, "button %d" % index, pressed)
	elif pressed and MENU_KEYS.has(index):
		_tap_key(int(MENU_KEYS[index]))

func _axis(axis: int, value: float) -> void:
	match axis:
		JOY_AXIS_LEFT_X:
			_tilt("stick", "left", -value, DEADZONE, RELEASE)
			_tilt("stick", "right", value, DEADZONE, RELEASE)
		JOY_AXIS_LEFT_Y:
			_tilt("stick", "up", -value, DEADZONE, RELEASE)
			_tilt("stick", "down", value, DEADZONE, RELEASE)
			_tilt("jump", "up", -value, JUMP_TILT, JUMP_RELEASE)
		JOY_AXIS_RIGHT_X:
			_tilt("cards", "left", -value, CARD_TILT, CARD_RELEASE)
			_tilt("cards", "right", value, CARD_TILT, CARD_RELEASE)
		JOY_AXIS_RIGHT_Y:
			_tilt("cards", "up", -value, CARD_TILT, CARD_RELEASE)
		JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT:
			_tilt("trigger", str(axis), value, TRIGGER_ON, TRIGGER_OFF)

## One direction of one stick (or a trigger): pressed past `on`, let go under `off`.
func _tilt(source: String, direction: String, value: float, on: float, off: float) -> void:
	var was: bool = _down.get("%s:%s" % [source, direction], false)
	_direction(source, direction, value >= (off if was else on))

func _direction_held(direction: String) -> bool:
	return bool(_down.get("stick:%s" % direction, false)) or bool(_down.get("dpad:%s" % direction, false))

## A direction, a tilt or a trigger went down or came up: what that means now.
func _direction(source: String, direction: String, down: bool) -> void:
	var name := "%s:%s" % [source, direction]
	if bool(_down.get(name, false)) == down:
		return
	_down[name] = down
	if down:
		_set_active(true)
	match source:
		"stick", "dpad":
			if _context == "play":
				_set_action("move_%s" % direction, source, down)
				if source == "dpad" and direction == "up":
					_set_action("jump", source, down)
			elif down:
				_tap_key(int(ARROWS[direction]))
		"jump":
			if _context == "play":
				_set_action("jump", "stick", down)
		"cards":
			if _context == "play":
				_set_action(str(CARD_ACTIONS[direction]), source, down)
			elif _context == "cards" and down:
				_tap_key(int(CARD_KEYS[direction]))
		"trigger":
			if _context == "play":
				_set_action(str(PLAY_TRIGGERS[int(direction)]), source, down)

# --- What the game sees ---

func _set_action(action: String, source: String, down: bool) -> void:
	var sources: Dictionary = _held.get(action, {})
	var was := not sources.is_empty()
	if down:
		sources[source] = true
	else:
		sources.erase(source)
	_held[action] = sources
	var now := not sources.is_empty()
	if now == was:
		return
	var event := InputEventAction.new()
	event.action = action
	event.pressed = now
	event.strength = 1.0 if now else 0.0
	_send(event)

func _tap_key(code: int) -> void:
	_send_key(code, true)
	_key_releases.append([code, Engine.get_process_frames()])

func _send_key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code as Key
	event.keycode = code as Key
	event.pressed = pressed
	_send(event)

## Events made here pass this node again: they are not a keyboard, and not a pad.
func _send(event: InputEvent) -> void:
	event.set_meta(OWN, true)
	Input.parse_input_event(event)

## A key pressed for a menu comes up a frame later (a press and a release in one frame is no
## press at all to code that polls, such as V for the body).
func _flush_keys(all: bool) -> void:
	var frame := Engine.get_process_frames()
	var waiting: Array = []
	for entry: Array in _key_releases:
		if all or int(entry[1]) < frame:
			_send_key(int(entry[0]), false)
		else:
			waiting.append(entry)
	_key_releases = waiting

func _release_all() -> void:
	for action: String in _held.keys():
		if not (_held[action] as Dictionary).is_empty():
			_held[action] = {}
			var event := InputEventAction.new()
			event.action = action
			event.pressed = false
			_send(event)
	_held.clear()

## Play and menus read the pad differently. Leaving play lets go of everything; entering it, a
## direction still held keeps its meaning (the stick already pushed right walks right).
func _sync_context() -> void:
	var now: String = main.pad_context() if is_instance_valid(main) else "menu"
	if now == _context:
		return
	_context = now
	_release_all()
	if now == "play":
		for direction in ["left", "right", "up", "down"]:
			for source in ["stick", "dpad"]:
				if bool(_down.get("%s:%s" % [source, direction], false)):
					_set_action("move_%s" % direction, source, true)

func _set_active(pad: bool) -> void:
	if active == pad:
		return
	active = pad
	device_changed.emit(pad)

## A browser, and this game, wait for a first press before sound: a pad's press counts here.
func _unlock_audio() -> void:
	var manager := AUDIO.find(self)
	if manager != null and not bool(manager.unlocked):
		manager.unlock()
