extends RefCounted
## What the screen calls the controls while a gamepad is the device in use (2026-11-26).
##
## The HUD is the UI session's and is being rebuilt on its own branch, so nothing of this lives in
## MatchHud.gd: the names and the hint line are here, and apply() writes them into the HUD's labels
## from outside. It writes to three things, which both versions of the HUD have under these names:
##   skill_slots[slot].key, skill_slots[slot].glyph    the skill bar's key names
##   controls_label                                    the control hint under it (may go away)
## Each is checked before it is written; a HUD without one is left as it is. Main applies the
## names again after the HUD's own update every frame, so the HUD may rewrite these labels: the
## pad's names go back on top while a pad is in use, and the HUD's own text stays otherwise.
##
## PadInput's tables are the layout; these are its names. test_gamepad holds the two together.

## The five slots of the skill bar, by the button that uses each (Xbox names).
const SLOT_NAMES := {"j": "X", "k": "Y", "l": "B", "u": "RB", "i": "RT"}
## The action each slot stands for, for the test that the names follow PadInput's layout.
const SLOT_ACTIONS := {"j": "basic_attack", "k": "skill_1", "l": "skill_2", "u": "skill_3", "i": "ultimate"}
## The control hint under the skill bar, for a pad.
const CONTROLS_PAD := "Stick move   A jump   Down+A drop   LB guard   LT portal   R-stick soul card"
## Practice mode's second line, for a pad: one button instead of nine keys.
const PRACTICE_PAD := "Start or Back: practice menu"
## On the hint line: the HUD's own text, and the pad text this wrote over it.
const HUD_TEXT := &"pad_glyphs_hud_text"
const WRITTEN := &"pad_glyphs_written"
## On a key badge widened for a two-letter name: its place and width before.
const BADGE := &"pad_glyphs_badge"

## The device the last press came from (PadInput tells Main, Main calls apply).
static var pad_in_use := false

## Writes the pad's names into `hud`, or puts the HUD's own back. Cheap when nothing changes.
static func apply(hud: Node, pad: bool) -> void:
	pad_in_use = pad
	if not is_instance_valid(hud):
		return
	var slots: Variant = hud.get("skill_slots")
	if slots is Dictionary:
		for slot: String in SLOT_NAMES:
			var nodes: Variant = slots.get(slot)
			if not nodes is Dictionary:
				continue
			var name: String = SLOT_NAMES[slot]
			_set_name(nodes.get("glyph"), name, slot.to_upper(), pad)
			var key: Variant = nodes.get("key")
			_set_name(key, name, slot.to_upper(), pad)
			if _is_label(key):
				_fit_badge(key, pad)
	var hint: Variant = hud.get("controls_label")
	if _is_label(hint):
		_set_hint(hint, pad)

static func _is_label(node: Variant) -> bool:
	# Validity first: `is` on a freed object is an error.
	return is_instance_valid(node) and node is Label

## A slot's name: the pad's over the key's while a pad is in use; the key's back only where the pad's
## is shown (the HUD's own text is left alone).
static func _set_name(label: Variant, pad_name: String, key_name: String, pad: bool) -> void:
	if not _is_label(label):
		return
	if pad and label.text == key_name:
		label.text = pad_name
	elif not pad and label.text == pad_name:
		label.text = key_name

## A badge too narrow for its name (RB, RT) grows to the left; it goes back with the keyboard.
static func _fit_badge(badge: Label, pad: bool) -> void:
	if pad:
		var font := badge.get_theme_font("font")
		var width := font.get_string_size(badge.text, HORIZONTAL_ALIGNMENT_LEFT, -1, badge.get_theme_font_size("font_size")).x + 4.0
		if width > badge.size.x:
			if not badge.has_meta(BADGE):
				badge.set_meta(BADGE, Vector2(badge.position.x, badge.size.x))
			badge.position.x -= width - badge.size.x
			badge.size.x = width
	elif badge.has_meta(BADGE):
		var before: Vector2 = badge.get_meta(BADGE)
		badge.position.x = before.x
		badge.size.x = before.y
		badge.remove_meta(BADGE)

## The hint line keeps its right edge and the room it had round its text. The match HUD of
## 2026-11-26 lays a long hint out in lines itself (MatchHud.set_control_hints, a line break at a
## wide gap), so two texts that differ only in spacing and line breaks are the same text here:
## compared as written, the laid-out pad text read as the HUD's own and the keyboard's never came back.
static func _set_hint(hint: Label, pad: bool) -> void:
	var pad_text: String = hint.tr(CONTROLS_PAD)
	var written: String = str(hint.get_meta(WRITTEN, ""))
	if pad:
		if _same(hint.text, pad_text):
			return
		# Not this one's text: the HUD wrote it, and it is what comes back with the keyboard.
		if written == "" or not _same(hint.text, written):
			hint.set_meta(HUD_TEXT, hint.text)
		_write_hint(hint, pad_text)
		hint.set_meta(WRITTEN, pad_text)
	elif written != "" and _same(hint.text, written):
		_write_hint(hint, str(hint.get_meta(HUD_TEXT, "")))
		hint.remove_meta(WRITTEN)

static func _same(a: String, b: String) -> bool:
	return " ".join(a.replace("\n", " ").split(" ", false)) == " ".join(b.replace("\n", " ").split(" ", false))

static func _write_hint(hint: Label, text: String) -> void:
	# A HUD that lays its hint out itself gets the words only.
	var hud := hint.get_parent()
	if hud != null and hud.has_method("set_control_hints"):
		hud.set_control_hints(text)
		return
	var font := hint.get_theme_font("font")
	var font_size := hint.get_theme_font_size("font_size")
	var room := hint.size.x - font.get_string_size(hint.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + maxf(room, 0.0)
	hint.text = text
	if is_equal_approx(hint.anchor_left, hint.anchor_right):
		# Anchored to one point (MatchHud._pin, the right edge): the left offset follows the text.
		hint.offset_left = hint.offset_right - width
	else:
		hint.position.x += hint.size.x - width
		hint.size.x = width

## Practice mode's second line while a pad is in use (PracticeSession.show_pad_help).
static func practice_line(node: Node, keyboard_line: String) -> String:
	return node.tr(PRACTICE_PAD) if pad_in_use else keyboard_line
