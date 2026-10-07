extends Node
## One soul crystal per playable realm, over a seeded random spawn point; a broken one
## comes back after RESPAWN_DELAY while its realm is still playable. The breaker gets
## the crystal's souls (concept panel 9: "소울 크리스탈 파괴").

const CRYSTAL_SCRIPT := preload("res://scripts/SoulCrystal.gd")
const RESPAWN_DELAY := 25.0

var spawn_points_provider: Callable
var playable_realm_provider: Callable
var crystals: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func configure(new_spawn_points_provider: Callable, new_playable_realm_provider: Callable, match_seed: int) -> void:
	spawn_points_provider = new_spawn_points_provider
	playable_realm_provider = new_playable_realm_provider
	_rng.seed = hash([match_seed, "soul_crystals"])

func sync_playable_realms(playable_realms: Array[int]) -> void:
	for realm_index in crystals.keys():
		if not playable_realms.has(realm_index):
			if is_instance_valid(crystals[realm_index]):
				# Off right away: a crystal queued for deletion must not pay this frame.
				crystals[realm_index].set_realm_active(false)
				crystals[realm_index].queue_free()
			crystals.erase(realm_index)
	for realm_index in playable_realms:
		_spawn(realm_index)

func get_crystal(realm_index: int) -> Node:
	var crystal: Variant = crystals.get(realm_index)
	return crystal if is_instance_valid(crystal) and not crystal.is_queued_for_deletion() else null

func _spawn(realm_index: int) -> void:
	if get_crystal(realm_index) != null or not spawn_points_provider.is_valid():
		return
	var points: Array = spawn_points_provider.call(realm_index)
	if points.is_empty():
		return
	var crystal := CharacterBody2D.new()
	crystal.set_script(CRYSTAL_SCRIPT)
	crystal.setup(realm_index, points[_rng.randi_range(0, points.size() - 1)])
	get_parent().add_child(crystal)
	crystal.broken.connect(_on_broken.bind(realm_index))
	crystals[realm_index] = crystal

func _on_broken(_crystal: Node, attacker: Node, realm_index: int) -> void:
	if is_instance_valid(attacker) and attacker.has_method("add_souls"):
		attacker.add_souls(CRYSTAL_SCRIPT.SOUL_REWARD)
	crystals.erase(realm_index)
	get_tree().create_timer(RESPAWN_DELAY).timeout.connect(_respawn.bind(realm_index))

func _respawn(realm_index: int) -> void:
	if playable_realm_provider.is_valid() and playable_realm_provider.call().has(realm_index):
		_spawn(realm_index)
