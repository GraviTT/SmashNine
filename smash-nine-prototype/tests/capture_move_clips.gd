extends SceneTree
## Windowed capture of every J variant at the speed and timing used by the game.
## Usage (from smash-nine-prototype/):
## godot --path . --fixed-fps 60 -s tests/capture_move_clips.gd

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const FPS := 30
const PHYSICS_FRAMES_PER_SHOT := 2
const CLIP_SIZE := Vector2i(960, 540)
## Just above the floor's top (y=0); a ground move waits until the fighter has landed. 110 was
## below the floor, so every fighter fell out of the clip (2026-10-15).
const FLOOR_Y := -40.0
const AIR_Y := -170.0
const FINAL_HOLD_FRAMES := 5 # 0.167 s, the requested idle +0.15 s.
const MAX_CAPTURE_FRAMES := 120
const SEED := 20261015
const PYTHON := "C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe"

const FORMS := [
	{"id": "frey", "character": "frey", "body": "", "brave": false},
	{"id": "luna", "character": "luna", "body": "", "brave": false},
	{"id": "luna_brave", "character": "luna", "body": "", "brave": true},
	{"id": "yuki", "character": "yuki", "body": "", "brave": false},
	{"id": "nova", "character": "nova", "body": "male", "brave": false},
	{"id": "rio", "character": "rio", "body": "male", "brave": false},
]

const MOVES := [
	{"id": "ground-j", "name": "지상 J", "input": "J", "air": false, "direction": Vector2.RIGHT},
	{"id": "up-j", "name": "지상 ↑J", "input": "↑J", "air": false, "direction": Vector2.UP},
	{"id": "down-j", "name": "지상 ↓J", "input": "↓J", "air": false, "direction": Vector2.DOWN},
	{"id": "air-j", "name": "공중 J", "input": "공중 J", "air": true, "direction": Vector2.RIGHT},
	{"id": "air-up-j", "name": "공중 ↑J", "input": "공중 ↑J", "air": true, "direction": Vector2.UP},
	{"id": "air-down-j", "name": "공중 ↓J", "input": "공중 ↓J", "air": true, "direction": Vector2.DOWN},
]

const FORM_ROWS := {
	"frey": {
		"ground-j": ["attack_chain 1-2", "attack_chain 3-4", "attack_chain 5-6"],
		"up-j": ["attack_up 2-4"], "down-j": ["attack_down 3-4"],
		"air-j": ["attack_air_side 2-3"], "air-up-j": ["attack_up 2-4"], "air-down-j": ["attack_down 3-4"],
	},
	"luna": {
		"ground-j": ["star_side"], "up-j": ["star_up"], "down-j": ["star_down"],
		"air-j": ["star_side"], "air-up-j": ["star_up"], "air-down-j": ["star_down"],
	},
	"luna_brave": {
		"ground-j": ["brave_combo 1-2", "brave_combo 3-4", "brave_combo 5-6"],
		"up-j": ["brave_upper"], "down-j": ["brave_low"],
		"air-j": ["brave_air_side"], "air-up-j": ["brave_upper"], "air-down-j": ["brave_dive"],
	},
	"yuki": {
		"ground-j": ["talisman_side"], "up-j": ["talisman_up"], "down-j": ["ground_ward"],
		"air-j": ["talisman_air_side"], "air-up-j": ["talisman_up"], "air-down-j": ["talisman_air_down"],
	},
	"nova": {
		"ground-j": ["vector_side"], "up-j": ["vector_upper"], "down-j": ["compression_stomp"],
		"air-j": ["air_side"], "air-up-j": ["vector_upper"], "air-down-j": ["meteor_kick"],
	},
	"rio": {
		"ground-j": ["mana_combo 1-2", "mana_combo 3-4", "mana_combo 5-6"],
		"up-j": ["rising_slash"], "down-j": ["low_sweep"],
		"air-j": ["air_slash"], "air-up-j": ["rising_slash"], "air-down-j": ["plunge"],
	},
}

