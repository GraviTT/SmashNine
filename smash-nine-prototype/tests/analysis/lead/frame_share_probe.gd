extends "res://tests/analysis/lead/frame_time_probe.gd"
## Quality track 4 (2026-11-27): how much of a frame goes to the bots' brains. Every bot's
## EnemyAI is swapped at the start for a subclass that times update() and forwards to it (the
## same code runs, so the match is the same: SOAK_RESULT matches soak_match). Prints
## SHARE_RESULT {json}: per frame, the ms spent in all bots' update() against the whole frame,
## as P50/P95 and the share of the total. A share is a ratio: it holds even on a busy machine,
## where the absolute times do not.

const TIMED_AI := preload("res://tests/analysis/lead/timed_enemy_ai.gd")

var ai_ms: Array = []
var frame_ms: Array = []
var last_ai_total := 0.0

func _check_positions() -> void:
	if not _swapped:
		_swap_brains()
	var before := samples.size()
	super._check_positions()
	if samples.size() > before:
		var total := TIMED_AI.total_ms
		ai_ms.append(total - last_ai_total)
		frame_ms.append(float(samples[-1][0]))
	last_ai_total = TIMED_AI.total_ms

var _swapped := false

## Each bot gets the timed brain carrying over every variable of the one it had (its random
## numbers too), so the bots think exactly as they would have.
func _swap_brains() -> void:
	_swapped = true
	TIMED_AI.total_ms = 0.0
	for player in main.players:
		if is_instance_valid(player) and not player.is_human:
			var old: Object = player.ai_controller
			var brain := TIMED_AI.new()
			for property in old.get_property_list():
				if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
					brain.set(property.name, old.get(property.name))
			player.ai_controller = brain

func _collect_result(finished_early: bool) -> Dictionary:
	var result := super._collect_result(finished_early)
	var ai_total := 0.0
	var frame_total := 0.0
	for value in ai_ms:
		ai_total += float(value)
	for value in frame_ms:
		frame_total += float(value)
	print("SHARE_RESULT ", JSON.stringify({"players": main.players.size(), "seed": seed_value, "frames": frame_ms.size(),
		"ai_ms": _percentiles(ai_ms), "frame_ms": _percentiles(frame_ms),
		"ai_share": snappedf(ai_total / maxf(frame_total, 0.001), 0.001)}))
	return result
