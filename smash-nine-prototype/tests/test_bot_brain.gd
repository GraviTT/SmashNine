extends SceneTree
## Bot brain rules settled in the bot AI debate (reports/debate-bot-ai/, 2026-10-08):
## attacks aim up or down at a steep target; no down attack in the air over the void (D7);
## a guard faces the attacker, also one behind the bot (D2); a target on another level that
## does not get closer is dropped and ignored (D4 lead finding / blind 1); the climb air jump
## keeps the last jump for recovery (D1); a bot-driven Nova launch redirects toward its
## target (D5). Round 3 (Codex QA-14 round 2 data): a target that jumps during a close fight is
## kept, levels are judged by floors; a swing that began during hitstun or is past its wind-up
## raises no guard unless the attacker stays close (round 4); a kiting bot at a ledge jumps past
## instead of backing off, at most every 2.5 s and only with floor beyond the opponent.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	for test in [_test_aim, _test_no_dive_over_void, _test_guard_faces_attacker, _test_drop_unreachable_target, _test_climb_keeps_last_air_jump, _test_nova_redirect, _test_portal_grace, _test_recovery_skill, _test_keep_jumping_target, _test_late_swing_no_guard, _test_cornered_escape, _test_trading_hits, _test_rio_basic_reach, _test_near_target_dropped, _test_yuki_basic_reach, _test_gap_dead_band, _test_routes_follow_movement, _test_round9_targets, _test_fall_path_landing, _test_ultimate_reach_scale]:
		await test.call()
		if failed:
			quit(1)
			return
	print("Bot brain tests passed")
	arena.queue_free()
	await process_frame
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
	return fighter

func _floor(at: Vector2, width: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 40)
	shape.shape = rect
	body.add_child(shape)
	arena.add_child(body)
	body.global_position = at + Vector2(0, 20)
	return body

func _test_aim() -> void:
	var bot := _fighter("frey", 1, Vector2(0, 0))
	var foe := _fighter("yuki", 2, Vector2(40, -160))
	bot.set_physics_process(false)
	foe.set_physics_process(false)
	bot.ai_controller.target = foe
	var aim: Vector2 = bot.ai_controller._attack_aim(bot, "basic")
	if aim.y > -0.45:
		_fail("A target 160 px above should get an upward attack (aim %s)" % aim)
	foe.global_position = Vector2(220, -40)
	aim = bot.ai_controller._attack_aim(bot, "basic")
	if absf(aim.y) > 0.01 or aim.x <= 0.0:
		_fail("A target ahead and only a little higher should get a side attack (aim %s)" % aim)
	bot.queue_free()
	foe.queue_free()
	await process_frame

func _test_no_dive_over_void() -> void:
	var bot := _fighter("nova", 1, Vector2(0, -600))
	var foe := _fighter("rio", 2, Vector2(30, -300))
	bot.set_physics_process(false)
	foe.set_physics_process(false)
	bot.ai_controller.target = foe
	await physics_frame
	var aim: Vector2 = bot.ai_controller._attack_aim(bot, "basic")
	if aim.y > 0.1:
		_fail("No down attack in the air over the void (aim %s)" % aim)
	bot.queue_free()
	foe.queue_free()
	await process_frame

func _test_guard_faces_attacker() -> void:
	var ground := _floor(Vector2(0, 0), 900)
	var bot := _fighter("frey", 1, Vector2(0, -2))
	var foe := _fighter("rio", 2, Vector2(-120, -2))
	foe.set_physics_process(false)
	bot.facing = 1
	for frame in 20:
		await physics_frame
	bot.set_physics_process(false)
	if not bot.is_on_floor():
		_fail("Test setup: the bot should stand on the floor")
	elif not bot.ai_controller._start_guard_against(bot, foe):
		_fail("The bot should be able to raise its guard")
	elif bot.guard_direction.x >= 0.0:
		_fail("A guard against an attacker behind should face it (guard %s)" % bot.guard_direction)
	bot._stop_guard(false)
	bot.guard_recovery_timer = 0.0
	# Debate N1: an attacker straight above is guarded upward.
	foe.global_position = bot.global_position + Vector2(6, -150)
	if not bot.ai_controller._start_guard_against(bot, foe) or bot.guard_direction.y >= 0.0:
		_fail("A guard against an attacker above should face up (guard %s)" % bot.guard_direction)
	bot._stop_guard(false)
	bot.guard_recovery_timer = 0.0
	# Debate N2: while the bot guards, its old move input stops.
	bot.move_input = 1.0
	bot.ai_controller.guard_hold_timer = 0.3
	bot.ai_controller._start_guard_against(bot, foe)
	bot.ai_controller.update(bot, 0.016)
	if not is_zero_approx(bot.move_input):
		_fail("A guarding bot should stop its move input (move %.2f)" % bot.move_input)
	bot._stop_guard(false)
	bot.queue_free()
	foe.queue_free()
	ground.queue_free()
	await process_frame

