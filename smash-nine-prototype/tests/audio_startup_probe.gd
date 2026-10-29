extends SceneTree
## Sound apply 10-29: the game's real start-up path. With the main scene as the positional
## argument the engine adds Main before the root is ready, exactly as when the game starts:
## godot --headless --path . -s tests/audio_startup_probe.gd res://scenes/Main.tscn
## After 2 s of real time prints STARTUP {json}: whether root/AudioManager exists, what the
## music player plays, and the level the Master bus received meanwhile (AudioEffectCapture).
## Not in run_all's list: test_audio runs it in a child process (_test_startup_path).
var capture := AudioEffectCapture.new()
var started := 0
var peak := 0.0
var total := 0.0
var count := 0

func _initialize() -> void:
	capture.buffer_length = 4.0
	AudioServer.add_bus_effect(0, capture)
	started = Time.get_ticks_msec()

func _process(_delta: float) -> bool:
	var available := capture.get_frames_available()
	if available > 0:
		for frame in capture.get_buffer(available):
			peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
			total += frame.x * frame.x + frame.y * frame.y
			count += 2
	if Time.get_ticks_msec() - started < 2000:
		return false
	var manager := root.get_node_or_null("AudioManager")
	var info := {"current_scene": str(current_scene.name) if current_scene != null else "", "manager_in_tree": manager != null,
		"captured_frames": count / 2, "rms_dbfs": snappedf(linear_to_db(sqrt(total / maxf(1.0, count))), 0.01) if total > 0.0 else -200.0,
		"peak_dbfs": snappedf(linear_to_db(peak), 0.01) if peak > 0.0 else -200.0}
	if manager != null:
		var player: AudioStreamPlayer = manager.music_players[manager.music_index]
		info["current_music"] = manager.current_music
		info["music_path"] = (manager.cache[manager.resolved_music] as Resource).resource_path if manager.resolved_music != "" else ""
		info["music_playing"] = player.playing
		info["music_loop"] = bool(player.stream.get("loop")) if player.stream != null else false
		info["position_s"] = snappedf(player.get_playback_position(), 0.001)
	print("STARTUP " + JSON.stringify(info))
	return true
