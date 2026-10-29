extends SceneTree

const MAIN_SCRIPT := preload("res://scripts/Main.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
## Redrawn with 6-frame motions (D33, 2026-10-14) and the 8-frame walk (user 2026-10-15): Frey, Luna
## and Brave Luna, Yuki, Nova and Rio (both bodies each).
const FREY_LAYOUT := {"idle": 6, "walk": 8, "jump": 1, "fall": 1, "attack": 6, "shield": 6, "hurt": 1}
const LUNA_LAYOUT := FREY_LAYOUT
const YUKI_LAYOUT := FREY_LAYOUT
const NOVA_LAYOUT := FREY_LAYOUT

func _initialize() -> void:
	call_deferred("_run")

## Every character's scene, script and shared 6x7 animation cut, in both art styles
## (fighters always draw their original sheet; the prototype sprites were removed).
func _run() -> void:
	for style in [ART_SETTINGS.STYLE_PROTOTYPE, ART_SETTINGS.STYLE_ORIGINAL]:
		ART_SETTINGS.style = style
		if not await _check_characters():
			return
	print("All character scene and sprite smoke tests passed")
	quit(0)

func _check_characters() -> bool:
	var main := MAIN_SCRIPT.new()
	var characters := CHARACTER_REGISTRY.get_characters()
	var expected_counts := {
		"frey": FREY_LAYOUT,
		"yuki": YUKI_LAYOUT,
		"luna": LUNA_LAYOUT,
		"nova": NOVA_LAYOUT,
		"rio": FREY_LAYOUT
	}
	for character_id in expected_counts:
		var player := PLAYER_FACTORY.create(character_id)
		root.add_child(player)
		player.setup(characters[character_id], 1, true)
		await process_frame
		var expected_script := "res://characters/%s/%s.gd" % [character_id, character_id.capitalize()]
		if player.get_script().resource_path != expected_script:
			_fail("Wrong character script: %s" % player.get_script().resource_path)
			return false
		var sprite := player.get_node("CharacterSprite") as AnimatedSprite2D
		var frames := sprite.sprite_frames
		for base_name in expected_counts[character_id]:
			var animation_name := StringName("%s_%s" % [character_id, base_name])
			if not frames.has_animation(animation_name):
				_fail("Missing animation: %s" % animation_name)
				return false
			var expected: int = _adopted_strip_frames(player, character_id, base_name)
			if expected == 0:
				expected = expected_counts[character_id][base_name]
			if frames.get_frame_count(animation_name) != expected:
				_fail("Wrong frame count for %s" % animation_name)
				return false
		if not sprite.visible or player.get_node("Body").visible:
			_fail("%s sprite visibility did not replace the placeholder body" % character_id)
			return false
		root.remove_child(player)
		player.free()
	main.free()
	return true

## A sheet row replaced by an adopted SYS-06 strip plays the strip (jump 3, fall 2, hurt 3 drawings);
## same lookup as PlayerBase._add_optional_motion_rows: <id>_<body>_<row>.png, else <id>_<row>.png.
func _adopted_strip_frames(player: Node, prefix: String, row: String) -> int:
	for spec in player.OPTIONAL_MOTION_ROWS:
		if spec[0] != row:
			continue
		for stem in ["%s_%s" % [prefix, player.body_type], prefix]:
			if ResourceLoader.exists("res://assets/art/%s/%s_%s.png" % [prefix, stem, row]):
				return int(spec[1])
	return 0

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
