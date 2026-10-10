extends RefCounted
## Which art set the realms, effects and UI draw: the original art made for the game
## (Codex builders, 2026-10-07; the default since the user adopted it, D20) or the plain
## procedural look. F2 on the start screen switches and reloads. Fighters always draw their
## original sheets (the third-party prototype sprites were removed, user 2026-10-07).

const STYLE_PROTOTYPE := "prototype"
const STYLE_ORIGINAL := "original"
const DEFAULT_STYLE := STYLE_ORIGINAL

static var style := DEFAULT_STYLE

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

## A character's original sheet, or null: assets/art/<id>/<id>_<body>_sheet.png for a
## character drawn in two bodies (male characters get a male and a female sheet, user
## 2026-10-07), else assets/art/<id>/<id>_sheet.png. Characters have no other art since the
## third-party prototype sprites were removed (user 2026-10-07), so the style switch does
## not apply to them.
static func original_character_sheet(character_id: String, body := "") -> Texture2D:
	var paths: Array[String] = []
	if body != "":
		paths.append("res://assets/art/%s/%s_%s_sheet.png" % [character_id, character_id, body])
	paths.append("res://assets/art/%s/%s_sheet.png" % [character_id, character_id])
	# No body asked for (tests, the dummy path): any body the character has.
	for any_body in ["male", "female"]:
		paths.append("res://assets/art/%s/%s_%s_sheet.png" % [character_id, character_id, any_body])
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

## Optional move-only sheet beside the main character atlas. `variant` is used by alternate
## forms that live in the same character folder (Luna's luna_brave_moves_sheet.png).
static func original_character_moves_sheet(character_id: String, body := "", variant := "") -> Texture2D:
	var stem := character_id if variant == "" else variant
	var paths: Array[String] = []
	if body != "":
		paths.append("res://assets/art/%s/%s_%s_moves_sheet.png" % [character_id, stem, body])
	paths.append("res://assets/art/%s/%s_moves_sheet.png" % [character_id, stem])
	for any_body in ["male", "female"]:
		paths.append("res://assets/art/%s/%s_%s_moves_sheet.png" % [character_id, stem, any_body])
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

## A sprite for right-facing effect art (projectiles) pointed along `direction`: art
## aimed left is mirrored instead of turned upside down. Scale 2 matches the fighters.
## Effect files redrawn at a larger size for today's scales (CODEX-ART-14/16) are drawn smaller
## by this ratio, so code written for the old size keeps its on-screen size: actual width over
## the width the code was written for (1 for the old files).
static func size_ratio(texture: Texture2D, authored_width: float) -> float:
	if texture == null or authored_width <= 0.0:
		return 1.0
	return maxf(float(texture.get_width()) / authored_width, 0.01)

static func aimed_sprite(texture: Texture2D, direction: Vector2, art_scale := 2.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "ArtSprite"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(art_scale, art_scale)
	if direction.x < 0.0:
		sprite.flip_h = true
		sprite.rotation = (-direction).angle()
	else:
		sprite.rotation = direction.angle()
	return sprite

## Character portrait for menus and the HUD: the face cut from the main illustration
## (<id>[_<body>]_face.png, CODEX-ART-08), then the pixel portrait (<id>[_<body>]_portrait.png),
## else the first idle frame of the character's sheet.
static func character_portrait(character_id: String, body := "") -> Texture2D:
	for kind in ["face", "portrait"]:
		var found := _first_existing(character_id, body, kind)
		if found != null:
			return found
	var sheet := original_character_sheet(character_id, body)
	if sheet == null:
		return null
	var cell := float(sheet.get_width() / 6)
	var idle := AtlasTexture.new()
	idle.atlas = sheet
	idle.region = Rect2(0, 0, cell, cell)
	return idle

## True when the portrait is a painted face (smooth filter) rather than pixel art.
static func is_painted_portrait(texture: Texture2D) -> bool:
	return texture != null and texture.resource_path.ends_with("_face.png")

static func _first_existing(character_id: String, body: String, kind: String) -> Texture2D:
	var paths: Array[String] = []
	if body != "":
		paths.append("res://assets/art/%s/%s_%s_%s.png" % [character_id, character_id, body, kind])
	paths.append("res://assets/art/%s/%s_%s.png" % [character_id, character_id, kind])
	for any_body in ["male", "female"]:
		paths.append("res://assets/art/%s/%s_%s_%s.png" % [character_id, character_id, any_body, kind])
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null
