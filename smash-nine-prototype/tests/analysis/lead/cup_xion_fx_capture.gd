extends SceneTree
## Lead capture for the pick cup on Xion's effects (CODEX-VFX-10, 2026-11-24): the same scene for now / a / b of
## one item, in a realm at the match camera (0.85). "now" draws her code stand-ins; "a" or "b" puts the candidate
## strip (`art/bakeoff/effects/xion/<name>-<variant>-v1.png` with its .json; the reload mark also under
## `art/bakeoff/ui/status/`) into Vfx's cache at runtime, so the game's own calls draw it where and when they
## draw the effect. No game code or game art changes. A frame every 2 physics frames (30 fps) goes to <out>/####.png.
##   blast        J side twice, up and down at Frey
##   recoil       L next to Frey
##   point_blank  J twice at Frey from up close
##   reload       the last round, then the 3 s reload (the mark over her head)
##   double_in    U: her double appears and hunts Frey
##   dive_trail   U, the pin on Frey, U again
##   bullet       I, the barrage, with her double out
## Windowed: <godot> --path . --fixed-fps 60 -s tests/analysis/lead/cup_xion_fx_capture.gd -- --out=<dir> --item=blast --variant=a [--realm=niflheim]

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_CATALOG := preload("res://scripts/realms/RealmCatalog.gd")
const VFX := preload("res://scripts/Vfx.gd")
const BAKEOFF := "res://../art/bakeoff/"
const ITEM_EFFECTS := {"blast": "xion_blast", "recoil": "xion_recoil_blast", "point_blank": "xion_point_blank",
	"double_in": "xion_double_in", "dive_trail": "xion_dive_trail", "bullet": "xion_bullet"}
const REALM_SIZE := Vector2(1920, 1080)
const FLOOR_SIZE := Vector2(1400, 52)

var out_dir := "user://cup_xion_fx"
var item := "blast"
var variant := "now"
var realm := "niflheim"
var arena: Node2D
var camera: Camera2D
var xion: Node
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
		elif arg.begins_with("--realm="):
			realm = arg.substr(8)
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(960, 540)
	RenderingServer.set_default_clear_color(Color(0.09, 0.11, 0.17))
	_stage()
	var frey_at := Vector2(30.0 if item == "point_blank" or item == "recoil" else 170.0, -2)
	frey = _fighter("frey", "", 2, frey_at)
	frey.facing = -1
	xion = PLAYER_FACTORY.create("xion")
	xion.position = Vector2(-40, -2)
	arena.add_child(xion)
	xion.setup(CHARACTER_REGISTRY.get_characters()["xion"], 1, true)
	xion.set_process_unhandled_input(false)
	xion.ringout_y = 100000.0
	xion.facing = 1
	if variant != "now" and not _use_candidate():
		push_error("candidate missing for %s %s" % [item, variant])
		quit(1)
		return
	await _idle(30)
	DirAccess.make_dir_recursive_absolute(out_dir)
	match item:
		"blast":
			await _shoot("side", Vector2.RIGHT, 30)
			await _shoot("side", Vector2.RIGHT, 30)
			await _shoot("up", Vector2.UP, 30)
			await _shoot("down", Vector2(1, 1).normalized(), 36)
		"recoil":
			await _wait(10)
			xion.skill_two()
			await _wait(20)
			await _until(func() -> bool: return xion.is_on_floor(), 120)
			await _wait(16)
			xion.ammo = xion.MAGAZINE
			xion.recoil_available = true
			xion.skill_two()
			await _wait(60)
		"point_blank":
			await _shoot("side", Vector2.RIGHT, 32)
			frey.global_position.x = xion.global_position.x + 70.0
			await _shoot("side", Vector2.RIGHT, 40)
		"reload":
			xion.ammo = 1
			await _shoot("side", Vector2.RIGHT, 10)
			await _wait(170)
		"double_in":
			xion.last_hit_foe = frey
			await _wait(10)
			xion.skill_three()
			await _wait(80)
		"dive_trail":
			xion.last_hit_foe = frey
			xion.skill_three()
			await _until(func() -> bool: return frey.is_pinned(), 240)
			await _wait(12)
			xion.try_skill_three_followup()
			await _wait(40)
		"bullet":
			xion.last_hit_foe = frey
			xion.skill_three()
			await _wait(40)
			await _until(func() -> bool: return xion._can_start_attack(), 30)
			xion.ultimate_cooldown_timer = 0.0
			xion.ultimate()
			await _wait(80)
	print("CAPTURE_DONE ", out_dir, " frames ", tick / 2)
	quit(0)

## The candidate strip of this item, cut by its .json (frames, fps, loop), into Vfx's cache under the keys the
## game's calls use; the reload mark goes to her own override.
func _use_candidate() -> bool:
	# "a" means a-v1; "a-v2" names a later version.
	var versioned := variant if variant.contains("-v") else variant + "-v1"
	if item == "reload":
		var texture := _texture(["ui/status/xion_reload-%s.png" % versioned, "effects/xion/xion_reload-%s.png" % versioned])
		if texture == null:
			return false
		xion.reload_art_override = texture
		return true
	var effect: String = ITEM_EFFECTS.get(item, "")
	var path := "effects/xion/%s-%s" % [effect, versioned]
	var texture := _texture([path + ".png"])
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

func _texture(paths: Array) -> Texture2D:
	for relative in paths:
		var path := ProjectSettings.globalize_path(BAKEOFF + str(relative))
		if FileAccess.file_exists(path):
			var image := Image.load_from_file(path)
			if image != null and not image.is_empty():
				return ImageTexture.create_from_image(image)
	return null

func _shoot(kind: String, direction: Vector2, after: int) -> void:
	await _until(func() -> bool: return xion._can_start_attack() and xion.shot_timer <= 0.0, 60)
	xion.perform_basic_attack(kind, direction)
	await _wait(after)

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
	camera.global_position = Vector2(40, -130)
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
	fighter.position = at
	arena.add_child(fighter)
	fighter.setup(CHARACTER_REGISTRY.get_characters()[id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = true
	fighter.invulnerable_timer = 0.0
	fighter.set_process_unhandled_input(false)
	return fighter
