extends CanvasLayer
## In-match overlay: announcement line, debug panel and the 3x3 realm minimap.

const CONTROLS_HINT := "A/D move, W jump, Space guard, J attack, K/L skills, I ultimate, Q portal, 1-4 character, 5/6 players, H dummy"

var info_label: Label
var debug_label: Label
var minimap_root: Control
var minimap_labels: Dictionary = {}

func _ready() -> void:
	name = "UI"
	info_label = Label.new()
	info_label.position = Vector2(32, 620)
	info_label.size = Vector2(850, 92)
	info_label.text = CONTROLS_HINT
	info_label.add_theme_font_size_override("font_size", 15)
	add_child(info_label)

	debug_label = Label.new()
	debug_label.position = Vector2(900, 24)
	debug_label.size = Vector2(370, 250)
	debug_label.add_theme_font_size_override("font_size", 15)
	add_child(debug_label)

	minimap_root = Control.new()
	minimap_root.name = "RealmMinimap"
	minimap_root.position = Vector2(32, 94)
	minimap_root.size = Vector2(256, 136)
	add_child(minimap_root)

func show_message(text: String) -> void:
	if is_instance_valid(info_label):
		info_label.text = text

func set_debug_text(text: String) -> void:
	if is_instance_valid(debug_label):
		debug_label.text = text

func rebuild_minimap(layout: RefCounted, director: Node, current_index: int) -> void:
	if not is_instance_valid(minimap_root):
		return
	for child in minimap_root.get_children():
		child.queue_free()
	minimap_labels.clear()
	var cell := Vector2(82, 42)
	for i in layout.realm_count():
		var grid: Vector2i = layout.get_realm(i).grid
		var box := ColorRect.new()
		box.position = Vector2(grid.x * (cell.x + 5), grid.y * (cell.y + 5))
		box.size = cell
		box.color = _get_state_color(director.get_state(i), i == current_index)
		minimap_root.add_child(box)

		var label := Label.new()
		label.position = box.position + Vector2(5, 4)
		label.size = cell - Vector2(10, 8)
		label.text = "%d\n%s" % [i + 1, director.get_state(i).to_upper()]
		label.add_theme_font_size_override("font_size", 10)
		minimap_root.add_child(label)
		minimap_labels[i] = label

func update_minimap_labels(director: Node) -> void:
	var seconds_left: int = director.get_warning_seconds_left()
	for i in minimap_labels:
		var label: Label = minimap_labels[i]
		if not is_instance_valid(label):
			continue
		if i == director.warning_realm_index:
			label.text = "%d\n! %ds" % [i + 1, seconds_left]
		else:
			label.text = "%d\n%s" % [i + 1, director.get_state(i).to_upper()]

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
