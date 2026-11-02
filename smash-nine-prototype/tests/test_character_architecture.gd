extends SceneTree

const MAIN_SCRIPT := preload("res://scripts/Main.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D
var main: Node
var characters: Dictionary

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	main = MAIN_SCRIPT.new()
	characters = CHARACTER_REGISTRY.get_characters()
	if characters.size() != 5:
		_fail("Registry did not return all five characters")
		return
	if not await _test_public_ability_dispatch():
		return
	if not await _test_frey_wave():
		return
	if not await _test_yuki_seal():
		return
	print("Character architecture combat regression tests passed")
	arena.queue_free()
	await process_frame
	main.free()
	quit(0)

func _create_player(character_id: String, player_id: int) -> Node:
	var player: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(player)
	player.global_position = Vector2(player_id * 1000.0, 0.0)
	player.setup(characters[character_id], player_id, false)
	player.set_physics_process(false)
	return player

func _test_public_ability_dispatch() -> bool:
	var player_id := 1
	for character_id in ["frey", "yuki", "luna", "nova"]:
		var player := _create_player(character_id, player_id)
		player_id += 1
		player.basic_attack()
		if player.attack_lock_timer <= 0.0:
			_fail("%s basic attack did not reach its character script" % character_id)
			return false
		player.attack_lock_timer = 0.0
		player.skill_one()
		if player.attack_lock_timer <= 0.0:
			_fail("%s K skill did not reach its character script" % character_id)
			return false
		player.is_defeated = true
		await create_timer(0.02).timeout
		player.queue_free()
	return true

## Frey's K (2026-11-03): one spin, then a sword wave that slows what it hits.
func _test_frey_wave() -> bool:
	var frey := _create_player("frey", 10)
	frey.skill_one()
	await create_timer(0.25).timeout
	var waves := arena.get_children().filter(func(node): return node.get_script() != null and node.get_script().resource_path == "res://scripts/Projectile.gd" and node.get("source") == frey)
	if waves.size() != 1:
		_fail("Frey K should send one sword wave (got %d)" % waves.size())
		return false
	if absf(float(waves[0].hit_slow_time) - 2.0) > 0.001:
		_fail("Frey's sword wave should slow for 2 s on a hit (got %.2f)" % float(waves[0].hit_slow_time))
		return false
	return true

func _test_yuki_seal() -> bool:
	var yuki := _create_player("yuki", 11)
	yuki.skill_one()
	for attempt in 60:
		if yuki.seals.size() == 1:
			break
		await create_timer(0.01).timeout
	if yuki.seals.size() != 1:
		_fail("Yuki K did not create exactly one binding seal")
		return false
	return true

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
