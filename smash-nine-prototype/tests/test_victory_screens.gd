extends SceneTree
const MENU := preload("res://scripts/ui/FrontendMenu.gd")
const STORY := preload("res://scripts/ui/StoryScreens.gd")
const FACTORY := preload("res://scripts/PlayerFactory.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")

var failed := false
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)

func _lend(fighter: Node) -> void:
	var frames: SpriteFrames = fighter.character_sprite.sprite_frames
	var row: StringName = fighter._get_sprite_animation_name(&"victory")
	var original := frames.get_frame_texture(fighter._get_sprite_animation_name(&"hurt"), 0).get_image()
	var strip := Image.create(1152, 192, false, Image.FORMAT_RGBA8)
	for index in 6:
		strip.blit_rect(original, Rect2i(0, 0, 128, 128), Vector2i(index * 192 + 32, 32))
	_check(fighter._add_optional_motion_strip(frames, String(row).trim_suffix("_victory"), ImageTexture.create_from_image(strip), fighter.OPTIONAL_MOTION_ROWS[4]), "192px victory stand-in loads")

func _illustrations(screen: Node, texture: Texture2D) -> int:
	var count := 0
	for child in screen.content.get_children():
		if child is TextureRect and child.texture == texture:
			count += 1
	return count

func _run() -> void:
	var menu := Control.new()
	menu.set_script(MENU)
	root.add_child(menu)
	var ending: Control = STORY.new()
	root.add_child(ending)
	for id in REGISTRY.get_character_ids():
		for body in REGISTRY.get_bodies(id):
			var winner: Node = FACTORY.create(id, body)
			root.add_child(winner)
			winner.setup(REGISTRY.get_characters()[id], 1, false)
			winner.set_physics_process(false)
			for row in winner.character_sprite.sprite_frames.get_animation_names():
				if String(row).ends_with("_victory"):
					winner.character_sprite.sprite_frames.remove_animation(row)
			var standings: Array[Node] = [winner]
			menu.show_results(winner, "last_survivor", standings, winner, {})
			_check(menu.content.get_node_or_null("VictoryMotion") == null, "missing victory keeps results still")
			_check(_illustrations(menu, MENU.illustration(id, body)) == 1, "results keeps today's illustration for %s %s" % [id, body])
			if id == "frey":
				ending.hide()
				await _shot("results-existing")
			ending.selected_id = id
			ending.body = body
			var players_before := get_nodes_in_group("players").size()
			ending.show_story_ending()
			# D43: every form has an adopted victory row now; the story ending still shows the main illustration.
			_check(ending.content.get_node_or_null("VictoryMotion") == null and _illustrations(ending, MENU.illustration(id, body)) == 1, "story ending keeps the main illustration for %s %s (D43)" % [id, body])
			_check(get_nodes_in_group("players").size() == players_before, "ending builds no fighter")
			if id == "frey":
				menu.hide()
				await _shot("ending-illustration")
				menu.show()
			_lend(winner)
			winner._play_sprite_pose(&"attack", 0, 1, 0.4, 0.1)
			var pose: StringName = winner.character_sprite.animation
			menu.show_results(winner, "last_survivor", standings, winner, {})
			var motion := menu.content.get_node_or_null("VictoryMotion") as AnimatedSprite2D
			_check(motion != null and motion.is_playing(), "results plays winner victory")
			_check(winner.character_sprite.animation == pose and winner.sprite_pose_last == 1, "results leaves live winner's D38 pose untouched")
			_check(_illustrations(menu, MENU.illustration(id, body)) == 0, "new victory replaces illustration in same slot")
			if id == "frey":
				ending.hide()
				await _shot("results-stand-in")
				ending.show()
			winner.free()
	# Verify playback after the source fighter has been freed, including hold and screen cleanup.
	await create_timer(0.84).timeout
	var motion := menu.content.get_node("VictoryMotion") as AnimatedSprite2D
	_check(motion.frame == 5 and not motion.is_playing(), "results victory holds final drawing after source removal")
	var old_content: Control = menu.content
	menu.show_title()
	_check(old_content.is_queued_for_deletion() and menu.content.get_node_or_null("VictoryMotion") == null, "changing screen disposes victory preview")
	var nobody: Array[Node] = []
	menu.show_results(null, "draw", nobody, null, {})
	_check(menu.content.get_node_or_null("VictoryMotion") == null, "draw has no winner motion")
	menu.queue_free()
	ending.queue_free()
	await process_frame
	print("Victory screens: %d checks, failed=%s" % [checks, failed])
	quit(1 if failed else 0)

func _shot(stem: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture") or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../reports/codex-sys-06")
	DirAccess.make_dir_recursive_absolute(path)
	_check(root.get_texture().get_image().save_png(path.path_join(stem + ".png")) == OK, "capture " + stem)
