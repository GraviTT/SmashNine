extends "res://scripts/Projectile.gd"
## One shot of Xion's I "이퀄리브리엄" (2026-11-18), from her or from her doppelganger. It keeps its
## muzzle, so the passive (더블 샷건) measures the distance from where it was fired. Her own
## doppelganger does not stop it. Stand-in look: a thin crimson-gold streak.

var muzzle := Vector2.ZERO

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(source):
		_discard_orphaned_projectile()
		return
	if body == source or hit_targets.has(body) or not body.has_method("apply_hit"):
		return
	if body.has_method("is_owned_by") and body.is_owned_by(source):
		return
	hit_targets.append(body)
	var landed = false
	if source.has_method("hit_from"):
		landed = source.hit_from(muzzle, body, damage, knockback, direction, damage_type)
	else:
		landed = body.apply_hit(source, damage, knockback, direction, damage_type)
	if landed != false and source.has_method("on_bullet_hit"):
		source.on_bullet_hit(body, global_position)
	queue_free()
