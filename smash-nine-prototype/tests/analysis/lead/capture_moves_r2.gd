extends SceneTree
## Lead copy of Codex QA-17 capture_moves.gd for the round-2 retest (Codex hit its usage limit):
## saves into CAPTURE_OUT, and the spike row presses L again while the follow-up window is open.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const TILE := Vector2i(480, 260)
const VIEW := Vector2i(900, 360)

var out_dir := ""
var arena: Node2D
var fighter: Node
var dummy: Node
var title: Label

func _initialize() -> void:
	out_dir = OS.get_environment("CAPTURE_OUT")
	DirAccess.make_dir_recursive_absolute(out_dir)
	DisplayServer.window_set_size(VIEW)
	# The project draws a 1920x1080 base canvas; map the 900x360 stage onto the whole window.
	root.content_scale_size = VIEW
	call_deferred("_run")

func _run() -> void:
	var frey_moves := ["J1", "J2", "J3", "up J", "down J", "air J", "K dash", "L rising", "L spike input", "ultimate"]
	var luna_moves := ["normal J", "normal up J", "normal down J", "air J", "normal K", "normal L", "Brave J1", "Brave J2", "Brave J3", "Brave up J", "Brave K", "Brave L", "transform", "heart laser", "star charge"]
	await _capture_character("frey", frey_moves, out_dir.path_join("frey-move-contact-sheet.png"))
	await _capture_character("luna", luna_moves, out_dir.path_join("luna-move-contact-sheet.png"))
	_release_all()
	print("QA17_CAPTURE saved Frey and Luna contact sheets")
	quit(0)

func _capture_character(character: String, moves: Array, path: String) -> void:
	var sheet := Image.create(TILE.x * 3, TILE.y * moves.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.035, 0.045, 0.075, 1.0))
	for row in moves.size():
		var move: String = str(moves[row])
		await _new_stage(character, move)
		await _prepare_move(character, move)
		_set_phase(move, "START")
		_start_move(move)
		await process_frame
		await RenderingServer.frame_post_draw
		_blit(sheet, await _shot(), 0, row)
		for frame in _active_wait(move):
			await physics_frame
		_set_phase(move, "ACTIVE")
		await process_frame
		await RenderingServer.frame_post_draw
		_blit(sheet, await _shot(), 1, row)
		for frame in _end_wait(move):
			await physics_frame
		_set_phase(move, "END")
		await process_frame
		await RenderingServer.frame_post_draw
		_blit(sheet, await _shot(), 2, row)
		_release_all()
		arena.queue_free()
		await process_frame
	sheet.save_png(path)

func _new_stage(character: String, move: String) -> void:
	arena = Node2D.new()
	root.add_child(arena)
	var background := ColorRect.new()
	background.size = VIEW
	background.color = Color(0.035, 0.045, 0.075)
	background.z_index = -20
	arena.add_child(background)
	var floor_visual := ColorRect.new()
	floor_visual.position = Vector2(0, 270)
	floor_visual.size = Vector2(900, 90)
	floor_visual.color = Color(0.16, 0.19, 0.28)
	floor_visual.z_index = -10
	arena.add_child(floor_visual)
	var floor := StaticBody2D.new()
	floor.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(900, 100)
	shape.shape = rect
	shape.position = Vector2(450, 320)
	floor.add_child(shape)
	arena.add_child(floor)
	fighter = PLAYER_FACTORY.create(character)
	arena.add_child(fighter)
	fighter.global_position = Vector2(350, 269)
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character], 1, true)
	dummy = PLAYER_FACTORY.create("")
	arena.add_child(dummy)
	dummy.global_position = Vector2(510 if move != "normal L" else 485, 269)
	dummy.setup_dummy(2)
	title = Label.new()
	title.position = Vector2(225, 54)
	title.size = Vector2(470, 32)
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.z_index = 100
	arena.add_child(title)
	for frame in 8:
		await physics_frame
	_hold("move_right", true)

func _prepare_move(character: String, move: String) -> void:
	if move in ["J2", "J3", "Brave J2", "Brave J3"]:
		if move.begins_with("Brave"):
			await _transform()
		var count := 1 if move.ends_with("2") else 2
		for index in count:
			_tap("basic_attack")
			await _wait_ready()
	elif move.begins_with("Brave") or move == "heart laser":
		await _transform()
	if move == "air J":
		_tap("jump")
		for frame in 5:
			await physics_frame
	if move in ["up J", "normal up J", "Brave up J"]:
		_hold("move_right", false)
		_hold("move_up", true)
	if move in ["down J", "normal down J"]:
		_hold("move_right", false)
		_hold("move_down", true)
	if move == "star charge":
		# Setup only: show three charge stars circling her (the passive mark art).
		fighter.star_charge = 3
		fighter._update_star_orbit()
	if move == "L spike input":
		_tap("skill_2")
		for frame in 40:
			await physics_frame
			if float(fighter.rising_followup_timer) > 0.0:
				break

func _start_move(move: String) -> void:
	if move in ["K dash", "normal K", "Brave K"]:
		_tap("skill_1")
	elif move in ["L rising", "normal L", "Brave L"]:
		_tap("skill_2")
	elif move == "L spike input":
		_tap("skill_2")
	elif move == "ultimate" or move == "transform":
		_tap("ultimate")
	elif move == "heart laser":
		_tap("ultimate")
	else:
		_tap("basic_attack")

func _transform() -> void:
	_tap("ultimate")
	for frame in 50:
		await physics_frame
		if bool(fighter.transformed) and fighter._can_start_attack():
			break

func _wait_ready() -> void:
	for frame in 50:
		await physics_frame
		if fighter._can_start_attack():
			return

func _active_wait(move: String) -> int:
	if move in ["K dash", "normal K", "ultimate", "transform", "heart laser"]:
		return 10
	if move in ["L rising", "normal L", "Brave L", "L spike input"]:
		return 13
	return 6

func _end_wait(move: String) -> int:
	if move in ["ultimate", "heart laser"]:
		return 28
	return 20

func _set_phase(move: String, phase: String) -> void:
	title.text = "%s  |  %s" % [move, phase]

func _shot() -> Image:
	var full := root.get_texture().get_image()
	full.resize(TILE.x, TILE.y, Image.INTERPOLATE_NEAREST)
	return full

func _blit(sheet: Image, shot: Image, column: int, row: int) -> void:
	sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, TILE), Vector2i(column * TILE.x, row * TILE.y))

func _tap(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)

func _hold(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)

func _release_all() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "jump", "basic_attack", "skill_1", "skill_2", "ultimate"]:
		Input.action_release(action)
