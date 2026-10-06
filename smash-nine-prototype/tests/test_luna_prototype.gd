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
	var initial_attacks := _count_nodes_with_script(ATTACK_PATH)
	luna.perform_basic_attack("side", Vector2.RIGHT)
	var saw_two_beats := false
	for attempt in 80:
		if _count_nodes_with_script(ATTACK_PATH) >= initial_attacks + 2:
			saw_two_beats = true
			break
		await create_timer(0.005).timeout
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
	await process_frame
	if _count_nodes_with_script(ATTACK_PATH) <= attacks_before_bloom:
		_fail("Luna comet did not create its range-end bloom attack")
		return false
	await create_timer(0.16).timeout
	luna.attack_lock_timer = 0.0
	var attacks_before_ring := _count_nodes_with_script(ATTACK_PATH)
	luna.skill_two()
	var saw_both_ring_halves := false
	for attempt in 80:
		if _count_nodes_with_script(ATTACK_PATH) >= attacks_before_ring + 2:
			saw_both_ring_halves = true
			break
		await create_timer(0.01).timeout
	if not saw_both_ring_halves:
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

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