func _test_drop_unreachable_target() -> void:
	var upper := _floor(Vector2(0, 0), 300)
	var lower := _floor(Vector2(60, 260), 300)
	var bot := _fighter("luna", 1, Vector2(0, -2))
	var monster_like := _fighter("yuki", 2, Vector2(60, 258))
	bot.set_physics_process(false)
	monster_like.set_physics_process(false)
	await physics_frame
	var ai = bot.ai_controller
	ai.state = ai.STATE_ENGAGE
	ai.target = monster_like
	for step in 40:
		ai._update_target_progress(bot, 0.1)
	if ai.target != null or float(ai.ignored_targets.get(monster_like, 0.0)) <= 0.0:
		_fail("A target on another level that never gets closer should be dropped and ignored")
	bot.queue_free()
	monster_like.queue_free()
	upper.queue_free()
	lower.queue_free()
	await process_frame

func _test_climb_keeps_last_air_jump() -> void:
	var ground := _floor(Vector2(0, 0), 900)
	var bot := _fighter("frey", 1, Vector2(0, -200))
	bot.set_physics_process(false)
	await physics_frame
	var ai = bot.ai_controller
	bot.velocity = Vector2(0, 10)
	bot.air_jumps_left = 1
	ai.jump_retry_timer = 0.0
	var intent: Dictionary = ai._terrain_move_intent(bot, 1.0, true, true)
	if bool(intent.get("jump", false)):
		_fail("The last air jump is kept for recovery, not spent climbing")
	bot.air_jumps_left = 2
	ai.jump_retry_timer = 0.0
	intent = ai._terrain_move_intent(bot, 1.0, true, true)
	if not bool(intent.get("jump", false)):
		_fail("With an air jump to spare over solid ground the bot should climb")
	bot.queue_free()
	ground.queue_free()
	await process_frame

func _test_nova_redirect() -> void:
	var nova := _fighter("nova", 1, Vector2(0, 0))
	var foe := _fighter("frey", 2, Vector2(400, 0))
	nova.set_physics_process(false)
	foe.set_physics_process(false)
	var ai = nova.ai_controller
	ai.target = foe
	var redirected := false
	for attempt in 12:
		nova.ultimate_phase = nova.ULTIMATE_LAUNCH
		nova.ultimate_launch_direction = Vector2.LEFT
		nova.ultimate_launch_shift_available = true
		ai.nova_redirect_timer = 0.001
		ai._drive_nova_slingshot(nova, 0.01)
		if nova.ultimate_launch_direction.x > 0.5:
			redirected = true
			break
	nova.ultimate_phase = nova.ULTIMATE_NONE
	if not redirected:
		_fail("A bot-driven Nova launch flying away should redirect toward its target")
	nova.queue_free()
	foe.queue_free()
	await process_frame

## Codex QA-14: 94 portal moves per match. A move resets the bot (reset()), which now starts a
## stay, and off-screen hops wait for it (collapse warnings still escape at once).
func _test_portal_grace() -> void:
	var bot := _fighter("rio", 1, Vector2(0, 0))
	bot.set_physics_process(false)
	var ai = bot.ai_controller
	ai.reset(bot.global_position)
	if ai.portal_cooldown < ai.PORTAL_COOLDOWN - 0.01:
		_fail("Arriving through a portal should start a stay (cooldown %.1f)" % ai.portal_cooldown)
	var portals: Array[Dictionary] = [{"rect": Rect2(100, -40, 60, 60), "destination": 1, "destination_state": "stable"}]
	var hops := 0
	for think in 20:
		ai.offscreen_timer = 0.0
		var portal: Dictionary = ai.update_offscreen_realm(bot, 0.25, [] as Array[Node], portals, "stable", func(_i: int) -> String: return "stable", func(_a: int, _b: int) -> int: return 1)
		if not portal.is_empty():
			hops += 1
	if hops > 0:
		_fail("An off-screen bot should not hop again during its stay (%d hops)" % hops)
	ai.offscreen_timer = 0.0
	var escape: Dictionary = ai.update_offscreen_realm(bot, 0.25, [] as Array[Node], portals, "warning", func(_i: int) -> String: return "stable", func(_a: int, _b: int) -> int: return 1)
	if escape.is_empty():
		_fail("A collapse warning should still send the bot through a portal")
	bot.queue_free()
	await process_frame

