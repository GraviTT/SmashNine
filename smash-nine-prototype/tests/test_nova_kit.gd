extends SceneTree
## Nova's new kit (user 2026-11-03, D47). Passive "중력 중첩": stacking hits raise a gravity stage
## (slower walk, lower jumps); the third roots the fighter 2 s (no moving, no knockback, no
## teleport), then the stacks clear. J: a three-hit chain whose last hit stacks. K "중력 구체": an orb
## that bursts, pulls and stacks. L "중력 필드": a field where she flies, foes move as at stage 1 and
## monsters float. U "중력 광선": a beam that drags a grounded foe to her or slams an airborne one
## down. I "사건의 지평선": a sphere that swings foes round it; she joins, launches on release, and the
## sphere drops and bursts on them. Also the third skill slot (U) itself.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const GAME_SCALE := preload("res://scripts/GameScale.gd")
const MONSTER := preload("res://scripts/RealmMonster.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	await _test_gravity_stacks()
	await _clear()
	await _test_root()
	await _clear()
	await _test_chain_stacks()
	await _clear()
	await _test_orb()
	await _clear()
	await _test_field()
	await _clear()
	await _test_beam()
	await _clear()
	await _test_sphere()
	await _clear()
	await _test_third_skill_slot()
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Nova kit tests passed")
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

func _fighter(character_id: String, player_id: int, at: Vector2, human := false) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, human)
	fighter.ringout_y = 100000.0
	if human:
		fighter.set_process_unhandled_input(false)
	else:
		fighter.is_dummy = true
	return fighter

func _dummy(player_id: int, at: Vector2) -> Node:
	var dummy: Node = PLAYER_FACTORY.create("")
	arena.add_child(dummy)
	dummy.global_position = at
	dummy.setup_dummy(player_id)
	dummy.ringout_y = 100000.0
	return dummy

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

func _clear() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "ultimate"]:
		Input.action_release(action)
	for child in arena.get_children():
		child.queue_free()
	await process_frame
	await physics_frame

func _wait_ready(fighter: Node, limit := 120) -> void:
	for frame in limit:
		if fighter._can_start_attack():
			return
		await physics_frame

func _test_gravity_stacks() -> void:
	_floor(Vector2(0, 0), 2400)
	var nova := _fighter("nova", 1, Vector2(-400, -2))
	var foe := _fighter("frey", 2, Vector2(0, -2), true)
	await _frames(20)
	foe.add_gravity_stack(nova)
	if foe.gravity_stage != 1 or not is_equal_approx(foe.gravity_jump_scale(), sqrt(0.8)):
		_fail("One stack should be stage 1 with 80%% jump height (stage %d, jump speed x%.3f)" % [foe.gravity_stage, foe.gravity_jump_scale()])
	Input.action_press("move_right")
	await _frames(40)
	var stage_one_speed := absf(foe.velocity.x)
	foe.add_gravity_stack(nova)
	await _frames(40)
	var stage_two_speed := absf(foe.velocity.x)
	Input.action_release("move_right")
	if foe.gravity_stage != 2 or absf(stage_two_speed / maxf(stage_one_speed, 1.0) - 0.625) > 0.05:
		_fail("Stage 2 should walk at 50%% against stage 1's 80%% (%.0f vs %.0f px/s, stage %d)" % [stage_two_speed, stage_one_speed, foe.gravity_stage])
	# Each stage lasts 2 s, then drops one step.
	foe.gravity_stage_timer = 0.05
	await _frames(6)
	if foe.gravity_stage != 1 or foe.gravity_stage_timer < 1.8:
		_fail("Stage 2 should fall to stage 1 with a fresh 2 s (stage %d, %.2f s)" % [foe.gravity_stage, foe.gravity_stage_timer])
	foe.gravity_stage_timer = 0.05
	await _frames(6)
	if foe.gravity_stage != 0 or foe.gravity_effect_stage() != 0:
		_fail("Stage 1 should run out (stage %d)" % foe.gravity_stage)

