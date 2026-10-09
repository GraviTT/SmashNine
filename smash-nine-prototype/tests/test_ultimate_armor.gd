extends SceneTree
## Super armor right after an ultimate starts (user 2026-10-10: ultimates were cut off by a basic
## hit in brawls): a hit in the first ULTIMATE_ARMOR_TIME deals its damage but no knockback, no
## hitstun and no cancel; after it, hits interrupt as before. Rio's own rune absorption stays
## separate. Only a follow-up press that starts a new stage renews the armor: mashing the key
## during Brave Luna or Nova's launch does not keep it up.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	await _test_nova_slingshot_armor()
	await _test_frey_dive_armor()
	await _test_mashing_keeps_no_armor()
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Ultimate armor tests passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _fighter(character_id: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = true
	return fighter

## Nova's slingshot used to be cancelled by any hit (character_on_hit -> _cancel_ultimate).
func _test_nova_slingshot_armor() -> void:
	var nova := _fighter("nova", 1, Vector2(0, -400))
	var foe := _fighter("frey", 2, Vector2(60, -400))
	await physics_frame
	nova.ultimate()
	if int(nova.ultimate_phase) == 0:
		_fail("Test setup: Nova's ultimate should start")
		return
	var hp_before: float = nova.hp
	nova.apply_hit(foe, 6.0, 380.0, Vector2(-1, -0.2))
	if int(nova.ultimate_phase) == 0:
		_fail("A basic hit right after Nova's ultimate starts should not cancel it")
	if float(nova.hitstun_timer) > 0.0 or nova.knockback_velocity.length() > 1.0:
		_fail("A hit in the ultimate's super armor should cause no hitstun or knockback (hitstun %.2f, knockback %.0f)" % [nova.hitstun_timer, nova.knockback_velocity.length()])
	if float(nova.hp) >= hp_before:
		_fail("A hit in the super armor should still deal its damage")
	# After the armor: a hit interrupts as before.
	for frame in int(ceil((nova.ULTIMATE_ARMOR_TIME + 0.1) * 60.0)):
		await physics_frame
	nova.knockback_velocity = Vector2.ZERO
	nova.apply_hit(foe, 6.0, 380.0, Vector2(-1, -0.2))
	if float(nova.hitstun_timer) <= 0.0:
		_fail("Once the super armor is over, a hit should cause hitstun again")
	nova.queue_free()
	foe.queue_free()
	await process_frame

## Mashing I used to renew the armor on every press while Luna was transformed (her follow-up
## press is consumed even when no laser starts) and through Nova's launch.
func _test_mashing_keeps_no_armor() -> void:
	var luna := _fighter("luna", 1, Vector2(0, -400))
	luna.set_physics_process(false)
	luna._enter_transformation()
	luna.ultimate_armor_timer = 0.0
	luna.attack_lock_timer = 0.3
	luna.ultimate()
	if float(luna.ultimate_armor_timer) > 0.0:
		_fail("A Brave Luna press that starts no heart laser (she is mid-attack) should not renew the armor")
	luna.attack_lock_timer = 0.0
	luna.ultimate()
	if float(luna.ultimate_armor_timer) <= 0.0:
		_fail("The press that starts Luna's heart laser should renew the armor")
	luna.ultimate_armor_timer = 0.0
	luna.ultimate()
	if float(luna.ultimate_armor_timer) > 0.0:
		_fail("Pressing again during the heart laser should not renew the armor")
	luna.queue_free()
	var nova := _fighter("nova", 2, Vector2(400, -400))
	nova.set_physics_process(false)
	nova.ultimate()
	nova.ultimate()
	nova.ultimate()
	if int(nova.ultimate_phase) == 0:
		_fail("Test setup: Nova's slingshot should still be running after its three presses")
	nova.ultimate_armor_timer = 0.0
	nova.ultimate()
	if float(nova.ultimate_armor_timer) > 0.0:
		_fail("Pressing again during Nova's launch should not renew the armor")
	nova.queue_free()
	await process_frame

## Frey's air ultimate dive used to stop on any hit (character_on_hit -> ultimate_diving = false).
func _test_frey_dive_armor() -> void:
	var frey := _fighter("frey", 1, Vector2(0, -600))
	var foe := _fighter("luna", 2, Vector2(60, -600))
	await physics_frame
	frey.ultimate()
	for frame in 3:
		await physics_frame
	if not bool(frey.ultimate_diving):
		_fail("Test setup: Frey's air ultimate should dive")
		return
	frey.apply_hit(foe, 6.0, 380.0, Vector2(-1, -0.2))
	if not bool(frey.ultimate_diving):
		_fail("A basic hit right after Frey's ultimate starts should not stop her dive")
	frey.queue_free()
	foe.queue_free()
	await process_frame