## Out of air jumps below the stage, Frey and Nova use their directional skill toward the
## platform like Rio (Codex QA-14: 78% of ring-outs had no air jump left). Round 4 (QA-14
## round 3: Rio reached a floor 2 of 10 times): Rio waits until the ledge is within the skill's
## reach and aims a little above it; Frey (18 of 19) and Nova (round 4: the limit did not help)
## go from anywhere. Round 6: asked only while free to act (round 4: 2,200 asks for 21 uses),
## and again after each use (round 5: once per recovery cut Frey from 18/19 to 6/13), at most
## twice per recovery and only while the skill can start in the air (round 7).
func _test_recovery_skill() -> void:
	for id in ["frey", "nova", "rio"]:
		var bot := _fighter(id, 1, Vector2(0, 300))
		bot.set_physics_process(false)
		bot.realm_origin = Vector2(-960, -540)
		bot.realm_size = Vector2(1920, 1080)
		var ai = bot.ai_controller
		ai.state = ai.STATE_RECOVER
		ai.recovery_target = Vector2(120, 160)
		bot.velocity = Vector2(0, 120)
		bot.air_jumps_left = 0
		var intent: Dictionary = ai._recover_intent(bot)
		var aim: Vector2 = intent.get("aim", Vector2.ZERO)
		if str(intent.get("attack", "")) != "skill_1" or aim.y >= 0.0 or aim.x <= 0.0:
			_fail("%s out of jumps below a close ledge should aim its skill up toward it (%s)" % [id, intent])
		bot.attack_lock_timer = 0.3
		if str(ai._recover_intent(bot).get("attack", "")) == "skill_1":
			_fail("%s should not ask for its recovery skill while it is still busy" % id)
		bot.attack_lock_timer = 0.0
		if str(ai._recover_intent(bot).get("attack", "")) != "skill_1":
			_fail("%s should ask again once it is free to act" % id)
		# Round 7: at most two uses per recovery (round 6: Frey dashed 437 times).
		if str(ai._recover_intent(bot).get("attack", "")) == "skill_1":
			_fail("%s should stop after two recovery-skill uses in one recovery" % id)
		ai.recovery_skill_uses = 0
		if id == "rio":
			# One blink per airtime: after it, Rio does not keep asking in the air.
			bot.air_blink_available = false
			if str(ai._recover_intent(bot).get("attack", "")) == "skill_1":
				_fail("Rio should not ask for a second blink in the same airtime")
			bot.air_blink_available = true
		if id == "nova":
			# One vector shift per airtime (round 6: 35,321 asking frames for 27 uses).
			bot.air_vector_shift_available = false
			if str(ai._recover_intent(bot).get("attack", "")) == "skill_1":
				_fail("Nova should not ask for a second vector shift in the same airtime")
			bot.air_vector_shift_available = true
		ai.recovery_target = Vector2(600, -100)
		intent = ai._recover_intent(bot)
		var far_skill: bool = str(intent.get("attack", "")) == "skill_1"
		if far_skill != (id != "rio"):
			_fail("%s with the ledge out of reach: skill %s (Frey and Nova use it from afar, Rio waits)" % [id, far_skill])
		bot.queue_free()
		await process_frame

## Round 3: a target jumping above our own floor in a close fight is not "another level" (the
## old check read its height, so bots dropped close fights whenever the target jumped).
func _test_keep_jumping_target() -> void:
	var ground := _floor(Vector2(0, 0), 900)
	var bot := _fighter("frey", 1, Vector2(0, -2))
	var foe := _fighter("rio", 2, Vector2(90, -240))
	bot.set_physics_process(false)
	foe.set_physics_process(false)
	await physics_frame
	var ai = bot.ai_controller
	ai.state = ai.STATE_ENGAGE
	ai.target = foe
	for step in 40:
		ai._update_target_progress(bot, 0.1)
	if ai.target != foe:
		_fail("A target jumping above the same floor should be kept, not dropped as unreachable")
	if ai._find_target(bot) != foe:
		_fail("A jumping target above the same floor should still be chosen as the target")
	bot.queue_free()
	foe.queue_free()
	ground.queue_free()
	await process_frame

