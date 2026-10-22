extends Node
## One persistent SceneTree-root node, installed by Main (explicitly by standalone probes).
## All helpers observe game state only. Audio never uses the gameplay RNG or time scale.
const CATALOG := preload("res://scripts/audio/AudioCatalog.gd")
const SETTINGS := preload("res://scripts/audio/AudioSettings.gd")
const POOL_SIZE := 24
const MIN_GAP_USEC := 40000
const MIN_LAND_AIR_SECONDS := 0.12
const FADE_SECONDS := 0.5
var voices: Array[AudioStreamPlayer] = []
var music_players: Array[AudioStreamPlayer] = []
var cache: Dictionary = {}
var last_started: Dictionary = {}
var requests: Dictionary = {}
var resolutions: Dictionary = {}
var resolution_attempts: Dictionary = {}
var probe_enabled := false
var world_probe := {"watched": 0, "filtered": 0, "no_realm": 0}
var watched_realm: Callable
var debug_missing := false
var unlocked := not OS.has_feature("web")
var current_music := ""
var resolved_music := ""
var pending_music := ""
var music_index := 0
var music_tween: Tween
var pitch_rng := RandomNumberGenerator.new()
var _snapshots: Dictionary = {}
var _missing_reported: Dictionary = {}
var _landing_states: Dictionary = {}

static func install(source: Node) -> Node:
	var tree := source.get_tree()
	var manager := tree.root.get_node_or_null("AudioManager")
	if manager == null:
		manager = load("res://scripts/audio/AudioManager.gd").new()
		manager.name = "AudioManager"
		tree.root.add_child(manager)
	return manager

static func find(source: Node) -> Node:
	if not is_instance_valid(source) or not source.is_inside_tree():
		return null
	return source.get_tree().root.get_node_or_null("AudioManager")

static func sound(source: Node, id: String, options: Dictionary = {}) -> void:
	var manager := find(source)
	if manager != null:
		var request := options.duplicate()
		if not request.has("realm") and source.get("realm_index") != null:
			request["realm"] = int(source.get("realm_index"))
		manager.play(id, request)

## Main supplies a callable so camera/spectator/story changes cannot leave a stale realm.
func watch(source: Node) -> void:
	watched_realm = source.get.bind("current_map_index")

func _world_audible(id: String, options: Dictionary) -> bool:
	if not bool(CATALOG.SOUNDS[id].get("world", false)):
		return true
	var realm := int(options.get("realm", -1))
	var outcome := "no_realm" if realm < 0 else "watched"
	if realm >= 0 and watched_realm.is_valid() and realm != int(watched_realm.call()):
		outcome = "filtered"
	if probe_enabled:
		world_probe[outcome] += 1
	return outcome != "filtered"

static func music(source: Node, id: String) -> void:
	var manager := find(source)
	if manager != null:
		manager.play_music(id)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SETTINGS.load_saved()
	pitch_rng.seed = 517793
	for index in POOL_SIZE:
		var voice := AudioStreamPlayer.new()
		voice.name = "SFX%d" % index
		voice.bus = "SFX"
		add_child(voice)
		voices.append(voice)
	for index in 2:
		var player := AudioStreamPlayer.new()
		player.name = "Music%d" % index
		player.bus = "Music"
		add_child(player)
		music_players.append(player)
		player.finished.connect(_loop_music.bind(player))

func _input(event: InputEvent) -> void:
	if not unlocked and ((event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventJoypadButton and event.pressed)):
		unlock()

func unlock() -> void:
	unlocked = true
	if pending_music != "":
		var track := pending_music
		pending_music = ""
		_start_music(track)

func _record(id: String) -> void:
	if probe_enabled:
		requests[id] = int(requests.get(id, 0)) + 1

## Test-only injection takes an in-memory AudioStreamWAV; it creates no game asset.
func register_stream(id: String, stream: AudioStream) -> void:
	cache[id] = stream

