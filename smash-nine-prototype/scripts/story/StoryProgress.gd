extends RefCounted
## Static in-process state survives Main reloads. Script/headless runs never touch the real save.
const SAVE_PATH := "user://story.cfg"
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const CARDS := preload("res://scripts/match/SoulCards.gd")
static var runs: Dictionary = {}
static var _loaded := false

static func uses_real_save() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	for argument in OS.get_cmdline_args():
		if argument in ["-s", "--script"]:
			return false
	return true

static func load_saved(test_path := "") -> void:
	if test_path == "" and _loaded:
		return
	_loaded = true
	if test_path == "" and not uses_real_save():
		return
	var config := ConfigFile.new()
	if config.load(SAVE_PATH if test_path == "" else test_path) != OK:
		return
	runs.clear()
	for id in REGISTRY.get_character_ids():
		var value: Variant = config.get_value("runs", id, {})
		if value is Dictionary and not value.is_empty():
			runs[id] = _validated(value)

static func save(test_path := "") -> Error:
	if test_path == "" and not uses_real_save():
		return OK
	var config := ConfigFile.new()
	config.set_value("meta", "version", 1)
	for id in runs:
		config.set_value("runs", id, runs[id])
	return config.save(SAVE_PATH if test_path == "" else test_path)

static func _validated(value: Dictionary) -> Dictionary:
	var checkpoints := {"1": {"souls": 0, "cards": []}}
	var source: Variant = value.get("checkpoints", {})
	if source is Dictionary:
		for number in range(1, 10):
			var entry: Variant = source.get(str(number), {})
			if not entry is Dictionary or entry.is_empty():
				continue
			var cards: Array[String] = []
			var saved_cards: Variant = entry.get("cards", [])
			if saved_cards is Array:
				for card in saved_cards:
					if cards.size() < 3 and not CARDS.find(str(card)).is_empty():
						cards.append(str(card))
			checkpoints[str(number)] = {"souls": maxi(int(entry.get("souls", 0)), 0), "cards": cards}
	return {"cleared": clampi(int(value.get("cleared", 0)), 0, 9), "difficulty": "easy" if value.get("difficulty", "normal") == "easy" else "normal", "done": bool(value.get("done", false)), "checkpoints": checkpoints}

static func get_run(id: String) -> Dictionary:
	return runs.get(id, {}).duplicate(true)

static func new_journey(id: String, difficulty: String) -> void:
	runs[id] = {"cleared": 0, "difficulty": difficulty, "done": false, "checkpoints": {"1": {"souls": 0, "cards": []}}}
	save()

static func set_difficulty(id: String, difficulty: String) -> void:
	if runs.has(id):
		runs[id].difficulty = "easy" if difficulty == "easy" else "normal"
		save()

static func checkpoint(id: String, number: int) -> Dictionary:
	return get_run(id).get("checkpoints", {}).get(str(number), {"souls": 0, "cards": []}).duplicate(true)

static func complete_stage(id: String, number: int, souls: int, cards: Array) -> void:
	if not runs.has(id):
		new_journey(id, "normal")
	var run: Dictionary = runs[id]
	# Replaying a cleared stage never overwrites a later checkpoint or rolls progress back.
	if number > int(run.cleared):
		run.cleared = number
		if number < 9:
			run.checkpoints[str(number + 1)] = {"souls": souls, "cards": cards.slice(0, 3).duplicate()}
		run.done = number == 9
	save()

static func continue_stage(id: String) -> int:
	return clampi(int(get_run(id).get("cleared", 0)) + 1, 1, 9)
