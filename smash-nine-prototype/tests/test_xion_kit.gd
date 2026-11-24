extends SceneTree
## Xion's kit (2026-11-18, the user's kit with the lead's review and the user's corrections, "이대로
## 넣기"). Passive 더블 샷건: up to 2x the closer the foe (from the muzzle). J: twin shotguns, ten
## rounds, two shots a second, 3 s reload when empty, a full magazine after 6 s without a shot. K:
## a roll, invulnerable at first, loading two rounds, once per airtime. L: every round fired down,
## she rises; damage follows the rounds; once per airtime. U: a doppelganger that hunts the foe she
## hit last at 200 px/s, pins the first foe it touches for 3 s (full damage, no push), is pushed and
## slowed by foes' hits but never destroyed, lasts 30 s; U again dives to it within 500 px and frees
## the foe. I: shots all round from her and the doppelganger, slow walk, full magazine before and
## after. Also: the shared pin, the skill bar counts, bots, and story mode leaving her out (D43).

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const GAME_SCALE := preload("res://scripts/GameScale.gd")
const BULLET_PATH := "res://characters/xion/XionBullet.gd"
const VFX := preload("res://scripts/Vfx.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	for test in [_test_data_and_art, _test_story_leaves_her_out, _test_shot_rhythm, _test_reload, _test_passive,
			_test_roll, _test_recoil, _test_shared_pin, _test_double_hunts_and_pins, _test_double_pushed,
			_test_double_lifetime, _test_dive, _test_barrage, _test_skill_bar, _test_bots, _test_effect_art]:
		await test.call()
		await _clear()
		if failed:
			quit(1)
			return
	arena.queue_free()
	await process_frame
	print("Xion kit tests passed")
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
	body.position = at + Vector2(0, 20)
	arena.add_child(body)
	return body

## Xion as a person whose keys nobody presses, or a bot body with no AI moves (`bot`).
func _xion(at: Vector2, bot := false) -> Node:
	var xion: Node = PLAYER_FACTORY.create("xion")
	arena.add_child(xion)
	xion.global_position = at
	xion.setup(CHARACTER_REGISTRY.get_characters()["xion"], 1, not bot)
	xion.ringout_y = 100000.0
	xion.ultimate_cooldown_timer = 0.0
	if bot:
		xion.is_dummy = true
	else:
		xion.set_process_unhandled_input(false)
	return xion

func _dummy(player_id: int, at: Vector2, facing: int) -> Node:
	var dummy: Node = PLAYER_FACTORY.create("")
	arena.add_child(dummy)
	dummy.global_position = at
	dummy.setup_dummy(player_id)
	dummy.ringout_y = 100000.0
	dummy.facing = facing
	dummy.invulnerable_timer = 0.0
	return dummy

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

func _seconds(seconds: float) -> void:
	var waited := 0.0
	while waited < seconds:
		await physics_frame
		waited += get_root().get_physics_process_delta_time()

func _clear() -> void:
	for child in arena.get_children():
		child.queue_free()
	await process_frame
	await physics_frame

func _wait_for(condition: Callable, timeout: float) -> bool:
	var waited := 0.0
	while not condition.call() and waited < timeout:
		await physics_frame
		waited += get_root().get_physics_process_delta_time()
	return condition.call()

func _bullets() -> int:
	var count := 0
	for node in arena.get_children():
		if node.get_script() != null and node.get_script().resource_path == BULLET_PATH and not node.is_queued_for_deletion():
			count += 1
	return count

## A J press as soon as she can shoot again.
func _shoot(xion: Node) -> void:
	await _wait_for(func() -> bool: return xion._can_start_attack() and xion.shot_timer <= 0.0, 1.0)
	xion.basic_attack()

func _test_data_and_art() -> void:
	var data: Dictionary = CHARACTER_REGISTRY.get_characters()["xion"]
	if CHARACTER_REGISTRY.get_bodies("xion") != ["female"]:
		_fail("Xion is drawn in the female body only (D22), got %s" % [CHARACTER_REGISTRY.get_bodies("xion")])
	if data.get("story", true) != false:
		_fail("Xion's data must keep her out of story mode")
	var xion := _xion(Vector2(0, -400))
	if not xion.has_skill_three() or xion.max_air_jumps != 1:
		_fail("Xion should have a third skill and one air jump")
	if not xion.uses_original_sheet:
		_fail("Xion should draw her stand-in sheet")
		return
	var frames: SpriteFrames = xion.character_sprite.sprite_frames
	for row in ["xion_idle", "xion_walk", "xion_shot", "xion_shot_alt", "xion_tumble", "xion_recoil_jump", "xion_double_float", "xion_barrage", "xion_victory"]:
		if not frames.has_animation(row):
			_fail("Xion's stand-in art lacks the row " + row)

