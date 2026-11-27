extends "res://tests/soak_match.gd"
## Quality track 4 (2026-11-27): what one frame of a bot match costs, 8 or 16 players.
##   <godot> --headless --path . --fixed-fps 60 -s tests/analysis/lead/frame_time_probe.gd -- \
##       --seconds=480 --seed=N --players=16
## Headless: nothing is drawn, so this is the CPU side alone (scripts, physics, the bots).
## With --fixed-fps the loop does not wait for real time: the wall time between two physics frames
## is what one frame costs. Per frame it keeps that time, the engine's own physics and process
## times (Performance TIME_PHYSICS_PROCESS, TIME_PROCESS), the fighters alive and the phase, and
## prints P50/P95/P99 per group in FRAME_RESULT {json}. The first second (loading) is left out.
## Validated against soak_match: same seed, same SOAK_RESULT apart from the added keys.

const SKIP_FRAMES := 60

var last_usec := 0
## --no-bot-panel: the live bot panel hidden (it is on by default while testing; a player's game
## need not show it). The panel only shows the bots' state, so the match is the same.
var bot_panel_off := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--no-bot-panel":
			bot_panel_off = true
			load("res://scripts/Main.gd").session_bot_panel = false
	super._initialize()
var frame_index := 0
## [wall_ms, physics_ms, process_ms, alive, phase, bot panel refreshed in this frame]
var samples: Array = []
var last_panel_timer := 0.0

func _check_positions() -> void:
	super._check_positions()
	var now := Time.get_ticks_usec()
	frame_index += 1
	if last_usec > 0 and frame_index > SKIP_FRAMES:
		var alive := 0
		for player in main.players:
			if is_instance_valid(player) and not player.is_defeated:
				alive += 1
		# Main counts the bot panel's refresh down and sets it back to 0.1 s when it refreshes.
		var panel_timer: float = main.bot_panel_timer
		samples.append([float(now - last_usec) / 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			alive, str(main.director.get_phase_name()), panel_timer > last_panel_timer])
	last_panel_timer = main.bot_panel_timer
	last_usec = now

static func _percentiles(values: Array) -> Dictionary:
	if values.is_empty():
		return {"n": 0}
	var sorted := values.duplicate()
	sorted.sort()
	var pick := func(p: float) -> float: return snappedf(float(sorted[mini(int(p * sorted.size()), sorted.size() - 1)]), 0.01)
	var total := 0.0
	for value in sorted:
		total += float(value)
	return {"n": sorted.size(), "p50": pick.call(0.5), "p95": pick.call(0.95), "p99": pick.call(0.99), "max": snappedf(float(sorted[-1]), 0.01), "mean": snappedf(total / sorted.size(), 0.01)}

func _group(filter: Callable) -> Dictionary:
	var wall: Array = []
	var physics: Array = []
	var process: Array = []
	for sample: Array in samples:
		if filter.call(sample):
			wall.append(sample[0])
			physics.append(sample[1])
			process.append(sample[2])
	return {"frame_ms": _percentiles(wall), "physics_ms": _percentiles(physics), "process_ms": _percentiles(process)}

func _collect_result(finished_early: bool) -> Dictionary:
	var result := super._collect_result(finished_early)
	var groups := {
		"all": _group(func(s: Array) -> bool: return true),
		"alive_12_plus": _group(func(s: Array) -> bool: return int(s[3]) >= 12),
		"alive_6_to_11": _group(func(s: Array) -> bool: return int(s[3]) >= 6 and int(s[3]) <= 11),
		"alive_2_to_5": _group(func(s: Array) -> bool: return int(s[3]) >= 2 and int(s[3]) <= 5),
		"panel_refresh_frames": _group(func(s: Array) -> bool: return bool(s[5])),
		"other_frames": _group(func(s: Array) -> bool: return not bool(s[5])),
	}
	var phases := {}
	for sample: Array in samples:
		phases[sample[4]] = true
	for phase: String in phases:
		groups["phase " + phase] = _group(func(s: Array) -> bool: return s[4] == phase)
	print("FRAME_RESULT ", JSON.stringify({"players": main.players.size(), "seed": seed_value, "bot_panel": not bot_panel_off, "frames": samples.size(), "groups": groups}))
	return result