## Round 3 (debate D3): a swing that started while the bot was in hitstun is not taken for a new
## one afterwards, and a reaction that comes after the wind-up has passed raises no guard.
func _test_late_swing_no_guard() -> void:
	var ground := _floor(Vector2(0, 0), 900)
	var bot := _fighter("frey", 1, Vector2(0, -2))
	var foe := _fighter("rio", 2, Vector2(120, -2))
	foe.set_physics_process(false)
	foe.facing = -1
	for frame in 20:
		await physics_frame
	bot.set_physics_process(false)
	var ai = bot.ai_controller
	ai.update(bot, 0.016)
	# The swing starts while the bot is stunned; the bot still watches it.
	bot.hitstun_timer = 0.3
	foe.attack_lock_timer = 0.3
	foe.attack_serial += 1
	foe.attack_elapsed = 0.0
	foe.attack_startup = 0.08
	ai.update(bot, 0.016)
	bot.hitstun_timer = 0.0
	ai.update(bot, 0.016)
	if ai.pending_threat != null:
		_fail("A swing that began during hitstun should not count as a new swing afterwards")
	# A reaction that ends after the wind-up and the grace raises no guard.
	if bot.is_guarding:
		bot._stop_guard(false)
	bot.guard_recovery_timer = 0.0
	# Past the wind-up with the attacker turned away: no guard.
	foe.attack_elapsed = 0.08 + ai.GUARD_LATE_GRACE + 0.05
	foe.facing = 1
	ai.guard_threat_from = foe
	ai.guard_delay_timer = 0.0
	if ai._update_guard(bot, 0.016) or bot.is_guarding:
		_fail("No guard once the swing is past its wind-up and the attacker turned away")
	# Round 4: past the wind-up but still close and facing us, the guard braces for the next
	# swing (QA-14 round 3: skipping these cut blocks and parries from 463 to 155).
	foe.facing = -1
	ai.guard_delay_timer = 0.0
	if not ai._update_guard(bot, 0.016) or not bot.is_guarding:
		_fail("A close attacker facing us should still get a guard for its follow-up")
	bot._stop_guard(false)
	bot.guard_recovery_timer = 0.0
	# In time, it guards.
	foe.attack_elapsed = 0.02
	ai.guard_delay_timer = 0.0
	if not ai._update_guard(bot, 0.016) or not bot.is_guarding:
		_fail("A reaction during the wind-up should raise the guard")
	bot._stop_guard(false)
	bot.queue_free()
	foe.queue_free()
	ground.queue_free()
	await process_frame

## Round 3: Yuki kites; at a ledge it jumps past the opponent instead of backing off the edge
## (Codex QA-14 round 2: 44 of 135 ring-outs were Yuki's).
func _test_cornered_escape() -> void:
	# Distances come from the scales and Yuki's profile, so the same situations are tested at any
	# GameScale (the first version assumed COMBAT 2.0).
	var ground := _floor(Vector2(0, 0), 300)
	var bot := _fighter("yuki", 1, Vector2(-130, -2))
	var foe := _fighter("frey", 2, Vector2(-70, -2))
	foe.set_physics_process(false)
	for frame in 20:
		await physics_frame
	bot.set_physics_process(false)
	if not bot.is_on_floor():
		_fail("Test setup: the bot should stand near the left ledge")
	var ai = bot.ai_controller
	ai.target = foe
	var min_range: float = float(ai._combat_profile(bot).min_range)
	var close := 60.0
	# Kiting range, but landing 90 px past the opponent would be off the 300 px platform.
	var no_landing: float = 150.0 + 130.0 - float(ai.ESCAPE_LANDING_PAST) + 30.0
	# On another level, but still inside the engage height.
	var lower: float = (ai.NAV_SAME_LEVEL + 120.0 * ai.GAME_SCALE.COMBAT) * 0.5
	if no_landing >= min_range or lower <= ai.NAV_SAME_LEVEL:
		_fail("Test setup: distances out of range (no_landing %.0f, min_range %.0f, lower %.0f)" % [no_landing, min_range, lower])
	ai._choose_engage_action(bot, close, 0.0, 1.0)
	if ai.action != "escape":
		_fail("A kiting bot with a ledge behind it should jump past, not retreat (action %s)" % ai.action)
	# Cornered by an opponent on a lower level, it holds the ledge instead of walking toward it.
	ai.last_action = ""
	ai._choose_engage_action(bot, close, lower, 1.0)
	if ai.action != "hold":
		_fail("Cornered by an opponent on another level, a kiting bot should hold (action %s)" % ai.action)
	# Round 4: one escape per 2.5 s, then it holds; and none without floor past the opponent.
	ai.last_action = ""
	ai._choose_engage_action(bot, close, 0.0, 1.0)
	if ai.action != "hold":
		_fail("Right after an escape a cornered bot should hold (action %s)" % ai.action)
	ai.escape_cooldown = 0.0
	ai.last_action = ""
	ai._choose_engage_action(bot, no_landing, 0.0, 1.0)
	if ai.action != "hold":
		_fail("With no floor past the opponent a cornered bot should hold (action %s)" % ai.action)
	# With open floor behind, it keeps its range as before.
	bot.global_position = Vector2(140, -2)
	foe.global_position = Vector2(200, -2)
	await physics_frame
	ai.last_action = ""
	var retreats := 0
	for roll in 12:
		ai._choose_engage_action(bot, close, 0.0, 1.0)
		retreats += 1 if ai.action == "retreat" else 0
		ai.last_action = ""
	if retreats == 0:
		_fail("With floor behind, a kiting bot should still retreat to keep its range")
	bot.queue_free()
	foe.queue_free()
	ground.queue_free()
	await process_frame

