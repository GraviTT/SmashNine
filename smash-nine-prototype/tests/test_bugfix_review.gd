extends SceneTree
## Regressions from the whole-code bug review of 2026-10-21 (branch claude/bugfix-review-2026-10-21).
## Each case failed before its fix.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D
var failed := false
var passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	await _test_launch_hit_ends_skill_dash()
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Bug review regression tests passed (%d)" % passed)
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _fighter(character_id: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = true
	return fighter

## A launching hit (apply_forced_launch_hit) left skill_dash_timer and skill_dash_velocity running,
## so Frey hit out of her Valkyrie dive kept plunging at the dive speed for up to 1.2 s (and Luna's
## and Rio's dashes carried on through the launch). apply_hit already ended the dash.
func _test_launch_hit_ends_skill_dash() -> void:
	var frey := _fighter("frey", 1, Vector2(0, -600))
	var foe := _fighter("rio", 2, Vector2(60, -600))
	await physics_frame
	frey._ultimate_dive()
	if float(frey.skill_dash_timer) <= 0.0:
		_fail("Test setup: Frey's dive should start a skill dash")
		return
	frey.apply_forced_launch_hit(foe, 5.0, Vector2(0, -620), 0.3, 300.0, Vector2(0, -1))
	if float(frey.skill_dash_timer) > 0.0 or frey.skill_dash_velocity.length() > 0.0:
		_fail("A launch hit should end the skill dash (timer %.2f, dash velocity %s)" % [frey.skill_dash_timer, frey.skill_dash_velocity])
	var start_y: float = frey.global_position.y
	for frame in 6:
		await physics_frame
	if frey.global_position.y > start_y:
		_fail("Launched Frey should rise, not keep diving (moved %.0f px down)" % (frey.global_position.y - start_y))
	frey.queue_free()
	foe.queue_free()
	await process_frame
	passed += 1
