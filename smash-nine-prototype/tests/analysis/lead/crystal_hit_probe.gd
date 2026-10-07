extends SceneTree
## In a real match: does a fighter's attack area overlapping a soul crystal see it?

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	main.match_seed = 303
	main.player_count = 2
	root.add_child(main)
	await process_frame
	main._start_match("frey")
	var bot: Node = main.players[0]
	var crystal: Node = main.soul_crystal_spawner.get_crystal(bot.realm_index)
	var shape: CollisionShape2D = crystal.get_child(0)
	print("CRYSTAL pos=", crystal.global_position, " shape_at=", shape.global_position, " layer=", crystal.collision_layer, " shape=", shape.shape, " disabled=", shape.disabled, " in_tree=", crystal.is_inside_tree(), " parent=", crystal.get_parent().name)
	bot.global_position = crystal.global_position + Vector2(-40, 60)
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 6
	var area_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(100, 100)
	area_shape.shape = rect
	area.add_child(area_shape)
	main.add_child(area)
	area.global_position = crystal.global_position
	for frame in 5:
		await physics_frame
	var names: Array[String] = []
	for body in area.get_overlapping_bodies():
		names.append("%s(%s)" % [body.name, body.get_class()])
	print("OVERLAP ", names)
	var space: PhysicsDirectSpaceState2D = crystal.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = shape.global_position
	query.collision_mask = 4
	var hits: Array[String] = []
	for hit in space.intersect_point(query):
		hits.append(str(hit.collider.name))
	print("POINT ", hits)
	area.queue_free()
	# A real grounded swing from 40 px left, feet 60 px below the crystal's anchor.
	bot.set_physics_process(false)
	bot.global_position = crystal.global_position + Vector2(-40, 60)
	bot.facing = 1
	bot.attack_lock_timer = 0.0
	var hp_before: float = crystal.hp
	bot.perform_basic_attack("neutral", Vector2.RIGHT)
	for frame in 30:
		await physics_frame
	print("SWING hp ", hp_before, " -> ", crystal.hp if is_instance_valid(crystal) else -1.0)
	quit(0)
