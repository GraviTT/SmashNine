extends CanvasLayer
## In-match overlay: phase clock, survivors, souls, 3x3 realm minimap, soul card
## offer, announcement line, debug panel (F3), and the start / result screens.

const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const ART_CREDITS := "Original art made for Smash Nine Realms (working title).  F2 switches realms and effects to the plain procedural look."
const TITLE_LOGO_ART := "res://assets/art/ui/title_logo.png"
const CONTROLS_HINT := "A/D move  W jump  S+S drop  Space guard  J attack  K/L skills  I ultimate  Q portal  1-3 soul card  F3 debug"
const PANEL_COLOR := Color(0.03, 0.03, 0.07, 0.78)
const CARD_COLOR := Color(0.1, 0.08, 0.2, 0.92)
const TEXT_DIM := Color(1.0, 1.0, 1.0, 0.7)
const REFERENCE_SIZE := Vector2(1280, 720)
const TOP_CENTER := Vector2(0.5, 0.0)
const TOP_RIGHT := Vector2(1.0, 0.0)
const BOTTOM_LEFT := Vector2(0.0, 1.0)
const BOTTOM_CENTER := Vector2(0.5, 1.0)

var info_label: Label
var clock_label: Label
var realm_label: Label
var warning_label: Label
var results_grid: GridContainer
var status_label: Label
## The followed fighter's face (CODEX-ART-08) beside the status line.
var focus_frame: ColorRect
var focus_portrait: TextureRect
var focus_portrait_key := ""
var debug_label: Label
var minimap_root: Control
var minimap_labels: Dictionary = {}
var card_panel: Control
var card_title: Label
var card_labels: Array[Label] = []
var card_icons: Array[TextureRect] = []
var overlay: Control
var overlay_title: Label
var overlay_logo: TextureRect
var portrait_strip: Control
var overlay_body: Label
var overlay_credits: Label

func _ready() -> void:
	name = "UI"
	clock_label = _label(Vector2(390, 12), Vector2(500, 30), 20, HORIZONTAL_ALIGNMENT_CENTER)
	status_label = _label(Vector2(782, 12), Vector2(390, 60), 16, HORIZONTAL_ALIGNMENT_RIGHT)
	focus_frame = ColorRect.new()
	focus_frame.position = Vector2(1184, 8)
	focus_frame.size = Vector2(80, 80)
	focus_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_frame.visible = false
	add_child(focus_frame)
	focus_portrait = _portrait_rect(Vector2(1186, 10), Vector2(76, 76))
	add_child(focus_portrait)
	realm_label = _label(Vector2(390, 40), Vector2(500, 26), 16, HORIZONTAL_ALIGNMENT_CENTER)
	warning_label = _label(Vector2(240, 96), Vector2(800, 90), 30, HORIZONTAL_ALIGNMENT_CENTER)
	warning_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.22))
	warning_label.visible = false
	info_label = _label(Vector2(24, 664), Vector2(1232, 48), 15, HORIZONTAL_ALIGNMENT_LEFT)
	info_label.text = CONTROLS_HINT
	debug_label = _label(Vector2(870, 80), Vector2(390, 360), 13, HORIZONTAL_ALIGNMENT_LEFT)
	debug_label.visible = false

	minimap_root = Control.new()
	minimap_root.name = "RealmMinimap"
	minimap_root.position = Vector2(24, 52)
	minimap_root.size = Vector2(190, 110)
	minimap_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(minimap_root)

	_build_card_panel()
	_build_overlay()
	# Keep each element on its screen edge for any window shape (web canvases are not 16:9).
	for entry in [[clock_label, TOP_CENTER], [realm_label, TOP_CENTER], [warning_label, TOP_CENTER],
			[status_label, TOP_RIGHT], [focus_frame, TOP_RIGHT], [focus_portrait, TOP_RIGHT],
			[debug_label, TOP_RIGHT], [info_label, BOTTOM_LEFT],
			[card_panel, BOTTOM_CENTER]]:
		_pin(entry[0], entry[1])

## Re-expresses a control laid out on the 1280x720 reference as an offset from an
## anchor point, e.g. (0.5, 1) = bottom centre.
func _pin(control: Control, anchor: Vector2) -> void:
	var position := control.position
	var size := control.size
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = position.x - anchor.x * REFERENCE_SIZE.x
	control.offset_top = position.y - anchor.y * REFERENCE_SIZE.y
	control.offset_right = control.offset_left + size.x
	control.offset_bottom = control.offset_top + size.y