func _test_root() -> void:
	_floor(Vector2(0, 0), 2400)
	var nova := _fighter("nova", 1, Vector2(-400, -2))
	var foe := _fighter("frey", 2, Vector2(0, -2), true)
	await _frames(20)
	for stack in 3:
		foe.add_gravity_stack(nova)
	if not foe.is_gravity_rooted() or foe.gravity_stage != 3:
		_fail("Three stacks should root (stage %d)" % foe.gravity_stage)
	var spot: Vector2 = foe.global_position
	foe.apply_hit(nova, 10.0, 700.0, Vector2(1, -0.5))
	Input.action_press("move_right")
	Input.action_press("move_up")
	await _frames(20)
	Input.action_release("move_right")
	Input.action_release("move_up")
	if foe.global_position.distance_to(spot) > 1.0:
		_fail("A rooted fighter should not walk, jump or fly from a hit (moved %.1f px)" % foe.global_position.distance_to(spot))
	var root_left: float = foe.gravity_root_timer
	foe.add_gravity_stack(nova)
	if foe.gravity_root_timer > root_left + 0.001:
		_fail("Nothing should stack while rooted")
	foe.gravity_root_timer = 0.05
	await _frames(6)
	if foe.is_gravity_rooted() or foe.gravity_stage != 0:
		_fail("The root should end with the stacks cleared (stage %d)" % foe.gravity_stage)
	# A rooted Luna cannot warp out.
	var luna := _fighter("luna", 3, Vector2(300, -2), true)
	await _frames(20)
	for stack in 3:
		luna.add_gravity_stack(nova)
	var luna_spot: Vector2 = luna.global_position
	luna.skill_one()
	await _frames(20)
	if luna.global_position.distance_to(luna_spot) > 1.0:
		_fail("A rooted Luna should not warp (moved %.1f px)" % luna.global_position.distance_to(luna_spot))

func _test_chain_stacks() -> void:
	_floor(Vector2(0, 0), 2400)
	var nova := _fighter("nova", 1, Vector2(-60, -2), true)
	var foe := _dummy(2, Vector2(40, -2))
	await _frames(20)
	nova.facing = 1
	var stages: Array[int] = []
	for press in 3:
		# On the floor too: a bump into the dummy can lift her a pixel, and an air J ends the chain.
		for frame in 30:
			if nova._can_start_attack() and nova.is_on_floor():
				break
			await physics_frame
		foe.global_position = nova.global_position + Vector2(85, 0)
		foe.knockback_velocity = Vector2.ZERO
		nova.basic_attack()
		await _frames(12)
		stages.append(foe.gravity_stage)
	if stages != [0, 0, 1]:
		_fail("Only the chain's third hit should stack (stages after each hit %s)" % [stages])

func _test_orb() -> void:
	_floor(Vector2(0, 0), 2400)
	var nova := _fighter("nova", 1, Vector2(-300, -2), true)
	var foe := _fighter("frey", 2, Vector2(0, -2))
	var other := _fighter("rio", 3, Vector2(90, -2))
	await _frames(20)
	nova.facing = 1
	var hp_before: float = foe.hp
	nova.skill_one()
	var burst := false
	for frame in 60:
		await physics_frame
		if nova.orb_pull_timer > 0.0:
			burst = true
			break
	if not burst:
		_fail("The orb should burst on the fighter it reaches")
		return
	if foe.hp >= hp_before:
		_fail("The orb's burst should hurt")
	var centre: Vector2 = nova.orb_pull_centre - GAME_SCALE.BODY_CENTRE
	var start_distance: float = other.global_position.distance_to(centre)
	await _frames(26)
	if other.global_position.distance_to(centre) >= start_distance - 10.0:
		_fail("The burst should pull a fighter beside it in (%.0f -> %.0f px)" % [start_distance, other.global_position.distance_to(centre)])
	if foe.gravity_stage != 1 or other.gravity_stage != 1:
		_fail("Everyone the burst pulled should get a stack after the pull (stages %d, %d)" % [foe.gravity_stage, other.gravity_stage])

