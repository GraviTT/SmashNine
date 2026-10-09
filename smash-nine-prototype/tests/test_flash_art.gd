extends SceneTree
## Short flashes draw their art, not a coloured rectangle on top of it (decision.md next-session
## item "사각형 대체 그림 점검", 2026-10-09): Frey's ultimate charge and release, Yuki's grand ward
## ending and seal burst. Each rectangle stays only as the fallback without the art.

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
	var ward: Node2D = load("res://characters/yuki/YukiGrandWard.gd").new()
	arena.add_child(ward)
	ward.set_physics_process(false)
	_expect_no_box("Yuki's grand ward ending", "yuki_ult_burst", func() -> void: ward._play_final_effect())
	var seal: Node2D = load("res://characters/yuki/YukiSeal.gd").new()
	arena.add_child(seal)
	seal.set_physics_process(false)
	_expect_no_box("Yuki's seal burst", "yuki_l", func() -> void: seal._play_burst_effect())
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Flash art tests passed")
	quit(0)

## Runs the effect and fails if it added a ColorRect next to the art.
func _expect_no_box(what: String, effect: String, play: Callable) -> void:
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

func _boxes() -> int:
	var count := 0
	for child in arena.get_children():
		if child is ColorRect:
			count += 1
	return count
