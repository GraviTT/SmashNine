extends Control
## Front-end presentation only. Main owns starting/reloading matches and session choices.

signal action_requested(action: String, value: String)

const ART := preload("res://scripts/ArtSettings.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const SOUL_CARDS := preload("res://scripts/match/SoulCards.gd")
const VICTORY_FACTORY := preload("res://scripts/PlayerFactory.gd")
const SIZE := Vector2(1280, 720)
const GOLD := Color("f3cd7c")
const DIM := Color("aebbd0")
const INK := Color("101827")
## Short descriptions from design/SKILLS.md; no balance data is duplicated here.
const KITS := {
	"frey": ["Claim close range with your sword.\nLaunch rivals, then chase them through the air.",
		"Sword chain  /  Direction changes your slash.", "Dash Strike  /  Aim, then lunge in 8 directions.",
		"Rising Cleave  /  Hit, then tap L again to spike.", "Valkyrie Descent  /  Dive into two shockwaves.",
		"Pursuit  /  Move faster toward marked airborne rivals."],
	"yuki": ["Set talismans along your opponent's path.\nControl landings with seals and pulling wards.",
		"Snow Talisman  /  Fire ahead, above or below.", "Binding Seal  /  Place up to two fragile seals.",
		"Release Ward  /  Pull and burst; no seals: repel.", "Grand Ward  /  Pull, slow and finish with a blast.",
		"No passive  /  Plan your seals before the fight."],
	"luna": ["Cover mid-range with delayed star blossoms.\nTransform into Brave Luna for a close-range rush.",
		"Star Echo  /  A small arc, then a delayed bloom.", "Star Comet  /  Aim a star that bursts on arrival.",
		"Moon Ring  /  Push away foes around the rim.", "Brave Luna  /  Transform; tap I again for a laser.",
		"Star Charge  /  Five charges shorten your ultimate wait."],
	"nova": ["Turn speed into heavier, wider attacks.\nUse gravity to chase rivals and redirect your flight.",
		"Vector Strike  /  Momentum adds reach and power.", "Vector Shift  /  Accelerate in 8 directions; no hit.",
		"Gravity Brake  /  Stop and turn speed into a blast.", "Event Horizon  /  Tap I: core, orbit, then launch.",
		"Momentum  /  Faster movement powers your attacks."],
	"rio": ["Blink in, cut through and slip away.\nCounter attacks with runes and stay mobile in the air.",
		"Mana Combo  /  Three cuts; the last sends a wave.", "Dimension Slash  /  Blink and cut along your path.",
		"Rune Shield  /  Absorb hits, then counter; risky on miss.", "Infinity Overdrive  /  Aim six flying gem swords.",
		"Air Steps  /  Two extra jumps before landing."]
}
const CONTROLS := [
	["A / D  or  Left / Right", "Move / aim attacks"],
	["W  or  Up", "Jump (air jumps available)"],
	["S, S  or  Down, Down", "Drop through a thin platform"],
	["Space", "Guard / tap just before a hit to parry"],
	["J  + direction", "Basic attack (ground and air variants)"],
	["K / L", "Character skills"], ["I", "Ultimate (30 second cooldown)"],
	["Q", "Use the portal under your feet"], ["1 / 2 / 3", "Pick a soul card when offered"],
	["H", "Spawn / remove a training dummy"], ["F3 / F4", "Debug panel / live bot panel"],
	["T", "Game speed: 100 / 90 / 80 / 70%"], ["F2 (before a match)", "Switch original / prototype art"],
	["1 - 5 / V / B (menus)", "Quick start / body / watch bots"],
	["Arrows or W-S / Enter or J", "Navigate menus / confirm (mouse also works)"],
	["Esc / R (results)", "Back in menus / rematch"]
]

var screen := "title"
var selected_id := "frey"
var body := "male"
var fighter_count := 8
var bot_panel_at_start := true
var content: Control
var buttons: Array[Button] = []
var portrait_buttons: Array[Button] = []
var focus_index := 0
var hero_art: TextureRect
var fighter_name: Label
var fighter_role: Label
var description: Label
var skill_labels: Array[Label] = []
var body_button: Button
var speed_button: Button
var art_button: Button
var count_button: Button
var panel_button: Button
var language_button: Button
var footer: Label
var session_status: Label
var _roster := REGISTRY.get_characters()

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
	screen = next_screen
	buttons.clear()
	portrait_buttons.clear()
	skill_labels.clear()
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

func _button(text: String, rect: Rect2, action: String, value := "") -> Button:
	var button := Button.new()
	button.text = tr(text)
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("e7edf8"))
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_focus_color", GOLD)
	button.focus_mode = Control.FOCUS_ALL
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
	content.add_child(button)
	buttons.append(button)
	button.pressed.connect(func() -> void: _activate(action, value))
	button.mouse_entered.connect(func() -> void:
		if button.is_inside_tree():
			button.grab_focus()
			focus_index = buttons.find(button))
	button.focus_entered.connect(func() -> void:
		focus_index = buttons.find(button)
		if screen == "select" and action == "pick":
			selected_id = value
			_refresh_fighter())
	return button