func _test_field() -> void:
	_floor(Vector2(0, 0), 2400)
	var nova := _fighter("nova", 1, Vector2(0, -2), true)
	var foe := _fighter("frey", 2, Vector2(140, -2))
	var monster := CharacterBody2D.new()
	monster.set_script(MONSTER)
	monster.setup("mossling", 0, Vector2(-150, -40))
	arena.add_child(monster)
	await _frames(30)
	var monster_y: float = monster.global_position.y
	nova.skill_two()
	await _frames(20)
	if not is_instance_valid(nova.field) or not nova.field.is_active():
		_fail("L should cast the gravity field")
		return
	if not is_equal_approx(float(nova.skill_cooldown("l").y), 12.0) or float(nova.skill_cooldown("l").x) <= 10.0:
		_fail("The field should start its 12 s cooldown on the skill bar (%s)" % nova.skill_cooldown("l"))
	if foe.gravity_effect_stage() != 1 or foe.gravity_stage != 0:
		_fail("A foe in the field should move as at stage 1 without a stack (effect %d, stacks %d)" % [foe.gravity_effect_stage(), foe.gravity_stage])
	await _frames(30)
	if not monster.is_floating() or monster.global_position.y > monster_y - 30.0:
		_fail("A monster in the field should float up and stop (floating %s, %.0f -> %.0f)" % [monster.is_floating(), monster_y, monster.global_position.y])
	# She flies in it: up rises, and letting go she hangs there.
	var start_y: float = nova.global_position.y
	Input.action_press("move_up")
	await _frames(20)
	Input.action_release("move_up")
	var risen_y: float = nova.global_position.y
	await _frames(20)
	if risen_y > start_y - 60.0 or absf(nova.global_position.y - risen_y) > 25.0:
		_fail("Nova should fly up in her field and hang there (%.0f -> %.0f -> %.0f)" % [start_y, risen_y, nova.global_position.y])
	foe.global_position = Vector2(900, -2)
	await _frames(10)
	if foe.gravity_effect_stage() != 0:
		_fail("Leaving the field should end its slow at once")
	nova.field.elapsed = nova.FIELD_TIME - 0.02
	await _frames(20)
	if is_instance_valid(nova.field) and nova.field.is_active():
		_fail("The field should end after 6 s")

func _test_beam() -> void:
	_floor(Vector2(0, 0), 2400)
	var nova := _fighter("nova", 1, Vector2(-300, -2), true)
	var foe := _fighter("frey", 2, Vector2(0, -2))
	await _frames(20)
	nova.facing = 1
	var hp_before: float = foe.hp
	nova.skill_three()
	var stacked := false
	var wrapped := false
	for frame in 70:
		await physics_frame
		var wrap := arena.get_node_or_null("NovaBeamWrap")
		if wrap != null and wrap.get_node_or_null("Claws") != null:
			wrapped = true
		if foe.gravity_stage >= 1:
			stacked = true
			break
	if not stacked:
		_fail("The beam should drag a grounded foe and stack it")
		return
	if not wrapped:
		_fail("The beam's tip should split and wrap the foe while it drags it")
	await _frames(2)
	if arena.get_node_or_null("NovaBeamWrap") != null:
		_fail("The wrap should let go once the foe has arrived")
	var pulled_to: float = foe.global_position.distance_to(nova.global_position)
	if pulled_to > 130.0:
		_fail("The beam should drag the foe to just in front of her (%.0f px away)" % pulled_to)
	var grounded_damage: float = hp_before - foe.hp
	# Out of the way: the dragged foe stands where the next beam starts.
	foe.global_position = Vector2(700, -2)
	# Airborne: slammed down, more damage, a stack.
	# On the up-right line from her body centre (-300, -34).
	var flyer := _fighter("rio", 3, Vector2(-150, -152))
	flyer._freeze_movement(2.0)
	await _frames(5)
	await _wait_ready(nova)
	var flyer_hp: float = flyer.hp
	nova.facing = 1
	# Aimed up-right like a held stick, without the keys also jumping and walking her.
	nova.is_human = false
	nova.is_dummy = true
	nova.ai_controller.aim_direction = Vector2(1, -1).normalized()
	nova.skill_three()
	var slammed := false
	for frame in 40:
		await physics_frame
		if flyer.gravity_stage >= 1:
			slammed = true
			break
	if not slammed:
		_fail("The beam should reach a foe in the air and stack it")
		return
	if flyer.knockback_velocity.y <= 0.0 and flyer.velocity.y <= 0.0:
		_fail("A foe in the air should be slammed down (knockback %s)" % flyer.knockback_velocity)
	if flyer_hp - flyer.hp <= grounded_damage:
		_fail("The slam should hurt more than the drag (%.1f vs %.1f)" % [flyer_hp - flyer.hp, grounded_damage])

