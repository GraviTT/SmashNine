extends SceneTree
## Windowed captures of the story art applied 2026-10-29 (SART-01..04): the three new scene
## pictures and the repaired root picture behind the dialogue box, start cards, the map
## ornaments and a stage 9 shadow dissolving. Korean text; never reads or writes the real save.
## Run windowed from smash-nine-prototype/:
##   <godot> --path . -s tests/analysis/lead/capture_story_art.gd
const DIALOGUE := preload("res://scripts/ui/StoryDialogue.gd")
const SCREENS := preload("res://scripts/ui/StoryScreens.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const MAIN := preload("res://scripts/Main.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
var report_dir := ""
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	report_dir = ProjectSettings.globalize_path("res://../reports/after-checkpoint-2026-10-25/story-art-apply-2026-10-29")
	DirAccess.make_dir_recursive_absolute(report_dir)
	_check(DisplayServer.get_name() != "headless", "Captures must be windowed")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	# The menus load the saved language once on creation; load it first so Korean stays.
	LANGUAGE.load_saved()
	LANGUAGE.set_locale("ko")
	# Scene pictures behind the dialogue box: the opening narration of stages 5, 7 and 9, and the
	# root seal after stage 8 (its papers repainted as talismans).
	var dialogue: Control = DIALOGUE.new()
	root.add_child(dialogue)
	await _frames(2)
	for shot in [[5, "pre", "01-cg-forest"], [7, "pre", "02-cg-beast"], [9, "pre", "03-cg-heart"], [8, "post", "04-cg-root-talismans"]]:
		var data := STORY.stage(int(shot[0]))
		dialogue.play(STORY.dialogue_for(data, "luna", str(shot[1])), "luna", str(data.rival), "female")
		dialogue.line_label.visible_characters = -1
		dialogue._characters = dialogue.line_label.get_total_character_count()
		await _capture(str(shot[2]))
	dialogue.queue_free()
	# Start cards: a monster stage, a rival stage with the VS band, and the final stage.
	var menu: Control = SCREENS.new()
	root.add_child(menu)
	await _frames(2)
	menu.selected_id = "luna"
	menu.body = "female"
	for number in [5, 2, 9]:
		menu.show_stage_card(STORY.stage(number))
		menu.card_deadline = 9223372036854775807
		await _capture("05-start-card-%02d" % number)
	# The map after three clears: seals, the next-stage flame and the root path in the gaps.
	PROGRESS.new_journey("luna", "normal")
	for number in [1, 2, 3]:
		PROGRESS.complete_stage("luna", number, 0, [])
	menu.show_story_map(4)
	await _capture("06-story-map")
	menu.queue_free()
	PROGRESS.runs.clear()
	# Stage 9: four shadows on the floor, then one breaks into the dissolve smoke.
	MAIN.story_hero = "luna"
	MAIN.story_stage = 9
	MAIN.story_difficulty = "normal"
	MAIN.story_art_state = {}
	MAIN.next_screen = "story_stage"
	PROGRESS.new_journey("luna", "normal")
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(8)
	var main: Node = current_scene
	main.hud.bot_panel_wanted = false
	main.hud.bot_panel.visible = false
	main.story_session.begin_dialogue()
	main.story_session.dialogue._activate("dialogue_skip", "")
	var hero: Node = main.story_session.hero
	hero.grant_protection(1000.0)
	var floor_rect: Rect2 = main.layout.get_platform_rects(8)[0]
	var center := Vector2(floor_rect.get_center().x, floor_rect.position.y - 2.0)
	hero.global_position = center + Vector2(-340, 0)
	var shadows: Array = main.story_session.enemies
	for index in shadows.size():
		shadows[index].global_position = center + Vector2([-120, 60, 240, 420][index], 0)
		shadows[index].velocity = Vector2.ZERO
	main._update_camera_follow()
	main.camera.reset_smoothing()
	await _frames(2)
	await _capture("07-shadows-before")
	var target: Node = shadows[1]
	target.invulnerable_timer = 0.0
	target.apply_environment_damage(target.hp, hero)
	await _frames(1)
	await _capture("08-dissolve-a")
	await _frames(8)
	await _capture("09-dissolve-b")
	await _frames(12)
	await _capture("10-dissolve-c")
	main._on_story_action("story_title")
	await _frames(4)
	PROGRESS.runs.clear()
	LANGUAGE.set_locale("en")
	print("Story art captures in %s" % report_dir)
	quit(1 if failed else 0)

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _capture(stem: String) -> void:
	await _frames(2)
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_jpg(report_dir.path_join(stem + ".jpg"), 0.92) == OK, "Save capture: " + stem)
