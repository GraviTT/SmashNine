extends SceneTree
## Lead capture (2026-10-29, CODEX-VFX-01 applied): Rio male and female spend both extra air
## jumps as in play (nothing held); a picture one and three physics frames after each jump shows
## the plate left at the soles he jumped from and him rising off it.
## Windowed run (not headless): <godot> --path . -s tests/analysis/lead/rio_air_step_capture.gd -- --out=<dir>

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var out_dir := "user://rio_air_step"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(480, 360)
	RenderingServer.set_default_clear_color(Color(0.09, 0.11, 0.17))
	var arena := Node2D.new()
	root.add_child(arena)
	var camera := Camera2D.new()
	camera.zoom = Vector2(2, 2)
	arena.add_child(camera)
	camera.make_current()
	# Warm-up: the first draw of a strip compiles its shader, and the physics frames that catch up
	# afterwards can outlast the 0.125 s plate before the first picture.
	for effect in ["rio_air_step", "rio_air_step_last"]:
		preload("res://scripts/Vfx.gd").spawn(arena, effect, Vector2(0, 4000))
	for frame in 30:
		await process_frame
	for body in ["male", "female"]:
		var rio: Node = PLAYER_FACTORY.create("rio", body)
		arena.add_child(rio)
		rio.global_position = Vector2(0, 0)
		rio.setup(CHARACTER_REGISTRY.get_characters()["rio"], 1, true)
		rio.ringout_y = 100000.0
		rio.set_process_unhandled_input(false)
		for frame in 3:
			await physics_frame
		rio.air_jumps_left = rio.max_air_jumps
		for jump in 2:
			rio.velocity = Vector2.ZERO
			var at: Vector2 = rio.global_position
			camera.global_position = at + Vector2(0, -50)
			rio.jump_buffer_timer = 0.1
			rio.coyote_timer = 0.0
			await physics_frame
			await physics_frame
			# Pictures only: the plate is held on a chosen frame, since a window's frame pacing can
			# outlast the 0.125 s strip before the picture is taken.
			var plate: AnimatedSprite2D = arena.get_children().filter(func(n): return String(n.name).begins_with("Vfx_rio_air_step")).back()
			plate.pause()
			plate.frame = 1
			# a: the jump instant, Rio put back where he jumped from (jump pose, plate under his soles).
			rio.set_physics_process(false)
			rio.global_position = at
			await _shot(arena, rio, "%s/rio_%s_air_step_%d_a.png" % [out_dir, body, jump + 1])
			# b: three frames later in real flight, rising off the plate.
			rio.set_physics_process(true)
			for frame in 3:
				await physics_frame
			plate.frame = 3
			await _shot(arena, rio, "%s/rio_%s_air_step_%d_b.png" % [out_dir, body, jump + 1])
			plate.queue_free()
			for frame in 30:
				await physics_frame
		rio.queue_free()
		await process_frame
	quit(0)

func _shot(arena: Node, rio: Node, path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	var plates: Array = arena.get_children().filter(func(n): return String(n.name).begins_with("Vfx_rio_air_step")).map(func(n): return "%s@%s f%d" % [n.name, n.global_position, n.frame])
	print("saved ", path, " rio ", rio.global_position, " left ", rio.air_jumps_left, " plates ", plates)