## Round 4: hitting the target in the last 3 s counts as progress for every target kind
## (fighters by their attacker memory, crystals and monsters by the frame of the last hit).
func _test_trading_hits() -> void:
	var bot := _fighter("frey", 1, Vector2(0, 0))
	var foe := _fighter("rio", 2, Vector2(200, 260))
	bot.set_physics_process(false)
	foe.set_physics_process(false)
	var ai = bot.ai_controller
	foe.last_attacker = bot
	foe.last_attacker_timer = 7.0
	if not ai._trading_hits(bot, foe):
		_fail("A fighter we hit a second ago should count as trading hits")
	foe.last_attacker_timer = 3.0
	if ai._trading_hits(bot, foe):
		_fail("A fighter we hit five seconds ago should not count as trading hits")
	var crystal: Node = load("res://scripts/SoulCrystal.gd").new()
	arena.add_child(crystal)
	crystal.last_attacker = bot
	crystal.last_hit_frame = Engine.get_physics_frames()
	if not ai._trading_hits(bot, crystal):
		_fail("A crystal we just hit should count as trading hits")
	crystal.last_hit_frame = Engine.get_physics_frames() - 600
	if ai._trading_hits(bot, crystal):
		_fail("A crystal hit ten seconds ago should not count as trading hits")
	crystal.queue_free()
	bot.queue_free()
	foe.queue_free()
	await process_frame

## Round 4: Rio does not throw basics from beyond their reach (QA-14 round 3: 89-92% missed
## from 240 px out).
func _test_rio_basic_reach() -> void:
	var bot := _fighter("rio", 1, Vector2(0, 0))
	var foe := _fighter("frey", 2, Vector2(300, 0))
	bot.set_physics_process(false)
	foe.set_physics_process(false)
	var ai = bot.ai_controller
	ai.target = foe
	bot.ultimate_cooldown_timer = 30.0
	var far_basics := 0
	var near_basics := 0
	for roll in 40:
		ai.attack_cooldown = 0.0
		far_basics += 1 if ai._choose_attack(bot, 300.0, 0.0) == "basic" else 0
		ai.attack_cooldown = 0.0
		near_basics += 1 if ai._choose_attack(bot, 100.0, 0.0) == "basic" else 0
	if far_basics > 0 or near_basics == 0:
		_fail("Rio basics: %d from 300 px (want 0), %d from 100 px (want some)" % [far_basics, near_basics])
	bot.queue_free()
	foe.queue_free()
	await process_frame

## Round 6: a close target on another level that never gets closer is dropped after 2.5 s even
## when a route exists (rounds 4-5: keeping or extending such targets raised no-progress time
## 647 -> 1,104 -> 1,239 s). Hits on it still count as progress (round 4).
func _test_near_target_dropped() -> void:
	var nav_script := GDScript.new()
	nav_script.source_code = "extends Node2D
