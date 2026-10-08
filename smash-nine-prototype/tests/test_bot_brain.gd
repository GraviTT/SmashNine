extends SceneTree
## Bot brain rules settled in the bot AI debate (reports/debate-bot-ai/, 2026-10-08):
## attacks aim up or down at a steep target; no down attack in the air over the void (D7);
## a guard faces the attacker, also one behind the bot (D2); a target on another level that
## does not get closer is dropped and ignored (D4 lead finding / blind 1); the climb air jump
## keeps the last jump for recovery (D1); a bot-driven Nova launch redirects toward its
## target (D5). Round 3 (Codex QA-14 round 2 data): a target that jumps during a close fight is
## kept, levels are judged by floors; a swing that began during hitstun or is past its wind-up
## raises no guard; a kiting bot at a ledge jumps past instead of backing off.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	for test in [_test_aim, _test_no_dive_over_void, _test_guard_faces_attacker, _test_drop_unreachable_target, _test_climb_keeps_last_air_jump, _test_nova_redirect, _test_portal_grace, _test_recovery_skill, _test_keep_jumping_target, _test_late_swing_no_guard, _test_cornered_escape]:
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
## platform like Rio (Codex QA-14: 78% of ring-outs had no air jump left).
func _test_recovery_skill() -> void:
	for id in ["frey", "nova", "rio"]:
		var bot := _fighter(id, 1, Vector2(0, 300))
		bot.set_physics_process(false)
		var ai = bot.ai_controller
		ai.state = ai.STATE_RECOVER
		ai.recovery_target = Vector2(260, 0)
		bot.velocity = Vector2(0, 120)
		bot.air_jumps_left = 0
		var intent: Dictionary = ai._recover_intent(bot)
		var aim: Vector2 = intent.get("aim", Vector2.ZERO)
		if str(intent.get("attack", "")) != "skill_1" or aim.y >= 0.0 or aim.x <= 0.0:
			_fail("%s out of jumps below the stage should aim its skill up toward the platform (%s)" % [id, intent])
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
	foe.attack_elapsed = 0.08 + ai.GUARD_LATE_GRACE + 0.05
	ai.guard_threat_from = foe
	ai.guard_delay_timer = 0.0
	if ai._update_guard(bot, 0.016) or bot.is_guarding:
		_fail("No guard once the swing is past its wind-up")
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
	var ground := _floor(Vector2(0, 0), 400)
	var bot := _fighter("yuki", 1, Vector2(-180, -2))
	var foe := _fighter("frey", 2, Vector2(-120, -2))
	foe.set_physics_process(false)
	for frame in 20:
		await physics_frame
	bot.set_physics_process(false)
	if not bot.is_on_floor():
		_fail("Test setup: the bot should stand near the left ledge")
	var ai = bot.ai_controller
	ai.target = foe
	ai._choose_engage_action(bot, 60.0, 0.0, 1.0)
	if ai.action != "escape":
		_fail("A kiting bot with a ledge behind it should jump past, not retreat (action %s)" % ai.action)
	# With open floor behind, it keeps its range as before.
	bot.global_position = Vector2(60, -2)
	foe.global_position = Vector2(120, -2)
	await physics_frame
	ai.last_action = ""
	var retreats := 0
	for roll in 12:
		ai._choose_engage_action(bot, 60.0, 0.0, 1.0)
		retreats += 1 if ai.action == "retreat" else 0
		ai.last_action = ""
	if retreats == 0:
		_fail("With floor behind, a kiting bot should still retreat to keep its range")
	bot.queue_free()
	foe.queue_free()
	ground.queue_free()
	await process_frame
