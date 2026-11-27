extends Control

## Front-end presentation only. Main owns starting/reloading matches and session choices.

signal action_requested(action: String, value: String)

const AUDIO := preload("res://scripts/audio/AudioManager.gd")
const ART := preload("res://scripts/ArtSettings.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const AUDIO_SETTINGS := preload("res://scripts/audio/AudioSettings.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const SOUL_CARDS := preload("res://scripts/match/SoulCards.gd")
const PAD_BADGES := preload("res://scripts/ui/PadBadges.gd")
const GLYPHS := preload("res://scripts/input/PadGlyphs.gd")
const FIGHTER_NAMES := preload("res://scripts/ui/FighterNames.gd")
const SIZE := Vector2(1280, 720)
const GOLD := Color("f3cd7c")
const DIM := Color("aebbd0")
const INK := Color("101827")
const WHITE := Color("f5f8fc")
const EDGE := Color(1, 1, 1, 0.16)
## The title and the select screen as the user picked them (pick cup round 2026-11-25-menu, B;
## reports/ui-direction-2026-11-25): flat slanted plates like the match HUD's, the menu as a column
## beside the key art, the select screen built round the fighter with the roster as one strip.
const SLANT := 0.2
## The screens after the menus in the same look (2026-11-27, UI lead, from the picks above): the
## heading on a slanted plate at the top left with Back on an Esc cap beside it, the key hints at the
## top right, flat sheets where framed panels were.
const HINTS_TOP := Rect2(508, 28, 736, 26)
const SKILL_ICON := "res://assets/art/skill_icons/%s_%s.png"
## Select screen: the roster strip and its tiles (a fighter's face, or Random), the kit in two columns.
## Up to seven slots keep 92 px tiles; more (nine fighters and Random, D58) share the strip's width.
const SELECT_STRIP := Rect2(536, 510, 720, 136)
const SELECT_TILE := 92.0
const SELECT_PITCH := 100.0
const KIT_ORIGIN := Vector2(574, 244)
const KIT_COLUMN := 330.0
const KIT_ROW := 84.0
const KIT_WIDTH := 310.0
const KIT_SLOT := 42.0
## Short descriptions from design/SKILLS.md; no balance data is duplicated here.
const KITS := {
	"frey": ["Claim close range with your sword.\nHover on your wings, then strike from any angle.",
		"Sword chain  /  Direction changes your slash.", "Whirlwind Wave  /  Spin and send a slowing wave.",
		"Soaring Cleave  /  Tap L again: Valhalla Strike.", "Valkyrie Descent  /  Light pulls foes in, then a slam.",
		"Valkyrie Wings  /  Hold jump in the air, then dash-slash."],
	"yuki": ["Set talismans along your opponent's path.\nControl landings with seals and pulling wards.",
		"Snow Talisman  /  Fire ahead, above or below.", "Binding Seal  /  Place up to two fragile seals.",
		"Release Ward  /  Pull and burst; no seals: repel.", "Grand Ward  /  Pull, slow and finish with a blast.",
		"No passive  /  Plan your seals before the fight."],
	"luna": ["Mark foes with magic stars, then warp and shield.\nTransform into Brave Luna to grab, spin and beam.",
		"Star Volley  /  Three small stars, then a bursting one.", "Twinkle Warp  /  Warp where you aim; burst on arrival.",
		"Star Barrier  /  Block shots and take hits for 5 s.", "Brave Luna  /  Transform, burst marks; I again: beam.",
		"Star Magic  /  Marked foes take 10% more damage."],
	# Nova has a third skill (U, D47): J, K, L, U, I, passive.
	"nova": ["Pull, float and pin your foes with gravity.\nStack it to root them, then fling them off your sphere.",
		"Vector Chain  /  Three strikes; the last adds a gravity stack.", "Gravity Orb  /  Bursts, pulls foes in, adds a stack.",
		"Gravity Field  /  Fly inside it; foes slow, monsters float.", "Gravity Beam  /  Drag a foe to you; slam one in the air.",
		"Event Horizon  /  Foes circle a sphere; hold I, let go to launch.",
		"Gravity Stacks  /  Three stacks root a foe for 2 s."],
	# Rio's kit v3 also has a third skill (U, D50).
	"rio": ["Blink to your sword, behind attackers or into your decoy.\nHits from behind cut deeper.",
		"Mana Combo  /  Three cuts; the last dashes through the foe.", "Sword Throw  /  K again: blink to it, behind a struck foe.",
		"Shadow Counter  /  Take a hit unharmed, strike from behind.", "Decoy Swap  /  Leave a decoy and step back; U again: swap.",
		"Blade Flurry  /  Stick six gem swords; I again: cut them all.",
		"Backstab  /  Hits from behind deal 1.5x. Two air jumps."],
	# Xion (2026-11-18, the user's kit): J, K, L, U, I, passive.
	"xion": ["Push foes back with twin shotguns from mid range.\nYour doppelganger pins one; close in for double damage.",
		"Buckshot  /  10 rounds, 2 a second; empty: 3 s reload.", "Reload Roll  /  Roll unharmed at first and load 2 rounds.",
		"Recoil Jump  /  Fire every round down and rise.", "Doppelganger  /  Hunts and pins a foe 3 s; U again: dive to it.",
		"Equilibrium  /  Shots all round, your double too; walk slowly.",
		"Double Shotgun  /  The closer the foe, the more damage (up to 2x)."]
}
## Main.CHOOSE_ACTIONS: the number keys that quick-start a fighter. Hints that name them take
## the count as %d (the controls row still said "1 - 5" after the sixth fighter; UI audit B3).
const QUICK_START_KEYS := 9
const CONTROLS := [
	["A / D  or  Left / Right", "Move / aim attacks"],
	["W  or  Up", "Jump (air jumps available)"],
	["S, S  or  Down, Down", "Drop through a thin platform"],
	["Space", "Guard / tap just before a hit to parry"],
	["J  + direction", "Basic attack (ground and air variants)"],
	["K / L / U", "Character skills (U: third skill)"], ["I", "Ultimate (30 second cooldown)"],
	["Q", "Use the portal under your feet"], ["1 / 2 / 3", "Pick a soul card when offered"],
	# Menus and tools after the match's keys (UI audit 4-1: the developer's keys sat among them).
	["1 - %d / V / B (menus)", "Quick start / body / watch bots"],
	["Arrows or W-S / Enter or J", "Navigate menus / confirm (mouse also works)"],
	["Esc / R (results)", "Back in menus / rematch"],
	["T", "Game speed: 100 / 90 / 80 / 70%"], ["F2 (before a match)", "Switch original / prototype art"],
	["H", "Spawn / remove a training dummy"], ["F3 / F4", "Debug panel / live bot panel"]
]
## The keyboard table's first rows are the match's keys; the rest are menus and tools.
const CONTROLS_IN_MATCH := 9
## The gamepad's table (the gamepad report's section 1, Xbox names), on the controls screen's second
## tab: each row the buttons (badges, PadBadges; DPAD is the cross, a word is written) over what they
## do. The keyboard rows' words are reused where the action is the same.
const PAD_CONTROLS := [
	[["LS", "DPAD"], "Move / aim attacks"],
	[["A", "or", "stick all the way up"], "Jump (air jumps available)"],
	[["stick up a little"], "Aim up without jumping"],
	[["Down", "+", "A"], "Drop through a thin platform"],
	[["LB"], "Guard / tap just before a hit to parry"],
	[["X", "+ direction"], "Basic attack (ground and air variants)"],
	[["Y", "B", "RB"], "Character skills (RB: third skill)"],
	[["RT"], "Ultimate (30 second cooldown)"],
	[["LT"], "Use the portal under your feet"],
	[["RS", "← ↑ →"], "Pick a soul card when offered"],
	[["Start"], "Practice menu / story pause / confirm"],
	[["Back"], "Back in menus (in a match: as Start)"],
	[["In menus"], "Stick: arrows   A: Enter   B: Esc   Y: body"],
]

var screen := "title"
## The controls screen's tab: "keys" or "pad" ("" picks the device in use when the screen opens).
var controls_tab := ""
## What the select screen starts: "match", or "practice" when it was opened from Practice.
var select_mode := "match"
var selected_id := "frey"
var body := "male"
var fighter_count := 8
var bot_panel_at_start := true
var content: Control
var buttons: Array[Button] = []
var portrait_buttons: Array[Button] = []
var focus_index := 0
var _audio_mouse_frame := -1
var _audio_hover_serial := 0
var hero_art: TextureRect
var fighter_name: Label
var fighter_role: Label
var description: Label
## A kit row: the key on its cap (skill_keys), the move's name (skill_titles) and what it does
## (skill_labels), beside the move's icon in a slot.
var skill_keys: Array[Label] = []
var skill_titles: Array[Label] = []
var skill_labels: Array[Label] = []
var skill_rows: Array[Dictionary] = []
## Select screen: the band of the fighter's colour behind its picture, the name band, each tile's
## face and name, Random's name, and the start button.
var select_band: Panel
var name_band: Panel
var name_stripe: Panel
var portrait_pictures: Array[TextureRect] = []
var portrait_captions: Array[Label] = []
var random_caption: Label
var select_start: Button
## The strip's tile pitch and size for the slots it holds (SELECT_PITCH and SELECT_TILE up to seven).
var strip_pitch := SELECT_PITCH
var strip_tile := SELECT_TILE
var _bold: FontVariation
var _gaps: RegEx
var body_button: Button
var speed_button: Button
var art_button: Button
var count_button: Button
var panel_button: Button
var language_button: Button
var audio_buttons: Dictionary = {}
var footer: Label
var session_status: Label
var _roster := REGISTRY.get_characters()
## The fighters the select screen shows, in order (story mode passes its own heroes).
var select_ids: Array[String] = []

func _init() -> void:
	LANGUAGE.load_saved()

func _ready() -> void:
	name = "Frontend"
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_viewport().size_changed.connect(_fit)
	_fit()

func _fit() -> void:
	var view := get_viewport().get_visible_rect().size
	var ratio := minf(view.x / SIZE.x, view.y / SIZE.y)
	scale = Vector2.ONE * ratio
	position = (view - SIZE * ratio) * 0.5
	size = SIZE

func _clear(next_screen: String) -> void:
	_audio_mouse_frame = -1
	_audio_hover_serial += 1
	screen = next_screen
	buttons.clear()
	portrait_buttons.clear()
	portrait_pictures.clear()
	portrait_captions.clear()
	skill_keys.clear()
	skill_titles.clear()
	skill_labels.clear()
	skill_rows.clear()
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content = Control.new()
	content.size = SIZE
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	focus_index = 0
	session_status = null
	visible = true

func _label(text: String, rect: Rect2, font_size := 20, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = tr(text)
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)
	return label

func _picture(texture: Texture2D, rect: Rect2, pixel := false) -> TextureRect:
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.texture = texture
	picture.position = rect.position
	picture.size = rect.size
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel else CanvasItem.TEXTURE_FILTER_LINEAR
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(picture)
	return picture

func _panel(rect: Rect2, alpha := 0.94) -> void:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, alpha)
	style.border_color = Color("59617c")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	content.add_child(panel)