func _label(position: Vector2, size: Vector2, font_size: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	return label

func show_message(text: String) -> void:
	info_label.text = text

func set_debug_text(text: String) -> void:
	debug_label.text = text

func toggle_debug() -> void:
	debug_label.visible = not debug_label.visible

func set_clock(phase: String, elapsed: float, next_label: String, next_in: float) -> void:
	var text := "%s   %s" % [phase, _format_time(elapsed)]
	if next_label != "":
		text += "   |   %s in %s" % [next_label, _format_time(next_in)]
	clock_label.text = text

func set_status(alive: int, total: int, focus: Node) -> void:
	var lines: Array[String] = ["Alive %d / %d" % [alive, total]]
	if is_instance_valid(focus):
		var next_threshold: int = focus.get_next_soul_threshold()
		var soul_text := "Souls %d" % focus.souls
		soul_text += "  (next card %d)" % next_threshold if next_threshold > 0 else "  (all cards taken)"
		lines.append("%s  HP %.0f/%.0f  KOs %d   %s" % [focus.display_name, focus.hp, focus.max_hp, focus.score, soul_text])
	status_label.text = "\n".join(lines)
	_show_focus_portrait(focus)

func _show_focus_portrait(focus: Node) -> void:
	var key := "" if not is_instance_valid(focus) else "%s/%s" % [focus.character_id, focus.body_type]
	if key == focus_portrait_key:
		return
	focus_portrait_key = key
	var texture: Texture2D = null if key == "" else ART_SETTINGS.character_portrait(focus.character_id, focus.body_type)
	_set_portrait(focus_portrait, texture)
	focus_frame.visible = texture != null and focus_portrait.visible
	if is_instance_valid(focus):
		focus_frame.color = Color(focus.body_color, 0.55)

## A portrait slot: painted faces scale smoothly, pixel portraits stay crisp.
func _portrait_rect(position: Vector2, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.position = position
	rect.size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func _set_portrait(rect: TextureRect, texture: Texture2D) -> void:
	rect.texture = texture
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if ART_SETTINGS.is_painted_portrait(texture) else CanvasItem.TEXTURE_FILTER_NEAREST

func _format_time(seconds: float) -> String:
	var whole := maxi(0, int(seconds))
	return "%d:%02d" % [whole / 60, whole % 60]

# --- Minimap ---

func rebuild_minimap(layout: RefCounted, director: Node, current_index: int) -> void:
	for child in minimap_root.get_children():
		child.queue_free()
	minimap_labels.clear()
	var cell := Vector2(60, 34)
	for i in layout.realm_count():
		var grid: Vector2i = layout.get_realm(i).grid
		var box := ColorRect.new()
		box.position = Vector2(grid.x * (cell.x + 4), grid.y * (cell.y + 4))
		box.size = cell
		box.color = _get_state_color(director.get_state(i), i == current_index)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		minimap_root.add_child(box)
		var label := Label.new()
		label.position = box.position + Vector2(3, 1)
		label.size = cell - Vector2(6, 2)
		label.add_theme_font_size_override("font_size", 9)
		minimap_root.add_child(label)
		minimap_labels[i] = {"label": label, "name": str(layout.get_realm(i).name).left(9)}
	update_minimap_labels(director, {})

## counts: realm_index -> living combatants there
func update_minimap_labels(director: Node, counts: Dictionary) -> void:
	var seconds_left: int = director.get_warning_seconds_left()
	for i in minimap_labels:
		var entry: Dictionary = minimap_labels[i]
		var label: Label = entry.label
		if not is_instance_valid(label):
			continue
		var state: String = director.get_state(i)
		var detail := "! %ds" % seconds_left if state == "warning" else state.to_upper()
		if state == "stable" or state == "warning":
			detail += "  x%d" % int(counts.get(i, 0))
		label.text = "%s\n%s" % [entry.name, detail]

func _get_state_color(state: String, is_current: bool) -> Color:
	if is_current:
		return Color(0.35, 0.8, 1.0, 0.72)
	match state:
		"locked":
			return Color(0.25, 0.25, 0.3, 0.75)
		"warning":
			return Color(1.0, 0.28, 0.1, 0.78)
		"collapsed":
			return Color(0.03, 0.03, 0.035, 0.86)
		_:
			return Color(0.14, 0.18, 0.22, 0.72)

# --- Soul card offer ---

func _build_card_panel() -> void:
	card_panel = Control.new()
	card_panel.name = "SoulCards"
	card_panel.position = Vector2(290, 520)
	card_panel.size = Vector2(700, 130)
	card_panel.visible = false
	card_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_panel)
	card_title = Label.new()
	card_title.size = Vector2(700, 26)
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.add_theme_font_size_override("font_size", 17)
	card_panel.add_child(card_title)
	for index in 3:
		var back := ColorRect.new()
		back.position = Vector2(index * 236, 30)
		back.size = Vector2(224, 96)
		back.color = CARD_COLOR
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_panel.add_child(back)
		var icon := TextureRect.new()
		icon.position = back.position + Vector2(8, 24)
		icon.size = Vector2(48, 48)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_panel.add_child(icon)
		card_icons.append(icon)
		var label := Label.new()
		label.position = back.position + Vector2(64, 8)
		label.size = back.size - Vector2(72, 16)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 15)
		card_panel.add_child(label)
		card_labels.append(label)

