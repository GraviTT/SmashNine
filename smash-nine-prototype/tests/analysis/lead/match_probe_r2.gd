extends SceneTree
## Lead copy of Codex QA-17 match_probe.gd for the round-2 retest (Codex hit its usage limit):
## writes to PROBE_OUT and counts hits the ultimate armor absorbed.

const MAIN_SCENE := "res://scenes/Main.tscn"
const FRAME_TIME := 1.0 / 60.0

var seeds: Array[int] = []
var seconds := 480.0
var player_count := 8
var main: Node
var match_seed := 0
var ultimate_rows: Array[Dictionary] = []
var active_ultimates: Dictionary = {}
var fighter_memory: Dictionary = {}
var luna_forms: Array[Dictionary] = []
var frey_followups := {"opportunities": 0, "spikes": 0}
var match_rows: Array[Dictionary] = []

func _initialize() -> void:
	var first_seed := 201
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
	call_deferred("_run")

func _run() -> void:
	var wall_start := Time.get_ticks_usec()
	for value in seeds:
		await _run_match(value)
	var result := {
		"schema": 1, "seeds": seeds, "players": player_count, "fixed_fps": 60,
		"wall_seconds": snappedf(float(Time.get_ticks_usec() - wall_start) / 1000000.0, 0.001),
		"matches": match_rows, "ultimate_events": ultimate_rows,
		"luna_forms": luna_forms, "frey_followups": frey_followups,
		"definitions": {
			"hit_within_1s": "caster received PvP damage in [cast, cast+1.0s]",
			"likely_cancelled": "hit within 1s and the cast produced zero PvP ultimate-window hit events; this is an inference, not direct state proof",
			"luna_form_duration": "physics-frame time from transformed false->true to true->false",
			"heart_laser": "heart_laser node first became valid during that form",
			"frey_spike": "rising follow-up opportunity followed by action_locked_until_land before its timer expired"
		}
	}
	for row in ultimate_rows:
		row.likely_cancelled = bool(row.hit_within_1s) and int(row.hit_events) == 0
	var path := OS.get_environment("PROBE_OUT")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("QA17_MATCH_RESULT ", JSON.stringify(_summary()))
	quit(0)

func _run_match(value: int) -> void:
	match_seed = value
	seed(value)
	fighter_memory.clear()
	active_ultimates.clear()
	main = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.match_seed = value
	main.player_count = player_count
	root.add_child(main)
	await process_frame
	for player in main.players:
		player.ultimate_cast.connect(_on_ultimate_cast)
		player.damaged.connect(_on_damaged)
		fighter_memory[player.get_instance_id()] = {
			"character": str(player.character_id), "transformed": false,
			"form_start": -1.0, "form_laser": false,
			"laser_valid": false, "followup_open": false, "followup_spiked": false
		}
	var frame_limit := int(seconds / FRAME_TIME)
	for _frame in frame_limit:
		await physics_frame
		_observe_frame()
		if main.match_over:
			break
	_finalize_forms()
	match_rows.append({"seed": value, "seconds": snappedf(float(main.director.match_elapsed), 0.1), "finished": bool(main.match_over)})
	print("QA17_MATCH seed=%d seconds=%.1f ultimates=%d forms=%d" % [value, main.director.match_elapsed, ultimate_rows.size(), luna_forms.size()])
	main.queue_free()
	await process_frame
	await process_frame
	main = null

func _on_ultimate_cast(caster: Node) -> void:
	var row := {
		"seed": match_seed, "time": snappedf(float(main.director.match_elapsed), 0.01),
		"caster_id": caster.get_instance_id(), "character": str(caster.character_id),
		"grounded": bool(caster.is_on_floor()), "hit_within_1s": false,
		"first_hit_age": -1.0, "hit_events": 0, "damage": 0.0, "armor_absorbed": 0
	}
	ultimate_rows.append(row)
	active_ultimates[caster.get_instance_id()] = ultimate_rows.size() - 1

