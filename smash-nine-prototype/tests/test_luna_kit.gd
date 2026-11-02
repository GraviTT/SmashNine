extends SceneTree
## Luna's new kit (user 2026-11-03, D45). Normal: J "별빛 연사" fires three small stars and a big
## bursting one, every landed star marks the target (passive "별의 마법": +10% damage taken); K
## "반짝 도약" warps her and bursts around her, once per airtime; L "별의 방어막" stops projectiles,
## takes the hits meant for her, nudges whoever touches it and breaks; I bursts her marks with a
## 3 s stun. Brave: J "브레이브 러시" dashes and strikes in front of the foe it meets (frames 0, 2, 4;
## the third hit launches); K "혜성 붙잡기" grabs and throws (up when up is held); L "별의 회오리"
## stops projectiles while she spins and fires a cyclone that stuns 2 s, then throws up; I "별의 광선"
## holds its target in hitstun for 3 s, blasts it away and ends Brave; the passive "별의 정화" takes
## her J to the foe her last skill hit. Also kept: the special transformation's timing and the bot's
## beam retry.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const STAR_PATH := "res://characters/luna/LunaStar.gd"

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	await _test_star_volley_and_mark()
	await _test_warp()
	await _test_barrier()
	await _test_mark_burst()
	await _test_special_transformation()
	await _test_brave_rush_chain()
	await _test_grab_and_purify()
	await _test_cyclone()
	await _test_star_beam()
	await _test_bot_beam_retry()
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Luna kit tests passed")
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
	for child in arena.get_children():
		child.queue_free()
	await process_frame
	await physics_frame

func _wait_ready(fighter: Node, limit := 120) -> void:
	for frame in limit:
		if fighter._can_start_attack():
			return
		await physics_frame

func _test_star_volley_and_mark() -> void:
	_floor(Vector2(0, 0), 2400)
	var luna := _fighter("luna", 1, Vector2(0, -2))
	var foe := _fighter("frey", 2, Vector2(200, -2))
	await _frames(20)
	var stars: Array[Node] = []
	var on_added := func(node: Node) -> void:
		var script: Script = node.get_script()
		if script != null and script.resource_path == STAR_PATH:
			stars.append(node)
	node_added.connect(on_added)
	var hits := []
	foe.damaged.connect(func(_v, amount, _att, _src): hits.append(amount))
	luna.facing = 1
	# Read while each star still flies (they live a few frames before they hit).
	var kinds: Array[bool] = []
	for press in 4:
		await _wait_ready(luna)
		luna.basic_attack()
		for frame in 30:
			await physics_frame
			if stars.size() > kinds.size():
				kinds.append(bool(stars[-1].big) if is_instance_valid(stars[-1]) else false)
				break
	await _frames(40)
	node_added.disconnect(on_added)
	if kinds != [false, false, false, true]:
		_fail("Normal J four times should fire three small stars, then one big one (got %s)" % [kinds])
	if hits.size() < 4:
		_fail("The stars and the big star's burst should land on a fighter 200 px ahead (%d hits)" % hits.size())
	if float(foe.star_mark_timer) < 9.0 or foe.star_mark_source != luna:
		_fail("A landed star should mark the target for 10 s (%.2f s left)" % float(foe.star_mark_timer))
	# The mark: 10% more damage from any hit.
	var plain := _fighter("frey", 3, Vector2(-400, -2))
	await _frames(4)
	var before_marked: float = foe.hp
	var before_plain: float = plain.hp
	foe.apply_hit(plain, 10.0, 0.0, Vector2.RIGHT)
	plain.apply_hit(foe, 10.0, 0.0, Vector2.RIGHT)
	var marked_damage := before_marked - float(foe.hp)
	var plain_damage := before_plain - float(plain.hp)
	if absf(marked_damage - plain_damage * 1.1) > 0.05:
		_fail("A marked fighter should take 10%% more damage (%.2f marked vs %.2f)" % [marked_damage, plain_damage])
	await _clear()

func _test_warp() -> void:
	_floor(Vector2(0, 0), 2400)
	var luna := _fighter("luna", 1, Vector2(0, -2))
	var dummy := _dummy(2, Vector2(300, -2))
	await _frames(20)
	var hits := []
	dummy.damaged.connect(func(_v, amount, _att, _src): hits.append(amount))
	luna.facing = 1
	var start_x: float = luna.global_position.x
	luna.skill_one()
	await _frames(30)
	var moved: float = luna.global_position.x - start_x
	if moved < 200.0 or moved > 300.0:
		_fail("K should warp Luna about 255 px ahead (moved %.0f)" % moved)
	if hits.is_empty():
		_fail("K's arrival burst should hit a fighter next to where she appears")
	# Once per airtime.
	await _wait_ready(luna)
	luna.global_position = Vector2(0, -400)
	luna.velocity = Vector2.ZERO
	await _frames(2)
	luna.skill_one()
	await _wait_ready(luna)
	if luna.is_on_floor():
		_fail("The air warp test needs Luna in the air")
	var air_x: float = luna.global_position.x
	luna.skill_one()
	await _frames(20)
	if absf(luna.global_position.x - air_x) > 40.0:
		_fail("K should warp only once per airtime (moved %.0f on the second press)" % (luna.global_position.x - air_x))
	await _clear()

