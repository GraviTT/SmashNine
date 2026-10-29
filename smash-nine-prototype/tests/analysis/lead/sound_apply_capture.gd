extends SceneTree
## Sound apply 10-29 evidence (not part of run_all). Plays the adopted OGG files through the
## real AudioManager and records the Master bus with AudioEffectCapture. The headless Dummy
## driver mixes in real time, so the recording is what the game's mixer produced
## (Music and SFX faders included, Master fader not: it comes after the capture).
## usage: godot --headless --path . -s tests/analysis/lead/sound_apply_capture.gd -- --out=<abs dir> [--match-seconds=20] [--match-only]
## Writes <out>/capture.json (capture-match.json with --match-only), <out>/seam_<track>.wav,
## <out>/match_mix.wav and the unclamped float32 frames <out>/match_mix.f32.
const AUDIO := preload("res://scripts/audio/AudioManager.gd")
const CATALOG := preload("res://scripts/audio/AudioCatalog.gd")
const MAIN_SCENE := "res://scenes/Main.tscn"
var manager: Node
var capture := AudioEffectCapture.new()
var out_dir := ""
var match_seconds := 20.0
var match_only := false
var recording := false
var recorded := PackedVector2Array()
var report := {"sfx": {}, "music": {}, "seams": {}, "match": {}}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
		elif arg.begins_with("--match-seconds="):
			match_seconds = float(arg.get_slice("=", 1))
		elif arg == "--match-only":
			match_only = true
	Engine.max_fps = 120
	call_deferred("_run")

func _pull() -> void:
	var available := capture.get_frames_available()
	if available > 0:
		var frames := capture.get_buffer(available)
		if recording:
			recorded.append_array(frames)

func _wait(milliseconds: int) -> void:
	var deadline := Time.get_ticks_msec() + milliseconds
	while Time.get_ticks_msec() < deadline:
		await process_frame
		_pull()

func _start_recording() -> void:
	_pull()
	recorded = PackedVector2Array()
	recording = true

func _stop_recording() -> PackedVector2Array:
	_pull()
	recording = false
	return recorded

func _db(value: float) -> float:
	return snappedf(linear_to_db(value), 0.01) if value > 0.0 else -200.0

func _levels(frames: PackedVector2Array) -> Dictionary:
	var total := 0.0
	var peak := 0.0
	var window := 2205
	var acc := 0.0
	var best := 0.0
	for index in frames.size():
		var frame := frames[index]
		total += frame.x * frame.x + frame.y * frame.y
		peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
		var mono := (frame.x + frame.y) * 0.5
		acc += mono * mono
		if (index + 1) % window == 0:
			best = maxf(best, acc / window)
			acc = 0.0
	var rms := sqrt(total / maxf(1.0, 2.0 * frames.size()))
	# Master's fader comes after the capture: output clips where |frame| * master > 1.
	var master := db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	var over_full := 0
	var over_output := 0
	var runs := 0
	var run := 0
	var longest := 0
	for frame in frames:
		var level := maxf(absf(frame.x), absf(frame.y))
		if level > 1.0:
			over_full += 1
		if level * master > 1.0:
			over_output += 1
			run += 1
			if run == 1:
				runs += 1
			longest = maxi(longest, run)
		else:
			run = 0
	return {"frames": frames.size(), "rms_dbfs": _db(rms), "peak_dbfs": _db(peak), "max_50ms_rms_dbfs": _db(sqrt(best)),
		"peak_after_master_dbfs": _db(peak * master), "frames_over_0dbfs": over_full, "frames_clipping_output": over_output,
		"output_clip_runs": runs, "longest_output_clip_frames": longest}

func _save_f32(file_name: String, frames: PackedVector2Array) -> void:
	var data := PackedFloat32Array()
	data.resize(frames.size() * 2)
	for index in frames.size():
		data[index * 2] = frames[index].x
		data[index * 2 + 1] = frames[index].y
	var file := FileAccess.open(out_dir.path_join(file_name), FileAccess.WRITE)
	file.store_buffer(data.to_byte_array())
	file.close()

