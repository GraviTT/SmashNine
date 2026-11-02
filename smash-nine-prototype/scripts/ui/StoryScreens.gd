extends "res://scripts/ui/FrontendMenu.gd"
## Reuses the battle-royale menu's art, layout helpers, focus and body preview.
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const REALMS := preload("res://scripts/realms/RealmCatalog.gd")
## Story art applied 2026-10-29: each stage's picture on the start card inside the dialogue box's
## 9-slice family (SART-02, SART-03), and on the map a root path, a looping soul flame on the next
## stage and clear/locked seals (SART-04).
const CARD_ART := "res://assets/art/story/stage_card_%02d.png"
const CARD_FRAME_ART := "res://assets/art/story/start_card_frame.png"
const CARD_FRAME_MARGIN := 24
const CARD_PANEL := Rect2(190, 98, 900, 520)
const CARD_PICTURE := Rect2(224, 126, 384, 216)
const MAP_PATH_ART := "res://assets/art/story/map_path_tile.png"
const MAP_NEXT_ART := "res://assets/art/story/map_marker_next.png"
const MAP_SEAL_ART := "res://assets/art/story/map_seal_%s.png"
const MAP_NEXT_FPS := 8.0
var difficulty := "normal"
var map_stage := 1
var continue_button: Button
var difficulty_button: Button
var start_button: Button
var map_title: Label
var map_goal: Label
var map_realm: Label
var map_status: Label
var map_face: TextureRect
var stage_buttons: Array[Button] = []
var map_next_flame: AtlasTexture
var stage_result: Dictionary = {}
var card_deadline := 0
var _story_preview_id := ""

func _ready() -> void:
	super._ready()
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_story_select() -> void:
	_story_preview_id = ""
	super.show_select()
	screen = "story_select"
	content.get_child(0).text = tr("CHOOSE YOUR HERO")
	content.get_child(1).text = tr("A journey through nine realms.")
	# Keep the existing five portraits and kit preview; progress fits beneath each name.
	for index in portrait_buttons.size():
		var id := REGISTRY.get_character_ids()[index]
		var run := PROGRESS.get_run(id)
		portrait_buttons[index].focus_entered.connect(func() -> void:
			selected_id = id
			_refresh_fighter())
		var caption := content.get_child(portrait_buttons[index].get_index() + 2) as Label
		caption.position.y -= 8
		caption.size.y = 42
		caption.add_theme_font_size_override("font_size", 15)
		caption.text = "%d  %s\n%s" % [index + 1, tr(str(_roster[id].name)), tr("CLEAR") if run.get("done", false) else "★ %d/9" % int(run.get("cleared", 0))]
		var picture := content.get_child(portrait_buttons[index].get_index() + 1) as TextureRect
		picture.size.y = 82
	buttons[5].visible = false
	buttons[5].disabled = true
	difficulty_button = _button("", Rect2(206, 436, 142, 132), "story_difficulty")
	difficulty_button.add_theme_font_size_override("font_size", 17)
	buttons[8].text = tr("New journey")
	continue_button = _button("Continue", Rect2(394, 522, 326, 48), "story_continue")
	footer.text = tr("1-5: choose hero    V: body    Enter / J: continue    Esc: title")
	_refresh_story_selection()

func _refresh_fighter() -> void:
	super._refresh_fighter()
	if screen == "story_select":
		_refresh_story_selection()

func _refresh_story_selection() -> void:
	if not is_instance_valid(continue_button) or not is_instance_valid(difficulty_button):
		return
	var run := PROGRESS.get_run(selected_id)
	if _story_preview_id != selected_id:
		_story_preview_id = selected_id
		if not run.is_empty():
			difficulty = str(run.difficulty)
	continue_button.disabled = run.is_empty()
	difficulty_button.text = tr("Difficulty") + "\n" + tr("Easy" if difficulty == "easy" else "Normal")

