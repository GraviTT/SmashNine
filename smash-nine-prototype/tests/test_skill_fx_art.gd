extends SceneTree
## CODEX-ART-24: every wired skill effect uses art in original mode and its old procedural
## node in prototype mode. This is intentionally a short construction test, not a match soak.

const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")

var failed := false
var arena: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	ART_SETTINGS.style = ART_SETTINGS.STYLE_ORIGINAL
	arena = Node2D.new()
	root.add_child(arena)
	_run_original_checks()
	arena.queue_free()
	await process_frame

	ART_SETTINGS.style = ART_SETTINGS.STYLE_PROTOTYPE
	arena = Node2D.new()
	root.add_child(arena)
	_run_fallback_checks()
	arena.queue_free()
	await process_frame
	ART_SETTINGS.style = ART_SETTINGS.DEFAULT_STYLE
	if failed:
		quit(1)
		return
	print("Skill FX art tests passed")
	quit(0)

func _run_original_checks() -> void:
	var luna := _player("luna")
	luna._play_star_bloom(Vector2.ZERO, 40.0, Color.WHITE)
	_expect_vfx(luna.get_parent(), "luna_star_bloom")
	luna._play_moon_ring_flash(60.0)
	_expect_vfx(luna.get_parent(), "luna_moon_ring")
	luna._create_transformation_aura()
	_expect_vfx(luna, "luna_brave_aura")

	var comet := _comet_node()
	comet._spawn_trail()
	_expect_vfx(arena, "luna_comet_trail")
	comet._spawn_bloom_flash()
	_expect_vfx(arena, "luna_comet_burst")

	var nova := _player("nova")
	var burst: Node = nova._spawn_gravity_burst(72.0, 1.0, 1.0, 0.5, Color.WHITE, "test")
	_expect_vfx(burst, "nova_gravity_burst")
	nova.velocity = Vector2(700, 0)
	nova._update_momentum_visual()
	_expect_vfx(arena, "nova_momentum_trail")
	nova._play_vector_flash(Vector2.RIGHT, 120.0, 0.8)
	_expect_vfx(arena, "nova_vector_streak")
	nova._play_shift_flash(Vector2.RIGHT)
	_expect_vfx(arena, "nova_shift_dash")
	nova._play_shift_recharge_flash()
	_expect_vfx(arena, "nova_shift_ready")
	nova._play_impact_flash(Vector2.ZERO, 70.0, Color.WHITE)
	_expect_vfx(arena, "nova_impact_star")
	nova._play_launch_flash(Vector2.RIGHT)
	_expect_vfx(arena, "nova_launch_flash")

	var rio := _player("rio")
	rio._show_rune(true)
	_expect_vfx(rio, "rio_rune_guard")
	rio._play_rune_burst()
	_expect_vfx(arena, "rio_rune_burst")
	rio._play_blink_trail(Vector2.ZERO, Vector2(180, 0))
	_expect_vfx(arena, "rio_blink_trail")
	var sword: Node = rio._make_gem_sword(Color.CYAN)
	if sword.get_node_or_null("ArtSprite") == null:
		_fail("Rio gem sword did not use rio_gem_sword.png")
	sword.free()

	var ward: Node = load("res://characters/yuki/YukiGrandWard.gd").new()
	arena.add_child(ward)
	ward.set_physics_process(false)
	_expect_vfx(ward, "yuki_grand_ward")

	luna.is_guarding = true
	luna._update_guard_visual()
	var guard_art := luna.get_node_or_null("Vfx_guard_bubble") as CanvasItem
	if guard_art == null or not guard_art.visible or luna.guard_visual.visible:
		_fail("Guard did not show art and hide its Line2D")

	var attack := _attack_node()
	attack._spawn_trail_afterimage()
	_expect_vfx(arena, "attack_afterimage")
	_run_original_realm_checks()