func _on_damaged(victim: Node, amount: float, attacker: Node, source: String) -> void:
	if source != "hit" or not is_instance_valid(main):
		return
	var now: float = main.director.match_elapsed
	var victim_id := victim.get_instance_id()
	if active_ultimates.has(victim_id):
		var own_index := int(active_ultimates[victim_id])
		if own_index >= 0 and own_index < ultimate_rows.size():
			var own: Dictionary = ultimate_rows[own_index]
			var age := now - float(own.time)
			if age >= 0.0 and age <= 1.0 and is_instance_valid(attacker) and attacker.is_in_group("players"):
				if float(victim.get("ultimate_armor_timer") if victim.get("ultimate_armor_timer") != null else 0.0) > 0.0:
					own.armor_absorbed = int(own.armor_absorbed) + 1
				own.hit_within_1s = true
				if float(own.first_hit_age) < 0.0:
					own.first_hit_age = snappedf(age, 0.01)
				ultimate_rows[own_index] = own
	if not is_instance_valid(attacker) or not attacker.is_in_group("players"):
		return
	var attacker_id := attacker.get_instance_id()
	if active_ultimates.has(attacker_id) and float(attacker.ultimate_window_timer) > 0.0:
		var attack_index := int(active_ultimates[attacker_id])
		if attack_index >= 0 and attack_index < ultimate_rows.size():
			var attack_row: Dictionary = ultimate_rows[attack_index]
			attack_row.hit_events = int(attack_row.hit_events) + 1
			attack_row.damage = snappedf(float(attack_row.damage) + amount, 0.01)
			ultimate_rows[attack_index] = attack_row

func _observe_frame() -> void:
	if not is_instance_valid(main):
		return
	var now: float = main.director.match_elapsed
	for player in main.players:
		if not is_instance_valid(player) or not fighter_memory.has(player.get_instance_id()):
			continue
		var pid: int = int(player.get_instance_id())
		var memory: Dictionary = fighter_memory[pid]
		if str(player.character_id) == "luna":
			var transformed := bool(player.transformed)
			if transformed and not bool(memory.transformed):
				memory.form_start = now
				memory.form_laser = false
			if transformed and is_instance_valid(player.heart_laser):
				memory.form_laser = true
			if not transformed and bool(memory.transformed):
				luna_forms.append({
					"seed": match_seed, "start": snappedf(float(memory.form_start), 0.01),
					"duration": snappedf(now - float(memory.form_start), 0.01),
					"heart_laser": bool(memory.form_laser)
				})
			memory.transformed = transformed
		elif str(player.character_id) == "frey":
			var open := float(player.rising_followup_timer) > 0.0
			if open and not bool(memory.followup_open):
				frey_followups.opportunities = int(frey_followups.opportunities) + 1
				memory.followup_spiked = false
			if open and bool(player.action_locked_until_land) and not bool(memory.followup_spiked):
				frey_followups.spikes = int(frey_followups.spikes) + 1
				memory.followup_spiked = true
			memory.followup_open = open
		fighter_memory[pid] = memory

func _finalize_forms() -> void:
	if not is_instance_valid(main):
		return
	var now: float = main.director.match_elapsed
	for player in main.players:
		if not is_instance_valid(player) or not fighter_memory.has(player.get_instance_id()):
			continue
		var memory: Dictionary = fighter_memory[player.get_instance_id()]
		if str(player.character_id) == "luna" and bool(memory.transformed):
			luna_forms.append({"seed": match_seed, "start": snappedf(float(memory.form_start), 0.01), "duration": snappedf(now - float(memory.form_start), 0.01), "heart_laser": bool(memory.form_laser), "censored": true})

func _summary() -> Dictionary:
	var summary := {"ultimates": {}, "luna_forms": {"count": luna_forms.size(), "lasers": 0, "seconds": 0.0}, "frey_followups": frey_followups}
	for row in ultimate_rows:
		var character := str(row.character)
		if not summary.ultimates.has(character):
			summary.ultimates[character] = {"casts": 0, "hit_within_1s": 0, "likely_cancelled": 0, "armor_absorbed": 0}
		var group: Dictionary = summary.ultimates[character]
		group.casts += 1
		group.hit_within_1s += 1 if row.hit_within_1s else 0
		group.likely_cancelled += 1 if row.hit_within_1s and int(row.hit_events) == 0 else 0
		group.armor_absorbed += int(row.get("armor_absorbed", 0))
	for form in luna_forms:
		summary.luna_forms.lasers += 1 if form.heart_laser else 0
		summary.luna_forms.seconds += float(form.duration)
	if luna_forms.size() > 0:
		summary.luna_forms.avg_seconds = snappedf(float(summary.luna_forms.seconds) / float(luna_forms.size()), 0.01)
	return summary
