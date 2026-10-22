extends RefCounted
## Audio alone uses audio.cfg; headless/script runs never touch the player's file.
const SAVE_PATH := "user://audio.cfg"
const DEFAULTS := {"master": 80, "music": 60, "effects": 80, "mute": false}
static var values: Dictionary = DEFAULTS.duplicate()
static var _loaded := false

static func uses_saved_choice() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	for arg in OS.get_cmdline_args():
		if arg in ["--script", "-s"]:
			return false
	return true

static func load_saved() -> void:
	if not _loaded:
		_loaded = true
		values = DEFAULTS.duplicate()
		if uses_saved_choice():
			load_from(SAVE_PATH)
	apply()

static func load_from(path: String) -> Error:
	var config := ConfigFile.new()
	var result := config.load(path)
	values = DEFAULTS.duplicate()
	if result == OK:
		for key in DEFAULTS:
			var value: Variant = config.get_value("audio", key, DEFAULTS[key])
			values[key] = bool(value) if key == "mute" else _step(float(value))
	apply()
	return result

static func save_to(path: String) -> Error:
	var config := ConfigFile.new()
	for key in DEFAULTS:
		config.set_value("audio", key, values[key])
	return config.save(path)

static func cycle(key: String) -> void:
	if key == "mute":
		values.mute = not bool(values.mute)
	elif key in ["master", "music", "effects"]:
		values[key] = (int(values[key]) + 10) % 110
	else:
		return
	apply()
	if uses_saved_choice():
		save_to(SAVE_PATH)

static func _step(value: float) -> int:
	return clampi(roundi(value / 10.0) * 10, 0, 100)

static func ensure_buses() -> void:
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")

static func apply() -> void:
	ensure_buses()
	for pair in [["Master", "master"], ["Music", "music"], ["SFX", "effects"]]:
		var index := AudioServer.get_bus_index(pair[0])
		var linear := float(values[pair[1]]) / 100.0
		AudioServer.set_bus_volume_db(index, linear_to_db(linear) if linear > 0.0 else -80.0)
		AudioServer.set_bus_mute(index, linear <= 0.0 or (pair[0] == "Master" and bool(values.mute)))