func _test_barrier() -> void:
	_floor(Vector2(0, 0), 2400)
	var luna := _fighter("luna", 1, Vector2(0, -2))
	var rio := _fighter("rio", 2, Vector2(300, -2))
	await _frames(20)
	luna.skill_two()
	await _frames(20)
	if not luna._barrier_up():
		_fail("L should raise the star barrier")
		await _clear()
		return
	if float(luna.skill_cooldown("l").x) <= 6.0:
		_fail("The barrier should start its 8 s cooldown (%.1f)" % float(luna.skill_cooldown("l").x))
	# A projectile from Rio stops at the barrier.
	var hp_before: float = luna.hp
	var barrier_hp: float = luna.barrier.hp
	rio.facing = -1
	var wave: Node = rio._spawn_projectile(Vector2(24, 54), 6, 300, Vector2.LEFT, Color.WHITE, 640.0, 0.6)
	await _frames(30)
	if is_instance_valid(wave):
		_fail("The barrier should stop Rio's wave")
	if luna.hp < hp_before or float(luna.barrier.hp) >= barrier_hp:
		_fail("The stopped wave should hurt the barrier, not Luna (Luna %.1f -> %.1f, barrier %.1f -> %.1f)" % [hp_before, luna.hp, barrier_hp, luna.barrier.hp])
	# A hit meant for her goes into the barrier.
	luna.apply_hit(rio, 8.0, 300.0, Vector2.LEFT)
	if luna.hp < hp_before or float(luna.hitstun_timer) > 0.0:
		_fail("The barrier should take a hit meant for Luna (hp %.1f, hitstun %.2f)" % [luna.hp, luna.hitstun_timer])
	# Touching it hurts a little and pushes out.
	rio.global_position = Vector2(luna.global_position.x + 90.0, -2)
	var rio_hp: float = rio.hp
	await _frames(6)
	if rio.hp >= rio_hp or rio.knockback_velocity.x <= 0.0:
		_fail("A fighter touching the barrier should take a small hit and be pushed out (hp %.1f -> %.1f, push %.0f)" % [rio_hp, rio.hp, rio.knockback_velocity.x])
	# Enough damage breaks it.
	luna.apply_hit(rio, 40.0, 300.0, Vector2.LEFT)
	await _frames(2)
	if luna._barrier_up():
		_fail("The barrier should break after taking 30 damage")
	luna.apply_hit(rio, 8.0, 300.0, Vector2.LEFT)
	if luna.hp >= hp_before:
		_fail("Once broken, hits should reach Luna again")
	await _clear()

func _test_mark_burst() -> void:
	_floor(Vector2(0, 0), 2400)
	var luna := _fighter("luna", 1, Vector2(0, -2))
	var far := _fighter("frey", 2, Vector2(900, -2))
	var other := _fighter("frey", 3, Vector2(-900, -2))
	await _frames(10)
	far.apply_star_mark(luna, 10.0)
	var hp_before: float = far.hp
	luna.ultimate()
	await create_timer(luna.transform_time(8) + 0.1).timeout
	if far.star_mark_timer > 0.0:
		_fail("The transformation should burst the star mark")
	if far.hp >= hp_before or float(far.status_stun_timer) < 2.5 or float(far.hitstun_timer) < 2.5:
		_fail("A burst mark should deal damage and stun 3 s at any distance (hp %.1f -> %.1f, stun %.2f)" % [hp_before, far.hp, far.status_stun_timer])
	if other.hp < other.max_hp:
		_fail("An unmarked fighter far away should be untouched")
	await _clear()

