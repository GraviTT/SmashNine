extends SceneTree
## QA-30: real production presenters/assets in a deterministic evidence fixture.
## No synthetic art, cached stand-ins, product edits, match simulation, or save writes.
const MONSTER := preload("res://scripts/RealmMonster.gd")
const MENU := preload("res://scripts/ui/FrontendMenu.gd")
const SCREENS := preload("res://scripts/ui/StoryScreens.gd")
const DIALOGUE := preload("res://scripts/ui/StoryDialogue.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const FACTORY := preload("res://scripts/PlayerFactory.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const ART := preload("res://scripts/ArtSettings.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const WORLD := preload("res://scripts/realms/RealmWorld.gd")
const LAYOUT := preload("res://scripts/realms/RealmLayout.gd")

var out_dir := ""
var stage: Node2D
var ui: CanvasLayer
var evidence: Array[Dictionary] = []
var failed := false

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://../reports/codex-qa-30")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = ProjectSettings.globalize_path("res://").path_join(arg.get_slice("=", 1))
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	if not ok:
		failed = true
		push_error("QA30: " + description)
	print("QA30_CHECK ", ok, " ", description)

func _run() -> void:
	_check(DisplayServer.get_name() != "headless", "windowed renderer: " + DisplayServer.get_name())
	root.size = Vector2i(1280, 720)
	root.title = "SmashNine QA-30 evidence"
	Engine.max_fps = 60
	ART.style = ART.STYLE_ORIGINAL
	LANGUAGE.load_saved()
	LANGUAGE.set_locale("ko")
	await _reset()
	await _monsters()
	await _reset()
	await _waves()
	await _reset()
	await _dialogue_shot("story-faces", "frey", 3, "pre", 2, "happy", "luna", true)
	await _reset()
	await _dialogue_shot("story-faces-angry", "luna", 3, "pre", 1, "angry", "luna", false)
	await _reset()
	await _dialogue_shot("story-faces-hurt", "luna", 3, "post", 1, "hurt", "luna", false)
	await _reset()
	await _dialogue_shot("story-faces-yuki-hurt", "yuki", 8, "pre", 1, "hurt", "yuki", false)
	await _reset()
	await _dialogue_shot("shadow-face", "luna", 9, "mid", 1, "shadow", "luna", true)
	for id in ["nova", "luna"]:
		await _reset()
		await _results(id, "results-victory" if id == "nova" else "results-victory-luna")
		await _reset()
		await _ending(id, "story-ending" if id == "nova" else "story-ending-luna")
	var file := FileAccess.open(out_dir.path_join("capture-evidence.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"failed": failed, "renderer": DisplayServer.get_name(), "screens": evidence}, "\t") + "\n")
	await _reset()
	print("QA30_CAPTURE_DONE screens=", evidence.size(), " failed=", failed)
	quit(1 if failed else 0)

func _reset() -> void:
	if is_instance_valid(stage):
		stage.queue_free()
	if is_instance_valid(ui):
		ui.queue_free()
	await process_frame
	stage = Node2D.new()
	root.add_child(stage)
	ui = CanvasLayer.new()
	root.add_child(ui)
	root.canvas_transform = Transform2D.IDENTITY
	RenderingServer.set_default_clear_color(Color("101827"))

func _label(text: String, rect: Rect2, font_size := 20) -> void:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e8e5d7"))
	label.add_theme_color_override("font_outline_color", Color("101827"))
	label.add_theme_constant_override("outline_size", 4)
	ui.add_child(label)

func _floor(y: float) -> void:
	# Production platform builder, staged at a known QA baseline.
	var world := WORLD.new()
	stage.add_child(world)
	var tags: Array[String] = []
	world._create_platform(stage, Vector2(740, y + 10), Vector2(960, 20), Color("263746"), "main", tags, Color("8db1cb"), "")

func _monster(id: String, at: Vector2) -> Node:
	var m := MONSTER.new()
	m.setup("ember_imp" if id in ["alfheim_moon_moth", "niflheim_frost_owl"] else "mossling", 0, at, id)
	stage.add_child(m)
	m.set_physics_process(false)
	m.name_label.visible = false
	return m

func _monsters() -> void:
	_label("QA-30 | Real RealmMonster nodes / adopted six-row sheets", Rect2(28, 16, 1220, 34), 26)
	_label("1x game scale. Column poses held for inspection; ground = collision origin.", Rect2(28, 54, 1220, 30), 18)
	var ids := ["alfheim_moon_moth", "jotunheim_rune_golem", "yggdrasil_root_guardian", "niflheim_frost_owl"]
	var states := ["idle", "windup", "attack", "defeat"]
	var details: Array[Dictionary] = []
	for col in 4:
		_label(["IDLE / F1", "WINDUP / 50%", "ATTACK / F3", "DEFEAT / 50%"][col], Rect2(295 + col * 245, 98, 240, 28), 19)
	for row in 4:
		var y := 230.0 + row * 140.0
		_floor(y)
		_label(ids[row].replace("_", "\n"), Rect2(30, y - 95, 230, 90), 19)
		for col in 4:
			var m: Node = _monster(ids[row], Vector2(370 + col * 245, y))
			match states[col]:
				"windup":
					m.action_phase = "windup"
					m.action_timer = m.windup_duration * 0.5
					m.locked_target_position = m.position + Vector2(80, 0)
					m._update_art(0.0)
				"attack":
					m._play_strike_animation()
					m.art_sprite.frame = 2
				"defeat":
					m._die(null)
					m.set_physics_process(false)
					m.defeat_elapsed = 0.25
					m.art_sprite.frame = 2
			m.art_sprite.pause()
			m.queue_redraw()
			var counts: Array[int] = []
			for name in ["idle", "walk", "windup", "attack", "hurt", "defeat"]:
				counts.append(m.art_sprite.sprite_frames.get_frame_count(name))
			_check(counts == [4, 6, 4, 4, 1, 4], ids[row] + " runtime frame counts " + str(counts))
			_check(str(m.art_sprite.animation) == states[col], ids[row] + " selected " + states[col])
			details.append({"skin": ids[row], "state": states[col], "frame_0based": m.art_sprite.frame, "counts": counts, "sheet": m.art_sheet_path, "sprite_y_offset": m.art_sprite.position.y})
	await _shot("six-row-monsters", {"nodes": details, "pose_selection": "game state methods; animation paused at explicit evidence frame"})

func _waves() -> void:
	_label("QA-30 | Real slam attacks / skin-specific and shared waves", Rect2(28, 20, 1220, 40), 26)
	_label("Root Guardian: own wave", Rect2(210, 160, 440, 40), 24)
	_label("Rune Golem: shared slam wave", Rect2(770, 160, 470, 40), 24)
	_floor(440)
	var left: Node = _monster("yggdrasil_root_guardian", Vector2(440, 440))
	var right: Node = _monster("jotunheim_rune_golem", Vector2(970, 440))
	await physics_frame
	left._execute_action()
	right._execute_action()
	# Let the real projectile physics and strip animation advance, then hold them for the shot.
	await create_timer(0.18).timeout
	var details: Array[Dictionary] = []
	for child in stage.get_children():
		if child is Area2D and child.get("projectile_kind") == "shockwave":
			child.set_physics_process(false)
			var sprite := child.get_node("ArtSprite") as AnimatedSprite2D
			sprite.pause()
			var atlas := sprite.sprite_frames.get_frame_texture(&"default", sprite.frame) as AtlasTexture
			var expected := "yggdrasil_root_guardian_shockwave.png" if child.source == left else "slam_shockwave.png"
			_check(atlas.atlas.resource_path.ends_with(expected), "wave texture: " + expected)
			details.append({"source": child.source.skin_id, "texture": atlas.atlas.resource_path, "frame_0based": sprite.frame, "elapsed": child.elapsed, "direction_x": child.direction.x, "flip_h": sprite.flip_h, "position": str(child.position)})
	_check(details.size() == 4, "four live waves from two production slam attacks")
	left.art_sprite.pause()
	right.art_sprite.pause()
	_label("Both directions emitted by RealmMonster._execute_action(). Paused after 0.18 s.", Rect2(110, 535, 1120, 40), 20)
	await _shot("shockwaves", {"waves": details})

func _realm(realm: int) -> void:
	var world := WORLD.new()
	world.layout = LAYOUT.new()
	stage.add_child(world)
	world._build_terrain(stage, realm)
	var camera := Camera2D.new()
	camera.position = world.layout.get_bounds(realm).get_center()
	camera.zoom = Vector2.ONE * minf(1280.0 / world.layout.get_size(realm).x, 720.0 / world.layout.get_size(realm).y)
	stage.add_child(camera)
	camera.make_current()

func _dialogue_shot(stem: String, hero: String, number: int, scene: String, index: int, emotion: String, speaker: String, right: bool) -> void:
	var data := STORY.stage(number)
	_realm(int(data.realm))
	var dialogue := DIALOGUE.new()
	ui.add_child(dialogue)
	var lines := STORY.dialogue_for(data, hero, scene)
	# Match StorySession's home-stage call: there is no rival portrait at home.
	dialogue.play(lines, hero, "" if STORY.is_home(data, hero) else str(data.rival), "female")
	dialogue.line_index = index
	dialogue._show_line()
	dialogue.advance_line()
	dialogue.set_process(false)
	var face: Texture2D = dialogue.right_face.texture if right else dialogue.left_face.texture
	var expected := "res://assets/art/%s/%s_face%s.png" % [speaker, speaker, "" if speaker == "yuki" and emotion == "hurt" else "_" + emotion]
	_check(face.resource_path == expected, stem + " uses " + expected)
	if emotion == "shadow":
		_check(dialogue.right_face.modulate == Color.WHITE, "shadow face has no extra purple tint")
	_label("QA-30 | Story stage %d / %s / %s" % [number, speaker, emotion], Rect2(30, 20, 1200, 38), 24)
	await _shot(stem, {"hero": hero, "speaker": str(lines[index][0]), "stage": number, "scene": scene, "line_index": index, "line": lines[index], "selected_texture": face.resource_path, "yuki_neutral_fallback": speaker == "yuki" and emotion == "hurt"})

func _fighter(id: String) -> Node:
	var fighter: Node = FACTORY.create(id, "female")
	stage.add_child(fighter)
	fighter.setup(REGISTRY.get_characters()[id], 1, false)
	fighter.set_physics_process(false)
	fighter.visible = false
	return fighter

func _results(id: String, stem: String) -> void:
	var winner: Node = _fighter(id)
	var other: Node = _fighter("luna" if id == "nova" else "nova")
	other.player_id = 2
	var standings: Array[Node] = [winner, other]
	var menu := MENU.new()
	ui.add_child(menu)
	menu.show_results(winner, "last_survivor", standings, winner, {})
	var motion := menu.content.get_node_or_null("VictoryMotion") as AnimatedSprite2D
	_check(motion != null, id + " adopted victory motion present")
	if motion == null:
		return
	var limit := Time.get_ticks_msec() + 10000
	while motion.is_playing() and Time.get_ticks_msec() < limit:
		await process_frame
	_check(not motion.is_playing() and motion.frame == 5, id + " victory finishes and holds F6")
	var atlas := motion.sprite_frames.get_frame_texture(&"victory", motion.frame) as AtlasTexture
	_label("QA-30 | " + id + " female / victory F6 held / fixture statistics", Rect2(360, 470, 830, 28), 17)
	await _shot(stem, {"hero": id, "body": "female", "frame_0based": motion.frame, "is_playing": motion.is_playing(), "texture": atlas.atlas.resource_path, "statistics": "two real fighters with default zero statistics; not a played match"})

func _ending(id: String, stem: String) -> void:
	var ending := SCREENS.new()
	ui.add_child(ending)
	ending.selected_id = id
	ending.body = "female"
	ending.show_story_ending()
	var main_art := MENU.illustration(id, "female")
	var count := 0
	for child in ending.content.get_children():
		if child is TextureRect and child.texture == main_art:
			count += 1
	_check(count == 1 and ending.content.get_node_or_null("VictoryMotion") == null, id + " ending shows illustration and no victory motion")
	_label("QA-30 | " + id + " female / real story ending / main illustration (D43)", Rect2(36, 20, 1190, 28), 17)
	await _shot(stem, {"hero": id, "body": "female", "illustration": main_art.resource_path, "illustration_nodes": count, "victory_motion_nodes": 0})

func _shot(stem: String, detail: Dictionary) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join(stem + ".png")
	_check(root.get_texture().get_image().save_png(path) == OK, "saved " + stem)
	detail["png"] = stem + ".png"
	evidence.append(detail)
	print("QA30_SAVED ", path)
