extends SceneTree
## Original art path (ArtSettings): the center realm draws its painted layers, platform
## strips (edge line kept on top) and portal art; Frey loads the original sheet; the
## prototype style keeps the old look.

const MAIN_SCENE := "res://scenes/Main.tscn"
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const FREY_SHEET := "res://assets/art/frey/frey_sheet.png"

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# The user adopted the original art (2026-10-07): it is what a fresh game shows.
	if ART_SETTINGS.style != ART_SETTINGS.STYLE_ORIGINAL:
		_fail("Default art style is %s, expected original" % ART_SETTINGS.style)
		quit(1)
		return
	for style in [ART_SETTINGS.STYLE_ORIGINAL, ART_SETTINGS.STYLE_PROTOTYPE]:
		ART_SETTINGS.style = style
		await _check_style(style == ART_SETTINGS.STYLE_ORIGINAL)
		if failed:
			quit(1)
			return
	print("Art tests passed (original and prototype, every character and body)")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _check_style(original: bool) -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.player_count = 2
	root.add_child(main)
	await process_frame
	var center_root: Node = main.world.get_child(main.CENTRAL_REALM_INDEX)
	var painted_layers := center_root.find_children("Painted_bg_*", "TextureRect", true, false).size()
	var painted_platforms := center_root.find_children("PaintedPlatform", "NinePatchRect", true, false)
	var label := "original" if original else "prototype"
	if original and (painted_layers != 2 or painted_platforms.size() != 12):
		_fail("%s: expected 2 painted layers and 12 painted platforms, got %d / %d" % [label, painted_layers, painted_platforms.size()])
	elif not original and (painted_layers != 0 or not painted_platforms.is_empty()):
		_fail("%s: painted art shown in the prototype style" % label)
	if original and not failed:
		var body: Node = painted_platforms[0].get_parent()
		if body.get_child(body.get_child_count() - 1).name != "Edge":
			_fail("The platform edge line must stay on top of the painted strip")
	var frey: Node = PLAYER_FACTORY.create("frey")
	main.add_child(frey)
	frey.setup(CHARACTER_REGISTRY.get_characters()["frey"], 99, false)
	# Fighters draw their original sheet in both styles (no prototype sprites any more).
	var frame: AtlasTexture = frey.character_sprite.sprite_frames.get_frame_texture(&"frey_idle", 0)
	if frame.atlas.resource_path != FREY_SHEET:
		_fail("%s: Frey sheet is %s" % [label, frame.atlas.resource_path])
	if (main.hud.overlay_logo.texture != null) != original:
		_fail("%s: the title logo should load only in the original style" % label)
	if original:
		_check_character_sheets(main)
		_check_brave_luna(main)
	main.queue_free()
	await process_frame

## Every character draws its original sheet in every body it has (male characters
## both, user 2026-10-07), cut into the shared 6x7 layout and drawn at scale 2.
func _check_character_sheets(main: Node) -> void:
	var characters := CHARACTER_REGISTRY.get_characters()
	for character_id in CHARACTER_REGISTRY.get_character_ids():
		for body in CHARACTER_REGISTRY.get_bodies(character_id):
			var player: Node = PLAYER_FACTORY.create(character_id, body)
			main.add_child(player)
			player.setup(characters[character_id], 90, false)
			var expected := "res://assets/art/%s/%s_%s_sheet.png" % [character_id, character_id, body]
			if not ResourceLoader.exists(expected):
				expected = "res://assets/art/%s/%s_sheet.png" % [character_id, character_id]
			var frames: SpriteFrames = player.character_sprite.sprite_frames
			var label := "%s (%s)" % [character_id, body]
			if not player.uses_original_sheet or frames.get_frame_texture(StringName("%s_idle" % character_id), 0).atlas.resource_path != expected:
				_fail("%s does not draw %s" % [label, expected])
			elif frames.get_frame_count(StringName("%s_walk" % character_id)) != 6 or frames.get_frame_count(StringName("%s_shield" % character_id)) != 6:
				_fail("%s sheet is not cut in the shared layout" % label)
			else:
				_sheet_drawn_right(player, label)
			player.queue_free()

## Brave Luna draws her own sheet while transformed, the normal one otherwise.
func _check_brave_luna(main: Node) -> void:
	var luna: Node = PLAYER_FACTORY.create("luna")
	main.add_child(luna)
	luna.setup(CHARACTER_REGISTRY.get_characters()["luna"], 91, false)
	if not luna.character_sprite.sprite_frames.has_animation(&"luna_brave_attack"):
		_fail("Brave Luna's sheet is not loaded")
	elif luna._get_sprite_animation_name(&"idle") != &"luna_idle":
		_fail("Normal Luna should draw luna_idle")
	else:
		luna.transformed = true
		if luna._get_sprite_animation_name(&"idle") != &"luna_brave_idle":
			_fail("Transformed Luna should draw luna_brave_idle")
	luna.queue_free()

## v1 sheets (64 px cells) draw at 2x, v2 (128 px cells) at 1x; feet on the origin either way.
func _sheet_drawn_right(player: Node, label: String) -> bool:
	var cell: int = player.original_sheet_cell
	# Every fighter has the v2 sheet since CODEX-ART-08 (D25): 128 px cells, per-character proportions.
	if cell != 128:
		_fail("%s still has a v1 sheet (cell %d)" % [label, cell])
		return false
	var expected_scale := 128.0 / float(cell)
	var feet := 48.0 if cell == 64 else 120.0
	var sprite: AnimatedSprite2D = player.character_sprite
	if cell != 64 and cell != 128:
		_fail("%s sheet has an unknown cell size %d" % [label, cell])
		return false
	if not sprite.scale.is_equal_approx(Vector2.ONE * expected_scale):
		_fail("%s sheet should be drawn at %.0fx, got %s" % [label, expected_scale, sprite.scale])
		return false
	# Centered sprite: the cell's feet row must land on the collision origin (y = 0).
	var feet_world := sprite.position.y + (feet - cell * 0.5) * expected_scale
	if absf(feet_world) > 0.5:
		_fail("%s feet land at y=%.1f, expected 0" % [label, feet_world])
		return false
	return true