func _test_story_leaves_her_out() -> void:
	if CHARACTER_REGISTRY.get_story_character_ids().has("xion"):
		_fail("Story mode should not offer Xion yet (D43)")
	if not CHARACTER_REGISTRY.get_character_ids().has("xion"):
		_fail("Battle royale should offer Xion")
	var last: Dictionary = STORY.stage(9)
	if not last.is_empty():
		for wave in STORY.waves_for(last, "frey"):
			for foe in wave:
				if str(foe.get("id", "")) == "xion":
					_fail("Story's last stage should not raise a shadow of Xion")

## Two shots a second at most, one round each, the near foe hit and pushed away.
func _test_shot_rhythm() -> void:
	_floor(Vector2(0, 0), 2400)
	var xion := _xion(Vector2(0, -2))
	var foe := _dummy(10, Vector2(150, -2), -1)
	await _frames(6)
	xion.facing = 1
	xion.basic_attack()
	await _frames(14)
	if xion.ammo != 9:
		_fail("A shot should use one round (ammo %d)" % xion.ammo)
	if foe.hp >= foe.max_hp:
		_fail("A shot should hit a foe 150 px away")
	if foe.knockback_velocity.x <= 0.0:
		_fail("A shot should push the foe away (knockback x %.0f)" % foe.knockback_velocity.x)
	if xion.last_hit_foe != foe:
		_fail("A shot that lands should make that foe the doppelganger's quarry")
	# A press inside the half-second gap does not shoot.
	xion.attack_lock_timer = 0.0
	xion.hitstun_timer = 0.0
	xion.basic_attack()
	await _frames(3)
	if xion.ammo != 9:
		_fail("A press inside the gap should not shoot (ammo %d)" % xion.ammo)
	await _shoot(xion)
	await _frames(8)
	if xion.ammo != 8:
		_fail("The next shot after the gap should fire (ammo %d)" % xion.ammo)
	var far := _dummy(11, Vector2(-330, -2), 1)
	xion.facing = -1
	await _shoot(xion)
	await _frames(10)
	if far.hp < far.max_hp:
		_fail("A shot should not reach 330 px")

func _test_reload() -> void:
	_floor(Vector2(0, 0), 2400)
	var xion := _xion(Vector2(0, -2))
	await _frames(4)
	xion.ammo = 1
	xion.basic_attack()
	await _frames(8)
	if xion.ammo != 0 or not is_equal_approx(snappedf(xion.reload_timer, 0.5), 3.0):
		_fail("The last round should start a 3 s reload (ammo %d, reload %.2f)" % [xion.ammo, xion.reload_timer])
	if xion.skill_cooldown("j").x <= 0.0 or xion.skill_counter("j") != "":
		_fail("While reloading the J slot shows the reload, not a count")
	if not is_instance_valid(xion.reload_ring) or not xion.reload_ring.visible:
		_fail("Reloading should show the ring over her head")
	await _seconds(0.6)
	xion.basic_attack()
	await _frames(4)
	if xion.ammo != 0 or xion.attack_lock_timer > 0.0:
		_fail("An empty press should not shoot")
	await _seconds(2.6)
	if xion.ammo != xion.MAGAZINE or xion.reload_ring.visible:
		_fail("After 3 s the magazine should be full and the ring gone (ammo %d)" % xion.ammo)
	# Six seconds without a shot fill a part-empty magazine.
	xion.ammo = 4
	xion.since_shot = 5.9
	await _seconds(0.2)
	if xion.ammo != xion.MAGAZINE:
		_fail("Six seconds without a shot should fill the magazine (ammo %d)" % xion.ammo)

