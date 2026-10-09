extends "res://tests/analysis/codex_qa_14/bot_behavior_probe_round16.gd"
## Lead's sweep for the Codex QA-17 round-2 retest (Codex hit its usage limit on 2026-10-10):
## the Round 16 probe with its target-selection check skipped (it calls
## EnemyAI._walkable_between, which went away with the S0 bot code) plus counters for Frey's
## pursuit and spike and Luna's stars, printed after every match as LEAD_PASSIVE.
## Run: --script tests/analysis/lead/sweep_r2.gd -- --seed=101 --count=12 --seconds=480 --players=8 --variant=current

var passive := {}
var passive_state := {}

func _selection_mode(_player: Node, _chosen: Node) -> String:
	return "skipped"

func _run_match(value: int) -> void:
	await super._run_match(value)
	print("LEAD_PASSIVE seed=%d %s" % [value, JSON.stringify(passive)])

func _observe_frame() -> void:
	super._observe_frame()
	if not is_instance_valid(main):
		return
	for player in main.players:
		if not is_instance_valid(player):
			continue
		var id: int = player.get_instance_id()
		var cid: String = str(player.character_id)
		if cid != "frey" and cid != "luna":
			continue
		var counters: Dictionary = passive.get(cid, {"marks": 0, "pursuit_seconds": 0.0, "spike_windows": 0, "spikes": 0, "stars": 0, "full_charges": 0, "cooldown_cut": 0.0})
		var last: Dictionary = passive_state.get(id, {})
		if cid == "frey":
			var marked: bool = is_instance_valid(player.pursuit_target) and float(player.pursuit_timer) > 0.0
			if marked and not bool(last.get("marked", false)):
				counters.marks += 1
			if marked:
				counters.pursuit_seconds += FRAME_TIME
			last.marked = marked
			var window: bool = float(player.rising_followup_timer) > 0.0
			if window and not bool(last.get("window", false)):
				counters.spike_windows += 1
				last.spiked = false
			if bool(last.get("window", false)) and bool(player.action_locked_until_land) and not bool(last.get("spiked", true)):
				counters.spikes += 1
				last.spiked = true
			last.window = window
		else:
			var stars := int(player.star_charge)
			var cooldown := float(player.ultimate_cooldown_timer)
			var old_stars := int(last.get("stars", 0))
			var old_cooldown := float(last.get("cooldown", cooldown))
			if stars > old_stars:
				counters.stars += stars - old_stars
			elif stars == 0 and old_stars > 0 and old_cooldown - cooldown > 3.0:
				counters.stars += 5 - old_stars
				counters.full_charges += 1
				counters.cooldown_cut += minf(6.0, old_cooldown)
			last.stars = stars
			last.cooldown = cooldown
		passive[cid] = counters
		passive_state[id] = last
