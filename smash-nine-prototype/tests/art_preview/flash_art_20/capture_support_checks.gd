extends SceneTree
## Running-game cross-check for monster bite/fireball and all timed hazard warnings.

const MONSTER_SCRIPT := preload("res://scripts/RealmMonster.gd")
const MAIN_SCENE := "res://scenes/Main.tscn"
const OUT_RELATIVE := "../reports/codex-art-20/before/support"

var out_dir := ""

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://").path_join(OUT_RELATIVE)
	DirAccess.make_dir_recursive_absolute(out_dir)
	root.content_scale_size = Vector2i(1280, 720)
	call_deferred("_run")

func _run() -> void:
	await _capture_monster("mossling", "bite", false)
	await _capture_monster("ember_imp", "fireball", true)
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.match_seed = 2020
	root.add_child(main)
	for frame in 90:
		await process_frame
	main.set_process(false)
	main.set_physics_process(false)
	for spec in [[0, "beams"], [4, "eruption"], [6, "vines"], [7, "quake"]]:
		main._set_map(spec[0])
		main.hazards.trigger(spec[0])
		for frame in 4:
			await process_frame
		await _shot("hazard_%s_warning" % spec[1])
	print("support checks saved to ", out_dir)
	quit(0)

func _capture_monster(type_id: String, label: String, projectile: bool) -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	var bg := ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color("1A1F2E")
	bg.z_index = -20
	arena.add_child(bg)
	var floor := ColorRect.new()
	floor.position = Vector2(240, 470)
	floor.size = Vector2(800, 24)
	floor.color = Color("4B5368")
	floor.z_index = -10
	arena.add_child(floor)
	var monster := CharacterBody2D.new()
	monster.set_script(MONSTER_SCRIPT)
	monster.setup(type_id, 0, Vector2(600, 470))
	arena.add_child(monster)
	monster.set_physics_process(false)
	await process_frame
	if projectile:
		monster._spawn_projectile(Vector2.RIGHT)
	else:
		monster._spawn_melee_attack()
	monster._update_art(0.0)
	for frame in 12:
		await process_frame
		if frame % 3 == 0:
			await _shot("monster_%s_%02d" % [label, frame])
	arena.queue_free()
	await process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("%s.png" % name))