## The special transformation (user 2026-10-14): the 12-frame row at its own speed (drawn for 12 fps;
## the user's adopted 7.8 fps since 2026-10-15, about 1.5 s). She becomes Brave Luna (and bursts) on
## the landing frame 9, and the ultimate's super armour covers the motion.
func _test_special_transformation() -> void:
	_floor(Vector2(0, 0), 1400)
	var luna := _fighter("luna", 1, Vector2(0, -2))
	await _frames(4)
	luna.perform_ultimate()
	var frames: SpriteFrames = luna.character_sprite.sprite_frames
	if luna.character_sprite.animation != &"luna_transform" or frames.get_frame_count(&"luna_transform") != 12:
		_fail("The ultimate should play the 12-frame luna_transform (got %s, %d frames)" % [luna.character_sprite.animation, frames.get_frame_count(&"luna_transform")])
	var fps := frames.get_animation_speed(&"luna_transform")
	var motion: float = luna.transform_time(12)
	var burst: float = luna.transform_time(8)
	if absf(motion - 12.0 / fps) > 0.001 or absf(burst - 8.0 / fps) > 0.001:
		_fail("The transformation should take the row's 12 drawings at its %.2f fps, the burst its 8 (got %.2f s, %.2f s)" % [fps, motion, burst])
	if float(luna.ultimate_armor_timer) < motion - 0.01:
		_fail("Super armour should cover the %.2f s transformation (got %.2f s)" % [motion, float(luna.ultimate_armor_timer)])
	await create_timer(burst - 0.15).timeout
	if bool(luna.transformed):
		_fail("Luna should still be mid-spin %.2f s in, not Brave Luna yet" % (burst - 0.15))
	await create_timer(0.3).timeout
	if not bool(luna.transformed):
		_fail("Luna should be Brave Luna by %.2f s (the landing frame is at %.2f s)" % [burst + 0.15, burst])
	await _clear()

func _brave_luna(at: Vector2, human := false) -> Node:
	var luna := _fighter("luna", 1, at, human)
	await _frames(10)
	luna._enter_transformation()
	luna.transformation_timer = 60.0
	await _frames(40)
	return luna

## The rush closes in on a foe 140 px ahead and strikes in front of it; the chain plays the jab,
## body kick and spin kick frames and is a true combo; the third hit launches.
func _test_brave_rush_chain() -> void:
	_floor(Vector2(0, 0), 2400)
	var luna: Node = await _brave_luna(Vector2(0, -2))
	var target := _fighter("frey", 3, Vector2(luna.global_position.x + 140.0, -2))
	for frame in 120:
		if target.hitstun_timer <= 0.0 and target.is_on_floor():
			break
		await physics_frame
	var hits := []
	target.damaged.connect(func(_v, _amount, _att, _src): hits.append(float(target.hitstun_timer)))
	luna.facing = 1
	var first_frames: Array[int] = []
	var gap_at_first_hit := -1.0
	for hit in 3:
		await _wait_ready(luna)
		luna.perform_basic_attack("neutral", Vector2.RIGHT)
		first_frames.append(int(luna.character_sprite.frame))
		if hit == 0:
			for frame in 20:
				await physics_frame
				if hits.size() >= 1:
					gap_at_first_hit = target.global_position.x - luna.global_position.x
					break
	await _frames(30)
	if hits.size() < 3:
		_fail("Brave Rush: all three hits should land on a foe 140 px ahead (%d did)" % hits.size())
	elif gap_at_first_hit < 0.0 or gap_at_first_hit > 90.0:
		_fail("Brave Rush should stop in front of the foe before the jab (gap %.0f)" % gap_at_first_hit)
	for index in range(1, hits.size()):
		if float(hits[index]) <= 0.0:
			_fail("Brave Rush should be a true combo once the first hit lands (hit %d outside hitstun)" % (index + 1))
	if first_frames != [0, 2, 4]:
		_fail("Brave Rush jab, body kick and spin kick should start on frames 0, 2 and 4 (got %s)" % [first_frames])
	if target.is_on_floor() and target.velocity.y >= 0.0 and target.knockback_velocity.y >= 0.0:
		_fail("The third Brave Rush hit should launch the foe")
	await _clear()

## K grabs a fighter in reach, holds it, throws it up when up is held; the next J takes her to it
## (star purification).
func _test_grab_and_purify() -> void:
	_floor(Vector2(0, 0), 3000)
	var luna: Node = await _brave_luna(Vector2(0, -2), true)
	var foe := _fighter("frey", 2, Vector2(luna.global_position.x + 150.0, -2))
	await _frames(10)
	luna.facing = 1
	luna.skill_one()
	var held := false
	for frame in 30:
		await physics_frame
		if luna.grabbed == foe:
			held = true
			break
	if not held:
		_fail("Brave K should grab a fighter 150 px ahead")
		await _clear()
		return
	var hold_x: float = foe.global_position.x
	Input.action_press("move_up")
	await _frames(8)
	if absf(foe.global_position.x - hold_x) > 2.0 or foe.hitstun_timer <= 0.0:
		_fail("A grabbed fighter should be held in place, unable to act")
	for frame in 30:
		await physics_frame
		if luna.grabbed == null:
			break
	await _frames(2)
	Input.action_release("move_up")
	if foe.knockback_velocity.y > -300.0 or absf(foe.knockback_velocity.x) > absf(foe.knockback_velocity.y):
		_fail("Holding up should throw upward (knockback %s)" % [foe.knockback_velocity])
	if float(luna.purify_timer) <= 0.0:
		_fail("A Brave skill hit should open star purification")
	await _frames(50)
	await _wait_ready(luna)
	var distance_before: float = absf(foe.global_position.x - luna.global_position.x) + absf(foe.global_position.y - luna.global_position.y)
	var hits := []
	foe.damaged.connect(func(_v, amount, _att, _src): hits.append(amount))
	luna.perform_basic_attack("neutral", Vector2.RIGHT)
	await _frames(20)
	if hits.is_empty():
		_fail("After a skill hit, J should take Luna to that foe and strike (%.0f px away before)" % distance_before)
	if float(luna.purify_timer) > 0.0:
		_fail("Star purification should be spent by the J")
	await _clear()

