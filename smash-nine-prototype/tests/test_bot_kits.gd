extends SceneTree
## Bots use the moves that make each fighter itself (2026-11-24, user "추천대로 해" on
## reports/quality-systems-2026-11-24/; until then no bot pressed U or opened Frey's wings):
## - Frey: the wings strike a target along one of eight ways when there is floor under the dash's
##   end, and never over the void; at mid range she sometimes jumps in for them.
## - Nova: the gravity beam (U) past melee reach with a clear line, more readily at a foe in the
##   air; the field (L) where it holds the target; inside it she flies up to a target above her.
## - Rio: the decoy (U) as a foe starts a swing at him, never with a ledge behind him; the swap
##   when the foe stands between him and the decoy facing him, and to get back onto the stage.
##   A bot facing him takes the decoy for him about 60% of the time and fights it until it is gone.
## - Brave Luna: the star beam once a foe stands in its path (not 4.4 s into her form whatever is
##   there), a foe at arm's length punched first, fired anyway before the form ends; the cyclone
##   shot early at a foe in its path.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const AI := preload("res://scripts/EnemyAI.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	seed(20261124)
	arena = Node2D.new()
	root.add_child(arena)
	for test in [_test_frey_wing_strike, _test_frey_wing_not_over_void, _test_frey_jumps_in, _test_nova_beam, _test_nova_field_and_flight, _test_rio_bait, _test_rio_swap, _test_bots_take_the_decoy, _test_luna_beam, _test_luna_cyclone]:
		await test.call()
		for child in arena.get_children():
			child.queue_free()
		await process_frame
		await physics_frame
	if failed:
		quit(1)
		return
	print("Bot kit tests passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	failed = true

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

func _fighter(character_id: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.realm_origin = Vector2(-960, -540)
	fighter.realm_size = Vector2(1920, 1080)
	return fighter

## A foe that stands where it is put and survives the test.
func _foe(character_id: String, at: Vector2, facing := -1) -> Node:
	var foe := _fighter(character_id, 2, at)
	foe.set_physics_process(false)
	foe.max_hp = 100000.0
	foe.hp = 100000.0
	foe.facing = facing
	return foe

## The same foe, standing on the floor under it (a body that never moved does not know its floor).
func _standing_foe(character_id: String, at: Vector2, facing := -1) -> Node:
	var foe := _foe(character_id, at, facing)
	foe.is_dummy = true
	foe.set_physics_process(true)
	for frame in 20:
		await physics_frame
	foe.is_dummy = false
	foe.set_physics_process(false)
	return foe

func _wall(at: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	arena.add_child(body)
	body.global_position = at
	return body

## A bot standing on the floor with its brain switched off: the tests call the brain themselves.
func _standing_bot(character_id: String, at: Vector2) -> Node:
	var bot := _fighter(character_id, 1, at)
	bot.is_dummy = true
	for frame in 20:
		await physics_frame
	bot.is_dummy = false
	bot.set_physics_process(false)
	if not bot.is_on_floor():
		_fail("Test setup: the %s bot should stand on the floor" % character_id)
	return bot

func _count(fighter: Node, key: String) -> int:
	return int(fighter.move_counts.get(key, 0.0))

# --- Frey ---

## In the air, a target down and ahead along the diagonal, floor all round: she hovers, dashes at
## it and hits it.
func _test_frey_wing_strike() -> void:
	_floor(Vector2(0, 0), 1800)
	var frey := _fighter("frey", 1, Vector2(0, -150))
	var foe := _foe("yuki", Vector2(140, -2))
	frey.is_dummy = true
	for frame in 3:
		await physics_frame
	frey.global_position = Vector2(0, -150)
	frey.velocity = Vector2.ZERO
	frey.air_jumps_left = frey.max_air_jumps
	var ai = frey.ai_controller
	ai.target = foe
	ai.state = AI.STATE_ENGAGE
	ai.wing_roll = 1
	ai.air_time = 1.0
	ai._drive_frey_wings(frey, 0.016)
	if not bool(frey.wing_hovering):
		_fail("A Frey bot in the air with a target along the diagonal should open her wings")
	elif ai.wing_aim.x < 0.6 or ai.wing_aim.y < 0.6:
		_fail("The wing dash should aim down and ahead at the target (aim %s)" % ai.wing_aim)
	var hp: float = foe.hp
	for frame in 40:
		await physics_frame
	if float(foe.hp) >= hp:
		_fail("The wing dash-slash should hit the target it was aimed at")
	if _count(frey, "wings") != 1:
		_fail("The wings should be counted once (got %d)" % _count(frey, "wings"))
	if ai.wing_cooldown <= 0.0:
		_fail("The wings should pause after a use")

## The same strike with no floor under where the dash ends, and one out of reach: no wings.
func _test_frey_wing_not_over_void() -> void:
	_floor(Vector2(-300, 0), 500)
	var frey := _fighter("frey", 1, Vector2(-60, -150))
	var foe := _foe("yuki", Vector2(80, -10))
	frey.is_dummy = true
	for frame in 3:
		await physics_frame
	frey.global_position = Vector2(-60, -150)
	frey.velocity = Vector2.ZERO
	frey.air_jumps_left = frey.max_air_jumps
	var ai = frey.ai_controller
	ai.target = foe
	ai.state = AI.STATE_ENGAGE
	ai.wing_roll = 1
	ai.air_time = 1.0
	ai._drive_frey_wings(frey, 0.016)
	if bool(frey.wing_hovering):
		_fail("No wings when the dash would end over the void (after it she cannot act until she lands)")
	foe.global_position = Vector2(-60 - 400, -150)
	ai._drive_frey_wings(frey, 0.016)
	if bool(frey.wing_hovering):
		_fail("No wings at a target out of the strike's reach")

## On the floor at mid range she takes the jump for her wings some of the time.
func _test_frey_jumps_in() -> void:
	_floor(Vector2(0, 0), 1800)
	var frey: Node = await _standing_bot("frey", Vector2(-150, -2))
	var foe := _foe("yuki", Vector2(150, -2))
	var ai = frey.ai_controller
	ai.target = foe
	var picks := 0
	for trial in 200:
		ai.wing_cooldown = 0.0
		ai.last_action = ""
		ai._choose_engage_action(frey, 300.0, 0.0, 1.0)
		if ai.action == "wing_in":
			picks += 1
		if frey.is_guarding:
			frey._stop_guard(false)
		frey.guard_recovery_timer = 0.0
	if picks < 30 or picks > 95:
		_fail("At mid range Frey should jump in for her wings about 30% of the time (%d of 200)" % picks)
	picks = 0
	for trial in 100:
		ai.wing_cooldown = 0.0
		ai._choose_engage_action(frey, 60.0, 0.0, 1.0)
		if ai.action == "wing_in":
			picks += 1
		if frey.is_guarding:
			frey._stop_guard(false)
		frey.guard_recovery_timer = 0.0
	if picks != 0:
		_fail("Up close there is no room for the wings: no jump for them (%d of 100)" % picks)

# --- Nova ---

func _beam_asks(ai, nova: Node, trials: int) -> int:
	var asks := 0
	for trial in trials:
		ai.beam_pause = 0.0
		ai.field_pause = 100.0
		if str(ai._nova_kit_intent(nova, ai._intent()).get("attack", "")) == "skill_3":
			asks += 1
	return asks

func _test_nova_beam() -> void:
	_floor(Vector2(0, 0), 1800)
	var nova: Node = await _standing_bot("nova", Vector2(-200, -2))
	var standing: Node = await _standing_foe("frey", Vector2(200, -2))
	var ai = nova.ai_controller
	ai.target = standing
	ai.state = AI.STATE_ENGAGE
	var asks := _beam_asks(ai, nova, 40)
	if asks < 10 or asks > 30:
		_fail("Nova should fire the beam at a standing foe 400 px away about half the time (%d of 40)" % asks)
	# Too close, too far, or behind a wall: never.
	standing.global_position = Vector2(-100, -2)
	if _beam_asks(ai, nova, 20) != 0:
		_fail("No beam inside melee reach")
	standing.global_position = Vector2(700, -2)
	if _beam_asks(ai, nova, 20) != 0:
		_fail("No beam past its reach")
	standing.global_position = Vector2(200, -2)
	var wall := _wall(Vector2(0, -150), Vector2(40, 300))
	await physics_frame
	await physics_frame
	if _beam_asks(ai, nova, 20) != 0:
		_fail("No beam with a wall in its line")
	wall.queue_free()
	standing.queue_free()
	await physics_frame
	await physics_frame
	# In the air it is slammed down: asked for more readily, aimed up at it.
	var foe := _foe("frey", Vector2(60, -230))
	ai.target = foe
	asks = _beam_asks(ai, nova, 40)
	if asks < 24:
		_fail("Nova should fire the beam at a foe in the air most of the time (%d of 40)" % asks)
	ai.beam_pause = 0.0
	var intent: Dictionary = {}
	for trial in 20:
		ai.beam_pause = 0.0
		intent = ai._nova_kit_intent(nova, ai._intent())
		if str(intent.get("attack", "")) == "skill_3":
			break
	var aim: Vector2 = intent.get("aim", Vector2.ZERO)
	if aim.y > -0.4 or aim.x < 0.4:
		_fail("The beam should be aimed up at the foe in the air (aim %s)" % aim)
	if ai.beam_pause < AI.NOVA_BEAM_PAUSE_MIN:
		_fail("The beam should pause after a shot")
	# The press goes out and the shot lands.
	nova.set_physics_process(true)
	nova.is_dummy = true
	ai._apply_intent(nova, intent)
	var hp: float = foe.hp
	for frame in 40:
		ai.aim_direction = aim
		await physics_frame
	if _count(nova, "u") != 1:
		_fail("The bot's U press should start the gravity beam (counted %d)" % _count(nova, "u"))
	if float(foe.hp) >= hp:
		_fail("The gravity beam should reach the foe it was aimed at")
	nova.is_dummy = false
	nova.set_physics_process(false)

func _test_nova_field_and_flight() -> void:
	_floor(Vector2(0, 0), 1800)
	var nova: Node = await _standing_bot("nova", Vector2(0, -2))
	var foe := _foe("frey", Vector2(150, -2))
	var ai = nova.ai_controller
	ai.target = foe
	ai.state = AI.STATE_ENGAGE
	var casts := 0
	for trial in 40:
		ai.beam_pause = 100.0
		ai.field_pause = 0.0
		if str(ai._nova_kit_intent(nova, ai._intent()).get("attack", "")) == "skill_2":
			casts += 1
	if casts < 8 or casts > 26:
		_fail("Nova should cast her field on a foe 150 px away about 40%% of the looks (%d of 40)" % casts)
	foe.global_position = Vector2(420, -2)
	casts = 0
	for trial in 40:
		ai.beam_pause = 100.0
		ai.field_pause = 0.0
		if str(ai._nova_kit_intent(nova, ai._intent()).get("attack", "")) == "skill_2":
			casts += 1
	if casts != 0:
		_fail("No field where it would not hold the target (%d of 40)" % casts)
	# Inside her field, a foe above her: she flies up to it.
	nova._cast_field()
	foe.global_position = Vector2(40, -230)
	var intent: Dictionary = ai._nova_kit_intent(nova, ai._intent())
	var aim: Vector2 = intent.get("aim", Vector2.ZERO)
	if aim.y > -0.9:
		_fail("In her field Nova should steer up to a foe above her (aim %s)" % aim)
	nova.set_physics_process(true)
	for frame in 45:
		await physics_frame
	if nova.global_position.y > -90.0:
		_fail("In her field the Nova bot should fly up toward the foe above her (y %.0f)" % nova.global_position.y)
	if float(nova.move_counts.get("flight", 0.0)) < 0.2:
		_fail("Her flight should be counted (%.2f s)" % float(nova.move_counts.get("flight", 0.0)))

# --- Rio ---

## A foe 110 px away starts a swing at Rio, `trials` times; how often he leaves the decoy.
func _bait_casts(rio: Node, foe: Node, trials: int) -> int:
	var ai = rio.ai_controller
	var home: Vector2 = rio.global_position
	var casts := 0
	for trial in trials:
		rio._clear_decoy()
		rio.decoy_cooldown_timer = 0.0
		rio.attack_lock_timer = 0.0
		rio.global_position = home
		rio.velocity = Vector2.ZERO
		rio.facing = 1
		foe.attack_lock_timer = 0.0
		ai.guard_delay_timer = -1.0
		if rio.is_guarding:
			rio._stop_guard(false)
		rio.guard_recovery_timer = 0.0
		ai.update(rio, 0.016)
		foe.attack_serial += 1
		foe.attack_lock_timer = 0.3
		foe.attack_elapsed = 0.0
		foe.attack_startup = 0.2
		ai.update(rio, 0.016)
		if is_instance_valid(rio.decoy):
			casts += 1
			if rio.decoy.global_position.distance_to(home) > 4.0:
				_fail("The decoy should stand where Rio stood (%s, he stood at %s)" % [rio.decoy.global_position, home])
			if rio.global_position.x > home.x - 100.0:
				_fail("Rio should step back from the foe as he leaves the decoy (x %.0f from %.0f)" % [rio.global_position.x, home.x])
	rio._clear_decoy()
	rio.global_position = home
	return casts

func _test_rio_bait() -> void:
	var ground := _floor(Vector2(0, 0), 1800)
	var rio: Node = await _standing_bot("rio", Vector2(0, -2))
	var foe := _foe("frey", Vector2(110, -2))
	var casts := _bait_casts(rio, foe, 40)
	if casts < 10 or casts > 30:
		_fail("Rio should leave his decoy for about half the swings started at him (%d of 40)" % casts)
	if _count(rio, "u") != casts:
		_fail("Each decoy should be counted as a U (%d casts, %d counted)" % [casts, _count(rio, "u")])
	# A ledge 70 px behind him: the step back would leave the floor.
	ground.queue_free()
	_floor(Vector2(830, 0), 1800)
	await physics_frame
	await physics_frame
	casts = _bait_casts(rio, foe, 30)
	if casts != 0:
		_fail("No decoy step with a ledge behind him (%d of 30)" % casts)

func _test_rio_swap() -> void:
	_floor(Vector2(0, 0), 1800)
	var rio: Node = await _standing_bot("rio", Vector2(0, -2))
	var foe := _foe("frey", Vector2(300, -2))
	var ai = rio.ai_controller
	ai.target = foe
	ai.state = AI.STATE_ENGAGE
	rio.facing = 1
	rio.press_skill_three()
	if not is_instance_valid(rio.decoy) or rio.global_position.x > -100.0:
		_fail("Test setup: Rio should have left a decoy at 0 and stepped back (x %.0f)" % rio.global_position.x)
		return
	rio.attack_lock_timer = 0.0
	# The foe not between them, or looking at the decoy: no swap.
	ai._drive_rio_decoy(rio)
	foe.global_position = Vector2(-60, -2)
	foe.facing = 1
	ai._drive_rio_decoy(rio)
	if not bool(rio.decoy_swap_ready):
		_fail("No swap unless the foe stands between Rio and the decoy with its back to the decoy")
	# Between them and facing Rio: he swaps and stands behind it.
	foe.facing = -1
	var was: Vector2 = rio.global_position
	ai._drive_rio_decoy(rio)
	if bool(rio.decoy_swap_ready) or absf(rio.global_position.x) > 4.0:
		_fail("Rio should swap to the decoy's place behind the foe (x %.0f)" % rio.global_position.x)
	elif not rio._is_behind(foe):
		_fail("After the swap Rio should stand behind the foe (the back hit)")
	elif rio.decoy.global_position.distance_to(was) > 4.0:
		_fail("The decoy should stand where Rio was")
	if _count(rio, "u2") != 1:
		_fail("The swap should be counted once (got %d)" % _count(rio, "u2"))
	# Off the stage with the decoy on the floor: back to it.
	rio._clear_decoy()
	rio.decoy_cooldown_timer = 0.0
	rio.attack_lock_timer = 0.0
	rio.global_position = Vector2(0, -2)
	rio.facing = 1
	rio.press_skill_three()
	var spot: Vector2 = rio.decoy.global_position
	rio.attack_lock_timer = 0.0
	rio.global_position = Vector2(-1100, 200)
	ai.state = AI.STATE_RECOVER
	ai._drive_rio_decoy(rio)
	if rio.global_position.distance_to(spot) > 4.0:
		_fail("Off the stage, Rio should swap back to the decoy standing on it (at %s)" % rio.global_position)

## A bot whose target leaves a decoy takes the decoy for him some of the time, and fights there.
func _test_bots_take_the_decoy() -> void:
	_floor(Vector2(0, 0), 1800)
	var bot: Node = await _standing_bot("frey", Vector2(150, -2))
	var rio: Node = await _standing_bot("rio", Vector2(0, -2))
	var ai = bot.ai_controller
	ai.target = rio
	ai.state = AI.STATE_ENGAGE
	var fooled := 0
	for trial in 40:
		rio._clear_decoy()
		rio.decoy_cooldown_timer = 0.0
		rio.attack_lock_timer = 0.0
		rio.global_position = Vector2(0, -2)
		rio.facing = 1
		ai.fooled_by = null
		ai.seen_decoy = null
		rio.press_skill_three()
		ai._watch_decoy(0.016)
		if is_instance_valid(ai.fooled_by):
			fooled += 1
			if ai._target_point().distance_to(rio.decoy.global_position) > 1.0 or ai._predicted_target_position().distance_to(rio.decoy.global_position) > 1.0:
				_fail("A fooled bot should fight and aim at the decoy")
		elif ai._target_point().distance_to(rio.global_position) > 1.0:
			_fail("A bot that is not fooled should keep fighting Rio himself")
		# One roll per decoy.
		var before: bool = is_instance_valid(ai.fooled_by)
		ai._watch_decoy(0.016)
		if is_instance_valid(ai.fooled_by) != before:
			_fail("A decoy should be rolled for once")
	if fooled < 14 or fooled > 34:
		_fail("A bot should take Rio's decoy for him about 60%% of the time (%d of 40)" % fooled)
	# The decoy bursts: the bot is back on Rio.
	ai.fooled_by = rio.decoy
	ai.fooled_timer = 1.0
	rio.decoy.apply_hit(bot, 5.0, 100.0, Vector2.LEFT)
	ai._watch_decoy(0.016)
	if is_instance_valid(ai.fooled_by):
		_fail("Once the decoy bursts the bot should fight Rio again")
	if _count(rio, "decoy_burst") != 1:
		_fail("The burst should be counted (got %d)" % _count(rio, "decoy_burst"))

# --- Brave Luna ---

func _brave_luna(at: Vector2) -> Node:
	var luna: Node = await _standing_bot("luna", at)
	luna._enter_transformation()
	luna.attack_lock_timer = 0.0
	return luna

func _test_luna_beam() -> void:
	_floor(Vector2(0, 0), 1800)
	var luna: Node = await _brave_luna(Vector2(0, -2))
	var foe := _foe("frey", Vector2(60, -300))
	var ai = luna.ai_controller
	ai.target = foe
	ai.state = AI.STATE_ENGAGE
	# Nobody in the beam's path 2 s into the form: she keeps it.
	luna.transformation_timer = luna.TRANSFORMATION_DURATION - 2.0
	ai._drive_luna_brave(luna)
	if bool(luna.transformation_finishing):
		_fail("No star beam while nobody stands in its path")
	# A foe at arm's length is punched first.
	foe.global_position = Vector2(50, -2)
	ai._drive_luna_brave(luna)
	if bool(luna.transformation_finishing):
		_fail("A foe at arm's length should be punched before the beam ends her form")
	# In the path, behind her: she turns and fires.
	foe.global_position = Vector2(-320, -2)
	luna.facing = 1
	ai._drive_luna_brave(luna)
	if not bool(luna.transformation_finishing):
		_fail("Brave Luna should fire the star beam once a foe stands in its path")
	elif int(luna.facing) != -1:
		_fail("She should turn the beam toward the foe")
	if _count(luna, "i2") != 1:
		_fail("The beam should be counted once (got %d)" % _count(luna, "i2"))
	luna.queue_free()
	await process_frame
	# Nobody in the path at all: fired anyway before the form runs out.
	luna = await _brave_luna(Vector2(0, -2))
	ai = luna.ai_controller
	foe.global_position = Vector2(60, -300)
	ai.target = foe
	ai.state = AI.STATE_ENGAGE
	luna.transformation_timer = luna.TRANSFORMATION_DURATION - 4.7
	ai._drive_luna_brave(luna)
	if not bool(luna.transformation_finishing):
		_fail("The star beam should be fired before the form ends even with nobody in its path")

func _test_luna_cyclone() -> void:
	_floor(Vector2(0, 0), 1800)
	var luna: Node = await _brave_luna(Vector2(0, -2))
	var foe := _foe("frey", Vector2(250, -2))
	var ai = luna.ai_controller
	ai.target = foe
	ai.state = AI.STATE_ENGAGE
	luna._spin_cyclone()
	luna.cyclone_timer = luna.CYCLONE_TIME - 0.2
	ai._drive_luna_brave(luna)
	if float(luna.cyclone_timer) <= 0.0:
		_fail("The cyclone should spin a moment before the early shot")
	luna.cyclone_timer = luna.CYCLONE_TIME - 0.8
	foe.global_position = Vector2(250, -260)
	ai._drive_luna_brave(luna)
	if float(luna.cyclone_timer) <= 0.0:
		_fail("No early cyclone shot at a foe out of its path")
	foe.global_position = Vector2(-250, -2)
	luna.facing = 1
	ai._drive_luna_brave(luna)
	if float(luna.cyclone_timer) > 0.0:
		_fail("Brave Luna should fire the cyclone early at a foe in its path")
	elif int(luna.facing) != -1:
		_fail("She should turn the cyclone shot toward the foe")
	if _count(luna, "l2") != 1:
		_fail("The early cyclone shot should be counted once (got %d)" % _count(luna, "l2"))
	if bool(luna.transformation_finishing):
		_fail("The beam should wait while the cyclone spins")
