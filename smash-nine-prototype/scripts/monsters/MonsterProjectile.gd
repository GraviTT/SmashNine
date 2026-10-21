extends "res://scripts/Projectile.gd"
## All monster shots retain Projectile's public combat/art API.
var projectile_kind := "bolt"
var flight_velocity := Vector2.ZERO
var arc_gravity := 0.0
var turn_rate := 1.4
var slow_duration := 0.0
var target: Node
var previous_position := Vector2.ZERO
var ground_check := false
var detonated := false

func _physics_process(delta: float) -> void:
	if not is_instance_valid(source) or not source.is_realm_active or source.hp <= 0.0:
		queue_free()
		return
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	previous_position = global_position
	if projectile_kind == "homing" and is_instance_valid(target) and target.get("is_realm_active") == true and target.get("realm_index") == source.realm_index:
		var desired: Vector2 = (target.global_position + Vector2(0, -28) - global_position).normalized()
		direction = direction.rotated(clampf(direction.angle_to(desired), -turn_rate * delta, turn_rate * delta))
	if projectile_kind in ["lob", "bomb"]:
		flight_velocity.y += arc_gravity * delta
		position += flight_velocity * delta
		direction = flight_velocity.normalized()
	else:
		position += direction * speed * delta
	# World-only ray stops shots at platforms, walls and ledges; swept fighter checks
	# prevent a small shot tunnelling through a fighter between physics frames.
	var query := PhysicsRayQueryParameters2D.create(previous_position, global_position, 1 | 2)
	query.exclude = [source.get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if hit.collider.is_in_group("players"):
			_on_body_entered(hit.collider)
		else:
			if projectile_kind == "bomb":
				_detonate(hit.position)
			queue_free()
	if ground_check:
		var floor_ray := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 80), 1)
		if get_world_2d().direct_space_state.intersect_ray(floor_ray).is_empty():
			queue_free()

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(source) or not source.is_realm_active or source.hp <= 0.0:
		queue_free()
		return
	if body == source or hit_targets.has(body) or body.get("realm_index") != source.realm_index or body.get("is_realm_active") != true:
		return
	if body.has_method("apply_hit"):
		hit_targets.append(body)
		var landed: Variant = body.apply_hit(source, damage, knockback, direction, damage_type)
		if landed != false and slow_duration > 0.0 and body.has_method("apply_control_pull"):
			body.apply_control_pull(body.global_position, 0.0, 0.0, slow_duration)
		if projectile_kind == "bomb":
			_detonate(body.global_position)
		queue_free()

func _detonate(at: Vector2) -> void:
	if detonated or not is_instance_valid(source) or source.hp <= 0.0 or not source.is_realm_active:
		return
	detonated = true
	var burst := Area2D.new()
	burst.set_script(preload("res://scripts/monsters/MonsterAttack.gd"))
	burst.collision_layer = 0
	burst.collision_mask = 2
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(104, 70)
	collision.shape = rect
	burst.add_child(collision)
	var flash := ColorRect.new()
	flash.name = "Visual"
	flash.size = rect.size
	flash.position = -rect.size * 0.5
	flash.color = Color(1.0, 0.7, 0.2, 0.55)
	burst.add_child(flash)
	burst.position = get_parent().to_local(at + Vector2(0, -22))
	burst.source = source
	burst.damage = damage
	burst.knockback = knockback
	burst.direction = Vector2.UP
	burst.lifetime = 0.18
	# A direct bomb hit and its burst share the same victim set: never double damage.
	burst.hit_targets = hit_targets
	# body_entered can run while Godot is flushing physics queries. Attach the
	# configured area afterwards, rather than mutating collision state in that signal.
	get_parent().call_deferred("add_child", burst)
