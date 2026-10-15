extends SceneTree
## Windowed capture of every J variant at the speed and timing used by the game.
## Usage (from smash-nine-prototype/):
## godot --path . --fixed-fps 60 -s tests/capture_move_clips.gd

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const FPS := 30
const PHYSICS_FRAMES_PER_SHOT := 2
const CLIP_SIZE := Vector2i(960, 540)
const FLOOR_Y := 110.0
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

var arena: Node2D
var floor_body: StaticBody2D
var camera: Camera2D
var fighter: CharacterBody2D
var clips_root := ""
var capture_entries: Array[Dictionary] = []
var suppress_fx := false

func _initialize() -> void:
	clips_root = ProjectSettings.globalize_path("res://../art/clips")
	DirAccess.make_dir_recursive_absolute(clips_root)
	RenderingServer.set_default_clear_color(Color("101522"))
	call_deferred("_run")

func _run() -> void:
	_build_arena()
	await process_frame
	for form in FORMS:
		for move in MOVES:
			var pair: Dictionary = {}
			for mode in ["fx", "nofx"]:
				seed(SEED)
				var frames := await _capture(form, move, mode)
				pair[mode] = frames
			if int(pair.fx) != int(pair.nofx):
				push_error("clip pair frame mismatch: %s/%s" % [form.id, move.id])
				quit(2)
				return
			capture_entries.append({
				"form": form.id,
				"move": move.id,
				"name": move.name,
				"input": move.input,
				"frames": pair.fx,
				"rows": FORM_ROWS[form.id][move.id],
				"size": [CLIP_SIZE.x, CLIP_SIZE.y],
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
	print("CAPTURE_RESULT forms=%d pairs=%d files=%d size=%dx%d fps=%d" % [FORMS.size(), capture_entries.size(), capture_entries.size() * 2, CLIP_SIZE.x, CLIP_SIZE.y, FPS])
	quit(0)

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
	camera.position = Vector2(0, -160)
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

func _hide_hud() -> void:
	for path in ["Body", "NameLabel", "HpBar", "SoulBar", "StatusIcon", "GuardVisual"]:
		var node := fighter.get_node_or_null(path)
		if node is CanvasItem:
			(node as CanvasItem).visible = false

func _apply_capture_visibility(with_fx: bool) -> void:
	_hide_hud()
	if with_fx:
		return
	for child in arena.get_children():
		if child == floor_body or child == camera:
			continue
		if child == fighter:
			_hide_except_character_sprite(child)
		elif child is CanvasItem:
			(child as CanvasItem).visible = false
		else:
			_hide_canvas_descendants(child)

func _hide_except_character_sprite(node: Node) -> void:
	for child in node.get_children():
		if child == fighter.character_sprite:
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
	if node == fighter:
		if not node.child_entered_tree.is_connected(_on_fighter_child_entered):
			node.child_entered_tree.connect(_on_fighter_child_entered)
		if suppress_fx:
			_hide_except_character_sprite(node)
		return
	if suppress_fx:
		_hide_effect_tree(node)

func _on_fighter_child_entered(node: Node) -> void:
	if suppress_fx and node != fighter.character_sprite:
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