func refresh_body(next_body: String) -> void:
	if screen == "story_select":
		body = next_body
		_refresh_fighter()
	else:
		super.refresh_body(next_body)

func show_story_map(selected_stage := 1) -> void:
	_clear("story_map")
	var initial_stage := clampi(selected_stage, 1, 9)
	map_stage = initial_stage
	stage_buttons.clear()
	map_next_flame = null
	_label("STORY MAP", Rect2(44, 24, 800, 48), 34, GOLD)
	_label(tr("%s's journey") % tr(str(_roster[selected_id].name)), Rect2(46, 80, 820, 32), 20, DIM)
	var realms := REALMS.build_maps()
	var stages := STORY.stages()
	var cleared := int(PROGRESS.get_run(selected_id).get("cleared", 0))
	var path := Line2D.new()
	var root_tile := ART.original_texture(MAP_PATH_ART)
	if root_tile != null:
		# The root repeats along the path at 1x; the cells cover it except in the gaps between them.
		path.texture = root_tile
		path.texture_mode = Line2D.LINE_TEXTURE_TILE
		path.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		path.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		path.width = root_tile.get_height()
	else:
		path.width = 5
		path.default_color = Color("777255")
	content.add_child(path)
	for data in stages:
		var grid: Vector2i = realms[data.realm].grid
		path.add_point(Vector2(144 + grid.x * 214, 218 + grid.y * 168))
	for data in stages:
		var grid: Vector2i = realms[data.realm].grid
		var x := 46.0 + grid.x * 214
		var y := 132.0 + grid.y * 168
		var button := _button("", Rect2(x, y, 196, 152), "story_stage_pick", str(data.id))
		stage_buttons.append(button)
		button.focus_entered.connect(func() -> void:
			map_stage = int(data.id)
			_refresh_map_detail())
		var emblem := _picture(ART.original_texture("res://assets/art/ui/realm_emblems/%s.png" % str(realms[data.realm].name).to_lower().replace(" ", "_")), Rect2(x + 50, y + 4, 96, 96), true)
		emblem.modulate.a = 1.0 if int(data.id) <= cleared + 1 else 0.3
		var caption := _label("%d  %s" % [data.id, tr(str(realms[data.realm].name))], Rect2(x + 4, y + 98, 188, 26), 16)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var status := _label(tr("CLEAR") if int(data.id) <= cleared else (tr("Coming soon") if not data.ready else (tr("Next stage") if int(data.id) == cleared + 1 else tr("Locked"))), Rect2(x + 4, y + 124, 188, 22), 14, GOLD if int(data.id) <= cleared + 1 else DIM)
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_map_badge(int(data.id), cleared, bool(data.ready), Vector2(x + 150, y + 6))
	_panel(Rect2(730, 132, 510, 488))
	map_title = _label("", Rect2(754, 152, 460, 98), 30, GOLD)
	map_realm = _label("", Rect2(754, 256, 460, 30), 22, DIM)
	map_goal = _label("", Rect2(754, 306, 460, 100), 23)
	map_face = _picture(null, Rect2(1046, 422, 150, 150))
	map_status = _label("", Rect2(754, 426, 274, 104), 20, DIM)
	start_button = _button("Start stage", Rect2(754, 552, 260, 48), "story_start")
	_button("Back", Rect2(1040, 552, 174, 48), "story_select")
	_finish("Arrows / W-A-S-D: browse    Enter / J: start    Esc: back")
	stage_buttons[initial_stage - 1].grab_focus()
	map_stage = initial_stage
	_refresh_map_detail()

