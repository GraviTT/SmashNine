extends CanvasLayer
## In-match overlay: phase clock, survivors, souls, 3x3 realm minimap, soul card
## offer, announcement line, debug panel (F3), and the start / result screens.

const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const SOUL_CARDS := preload("res://scripts/match/SoulCards.gd")
const ART_CREDITS := "Original art made for Smash Nine Realms (working title).  F2 switches realms and effects to the plain procedural look."
const TITLE_LOGO_ART := "res://assets/art/ui/title_logo.png"
const REALM_EMBLEM_ART := "res://assets/art/ui/realm_emblems/%s.png"
const CUTIN_BAND_ART := "res://assets/art/vfx/ult_cutin_band.png"
const CONTROLS_HINT := "A/D move  W jump  S+S drop  Space guard  J attack  K/L skills  I ultimate  Q portal  1-3 soul card  F3 debug  F4 bots"
## Bottom right, all match (user 2026-10-08: "화면 오른쪽 아래에 조작키를 간단히 표시하고, 스킬
## 아이콘도 간단하게"): the focused fighter's four moves as icon slots with their keys, and the
## other keys in one short line under them.
const CONTROLS_SHORT := "A/D move   W jump   S+S drop   Space guard   Q portal   F4 bots"
const SKILL_ICON_ART := "res://assets/art/skill_icons/%s.png"
const SKILL_SLOTS: Array[String] = ["j", "k", "l", "i"]
const SKILL_SLOT_SIZE := 48.0
const SKILL_SLOT_GAP := 6.0
const SKILL_BAR_MARGIN := 12.0
const SKILL_SLOT_COLOR := Color(0.08, 0.09, 0.14, 0.82)
const SKILL_READY_COLOR := Color(1.0, 0.82, 0.35)
## Live bot panel (F4, development aid 2026-10-08): on by default while the game is tested.
const BOT_PANEL_SHOWN_AT_START := true
const BOT_PANEL_WIDTH := 300.0
const BOT_ROW_FACE := 26.0
## The bottom-left line shows match messages and fades out this long after each (QA-15 #9: the
## controls covered the floor all match; they now sit bottom right).
const MESSAGE_TIME := 4.0
const PANEL_COLOR := Color(0.03, 0.03, 0.07, 0.78)
## The results table hides the match behind it (QA-15: the world showed through at 0.78).
const RESULTS_BACK_COLOR := Color(0.03, 0.03, 0.07, 0.92)
## Cut-in band heights: above the fighters when the caster is in the lower half of the screen,
## below them otherwise, so the band never covers the cast itself (Codex QA-12: at a fixed
## y 230 it hid Frey and the first wave).
const CUTIN_HIGH_Y := 172.0
const CUTIN_LOW_Y := 536.0
const CARD_COLOR := Color(0.1, 0.08, 0.2, 0.92)
const TEXT_DIM := Color(1.0, 1.0, 1.0, 0.7)
const REFERENCE_SIZE := Vector2(1280, 720)
const TOP_CENTER := Vector2(0.5, 0.0)
const TOP_RIGHT := Vector2(1.0, 0.0)
const BOTTOM_LEFT := Vector2(0.0, 1.0)
const BOTTOM_CENTER := Vector2(0.5, 1.0)
const BOTTOM_RIGHT := Vector2(1.0, 1.0)

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
var overlay_back: ColorRect
## The bot panel's on/off choice (F4), kept while screens hide the match HUD.
var bot_panel_wanted := BOT_PANEL_SHOWN_AT_START
var overlay_title: Label
var overlay_logo: TextureRect
var portrait_strip: Control
## Ultimate cut-in: a coloured band with the caster's face, name and ultimate name.
var cutin_root: Control
var cutin_band: Control
var cutin_face: TextureRect
var cutin_name: Label
var cutin_title: Label
var cutin_tween: Tween
var flash_rect: ColorRect
## Arrows at the screen edge toward fighters in the shown realm who are off screen (realms
## are bigger than the view since 2026-10-08).
var offscreen_root: Node2D
var hazard_label: Label
var skill_bar: Control
var controls_label: Label
## slot -> {"style", "icon", "glyph", "key", "shade", "time"}
var skill_slots: Dictionary = {}
var skill_icon_set := ""
var skill_pulse := 0.0
var info_timer := 0.0
var info_fade: Tween
## Right-hand list of every fighter: face, realm, HP and what its bot is trying to do.
var bot_panel: PanelContainer
var bot_rows: VBoxContainer
var bot_row_nodes: Array = []
var offscreen_markers: Array[Polygon2D] = []
var flash_tween: Tween
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
	# Realm title, then its hazard on a third line, both kept left of the status block (QA-15:
	# a long title ran into "Frey HP ..." on the right).
	realm_label = _label(Vector2(400, 40), Vector2(380, 24), 16, HORIZONTAL_ALIGNMENT_CENTER)
	realm_label.clip_text = true
	hazard_label = _label(Vector2(400, 62), Vector2(380, 20), 13, HORIZONTAL_ALIGNMENT_CENTER)
	warning_label = _label(Vector2(240, 96), Vector2(800, 90), 30, HORIZONTAL_ALIGNMENT_CENTER)
	warning_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.22))
	warning_label.visible = false
	# Messages only; it stops short of the skill bar on the right.
	info_label = _label(Vector2(24, 664), Vector2(820, 48), 15, HORIZONTAL_ALIGNMENT_LEFT)
	info_label.visible = false
	# Sized to its text on a faint backing, so platforms behind it do not cut through the words.
	var controls_width := controls_label_width()
	controls_label = _label(Vector2(1280.0 - SKILL_BAR_MARGIN - controls_width, 720.0 - SKILL_BAR_MARGIN - 18.0), Vector2(controls_width, 18), 12, HORIZONTAL_ALIGNMENT_CENTER)
	controls_label.text = CONTROLS_SHORT
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(0.02, 0.03, 0.06, 0.55)
	backing.set_corner_radius_all(4)
	controls_label.add_theme_stylebox_override("normal", backing)
	_build_skill_bar()
	debug_label = _label(Vector2(870, 80), Vector2(390, 360), 13, HORIZONTAL_ALIGNMENT_LEFT)
	debug_label.visible = false

	minimap_root = Control.new()
	minimap_root.name = "RealmMinimap"
	minimap_root.position = Vector2(24, 52)
	minimap_root.size = Vector2(212, 116)
	minimap_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(minimap_root)

	_build_card_panel()
	_build_cutin()
	offscreen_root = Node2D.new()
	offscreen_root.name = "OffscreenMarkers"
	add_child(offscreen_root)
	_build_bot_panel()
	_build_overlay()
	# Keep each element on its screen edge for any window shape (web canvases are not 16:9).
	for entry in [[clock_label, TOP_CENTER], [realm_label, TOP_CENTER], [hazard_label, TOP_CENTER], [warning_label, TOP_CENTER],
			[status_label, TOP_RIGHT], [focus_frame, TOP_RIGHT], [focus_portrait, TOP_RIGHT],
			[debug_label, TOP_RIGHT], [bot_panel, TOP_RIGHT], [info_label, BOTTOM_LEFT],
			[skill_bar, BOTTOM_RIGHT], [controls_label, BOTTOM_RIGHT],
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
	_show_info(MESSAGE_TIME)

func _show_info(seconds: float) -> void:
	if info_fade != null and info_fade.is_valid():
		info_fade.kill()
	info_label.modulate.a = 1.0
	info_label.visible = clock_label.visible
	info_timer = seconds

func set_debug_text(text: String) -> void:
	debug_label.text = text

func toggle_debug() -> void:
	debug_label.visible = not debug_label.visible

func toggle_bot_panel() -> void:
	if not clock_label.visible:
		bot_panel_wanted = not bot_panel_wanted
		return
	bot_panel.visible = not bot_panel.visible

func controls_label_width() -> float:
	return ThemeDB.fallback_font.get_string_size(CONTROLS_SHORT, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 14.0

func _build_skill_bar() -> void:
	skill_bar = Control.new()
	skill_bar.name = "SkillBar"
	skill_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var width := SKILL_SLOTS.size() * SKILL_SLOT_SIZE + (SKILL_SLOTS.size() - 1) * SKILL_SLOT_GAP
	skill_bar.size = Vector2(width, SKILL_SLOT_SIZE)
	skill_bar.position = Vector2(1280.0 - SKILL_BAR_MARGIN - width, 720.0 - SKILL_BAR_MARGIN - 18.0 - 6.0 - SKILL_SLOT_SIZE)
	add_child(skill_bar)
	for index in SKILL_SLOTS.size():
		var slot: String = SKILL_SLOTS[index]
		var panel := Panel.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.position = Vector2(index * (SKILL_SLOT_SIZE + SKILL_SLOT_GAP), 0.0)
		panel.size = Vector2(SKILL_SLOT_SIZE, SKILL_SLOT_SIZE)
		panel.clip_contents = true
		var style := StyleBoxFlat.new()
		style.bg_color = SKILL_SLOT_COLOR
		style.set_corner_radius_all(6)
		style.set_border_width_all(1)
		style.border_color = Color(1, 1, 1, 0.25)
		panel.add_theme_stylebox_override("panel", style)
		skill_bar.add_child(panel)
		# The icon (CODEX-ART-18, 40 px at 1:1), or the key letter in the fighter's colour.
		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.position = Vector2(4, 4)
		icon.size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		panel.add_child(icon)
		var glyph := _slot_label(slot.to_upper(), Vector2.ZERO, panel.size, 22, HORIZONTAL_ALIGNMENT_CENTER)
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(glyph)
		# Cooldown: a shade from the top for the share still to wait, and the seconds.
		var shade := ColorRect.new()
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.color = Color(0.0, 0.0, 0.0, 0.62)
		shade.size = Vector2(SKILL_SLOT_SIZE, 0.0)
		panel.add_child(shade)
		var time := _slot_label("", Vector2.ZERO, panel.size, 16, HORIZONTAL_ALIGNMENT_CENTER)
		time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(time)
		var key := _slot_label(slot.to_upper(), Vector2(29, 29), Vector2(16, 16), 11, HORIZONTAL_ALIGNMENT_CENTER)
		key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var badge := StyleBoxFlat.new()
		badge.bg_color = Color(0.0, 0.0, 0.0, 0.7)
		badge.set_corner_radius_all(3)
		key.add_theme_stylebox_override("normal", badge)
		panel.add_child(key)
		skill_slots[slot] = {"style": style, "icon": icon, "glyph": glyph, "key": key, "shade": shade, "time": time}

func _slot_label(text: String, position: Vector2, size: Vector2, font_size: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.position = position
	label.size = size
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 3)
	return label

## The focused fighter's moves: icons by character (Brave Luna's set while she is transformed),
## a shade and seconds while a move cools down, a gold edge when the ultimate is ready.
func update_skill_bar(fighter: Node, delta: float) -> void:
	if not skill_bar.visible:
		return
	if not is_instance_valid(fighter):
		skill_bar.modulate.a = 0.0
		return
	skill_bar.modulate.a = 0.55 if bool(fighter.get("is_defeated")) else 1.0
	var character_id := str(fighter.get("character_id"))
	var icon_set := "%s%s|%s" % [character_id, "_brave" if fighter.get("transformed") == true else "", ART_SETTINGS.use_original()]
	if icon_set != skill_icon_set:
		skill_icon_set = icon_set
		var accent: Color = fighter.get("body_color") if fighter.get("body_color") is Color else Color.WHITE
		for slot in SKILL_SLOTS:
			var nodes: Dictionary = skill_slots[slot]
			var texture := ART_SETTINGS.original_texture(SKILL_ICON_ART % ("%s_%s" % [icon_set.get_slice("|", 0), slot]))
			nodes.icon.texture = texture
			nodes.glyph.add_theme_color_override("font_color", accent.lerp(Color.WHITE, 0.35))
			nodes.key.visible = texture != null
	skill_pulse += delta
	for slot in SKILL_SLOTS:
		var nodes: Dictionary = skill_slots[slot]
		var cooldown: Vector2 = fighter.skill_cooldown(slot) if fighter.has_method("skill_cooldown") else Vector2.ZERO
		var waiting: float = clampf(cooldown.x / cooldown.y, 0.0, 1.0) if cooldown.y > 0.0 else 0.0
		nodes.shade.size = Vector2(SKILL_SLOT_SIZE, SKILL_SLOT_SIZE * waiting)
		nodes.time.text = "%d" % ceili(cooldown.x) if cooldown.x > 0.0 else ""
		# Without an icon the key letter fills the slot; the seconds take its place while waiting.
		nodes.glyph.visible = nodes.icon.texture == null and cooldown.x <= 0.0
		var style: StyleBoxFlat = nodes.style
		if slot == "i" and cooldown.x <= 0.0:
			var pulse := 0.65 + 0.35 * sin(skill_pulse * 6.0)
			style.border_color = Color(SKILL_READY_COLOR, pulse)
			style.set_border_width_all(2)
		else:
			style.border_color = Color(1, 1, 1, 0.25)
			style.set_border_width_all(1)

func _build_bot_panel() -> void:
	bot_panel = PanelContainer.new()
	bot_panel.name = "BotPanel"
	bot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.03, 0.06, 0.55)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	bot_panel.add_theme_stylebox_override("panel", style)
	bot_panel.position = Vector2(1280.0 - BOT_PANEL_WIDTH - 6.0, 96.0)
	bot_panel.size = Vector2(BOT_PANEL_WIDTH, 0.0)
	bot_panel.visible = BOT_PANEL_SHOWN_AT_START
	add_child(bot_panel)
	bot_rows = VBoxContainer.new()
	bot_rows.add_theme_constant_override("separation", 3)
	bot_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot_panel.add_child(bot_rows)

## rows: [{"face": Texture2D or null, "color": Color, "title": String, "lines": String,
## "dim": bool}], one per fighter, in a stable order.
func update_bot_panel(rows: Array) -> void:
	if not bot_panel.visible:
		return
	while bot_row_nodes.size() < rows.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var face := TextureRect.new()
		face.custom_minimum_size = Vector2(BOT_ROW_FACE, BOT_ROW_FACE)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(face)
		var text := Label.new()
		text.add_theme_font_size_override("font_size", 10)
		text.add_theme_constant_override("line_spacing", -2)
		text.custom_minimum_size = Vector2(BOT_PANEL_WIDTH - BOT_ROW_FACE - 18.0, 0.0)
		text.autowrap_mode = TextServer.AUTOWRAP_OFF
		text.clip_text = true
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(text)
		bot_rows.add_child(row)
		bot_row_nodes.append({"row": row, "face": face, "text": text})
	for index in bot_row_nodes.size():
		var nodes: Dictionary = bot_row_nodes[index]
		var row: HBoxContainer = nodes.row
		row.visible = index < rows.size()
		if not row.visible:
			continue
		var data: Dictionary = rows[index]
		var face: TextureRect = nodes.face
		face.texture = data.get("face")
		var text: Label = nodes.text
		text.text = "%s\n%s" % [data.title, data.lines]
		var color: Color = data.color
		text.add_theme_color_override("font_color", color.lerp(Color.WHITE, 0.55))
		row.modulate = Color(1, 1, 1, 0.5 if bool(data.get("dim", false)) else 1.0)

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

## Names that fit a minimap cell (QA-15: long names were cut mid-word).
const SHORT_REALM_NAMES := {"Svartalfheim": "Svartalf", "Yggdrasil Heart": "Yggdrasil", "Muspelheim": "Muspel"}

func _short_realm_name(full: String) -> String:
	return str(SHORT_REALM_NAMES.get(full, full.left(9)))

func rebuild_minimap(layout: RefCounted, director: Node, current_index: int) -> void:
	for child in minimap_root.get_children():
		child.queue_free()
	minimap_labels.clear()
	var cell := Vector2(68, 36)
	for i in layout.realm_count():
		var grid: Vector2i = layout.get_realm(i).grid
		var box := ColorRect.new()
		box.position = Vector2(grid.x * (cell.x + 4), grid.y * (cell.y + 4))
		box.size = cell
		box.color = _get_state_color(director.get_state(i), i == current_index)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		minimap_root.add_child(box)
		var realm_name := str(layout.get_realm(i).name)
		var emblem_texture := _realm_emblem_texture(realm_name)
		if emblem_texture != null:
			var emblem := TextureRect.new()
			emblem.position = box.position + Vector2(2, 2)
			emblem.size = Vector2(32, 32)
			emblem.texture = emblem_texture
			emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			emblem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
			minimap_root.add_child(emblem)
		var label := Label.new()
		label.position = box.position + (Vector2(34, 1) if emblem_texture != null else Vector2(3, 1))
		label.size = Vector2(32, 34) if emblem_texture != null else cell - Vector2(6, 2)
		label.add_theme_font_size_override("font_size", 8 if emblem_texture != null else 10)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		minimap_root.add_child(label)
		minimap_labels[i] = {"label": label, "name": _short_realm_name(realm_name), "emblem": emblem_texture != null}
	update_minimap_labels(director, {})

func _realm_emblem_texture(realm_name: String) -> Texture2D:
	var key := realm_name.to_lower().replace(" ", "_")
	return ART_SETTINGS.original_texture(REALM_EMBLEM_ART % key)

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
		label.text = detail if bool(entry.get("emblem", false)) else "%s\n%s" % [entry.name, detail]

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

# --- Ultimate cut-in ---

## markers: [{"position": screen point on the edge, "angle": radians, "color": Color}]
func set_offscreen_markers(markers: Array) -> void:
	while offscreen_markers.size() < markers.size():
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([Vector2(16, 0), Vector2(-9, -12), Vector2(-4, 0), Vector2(-9, 12)])
		var outline := Line2D.new()
		outline.points = PackedVector2Array([Vector2(16, 0), Vector2(-9, -12), Vector2(-4, 0), Vector2(-9, 12), Vector2(16, 0)])
		outline.width = 2.0
		outline.default_color = Color(0.02, 0.02, 0.05, 0.85)
		arrow.add_child(outline)
		offscreen_root.add_child(arrow)
		offscreen_markers.append(arrow)
	for index in offscreen_markers.size():
		var arrow := offscreen_markers[index]
		arrow.visible = index < markers.size()
		if arrow.visible:
			arrow.position = markers[index].position
			arrow.rotation = float(markers[index].angle)
			arrow.color = Color(markers[index].color, 0.92)

func _build_cutin() -> void:
	flash_rect = ColorRect.new()
	flash_rect.name = "UltimateFlash"
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_rect)
	cutin_root = Control.new()
	cutin_root.name = "UltimateCutin"
	cutin_root.position = Vector2(0, 230)
	cutin_root.size = Vector2(560, 112)
	cutin_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutin_root.visible = false
	add_child(cutin_root)
	_pin(cutin_root, Vector2(0.0, 0.5))
	var band_texture := ART_SETTINGS.original_texture(CUTIN_BAND_ART)
	if band_texture != null:
		var textured_band := TextureRect.new()
		textured_band.texture = band_texture
		textured_band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		textured_band.stretch_mode = TextureRect.STRETCH_SCALE
		textured_band.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cutin_band = textured_band
	else:
		cutin_band = ColorRect.new()
	cutin_band.size = Vector2(560, 112)
	cutin_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutin_root.add_child(cutin_band)
	var shine := ColorRect.new()
	shine.position = Vector2(0, 100)
	shine.size = Vector2(560, 6)
	shine.color = Color(1, 1, 1, 0.65)
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutin_root.add_child(shine)
	cutin_face = _portrait_rect(Vector2(16, 4), Vector2(104, 104))
	cutin_root.add_child(cutin_face)
	cutin_name = _label(Vector2(136, 14), Vector2(410, 30), 18, HORIZONTAL_ALIGNMENT_LEFT)
	cutin_name.reparent(cutin_root, false)
	cutin_title = _label(Vector2(136, 44), Vector2(410, 50), 32, HORIZONTAL_ALIGNMENT_LEFT)
	cutin_title.reparent(cutin_root, false)

