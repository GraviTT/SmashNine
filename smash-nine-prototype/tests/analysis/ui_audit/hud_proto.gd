extends CanvasLayer
## Prototype match HUDs for the UI direction round of 2026-11-25 (reports/ui-direction-2026-11-25).
## Two different ideas, not two strengths of one:
## "a" spreads the information along the edges where the game has it today and keeps the game's
##     pixel frames, on solid backs and at readable sizes;
## "b" gathers the player's own numbers in one place at the bottom left, lists every fighter at
##     the top left, puts the map at the top right and the news at the bottom right, flat and slanted.
## The live bot panel (F4, on while the game is tested) is part of both: under the player's plate
## in "a", as the opened fighter list in "b". Both read the live match through Main every frame. Nothing in the
## game loads this file: ui_direction_capture.gd hides the real HUD and adds one of these.

const ART := preload("res://scripts/ArtSettings.gd")
const REF := Vector2(1280, 720)
const PLATE := Color(0.047, 0.07, 0.125, 0.88)
const PLATE_SOLID := Color(0.047, 0.07, 0.125, 0.97)
const EDGE := Color(1, 1, 1, 0.16)
const GOLD := Color("f3cd7c")
const DIM := Color("b7c3d6")
const WHITE := Color("f5f8fc")
const DANGER := Color("ff6a3d")
const DANGER_PLATE := Color(0.36, 0.05, 0.06, 0.92)
const HP_LOW := Color("ee4a3a")
const HP_MID := Color("f2b632")
const HP_FULL := Color("3ecf6a")
const SOUL := Color("9a86ff")
const KIND_COLOR := {"stat": Color("f3cd7c"), "action": Color("5fd0ff"), "exclusive": Color("ff7ab8")}
const SLOTS: Array[String] = ["j", "k", "l", "u", "i"]
const TOP_LEFT := Vector2(0, 0)
const TOP_CENTER := Vector2(0.5, 0)
const TOP_RIGHT := Vector2(1, 0)
const BOTTOM_LEFT := Vector2(0, 1)
const BOTTOM_CENTER := Vector2(0.5, 1)
const BOTTOM_RIGHT := Vector2(1, 1)
const FEED_TIME := 4.5
const BOT_WIDTH := 320.0
const BOT_ROW := 40.0
const BOT_REFRESH := 0.1

var main: Node
var style := "a"
var bold: FontVariation
var clock := {}
var player := {}
var skills := {}
var skill_root: Control
var minimap := {}
var roster := {}
var bots := {}
var show_bots := true
var _bot_timer := 0.0
var feed_root: Control
var feed_rows: Array = []
var banner := {}
var cards := {}
var cutin := {}
var bubbles: Array = []
var bubble_root: Control
var tag: Control
## Set to show these cards instead of the match's offer (stills of the D54 card kinds).
var mock_offer: Dictionary = {}
var mock_total := 8.0
var _last_message := ""
var _last_message_timer := 0.0
var _pulse := 0.0
var _skill_set := ""
var _cutin_tween: Tween

func setup(owner_main: Node, new_style: String, bots_shown := true) -> void:
	main = owner_main
	style = new_style
	show_bots = bots_shown
	layer = 3
	bold = FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 0.7
	_build_clock()
	_build_player()
	_build_skills()
	_build_minimap()
	if style == "b":
		_build_roster()
		roster.root.visible = not show_bots
	if show_bots:
		_build_bots()
	_build_feed()
	_build_banner()
	_build_bubbles()
	_build_tag()
	_build_cards()
	_build_cutin()
	for fighter in main.players:
		fighter.ultimate_cast.connect(_on_ultimate_cast)

# --- Small builders ---

func _root(position: Vector2, size: Vector2, anchor: Vector2) -> Control:
	var control := Control.new()
	control.position = position
	control.size = size
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = position.x - anchor.x * REF.x
	control.offset_top = position.y - anchor.y * REF.y
	control.offset_right = control.offset_left + size.x
	control.offset_bottom = control.offset_top + size.y
	return control

