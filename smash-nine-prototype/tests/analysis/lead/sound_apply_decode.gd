extends SceneTree
## Sound apply 10-29: decodes every adopted OGG the way the game plays it (the imported
## AudioStreamOggVorbis through AudioStreamPlayback.mix_audio, no driver) and writes raw
## float32 stereo frames for reports/apply-sound-2026-10-29/verify_decode.py.
## Looping music also gets <id>-seam.f32: 2 s rendered from 1 s before the end, across the wrap.
## usage: godot --headless --path . -s tests/analysis/lead/sound_apply_decode.gd -- --out=<abs dir>
const CATALOG := preload("res://scripts/audio/AudioCatalog.gd")

func _write(path: String, frames: PackedVector2Array) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	var data := PackedFloat32Array()
	data.resize(frames.size() * 2)
	for index in frames.size():
		data[index * 2] = frames[index].x
		data[index * 2 + 1] = frames[index].y
	file.store_buffer(data.to_byte_array())
	file.close()

func _initialize() -> void:
	var out_dir := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var rate := AudioServer.get_mix_rate()
	var info := {"mix_rate": rate}
	for id: String in CATALOG.SOUNDS:
		var path := "res://assets/audio/%s/%s.ogg" % ["music" if id.begins_with("music_") else "sfx", id]
		var stream := load(path) as AudioStreamOggVorbis
		var length := stream.get_length()
		var entry := {"path": path, "class": stream.get_class(), "loop": stream.loop, "loop_offset": stream.loop_offset, "length_s": length, "frames_by_length": roundi(length * rate)}
		var playback := stream.instantiate_playback()
		playback.start(0.0)
		var frames := PackedVector2Array()
		if stream.loop:
			frames = playback.mix_audio(1.0, roundi(length * rate))
			var seam := stream.instantiate_playback()
			seam.start(length - 1.0)
			var seam_frames := seam.mix_audio(1.0, roundi(2.0 * rate))
			_write(out_dir.path_join(id + "-seam.f32"), seam_frames)
			entry["seam_frames"] = seam_frames.size()
			entry["seam_still_playing"] = seam.is_playing()
		else:
			while playback.is_playing() and frames.size() < roundi(30.0 * rate):
				frames.append_array(playback.mix_audio(1.0, 256))
		_write(out_dir.path_join(id + ".f32"), frames)
		entry["frames_rendered"] = frames.size()
		info[id] = entry
	var file := FileAccess.open(out_dir.path_join("decode.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(info, "\t") + "\n")
	file.close()
	print("DECODE_DONE %d streams" % (info.size() - 1))
	quit(0)
