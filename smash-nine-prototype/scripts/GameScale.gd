extends RefCounted
## Global scales (routine 2026-10-08 work; user: "공격 범위와 이펙트들이 지금보다 최소 2배",
## "맵 1.5배"). Fighters keep their size (1x art, 42x64 hurtbox); attacks and realms are
## measured against them through these numbers, so a scale can be tried or rolled back in
## one place.

## Attack reach and hit areas, projectiles, attack effects, bots' fighting distances.
const COMBAT := 2.0
## Realm layouts: platform spans, portals, spawns, hazards, blast lines.
const WORLD := 1.5
## Run speeds, dash and knockback distances (the realms grow 1.5x, fighters cover them a
## little slower than before so the fighters do not look like they zip around).
const MOVE := 1.2
## Jump heights follow the platform spacing.
const JUMP_HEIGHT := WORLD
## Gravity is a little stronger so the higher jumps do not float (air time x1.12).
const GRAVITY := 1.2
## Launch speeds for JUMP_HEIGHT x the height under GRAVITY x the pull: sqrt(1.5 * 1.2).
## Fall speed caps scale the same way so falls keep their shape.
const JUMP_SPEED := 1.3416
## Knockback travels as far as the realms grew, in the same time (speed and decay both
## scale), so ring-outs need the same share of a realm as before.
const KNOCKBACK := WORLD

## Attack offsets are measured from the body's centre (origin at the feet, 64 px hurtbox),
## so a chest-high slash stays chest-high while its reach doubles, and an upward or downward
## attack reaches twice as far up or down.
const BODY_CENTRE := Vector2(0, -32)

static func attack_point(point: Vector2) -> Vector2:
	return BODY_CENTRE + (point - BODY_CENTRE) * COMBAT

static func attack_points(points: Array[Vector2]) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for point in points:
		result.append(attack_point(point))
	return result
