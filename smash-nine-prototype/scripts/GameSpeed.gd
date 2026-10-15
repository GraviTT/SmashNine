extends RefCounted
## Game speed (user 2026-10-15: "너무 빨라서 스프라이트의 각 모션이 잘 보이지도 않고 상대의 반응도
## 따라갈수 없다"; proposal reports/tempo-proposal-2026-10-15.md, option A). A match runs under
## Engine.time_scale = factor, so movement, jumps, attacks, knockback, effects, bots and the match
## clock all slow by the same ratio and every balance number measured at 100% still holds.
## T cycles 100 / 90 / 80 / 70 % on the start screen and during a match; the choice is kept in
## user://. Menus and the result screen run at 100%. Headless runs and test scripts always use 100%.

const STEPS: Array[float] = [1.0, 0.9, 0.8, 0.7]
const SAVE_PATH := "user://game_speed.cfg"

static var factor := 1.0
static var _loaded := false

## Reads the saved choice once (only when the game runs normally; tests stay at 100%).
static func load_saved() -> void:
	if _loaded:
		return
	_loaded = true
	factor = 1.0
	if not _uses_saved_choice():
		return
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		factor = _nearest_step(float(config.get_value("game", "speed", 1.0)))

## Next step (100 -> 90 -> 80 -> 70 -> 100 %), saved for the next start.
static func cycle() -> float:
	var index := STEPS.find(_nearest_step(factor))
	factor = STEPS[(index + 1) % STEPS.size()]
	if _uses_saved_choice():
		var config := ConfigFile.new()
		config.set_value("game", "speed", factor)
		config.save(SAVE_PATH)
	return factor

static func percent() -> int:
	return roundi(factor * 100.0)

static func label() -> String:
	return "Game speed %d%%" % percent()

## A match in progress runs at the chosen speed.
static func apply_to_match() -> void:
	Engine.time_scale = factor

## Menus, the result screen and anything outside a match run at normal speed.
static func reset_engine() -> void:
	Engine.time_scale = 1.0

static func _nearest_step(value: float) -> float:
	var best: float = STEPS[0]
	for step in STEPS:
		if absf(step - value) < absf(best - value):
			best = step
	return best

static func _uses_saved_choice() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	for arg in OS.get_cmdline_args():
		if arg == "--script" or arg == "-s":
			return false
	return true
