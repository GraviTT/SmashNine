extends SceneTree

const MAIN_SCRIPT := preload("res://scripts/Main.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const ATTACK_PATH := "res://scripts/Attack.gd"
const COMET_PATH := "res://characters/luna/LunaComet.gd"
const HEART_LASER_PATH := "res://characters/luna/LunaHeartLaser.gd"

var arena: Node2D
var main: Node
var luna_data: Dictionary

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	main = MAIN_SCRIPT.new()
	luna_data = CHARACTER_REGISTRY.get_characters()["luna"]
	if not await _test_normal_star_echo():
		return
	if not await _test_comet_and_ring():
		return
	if not await _test_brave_transformation():
		return
	print("Luna normal and Brave form prototype tests passed")
	arena.queue_free()
	await process_frame
	main.free()
	quit(0)

func _create_luna(player_id: int) -> Node:
	var luna: Node = PLAYER_FACTORY.create("luna")
	arena.add_child(luna)
	luna.global_position = Vector2(player_id * 1200.0, 0.0)
	luna.setup(luna_data, player_id, false)
	luna.set_physics_process(false)
	return luna

func _test_normal_star_echo() -> bool:
	var luna := _create_luna(1)
	# Count hitboxes as they are created: the trail (0.1 s) and the bloom (after 0.065 s)
	# overlap for only ~2 physics frames, so sampling live nodes was flaky.
	var created: Array[Node] = []
	var on_node_added := func(node: Node) -> void:
		var script: Script = node.get_script()
		if script != null and script.resource_path == ATTACK_PATH:
			created.append(node)
	node_added.connect(on_node_added)
	luna.perform_basic_attack("side", Vector2.RIGHT)
	for attempt in 80:
		if created.size() >= 2:
			break
		await create_timer(0.005).timeout
	node_added.disconnect(on_node_added)
	var saw_two_beats := created.size() >= 2
	if not saw_two_beats:
		_fail("Luna normal J did not create the trail and delayed star bloom")
		return false
	luna.queue_free()
	await create_timer(0.25).timeout
	return true

func _test_comet_and_ring() -> bool:
	var luna := _create_luna(2)
	luna.skill_one()
	var comet: Node
	for attempt in 80:
		comet = _find_node_with_script(COMET_PATH)
		if is_instance_valid(comet):
			break
		await create_timer(0.01).timeout
	if not is_instance_valid(comet):
		_fail("Luna K did not create a star comet")
		return false
	var attacks_before_bloom := _count_nodes_with_script(ATTACK_PATH)
	comet._detonate()
	# The bloom lives 0.13 s; one late process frame can outlast it, a physics frame cannot.
	if not await _wait_for(func() -> bool: return _count_nodes_with_script(ATTACK_PATH) > attacks_before_bloom, 0.5):
		_fail("Luna comet did not create its range-end bloom attack")
		return false
	luna.attack_lock_timer = 0.0
	# Counted as they are created, like the star echo, so the bloom running out meanwhile
	# cannot hide a half.
	var ring_halves: Array[Node] = []
	var on_node_added := func(node: Node) -> void:
		var script: Script = node.get_script()
		if script != null and script.resource_path == ATTACK_PATH:
			ring_halves.append(node)
	node_added.connect(on_node_added)
	luna.skill_two()
	await _wait_for(func() -> bool: return ring_halves.size() >= 2, 1.0)
	node_added.disconnect(on_node_added)
	if ring_halves.size() < 2:
		_fail("Luna L did not create both rotating ring halves")
		return false
	luna.queue_free()
	await create_timer(0.3).timeout
	return true

func _test_brave_transformation() -> bool:
	var luna := _create_luna(3)
	luna.ultimate()
	for attempt in 80:
		if luna.transformed:
			break
		await create_timer(0.01).timeout
	if not luna.transformed or luna.transformation_timer < 5.8:
		_fail("Luna ultimate did not enter the timed Brave form")
		return false
	if luna.get_character_movement_multiplier() <= 1.0 or not is_instance_valid(luna.transformation_aura):
		_fail("Brave form did not apply mobility and aura state")
		return false
	luna.attack_lock_timer = 0.0
	luna.basic_attack()
	if luna.attack_lock_timer <= 0.0 or luna.attack_lock_timer >= 0.3:
		_fail("Brave J did not switch to its fast melee timing")
		return false
	luna.attack_lock_timer = 0.0
	luna.skill_one()
	for attempt in 40:
		if luna.skill_dash_velocity.length() > 600.0:
			break
		await create_timer(0.01).timeout
	if luna.skill_dash_velocity.length() <= 600.0:
		_fail("Brave K did not move Luna's character body")
		return false
	luna.skill_dash_timer = 0.0
	luna._end_skill_dash()
	luna.attack_lock_timer = 0.0
	luna.transformation_timer = 0.46
	var expected_laser_duration: float = luna.transformation_timer
	var target := _create_luna(4)
	target.global_position = luna.global_position + Vector2(220.0, 0.0)
	var target_hp_before: float = target.hp
	luna.ultimate()
	var laser: Node
	for attempt in 40:
		laser = _find_node_with_script(HEART_LASER_PATH)
		if luna.transformation_finishing and is_instance_valid(laser):
			break
		await create_timer(0.01).timeout
	if not luna.transformation_finishing or not is_instance_valid(laser):
		_fail("Ultimate re-input did not fire Luna's heart laser")
		return false
	if absf(laser.duration - expected_laser_duration) > 0.02:
		_fail("Luna heart laser duration did not match the remaining transformation time")
		return false
	if laser.collision_shape.shape.size.x < 500.0 or laser.collision_shape.shape.size.y < 100.0:
		_fail("Luna heart laser did not create a giant forward hitbox")
		return false
	if luna.skill_dash_velocity.length() > 0.01:
		_fail("Luna ultimate re-input still used the removed finale dash")
		return false
	await create_timer(0.3).timeout
	if target.hp >= target_hp_before - 4.0:
		_fail("Luna heart laser did not apply repeated damage while sustained")
		return false
	for attempt in 100:
		if not luna.transformed:
			break
		await create_timer(0.01).timeout
	if luna.transformed or is_instance_valid(luna.transformation_aura) or is_instance_valid(luna.heart_laser):
		_fail("Luna heart laser did not consume and clean up Brave form")
		return false
	target.queue_free()
	return true

func _count_nodes_with_script(script_path: String) -> int:
	var count := 0
	for child in arena.get_children():
		if child.get_script() != null and child.get_script().resource_path == script_path:
			count += 1
	return count

func _find_node_with_script(script_path: String) -> Node:
	for child in arena.get_children():
		if child.get_script() != null and child.get_script().resource_path == script_path:
			return child
	return null

## Polls a condition every physics frame, for up to `timeout` seconds of game time.
## physics_frame comes before any node's _physics_process, so a hit area is seen before its
## own frames can expire it (as in test_rio_prototype.gd).
func _wait_for(condition: Callable, timeout: float) -> bool:
	var waited := 0.0
	while not condition.call() and waited < timeout:
		await physics_frame
		waited += get_root().get_physics_process_delta_time()
	return condition.call()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
