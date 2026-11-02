## Barriers that stop projectiles (Luna's star barrier and Brave Luna's cyclone, 2026-11-03 D45).
## A barrier node joins GROUP and answers stops_projectile(projectile, source) -> bool; a projectile
## asks after each step of its flight and is gone when a barrier stopped it.

const GROUP := "projectile_barriers"

static func stopped(projectile: Node2D, source: Node) -> bool:
	if not projectile.is_inside_tree():
		return false
	for barrier in projectile.get_tree().get_nodes_in_group(GROUP):
		if barrier.stops_projectile(projectile, source):
			return true
	return false
