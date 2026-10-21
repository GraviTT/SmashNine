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
	await _test_startup_wait_in_physics_ticks()
	await _test_results_hide_hp_bar()
	await _test_ringout_respawn_clears_attack_lock()
	await _test_stale_attacker_gets_no_ko()
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

## Attack start-ups (_wait_action) ran on an idle-frame SceneTreeTimer while hitstun, the attack
## lock and movement count physics ticks. At a low frame rate the wait came out several ticks long
## or short, so moves fired off their timing and Luna's echo blooms missed (test_luna_kit failed at
## --max-fps 20). The wait must last its seconds in physics ticks whatever the frame rate.
func _test_startup_wait_in_physics_ticks() -> void:
	var frey := _fighter("frey", 1, Vector2(0, -600))
	frey.set_physics_process(false)
	await physics_frame
	var expected := roundi(0.5 * Engine.physics_ticks_per_second)
	var worst := 0
	# Measured before the fix (headless): 29-32 ticks at 20 fps, 30-36 at 7 fps.
	for fps in [20, 7]:
		Engine.max_fps = fps
		await process_frame
		for trial in 6:
			await physics_frame
			var start := Engine.get_physics_frames()
			await frey._wait_action(0.5)
			worst = maxi(worst, absi(int(Engine.get_physics_frames() - start) - expected))
	Engine.max_fps = 0
	if worst > 1:
		_fail("A 0.5 s start-up wait should last %d physics ticks at any frame rate (off by %d)" % [expected, worst])
	frey.queue_free()
	await process_frame
	passed += 1

## The result screen hides the match HUD, but Main keeps calling set_status every frame and it set
## the HP bar visible again behind the results table.
func _test_results_hide_hp_bar() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.match_seed = 22
	main.realm_hazards = false
	root.add_child(main)
	await process_frame
	main._start_match("luna")
	for frame in 3:
		await process_frame
	if not main.hud.hp_bar.visible:
		_fail("Test setup: the HP bar should show during the match")
	main.director._finish(main.players[0], "test")
	for frame in 4:
		await process_frame
	if main.hud.hp_bar.visible:
		_fail("The HP bar should stay hidden behind the result screen")
	main.queue_free()
	await process_frame
	passed += 1

## A ring-out respawn kept the attack lock and hitstun of whatever was going on when the fighter fell:
## Frey diving off the stage with her air ultimate came back unable to jump or attack for the rest of
## its 1.45 s lock (reset_for_map, the portal and collapse move, already cleared them).
func _test_ringout_respawn_clears_attack_lock() -> void:
	var frey := _fighter("frey", 1, Vector2(0, -600))
	frey.spawn_points = [Vector2(0, -600)] as Array[Vector2]
	await physics_frame
	frey._ultimate_start()
	if float(frey.attack_lock_timer) < 1.0:
		_fail("Test setup: Frey's air ultimate should lock her attacks")
	frey.hitstun_timer = 0.2
	frey._ringout()
	if frey.is_defeated:
		_fail("Test setup: one ring-out should not defeat a full-HP fighter")
	if not frey._can_start_attack():
		_fail("A fighter respawned after a ring-out should be free to act (attack lock %.2f, hitstun %.2f)" % [frey.attack_lock_timer, frey.hitstun_timer])
	frey.queue_free()
	await process_frame
	passed += 1

## A hit with no attacker (realm hazards: eruptions, beams, quakes) that knocked a fighter out gave the
## KO to last_attacker however long ago that hit was. Ring-outs already gave it only within
## LAST_ATTACKER_MEMORY; hit KOs now follow the same window.
func _test_stale_attacker_gets_no_ko() -> void:
	var victim := _fighter("luna", 1, Vector2(0, -600))
	var old_foe := _fighter("rio", 2, Vector2(400, -600))
	victim.set_physics_process(false)
	old_foe.set_physics_process(false)
	await physics_frame
	victim.apply_hit(old_foe, 2.0, 100.0, Vector2.RIGHT)
	victim.last_attacker_timer = 0.0
	victim.invulnerable_timer = 0.0
	victim.hp = 3.0
	victim.apply_hit(null, 20.0, 300.0, Vector2.UP, victim.DAMAGE_FIXED)
	if not victim.is_defeated:
		_fail("Test setup: the hazard hit should knock the fighter out")
	if int(old_foe.score) != 0:
		_fail("A hit from long ago (outside LAST_ATTACKER_MEMORY) should not earn the KO (score %d)" % old_foe.score)
	victim.queue_free()
	old_foe.queue_free()
	await process_frame
	passed += 1
