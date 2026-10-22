extends SceneTree
## Production selector and gate carry, real collision. No authored geometry is edited.
const MAIN := preload("res://scripts/Main.gd")
var rows: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	MAIN.next_screen = "title"
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	main.match_seed = 2104
	root.add_child(main)
	current_scene = main
	main._start_match("frey")
	main.set_process(false)
	main.realm_monster_spawner.set_physics_process(false)
	for actor: Node in main.players + get_nodes_in_group("realm_monsters"):
		actor.set_physics_process(false)
	await _frames(3)
	var hero: Node = main.players[0]
	hero.is_dummy = true
	hero.grant_protection(10000.0)
	main.layout.assign_combatant(hero, 3)
	var entry: Dictionary = main.hazards._realms[3]
	var origin: Vector2 = main.layout.get_origin(3)
	var bad := 0
	for spot: Vector2 in entry.hazard.spots:
		var destination: Vector2 = origin + spot
		var selected_seed := -1
		var pair: Array = []
		for sample in 1000:
			main.hazards._rng.seed = sample
			pair = main.hazards._pick_gates(3, entry.hazard)
			if (pair[1] as Vector2).is_equal_approx(destination):
				selected_seed = sample
				break
		entry.gates = pair
		main.hazards._gate_inside.erase(hero)
		main.hazards._gate_cooldown.erase(hero)
		hero.set_physics_process(false)
		hero.global_position = pair[0]
		hero.velocity = Vector2.ZERO
		main.hazards._carry_through_gates(3, entry)
		var arrived: Vector2 = hero.global_position
		var nearest_top := INF
		var closest_gap := INF
		for rect: Rect2 in main.layout.get_platform_rects(3):
			if destination.x >= rect.position.x and destination.x <= rect.end.x:
				var gap := absf(destination.y - rect.position.y)
				if gap < closest_gap:
					closest_gap = gap
					nearest_top = rect.position.y
		hero.set_physics_process(true)
		var start_frame := Engine.get_physics_frames()
		var max_drop := 0.0
		for frame in 120:
			await _frames(1)
			max_drop = maxf(max_drop, hero.global_position.y - arrived.y)
		hero.set_physics_process(false)
		var gap_to_top := destination.y - nearest_top
		if absf(gap_to_top) > 4.0:
			bad += 1
		var row := {"match_seed": 2104, "selector_seed": selected_seed, "source": str(pair[0]), "destination": str(destination), "arrival": str(arrived), "nearest_platform_top_y": nearest_top, "gate_feet_minus_nearest_top": gap_to_top, "max_drop_120_frames": max_drop, "final_position": str(hero.global_position), "on_floor_after": hero.is_on_floor(), "ringouts": hero.respawn_count, "start_frame": start_frame}
		rows.append(row)
		print("QA21_GATE_GEOMETRY ", JSON.stringify(row))
	var file := FileAccess.open("res://../reports/codex-qa-21/gate-geometry.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"bad_slots": bad, "rows": rows}, "\t") + "\n")
	quit(1 if bad > 0 else 0)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
