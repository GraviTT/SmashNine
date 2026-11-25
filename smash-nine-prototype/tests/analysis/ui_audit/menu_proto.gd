extends Control
## Prototype menus for the next UI direction round (prepared 2026-11-25 while the match HUD round
## 2026-11-25-ui waits for its picks; reports/ui-direction-2026-11-25). Title and character select
## in the two ideas of the HUD round:
## "a" keeps today's places and puts everything in the story screens' gold frames (start card
##     frame for panels, name plate for buttons), with skill icons and bigger tiles;
## "b" is flat and slanted and built round the fighter: a menu column beside the key art, a
##     roster strip under a large illustration.
## It reads the real roster, kit texts, faces, illustrations and icons. Nothing in the game loads
## this file: menu_direction_capture.gd adds it over a Main whose own menu is hidden.

const ART := preload("res://scripts/ArtSettings.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const MENU := preload("res://scripts/ui/FrontendMenu.gd")
const SIZE := Vector2(1280, 720)
const INK := Color("0d1424")
const GOLD := Color("f3cd7c")
const DIM := Color("b7c3d6")
const WHITE := Color("f5f8fc")
const EDGE := Color(1, 1, 1, 0.16)
const PANEL_FRAME := "res://assets/art/story/start_card_frame.png"
const PLATE_FRAME := "res://assets/art/story/name_plate.png"
const SLOT_FRAME := "res://assets/art/ui/frames/skill_slot.png"
const LOGO := "res://assets/art/ui/title_logo.png"
const BACKGROUND := "res://assets/art/ui/title_bg.png"
const ICON := "res://assets/art/skill_icons/%s_%s.png"
const TITLE_ITEMS := ["Battle Royale", "Story", "Watch bots", "Options", "Controls"]

var style := "a"
var content: Control
var bold: FontVariation
var _roster := REGISTRY.get_characters()

func setup(new_style: String) -> void:
	style = new_style
	bold = FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 0.7
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_fit)
	_fit()

## The 1280x720 layout scaled to fit the window, as FrontendMenu does.
func _fit() -> void:
	var view := get_viewport().get_visible_rect().size
	var ratio := minf(view.x / SIZE.x, view.y / SIZE.y)
	scale = Vector2.ONE * ratio
	position = (view - SIZE * ratio) * 0.5
	size = SIZE

func _clear() -> void:
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content = Control.new()
	content.size = SIZE
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	# The key art the game's menus stand on, darkened the same way.
	var art := _picture(ART.original_texture(BACKGROUND), Rect2(Vector2.ZERO, SIZE), true)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate = Color(0.62, 0.62, 0.72, 1.0)
	var view := get_viewport().get_visible_rect().size / maxf(scale.x, 0.001)
	art.position = -position / maxf(scale.x, 0.001)
	art.size = view
	_fill(Rect2(art.position, art.size), Color(0.01, 0.015, 0.04, 0.34), 0)

# --- Small builders ---

