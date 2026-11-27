extends SceneTree
## Sound apply 10-29: the game's real start-up path. With the main scene as the positional
## argument the engine adds Main before the root is ready, exactly as when the game starts:
## godot --headless --path . -s tests/audio_startup_probe.gd res://scenes/Main.tscn
## Prints STARTUP {json}: whether root/AudioManager exists, what the music player plays, and the
## level the Master bus received (AudioEffectCapture) over the first second of the music.
## Not in run_all's list: test_audio runs it in a child process (_test_startup_path).
##
## The level is measured from the moment the music plays, not from the probe's start
## (2026-11-27): on a busy machine loading the main scene took most of a fixed 2 s window, the
## music started 3 ms before it closed, and the bus read -200 dBFS (2 runs of 4 under load) while
## an idle machine read -25 dBFS. If the music never plays, the probe still ends, after 15 s.

const MEASURE_MS := 1000
const GIVE_UP_MS := 15000

var capture := AudioEffectCapture.new()
var started := 0
var music_started := -1
var peak := 0.0
var total := 0.0
var count := 0

func _initialize() -> void:
	capture.buffer_length = 4.0
	AudioServer.add_bus_effect(0, capture)
	started = Time.get_ticks_msec()

func _music_player() -> AudioStreamPlayer:
	var manager := root.get_node_or_null("AudioManager")
	if manager == null or manager.music_players.is_empty():
		return null
	return manager.music_players[manager.music_index]

func _process(_delta: float) -> bool:
	var now := Time.get_ticks_msec()
	var player := _music_player()
	var available := capture.get_frames_available()
	if available > 0:
		var frames := capture.get_buffer(available)
		# Only what the bus received once the music plays counts.
		if music_started >= 0:
			for frame in frames:
				peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
				total += frame.x * frame.x + frame.y * frame.y
				count += 2
	if music_started < 0 and player != null and player.playing and player.get_playback_position() > 0.0:
		music_started = now
	var measured := music_started >= 0 and now - music_started >= MEASURE_MS
	if not measured and now - started < GIVE_UP_MS:
		return false
	var manager := root.get_node_or_null("AudioManager")
	var info := {"current_scene": str(current_scene.name) if current_scene != null else "", "manager_in_tree": manager != null,
		"captured_frames": count / 2, "rms_dbfs": snappedf(linear_to_db(sqrt(total / maxf(1.0, count))), 0.01) if total > 0.0 else -200.0,
		"peak_dbfs": snappedf(linear_to_db(peak), 0.01) if peak > 0.0 else -200.0,
		"music_started_ms": music_started - started if music_started >= 0 else -1}
	if manager != null:
		info["current_music"] = manager.current_music
		info["music_path"] = (manager.cache[manager.resolved_music] as Resource).resource_path if manager.resolved_music != "" else ""
		info["music_playing"] = player.playing if player != null else false
		info["music_loop"] = bool(player.stream.get("loop")) if player != null and player.stream != null else false
		info["position_s"] = snappedf(player.get_playback_position(), 0.001) if player != null else 0.0
	print("STARTUP " + JSON.stringify(info))
	return true