func _test_passive() -> void:
	_floor(Vector2(0, 0), 2400)
	var xion := _xion(Vector2(0, -2))
	var near := _dummy(10, Vector2(40, -2), -1)
	var mid := _dummy(11, Vector2(155, -2), -1)
	var far := _dummy(12, Vector2(-300, -2), 1)
	await _frames(4)
	if not is_equal_approx(xion.damage_scale_against(near), 2.0):
		_fail("A foe 40 px away should take 2x (got %.2f)" % xion.damage_scale_against(near))
	if absf(xion.damage_scale_against(mid) - 1.5) > 0.02:
		_fail("A foe 155 px away should take 1.5x (got %.2f)" % xion.damage_scale_against(mid))
	if not is_equal_approx(xion.damage_scale_against(far), 1.0):
		_fail("A foe 300 px away should take 1x (got %.2f)" % xion.damage_scale_against(far))
	near.hp = near.max_hp
	near.apply_hit(xion, 10.0, 0.0, Vector2.RIGHT)
	var close_loss: float = near.max_hp - near.hp
	far.hp = far.max_hp
	far.apply_hit(xion, 10.0, 0.0, Vector2.LEFT)
	var far_loss: float = far.max_hp - far.hp
	if absf(close_loss - far_loss * 2.0) > 0.6:
		_fail("Point blank should deal twice the far hit (%.2f vs %.2f)" % [close_loss, far_loss])
	# A bullet measures from its muzzle: fired next to the far foe, it counts as close.
	far.hp = far.max_hp
	xion.hit_from(far.global_position + GAME_SCALE.BODY_CENTRE + Vector2(20, 0), far, 10.0, 0.0, Vector2.LEFT, "normal")
	if absf((far.max_hp - far.hp) - close_loss) > 0.6:
		_fail("A hit from a muzzle beside the foe should count as point blank (%.2f vs %.2f)" % [far.max_hp - far.hp, close_loss])

func _test_roll() -> void:
	_floor(Vector2(0, 0), 2400)
	var xion := _xion(Vector2(0, -2))
	await _frames(4)
	xion.facing = 1
	xion.ammo = 5
	var start: float = xion.global_position.x
	xion.skill_one()
	await _frames(3)
	if not xion.is_invulnerable():
		_fail("The roll should start invulnerable")
	if xion.ammo != 7:
		_fail("The roll should load two rounds (ammo %d)" % xion.ammo)
	await _seconds(0.45)
	if xion.is_invulnerable():
		_fail("The roll's invulnerability should end after 0.2 s")
	var moved: float = xion.global_position.x - start
	if absf(moved - xion.ROLL_DISTANCE) > 30.0:
		_fail("The roll should cover about %.0f px (moved %.0f)" % [xion.ROLL_DISTANCE, moved])
	var cooldown: Vector2 = xion.skill_cooldown("k")
	if not is_equal_approx(cooldown.y, xion.ROLL_COOLDOWN) or cooldown.x <= 0.0:
		_fail("The K slot should show the roll cooldown (%s)" % cooldown)
	xion.ammo = 9
	xion.roll_cooldown_timer = 0.0
	xion.skill_one()
	if xion.ammo != xion.MAGAZINE:
		_fail("Loading should stop at ten rounds (ammo %d)" % xion.ammo)
	# In the air: once before landing.
	var flyer := _xion(Vector2(400, -600))
	await _frames(2)
	flyer.skill_one()
	await _seconds(0.4)
	flyer.roll_cooldown_timer = 0.0
	var air_before: float = flyer.global_position.x
	flyer.skill_one()
	await _frames(4)
	if flyer.roll_invulnerable_timer > 0.0 or absf(flyer.global_position.x - air_before) > 6.0:
		_fail("A second air roll before landing should do nothing")