func _refresh_map_detail() -> void:
	if not is_instance_valid(map_title):
		return
	var data := STORY.stage(map_stage)
	var realm: Dictionary = REALMS.build_maps()[data.realm]
	map_title.text = tr("STAGE %d") % map_stage + "\n" + tr(str(data.title))
	map_realm.text = tr(str(realm.name))
	map_goal.text = tr("Defeat the home guardian") if STORY.is_home(data, selected_id) else tr(str(data.goal))
	var unlocked := map_stage <= int(PROGRESS.get_run(selected_id).get("cleared", 0)) + 1
	start_button.disabled = not data.ready or not unlocked
	var objective_label := {5: "Soul crystal escape", 7: "Boss battle", 9: "Shadow showdown"}
	map_status.text = tr("Coming soon") if not data.ready else (tr("Locked") if not unlocked else (tr("Home guardian") if STORY.is_home(data, selected_id) else (tr(str(_roster[data.rival].name)) if data.rival != "" else tr(str(objective_label.get(map_stage, "Two monster waves"))))))
	map_face.texture = ART.character_portrait(str(data.rival), REGISTRY.get_bodies(str(data.rival))[0]) if data.rival != "" and not STORY.is_home(data, selected_id) else ART.original_texture("res://assets/art/monsters/%s_sheet.png" % data.home_elite)
	if map_stage == 9:
		map_face.texture = ART.character_portrait(selected_id, body)
		map_face.modulate = Color(0.42, 0.24, 0.62)
	elif data.rival == "" or STORY.is_home(data, selected_id):
		map_face.modulate = Color.WHITE
		# Monster sheets have six columns; use their authored cell size.
		if map_face.texture != null:
			var atlas := AtlasTexture.new()
			atlas.atlas = map_face.texture
			var cell := map_face.texture.get_width() / 6
			atlas.region = Rect2(0, 0, cell, cell)
			map_face.texture = atlas
		map_face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	else:
		map_face.modulate = Color.WHITE

## The cell's top-right badge: a seal on cleared and locked stages, the soul flame on the next one.
func _map_badge(id: int, cleared: int, playable: bool, at: Vector2) -> void:
	if not playable:
		return
	if id == cleared + 1:
		var strip := ART.original_texture(MAP_NEXT_ART)
		if strip != null:
			map_next_flame = AtlasTexture.new()
			map_next_flame.atlas = strip
			map_next_flame.region = Rect2(0, 0, strip.get_height(), strip.get_height())
			_picture(map_next_flame, Rect2(at - Vector2(4, 4), map_next_flame.region.size), true)
		return
	var seal := ART.original_texture(MAP_SEAL_ART % ("clear" if id <= cleared else "locked"))
	if seal != null:
		_picture(seal, Rect2(at, seal.get_size()), true)

func show_stage_card(data: Dictionary) -> void:
	_clear("story_start")
	_card_frame()
	var realm: Dictionary = REALMS.build_maps()[data.realm]
	# The stage's picture on the left with the title beside it; the realm emblem stands in when
	# that art is off (F2) or missing.
	var picture := ART.original_texture(CARD_ART % int(data.id))
	if picture != null:
		_panel(CARD_PICTURE.grow(2), 1.0)
		_picture(picture, CARD_PICTURE)
	else:
		_picture(ART.original_texture("res://assets/art/ui/realm_emblems/%s.png" % str(realm.name).to_lower().replace(" ", "_")), Rect2(CARD_PICTURE.get_center() - Vector2(48, 48), Vector2(96, 96)), true)
	_label(tr("STAGE %d") % int(data.id), Rect2(632, 124, 424, 42), 28, GOLD)
	_label(tr(str(data.title)), Rect2(632, 166, 424, 52), 32)
	_label(tr(str(realm.name)), Rect2(632, 222, 424, 36), 24, GOLD)
	_label(tr("Defeat the home guardian") if STORY.is_home(data, selected_id) else tr(str(data.goal)), Rect2(632, 262, 424, 66), 22)
	for index in data.tips.size():
		_label(tr(str(data.tips[index])), Rect2(224, 360 + index * 32, 832, 30), 19, DIM)
	if data.rival != "" and not STORY.is_home(data, selected_id):
		_picture(ART.original_texture("res://assets/art/vfx/ult_cutin_band.png"), Rect2(224, 436, 810, 94), true)
		_picture(ART.character_portrait(selected_id, body), Rect2(280, 434, 94, 94))
		_picture(ART.character_portrait(data.rival, "male"), Rect2(890, 434, 94, 94))
		var vs := _label("VS", Rect2(590, 454, 100, 40), 30, GOLD)
		vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button("Begin", Rect2(490, 550, 300, 48), "story_begin")
	card_deadline = Time.get_ticks_msec() + 2500

