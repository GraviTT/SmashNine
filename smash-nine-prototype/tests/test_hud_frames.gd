extends SceneTree
## CODEX-ART-27: authored HUD frames in original mode, exact ColorRect fallback in F2 mode.

const MATCH_HUD := preload("res://scripts/ui/MatchHud.gd")
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")

func _initialize() -> void:
	ART_SETTINGS.style = ART_SETTINGS.STYLE_ORIGINAL
	var original := MATCH_HUD.new()
	root.add_child(original)
	await process_frame
	original.show_start_screen([])
	await process_frame
	_check_original(original)
	original.queue_free()
	await process_frame

	ART_SETTINGS.style = ART_SETTINGS.STYLE_PROTOTYPE
	var fallback := MATCH_HUD.new()
	root.add_child(fallback)
	await process_frame
	fallback.show_start_screen([])
	await process_frame
	_check_fallback(fallback)
	fallback.queue_free()
	ART_SETTINGS.style = ART_SETTINGS.STYLE_ORIGINAL
	if _failed:
		quit(1)
		return
	print("HUD frame tests passed (skill 4, HP 1, cards 3, result 1, menu 2; title art + ColorRect fallback)")
	quit(0)

var _failed := false

func _check_original(hud: CanvasLayer) -> void:
	var expected := {
		"SkillSlotFrame": 4,
		"HpBarFrame": 1,
		"CardPanelFrame": 3,
		"ResultPanelFrame": 1,
		"Menu": 2,
	}
	for prefix: String in expected:
		var found := _count_named_type(hud, prefix, "NinePatchRect")
		if found != int(expected[prefix]):
			_fail("Original HUD expected %d NinePatchRect nodes for %s, got %d" % [expected[prefix], prefix, found])
	if hud.overlay_background_art.texture == null:
		_fail("Original HUD did not load title_bg.png")
	elif hud.overlay_background_art.texture.resource_path != "res://assets/art/ui/title_bg.png":
		_fail("Original HUD loaded unexpected title background: %s" % hud.overlay_background_art.texture.resource_path)

func _check_fallback(hud: CanvasLayer) -> void:
	for prefix in ["SkillSlotFrame", "HpBarFrame", "CardPanelFrame", "ResultPanelFrame", "Menu"]:
		if _count_named_type(hud, prefix, "NinePatchRect") != 0:
			_fail("Prototype HUD unexpectedly kept authored NinePatchRect for %s" % prefix)
	var expected := {"SkillSlotFrame": 4, "HpBarFrame": 1, "CardPanelFrame": 3, "ResultPanelFrame": 1, "Menu": 2}
	for prefix: String in expected:
		var found := _count_named_type(hud, prefix, "ColorRect")
		if found != int(expected[prefix]):
			_fail("Prototype HUD expected %d ColorRect nodes for %s, got %d" % [expected[prefix], prefix, found])
	if hud.overlay_background_art.texture != null:
		_fail("Prototype HUD unexpectedly loaded title background art")

func _count_named_type(node: Node, prefix: String, type_name: String) -> int:
	var count := 0
	for child in node.get_children():
		if child.name.begins_with(prefix) and child.get_class() == type_name:
			count += 1
		count += _count_named_type(child, prefix, type_name)
	return count

func _fail(message: String) -> void:
	_failed = true
	push_error(message)
