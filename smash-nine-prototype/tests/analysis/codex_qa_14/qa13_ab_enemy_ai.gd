extends "res://scripts/EnemyAI.gd"
## Probe-only A/B controller. Variant B suppresses recovery for a whole airborne
## episode when the live R11 arc rejects the fall but the R10 vertical probes
## accept it. Product source is not changed.

const QA13_R10_TIMES: Array[float] = [0.0, 0.25, 0.5, 0.8]
const QA13_R10_MAX_AHEAD := 540.0
const QA13_R10_DEPTH := 1050.0

var qa13_suppress_active := false
var qa13_suppress_serial := 0
var qa13_suppress_started := false

func reset(position: Vector2) -> void:
	super.reset(position)
	qa13_suppress_active = false
	qa13_suppress_started = false

func _needs_recovery(player) -> bool:
	qa13_suppress_started = false
	if qa13_suppress_active:
		if player.is_on_floor():
			qa13_suppress_active = false
			return false
		# The experiment intentionally leaves normal combat movement in control until
		# this airborne episode lands or rings out.
		return false

	var live_need: bool = super._needs_recovery(player)
	if not live_need or state == STATE_RECOVER or player.is_on_floor() or player.velocity.y <= 0.0:
		return live_need
	if _landing_in_fall(player) or not _qa13_r10_landing(player):
		return live_need
	qa13_suppress_active = true
	qa13_suppress_started = true
	qa13_suppress_serial += 1
	return false

func _qa13_r10_landing(player) -> bool:
	var foot: Vector2 = player.global_position
	for seconds_ahead in QA13_R10_TIMES:
		var ahead: float = clampf(player.velocity.x * seconds_ahead, -QA13_R10_MAX_AHEAD, QA13_R10_MAX_AHEAD)
		var from: Vector2 = foot + Vector2(ahead, 0.0)
		if _ray_hits_world(player, from, from + Vector2(0.0, QA13_R10_DEPTH)):
			return true
	return false
