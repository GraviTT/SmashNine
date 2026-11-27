extends RefCounted
## A gamepad's button names as small badges (2026-11-27, UI lead; the gamepad report's section 6):
## drawn with flat boxes and words only, no pictures (the web download has no room for any).
## A, B, X and Y are round in their usual colours; LB/RB and LT/RT are dark tabs, the triggers with
## a taller rounded top; Start and Back are small pills; the sticks are dark circles with a ring.
## The match HUD's skill slots and the controls screen's pad table use these.

const FACE := {"A": Color("4caf50"), "B": Color("e5534b"), "X": Color("3d8fe0"), "Y": Color("e8b730")}
const SHOULDERS := ["LB", "RB"]
const TRIGGERS := ["LT", "RT"]
const PILLS := ["Start", "Back"]
const STICKS := {"LS": "L", "RS": "R"}
const DARK := Color("2b3446")
const RING := Color(0.86, 0.9, 0.97, 0.75)
const INK := Color("101827")
const WHITE := Color("f5f8fc")

## Whether `text` is one of the pad's names this draws (the HUD's key labels hold either a key or one).
static func is_pad_name(text: String) -> bool:
	return FACE.has(text) or SHOULDERS.has(text) or TRIGGERS.has(text) or PILLS.has(text) or STICKS.has(text)

## The badge's width for `name` at `height`: a circle for a face button or a stick, else the words
## and some room each side.
static func width(name: String, height: float, font: Font, font_size: int) -> float:
	if FACE.has(name) or STICKS.has(name):
		return height
	return ceilf(font.get_string_size(label(name), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) + height * 0.7

## The words on the badge (a stick shows L or R).
static func label(name: String) -> String:
	return str(STICKS.get(name, name))

## The colour of the words on the badge.
static func ink(name: String) -> Color:
	return INK if name == "Y" else WHITE

## The badge's box: its fill, ring and corners for `name`.
static func box(name: String, height: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.anti_aliasing = true
	style.set_border_width_all(1)
	style.border_color = RING
	if FACE.has(name):
		style.bg_color = FACE[name]
		style.border_color = Color(FACE[name].lightened(0.45), 0.9)
		style.set_corner_radius_all(int(height * 0.5))
	elif STICKS.has(name):
		style.bg_color = DARK
		style.set_border_width_all(2)
		style.set_corner_radius_all(int(height * 0.5))
	elif TRIGGERS.has(name):
		style.bg_color = DARK
		style.corner_radius_top_left = int(height * 0.5)
		style.corner_radius_top_right = int(height * 0.5)
		style.corner_radius_bottom_left = 2
		style.corner_radius_bottom_right = 2
	elif SHOULDERS.has(name):
		style.bg_color = DARK
		style.corner_radius_top_left = int(height * 0.3)
		style.corner_radius_top_right = int(height * 0.3)
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
	else:
		style.bg_color = DARK
		style.set_corner_radius_all(int(height * 0.5))
	return style

## A badge to place: a plate of `name`'s shape with its words centred, `height` tall, its width from
## width(). The words use `font` at `font_size`.
static func make(name: String, height: float, font: Font, font_size: int) -> Panel:
	var badge := Panel.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.size = Vector2(width(name, height, font, font_size), height)
	badge.add_theme_stylebox_override("panel", box(name, height))
	var words := Label.new()
	# A button's printed name: "Back" stays "Back" in Korean (the table translates the menu's Back).
	words.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	words.text = label(name)
	words.size = badge.size
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	words.add_theme_font_override("font", font)
	words.add_theme_font_size_override("font_size", font_size)
	words.add_theme_color_override("font_color", ink(name))
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(words)
	return badge

## The D-pad: a dark plus, `size` across, drawn as two crossing bars.
static func make_dpad(size: float) -> Control:
	var pad := Control.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.size = Vector2(size, size)
	var bar := size * 0.38
	for rect in [Rect2((size - bar) * 0.5, 0, bar, size), Rect2(0, (size - bar) * 0.5, size, bar)]:
		var arm := Panel.new()
		arm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arm.position = rect.position
		arm.size = rect.size
		var style := StyleBoxFlat.new()
		style.bg_color = DARK
		style.border_color = RING
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		arm.add_theme_stylebox_override("panel", style)
		pad.add_child(arm)
	return pad
