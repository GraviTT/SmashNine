extends SceneTree
## pixelfx motion effects (user 2026-11-04: "현재 테스트로 만든 것들 전부 게임에 넣어볼 것"): Luna's idle
## stars loop over her while she idles (normal form only) and turn with her; a landing from a jump
## scatters her stardust, never the grey dust: the clear one after a big fall, the small one after a
## small one (user 2026-11-04), and a tiny drop shows nothing; Frey kicks up dust on the walk drawings
## where a foot lands, only while she runs, behind her in either direction, each puff over one step;
## each J cut draws its own sparks with the slash. The Frey pilot picks (2026-11-04, D49): her up, down
## and air J draw their follow-through (ground and air versions apart), and each melee hit that lands,
## on a fighter or a monster, leaves exactly one afterglow on the struck body (the big one for a strong
## hit), none on a miss. The pick cup round 2026-11-19 winners (D49): Frey's and normal Luna's take-off
## art at the feet (air jumps their own), turned their way, none for Brave Luna; Frey's landing art, big
## after a big fall, turned her way, never the grey dust; normal Luna's step flash on her front foot, over
## one step; the J star's launch flash and the looping tail riding the star, turned to the aim; one
## afterglow per landed star (big for the big star, none from its burst, none on a miss); Brave Luna's
## follow-through for each of her J moves and her melee hit afterglow (big from knockback 400).
## Presentation only: nothing in the plain style (F2).

const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const MONSTER_SCRIPT := preload("res://scripts/RealmMonster.gd")
const STAR_SCRIPT := preload("res://characters/luna/LunaStar.gd")
## Brave Luna's J moves: [method, arguments, follow-through strip].
const BRAVE_MOVES := [
	["_brave_jab", [], "brave_rush_1"], ["_brave_body_kick", [], "brave_rush_2"], ["_brave_spin_kick", [], "brave_rush_3"],
	["_brave_uppercut", [false], "brave_up"], ["_brave_uppercut", [true], "brave_up"], ["_brave_low_sweep", [], "brave_low"],
	["_brave_flying_kick", [], "brave_side_air"], ["_brave_dive_kick", [], "brave_down_air"],
]

var arena: Node2D
var failed := false
## The Vfx strips of the sprites added to the arena, in order ("" for other nodes).
var spawned: Array[String] = []
## The running Frey, and each of her step dusts seen from her feet: [x, y, scale.x], and how long
## each one plays (seconds).
var runner: Node
var steps: Array[Vector3] = []
var step_spans: Array[float] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	ART_SETTINGS.style = ART_SETTINGS.STYLE_ORIGINAL
	arena = Node2D.new()
	root.add_child(arena)
	arena.child_entered_tree.connect(_on_spawned)
	_floor(Vector2.ZERO, 6000.0)
	await _test_luna_idle_stars()
	await _test_luna_landing()
	await _test_frey_step_dust()
	await _test_frey_slash_sparks()
	await _test_frey_follow_through()
	await _test_frey_hit_afterglow()
	await _test_jump_art()
	await _test_luna_steps()
	await _test_luna_star_flight()
	await _test_luna_star_afterglow()
	await _test_brave_follow_through()
	await _test_brave_hit_afterglow()
	await _test_plain_style()
	arena.queue_free()
	await process_frame
	ART_SETTINGS.style = ART_SETTINGS.DEFAULT_STYLE
	_release_all()
	if failed:
		quit(1)
		return
	print("Motion FX tests passed")
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
	fighter.is_dummy = not human
	if human:
		fighter.set_process_unhandled_input(false)
	return fighter

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

## The Vfx strip a sprite plays, or "". A second sprite of the same effect gets a generated name
## (@AnimatedSprite2D@N), so the name cannot tell.
func _effect_of(node: Node) -> String:
	var sprite := node as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(&"play"):
		return ""
	var frame := sprite.sprite_frames.get_frame_texture(&"play", 0) as AtlasTexture
	return frame.atlas.resource_path.get_file().get_basename() if frame != null and frame.atlas != null else ""

func _on_spawned(node: Node) -> void:
	spawned.append(_effect_of(node))
	if spawned[-1] in ["frey_step_dust", "luna_step"]:
		_note_step.call_deferred(node)

