extends "res://tests/analysis/lead/luna_beam_probe.gd"
## Two candidate common rules against knockback piling up under an ultimate's hits, tried in
## whole bot matches without changing the game (2026-11-25, the lead's question before the user
## picks for Luna's beam: reports/luna-beam-2026-11-25/).
## Usage: <godot> --headless --path . --fixed-fps 60 -s tests/analysis/lead/ult_rule_probe.gd -- --seconds=480 --seed=2001 --rule=none|a|b
##   none  the game as it is: must replay tests/soak_match.gd
##   a     a hit landed in an ultimate window gives normal hitstop (0.065 s to the target, 0.045 s
##         to the attacker, not 2.2x) when the same attacker hit that target RAPID s ago or less:
##         the first hit of a run keeps the long freeze, the hits that follow do not
##   b     knockback fades during hitstop as it does outside it (the fighter still does not move)
## How each is put on from outside:
##   a     the game sets the long hitstop inside the hit; at the start of the next physics frame
##         the probe cuts it to what the short one would have left by then
##   b     at the start of every physics frame the probe fades the knockback of every fighter
##         that is in hitstop by one frame of its own decay (that fighter's own step is skipped)
## The SOAK_RESULT line gains "rule" and "stack": per attacking character {"casts", "hits":
## hits landed in its ultimate window, "carried": [per cast that hit, the largest knockback speed
## a target already carried before one of its hits, px/s]}, on top of luna_beam_probe's blocks.

const RAPID := 0.3
const VICTIM_HITSTOP := 0.065
const ATTACKER_HITSTOP := 0.045
const ULTIMATE_HITSTOP_SCALE := 2.2

var rule := "none"
var stack: Dictionary = {}
var cast_peak: Dictionary = {}
var cast_owner: Dictionary = {}
## "<attacker id>:<target id>" -> the frame of that attacker's last hit on that target.
var last_hit: Dictionary = {}
## Hits of the frame before whose hitstop rule "a" shortens: [target, attacker].
var to_shorten: Array = []
var shortened := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--rule="):
			rule = arg.get_slice("=", 1)
	if not ["none", "a", "b"].has(rule):
		push_error("--rule must be none, a or b; got %s" % rule)
		quit(2)
		return
	super._initialize()

func _check_positions() -> void:
	super._check_positions()
	if rule == "a":
		for pair in to_shorten:
			_shorten(pair[0], VICTIM_HITSTOP)
			_shorten(pair[1], ATTACKER_HITSTOP)
		to_shorten.clear()
	elif rule == "b":
		for player in main.players:
			if is_instance_valid(player) and not bool(player.is_defeated) and float(player.hitstop_timer) > 0.0:
				player.knockback_velocity = player.knockback_velocity.move_toward(Vector2.ZERO, float(player.current_knockback_decay) * FRAME_TIME)

## The long hitstop a hit just set, cut to what the short one would have left by now. Left alone
## when the timer is not the long one any more (another hit set its own since).
func _shorten(fighter: Variant, short: float) -> void:
	if not is_instance_valid(fighter):
		return
	var long := short * ULTIMATE_HITSTOP_SCALE
	var timer: float = float(fighter.hitstop_timer)
	var elapsed := long - timer
	if timer <= 0.0 or elapsed < -0.001 or elapsed > FRAME_TIME + 0.001:
		return
	fighter.hitstop_timer = maxf(short - elapsed, 0.0)
	shortened += 1

func _on_damaged(player: Node, amount: float, attacker: Variant, source: String) -> void:
	super._on_damaged(player, amount, attacker, source)
	if source != "hit" or not is_instance_valid(attacker) or not attacker.is_in_group("players"):
		return
	if float(attacker.ultimate_window_timer) <= 0.0:
		return
	var id := str(attacker.character_id)
	if not stack.has(id):
		stack[id] = {"hits": 0}
	stack[id].hits = int(stack[id].hits) + 1
	var cast := "%d:%d" % [attacker.get_instance_id(), int(attacker.move_counts.get("i", 0.0))]
	cast_owner[cast] = id
	cast_peak[cast] = maxf(float(cast_peak.get(cast, 0.0)), float(player.knockback_velocity.length()))
	var pair := "%d:%d" % [attacker.get_instance_id(), player.get_instance_id()]
	if rule == "a" and last_hit.has(pair) and frame_index - int(last_hit[pair]) <= int(RAPID / FRAME_TIME):
		to_shorten.append([player, attacker])
	last_hit[pair] = frame_index

func _collect_result(finished_early: bool) -> Dictionary:
	var result := super._collect_result(finished_early)
	for player in main.players:
		if not is_instance_valid(player):
			continue
		var id := str(player.character_id)
		if not stack.has(id):
			stack[id] = {"hits": 0}
		stack[id]["casts"] = int(stack[id].get("casts", 0)) + int(player.move_counts.get("i", 0.0))
	for cast in cast_peak:
		var id: String = cast_owner[cast]
		if not stack[id].has("carried"):
			stack[id]["carried"] = []
		stack[id]["carried"].append(snappedf(float(cast_peak[cast]), 1.0))
	result["rule"] = rule
	result["shortened"] = shortened
	result["stack"] = stack
	return result
