extends "res://scripts/EnemyAI.gd"
## Probe-only Round 16 U0 controller. Restore only R11's already-scaled x2
## ultimate reach values; every other current AI rule remains unchanged.

const QA16_R11_ULTIMATE_REACH := {
	"frey": 480.0, "yuki": 820.0, "luna": 420.0, "nova": 460.0, "rio": 900.0
}

func _ultimate_score(player) -> int:
	if not is_instance_valid(target):
		return 0
	var score := 0
	var distance: float = player.global_position.distance_to(target.global_position)
	if distance <= float(QA16_R11_ULTIMATE_REACH.get(player.character_id, 400.0)):
		score += 2
	if float(target.hp) / maxf(float(target.max_hp), 1.0) <= 0.35:
		score += 1
	if float(target.hitstun_timer) > 0.0 or float(target.attack_lock_timer) > 0.0:
		score += 1
	for other in player.get_tree().get_nodes_in_group("players"):
		if other != player and other != target and _is_valid_target_candidate(player, other) and other.global_position.distance_to(target.global_position) <= 260.0 * GAME_SCALE.COMBAT:
			score += 1
			break
	if player.character_id == "nova" and not _mobility_skill_is_safe(player):
		score -= 3
	if player.character_id == "luna" and float(player.hp) / maxf(float(player.max_hp), 1.0) >= 0.5:
		score += 1
	return score
