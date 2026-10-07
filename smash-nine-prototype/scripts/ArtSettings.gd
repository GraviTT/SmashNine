extends RefCounted
## Which art set the game draws: the procedural/third-party prototype look or the
## original art made for the game (Codex builders, routine 2026-10-07). The user picks
## the default after comparing; F2 on the start screen switches and reloads the scene.
## Anything missing from the original set falls back to the prototype look.

const STYLE_PROTOTYPE := "prototype"
const STYLE_ORIGINAL := "original"

static var style := STYLE_PROTOTYPE

static func use_original() -> bool:
	return style == STYLE_ORIGINAL

static func toggle() -> void:
	style = STYLE_ORIGINAL if style == STYLE_PROTOTYPE else STYLE_PROTOTYPE

static func label() -> String:
	return "Original art" if use_original() else "Prototype art"

## Original art texture at res://assets/art/... when the original style is on and the file
## exists, otherwise null (the caller keeps its prototype look).
static func original_texture(path: String) -> Texture2D:
	if not use_original() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

## A character's sheet: assets/art/<id>/<id>_sheet.png when the original style is on.
static func character_sheet(character_id: String, fallback: Texture2D) -> Texture2D:
	var sheet := original_texture("res://assets/art/%s/%s_sheet.png" % [character_id, character_id])
	return sheet if sheet != null else fallback
