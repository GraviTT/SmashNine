extends Node
## Slot deadlines survive sync calls: realm refreshes cannot bypass refill pacing.
signal announcement(text: String)
const LANGUAGE := preload("res://scripts/Language.gd")
const MONSTER_SCRIPT := preload("res://scripts/RealmMonster.gd")
const REALM_CATALOG := preload("res://scripts/realms/RealmCatalog.gd")
const MONSTERS_PER_REALM := 4
const CENTRAL_MONSTERS_PER_REALM := 3
const RESPAWN_MIN := 12.0
const RESPAWN_MAX := 18.0
const ELITE_MIN := 70.0
const ELITE_MAX := 90.0
var spawn_points_provider: Callable
var playable_realm_provider: Callable
var phase_provider: Callable
var monsters_by_realm: Dictionary = {}
var realm_profiles: Array = REALM_CATALOG.build_maps()
var slots_by_realm: Dictionary = {}
var refill_at_by_realm: Dictionary = {}
var elite_by_realm: Dictionary = {}
var elite_due: Dictionary = {}
var elapsed := 0.0
var ecology_rng := RandomNumberGenerator.new()
var population_started := false
var pending_announcements: Array[Dictionary] = []
var announcement_timer := 0.0

func _init() -> void:
	LANGUAGE.load_saved()

func configure(new_spawn_points_provider: Callable, new_playable_realm_provider: Callable, new_phase_provider := Callable(), match_seed := 0) -> void:
	spawn_points_provider = new_spawn_points_provider
	playable_realm_provider = new_playable_realm_provider
	phase_provider = new_phase_provider
	ecology_rng.seed = match_seed + 73019

func _phase() -> String:
	return str(phase_provider.call()) if phase_provider.is_valid() else "Exploration"

func _population_limit() -> int:
	return CENTRAL_MONSTERS_PER_REALM if _phase() in ["Central brawl", "Sudden death", "Match over"] else MONSTERS_PER_REALM

func _elites_enabled() -> bool:
	return _phase() in ["Corner collapse warning", "Convergence", "Central brawl", "Sudden death"]

func _physics_process(delta: float) -> void:
	if not population_started or not playable_realm_provider.is_valid() or _phase() == "Match over":
		return
	elapsed += delta
	announcement_timer = maxf(announcement_timer - delta, 0.0)
	if announcement_timer <= 0.0 and not pending_announcements.is_empty():
		while not pending_announcements.is_empty():
			var pending: Dictionary = pending_announcements.pop_front()
			if not is_instance_valid(pending.monster) or pending.monster.hp <= 0.0:
				continue
			announcement.emit(str(pending.message))
			announcement_timer = 2.8
			break
	var playable: Array[int] = []
	for index in playable_realm_provider.call():
		playable.append(int(index))
	sync_playable_realms(playable)

func sync_playable_realms(playable_realms: Array[int]) -> void:
	population_started = true
	for realm_index in monsters_by_realm.keys():
		if not playable_realms.has(realm_index):
			_clear_realm(realm_index)
	if _phase() == "Match over":
		return
	for realm_index in playable_realms:
		_spawn_missing_for_realm(realm_index)
		if _elites_enabled():
			_try_spawn_elite(realm_index)

func _spawn_missing_for_realm(realm_index: int) -> void:
	if not spawn_points_provider.is_valid():
		return
	if not slots_by_realm.has(realm_index):
		slots_by_realm[realm_index] = [null, null, null, null]
		refill_at_by_realm[realm_index] = [0.0, 0.0, 0.0, 0.0]
		monsters_by_realm[realm_index] = []
	var slots: Array = slots_by_realm[realm_index]
	var deadlines: Array = refill_at_by_realm[realm_index]
	var limit := _population_limit()
	for slot in range(limit, MONSTERS_PER_REALM):
		if is_instance_valid(slots[slot]):
			monsters_by_realm[realm_index].erase(slots[slot])
			slots[slot].set_realm_active(false)
			slots[slot].queue_free()
			slots[slot] = null
	for slot in limit:
		if is_instance_valid(slots[slot]) or elapsed < float(deadlines[slot]):
			continue
		var monster := _spawn_monster(realm_index, slot, false)
		if monster != null:
			slots[slot] = monster

