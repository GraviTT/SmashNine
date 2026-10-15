extends SceneTree
## Game speed (user 2026-10-15, tempo proposal A): T cycles 100 / 90 / 80 / 70 %; a match runs under
## Engine.time_scale = the chosen factor and anything outside a match at 100%; the idle loop keeps
## its real-time speed (D37) under a slower game. Headless runs never read or write the saved choice.

const GAME_SPEED := preload("res://scripts/GameSpeed.gd")
const MAIN_SCENE := preload("res://scenes/Main.tscn")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _run() -> void:
	_test_cycle()
	await _test_match_applies_and_restores()
	await _test_idle_keeps_real_time_speed()
	GAME_SPEED.factor = 1.0
	GAME_SPEED.reset_engine()
	if failed:
		quit(1)
		return
	print("Game speed tests passed")
	quit(0)

func _test_cycle() -> void:
	GAME_SPEED.load_saved()
	if absf(GAME_SPEED.factor - 1.0) > 0.001:
		_fail("Headless runs should start at 100%% (got %d%%)" % GAME_SPEED.percent())
	var seen: Array[int] = []
	for step in 4:
		GAME_SPEED.cycle()
		seen.append(GAME_SPEED.percent())
	if seen != [90, 80, 70, 100]:
		_fail("T should cycle 100 -> 90 -> 80 -> 70 -> 100 (got %s)" % [seen])
	if FileAccess.file_exists(GAME_SPEED.SAVE_PATH):
		var config := ConfigFile.new()
		config.load(GAME_SPEED.SAVE_PATH)
		if config.has_section_key("game", "speed") and absf(float(config.get_value("game", "speed")) - 1.0) > 0.001:
			_fail("A headless run should not write the saved game speed")

func _test_match_applies_and_restores() -> void:
	GAME_SPEED.factor = 0.8
	var main: Node = MAIN_SCENE.instantiate()
	main.bots_only = true
	main.match_seed = 4242
	root.add_child(main)
	await process_frame
	await physics_frame
	if absf(Engine.time_scale - 0.8) > 0.001:
		_fail("A match should run at the chosen game speed (time scale %.2f)" % Engine.time_scale)
	main._on_match_finished(null, "test")
	if absf(Engine.time_scale - 1.0) > 0.001:
		_fail("The result screen should run at normal speed (time scale %.2f)" % Engine.time_scale)
	main.match_over = false
	GAME_SPEED.apply_to_match()
	main.queue_free()
	await process_frame
	await process_frame
	if absf(Engine.time_scale - 1.0) > 0.001:
		_fail("Leaving the match scene should restore normal speed (time scale %.2f)" % Engine.time_scale)

func _test_idle_keeps_real_time_speed() -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	var floor := StaticBody2D.new()
	floor.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(800, 40)
	shape.shape = rect
	floor.add_child(shape)
	arena.add_child(floor)
	floor.global_position = Vector2(0, 20)
	var luna: Node = PLAYER_FACTORY.create("luna")
	arena.add_child(luna)
	luna.global_position = Vector2(0, -2)
	luna.setup(CHARACTER_REGISTRY.get_characters()["luna"], 1, false)
	luna.is_dummy = true
	luna.ringout_y = 100000.0
	Engine.time_scale = 0.8
	for frame in 20:
		await physics_frame
	luna._update_character_sprite()
	var idle_speed: float = luna.character_sprite.speed_scale
	Engine.time_scale = 1.0
	if absf(idle_speed - 1.25) > 0.01:
		_fail("Under 80%% game speed the idle loop should play 1.25x to keep its real-time speed (got %.2f)" % idle_speed)
	arena.queue_free()
	await process_frame