var points: Array[Vector2] = []
func get_ai_navigation_points_for_realm(_realm: int) -> Array[Vector2]:
	return points
"
	nav_script.reload()
	var holder := Node2D.new()
	holder.set_script(nav_script)
	arena.add_child(holder)
	holder.points = [Vector2(0, -2), Vector2(80, -132), Vector2(160, -262)] as Array[Vector2]
	var lower := _floor(Vector2(0, 0), 300)
	var upper := _floor(Vector2(160, -260), 200)
	var bot: Node = PLAYER_FACTORY.create("frey")
	holder.add_child(bot)
	bot.global_position = Vector2(0, -2)
	bot.setup(CHARACTER_REGISTRY.get_characters()["frey"], 1, false)
	var foe: Node = PLAYER_FACTORY.create("rio")
	holder.add_child(foe)
	foe.global_position = Vector2(160, -262)
	foe.setup(CHARACTER_REGISTRY.get_characters()["rio"], 2, false)
	bot.set_physics_process(false)
	foe.set_physics_process(false)
	await physics_frame
	var ai = bot.ai_controller
	ai.state = ai.STATE_ENGAGE
	ai.target = foe
	ai._update_target_progress(bot, 0.1)
	for step in 30:
		ai._update_target_progress(bot, 0.1)
	if ai.target != null:
		_fail("A close target on another level that never gets closer should be dropped after 2.5 s")
	holder.queue_free()
	lower.queue_free()
	upper.queue_free()
	await process_frame

## Round 6: Yuki does not throw talismans from beyond 480 px (round 5: 503 of 718 missed from
## 360 px out).
func _test_yuki_basic_reach() -> void:
	var bot := _fighter("yuki", 1, Vector2(0, 0))
	var foe := _fighter("frey", 2, Vector2(600, 0))
	bot.set_physics_process(false)
	foe.set_physics_process(false)
	var ai = bot.ai_controller
	ai.target = foe
	bot.ultimate_cooldown_timer = 30.0
	var far_basics := 0
	var near_basics := 0
	for roll in 40:
		ai.attack_cooldown = 0.0
		far_basics += 1 if ai._choose_attack(bot, 600.0, 0.0) == "basic" else 0
		ai.attack_cooldown = 0.0
		near_basics += 1 if ai._choose_attack(bot, 300.0, 0.0) == "basic" else 0
	if far_basics > 0 or near_basics == 0:
		_fail("Yuki basics: %d from 600 px (want 0), %d from 300 px (want some)" % [far_basics, near_basics])
	bot.queue_free()
	foe.queue_free()
	await process_frame

## Round 8 (Codex QA-14 round 7, seed 112): two bots on the same level across a gap they cannot
## cross, just out of reach, must not stay "engaged" forever: a way blocked toward the target is
## not progress (the bot really tries to walk across here; the round-7 brain kept the target).
func _test_gap_dead_band() -> void:
	var left := _floor(Vector2(-300, 0), 400)
	var right := _floor(Vector2(501, 0), 400)
	var bot := _fighter("frey", 1, Vector2(-300, -2))
	var foe := _fighter("frey", 2, Vector2(291, -2))
	bot.is_dummy = true
	foe.is_dummy = true
	for frame in 20:
		await physics_frame
	bot.set_physics_process(false)
	foe.set_physics_process(false)
	bot.global_position = Vector2(-110, -2)
	bot.is_dummy = false
	if not bot.is_on_floor():
		_fail("Test setup: the bot should stand at the edge of its platform")
	var ai = bot.ai_controller
	ai.state = ai.STATE_ENGAGE
	ai.target = foe
	ai._update_target_progress(bot, 0.1)
	# Walking away from the gap is open: same level stays progress.
	for step in 30:
		ai._terrain_move_intent(bot, -1.0, false, true)
		ai._update_target_progress(bot, 0.1)
	if ai.target != foe:
		_fail("A target on our level with an open way should be kept")
	# Walking toward it hits the gap with no landing: dropped after 2.5 s.
	for step in 40:
		ai._terrain_move_intent(bot, 1.0, false, true)
		ai._update_target_progress(bot, 0.1)
	if ai.target != null:
		_fail("A target across a gap the bot cannot cross should be dropped, not engaged forever")
	bot.queue_free()
	foe.queue_free()
	left.queue_free()
	right.queue_free()
	await process_frame

