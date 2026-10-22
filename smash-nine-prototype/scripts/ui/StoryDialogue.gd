extends "res://scripts/ui/FrontendMenu.gd"
## Bottom dialogue presentation. Real-time typing is independent of Engine.time_scale.
signal finished
const STORY := preload("res://scripts/story/StoryCatalog.gd")
var lines: Array = []
var line_index := 0
var hero_id := "frey"
var rival_id := ""
var line_label: Label
var speaker_label: Label
var left_face: TextureRect
var right_face: TextureRect
var _characters := 0.0
var _last_tick := 0

func play(scene_lines: Array, hero: String, rival: String, hero_body: String) -> void:
	hero_id = hero
	rival_id = rival
	body = hero_body
	lines = scene_lines
	line_index = 0
	_clear("story_dialogue")
	_panel(Rect2(36, 472, 1208, 230), 0.98)
	left_face = _picture(ART.character_portrait(hero_id, body), Rect2(54, 496, 142, 164))
	right_face = _picture(null, Rect2(1084, 496, 142, 164))
	speaker_label = _label("", Rect2(220, 488, 840, 34), 24, GOLD)
	line_label = _label("", Rect2(220, 532, 840, 104), 24)
	_button("Next", Rect2(936, 648, 130, 42), "dialogue_next")
	_button("Skip", Rect2(1080, 648, 146, 42), "dialogue_skip")
	_label("J / Enter: next    Esc: skip", Rect2(220, 662, 700, 24), 15, DIM)
	_show_line()

func _show_line() -> void:
	if line_index >= lines.size():
		visible = false
		finished.emit()
		return
	var line: Array = lines[line_index]
	var speaker := str(line[0])
	var id := hero_id if speaker == "hero" else (rival_id if speaker == "rival" else speaker)
	var narrator := speaker == "narrator"
	var hero_speaks := speaker == "hero" or id == hero_id
	left_face.visible = not narrator
	right_face.visible = not narrator and rival_id != ""
	left_face.modulate = Color.WHITE if hero_speaks else Color(0.35, 0.35, 0.45)
	var other_id := id if not hero_speaks and not narrator else rival_id
	if other_id != "" and _roster.has(other_id):
		right_face.visible = not narrator
		right_face.texture = ART.character_portrait(other_id, "female" if REGISTRY.get_bodies(other_id).size() == 1 else "male")
	right_face.modulate = Color.WHITE if not hero_speaks else Color(0.35, 0.35, 0.45)
	speaker_label.text = tr("Narrator") if narrator else tr(str(_roster[id].name))
	speaker_label.add_theme_color_override("font_color", DIM if narrator else _roster[id].color)
	speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if narrator else (HORIZONTAL_ALIGNMENT_LEFT if hero_speaks else HORIZONTAL_ALIGNMENT_RIGHT)
	line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if narrator else HORIZONTAL_ALIGNMENT_LEFT
	var text := tr(STORY.resolve_id(str(line[1]), hero_id, rival_id))
	line_label.text = text % tr(str(_roster[hero_id].name)) if text.contains("%s") else text
	line_label.visible_characters = 0
	_characters = 0.0
	_last_tick = Time.get_ticks_usec()

func _process(_delta: float) -> void:
	if not visible or not is_instance_valid(line_label):
		return
	var now := Time.get_ticks_usec()
	_characters += float(now - _last_tick) / 1000000.0 * 45.0
	_last_tick = now
	line_label.visible_characters = mini(int(_characters), line_label.get_total_character_count())

func advance_line() -> void:
	if line_label.visible_characters >= 0 and line_label.visible_characters < line_label.get_total_character_count():
		_characters = line_label.get_total_character_count()
		line_label.visible_characters = -1
	else:
		line_index += 1
		_show_line()

func _activate(action: String, value: String) -> void:
	if action == "dialogue_next":
		advance_line()
	elif action == "dialogue_skip":
		line_index = lines.size()
		_show_line()
	else:
		super._activate(action, value)

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if code in [KEY_J, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
		get_viewport().set_input_as_handled()
		_activate("dialogue_skip" if code == KEY_ESCAPE else "dialogue_next", "")
