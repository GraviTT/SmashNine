extends "res://tests/soak_match.gd"
## Does knockback pile up under an ultimate's hits? (2026-11-25, after Brave Luna's star beam.)
## A fighter in hitstop skips its whole physics step: it does not move and its knockback does not
## fade. While an attacker's ultimate window is open its hits give 2.2x hitstop (0.143 s), so
## hits that come faster than that keep their target frozen and each one adds its knockback to
## what is already there; the sum is let go at once when the hits stop.
## This watches whole bot matches: for every hit a fighter lands while its ultimate window is
## open, the knockback speed its target already carries (the hit's own is not added yet) and
## whether the target is frozen in hitstop.
## Usage: <godot> --headless --path . --fixed-fps 60 -s tests/analysis/lead/ult_stack_probe.gd -- --seconds=480 --seed=2001
## The SOAK_RESULT line gains "stack": per attacking character {"casts": ultimates cast,
## "hits": hits landed in the window, "frozen": those on a target in hitstop, "carried": [per cast
## that hit, the largest speed a target carried before a hit, px/s]}.

var tally: Dictionary = {}
## "<attacker id>:<its ultimate number>" -> the largest speed carried before one of its hits.
var cast_peak: Dictionary = {}
var cast_owner: Dictionary = {}

func _on_damaged(player: Node, amount: float, attacker: Variant, source: String) -> void:
	super._on_damaged(player, amount, attacker, source)
	if source != "hit" or not is_instance_valid(attacker) or not attacker.is_in_group("players"):
		return
	if float(attacker.ultimate_window_timer) <= 0.0:
		return
	var id := str(attacker.character_id)
	if not tally.has(id):
		tally[id] = {"hits": 0, "frozen": 0}
	var row: Dictionary = tally[id]
	row.hits = int(row.hits) + 1
	if float(player.hitstop_timer) > 0.0:
		row.frozen = int(row.frozen) + 1
	var key := "%d:%d" % [attacker.get_instance_id(), int(attacker.move_counts.get("i", 0.0))]
	cast_owner[key] = id
	cast_peak[key] = maxf(float(cast_peak.get(key, 0.0)), float(player.knockback_velocity.length()))

func _collect_result(finished_early: bool) -> Dictionary:
	var result := super._collect_result(finished_early)
	for player in main.players:
		if not is_instance_valid(player):
			continue
		var id := str(player.character_id)
		if not tally.has(id):
			tally[id] = {"hits": 0, "frozen": 0}
		tally[id]["casts"] = int(tally[id].get("casts", 0)) + int(player.move_counts.get("i", 0.0))
	for key in cast_peak:
		var id: String = cast_owner[key]
		if not tally[id].has("carried"):
			tally[id]["carried"] = []
		tally[id]["carried"].append(snappedf(float(cast_peak[key]), 1.0))
	result["stack"] = tally
	return result