func _load_stream(id: String) -> AudioStream:
	if cache.has(id):
		return cache[id] as AudioStream
	var folder := "music" if id.begins_with("music_") else "sfx"
	for extension in ["ogg", "wav"]:
		var path := "res://assets/audio/%s/%s.%s" % [folder, id, extension]
		if ResourceLoader.exists(path):
			cache[id] = load(path) as AudioStream
			return cache[id] as AudioStream
	cache[id] = null
	if debug_missing and OS.is_debug_build() and not _missing_reported.has(id):
		_missing_reported[id] = true
		print("[audio] missing ", id)
	return null

func _resolve(id: String) -> String:
	var visited: Dictionary = {}
	while id != "" and not visited.has(id):
		visited[id] = true
		if probe_enabled:
			resolution_attempts[id] = int(resolution_attempts.get(id, 0)) + 1
		if _load_stream(id) != null:
			return id
		id = str(CATALOG.SOUNDS.get(id, {}).get("fallback", ""))
	return ""

func active_count(id: String, resolved := false) -> int:
	var count := 0
	for voice in voices:
		if voice.playing and str(voice.get_meta("resolved" if resolved else "id", "")) == id:
			count += 1
	return count

func gap_usec(id: String) -> int:
	return int(CATALOG.SOUNDS.get(id, {}).get("gap_ms", MIN_GAP_USEC / 1000)) * 1000

## Both the requested id and its resolved fallback keep their own catalog gap.
func gap_allows(id: String, resolved: String, now: int) -> bool:
	return now - int(last_started.get(id, -gap_usec(id))) >= gap_usec(id) and now - int(last_started.get(resolved, -gap_usec(resolved))) >= gap_usec(resolved)

func play(id: String, options: Dictionary = {}) -> AudioStreamPlayer:
	_record(id)
	if not CATALOG.SOUNDS.has(id) or not unlocked or not bool(options.get("enabled", true)):
		return null
	if not _world_audible(id, options):
		return null
	var resolved := _resolve(id)
	if resolved == "":
		return null
	var now := Time.get_ticks_usec()
	if not gap_allows(id, resolved, now):
		return null
	if active_count(id) >= int(CATALOG.SOUNDS[id].voices) or active_count(resolved, true) >= int(CATALOG.SOUNDS[resolved].voices):
		return null
	for voice in voices:
		if voice.playing:
			continue
		voice.stream = cache[resolved]
		voice.set_meta("id", id)
		voice.set_meta("resolved", resolved)
		voice.pitch_scale = pitch_rng.randf_range(0.96, 1.04) if id.begins_with("hit_") or id.begins_with("swing") else 1.0
		voice.volume_db = clampf(float(options.get("volume_db", 0.0)), -80.0, 6.0)
		voice.play()
		last_started[id] = now
		last_started[resolved] = now
		if probe_enabled:
			resolutions[id] = resolved
		return voice
	return null

func play_music(track: String) -> void:
	_record(track)
	if not CATALOG.SOUNDS.has(track) or not track.begins_with("music_"):
		return
	if not unlocked:
		pending_music = track
		return
	_start_music(track)

func _start_music(track: String) -> void:
	var resolved := _resolve(track)
	if track == current_music and resolved == resolved_music:
		return
	current_music = track
	if music_tween != null and music_tween.is_valid():
		music_tween.kill()
	var old := music_players[music_index]
	var next := music_players[1 - music_index]
	next.stop()
	resolved_music = resolved
	music_tween = create_tween().set_ignore_time_scale(true)
	if resolved == "":
		music_tween.tween_property(old, "volume_db", -80.0, FADE_SECONDS)
		music_tween.tween_callback(old.stop)
		return
	# Duplicate before enabling native loop flags: cached/test streams remain unchanged.
	var stream := (cache[resolved] as AudioStream).duplicate() as AudioStream
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		var sample_frames := roundi(stream.get_length() * stream.mix_rate)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_frames
	next.stream = stream
	next.pitch_scale = 1.0
	next.volume_db = -80.0
	next.play()
	music_index = 1 - music_index
	music_tween.tween_property(next, "volume_db", 0.0, FADE_SECONDS)
	music_tween.parallel().tween_property(old, "volume_db", -80.0, FADE_SECONDS)
	music_tween.tween_callback(old.stop)

