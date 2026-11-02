extends "res://scripts/Projectile.gd"
## Luna's J stars ("별빛 연사", 2026-11-03 D45): a landed hit marks the target (the source's
## on_star_hit). The big last star bursts where it hits or where its flight ends
## (the source's star_burst_at).

var big := false
var burst_done := false

func _physics_process(delta: float) -> void:
	if big and not burst_done and is_instance_valid(source) and elapsed + delta >= lifetime:
		_burst()
		return
	super(delta)

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(source):
		_discard_orphaned_projectile()
		return
	if body == source or hit_targets.has(body) or not body.has_method("apply_hit"):
		return
	hit_targets.append(body)
	var landed = body.apply_hit(source, damage, knockback, direction, damage_type)
	if landed != false and source.has_method("on_star_hit"):
		source.on_star_hit(body)
	if big:
		# Not inside the physics callback: the burst adds a hit area (Godot refuses it while
		# queries flush).
		set_deferred("monitoring", false)
		_burst.call_deferred()
	else:
		queue_free()

func _burst() -> void:
	if burst_done:
		return
	burst_done = true
	set_deferred("monitoring", false)
	if is_instance_valid(source) and source.has_method("star_burst_at"):
		source.star_burst_at(global_position, direction)
	queue_free()
