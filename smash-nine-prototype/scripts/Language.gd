extends RefCounted
## Game language (user 2026-10-22: "인게임이 계속 영어로 써져 있는데, 한글과 영어판 2가지 선택 가능하게
## 해줘"). English is the source text; Korean comes from assets/i18n/strings.csv through Godot's
## TranslationServer (keys are the English strings, so code reads tr("Play")). The UI font is Noto
## Sans KR (assets/fonts/), which draws both languages in the web build too. The choice is kept in
## user:// like the game speed. Headless runs and test scripts always use English.

const LOCALES: Array[String] = ["en", "ko"]
const NAMES := {"en": "English", "ko": "한국어"}
const SAVE_PATH := "user://language.cfg"

static var locale := "en"
static var _loaded := false

## Reads the saved choice once (only when the game runs normally) and applies it.
static func load_saved() -> void:
	if not _loaded:
		_loaded = true
		locale = "en"
		if _uses_saved_choice():
			var config := ConfigFile.new()
			if config.load(SAVE_PATH) == OK:
				var saved := str(config.get_value("game", "language", "en"))
				locale = saved if LOCALES.has(saved) else "en"
	apply()

static func apply() -> void:
	TranslationServer.set_locale(locale)

## Next language, applied and saved for the next start.
static func cycle() -> String:
	locale = LOCALES[(LOCALES.find(locale) + 1) % LOCALES.size()]
	apply()
	if _uses_saved_choice():
		var config := ConfigFile.new()
		config.set_value("game", "language", locale)
		config.save(SAVE_PATH)
	return locale

static func set_locale(new_locale: String) -> void:
	locale = new_locale if LOCALES.has(new_locale) else "en"
	apply()

static func label() -> String:
	return str(NAMES.get(locale, "English"))

static func is_korean() -> bool:
	return locale == "ko"

static func _uses_saved_choice() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	for arg in OS.get_cmdline_args():
		if arg == "--script" or arg == "-s":
			return false
	return true
