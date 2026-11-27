extends "res://scripts/EnemyAI.gd"
## A bot brain that times its own thinking (frame_share_probe.gd). Same code: update() forwards.

static var total_ms := 0.0

func update(player, delta: float) -> void:
	var start := Time.get_ticks_usec()
	super.update(player, delta)
	total_ms += float(Time.get_ticks_usec() - start) / 1000.0
