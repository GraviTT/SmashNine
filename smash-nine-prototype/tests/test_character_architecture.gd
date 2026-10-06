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
	if characters.size() != 4:
		_fail("Registry did not return all four characters")
		return
	if not await _test_public_ability_dispatch():
		return
	if not await _test_frey_dash():
		return
	if not await _test_yuki_seal():
		return
	if not await _test_match_state_transfer():
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

func _test_frey_dash() -> bool:
	var frey := _create_player("frey", 10)
	var start_position: Vector2 = frey.global_position
	frey.skill_one()
	await create_timer(0.15).timeout
	if frey.skill_dash_velocity.length() < 700.0:
		_fail("Frey K did not start the character-body dash")
		return false
	if frey.skill_dash_timer <= 0.0:
		_fail("Frey K dash timer was not armed")
		return false
	if frey.global_position != start_position:
		_fail("Disabled physics unexpectedly moved Frey during the dash assertion")
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

func _test_match_state_transfer() -> bool:
	var frey := _create_player("frey", 20)
	frey.level = 6
	frey.experience = 9
	frey.experience_to_next_level = 77
	frey.score = 4
	frey.respawn_count = 3
	frey.match_pressure = 1.6
	frey.hp = frey.max_hp * 0.4
	var yuki := _create_player("yuki", 20)
	yuki.inherit_match_state(frey)
	if yuki.level != 6 or yuki.experience != 9 or yuki.experience_to_next_level != 77:
		_fail("Character replacement did not preserve level experience")
		return false
	if yuki.score != 4 or yuki.respawn_count != 3 or not is_equal_approx(yuki.match_pressure, 1.6):
		_fail("Character replacement did not preserve match state")
		return false
	if not is_equal_approx(yuki.hp / yuki.max_hp, 0.4):
		_fail("Character replacement did not preserve HP ratio")
		return false
	return true

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