## TOOL-02 captures only the new around-the-character scenes. The encoder merges these with the
## existing TOOL-01 J clips, so rerunning this script never rewrites the accepted basic attacks.
const AROUND_SCENARIOS := [
	{"form": "frey", "move": "guard", "name": "방어·패리", "input": "Guard", "frames": 58, "dummy": true},
	{"form": "luna", "move": "guard", "name": "방어·패리", "input": "Guard", "frames": 58, "dummy": true},
	{"form": "luna_brave", "move": "guard", "name": "방어·패리", "input": "Guard", "frames": 58, "dummy": true},
	{"form": "yuki", "move": "guard", "name": "방어·패리", "input": "Guard", "frames": 58, "dummy": true},
	{"form": "nova", "move": "guard", "name": "방어·패리", "input": "Guard", "frames": 58, "dummy": true},
	{"form": "rio", "move": "guard", "name": "방어·패리", "input": "Guard", "frames": 58, "dummy": true},
	{"form": "frey", "move": "pursuit", "name": "추격 표식", "input": "↑J 적중", "frames": 52, "dummy": true},
	{"form": "frey", "move": "spike", "name": "상승 가르기·강스파이크", "input": "L · L", "frames": 68, "dummy": true},
	{"form": "frey", "move": "ultimate", "name": "발키리 강림", "input": "I", "frames": 58, "zoom": 1.45},
	{"form": "luna", "move": "star-charge", "name": "별빛 충전 3개", "input": "J ×3", "frames": 94, "dummy": true},
	{"form": "luna", "move": "transform", "name": "Brave Luna 변신", "input": "I", "frames": 58, "zoom": 1.55},
	{"form": "luna_brave", "move": "aura", "name": "Brave 오라", "input": "대기", "frames": 45},
	{"form": "yuki", "move": "seals", "name": "봉인부 2개·파괴", "input": "K · K", "frames": 82, "dummy": true, "zoom": 1.55},
	{"form": "yuki", "move": "ultimate", "name": "대결계", "input": "I", "frames": 126, "dummy": true, "zoom": 1.05, "camera_x": 165.0},
	{"form": "nova", "move": "momentum", "name": "관성·벡터 시프트", "input": "달리기 · K", "frames": 78, "follow": true, "zoom": 1.45},
	{"form": "nova", "move": "ultimate", "name": "중력 슬링샷", "input": "I · I · I", "frames": 76, "follow": true, "zoom": 1.25},
	{"form": "rio", "move": "rune", "name": "룬 방패·반격", "input": "L", "frames": 52, "dummy": true},
	{"form": "rio", "move": "ultimate", "name": "인피니티 오버드라이브", "input": "I", "frames": 52, "dummy": true, "zoom": 1.45},
	{"form": "frey", "move": "status", "name": "기절·슈퍼아머", "input": "상태", "frames": 74, "dummy": true},
]

var arena: Node2D
var floor_body: StaticBody2D
var camera: Camera2D
var fighter: CharacterBody2D
var capture_dummy: CharacterBody2D
var clips_root := ""
var capture_entries: Array[Dictionary] = []
var suppress_fx := false
var scenario_state: Dictionary = {}

func _initialize() -> void:
	clips_root = ProjectSettings.globalize_path("res://../art/clips")
	DirAccess.make_dir_recursive_absolute(clips_root)
	RenderingServer.set_default_clear_color(Color("101522"))
	call_deferred("_run")

