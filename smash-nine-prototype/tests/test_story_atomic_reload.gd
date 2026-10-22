extends SceneTree
## F2 snapshots can precede deferred objective/failure callbacks in the same frame.
const MAIN := preload("res://scripts/Main.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const ART := preload("res://scripts/ArtSettings.gd")
var failed := false
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	var main: Node = await _start(5)
	for crystal: Node in main.story_session.crystals:
		for hit in 3:
			crystal.apply_hit(main.story_session.hero, 1.0, 0.0, Vector2.RIGHT)
	# No frame has elapsed: the third broken callback has queued, but not yet run,
	# _objective_done. Capture this valid intermediate state.
	main._on_story_action("story_art")
	await _frames(6)
	main = current_scene
	_check(main.story_session.crystals_broken == 3, "Atomic crystal reload keeps the three broken crystals")
	_check(main.story_session.phase == "post" and main.story_session.dialogue.visible, "F2 on the final crystal frame must finish the objective, not strand combat at 3/3")
	_check(main.director.warning_realms.is_empty(), "Completed atomic crystal reload cannot restart the warning")
	for number in [1, 9]:
		main = await _start(number)
		if number == 9:
			for enemy: Node in main.story_session.enemies:
				enemy.apply_environment_damage(enemy.hp, main.story_session.hero)
			await _frames(3)
			main.story_session.dialogue._activate("dialogue_skip", "")
			_check(main.director.band_started_at >= 0.0, "Atomic final-death fixture includes the active band")
		main.story_session.hero.apply_environment_damage(main.story_session.hero.hp + 1.0)
		main._on_story_action("story_art")
		await _frames(6)
		main = current_scene
		_check(main.match_over and main.story_session.phase == "result" and not main.hud.frontend.stage_result.clear, "F2 on the fatal-hit frame must preserve stage %d failure" % number)
		_check(main.story_session.hero.is_defeated and main.story_session.hero.hp <= 0.0, "Reload cannot revive a zero-HP hero before deferred failure")
		_check(not PROGRESS.get_run("frey").done, "Atomic death does not mark CLEAR")
		main._on_story_action("story_art")
		await _frames(6)
		main = current_scene
		_check(main.match_over and main.story_session.hero.is_defeated, "F2 from a failed result also retains the defeated hero")
	main = await _start(7)
	main.story_session.rival.apply_hit(main.story_session.hero, 100000.0, 0.0, Vector2.RIGHT, "fixed")
	main._on_story_action("story_art")
	await _frames(6)
	main = current_scene
	_check(main.story_session.phase == "post" and main.story_session.dialogue.visible, "F2 on boss-defeat frame preserves pending completion too")
	main._on_story_action("story_title")
	await _frames(6)
	ART.style = ART.STYLE_ORIGINAL
	PROGRESS.runs.clear()
	if not failed:
		print("Story atomic reload tests passed (%d checks; final crystal, hero death in stages 1/9, boss death before deferred callbacks)" % checks)
	quit(1 if failed else 0)

func _start(number: int) -> Node:
	MAIN.story_hero = "frey"
	MAIN.human_body = "female"
	MAIN.story_stage = number
	MAIN.story_difficulty = "normal"
	MAIN.story_art_state = {}
	MAIN.next_screen = "story_stage"
	PROGRESS.runs.clear()
	PROGRESS.new_journey("frey", "normal")
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(6)
	var main: Node = current_scene
	main.story_session.begin_dialogue()
	main.story_session.dialogue._activate("dialogue_skip", "")
	main.story_session.hero.grant_protection(1000.0)
	return main

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
