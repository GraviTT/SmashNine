extends SceneTree
## Lead capture for the pick cup on Rio's kit v3 effects (CODEX-VFX-11, 2026-11-27): the same scene for now / a / b
## of one item, in a realm at the match camera (0.85). "now" draws his stand-ins; "a" or "b" puts the candidate
## strips (`art/bakeoff/effects/rio/<name>-<variant>-v1.png` with their .json) into Vfx's cache at runtime, so the
## game's own calls draw them where and when they draw the effect. No game code or game art changes. A frame every
## 2 physics frames (30 fps) goes to <out>/####.png.
##   sword     K at Frey (the sword sticks in him), then K again (the blink behind him)
##   backstab  K, K again, then two J from behind
##   blink     K, K again; then the L counter: Frey swings, Rio vanishes and appears behind him
##   counter   the L stance held, then Frey's swing and the counter
##   decoy     U: the decoy and the step back, then Frey hits the decoy and it bursts
## Windowed: <godot> --path . --fixed-fps 60 -s tests/analysis/lead/cup_rio_fx_capture.gd -- --out=<dir> --item=sword --variant=a [--body=male] [--realm=niflheim]

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_CATALOG := preload("res://scripts/realms/RealmCatalog.gd")
const VFX := preload("res://scripts/Vfx.gd")
const BAKEOFF := "res://../art/bakeoff/"
const ITEM_EFFECTS := {"sword": ["rio_mana_sword", "rio_mana_sword_stuck"], "backstab": ["rio_backstab"],
	"blink": ["rio_shadow_blink"], "counter": ["rio_counter_stance"], "decoy": ["rio_decoy_burst"]}
const REALM_SIZE := Vector2(1920, 1080)
const FLOOR_SIZE := Vector2(1400, 52)

var out_dir := "user://cup_rio_fx"
var item := "sword"
var variant := "now"
var body := "male"
var realm := "niflheim"
var arena: Node2D
var camera: Camera2D
var rio: Node
var frey: Node
var tick := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
		elif arg.begins_with("--item="):
			item = arg.substr(7)
		elif arg.begins_with("--variant="):
			variant = arg.substr(10)
		elif arg.begins_with("--body="):
			body = arg.substr(7)
		elif arg.begins_with("--realm="):
			realm = arg.substr(8)
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(960, 540)
	RenderingServer.set_default_clear_color(Color(0.09, 0.11, 0.17))
	_stage()
	frey = _fighter("frey", "", 2, Vector2(150, -2))
	frey.facing = -1
	rio = PLAYER_FACTORY.create("rio", body)
	rio.position = Vector2(-200, -2)
	arena.add_child(rio)
	rio.setup(CHARACTER_REGISTRY.get_characters()["rio"], 1, true)
	rio.set_process_unhandled_input(false)
	rio.ringout_y = 100000.0
	rio.facing = 1
	if variant != "now" and not _use_candidate():
		push_error("candidate missing for %s %s" % [item, variant])
		quit(1)
		return
	await _idle(30)
	DirAccess.make_dir_recursive_absolute(out_dir)
	match item:
		"sword", "backstab", "blink":
			await _throw_and_blink()
			if item == "backstab":
				for swing in 2:
					await _until(func() -> bool: return rio._can_start_attack(), 60)
					rio.perform_basic_attack("neutral", Vector2.RIGHT * rio.facing)
					await _wait(20)
			elif item == "blink":
				await _wait(20)
				await _counter()
			await _wait(30)
		"counter":
			await _wait(10)
			await _counter()
			await _wait(30)
		"decoy":
			frey.global_position.x = rio.global_position.x + 70.0
			await _wait(10)
			rio.perform_skill_three()
			await _wait(24)
			if is_instance_valid(rio.decoy):
				rio.decoy.apply_hit(frey, 10.0, 200.0, Vector2.LEFT)
			await _wait(50)
	print("CAPTURE_DONE ", out_dir, " frames ", tick / 2)
	quit(0)

## K at Frey: the sword sticks in him; K again: Rio appears behind him and cuts (a backstab).
func _throw_and_blink() -> void:
	await _until(func() -> bool: return rio._can_start_attack(), 60)
	rio.perform_skill_one()
	await _until(func() -> bool: return is_instance_valid(rio.thrown_sword) and rio.thrown_sword.stuck, 90)
	await _wait(36)
	await _until(func() -> bool: return rio._can_start_attack(), 60)
	rio.try_skill_one_followup()
	await _wait(24)

## The L stance, then Frey's swing lands in it: Rio vanishes and appears behind him.
func _counter() -> void:
	await _until(func() -> bool: return rio._can_start_attack(), 60)
	if frey.global_position.distance_to(rio.global_position) > 160.0:
		frey.global_position.x = rio.global_position.x + 90.0 * rio.facing
	frey.facing = -rio.facing
	rio.counter_cooldown_timer = 0.0
	rio.perform_skill_two()
	await _wait(10)
	rio.apply_hit(frey, 12.0, 300.0, Vector2(rio.facing * -1.0, 0.0))
	await _wait(24)

## The candidate strips of this item, cut by their .json (frames, fps), into Vfx's cache under the keys the
## game's calls use.
func _use_candidate() -> bool:
	var versioned := variant if variant.contains("-v") else variant + "-v1"
	for effect in ITEM_EFFECTS.get(item, []):
		var path := "effects/rio/%s-%s" % [effect, versioned]
		var texture := _texture(path + ".png")
		if texture == null:
			return false
		var spec: Array = VFX.SPECS[effect]
		var frames_count := int(spec[0])
		var fps := float(spec[1])
		var meta_path := ProjectSettings.globalize_path(BAKEOFF + path + ".json")
		if FileAccess.file_exists(meta_path):
			var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
			if meta is Dictionary:
				frames_count = int(meta.get("frames", frames_count))
				fps = float(meta.get("fps", fps))
		for loop in [false, true]:
			var frames := SpriteFrames.new()
			frames.add_animation(&"play")
			frames.set_animation_speed(&"play", fps)
			frames.set_animation_loop(&"play", loop)
			var width := texture.get_width() / frames_count
			for index in frames_count:
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(index * width, 0, width, texture.get_height())
				frames.add_frame(&"play", atlas)
			VFX._cache["%s/%s" % [effect, loop]] = frames
	return true

func _texture(relative: String) -> Texture2D:
	var path := ProjectSettings.globalize_path(BAKEOFF + relative)
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

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

func _idle(count: int) -> void:
	for frame in count:
		await physics_frame

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
	camera.global_position = Vector2(-20, -130)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = FLOOR_SIZE
	shape.shape = box
	floor_body.add_child(shape)
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
		floor_body.add_child(strip)
	var accent: Color = map.get("accent", Color.WHITE)
	var edge := ColorRect.new()
	edge.color = Color(accent.r, accent.g, accent.b, 0.72)
	edge.size = Vector2(FLOOR_SIZE.x, 5.0)
	edge.position = -FLOOR_SIZE * 0.5
	floor_body.add_child(edge)
	floor_body.position = Vector2(0, FLOOR_SIZE.y * 0.5)
	arena.add_child(floor_body)

func _realm_map(dir: String) -> Dictionary:
	for map in REALM_CATALOG.build_maps():
		if str(map.get("art", {}).get("dir", "")) == dir:
			return map
	return {}

func _fighter(id: String, body_type: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(id, body_type)
	fighter.position = at
	arena.add_child(fighter)
	fighter.setup(CHARACTER_REGISTRY.get_characters()[id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = true
	fighter.invulnerable_timer = 0.0
	fighter.set_process_unhandled_input(false)
	return fighter
