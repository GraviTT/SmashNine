extends SceneTree
## Lead capture for the pick cup on Xion's move rows (CODEX-SKM-06, 2026-11-24): one reel of her moves in a realm
## at the match camera (0.85), between a Frey and a Rio (female) dummy. "now" keeps the rows the game has;
## "v1" (or another version) swaps each candidate row found at `art/bakeoff/xion/b/xion-<row>-<variant>.png`
## (6 frames in 192-px cells) into her SpriteFrames at runtime, which her hologram double shares. No game code or
## game art changes. A frame every 2 physics frames (30 fps) goes to <out>/####.png.
## Windowed: <godot> --path . --fixed-fps 60 -s tests/analysis/lead/cup_xion_moves_capture.gd -- --out=<dir> --variant=v1 [--realm=niflheim]
## The reel: J side twice (right and left hand), J up, J down, a jump and J down in the air, K roll, L recoil
## jump, U (the double hunts and pins Frey, then U again dives to it), I barrage.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_CATALOG := preload("res://scripts/realms/RealmCatalog.gd")
const CANDIDATE := "res://../art/bakeoff/xion/b/xion-%s-%s.png"
const REALM_SIZE := Vector2(1920, 1080)
const FLOOR_SIZE := Vector2(1400, 52)
const MOVE_CELL := 192

var out_dir := "user://cup_xion_moves"
var variant := "now"
var realm := "niflheim"
var arena: Node2D
var camera: Camera2D
var xion: Node
var tick := 0
var shot := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
		elif arg.begins_with("--variant="):
			variant = arg.substr(10)
		elif arg.begins_with("--realm="):
			realm = arg.substr(8)
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(960, 540)
	RenderingServer.set_default_clear_color(Color(0.09, 0.11, 0.17))
	_stage()
	var frey := _fighter("frey", "", 2, Vector2(170, -2))
	frey.facing = -1
	var rio := _fighter("rio", "female", 3, Vector2(-300, -2))
	rio.facing = 1
	xion = PLAYER_FACTORY.create("xion")
	arena.add_child(xion)
	xion.global_position = Vector2(-40, -2)
	xion.setup(CHARACTER_REGISTRY.get_characters()["xion"], 1, true)
	xion.set_process_unhandled_input(false)
	xion.ringout_y = 100000.0
	if variant != "now":
		print("SWAPPED ", _swap_rows())
	await _idle(30)
	DirAccess.make_dir_recursive_absolute(out_dir)
	xion.facing = 1
	await _shoot("side", Vector2.RIGHT, 36)
	await _shoot("side", Vector2.RIGHT, 40)
	await _shoot("up", Vector2.UP, 40)
	await _shoot("down", Vector2(1, 1).normalized(), 44)
	xion.velocity.y = xion.jump_velocity
	await _wait(16)
	await _shoot("air_down", Vector2.DOWN, 60)
	xion.facing = -1
	xion.roll_cooldown_timer = 0.0
	xion.skill_one()
	await _wait(44)
	xion.facing = 1
	xion.ammo = xion.MAGAZINE
	await _until(func() -> bool: return xion._can_start_attack() and xion.is_on_floor(), 60)
	xion.skill_two()
	await _wait(20)
	await _until(func() -> bool: return xion.is_on_floor(), 120)
	await _wait(10)
	xion.last_hit_foe = frey
	xion.double_cooldown_timer = 0.0
	xion.skill_three()
	await _until(func() -> bool: return frey.is_pinned(), 240)
	await _wait(30)
	xion.try_skill_three_followup()
	await _wait(40)
	await _until(func() -> bool: return xion._can_start_attack() and xion.is_on_floor(), 90)
	xion.ultimate_cooldown_timer = 0.0
	xion.facing = 1
	xion.skill_three()
	await _wait(20)
	await _until(func() -> bool: return xion._can_start_attack(), 30)
	xion.ultimate()
	await _wait(170)
	print("CAPTURE_DONE ", out_dir, " frames ", tick / 2)
	quit(0)

