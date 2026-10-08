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
const OUT_PATH := "res://../reports/codex-qa-14/round4-results.json"
const AIR_DOWN_RINGOUT_WINDOW := 2.0
const NOVA_LAUNCH_HIT_WINDOW := 3.2
const CORNER_ESCAPE_RINGOUT_WINDOW := 3.0
const RECENT_TRADE_WINDOW := 3.0
const YUKI_LEDGE_DISTANCE := 225.0
const PRODUCT_PROGRESS_TIME := 2.5

var seeds: Array[int] = []
var seconds := 480.0
var player_count := 8
var main: Node
var match_seed := 0

var totals: Dictionary = {
	"samples": {}, "states": {}, "actions": {}, "targets": {}, "stuck": {},
	"target_switches": {}, "target_active_seconds": {}, "no_progress": {},
	"attacks": {}, "character_seconds": {}, "pvp_damage": {}, "pve_damage": {},
	"recovery": {}, "portals": {}, "portal_reasons": {}, "standoffs": [],
	"guards_by_attacker": {}, "nova": {"launches": 0, "aimed": 0, "forced": 0, "redirects": 0, "hits": 0},
	"air_down_self_ringouts": {}, "target_drops": {}, "corner_escapes": {},
	"swing_context": {}, "recovery_skills": {}, "yuki_ledge_ringouts": {"all": 0, "near_ledge": 0},
	"frey_recovery_entries": {"knocked_off": 0, "walked_or_dashed_off": 0, "other": 0}
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
var seen_parry_effects: Dictionary = {}
var recent_pair_hits: Dictionary = {}
var pending_swing_context: Dictionary = {}
var target_drop_rows: Array[Dictionary] = []
var corner_escape_rows: Array[Dictionary] = []
var recovery_skill_rows: Array[Dictionary] = []
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
		"schema": 4,
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
		"relocations": relocation_rows,
		"target_drop_events": target_drop_rows,
		"corner_escape_events": corner_escape_rows,
		"recovery_skill_events": recovery_skill_rows,
		"round2_definitions": {
			"reaction_in_recovery": "reactive guard timer first seen after the observed attack's conservative per-character startup bound",
			"block": "damage signal arrived while the defender was still guarding (wrong-direction guards are lowered before the signal)",
			"parry": "the 92x92 parry effect created by PlayerBase was observed and attributed to the nearby attacker receiving parry recoil",
			"air_down_self_ringout": "same fighter rang out within 2.0 s after starting a basic air-down",
			"nova_launch_hit": "Nova dealt PvP damage within 3.2 s after the slingshot launch"
		},
		"round3_definitions": {
			"target_drop": "debug reason changed to 'gave up: target out of reach'; dropped target recovered from ignored_targets",
			"recent_trade": "the bot and dropped target exchanged a measured damage event in either direction during the prior 3.0 s",
			"corner_escape": "debug reason changed to 'cornered: jumping past'",
			"distance_buckets": "target distance at exact attack_serial increment: 0-120, 120-240, 240-360, 360+ px",
			"too_late": "debug reason changed to 'too late to block' after a queued reaction expired",
			"recovery_skill": "skill_1 coincided with attack_serial increment while state was recover; reached_floor means that recovery episode later exited recover without a ring-out",
			"yuki_near_ledge": "Yuki's last attributed PvP hit before ring-out occurred while _cornered() found no floor within 225 px behind her, away from the attacker"
		},
		"round4_definitions": {
			"combo_block": "a guarded damage event attributed to Frey/Rio ground-side combo step 2 or 3 from combo_step at attack_serial increment",
			"frey_recovery_entry": "knocked_off if PvP-damaged within 3s; otherwise walked_or_dashed_off if recover began outside the realm sides or over void; remaining entries are other"
		}
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
	seen_parry_effects.clear()
	recent_pair_hits.clear()
	pending_swing_context.clear()
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
		"last_hp": float(player.hp),
		"last_is_guarding": bool(player.is_guarding),
		"last_guard_delay": float(player.ai_controller.guard_delay_timer),
		"last_attack_lock": float(player.attack_lock_timer),
		"attack_started_time": -99.0,
		"attack_startup_bound": 999.0,
		"last_air_down_time": -99.0,
		"nova_phase": int(player.get("ultimate_phase")) if player.character_id == "nova" else -1,
		"nova_stage_timer": float(player.ai_controller.nova_stage_timer) if player.character_id == "nova" else -1.0,
		"nova_launch_pending": {}
		,"last_reason": "",
		"last_attack_serial": int(player.attack_serial),
		"last_vector_shift_active": bool(player.get("vector_shift_active")) if player.character_id == "nova" else false,
		"last_air_blink_available": bool(player.get("air_blink_available")) if player.character_id == "rio" else false,
		"last_corner_escape_time": -99.0,
		"recovery_skill_pending": [],
		"last_yuki_hit_near_ledge": false,
		"last_yuki_hit_time": -99.0,
		"ignored_target_ids": {},
		"last_progress_target": player.ai_controller.progress_target,
		"last_progress_timer": float(player.ai_controller.progress_timer),
		"last_progress_drop_time": -99.0,
		"last_combo_step": 0,
		"last_combo_serial": -1,
		"last_pvp_hit_received": -99.0,
		"last_damage_time": -99.0,
		"last_damage_source": ""
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
		_observe_round3(player, snapshot, memory, now)
		_observe_attack(player, snapshot, memory, now)
		_observe_guard(player, memory, now)
		_observe_nova(player, memory, now)
		_observe_recovery(player, snapshot, memory, now)
		_observe_realm_change(player, snapshot, memory, now)
		_observe_low_hp_followup(player, snapshot, memory, now)
		memory.last_hp = float(player.hp)
		player_memory[pid] = memory
	_observe_parry_effects()
	# Preserve every fighter's previous-frame attack lock until all guard/parry observers ran;
	# otherwise detection depends on player iteration order.
	for player in main.players:
		if is_instance_valid(player) and player_memory.has(player.get_instance_id()):
			player_memory[player.get_instance_id()].last_attack_lock = float(player.attack_lock_timer)
	_observe_entity_hp(now)
	sample_timer -= FRAME_TIME
	if sample_timer <= 0.0:
		sample_timer += SAMPLE_INTERVAL
		_observe_sample(now)

func _observe_round3(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	_observe_progress_drop_edge(player, memory, now)
	var reason := str(snapshot.reason)
	if reason != str(memory.last_reason):
		if reason == "gave up: target out of reach":
			if now - float(memory.last_progress_drop_time) > 0.1:
				_observe_target_drop(player, now)
				memory.last_progress_drop_time = now
		elif reason == "cornered: jumping past":
			_add_number(totals.corner_escapes, str(player.character_id), 1.0)
			memory.last_corner_escape_time = now
			corner_escape_rows.append({"seed": match_seed, "time": snappedf(now, 0.01), "character": str(player.character_id), "realm": int(player.realm_index), "ringout_within_3s": false})
		elif reason == "too late to block":
			var threat: Node = player.ai_controller.guard_threat_from if is_instance_valid(player.ai_controller.guard_threat_from) else null
			if is_instance_valid(threat):
				var stats := _guard_stats(str(threat.character_id))
				stats["too_late"] = int(stats.get("too_late", 0)) + 1
				totals.guards_by_attacker[str(threat.character_id)] = stats
	memory.last_reason = reason
	_observe_recovery_skill_activation(player, snapshot, memory, now)

	var serial := int(player.attack_serial)
	if serial != int(memory.last_attack_serial):
		_observe_exact_swing(player, snapshot, memory, now, serial)
		memory.last_attack_serial = serial

func _observe_progress_drop_edge(player: Node, memory: Dictionary, now: float) -> void:
	var current_ids: Dictionary = {}
	var previous_ids: Dictionary = memory.ignored_target_ids
	var previous_target: Variant = memory.last_progress_target
	var previous_timer := float(memory.last_progress_timer)
	for candidate_value in player.ai_controller.ignored_targets:
		if not is_instance_valid(candidate_value):
			continue
		var candidate_id: int = candidate_value.get_instance_id()
		current_ids[candidate_id] = true
		# _update_target_progress adds the previous progress target to ignored_targets at
		# 2.5 s, then _select_state overwrites debug_reason in the same update. This edge
		# distinguishes that drop from route candidates ignored inside _find_target().
		if not previous_ids.has(candidate_id) and candidate_value == previous_target and previous_timer >= PRODUCT_PROGRESS_TIME - FRAME_TIME * 2.0:
			_observe_target_drop(player, now, candidate_value)
			memory.last_progress_drop_time = now
	memory.ignored_target_ids = current_ids
	memory.last_progress_target = player.ai_controller.progress_target
	memory.last_progress_timer = float(player.ai_controller.progress_timer)

func _observe_recovery_skill_activation(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	var character := str(player.character_id)
	var activated := false
	if str(snapshot.state) == "recover" and str(snapshot.attack) == "skill_1":
		match character:
			"frey":
				activated = float(memory.last_attack_lock) <= 0.0 and float(player.attack_lock_timer) > 0.0
			"nova":
				activated = bool(player.get("vector_shift_active")) and not bool(memory.last_vector_shift_active)
			"rio":
				activated = bool(memory.last_air_blink_available) and not bool(player.get("air_blink_available"))
	if activated:
		_record_swing_context(player, "skill_1", now, int(player.attack_serial))
		var recovery_stats: Dictionary = totals.recovery_skills.get(character, {"used": 0, "reached_floor": 0})
		recovery_stats.used = int(recovery_stats.used) + 1
		totals.recovery_skills[character] = recovery_stats
		memory.recovery_skill_pending.append({"seed": match_seed, "time": snappedf(now, 0.01), "character": character, "reached_floor": false})
	if character == "nova":
		memory.last_vector_shift_active = bool(player.get("vector_shift_active"))
	elif character == "rio":
		memory.last_air_blink_available = bool(player.get("air_blink_available"))

func _observe_target_drop(player: Node, now: float, known_dropped: Node = null) -> void:
	var dropped: Node = known_dropped
	var best_remaining := -INF
	if not is_instance_valid(dropped):
		for candidate_value in player.ai_controller.ignored_targets:
			if not is_instance_valid(candidate_value):
				continue
			var remaining := float(player.ai_controller.ignored_targets[candidate_value])
			if remaining > best_remaining:
				best_remaining = remaining
				dropped = candidate_value
	var kind := "unknown"
	var distance := -1.0
	var traded := false
	if is_instance_valid(dropped):
		distance = player.global_position.distance_to(dropped.global_position)
		kind = _target_kind(dropped)
		var pair_key_a := "%d|%d" % [player.get_instance_id(), dropped.get_instance_id()]
		var pair_key_b := "%d|%d" % [dropped.get_instance_id(), player.get_instance_id()]
		var last_trade := maxf(float(recent_pair_hits.get(pair_key_a, -INF)), float(recent_pair_hits.get(pair_key_b, -INF)))
		traded = now - last_trade <= RECENT_TRADE_WINDOW
	var row := {
		"seed": match_seed, "time": snappedf(now, 0.01), "character": str(player.character_id),
		"target_kind": kind, "distance": snappedf(distance, 0.1), "within_300": distance >= 0.0 and distance <= 300.0,
		"traded_within_3s": traded
	}
	target_drop_rows.append(row)
	var stats: Dictionary = totals.target_drops.get(str(player.character_id), {"all": 0, "within_300": 0, "traded_within_3s": 0})
	stats.all = int(stats.all) + 1
	stats.within_300 = int(stats.within_300) + (1 if bool(row.within_300) else 0)
	stats.traded_within_3s = int(stats.traded_within_3s) + (1 if traded else 0)
	totals.target_drops[str(player.character_id)] = stats

func _observe_exact_swing(player: Node, snapshot: Dictionary, memory: Dictionary, now: float, serial: int) -> void:
	var attack_type := _current_attack_type(player, snapshot)
	memory.last_combo_step = _combo_swing_step(player, attack_type)
	memory.last_combo_serial = serial
	_record_swing_context(player, attack_type, now, serial)

func _combo_swing_step(player: Node, attack_type: String) -> int:
	if attack_type != "basic_side" or not ["frey", "rio"].has(str(player.character_id)):
		return 0
	var next_step: Variant = player.get("combo_step")
	var timer: Variant = player.get("combo_timer")
	if next_step == null or timer == null:
		return 0
	# Both kits advance combo_step after swings 1/2 and reset it immediately after swing 3.
	if int(next_step) == 1:
		return 1
	if int(next_step) == 2:
		return 2
	return 3 if float(timer) <= 0.0 else 0

func _record_swing_context(player: Node, attack_type: String, now: float, serial: int) -> void:
	var target_value: Variant = player.ai_controller.target
	var kind := "none"
	var distance := INF
	if is_instance_valid(target_value):
		kind = _target_kind(target_value)
		distance = player.global_position.distance_to(target_value.global_position)
	var bucket := _distance_bucket(distance)
	var key := "%s|%s|%s|%s" % [player.character_id, attack_type, bucket, kind]
	var stats: Dictionary = totals.swing_context.get(key, {"uses": 0, "hits": 0})
	stats.uses = int(stats.uses) + 1
	totals.swing_context[key] = stats
	pending_swing_context[player.get_instance_id()] = {"time": now, "key": key, "hit": false, "serial": serial}

func _current_attack_type(player: Node, snapshot: Dictionary) -> String:
	var attack_text := str(snapshot.attack)
	if attack_text == "basic":
		return "basic_%s" % str(player._get_basic_attack_type(player._get_attack_direction()))
	return attack_text if attack_text != "" else "unknown"

func _target_kind(target_value: Node) -> String:
	if target_value.is_in_group("players"):
		return "player"
	if target_value.is_in_group("soul_crystals"):
		return "crystal"
	return "monster"

func _distance_bucket(distance: float) -> String:
	if distance < 120.0:
		return "0_120"
	if distance < 240.0:
		return "120_240"
	if distance < 360.0:
		return "240_360"
	return "360_plus"

func _mark_swing_context_hit(attacker: Node, now: float) -> void:
	if not is_instance_valid(attacker):
		return
	var pid := attacker.get_instance_id()
	if not pending_swing_context.has(pid):
		return
	var pending: Dictionary = pending_swing_context[pid]
	if now - float(pending.time) > HIT_WINDOW or bool(pending.hit):
		return
	var stats: Dictionary = totals.swing_context[pending.key]
	stats.hits = int(stats.hits) + 1
	pending.hit = true
	totals.swing_context[pending.key] = stats
	pending_swing_context[pid] = pending

func _observe_attack(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	var attack_text := str(snapshot.attack)
	if attack_text == "":
		memory.last_attack_text = ""
		return
	if attack_text == str(memory.last_attack_text) and now - float(memory.last_attack_time) < 0.2:
		return
	var attack_type := attack_text
	if attack_text == "basic":
		var attack_direction: Vector2 = player._get_attack_direction()
		attack_type = "basic_%s" % str(player._get_basic_attack_type(attack_direction))
	memory.last_attack_text = attack_text
	memory.last_attack_time = now
	memory.attack_started_time = now
	memory.attack_startup_bound = _attack_startup_bound(str(player.character_id), attack_type)
	if attack_type == "basic_air_down":
		memory.last_air_down_time = now
	var key := "%s|%s" % [player.character_id, attack_type]
	var stats: Dictionary = totals.attacks.get(key, {"uses": 0, "hits": 0, "damage": 0.0})
	stats.uses = int(stats.uses) + 1
	totals.attacks[key] = stats
	pending_attacks[player.get_instance_id()] = {"time": now, "key": key, "hit": false}

func _attack_startup_bound(character: String, attack_type: String) -> float:
	# Conservative (largest) basic startup for each kit. A reaction counted after this bound is
	# certainly in recovery for basic attacks; skills/ultimates use 999 and are never guessed.
	if not attack_type.begins_with("basic_"):
		return 999.0
	return {"frey": 0.17, "luna": 0.21, "nova": 0.10, "rio": 0.08, "yuki": 0.16}.get(character, 0.25)

func _guard_stats(attacker_character: String) -> Dictionary:
	var stats: Dictionary = totals.guards_by_attacker.get(attacker_character, {
		"reactions": 0, "raised": 0, "blocks": 0, "parries": 0, "reaction_in_recovery": 0, "too_late": 0,
		"combo_2_blocks": 0, "combo_3_blocks": 0
	})
	return stats

func _observe_guard(defender: Node, memory: Dictionary, now: float) -> void:
	var ai = defender.ai_controller
	var delay := float(ai.guard_delay_timer)
	var guarding := bool(defender.is_guarding)
	var threat: Node = ai.guard_threat_from if is_instance_valid(ai.guard_threat_from) else null
	if delay >= 0.0 and float(memory.last_guard_delay) < 0.0 and is_instance_valid(threat):
		var attacker_character := str(threat.character_id)
		var stats := _guard_stats(attacker_character)
		stats.reactions = int(stats.reactions) + 1
		var attacker_memory: Dictionary = player_memory.get(threat.get_instance_id(), {})
		if not attacker_memory.is_empty() and now - float(attacker_memory.attack_started_time) >= float(attacker_memory.attack_startup_bound):
			stats.reaction_in_recovery = int(stats.reaction_in_recovery) + 1
		totals.guards_by_attacker[attacker_character] = stats
	if guarding and not bool(memory.last_is_guarding):
		var source: Node = threat if str(ai.debug_reason) == "blocking an attack" and is_instance_valid(threat) else ai.target
		if is_instance_valid(source) and source.is_in_group("players"):
			var stats := _guard_stats(str(source.character_id))
			stats.raised = int(stats.raised) + 1
			totals.guards_by_attacker[str(source.character_id)] = stats
	memory.last_is_guarding = guarding
	memory.last_guard_delay = delay

func _nearest_parried_attacker(defender: Node) -> Node:
	var best: Node
	var best_distance := INF
	for candidate in main.players:
		if not is_instance_valid(candidate) or candidate == defender or candidate.is_defeated:
			continue
		var candidate_memory: Dictionary = player_memory.get(candidate.get_instance_id(), {})
		if candidate_memory.is_empty():
			continue
		var lock_ended := float(candidate_memory.last_attack_lock) > 0.0 and float(candidate.attack_lock_timer) <= 0.0
		var parry_recoil := float(candidate.hitstop_timer) >= 0.04
		if not lock_ended and not parry_recoil:
			continue
		var distance: float = defender.global_position.distance_to(candidate.global_position)
		if distance < best_distance and distance <= 700.0:
			best_distance = distance
			best = candidate
	return best

func _observe_parry_effects() -> void:
	# PlayerBase._play_parry_effect creates a 92x92 ColorRect directly under Main. Unlike block
	# damage, parries emit no signal, so the effect is the only exact read-only observation hook.
	for child in main.get_children():
		if not child is ColorRect or (child as ColorRect).size != Vector2(92.0, 92.0):
			continue
		var effect_id := child.get_instance_id()
		if seen_parry_effects.has(effect_id):
			continue
		seen_parry_effects[effect_id] = true
		var effect_center: Vector2 = (child as ColorRect).position + Vector2(46.0, 78.0)
		var defender: Node
		var best_distance := INF
		for player in main.players:
			if not is_instance_valid(player) or not bool(player.is_guarding):
				continue
			var distance: float = effect_center.distance_to(player.global_position)
			if distance < best_distance:
				best_distance = distance
				defender = player
		if not is_instance_valid(defender) or best_distance > 8.0:
			continue
		var attacker := _nearest_parried_attacker(defender)
		if is_instance_valid(attacker):
			var stats := _guard_stats(str(attacker.character_id))
			stats.parries = int(stats.parries) + 1
			totals.guards_by_attacker[str(attacker.character_id)] = stats

func _observe_nova(player: Node, memory: Dictionary, now: float) -> void:
	if str(player.character_id) != "nova":
		return
	var phase := int(player.get("ultimate_phase"))
	var previous_phase := int(memory.nova_phase)
	if previous_phase == 2 and phase == 3:
		var forced := float(memory.nova_stage_timer) >= 0.79
		totals.nova.launches = int(totals.nova.launches) + 1
		totals.nova.forced = int(totals.nova.forced) + (1 if forced else 0)
		totals.nova.aimed = int(totals.nova.aimed) + (0 if forced else 1)
		memory.nova_launch_pending = {"time": now, "hit": false, "direction": player.ultimate_launch_direction}
	if phase == 3 and previous_phase == 3 and not memory.nova_launch_pending.is_empty():
		var old_direction: Vector2 = memory.nova_launch_pending.direction
		var new_direction: Vector2 = player.ultimate_launch_direction
		if old_direction.length() > 0.1 and new_direction.length() > 0.1 and absf(old_direction.angle_to(new_direction)) > 0.05:
			totals.nova.redirects = int(totals.nova.redirects) + 1
			memory.nova_launch_pending.direction = new_direction
	if not memory.nova_launch_pending.is_empty() and (phase == 0 or now - float(memory.nova_launch_pending.time) > NOVA_LAUNCH_HIT_WINDOW):
		if bool(memory.nova_launch_pending.hit):
			totals.nova.hits = int(totals.nova.hits) + 1
		memory.nova_launch_pending = {}
	memory.nova_phase = phase
	memory.nova_stage_timer = float(player.ai_controller.nova_stage_timer)

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
		_mark_swing_context_hit(best, now)
		recent_pair_hits["%d|%d" % [best.get_instance_id(), entity.get_instance_id()]] = now
		if not crystal:
			_add_number(totals.pve_damage, str(best.character_id), loss)

func _observe_recovery(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	var recovering := str(snapshot.state) == "recover"
	if recovering and not bool(memory.recovery):
		memory.recovery = true
		memory.recovery_started = now
		memory.recovery_air_jumps = int(player.air_jumps_left)
		if str(player.character_id) == "frey":
			var entry_kind := "other"
			if now - float(memory.last_pvp_hit_received) <= 3.0:
				entry_kind = "knocked_off"
			else:
				var local_position: Vector2 = player.global_position - player.realm_origin
				var outside_sides: bool = local_position.x < 0.0 or local_position.x > player.realm_size.x
				if outside_sides or player.ai_controller._over_void(player):
					entry_kind = "walked_or_dashed_off"
			totals.frey_recovery_entries[entry_kind] = int(totals.frey_recovery_entries.get(entry_kind, 0)) + 1
	elif not recovering and bool(memory.recovery):
		memory.recovery = false
		match_recovery_success += 1
		_add_recovery(player.character_id, "success")
		for event in memory.recovery_skill_pending:
			event.reached_floor = true
			recovery_skill_rows.append(event.duplicate())
			var stats: Dictionary = totals.recovery_skills.get(str(player.character_id), {"used": 0, "reached_floor": 0})
			stats.reached_floor = int(stats.reached_floor) + 1
			totals.recovery_skills[str(player.character_id)] = stats
		memory.recovery_skill_pending.clear()

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
		var portal_reason := "off_screen_hop"
		if str(memory.portal_reason).begins_with("realm collapsing") or (str(memory.portal_reason) == "" and str(main.director.get_state(old_realm)) == "warning"):
			portal_reason = "escape"
		elif str(memory.portal_reason).begins_with("low HP"):
			portal_reason = "retreat"
		elif str(memory.portal_reason).begins_with("nobody here"):
			portal_reason = "roam"
		_add_number(totals.portal_reasons, portal_reason, 1.0)
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
	var memory: Dictionary = player_memory.get(pid, {})
	if not memory.is_empty():
		memory.last_damage_time = now
		memory.last_damage_source = source
		if source == "hit" and is_instance_valid(attacker) and attacker.is_in_group("players"):
			memory.last_pvp_hit_received = now
	if player_memory.has(pid):
		for event in player_memory[pid].low_hp_pending:
			event.damaged = true
	if source == "hit":
		last_pvp_damage[int(player.realm_index)] = now
		if is_instance_valid(attacker) and attacker.is_in_group("players"):
			recent_pair_hits["%d|%d" % [attacker.get_instance_id(), player.get_instance_id()]] = now
			if bool(player.is_guarding):
				var guard_stats := _guard_stats(str(attacker.character_id))
				guard_stats.blocks = int(guard_stats.blocks) + 1
				var attacker_memory: Dictionary = player_memory.get(attacker.get_instance_id(), {})
				var combo_step := int(attacker_memory.get("last_combo_step", 0))
				if combo_step == 2:
					guard_stats.combo_2_blocks = int(guard_stats.combo_2_blocks) + 1
				elif combo_step == 3:
					guard_stats.combo_3_blocks = int(guard_stats.combo_3_blocks) + 1
				totals.guards_by_attacker[str(attacker.character_id)] = guard_stats
			_mark_attack_hit(attacker, amount, now)
			_mark_swing_context_hit(attacker, now)
			_add_number(totals.pvp_damage, str(attacker.character_id), amount)
			if str(player.character_id) == "yuki":
				var toward_attacker := signf(attacker.global_position.x - player.global_position.x)
				memory.last_yuki_hit_near_ledge = bool(player.ai_controller._cornered(player, toward_attacker))
				memory.last_yuki_hit_time = now
			if str(attacker.character_id) == "nova":
				var attacker_memory: Dictionary = player_memory.get(attacker.get_instance_id(), {})
				if not attacker_memory.is_empty() and not attacker_memory.nova_launch_pending.is_empty() and now - float(attacker_memory.nova_launch_pending.time) <= NOVA_LAUNCH_HIT_WINDOW:
					attacker_memory.nova_launch_pending.hit = true
		return
	var previous_ringouts := int(player_memory[pid].ringouts) if player_memory.has(pid) else int(player.respawn_count)
	if int(player.respawn_count) <= previous_ringouts:
		return
	match_ringouts += 1
	memory = player_memory[pid]
	memory.ringouts = int(player.respawn_count)
	var recovery_active := bool(memory.recovery)
	if recovery_active:
		memory.recovery = false
		match_recovery_fail += 1
		_add_recovery(player.character_id, "fail")
		for event in memory.recovery_skill_pending:
			recovery_skill_rows.append(event.duplicate())
		memory.recovery_skill_pending.clear()
	ringout_rows.append({
		"seed": match_seed, "time": snappedf(now, 0.1), "phase": str(main.director.phase),
		"victim": str(player.character_id), "attacker": str(attacker.character_id) if is_instance_valid(attacker) and attacker.is_in_group("players") else "environment",
		"air_jumps_left": int(player.air_jumps_left), "max_air_jumps": int(player.max_air_jumps),
		"during_recovery": recovery_active, "realm": int(player.realm_index)
	})
	if now - float(memory.last_air_down_time) <= AIR_DOWN_RINGOUT_WINDOW:
		_add_number(totals.air_down_self_ringouts, str(player.character_id), 1.0)
	if now - float(memory.last_corner_escape_time) <= CORNER_ESCAPE_RINGOUT_WINDOW:
		_add_number(totals.corner_escapes, "%s_ringout_within_3s" % str(player.character_id), 1.0)
		for index in range(corner_escape_rows.size() - 1, -1, -1):
			var escape_event: Dictionary = corner_escape_rows[index]
			if escape_event.character == str(player.character_id) and int(escape_event.seed) == match_seed and now - float(escape_event.time) <= CORNER_ESCAPE_RINGOUT_WINDOW:
				escape_event.ringout_within_3s = true
				break
	if str(player.character_id) == "yuki":
		totals.yuki_ledge_ringouts.all = int(totals.yuki_ledge_ringouts.all) + 1
		if bool(memory.last_yuki_hit_near_ledge) and is_instance_valid(player.last_attacker):
			totals.yuki_ledge_ringouts.near_ledge = int(totals.yuki_ledge_ringouts.near_ledge) + 1
			(ringout_rows[ringout_rows.size() - 1] as Dictionary)["last_hit_near_ledge"] = true
			(ringout_rows[ringout_rows.size() - 1] as Dictionary)["last_hit_age"] = snappedf(now - float(memory.last_yuki_hit_time), 0.01)
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
		for event in memory.recovery_skill_pending:
			recovery_skill_rows.append(event.duplicate())
		memory.recovery_skill_pending.clear()
		for event in memory.low_hp_pending:
			var followed: float = now - float(event.time)
			event["hp_after"] = snappedf(player.hp, 0.1)
			event["follow_seconds"] = snappedf(followed, 0.1)
			event["survived_10s"] = not player.is_defeated and followed >= LOW_HP_FOLLOW_SECONDS
			low_hp_rows.append(event.duplicate())
		if str(player.character_id) == "nova" and not memory.nova_launch_pending.is_empty():
			if bool(memory.nova_launch_pending.hit):
				totals.nova.hits = int(totals.nova.hits) + 1
			memory.nova_launch_pending = {}
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
	for attacker in totals.guards_by_attacker:
		var guard_row: Dictionary = totals.guards_by_attacker[attacker]
		print("QA14_GUARD attacker=%s reactions=%d too_late=%d raised=%d blocks=%d parries=%d combo2=%d combo3=%d recovery_detections=%d" % [attacker, guard_row.reactions, guard_row.get("too_late", 0), guard_row.raised, guard_row.blocks, guard_row.parries, guard_row.get("combo_2_blocks", 0), guard_row.get("combo_3_blocks", 0), guard_row.reaction_in_recovery])
	print("QA14_NOVA launches=%d aimed=%d forced=%d redirects=%d hits=%d" % [totals.nova.launches, totals.nova.aimed, totals.nova.forced, totals.nova.redirects, totals.nova.hits])
	print("QA14_OUTPUT ", ProjectSettings.globalize_path(OUT_PATH))
