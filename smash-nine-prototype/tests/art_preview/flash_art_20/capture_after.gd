extends SceneTree
## CODEX-ART-20 screen check after the lead wired the strips in (copy of capture_flashes.gd writing to after/). Runs the real effect functions in a stable small arena and records
## every rendered 1/60 s frame. The art files are intentionally not wired in by this unit, so this
## captures current-main placeholders before lead integration.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const WARD_SCRIPT := preload("res://characters/yuki/YukiGrandWard.gd")
const SEAL_SCRIPT := preload("res://characters/yuki/YukiSeal.gd")
const OUT_RELATIVE := "../reports/codex-art-20/after"
const VIEW := Vector2i(640, 360)
const CROP := Rect2i(160, 60, 320, 240)

var out_dir := ""
var arena: Node2D
var fighter: Node
var saved: Dictionary = {}

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://").path_join(OUT_RELATIVE)
	DirAccess.make_dir_recursive_absolute(out_dir)
	root.content_scale_size = VIEW
	call_deferred("_run")

func _run() -> void:
	await _scenario("parry", 10, func() -> void: fighter._play_parry_effect())
	await _scenario("landing", 7, func() -> void: fighter._spawn_landing_puff())
	await _scenario("hit_light", 7, func() -> void:
		fighter._spawn_hit_effect(Vector2(320, 190), 5.0, 380.0)
		fighter._spawn_hit_slash(Vector2(320, 190), 380.0))
	await _scenario("hit_heavy", 7, func() -> void:
		fighter._spawn_hit_effect(Vector2(320, 190), 18.0, 760.0)
		fighter._spawn_hit_slash(Vector2(320, 190), 760.0))
	await _scenario("streak_light", 7, func() -> void: fighter._spawn_hit_slash(Vector2(320, 190), 380.0))
	await _scenario("streak_heavy", 7, func() -> void: fighter._spawn_hit_slash(Vector2(320, 190), 760.0))
	await _scenario("guard_block", 8, func() -> void:
		fighter.is_guarding = true
		fighter._update_guard_visual()
		fighter._play_guard_block_effect())
	await _scenario("frey_charge", 18, func() -> void: fighter._play_ultimate_charge())
	await _scenario("frey_release", 14, func() -> void: fighter._play_ultimate_release())
	await _node_scenario("ward_final", 14, WARD_SCRIPT, func(node: Node) -> void: node._play_final_effect())
	await _node_scenario("seal_burst", 14, SEAL_SCRIPT, func(node: Node) -> void: node._play_burst_effect())
	await _seal_break_scenario()
	_build_contact("short_flashes", ["parry", "landing", "hit_light", "hit_heavy", "streak_light", "streak_heavy", "guard_block", "frey_charge", "frey_release", "ward_final", "seal_burst", "seal_break"])
	print("CODEX-ART-20 flash frames saved to ", out_dir)
	quit(0)

func _scenario(name: String, frames: int, trigger: Callable) -> void:
	_setup_arena()
	fighter = PLAYER_FACTORY.create("frey")
	arena.add_child(fighter)
	fighter.setup(REGISTRY.get_characters()["frey"], 1, false)
	fighter.global_position = Vector2(320, 230)
	fighter.set_physics_process(false)
	if is_instance_valid(fighter.character_sprite):
		fighter.character_sprite.pause()
	await process_frame
	trigger.call()
	await _capture_sequence(name, frames)
	_teardown()
	await process_frame

func _node_scenario(name: String, frames: int, script: Script, trigger: Callable) -> void:
	_setup_arena()
	var node: Node2D = script.new()
	arena.add_child(node)
	node.global_position = Vector2(320, 190)
	node.set_physics_process(false)
	await process_frame
	trigger.call(node)
	await _capture_sequence(name, frames)
	_teardown()
	await process_frame

func _seal_break_scenario() -> void:
	_setup_arena()
	var node: Node2D = SEAL_SCRIPT.new()
	arena.add_child(node)
	node.global_position = Vector2(320, 190)
	node.set_physics_process(false)
	await process_frame
	# Isolate the break ColorRect for pixel measurement; the preceding seal/break composite is
	# covered separately by the ordinary seal scenario above.
	if is_instance_valid(node.idle_art):
		node.idle_art.visible = false
	if is_instance_valid(node.visual):
		node.visual.visible = false
	if is_instance_valid(node.aura):
		node.aura.visible = false
	for child in arena.get_children():
		if child.is_in_group("vfx"):
			child.visible = false
	node._play_break_effect()
	await _capture_sequence("seal_break", 10)
	_teardown()
	await process_frame

func _setup_arena() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	var bg := ColorRect.new()
	bg.size = VIEW
	bg.color = Color("1A1F2E")
	bg.z_index = -20
	arena.add_child(bg)
	var floor := ColorRect.new()
	floor.position = Vector2(80, 230)
	floor.size = Vector2(480, 18)
	floor.color = Color("4B5368")
	floor.z_index = -10
	arena.add_child(floor)

func _teardown() -> void:
	if is_instance_valid(arena):
		arena.queue_free()
	fighter = null

func _capture_sequence(name: String, count: int) -> void:
	var paths: Array[String] = []
	var group_dir := out_dir.path_join(name)
	DirAccess.make_dir_recursive_absolute(group_dir)
	for frame in count:
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := group_dir.path_join("%s_%02d.png" % [name, frame])
		image.save_png(path)
		paths.append(path)
	saved[name] = paths

func _build_contact(name: String, order: Array[String]) -> void:
	var max_frames := 0
	for scenario in order:
		max_frames = maxi(max_frames, saved[scenario].size())
	var thumb := Vector2i(CROP.size.x / 2, CROP.size.y / 2)
	var sheet := Image.create(max_frames * thumb.x, order.size() * thumb.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("101522"))
	for row in order.size():
		var paths: Array = saved[order[row]]
		for col in paths.size():
			var frame := Image.load_from_file(paths[col]).get_region(CROP)
			frame.resize(thumb.x, thumb.y, Image.INTERPOLATE_NEAREST)
			sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, thumb), Vector2i(col * thumb.x, row * thumb.y))
	sheet.save_png(out_dir.path_join("%s_contact.png" % name))