## A dark backing under the start card's 9-slice frame, as under the dialogue box; the plain
## panel when that art is off (F2) or missing.
func _card_frame() -> void:
	var frame := ART.original_texture(CARD_FRAME_ART)
	if frame == null:
		_panel(CARD_PANEL, 0.98)
		return
	var backing := ColorRect.new()
	backing.position = CARD_PANEL.position + Vector2(6, 6)
	backing.size = CARD_PANEL.size - Vector2(12, 12)
	backing.color = Color(INK, 0.98)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(backing)
	var patch := NinePatchRect.new()
	patch.texture = frame
	patch.patch_margin_left = CARD_FRAME_MARGIN
	patch.patch_margin_top = CARD_FRAME_MARGIN
	patch.patch_margin_right = CARD_FRAME_MARGIN
	patch.patch_margin_bottom = CARD_FRAME_MARGIN
	patch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	patch.position = CARD_PANEL.position
	patch.size = CARD_PANEL.size
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(patch)

func show_story_pause() -> void:
	_clear("story_pause")
	_panel(Rect2(414, 140, 452, 450), 0.98)
	_label("PAUSED", Rect2(454, 164, 372, 48), 34, GOLD)
	for entry in [["Resume", "story_resume"], ["Retry", "story_retry"], ["Story map", "story_map"], ["Title", "story_title"]]:
		_button(entry[0], Rect2(454, 242 + buttons.size() * 74, 372, 52), entry[1])
	_finish("Esc: resume    Enter / J: confirm")

func show_story_result(result: Dictionary) -> void:
	AUDIO.story_result(self, bool(result.clear))
	stage_result = result
	_clear("story_result")
	_panel(Rect2(140, 78, 1000, 548), 0.98)
	_picture(illustration(selected_id, body), Rect2(164, 144, 320, 448))
	_label("STAGE CLEAR" if result.clear else "STAGE FAILED", Rect2(500, 112, 600, 64), 40, GOLD)
	_label(tr("STAGE %d") % int(result.stage) + "  /  " + tr(str(STORY.stage(result.stage).title)), Rect2(500, 194, 600, 60), 24)
	var seconds := int(result.seconds)
	_label(tr("Time: %s") % ("%d:%02d" % [seconds / 60, seconds % 60]), Rect2(500, 276, 600, 40), 24)
	_label(tr("Damage taken: %d") % int(result.damage), Rect2(500, 326, 600, 40), 24)
	var card_names: Array[String] = []
	for id in result.cards:
		card_names.append(tr(str(SOUL_CARDS.find(id).get("title", id))))
	_label(tr("Cards: %s") % (", ".join(card_names) if not card_names.is_empty() else tr("No soul cards")), Rect2(500, 376, 600, 80), 22)
	if not result.clear and result.get("reason", "") == "time up":
		_label("Time up", Rect2(500, 470, 600, 40), 21, GOLD)
	_button("Next" if result.clear else "Retry", Rect2(500, 544, 190, 52), "story_next" if result.clear else "story_retry")
	_button("Story map", Rect2(706, 544, 190, 52), "story_map")
	_button("Title", Rect2(912, 544, 190, 52), "story_title")
	_finish("R: retry    Enter / J: confirm    Esc: story map")