## Slides the caster's face in from the left for about 0.9 s and flashes the screen.
func show_ultimate_cutin(player: Node) -> void:
	var caster_y := 360.0
	if player is CanvasItem:
		caster_y = (player as CanvasItem).get_global_transform_with_canvas().origin.y
	cutin_root.position.y = CUTIN_HIGH_Y if caster_y > get_viewport().get_visible_rect().size.y * 0.5 else CUTIN_LOW_Y
	_set_portrait(cutin_face, ART_SETTINGS.character_portrait(player.character_id, player.body_type))
	var band_color := Color(player.body_color.darkened(0.35), 0.86)
	if cutin_band is ColorRect:
		(cutin_band as ColorRect).color = band_color
	else:
		cutin_band.modulate = band_color
	cutin_name.text = ("P1 " if player.is_human else "") + str(player.display_name)
	cutin_title.text = str(player.ultimate_name).to_upper()
	cutin_root.visible = true
	cutin_root.modulate.a = 1.0
	if cutin_tween != null and cutin_tween.is_valid():
		cutin_tween.kill()
	var rest_x := cutin_root.position.x
	cutin_band.position.x = -560.0
	cutin_tween = create_tween()
	cutin_tween.tween_property(cutin_band, "position:x", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	cutin_tween.tween_interval(0.62)
	cutin_tween.tween_property(cutin_root, "modulate:a", 0.0, 0.18)
	cutin_tween.tween_callback(func() -> void: cutin_root.visible = false)
	cutin_root.position.x = rest_x
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	flash_rect.color = Color(1, 1, 1, 0.24)
	flash_tween = create_tween()
	flash_tween.tween_property(flash_rect, "color:a", 0.0, 0.2)

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
	overlay_back = ColorRect.new()
	overlay_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_back.color = PANEL_COLOR
	overlay_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(overlay_back)
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
	overlay_back.color = PANEL_COLOR
	overlay.visible = true

## survival: combatant -> seconds survived (MatchDirector.get_survival_time).
func show_results(winner: Node, reason: String, standings: Array[Node], human: Node, survival: Dictionary = {}) -> void:
	overlay_logo.visible = false
	if is_instance_valid(portrait_strip):
		portrait_strip.visible = false
	overlay_title.text = "%s WINS" % winner.display_name.to_upper() if is_instance_valid(winner) else "DRAW"
	overlay_body.text = "Decided by %s" % reason
	# The table stands alone: no clock, status, minimap, portrait, bot panel or arrows behind it.
	_set_match_hud_visible(false)
	overlay_back.color = RESULTS_BACK_COLOR
	hazard_label.visible = false
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
		_add_result_cell(", ".join(_card_names(player.upgrades)), color)
	_add_result_cell("", Color.WHITE)
	_add_result_cell("", Color.WHITE)
	_add_result_cell("[R] play again", Color(1.0, 0.82, 0.4))
	overlay_credits.visible = false
	overlay.visible = true

## Display names for picked card ids (results showed "sky_step", "last_stand").
func _card_names(ids: Array) -> Array[String]:
	var names: Array[String] = []
	for id in ids:
		var card: Dictionary = SOUL_CARDS.find(str(id))
		names.append(str(card.get("title", str(id).replace("_", " ").capitalize())))
	return names

func _add_result_cell(text: String, color: Color) -> void:
	var cell := Label.new()
	cell.text = text
	cell.add_theme_font_size_override("font_size", 18)
	cell.add_theme_color_override("font_color", color)
	results_grid.add_child(cell)

func hide_overlay() -> void:
	_set_match_hud_visible(true)
	overlay.visible = false

func set_realm_title(text: String, accent: Color, hazard_text := "") -> void:
	realm_label.text = text
	realm_label.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.9))
	hazard_label.text = hazard_text
	hazard_label.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.75))

## Counts the bottom line down; it fades out when its time is up.
func tick_info(delta: float) -> void:
	if info_timer <= 0.0 or not info_label.visible:
		return
	info_timer -= delta
	if info_timer <= 0.0:
		info_fade = info_label.create_tween()
		info_fade.tween_property(info_label, "modulate:a", 0.0, 0.6)
		info_fade.tween_callback(func() -> void:
			info_label.visible = false
			info_label.modulate.a = 1.0)

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
	if not visible_now and clock_label.visible:
		bot_panel_wanted = bot_panel.visible
	for node in [clock_label, realm_label, hazard_label, status_label, minimap_root, focus_portrait, skill_bar, controls_label]:
		node.visible = visible_now
	# A fresh screen starts without an old message.
	info_label.visible = false
	info_timer = 0.0
	# The bot panel and the off-screen arrows belong to the match too (they showed through the
	# results table, QA-15).
	bot_panel.visible = visible_now and bot_panel_wanted
	offscreen_root.visible = visible_now
	focus_frame.visible = visible_now and focus_portrait.texture != null
	if not visible_now:
		warning_label.visible = false
		card_panel.visible = false
