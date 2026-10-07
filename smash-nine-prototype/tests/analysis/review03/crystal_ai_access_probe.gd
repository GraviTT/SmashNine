extends SceneTree
## Isolates one real bot beside a crystal to distinguish target priority from inability.

const MAIN_SCENE := "res://scenes/Main.tscn"

var attack_nodes := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.match_seed = 303
	main.player_count = 2
	root.add_child(main)
	await process_frame
	main._start_match("frey")
	var bot: Node = main.players[0]
	bot.is_human = false
	var other: Node = main.players[1]
	other.is_dummy = true
	other.set_physics_process(false)
	other.collision_layer = 0
	for monster in get_nodes_in_group("realm_monsters"):
		monster.queue_free()
	main.realm_monster_spawner.set_process(false)
	main.realm_monster_spawner.monsters_by_realm.clear()
	var crystal: Node = main.soul_crystal_spawner.get_crystal(bot.realm_index)
	bot.global_position = crystal.global_position + Vector2(-120.0, 0.0)
	bot.velocity = Vector2.ZERO
	var souls_before: int = bot.souls
	node_added.connect(func(node: Node) -> void:
		if node is Area2D:
			call_deferred("_count_attack", node, bot))
	var frames := 0
	while frames < 60 * 12 and main.soul_crystal_spawner.get_crystal(bot.realm_index) != null:
		await physics_frame
		frames += 1
		for monster in get_nodes_in_group("realm_monsters"):
			monster.queue_free()
	var standing: Node = main.soul_crystal_spawner.get_crystal(bot.realm_index)
	var hp_before_forced_overlap: float = standing.hp if is_instance_valid(standing) else 0.0
	var manual_attack: Area2D
	if is_instance_valid(standing):
		var offset: Vector2 = standing.global_position + Vector2(0.0, -26.0) - bot.global_position
		bot._spawn_attack(Vector2(100.0, 100.0), offset, 1.0, 0.0, Vector2.RIGHT, Color.WHITE, 0.2)
		for child in main.get_children():
			if child is Area2D and child.get("source") == bot and child.global_position.distance_to(standing.global_position + Vector2(0.0, -26.0)) < 1.0:
				manual_attack = child
		await physics_frame
	var manual_overlap_names: Array[String] = []
	if is_instance_valid(manual_attack):
		for body in manual_attack.get_overlapping_bodies():
			manual_overlap_names.append(str(body.name))
	if is_instance_valid(standing):
		await physics_frame
	standing = main.soul_crystal_spawner.get_crystal(bot.realm_index)
	print("CRYSTAL_AI_ACCESS ", JSON.stringify({
		"seed": 303,
		"seconds": snappedf(float(frames) / 60.0, 0.1),
		"character": bot.character_id,
		"broken": standing == null,
		"remaining_hp": standing.hp if is_instance_valid(standing) else 0,
		"hp_before_forced_overlap": hp_before_forced_overlap,
		"crystal_collision_layer": crystal.collision_layer,
		"crystal_active": crystal.is_realm_active,
		"manual_attack_overlaps": manual_overlap_names,
		"souls_gained": bot.souls - souls_before,
		"attack_nodes": attack_nodes,
		"final_distance": snappedf(bot.global_position.distance_to(crystal.global_position), 0.1),
		"target_is_crystal": bot.ai_controller.target == crystal
	}))
	quit(0)

func _count_attack(node: Node, bot: Node) -> void:
	if is_instance_valid(node) and node.get("source") == bot:
		attack_nodes += 1
