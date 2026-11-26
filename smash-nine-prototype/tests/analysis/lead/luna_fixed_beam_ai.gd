extends "res://scripts/EnemyAI.gd"
## Probe-only bot brain (tests/analysis/lead/luna_beam_probe.gd, variant "fixed"): Brave Luna's
## star beam pressed the way bots pressed it until 2026-11-24, once, 4.4 s after the ultimate
## press, whatever stands in front of her (the 0.6 s retry is the base class's). Everything else,
## her cyclone rule included, is the current brain.

const FIXED_FOLLOWUPS := {"luna": [4.4]}

func _schedule_ultimate_followups(player) -> void:
	ultimate_followup_delays.clear()
	for delay in FIXED_FOLLOWUPS.get(player.character_id, []):
		ultimate_followup_delays.append(float(delay))
	ultimate_followup_timer = ultimate_followup_delays.pop_front() if not ultimate_followup_delays.is_empty() else 0.0

## The cyclone half of EnemyAI._drive_luna_brave, word for word; the beam half is left out.
func _drive_luna_brave(player) -> void:
	if not bool(player.transformed) or bool(player.transformation_finishing):
		return
	var has_foe: bool = is_instance_valid(target) and target.is_in_group("players")
	var offset: Vector2 = target.global_position - player.global_position if has_foe else Vector2.ZERO
	var side: int = (1 if offset.x > 0.0 else -1) if absf(offset.x) > 1.0 else int(player.facing)
	if float(player.cyclone_timer) > 0.0:
		var spun: float = float(player.CYCLONE_TIME) - float(player.cyclone_timer)
		if has_foe and spun >= LUNA_CYCLONE_SPIN_MIN and absf(offset.x) <= LUNA_CYCLONE_REACH * GAME_SCALE.COMBAT and absf(offset.y) <= LUNA_CYCLONE_HALF_HEIGHT * GAME_SCALE.COMBAT:
			player.facing = side
			if player.try_skill_two_followup():
				player.count_move("l2")
				debug_reason = "star cyclone: fired at a foe in its path"