func _spawn_monster(realm_index: int, slot: int, elite: bool) -> Node:
	var points: Array = spawn_points_provider.call(realm_index)
	if points.is_empty():
		return null
	var kind := "melee" if slot % 2 == 0 else "ranged"
	var type_id := "mossling" if kind == "melee" else "ember_imp"
	var skin_id := _skin_for_realm_kind(realm_index, kind)
	var point := _choose_spawn_point(realm_index, points)
	var monster := CharacterBody2D.new()
	monster.set_script(MONSTER_SCRIPT)
	monster.setup(type_id, realm_index, point, skin_id)
	monster.spawn_slot = slot
	if elite:
		monster.make_elite()
	get_parent().add_child(monster)
	monster.defeated.connect(_on_monster_defeated.bind(realm_index))
	monsters_by_realm[realm_index].append(monster)
	return monster

func _choose_spawn_point(realm_index: int, points: Array) -> Vector2:
	var start := ecology_rng.randi_range(0, points.size() - 1)
	var best_point: Vector2 = points[start]
	var best_clearance := -1.0
	for offset in points.size():
		var point: Vector2 = points[(start + offset) % points.size()]
		var clearance := INF
		for other in monsters_by_realm.get(realm_index, []):
			if is_instance_valid(other) and other.hp > 0.0:
				clearance = minf(clearance, point.distance_to(other.global_position))
		if clearance >= 120.0:
			return point
		if clearance > best_clearance:
			best_clearance = clearance
			best_point = point
	return best_point

func _try_spawn_elite(realm_index: int) -> void:
	if is_instance_valid(elite_by_realm.get(realm_index)):
		return
	if elapsed < float(elite_due.get(realm_index, 0.0)):
		return
	var elite := _spawn_monster(realm_index, ecology_rng.randi_range(0, 1), true)
	if elite == null:
		return
	elite_by_realm[realm_index] = elite
	var realm_name := str(realm_profiles[realm_index].name)
	var message := tr("An elite %s rises in %s") % [tr(elite.display_name.trim_prefix("Elite ")), tr(realm_name)]
	if announcement_timer <= 0.0 and pending_announcements.is_empty():
		announcement.emit(message)
		announcement_timer = 2.8
	else:
		pending_announcements.append({"realm": realm_index, "monster": elite, "message": message})

func _skin_for_realm_kind(realm_index: int, kind: String) -> String:
	var generic := "mossling" if kind == "melee" else "ember_imp"
	if realm_index < 0 or realm_index >= realm_profiles.size():
		return generic
	var monsters: Dictionary = realm_profiles[realm_index].get("monsters", {})
	return str(monsters.get(kind, generic))

func _clear_realm(realm_index: int) -> void:
	pending_announcements = pending_announcements.filter(func(pending: Dictionary) -> bool: return int(pending.realm) != realm_index)
	for monster in monsters_by_realm.get(realm_index, []):
		if is_instance_valid(monster):
			monster.set_realm_active(false)
			monster.queue_free()
	monsters_by_realm.erase(realm_index)
	slots_by_realm.erase(realm_index)
	refill_at_by_realm.erase(realm_index)
	elite_by_realm.erase(realm_index)
	elite_due.erase(realm_index)

func _on_monster_defeated(monster: Node, attacker: Node, soul_reward: int, realm_index: int) -> void:
	if is_instance_valid(attacker) and attacker.has_method("add_souls"):
		attacker.add_souls(soul_reward)
	if not monsters_by_realm.has(realm_index):
		return
	monsters_by_realm[realm_index].erase(monster)
	if monster.is_elite:
		elite_by_realm.erase(realm_index)
		elite_due[realm_index] = elapsed + ecology_rng.randf_range(ELITE_MIN, ELITE_MAX)
	else:
		var slot: int = monster.spawn_slot
		slots_by_realm[realm_index][slot] = null
		refill_at_by_realm[realm_index][slot] = elapsed + ecology_rng.randf_range(RESPAWN_MIN, RESPAWN_MAX)

func _try_respawn_realm(realm_index: int) -> void:
	if playable_realm_provider.is_valid() and playable_realm_provider.call().has(realm_index):
		_spawn_missing_for_realm(realm_index)

func get_monster_count(realm_index := -1) -> int:
	var count := 0
	for key in monsters_by_realm:
		if realm_index >= 0 and key != realm_index:
			continue
		for monster in monsters_by_realm[key]:
			if is_instance_valid(monster) and not monster.is_queued_for_deletion() and monster.hp > 0.0:
				count += 1
	return count