func _test_recoil() -> void:
	_floor(Vector2(0, 0), 2400)
	var xion := _xion(Vector2(0, -2))
	var foe := _dummy(10, Vector2(30, -2), -1)
	await _frames(4)
	xion.ammo = 6
	var start_y: float = xion.global_position.y
	xion.skill_two()
	await _frames(10)
	if xion.ammo != 0 or xion.reload_timer <= 0.0:
		_fail("L should fire every round and start the reload (ammo %d)" % xion.ammo)
	if xion.global_position.y > start_y - 30.0:
		_fail("L should lift her (rose %.0f px)" % (start_y - xion.global_position.y))
	var loss: float = foe.max_hp - foe.hp
	var expected: float = foe._calculate_incoming_damage(xion, xion.RECOIL_DAMAGE_PER_ROUND * 6.0, "normal")
	if loss <= 0.0 or absf(loss - expected) > 1.5:
		_fail("L's blast should deal 2 per round to a foe at her feet (lost %.1f, expected about %.1f)" % [loss, expected])
	# Once per airtime, and nothing without rounds.
	xion.ammo = 3
	xion.attack_lock_timer = 0.0
	xion.skill_two()
	await _frames(6)
	if xion.ammo != 3:
		_fail("A second L before landing should do nothing")
	await _wait_for(func() -> bool: return xion.is_on_floor() and xion.velocity.y >= 0.0, 3.0)
	await _frames(2)
	xion.ammo = 0
	xion.reload_timer = 2.0
	xion.attack_lock_timer = 0.0
	var ground_y: float = xion.global_position.y
	xion.skill_two()
	await _frames(8)
	if xion.global_position.y < ground_y - 4.0:
		_fail("L with no rounds should not lift her")

## The shared pin (PlayerBase.apply_pin_hold): still, unable to act, hits land in full and push
## nothing, no grab on top, and it ends early on release.
func _test_shared_pin() -> void:
	_floor(Vector2(0, 0), 2400)
	var holder := _xion(Vector2(-200, -2))
	var foe := _dummy(10, Vector2(0, -2), 1)
	await _frames(4)
	if not foe.apply_pin_hold(holder, 3.0) or not foe.is_pinned():
		_fail("A foe should take the pin")
		return
	var spot: Vector2 = foe.global_position
	foe.hp = foe.max_hp
	foe.apply_hit(holder, 10.0, 500.0, Vector2.RIGHT)
	await _frames(10)
	if foe.hp >= foe.max_hp:
		_fail("A pinned foe should still take damage")
	if foe.global_position.distance_to(spot) > 1.0 or foe.knockback_velocity.length() > 0.1:
		_fail("A pinned foe should not be pushed (moved %.1f)" % foe.global_position.distance_to(spot))
	if foe.hitstun_timer <= 0.0 or foe._can_start_attack():
		_fail("A pinned foe should not act")
	if foe.apply_grab_hold(holder, spot, 0.3):
		_fail("A pinned foe should not be grabbed on top of the pin")
	if foe.apply_pin_hold(holder, 3.0):
		_fail("A pinned foe should not be pinned twice")
	foe.release_pin_hold()
	if foe.is_pinned() or foe.hitstun_timer > 0.0:
		_fail("Releasing the pin should free the foe at once")

func _test_double_hunts_and_pins() -> void:
	_floor(Vector2(0, 0), 2400)
	var xion := _xion(Vector2(0, -2))
	var foe := _dummy(10, Vector2(260, -2), -1)
	await _frames(4)
	xion.last_hit_foe = foe
	xion.skill_three()
	if not is_instance_valid(xion.double):
		_fail("U should leave a doppelganger")
		return
	var double: Node2D = xion.double
	await _frames(2)
	var from: Vector2 = double.global_position
	await _seconds(0.5)
	var travelled: float = double.global_position.distance_to(from)
	if absf(travelled - 100.0) > 20.0:
		_fail("The doppelganger should move at 200 px/s (0.5 s: %.0f px)" % travelled)
	if double.global_position.x <= from.x:
		_fail("The doppelganger should head for the foe she hit last")
	xion.skill_three()
	if xion.double != double:
		_fail("A second U should not make a second doppelganger")
	if not await _wait_for(func() -> bool: return foe.is_pinned(), 2.0):
		_fail("The doppelganger should pin the foe it reaches")
		return
	await _frames(2)
	if absf(double.global_position.y - (foe.global_position.y - double.HEAD_SEAT)) > 2.0 or absf(double.global_position.x - foe.global_position.x) > 2.0:
		_fail("Pinning, the doppelganger should sit on the foe's head")
	# Hit all through the pin (as under the barrage): the foe's hitstops pause its own pin timer,
	# yet the pin ends with the doppelganger's 3 s.
	var hitter := _dummy(11, Vector2(-300, -2), 1)
	var held := 0.0
	while held < 3.1:
		foe.apply_hit(hitter, 0.5, 100.0, Vector2.RIGHT)
		await physics_frame
		held += get_root().get_physics_process_delta_time()
	await _frames(2)
	if foe.is_pinned() or is_instance_valid(xion.double):
		_fail("After 3 s the pin should end and the doppelganger be gone, even under fire (pin left %.2f)" % foe.pin_hold_timer)
	var cooldown: Vector2 = xion.skill_cooldown("u")
	if not is_equal_approx(cooldown.y, xion.DOUBLE_COOLDOWN) or cooldown.x <= 0.0:
		_fail("Its going should start the U cooldown (%s)" % cooldown)

