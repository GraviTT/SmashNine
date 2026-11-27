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
var frame_index := 0
## [wall_ms, physics_ms, process_ms, alive, phase]
var samples: Array = []

func _check_positions() -> void:
	super._check_positions()
	var now := Time.get_ticks_usec()
	frame_index += 1
	if last_usec > 0 and frame_index > SKIP_FRAMES:
		var alive := 0
		for player in main.players:
			if is_instance_valid(player) and not player.is_defeated:
				alive += 1
		samples.append([float(now - last_usec) / 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			alive, str(main.director.get_phase_name())])
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
	}
	var phases := {}
	for sample: Array in samples:
		phases[sample[4]] = true
	for phase: String in phases:
		groups["phase " + phase] = _group(func(s: Array) -> bool: return s[4] == phase)
	print("FRAME_RESULT ", JSON.stringify({"players": main.players.size(), "seed": seed_value, "frames": samples.size(), "groups": groups}))
	return result
