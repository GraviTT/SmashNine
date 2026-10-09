extends "res://tests/analysis/codex_qa_17/match_probe.gd"

## Independent Round 2b match probe. The Round 1 spike detector required the follow-up window and
## the landing lock to be true simultaneously. _spike_start clears the window immediately, so this
## copy detects the transition from an observed open window to a closed window plus landing lock.

var frey_followups_r2b := {"opportunities": 0, "spikes": 0}
var armor_absorbed_hits := 0
var armor_by_character := {}

func _run() -> void:
	var wall_start := Time.get_ticks_usec()
	for value in seeds:
		await _run_match(value)
	for row in ultimate_rows:
		row.likely_cancelled = bool(row.hit_within_1s) and int(row.hit_events) == 0
	var result := {
		"schema": 2, "seeds": seeds, "players": player_count, "fixed_fps": 60,
		"wall_seconds": snappedf(float(Time.get_ticks_usec() - wall_start) / 1000000.0, 0.001),
		"matches": match_rows, "ultimate_events": ultimate_rows,
		"luna_forms": luna_forms, "frey_followups": frey_followups_r2b,
		"armor_absorbed_hits": armor_absorbed_hits, "armor_by_character": armor_by_character,
		"definitions": {
			"hit_within_1s": "caster received PvP damage in [cast, cast+1.0s]",
			"likely_cancelled": "hit within 1s and the cast produced zero PvP ultimate-window hit events; inference, not a cancellation signal",
			"armor_absorbed_hit": "PvP damaged signal fired while victim ultimate_armor_timer > 0; full damage but no knockback/hitstun/cancel",
			"frey_opportunity": "rising_followup_timer changed closed->open",
			"frey_spike": "after an observed open window, timer changed open->closed while action_locked_until_land became true",
			"heart_laser": "heart_laser node became valid during that transformation"
		}
	}
	result.summary = _summary_r2b()
	var path := ProjectSettings.globalize_path("res://../reports/codex-qa-17/round-2-codex/match-raw-r2b.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("QA17_R2B_MATCH_RESULT ", JSON.stringify(result.summary))
	quit(0)

func _on_damaged(victim: Node, amount: float, attacker: Node, source: String) -> void:
	super._on_damaged(victim, amount, attacker, source)
	if source != "hit" or not is_instance_valid(attacker) or not attacker.is_in_group("players"):
		return
	if float(victim.ultimate_armor_timer) <= 0.0:
		return
	armor_absorbed_hits += 1
	var character := str(victim.character_id)
	armor_by_character[character] = int(armor_by_character.get(character, 0)) + 1
	var victim_id := victim.get_instance_id()
	if active_ultimates.has(victim_id):
		var index := int(active_ultimates[victim_id])
		if index >= 0 and index < ultimate_rows.size():
			var row: Dictionary = ultimate_rows[index]
			row.armor_absorbed_hits = int(row.get("armor_absorbed_hits", 0)) + 1
			ultimate_rows[index] = row

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
			var was_open := bool(memory.followup_open)
			if open and not was_open:
				frey_followups_r2b.opportunities = int(frey_followups_r2b.opportunities) + 1
				memory.followup_spiked = false
			if was_open and not open and bool(player.action_locked_until_land) and not bool(memory.followup_spiked):
				frey_followups_r2b.spikes = int(frey_followups_r2b.spikes) + 1
				memory.followup_spiked = true
			memory.followup_open = open
		fighter_memory[pid] = memory

func _summary_r2b() -> Dictionary:
	var summary := {
		"ultimates": {},
		"luna_forms": {"count": luna_forms.size(), "lasers": 0, "seconds": 0.0},
		"frey_followups": frey_followups_r2b,
		"armor_absorbed_hits": armor_absorbed_hits,
		"armor_by_character": armor_by_character
	}
	for row in ultimate_rows:
		var character := str(row.character)
		if not summary.ultimates.has(character):
			summary.ultimates[character] = {"casts": 0, "hit_within_1s": 0, "likely_cancelled": 0, "armor_absorbed_hits": 0}
		var group: Dictionary = summary.ultimates[character]
		group.casts += 1
		group.hit_within_1s += 1 if row.hit_within_1s else 0
		group.likely_cancelled += 1 if row.hit_within_1s and int(row.hit_events) == 0 else 0
		group.armor_absorbed_hits += int(row.get("armor_absorbed_hits", 0))
	for form in luna_forms:
		summary.luna_forms.lasers += 1 if form.heart_laser else 0
		summary.luna_forms.seconds += float(form.duration)
	if luna_forms.size() > 0:
		summary.luna_forms.avg_seconds = snappedf(float(summary.luna_forms.seconds) / float(luna_forms.size()), 0.01)
	return summary
