extends "res://scripts/audio/AudioManager.gd"
## Probe subclass only: each production method still runs exactly once via super.
## No streams injected; accepted means candidate before missing assets / voice caps.
var observed_main: Node
var events: Array = []
var checkpoints: Array = []
var active_peak := 0

func watch(source: Node) -> void:
	observed_main = source
	super.watch(source)

func _stamp() -> Dictionary:
	var t := 0.0
	var realm := -1
	var screen := "initial"
	var phase := ""
	if is_instance_valid(observed_main):
		realm = int(observed_main.current_map_index)
		if observed_main.director != null:
			t = float(observed_main.director.match_elapsed)
		if observed_main.hud != null:
			screen = str(observed_main.hud.frontend.screen)
		if observed_main.story_session != null:
			phase = str(observed_main.story_session.phase)
	return {"t": t, "frame": Engine.get_physics_frames(), "watched": realm, "screen": screen, "phase": phase}

func play(id: String, options: Dictionary = {}) -> AudioStreamPlayer:
	var row := _stamp()
	row.id = id
	row.source_realm = int(options.get("realm", -1))
	var before := world_probe.duplicate()
	var voice := super.play(id, options)
	row.outcome = "global"
	if not bool(options.get("enabled", true)):
		row.outcome = "disabled"
	elif CATALOG.SOUNDS.has(id) and bool(CATALOG.SOUNDS[id].get("world", false)):
		row.outcome = "unclassified"
		for outcome in ["watched", "filtered", "no_realm"]:
			if int(world_probe[outcome]) > int(before[outcome]):
				row.outcome = outcome
	row.played = voice != null
	var active := 0
	for player: AudioStreamPlayer in voices:
		if player.playing:
			active += 1
	active_peak = maxi(active_peak, active)
	events.append(row)
	return voice

func play_music(track: String) -> void:
	var row := _stamp()
	row.id = track
	row.outcome = "music"
	super.play_music(track)
	row.current_music = current_music
	row.resolved_music = resolved_music
	events.append(row)

func mark(label: String) -> void:
	var row := _stamp()
	row.label = label
	row.music = current_music
	row.requests = requests.duplicate()
	checkpoints.append(row)

func save_capture(path: String, stats: Dictionary) -> void:
	mark("capture_end")
	var file := FileAccess.open(path, FileAccess.WRITE)
	var played := 0
	for row: Dictionary in events:
		if bool(row.get("played", false)):
			played += 1
	file.store_string(JSON.stringify({"stats": stats, "events": events, "checkpoints": checkpoints, "requests": requests, "world_probe": world_probe, "resolution_attempts": resolution_attempts, "catalog": CATALOG.SOUNDS, "actual_sfx_plays": played, "actual_voice_peak_after_requests": active_peak, "audio_manager_nodes": 1 + get_child_count(), "note": "No audio assets or injected streams. Candidate requests precede missing-file / min-gap / voice-cap rejection."}) + "\n")
