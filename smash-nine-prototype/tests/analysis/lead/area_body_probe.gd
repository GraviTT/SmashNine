extends SceneTree
## Which body types does an attack Area2D (mask = players | monsters) see on the monster layer?

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var results := {}
	for kind in ["StaticBody2D", "AnimatableBody2D", "CharacterBody2D", "StaticBody2D+mask"]:
		var body: PhysicsBody2D
		match kind:
			"StaticBody2D", "StaticBody2D+mask": body = StaticBody2D.new()
			"AnimatableBody2D": body = AnimatableBody2D.new()
			_: body = CharacterBody2D.new()
		body.collision_layer = 4
		body.collision_mask = 1 if kind == "StaticBody2D+mask" else 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(40, 40)
		shape.shape = rect
		body.add_child(shape)
		root.add_child(body)
		# The crystal sits still for a long time before an attack appears.
		for frame in 30:
			await physics_frame
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 6
		var area_shape := CollisionShape2D.new()
		var area_rect := RectangleShape2D.new()
		area_rect.size = Vector2(100, 100)
		area_shape.shape = area_rect
		area.add_child(area_shape)
		root.add_child(area)
		for frame in 4:
			await physics_frame
		results[kind] = area.get_overlapping_bodies().has(body)
		body.queue_free()
		area.queue_free()
		await physics_frame
	print("AREA_BODY ", results)
	quit(0)
