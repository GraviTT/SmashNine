extends SceneTree
## Things that attacks must reach are not static bodies, and areas that must meet platforms are
## monitorable (2026-11-25).
## The engine fact behind both: an Area2D with monitorable off never meets a StaticBody2D (it meets
## an AnimatableBody2D and a CharacterBody2D). Every attack and projectile area in the game has
## monitorable off. So:
##  - a script with apply_hit (something a hit must land on) may not be a StaticBody2D: Rio's decoy
##    was one and no swing ever burst it; Yuki's seal was one and nothing ever tore it;
##  - an area that asks whether the body it met is a platform must have monitorable on: Yuki's
##    talisman had it off and flew through every platform.
## This reads the game's scripts and checks the engine fact itself, so that the rule can be dropped
## the day the engine stops behaving this way.

const ROOTS := ["res://characters", "res://scripts"]

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _scripts(path: String, found: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for name in dir.get_files():
		if name.ends_with(".gd"):
			found.append(path.path_join(name))
	for name in dir.get_directories():
		_scripts(path.path_join(name), found)

func _run() -> void:
	var scripts: Array[String] = []
	for root_path in ROOTS:
		_scripts(root_path, scripts)
	if scripts.size() < 40:
		_fail("Test setup: expected the game's scripts under %s (found %d)" % [ROOTS, scripts.size()])
	var hittable := 0
	for path in scripts:
		var text := FileAccess.get_file_as_string(path)
		var base := ""
		for line in text.split("\n"):
			if line.begins_with("extends "):
				base = line.trim_prefix("extends ").strip_edges()
				break
		if text.contains("\nfunc apply_hit("):
			hittable += 1
			if base == "StaticBody2D" or base == "RigidBody2D":
				_fail("%s takes hits (apply_hit) but is a %s: attack areas have monitorable off and never meet a static body. Make it an AnimatableBody2D with sync_to_physics off from _init, placed before it enters the tree (RioDecoy.gd, YukiSeal.gd)" % [path, base])
		if text.contains("is_in_group(\"platforms\")") and text.contains("body_entered") and text.contains("monitorable = false"):
			_fail("%s is an area that looks for platforms among the bodies it meets, with monitorable off: it never meets a static platform. Turn monitorable on (YukiTalisman.gd) or cast a ray (RioSword.gd)" % path)
	if hittable < 5:
		_fail("Test setup: expected at least five scripts with apply_hit (found %d)" % hittable)
	await _check_the_engine_fact()
	if failed:
		quit(1)
		return
	print("Hittable body tests passed (%d scripts read, %d take hits)" % [scripts.size(), hittable])
	quit(0)

func _box(size: Vector2) -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	return shape

## Far from the origin on purpose (a body left at the origin must not pass for one in place).
func _check_the_engine_fact() -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	var at := Vector2(9000, 6000)
	var still := StaticBody2D.new()
	var moving := AnimatableBody2D.new()
	moving.sync_to_physics = false
	var bodies: Array[PhysicsBody2D] = [still, moving]
	for index in bodies.size():
		bodies[index].collision_layer = 4
		bodies[index].collision_mask = 0
		bodies[index].add_child(_box(Vector2(30, 42)))
		bodies[index].position = at + Vector2(index * 400, 0)
		arena.add_child(bodies[index])
	await physics_frame
	await physics_frame
	var met: Array[int] = []
	for index in bodies.size():
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 4
		area.monitoring = true
		area.monitorable = false
		area.add_child(_box(Vector2(60, 60)))
		area.position = at + Vector2(index * 400 + 10, 0)
		arena.add_child(area)
		for frame in 4:
			await physics_frame
		met.append(area.get_overlapping_bodies().size())
		area.queue_free()
	if met[1] != 1:
		_fail("An area with monitorable off should meet an AnimatableBody2D (the decoy and the seal rely on it)")
	if met[0] != 0:
		print("NOTE: an area with monitorable off now meets a StaticBody2D: the engine changed, and the rule this test keeps may no longer be needed")
	arena.queue_free()
	await process_frame
