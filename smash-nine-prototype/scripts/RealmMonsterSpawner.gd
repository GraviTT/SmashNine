extends Node

const MONSTER_SCRIPT := preload("res://scripts/RealmMonster.gd")
const REALM_TILE_COUNT := 9
const MONSTERS_PER_TILE := 2
const MONSTERS_PER_REALM := REALM_TILE_COUNT * MONSTERS_PER_TILE
const RESPAWN_DELAY := 7.0

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
	monsters = monsters.filter(func(monster: Node) -> bool: return is_instance_valid(monster) and not monster.is_queued_for_deletion())
	monsters_by_realm[realm_index] = monsters
	if monsters.size() >= MONSTERS_PER_REALM or not spawn_points_provider.is_valid():
		return
	var points: Array = spawn_points_provider.call(realm_index)
	if points.is_empty():
		return
	points = _build_distributed_spawn_points(points)
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

func _build_distributed_spawn_points(all_points: Array) -> Array:
	if all_points.size() < REALM_TILE_COUNT:
		all_points.shuffle()
		return all_points
	var distributed: Array = []
	var points_per_tile := all_points.size() / REALM_TILE_COUNT
	for tile_index in REALM_TILE_COUNT:
		var tile_points: Array = []
		var first_index := tile_index * points_per_tile
		for point_index in points_per_tile:
			tile_points.append(all_points[first_index + point_index])
		tile_points.shuffle()
		for spawn_index in mini(MONSTERS_PER_TILE, tile_points.size()):
			distributed.append(tile_points[spawn_index])
	return distributed

func _clear_realm(realm_index: int) -> void:
	for monster in monsters_by_realm.get(realm_index, []):
		if is_instance_valid(monster):
			monster.queue_free()
	monsters_by_realm.erase(realm_index)

func _on_monster_defeated(monster: Node, attacker: Node, experience_reward: int, realm_index: int) -> void:
	if is_instance_valid(attacker) and attacker.has_method("add_experience"):
		attacker.add_experience(experience_reward)
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
