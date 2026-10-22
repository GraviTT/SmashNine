extends SceneTree
## Escape/boss objectives leave live monsters: opening an exit must keep them stopped after F2.
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
	for number in [5, 7]:
		PROGRESS.runs.clear()
		PROGRESS.new_journey("luna", "normal")
		MAIN.story_hero = "luna"
		MAIN.story_stage = number
		MAIN.story_difficulty = "normal"
		MAIN.story_art_state = {}
		MAIN.next_screen = "story_stage"
		change_scene_to_file("res://scenes/Main.tscn")
		await _frames(6)
		var main: Node = current_scene
		main.story_session.begin_dialogue()
		main.story_session.dialogue._activate("dialogue_skip", "")
		main.story_session.hero.grant_protection(1000.0)
		if number == 5:
			for crystal: Node in main.story_session.crystals:
				for hit in 3:
					crystal.apply_hit(main.story_session.hero, 1.0, 0.0, Vector2.RIGHT)
		else:
			main.director.advance(20.1)
			main.story_session._tick_reinforcements()
			main.story_session.rival.apply_hit(main.story_session.hero, 10000.0, 0.0, Vector2.RIGHT, "fixed")
		await _frames(3)
		main.story_session.dialogue._activate("dialogue_skip", "")
		await _frames(2)
		_check(main.story_session.phase == "exit" and main.director.exit_open, "Fixture opens stage %d exit with live monsters" % number)
		_check(_living_monsters(main).size() == 2 and _living_monsters(main).all(func(enemy: Node) -> bool: return enemy.process_mode == Node.PROCESS_MODE_DISABLED), "Remaining monsters stop at the opened exit")
		main._on_story_action("story_art")
		await _frames(6)
		main = current_scene
		_check(main.story_session.phase == "exit" and main.director.exit_open, "F2 retains opened stage %d exit" % number)
		_check(_living_monsters(main).size() == 2 and _living_monsters(main).all(func(enemy: Node) -> bool: return enemy.process_mode == Node.PROCESS_MODE_DISABLED), "F2 must not restart living monsters after objective completion (stage %d)" % number)
		main._on_story_action("story_title")
		await _frames(6)
	ART.style = ART.STYLE_ORIGINAL
	MAIN.story_art_state = {}
	PROGRESS.runs.clear()
	if not failed:
		print("Story exit reload tests passed (%d checks; crystals and boss exits keep live monsters stopped across F2)" % checks)
	quit(1 if failed else 0)

func _living_monsters(main: Node) -> Array:
	return (main.story_session.enemies + main.story_session.reinforcements).filter(func(enemy: Variant) -> bool: return is_instance_valid(enemy) and enemy.hp > 0.0)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