func _loop_music(player: AudioStreamPlayer) -> void:
	if player == music_players[music_index] and resolved_music != "":
		player.play()

static func begin_action(source: Node) -> void:
	var manager := find(source)
	if manager != null:
		manager._snapshots[source.get_instance_id()] = [float(source.attack_lock_timer), int(source.attack_serial), _fighter_id(source)]

static func end_action(source: Node, slot: String) -> void:
	var manager := find(source)
	if manager == null:
		return
	var key := source.get_instance_id()
	var before: Array = manager._snapshots.get(key, [])
	manager._snapshots.erase(key)
	if before.is_empty() or (float(source.attack_lock_timer) <= float(before[0]) and int(source.attack_serial) <= int(before[1])):
		return
	var id: String = before[2]
	sound(source, "skill_%s_%s" % [id, slot])
	if slot == "1" and id in ["frey", "nova", "rio"]:
		sound(source, "dash")

static func _fighter_id(source: Node) -> String:
	return "luna_brave" if str(source.character_id) == "luna" and bool(source.get("transformed")) else str(source.character_id)

static func basic(source: Node, attack_type: String) -> void:
	if float(source.attack_lock_timer) > 0.0:
		sound(source, "swing_heavy" if attack_type in ["up", "down", "air_up", "air_down"] else "swing_light")

static func ultimate_started(source: Node, followup := false) -> void:
	if not followup or _fighter_id(source) == "luna_brave":
		sound(source, "ult_%s" % _fighter_id(source))

static func hit(source: Node, damage: float, strength: float, blocked: bool, absorbed: bool, forced := false) -> void:
	if blocked:
		sound(source, "guard")
		return
	sound(source, "hit_launch" if not absorbed and (forced or strength >= 480.0) else ("hit_heavy" if damage >= 10.0 else "hit_light"))
	sound(source, "hurt")

static func landing(source: Node, landed: bool) -> void:
	var manager := find(source)
	if manager == null:
		return
	var key := source.get_instance_id()
	if not manager._landing_states.has(key):
		manager._landing_states[key] = 0.0
		source.tree_exiting.connect(manager._forget_landing.bind(key), CONNECT_ONE_SHOT)
	var air_seconds: float = manager._landing_states[key]
	if not source.is_on_floor():
		manager._landing_states[key] = air_seconds + source.get_physics_process_delta_time()
		return
	manager._landing_states[key] = 0.0
	if landed and air_seconds + 0.000001 >= MIN_LAND_AIR_SECONDS:
		sound(source, "land")

func _forget_landing(key: int) -> void:
	_landing_states.erase(key)

static func card_offer(source: Node, already_visible: bool) -> void:
	if not already_visible:
		sound(source, "card_offer")

static func collapse(source: Node, seconds: int, label: Label) -> void:
	# The HUD calls this every frame. Keep the edge state on its own label so a
	# newly created HUD starts clean, including after a language/scene reload.
	var was_collapse := bool(label.get_meta("audio_collapse", false)) and label.visible
	label.set_meta("audio_collapse", seconds >= 0)
	if seconds >= 0 and not was_collapse:
		sound(source, "collapse_warning")

static func hazard(source: Node, kind: String, options: Dictionary) -> void:
	var ids := {"eruption": "eruption", "quake": "quake", "beams": "beam", "vines": "vines", "belts": "belt_reverse", "gates": "gate_open"}
	if ids.has(kind):
		sound(source, ids[kind], options)

static func results(source: Node, winner: Node) -> void:
	sound(source, "results")
	if is_instance_valid(winner):
		sound(source, "victory")
	music(source, "music_results")

static func story_advance(source: Node, action: String) -> void:
	if action in ["dialogue_next", "dialogue_skip"]:
		sound(source, "story_advance")

static func story_result(source: Node, clear: bool) -> void:
	sound(source, "results")
	if clear:
		sound(source, "victory")
	music(source, "music_results")

static func story_ending(source: Node) -> void:
	sound(source, "victory")
	music(source, "music_results")
