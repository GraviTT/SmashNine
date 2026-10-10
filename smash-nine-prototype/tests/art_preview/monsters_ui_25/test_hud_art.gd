extends SceneTree
## Headless wiring smoke test for the ART-25 MatchHud-only changes.

const MATCH_HUD := preload("res://scripts/ui/MatchHud.gd")
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const NAMES := [
	"Asgard", "Midgard", "Niflheim", "Alfheim", "Muspelheim",
	"Svartalfheim", "Vanaheim", "Jotunheim", "Yggdrasil Heart",
]

class TestLayout extends RefCounted:
	func realm_count() -> int:
		return 9

	func get_realm(index: int) -> Dictionary:
		return {"name": NAMES[index], "grid": Vector2i(index % 3, index / 3)}

class TestDirector extends Node:
	func get_state(_index: int) -> String:
		return "stable"

	func get_warning_seconds_left() -> int:
		return 7

func _initialize() -> void:
	ART_SETTINGS.style = ART_SETTINGS.STYLE_ORIGINAL
	var hud := MATCH_HUD.new()
	root.add_child(hud)
	await process_frame
	if not hud.cutin_band is TextureRect:
		push_error("Ultimate cut-in did not load the authored band texture")
		quit(1)
		return
	var director := TestDirector.new()
	root.add_child(director)
	hud.rebuild_minimap(TestLayout.new(), director, 0)
	await process_frame
	var textured := 0
	for child in hud.minimap_root.get_children():
		if child is TextureRect:
			textured += 1
	if textured != 9:
		push_error("Expected 9 minimap emblems, got %d" % textured)
		quit(1)
		return
	ART_SETTINGS.style = ART_SETTINGS.STYLE_PROTOTYPE
	hud.rebuild_minimap(TestLayout.new(), director, 0)
	await process_frame
	textured = 0
	for child in hud.minimap_root.get_children():
		if child is TextureRect:
			textured += 1
	if textured != 0:
		push_error("Prototype fallback unexpectedly kept %d emblem textures" % textured)
		quit(1)
		return
	ART_SETTINGS.style = ART_SETTINGS.STYLE_ORIGINAL
	print("HUD art wiring passed (9 emblems, prototype boxes fallback, authored cut-in band)")
	quit(0)