func _test_sphere() -> void:
	_floor(Vector2(0, 0), 2400)
	var nova := _fighter("nova", 1, Vector2(0, -2), true)
	var foe := _fighter("frey", 2, Vector2(170, -2))
	await _frames(20)
	var hp_before: float = foe.hp
	nova.ultimate()
	if nova.ultimate_phase != nova.ULTIMATE_SPHERE:
		_fail("I should raise the sphere (phase %d)" % nova.ultimate_phase)
		return
	await _frames(20)
	if not nova.sphere_caught.has(foe):
		_fail("The sphere should catch a foe within its reach")
		return
	var before: Vector2 = foe.global_position
	await _frames(10)
	if foe.global_position.distance_to(before) < 5.0:
		_fail("A caught foe should circle the sphere")
	Input.action_press("ultimate")
	nova.try_ultimate_followup()
	await _frames(10)
	if nova.ultimate_phase != nova.ULTIMATE_ORBIT:
		_fail("Holding I should keep Nova circling (phase %d)" % nova.ultimate_phase)
	Input.action_release("ultimate")
	await _frames(2)
	if nova.ultimate_phase != nova.ULTIMATE_LAUNCH or not nova.sphere_falling:
		_fail("Letting go of I should launch her and drop the sphere (phase %d, falling %s)" % [nova.ultimate_phase, nova.sphere_falling])
	for frame in 80:
		await physics_frame
		if not nova.sphere_active:
			break
	if nova.sphere_active:
		_fail("The sphere should burst within its fall")
	if foe.hp >= hp_before or foe.gravity_stage < 1:
		_fail("The sphere's burst should hurt and stack its catch (hp %.1f -> %.1f, stage %d)" % [hp_before, foe.hp, foe.gravity_stage])
	if nova.ultimate_phase != nova.ULTIMATE_NONE:
		await _frames(30)
	if nova.ultimate_phase != nova.ULTIMATE_NONE:
		_fail("The ultimate should end after the launch (phase %d)" % nova.ultimate_phase)

func _test_third_skill_slot() -> void:
	_floor(Vector2(0, 0), 2400)
	if not InputMap.has_action("skill_3"):
		_fail("The skill_3 action should exist")
	else:
		var keys := InputMap.action_get_events("skill_3").filter(func(event: InputEvent) -> bool: return event is InputEventKey and event.physical_keycode == KEY_U)
		if keys.is_empty():
			_fail("skill_3 should be on U")
	var frey := _fighter("frey", 1, Vector2(-200, -2), true)
	var nova := _fighter("nova", 2, Vector2(200, -2), true)
	await _frames(20)
	if frey.has_skill_three() or not nova.has_skill_three():
		_fail("Only Nova has a third skill for now")
	frey.skill_three()
	nova.skill_three()
	await _frames(2)
	if frey.attack_lock_timer > 0.0 or nova.attack_lock_timer <= 0.0:
		_fail("U should do nothing for Frey and fire Nova's beam (locks %.2f, %.2f)" % [frey.attack_lock_timer, nova.attack_lock_timer])