func _finish(hint: String) -> void:
	footer = _label(hint, Rect2(44, 672, 1192, 26), 15, DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not buttons.is_empty():
		var initial := REGISTRY.get_character_ids().find(selected_id) if screen == "select" else 0
		buttons[initial].grab_focus()

func show_title() -> void:
	_clear("title")
	_panel(Rect2(414, 76, 452, 582), 0.87)
	var logo := ART.original_texture("res://assets/art/ui/title_logo.png")
	if logo != null:
		_picture(logo, Rect2(450, 114, 380, 126), true)
	else:
		var title := _label("SMASH NINE\nREALMS", Rect2(440, 120, 400, 124), 42, GOLD)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tagline := _label("NINE REALMS. ONE SURVIVOR.", Rect2(440, 250, 400, 28), 18, DIM)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for entry in [["Battle Royale", "select"], ["Story", "story"], ["Watch bots", "watch"], ["Options", "options"], ["Controls", "controls"]]:
		_button(entry[0], Rect2(466, 294 + buttons.size() * 60, 348, 52), entry[1])
	session_status = _label("", Rect2(424, 600, 432, 48), 14, DIM)
	session_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	refresh_options()
	_label("Working title  /  Prototype", Rect2(44, 28, 500, 26), 15, DIM)
	_finish("Arrows / W-S: navigate    Enter / J: confirm    1-5: quick start    V: body    B: watch    T: speed    F2: art")

func show_select() -> void:
	_clear("select")
	_label("CHOOSE YOUR FIGHTER", Rect2(44, 26, 900, 50), 34, GOLD)
	_label("Five worlds. Five ways to survive.", Rect2(46, 79, 800, 26), 17, DIM)
	_panel(Rect2(36, 128, 330, 510))
	_panel(Rect2(742, 128, 502, 510))
	hero_art = _picture(null, Rect2(370, 118, 366, 460))
	var ids := REGISTRY.get_character_ids()
	for index in ids.size():
		var id := ids[index]
		var x := 52.0 + (index % 2) * 154
		var y := 148.0 + floori(index / 2.0) * 144
		var button := _button("", Rect2(x, y, 142, 132), "pick", id)
		portrait_buttons.append(button)
		var selected_frame := Panel.new()
		selected_frame.name = "SelectionOutline"
		selected_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		selected_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var selected_style := StyleBoxFlat.new()
		selected_style.bg_color = Color.TRANSPARENT
		selected_style.border_color = GOLD
		selected_style.set_border_width_all(3)
		selected_frame.add_theme_stylebox_override("panel", selected_style)
		button.add_child(selected_frame)
		_picture(ART.character_portrait(id, body), Rect2(x + 8, y + 6, 126, 94))
		var caption := _label("%d  %s" % [index + 1, tr(str(_roster[id].name))], Rect2(x, y + 100, 142, 26), 18)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button("Random", Rect2(206, 436, 142, 132), "random")
	fighter_name = _label("", Rect2(766, 146, 450, 53), 40, GOLD)
	fighter_role = _label("", Rect2(768, 202, 442, 30), 22)
	description = _label("", Rect2(768, 247, 448, 68), 17, DIM)
	for index in 5:
		var key: String = ["J", "K", "L", "I", "PASSIVE"][index]
		_label(key, Rect2(768, 334 + index * 49, 80, 24), 15, GOLD)
		var line := _label("", Rect2(850, 330 + index * 49, 366, 44), 15)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		skill_labels.append(line)
	body_button = _button("", Rect2(52, 584, 296, 40), "body")
	_button("Back", Rect2(394, 584, 150, 44), "title")
	_button("Start match", Rect2(558, 584, 162, 44), "start")
	_refresh_fighter()
	_finish("Arrows / W-A-S-D: browse    Enter / J: confirm / start    V: body    1-5: quick start    Esc: back")

func _refresh_fighter() -> void:
	var data: Dictionary = _roster[selected_id]
	hero_art.texture = illustration(selected_id, body)
	fighter_name.text = tr(str(data.name)).to_upper()
	fighter_role.text = tr(str(data.role))
	var kit: Array = KITS[selected_id]
	description.text = tr(kit[0])
	for index in 5:
		skill_labels[index].text = tr(kit[index + 1])
	var bodies := REGISTRY.get_bodies(selected_id)
	body_button.text = tr("[V] Body: %s") % tr((body if bodies.size() > 1 else bodies[0]).capitalize())
	body_button.disabled = bodies.size() < 2
	for index in portrait_buttons.size():
		portrait_buttons[index].get_node("SelectionOutline").visible = REGISTRY.get_character_ids()[index] == selected_id
		# Each portrait is followed by its picture and caption in content.
		var picture := content.get_child(portrait_buttons[index].get_index() + 1) as TextureRect
		picture.texture = ART.character_portrait(REGISTRY.get_character_ids()[index], body)

static func illustration(id: String, selected_body: String) -> Texture2D:
	var stem := id + "_" + selected_body if REGISTRY.get_bodies(id).size() > 1 else id
	var path := "res://assets/art/%s/%s_illustration.png" % [id, stem]
	return load(path) as Texture2D if ResourceLoader.exists(path) else ART.character_portrait(id, selected_body)

func show_options() -> void:
	_clear("options")
	_panel(Rect2(270, 66, 740, 580))
	_label("OPTIONS", Rect2(314, 86, 650, 54), 38, GOLD)
	_label("Your choices stay for this session.", Rect2(316, 146, 650, 28), 18, DIM)
	speed_button = _button("", Rect2(316, 198, 648, 54), "speed")
	art_button = _button("", Rect2(316, 264, 648, 54), "art")
	count_button = _button("", Rect2(316, 330, 648, 54), "count")
	panel_button = _button("", Rect2(316, 396, 648, 54), "panel")
	language_button = _button("", Rect2(316, 462, 648, 54), "language")
	_button("Back", Rect2(316, 570, 210, 48), "title")
	refresh_options()
	_finish("Arrows / W-S: navigate    Enter / J / click: change    T: speed    F2: art    Esc: back")

func refresh_options() -> void:
	if screen == "title" and is_instance_valid(session_status):
		session_status.text = tr("Nova / Rio body: %s    |    Speed: %d%%") % [tr(body.capitalize()), SPEED.percent()] + "    |    " + tr("Language") + ": " + LANGUAGE.label()
	if screen != "options":
		return
	speed_button.text = tr("[T]   Game speed                         %d%%") % SPEED.percent()
	art_button.text = tr("[F2]   Art style                         %s") % tr(ART.label())
	count_button.text = tr("Fighters in the next match                         %d") % fighter_count
	panel_button.text = tr("Live bot panel at match start                         %s") % tr("On" if bot_panel_at_start else "Off")
	language_button.text = tr("Language: %s") % LANGUAGE.label()

func show_controls() -> void:
	_clear("controls")
	_panel(Rect2(84, 40, 1112, 604))
	_label("CONTROLS", Rect2(112, 56, 1000, 48), 34, GOLD)
	for index in CONTROLS.size():
		var row: Array = CONTROLS[index]
		var y := 116.0 + index * 29
		_label(row[0], Rect2(116, y, 386, 28), 17, GOLD)
		_label(row[1], Rect2(506, y, 658, 28), 17)
	_button("Back", Rect2(926, 590, 240, 42), "title")
	_finish("Esc: back    Enter / J / click: return to title")

func show_results(winner: Node, reason: String, standings: Array[Node], human: Node, survival: Dictionary) -> void:
	_clear("results")
	_panel(Rect2(28, 26, 1224, 620))
	if is_instance_valid(winner):
		if not _victory_picture(winner, Rect2(38, 98, 310, 478)):
			_picture(illustration(winner.character_id, winner.body_type), Rect2(38, 98, 310, 478))
		_label(tr("%s WINS") % tr(str(winner.display_name)).to_upper(), Rect2(54, 42, 1180, 60), 42, GOLD)
	else:
		_label("DRAW", Rect2(54, 42, 1180, 60), 42, GOLD)
	_label(tr("Decided by %s") % tr(reason.replace("_", " ")), Rect2(360, 106, 836, 26), 17, DIM)
	var grid := GridContainer.new()
	grid.name = "Standings"
	grid.columns = 8
	grid.position = Vector2(360, 156)
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)
	for heading in ["#", "", "Fighter", "KOs", "Damage", "Souls", "Cards", "Survived"]:
		_cell(grid, heading, GOLD)
	for index in standings.size():
		var player: Node = standings[index]
		if not is_instance_valid(player):
			continue
		var color := GOLD if player == human else Color.WHITE
		_cell(grid, str(index + 1), color)
		var face := TextureRect.new()
		face.texture = ART.character_portrait(player.character_id, player.body_type)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.custom_minimum_size = Vector2(34, 34)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(face)
		_cell(grid, ("P1 " if player == human else "") + tr(str(player.display_name)), color, 120)
		_cell(grid, str(player.score), color, 36)
		_cell(grid, "%.0f" % player.damage_dealt, color, 70)
		_cell(grid, str(player.souls), color, 54)
		var card_names: Array[String] = []
		for id in player.upgrades:
			card_names.append(tr(str(SOUL_CARDS.find(str(id)).get("title", id))))
		var cards := _cell(grid, "%d  %s" % [player.upgrades.size(), ", ".join(card_names)] if not card_names.is_empty() else "0", color, 210)
		cards.add_theme_font_size_override("font_size", 13)
		cards.clip_text = true
		cards.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		cards.tooltip_text = ", ".join(card_names) if not card_names.is_empty() else tr("No soul cards")
		cards.mouse_filter = Control.MOUSE_FILTER_PASS
		var seconds := maxi(0, int(survival.get(player, 0)))
		_cell(grid, "%d:%02d" % [seconds / 60, seconds % 60], color, 76)
	var award_names := ["MOST DAMAGE", "MOST KOs", "LONGEST SURVIVAL"]
	for award in 3:
		var best: Node = null
		var best_value := -1.0
		for player in standings:
			var value := float(player.damage_dealt) if award == 0 else (float(player.score) if award == 1 else float(survival.get(player, 0)))
			if value > best_value:
				best = player
				best_value = value
		var x := 360.0 + award * 288
		_panel(Rect2(x, 534, 274, 88), 1.0)
		_label(award_names[award], Rect2(x + 12, 544, 250, 24), 14, GOLD)
		var detail := "No contenders"
		if is_instance_valid(best):
			detail = "%s  /  %s" % [tr(str(best.display_name)), ("%d:%02d" % [int(best_value) / 60, int(best_value) % 60]) if award == 2 else str(int(best_value))]
		_label(detail, Rect2(x + 12, 576, 250, 28), 18)
	_button("[R] Rematch", Rect2(360, 660, 270, 44), "rematch")
	_button("Character select", Rect2(650, 660, 280, 44), "return_select")
	_button("Title", Rect2(950, 660, 274, 44), "return_title")
	if not buttons.is_empty():
		buttons[0].grab_focus()

