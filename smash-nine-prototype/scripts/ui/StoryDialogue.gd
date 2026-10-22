extends "res://scripts/ui/FrontendMenu.gd"
## Bottom dialogue presentation. Real-time typing is independent of Engine.time_scale.
signal finished
const STORY := preload("res://scripts/story/StoryCatalog.gd")
## ART-70 presentation art: a 9-slice box frame and name plate, and full-screen scene pictures
## (a line's optional third field {"cg": name} shows assets/art/story/cg_<name>.png behind the box).
const FRAME_ART := "res://assets/art/story/dialogue_frame.png"
const FRAME_MARGIN := 24
const PLATE_ART := "res://assets/art/story/name_plate.png"
const PLATE_MARGIN := 12
const CG_ART := "res://assets/art/story/cg_%s.png"
const BOX := Rect2(36, 472, 1208, 230)
var lines: Array = []
var line_index := 0
var hero_id := "frey"
var rival_id := ""
var line_label: Label
var speaker_label: Label
var left_face: TextureRect
var right_face: TextureRect
var cg_picture: TextureRect
var name_plate: Control
var _characters := 0.0
var _last_tick := 0

func play(scene_lines: Array, hero: String, rival: String, hero_body: String) -> void:
	hero_id = hero
	rival_id = rival
	body = hero_body
	lines = scene_lines
	line_index = 0
	_clear("story_dialogue")
	cg_picture = _picture(null, Rect2(Vector2.ZERO, SIZE))
	cg_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cg_picture.visible = false
	_cover_viewport()
	_box_frame()
	left_face = _picture(ART.character_portrait(hero_id, body), Rect2(54, 496, 142, 164))
	right_face = _picture(null, Rect2(1084, 496, 142, 164))
	name_plate = _nine_patch(PLATE_ART, Rect2(212, 452, 200, 40), PLATE_MARGIN)
	speaker_label = _label("", Rect2(220, 455, 840, 34), 22, GOLD)
	line_label = _label("", Rect2(220, 512, 840, 120), 24)
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
	var shadow_speaks := speaker == "shadow"
	var shadow_scene := lines.any(func(entry: Array) -> bool: return str(entry[0]) == "shadow")
	var id := hero_id if speaker in ["hero", "shadow"] else (rival_id if speaker == "rival" else speaker)
	var narrator := speaker == "narrator"
	var hero_speaks := not shadow_speaks and (speaker == "hero" or id == hero_id)
	left_face.visible = not narrator
	right_face.visible = not narrator and (rival_id != "" or shadow_scene)
	left_face.modulate = Color.WHITE if hero_speaks else Color(0.35, 0.35, 0.45)
	var other_id := hero_id if shadow_scene else (id if not hero_speaks and not narrator else rival_id)
	if other_id != "" and _roster.has(other_id):
		right_face.visible = not narrator
		right_face.texture = ART.character_portrait(other_id, body if shadow_scene else REGISTRY.get_bodies(other_id)[0])
	var right_tint := Color(0.42, 0.24, 0.62) if shadow_scene else Color.WHITE
	right_face.modulate = right_tint if not hero_speaks else right_tint * Color(0.35, 0.35, 0.45)
	speaker_label.text = tr("Narrator") if narrator else (tr("Shadow %s") % tr(str(_roster[id].name)) if shadow_speaks else tr(str(_roster[id].name)))
	speaker_label.add_theme_color_override("font_color", DIM if narrator else (Color("b98af0") if shadow_speaks else _roster[id].color))
	_place_name_plate(narrator, hero_speaks)
	line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if narrator else HORIZONTAL_ALIGNMENT_LEFT
	var extra: Dictionary = line[2] if line.size() > 2 and line[2] is Dictionary else {}
	var cg: Texture2D = ART.original_texture(CG_ART % str(extra.cg)) if extra.has("cg") else null
	cg_picture.texture = cg
	cg_picture.visible = cg != null
	var text := tr(STORY.resolve_id(str(line[1]), hero_id, rival_id))
	line_label.text = text % tr(str(_roster[hero_id].name)) if text.contains("%s") else text
	line_label.visible_characters = 0
	_characters = 0.0
	_last_tick = Time.get_ticks_usec()

func _fit() -> void:
	super._fit()
	_cover_viewport()

## The 1280x720 layout is letterboxed on other window shapes; a scene picture still fills the screen.
func _cover_viewport() -> void:
	if not is_instance_valid(cg_picture) or not is_inside_tree() or is_zero_approx(scale.x):
		return
	cg_picture.position = -position / scale.x
	cg_picture.size = get_viewport().get_visible_rect().size / scale.x

## The plate sits on the box's top edge over the speaker's side (centred for the narrator).
func _place_name_plate(narrator: bool, hero_speaks: bool) -> void:
	var font: Font = speaker_label.get_theme_font("font")
	var width := clampf(font.get_string_size(speaker_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 56.0, 160.0, 420.0)
	var x := SIZE.x * 0.5 - width * 0.5 if narrator else (212.0 if hero_speaks else 1068.0 - width)
	name_plate.position = Vector2(x, 452)
	name_plate.size = Vector2(width, 40)
	speaker_label.position = Vector2(x, 455)
	speaker_label.size = Vector2(width, 34)
	speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

## A dark backing under the ART-70 frame; the plain panel when that art is off (F2) or missing.
func _box_frame() -> void:
	if ART.original_texture(FRAME_ART) == null:
		_panel(BOX, 0.98)
		return
	var backing := ColorRect.new()
	backing.position = BOX.position + Vector2(6, 6)
	backing.size = BOX.size - Vector2(12, 12)
	backing.color = Color(INK, 0.95)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(backing)
	_nine_patch(FRAME_ART, BOX, FRAME_MARGIN)

func _nine_patch(path: String, rect: Rect2, margin: int) -> Control:
	var texture := ART.original_texture(path)
	var node: Control
	if texture == null:
		var plain := ColorRect.new()
		plain.color = Color(INK, 0.95)
		node = plain
	else:
		var patch := NinePatchRect.new()
		patch.texture = texture
		patch.patch_margin_left = margin
		patch.patch_margin_top = margin
		patch.patch_margin_right = margin
		patch.patch_margin_bottom = margin
		patch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		node = patch
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(node)
	return node

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