## Read once Vfx.spawn has placed the dust (it sets the position after adding the node).
func _note_step(node: Node) -> void:
	if is_instance_valid(node) and is_instance_valid(runner):
		var offset: Vector2 = node.global_position - runner.global_position
		steps.append(Vector3(offset.x, offset.y, node.scale.x))
		var sprite := node as AnimatedSprite2D
		step_spans.append(sprite.sprite_frames.get_frame_count(&"play") / (sprite.sprite_frames.get_animation_speed(&"play") * sprite.speed_scale))

func _count(effect: String) -> int:
	return spawned.count(effect)

func _release_all() -> void:
	for action in ["jump", "move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)

func _remove(fighter: Node) -> void:
	fighter.queue_free()
	await process_frame

func _test_luna_idle_stars() -> void:
	var luna: Node = _fighter("luna", 1, Vector2(0, -1))
	# The one-pixel drop plays the land row (2 drawings at 12 fps) first.
	await _frames(20)
	if luna.character_sprite.animation != &"luna_idle":
		_fail("Test setup: Luna should idle on the floor (plays %s)" % luna.character_sprite.animation)
	var stars: AnimatedSprite2D = luna.motion_overlay
	if stars == null or stars.get_parent() != luna or _effect_of(stars) != "luna_idle_stars" or not stars.is_playing():
		_fail("Idle Luna should loop her stars over her body (found %s)" % stars)
		await _remove(luna)
		return
	if stars.position != Vector2.ZERO or stars.scale.x <= 0.0:
		_fail("The idle stars should sit on her feet and face right with her (at %s, scale %s)" % [stars.position, stars.scale])
	luna.facing = -1
	await _frames(1)
	if luna.motion_overlay == null or luna.motion_overlay.scale.x >= 0.0:
		_fail("The idle stars should turn with her")
	# Any other motion ends them at once, before the next physics update.
	luna.character_sprite.play(&"luna_walk")
	if luna.motion_overlay != null or not stars.is_queued_for_deletion():
		_fail("The idle stars should stop when she leaves the idle")
	await _frames(2)
	if luna.motion_overlay == null:
		_fail("The idle stars should come back when she idles again")
	luna.transformed = true
	luna._update_character_sprite(true)
	if luna.character_sprite.animation != &"luna_brave_idle" or luna.motion_overlay != null:
		_fail("Brave Luna's idle has no stars (they sit on normal Luna's outline; plays %s)" % luna.character_sprite.animation)
	luna.transformed = false
	if _count("luna_land_stardust") != 0 or _count("luna_land_stardust_small") != 0:
		_fail("A one-pixel drop onto the floor should not scatter stardust")
	await _remove(luna)

func _test_luna_landing() -> void:
	spawned.clear()
	var luna: Node = _fighter("luna", 2, Vector2(400, -220))
	for frame in 120:
		await physics_frame
		if luna.is_on_floor():
			break
	if not luna.is_on_floor():
		_fail("Test setup: Luna should land")
	await _frames(2)
	if _count("luna_land_stardust") != 1 or _count("luna_land_stardust_small") != 0 or _count("landing_dust") != 0:
		_fail("Luna's landing from a big fall should scatter the clear stardust once, nothing else (%s)" % [spawned])
	# A landing that ends an action shows her stardust in place of the grey dust too.
	spawned.clear()
	luna._spawn_landing_puff()
	if _count("luna_land_stardust") != 1 or _count("landing_dust") != 0:
		_fail("Luna's action landing should show stardust, not the grey dust (%s)" % [spawned])
	await _remove(luna)
	# A small fall (a tapped jump falls 50-110 px) shows the small stardust.
	spawned.clear()
	luna = _fighter("luna", 2, Vector2(600, -70))
	for frame in 120:
		await physics_frame
		if luna.is_on_floor():
			break
	await _frames(2)
	if _count("luna_land_stardust_small") != 1 or _count("luna_land_stardust") != 0 or absf(luna.landing_drop - 69.0) > 2.0:
		_fail("Luna's landing from a small fall should scatter the small stardust (drop %s, %s)" % [luna.landing_drop, spawned])
	await _remove(luna)
	# Frey's own landing art (pick cup 2026-11-19): the big one after a big fall, at her feet and turned her
	# way, never the grey dust; the small one after a small fall.
	for fall in [[-220.0, "frey_land_big", "frey_land"], [-70.0, "frey_land", "frey_land_big"]]:
		spawned.clear()
		var frey: Node = _fighter("frey", 3, Vector2(800, fall[0]))
		frey.facing = -1
		for frame in 120:
			await physics_frame
			if frey.is_on_floor():
				break
		await _frames(2)
		var land := _live(fall[1])
		if _count(fall[1]) != 1 or _count(fall[2]) != 0 or _count("landing_dust") != 0 or _count("luna_land_stardust") != 0 or land == null:
			_fail("Frey's landing from %d px should show %s once, nothing else (%s)" % [-fall[0], fall[1], spawned])
		elif land.scale.x >= 0.0 or land.global_position.distance_to(frey.global_position) > 0.5:
			_fail("Frey's landing art belongs at her feet, turned her way (at %s, feet %s, scale %s)" % [land.global_position, frey.global_position, land.scale])
		await _remove(frey)

func _test_frey_step_dust() -> void:
	runner = _fighter("frey", 4, Vector2(-1200, -1), true)
	await _frames(20)
	steps.clear()
	await _frames(30)
	if not steps.is_empty():
		_fail("Frey standing still should not kick up dust")
	# The dust sits on the front foot of the drawing (18 or 21 px ahead of her feet) and trails
	# behind her: drawn facing her way.
	var step_time: float = 4.0 / runner.character_sprite.sprite_frames.get_animation_speed(&"frey_walk")
	for side in [1, -1]:
		steps.clear()
		step_spans.clear()
		var action := "move_right" if side > 0 else "move_left"
		Input.action_press(action)
		await _frames(80)
		Input.action_release(action)
		await process_frame
		if steps.size() < 2:
			_fail("Running Frey should kick up dust on her steps (%d, side %d)" % [steps.size(), side])
		for step in steps:
			var on_foot := is_equal_approx(step.x, 18.0 * side) or is_equal_approx(step.x, 21.0 * side)
			if not on_foot or absf(step.y) > 0.01 or signf(step.z) != float(side):
				_fail("Step dust on her front foot, drawn her way (from the feet %s, scale %s, side %d)" % [Vector2(step.x, step.y), step.z, side])
				break
		# Each puff plays out within the step it marks (4 walk drawings), not over two.
		for span in step_spans:
			if absf(span - step_time) > step_time * 0.01:
				_fail("A step dust should last one step (%.3f s, step %.3f s)" % [span, step_time])
				break
		await _frames(30)
	await _remove(runner)

func _test_frey_slash_sparks() -> void:
	var frey: Node = _fighter("frey", 5, Vector2(1600, -1))
	await _frames(20)
	for cut in [1, 2, 3]:
		spawned.clear()
		frey.call("_combo_slash_%s" % ["one", "two", "three"][cut - 1])
		var sparks: Node = null
		for node in arena.get_children():
			if _effect_of(node) == "frey_slash_sparks_%d" % cut and not node.is_queued_for_deletion():
				sparks = node
		if _count("frey_slash") != 1 or sparks == null:
			_fail("J cut %d should draw frey_slash and its sparks (%s)" % [cut, spawned])
			continue
		if sparks.global_position != frey.global_position + Vector2(0, -32) or sparks.scale.x != float(frey.facing):
			_fail("J cut %d sparks belong on her body centre, facing her way (at %s, Frey %s)" % [cut, sparks.global_position, frey.global_position])
		await _frames(30)
	frey.facing = -1
	spawned.clear()
	frey._combo_slash_one()
	var mirrored := arena.get_children().filter(func(node: Node) -> bool: return _effect_of(node) == "frey_slash_sparks_1" and not node.is_queued_for_deletion() and node.scale.x < 0.0)
	if mirrored.is_empty():
		_fail("Facing left, the J sparks should be mirrored")
	await _remove(frey)

## The newest live sprite playing that strip in the arena, or null.
func _live(effect: String) -> Node2D:
	var found: Node2D = null
	for node in arena.get_children():
		if _effect_of(node) == effect and not node.is_queued_for_deletion():
			found = node
	return found

func _test_frey_follow_through() -> void:
	var frey: Node = _fighter("frey", 8, Vector2(2400, -1))
	await _frames(20)
	for step in [["_up_slash", "frey_jfx_up"], ["_down_cut", "frey_jfx_down"]]:
		spawned.clear()
		frey.call(step[0])
		var strip := _live(step[1])
		if strip == null or _count("frey_slash") != 1:
			_fail("On the ground %s should draw frey_slash and %s (%s)" % [step[0], step[1], spawned])
		elif strip.global_position != frey.global_position + Vector2(0, -32) or strip.scale.x != float(frey.facing):
			_fail("%s belongs on her body centre, facing her way (at %s, Frey %s)" % [step[1], strip.global_position, frey.global_position])
		await _frames(30)
	# Nothing under her: the air versions.
	frey.global_position = Vector2(2400, -900)
	frey.velocity = Vector2.ZERO
	await _frames(2)
	for step in [["_up_slash", "frey_jfx_up_air"], ["_down_cut", "frey_jfx_down_air"], ["_air_slash", "frey_jfx_side_air"]]:
		spawned.clear()
		frey.call(step[0])
		if _count(step[1]) != 1 or _count("frey_jfx_up") + _count("frey_jfx_down") != 0:
			_fail("In the air %s should draw %s only (%s)" % [step[0], step[1], spawned])
	await _remove(frey)

func _test_frey_hit_afterglow() -> void:
	var frey: Node = _fighter("frey", 9, Vector2(-2600, -1))
	var foe: Node = _fighter("rio", 10, Vector2(-2540, -1))
	await _frames(20)
	frey.facing = 1
	spawned.clear()
	var centre: Vector2 = foe.global_position + Vector2(0, -34)
	frey._combo_slash_one()
	await _frames(6)
	var glow := _live("frey_hit_after")
	if _count("frey_hit_after") != 1 or _count("frey_hit_after_big") != 0 or glow == null:
		_fail("A J hit on a fighter should leave exactly one afterglow (%s)" % [spawned])
	elif glow.global_position.distance_to(centre) > 6.0 or glow.scale.x != 1.0:
		_fail("The afterglow belongs on the struck body's centre, facing Frey's way (at %s, centre %s)" % [glow.global_position, centre])
	# A miss leaves none.
	foe.global_position = Vector2(-1900, -1)
	await _frames(2)
	spawned.clear()
	frey._combo_slash_two()
	await _frames(6)
	if _count("frey_hit_after") + _count("frey_hit_after_big") != 0:
		_fail("A miss should leave no afterglow (%s)" % [spawned])
	# The finisher (knockback 430) leaves the big one.
	foe.global_position = frey.global_position + Vector2(60, 0)
	foe.velocity = Vector2.ZERO
	await _frames(20)
	spawned.clear()
	frey._combo_slash_three()
	await _frames(6)
	if _count("frey_hit_after_big") != 1 or _count("frey_hit_after") != 0:
		_fail("The finisher should leave exactly one big afterglow (%s)" % [spawned])
	await _remove(foe)
	# A monster gets one too, on its drawing's centre.
	var monster := CharacterBody2D.new()
	monster.set_script(MONSTER_SCRIPT)
	monster.setup("ember_imp", 0, frey.global_position + Vector2(70, -2))
	arena.add_child(monster)
	monster.global_position = frey.global_position + Vector2(70, -2)
	await _frames(4)
	spawned.clear()
	var art: Node2D = monster.art_sprite
	var art_centre: Vector2 = art.global_position if art != null else Vector2.ZERO
	frey._combo_slash_one()
	await _frames(6)
	glow = _live("frey_hit_after")
	if _count("frey_hit_after") != 1 or glow == null:
		_fail("A J hit on a monster should leave exactly one afterglow (%s)" % [spawned])
	elif art != null and glow.global_position.distance_to(art_centre) > 8.0:
		_fail("The monster's afterglow belongs on its drawing's centre (at %s, centre %s)" % [glow.global_position, art_centre])
	monster.queue_free()
	await _remove(frey)

## Take-off art (pick cup 2026-11-19): a jump from the floor flashes once where the feet left it, an air jump
## its own art where she is, both turned her way; Brave Luna has none.
func _test_jump_art() -> void:
	for id in ["frey", "luna"]:
		var fighter: Node = _fighter(id, 11, Vector2(1000, -1))
		await _frames(20)
		for side in [1, -1]:
			fighter.facing = side
			spawned.clear()
			var feet: Vector2 = fighter.global_position
			fighter.jump_buffer_timer = 0.1
			await _frames(1)
			var flash := _live("%s_jump" % id)
			if _count("%s_jump" % id) != 1 or _count("%s_air_jump" % id) != 0 or flash == null:
				_fail("%s's jump should flash its take-off art once (%s)" % [id, spawned])
			elif flash.global_position.distance_to(feet) > 0.5 or signf(flash.scale.x) != float(side):
				_fail("%s's take-off art belongs where her feet left the floor, turned her way (at %s, feet %s, scale %s)" % [id, flash.global_position, feet, flash.scale])
			# Past the coyote time: the air jump.
			await _frames(14)
			spawned.clear()
			var air_feet: Vector2 = fighter.global_position
			fighter.jump_buffer_timer = 0.1
			await _frames(1)
			var air := _live("%s_air_jump" % id)
			if _count("%s_air_jump" % id) != 1 or _count("%s_jump" % id) != 0 or air == null:
				_fail("%s's air jump should flash its own art once (%s)" % [id, spawned])
			elif air.global_position.distance_to(air_feet) > 0.5 or signf(air.scale.x) != float(side):
				_fail("%s's air-jump art belongs at her feet in the air, turned her way (at %s, feet %s)" % [id, air.global_position, air_feet])
			for frame in 120:
				await physics_frame
				if fighter.is_on_floor():
					break
			await _frames(10)
		await _remove(fighter)
	var brave: Node = _fighter("luna", 12, Vector2(1000, -1))
	await _frames(20)
	# A set timer keeps her transformed (at 0 the form ends once no attack holds her).
	brave.transformed = true
	brave.transformation_timer = 60.0
	spawned.clear()
	brave.jump_buffer_timer = 0.1
	await _frames(14)
	brave.jump_buffer_timer = 0.1
	await _frames(2)
	if _count("luna_jump") + _count("luna_air_jump") != 0:
		_fail("Brave Luna's jumps have no take-off art (%s)" % [spawned])
	brave.transformed = false
	brave.transformation_timer = 0.0
	await _remove(brave)

## Normal Luna's step flash (pick cup 2026-11-19): on the front foot of walk drawings 4 and 8 (17 and 18 px
## ahead of her feet), drawn her way, each over one step; Brave Luna's run has none.
func _test_luna_steps() -> void:
	runner = _fighter("luna", 13, Vector2(-400, -1), true)
	await _frames(20)
	var step_time: float = 4.0 / runner.character_sprite.sprite_frames.get_animation_speed(&"luna_walk")
	for side in [1, -1]:
		steps.clear()
		step_spans.clear()
		var action := "move_right" if side > 0 else "move_left"
		Input.action_press(action)
		await _frames(80)
		Input.action_release(action)
		await process_frame
		if steps.size() < 2:
			_fail("Running Luna should flash on her steps (%d, side %d)" % [steps.size(), side])
		for step in steps:
			var on_foot := is_equal_approx(step.x, 17.0 * side) or is_equal_approx(step.x, 18.0 * side)
			if not on_foot or absf(step.y) > 0.01 or signf(step.z) != float(side):
				_fail("Luna's step flash on her front foot, drawn her way (from the feet %s, scale %s, side %d)" % [Vector2(step.x, step.y), step.z, side])
				break
		for span in step_spans:
			if absf(span - step_time) > step_time * 0.01:
				_fail("A step flash should last one step (%.3f s, step %.3f s)" % [span, step_time])
				break
		await _frames(30)
	runner.transformed = true
	runner.transformation_timer = 60.0
	runner._update_character_sprite(true)
	spawned.clear()
	Input.action_press("move_right")
	await _frames(60)
	Input.action_release("move_right")
	await process_frame
	if _count("luna_step") != 0:
		_fail("Brave Luna's run should leave no step flash (%s)" % [spawned])
	runner.transformed = false
	await _remove(runner)

## The J star's launch flash where the star starts and the tail riding the star (pick cup 2026-11-19): turned
## to the aim, mirrored for a left aim; the tail loops; the big star has its own.
func _test_luna_star_flight() -> void:
	var luna: Node = _fighter("luna", 14, Vector2(2600, -1))
	await _frames(20)
	for shot in [[Vector2(1, 0), false], [Vector2(0.5, -0.866), false], [Vector2(-1, 0), false], [Vector2(-0.5, -0.866), true]]:
		var aim: Vector2 = shot[0]
		var big: bool = shot[1]
		var suffix := "_big" if big else ""
		spawned.clear()
		luna._fire_star(aim, big, false)
		var star: Node2D = null
		for node in arena.get_children():
			if node.get_script() == STAR_SCRIPT and not node.is_queued_for_deletion():
				star = node
		var flash := _live("luna_star_launch" + suffix)
		var turn := -1.0 if aim.x < 0.0 else 1.0
		var angle := (-aim).angle() if aim.x < 0.0 else aim.angle()
		if star == null or flash == null or _count("luna_star_launch" + suffix) != 1:
			_fail("A star aimed %s should flash luna_star_launch%s once (%s)" % [aim, suffix, spawned])
			continue
		if flash.global_position != star.global_position or signf(flash.scale.x) != turn or absf(flash.rotation - angle) > 0.001:
			_fail("The launch flash belongs on the star, turned to the aim %s (at %s, star %s, scale %s, rotation %.3f)" % [aim, flash.global_position, star.global_position, flash.scale, flash.rotation])
		var tail: AnimatedSprite2D = null
		for child in star.get_children():
			if _effect_of(child) == "luna_star_trail" + suffix:
				tail = child
		if tail == null or not tail.sprite_frames.get_animation_loop(&"play") or tail.position != Vector2.ZERO:
			_fail("The star aimed %s should carry its looping tail on its centre (%s)" % [aim, tail])
		elif signf(tail.scale.x) != turn or absf(tail.rotation - angle) > 0.001:
			_fail("The tail should be turned to the aim %s (scale %s, rotation %.3f)" % [aim, tail.scale, tail.rotation])
		await _frames(30)
	await _remove(luna)

## One afterglow per landed star on the struck body's centre (pick cup 2026-11-19), facing the way it flew:
## the big one for the big star, none from its burst, none on a miss.
func _test_luna_star_afterglow() -> void:
	var luna: Node = _fighter("luna", 15, Vector2(-1600, -1))
	var foe: Node = _fighter("rio", 16, Vector2(-1480, -1))
	await _frames(20)
	luna.facing = 1
	spawned.clear()
	var centre: Vector2 = foe.global_position + Vector2(0, -34)
	luna._fire_star(Vector2(1, 0), false, false)
	await _frames(10)
	var glow := _live("luna_hit_after")
	if _count("luna_hit_after") != 1 or _count("luna_hit_after_big") != 0 or glow == null:
		_fail("A small star that lands should leave exactly one afterglow (%s)" % [spawned])
	elif glow.global_position.distance_to(centre) > 6.0 or glow.scale.x != 1.0:
		_fail("The star's afterglow belongs on the struck body's centre, facing its flight (at %s, centre %s, scale %s)" % [glow.global_position, centre, glow.scale])
	for setup in [[Vector2(-1480, -1), 1, Vector2(1, 0)], [Vector2(-1720, -1), -1, Vector2(-1, 0)]]:
		# The last star knocked the foe away: stand it still in place again (knockback included).
		luna.facing = setup[1]
		foe.hitstun_timer = 0.0
		await _frames(30)
		foe.global_position = setup[0]
		foe.velocity = Vector2.ZERO
		foe.knockback_velocity = Vector2.ZERO
		await _frames(2)
		spawned.clear()
		luna._fire_star(setup[2], true, false)
		await _frames(14)
		var big_glow := _live("luna_hit_after_big")
		if _count("luna_hit_after_big") != 1 or _count("luna_hit_after") != 0 or big_glow == null:
			_fail("The big star should leave exactly one big afterglow, its burst none (%s)" % [spawned])
		elif signf(big_glow.scale.x) != float(setup[1]):
			_fail("The big afterglow should face the star's flight (scale %s, side %d)" % [big_glow.scale, setup[1]])
		if _count("luna_comet_burst") != 1:
			_fail("Test setup: the big star should burst on the hit (%s)" % [spawned])
	foe.global_position = Vector2(-2900, -1)
	luna.facing = 1
	await _frames(30)
	spawned.clear()
	luna._fire_star(Vector2(1, 0), false, false)
	await _frames(30)
	if _count("luna_hit_after") + _count("luna_hit_after_big") != 0:
		_fail("A star that misses should leave no afterglow (%s)" % [spawned])
	await _remove(foe)
	await _remove(luna)

## Brave Luna's J follow-through (pick cup 2026-11-19): each move draws luna_brave_slash and its own strip at
## her body centre, facing her way (mirrored facing left); the uppercut's strip on the ground and in the air.
func _test_brave_follow_through() -> void:
	var luna: Node = _fighter("luna", 17, Vector2(1800, -1))
	await _frames(20)
	luna.transformed = true
	luna.transformation_timer = 60.0
	for move in BRAVE_MOVES:
		luna.global_position = Vector2(1800, -1)
		luna.velocity = Vector2.ZERO
		await _frames(4)
		spawned.clear()
		luna.callv(move[0], move[1])
		var strip := _live(move[2])
		if strip == null or _count(move[2]) != 1 or _count("luna_brave_slash") != 1:
			_fail("%s%s should draw luna_brave_slash and %s once (%s)" % [move[0], move[1], move[2], spawned])
		elif strip.global_position != luna.global_position + Vector2(0, -32) or strip.scale.x != float(luna.facing):
			_fail("%s belongs on her body centre, facing her way (at %s, Luna %s)" % [move[2], strip.global_position, luna.global_position])
		await _frames(20)
	luna.facing = -1
	spawned.clear()
	luna._brave_jab()
	var mirrored := _live("brave_rush_1")
	if mirrored == null or mirrored.scale.x >= 0.0:
		_fail("Facing left, Brave Luna's follow-through should be mirrored")
	luna.transformed = false
	await _remove(luna)

## Brave Luna's melee hits leave one afterglow on the struck body (pick cup 2026-11-19): the big one from base
## knockback 400 (the spinning kick 520), none on a miss.
func _test_brave_hit_afterglow() -> void:
	var luna: Node = _fighter("luna", 18, Vector2(-800, -1))
	var foe: Node = _fighter("rio", 19, Vector2(-740, -1))
	await _frames(20)
	luna.facing = 1
	luna.transformed = true
	luna.transformation_timer = 60.0
	spawned.clear()
	var centre: Vector2 = foe.global_position + Vector2(0, -34)
	luna._brave_jab()
	await _frames(6)
	var glow := _live("brave_hit_after")
	if _count("brave_hit_after") != 1 or _count("brave_hit_after_big") != 0 or glow == null:
		_fail("Brave Luna's jab on a fighter should leave exactly one afterglow (%s)" % [spawned])
	elif glow.global_position.distance_to(centre) > 6.0 or glow.scale.x != 1.0:
		_fail("Her afterglow belongs on the struck body's centre, facing her way (at %s, centre %s)" % [glow.global_position, centre])
	foe.global_position = luna.global_position + Vector2(60, 0)
	foe.velocity = Vector2.ZERO
	foe.hitstun_timer = 0.0
	await _frames(20)
	spawned.clear()
	luna._brave_spin_kick()
	await _frames(6)
	if _count("brave_hit_after_big") != 1 or _count("brave_hit_after") != 0:
		_fail("The spinning kick should leave exactly one big afterglow (%s)" % [spawned])
	foe.global_position = Vector2(-200, -1)
	await _frames(20)
	spawned.clear()
	luna._brave_jab()
	await _frames(6)
	if _count("brave_hit_after") + _count("brave_hit_after_big") != 0:
		_fail("A miss should leave no afterglow (%s)" % [spawned])
	luna.transformed = false
	await _remove(foe)
	await _remove(luna)

func _test_plain_style() -> void:
	var luna: Node = _fighter("luna", 6, Vector2(-2400, -1))
	var frey: Node = _fighter("frey", 7, Vector2(-2000, -1))
	await _frames(20)
	if luna.motion_overlay == null:
		_fail("Test setup: idle Luna should have her stars")
	ART_SETTINGS.style = ART_SETTINGS.STYLE_PROTOTYPE
	await _frames(2)
	spawned.clear()
	frey._combo_slash_one()
	luna._spawn_landing_puff()
	frey._spawn_jump_effect(false)
	frey._spawn_landing_puff()
	luna._fire_star(Vector2(1, 0), false, false)
	var pickups := ["frey_slash_sparks_1", "luna_land_stardust", "luna_land_stardust_small", "frey_jump", "frey_land", "frey_land_big", "luna_star_launch"]
	if luna.motion_overlay != null or pickups.any(func(effect: String) -> bool: return _count(effect) != 0):
		_fail("The plain style should draw none of the motion effects (overlay %s, %s)" % [luna.motion_overlay, spawned])
	ART_SETTINGS.style = ART_SETTINGS.STYLE_ORIGINAL
	await _frames(2)
	if luna.motion_overlay == null:
		_fail("Back in the original style the idle stars should return")
	await _remove(luna)
	await _remove(frey)
