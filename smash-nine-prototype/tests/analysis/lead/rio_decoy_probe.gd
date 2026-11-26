extends "res://tests/soak_match.gd"
## Rio's decoy in whole bot matches: where each one stands and how it ends (2026-11-25; eight soak
## matches had shown 77 decoys left, none burst and none swapped with: they stood at the world
## origin).
## Usage: <godot> --headless --path . --fixed-fps 60 -s tests/analysis/lead/rio_decoy_probe.gd -- --seconds=480 --seed=2002
## Prints one "RIO_DECOY {json}" line per decoy ("step": how far Rio stood from it one frame after
## the cast, 150 px when he stepped straight back; "foe": the nearest foe to it then), then the
## SOAK_RESULT line with a "decoys" block that counts the endings.

var frame_index := 0
## Per Rio (instance id): {"node", "following", "decoy", "record"}.
var rios: Dictionary = {}
var endings: Dictionary = {}

func _check_positions() -> void:
	super._check_positions()
	if frame_index == 0:
		for player in main.players:
			if str(player.character_id) == "rio":
				rios[player.get_instance_id()] = {"node": player, "following": false, "decoy": null, "record": {}}
	frame_index += 1
	for watch in rios.values():
		_watch(watch)

func _count(rio: Node, key: String) -> float:
	return float(rio.move_counts.get(key, 0.0))

func _watch(watch: Dictionary) -> void:
	var rio: Node = watch.node
	if not is_instance_valid(rio):
		return
	if bool(watch.following):
		var record: Dictionary = watch.record
		# A freed node reads as null: its validity is asked first, never compared.
		var gone: bool = not is_instance_valid(watch.decoy) or watch.decoy.is_queued_for_deletion()
		if not gone:
			record.frames = int(record.frames) + 1
			record.elapsed = snappedf(float(watch.decoy.elapsed), 0.01)
		if gone or rio.decoy != watch.decoy:
			var bursts: float = _count(rio, "decoy_burst") - float(record.bursts_before)
			record.swapped = _count(rio, "u2") > float(record.swaps_before)
			var ending := "timed out"
			if bursts > 0.0:
				ending = "burst"
			elif bool(rio.is_defeated):
				ending = "Rio defeated"
			elif float(record.elapsed) < 3.9:
				ending = "cleared"
			record.ending = ending
			var key := ending + (", swapped" if bool(record.swapped) else "")
			endings[key] = int(endings.get(key, 0)) + 1
			record.erase("bursts_before")
			record.erase("swaps_before")
			print("RIO_DECOY ", JSON.stringify(record))
			watch.following = false
			watch.decoy = null
	if not bool(watch.following) and is_instance_valid(rio.decoy) and not rio.decoy.is_queued_for_deletion():
		var decoy: Node2D = rio.decoy
		var nearest := INF
		for other in main.players:
			if other != rio and is_instance_valid(other) and not other.is_defeated and int(other.realm_index) == int(rio.realm_index):
				nearest = minf(nearest, other.global_position.distance_to(decoy.global_position))
		watch.following = true
		watch.decoy = decoy
		watch.record = {
			"seed": seed_value, "t": snappedf(main.director.match_elapsed, 0.1), "frames": 0, "elapsed": 0.0,
			"step": snappedf(rio.global_position.distance_to(decoy.global_position), 1.0),
			"foe": snappedf(nearest, 1.0) if nearest < INF else -1.0,
			"bursts_before": _count(rio, "decoy_burst"), "swaps_before": _count(rio, "u2")
		}

func _collect_result(finished_early: bool) -> Dictionary:
	var result := super._collect_result(finished_early)
	result["decoys"] = endings
	return result
