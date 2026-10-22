extends SceneTree
## The UI font is a subset of Noto Sans KR (assets/fonts/README.md): every character the
## translation table writes, in English and Korean, must be in it, or the screen shows empty
## boxes. Rebuild the font with tools/font_subset/make_ui_font.py when this fails.

const UI_FONT := "res://assets/fonts/ui_font.tres"
const TABLE := "res://assets/i18n/strings.csv"

func _initialize() -> void:
	var font: Font = load(UI_FONT)
	if font == null:
		push_error("The UI font %s should load" % UI_FONT)
		quit(1)
		return
	var text := FileAccess.get_file_as_string(TABLE) + FileAccess.get_file_as_string("res://assets/i18n/story.csv")
	var missing := {}
	var checked := 0
	for index in text.length():
		var code := text.unicode_at(index)
		if code < 0x20 or code == 0x22 or code == 0x2C:
			continue
		checked += 1
		if not font.has_char(code):
			missing[String.chr(code)] = true
	if not missing.is_empty():
		push_error("The UI font lacks %d characters used by the translation table: %s" % [missing.size(), "".join(missing.keys())])
		quit(1)
		return
	print("Font coverage tests passed (%d characters of the translation table)" % checked)
	quit(0)
