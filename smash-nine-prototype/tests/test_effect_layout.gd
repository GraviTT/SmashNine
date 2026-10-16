extends SceneTree
## Where and how the effects are drawn, after the sprite audit with Codex (2026-10-16,
## reports/debate-sprite-audit/decision.md; the guard arc is in test_skill_fx_art):
## - B1: a J trail is thinner than it is long (it stood twice as tall as the fighter);
## - B3: a ground move aimed at the floor shows its trail along the floor, not into it;
## - B2/B5: Rio's rune counter and Nova's vector strikes draw only their own effects;
## - B4: Luna's star bloom is drawn behind the fighters;
## - B7: the screen-filling ultimate flashes are see-through.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const VFX := preload("res://scripts/Vfx.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _run() -> void:
	ART_SETTINGS.style = ART_SETTINGS.STYLE_ORIGINAL
	arena = Node2D.new()
	root.add_child(arena)
	await _test_trail_thickness()
	await _test_ground_down_trail()
	await _test_own_effects_only()
	_test_bloom_behind_fighters()
	await _test_ultimate_flashes()
	arena.queue_free()
	await process_frame
	ART_SETTINGS.style = ART_SETTINGS.DEFAULT_STYLE
	if failed:
		quit(1)
		return
	print("Effect layout tests passed")
	quit(0)

func _player(id: String, at := Vector2(0, -400)) -> Node:
	var player: Node = PLAYER_FACTORY.create(id)
	arena.add_child(player)
	player.global_position = at
	player.setup(CHARACTER_REGISTRY.get_characters()[id], 1, false)
	player.is_dummy = true
	player.ringout_y = 100000.0
	return player

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

func _vfx(effect: String) -> AnimatedSprite2D:
	return arena.find_child("Vfx_%s" % effect, true, false) as AnimatedSprite2D

func _clear(nodes: Array) -> void:
	for node in nodes:
		if is_instance_valid(node):
			node.free()
	for child in arena.get_children():
		child.free()

func _test_trail_thickness() -> void:
	var frey := _player("frey")
	await physics_frame
	frey._air_slash()
	var slash := _vfx("frey_slash")
	if slash == null:
		_fail("Test setup: Frey's air slash should draw frey_slash")
	elif absf(slash.scale.y / slash.scale.x - frey.ATTACK_ART_THICKNESS) > 0.01:
		_fail("A J trail should be %.2f as thick as it is long (scale %s)" % [frey.ATTACK_ART_THICKNESS, slash.scale])
	_clear([frey])

func _test_ground_down_trail() -> void:
	var ground := _floor(Vector2.ZERO, 800)
	var frey := _player("frey", Vector2(0, -2))
	for frame in 20:
		await physics_frame
	if not frey.is_on_floor():
		_fail("Test setup: Frey should stand on the floor")
	frey._down_cut()
	var slash := _vfx("frey_slash")
	var limit := deg_to_rad(frey.GROUND_TRAIL_MAX_DROP) + 0.001
	if slash == null:
		_fail("Test setup: Frey's down cut should draw frey_slash")
	elif slash.rotation > limit or slash.rotation < -limit:
		_fail("A ground down cut should show its trail along the floor (rotation %.1f deg, at most %.0f)" % [rad_to_deg(slash.rotation), frey.GROUND_TRAIL_MAX_DROP])
	_clear([frey, ground])

func _test_own_effects_only() -> void:
	var rio := _player("rio")
	await physics_frame
	rio.rune_absorbed_hits = 2
	rio._rune_release()
	if _vfx("rio_slash") != null or _vfx("rio_rune_burst") == null:
		_fail("Rio's rune counter should draw its rune burst and no shared slash (slash %s)" % [_vfx("rio_slash")])
	_clear([rio])
	var nova := _player("nova")
	await physics_frame
	nova._vector_side_strike(0.5, false, Vector2.RIGHT)
	if _vfx("nova_slash") != null or _vfx("nova_vector_streak") == null:
		_fail("Nova's vector strike should draw its streak and no shared slash")
	nova._vector_uppercut(0.5, false)
	if _vfx("nova_slash") != null:
		_fail("Nova's vector uppercut should draw no shared slash")
	_clear([nova])

func _test_bloom_behind_fighters() -> void:
	var luna := _player("luna")
	luna._play_star_bloom(Vector2(40, -30), 40.0, Color.WHITE)
	var bloom := _vfx("luna_star_bloom")
	if bloom == null or bloom.z_index >= int(luna.character_sprite.z_index):
		_fail("Luna's star bloom should be drawn behind the fighters (z %s, fighter %d)" % [bloom.z_index if bloom else "none", luna.character_sprite.z_index])
	_clear([luna])

func _test_ultimate_flashes() -> void:
	var luna := _player("luna")
	await physics_frame
	luna._enter_transformation()
	var transform_art := luna.find_child("Vfx_luna_ult_transform", true, false) as AnimatedSprite2D
	if transform_art == null or absf(transform_art.modulate.a - VFX.ULTIMATE_FLASH_ALPHA) > 0.01:
		_fail("Luna's transformation flash should be see-through (alpha %s)" % [transform_art.modulate.a if transform_art else "none"])
	_clear([luna])
	var yuki := _player("yuki")
	await physics_frame
	var ward: Node2D = load("res://characters/yuki/YukiGrandWard.gd").new()
	arena.add_child(ward)
	ward.configure(yuki, int(yuki.realm_index))
	ward.activated = true
	ward.pulse_timer = 10.0
	ward.active_timer = ward.ACTIVE_TIME
	ward._physics_process(0.0)
	var burst := _vfx("yuki_ult_burst")
	if burst == null or absf(burst.modulate.a - VFX.ULTIMATE_FLASH_ALPHA) > 0.01:
		_fail("Yuki's final burst should be see-through (alpha %s)" % [burst.modulate.a if burst else "none"])
	_clear([yuki])