## J as the game plays it once the gap allows the next shot (the press itself, without the keyboard).
func _shoot(kind: String, direction: Vector2, after: int) -> void:
	xion.ammo = maxi(xion.ammo, 2)
	await _until(func() -> bool: return xion._can_start_attack() and xion.shot_timer <= 0.0, 60)
	xion.perform_basic_attack(kind, direction)
	shot += 1
	await _wait(after)

## Physics frames, saving every second one.
func _wait(count: int) -> void:
	for frame in count:
		await physics_frame
		tick += 1
		if tick % 2 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%04d.png" % [out_dir, tick / 2 - 1])

func _until(condition: Callable, limit: int) -> void:
	for frame in limit:
		if condition.call():
			return
		await _wait(1)

## Frames before the recording starts.
func _idle(count: int) -> void:
	for frame in count:
		await physics_frame

## Each candidate row replaces the drawings of the same row in Xion's SpriteFrames; its fps and loop stay the
## game's (Xion.MOVE_SHEET_ROWS).
func _swap_rows() -> Array[String]:
	var swapped: Array[String] = []
	var frames: SpriteFrames = xion.character_sprite.sprite_frames
	for spec in xion.MOVE_SHEET_ROWS:
		var row := str(spec[0])
		var path := ProjectSettings.globalize_path(CANDIDATE % [row, variant])
		if not FileAccess.file_exists(path):
			continue
		var image := Image.load_from_file(path)
		if image == null or image.is_empty():
			continue
		var texture := ImageTexture.create_from_image(image)
		var animation := StringName("xion_%s" % row)
		if not frames.has_animation(animation):
			continue
		frames.clear(animation)
		for index in int(image.get_width() / MOVE_CELL):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(index * MOVE_CELL, 0, MOVE_CELL, MOVE_CELL)
			frames.add_frame(animation, atlas)
		swapped.append(row)
	return swapped

func _stage() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	var dir := "res://assets/art/realm_%s" % realm
	var map := _realm_map(dir)
	var art: Dictionary = map.get("art", {})
	var layer := 0
	for name in ["bg_far", "bg_mid"]:
		var texture := load("%s/%s.png" % [dir, name]) as Texture2D
		if texture == null:
			continue
		var rect := TextureRect.new()
		rect.texture = texture
		rect.position = Vector2(-REALM_SIZE.x * 0.5, -REALM_SIZE.y * 0.62)
		rect.size = REALM_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.z_index = -19 + layer
		arena.add_child(rect)
		layer += 1
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, float(art.get("dim", 0.0)))
	shade.position = Vector2(-REALM_SIZE.x * 0.5, -REALM_SIZE.y * 0.62)
	shade.size = REALM_SIZE
	shade.z_index = -19 + layer
	arena.add_child(shade)
	camera = Camera2D.new()
	camera.zoom = Vector2(0.85, 0.85)
	arena.add_child(camera)
	camera.make_current()
	camera.global_position = Vector2(0, -130)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = FLOOR_SIZE
	shape.shape = box
	body.add_child(shape)
	var floor_art := load("%s/platform_main.png" % dir) as Texture2D
	if floor_art != null:
		var strip := NinePatchRect.new()
		strip.texture = floor_art
		strip.patch_margin_left = int(art.get("cap_main", 16))
		strip.patch_margin_right = int(art.get("cap_main", 16))
		strip.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
		strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		strip.position = -box.size * 0.5
		strip.size = box.size
		body.add_child(strip)
	var accent: Color = map.get("accent", Color.WHITE)
	var edge := ColorRect.new()
	edge.color = Color(accent.r, accent.g, accent.b, 0.72)
	edge.size = Vector2(FLOOR_SIZE.x, 5.0)
	edge.position = -FLOOR_SIZE * 0.5
	body.add_child(edge)
	body.position = Vector2(0, FLOOR_SIZE.y * 0.5)
	arena.add_child(body)

func _realm_map(dir: String) -> Dictionary:
	for map in REALM_CATALOG.build_maps():
		if str(map.get("art", {}).get("dir", "")) == dir:
			return map
	return {}

func _fighter(id: String, body_type: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(id, body_type)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = true
	fighter.invulnerable_timer = 0.0
	fighter.set_process_unhandled_input(false)
	return fighter