## Round 9 (Codex QA-14 round 8: 86 of 88 dropped close targets had routes the movement could
## not follow): between platforms a route only crosses gaps the gap jump can, and a jump up to a
## waypoint starts near the platform it stands on.
func _test_routes_follow_movement() -> void:
	var nav_script := GDScript.new()
	nav_script.source_code = "extends Node2D
var points: Array[Vector2] = []
var rects: Array[Rect2] = []
func get_ai_navigation_points_for_realm(_realm: int) -> Array[Vector2]:
	return points
func get_ai_platform_rects_for_realm(_realm: int) -> Array[Rect2]:
	return rects
"
	nav_script.reload()
	var holder := Node2D.new()
	holder.set_script(nav_script)
	arena.add_child(holder)
	var bot: Node = PLAYER_FACTORY.create("frey")
	holder.add_child(bot)
	bot.setup(CHARACTER_REGISTRY.get_characters()["frey"], 1, false)
	bot.set_physics_process(false)
	var ai = bot.ai_controller
	# Same value as NAV_GAP_JUMP, from constants the older brains have too.
	var gap_jump: float = float(ai.LONG_LANDING_DISTANCE) - float(ai.LANDING_PATCH_HALF_WIDTH) - float(ai.FLOOR_PROBE_AHEAD)
	# Two platforms on one level, a gap too wide for the gap jump: no route across.
	for gap in [gap_jump + 60.0, gap_jump - 30.0]:
		var left := Rect2(-400, 0, 300, 40)
		var right := Rect2(-100 + gap, 0, 300, 40)
		holder.rects = [left, right] as Array[Rect2]
		holder.points = [Vector2(-250, 0), Vector2(-130, 0), right.position + Vector2(30, 0), right.position + Vector2(150, 0)] as Array[Vector2]
		bot.global_position = Vector2(-250, 0)
		var route: Array[Vector2] = ai._plan_navigation_path(bot, right.position + Vector2(150, 0))
		var crosses: bool = not route.is_empty() and route[route.size() - 1].x > right.position.x
		if crosses != (gap <= gap_jump):
			_fail("A route across a %.0f px gap should %s (gap jump %.0f)" % [gap, "exist" if gap <= gap_jump else "not exist", gap_jump])
	# A waypoint on a platform above: no jump while far from that platform, a jump when near.
	var ground := _floor(Vector2(0, 0), 1600)
	holder.rects = [Rect2(-800, 0, 1600, 40), Rect2(400, -150, 300, 30)] as Array[Rect2]
	bot.set_physics_process(true)
	bot.is_dummy = true
	bot.global_position = Vector2(0, -2)
	for frame in 20:
		await physics_frame
	bot.set_physics_process(false)
	bot.is_dummy = false
	ai.jump_retry_timer = 0.0
	var far: Dictionary = ai._navigate_to_intent(bot, Vector2(550, -150))
	if bool(far.get("jump", false)):
		_fail("A jump up should not start 400 px away from the platform above")
	bot.global_position = Vector2(330, -2)
	ai.jump_retry_timer = 0.0
	var near: Dictionary = ai._navigate_to_intent(bot, Vector2(550, -150))
	if not bool(near.get("jump", false)):
		_fail("Close under the platform above, the bot should jump up to it")
	holder.queue_free()
	ground.queue_free()
	await process_frame

## Round 9-10: a blocked way does not drop a target the bot keeps attacking (a ranged fighter
## fights across a gap) but does drop one it only stands facing (round 9: Yuki held a monster
## 607 px away for 5 s); a monster that is only after us is not progress; nobody kites from a
## crystal.
func _test_round9_targets() -> void:
	var left := _floor(Vector2(-300, 0), 400)
	var right := _floor(Vector2(501, 0), 400)
	var bot := _fighter("yuki", 1, Vector2(-300, -2))
	var foe := _fighter("frey", 2, Vector2(291, -2))
	bot.is_dummy = true
	foe.is_dummy = true
	for frame in 20:
		await physics_frame
	bot.set_physics_process(false)
	foe.set_physics_process(false)
	bot.global_position = Vector2(-110, -2)
	bot.is_dummy = false
	var ai = bot.ai_controller
	ai.state = ai.STATE_ENGAGE
	ai.target = foe
	ai._update_target_progress(bot, 0.1)
	for step in 40:
		ai._terrain_move_intent(bot, 1.0, false, true)
		ai.attack_age = 0.0
		ai._update_target_progress(bot, 0.1)
	if ai.target != foe:
		_fail("A target across a gap that the bot keeps attacking should be kept")
	# 2.5 s until it no longer counts as attacking, then 2.5 s without progress.
	for step in 60:
		ai._terrain_move_intent(bot, 1.0, false, true)
		ai.attack_age += 0.1
		ai._update_target_progress(bot, 0.1)
	if ai.target != null:
		_fail("A target across a gap that the bot only stands facing should be dropped")
	# A monster after us that we never hit is not progress.
	var monster_script := GDScript.new()
	monster_script.source_code = "extends Node2D
