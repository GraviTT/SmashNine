extends "res://scripts/EnemyAI.gd"
## Probe-only bot brain (tests/analysis/lead/decoy_fooled_probe.gd): how often a bot takes Rio's
## decoy for him is a variable here; everything else is the current brain. The roll is made for
## every decoy whatever the chance, so the bots' random draws stay in step across chances.

var fooled_chance: float = DECOY_FOOLED_CHANCE

## EnemyAI._watch_decoy, word for word but for the chance.
func _watch_decoy(delta: float) -> void:
	fooled_timer = maxf(fooled_timer - delta, 0.0)
	if not is_instance_valid(fooled_by) or fooled_timer <= 0.0 or fooled_by.get("burst") == true:
		fooled_by = null
	if not is_instance_valid(target):
		return
	var decoy: Variant = target.get("decoy")
	if decoy == null or not is_instance_valid(decoy) or decoy == seen_decoy:
		return
	seen_decoy = decoy
	if randf() < fooled_chance:
		fooled_by = decoy
		fooled_timer = DECOY_FOOLED_TIME
		debug_reason = "took the decoy for him"
