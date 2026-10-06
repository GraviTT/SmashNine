extends CanvasLayer
## In-match overlay: phase clock, survivors, souls, 3x3 realm minimap, soul card
## offer, announcement line, debug panel (F3), and the start / result screens.

const CONTROLS_HINT := "A/D move  W jump  S+S drop  Space guard  J attack  K/L skills  I ultimate  Q portal  1-3 soul card  F3 debug"
const PANEL_COLOR := Color(0.03, 0.03, 0.07, 0.78)
const CARD_COLOR := Color(0.1, 0.08, 0.2, 0.92)
const TEXT_DIM := Color(1.0, 1.0, 1.0, 0.7)

var info_label: Label
var clock_label: Label
var realm_label: Label
var warning_label: Label
var results_grid: GridContainer
var status_label: Label
var debug_label: Label
var minimap_root: Control
var minimap_labels: Dictionary = {}
var card_panel: Control
var card_title: Label
var card_labels: Array[Label] = []
var overlay: Control
var overlay_title: Label
var overlay_body: Label

func _ready() -> void:
	name = "UI"
	clock_label = _label(Vector2(390, 12), Vector2(500, 30), 20, HORIZONTAL_ALIGNMENT_CENTER)
	status_label = _label(Vector2(870, 12), Vector2(390, 60), 16, HORIZONTAL_ALIGNMENT_RIGHT)
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
		var label := Label.new()
		label.position = back.position + Vector2(10, 8)
		label.size = back.size - Vector2(20, 16)
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
		else:
			label.text = ""

func hide_card_offer() -> void:
	card_panel.visible = false

# --- Start and result screens ---

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.name = "Overlay"
	overlay.size = Vector2(1280, 720)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var back := ColorRect.new()
	back.size = overlay.size
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
	overlay_body = Label.new()
	overlay_body.position = Vector2(240, 200)
	overlay_body.size = Vector2(800, 480)
	overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_body.add_theme_font_size_override("font_size", 19)
	overlay.add_child(overlay_body)

func show_start_screen(characters: Array[Dictionary]) -> void:
	overlay_title.text = "SMASH NINE REALMS"
	var lines: Array[String] = ["Nine realms are collapsing into the heart of Yggdrasil.", "Be the last one standing.", "", "Choose your fighter"]
	for index in characters.size():
		var data: Dictionary = characters[index]
		lines.append("[%d]  %s  -  %s" % [index + 1, data.name, data.role])
	lines.append("")
	lines.append("[B]  Watch a bots-only match")
	lines.append("")
	lines.append(CONTROLS_HINT)
	overlay_body.text = "\n".join(lines)
	overlay.visible = true

func show_results(winner: Node, reason: String, standings: Array[Node], human: Node) -> void:
	overlay_title.text = "%s WINS" % (winner.display_name.to_upper() if is_instance_valid(winner) else "NOBODY")
	overlay_body.text = "Decided by %s" % reason
	if is_instance_valid(results_grid):
		results_grid.queue_free()
	results_grid = GridContainer.new()
	results_grid.columns = 6
	results_grid.position = Vector2(250, 250)
	results_grid.add_theme_constant_override("h_separation", 34)
	results_grid.add_theme_constant_override("v_separation", 4)
	overlay.add_child(results_grid)
	for header in ["#", "Fighter", "KOs", "Damage", "Souls", "Cards"]:
		_add_result_cell(header, Color(1.0, 0.82, 0.4))
	for index in standings.size():
		var player: Node = standings[index]
		if not is_instance_valid(player):
			continue
		var color := Color(1.0, 0.92, 0.55) if player == human else Color.WHITE
		_add_result_cell(str(index + 1), color)
		_add_result_cell(("P1 " if player == human else "") + player.display_name, color)
		_add_result_cell(str(player.score), color)
		_add_result_cell("%.0f" % player.damage_dealt, color)
		_add_result_cell(str(player.souls), color)
		_add_result_cell(", ".join(player.upgrades), color)
	_add_result_cell("", Color.WHITE)
	_add_result_cell("[R] play again", Color(1.0, 0.82, 0.4))
	overlay.visible = true

func _add_result_cell(text: String, color: Color) -> void:
	var cell := Label.new()
	cell.text = text
	cell.add_theme_font_size_override("font_size", 18)
	cell.add_theme_color_override("font_color", color)
	results_grid.add_child(cell)

func hide_overlay() -> void:
	overlay.visible = false

func set_realm_title(text: String, accent: Color) -> void:
	realm_label.text = text
	realm_label.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.9))

## seconds < 0 hides the banner.
func set_warning_banner(seconds: int) -> void:
	warning_label.visible = seconds >= 0
	if seconds >= 0:
		warning_label.text = "COLLAPSE WARNING  %d\nfind a portal to a safe realm" % seconds
