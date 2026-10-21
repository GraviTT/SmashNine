extends "res://scripts/Attack.gd"
## A moving body attack follows its monster; one hit per fighter per action.
var follow_source := false
var follow_offset := Vector2.ZERO
var slow_duration := 0.0

func _physics_process(delta: float) -> void:
	if not _source_active():
		queue_free()
		return
	if follow_source:
		global_position = source.global_position + follow_offset
	super._physics_process(delta)

func _source_active() -> bool:
	return is_instance_valid(source) and source.is_realm_active and source.hp > 0.0

func _hit_body(body: Node) -> void:
	if not _source_active() or body == source or hit_targets.has(body):
		return
	if body.get("realm_index") != source.realm_index or body.get("is_realm_active") != true:
		return
	if body.has_method("apply_hit"):
		hit_targets.append(body)
		var landed: Variant = body.apply_hit(source, damage, knockback, direction, damage_type)
		if landed != false and slow_duration > 0.0 and body.has_method("apply_control_pull"):
			body.apply_control_pull(body.global_position, 0.0, 0.0, slow_duration)
