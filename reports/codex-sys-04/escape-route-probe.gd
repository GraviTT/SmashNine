extends SceneTree
## Physical reachability probe: real movement/jumps/J attacks, no teleports or direct crystal hits.
const MAIN := preload("res://scripts/Main.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
var main: Node
var failed := false
var hero_id := "frey"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--hero="):
			hero_id = argument.trim_prefix("--hero=")
	call_deferred("_run")

func _run() -> void:
	MAIN.story_hero = hero_id
	MAIN.story_stage = 5
	MAIN.story_difficulty = "normal"
	MAIN.next_screen = "story_stage"
	MAIN.story_art_state = {}
	PROGRESS.runs.clear()
	PROGRESS.new_journey(hero_id, "normal")
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(6)
	main = current_scene
	main.story_session.begin_dialogue()
	main.story_session.dialogue._activate("dialogue_skip", "")
	main.story_session.hero.grant_protection(1000.0)
	await _frames(40)
	await _attack_crystal(0)
	var origin: Vector2 = main.layout.get_origin(6)
	var platforms: Array = main.layout.get_platform_rects(6)
	print("ROUTE terrain ", platforms, " hero ", main.story_session.hero.global_position - origin)
	await _jump_to(origin + Vector2(900, (platforms[3] as Rect2).position.y - origin.y))
	var bridge: Rect2 = main.layout.get_realm(6).hazard.bridges[0]
	# Wait for the intended timed bridge if it expired during the first approach.
	for frame in 1200:
		if main.hazards.get_phase(6) == "active":
			break
		await _frames(1)
	await _jump_to(origin + Vector2(bridge.get_center().x, bridge.position.y))
	await _attack_crystal(2)
	Input.action_press("move_right")
	for frame in 300:
		if main.story_session.hero.global_position.x >= origin.x + 1500.0:
			break
		await _frames(1)
	Input.action_release("move_right")
	await _frames(80)
	await _tap(KEY_S)
	await _tap(KEY_S)
	await _frames(80)
	await _attack_crystal(1)
	if main.story_session.phase == "post":
		main.story_session.dialogue._activate("dialogue_skip", "")
	for choice in 3:
		if main.soul_growth.get_offer(main.story_session.hero).is_empty():
			break
		await _tap(KEY_1)
	Input.action_press("move_right")
	for frame in 180:
		if main.story_session.hero.global_position.x >= origin.x + 1720.0:
			break
		await _frames(1)
	Input.action_release("move_right")
	await _frames(4)
	await _tap(KEY_Q)
	await _frames(4)
	print("ESCAPE_ROUTE_RESULT ", JSON.stringify({"id": hero_id, "failed": failed, "phase": main.story_session.phase, "crystals": main.story_session.crystals_broken, "seconds": main.director.match_elapsed, "hero": main.story_session.hero.global_position - origin}))
	quit(1 if failed or main.story_session.crystals_broken != 3 or not main.match_over else 0)

func _attack_crystal(slot: int) -> void:
	for attempt in 10:
		var crystal: Node = null
		for candidate: Variant in main.story_session.crystals:
			if is_instance_valid(candidate) and int(candidate.get_meta("story_crystal_slot")) == slot:
				crystal = candidate
		if crystal == null or crystal.is_broken:
			print("ROUTE crystal ", slot, " broken at ", main.director.match_elapsed)
			return
		if attempt == 0:
			await _walk_to_x(crystal.global_position.x - (30.0 if hero_id == "nova" else 80.0))
			# Face the target using the same horizontal input as a player.
			Input.action_press("move_right")
			await _frames(1)
			Input.action_release("move_right")
		await _tap(KEY_J)
		await _frames(32)
	failed = true
	print("ROUTE failed crystal ", slot, " hero ", main.story_session.hero.global_position - main.layout.get_origin(6))

func _jump_to(point: Vector2) -> void:
	var hero: Node = main.story_session.hero
	if hero.is_on_floor() and hero.global_position.y <= point.y + 12.0:
		await _walk_to_x(point.x)
		return
	Input.action_release("jump")
	await _frames(1)
	Input.action_press("jump")
	for frame in 180:
		if frame == 25:
			Input.action_release("jump")
		elif frame == 26:
			Input.action_press("jump")
		var dx: float = point.x - hero.global_position.x
		Input.action_release("move_left")
		Input.action_release("move_right")
		if absf(dx) > 8.0:
			Input.action_press("move_right" if dx > 0.0 else "move_left")
		await _frames(1)
		if frame > 30 and hero.is_on_floor() and hero.global_position.y <= point.y + 12.0 and absf(dx) < 20.0:
			break
	Input.action_release("jump")
	Input.action_release("move_left")
	Input.action_release("move_right")
	print("ROUTE jump at ", main.director.match_elapsed, " target ", point - main.layout.get_origin(6), " got ", hero.global_position - main.layout.get_origin(6))

func _walk_to_x(x: float) -> void:
	for frame in 240:
		var dx: float = x - main.story_session.hero.global_position.x
		Input.action_release("move_left")
		Input.action_release("move_right")
		if absf(dx) <= 8.0:
			break
		Input.action_press("move_right" if dx > 0.0 else "move_left")
		await _frames(1)
	Input.action_release("move_left")
	Input.action_release("move_right")

func _tap(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