func _save_wav(file_name: String, frames: PackedVector2Array) -> void:
	var pcm := PackedByteArray()
	pcm.resize(frames.size() * 4)
	for index in frames.size():
		pcm.encode_s16(index * 4, clampi(roundi(frames[index].x * 32767.0), -32768, 32767))
		pcm.encode_s16(index * 4 + 2, clampi(roundi(frames[index].y * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = true
	stream.mix_rate = int(AudioServer.get_mix_rate())
	stream.data = pcm
	stream.save_to_wav(out_dir.path_join(file_name))

func _stop_all() -> void:
	for voice: AudioStreamPlayer in manager.voices:
		voice.stop()
	manager.last_started.clear()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	manager = AUDIO.install(root)
	await process_frame
	manager.unlocked = true
	manager.probe_enabled = true
	capture.buffer_length = 10.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Master"), capture)
	report["mixer"] = {"mix_rate": AudioServer.get_mix_rate(), "driver": AudioServer.get_driver_name() if AudioServer.has_method("get_driver_name") else "", "buses": {}}
	for bus in ["Master", "Music", "SFX"]:
		report.mixer.buses[bus] = _db(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))))
	await _wait(300)
	# 1. Every effect alone, through manager.play (the path the game hooks use).
	for id: String in CATALOG.SOUNDS:
		if id.begins_with("music_") or match_only:
			continue
		_stop_all()
		await _wait(120)
		_start_recording()
		var voice: AudioStreamPlayer = manager.play(id)
		var path := ""
		if voice != null:
			path = voice.stream.resource_path
			var started := Time.get_ticks_msec()
			while voice.playing and Time.get_ticks_msec() - started < 8000:
				await process_frame
				_pull()
		await _wait(80)
		var entry := _levels(_stop_recording())
		entry["path"] = path
		entry["resolved"] = str(manager.resolutions.get(id, ""))
		report.sfx[id] = entry
		print("SFX %-20s %s  max50 %.1f peak %.1f" % [id, path, entry.max_50ms_rms_dbfs, entry.peak_dbfs])
	_stop_all()
	# 2. Every track through play_music, after its 0.5 s fade-in.
	for track: String in CATALOG.SOUNDS:
		if not track.begins_with("music_") or match_only:
			continue
		manager.play_music(track)
		await _wait(800)
		_start_recording()
		await _wait(3000)
		var entry := _levels(_stop_recording())
		var player: AudioStreamPlayer = manager.music_players[manager.music_index]
		entry["path"] = (manager.cache[manager.resolved_music] as Resource).resource_path
		entry["resolved"] = manager.resolved_music
		entry["playing_stream_loop"] = bool(player.stream.get("loop"))
		entry["imported_loop"] = bool(manager.cache[manager.resolved_music].get("loop"))
		entry["length_s"] = player.stream.get_length()
		report.music[track] = entry
		print("MUSIC %-14s %s  rms %.1f loop %s/%s len %.4f" % [track, entry.path, entry.rms_dbfs, entry.imported_loop, entry.playing_stream_loop, entry.length_s])
	# 3. Loop seams: jump to 1 s before the end and record across the wrap.
	for track: String in CATALOG.SOUNDS:
		if not track.begins_with("music_") or match_only:
			continue
		manager.play_music(track)
		await _wait(800)
		var player: AudioStreamPlayer = manager.music_players[manager.music_index]
		var length: float = player.stream.get_length()
		_start_recording()
		player.seek(length - 1.0)
		await _wait(2600)
		var frames := _stop_recording()
		_save_wav("seam_%s.wav" % track, frames)
		report.seams[track] = {"length_s": length, "seek_to_s": length - 1.0, "frames": frames.size(), "wav": "seam_%s.wav" % track, "still_playing": player.playing, "position_after_s": player.get_playback_position()}
		print("SEAM %-14s len %.4f recorded %d frames, playing %s at %.3f s" % [track, length, frames.size(), player.playing, player.get_playback_position()])
	manager.play_music("music_title")
	await _wait(100)
	for player: AudioStreamPlayer in manager.music_players:
		player.stop()
	manager.current_music = ""
	manager.resolved_music = ""
	_stop_all()
	await _wait(300)
	# 4. A real bot match: the game's own hooks, with the paths every voice actually played.
	manager.requests.clear()
	manager.resolutions.clear()
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.match_seed = 1001
	root.add_child(main)
	_start_recording()
	var started_paths: Dictionary = {}
	var last_positions: Dictionary = {}
	var deadline := Time.get_ticks_msec() + int(match_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame
		_pull()
		for player: AudioStreamPlayer in manager.voices + manager.music_players:
			var position := player.get_playback_position()
			var key := player.get_instance_id()
			if player.playing and player.stream != null and (not last_positions.has(key) or position < float(last_positions[key])):
				var path := player.stream.resource_path if player.stream.resource_path != "" else (manager.cache[manager.resolved_music] as Resource).resource_path
				started_paths[path] = int(started_paths.get(path, 0)) + 1
			if player.playing:
				last_positions[key] = position
			else:
				last_positions.erase(key)
	var mix := _stop_recording()
	_save_wav("match_mix.wav", mix)
	_save_f32("match_mix.f32", mix)
	report.match = _levels(mix)
	report.match["seconds"] = match_seconds
	report.match["started_paths"] = started_paths
	report.match["requests"] = manager.requests.duplicate()
	report.match["resolutions"] = manager.resolutions.duplicate()
	report.match["music"] = manager.resolved_music
	report.match["wav"] = "match_mix.wav"
	print("MATCH %d distinct files started, music %s, %s" % [started_paths.size(), manager.resolved_music, JSON.stringify(_levels(mix))])
	var file := FileAccess.open(out_dir.path_join("capture-match.json" if match_only else "capture.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	main.queue_free()
	await process_frame
	print("CAPTURE_DONE")
	quit(0)
