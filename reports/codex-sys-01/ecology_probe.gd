extends SceneTree
## Read-only integration telemetry. Does not replace the required unmodified soak.
var main: Node
var seed_value := 1001
var player_count := 8
var seen: Dictionary = {}
var by_skin: Dictionary = {}
var last_regular_defeat: Dictionary = {}
var last_elite_defeat: Dictionary = {}
var refill_intervals: Array[float] = []
var elite_intervals: Array[float] = []
var elite_spawns: Array[Dictionary] = []
var violations: Array[String] = []
var monster_hits := {"regular": 0, "elite": 0}
var monster_eliminations := {"regular": 0, "elite": 0}
var announcements: Array[String] = []
var peak_living_monsters := 0
var peak_projectiles := 0
var monster_fallouts := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			seed_value = int(arg.get_slice("=", 1))
		if arg.begins_with("--players="):
			player_count = int(arg.get_slice("=", 1))
	call_deferred("_run")

func _run() -> void:
	seed(seed_value)
	main = load("res://scenes/Main.tscn").instantiate()
	main.bots_only = true
	main.match_seed = seed_value
	main.player_count = player_count
	root.add_child(main)
	await process_frame
	main.realm_monster_spawner.announcement.connect(func(message: String) -> void: announcements.append(message))
	for fighter in main.players:
		fighter.damaged.connect(_on_damaged)
		fighter.defeated.connect(_on_fighter_defeated)
	for frame in 480 * 60:
		await physics_frame
		_sample()
		if main.match_over:
			break
	var result := {
		"seed": seed_value, "players": player_count,
		"seconds": snappedf(main.director.match_elapsed, 0.1), "match_over": main.match_over,
		"by_skin": by_skin, "elite_spawns": elite_spawns,
		"monster_hits": monster_hits, "monster_eliminations": monster_eliminations,
		"refill_intervals": refill_intervals, "elite_intervals": elite_intervals,
		"peak_living_monsters": peak_living_monsters, "peak_projectiles": peak_projectiles,
		"monster_fallouts": monster_fallouts, "announcements": announcements,
		"violations": violations,
	}
	var output := ProjectSettings.globalize_path("res://../reports/codex-sys-01/probe-%d-p%d.json" % [seed_value, player_count])
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	print("ECOLOGY_PROBE ", JSON.stringify(result))
	main.queue_free()
	await process_frame
	quit(0 if violations.is_empty() and bool(result.match_over) else 1)

func _sample() -> void:
	var living := 0
	var elite_counts: Dictionary = {}
	var now: float = main.director.match_elapsed
	for monster in get_nodes_in_group("realm_monsters"):
		var id: int = monster.get_instance_id()
		var skin: String = monster.skin_id
		if not seen.has(id):
			seen[id] = {"serial": 0, "phase": "idle", "windup_seen": false}
			if not by_skin.has(skin):
				by_skin[skin] = {"archetype": monster.archetype, "regular_spawns": 0, "elite_spawns": 0, "windups": 0, "actions": 0, "defeats": 0, "hits": 0}
			monster.defeated.connect(_on_monster_defeated)
			var key := "%d:%d" % [monster.realm_index, monster.spawn_slot]
			if monster.is_elite:
				by_skin[skin].elite_spawns += 1
				elite_spawns.append({"time": now, "phase": main.director.phase, "realm": monster.realm_index, "skin": skin, "hp": monster.max_hp, "souls": monster.soul_reward})
				if main.director.phase == "Exploration":
					violations.append("Elite spawned during exploration")
				if last_elite_defeat.has(monster.realm_index):
					var interval := now - float(last_elite_defeat[monster.realm_index])
					elite_intervals.append(interval)
					if interval < 69.96 or interval > 90.04:
						violations.append("Elite refill outside 70-90 seconds: %.3f" % interval)
			else:
				by_skin[skin].regular_spawns += 1
				if last_regular_defeat.has(key):
					var interval := now - float(last_regular_defeat[key])
					refill_intervals.append(interval)
					if interval < 11.96 or interval > 18.04:
						violations.append("Regular refill outside 12-18 seconds: %.3f" % interval)
		if monster.hp <= 0.0:
			continue
		living += 1
		if monster.is_elite:
			elite_counts[monster.realm_index] = int(elite_counts.get(monster.realm_index, 0)) + 1
		var record: Dictionary = seen[id]
		if monster.action_phase == "windup":
			record.windup_seen = true
			if record.phase != "windup":
				by_skin[skin].windups += 1
		if monster.attack_serial > int(record.serial):
			by_skin[skin].actions += monster.attack_serial - int(record.serial)
			if not bool(record.windup_seen):
				violations.append("Action without an observed windup: %s" % skin)
			record.windup_seen = false
		record.serial = monster.attack_serial
		record.phase = monster.action_phase
	for count in elite_counts.values():
		if int(count) > 1:
			violations.append("More than one living elite in a realm")
	peak_living_monsters = maxi(peak_living_monsters, living)
	var projectiles := 0
	for child in main.get_children():
		if child is Area2D and child.get("projectile_kind") != null:
			projectiles += 1
	peak_projectiles = maxi(peak_projectiles, projectiles)

func _on_monster_defeated(monster: Node, _attacker: Node, _reward: int) -> void:
	var now: float = main.director.match_elapsed
	by_skin[monster.skin_id].defeats += 1
	if monster.global_position.y > monster.patrol_center.y + monster.FALL_OUT_DEPTH:
		monster_fallouts += 1
	if monster.is_elite:
		last_elite_defeat[monster.realm_index] = now
	else:
		last_regular_defeat["%d:%d" % [monster.realm_index, monster.spawn_slot]] = now

func _on_damaged(_fighter: Node, _amount: float, attacker: Variant, kind: String) -> void:
	if kind != "hit" or not is_instance_valid(attacker) or not attacker.is_in_group("realm_monsters"):
		return
	monster_hits["elite" if attacker.is_elite else "regular"] += 1
	if by_skin.has(attacker.skin_id):
		by_skin[attacker.skin_id].hits += 1

func _on_fighter_defeated(_fighter: Node, attacker: Variant) -> void:
	if is_instance_valid(attacker) and attacker.is_in_group("realm_monsters"):
		monster_eliminations["elite" if attacker.is_elite else "regular"] += 1