var target: Node
var last_attacker: Node
"
	monster_script.reload()
	var monster := Node2D.new()
	monster.set_script(monster_script)
	monster.add_to_group("realm_monsters")
	arena.add_child(monster)
	monster.target = bot
	if ai._trading_hits(bot, monster):
		_fail("A monster that is only after us should not count as trading hits")
	monster.queue_free()
	# A crystal close by is hit, not kited from.
	var crystal: Node = load("res://scripts/SoulCrystal.gd").new()
	arena.add_child(crystal)
	crystal.global_position = bot.global_position + Vector2(40, 0)
	ai.target = crystal
	var retreats := 0
	for roll in 12:
		ai.last_action = ""
		ai._choose_engage_action(bot, 40.0, 0.0, 1.0)
		retreats += 1 if ai.action == "retreat" else 0
	if retreats > 0:
		_fail("Yuki should not back away from a crystal (%d retreats)" % retreats)
	crystal.queue_free()
	bot.queue_free()
	foe.queue_free()
	left.queue_free()
	right.queue_free()
	await process_frame

## Round 10-11 (Codex QA-14 round 9: 77% of recovery entries were bots dropping to a lower
## platform that was not straight below): a fall whose arc meets a floor is not a recovery; one
## that passes under a floor is.
func _test_fall_path_landing() -> void:
	var lower := _floor(Vector2(300, 0), 300)
	var bot := _fighter("nova", 1, Vector2(0, -300))
	bot.set_physics_process(false)
	await physics_frame
	var ai = bot.ai_controller
	bot.realm_origin = Vector2(-960, -540)
	bot.realm_size = Vector2(1920, 1080)
	bot.velocity = Vector2(420, 200)
	if ai._needs_recovery(bot):
		_fail("Falling toward a lower platform ahead should not start a recovery")
	bot.velocity = Vector2(-420, 200)
	if not ai._needs_recovery(bot):
		_fail("Falling away from every floor should start a recovery")
	# Round 11: a floor ahead and below that the arc passes under is no landing (round 10 counted
	# it: 162 of 332 such falls became late recoveries).
	# Floor x 320-620 at the start height + 300: straight down from 0.8 s ahead (x 336) hits it, the
	# arc reaches that height at x ~171 and passes under it.
	lower.global_position = Vector2(470, 20)
	await physics_frame
	bot.velocity = Vector2(420, 200)
	if not ai._needs_recovery(bot):
		_fail("A floor the fall passes under should not hold off the recovery")
	bot.queue_free()
	lower.queue_free()
	await process_frame

## 2026-10-09: the ultimate's "target in reach" follows the attack scale (it stayed at the x2
## values when attacks went to x1.5, so bots fired from a third farther than the areas reach).
func _test_ultimate_reach_scale() -> void:
	var bases := {"frey": 240.0, "yuki": 410.0, "luna": 210.0, "nova": 230.0, "rio": 450.0}
	for character_id: String in bases:
		var bot := _fighter(character_id, 1, Vector2(0, 0))
		var foe := _fighter("frey", 2, Vector2(0, 0))
		bot.set_physics_process(false)
		foe.set_physics_process(false)
		var ai = bot.ai_controller
		ai.target = foe
		var reach: float = float(bases[character_id]) * float(ai.GAME_SCALE.COMBAT)
		foe.global_position = Vector2(reach - 10.0, 0)
		var inside: int = ai._ultimate_score(bot)
		foe.global_position = Vector2(reach + 10.0, 0)
		var outside: int = ai._ultimate_score(bot)
		if inside - outside != 2:
			_fail("%s: a target just inside its ultimate's reach (%.0f px) should score 2 more than one just outside (%d vs %d)" % [character_id, reach, inside, outside])
		bot.queue_free()
		foe.queue_free()
		await process_frame
