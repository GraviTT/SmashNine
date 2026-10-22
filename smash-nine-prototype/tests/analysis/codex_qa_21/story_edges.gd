extends SceneTree
## Seed 2101. Public combat/card APIs; only the fixture bypasses physical combat.
const MAIN := preload("res://scripts/Main.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
var rows: Array = []
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _record(case_name: String, data: Dictionary, ok: bool) -> void:
	data.case_name = case_name
	data.ok = ok
	data.frame = Engine.get_physics_frames()
	rows.append(data)
	print("QA21_STORY ", JSON.stringify(data))
	if not ok:
		failures += 1

func _run() -> void:
	root.size = Vector2i(1280, 720)
	# Stage 8's last offer closes synchronously, but result completion is deferred.
	# F2 in that exact input frame snapshots phase=root with no active offer.
	var main: Node = await _start(8)
	var session: Node = main.story_session
	var hero: Node = session.hero
	hero.add_souls(25)
	for enemy: Node in session.enemies.duplicate():
		if enemy.has_method("apply_environment_damage"):
			enemy.apply_environment_damage(enemy.hp, hero)
		else:
			enemy.apply_hit(hero, 100000.0, 0.0, Vector2.RIGHT, "fixed")
	await _frames(3)
	session.dialogue._activate("dialogue_skip", "")
	_record("root_fixture", {"phase": session.phase, "offer": not main.soul_growth.get_offer(hero).is_empty()}, session.phase == "root")
	while int(main.soul_growth.queued_offers.get(hero, 0)) > 0:
		main.soul_growth.choose(hero, 0)
	main.soul_growth.choose(hero, 0)
	var snapshot_phase: String = session.phase
	main._on_story_action("story_art")
	await _frames(12)
	main = current_scene
	session = main.story_session
	var after_12 := {"phase": session.phase, "match_over": main.match_over, "offers": main.soul_growth.active_offers.size(), "snapshot_phase": snapshot_phase, "cleared": PROGRESS.get_run("frey").cleared}
	await _frames(360)
	after_12.phase_after_360 = session.phase
	after_12.over_after_360 = main.match_over
	_record("F01_root_last_card_F2", after_12, main.match_over and session.phase == "result")
	# Control: same fixture without F2 must reach result.
	main = await _start(8)
	session = main.story_session
	hero = session.hero
	hero.add_souls(25)
	for enemy: Node in session.enemies.duplicate():
		if enemy.has_method("apply_environment_damage"):
			enemy.apply_environment_damage(enemy.hp, hero)
		else:
			enemy.apply_hit(hero, 100000.0, 0.0, Vector2.RIGHT, "fixed")
	await _frames(3)
	session.dialogue._activate("dialogue_skip", "")
	while not main.soul_growth.get_offer(hero).is_empty():
		main.soul_growth.choose(hero, 0)
	await _frames(12)
	_record("root_control_no_F2", {"phase": session.phase, "match_over": main.match_over}, main.match_over)
	# Real disk IO uses the production save/load API with an explicit isolated path.
	var path := "res://../reports/codex-qa-21/story-save-test.cfg"
	PROGRESS.runs.clear()
	for id in ["frey", "yuki", "luna", "nova", "rio"]:
		PROGRESS.new_journey(id, "easy")
		for stage in range(1, 10):
			PROGRESS.complete_stage(id, stage, stage * 10, ["power"])
	var before := PROGRESS.runs.duplicate(true)
	var error := PROGRESS.save(path)
	PROGRESS.runs.clear()
	PROGRESS.load_saved(path)
	_record("five_hero_disk_roundtrip", {"error": error, "heroes": PROGRESS.runs.size(), "equal": before == PROGRESS.runs}, before == PROGRESS.runs and error == OK)
	main._on_story_action("story_title")
	await _frames(6)
	var out := FileAccess.open("res://../reports/codex-qa-21/story-edges.json", FileAccess.WRITE)
	out.store_string(JSON.stringify({"seed": 2101, "failures": failures, "rows": rows}, "\t") + "\n")
	quit(1 if failures else 0)

func _start(stage: int) -> Node:
	if is_instance_valid(current_scene):
		var old := current_scene
		current_scene = null
		old.queue_free()
		await _frames(2)
	MAIN.story_hero = "frey"
	MAIN.human_body = "female"
	MAIN.story_stage = stage
	MAIN.story_difficulty = "normal"
	MAIN.story_art_state = {}
	MAIN.next_screen = "story_stage"
	PROGRESS.runs.clear()
	PROGRESS.new_journey("frey", "normal")
	for number in range(1, stage):
		PROGRESS.complete_stage("frey", number, 0, [])
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	main.match_seed = 2101
	root.add_child(main)
	current_scene = main
	await _frames(6)
	main.story_session.begin_dialogue()
	main.story_session.dialogue._activate("dialogue_skip", "")
	main.story_session.hero.grant_protection(1000.0)
	return main

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