func _run() -> void:
	_build_arena()
	await process_frame
	# Every basic attack (J) first, then the around-the-character scenes: one run refreshes both
	# groups (2026-10-15: TOOL-02 had dropped the J loop, so adopted J effects were never recaptured).
	for form in FORMS:
		for move in MOVES:
			var j_pair: Dictionary = {}
			for mode in ["fx", "nofx"]:
				seed(SEED)
				j_pair[mode] = await _capture(form, move, mode)
			if int(j_pair.fx) != int(j_pair.nofx):
				push_error("clip pair frame mismatch: %s/%s" % [form.id, move.id])
				quit(2)
				return
			capture_entries.append({
				"group": "j",
				"form": form.id,
				"move": move.id,
				"name": move.name,
				"input": move.input,
				"frames": j_pair.fx,
				"rows": FORM_ROWS[form.id][move.id],
				"size": [CLIP_SIZE.x, CLIP_SIZE.y],
			})
	for scenario in AROUND_SCENARIOS:
		var pair: Dictionary = {}
		for mode in ["fx", "nofx"]:
			seed(SEED)
			var frames := await _capture_around(scenario, mode)
			pair[mode] = frames
		if int(pair.fx) != int(pair.nofx):
			push_error("clip pair frame mismatch: %s/%s" % [scenario.form, scenario.move])
			quit(2)
			return
		capture_entries.append({
			"group": "around",
			"form": scenario.form,
			"move": scenario.move,
			"name": scenario.name,
			"input": scenario.input,
			"frames": pair.fx,
			"rows": [],
			"size": [CLIP_SIZE.x, CLIP_SIZE.y],
			"zoom": float(scenario.get("zoom", 1.8)),
		})
	var raw_manifest := clips_root.path_join("_capture.json")
	var file := FileAccess.open(raw_manifest, FileAccess.WRITE)
	file.store_string(JSON.stringify({"fps": FPS, "clips": capture_entries}, "\t"))
	file.close()
	var encoder := ProjectSettings.globalize_path("res://../reports/codex-tool-01/encode_clips.py")
	var output: Array = []
	var code := OS.execute(PYTHON, PackedStringArray(["-B", encoder, clips_root]), output, true)
	for line in output:
		print(line)
	if code != 0:
		push_error("clip encoder failed with exit code %d" % code)
		quit(code)
		return
	print("CAPTURE_RESULT group=around pairs=%d files=%d size=%dx%d fps=%d" % [capture_entries.size(), capture_entries.size() * 2, CLIP_SIZE.x, CLIP_SIZE.y, FPS])
	quit(0)

func _form_data(id: String) -> Dictionary:
	for form in FORMS:
		if form.id == id:
			return form
	return {}

func _capture_around(scenario: Dictionary, mode: String) -> int:
	_clear_capture_nodes()
	suppress_fx = mode == "nofx"
	scenario_state = {}
	var form := _form_data(scenario.form)
	fighter = PLAYER_FACTORY.create(form.character, form.body)
	fighter.name = "CapturedFighter"
	fighter.global_position = Vector2.ZERO
	arena.add_child(fighter)
	fighter.setup(CHARACTER_REGISTRY.get_characters()[form.character], 1, false)
	fighter.is_dummy = true
	fighter.facing = 1
	fighter.spawn_point = fighter.global_position
	if form.brave:
		fighter.transformed = true
		fighter.transformation_timer = 999.0
		fighter.call_deferred("_update_visuals")
	if bool(scenario.get("dummy", false)):
		capture_dummy = PLAYER_FACTORY.create()
		capture_dummy.name = "TrainingDummy"
		capture_dummy.global_position = Vector2(_dummy_x(scenario.move), FLOOR_Y)
		arena.add_child(capture_dummy)
		capture_dummy.setup_dummy(99)
		# Frey's pursuit scene must visibly launch the target. Other scripted targets stay put so
		# repeated hits (three Luna charges, guard/rune probes) remain deterministic.
		capture_dummy.set_physics_process(scenario.move == "pursuit")
	for unused in 4:
		await physics_frame
	fighter.global_position = Vector2(0, FLOOR_Y)
	fighter.velocity = Vector2.ZERO
	for unused in 60:
		if fighter.is_on_floor():
			break
		await physics_frame
	if not fighter.is_on_floor():
		push_error("fighter did not land: %s/%s" % [scenario.form, scenario.move])
	if is_instance_valid(capture_dummy):
		capture_dummy.global_position = Vector2(_dummy_x(scenario.move), FLOOR_Y)
	if scenario.move == "aura":
		fighter.call("_create_transformation_aura")
	await process_frame
	camera.zoom = Vector2.ONE * float(scenario.get("zoom", 1.8))
	camera.position = Vector2(float(scenario.get("camera_x", 80.0)), -140)
	_hide_actor_hud(fighter)
	if is_instance_valid(capture_dummy):
		_hide_actor_hud(capture_dummy)
	var frame_dir := clips_root.path_join("_frames").path_join(scenario.form).path_join(scenario.move).path_join(mode)
	DirAccess.make_dir_recursive_absolute(frame_dir)
	_remove_pngs(frame_dir)
	var frame_count := 0
	while frame_count < int(scenario.frames):
		_tick_scenario(scenario, frame_count)
		if bool(scenario.get("follow", false)):
			camera.global_position = fighter.global_position + Vector2(80, -100)
		await RenderingServer.frame_pre_draw
		_apply_capture_visibility(mode == "fx")
		await RenderingServer.frame_post_draw
		_save_frame(frame_dir, frame_count)
		frame_count += 1
		for unused in PHYSICS_FRAMES_PER_SHOT:
			await physics_frame
	print("captured %s/%s/%s: %d frames" % [scenario.form, scenario.move, mode, frame_count])
	return frame_count

