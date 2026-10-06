extends Node
## Keeps a small neutral monster population in every playable realm (design D7)
## and pays souls to whoever finishes a monster.

const MONSTER_SCRIPT := preload("res://scripts/RealmMonster.gd")
const MONSTERS_PER_REALM := 4
const RESPAWN_DELAY := 20.0

var spawn_points_provider: Callable
var playable_realm_provider: Callable
var monsters_by_realm: Dictionary = {}

func configure(new_spawn_points_provider: Callable, new_playable_realm_provider: Callable) -> void:
	spawn_points_provider = new_spawn_points_provider
	playable_realm_provider = new_playable_realm_provider

func sync_playable_realms(playable_realms: Array[int]) -> void:
	for realm_index in monsters_by_realm.keys():
		if not playable_realms.has(realm_index):
			_clear_realm(realm_index)
	for realm_index in playable_realms:
		_spawn_missing_for_realm(realm_index)

func _spawn_missing_for_realm(realm_index: int) -> void:
	var monsters: Array = monsters_by_realm.get(realm_index, [])
	monsters = monsters.filter(func(monster: Variant) -> bool: return is_instance_valid(monster) and not monster.is_queued_for_deletion())
	monsters_by_realm[realm_index] = monsters
	if monsters.size() >= MONSTERS_PER_REALM or not spawn_points_provider.is_valid():
		return
	var points: Array = spawn_points_provider.call(realm_index).duplicate()
	if points.is_empty():
		return
	points.shuffle()
	while monsters.size() < MONSTERS_PER_REALM:
		var type_id := "mossling" if monsters.size() % 2 == 0 else "ember_imp"
		var point: Vector2 = points[monsters.size() % points.size()]
		var monster := CharacterBody2D.new()
		monster.set_script(MONSTER_SCRIPT)
		monster.setup(type_id, realm_index, point)
		get_parent().add_child(monster)
		monster.defeated.connect(_on_monster_defeated.bind(realm_index))
		monsters.append(monster)
	monsters_by_realm[realm_index] = monsters

func _clear_realm(realm_index: int) -> void:
	for monster in monsters_by_realm.get(realm_index, []):
		if is_instance_valid(monster):
			monster.queue_free()
	monsters_by_realm.erase(realm_index)

func _on_monster_defeated(monster: Node, attacker: Node, soul_reward: int, realm_index: int) -> void:
	if is_instance_valid(attacker) and attacker.has_method("add_souls"):
		attacker.add_souls(soul_reward)
	var monsters: Array = monsters_by_realm.get(realm_index, [])
	monsters.erase(monster)
	monsters_by_realm[realm_index] = monsters
	var timer := get_tree().create_timer(RESPAWN_DELAY)
	timer.timeout.connect(_try_respawn_realm.bind(realm_index))

func _try_respawn_realm(realm_index: int) -> void:
	if not playable_realm_provider.is_valid():
		return
	var playable_realms: Array = playable_realm_provider.call()
	if playable_realms.has(realm_index):
		_spawn_missing_for_realm(realm_index)

func get_monster_count(realm_index := -1) -> int:
	var count := 0
	for key in monsters_by_realm:
		if realm_index >= 0 and key != realm_index:
			continue
		for monster in monsters_by_realm[key]:
			if is_instance_valid(monster) and not monster.is_queued_for_deletion():
				count += 1
	return count