func _run_fallback_checks() -> void:
	var luna := _player("luna")
	_expect_added_shape("Luna star bloom", Polygon2D, func() -> void: luna._play_star_bloom(Vector2.ZERO, 40.0, Color.WHITE))
	_expect_added_shape("Luna moon ring", Line2D, func() -> void: luna._play_moon_ring_flash(60.0))
	_expect_added_shape("Luna brave aura", Line2D, func() -> void: luna._create_transformation_aura())
	var comet := _comet_node()
	_expect_added_shape("Luna comet trail", Polygon2D, func() -> void: comet._spawn_trail())
	_expect_added_shape("Luna comet burst", Polygon2D, func() -> void: comet._spawn_bloom_flash())

	var nova := _player("nova")
	_expect_added_shape("Nova gravity burst", Polygon2D, func() -> void: nova._spawn_gravity_burst(72.0, 1.0, 1.0, 0.5, Color.WHITE, "test"))
	nova.velocity = Vector2(700, 0)
	_expect_added_shape("Nova momentum trail", Polygon2D, func() -> void: nova._update_momentum_visual())
	_expect_added_shape("Nova vector streak", Line2D, func() -> void: nova._play_vector_flash(Vector2.RIGHT, 120.0, 0.8))
	_expect_added_shape("Nova shift dash", Line2D, func() -> void: nova._play_shift_flash(Vector2.RIGHT))
	_expect_added_shape("Nova shift ready", Line2D, func() -> void: nova._play_shift_recharge_flash())
	_expect_added_shape("Nova impact star", Polygon2D, func() -> void: nova._play_impact_flash(Vector2.ZERO, 70.0, Color.WHITE))
	_expect_added_shape("Nova launch flash", Line2D, func() -> void: nova._play_launch_flash(Vector2.RIGHT))

	var rio := _player("rio")
	_expect_added_shape("Rio rune guard", Line2D, func() -> void: rio._show_rune(true))
	_expect_added_shape("Rio rune burst", Line2D, func() -> void: rio._play_rune_burst())
	_expect_added_shape("Rio blink trail", Line2D, func() -> void: rio._play_blink_trail(Vector2.ZERO, Vector2(180, 0)))
	var sword: Polygon2D = rio._make_gem_sword(Color.CYAN)
	if sword.polygon.is_empty() or sword.get_node_or_null("ArtSprite") != null:
		_fail("Rio gem sword fallback was not the old polygon")
	sword.free()

	var ward: Node = load("res://characters/yuki/YukiGrandWard.gd").new()
	arena.add_child(ward)
	ward.set_physics_process(false)
	if ward.ring == null or not ward.ring.visible or _has_vfx(ward, "yuki_grand_ward"):
		_fail("Yuki grand ward did not keep its ring fallback")

	luna.is_guarding = true
	luna._update_guard_visual()
	if not luna.guard_visual.visible or luna.get_node_or_null("Vfx_guard_bubble") != null:
		_fail("Guard did not keep its Line2D fallback")

	var attack := _attack_node()
	_expect_added_shape("Attack afterimage", ColorRect, func() -> void: attack._spawn_trail_afterimage())
	_run_fallback_realm_checks()
	for effect in ["luna_star_bloom", "luna_moon_ring", "luna_brave_aura", "luna_comet_trail", "luna_comet_burst", "nova_gravity_burst", "nova_momentum_trail", "nova_vector_streak", "nova_shift_dash", "nova_shift_ready", "nova_impact_star", "nova_launch_flash", "rio_rune_guard", "rio_rune_burst", "rio_blink_trail", "yuki_grand_ward", "guard_bubble", "attack_afterimage"]:
		if _has_vfx(arena, effect):
			_fail("Prototype mode unexpectedly drew %s art" % effect)

func _player(id: String) -> Node:
	var player := PLAYER_FACTORY.create(id)
	arena.add_child(player)
	player.setup(CHARACTER_REGISTRY.get_characters()[id], 1, false)
	player.set_physics_process(false)
	return player

func _attack_node() -> Node:
	var attack: Node = load("res://scripts/Attack.gd").new()
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	attack.add_child(collision)
	var visual := ColorRect.new()
	visual.name = "Visual"
	visual.size = Vector2(120, 44)
	visual.color = Color(0.4, 0.8, 1.0, 0.8)
	attack.add_child(visual)
	arena.add_child(attack)
	attack.set_physics_process(false)
	return attack

func _run_original_realm_checks() -> void:
	var world: Node = load("res://scripts/realms/RealmWorld.gd").new()
	world.layout = REALM_LAYOUT.new()
	arena.add_child(world)
	var portal_root := Node2D.new()
	world.add_child(portal_root)
	world._create_portal_visual(portal_root, Vector2(100, 100), "RIGHT", 1, 0, false)
	if portal_root.get_node_or_null("PortalAnimated") == null:
		_fail("Portal did not use portal_anim.png")
	for state in ["warning", "locked", "collapsed"]:
		var state_root := Node2D.new()
		world.add_child(state_root)
		world._create_state_overlay(state_root, 0, state)
		var effect := "warning_edge" if state == "warning" else ("seal_barrier" if state == "locked" else "collapse_cracks")
		_expect_vfx(state_root, effect)

func _run_fallback_realm_checks() -> void:
	var world: Node = load("res://scripts/realms/RealmWorld.gd").new()
	world.layout = REALM_LAYOUT.new()
	arena.add_child(world)
	var portal_root := Node2D.new()
	world.add_child(portal_root)
	world._create_portal_visual(portal_root, Vector2(100, 100), "RIGHT", 1, 0, false)
	if portal_root.get_node_or_null("PortalAnimated") != null or _count_type(portal_root, ColorRect) == 0:
		_fail("Portal did not keep its prototype fallback")
	for state in ["warning", "locked", "collapsed"]:
		var state_root := Node2D.new()
		world.add_child(state_root)
		world._create_state_overlay(state_root, 0, state)
		var effect := "warning_edge" if state == "warning" else ("seal_barrier" if state == "locked" else "collapse_cracks")
		if _has_vfx(state_root, effect) or _count_type(state_root, ColorRect) == 0:
			_fail("Realm %s did not keep its tint fallback" % state)

func _comet_node() -> Node:
	var comet: Node = load("res://characters/luna/LunaComet.gd").new()
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	comet.add_child(collision)
	var visual := Polygon2D.new()
	visual.name = "Visual"
	comet.add_child(visual)
	arena.add_child(comet)
	comet.set_physics_process(false)
	return comet

func _expect_vfx(node: Node, effect: String) -> void:
	if not _has_vfx(node, effect):
		_fail("Expected art node Vfx_%s" % effect)

func _has_vfx(node: Node, effect: String) -> bool:
	if node.name == "Vfx_%s" % effect:
		return true
	for child in node.get_children():
		if _has_vfx(child, effect):
			return true
	return false

func _expect_added_shape(label: String, type: Variant, action: Callable) -> void:
	var before := _count_type(arena, type)
	action.call()
	var after := _count_type(arena, type)
	if after <= before:
		_fail("%s did not add its procedural fallback" % label)

func _count_type(node: Node, type: Variant) -> int:
	var count := 1 if is_instance_of(node, type) else 0
	for child in node.get_children():
		count += _count_type(child, type)
	return count

func _fail(message: String) -> void:
	push_error(message)
	failed = true
