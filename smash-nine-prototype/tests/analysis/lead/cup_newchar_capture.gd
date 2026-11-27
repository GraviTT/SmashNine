extends SceneTree
## Lead capture for the pick cup round on the new character candidates (CODEX-ART-98): each candidate's idle
## frame standing in a realm at the match camera (0.85), between Frey and Rio (female), for size and colour.
## A stand-in fighter (Xion) carries the candidate: her idle frames are replaced at runtime by the candidate's
## frame (a 128-px or 192-px cell; both put the feet on the same line, D34) and her name tag and HP bar are
## hidden. No game code or game art changes. One run records every candidate in turn for one realm:
## <godot> --path . --fixed-fps 60 -s tests/analysis/lead/cup_newchar_capture.gd -- --out=<dir> --realm=muspelheim
##     --ids=borok:1,borok:2,doron:1 [--dir=res://../art/bakeoff/newchar-2026-11-26]
## An id `c:n` reads <dir>/c/n/c-idle-n.png (CODEX-ART-99) and a plain id `c` reads <dir>/c/c-idle.png (ART-98).
## Frames go to <out>/<c><n>/<realm>/0000.png ...

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_CATALOG := preload("res://scripts/realms/RealmCatalog.gd")
## The painted realm layers are stretched over the realm (1280x720 x GameScale.WORLD) and dimmed, and the main
## platform is its painted strip with the accent edge on top, as RealmWorld draws them (RealmCatalog values).
const REALM_SIZE := Vector2(1920, 1080)
const FLOOR_SIZE := Vector2(1400, 52)
const SHOTS := 48

var out_dir := "user://cup_newchar"
var realm := "muspelheim"
var ids: PackedStringArray = []
var source_dir := "res://../art/bakeoff/newchar-2026-11-26"
var arena: Node2D
var camera: Camera2D

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
		elif arg.begins_with("--realm="):
			realm = arg.substr(8)
		elif arg.begins_with("--ids="):
			ids = arg.substr(6).split(",", false)
		elif arg.begins_with("--dir="):
			source_dir = arg.substr(6)
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(960, 540)
	RenderingServer.set_default_clear_color(Color(0.09, 0.11, 0.17))
	_stage()
	var frey := _fighter("frey", "", 1, Vector2(-190, -2))
	frey.facing = 1
	var host := _fighter("xion", "", 2, Vector2(0, -2))
	host.facing = 1
	var rio := _fighter("rio", "female", 3, Vector2(190, -2))
	rio.facing = -1
	var base_frames: SpriteFrames = host.character_sprite.sprite_frames
	await _frames(30)
	for id in ids:
		var parts := id.split(":")
		var path := "%s/%s/%s-idle.png" % [source_dir, id, id]
		if parts.size() == 2:
			path = "%s/%s/%s/%s-idle-%s.png" % [source_dir, parts[0], parts[1], parts[0], parts[1]]
		if not _carry(host, base_frames, path):
			push_error("candidate frame missing: " + path)
			continue
		await _frames(20)
		var dir := "%s/%s/%s" % [out_dir, id.replace(":", ""), realm]
		DirAccess.make_dir_recursive_absolute(dir)
		for index in SHOTS:
			await _frames(2)
			_hide_tags(host)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%04d.png" % [dir, index])
		print("CAPTURED ", id, " ", realm)
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
		strip.position = -FLOOR_SIZE * 0.5
		strip.size = FLOOR_SIZE
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

## The candidate's frame replaces the stand-in's idle drawings in a copy of her SpriteFrames.
func _carry(host: Node, base_frames: SpriteFrames, path: String) -> bool:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return false
	var cell := image.get_height()
	var cut := AtlasTexture.new()
	cut.atlas = ImageTexture.create_from_image(image)
	cut.region = Rect2(0, 0, cell, cell)
	var frames: SpriteFrames = base_frames.duplicate()
	var name := &"xion_idle"
	if not frames.has_animation(name):
		return false
	frames.clear(name)
	frames.add_frame(name, cut)
	var sprite: AnimatedSprite2D = host.character_sprite
	sprite.sprite_frames = frames
	sprite.play(name)
	_hide_tags(host)
	return true

## The stand-in's name and HP bar would name the wrong fighter.
func _hide_tags(host: Node) -> void:
	host.name_label.visible = false
	var bar := host.get_node_or_null("HpBar")
	if bar != null:
		bar.visible = false

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