## L spins: Rio's wave stops at the cyclone; L again fires it; the fighter it reaches is stunned
## 2 s and then thrown up.
func _test_cyclone() -> void:
	_floor(Vector2(0, 0), 2400)
	var luna: Node = await _brave_luna(Vector2(0, -2), true)
	var rio := _fighter("rio", 2, Vector2(luna.global_position.x + 260.0, -2))
	await _frames(10)
	luna.facing = 1
	luna.skill_two()
	await _frames(12)
	if luna.cyclone_timer <= 0.0 or not is_instance_valid(luna.cyclone):
		_fail("Brave L should start the cyclone spin")
		await _clear()
		return
	var hp_before: float = luna.hp
	rio.facing = -1
	var wave: Node = rio._spawn_projectile(Vector2(24, 54), 6, 300, Vector2.LEFT, Color.WHITE, 640.0, 0.6)
	await _frames(25)
	if is_instance_valid(wave) or luna.hp < hp_before:
		_fail("The cyclone should stop Rio's wave before it reaches Luna")
	if not luna.try_skill_two_followup():
		_fail("L again should fire the cyclone")
	var stunned := false
	for frame in 40:
		await physics_frame
		if float(rio.status_stun_timer) > 1.5:
			stunned = true
			break
	if not stunned:
		_fail("The fired cyclone should stun the fighter it reaches for 2 s")
		await _clear()
		return
	var y_before: float = rio.global_position.y
	await create_timer(2.2).timeout
	var launched := false
	for frame in 20:
		await physics_frame
		if rio.global_position.y < y_before - 30.0:
			launched = true
			break
	if not launched:
		_fail("After the cyclone's stun the fighter should be thrown up")
	await _clear()

## I in Brave: a 3 s beam that keeps its target in hitstun, then blasts it away; Luna is normal again.
func _test_star_beam() -> void:
	_floor(Vector2(0, 0), 4000)
	var luna: Node = await _brave_luna(Vector2(0, -2))
	var foe := _fighter("frey", 2, Vector2(luna.global_position.x + 260.0, -2))
	await _frames(10)
	luna.facing = 1
	if not luna.try_ultimate_followup():
		_fail("I in Brave should fire the star beam")
	await create_timer(1.5).timeout
	if not is_instance_valid(luna.heart_laser) or absf(float(luna.heart_laser.duration) - 3.0) > 0.01:
		_fail("The star beam should last 3 s")
	if foe.hitstun_timer <= 0.0:
		_fail("The beam should keep its target in hitstun")
	var x_mid: float = foe.global_position.x
	await create_timer(1.75).timeout
	await _frames(4)
	if foe.global_position.x <= x_mid:
		_fail("The beam should push its target away")
	if absf(foe.knockback_velocity.x) < 300.0 and foe.global_position.x < x_mid + 80.0:
		_fail("The beam's end should blast the target away (knockback %.0f)" % foe.knockback_velocity.x)
	await _frames(10)
	if luna.transformed:
		_fail("After the star beam Luna should be normal again")
	await _clear()

func _test_bot_beam_retry() -> void:
	var luna := _fighter("luna", 1, Vector2(0, -400))
	luna.set_physics_process(false)
	luna.is_dummy = false
	var ai = luna.ai_controller
	luna._enter_transformation()
	luna.attack_lock_timer = 0.2
	ai.ultimate_followup_timer = 0.05
	for step in 50:
		luna.attack_lock_timer = maxf(float(luna.attack_lock_timer) - 0.016, 0.0)
		ai._update_ultimate_followups(luna, 0.016)
		if bool(luna.transformation_finishing):
			break
	if not bool(luna.transformation_finishing):
		_fail("A Luna bot whose beam press came mid-attack should press again and fire the star beam")
	await _clear()
