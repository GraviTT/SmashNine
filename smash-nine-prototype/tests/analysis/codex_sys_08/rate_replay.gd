extends SceneTree
## Counterfactual rate ceiling, not an audio playback/voice-overlap measurement.
## Same QA-22 recorder, original event order and match-clock timestamps.
## Assumes every id has its own stream and available voices. Only gaps reject.
const AUDIO := preload("res://scripts/audio/AudioManager.gd")
const BEFORE := preload("res://tests/analysis/codex_sys_08/baseline_gap.gd")
const OUT := "res://../reports/codex-sys-08/"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var captures: Array = []
	for period in ["before", "after"]:
		for seed_value in [1001, 2105, 2106]:
			var file := ("before-br-%d.json" if period == "before" else "sound-br-%d.json") % seed_value
			var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + file))
			var policy: Node = BEFORE.new() if period == "before" else AUDIO.new()
			root.add_child(policy)
			var tone := _tone()
			for id: String in data.catalog:
				policy.register_stream(id, tone)
			var virtual_starts: Dictionary = {}
			var synthetic_plays := 0
			var accepted: Dictionary = {}
			var raw: Dictionary = {}
			var rows: Dictionary = {}
			var raw_total := 0
			for event: Dictionary in data.events:
				if event.outcome != "watched":
					continue
				raw_total += 1
				var id: String = event.id
				var now := roundi(float(event.t) * 1000000.0)
				if not raw.has(id): raw[id] = []
				raw[id].append(float(event.t))
				# Translate simulation timestamps onto the production monotonic clock.
				# Voices are stopped immediately: this measures the free-voice ceiling.
				var wall_now := Time.get_ticks_usec()
				policy.last_started.clear()
				for previous_id: String in virtual_starts:
					policy.last_started[previous_id] = wall_now - (now - int(virtual_starts[previous_id]))
				var voice: AudioStreamPlayer = policy.play(id, {"realm": int(event.source_realm)})
				if voice != null:
					voice.stop()
					synthetic_plays += 1
					virtual_starts[id] = now
					if not accepted.has(id): accepted[id] = []
					accepted[id].append(float(event.t))
			for id: String in data.catalog:
				var times: Array = accepted.get(id, [])
				var raw_times: Array = raw.get(id, [])
				rows[id] = {"raw": _peaks(raw_times), "gap_eligible": _peaks(times), "gap_ms": policy.gap_usec(id) / 1000}
			captures.append({"period": period, "seed": seed_value, "stats": data.stats, "raw_total": raw_total, "synthetic_plays_free_voices": synthetic_plays, "ids": rows})
			policy.free()
	var output := {"method": "Observed watched-realm requests replayed in original order through production play using an in-memory 10ms sine tone per id; QA22 baseline override = 40ms. Match-clock timestamps translated onto the production monotonic clock before each request. Each accepted voice is stopped immediately. Direct per-id streams and free voices are fixture assumptions; gap-eligible is a playback ceiling, not shipped-asset plays or overlap. Actual source captures have no audio assets.", "captures": captures}
	var file := FileAccess.open(OUT + "rate-comparison.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "\t") + "\n")
	print("SYS08_RATE_REPLAY captures=", captures.size())
	quit(0)

func _tone() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var pcm := PackedByteArray()
	pcm.resize(220 * 2)
	for sample in 220:
		pcm.encode_s16(sample * 2, int(sin(TAU * 440.0 * sample / 22050.0) * 2000.0))
	stream.data = pcm
	return stream

func _peaks(times: Array) -> Dictionary:
	var bins: Dictionary = {}
	var aligned_peak := 0
	var rolling_peak := 0
	var aligned_start := 0
	var rolling_start := 0.0
	var right := 0
	for left in times.size():
		var t: float = times[left]
		var second := floori(t + 0.0000001)
		bins[second] = int(bins.get(second, 0)) + 1
		if int(bins[second]) > aligned_peak:
			aligned_peak = bins[second]
			aligned_start = second
		right = maxi(left, right)
		while right < times.size() and float(times[right]) < t + 1.0 - 0.00000001:
			right += 1
		if right - left > rolling_peak:
			rolling_peak = right - left
			rolling_start = t
	return {"total": times.size(), "aligned_peak": aligned_peak, "aligned_start": aligned_start, "rolling_peak": rolling_peak, "rolling_start": rolling_start, "seconds": bins}
