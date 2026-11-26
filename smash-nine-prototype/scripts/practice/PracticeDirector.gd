extends "res://scripts/match/MatchDirector.gd"
## Practice mode (quality track, 2026-11-26): the central realm alone and no timeline. Nothing
## collapses, nobody is eliminated, nobody wins; the clock only counts up. Fights follow the
## central brawl's numbers (ring-out damage, no regeneration, bots at full aggression): that is
## the phase a match is decided in, and combat damage is the same in every phase.

const PHASE_PRACTICE := "Practice"

func setup(new_layout: REALM_LAYOUT) -> void:
	super.setup(new_layout)
	events.clear()
	for index in realm_states.size():
		realm_states[index] = STATE_STABLE if index == central_index else STATE_LOCKED
	phase = PHASE_PRACTICE

func advance(delta: float) -> void:
	match_elapsed += delta

## A fall is not an elimination here: PracticeSession stands the fighter up again.
func _on_combatant_defeated(_combatant: Node, _attacker: Node) -> void:
	pass

## A practice target that leaves (H and N swap it for another).
func unregister_combatant(combatant: Node) -> void:
	combatants.erase(combatant)

func get_ringout_damage() -> float:
	return float(RINGOUT_DAMAGE[PHASE_CENTRAL])

func get_recovery_rate() -> float:
	return float(RECOVERY_RATE[PHASE_CENTRAL])

func get_bot_aggression() -> float:
	return float(BOT_AGGRESSION[PHASE_CENTRAL])