func _dummy_x(move: String) -> float:
	match move:
		"pursuit", "spike": return 58.0
		"star-charge": return 84.0
		"rune": return 68.0
		"ultimate": return 150.0
		_: return 105.0

func _tick_scenario(scenario: Dictionary, shot: int) -> void:
	var move: String = scenario.move
	if move == "guard":
		if shot == 8:
			fighter.ai_controller.guard_aim = Vector2.RIGHT
			fighter.call("_try_start_guard")
		elif shot == 26:
			fighter.apply_hit(capture_dummy, 4.0, 80.0, Vector2.LEFT)
		elif shot == 35:
			fighter.call("_stop_guard", false)
			fighter.call("_try_start_guard")
		elif shot == 36:
			fighter.apply_hit(capture_dummy, 4.0, 80.0, Vector2.LEFT)
		elif shot == 45:
			fighter.call("_stop_guard", false)
	elif move == "pursuit" and shot == 19:
		fighter.ai_controller.aim_direction = Vector2.UP
		fighter.basic_attack()
	elif move == "spike":
		if shot == 8:
			fighter.ai_controller.aim_direction = Vector2.RIGHT
			fighter.skill_two()
		elif not bool(scenario_state.get("followup", false)) and float(fighter.get("rising_followup_timer")) > 0.0:
			scenario_state.followup = true
			fighter.skill_two()
	elif move == "ultimate" and scenario.form != "nova" and shot == 8:
		fighter.ai_controller.aim_direction = Vector2.RIGHT
		fighter.ultimate()
	elif move == "star-charge":
		if shot >= 8 and int(fighter.get("star_charge")) < 3 and fighter.attack_lock_timer <= 0.0:
			fighter.ai_controller.aim_direction = Vector2.RIGHT
			fighter.basic_attack()
	elif move == "transform" and shot == 8:
		fighter.ultimate()
	elif move == "seals":
		if shot == 8:
			fighter.ai_controller.aim_direction = Vector2.RIGHT
			fighter.skill_one()
		elif int(fighter.get("seals").size()) == 1 and fighter.attack_lock_timer <= 0.0 and not bool(scenario_state.get("second", false)):
			scenario_state.second = true
			fighter.ai_controller.aim_direction = Vector2.LEFT
			fighter.skill_one()
		elif int(fighter.get("seals").size()) >= 2 and shot >= 52 and not bool(scenario_state.get("broken", false)):
			scenario_state.broken = true
			var seals: Array = fighter.get("seals")
			seals[0].apply_hit(capture_dummy, 1.0, 0.0, Vector2.RIGHT)
	elif move == "momentum":
		if shot >= 8 and shot < 38:
			fighter.velocity = Vector2(840.0, 0.0)
		elif shot == 38:
			fighter.ai_controller.aim_direction = Vector2.RIGHT
			fighter.skill_one()
		elif shot == 55:
			fighter.call("on_nova_gravity_burst_landed", 1.0, "brake")
			fighter.velocity = Vector2.ZERO
	elif move == "ultimate" and scenario.form == "nova":
		if shot == 8 or shot == 20 or shot == 38:
			fighter.ai_controller.aim_direction = Vector2.RIGHT
			fighter.ultimate()
	elif move == "rune":
		if shot == 8:
			fighter.skill_two()
		elif shot == 15:
			fighter.apply_hit(capture_dummy, 6.0, 280.0, Vector2.LEFT)
	elif move == "status":
		if shot == 8:
			fighter.apply_stun_hit(capture_dummy, 1.0, 0.0, Vector2.LEFT, 0.72)
		elif shot == 39:
			fighter.ultimate_armor_timer = 0.8
			fighter.call("_update_status_icon", 0.0)

