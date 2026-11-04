extends SceneTree
## Lead capture (2026-11-04) for the pick cup: Frey running at the match camera (zoom 0.85, the camera
## follows her) with her step dust played three ways, for the user to compare:
##   now     - one step (4 walk drawings), as in the game since 11-04
##   half    - one and a half steps (6 drawings)
##   before  - the first in-game version: 11 drawings at 16 fps (0.69 s), starting on an empty drawing
## Windowed run (not headless), one variant per run:
## <godot> --path . --fixed-fps 60 -s tests/analysis/lead/cup_step_dust_capture.gd -- --out=<dir> --variant=now

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const BEFORE_STRIP := "res://../art/bakeoff/effects/pixelfx/frey_step_dust-v2.png"

var out_dir := "user://cup_step_dust"
var variant := "now"
var arena: Node2D
var camera: Camera2D
var before_frames: SpriteFrames

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
		elif arg.begins_with("--variant="):
			variant = arg.substr(10)
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(960, 540)
	RenderingServer.set_default_clear_color(Color(0.09, 0.11, 0.17))
	if variant == "before":
		before_frames = _strip_frames(ProjectSettings.globalize_path(BEFORE_STRIP), 11, 16.0)
	arena = Node2D.new()
	root.add_child(arena)
	arena.child_entered_tree.connect(_on_spawned)
	camera = Camera2D.new()
	camera.zoom = Vector2(0.85, 0.85)
	arena.add_child(camera)
	camera.make_current()
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8000, 40)
	shape.shape = rect
	body.add_child(shape)
	var look := ColorRect.new()
	look.size = Vector2(8000, 40)
	look.position = Vector2(-4000, -20)
	look.color = Color(0.22, 0.26, 0.34)
	body.add_child(look)
	arena.add_child(body)
	body.global_position = Vector2(0, 20)
	var frey: Node = PLAYER_FACTORY.create("frey")
	arena.add_child(frey)
	frey.global_position = Vector2(-600, -2)
	frey.setup(CHARACTER_REGISTRY.get_characters()["frey"], 1, true)
	frey.ringout_y = 100000.0
	frey.set_process_unhandled_input(false)
	await _frames(30)
	var shot := await _record(frey, 0, 12)
	Input.action_press("move_right")
	shot = await _record(frey, shot, 78)
	Input.action_release("move_right")
	await _record(frey, shot, 24)
	print("CAPTURE_DONE ", out_dir)
	quit(0)

## The game spawns each dust at the pace of one step; the other variants change it after the spawn.
func _on_spawned(node: Node) -> void:
	if String(node.name).begins_with("Vfx_frey_step_dust") or (node is AnimatedSprite2D and _is_step_dust(node)):
		_restyle.call_deferred(node)

func _is_step_dust(node: AnimatedSprite2D) -> bool:
	var frame := node.sprite_frames.get_frame_texture(&"play", 0) as AtlasTexture if node.sprite_frames != null else null
	return frame != null and frame.atlas != null and frame.atlas.resource_path.ends_with("frey_step_dust.png")

func _restyle(node: Node) -> void:
	var sprite := node as AnimatedSprite2D
	if sprite == null or not is_instance_valid(sprite):
		return
	match variant:
		"half":
			sprite.speed_scale *= 4.0 / 6.0
		"before":
			sprite.sprite_frames = before_frames
			sprite.speed_scale = 1.0
			sprite.play(&"play")

func _strip_frames(path: String, count: int, fps: float) -> SpriteFrames:
	var texture := ImageTexture.create_from_image(Image.load_from_file(path))
	var frames := SpriteFrames.new()
	frames.clear_all()
	frames.add_animation(&"play")
	frames.set_animation_speed(&"play", fps)
	frames.set_animation_loop(&"play", false)
	var width := texture.get_width() / count
	for index in count:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(index * width, 0, width, texture.get_height())
		frames.add_frame(&"play", frame)
	return frames

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

## Saves `count` shots, one every two physics frames (30 fps), the camera on Frey.
func _record(fighter: Node, first: int, count: int) -> int:
	DirAccess.make_dir_recursive_absolute(out_dir)
	for index in count:
		await _frames(2)
		camera.global_position = fighter.global_position + Vector2(40, -60)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/%04d.png" % [out_dir, first + index])
	return first + count