func show_card_offer(cards: Array, seconds_left: float) -> void:
	card_panel.visible = true
	card_title.text = "Soul card  -  press 1 / 2 / 3   (%.0fs)" % ceilf(seconds_left)
	for index in card_labels.size():
		var label := card_labels[index]
		if index < cards.size():
			var card: Dictionary = cards[index]
			label.text = "[%d] %s\n%s\n(%s)" % [index + 1, card.title, card.text, card.kind]
			# Original card icon (assets/art/ui/card_<id>.png); none in the prototype style.
			card_icons[index].texture = ART_SETTINGS.original_texture("res://assets/art/ui/card_%s.png" % card.id)
		else:
			label.text = ""
			card_icons[index].texture = null

func hide_card_offer() -> void:
	card_panel.visible = false

# --- Start and result screens ---

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var back := ColorRect.new()
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.color = PANEL_COLOR
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(back)
	overlay_title = Label.new()
	overlay_title.position = Vector2(0, 110)
	overlay_title.size = Vector2(1280, 70)
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.add_theme_font_size_override("font_size", 48)
	overlay_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.4))
	overlay.add_child(overlay_title)
	_pin(overlay_title, TOP_CENTER)
	# Original title logo (CODEX-ART-06) drawn at half size in place of the title text.
	overlay_logo = TextureRect.new()
	overlay_logo.position = Vector2(480, 92)
	overlay_logo.size = Vector2(320, 100)
	overlay_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay_logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay_logo.texture = ART_SETTINGS.original_texture(TITLE_LOGO_ART)
	overlay_logo.visible = false
	overlay_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(overlay_logo)
	_pin(overlay_logo, TOP_CENTER)
	overlay_body = Label.new()
	overlay_body.position = Vector2(240, 200)
	overlay_body.size = Vector2(800, 480)
	overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_body.add_theme_font_size_override("font_size", 19)
	overlay.add_child(overlay_body)
	_pin(overlay_body, TOP_CENTER)
	overlay_credits = Label.new()
	overlay_credits.position = Vector2(40, 650)
	overlay_credits.size = Vector2(1200, 50)
	overlay_credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_credits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_credits.add_theme_font_size_override("font_size", 12)
	overlay_credits.modulate = TEXT_DIM
	overlay_credits.text = ART_CREDITS
	overlay.add_child(overlay_credits)
	_pin(overlay_credits, BOTTOM_CENTER)

## A column of fighter portraits left of the menu (original style only); characters drawn
## in two bodies show the body P1 picked with V.
func _show_portraits(characters: Array[Dictionary], body: String) -> void:
	if is_instance_valid(portrait_strip):
		portrait_strip.queue_free()
	portrait_strip = Control.new()
	portrait_strip.name = "Portraits"
	portrait_strip.position = Vector2(150, 200)
	portrait_strip.size = Vector2(160, characters.size() * 76)
	portrait_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(portrait_strip)
	_pin(portrait_strip, TOP_CENTER)
	for index in characters.size():
		var data: Dictionary = characters[index]
		var portrait := ART_SETTINGS.character_portrait(str(data.id), body if data.get("bodies", []).size() > 1 else "")
		if portrait == null:
			continue
		var frame := ColorRect.new()
		frame.position = Vector2(40, index * 76)
		frame.size = Vector2(68, 68)
		frame.color = Color(data.color, 0.35)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_strip.add_child(frame)
		var picture := _portrait_rect(frame.position + Vector2(2, 2), Vector2(64, 64))
		_set_portrait(picture, portrait)
		portrait_strip.add_child(picture)
		var key := Label.new()
		key.position = Vector2(0, index * 76 + 20)
		key.size = Vector2(36, 28)
		key.text = "[%d]" % (index + 1)
		key.add_theme_font_size_override("font_size", 17)
		portrait_strip.add_child(key)