func _build_arena() -> void:
	arena = Node2D.new()
	arena.name = "ClipArena"
	arena.child_entered_tree.connect(_on_arena_child_entered)
	root.add_child(arena)
	floor_body = StaticBody2D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(3000, 40)
	collision.shape = shape
	collision.position = Vector2(0, 20)
	floor_body.add_child(collision)
	var floor_art := Polygon2D.new()
	floor_art.name = "FloorArt"
	floor_art.polygon = PackedVector2Array([Vector2(-1500, 0), Vector2(1500, 0), Vector2(1500, 40), Vector2(-1500, 40)])
	floor_art.color = Color("35445b")
	floor_body.add_child(floor_art)
	arena.add_child(floor_body)
	camera = Camera2D.new()
	camera.name = "ClipCamera"
	# Zoomed so the fighter reads at clip size, and biased forward where the J effects reach.
	camera.position = Vector2(80, -140)
	camera.zoom = Vector2(1.8, 1.8)
	camera.enabled = true
	arena.add_child(camera)

func _capture(form: Dictionary, move: Dictionary, mode: String) -> int:
	_clear_capture_nodes()
	suppress_fx = mode == "nofx"
	fighter = PLAYER_FACTORY.create(form.character, form.body)
	fighter.name = "CapturedFighter"
	fighter.global_position = Vector2(0, AIR_Y if move.air else FLOOR_Y)
	arena.add_child(fighter)
	fighter.setup(CHARACTER_REGISTRY.get_characters()[form.character], 1, false)
	fighter.is_dummy = true # Preserve game physics but suppress autonomous AI input.
	fighter.facing = 1
	fighter.spawn_point = fighter.global_position
	if form.brave:
		fighter.transformed = true
		fighter.transformation_timer = 999.0
		fighter.call_deferred("_update_visuals")
	for unused in 4:
		await physics_frame
	if move.air:
		fighter.global_position = Vector2(0, AIR_Y)
		fighter.velocity = Vector2.ZERO
		fighter.was_on_floor_last_frame = false
	else:
		fighter.global_position = Vector2(0, FLOOR_Y)
		fighter.velocity = Vector2.ZERO
		for unused in 60:
			if fighter.is_on_floor():
				break
			await physics_frame
		if not fighter.is_on_floor():
			push_error("fighter did not land: %s/%s" % [form.id, move.id])
	await process_frame
	_hide_hud()
	var frame_dir := clips_root.path_join("_frames").path_join(form.id).path_join(move.id).path_join(mode)
	DirAccess.make_dir_recursive_absolute(frame_dir)
	_remove_pngs(frame_dir)
	fighter.ai_controller.aim_direction = move.direction
	fighter.basic_attack()
	var chain_count := 3 if move.id == "ground-j" and form.id in ["frey", "luna_brave", "rio"] else 1
	var chain_step := 1
	var final_hold := -1
	var frame_count := 0
	while frame_count < MAX_CAPTURE_FRAMES:
		# SceneTree physics/timer callbacks may create VFX after `physics_frame` is emitted.
		# Hide at pre-draw so even an effect born in this frame is absent from the no-FX shot.
		await RenderingServer.frame_pre_draw
		_apply_capture_visibility(mode == "fx")
		await RenderingServer.frame_post_draw
		_save_frame(frame_dir, frame_count)
		frame_count += 1
		if fighter.attack_lock_timer <= 0.0 and not fighter.action_locked_until_land:
			if chain_step < chain_count:
				fighter.ai_controller.aim_direction = Vector2.RIGHT
				fighter.basic_attack()
				chain_step += 1
			elif (not move.air or fighter.is_on_floor()) and fighter.sprite_action_timer <= 0.0:
				if final_hold < 0:
					final_hold = FINAL_HOLD_FRAMES
				else:
					final_hold -= 1
					if final_hold <= 0:
						break
		for unused in PHYSICS_FRAMES_PER_SHOT:
			await physics_frame
	if frame_count >= MAX_CAPTURE_FRAMES:
		push_error("capture timeout: %s/%s/%s" % [form.id, move.id, mode])
	print("captured %s/%s/%s: %d frames" % [form.id, move.id, mode, frame_count])
	return frame_count