## look: "frame" (the authored pixel frame on a dark backing: now only the story dialogue's Next and
## Skip, inside its authored box), "slant" (the picked menu look: a flat slanted plate, gold under
## the focus), "primary" (slanted and gold at rest: the main action) or "tile" (a square tile: the
## roster, the story map's stages).
func _button(text: String, rect: Rect2, action: String, value := "", look := "frame", font_size := 20) -> Button:
	var button := Button.new()
	button.text = tr(text)
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", font_size)
	button.focus_mode = Control.FOCUS_ALL
	if look == "frame":
		_frame_look(button, rect)
	else:
		_flat_look(button, look)
	content.add_child(button)
	buttons.append(button)
	button.pressed.connect(func() -> void: _activate(action, value))
	button.mouse_entered.connect(func() -> void:
		if button.is_inside_tree():
			_audio_hover_serial += 1
			_mouse_navigation_sound.call_deferred(weakref(button), not button.has_focus(), Engine.get_process_frames(), _audio_hover_serial)
			button.grab_focus()
			focus_index = buttons.find(button))
	button.focus_entered.connect(func() -> void:
		focus_index = buttons.find(button)
		if screen == "select" and action == "pick":
			selected_id = value
			_refresh_fighter())
	return button

## The look the menus had before the pick, kept for the dialogue box's buttons.
func _frame_look(button: Button, rect: Rect2) -> void:
	button.add_theme_color_override("font_color", Color("e7edf8"))
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_focus_color", GOLD)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("29394f") if state != "normal" else Color("162236")
		style.border_color = GOLD if state != "normal" else Color("667089")
		style.set_border_width_all(2)
		style.content_margin_left = 12
		style.content_margin_right = 12
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
		button.add_theme_stylebox_override(state, style)
	# The existing pixel frame supplies the authored edge, underneath the focus ring.
	var frame_texture := ART.original_texture("res://assets/art/ui/frames/menu_button.png")
	if frame_texture != null:
		var frame_style := StyleBoxTexture.new()
		frame_style.texture = frame_texture
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			frame_style.set_texture_margin(side, 10)
			frame_style.set_content_margin(side, 12)
		button.add_theme_stylebox_override("normal", frame_style)
	# Authored frame centres are transparent. A separate backing keeps text readable.
	var backing := ColorRect.new()
	backing.position = rect.position
	backing.size = Vector2(rect.size.x, maxf(rect.size.y, 52.0))
	backing.color = Color(INK, 0.96)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(backing)

