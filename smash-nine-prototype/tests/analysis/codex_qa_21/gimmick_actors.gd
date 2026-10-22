extends SceneTree
## Seed 2104. Actors come from real Main battle spawning; freeze only their own motion.
const MAIN := preload("res://scripts/Main.gd")
var rows: Array = []
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	MAIN.next_screen = "title"
	MAIN.session_mode = "battle_royale"
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	main.match_seed = 2104
	root.add_child(main)
	current_scene = main
	main._start_match("frey")
	main.set_process(false)
	main.realm_monster_spawner.set_physics_process(false)
	for player: Node in main.players:
		player.set_physics_process(false)
	for monster: Node in get_nodes_in_group("realm_monsters"):
		monster.set_physics_process(false)
	var human: Node = main.players[0]
	var bot: Node = main.players[1]
	var monster: Node = main.realm_monster_spawner.monsters_by_realm[3][0]
	main.hazards.trigger(3)
	main.hazards.advance(1.3)
	var gates: Array = main.hazards.get_gates(3)
	for actor: Node in [human, bot, monster]:
		if actor != monster:
			main.layout.assign_combatant(actor, 3)
		actor.global_position = gates[0]
		actor.velocity = Vector2.ZERO
	main.hazards.advance(1.0 / 60.0)
	var gate_row := {"case_name": "moon_gate", "seed": 2104, "gates": [str(gates[0]), str(gates[1])], "registered": [main.hazards.combatants.has(human), main.hazards.combatants.has(bot), main.hazards.combatants.has(monster)], "human_distance_to_exit": human.global_position.distance_to(gates[1]), "bot_distance_to_exit": bot.global_position.distance_to(gates[1]), "monster_distance_to_exit": monster.global_position.distance_to(gates[1])}
	for frame in 90:
		main.hazards.advance(1.0 / 60.0)
	gate_row.human_still_at_exit = human.global_position.distance_to(gates[1])
	gate_row.bot_still_at_exit = bot.global_position.distance_to(gates[1])
	rows.append(gate_row)
	print("QA21_GIMMICK ", JSON.stringify(gate_row))
	if monster.global_position.distance_to(gates[1]) > 6.0:
		failed = true
	# Actual contact flags are established by the engine before measuring only belt motion.
	monster = main.realm_monster_spawner.monsters_by_realm[5][0]
	var belt: Rect2 = main.hazards.get_belts(5)[0]
	for actor: Node in [human, bot, monster]:
		if actor != monster:
			main.layout.assign_combatant(actor, 5)
			actor.is_dummy = true
			actor.grant_protection(1000.0)
		else:
			actor.wander_timer = 1000.0
			actor.wander_direction = 0.0
		actor.global_position = Vector2(belt.get_center().x, belt.position.y - 2)
		actor.velocity = Vector2.ZERO
		actor.set_physics_process(true)
	await _frames(30)
	var before: Array = []
	var floors: Array = []
	for actor: Node in [human, bot, monster]:
		actor.set_physics_process(false)
		before.append(actor.global_position.x)
		floors.append(actor.is_on_floor())
	main.hazards.advance(0.5)
	var delta: Array = []
	for index in 3:
		delta.append([human, bot, monster][index].global_position.x - before[index])
	var belt_row := {"case_name": "forge_belt", "seed": 2104, "on_floor": floors, "seconds": 0.5, "delta_x_human_bot_monster": delta, "direction": main.hazards.get_belt_direction(5)}
	rows.append(belt_row)
	print("QA21_GIMMICK ", JSON.stringify(belt_row))
	if absf(float(delta[2])) < 40.0:
		failed = true
	# Sample the production gate selector against real floor collision and realm bounds.
	var unsafe := 0
	var spot_checks: Array = []
	for sample in 100:
		main.hazards._rng.seed = sample
		var pair: Array = main.hazards._pick_gates(3, main.hazards._realms[3].hazard)
		for point: Vector2 in pair:
			var ray := PhysicsRayQueryParameters2D.create(point + Vector2(0, -64), point + Vector2(0, 64), 1)
			var hit: Dictionary = main.get_world_2d().direct_space_state.intersect_ray(ray)
			if sample < 4:
				spot_checks.append({"point": str(point), "hit": str(hit.get("position", Vector2.INF)), "feet_minus_surface": point.y - hit.position.y if not hit.is_empty() else 999.0})
			if not main.layout.get_bounds(3).has_point(point) or hit.is_empty():
				unsafe += 1
	var sample_row := {"case_name": "gate_floor_samples", "seeds": "0..99", "points": 200, "unsafe": unsafe, "spot_checks": spot_checks}
	rows.append(sample_row)
	print("QA21_GIMMICK ", JSON.stringify(sample_row))
	var file := FileAccess.open("res://../reports/codex-qa-21/gimmick-actors.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failed_expected_monster_use": failed, "rows": rows}, "\t") + "\n")
	quit(1 if failed else 0)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
