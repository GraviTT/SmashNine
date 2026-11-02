extends SceneTree
## Story presentation art (ART-70, D43): the dialogue box uses the 9-slice frame and name plate,
## and the lines the catalog marks show their scene picture behind the box. Story art applied
## 2026-10-29 (SART-01..04): three more scene pictures, the start card's stage picture in its
## 9-slice frame, the map's root path, next-stage flame and seals, and the shadow dissolve.

const DIALOGUE := preload("res://scripts/ui/StoryDialogue.gd")
const SCREENS := preload("res://scripts/ui/StoryScreens.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const ART := preload("res://scripts/ArtSettings.gd")
const MAIN := preload("res://scripts/Main.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const VFX := preload("res://scripts/Vfx.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _cg_lines(stage: int, scene: String) -> Array[String]:
	var marks: Array[String] = []
	for line: Array in STORY.stage(stage).dialogue[scene]:
		marks.append(str(line[2].cg) if line.size() > 2 else "")
	return marks

func _run() -> void:
	root.size = Vector2i(1280, 720)
	# Which lines carry a picture.
	_check(_cg_lines(1, "pre") == ["prologue", "prologue", "prologue", "", ""], "Prologue picture behind the three opening narration lines only")
	_check(_cg_lines(8, "post") == ["root", "root", "root"] and _cg_lines(8, "home_post") == ["root", "root"], "Root picture behind every line after Yuki or the home guardian")
	_check(_cg_lines(9, "post") == ["epilogue", "epilogue"], "Epilogue picture behind the closing narration")
	_check(_cg_lines(5, "pre") == ["forest", "forest"] and _cg_lines(7, "pre") == ["beast", "beast"] and _cg_lines(9, "pre") == ["heart", "heart"], "Forest, beast and heart pictures behind the narration opening stages 5, 7 and 9")
	_check(_cg_lines(5, "post") == [""] and _cg_lines(7, "post") == [""], "The short narration after stages 5 and 7 keeps the arena")
	for stage in [2, 3, 4, 6]:
		_check(_cg_lines(stage, "pre").count("") == STORY.stage(stage).dialogue.pre.size(), "No picture in stage %d" % stage)
	for name in ["prologue", "root", "epilogue", "forest", "beast", "heart"]:
		var texture := ART.original_texture(DIALOGUE.CG_ART % name)
		_check(texture != null and texture.get_size() == Vector2(1600, 900), "Scene picture %s is 1600x900" % name)
	# The box, the plate and the picture in a played scene.
	var dialogue: Control = DIALOGUE.new()
	root.add_child(dialogue)
	await process_frame
	dialogue.play(STORY.dialogue_for(STORY.stage(1), "frey", "pre"), "frey", "", "female")
	var frame: NinePatchRect = null
	for child in dialogue.content.get_children():
		if child is NinePatchRect and child.texture != null and child.texture.resource_path == DIALOGUE.FRAME_ART:
			frame = child
	_check(frame != null and frame.patch_margin_left == DIALOGUE.FRAME_MARGIN and Rect2(frame.position, frame.size) == DIALOGUE.BOX, "Dialogue box uses the 9-slice frame")
	_check(dialogue.name_plate is NinePatchRect and dialogue.name_plate.texture.resource_path == DIALOGUE.PLATE_ART, "Speaker name sits on the name plate")
	_check(dialogue.cg_picture.visible and dialogue.cg_picture.texture.resource_path == DIALOGUE.CG_ART % "prologue", "Line 1 shows the prologue picture")
	_check(dialogue.cg_picture.get_index() < frame.get_index(), "Picture is drawn behind the box")
	var narrator_plate: Rect2 = Rect2(dialogue.name_plate.position, dialogue.name_plate.size)
	_check(is_equal_approx(narrator_plate.get_center().x, 640.0), "Narrator plate is centred")
	for step in 3:
		dialogue.line_index += 1
		dialogue._show_line()
	_check(dialogue.line_index == 3 and not dialogue.cg_picture.visible, "The hero's arrival line has no picture")
	_check(is_equal_approx(dialogue.name_plate.position.x, 212.0), "Hero plate sits over the hero's side")
	_check(dialogue.speaker_label.text == tr("Frey") and dialogue.name_plate.size.x >= 160.0, "Plate fits the speaker's name")
	dialogue.queue_free()
	await process_frame
	# The start card: the stage's picture inside the 9-slice frame, every text inside its block.
	var menu: Control = SCREENS.new()
	root.add_child(menu)
	await process_frame
	menu.selected_id = "frey"
	menu.body = "male"
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		for data: Dictionary in STORY.stages():
			menu.show_stage_card(data)
			await process_frame
			var card_frame: NinePatchRect = null
			var picture: TextureRect = null
			for child in menu.content.get_children():
				if child is NinePatchRect and child.texture != null and child.texture.resource_path == SCREENS.CARD_FRAME_ART:
					card_frame = child
				elif child is TextureRect and child.texture != null and child.texture.resource_path == SCREENS.CARD_ART % int(data.id):
					picture = child
				elif child is Label:
					_check(child.get_line_count() * child.get_line_height() <= child.size.y, "Start card text fits its block: %s stage %d %s" % [locale, data.id, child.text])
			_check(card_frame != null and card_frame.patch_margin_left == SCREENS.CARD_FRAME_MARGIN and Rect2(card_frame.position, card_frame.size) == SCREENS.CARD_PANEL, "Stage %d start card uses the 9-slice frame" % data.id)
			_check(picture != null and Rect2(picture.position, picture.size) == SCREENS.CARD_PICTURE and picture.texture.get_size() == Vector2(640, 360), "Stage %d start card shows its 640x360 picture" % data.id)
	LANGUAGE.set_locale("en")
	# The map: the root path, seals on cleared and locked stages, the flame looping on the next one.
	PROGRESS.new_journey("frey", "normal")
	for number in [1, 2, 3]:
		PROGRESS.complete_stage("frey", number, 0, [])
	menu.show_story_map(4)
	await process_frame
	var path: Line2D = null
	var badges := {}
	for child in menu.content.get_children():
		if child is Line2D:
			path = child
		elif child is TextureRect and child.texture != null:
			var source: String = child.texture.atlas.resource_path if child.texture is AtlasTexture else child.texture.resource_path
			if source.contains("/story/map_"):
				badges[source] = int(badges.get(source, 0)) + 1
	_check(path != null and path.texture != null and path.texture_mode == Line2D.LINE_TEXTURE_TILE and path.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED and is_equal_approx(path.width, 12.0), "Map path repeats the 1x root tile")
	_check(badges == {SCREENS.MAP_SEAL_ART % "clear": 3, SCREENS.MAP_NEXT_ART: 1, SCREENS.MAP_SEAL_ART % "locked": 5}, "Three clear seals, one next-stage flame, five locked seals: %s" % str(badges))
	var first_frame: float = menu.map_next_flame.region.position.x
	var seen := {first_frame: true}
	for step in 20:
		await create_timer(0.05).timeout
		seen[menu.map_next_flame.region.position.x] = true
	_check(seen.size() >= 3 and menu.map_next_flame.region.size == Vector2(48, 48), "Next-stage flame loops through its 48x48 frames")
	menu.queue_free()
	PROGRESS.runs.clear()
	await process_frame
	# Main refreshes realm warnings every frame. A hazard warning already running
	# when the objective ends must not reappear over the post scene's hidden HUD.
	for number in [2, 7]:
		MAIN.story_hero = "nova"
		MAIN.story_stage = number
		MAIN.story_difficulty = "normal"
		MAIN.story_art_state = {}
		MAIN.next_screen = "story_stage"
		PROGRESS.new_journey("nova", "normal")
		change_scene_to_file("res://scenes/Main.tscn")
		await _frames(6)
		var main: Node = current_scene
		main.story_session.begin_dialogue()
		main.story_session.dialogue._activate("dialogue_skip", "")
		main.hazards.trigger(int(STORY.stage(number).realm))
		var enemy: Node = main.story_session.rival
		if enemy.has_method("apply_environment_damage"):
			enemy.apply_environment_damage(enemy.hp, main.story_session.hero)
		else:
			enemy.apply_hit(main.story_session.hero, 100000.0, 0.0, Vector2.RIGHT, "fixed")
		await _frames(3)
		_check(main.story_session.phase == "post" and main.story_session.dialogue.visible, "Hazard-warning fixture enters post scene")
		_check(main.hazards.get_phase(int(STORY.stage(number).realm)) == "warning", "The underlying realm warning remains frozen during the scene")
		main._update_hud()
		_check(not main.hud.warning_label.visible and not main.hud.clock_label.visible and not main.hud.minimap_root.visible and not main.hud.hp_bar.visible and not main.story_session.rival_bar.visible, "Every match HUD element, including a timed warning, stays hidden during stage %d scene" % number)
		main._on_story_action("story_title")
		await _frames(6)
	# A defeated stage 9 shadow breaks into the dissolve smoke at its feet; the body goes at once.
	_check(VFX.available("shadow_dissolve") and VFX.SPECS.shadow_dissolve[2] == Vector2(96, 152), "Shadow dissolve strip is present with its feet anchor")
	MAIN.story_hero = "frey"
	MAIN.story_stage = 9
	MAIN.story_difficulty = "normal"
	MAIN.story_art_state = {}
	MAIN.next_screen = "story_stage"
	PROGRESS.new_journey("frey", "normal")
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(6)
	var stage_nine: Node = current_scene
	stage_nine.story_session.begin_dialogue()
	stage_nine.story_session.dialogue._activate("dialogue_skip", "")
	stage_nine.story_session.hero.grant_protection(1000.0)
	var shadow: Node = stage_nine.story_session.enemies[0]
	var feet: Vector2 = shadow.global_position
	shadow.invulnerable_timer = 0.0
	shadow.apply_environment_damage(shadow.hp, stage_nine.story_session.hero)
	await _frames(2)
	var smoke: Node2D = stage_nine.get_node_or_null("Vfx_shadow_dissolve")
	_check(smoke != null and smoke.global_position.is_equal_approx(feet) and smoke.sprite_frames.get_frame_count(&"play") == 6, "Defeated shadow plays the six-frame dissolve at its feet")
	_check(not shadow.visible and shadow.get_node_or_null("Vfx_shadow_aura") == null, "The shadow's body and aura give way to the smoke")
	stage_nine._on_story_action("story_title")
	await _frames(6)
	PROGRESS.runs.clear()
	if not failed:
		print("Story presentation tests passed (marked pictures, 9-slice frame/name plate, start card picture and frame, map path/flame/seals, shadow dissolve, all match HUD including timed warnings hidden during scenes)")
	quit(1 if failed else 0)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
