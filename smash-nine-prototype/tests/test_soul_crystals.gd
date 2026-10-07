extends SceneTree
## Soul crystals: one per playable realm, three fighter hits break one and pay its souls
## to the breaker, hits from no one (environment) do not count, a broken crystal comes
## back after the delay, a realm that stops being playable loses its crystal, and bots
## treat a standing crystal as a target.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const SPAWNER_SCRIPT := preload("res://scripts/SoulCrystalSpawner.gd")
const CRYSTAL_SCRIPT := preload("res://scripts/SoulCrystal.gd")

var arena: Node2D
var layout: RefCounted
var playable: Array[int] = []
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	layout = REALM_LAYOUT.new()
	playable.assign(layout.get_corner_indices())
	var spawner: Node = SPAWNER_SCRIPT.new()
	arena.add_child(spawner)
	spawner.configure(Callable(layout, "get_spawn_points"), func() -> Array[int]: return playable, 7)
	spawner.sync_playable_realms(playable)
	await process_frame
	var realm_index: int = playable[0]
	if get_nodes_in_group("soul_crystals").size() != playable.size() or spawner.get_crystal(realm_index) == null:
		_fail("Expected one crystal per playable realm, got %d" % get_nodes_in_group("soul_crystals").size())
	var crystal: Node = spawner.get_crystal(realm_index)
	# Regression (12:45): a crystal floating at a spawn point could not be reached by a
	# grounded swing (about 34 px above feet on a floor 54-80 px below), so bots swung forever.
	var collision: CollisionShape2D = crystal.get_child(0)
	var hitbox := Rect2(collision.position - collision.shape.size * 0.5, collision.shape.size)
	for floor_depth in [54.0, 80.0]:
		if not failed and not hitbox.has_point(Vector2(0.0, floor_depth - 34.0)):
			_fail("A grounded swing %.0f px below the crystal should reach it" % floor_depth)
	var fighter: Node = PLAYER_FACTORY.create("frey")
	arena.add_child(fighter)
	fighter.setup(CHARACTER_REGISTRY.get_characters()["frey"], 1, false)
	fighter.set_physics_process(false)
	layout.assign_combatant(fighter, realm_index)
	# Regression (CODEX-ANALYST-03 P1): a real sweeping swing from the floor below must crack
	# it; as a StaticBody2D the moving attack area never registered the crystal.
	fighter.global_position = crystal.global_position + Vector2(-40, 60)
	fighter.facing = 1
	fighter.perform_basic_attack("neutral", Vector2.RIGHT)
	for frame in 30:
		await physics_frame
	if not failed and crystal.hp != float(CRYSTAL_SCRIPT.HITS_TO_BREAK - 1):
		_fail("A real grounded swing should crack the crystal once (hp %.0f)" % crystal.hp)
	crystal.hp = float(CRYSTAL_SCRIPT.HITS_TO_BREAK)
	fighter.global_position = crystal.global_position + Vector2(-120, 0)
	if not failed and not fighter.ai_controller._is_valid_target_candidate(fighter, crystal):
		_fail("Bots should see a standing crystal in their realm as a target")
	if not failed and crystal.apply_hit(null, 5.0, 100.0, Vector2.RIGHT):
		_fail("A hit from no one should not crack a crystal")
	var souls_before: int = fighter.souls
	for hit in CRYSTAL_SCRIPT.HITS_TO_BREAK:
		if not failed and not crystal.apply_hit(fighter, 5.0, 100.0, Vector2.RIGHT):
			_fail("A fighter's hit should land on the crystal")
	await process_frame
	if not failed and (fighter.souls - souls_before != CRYSTAL_SCRIPT.SOUL_REWARD or spawner.get_crystal(realm_index) != null):
		_fail("Three hits should break the crystal and pay %d souls (got %d)" % [CRYSTAL_SCRIPT.SOUL_REWARD, fighter.souls - souls_before])
	if not failed:
		await create_timer(SPAWNER_SCRIPT.RESPAWN_DELAY + 0.2).timeout
		if spawner.get_crystal(realm_index) == null:
			_fail("A broken crystal should come back after %.0f s" % SPAWNER_SCRIPT.RESPAWN_DELAY)
	if not failed:
		playable.erase(realm_index)
		spawner.sync_playable_realms(playable)
		await process_frame
		if spawner.get_crystal(realm_index) != null:
			_fail("A realm that is no longer playable should lose its crystal")
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Soul crystal tests passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	failed = true
