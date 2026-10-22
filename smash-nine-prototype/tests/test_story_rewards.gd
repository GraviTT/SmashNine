extends SceneTree
## Stage 8 has no portal: a new soul-card offer must finish before checkpoint 9 is saved.
const MAIN := preload("res://scripts/Main.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
var failed := false
var checks := 0

func _initialize() -> void:
	create_timer(45.0, true, false, true).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	PROGRESS.runs.clear()
	PROGRESS.new_journey("frey", "normal")
	for number in range(1, 8):
		PROGRESS.complete_stage("frey", number, 24, [])
	MAIN.story_hero = "frey"
	MAIN.story_stage = 8
	MAIN.story_difficulty = "normal"
	MAIN.story_art_state = {}
	MAIN.next_screen = "story_stage"
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(6)
	var main: Node = current_scene
	main.story_session.begin_dialogue()
	main.story_session.dialogue._activate("dialogue_skip", "")
	_check(main.story_session.phase == "combat", "Reward fixture starts stage 8")
	main.story_session.rival.apply_environment_damage(main.story_session.rival.hp, main.story_session.hero)
	await _frames(3)
	_check(not main.soul_growth.get_offer(main.story_session.hero).is_empty(), "Stage 8 defeat opens a real pending card offer")
	main.story_session.dialogue._activate("dialogue_skip", "")
	await _frames(2)
	_check(main.story_session.phase == "root" and not main.match_over and PROGRESS.get_run("frey").cleared == 7, "Stage 8 root waits for pending soul cards before saving the next checkpoint")
	if failed:
		quit(1)
		return
	_check(main.hud.card_panel.visible and main.story_session.accepts_gameplay(), "Existing offer panel remains available at the root")
	var hp: float = main.story_session.hero.hp
	main._on_story_action("story_art")
	await _frames(6)
	main = current_scene
	_check(main.story_session.phase == "root" and not main.soul_growth.get_offer(main.story_session.hero).is_empty(), "F2 restores root transition with pending offer")
	_check(is_equal_approx(main.story_session.hero.hp, hp), "Root reload retains hero HP")
	for attempt in 4:
		if main.soul_growth.get_offer(main.story_session.hero).is_empty():
			break
		_check(main.soul_growth.choose(main.story_session.hero, 0), "Hero chooses ordinary soul card at root")
		await _frames(2)
	_check(main.match_over and main.hud.frontend.screen == "story_result", "Root advances after the last offer closes")
	_check(PROGRESS.get_run("frey").cleared == 8 and not PROGRESS.checkpoint("frey", 9).cards.is_empty(), "Stage 9 checkpoint includes the earned card")
	_check(PROGRESS.checkpoint("frey", 9).cards == main.story_session.hero.upgrades, "Root checkpoint matches hero's final selected cards")
	PROGRESS.set_difficulty("frey", "easy")
	MAIN.story_difficulty = "easy"
	main.hud.frontend.buttons[0].pressed.emit()
	await _frames(6)
	main = current_scene
	main.story_session.begin_dialogue()
	main.story_session.dialogue._activate("dialogue_skip", "")
	_check(main.story_stage == 9 and main.story_session.hero.upgrades == PROGRESS.checkpoint("frey", 9).cards, "Next actually restores the root's selected card")
	for enemy: Node in main.story_session.enemies:
		_check(is_equal_approx(enemy.max_hp, enemy.base_max_hp * 0.6 * 0.8), "Easy also scales rival shadow HP")
	var growing_shadow: Node = main.story_session.enemies[0]
	growing_shadow.add_souls(25)
	_check(main.soul_growth.choose(growing_shadow, 0), "A wave-one shadow can earn an ordinary soul card")
	var plain_max: float = growing_shadow.base_max_hp + growing_shadow.hp_growth * 3.0 + float(growing_shadow.upgrade_modifiers.bonus_max_hp)
	_check(is_equal_approx(growing_shadow.max_hp, plain_max * 0.6 * 0.8), "Shadow HP multiplier survives card growth even when it is not the rival bar actor")
	main.story_session.hero.hp = main.story_session.hero.max_hp * 0.9
	for enemy: Node in main.story_session.enemies:
		enemy.apply_environment_damage(enemy.hp, main.story_session.hero)
	await _frames(3)
	_check(main.story_session.phase == "mid" and is_equal_approx(main.story_session.hero.hp, main.story_session.hero.max_hp), "Intermission heal caps at max HP")
	main.story_session.dialogue._activate("dialogue_skip", "")
	var own_shadow: Node = main.story_session.rival
	plain_max = own_shadow.base_max_hp + own_shadow.hp_growth * 9.0 + float(own_shadow.upgrade_modifiers.bonus_max_hp)
	_check(is_equal_approx(own_shadow.max_hp, plain_max * 1.5 * 0.8), "Easy own-shadow HP includes all three cards before scaling")
	var bounds: Rect2 = main.layout.get_bounds(8)
	main.story_session.hero.global_position.x = bounds.get_center().x
	main.director.advance(60.0)
	main.story_session.hero.hp = 4.0
	main.story_session.hero.global_position.x = bounds.position.x
	main.director.advance(1.0)
	await _frames(3)
	_check(main.match_over and main.story_session.hero.is_defeated and main.director.winner == null, "Shrinking band can defeat the hero; no battle-royale last-survivor protection")
	_check(PROGRESS.get_run("frey").cleared == 8 and not PROGRESS.get_run("frey").done, "Failed final battle cannot mark the story complete")
	main._on_story_action("story_retry")
	await _frames(6)
	main = current_scene
	_check(main.story_session.phase == "start" and main.story_session.wave_index == 0 and main.story_session.enemies.size() == 4, "Final retry starts wave one at the stage checkpoint")
	_check(main.story_session.hero.upgrades == PROGRESS.checkpoint("frey", 9).cards and main.director.band_started_at < 0.0, "Final retry restores the saved card and resets the band")
	main._on_story_action("story_title")
	await _frames(6)
	PROGRESS.runs.clear()
	if not failed:
		print("Story reward tests passed (%d checks; stage 8 offer/root/F2/checkpoint, Easy shadow growth/heal cap, lethal hero-only band/retry)" % checks)
	quit(1 if failed else 0)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
