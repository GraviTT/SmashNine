extends "res://tests/soak_match.gd"
## How many hits between fighters take exactly the 1.0 HP floor in a whole bot match
## (2026-11-25). In a match combat damage is scaled by MatchDirector.COMBAT_DAMAGE_SCALE (0.26)
## and PlayerBase._calculate_incoming_damage never returns less than 1.0, so a hit whose own
## damage is small takes 1.0 HP whatever its number says (Brave Luna's beam tick: 2.2 x 0.26).
## Usage: <godot> --headless --path . --fixed-fps 60 -s tests/analysis/lead/damage_floor_probe.gd -- --seconds=480 --seed=2001
## The match is soak_match.gd's own; the SOAK_RESULT line gains "floor": per attacking character
## {"hits", "floored", "hp", "floored_hp"}.

const FLOOR := 1.0

var tally: Dictionary = {}

func _on_damaged(player: Node, amount: float, attacker: Variant, source: String) -> void:
	super._on_damaged(player, amount, attacker, source)
	if source != "hit" or not is_instance_valid(attacker) or not attacker.is_in_group("players"):
		return
	var id := str(attacker.character_id)
	if not tally.has(id):
		tally[id] = {"hits": 0, "floored": 0, "hp": 0.0, "floored_hp": 0.0}
	var row: Dictionary = tally[id]
	row.hits = int(row.hits) + 1
	row.hp = float(row.hp) + amount
	if amount <= FLOOR + 0.0001:
		row.floored = int(row.floored) + 1
		row.floored_hp = float(row.floored_hp) + amount

func _collect_result(finished_early: bool) -> Dictionary:
	var result := super._collect_result(finished_early)
	for id in tally:
		tally[id].hp = snappedf(float(tally[id].hp), 0.1)
		tally[id].floored_hp = snappedf(float(tally[id].floored_hp), 0.1)
	result["floor"] = tally
	return result