func show_start_screen(characters: Array[Dictionary], body := "male") -> void:
	overlay_title.text = "SMASH NINE REALMS" if overlay_logo.texture == null else ""
	overlay_logo.visible = overlay_logo.texture != null
	_show_portraits(characters, body)
	var lines: Array[String] = ["Nine realms are collapsing into the heart of Yggdrasil.", "Be the last one standing.", "", "Choose your fighter"]
	for index in characters.size():
		var data: Dictionary = characters[index]
		lines.append("[%d]  %s  -  %s" % [index + 1, data.name, data.role])
	var two_bodies: Array[String] = []
	for data in characters:
		if data.get("bodies", []).size() > 1:
			two_bodies.append(str(data.name))
	if not two_bodies.is_empty():
		lines.append("[V]  Body for %s: %s  (switch)" % [", ".join(two_bodies), body.capitalize()])
	lines.append("")
	lines.append("[B]  Watch a bots-only match")
	lines.append("[F2]  Art: %s  (switch)" % ART_SETTINGS.label())
	lines.append("")
	lines.append(CONTROLS_HINT)
	_set_match_hud_visible(false)
	overlay_body.text = "\n".join(lines)
	overlay_credits.visible = true
	overlay.visible = true

## survival: combatant -> seconds survived (MatchDirector.get_survival_time).
func show_results(winner: Node, reason: String, standings: Array[Node], human: Node, survival: Dictionary = {}) -> void:
	overlay_logo.visible = false
	if is_instance_valid(portrait_strip):
		portrait_strip.visible = false
	overlay_title.text = "%s WINS" % winner.display_name.to_upper() if is_instance_valid(winner) else "DRAW"
	overlay_body.text = "Decided by %s" % reason
	info_label.visible = false
	warning_label.visible = false
	if is_instance_valid(results_grid):
		results_grid.queue_free()
	results_grid = GridContainer.new()
	results_grid.columns = 8
	results_grid.position = Vector2(200, 250)
	results_grid.add_theme_constant_override("h_separation", 34)
	results_grid.add_theme_constant_override("v_separation", 4)
	overlay.add_child(results_grid)
	_pin(results_grid, TOP_CENTER)
	for header in ["#", "", "Fighter", "Survived", "KOs", "Damage", "Souls", "Cards"]:
		_add_result_cell(header, Color(1.0, 0.82, 0.4))
	for index in standings.size():
		var player: Node = standings[index]
		if not is_instance_valid(player):
			continue
		var color := Color(1.0, 0.92, 0.55) if player == human else Color.WHITE
		_add_result_cell(str(index + 1), color)
		var face := _portrait_rect(Vector2.ZERO, Vector2(28, 28))
		face.custom_minimum_size = Vector2(28, 28)
		_set_portrait(face, ART_SETTINGS.character_portrait(player.character_id, player.body_type))
		results_grid.add_child(face)
		_add_result_cell(("P1 " if player == human else "") + player.display_name, color)
		var seconds := int(survival.get(player, -1.0))
		_add_result_cell("%d:%02d" % [seconds / 60, seconds % 60] if seconds >= 0 else "-", color)
		_add_result_cell(str(player.score), color)
		_add_result_cell("%.0f" % player.damage_dealt, color)
		_add_result_cell(str(player.souls), color)
		_add_result_cell(", ".join(player.upgrades), color)
	_add_result_cell("", Color.WHITE)
	_add_result_cell("", Color.WHITE)
	_add_result_cell("[R] play again", Color(1.0, 0.82, 0.4))
	overlay_credits.visible = false
	overlay.visible = true

func _add_result_cell(text: String, color: Color) -> void:
	var cell := Label.new()
	cell.text = text
	cell.add_theme_font_size_override("font_size", 18)
	cell.add_theme_color_override("font_color", color)
	results_grid.add_child(cell)

func hide_overlay() -> void:
	_set_match_hud_visible(true)
	overlay.visible = false

func set_realm_title(text: String, accent: Color) -> void:
	realm_label.text = text
	realm_label.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.9))

## seconds < 0 hides the banner.
## Collapse countdown (seconds >= 0) wins over a realm hazard warning; both empty hides it.
func set_warning_banner(seconds: int, hazard_warning := "") -> void:
	warning_label.visible = seconds >= 0 or hazard_warning != ""
	if seconds >= 0:
		warning_label.text = "COLLAPSE WARNING  %d\nfind a portal to a safe realm" % seconds
	elif hazard_warning != "":
		warning_label.text = hazard_warning.to_upper()

## The in-match HUD hides behind the start screen so it does not show through it.
func _set_match_hud_visible(visible_now: bool) -> void:
	for node in [clock_label, realm_label, status_label, info_label, minimap_root, focus_portrait]:
		node.visible = visible_now
	focus_frame.visible = visible_now and focus_portrait.texture != null
	if not visible_now:
		warning_label.visible = false
		card_panel.visible = false
