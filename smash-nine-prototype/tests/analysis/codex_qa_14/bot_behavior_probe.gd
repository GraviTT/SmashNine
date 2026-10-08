extends SceneTree
## CODEX-QA-14 reusable bot-behaviour probe. Runs matches sequentially and observes
## the real Main scene without replacing game rules.

const MAIN_SCENE := "res://scenes/Main.tscn"
const SAMPLE_INTERVAL := 0.25
const FRAME_TIME := 1.0 / 60.0
const HIT_WINDOW := 0.4
const NO_PROGRESS_MIN_SECONDS := 3.0
const NO_PROGRESS_MIN_PIXELS := 100.0
const LOW_HP_FOLLOW_SECONDS := 10.0
const OUT_PATH := "res://../reports/codex-qa-14/results.json"

var seeds: Array[int] = []
var seconds := 480.0
var player_count := 8
var main: Node
var match_seed := 0

var totals: Dictionary = {
	"samples": {}, "states": {}, "actions": {}, "targets": {}, "stuck": {},
	"target_switches": {}, "target_active_seconds": {}, "no_progress": {},
	"attacks": {}, "character_seconds": {}, "pvp_damage": {}, "pve_damage": {},
	"recovery": {}, "portals": {}, "standoffs": []
}
var match_rows: Array[Dictionary] = []
var ringout_rows: Array[Dictionary] = []
var low_hp_rows: Array[Dictionary] = []
var relocation_rows: Array[Dictionary] = []

var sample_timer := 0.0
var player_memory: Dictionary = {}
var pending_attacks: Dictionary = {}
var entity_hp: Dictionary = {}
var standoff_memory: Dictionary = {}
var last_pvp_damage: Dictionary = {}
var warning_members: Dictionary = {}
var escaped_warning: Dictionary = {}
var recent_relocations: Dictionary = {}
var match_ringouts := 0
var match_portals := 0
var match_relocations := 0
var match_recovery_success := 0
var match_recovery_fail := 0
var match_standoffs := 0

func _initialize() -> void:
	var first_seed := 101
	var count := 12
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			first_seed = int(arg.get_slice("=", 1))
		elif arg.begins_with("--count="):
			count = int(arg.get_slice("=", 1))
		elif arg.begins_with("--seconds="):
			seconds = float(arg.get_slice("=", 1))
		elif arg.begins_with("--players="):
			player_count = int(arg.get_slice("=", 1))
	for value in range(first_seed, first_seed + count):
		seeds.append(value)
	call_deferred("_run_all")