## A foe's hit pushes and slows it; her own attacks, monsters and her bullets pass; pinning, nothing
## moves it; nothing destroys it.
func _test_double_pushed() -> void:
	_floor(Vector2(0, 0), 2400)
	var xion := _xion(Vector2(0, -2))
	var foe := _dummy(10, Vector2(-900, -2), 1)
	await _frames(4)
	# It hunts the far foe, so it keeps moving while it is measured.
	xion.last_hit_foe = foe
	xion.skill_three()
	var double: Node2D = xion.double
	await _frames(2)
	var spot: Vector2 = double.global_position
	double.apply_hit(xion, 10.0, 400.0, Vector2.RIGHT)
	var monster := Node2D.new()
	arena.add_child(monster)
	double.apply_hit(monster, 10.0, 400.0, Vector2.RIGHT)
	double.apply_hit(null, 10.0, 400.0, Vector2.RIGHT)
	if double.push.length() > 0.1 or double.slow_timer > 0.0:
		_fail("Her own hits, monsters and hazards should not touch the doppelganger")
	var bullet_count := _bullets()
	xion._fire_bullet(double.global_position + Vector2(-30, -32), Vector2.RIGHT)
	var bullet: Node = arena.get_child(arena.get_child_count() - 1)
	bullet._on_body_entered(double)
	if bullet.is_queued_for_deletion() or _bullets() != bullet_count + 1:
		_fail("Her own bullet should pass through the doppelganger")
	double.apply_hit(foe, 8.0, 300.0, Vector2.RIGHT)
	await _frames(12)
	if double.global_position.x < spot.x + 20.0 or double.slow_timer <= 0.0:
		_fail("A foe's hit should push the doppelganger away and slow it (moved %.0f, slow %.2f)" % [double.global_position.x - spot.x, double.slow_timer])
	if double.gone or not is_instance_valid(double):
		_fail("A foe's hit should not destroy the doppelganger")
	await _seconds(0.5)
	var slow_from: Vector2 = double.global_position
	await _seconds(0.5)
	var slow_step: float = double.global_position.distance_to(slow_from)
	if absf(slow_step - 50.0) > 15.0:
		_fail("Slowed, the doppelganger should move at half speed (0.5 s: %.0f px)" % slow_step)
	# Pinning: a foe's hit moves nothing.
	var other := _dummy(11, double.global_position + Vector2(0, 32), 1)
	if not await _wait_for(func() -> bool: return other.is_pinned(), 1.0):
		_fail("The doppelganger should pin a foe it touches")
		return
	await _frames(1)
	var seat: Vector2 = double.global_position
	double.apply_hit(foe, 8.0, 600.0, Vector2.LEFT)
	await _frames(6)
	if double.global_position.distance_to(seat) > 2.0 or not other.is_pinned():
		_fail("Pinning, the doppelganger should not be pushed and the pin should hold")

func _test_double_lifetime() -> void:
	_floor(Vector2(0, 0), 2400)
	var xion := _xion(Vector2(0, -2))
	await _frames(4)
	xion.skill_three()
	var double: Node2D = xion.double
	if not is_equal_approx(double.lifetime, 30.0):
		_fail("The doppelganger should last 30 s (got %.1f)" % double.lifetime)
	double.elapsed = 29.95
	await _frames(8)
	if is_instance_valid(xion.double) or not double.gone:
		_fail("After 30 s the doppelganger should be gone")
	if xion.skill_cooldown("u").x <= 0.0:
		_fail("Its going should start the cooldown")