func _box(color: Color, border := Color.TRANSPARENT, width := 0, radius := 4, skew := 0.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.skew = Vector2(skew, 0)
	box.anti_aliasing = true
	return box

func _plate(rect: Rect2, box: StyleBoxFlat) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", box)
	content.add_child(panel)
	return panel

func _fill(rect: Rect2, color: Color, radius := 3) -> Panel:
	return _plate(rect, _box(color, Color.TRANSPARENT, 0, radius))

func _text(text: String, rect: Rect2, font_size: int, color := WHITE, heavy := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if heavy:
		label.add_theme_font_override("font", bold)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)
	return label

## Running text: wraps at spaces (Korean breaks between any two syllables otherwise), top aligned.
func _lines(text: String, rect: Rect2, font_size: int, color := WHITE, max_lines := 3) -> Label:
	var words: PackedStringArray = []
	for word in text.split(" "):
		words.append("⁠".join(word.split("")))
	var label := _text(" ".join(words).replace("\n⁠", "\n"), rect, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.max_lines_visible = max_lines
	label.add_theme_constant_override("line_spacing", -1)
	return label

func _picture(texture: Texture2D, rect: Rect2, pixel := false) -> TextureRect:
	var picture := TextureRect.new()
	# Before the size: a TextureRect is otherwise held at its texture's own size.
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture = texture
	picture.position = rect.position
	picture.size = rect.size
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel else CanvasItem.TEXTURE_FILTER_LINEAR
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(picture)
	return picture

func _nine(path: String, rect: Rect2, margin: int) -> NinePatchRect:
	var patch := NinePatchRect.new()
	patch.texture = ART.original_texture(path)
	patch.patch_margin_left = margin
	patch.patch_margin_top = margin
	patch.patch_margin_right = margin
	patch.patch_margin_bottom = margin
	patch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	patch.position = rect.position
	patch.size = rect.size
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(patch)
	return patch

## "a": a dark panel inside the story screens' gold frame.
func _framed_panel(rect: Rect2, alpha := 0.93) -> void:
	_fill(Rect2(rect.position + Vector2(6, 6), rect.size - Vector2(12, 12)), Color(INK, alpha), 2)
	_nine(PANEL_FRAME, rect, 24)

## "a": a button on the story name plate; the focused one is filled gold.
func _plate_button(text: String, rect: Rect2, focused: bool, font_size := 20, key := "") -> void:
	_nine(PLATE_FRAME, rect, 12)
	if focused:
		# The plate's centre is opaque: the gold goes over it, inside the border.
		_fill(Rect2(rect.position + Vector2(5, 5), rect.size - Vector2(10, 10)), GOLD, 3)
	_text(text, rect, font_size, INK if focused else WHITE, focused, HORIZONTAL_ALIGNMENT_CENTER)
	if key != "":
		_key(key, Vector2(rect.end.x - 62, rect.position.y + rect.size.y * 0.5 - 11), 54, focused)

## "b": a slanted flat button; the focused one is gold.
func _slant_button(text: String, rect: Rect2, focused: bool, font_size := 20, key := "") -> void:
	_plate(rect, _box(GOLD if focused else Color(INK, 0.82), Color.TRANSPARENT if focused else EDGE, 0 if focused else 1, 3, 0.2))
	_text(text, Rect2(rect.position + Vector2(26, 0), rect.size - Vector2(40, 0)), font_size, INK if focused else WHITE, focused)
	if key != "":
		_key(key, Vector2(rect.end.x - 78, rect.position.y + rect.size.y * 0.5 - 11), 54, focused)

## A key cap: light with dark text, or dark on a gold button.
func _key(text: String, at: Vector2, width := 26.0, on_gold := false) -> void:
	_plate(Rect2(at, Vector2(width, 22)), _box(Color(INK, 0.9) if on_gold else Color(0.93, 0.95, 0.98, 0.95), Color.TRANSPARENT, 0, 4))
	_text(text, Rect2(at, Vector2(width, 22)), 15, GOLD if on_gold else INK, true, HORIZONTAL_ALIGNMENT_CENTER)

## A line of key hints on a backing, centred on `centre_x`: [["Enter", "확인"], ...].
func _hints(pairs: Array, centre_x: float, y: float) -> void:
	var font := ThemeDB.fallback_font
	var widths: Array[float] = []
	var total := 0.0
	for pair: Array in pairs:
		var key_width := maxf(26.0, font.get_string_size(str(pair[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 16.0)
		var word_width := font.get_string_size(str(pair[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		widths.append(key_width)
		total += key_width + 8.0 + word_width + 26.0
	total -= 26.0
	var x := centre_x - total * 0.5
	_fill(Rect2(x - 18, y - 6, total + 36, 34), Color(INK, 0.78), 17)
	for index in pairs.size():
		var pair: Array = pairs[index]
		_key(str(pair[0]), Vector2(x, y), widths[index])
		var word_width := font.get_string_size(str(pair[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		_text(str(pair[1]), Rect2(x + widths[index] + 8, y - 2, word_width + 4, 26), 16, WHITE)
		x += widths[index] + 8.0 + word_width + 26.0

# --- Title ---

func show_title(focus := 0) -> void:
	_clear()
	if style == "a":
		_title_a(focus)
	else:
		_title_b(focus)

func _title_a(focus: int) -> void:
	_framed_panel(Rect2(414, 66, 452, 592), 0.9)
	_picture(ART.original_texture(LOGO), Rect2(450, 92, 380, 126), true)
	_text(tr("NINE REALMS. ONE SURVIVOR."), Rect2(440, 222, 400, 28), 18, DIM, false, HORIZONTAL_ALIGNMENT_CENTER)
	# The two ways to play are the big buttons; the rest sit smaller under a rule.
	for index in 2:
		_plate_button(tr(TITLE_ITEMS[index]), Rect2(466, 270 + index * 68, 348, 58), focus == index, 23, "Enter" if focus == index else "")
	_fill(Rect2(486, 414, 308, 1), Color(GOLD, 0.35), 0)
	for index in range(2, TITLE_ITEMS.size()):
		_plate_button(tr(TITLE_ITEMS[index]), Rect2(486, 430 + (index - 2) * 54, 308, 46), focus == index, 19, "Enter" if focus == index else "")
	_text("언어  한국어      속도  100%", Rect2(440, 604, 400, 26), 16, DIM, false, HORIZONTAL_ALIGNMENT_CENTER)
	_hints([["↑↓", "이동"], ["Enter", "확인"], ["1~6", "바로 시작"]], 640, 674)
	_text(tr("Working title  /  Prototype"), Rect2(36, 20, 300, 26), 15, DIM)

func _title_b(focus: int) -> void:
	# No panel over the key art: the menu is a column on the left.
	_fill(Rect2(-40, 0, 560, 720), Color(INK, 0.42), 0)
	_picture(ART.original_texture(LOGO), Rect2(56, 44, 430, 136), true)
	_text(tr("NINE REALMS. ONE SURVIVOR."), Rect2(72, 184, 400, 28), 18, DIM)
	for index in 2:
		_slant_button(tr(TITLE_ITEMS[index]), Rect2(64, 252 + index * 74, 400, 62), focus == index, 25, "Enter" if focus == index else "")
	for index in range(2, TITLE_ITEMS.size()):
		_slant_button(tr(TITLE_ITEMS[index]), Rect2(64, 416 + (index - 2) * 56, 330, 46), focus == index, 19, "Enter" if focus == index else "")
	_text("언어  한국어      속도  100%", Rect2(72, 606, 400, 26), 16, DIM)
	_hints([["↑↓", "이동"], ["Enter", "확인"], ["1~6", "바로 시작"]], 264, 668)
	_text(tr("Working title  /  Prototype"), Rect2(944, 20, 300, 26), 15, DIM, false, HORIZONTAL_ALIGNMENT_RIGHT)

# --- Character select ---

func show_select(selected_id := "frey", body := "male") -> void:
	_clear()
	if style == "a":
		_select_a(selected_id, body)
	else:
		_select_b(selected_id, body)

func _kit_keys(kit: Array) -> Array:
	return ["j", "k", "l", "u", "i", ""] if kit.size() > 6 else ["j", "k", "l", "i", ""]

## One move: key cap, icon in a slot (the key letter when it has no icon), name and what it does.
func _kit_row(character_id: String, key: String, text: String, origin: Vector2, width: float, row_height: float, framed: bool) -> void:
	var slot := minf(row_height - 6.0, 42.0)
	# "a" (framed): the key cap stands left of the icon; "b": on the icon's corner.
	var at := origin + (Vector2(30, 0) if framed else Vector2.ZERO)
	var parts := text.split("/", true, 1)
	var title := parts[0].strip_edges()
	var detail := parts[1].strip_edges() if parts.size() > 1 else ""
	if key == "":
		_plate(Rect2(at, Vector2(slot, slot)), _box(Color(GOLD, 0.16), Color(GOLD, 0.6), 1, 4))
		_text("P", Rect2(at, Vector2(slot, slot)), 20, GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_plate(Rect2(at, Vector2(slot, slot)), _box(Color(INK, 0.96), EDGE, 0 if framed else 1, 2 if framed else 6))
		var icon := ART.original_texture(ICON % [character_id, key])
		if icon != null:
			_picture(icon, Rect2(at + Vector2(3, 3), Vector2(slot - 6, slot - 6)), true)
		else:
			_text(key.to_upper(), Rect2(at, Vector2(slot, slot)), 20, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		if framed:
			_nine(SLOT_FRAME, Rect2(at - Vector2(2, 2), Vector2(slot + 4, slot + 4)), 10)
		if framed:
			_key(key.to_upper(), origin + Vector2(0, slot * 0.5 - 11), 22)
		else:
			_key(key.to_upper(), at + Vector2(slot - 14, slot - 16), 22)
	var x := at.x + slot + 14.0
	var text_width := width - (x - origin.x)
	_text(title, Rect2(x, at.y - 2, text_width, 24), 17, WHITE, true)
	_lines(detail, Rect2(x, at.y + 21, text_width, row_height - 22), 15, DIM, 2 if row_height >= 54.0 else 1)

func _select_a(selected_id: String, body: String) -> void:
	var ids := REGISTRY.get_character_ids()
	var data: Dictionary = _roster[selected_id]
	_fill(Rect2(-200, 0, 1680, 104), Color(INK, 0.5), 0)
	_text(tr("CHOOSE YOUR FIGHTER"), Rect2(44, 22, 700, 48), 34, GOLD, true)
	_text(tr("Six fighters. Six ways to survive."), Rect2(46, 68, 700, 26), 17, DIM)
	# Roster: three bigger tiles a row, Random as a strip under them.
	_framed_panel(Rect2(28, 116, 412, 500))
	for index in ids.size():
		var id: String = ids[index]
		var at := Vector2(46 + (index % 3) * 126, 134 + (index / 3) * 158)
		var chosen := id == selected_id
		_plate(Rect2(at, Vector2(118, 150)), _box(Color(0.08, 0.11, 0.18, 0.98), GOLD if chosen else EDGE, 3 if chosen else 1, 4))
		var face := _picture(ART.character_portrait(id, body if REGISTRY.get_bodies(id).size() > 1 else ""), Rect2(at + Vector2(7, 7), Vector2(104, 104)))
		face.modulate = Color.WHITE if chosen else Color(0.82, 0.82, 0.88)
		_key(str(index + 1), at + Vector2(6, 6), 22)
		_text(tr(str(_roster[id].name)), Rect2(at + Vector2(0, 116), Vector2(118, 28)), 18, GOLD if chosen else WHITE, chosen, HORIZONTAL_ALIGNMENT_CENTER)
	_plate_button(tr("Random"), Rect2(46, 456, 370, 44), false, 18)
	# The body choice shows only for a fighter drawn in two bodies.
	if REGISTRY.get_bodies(selected_id).size() > 1:
		_text("체형", Rect2(50, 520, 60, 40), 17, DIM)
		for index in 2:
			var body_name: String = ["male", "female"][index]
			var on := body_name == body
			_plate(Rect2(112 + index * 126, 520, 120, 40), _box(GOLD if on else Color(INK, 0.96), Color(GOLD, 0.7), 1, 4))
			_text(tr(body_name.capitalize()), Rect2(112 + index * 126, 520, 120, 40), 17, INK if on else WHITE, on, HORIZONTAL_ALIGNMENT_CENTER)
		_key("V", Vector2(372, 529), 26)
	else:
		_text("체형이 하나인 캐릭터입니다", Rect2(50, 520, 366, 40), 16, Color(DIM, 0.7))
	_picture(MENU.illustration(selected_id, body), Rect2(446, 100, 352, 520))
	# The fighter: name, role, how it plays, and each move with its icon.
	_framed_panel(Rect2(804, 116, 448, 500))
	_text(tr(str(data.name)), Rect2(828, 130, 400, 52), 40, GOLD, true)
	_text(tr(str(data.role)), Rect2(830, 180, 400, 30), 21, WHITE)
	var kit: Array = MENU.KITS[selected_id]
	_lines(tr(str(kit[0])), Rect2(830, 212, 400, 58), 16, DIM, 3)
	var keys := _kit_keys(kit)
	var row := 64.0 if keys.size() == 5 else 55.0
	for index in keys.size():
		_kit_row(selected_id, str(keys[index]), tr(str(kit[index + 1])), Vector2(830, 278 + index * row), 398, row, true)
	_plate_button(tr("Back"), Rect2(452, 632, 196, 46), false, 19, "Esc")
	_plate_button(tr("Start match"), Rect2(1004, 628, 248, 58), true, 23, "Enter")
	_hints([["←→↑↓", "고르기"], ["1~6", "바로 시작"]], 826, 646)

func _select_b(selected_id: String, body: String) -> void:
	var ids := REGISTRY.get_character_ids()
	var data: Dictionary = _roster[selected_id]
	var accent: Color = data.color
	_plate(Rect2(-30, 22, 330, 50), _box(Color(INK, 0.86), Color.TRANSPARENT, 0, 3, 0.2))
	_text(tr("CHOOSE YOUR FIGHTER"), Rect2(28, 22, 260, 50), 26, WHITE, true)
	_key("Esc", Vector2(318, 36), 44)
	_text(tr("Back"), Rect2(370, 34, 80, 26), 16, WHITE)
	# The fighter stands large on the left, over a slanted band of its colour.
	_plate(Rect2(40, 150, 470, 380), _box(Color(accent.darkened(0.55), 0.55), Color.TRANSPARENT, 0, 4, 0.16))
	_picture(MENU.illustration(selected_id, body), Rect2(64, 54, 420, 580))
	# Who it is and how it plays, flat on the right.
	_fill(Rect2(548, 72, 696, 432), Color(INK, 0.9), 6)
	_plate(Rect2(548, 72, 696, 98), _box(accent.darkened(0.42), Color.TRANSPARENT, 0, 6))
	_fill(Rect2(548, 164, 696, 6), accent.lightened(0.35), 0)
	_text(tr(str(data.name)), Rect2(574, 74, 420, 62), 44, WHITE, true)
	_text(tr(str(data.role)), Rect2(576, 132, 500, 28), 19, Color(1, 1, 1, 0.92))
	var kit: Array = MENU.KITS[selected_id]
	_lines(tr(str(kit[0])), Rect2(574, 182, 644, 46), 16, DIM, 2)
	var keys := _kit_keys(kit)
	# Two columns of moves: the icons read as a kit at a glance.
	for index in keys.size():
		var column := index % 2
		_kit_row(selected_id, str(keys[index]), tr(str(kit[index + 1])), Vector2(574 + column * 330, 244 + (index / 2) * 84), 310, 76, false)
	# The roster as a strip: faces big enough to tell apart, the chosen one lifted.
	_fill(Rect2(536, 510, 720, 136), Color(INK, 0.72), 6)
	for index in ids.size() + 1:
		var random := index == ids.size()
		var id: String = "" if random else ids[index]
		var chosen := id == selected_id
		var at := Vector2(548 + index * 100, 524 - (10 if chosen else 0))
		_plate(Rect2(at, Vector2(92, 92)), _box(Color(0.08, 0.11, 0.18, 0.98), GOLD if chosen else EDGE, 3 if chosen else 1, 6))
		if random:
			_text("?", Rect2(at, Vector2(92, 92)), 44, DIM, true, HORIZONTAL_ALIGNMENT_CENTER)
			_text(tr("Random"), Rect2(at + Vector2(-10, 94), Vector2(112, 24)), 15, DIM, false, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var face := _picture(ART.character_portrait(id, body if REGISTRY.get_bodies(id).size() > 1 else ""), Rect2(at + Vector2(4, 4), Vector2(84, 84)))
			face.modulate = Color.WHITE if chosen else Color(0.78, 0.78, 0.86)
			_key(str(index + 1), at + Vector2(4, 4), 22)
			_text(tr(str(_roster[id].name)), Rect2(at + Vector2(-10, 94 + (10 if chosen else 0)), Vector2(112, 24)), 16 if chosen else 15, GOLD if chosen else DIM, chosen, HORIZONTAL_ALIGNMENT_CENTER)
	if REGISTRY.get_bodies(selected_id).size() > 1:
		_key("V", Vector2(72, 650), 26)
		_text("체형", Rect2(106, 646, 50, 30), 16, DIM)
		for index in 2:
			var body_name: String = ["male", "female"][index]
			var on := body_name == body
			_plate(Rect2(160 + index * 104, 644, 100, 36), _box(GOLD if on else Color(INK, 0.86), Color.TRANSPARENT if on else EDGE, 0 if on else 1, 3, 0.2))
			_text(tr(body_name.capitalize()), Rect2(160 + index * 104, 644, 100, 36), 16, INK if on else WHITE, on, HORIZONTAL_ALIGNMENT_CENTER)
	_slant_button(tr("Start match"), Rect2(968, 650, 276, 56), true, 24, "Enter")
