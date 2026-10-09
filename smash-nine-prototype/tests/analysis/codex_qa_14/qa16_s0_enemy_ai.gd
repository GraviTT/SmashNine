extends "res://scripts/EnemyAI.gd"
## Probe-only Round 16 S0 controller. Restore only the R11 target choice:
## a candidate standing on our level is accepted without a route/walkability check.

func _find_target(player) -> Node:
	var scored: Array = _scored_targets(player)
	scored.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var checks := 0
	var own_floor: Vector2 = _standing_point(player, player)
	for entry: Array in scored:
		var candidate: Node = entry[1]
		var stands: Vector2 = _standing_point(player, candidate)
		if stands == Vector2.INF:
			continue
		if own_floor == Vector2.INF or absf(stands.y - own_floor.y) <= NAV_SAME_LEVEL or checks >= 3:
			return candidate
		checks += 1
		if _has_route_to(player, stands):
			return candidate
		ignored_targets[candidate] = IGNORE_TIME
	return null
