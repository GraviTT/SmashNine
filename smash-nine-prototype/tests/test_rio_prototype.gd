extends SceneTree
## Rio (character #5): two air jumps capped at three with Sky Step, the mana wave on the
## third J, the dimension slash teleport (once in the air), the rune shield (absorbs
## knockback, throws it back; a whiff is punished), the six gem swords, and the bot aim
## used to recover with K.

const MAIN_SCRIPT := preload("res://scripts/Main.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const SOUL_CARDS := preload("res://scripts/match/SoulCards.gd")
const ATTACK_PATH := "res://scripts/Attack.gd"
const PROJECTILE_PATH := "res://scripts/Projectile.gd"

var arena: Node2D
var main: Node
var rio_data: Dictionary
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	main = MAIN_SCRIPT.new()
	rio_data = CHARACTER_REGISTRY.get_characters()["rio"]
	for test in [_test_air_jumps, _test_mana_wave, _test_dimension_slash, _test_rune_shield, _test_rune_whiff, _test_overdrive, _test_bot_recovery_aim]:
		await test.call()
		if failed:
			quit(1)
			return
	print("Rio prototype tests passed")
	arena.queue_free()
	await process_frame
	main.free()
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _create_rio(player_id: int, body := "male") -> Node:
	var rio: Node = PLAYER_FACTORY.create("rio", body)
	arena.add_child(rio)
	rio.global_position = Vector2(player_id * 2200.0, 0.0)
	rio.setup(rio_data, player_id, false)
	rio.ringout_y = 100000.0
	rio.set_physics_process(false)
	return rio

func _create_dummy(player_id: int, at: Vector2) -> Node:
	var dummy: Node = PLAYER_FACTORY.create("")
	arena.add_child(dummy)
	dummy.global_position = at
	dummy.setup_dummy(player_id)
	dummy.set_physics_process(false)
	return dummy

func _count_owned(path: String, owner: Node) -> int:
	var count := 0
	for node in arena.get_children():
		if node.get_script() != null and node.get_script().resource_path == path and node.get("source") == owner:
			count += 1
	return count

func _test_air_jumps() -> void:
	var rio := _create_rio(1)
	if rio.max_air_jumps != 2 or rio.body_type != "male":
		_fail("Rio should start with 2 air jumps and the chosen body (got %d, %s)" % [rio.max_air_jumps, rio.body_type])
		return
	var sky_step: Dictionary = {}
	for card in SOUL_CARDS.CARDS:
		if card.id == "sky_step":
			sky_step = card
	rio.apply_upgrade(sky_step)
	rio.apply_upgrade(sky_step)
	if rio.max_air_jumps != 3:
		_fail("Rio air jumps with two Sky Steps should cap at 3, got %d" % rio.max_air_jumps)
	rio.queue_free()

func _test_mana_wave() -> void:
	var rio := _create_rio(2)
	for swing in 3:
		rio.attack_lock_timer = 0.0
		rio.perform_basic_attack("neutral", Vector2.RIGHT)
		await create_timer(0.12).timeout
	if _count_owned(PROJECTILE_PATH, rio) != 1:
		_fail("Rio's third J should throw one mana wave")
	rio.queue_free()
	await create_timer(0.3).timeout

func _test_dimension_slash() -> void:
	var rio := _create_rio(3)
	var start: Vector2 = rio.global_position
	rio.perform_skill_one()
	await create_timer(0.1).timeout
	var moved: float = rio.global_position.x - start.x
	if absf(moved - 200.0) > 1.0:
		_fail("Dimension slash should teleport 200 px forward, moved %.1f" % moved)
		return
	if _count_owned(ATTACK_PATH, rio) < 1:
		_fail("Dimension slash should cut along its path")
		return
	if rio.air_blink_available:
		_fail("An aerial dimension slash should use up the air blink")
		return
	rio.attack_lock_timer = 0.0
	var before: Vector2 = rio.global_position
	rio.perform_skill_one()
	await create_timer(0.1).timeout
	if rio.global_position != before:
		_fail("A second aerial dimension slash should not teleport")
	rio.queue_free()

func _test_rune_shield() -> void:
	var rio := _create_rio(4)
	var attacker := _create_dummy(40, rio.global_position + Vector2(-80, 0))
	var plain := _create_rio(5)
	plain.apply_hit(attacker, 20.0, 600.0, Vector2.RIGHT)
	var plain_loss: float = plain.max_hp - plain.hp
	rio.perform_skill_two()
	rio.apply_hit(attacker, 20.0, 600.0, Vector2.RIGHT)
	var shield_loss: float = rio.max_hp - rio.hp
	if rio.knockback_velocity.length() > 0.01 or rio.hitstun_timer > 0.0:
		_fail("Rune shield should take the hit without knockback or hitstun")
		return
	if absf(shield_loss - plain_loss * 0.5) > 0.01:
		_fail("Rune shield should halve the damage (%.2f vs %.2f)" % [shield_loss, plain_loss])
		return
	if rio.facing != -1:
		_fail("Rune shield should turn Rio toward the attacker")
		return
	var attacks_before := _count_owned(ATTACK_PATH, rio)
	await create_timer(0.56).timeout
	var returned: Node = null
	for node in arena.get_children():
		if node.get_script() != null and node.get_script().resource_path == ATTACK_PATH and node.get("source") == rio:
			returned = node
	if _count_owned(ATTACK_PATH, rio) <= attacks_before or returned == null or returned.knockback <= 320.0:
		_fail("Rune shield should throw the absorbed hit back as a stronger shockwave")
	rio.queue_free()
	plain.queue_free()
	attacker.queue_free()
	await create_timer(0.2).timeout

func _test_rune_whiff() -> void:
	var rio := _create_rio(6)
	rio.perform_skill_two()
	await create_timer(0.56).timeout
	if _count_owned(ATTACK_PATH, rio) != 0 or rio.attack_lock_timer < 0.2:
		_fail("An empty rune shield should not attack and should leave Rio open")
	rio.perform_skill_two()
	if rio.rune_timer > 0.0:
		_fail("Rune shield should be on cooldown")
	rio.queue_free()

func _test_overdrive() -> void:
	var rio := _create_rio(7)
	var target := _create_dummy(70, rio.global_position + Vector2(300, -32))
	rio.perform_ultimate()
	await process_frame
	if rio.overdrive_swords.size() != 6:
		_fail("Infinity Overdrive should summon 6 gem swords, got %d" % rio.overdrive_swords.size())
		return
	await create_timer(0.4).timeout
	if _count_owned(PROJECTILE_PATH, rio) != 0:
		_fail("Gem swords should orbit before firing")
		return
	# Orbit ends at 0.55 s, then one sword every 0.07 s.
	await create_timer(0.6).timeout
	if not rio.overdrive_swords.is_empty() or target.hp >= target.max_hp:
		_fail("All gem swords should fire and hit the nearest opponent (left %d, target hp %.0f)" % [rio.overdrive_swords.size(), target.hp])
	rio.queue_free()
	target.queue_free()

func _test_bot_recovery_aim() -> void:
	var rio := _create_rio(8)
	rio.ai_controller.aim_direction = Vector2(0.6, -0.8)
	var direction: Vector2 = rio._get_late_skill_direction()
	if direction.distance_to(Vector2(0.6, -0.8)) > 0.01:
		_fail("Bots should aim directed skills with the AI aim direction")
	rio.queue_free()