## Flat plates. Hovering grabs the focus, so hover and focus look the same: gold with dark words.
func _flat_look(button: Button, look: String) -> void:
	var tile := look == "tile"
	var primary := look == "primary"
	var skew := 0.0 if tile else SLANT
	var radius := 6 if tile else 3
	var rest := Color(0.08, 0.11, 0.18, 0.98) if tile else (GOLD if primary else Color(INK, 0.86))
	var lit := rest.lightened(0.06) if tile else (GOLD.lightened(0.18) if primary else GOLD)
	var styles := {
		"normal": _box(rest, Color.TRANSPARENT if primary else EDGE, 0 if primary else 1, radius, skew),
		"hover": _box(lit, GOLD if tile else (WHITE if primary else Color.TRANSPARENT), 3 if tile else (2 if primary else 0), radius, skew),
		"pressed": _box(GOLD.darkened(0.12), Color.TRANSPARENT, 0, radius, skew),
		"focus": _box(Color.TRANSPARENT if tile else lit, GOLD if tile else (WHITE if primary else Color.TRANSPARENT), 3 if tile else (2 if primary else 0), radius, skew),
		"disabled": _box(Color(INK, 0.5), EDGE, 1, radius, skew),
	}
	for state: String in styles:
		var box: StyleBoxFlat = styles[state]
		if not tile:
			box.content_margin_left = 26
			box.content_margin_right = 18
		button.add_theme_stylebox_override(state, box)
	var words := INK if primary else (DIM if tile else WHITE)
	button.add_theme_color_override("font_color", words)
	button.add_theme_color_override("font_hover_color", GOLD if tile else INK)
	button.add_theme_color_override("font_focus_color", GOLD if tile else INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_hover_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", Color(DIM, 0.45))
	button.add_theme_font_override("font", _bold_font())
	if not tile:
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT

func _box(color: Color, border := Color.TRANSPARENT, width := 0, radius := 4, skew := 0.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.skew = Vector2(skew, 0)
	box.anti_aliasing = true
	return box

func _plate(rect: Rect2, box: StyleBoxFlat, parent: Node = null) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", box)
	(parent if parent != null else content).add_child(panel)
	return panel

func _bold_font() -> FontVariation:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.7
	return _bold

## A key on a light cap (dark on gold), as the match HUD draws them. Not translated: key names.
func _key_cap(text: String, at: Vector2, width := 26.0, parent: Node = null, on_gold := false, height := 22.0) -> Label:
	var cap := _plate(Rect2(at, Vector2(width, height)), _box(Color(INK, 0.9) if on_gold else Color(0.93, 0.95, 0.98, 0.95), Color.TRANSPARENT, 0, 4), parent)
	var label := Label.new()
	label.text = text
	label.size = cap.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15 if height >= 22.0 else 12)
	label.add_theme_font_override("font", _bold_font())
	label.add_theme_color_override("font_color", GOLD if on_gold else INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_child(label)
	return label

## The "Enter" cap a slanted menu button shows at its right end while it has the focus.
func _focus_cap(button: Button, always := false) -> void:
	var cap := _key_cap("Enter", Vector2(button.size.x - 74, (button.size.y - 22) * 0.5), 54, button, true)
	var plate := cap.get_parent() as Control
	plate.visible = always
	if not always:
		button.focus_entered.connect(func() -> void: plate.visible = true)
		button.focus_exited.connect(func() -> void: plate.visible = false)

## A screen's heading on a slanted plate run off the left edge (as on the select screen), as wide as
## its words, and the line under it. `plate` colours the plate (a fighter's colour on the results).
func _heading(text: String, subtitle := "", font_size := 26, plate := Color(INK, 0.86), color := WHITE) -> Label:
	var height := 50.0 if font_size <= 26 else 64.0
	var heading := _label(text, Rect2(-30, 22, 240, height), font_size, color)
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", _bold_font())
	var box := _box(plate, Color.TRANSPARENT, 0, 3, SLANT)
	box.content_margin_left = 58
	box.content_margin_right = 30
	heading.add_theme_stylebox_override("normal", box)
	heading.size.x = maxf(heading.get_minimum_size().x, 240.0)
	if subtitle != "":
		_label(subtitle, Rect2(30, 22 + height + 6, 640, 24), 16, DIM)
	return heading

## Back at the end of the heading, its key on an Esc cap (as on the select screen). Each screen makes
## it last, so the buttons keep their order.
func _back_button(heading: Label, action: String) -> Button:
	var back := _button("Back", Rect2(heading.position.x + heading.size.x + 4.0, 26, 142, 44), action, "", "slant", 17)
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		back.get_theme_stylebox(state).content_margin_left = 66
	_key_cap("Esc", Vector2(20, 11), 38, back)
	return back

## A flat dark sheet under a screen's content, where a framed panel was.
func _sheet(rect: Rect2, alpha := 0.88) -> Panel:
	return _plate(rect, _box(Color(INK, alpha), Color.TRANSPARENT, 0, 6))

## The slanted band of a fighter's colour behind its picture (as on the select screen).
func _fighter_band(rect: Rect2, accent: Color) -> Panel:
	return _plate(rect, _box(Color(accent.darkened(0.55), 0.55), Color.TRANSPARENT, 0, 4, 0.16))

## A group's name over its part of a sheet.
func _group_title(text: String, at: Vector2, width: float) -> Label:
	var title := _label(text, Rect2(at, Vector2(width, 22)), 15, GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.add_theme_font_override("font", _bold_font())
	return title

## Hints are items set apart by wide gaps (three spaces or more): they break into lines there, no
## line wider than `width`.
func _wrap_gaps(text: String, font: Font, font_size: int, width: float) -> String:
	if _gaps == null:
		_gaps = RegEx.create_from_string(" {3,}")
	var lines: PackedStringArray = []
	for source in text.split("\n"):
		var line := ""
		for item in _gaps.sub(source, "\u001f", true).split("\u001f"):
			var joined := item if line == "" else line + "    " + item
			if line != "" and font.get_string_size(joined, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
				lines.append(line)
				line = item
			else:
				line = joined
		lines.append(line)
	return "\n".join(lines)

## Korean breaks a line between any two syllables: a word joiner (U+2060) between the letters of
## each word keeps the breaks at the spaces (as the match HUD does).
static func keep_words(text: String) -> String:
	var words: PackedStringArray = []
	for word in text.split(" "):
		words.append(String.chr(0x2060).join(word.split("")))
	return " ".join(words)

## Only user navigation calls this; _finish's initial grab_focus stays silent.
func _focus_from_navigation(button: Control) -> void:
	if not button.has_focus():
		AUDIO.sound(self, "ui_move")
	button.grab_focus()

## Godot may emit mouse_entered before _input. Check its input frame after dispatch.
func _mouse_navigation_sound(button_ref: WeakRef, changed: bool, event_frame: int, hover_serial: int) -> void:
	var button: Control = button_ref.get_ref()
	if changed and button != null and button.has_focus() and _audio_hover_serial == hover_serial and _audio_mouse_frame == event_frame:
		AUDIO.sound(self, "ui_move")

## The key hints and the first focus. `rect` and `alignment` place the hints (the picked title has
## them under its menu, the select screen and the screens after it at the top right). They stand on
## a dark plate as wide as their words (UI audit 1-1: bare 15 px hints were lost on bright art);
## `bottom` stands the plate on the rect's bottom edge, growing upward (the title, the pause).
func _finish(hint: String, rect := Rect2(44, 672, 1192, 26), alignment := HORIZONTAL_ALIGNMENT_CENTER, bottom := false) -> void:
	footer = _label(hint, rect, 15, DIM)
	if footer.text.contains("%d"):
		footer.text = footer.text % quick_start_count()
	footer.horizontal_alignment = alignment
	var box := _box(Color(INK, 0.78), Color.TRANSPARENT, 0, 10)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	footer.add_theme_stylebox_override("normal", box)
	footer.set_meta("area", rect)
	if bottom:
		footer.set_meta("bottom", rect.end.y)
	set_footer(footer.text)
	if not buttons.is_empty():
		var initial := maxi(select_ids.find(selected_id), 0) if screen == "select" else 0
		buttons[initial].grab_focus()

## Sets the hints, broken at their gaps to fit the footer's area, the plate as wide as the words and
## placed in the area by the footer's alignment.
func set_footer(text: String) -> void:
	var area: Rect2 = footer.get_meta("area", Rect2(footer.position, footer.size))
	var box := footer.get_theme_stylebox("normal")
	var room := area.size.x - box.get_margin(SIDE_LEFT) - box.get_margin(SIDE_RIGHT) - 4.0
	footer.autowrap_mode = TextServer.AUTOWRAP_OFF
	footer.text = _wrap_gaps(text, footer.get_theme_font("font"), footer.get_theme_font_size("font_size"), room)
	var needed := footer.get_minimum_size()
	var width := minf(ceilf(needed.x) + 2.0, area.size.x)
	var x := area.position.x
	if footer.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x = area.end.x - width
	elif footer.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x = area.position.x + (area.size.x - width) * 0.5
	var y := float(footer.get_meta("bottom")) - needed.y if footer.has_meta("bottom") else area.position.y
	footer.position = Vector2(x, y)
	footer.size = Vector2(width, needed.y)

## The title (menu round 2026-11-25-menu, B): no panel over the key art; the menu is a column of
## flat slanted buttons on a darker band at the left, the two ways to play large, the rest small.
func show_title() -> void:
	AUDIO.music(self, "music_title")
	_clear("title")
	_plate(Rect2(-40, 0, 560, 720), _box(Color(INK, 0.42), Color.TRANSPARENT, 0, 0))
	var logo := ART.original_texture("res://assets/art/ui/title_logo.png")
	if logo != null:
		_picture(logo, Rect2(64, 48, 380, 126), true)
	else:
		_label("SMASH NINE\nREALMS", Rect2(64, 50, 420, 124), 42, GOLD)
	_label("NINE REALMS. ONE SURVIVOR.", Rect2(72, 184, 440, 28), 18, DIM)
	var entries := [["Battle Royale", "select"], ["Story", "story"], ["Practice", "practice"], ["Watch bots", "watch"], ["Options", "options"], ["Controls", "controls"]]
	for index in entries.size():
		var big := index < 2
		var rect := Rect2(64, 240 + index * 70, 400, 62) if big else Rect2(64, 392 + (index - 2) * 52, 330, 44)
		_focus_cap(_button(entries[index][0], rect, entries[index][1], "", "slant", 25 if big else 19))
	session_status = _label("", Rect2(72, 604, 600, 26), 14, DIM)
	refresh_options()
	var mark := _label("Working title  /  Prototype", Rect2(744, 20, 500, 26), 15, DIM)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_finish("Arrows / W-S: navigate    Enter / J: confirm    1-%d: quick start    V: body    B: watch    T: speed    F2: art", Rect2(56, 640, 640, 68), HORIZONTAL_ALIGNMENT_LEFT, true)

## The select screen (menu round 2026-11-25-menu, B): the fighter stands large at the left over a
## band of its colour; who it is and its kit (each move's icon, key, name and what it does, two
## columns) on the right; the roster as one strip of tiles under them, Random last.
## `ids`: the fighters to offer (default: the whole roster; story mode passes its heroes). The first
## two children are the heading and the line under it (StoryScreens rewrites both), and each
## portrait button is followed by its face and its name (child +1, +2). `after` is how many tile
## slots follow the fighters (Random's one; the story's difficulty takes two).
func show_select(ids: Array[String] = [], after := 1) -> void:
	AUDIO.music(self, "music_select")
	_clear("select")
	select_ids = ids if not ids.is_empty() else REGISTRY.get_character_ids()
	if not select_ids.has(selected_id):
		selected_id = select_ids[0]
	# 12 px in from each end; a tile is its pitch less the gap: n slots take 16 + n x pitch.
	strip_pitch = minf(SELECT_PITCH, floorf((SELECT_STRIP.size.x - 16.0) / float(select_ids.size() + after)))
	strip_tile = strip_pitch - (SELECT_PITCH - SELECT_TILE)
	var heading := _heading("CHOOSE YOUR FIGHTER", "Six fighters. Six ways to survive.")
	# The fighter, over a slanted band of its colour.
	select_band = _plate(Rect2(40, 150, 470, 380), _box(Color.WHITE, Color.TRANSPARENT, 0, 4, 0.16))
	hero_art = _picture(null, Rect2(64, 104, 420, 540))
	# Who it is and how it plays.
	_plate(Rect2(548, 72, 696, 432), _box(Color(INK, 0.9), Color.TRANSPARENT, 0, 6))
	name_band = _plate(Rect2(548, 72, 696, 98), _box(Color.WHITE, Color.TRANSPARENT, 0, 6))
	name_stripe = _plate(Rect2(548, 164, 696, 6), _box(Color.WHITE, Color.TRANSPARENT, 0, 0))
	fighter_name = _label("", Rect2(574, 76, 650, 60), 44, WHITE)
	fighter_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	fighter_name.add_theme_font_override("font", _bold_font())
	fighter_role = _label("", Rect2(576, 132, 650, 30), 19, Color(1, 1, 1, 0.92))
	description = _label("", Rect2(574, 180, 650, 56), 16, DIM)
	for index in 6:
		_build_kit_row()
	# The roster: one strip, a tile each and Random last.
	_plate(SELECT_STRIP, _box(Color(INK, 0.72), Color.TRANSPARENT, 0, 6))
	for index in select_ids.size():
		var id := select_ids[index]
		var tile := _select_tile(index)
		var button := _button("", tile, "pick", id, "tile")
		portrait_buttons.append(button)
		var selected_frame := Panel.new()
		selected_frame.name = "SelectionOutline"
		selected_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		selected_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_frame.add_theme_stylebox_override("panel", _box(Color.TRANSPARENT, GOLD, 3, 6))
		button.add_child(selected_frame)
		portrait_pictures.append(_picture(ART.character_portrait(id, body), Rect2(tile.position + Vector2(4, 4), Vector2(strip_tile - 8.0, strip_tile - 8.0))))
		var caption := _label(str(_roster[id].name), Rect2(tile.position.x - 10, tile.end.y + 2, strip_tile + 20.0, 24), 15 if strip_tile >= 80.0 else 13, DIM)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.autowrap_mode = TextServer.AUTOWRAP_OFF
		portrait_captions.append(caption)
		# A smaller cap on small tiles (nine fighters), so the face shows.
		var small := strip_tile < 80.0
		_key_cap(str(index + 1), tile.position + (Vector2(3, 3) if small else Vector2(4, 4)), 16.0 if small else 22.0, null, false, 16.0 if small else 22.0)
	var random := _button("", _select_tile(select_ids.size()), "random", "", "tile", 40 if strip_tile >= 80.0 else 30)
	# A mark, not a word: set after the helper, which translates its text.
	random.text = "?"
	random_caption = _label("Random", Rect2(random.position.x - 10, random.position.y + strip_tile + 2, strip_tile + 20.0, 24), 15 if strip_tile >= 80.0 else 13, DIM)
	random_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	random_caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	body_button = _button("", Rect2(72, 650, 300, 42), "body", "", "slant", 17)
	_back_button(heading, "title")
	select_start = _button("Start practice" if select_mode == "practice" else "Start match", Rect2(948, 650, 296, 56), "start", "", "primary", 24)
	_focus_cap(select_start, true)
	_refresh_fighter()
	_finish("Arrows / W-A-S-D: browse    Enter / J: confirm / start    V: body    1-%d: quick start    Esc: back", HINTS_TOP, HORIZONTAL_ALIGNMENT_RIGHT)

## One kit row's nodes; _refresh_fighter places and fills them (five or six rows a fighter).
func _build_kit_row() -> void:
	var slot := _plate(Rect2(0, 0, KIT_SLOT, KIT_SLOT), _box(Color(INK, 0.96), EDGE, 1, 6))
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.position = Vector2(3, 3)
	icon.size = Vector2(KIT_SLOT - 6.0, KIT_SLOT - 6.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	# Without an icon (F2, the passive) the slot shows a letter.
	var glyph := Label.new()
	glyph.size = slot.size
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_font_size_override("font_size", 20)
	glyph.add_theme_font_override("font", _bold_font())
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(glyph)
	var key := _key_cap("", Vector2(KIT_SLOT - 14.0, KIT_SLOT - 16.0), 22, slot)
	var title := _label("", Rect2(0, 0, KIT_WIDTH - 56.0, 24), 17, WHITE)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_override("font", _bold_font())
	var detail := _label("", Rect2(0, 0, KIT_WIDTH - 56.0, 44), 15, DIM)
	detail.add_theme_constant_override("line_spacing", -1)
	skill_keys.append(key)
	skill_titles.append(title)
	skill_labels.append(detail)
	skill_rows.append({"slot": slot, "icon": icon, "glyph": glyph, "cap": key.get_parent()})

## A fighter's kit text (KITS), or a placeholder of dashes for a fighter whose text is not written
## yet (a new character before its kit is described), so its screens still draw.
static func kit_for(id: String) -> Array:
	if KITS.has(id):
		return KITS[id]
	return ["", "—", "—", "—", "—", "—"]

## How many fighters the number keys reach.
static func quick_start_count() -> int:
	return mini(REGISTRY.get_character_ids().size(), QUICK_START_KEYS)

## The roster strip's tile `index` (the fighters, then Random).
func _select_tile(index: int) -> Rect2:
	return Rect2(SELECT_STRIP.position.x + 12.0 + index * strip_pitch, SELECT_STRIP.position.y + 14.0, strip_tile, strip_tile)

func _refresh_fighter() -> void:
	var data: Dictionary = _roster[selected_id]
	var accent: Color = data.color
	hero_art.texture = illustration(selected_id, body)
	(select_band.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color(accent.darkened(0.55), 0.55)
	(name_band.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = accent.darkened(0.42)
	(name_stripe.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = accent.lightened(0.35)
	fighter_name.text = tr(str(data.name)).to_upper()
	fighter_role.text = tr(str(data.role))
	var kit: Array = kit_for(selected_id)
	description.text = tr(kit[0])
	# J, K, L(, U), I and the passive: two columns, three rows.
	var keys: Array = ["j", "k", "l", "u", "i", ""] if kit.size() > 6 else ["j", "k", "l", "i", ""]
	for index in 6:
		var nodes: Dictionary = skill_rows[index]
		var shown := index < keys.size()
		for node: CanvasItem in [nodes.slot, skill_titles[index], skill_labels[index]]:
			node.visible = shown
		if not shown:
			skill_labels[index].text = ""
			continue
		var at := KIT_ORIGIN + Vector2((index % 2) * KIT_COLUMN, (index / 2) * KIT_ROW)
		var key: String = keys[index]
		var parts := tr(kit[index + 1]).split("/", true, 1)
		var slot: Panel = nodes.slot
		slot.position = at
		var icon: TextureRect = nodes.icon
		icon.texture = ART.original_texture(SKILL_ICON % [selected_id, key]) if key != "" else null
		var glyph: Label = nodes.glyph
		glyph.text = key.to_upper() if key != "" else "P"
		glyph.visible = icon.texture == null
		glyph.add_theme_color_override("font_color", GOLD if key == "" else WHITE)
		(nodes.cap as Control).visible = key != ""
		skill_keys[index].text = key.to_upper()
		skill_titles[index].position = Vector2(at.x + KIT_SLOT + 14.0, at.y - 2.0)
		skill_titles[index].text = parts[0].strip_edges()
		var detail := skill_labels[index]
		detail.position = Vector2(at.x + KIT_SLOT + 14.0, at.y + 21.0)
		detail.text = keep_words(parts[1].strip_edges()) if parts.size() > 1 else ""
	var bodies := REGISTRY.get_bodies(selected_id)
	body_button.text = tr("[V] Body: %s") % tr((body if bodies.size() > 1 else bodies[0]).capitalize())
	body_button.disabled = bodies.size() < 2
	# Only a fighter drawn in two bodies has the choice.
	body_button.visible = bodies.size() > 1
	for index in portrait_buttons.size():
		var chosen := select_ids[index] == selected_id
		portrait_buttons[index].get_node("SelectionOutline").visible = chosen
		portrait_pictures[index].texture = ART.character_portrait(select_ids[index], body)
		portrait_pictures[index].modulate = Color.WHITE if chosen else Color(0.8, 0.8, 0.88)
		portrait_captions[index].add_theme_color_override("font_color", GOLD if chosen else DIM)

static func illustration(id: String, selected_body: String) -> Texture2D:
	var stem := id + "_" + selected_body if REGISTRY.get_bodies(id).size() > 1 else id
	var path := "res://assets/art/%s/%s_illustration.png" % [id, stem]
	return load(path) as Texture2D if ResourceLoader.exists(path) else ART.character_portrait(id, selected_body)

## Options in the picked look: the game's choices and the sound's on two sheets, each a column of
## slanted rows (Enter on the row in focus changes it). The buttons keep their order: the five game
## choices, the four sound ones, Back.
func show_options() -> void:
	_clear("options")
	var heading := _heading("OPTIONS", "Speed, language and sound are saved. The rest lasts this session.")
	for column in 2:
		var x := 48.0 + column * 600
		var rows := 5 if column == 0 else 4
		_sheet(Rect2(x, 132, 584, 136 + (rows - 1) * 72))
		_group_title(["GAME", "SOUND"][column], Vector2(x + 30, 146), 520)
	speed_button = _option_row(0, 0, "speed")
	art_button = _option_row(0, 1, "art")
	count_button = _option_row(0, 2, "count")
	panel_button = _option_row(0, 3, "panel")
	language_button = _option_row(0, 4, "language")
	audio_buttons.clear()
	for index in 4:
		var key: String = ["master", "music", "effects", "mute"][index]
		audio_buttons[key] = _option_row(1, index, "audio_" + key)
	_back_button(heading, "title")
	refresh_options()
	_finish("Up / Down: navigate    Left / Right: volume    Enter / J / click: change    T: speed    F2: art    Esc: back", HINTS_TOP, HORIZONTAL_ALIGNMENT_RIGHT)

func _option_row(column: int, row: int, action: String) -> Button:
	var button := _button("", Rect2(76.0 + column * 600, 182.0 + row * 72, 528, 58), action, "", "slant", 19)
	_focus_cap(button)
	return button

func refresh_options() -> void:
	if screen == "title" and is_instance_valid(session_status):
		session_status.text = tr("Nova / Rio body: %s    |    Speed: %d%%") % [tr(body.capitalize()), SPEED.percent()] + "    |    " + tr("Language") + ": " + LANGUAGE.label()
	if screen != "options":
		return
	speed_button.text = tr("[T] Game speed: %d%%") % SPEED.percent()
	art_button.text = tr("[F2] Art style: %s") % tr(ART.label())
	count_button.text = tr("Fighters: %d") % fighter_count
	panel_button.text = tr("Bot panel: %s") % tr("On" if bot_panel_at_start else "Off")
	language_button.text = tr("Language: %s") % LANGUAGE.label()
	audio_buttons.master.text = tr("Master volume: %d%%") % int(AUDIO_SETTINGS.values.master)
	audio_buttons.music.text = tr("Music volume: %d%%") % int(AUDIO_SETTINGS.values.music)
	audio_buttons.effects.text = tr("Effects volume: %d%%") % int(AUDIO_SETTINGS.values.effects)
	audio_buttons.mute.text = tr("Mute: %s") % tr("On" if AUDIO_SETTINGS.values.mute else "Off")

## The controls in the picked look, on two tabs: the keyboard's table and the gamepad's (it opens on
## the device in use). Each table stands on two sheets, each row the keys or buttons (gold words, or
## the pad's badges) over what they do, like a kit row on the select screen. Back comes first and
## has the focus, so Enter still returns to the title; Left / Right switch the tab. The tabs sit
## beside Back, and the hints under the sheets.
func show_controls() -> void:
	if controls_tab == "":
		controls_tab = "pad" if GLYPHS.pad_in_use else "keys"
	_clear("controls")
	var heading := _heading("CONTROLS")
	var back := _back_button(heading, "title")
	var x := back.position.x + back.size.x + 22.0
	for tab in [["Keyboard", "keys"], ["Gamepad", "pad"]]:
		var shown: bool = controls_tab == tab[1]
		var button := _button(tab[0], Rect2(x, 26, 168, 44), "controls_" + str(tab[1]), "", "primary" if shown else "slant", 17)
		x += button.size.x + 8.0
	var keys_tab := controls_tab == "keys"
	var rows: Array = CONTROLS if keys_tab else PAD_CONTROLS
	# The keyboard's table in two groups, each on its sheet under its name; the pad's in two halves.
	var split := CONTROLS_IN_MATCH if keys_tab else ceili(rows.size() / 2.0)
	var pitch := 56.0 if keys_tab else 66.0
	var top := 142.0 if keys_tab else 112.0
	for column in 2:
		var count := split if column == 0 else rows.size() - split
		_sheet(Rect2(48.0 + column * 600, 96, 584, top - 80.0 + count * pitch))
		if keys_tab:
			_group_title(["IN A MATCH", "MENUS AND TOOLS"][column], Vector2(78.0 + column * 600, 108), 520)
	for index in rows.size():
		var row: Array = rows[index]
		var column := 0 if index < split else 1
		var line := index if index < split else index - split
		var at := Vector2(78.0 + column * 600, top + line * pitch)
		if line % 2 == 1:
			_plate(Rect2(at - Vector2(16, 6), Vector2(556, pitch - 2.0)), _box(Color(1, 1, 1, 0.04), Color.TRANSPARENT, 0, 4))
		if keys_tab:
			var keys := _label(row[0], Rect2(at, Vector2(524, 24)), 17, GOLD)
			keys.autowrap_mode = TextServer.AUTOWRAP_OFF
			keys.add_theme_font_override("font", _bold_font())
			if keys.text.contains("%d"):
				keys.text = keys.text % quick_start_count()
		else:
			_pad_buttons(row[0], at)
		_label(row[1], Rect2(at + Vector2(0, 26), Vector2(524, 24)), 16, WHITE)
	# The tabs take the top row's room, so the hints stand under the sheets.
	_finish("Left / Right: keyboard / gamepad    Esc: back    Enter / J / click: return to title")

## Opens the controls on one tab ("keys" or "pad").
func show_controls_tab(tab: String) -> void:
	controls_tab = tab
	show_controls()

## A pad row's buttons from `at`, left to right: a badge for each button name, the cross for DPAD,
## gold words for the rest.
func _pad_buttons(tokens: Array, at: Vector2) -> void:
	var x := at.x
	for token: String in tokens:
		var item: Control
		if token == "DPAD":
			item = PAD_BADGES.make_dpad(24)
			content.add_child(item)
		elif PAD_BADGES.is_pad_name(token):
			item = PAD_BADGES.make(token, 24, _bold_font(), 15)
			content.add_child(item)
		else:
			var words := _label(token, Rect2(x, at.y, 400, 24), 17, GOLD)
			words.autowrap_mode = TextServer.AUTOWRAP_OFF
			words.add_theme_font_override("font", _bold_font())
			words.size.x = words.get_minimum_size().x
			item = words
		item.position = Vector2(x, at.y)
		x += item.size.x + 8.0

## The results in the picked look: the winner over a band of its colour and its name on a plate of
## that colour (as on the select screen), the standings on a sheet with the player's row lit, the
## awards on slanted plates, Rematch gold. The buttons keep their order: Rematch, select, title.
func show_results(winner: Node, reason: String, standings: Array[Node], human: Node, survival: Dictionary) -> void:
	AUDIO.results(self, winner)
	_clear("results")
	if is_instance_valid(winner):
		var accent: Color = _roster[winner.character_id].color if _roster.has(winner.character_id) else GOLD
		_fighter_band(Rect2(40, 150, 300, 380), accent)
		if not _victory_picture(winner, Rect2(38, 98, 310, 478)):
			_picture(illustration(winner.character_id, winner.body_type), Rect2(38, 98, 310, 478))
		_heading(tr("%s WINS") % FIGHTER_NAMES.shown(winner).to_upper(), "", 40, accent.darkened(0.42))
	else:
		_heading("DRAW", "", 40, Color(INK, 0.86), GOLD)
	_label(tr("Decided by %s") % tr(reason.replace("_", " ")), Rect2(30, 94, 700, 26), 17, DIM)
	# The player's own place, large at the top right (UI audit 13-5: a lost match read like someone
	# else's victory screen, the place only a gold row in the table). Watching bots has none.
	var place := standings.find(human) + 1 if is_instance_valid(human) else 0
	if place > 0:
		_plate(Rect2(948, 24, 292, 66), _box(Color(INK, 0.9), GOLD if place == 1 else EDGE, 2 if place == 1 else 1, 3, SLANT))
		var words := _label("YOUR PLACE", Rect2(980, 24, 130, 66), 15, DIM)
		words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		words.autowrap_mode = TextServer.AUTOWRAP_OFF
		var number := _label("%d / %d" % [place, standings.size()], Rect2(1100, 24, 116, 66), 34, GOLD if place == 1 else WHITE)
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		number.autowrap_mode = TextServer.AUTOWRAP_OFF
		number.add_theme_font_override("font", _bold_font())
	# The table's rows are 34 px with 8 between them, so each player's row lies at a known height.
	# More than eight players (sixteen-fighter matches) take compact rows: 22 px with 2 between, 15 px
	# words, so all of them stand above the awards.
	# Untyped: a freed fighter in the list must not be assigned to a typed parameter.
	var shown := standings.filter(func(player) -> bool: return is_instance_valid(player)).size()
	var compact := shown > 8
	var row_h := 22.0 if compact else 34.0
	var gap := 2 if compact else 8
	var pitch := row_h + gap
	var words := 15 if compact else 18
	var table_end := 146.0 + (shown + 1) * pitch
	var sheet_end := maxf(532.0, table_end + 8.0)
	_sheet(Rect2(356, 132, 884, sheet_end - 132.0))
	var row := 0
	for player in standings:
		if not is_instance_valid(player):
			continue
		row += 1
		var row_top := 146.0 + row * pitch - gap * 0.5
		if player == human:
			_plate(Rect2(364, row_top, 868, pitch), _box(Color(GOLD, 0.14), Color(GOLD, 0.55), 1, 4))
		elif row % 2 == 0:
			_plate(Rect2(364, row_top, 868, pitch), _box(Color(1, 1, 1, 0.04), Color.TRANSPARENT, 0, 4))
	var grid := GridContainer.new()
	grid.name = "Standings"
	grid.columns = 8
	grid.position = Vector2(380, 146)
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", gap)
	content.add_child(grid)
	for heading in ["#", "", "Fighter", "KOs", "Damage", "Souls", "Cards", "Survived"]:
		_cell(grid, heading, GOLD, 20.0, row_h, words)
	for index in standings.size():
		var player: Node = standings[index]
		if not is_instance_valid(player):
			continue
		var color := GOLD if player == human else Color.WHITE
		_cell(grid, str(index + 1), color, 20.0, row_h, words)
		var face := TextureRect.new()
		face.texture = ART.character_portrait(player.character_id, player.body_type)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.custom_minimum_size = Vector2(row_h, row_h)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(face)
		# Fighters sharing a name carry the number Main gave them (Nova 1, Nova 2).
		_cell(grid, ("P1 " if player == human else "") + FIGHTER_NAMES.shown(player), color, 120, row_h, words)
		_cell(grid, str(player.score), color, 36, row_h, words)
		_cell(grid, "%.0f" % player.damage_dealt, color, 70, row_h, words)
		_cell(grid, str(player.souls), color, 54, row_h, words)
		var card_names: Array[String] = []
		for id in player.upgrades:
			card_names.append(tr(str(SOUL_CARDS.find(str(id)).get("title", id))))
		var cards := _cell(grid, "%d  %s" % [player.upgrades.size(), ", ".join(card_names)] if not card_names.is_empty() else "0", color, 210, row_h, words)
		cards.add_theme_font_size_override("font_size", 12 if compact else 13)
		cards.clip_text = true
		cards.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		cards.tooltip_text = ", ".join(card_names) if not card_names.is_empty() else tr("No soul cards")
		cards.mouse_filter = Control.MOUSE_FILTER_PASS
		var seconds := maxi(0, int(survival.get(player, 0)))
		_cell(grid, "%d:%02d" % [seconds / 60, seconds % 60], color, 76, row_h, words)
	var award_names := ["MOST DAMAGE", "MOST KOs", "LONGEST SURVIVAL"]
	for award in 3:
		var best: Node = null
		var best_value := -1.0
		for player in standings:
			var value := float(player.damage_dealt) if award == 0 else (float(player.score) if award == 1 else float(survival.get(player, 0)))
			if value > best_value:
				best = player
				best_value = value
		var x := 360.0 + award * 292
		# Under the table: where the eight-row table left them, lower and shorter under a long one.
		var award_y := maxf(546.0, sheet_end + 12.0)
		var award_h := minf(84.0, 650.0 - award_y)
		_plate(Rect2(x, award_y, 280, award_h), _box(Color(INK, 0.9), EDGE, 1, 3, SLANT))
		var award_title := _label(award_names[award], Rect2(x + 22, award_y + (10.0 if award_h >= 80.0 else 4.0), 240, 24), 14, GOLD)
		award_title.add_theme_font_override("font", _bold_font())
		var detail := "No contenders"
		if is_instance_valid(best):
			# P1 as in its row ("P1 Frey"), so it is not read as one of its bots (Frey 2, Frey 3).
			detail = "%s  /  %s" % [("P1 " if best == human else "") + FIGHTER_NAMES.shown(best), ("%d:%02d" % [int(best_value) / 60, int(best_value) % 60]) if award == 2 else "%.0f" % best_value]
		_label(detail, Rect2(x + 22, award_y + award_h - 38.0, 240, 28), 18)
	var rematch := _button("[R] Rematch", Rect2(360, 656, 284, 48), "rematch", "", "primary", 20)
	_focus_cap(rematch, true)
	_focus_cap(_button("Character select", Rect2(656, 656, 296, 48), "return_select", "", "slant", 19))
	_focus_cap(_button("Title", Rect2(964, 656, 276, 48), "return_title", "", "slant", 19))
	if not buttons.is_empty():
		buttons[0].grab_focus()

func _cell(grid: GridContainer, text: String, color: Color, width := 20.0, height := 34.0, font_size := 18) -> Label:
	var cell := Label.new()
	cell.text = tr(text)
	cell.custom_minimum_size = Vector2(width, height)
	cell.add_theme_font_size_override("font_size", font_size)
	cell.add_theme_color_override("font_color", color)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_child(cell)
	return cell

## A separate sprite keeps the winner's combat node and pose clock untouched.
func _victory_picture(fighter: Node, bounds: Rect2) -> bool:
	if not fighter._has_motion_row(&"victory"):
		return false
	var row: StringName = fighter._get_sprite_animation_name(&"victory")
	var source: SpriteFrames = fighter.character_sprite.sprite_frames
	var frames := SpriteFrames.new()
	frames.add_animation(&"victory")
	frames.set_animation_speed(&"victory", source.get_animation_speed(row))
	frames.set_animation_loop(&"victory", false)
	for index in source.get_frame_count(row):
		frames.add_frame(&"victory", source.get_frame_texture(row, index), source.get_frame_duration(row, index))
	var sprite := AnimatedSprite2D.new()
	sprite.name = "VictoryMotion"
	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var cell := source.get_frame_texture(row, 0).get_size()
	# The fighter stands in about the middle 60% of its cell: fitting the cell's width left it about
	# 175 px tall in a 478 px place (UI audit 13-1). The cell may run past the place's sides (its
	# margins are empty; the table's sheet covers the right one); a whole scale keeps the pixels even.
	var fit := minf(bounds.size.x * 1.45 / cell.x, bounds.size.y / cell.y)
	sprite.scale = Vector2.ONE * maxf(1.0, floorf(fit))
	sprite.position = bounds.get_center()
	content.add_child(sprite)
	sprite.play(&"victory")
	return true

func _activate(action: String, value: String) -> void:
	AUDIO.sound(self, "ui_cancel" if action in ["title", "return_title", "return_select"] else "ui_select")
	match action:
		"select":
			select_mode = "match"
			show_select()
		"practice":
			select_mode = "practice"
			show_select()
		"title": show_title()
		"options": show_options()
		"controls":
			controls_tab = ""
			show_controls()
		"controls_keys": show_controls_tab("keys")
		"controls_pad": show_controls_tab("pad")
		"pick":
			selected_id = value
			_refresh_fighter()
		"audio_master", "audio_music", "audio_effects", "audio_mute":
			AUDIO_SETTINGS.cycle(action.trim_prefix("audio_"))
			refresh_options()
		"random":
			var ids := select_ids if not select_ids.is_empty() else REGISTRY.get_character_ids()
			selected_id = ids.pick_random()
			_refresh_fighter()
		_: action_requested.emit(action, value)

func refresh_body(next_body: String) -> void:
	body = next_body
	if screen == "select":
		_refresh_fighter()
	elif screen == "title":
		refresh_options()

## Handle navigation before focused buttons consume Enter. Main polls legacy shortcuts.
func _input(event: InputEvent) -> void:
	_audio_mouse_frame = Engine.get_process_frames() if event is InputEventMouseMotion and not event.relative.is_zero_approx() else -1
	if not visible or not is_visible_in_tree() or not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	if code == KEY_ESCAPE:
		AUDIO.sound(self, "ui_cancel")
		if screen == "results":
			action_requested.emit("return_title", "")
		else:
			show_title()
		get_viewport().set_input_as_handled()
	elif code in [KEY_ENTER, KEY_KP_ENTER, KEY_J]:
		get_viewport().set_input_as_handled()
		if screen == "select" and focus_index < portrait_buttons.size():
			AUDIO.sound(self, "ui_select")
			action_requested.emit("start", "")
		elif not buttons.is_empty() and focus_index >= 0:
			buttons[focus_index].pressed.emit()
	elif code in [KEY_UP, KEY_W, KEY_DOWN, KEY_S, KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D]:
		if screen == "select":
			var direction := SIDE_RIGHT
			if code in [KEY_UP, KEY_W]:
				direction = SIDE_TOP
			elif code in [KEY_DOWN, KEY_S]:
				direction = SIDE_BOTTOM
			elif code in [KEY_LEFT, KEY_A]:
				direction = SIDE_LEFT
			var neighbor := buttons[focus_index].find_valid_focus_neighbor(direction)
			if neighbor != null:
				_focus_from_navigation(neighbor)
		elif screen == "options" and code in [KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D] and _sound_row() != "":
			AUDIO_SETTINGS.step(_sound_row(), 10 if code in [KEY_RIGHT, KEY_D] else -10)
			AUDIO.sound(self, "ui_move")
			refresh_options()
		elif screen == "controls" and code in [KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D]:
			var tab := "pad" if code in [KEY_RIGHT, KEY_D] else "keys"
			if tab != controls_tab:
				AUDIO.sound(self, "ui_move")
				show_controls_tab(tab)
		else:
			var step := -1 if code in [KEY_UP, KEY_W, KEY_LEFT, KEY_A] else 1
			_move_focus(step)
		get_viewport().set_input_as_handled()

## The sound row (master, music, effects, mute) the options' focus is on, or "".
func _sound_row() -> String:
	if focus_index < 0 or focus_index >= buttons.size():
		return ""
	for key: String in audio_buttons:
		if audio_buttons[key] == buttons[focus_index]:
			return key
	return ""

func _move_focus(step: int) -> void:
	if buttons.is_empty():
		return
	focus_index = posmod(focus_index + step, buttons.size())
	for attempt in buttons.size():
		if not buttons[focus_index].disabled:
			break
		focus_index = posmod(focus_index + step, buttons.size())
	_focus_from_navigation(buttons[focus_index])