func show_story_ending() -> void:
	AUDIO.story_ending(self)
	_clear("story_ending")
	_panel(Rect2(100, 62, 1080, 590), 0.98)
	# D43: the story ending shows the hero's main illustration; the victory pose is for the results screen.
	_picture(illustration(selected_id, body), Rect2(122, 118, 350, 500))
	_label("STORY COMPLETE", Rect2(500, 102, 640, 66), 40, GOLD)
	_label(tr(str(_roster[selected_id].name)), Rect2(500, 188, 620, 42), 28, _roster[selected_id].color)
	var ids := STORY.ending_ids(selected_id)
	for index in ids.size():
		_label(tr(ids[index]), Rect2(500, 254 + index * 84, 620, 80), 24)
	_button("Story map", Rect2(500, 554, 294, 52), "story_map")
	_button("Title", Rect2(816, 554, 294, 52), "story_title")
	_finish("Enter / J: confirm    Esc: story map")

func _activate(action: String, value: String) -> void:
	if screen == "story_select" and action in ["start", "title"]:
		action_requested.emit("story_new" if action == "start" else "story_title", "")
		return
	match action:
		"story_difficulty":
			difficulty = "easy" if difficulty == "normal" else "normal"
			PROGRESS.set_difficulty(selected_id, difficulty)
			_refresh_story_selection()
		"story_stage_pick":
			map_stage = int(value)
			_refresh_map_detail()
			if not start_button.disabled:
				action_requested.emit("story_start", str(map_stage))
		"pick":
			super._activate(action, value)
		_: super._activate(action, value)

func _input(event: InputEvent) -> void:
	if not screen.begins_with("story_"):
		super._input(event)
		return
	if not visible or not is_visible_in_tree() or not event is InputEventKey or not event.pressed or event.echo:
		return
	var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if code == KEY_F2:
		action_requested.emit("story_art", "")
	elif code == KEY_ESCAPE:
		action_requested.emit({"story_select": "story_title", "story_map": "story_select", "story_pause": "story_resume", "story_result": "story_map", "story_ending": "story_map", "story_start": "story_begin"}.get(screen, "story_title"), "")
	elif code == KEY_R and screen == "story_result":
		action_requested.emit("story_retry", "")
	elif code >= KEY_1 and code <= KEY_5 and screen == "story_select":
		selected_id = REGISTRY.get_character_ids()[code - KEY_1]
		_refresh_fighter()
		portrait_buttons[code - KEY_1].grab_focus()
	elif code in [KEY_ENTER, KEY_KP_ENTER, KEY_J]:
		if screen == "story_select" and focus_index < portrait_buttons.size():
			action_requested.emit("story_continue" if not continue_button.disabled else "story_new", "")
		elif screen == "story_start":
			action_requested.emit("story_begin", "")
		elif not buttons.is_empty() and focus_index >= 0 and not buttons[focus_index].disabled:
			buttons[focus_index].pressed.emit()
	elif code in [KEY_UP, KEY_W, KEY_DOWN, KEY_S, KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D]:
		if screen in ["story_select", "story_map"]:
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
			if screen == "story_select" and focus_index < 5:
				selected_id = REGISTRY.get_character_ids()[focus_index]
				_refresh_fighter()
		else:
			_move_focus(-1 if code in [KEY_UP, KEY_W, KEY_LEFT, KEY_A] else 1)
	else:
		return
	get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if screen == "story_start" and visible and Time.get_ticks_msec() >= card_deadline:
		card_deadline = 9223372036854775807
		action_requested.emit("story_begin", "")
	if screen == "story_map" and visible:
		var next := int(PROGRESS.get_run(selected_id).get("cleared", 0))
		for index in stage_buttons.size():
			if is_instance_valid(stage_buttons[index]):
				stage_buttons[index].modulate = Color(1.0, 0.88 + 0.12 * sin(Time.get_ticks_msec() * 0.004), 0.7) if index == next else Color.WHITE
		if map_next_flame != null:
			var cell := map_next_flame.region.size.x
			var frames := int(map_next_flame.atlas.get_width() / cell)
			map_next_flame.region.position.x = cell * (int(Time.get_ticks_msec() * MAP_NEXT_FPS / 1000.0) % frames)
