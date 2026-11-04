extends SceneTree
## pixelfx motion effects (user 2026-11-04: "현재 테스트로 만든 것들 전부 게임에 넣어볼 것"): Luna's idle
## stars loop over her while she idles (normal form only) and turn with her; a landing from a jump
## scatters her stardust, never the grey dust: the clear one after a big fall, the small one after a
## small one (user 2026-11-04), and a tiny drop shows nothing; Frey kicks up dust on the walk drawings
## where a foot lands, only while she runs, behind her in either direction, each puff over one step;
## each J cut draws its own sparks with the slash. The Frey pilot picks (2026-11-04, D49): her up, down
## and air J draw their follow-through (ground and air versions apart), and each melee hit that lands,
## on a fighter or a monster, leaves exactly one afterglow on the struck body (the big one for a strong
## hit), none on a miss. Presentation only: nothing in the plain style (F2).

const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const MONSTER_SCRIPT := preload("res://scripts/RealmMonster.gd")

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
	if spawned[-1] == "frey_step_dust":
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
	# Frey keeps the old rule: no dust on a plain landing.
	spawned.clear()
	var frey: Node = _fighter("frey", 3, Vector2(800, -220))
	for frame in 120:
		await physics_frame
		if frey.is_on_floor():
			break
	await _frames(2)
	if _count("landing_dust") != 0 or _count("luna_land_stardust") != 0:
		_fail("Frey's plain landing should stay without dust (%s)" % [spawned])
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
	if luna.motion_overlay != null or _count("frey_slash_sparks_1") != 0 or _count("luna_land_stardust") != 0 or _count("luna_land_stardust_small") != 0:
		_fail("The plain style should draw none of the motion effects (overlay %s, %s)" % [luna.motion_overlay, spawned])
	ART_SETTINGS.style = ART_SETTINGS.STYLE_ORIGINAL
	await _frames(2)
	if luna.motion_overlay == null:
		_fail("Back in the original style the idle stars should return")
	await _remove(luna)
	await _remove(frey)
