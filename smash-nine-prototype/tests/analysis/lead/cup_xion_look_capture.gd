extends SceneTree
## Lead capture for the pick cup round on Xion's look (CODEX-ART-94): her idle in a realm, at the match camera
## (0.85), between Frey and Rio (female) for size and colour. Candidate A or B replaces the frames of her idle
## animation at runtime (the strip `art/bakeoff/xion/<letter>/xion-idle-<letter>.png`); "now" keeps the stand-in.
## No game code or game art changes.
## Windowed run, one realm and variant per run:
## <godot> --path . --fixed-fps 60 -s tests/analysis/lead/cup_xion_look_capture.gd -- --out=<dir> --variant=a --realm=niflheim

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_CATALOG := preload("res://scripts/realms/RealmCatalog.gd")
const CANDIDATE := "res://../art/bakeoff/xion/%s/xion-idle-%s.png"
## The painted realm layers are stretched over the realm (1280x720 x GameScale.WORLD) and dimmed, and the main
## platform is its painted strip with the accent edge on top, as RealmWorld draws them (RealmCatalog values).
const REALM_SIZE := Vector2(1920, 1080)
const FLOOR_SIZE := Vector2(1400, 52)
const CELL := 128

var out_dir := "user://cup_xion_look"
var variant := "now"
var realm := "niflheim"
var arena: Node2D
var camera: Camera2D

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
	var frey := _fighter("frey", "", 1, Vector2(-190, -2))
	frey.facing = 1
	var xion := _fighter("xion", "", 2, Vector2(0, -2))
	xion.facing = 1
	var rio := _fighter("rio", "female", 3, Vector2(190, -2))
	rio.facing = -1
	if variant != "now" and not _use_candidate(xion):
		push_error("candidate strip missing: " + CANDIDATE % [variant, variant])
		quit(1)
		return
	await _frames(40)
	DirAccess.make_dir_recursive_absolute(out_dir)
	for index in 96:
		await _frames(2)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/%04d.png" % [out_dir, index])
	print("CAPTURE_DONE ", out_dir)
	quit(0)

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
	camera.global_position = Vector2(0, -110)
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
	arena.add_child(body)
	body.global_position = Vector2(0, FLOOR_SIZE.y * 0.5)

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
	fighter.set_process_unhandled_input(false)
	return fighter

## The candidate's six idle drawings replace the stand-in's in Xion's own SpriteFrames (same 128-px cell, feet
## at y=120, 6.3 fps), so she stands and breathes exactly as the game draws an idle.
func _use_candidate(xion: Node) -> bool:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(CANDIDATE % [variant, variant]))
	if sheet == null or sheet.is_empty():
		return false
	var texture := ImageTexture.create_from_image(sheet)
	var sprite: AnimatedSprite2D = xion.character_sprite
	var frames: SpriteFrames = sprite.sprite_frames.duplicate()
	var name := &"xion_idle"
	if not frames.has_animation(name):
		return false
	frames.clear(name)
	for index in 6:
		var cut := AtlasTexture.new()
		cut.atlas = texture
		cut.region = Rect2(index * CELL, 0, CELL, CELL)
		frames.add_frame(name, cut)
	sprite.sprite_frames = frames
	sprite.play(name)
	return true

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
