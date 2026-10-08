extends SceneTree
## Bottom-right skill bar (user 2026-10-08: keys and skill icons at the bottom right): four
## slots for the fighter in focus, a cooldown shade and seconds for the ultimate and for Rio's
## rune shield, a gold edge once the ultimate is ready, Brave Luna's own set while she is
## transformed, and the key letter in the slot when there is no icon (prototype style).

const MAIN_SCENE := "res://scenes/Main.tscn"
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _run() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	root.add_child(main)
	for frame in 5:
		await process_frame
	main._start_match("rio")
	for frame in 10:
		await process_frame
	var hud: Node = main.hud
	var rio: Node = main._get_human_player()
	if not hud.skill_bar.visible or not hud.controls_label.visible or hud.skill_slots.size() != 4:
		_fail("The skill bar and the short controls line should show during a match")
	# Cooldown shades: the ultimate and Rio's rune shield.
	rio.ultimate_cooldown_timer = 15.0
	rio.rune_cooldown_timer = 1.5
	hud.update_skill_bar(rio, 0.016)
	var ultimate: Dictionary = hud.skill_slots["i"]
	var rune: Dictionary = hud.skill_slots["l"]
	if absf(ultimate.shade.size.y - hud.SKILL_SLOT_SIZE * 0.5) > 0.5 or ultimate.time.text != "15":
		_fail("Half the ultimate cooldown left should shade half the slot and say 15 (%.1f, %s)" % [ultimate.shade.size.y, ultimate.time.text])
	if rune.shade.size.y <= 0.0 or rune.time.text != "2":
		_fail("Rio's rune shield cooldown should shade its slot")
	if hud.skill_slots["k"].shade.size.y > 0.0:
		_fail("A move without a cooldown should not be shaded")
	rio.ultimate_cooldown_timer = 0.0
	hud.update_skill_bar(rio, 0.016)
	var edge: StyleBoxFlat = ultimate.style
	if edge.border_width_top < 2 or edge.border_color.r < 0.9:
		_fail("A ready ultimate should get the gold edge")
	# Brave Luna switches the icon set; the prototype style shows key letters.
	main.queue_free()
	await process_frame
	main = load(MAIN_SCENE).instantiate()
	root.add_child(main)
	for frame in 5:
		await process_frame
	main._start_match("luna")
	for frame in 10:
		await process_frame
	hud = main.hud
	var luna: Node = main._get_human_player()
	hud.update_skill_bar(luna, 0.016)
	var normal_set: String = hud.skill_icon_set
	luna.transformed = true
	hud.update_skill_bar(luna, 0.016)
	if hud.skill_icon_set == normal_set or not hud.skill_icon_set.begins_with("luna_brave"):
		_fail("Brave Luna should switch to her own icons (%s -> %s)" % [normal_set, hud.skill_icon_set])
	luna.transformed = false
	ART_SETTINGS.toggle()
	hud.update_skill_bar(luna, 0.016)
	ART_SETTINGS.toggle()
	var slot_j: Dictionary = hud.skill_slots["j"]
	if slot_j.icon.texture != null or not slot_j.glyph.visible or slot_j.glyph.text != "J":
		_fail("Without icons the slot should show its key letter")
	main.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Skill bar tests passed")
	quit(0)
