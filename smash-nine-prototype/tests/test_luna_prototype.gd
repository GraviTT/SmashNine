extends SceneTree

const MAIN_SCRIPT := preload("res://scripts/Main.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const ATTACK_PATH := "res://scripts/Attack.gd"
const STAR_PATH := "res://characters/luna/LunaStar.gd"
const BARRIER_PATH := "res://characters/luna/LunaBarrier.gd"
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
	if not await _test_normal_star_volley():
		return
	if not await _test_warp_and_barrier():
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

## Normal J (D45): each press fires a star projectile; the fourth is the big one.
func _test_normal_star_volley() -> bool:
	var luna := _create_luna(1)
	var stars: Array[Node] = []
	var on_node_added := func(node: Node) -> void:
		var script: Script = node.get_script()
		if script != null and script.resource_path == STAR_PATH:
			stars.append(node)
	node_added.connect(on_node_added)
	var big_flags: Array[bool] = []
	for press in 4:
		luna.attack_lock_timer = 0.0
		luna.basic_attack()
		if not await _wait_for(func() -> bool: return stars.size() > press, 0.5):
			break
		big_flags.append(bool(stars[press].big))
	node_added.disconnect(on_node_added)
	if big_flags != [false, false, false, true]:
		_fail("Luna normal J should fire three small stars and then a big one (got %s)" % [big_flags])
		return false
	luna.queue_free()
	await create_timer(0.4).timeout
	return true

## Normal K warps and bursts on both sides of her; normal L raises the star barrier.
func _test_warp_and_barrier() -> bool:
	var luna := _create_luna(2)
	var start_x: float = luna.global_position.x
	var bursts: Array[Node] = []
	var on_node_added := func(node: Node) -> void:
		var script: Script = node.get_script()
		if script != null and script.resource_path == ATTACK_PATH:
			bursts.append(node)
	node_added.connect(on_node_added)
	luna.skill_one()
	await _wait_for(func() -> bool: return bursts.size() >= 2, 1.0)
	node_added.disconnect(on_node_added)
	if bursts.size() < 2 or absf(luna.global_position.x - start_x) < 150.0:
		_fail("Luna K should warp her ahead and burst on both sides (%d hit areas, moved %.0f)" % [bursts.size(), luna.global_position.x - start_x])
		return false
	luna.attack_lock_timer = 0.0
	luna.skill_two()
	var barrier: Node
	for attempt in 60:
		barrier = luna.get_node_or_null("StarBarrier")
		if is_instance_valid(barrier):
			break
		await create_timer(0.01).timeout
	if not is_instance_valid(barrier) or barrier.get_script().resource_path != BARRIER_PATH or not barrier.is_in_group("projectile_barriers"):
		_fail("Luna L did not raise the star barrier")
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
		_fail("Brave K did not dash Luna's character body")
		return false
	luna.grab_dash_timer = 0.0
	luna.skill_dash_timer = 0.0
	luna._end_skill_dash()
	luna.attack_lock_timer = 0.0
	luna.transformation_timer = 0.46
	# The star beam (D45) always lasts 3 s, whatever is left of the Brave form.
	var expected_laser_duration: float = luna.BEAM_TIME
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
		_fail("Luna star beam should last BEAM_TIME")
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
	for attempt in 400:
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
