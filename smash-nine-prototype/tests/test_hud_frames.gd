extends SceneTree
## CODEX-ART-27: authored HUD frames in original mode, exact ColorRect fallback in F2 mode.
## Since the match HUD of 2026-11-25 (pick cup round 2026-11-25-ui) the skill slots and the HP bar
## are flat plates in both modes; the authored frames left are the soul card column's (one
## frame round the three cards), the result panel's and the menu buttons'.

const MATCH_HUD := preload("res://scripts/ui/MatchHud.gd")
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const FRAMED := {"CardPanelFrame": 1, "ResultPanelFrame": 1, "Menu": 2}
const FLAT := ["SkillSlotFrame", "HpBarFrame"]

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
	print("HUD frame tests passed (card column 1, result 1, menu 2 authored; five flat skill slots with U hidden, flat HP bar; title art + ColorRect fallback)")
	quit(0)

var _failed := false

func _check_original(hud: CanvasLayer) -> void:
	for prefix: String in FRAMED:
		var found := _count_named_type(hud, prefix, "NinePatchRect")
		if found != int(FRAMED[prefix]):
			_fail("Original HUD expected %d NinePatchRect nodes for %s, got %d" % [FRAMED[prefix], prefix, found])
	_check_flat(hud, "Original")
	if hud.overlay_background_art.texture == null:
		_fail("Original HUD did not load title_bg.png")
	elif hud.overlay_background_art.texture.resource_path != "res://assets/art/ui/title_bg.png":
		_fail("Original HUD loaded unexpected title background: %s" % hud.overlay_background_art.texture.resource_path)

func _check_fallback(hud: CanvasLayer) -> void:
	for prefix: String in FRAMED:
		if _count_named_type(hud, prefix, "NinePatchRect") != 0:
			_fail("Prototype HUD unexpectedly kept authored NinePatchRect for %s" % prefix)
		var found := _count_named_type(hud, prefix, "ColorRect")
		if found != int(FRAMED[prefix]):
			_fail("Prototype HUD expected %d ColorRect nodes for %s, got %d" % [FRAMED[prefix], prefix, found])
	_check_flat(hud, "Prototype")
	if hud.overlay_background_art.texture != null:
		_fail("Prototype HUD unexpectedly loaded title background art")

## J, K, L, U (the third skill, D47; shown only for a fighter that has one) and I, each a flat
## plate, and one flat HP bar: no authored frame and no ColorRect stand-in for either.
func _check_flat(hud: CanvasLayer, mode: String) -> void:
	for prefix: String in FLAT:
		for type_name in ["NinePatchRect", "ColorRect"]:
			if _count_named_type(hud, prefix, type_name) != 0:
				_fail("%s HUD should draw no %s for %s" % [mode, type_name, prefix])
	if _count_named_type(hud, "SkillSlotBack", "Panel") != 5:
		_fail("%s HUD expected five flat skill slots, got %d" % [mode, _count_named_type(hud, "SkillSlotBack", "Panel")])
	if _count_named_type(hud, "HpFill", "Panel") != 1:
		_fail("%s HUD expected one flat HP bar" % mode)
	var third := hud.skill_bar.get_node_or_null("SkillSlotU") as Control
	if third == null or third.visible:
		_fail("The U slot should exist and stay hidden until a fighter with a third skill shows")

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