func _clear_capture_nodes() -> void:
	for child in arena.get_children():
		if child != floor_body and child != camera:
			child.free()
	fighter = null
	capture_dummy = null

func _hide_actor_hud(actor: Node) -> void:
	for path in ["NameLabel", "HpBar", "SoulBar"]:
		var node := actor.get_node_or_null(path)
		if node is CanvasItem:
			(node as CanvasItem).visible = false
	if actor == fighter:
		var body_node := actor.get_node_or_null("Body")
		if body_node is CanvasItem:
			(body_node as CanvasItem).visible = false

func _hide_hud() -> void:
	_hide_actor_hud(fighter)

func _apply_capture_visibility(with_fx: bool) -> void:
	_hide_actor_hud(fighter)
	if is_instance_valid(capture_dummy):
		_hide_actor_hud(capture_dummy)
	if with_fx:
		return
	for child in arena.get_children():
		if child == floor_body or child == camera:
			continue
		if child == fighter or child == capture_dummy:
			_hide_except_actor_visual(child)
		elif child is CanvasItem:
			(child as CanvasItem).visible = false
		else:
			_hide_canvas_descendants(child)

func _hide_except_character_sprite(node: Node) -> void:
	_hide_except_actor_visual(node)

func _hide_except_actor_visual(node: Node) -> void:
	var sprite := node.get_node_or_null("CharacterSprite") as AnimatedSprite2D
	var has_sprite := sprite != null and sprite.sprite_frames != null and not sprite.sprite_frames.get_animation_names().is_empty()
	for child in node.get_children():
		if child == sprite:
			(child as CanvasItem).visible = true
			continue
		if child.name == "Body" and not has_sprite:
			(child as CanvasItem).visible = true
			continue
		if child is CanvasItem:
			(child as CanvasItem).visible = false
		else:
			_hide_canvas_descendants(child)

func _hide_canvas_descendants(node: Node) -> void:
	for child in node.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = false
		else:
			_hide_canvas_descendants(child)

## Suppression happens at insertion time, before a newly spawned effect can reach a draw pass.
## Per-frame hiding alone is too late for effects created by timer callbacks in that same frame.
func _on_arena_child_entered(node: Node) -> void:
	if node == floor_body or node == camera:
		return
	if node == fighter or node == capture_dummy:
		if not node.child_entered_tree.is_connected(_on_actor_child_entered):
			node.child_entered_tree.connect(_on_actor_child_entered.bind(node))
		if suppress_fx:
			_hide_except_actor_visual(node)
		return
	if suppress_fx:
		_hide_effect_tree(node)

func _on_fighter_child_entered(node: Node) -> void:
	if suppress_fx and node != fighter.character_sprite:
		_hide_effect_tree(node)

func _on_actor_child_entered(node: Node, actor: Node) -> void:
	if not suppress_fx:
		return
	var sprite := actor.get_node_or_null("CharacterSprite")
	if node != sprite and node.name != "Body":
		_hide_effect_tree(node)

func _hide_effect_tree(node: Node) -> void:
	if node is CanvasItem:
		(node as CanvasItem).visible = false
	if not node.child_entered_tree.is_connected(_on_effect_child_entered):
		node.child_entered_tree.connect(_on_effect_child_entered)
	_hide_canvas_descendants(node)

func _on_effect_child_entered(node: Node) -> void:
	if suppress_fx:
		_hide_effect_tree(node)

func _save_frame(frame_dir: String, index: int) -> void:
	var image := root.get_texture().get_image()
	var origin := Vector2i((image.get_width() - CLIP_SIZE.x) / 2, (image.get_height() - CLIP_SIZE.y) / 2)
	var cropped := image.get_region(Rect2i(origin, CLIP_SIZE))
	var error := cropped.save_png(frame_dir.path_join("%04d.png" % index))
	if error != OK:
		push_error("could not save frame %d: %s" % [index, error_string(error)])

func _remove_pngs(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for name in dir.get_files():
		if name.ends_with(".png"):
			dir.remove(name)