func _test_dive() -> void:
	_floor(Vector2(0, 0), 2400)
	var xion := _xion(Vector2(0, -2))
	var foe := _dummy(10, Vector2(300, -2), -1)
	await _frames(4)
	xion.last_hit_foe = foe
	xion.skill_three()
	if not await _wait_for(func() -> bool: return foe.is_pinned(), 3.0):
		_fail("The doppelganger should pin the foe")
		return
	await _frames(2)
	var seat: Vector2 = xion.double.global_position
	if xion.skill_counter("u") != "!":
		_fail("The U slot should show that she can dive")
	if not xion.try_skill_three_followup():
		_fail("U again should be taken while the doppelganger pins")
	await _frames(int(ceil(xion.DIVE_TIME * 60.0)) + 1)
	if xion.global_position.distance_to(seat) > 24.0:
		_fail("The dive should bring her to the doppelganger on the foe's head (%.0f px off)" % xion.global_position.distance_to(seat))
	if foe.is_pinned() or is_instance_valid(xion.double):
		_fail("Arriving should spend the doppelganger and free the foe")
	if xion.collision_mask == 0:
		_fail("After the dive she should be solid again")
	# Too far: U again does nothing.
	await _clear()
	_floor(Vector2(0, 0), 3000)
	var far_xion := _xion(Vector2(-700, -2))
	var far_foe := _dummy(10, Vector2(0, -2), -1)
	await _frames(4)
	far_xion.skill_three()
	far_xion.double.global_position = far_foe.global_position + Vector2(-10, 0)
	if not await _wait_for(func() -> bool: return far_foe.is_pinned(), 1.0):
		_fail("The doppelganger should pin the far foe")
		return
	far_xion.try_skill_three_followup()
	await _frames(14)
	if far_xion.global_position.x > -650.0 or not far_foe.is_pinned():
		_fail("Beyond 500 px U again should do nothing")

func _test_barrage() -> void:
	_floor(Vector2(0, 0), 2400)
	var xion := _xion(Vector2(0, -2))
	var foe := _dummy(10, Vector2(140, -2), -1)
	var behind := _dummy(11, Vector2(-140, -2), 1)
	await _frames(4)
	xion.skill_three()
	await _wait_for(func() -> bool: return xion._can_start_attack(), 1.0)
	xion.ammo = 2
	xion.ultimate()
	if xion.ammo != xion.MAGAZINE or not xion.is_barraging():
		_fail("I should fill the magazine and start the barrage")
	await _frames(6)
	var mobility: float = xion.get_character_movement_multiplier() * xion.ATTACK_GROUND_MOBILITY
	if absf(mobility - xion.BARRAGE_MOVE) > 0.01:
		_fail("During the barrage she should walk at 40%% (got %.2f)" % mobility)
	var from_her := 0
	var from_double := 0
	for node in arena.get_children():
		if node.get_script() == null or node.get_script().resource_path != BULLET_PATH or node.is_queued_for_deletion():
			continue
		if node.muzzle.distance_to(xion.global_position + GAME_SCALE.BODY_CENTRE) < 12.0:
			from_her += 1
		elif is_instance_valid(xion.double) and node.muzzle.distance_to(xion.double.global_position + GAME_SCALE.BODY_CENTRE) < 12.0:
			from_double += 1
	if from_her == 0 or from_double == 0:
		_fail("The barrage should fire from her and from the doppelganger (%d, %d)" % [from_her, from_double])
	await _seconds(1.0)
	if foe.hp >= foe.max_hp or behind.hp >= behind.max_hp:
		_fail("The barrage should hit foes on both sides")
	xion.ammo = 3
	await _seconds(1.7)
	if xion.is_barraging() or xion.ammo != xion.MAGAZINE:
		_fail("After 2.5 s the barrage should end with a full magazine (ammo %d)" % xion.ammo)

func _test_skill_bar() -> void:
	_floor(Vector2(0, 0), 2400)
	var xion := _xion(Vector2(0, -2))
	await _frames(4)
	if xion.skill_counter("j") != "10" or xion.skill_counter("k") != "":
		_fail("The J slot should show ten rounds (got '%s')" % xion.skill_counter("j"))
	xion.ammo = 7
	if xion.skill_counter("j") != "7":
		_fail("The J slot should follow the rounds")
	xion.skill_three()
	await _frames(2)
	if xion.skill_counter("u") != "30":
		_fail("The U slot should count the doppelganger's seconds (got '%s')" % xion.skill_counter("u"))
	var other := _dummy(10, Vector2(0, -400), 1)
	if other.skill_counter("j") != "":
		_fail("Other fighters show no count")

