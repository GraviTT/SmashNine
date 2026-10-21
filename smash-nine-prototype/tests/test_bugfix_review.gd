extends SceneTree
## Regressions from the whole-code bug review of 2026-10-21 (branch claude/bugfix-review-2026-10-21).
## Each case failed before its fix.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const MAIN_SCENE := "res://scenes/Main.tscn"

var arena: Node2D
var failed := false
var passed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	await _test_launch_hit_ends_skill_dash()
	await _test_card_offer_hides_when_p1_falls()
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

## SoulGrowth drops an open offer when its player is eliminated without emitting offer_closed, so
## P1's card panel ("press 1 / 2 / 3") stayed on screen, frozen, while P1 spectated the rest of the
## match.
func _test_card_offer_hides_when_p1_falls() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.match_seed = 21
	main.realm_hazards = false
	root.add_child(main)
	await process_frame
	main._start_match("frey")
	await process_frame
	var human: Node = main._get_human_player()
	if human == null:
		_fail("Test setup: P1 should be in the match")
		main.queue_free()
		await process_frame
		return
	human.add_souls(human.SOUL_THRESHOLDS[0])
	await process_frame
	await process_frame
	if not main.hud.card_panel.visible:
		_fail("Test setup: P1's soul card offer should show")
	human.apply_environment_damage(human.hp + 100.0)
	for frame in 4:
		await process_frame
	if main.match_over:
		_fail("Test setup: one elimination should not end an 8-fighter match")
	if main.hud.card_panel.visible:
		_fail("P1's card panel should hide once P1 is eliminated (the offer is gone)")
	main.queue_free()
	await process_frame
	passed += 1