func _run_all() -> void:
	var wall_start := Time.get_ticks_usec()
	for value in seeds:
		await _run_match(value)
	var result := {
		"schema": 1,
		"seeds": seeds,
		"players": player_count,
		"sample_interval": SAMPLE_INTERVAL,
		"hit_window": HIT_WINDOW,
		"no_progress_definition": "target episode >=3s whose distance never shrank by max(100px, 10% of start distance)",
		"wall_seconds": snappedf(float(Time.get_ticks_usec() - wall_start) / 1000000.0, 0.001),
		"matches": match_rows,
		"totals": totals,
		"ringouts": ringout_rows,
		"low_hp_portals": low_hp_rows,
		"relocations": relocation_rows
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../reports/codex-qa-14"))
	var file := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s" % OUT_PATH)
		quit(2)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	_print_summary(result)
	quit(0)

func _run_match(value: int) -> void:
	match_seed = value
	seed(value)
	_reset_match_memory()
	main = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.match_seed = value
	main.player_count = player_count
	root.add_child(main)
	await process_frame
	main.director.realm_state_changed.connect(_on_realm_state_changed)
	main.director.combatant_relocated.connect(_on_relocated)
	for player in main.players:
		player.damaged.connect(_on_damaged)
		player.defeated.connect(_on_defeated)
		player_memory[player.get_instance_id()] = _new_player_memory(player)
	var frame_limit := int(seconds / FRAME_TIME)
	var finished := false
	for _frame in frame_limit:
		await physics_frame
		_observe_frame()
		if main.match_over:
			finished = true
			break
	_finalize_match_episodes()
	var winner: Node = main.get_winner()
	match_rows.append({
		"seed": value,
		"seconds": snappedf(main.director.match_elapsed, 0.1),
		"finished": finished,
		"reason": main.director.finish_reason,
		"winner": winner.character_id if is_instance_valid(winner) else "",
		"ringouts": match_ringouts,
		"portals": match_portals,
		"relocations": match_relocations,
		"recovery_success": match_recovery_success,
		"recovery_fail": match_recovery_fail,
		"standoffs": match_standoffs
	})
	print("QA14_MATCH seed=%d seconds=%.1f ringouts=%d portals=%d relocations=%d recovery=%d/%d standoffs=%d" % [value, main.director.match_elapsed, match_ringouts, match_portals, match_relocations, match_recovery_success, match_recovery_fail, match_standoffs])
	main.queue_free()
	await process_frame
	await process_frame
	main = null

func _reset_match_memory() -> void:
	sample_timer = 0.0
	player_memory.clear()
	pending_attacks.clear()
	entity_hp.clear()
	standoff_memory.clear()
	last_pvp_damage.clear()
	warning_members.clear()
	escaped_warning.clear()
	recent_relocations.clear()
	match_ringouts = 0
	match_portals = 0
	match_relocations = 0
	match_recovery_success = 0
	match_recovery_fail = 0
	match_standoffs = 0

func _new_player_memory(player: Node) -> Dictionary:
	return {
		"character": str(player.character_id),
		"realm": int(player.realm_index),
		"ringouts": int(player.respawn_count),
		"last_attack_text": "",
		"last_attack_time": -99.0,
		"target_id": -1,
		"target_episode": {},
		"recovery": false,
		"portal_reason": "",
		"low_hp_pending": [],
		"last_hp": float(player.hp)
	}

func _observe_frame() -> void:
	if not is_instance_valid(main):
		return
	var now: float = main.director.match_elapsed
	for player in main.players:
		if not is_instance_valid(player):
			continue
		var pid: int = player.get_instance_id()
		if not player_memory.has(pid):
			player_memory[pid] = _new_player_memory(player)
		var memory: Dictionary = player_memory[pid]
		var snapshot: Dictionary = player.ai_controller.debug_snapshot(player)
		_observe_attack(player, snapshot, memory, now)
		_observe_recovery(player, snapshot, memory, now)
		_observe_realm_change(player, snapshot, memory, now)
		_observe_low_hp_followup(player, snapshot, memory, now)
		memory.last_hp = float(player.hp)
		player_memory[pid] = memory
	_observe_entity_hp(now)
	sample_timer -= FRAME_TIME
	if sample_timer <= 0.0:
		sample_timer += SAMPLE_INTERVAL
		_observe_sample(now)

func _observe_attack(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	var attack_text := str(snapshot.attack)
	if attack_text == "":
		memory.last_attack_text = ""
		return
	if attack_text == str(memory.last_attack_text) and now - float(memory.last_attack_time) < 0.2:
		return
	var attack_type := attack_text
	if attack_text == "basic":
		attack_type = "basic_side" if player.is_on_floor() else "basic_air_side"
	memory.last_attack_text = attack_text
	memory.last_attack_time = now
	var key := "%s|%s" % [player.character_id, attack_type]
	var stats: Dictionary = totals.attacks.get(key, {"uses": 0, "hits": 0, "damage": 0.0})
	stats.uses = int(stats.uses) + 1
	totals.attacks[key] = stats
	pending_attacks[player.get_instance_id()] = {"time": now, "key": key, "hit": false}

func _mark_attack_hit(attacker: Node, damage: float, now: float) -> void:
	if not is_instance_valid(attacker) or not attacker.is_in_group("players"):
		return
	var pid := attacker.get_instance_id()
	if not pending_attacks.has(pid):
		return
	var pending: Dictionary = pending_attacks[pid]
	if now - float(pending.time) > HIT_WINDOW:
		return
	var stats: Dictionary = totals.attacks[pending.key]
	if not bool(pending.hit):
		stats.hits = int(stats.hits) + 1
		pending.hit = true
	stats.damage = float(stats.damage) + damage
	totals.attacks[pending.key] = stats
	pending_attacks[pid] = pending

func _observe_entity_hp(now: float) -> void:
	for group in ["realm_monsters", "soul_crystals"]:
		for entity in get_nodes_in_group(group):
			if not is_instance_valid(entity):
				continue
			var eid := entity.get_instance_id()
			var hp_value := float(entity.get("hp"))
			if entity_hp.has(eid):
				var loss: float = maxf(float(entity_hp[eid]) - hp_value, 0.0)
				if loss > 0.0:
					_attribute_pve_hit(entity, loss, now, group == "soul_crystals")
			entity_hp[eid] = hp_value

func _attribute_pve_hit(entity: Node, loss: float, now: float, crystal: bool) -> void:
	var best: Node
	var best_age := INF
	for player in main.players:
		if not is_instance_valid(player):
			continue
		var pid: int = player.get_instance_id()
		if not pending_attacks.has(pid) or player.ai_controller.target != entity:
			continue
		var age: float = now - float(pending_attacks[pid].time)
		if age >= 0.0 and age <= HIT_WINDOW and age < best_age:
			best_age = age
			best = player
	if is_instance_valid(best):
		_mark_attack_hit(best, 0.0 if crystal else loss, now)
		if not crystal:
			_add_number(totals.pve_damage, str(best.character_id), loss)

func _observe_recovery(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	var recovering := str(snapshot.state) == "recover"
	if recovering and not bool(memory.recovery):
		memory.recovery = true
		memory.recovery_started = now
		memory.recovery_air_jumps = int(player.air_jumps_left)
	elif not recovering and bool(memory.recovery):
		memory.recovery = false
		match_recovery_success += 1
		_add_recovery(player.character_id, "success")

func _observe_realm_change(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	if str(snapshot.state) == "portal" and str(memory.portal_reason) == "":
		memory.portal_reason = str(snapshot.reason)
	var old_realm := int(memory.realm)
	var new_realm := int(player.realm_index)
	if new_realm == old_realm:
		return
	var pid := player.get_instance_id()
	var relocated := recent_relocations.has(pid) and now - float(recent_relocations[pid]) < 0.2
	if not relocated:
		match_portals += 1
		_add_number(totals.portals, "all", 1.0)
		if str(memory.portal_reason).begins_with("low HP"):
			_add_number(totals.portals, "low_hp", 1.0)
			memory.low_hp_pending.append({"seed": match_seed, "character": str(player.character_id), "time": now, "from": old_realm, "to": new_realm, "hp_before": snappedf(player.hp, 0.1), "damaged": false, "engaged": false, "defeated": false})
		var warning_key := "%d|%d" % [old_realm, pid]
		if warning_members.has(warning_key):
			escaped_warning[warning_key] = true
			_add_number(totals.portals, "collapse_escape", 1.0)
	memory.realm = new_realm
	memory.portal_reason = ""

func _observe_low_hp_followup(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	if memory.low_hp_pending.is_empty():
		return
	var active: Array = []
	for event in memory.low_hp_pending:
		if str(snapshot.state) == "engage":
			event.engaged = true
		if float(player.hp) < float(memory.last_hp) - 0.01:
			event.damaged = true
		var followed: float = now - float(event.time)
		if followed >= LOW_HP_FOLLOW_SECONDS or player.is_defeated:
			event["hp_after"] = snappedf(player.hp, 0.1)
			event["follow_seconds"] = snappedf(followed, 0.1)
			event["survived_10s"] = not player.is_defeated and followed >= LOW_HP_FOLLOW_SECONDS
			low_hp_rows.append(event.duplicate())
		else:
			active.append(event)
	memory.low_hp_pending = active

func _observe_sample(now: float) -> void:
	var phase := str(main.director.phase)
	var realm_counts: Dictionary = {}
	for player in main.players:
		if not is_instance_valid(player) or player.is_defeated:
			continue
		var pid: int = player.get_instance_id()
		var memory: Dictionary = player_memory[pid]
		var snapshot: Dictionary = player.ai_controller.debug_snapshot(player)
		var prefix := "%s|%s" % [player.character_id, phase]
		_add_number(totals.samples, prefix, 1.0)
		_add_number(totals.character_seconds, str(player.character_id), SAMPLE_INTERVAL)
		_add_number(totals.states, "%s|%s" % [prefix, snapshot.state], 1.0)
		if str(snapshot.action) != "":
			_add_number(totals.actions, "%s|%s" % [prefix, snapshot.action], 1.0)
		var target_kind := str(snapshot.target_kind) if str(snapshot.target_kind) != "" else "none"
		_add_number(totals.targets, "%s|%s" % [prefix, target_kind], 1.0)
		if float(snapshot.stuck) >= 0.5 and absf(float(snapshot.move)) > 0.01:
			var local: Vector2 = player.global_position - player.realm_origin
			var spot := "%d|%d|%d" % [player.realm_index, roundi(local.x / 100.0) * 100, roundi(local.y / 100.0) * 100]
			_add_number(totals.stuck, spot, SAMPLE_INTERVAL)
		_observe_target_episode(player, snapshot, memory, phase)
		player_memory[pid] = memory
		var realm := int(player.realm_index)
		realm_counts[realm] = int(realm_counts.get(realm, 0)) + 1
	_observe_standoffs(realm_counts, now)

func _observe_target_episode(player: Node, snapshot: Dictionary, memory: Dictionary, phase: String) -> void:
	# A monster/crystal can be queued free between the AI update and this 0.25 s sample.
	# Keep the raw value untyped until validity is checked; assigning a freed object to a
	# typed Node is itself a runtime error in Godot 4.
	var target_value: Variant = player.ai_controller.target
	var target_id := -1
	if is_instance_valid(target_value):
		target_id = target_value.get_instance_id()
	if target_id != int(memory.target_id):
		_finalize_target_episode(player.character_id, memory.target_episode)
		if int(memory.target_id) != -1 or target_id != -1:
			_add_number(totals.target_switches, str(player.character_id), 1.0)
		memory.target_id = target_id
		memory.target_episode = {}
		if target_id != -1:
			var distance := (snapshot.gap as Vector2).length()
			memory.target_episode = {"kind": str(snapshot.target_kind), "start": distance, "min": distance, "seconds": 0.0, "pursue": 0.0, "far_y": 0.0, "phases": {}}
	if memory.target_episode.is_empty():
		return
	var episode: Dictionary = memory.target_episode
	var distance := (snapshot.gap as Vector2).length()
	episode.min = minf(float(episode.min), distance)
	episode.seconds = float(episode.seconds) + SAMPLE_INTERVAL
	if str(snapshot.state) == "pursue":
		episode.pursue = float(episode.pursue) + SAMPLE_INTERVAL
	if absf((snapshot.gap as Vector2).y) > 240.0:
		episode.far_y = float(episode.far_y) + SAMPLE_INTERVAL
	var phases: Dictionary = episode.phases
	phases[phase] = float(phases.get(phase, 0.0)) + SAMPLE_INTERVAL
	episode.phases = phases
	memory.target_episode = episode
	_add_number(totals.target_active_seconds, str(player.character_id), SAMPLE_INTERVAL)

func _finalize_target_episode(character: String, episode: Dictionary) -> void:
	if episode.is_empty() or float(episode.seconds) < NO_PROGRESS_MIN_SECONDS:
		return
	if float(episode.pursue) < NO_PROGRESS_MIN_SECONDS and float(episode.far_y) < NO_PROGRESS_MIN_SECONDS:
		return
	var required := maxf(NO_PROGRESS_MIN_PIXELS, float(episode.start) * 0.1)
	if float(episode.start) - float(episode.min) >= required:
		return
	var stats: Dictionary = totals.no_progress.get(character, {"episodes": 0, "seconds": 0.0, "far_y_seconds": 0.0, "phases": {}})
	stats.episodes = int(stats.episodes) + 1
	stats.seconds = float(stats.seconds) + float(episode.seconds)
	stats.far_y_seconds = float(stats.far_y_seconds) + float(episode.far_y)
	var phase_totals: Dictionary = stats.phases
	for phase in episode.phases:
		phase_totals[phase] = float(phase_totals.get(phase, 0.0)) + float(episode.phases[phase])
	stats.phases = phase_totals
	totals.no_progress[character] = stats

func _observe_standoffs(realm_counts: Dictionary, now: float) -> void:
	for realm in range(9):
		var count := int(realm_counts.get(realm, 0))
		if count >= 2:
			if not standoff_memory.has(realm):
				standoff_memory[realm] = now
			var last_damage := float(last_pvp_damage.get(realm, -INF))
			if last_damage > float(standoff_memory[realm]):
				standoff_memory[realm] = last_damage
		elif standoff_memory.has(realm):
			_finalize_standoff(realm, float(standoff_memory[realm]), now)
			standoff_memory.erase(realm)

func _finalize_standoff(realm: int, started: float, ended: float) -> void:
	var duration := ended - started
	if duration < 20.0:
		return
	match_standoffs += 1
	(totals.standoffs as Array).append({"seed": match_seed, "realm": realm, "start": snappedf(started, 0.1), "duration": snappedf(duration, 0.1)})

func _on_damaged(player: Node, amount: float, attacker: Node, source: String) -> void:
	if not is_instance_valid(main):
		return
	var now: float = main.director.match_elapsed
	var pid := player.get_instance_id()
	if player_memory.has(pid):
		for event in player_memory[pid].low_hp_pending:
			event.damaged = true
	if source == "hit":
		last_pvp_damage[int(player.realm_index)] = now
		if is_instance_valid(attacker) and attacker.is_in_group("players"):
			_mark_attack_hit(attacker, amount, now)
			_add_number(totals.pvp_damage, str(attacker.character_id), amount)
		return
	var previous_ringouts := int(player_memory[pid].ringouts) if player_memory.has(pid) else int(player.respawn_count)
	if int(player.respawn_count) <= previous_ringouts:
		return
	match_ringouts += 1
	var memory: Dictionary = player_memory[pid]
	memory.ringouts = int(player.respawn_count)
	var recovery_active := bool(memory.recovery)
	if recovery_active:
		memory.recovery = false
		match_recovery_fail += 1
		_add_recovery(player.character_id, "fail")
	ringout_rows.append({
		"seed": match_seed, "time": snappedf(now, 0.1), "phase": str(main.director.phase),
		"victim": str(player.character_id), "attacker": str(attacker.character_id) if is_instance_valid(attacker) and attacker.is_in_group("players") else "environment",
		"air_jumps_left": int(player.air_jumps_left), "max_air_jumps": int(player.max_air_jumps),
		"during_recovery": recovery_active, "realm": int(player.realm_index)
	})
	player_memory[pid] = memory

func _on_defeated(player: Node, _attacker: Node) -> void:
	var pid := player.get_instance_id()
	if player_memory.has(pid):
		for event in player_memory[pid].low_hp_pending:
			event.defeated = true

func _on_realm_state_changed(realm_index: int, state: String) -> void:
	if state != "warning" or not is_instance_valid(main):
		return
	for player in main.players:
		if is_instance_valid(player) and not player.is_defeated and int(player.realm_index) == realm_index:
			warning_members["%d|%d" % [realm_index, player.get_instance_id()]] = true

func _on_relocated(player: Node, destination: int) -> void:
	if not is_instance_valid(main):
		return
	var pid := player.get_instance_id()
	recent_relocations[pid] = main.director.match_elapsed
	match_relocations += 1
	_add_number(totals.portals, "collapse_relocation", 1.0)
	relocation_rows.append({"seed": match_seed, "time": snappedf(main.director.match_elapsed, 0.1), "character": str(player.character_id), "to": destination, "hp": snappedf(player.hp, 0.1)})

func _finalize_match_episodes() -> void:
	var now: float = main.director.match_elapsed
	for player in main.players:
		if not is_instance_valid(player):
			continue
		var pid: int = player.get_instance_id()
		if not player_memory.has(pid):
			continue
		var memory: Dictionary = player_memory[pid]
		_finalize_target_episode(player.character_id, memory.target_episode)
		if bool(memory.recovery):
			match_recovery_fail += 1
			_add_recovery(player.character_id, "unfinished")
		for event in memory.low_hp_pending:
			var followed: float = now - float(event.time)
			event["hp_after"] = snappedf(player.hp, 0.1)
			event["follow_seconds"] = snappedf(followed, 0.1)
			event["survived_10s"] = not player.is_defeated and followed >= LOW_HP_FOLLOW_SECONDS
			low_hp_rows.append(event.duplicate())
	for realm in standoff_memory:
		_finalize_standoff(int(realm), float(standoff_memory[realm]), now)

func _add_recovery(character: String, outcome: String) -> void:
	var stats: Dictionary = totals.recovery.get(character, {"success": 0, "fail": 0, "unfinished": 0})
	stats[outcome] = int(stats[outcome]) + 1
	totals.recovery[character] = stats

func _add_number(dictionary: Dictionary, key: String, value: float) -> void:
	dictionary[key] = float(dictionary.get(key, 0.0)) + value

func _print_summary(result: Dictionary) -> void:
	print("QA14_SUMMARY matches=%d wall=%.1fs ringouts=%d low_hp_portals=%d standoffs=%d" % [match_rows.size(), result.wall_seconds, ringout_rows.size(), low_hp_rows.size(), (totals.standoffs as Array).size()])
	for character in totals.recovery:
		var row: Dictionary = totals.recovery[character]
		print("QA14_RECOVERY %s success=%d fail=%d unfinished=%d" % [character, row.success, row.fail, row.unfinished])
	for key in totals.attacks:
		var row: Dictionary = totals.attacks[key]
		print("QA14_ATTACK %s uses=%d hits=%d rate=%.3f damage=%.1f" % [key, row.uses, row.hits, float(row.hits) / maxf(float(row.uses), 1.0), row.damage])
	print("QA14_OUTPUT ", ProjectSettings.globalize_path(OUT_PATH))
