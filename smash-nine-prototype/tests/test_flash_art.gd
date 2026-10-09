extends SceneTree
## Short flashes draw their art, not a coloured rectangle on top of it (decision.md next-session
## item "사각형 대체 그림 점검", 2026-10-09): Frey's ultimate charge and release, Yuki's grand ward
## ending and seal burst; and, with the CODEX-ART-20 strips, the parry flash, landing dust, hit
## streak and seal break. Each rectangle stays only as the fallback without the art.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const VFX := preload("res://scripts/Vfx.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	var frey: Node = PLAYER_FACTORY.create("frey")
	arena.add_child(frey)
	frey.setup(CHARACTER_REGISTRY.get_characters()["frey"], 1, false)
	frey.set_physics_process(false)
	_expect_no_box("Frey's ultimate charge", "frey_ult_charge", func() -> void: frey._play_ultimate_charge())
	_expect_no_box("Frey's ultimate release", "frey_ult_wave", func() -> void: frey._play_ultimate_release())
	_expect_no_box("The parry flash", "parry_flash", func() -> void: frey._play_parry_effect(), true)
	_expect_no_box("The landing dust", "landing_dust", func() -> void: frey._spawn_landing_puff(), true)
	_expect_no_box("The hit streak", "hit_streak", func() -> void: frey._spawn_hit_slash(Vector2(40, -30), 600.0), true)
	var ward: Node2D = load("res://characters/yuki/YukiGrandWard.gd").new()
	arena.add_child(ward)
	ward.set_physics_process(false)
	_expect_no_box("Yuki's grand ward ending", "yuki_ult_burst", func() -> void: ward._play_final_effect())
	var seal: Node2D = load("res://characters/yuki/YukiSeal.gd").new()
	arena.add_child(seal)
	seal.set_physics_process(false)
	_expect_no_box("Yuki's seal burst", "yuki_l", func() -> void: seal._play_burst_effect())
	_expect_no_box("Yuki's seal break", "yuki_seal_break", func() -> void: seal._play_break_effect(), true)
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Flash art tests passed")
	quit(0)

## Runs the effect and fails if it added a ColorRect next to the art (and, with own_art, if that
## effect's strip did not play).
func _expect_no_box(what: String, effect: String, play: Callable, own_art := false) -> void:
	if not VFX.available(effect):
		push_error("%s: the effect art '%s' should be available" % [what, effect])
		failed = true
		return
	var before := _boxes()
	play.call()
	var added := _boxes() - before
	if added > 0:
		push_error("%s should draw its art, not a rectangle (%d added)" % [what, added])
		failed = true
	if own_art and arena.get_node_or_null("Vfx_%s" % effect) == null:
		push_error("%s should play the '%s' strip" % [what, effect])
		failed = true

func _boxes() -> int:
	var count := 0
	for child in arena.get_children():
		if child is ColorRect:
			count += 1
	return count