func _test_bots() -> void:
	_floor(Vector2(0, 0), 2400)
	var bot := _xion(Vector2(0, -2), true)
	var foe := _dummy(10, Vector2(220, -2), -1)
	await _frames(4)
	bot._bot_double(0.016)
	if is_instance_valid(bot.double):
		_fail("A bot should not leave the doppelganger before it has hit anyone")
	bot.last_hit_foe = foe
	bot._bot_double(0.016)
	if not is_instance_valid(bot.double):
		_fail("A bot should leave the doppelganger once it has hit a foe")
		return
	if not await _wait_for(func() -> bool: return foe.is_pinned(), 3.0):
		_fail("The bot's doppelganger should pin the foe")
		return
	for step in 30:
		bot._bot_double(0.016)
		await physics_frame
		if bot.dive_timer > 0.0 or not is_instance_valid(bot.double):
			break
	if bot.dive_timer <= 0.0 and is_instance_valid(bot.double):
		_fail("A bot should dive to its doppelganger once it pins a foe near it")
	# The recovery move: L with rounds, K in the air to load first.
	var flyer := _xion(Vector2(600, -500), true)
	await _frames(2)
	if flyer.recovery_attack() != "skill_2":
		_fail("With rounds a bot recovers with L (got '%s')" % flyer.recovery_attack())
	flyer.ammo = 0
	flyer.reload_timer = 3.0
	if flyer.recovery_attack() != "skill_1":
		_fail("Out of rounds in the air a bot rolls first to load (got '%s')" % flyer.recovery_attack())

## A strip of `count` plain frames, as Vfx builds one ("play").
func _fake_strip(count: int, loop: bool) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"play")
	frames.set_animation_loop(&"play", loop)
	frames.set_animation_speed(&"play", 30.0)
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 0, 0, 1))
	var texture := ImageTexture.create_from_image(image)
	for index in count:
		frames.add_frame(&"play", texture)
	return frames

func _named(node_name: String) -> int:
	var count := 0
	for node in arena.get_children():
		if node.name.begins_with(node_name) and not node.is_queued_for_deletion():
			count += 1
	return count

## Her effects draw the picked strips once they are in the folders (CODEX-VFX-10 contract), and her code
## stand-ins until then: the blast, the tracer and the reload mark.
func _test_effect_art() -> void:
	_floor(Vector2(0, 0), 2400)
	var xion := _xion(Vector2(0, -2))
	await _frames(4)
	xion.facing = 1
	xion.basic_attack()
	await _frames(6)
	if _named("Vfx_xion_blast") != 0:
		_fail("Without the picked blast the code pellets should draw")
	VFX._cache["xion_blast/false"] = _fake_strip(6, false)
	await _shoot(xion)
	await _frames(6)
	if _named("Vfx_xion_blast") != 1:
		_fail("With the blast strip in place the shot should draw it")
	VFX._cache.erase("xion_blast/false")
	VFX._cache["xion_bullet/true"] = _fake_strip(2, true)
	xion._fire_bullet(xion.global_position + Vector2(0, -32), Vector2.UP)
	var bullet: Node = arena.get_child(arena.get_child_count() - 1)
	if bullet.get_node_or_null("Vfx_xion_bullet") == null or bullet.get_node("Visual").visible:
		_fail("With the tracer strip in place a barrage shot should draw it instead of the rectangle")
	VFX._cache.erase("xion_bullet/true")
	# Let her last blast end first: a fighter added to the tree stands at the origin for a moment.
	await _frames(12)
	var strip := Image.create(192, 24, false, Image.FORMAT_RGBA8)
	var other := _xion(Vector2(300, -2))
	other.reload_art_override = ImageTexture.create_from_image(strip)
	await _frames(4)
	other.ammo = 1
	other.basic_attack()
	await _frames(8)
	if not is_instance_valid(other.reload_art):
		_fail("With a reload strip the mark over her head should draw it (ammo %d, reload %.2f, ring %s)" % [other.ammo, other.reload_timer, is_instance_valid(other.reload_ring)])
		return
	await _seconds(1.6)
	var region: Rect2 = (other.reload_art.texture as AtlasTexture).region
	if region.size.x != 24.0 or region.position.x < 48.0 or region.position.x > 96.0:
		_fail("Half way through the reload the mark should show a middle frame (region %s)" % region)