func _box(color: Color, border := Color.TRANSPARENT, width := 0, radius := 5, skew := 0.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.skew = Vector2(skew, 0)
	box.anti_aliasing = true
	return box

func _plate(parent: Node, rect: Rect2, box: StyleBoxFlat) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", box)
	parent.add_child(panel)
	return panel

func _text(parent: Node, text: String, rect: Rect2, font_size: int, color := WHITE, heavy := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	# Clip first: a Label's size is clamped up to its text's width unless it clips.
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("outline_size", 3)
	if heavy:
		label.add_theme_font_override("font", bold)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _picture(parent: Node, texture: Texture2D, rect: Rect2, pixel := true) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = texture
	picture.position = rect.position
	picture.size = rect.size
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel else CanvasItem.TEXTURE_FILTER_LINEAR
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture

## One of the game's HUD frames (assets/art/ui/frames) as a 9-slice over `rect`.
func _frame(parent: Node, frame_id: String, rect: Rect2, margin: int) -> NinePatchRect:
	var patch := NinePatchRect.new()
	patch.texture = ART.original_texture("res://assets/art/ui/frames/%s.png" % frame_id)
	patch.patch_margin_left = margin
	patch.patch_margin_top = margin
	patch.patch_margin_right = margin
	patch.patch_margin_bottom = margin
	patch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	patch.position = rect.position
	patch.size = rect.size
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(patch)
	return patch

func _fill(parent: Node, rect: Rect2, color: Color, radius := 3) -> Panel:
	return _plate(parent, rect, _box(color, Color.TRANSPARENT, 0, radius))

func _face(fighter: Node) -> Texture2D:
	return ART.character_portrait(fighter.character_id, fighter.body_type)

func _set_face(picture: TextureRect, fighter: Node) -> void:
	var texture := _face(fighter)
	picture.texture = texture
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if ART.is_painted_portrait(texture) else CanvasItem.TEXTURE_FILTER_NEAREST

## Korean wraps between any two syllables by default, so a line can end inside a word ("착 / 지").
## A word joiner (U+2060) between the letters of each word keeps the breaks at the spaces.
func _keep_words(text: String) -> String:
	var words: PackedStringArray = []
	for word in text.split(" "):
		words.append("⁠".join(word.split("")))
	return " ".join(words)

func _clock_text(seconds: float) -> String:
	var whole := maxi(0, int(seconds))
	return "%d:%02d" % [whole / 60, whole % 60]

# --- Clock, next event, survivors, realm ---

func _build_clock() -> void:
	if style == "a":
		var root := _root(Vector2(410, 10), Vector2(460, 92), TOP_CENTER)
		clock.plate = _plate(root, Rect2(0, 0, 460, 56), _box(PLATE, EDGE, 1))
		clock.phase = _text(root, "", Rect2(16, 5, 300, 22), 16, DIM)
		clock.time = _text(root, "", Rect2(16, 24, 84, 30), 26, WHITE, true)
		clock.next_name = _text(root, "", Rect2(100, 27, 146, 26), 16, DIM, false, HORIZONTAL_ALIGNMENT_RIGHT)
		clock.next_time = _text(root, "", Rect2(254, 24, 72, 30), 24, GOLD, true)
		_fill(root, Rect2(336, 8, 1, 40), EDGE, 0)
		_text(root, "생존", Rect2(350, 5, 100, 22), 16, DIM)
		clock.alive = _text(root, "", Rect2(350, 24, 40, 30), 26, WHITE, true)
		clock.total = _text(root, "", Rect2(388, 28, 60, 26), 17, DIM)
		clock.realm_plate = _plate(root, Rect2(60, 62, 340, 28), _box(Color(PLATE, 0.72), Color.TRANSPARENT, 0, 14))
		clock.realm = _text(root, "", Rect2(60, 62, 340, 28), 16, WHITE, false, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		var root := _root(Vector2(480, 10), Vector2(320, 96), TOP_CENTER)
		clock.plate = _plate(root, Rect2(20, 0, 280, 50), _box(PLATE_SOLID, EDGE, 1, 4, 0.22))
		clock.phase = _text(root, "", Rect2(36, 0, 150, 50), 16, DIM)
		clock.time = _text(root, "", Rect2(186, 0, 100, 50), 30, WHITE, true, HORIZONTAL_ALIGNMENT_RIGHT)
		clock.next_plate = _plate(root, Rect2(30, 56, 260, 32), _box(Color(PLATE, 0.84), Color.TRANSPARENT, 0, 4, 0.22))
		clock.next_name = _text(root, "", Rect2(44, 56, 150, 32), 16, DIM)
		clock.next_time = _text(root, "", Rect2(190, 56, 88, 32), 20, GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)

func _update_clock() -> void:
	var director: Node = main.director
	clock.phase.text = tr(director.get_phase_name())
	clock.time.text = _clock_text(director.match_elapsed)
	var next := str(director.get_next_event_label())
	clock.next_name.text = tr(next)
	clock.next_time.text = _clock_text(director.get_next_event_in()) if next != "" else ""
	var warning: bool = director.is_warning(main.current_map_index)
	if style == "a":
		clock.alive.text = str(director.get_alive_combatants().size())
		clock.total.text = "/ %d" % main.players.size()
		var realm: Dictionary = main.layout.get_realm(main.current_map_index)
		var hazard := str(main.hazards.get_hazard_text(main.current_map_index)) if main.hazards.enabled else ""
		clock.realm.text = tr(str(realm.name)) + ("  ·  " + hazard if hazard != "" else "")
	else:
		# The capsule itself turns red while this realm is about to fall.
		var box: StyleBoxFlat = clock.plate.get_theme_stylebox("panel")
		box.bg_color = DANGER_PLATE.lerp(Color(0.62, 0.1, 0.08, 0.95), 0.5 + 0.5 * sin(_pulse * 6.0)) if warning else PLATE_SOLID
		box.border_color = DANGER if warning else EDGE
		box.set_border_width_all(2 if warning else 1)

# --- The fighter in focus: face, HP, souls ---

func _build_player() -> void:
	if style == "a":
		var root := _root(Vector2(886, 10), Vector2(384, 96), TOP_RIGHT)
		player.root = root
		_plate(root, Rect2(0, 0, 384, 96), _box(PLATE, EDGE, 1))
		player.frame = _plate(root, Rect2(292, 6, 84, 84), _box(Color.WHITE, Color.TRANSPARENT, 0, 4))
		player.face = _picture(root, null, Rect2(294, 8, 80, 80), false)
		player.name = _text(root, "", Rect2(12, 4, 180, 26), 18, WHITE, true)
		player.kos = _text(root, "", Rect2(170, 4, 112, 26), 16, DIM, false, HORIZONTAL_ALIGNMENT_RIGHT)
		_fill(root, Rect2(12, 32, 270, 26), Color(0, 0, 0, 0.62), 4)
		player.hp_fill = _fill(root, Rect2(14, 34, 266, 22), HP_FULL, 3)
		_frame(root, "hp_bar", Rect2(6, 26, 282, 38), 8)
		player.hp_text = _text(root, "", Rect2(12, 32, 270, 26), 18, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		player.hp_width = 266.0
		_text(root, "소울", Rect2(12, 62, 44, 26), 16, SOUL.lightened(0.35))
		_fill(root, Rect2(56, 70, 140, 10), Color(0, 0, 0, 0.62), 5)
		player.soul_fill = _fill(root, Rect2(57, 71, 138, 8), SOUL, 4)
		player.soul_width = 138.0
		player.soul_text = _text(root, "", Rect2(202, 62, 80, 26), 16, WHITE, false, HORIZONTAL_ALIGNMENT_RIGHT)
	else:
		var root := _root(Vector2(16, 596), Vector2(432, 112), BOTTOM_LEFT)
		player.root = root
		player.band = _plate(root, Rect2(54, 14, 378, 92), _box(PLATE_SOLID, EDGE, 1, 4, 0.18))
		player.accent = _plate(root, Rect2(60, 14, 10, 92), _box(Color.WHITE, Color.TRANSPARENT, 0, 2, 0.18))
		player.frame = _plate(root, Rect2(0, 4, 108, 108), _box(Color.WHITE, Color.TRANSPARENT, 0, 6))
		player.face = _picture(root, null, Rect2(3, 7, 102, 102), false)
		player.name = _text(root, "", Rect2(124, 16, 150, 26), 18, WHITE, true)
		player.kos = _text(root, "", Rect2(300, 16, 116, 26), 16, DIM, false, HORIZONTAL_ALIGNMENT_RIGHT)
		player.hp_text = _text(root, "", Rect2(122, 38, 84, 40), 34, WHITE, true)
		player.hp_max = _text(root, "", Rect2(196, 50, 70, 26), 17, DIM)
		_fill(root, Rect2(252, 48, 164, 22), Color(0, 0, 0, 0.62), 4)
		player.hp_fill = _fill(root, Rect2(254, 50, 160, 18), HP_FULL, 3)
		player.hp_width = 160.0
		_text(root, "소울", Rect2(124, 76, 44, 26), 16, SOUL.lightened(0.35))
		_fill(root, Rect2(170, 84, 150, 10), Color(0, 0, 0, 0.62), 5)
		player.soul_fill = _fill(root, Rect2(171, 85, 148, 8), SOUL, 4)
		player.soul_width = 148.0
		player.soul_text = _text(root, "", Rect2(326, 76, 90, 26), 16, WHITE, false, HORIZONTAL_ALIGNMENT_RIGHT)

func _update_player(focus: Node) -> void:
	player.root.visible = is_instance_valid(focus)
	if not is_instance_valid(focus):
		return
	var watching: bool = not focus.is_human
	_set_face(player.face, focus)
	var accent: Color = focus.body_color
	(player.frame.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = accent
	if player.has("accent"):
		(player.accent.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = accent
	player.name.text = ("관전  " if watching else "") + tr(str(focus.display_name))
	player.name.add_theme_color_override("font_color", DIM if watching else WHITE)
	player.kos.text = "처치 %d" % int(focus.score)
	var ratio := clampf(float(focus.hp) / maxf(float(focus.max_hp), 1.0), 0.0, 1.0)
	var hp_color := HP_LOW if ratio <= 0.3 else (HP_MID if ratio <= 0.55 else HP_FULL)
	player.hp_fill.size.x = maxf(player.hp_width * ratio, 0.0)
	(player.hp_fill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = hp_color if ratio > 0.3 else hp_color.lerp(Color.WHITE, 0.25 + 0.25 * sin(_pulse * 9.0))
	if style == "a":
		player.hp_text.text = "%d / %d" % [ceili(focus.hp), ceili(focus.max_hp)]
	else:
		player.hp_text.text = str(ceili(focus.hp))
		player.hp_text.add_theme_color_override("font_color", WHITE if ratio > 0.3 else HP_LOW.lightened(0.3))
		player.hp_max.text = "/ %d" % ceili(focus.max_hp)
		player.hp_max.position.x = 124.0 + bold.get_string_size(player.hp_text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x + 8.0
	var next: int = focus.get_next_soul_threshold()
	if next > 0:
		var previous := 0
		for threshold: int in focus.SOUL_THRESHOLDS:
			if threshold < next:
				previous = threshold
		player.soul_fill.size.x = player.soul_width * clampf(float(focus.souls - previous) / maxf(float(next - previous), 1.0), 0.0, 1.0)
		player.soul_text.text = "%d / %d" % [focus.souls, next]
	else:
		player.soul_fill.size.x = player.soul_width
		player.soul_text.text = "카드 완료"

# --- Skill slots: a solid back, the key under the icon, big seconds ---

func _build_skills() -> void:
	skill_root = _root(Vector2(0, 0), Vector2(10, 10), BOTTOM_RIGHT if style == "a" else BOTTOM_LEFT)
	for slot in SLOTS:
		var cell := Control.new()
		cell.size = Vector2(56, 78)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		skill_root.add_child(cell)
		var back := _plate(cell, Rect2(0, 0, 56, 56), _box(PLATE_SOLID, EDGE, 2, 6 if style == "b" else 2))
		var icon := _picture(cell, null, Rect2(8, 8, 40, 40))
		var letter := _text(cell, slot.to_upper(), Rect2(0, 0, 56, 56), 26, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		var shade := _fill(cell, Rect2(2, 2, 52, 0), Color(0, 0, 0, 0.7), 4)
		var seconds := _text(cell, "", Rect2(0, 0, 56, 56), 26, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		var frame: NinePatchRect = _frame(cell, "skill_slot", Rect2(-3, -3, 62, 62), 10) if style == "a" else null
		var count_back := _fill(cell, Rect2(-4, -6, 30, 22), Color(0, 0, 0, 0.82), 4)
		var count := _text(cell, "", Rect2(-4, -6, 30, 22), 16, GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
		_plate(cell, Rect2(15, 58, 26, 20), _box(Color(0.93, 0.95, 0.98, 0.95), Color.TRANSPARENT, 0, 4))
		var key := _text(cell, slot.to_upper(), Rect2(15, 58, 26, 20), 16, Color("101827"), true, HORIZONTAL_ALIGNMENT_CENTER)
		key.add_theme_constant_override("outline_size", 0)
		skills[slot] = {"cell": cell, "back": back, "frame": frame, "icon": icon, "letter": letter, "shade": shade, "seconds": seconds, "count": count, "count_back": count_back}

func _update_skills(focus: Node) -> void:
	skill_root.visible = is_instance_valid(focus)
	if not is_instance_valid(focus):
		return
	var third: bool = focus.has_method("has_skill_three") and focus.has_skill_three()
	var set_name := "%s%s" % [focus.character_id, "_brave" if focus.get("transformed") == true else ""]
	var shown: Array[String] = SLOTS.filter(func(slot: String) -> bool: return slot != "u" or third)
	var width := shown.size() * 56.0 + (shown.size() - 1) * 10.0
	# Offsets from the anchored corner (bottom right in "a", after the player plate in "b").
	var left := -16.0 - width if style == "a" else 464.0
	var top := -16.0 - 78.0 if style == "a" else -16.0 - 82.0
	skill_root.offset_left = left
	skill_root.offset_top = top
	skill_root.offset_right = left + width
	skill_root.offset_bottom = top + 78.0
	for slot in SLOTS:
		var nodes: Dictionary = skills[slot]
		nodes.cell.visible = shown.has(slot)
		if not nodes.cell.visible:
			continue
		nodes.cell.position = Vector2(shown.find(slot) * 66.0, 0)
		if set_name != _skill_set:
			nodes.icon.texture = ART.original_texture("res://assets/art/skill_icons/%s_%s.png" % [set_name, slot])
		var cooldown: Vector2 = focus.skill_cooldown(slot)
		var waiting := clampf(cooldown.x / cooldown.y, 0.0, 1.0) if cooldown.y > 0.0 else 0.0
		nodes.shade.size.y = 52.0 * waiting
		nodes.shade.visible = waiting > 0.0
		nodes.seconds.text = str(ceili(cooldown.x)) if cooldown.x > 0.0 else ""
		nodes.letter.visible = nodes.icon.texture == null and cooldown.x <= 0.0
		nodes.icon.modulate = Color(1, 1, 1, 0.45) if cooldown.x > 0.0 else Color.WHITE
		var counter := str(focus.skill_counter(slot))
		nodes.count.text = counter
		nodes.count_back.visible = counter != ""
		var box: StyleBoxFlat = nodes.back.get_theme_stylebox("panel")
		var ready: bool = slot == "i" and cooldown.x <= 0.0
		if nodes.frame != null:
			# The pixel frame itself glows gold while the ultimate is ready, as in the game.
			nodes.frame.modulate = Color(1.0, 0.86, 0.42).lerp(Color.WHITE, 0.5 + 0.5 * sin(_pulse * 6.0)) if ready else Color.WHITE
			box.set_border_width_all(0)
		elif ready:
			box.border_color = GOLD.lerp(Color.WHITE, 0.5 + 0.5 * sin(_pulse * 6.0))
			box.set_border_width_all(3)
		else:
			box.border_color = EDGE
			box.set_border_width_all(2)
	_skill_set = set_name

# --- Minimap: colour and a number, no state words ---

func _build_minimap() -> void:
	var at := Vector2(16, 14) if style == "a" else Vector2(1280 - 16 - 186, 14)
	var root := _root(at, Vector2(186, 170), TOP_LEFT if style == "a" else TOP_RIGHT)
	minimap.root = root
	_plate(root, Rect2(-6, -6, 198, 148 if style == "a" else 182), _box(Color(PLATE, 0.66), Color.TRANSPARENT, 0, 6))
	minimap.cells = {}
	for index in main.layout.realm_count():
		var realm: Dictionary = main.layout.get_realm(index)
		var grid: Vector2i = realm.grid
		var cell := Control.new()
		cell.position = Vector2(grid.x * 63, grid.y * 46)
		cell.size = Vector2(60, 43)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(cell)
		var back := _plate(cell, Rect2(0, 0, 60, 43), _box(Color(0.12, 0.16, 0.23, 0.95), Color.TRANSPARENT, 0, 4))
		var emblem := _picture(cell, ART.original_texture("res://assets/art/ui/realm_emblems/%s.png" % str(realm.name).to_lower().replace(" ", "_")), Rect2(3, 5, 32, 32))
		var count := _text(cell, "", Rect2(32, 0, 26, 43), 21, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		minimap.cells[index] = {"back": back, "emblem": emblem, "count": count}
	if style == "b":
		minimap.realm = _text(root, "", Rect2(-6, 142, 198, 26), 16, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)

func _update_minimap() -> void:
	var director: Node = main.director
	var counts: Dictionary = main._count_alive_by_realm()
	for index: int in minimap.cells:
		var nodes: Dictionary = minimap.cells[index]
		var state := str(director.get_state(index))
		var here: bool = index == main.current_map_index
		var box: StyleBoxFlat = nodes.back.get_theme_stylebox("panel")
		var amount := int(counts.get(index, 0))
		nodes.count.text = str(amount) if amount > 0 and (state == "stable" or state == "warning") else ""
		nodes.emblem.modulate = Color.WHITE
		match state:
			"warning":
				box.bg_color = Color(0.78, 0.2, 0.08, 0.96).lerp(Color(1.0, 0.42, 0.16, 0.96), 0.5 + 0.5 * sin(_pulse * 7.0))
			"collapsed":
				box.bg_color = Color(0.02, 0.02, 0.03, 0.9)
				nodes.emblem.modulate = Color(1, 1, 1, 0.16)
				nodes.count.text = "×"
				nodes.count.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
			"locked":
				box.bg_color = Color(0.2, 0.2, 0.25, 0.9)
				nodes.emblem.modulate = Color(1, 1, 1, 0.45)
			_:
				box.bg_color = Color(0.12, 0.16, 0.23, 0.95)
		if state != "collapsed":
			nodes.count.add_theme_color_override("font_color", WHITE)
		box.border_color = GOLD if here else Color.TRANSPARENT
		box.set_border_width_all(3 if here else 0)
	if style == "b":
		var realm: Dictionary = main.layout.get_realm(main.current_map_index)
		minimap.realm.text = tr(str(realm.name))

# --- "b": every fighter as a face with a thin HP line ---

func _build_roster() -> void:
	var root := _root(Vector2(16, 14), Vector2(8 * 44, 60), TOP_LEFT)
	roster.root = root
	roster.rows = []
	var strip: float = main.players.size() * 44.0
	_plate(root, Rect2(-6, -6, strip + 76, 62), _box(Color(PLATE, 0.66), Color.TRANSPARENT, 0, 6))
	_text(root, "생존", Rect2(strip + 6, -2, 60, 22), 16, DIM)
	roster.alive = _text(root, "", Rect2(strip + 6, 20, 60, 28), 22, WHITE, true)
	for index in main.players.size():
		var fighter: Node = main.players[index]
		var cell := Control.new()
		cell.position = Vector2(index * 44, 0)
		cell.size = Vector2(40, 50)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(cell)
		var frame := _plate(cell, Rect2(0, 0, 40, 40), _box(Color(fighter.body_color, 0.9), Color.TRANSPARENT, 0, 4))
		var face := _picture(cell, null, Rect2(2, 2, 36, 36), false)
		_set_face(face, fighter)
		_fill(cell, Rect2(0, 43, 40, 6), Color(0, 0, 0, 0.7), 3)
		var hp := _fill(cell, Rect2(1, 44, 38, 4), HP_FULL, 2)
		var out := _text(cell, "×", Rect2(0, 0, 40, 40), 30, Color(1, 1, 1, 0.9), true, HORIZONTAL_ALIGNMENT_CENTER)
		roster.rows.append({"fighter": fighter, "frame": frame, "face": face, "hp": hp, "out": out})

func _update_roster() -> void:
	roster.alive.text = "%d" % main.director.get_alive_combatants().size()
	for row: Dictionary in roster.rows:
		var fighter: Node = row.fighter
		if not is_instance_valid(fighter):
			continue
		var ratio := clampf(float(fighter.hp) / maxf(float(fighter.max_hp), 1.0), 0.0, 1.0)
		row.hp.size.x = 38.0 * ratio
		(row.hp.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = HP_LOW if ratio <= 0.3 else (HP_MID if ratio <= 0.55 else HP_FULL)
		row.out.visible = fighter.is_defeated
		row.face.modulate = Color(0.35, 0.35, 0.4) if fighter.is_defeated else Color.WHITE
		var box: StyleBoxFlat = row.frame.get_theme_stylebox("panel")
		box.border_color = GOLD if fighter.is_human else Color.TRANSPARENT
		box.set_border_width_all(2 if fighter.is_human else 0)
		box.bg_color = Color(fighter.body_color, 0.25 if fighter.is_defeated else 0.9)

# --- The live bot panel: one row per fighter, the text the game's panel shows ---

func _build_bots() -> void:
	var count: int = main.players.size()
	# "b": the list is the fighter strip opened, so it carries the survivor count.
	var head := 26.0 if style == "b" else 0.0
	var height: float = count * BOT_ROW + 10.0 + head
	var root: Control
	if style == "a":
		root = _root(Vector2(1280 - 10 - BOT_WIDTH, 114), Vector2(BOT_WIDTH, height), TOP_RIGHT)
	else:
		root = _root(Vector2(10, 10), Vector2(BOT_WIDTH, height), TOP_LEFT)
	bots.root = root
	# See-through, as the game's panel is: fighters keep fighting behind it.
	_plate(root, Rect2(0, 0, BOT_WIDTH, height), _box(Color(PLATE, 0.58), Color.TRANSPARENT, 0, 6))
	bots.rows = []
	if style == "b":
		_text(root, "생존", Rect2(12, 3, 60, 24), 16, DIM)
		bots.alive = _text(root, "", Rect2(52, 3, 100, 24), 18, WHITE, true)
	for index in count:
		var fighter: Node = main.players[index]
		var row := Control.new()
		row.position = Vector2(0, 5 + head + index * BOT_ROW)
		row.size = Vector2(BOT_WIDTH, BOT_ROW)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(row)
		var frame := _plate(row, Rect2(6, 3, 34, 34), _box(Color(fighter.body_color, 0.9), GOLD, 2 if fighter.is_human else 0, 4))
		var face := _picture(row, null, Rect2(8, 5, 30, 30), false)
		_set_face(face, fighter)
		var title := _text(row, "", Rect2(48, 0, 168, 17), 12, fighter.body_color.lerp(Color.WHITE, 0.6), true)
		_fill(row, Rect2(220, 5, 56, 8), Color(0, 0, 0, 0.7), 3)
		var hp := _fill(row, Rect2(221, 6, 54, 6), HP_FULL, 2)
		var hp_text := _text(row, "", Rect2(278, 0, 36, 17), 12, WHITE, true, HORIZONTAL_ALIGNMENT_RIGHT)
		var plan := _text(row, "", Rect2(48, 14, BOT_WIDTH - 56, 26), 12, Color("d3dceb"))
		plan.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		plan.add_theme_constant_override("line_spacing", -4)
		bots.rows.append({"fighter": fighter, "row": row, "frame": frame, "face": face, "title": title, "hp": hp, "hp_text": hp_text, "plan": plan})

func _update_bots(delta: float) -> void:
	_bot_timer -= delta
	if _bot_timer > 0.0:
		return
	_bot_timer = BOT_REFRESH
	if bots.has("alive"):
		bots.alive.text = "%d / %d" % [main.director.get_alive_combatants().size(), main.players.size()]
	for nodes: Dictionary in bots.rows:
		var fighter: Node = nodes.fighter
		if not is_instance_valid(fighter):
			continue
		nodes.title.text = ("P1 " if fighter.is_human else "") + tr(str(fighter.display_name)) + "  ·  " + tr(str(main.layout.get_realm(fighter.realm_index).name))
		var ratio := clampf(float(fighter.hp) / maxf(float(fighter.max_hp), 1.0), 0.0, 1.0)
		nodes.hp.size.x = 54.0 * ratio
		(nodes.hp.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = HP_LOW if ratio <= 0.3 else (HP_MID if ratio <= 0.55 else HP_FULL)
		nodes.hp_text.text = str(ceili(fighter.hp))
		# The plan lines are the ones Main builds for the game's own panel.
		nodes.plan.text = "OUT" if fighter.is_defeated else ("직접 조작" if fighter.is_human else str(main._bot_plan_text(fighter)))
		nodes.row.modulate.a = 0.5 if fighter.is_defeated or fighter.realm_index != main.current_map_index else 1.0

# --- Messages: a short stack with a colour for what kind of news it is ---

func _build_feed() -> void:
	if style == "a":
		feed_root = _root(Vector2(10, 166), Vector2(330, 150), TOP_LEFT)
	else:
		feed_root = _root(Vector2(1280 - 16 - 400, 720 - 16 - 150), Vector2(400, 150), BOTTOM_RIGHT)

func _feed_color(text: String) -> Color:
	for word in ["탈락", "eliminated"]:
		if text.contains(word):
			return HP_LOW
	for word in ["붕괴", "서든데스", "ollaps", "Sudden"]:
		if text.contains(word):
			return DANGER
	for word in ["소울 카드", "Soul card"]:
		if text.contains(word):
			return SOUL
	for word in ["정예", "Elite"]:
		if text.contains(word):
			return GOLD
	return DIM

func _push_feed(text: String) -> void:
	var row := Control.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feed_root.add_child(row)
	var needed := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 30.0
	var width := minf(needed, feed_root.size.x)
	var height := 30.0 if needed <= feed_root.size.x else 52.0
	row.size = Vector2(feed_root.size.x, height)
	var x := 0.0 if style == "a" else feed_root.size.x - width
	_plate(row, Rect2(x, 0, width, height), _box(PLATE, Color.TRANSPARENT, 0, 4))
	_fill(row, Rect2(x, 0, 5, height), _feed_color(text), 2)
	var line := _text(row, _keep_words(text) if height > 30.0 else text, Rect2(x + 14, 0, width - 22, height), 16, WHITE)
	if height > 30.0:
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.max_lines_visible = 2
		line.add_theme_constant_override("line_spacing", -2)
	feed_rows.append({"row": row, "time": FEED_TIME, "height": height})
	while feed_rows.size() > 3:
		feed_rows[0].row.queue_free()
		feed_rows.remove_at(0)

func _update_feed(delta: float) -> void:
	# Main sends every message to the real HUD's bottom line; a new text or a restarted timer
	# there is a new message here.
	var label: Label = main.hud.info_label
	var timer: float = main.hud.info_timer
	if label.text != "" and (label.text != _last_message or timer > _last_message_timer + 0.5):
		_last_message = label.text
		_push_feed(label.text)
	_last_message_timer = timer
	for entry: Dictionary in feed_rows.duplicate():
		entry.time -= delta
		entry.row.modulate.a = clampf(entry.time / 0.5, 0.0, 1.0)
		if entry.time <= 0.0:
			entry.row.queue_free()
			feed_rows.erase(entry)
	if style == "a":
		var y := 0.0
		for entry: Dictionary in feed_rows:
			entry.row.position.y = y
			y += float(entry.height) + 5.0
	else:
		var bottom := feed_root.size.y
		for index in range(feed_rows.size() - 1, -1, -1):
			bottom -= float(feed_rows[index].height)
			feed_rows[index].row.position.y = bottom
			bottom -= 5.0

# --- Collapse and hazard warnings ---

func _build_banner() -> void:
	var root := _root(Vector2(360, 112) if style == "a" else Vector2(380, 104), Vector2(560, 64), TOP_CENTER)
	banner.root = root
	if style == "a":
		banner.plate = _plate(root, Rect2(0, 0, 560, 60), _box(DANGER_PLATE, DANGER, 2, 6))
		banner.title = _text(root, "", Rect2(18, 4, 300, 26), 19, Color("ffd9c8"), true)
		banner.line = _text(root, "", Rect2(18, 30, 420, 26), 16, WHITE)
		banner.number = _text(root, "", Rect2(430, 0, 116, 60), 40, Color("ffe07a"), true, HORIZONTAL_ALIGNMENT_RIGHT)
	else:
		banner.plate = _plate(root, Rect2(60, 0, 440, 34), _box(DANGER_PLATE, DANGER, 2, 4, 0.22))
		banner.title = _text(root, "", Rect2(60, 0, 440, 34), 17, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		banner.line = _text(root, "", Rect2(0, 0, 0, 0), 16)
		banner.number = _text(root, "", Rect2(0, 0, 0, 0), 16)
	root.visible = false

func _update_banner() -> void:
	var director: Node = main.director
	var collapsing: bool = director.is_warning(main.current_map_index) and not main.match_over
	var hazard := str(main.hazards.get_warning_text(main.current_map_index)) if not main.match_over else ""
	banner.root.visible = collapsing or hazard != ""
	if collapsing:
		var seconds: int = director.get_warning_seconds_left()
		if style == "a":
			banner.title.text = "이 렐름이 무너집니다"
			banner.line.text = "포털 위에서 Q를 눌러 안전한 렐름으로"
			banner.number.text = str(seconds)
		else:
			banner.title.text = "포털 위에서 Q  ·  안전한 렐름으로 이동"
			# The big number takes the place of the clock's "next" line.
			clock.next_name.text = "이 렐름 붕괴"
			clock.next_time.text = _clock_text(seconds)
			clock.next_time.add_theme_color_override("font_color", Color("ffe07a"))
	elif hazard != "":
		banner.title.text = tr(hazard)
		banner.line.text = ""
		banner.number.text = ""
	if not collapsing and style == "b":
		clock.next_time.add_theme_color_override("font_color", GOLD)
	var box: StyleBoxFlat = banner.plate.get_theme_stylebox("panel")
	box.bg_color = DANGER_PLATE if collapsing else Color(0.34, 0.2, 0.03, 0.92)
	box.border_color = DANGER if collapsing else GOLD
	if style == "a":
		banner.plate.size.y = 60.0 if collapsing else 36.0
		banner.title.size.y = 26.0 if collapsing else 28.0

# --- Soul cards: solid cards, a colour per kind, a bar that reads the offer's time ---

func _build_cards() -> void:
	# "a": along the bottom, left of the skill bar, inside the game's card frame; "b": under the
	# clock, flat. Three lines of text fit (the longest card of the D54 pool).
	var card_size := Vector2(290, 138) if style == "a" else Vector2(296, 128)
	var gap := 12.0 if style == "a" else 14.0
	var width := card_size.x * 3 + gap * 2
	var height := 34.0 + card_size.y
	var root: Control
	if style == "a":
		root = _root(Vector2(24, 720 - 14 - height), Vector2(width, height), BOTTOM_CENTER)
	else:
		root = _root(Vector2(344.0 if show_bots else (1280 - width) * 0.5, 196), Vector2(width, height), TOP_CENTER)
	cards.root = root
	cards.width = width
	_plate(root, Rect2(0, 0, width, 27), _box(PLATE_SOLID, Color.TRANSPARENT, 0, 4))
	cards.title = _text(root, "소울 카드 선택", Rect2(12, 0, 130, 26), 16, WHITE, true)
	_text(root, "1 · 2 · 3 키로 고르기", Rect2(138, 0, 240, 26), 16, DIM)
	cards.seconds = _text(root, "", Rect2(width - 92, 0, 80, 26), 18, GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)
	_fill(root, Rect2(0, 26, width, 5), Color(0, 0, 0, 0.75), 2)
	cards.bar = _fill(root, Rect2(0, 26, width, 5), GOLD, 2)
	cards.items = []
	for index in 3:
		var card := Control.new()
		card.position = Vector2(index * (card_size.x + gap), 34)
		card.size = card_size
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(card)
		var inset := 7.0 if style == "a" else 2.0
		var back := _plate(card, Rect2(Vector2.ZERO, card_size), _box(PLATE_SOLID, GOLD, 0 if style == "a" else 2, 2 if style == "a" else 8))
		var head := _plate(card, Rect2(inset, inset, card_size.x - inset * 2.0, 26), _box(GOLD, Color.TRANSPARENT, 0, 2 if style == "a" else 6))
		_plate(card, Rect2(inset + 6, inset + 3, 22, 20), _box(Color("101827"), Color.TRANSPARENT, 0, 4))
		_text(card, str(index + 1), Rect2(inset + 6, inset + 3, 22, 20), 16, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		var kind := _text(card, "", Rect2(inset + 36, inset, card_size.x - 60, 26), 16, Color("101827"), true)
		kind.add_theme_constant_override("outline_size", 0)
		var top := inset + 30.0
		var tile := _plate(card, Rect2(14, top + 6, 48, 48), _box(Color(1, 1, 1, 0.1), Color(1, 1, 1, 0.35), 2, 6))
		var letter := _text(card, "", Rect2(14, top + 6, 48, 48), 26, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		var icon := _picture(card, null, Rect2(14, top + 6, 48, 48))
		var title := _text(card, "", Rect2(72, top, card_size.x - 84, 28), 20, WHITE, true)
		var text := _text(card, "", Rect2(72, top + 28, card_size.x - 84, 62), 16, Color("dfe6f1"))
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		text.max_lines_visible = 3
		text.add_theme_constant_override("line_spacing", -1)
		if style == "a":
			_frame(card, "card_panel", Rect2(-5, -5, card_size.x + 10, card_size.y + 10), 14)
		cards.items.append({"card": card, "back": back, "head": head, "kind": kind, "icon": icon, "tile": tile, "letter": letter, "title": title, "text": text})
	root.visible = false

## offer: {"cards": [{id, title, text, kind}], "time_left": s}; total: the full choice time.
func show_cards(offer: Dictionary, total: float) -> void:
	cards.root.visible = not offer.is_empty()
	if offer.is_empty():
		return
	var left := float(offer.time_left)
	cards.seconds.text = "%d초" % ceili(left)
	cards.bar.size.x = cards.width * clampf(left / maxf(total, 0.1), 0.0, 1.0)
	(cards.bar.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = GOLD if left > 2.0 else DANGER
	for index in 3:
		var nodes: Dictionary = cards.items[index]
		nodes.card.visible = index < offer.cards.size()
		if not nodes.card.visible:
			continue
		var card: Dictionary = offer.cards[index]
		var color: Color = KIND_COLOR.get(str(card.kind), GOLD)
		(nodes.back.get_theme_stylebox("panel") as StyleBoxFlat).border_color = color
		(nodes.head.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = color
		nodes.kind.text = str(card.get("kind_name", tr(str(card.kind))))
		nodes.icon.texture = ART.original_texture("res://assets/art/ui/card_%s.png" % str(card.id))
		# A card without art yet shows its first letter on a tile (D54: new cards start that way).
		nodes.tile.visible = nodes.icon.texture == null
		nodes.letter.visible = nodes.icon.texture == null
		nodes.letter.text = tr(str(card.title)).left(1)
		(nodes.tile.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color(color, 0.7)
		nodes.title.text = tr(str(card.title))
		nodes.text.text = _keep_words(tr(str(card.text)))

# --- Ultimate cut-in: a slanted band in the caster's colour ---

func _build_cutin() -> void:
	var root := _root(Vector2(-40, 190), Vector2(640, 104), Vector2(0, 0.5))
	cutin.root = root
	cutin.band = _plate(root, Rect2(0, 0, 620, 104), _box(Color.WHITE, Color.TRANSPARENT, 0, 2, 0.3))
	cutin.stripe = _plate(root, Rect2(0, 90, 600, 8), _box(Color(1, 1, 1, 0.55), Color.TRANSPARENT, 0, 2, 0.3))
	cutin.face = _picture(root, null, Rect2(70, 0, 104, 104), false)
	cutin.name = _text(root, "", Rect2(190, 12, 400, 28), 19, WHITE, true)
	cutin.title = _text(root, "", Rect2(190, 40, 400, 50), 36, WHITE, true)
	root.visible = false

func _on_ultimate_cast(fighter: Node) -> void:
	if not is_instance_valid(fighter) or not (fighter.is_human or fighter.realm_index == main.current_map_index):
		return
	var caster_y := (fighter as CanvasItem).get_global_transform_with_canvas().origin.y
	var view := get_viewport().get_visible_rect().size
	cutin.root.offset_top = (-190.0 if caster_y > view.y * 0.5 else 170.0)
	cutin.root.offset_bottom = cutin.root.offset_top + 104.0
	(cutin.band.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color(fighter.body_color.darkened(0.42), 1.0)
	(cutin.stripe.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color(fighter.body_color.lightened(0.45), 0.9)
	_set_face(cutin.face, fighter)
	cutin.name.text = ("P1  " if fighter.is_human else "") + tr(str(fighter.display_name))
	cutin.title.text = tr(str(fighter.ultimate_name))
	cutin.root.visible = true
	cutin.root.modulate.a = 1.0
	if _cutin_tween != null and _cutin_tween.is_valid():
		_cutin_tween.kill()
	cutin.root.offset_left = -700.0
	_cutin_tween = create_tween()
	_cutin_tween.tween_property(cutin.root, "offset_left", -40.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_cutin_tween.tween_interval(0.66)
	_cutin_tween.tween_property(cutin.root, "modulate:a", 0.0, 0.18)
	_cutin_tween.tween_callback(func() -> void: cutin.root.visible = false)

# --- Fighters outside the view: a face on the edge and an arrow ---

func _build_bubbles() -> void:
	bubble_root = Control.new()
	bubble_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	bubble_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble_root)

func _update_bubbles(focus: Node) -> void:
	var view := get_viewport().get_visible_rect().size
	var centre := view * 0.5
	var inner := centre - Vector2(46, 46)
	var wanted: Array = []
	for fighter in main.players:
		if fighter == focus or fighter.is_defeated or fighter.realm_index != main.current_map_index:
			continue
		var screen: Vector2 = (fighter as CanvasItem).get_global_transform_with_canvas() * Vector2(0, -32)
		if Rect2(Vector2.ZERO, view).has_point(screen):
			continue
		var direction := (screen - centre).normalized()
		var reach := minf(inner.x / maxf(absf(direction.x), 0.001), inner.y / maxf(absf(direction.y), 0.001))
		wanted.append({"fighter": fighter, "at": centre + direction * reach, "angle": direction.angle()})
	# Faces heading the same way fan out along the edge instead of piling on one point.
	for index in wanted.size():
		for other in index:
			if (wanted[index].at as Vector2).distance_to(wanted[other].at) < 44.0:
				var along := Vector2(0, 46) if absf(cos(wanted[index].angle)) > 0.7 else Vector2(46, 0)
				wanted[index].at += along
	while bubbles.size() < wanted.size():
		var bubble := Control.new()
		bubble.size = Vector2(40, 40)
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bubble_root.add_child(bubble)
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([Vector2(34, 0), Vector2(18, -12), Vector2(18, 12)])
		arrow.position = Vector2(20, 20)
		bubble.add_child(arrow)
		var ring := _plate(bubble, Rect2(0, 0, 40, 40), _box(Color.WHITE, Color("0c1220"), 2, 20))
		var face := _picture(bubble, null, Rect2(4, 4, 32, 32), false)
		bubbles.append({"bubble": bubble, "arrow": arrow, "ring": ring, "face": face})
	for index in bubbles.size():
		var nodes: Dictionary = bubbles[index]
		nodes.bubble.visible = index < wanted.size()
		if not nodes.bubble.visible:
			continue
		var entry: Dictionary = wanted[index]
		var fighter: Node = entry.fighter
		nodes.bubble.position = (entry.at as Vector2) - Vector2(20, 20)
		nodes.arrow.rotation = float(entry.angle)
		nodes.arrow.color = fighter.body_color.lightened(0.2)
		(nodes.ring.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = fighter.body_color
		_set_face(nodes.face, fighter)

# --- "P1" over the player's own fighter ---

func _build_tag() -> void:
	tag = Control.new()
	tag.size = Vector2(44, 34)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)
	var pointer := Polygon2D.new()
	pointer.polygon = PackedVector2Array([Vector2(14, 22), Vector2(30, 22), Vector2(22, 33)])
	pointer.color = GOLD
	tag.add_child(pointer)
	_plate(tag, Rect2(0, 0, 44, 24), _box(GOLD, Color("101827"), 2, 5))
	var label := _text(tag, "P1", Rect2(0, 0, 44, 24), 16, Color("101827"), true, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_constant_override("outline_size", 0)

func _update_tag() -> void:
	var human: Node = main._get_human_player()
	tag.visible = is_instance_valid(human) and not human.is_defeated and human.realm_index == main.current_map_index
	if not tag.visible:
		return
	# The world label over the head says the same in small type; the tag replaces it.
	human.name_label.visible = false
	var head: Vector2 = (human as CanvasItem).get_global_transform_with_canvas() * Vector2(0, -134)
	tag.position = head - Vector2(22, 34)

func _process(delta: float) -> void:
	if not is_instance_valid(main) or not main.match_started:
		return
	_pulse += delta
	var focus: Node = main._get_focus_player()
	_update_clock()
	_update_player(focus)
	_update_skills(focus)
	_update_minimap()
	if style == "b":
		_update_roster()
	if show_bots:
		_update_bots(delta)
	_update_feed(delta)
	_update_banner()
	_update_bubbles(focus)
	_update_tag()
	var human: Node = main._get_human_player()
	var offer: Dictionary = main.soul_growth.get_offer(human) if is_instance_valid(human) and not main.match_over else {}
	if mock_offer.is_empty():
		show_cards(offer, float(main.soul_growth.CHOICE_TIME))
	else:
		show_cards(mock_offer, mock_total)
