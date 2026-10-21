extends SceneTree
## Realm gimmicks added in the 2026-10-22 night routine: Svartalfheim forge belts carry grounded
## fighters standing on them and reverse after a warning; Alfheim moon gates open after a shimmer
## and carry a fighter touching one to the other, and a fighter must step out of the exit gate
## before it takes them back; nothing runs in a realm that is not playable.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const REALM_HAZARDS := preload("res://scripts/realms/RealmHazards.gd")
const STEP := 1.0 / 60.0

var arena: Node2D
var layout: RefCounted
var realm_state := "stable"
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	layout = REALM_LAYOUT.new()
	await _test_belts_carry_and_reverse()
	await _test_belts_stop_when_unplayable()
	await _test_gates_carry_once()
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Realm gimmick tests passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _realm(realm_name: String) -> int:
	for i in layout.realm_count():
		if layout.get_realm(i).name == realm_name:
			return i
	return -1

func _new_hazards() -> Node:
	var hazards: Node = REALM_HAZARDS.new()
	arena.add_child(hazards)
	hazards.setup(layout, func(_realm_index: int) -> String: return realm_state, 7)
	return hazards

## A dummy standing on a floor laid along the belt's top edge.
func _fighter_on(rect: Rect2, realm_index: int) -> Node:
	var floor := StaticBody2D.new()
	floor.collision_layer = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(rect.size.x, 40)
	shape.shape = box
	floor.add_child(shape)
	arena.add_child(floor)
	floor.global_position = Vector2(rect.get_center().x, rect.position.y + 20)
	var fighter: Node = PLAYER_FACTORY.create("frey")
	arena.add_child(fighter)
	fighter.setup(CHARACTER_REGISTRY.get_characters()["frey"], 1, false)
	fighter.is_dummy = true
	fighter.ringout_y = 100000.0
	layout.assign_combatant(fighter, realm_index)
	fighter.global_position = Vector2(rect.get_center().x, rect.position.y - 2)
	return fighter

func _test_belts_carry_and_reverse() -> void:
	realm_state = "stable"
	var hazards := _new_hazards()
	var realm := _realm("Svartalfheim")
	var belts: Array = hazards.get_belts(realm)
	if belts.size() != 3:
		_fail("Svartalfheim should have three forge belts (got %d)" % belts.size())
		return
	var fighter := _fighter_on(belts[0], realm)
	hazards.register_combatant(fighter)
	for frame in 20:
		await physics_frame
	var start_x: float = fighter.global_position.x
	var direction: float = hazards.get_belt_direction(realm)
	for frame in 30:
		await physics_frame
		hazards.advance(STEP)
	var moved: float = fighter.global_position.x - start_x
	if signf(moved) != direction or absf(absf(moved) - 45.0) > 12.0:
		_fail("Half a second on a 90 px/s belt should carry a fighter about 45 px its way (moved %.1f, belt %.0f)" % [moved, direction])
	hazards.trigger(realm)
	for frame in 80:
		hazards.advance(STEP)
	if hazards.get_belt_direction(realm) != -direction:
		_fail("After the warning the belts should run the other way")
	fighter.queue_free()
	hazards.queue_free()
	await process_frame

func _test_belts_stop_when_unplayable() -> void:
	realm_state = "collapsed"
	var hazards := _new_hazards()
	var realm := _realm("Svartalfheim")
	var fighter := _fighter_on(hazards.get_belts(realm)[1], realm)
	hazards.register_combatant(fighter)
	for frame in 20:
		await physics_frame
	var start_x: float = fighter.global_position.x
	for frame in 30:
		await physics_frame
		hazards.advance(STEP)
	if absf(fighter.global_position.x - start_x) > 0.5:
		_fail("Belts in a realm that is not playable should not carry anyone (moved %.1f)" % (fighter.global_position.x - start_x))
	fighter.queue_free()
	hazards.queue_free()
	realm_state = "stable"
	await process_frame

func _test_gates_carry_once() -> void:
	realm_state = "stable"
	var hazards := _new_hazards()
	var realm := _realm("Alfheim")
	hazards.trigger(realm)
	for frame in 80:
		hazards.advance(STEP)
	var gates: Array = hazards.get_gates(realm)
	if gates.size() != 2 or (gates[0] as Vector2).distance_to(gates[1]) < 420.0:
		_fail("Two moon gates at least 420 px apart should be open after the shimmer (got %s)" % [gates])
		return
	var fighter: Node = PLAYER_FACTORY.create("luna")
	arena.add_child(fighter)
	fighter.setup(CHARACTER_REGISTRY.get_characters()["luna"], 2, false)
	fighter.set_physics_process(false)
	layout.assign_combatant(fighter, realm)
	hazards.register_combatant(fighter)
	fighter.global_position = gates[0]
	hazards.advance(STEP)
	if (fighter.global_position as Vector2).distance_to(gates[1]) > 6.0:
		_fail("Touching a moon gate should carry the fighter to the other gate (at %s, exit %s)" % [fighter.global_position, gates[1]])
	# Standing in the exit gate past the cooldown does not send them back.
	for frame in 90:
		hazards.advance(STEP)
	if (fighter.global_position as Vector2).distance_to(gates[1]) > 6.0:
		_fail("A fighter standing in the exit gate should stay until they step out")
	# Out, then in again: carried back.
	fighter.global_position = (gates[1] as Vector2) + Vector2(200, 0)
	hazards.advance(STEP)
	fighter.global_position = gates[1]
	hazards.advance(STEP)
	if (fighter.global_position as Vector2).distance_to(gates[0]) > 6.0:
		_fail("After stepping out, entering the gate again should carry the fighter back")
	fighter.queue_free()
	hazards.queue_free()
	await process_frame