func _cell(grid: GridContainer, text: String, color: Color, width := 20.0) -> Label:
	var cell := Label.new()
	cell.text = tr(text)
	cell.custom_minimum_size = Vector2(width, 34)
	cell.add_theme_font_size_override("font_size", 18)
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
	sprite.scale = Vector2.ONE * minf(bounds.size.x / cell.x, bounds.size.y / cell.y)
	sprite.position = bounds.get_center()
	content.add_child(sprite)
	sprite.play(&"victory")
	return true

## Configure only the sprite, outside the tree: no player, physics or input enters the menu.
func _ending_victory_source() -> Node:
	var fighter: Node = VICTORY_FACTORY.create(selected_id, body)
	fighter.character_id = selected_id
	fighter.character_sprite = fighter.get_node("CharacterSprite")
	fighter.configure_character_sprite()
	return fighter

func _activate(action: String, value: String) -> void:
	match action:
		"select": show_select()
		"title": show_title()
		"options": show_options()
		"controls": show_controls()
		"pick":
			selected_id = value
			_refresh_fighter()
		"random":
			var ids := REGISTRY.get_character_ids()
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
	if not visible or not is_visible_in_tree() or not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	if code == KEY_ESCAPE:
		if screen == "results":
			action_requested.emit("return_title", "")
		else:
			show_title()
		get_viewport().set_input_as_handled()
	elif code in [KEY_ENTER, KEY_KP_ENTER, KEY_J]:
		get_viewport().set_input_as_handled()
		if screen == "select" and focus_index < portrait_buttons.size():
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
				neighbor.grab_focus()
		else:
			var step := -1 if code in [KEY_UP, KEY_W, KEY_LEFT, KEY_A] else 1
			_move_focus(step)
		get_viewport().set_input_as_handled()

func _move_focus(step: int) -> void:
	if buttons.is_empty():
		return
	focus_index = posmod(focus_index + step, buttons.size())
	for attempt in buttons.size():
		if not buttons[focus_index].disabled:
			break
		focus_index = posmod(focus_index + step, buttons.size())
	buttons[focus_index].grab_focus()
