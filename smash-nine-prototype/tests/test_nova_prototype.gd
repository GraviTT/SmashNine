extends SceneTree

const MAIN_SCRIPT := preload("res://scripts/Main.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const ATTACK_PATH := "res://scripts/Attack.gd"
const BURST_PATH := "res://characters/nova/NovaGravityBurst.gd"

var arena: Node2D
var main: Node
var nova_data: Dictionary

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	main = MAIN_SCRIPT.new()
	nova_data = CHARACTER_REGISTRY.get_characters()["nova"]
	if not await _test_momentum_attack_scaling():
		return
	if not await _test_vector_shift_has_no_attack():
		return
	if not await _test_gravity_brake_scaling():
		return
	if not await _test_gravity_slingshot():
		return
	print("Nova momentum and gravity prototype tests passed")
	arena.queue_free()
	await process_frame
	main.free()
	quit(0)

func _create_nova(player_id: int, physics_enabled := false) -> Node:
	var nova: Node = PLAYER_FACTORY.create("nova")
	arena.add_child(nova)
	nova.global_position = Vector2(player_id * 2200.0, 0.0)
	nova.setup(nova_data, player_id, false)
	nova.ringout_y = 100000.0
	nova.set_physics_process(physics_enabled)
	return nova

func _test_momentum_attack_scaling() -> bool:
	var slow := _create_nova(1)
	slow.velocity = Vector2(180.0, 0.0)
	slow.perform_basic_attack("side", Vector2.RIGHT)
	var slow_attack := await _wait_for_source_script(slow, ATTACK_PATH)
	if not is_instance_valid(slow_attack):
		_fail("Nova slow J did not create an attack")
		return false
	var slow_damage: float = slow_attack.damage
	var slow_travel: float = slow_attack.motion_points[-1].length()
	var fast := _create_nova(2)
	fast.velocity = Vector2(700.0, 0.0)
	fast.perform_basic_attack("side", Vector2.RIGHT)
	var fast_attack := await _wait_for_source_script(fast, ATTACK_PATH)
	if not is_instance_valid(fast_attack):
		_fail("Nova high-speed J did not create an attack")
		return false
	if fast_attack.damage <= slow_damage or fast_attack.motion_points[-1].length() <= slow_travel:
		_fail("Nova J did not scale damage and travel with momentum")
		return false
	slow.queue_free()
	fast.queue_free()
	await create_timer(0.2).timeout
	return true

func _test_vector_shift_has_no_attack() -> bool:
	var nova := _create_nova(3)
	var attack_count := _count_nodes_with_script(ATTACK_PATH)
	nova.skill_one()
	if not nova.vector_shift_active or nova.air_vector_shift_available:
		_fail("Nova aerial K did not start or consume its air use")
		return false
	nova.apply_character_gravity(0.1)
	if nova.velocity.length() < 500.0:
		_fail("Nova K did not accelerate the character body")
		return false
	if _count_nodes_with_script(ATTACK_PATH) != attack_count:
		_fail("Nova K incorrectly created an attack hitbox")
		return false
	nova._cancel_vector_shift()
	nova.attack_lock_timer = 0.0
	nova.skill_one()
	if nova.vector_shift_active:
		_fail("Nova K ignored its one-use aerial limit")
		return false
	nova.queue_free()
	await process_frame
	return true

func _test_gravity_brake_scaling() -> bool:
	var slow := _create_nova(4)
	slow.velocity = Vector2(180.0, 0.0)
	slow.skill_two()
	var slow_burst := await _wait_for_source_script(slow, BURST_PATH)
	if not is_instance_valid(slow_burst):
		_fail("Nova slow L did not create a gravity burst")
		return false
	var slow_damage: float = slow_burst.damage
	var slow_radius: float = slow_burst.collision_shape.shape.radius
	var fast := _create_nova(5)
	fast.velocity = Vector2(700.0, 0.0)
	fast.skill_two()
	var fast_burst := await _wait_for_source_script(fast, BURST_PATH)
	if not is_instance_valid(fast_burst):
		_fail("Nova high-speed L did not create a gravity burst")
		return false
	if fast_burst.damage <= slow_damage or fast_burst.collision_shape.shape.radius <= slow_radius:
		_fail("Nova L did not scale damage and radius with momentum")
		return false
	if fast.velocity != Vector2.ZERO:
		_fail("Nova L did not cancel current momentum")
		return false
	slow.queue_free()
	fast.queue_free()
	await create_timer(0.2).timeout
	return true

func _test_gravity_slingshot() -> bool:
	var nova := _create_nova(6, true)
	nova.velocity = Vector2(520.0, 0.0)
	nova.ultimate()
	if nova.ultimate_phase != nova.ULTIMATE_CORE or not is_instance_valid(nova.singularity_visual):
		_fail("Nova ultimate first input did not create and hold its gravity core")
		return false
	var core_position: Vector2 = nova.ultimate_center
	nova.global_position = core_position + Vector2(-60.0, 0.0)
	nova.ultimate()
	if nova.ultimate_phase != nova.ULTIMATE_ORBIT:
		_fail("Nova ultimate second input did not begin orbiting")
		return false
	if not is_instance_valid(nova.ultimate_launch_preview) or nova.ultimate_preview_line.points.size() != 2:
		_fail("Nova ultimate orbit did not display its launch destination")
		return false
	var near_orbit_speed: float = nova.ultimate_orbit_speed
	var preview_distance: float = nova.ultimate_preview_line.points[1].length()
	if preview_distance < 250.0:
		_fail("Nova ultimate launch preview was too short to represent its destination")
		return false
	var orbit_position: Vector2 = nova.global_position
	for attempt in 20:
		await create_timer(0.01).timeout
	if nova.global_position.distance_to(orbit_position) < 8.0:
		_fail("Nova ultimate did not move along its gravity orbit")
		return false
	nova.ultimate()
	if nova.ultimate_phase != nova.ULTIMATE_LAUNCH:
		_fail("Nova ultimate third input did not start its launch")
		return false
	if is_instance_valid(nova.ultimate_launch_preview) or nova.ultimate_launch_speed < 900.0:
		_fail("Nova ultimate did not clear its preview and preserve launch speed")
		return false
	var pre_shift_direction: Vector2 = nova.ultimate_launch_direction
	nova.facing = -1 if pre_shift_direction.x >= 0.0 else 1
	nova.skill_one()
	if nova.ultimate_launch_shift_available or nova.ultimate_launch_direction.dot(pre_shift_direction) > 0.9:
		_fail("Nova ultimate launch did not allow K to redirect its trajectory")
		return false
	var saw_final_burst := false
	for attempt in 100:
		if nova.ultimate_phase == nova.ULTIMATE_NONE and is_instance_valid(_find_source_script(nova, BURST_PATH)):
			saw_final_burst = true
			break
		await create_timer(0.01).timeout
	if not saw_final_burst:
		_fail("Nova ultimate did not end in a gravity impact burst")
		return false
	if is_instance_valid(nova.singularity_visual) or is_instance_valid(nova.ultimate_launch_preview) or nova.collision_mask == 0:
		_fail("Nova ultimate did not restore visuals and world collision state")
		return false
	var wide := _create_nova(7)
	wide.ultimate()
	wide.global_position = wide.ultimate_center + Vector2(-280.0, 0.0)
	wide.ultimate()
	if wide.ultimate_phase != wide.ULTIMATE_ORBIT or wide.ultimate_orbit_speed >= near_orbit_speed:
		_fail("Nova wide orbit was not slower than its narrow orbit")
		return false
	if wide.ultimate_launch_speed >= nova.ULTIMATE_FAST_LAUNCH_SPEED:
		_fail("Nova wide orbit did not produce a slower launch profile")
		return false
	wide._cancel_ultimate()
	wide.queue_free()
	return true

func _wait_for_source_script(source: Node, script_path: String) -> Node:
	for attempt in 100:
		var found := _find_source_script(source, script_path)
		if is_instance_valid(found):
			return found
		await create_timer(0.005).timeout
	return null

func _find_source_script(source: Node, script_path: String) -> Node:
	for child in arena.get_children():
		if child.get_script() != null and child.get_script().resource_path == script_path and child.source == source:
			return child
	return null

func _count_nodes_with_script(script_path: String) -> int:
	var count := 0
	for child in arena.get_children():
		if child.get_script() != null and child.get_script().resource_path == script_path:
			count += 1
	return count

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
