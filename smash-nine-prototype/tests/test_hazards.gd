extends SceneTree
## Realm gimmick tests (RealmHazards): ice traction, eruption pillars, quake stun, off switch,
## Midgard bushes (hide, reveal on attack, bots notice only up close).

const MAIN_SCENE := "res://scenes/Main.tscn"
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const REALM_HAZARDS := preload("res://scripts/realms/RealmHazards.gd")

var arena: Node2D
var layout: RefCounted
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	layout = REALM_LAYOUT.new()
	var tests: Array[Callable] = [_test_ice_traction, _test_eruption_hits_once, _test_disabled_hazards_stay_idle, _test_quake_stuns_grounded_fighters, _test_bushes_conceal]
	for test in tests:
		await test.call()
		if failed:
			quit(1)
			return
	print("Hazard tests passed (%d)" % tests.size())
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _realm(realm_name: String) -> int:
	for i in layout.realm_count():
		if layout.get_realm(i).name == realm_name:
			return i
	return -1

func _new_hazards() -> Node:
	var hazards: Node = REALM_HAZARDS.new()
	arena.add_child(hazards)
	hazards.setup(layout, func(_realm_index: int) -> String: return "stable", 5)
	return hazards

func _new_player(character_id: String, player_id: int, realm_index: int) -> Node:
	var player: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(player)
	player.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, false)
	player.set_physics_process(false)
	layout.assign_combatant(player, realm_index)
	player.global_position = layout.pick_spawn(realm_index)
	return player

func _test_ice_traction() -> void:
	var hazards := _new_hazards()
	var on_ice := _new_player("frey", 1, _realm("Niflheim"))
	var on_stone := _new_player("yuki", 2, _realm("Asgard"))
	hazards.register_combatant(on_ice)
	hazards.register_combatant(on_stone)
	hazards.advance(0.016)
	if not is_equal_approx(on_ice.ground_traction, 0.22) or not is_equal_approx(on_stone.ground_traction, 1.0):
		_fail("Traction should be 0.22 on Niflheim ice and 1.0 elsewhere, got %.2f / %.2f" % [on_ice.ground_traction, on_stone.ground_traction])
		return
	hazards.enabled = false
	hazards.advance(0.016)
	if not is_equal_approx(on_ice.ground_traction, 1.0):
		_fail("Disabled hazards must restore normal traction")
		return
	for node in [hazards, on_ice, on_stone]:
		node.queue_free()

func _test_eruption_hits_once() -> void:
	var muspelheim := _realm("Muspelheim")
	var hazards := _new_hazards()
	var burned := _new_player("frey", 1, muspelheim)
	var safe := _new_player("yuki", 2, muspelheim)
	hazards.register_combatant(burned)
	hazards.register_combatant(safe)
	hazards.trigger(muspelheim)
	var columns: Array = hazards.get_columns(muspelheim)
	if columns.size() != 2:
		_fail("Eruption should raise 2 pillars, got %d" % columns.size())
		return
	var column: Rect2 = columns[0]
	burned.global_position = Vector2(column.get_center().x, column.end.y)
	safe.global_position = Vector2(column.position.x - 400.0, column.end.y)
	var hp_before: float = burned.hp
	var safe_hp: float = safe.hp
	hazards.advance(0.5)
	if burned.hp != hp_before:
		_fail("Pillar hurt during its warning")
		return
	for step in 10:
		hazards.advance(0.1)
	var hazard: Dictionary = layout.get_realm(muspelheim).hazard
	if not is_equal_approx(hp_before - burned.hp, float(hazard.damage)):
		_fail("A pillar should deal exactly %.0f fixed damage once, dealt %.1f" % [float(hazard.damage), hp_before - burned.hp])
		return
	if burned.knockback_velocity.y >= 0.0:
		_fail("A pillar should launch upward")
		return
	if safe.hp != safe_hp:
		_fail("A fighter away from the pillars was hurt")
		return
	for node in [hazards, burned, safe]:
		node.queue_free()

func _test_disabled_hazards_stay_idle() -> void:
	var hazards := _new_hazards()
	hazards.enabled = false
	for step in 300:
		hazards.advance(0.1)
	for realm_name in ["Muspelheim", "Jotunheim"]:
		if hazards.get_phase(_realm(realm_name)) != "idle":
			_fail("%s hazard ran while hazards are off" % realm_name)
			return
	hazards.queue_free()

## Real physics: a fighter standing on Jotunheim's floor is stunned; one in the air is not.
func _test_quake_stuns_grounded_fighters() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.player_count = 2
	main.match_seed = 21
	root.add_child(main)
	await process_frame
	var jotunheim := _realm("Jotunheim")
	var grounded: Node = main.players[0]
	var airborne: Node = main.players[1]
	for player in [grounded, airborne]:
		player.is_dummy = true
		main.layout.assign_combatant(player, jotunheim)
	grounded.reset_for_map(Vector2(main.layout.get_origin(jotunheim).x + 640.0, main.layout.get_origin(jotunheim).y + 560.0), main.layout.get_spawn_points(jotunheim))
	airborne.reset_for_map(Vector2(main.layout.get_origin(jotunheim).x + 700.0, main.layout.get_origin(jotunheim).y + 560.0), main.layout.get_spawn_points(jotunheim))
	main._sync_combatant_visibility()
	await create_timer(1.0).timeout
	if not grounded.is_on_floor():
		_fail("Test setup: the grounded fighter did not land on Jotunheim's floor")
		return
	var stunned: Array[Node] = []
	for player in [grounded, airborne]:
		player.damaged.connect(func(who: Node, _amount: float, attacker: Variant, source: String) -> void:
			if source == "hit" and attacker == null:
				stunned.append(who))
	main.hazards.trigger(jotunheim)
	var warning: float = float(layout.get_realm(jotunheim).hazard.warning)
	await create_timer(warning - 0.4).timeout
	airborne.velocity.y = -900.0
	await create_timer(0.7).timeout
	if not stunned.has(grounded):
		_fail("The quake did not hit the fighter standing on the floor")
		return
	if stunned.has(airborne):
		_fail("The quake hit a fighter who jumped during the warning")
		return
	main.queue_free()
	await process_frame

func _test_bushes_conceal() -> void:
	var midgard := _realm("Midgard")
	var hazards := _new_hazards()
	var bushes: Array = hazards.get_bushes(midgard)
	if bushes.size() != 3:
		_fail("Midgard should have 3 bushes, got %d" % bushes.size())
		return
	var bush: Rect2 = bushes[0]
	var hider := _new_player("rio", 1, midgard)
	var seeker := _new_player("frey", 2, midgard)
	hazards.register_combatant(hider)
	hazards.register_combatant(seeker)
	hider.global_position = Vector2(bush.get_center().x, bush.end.y - 4.0)
	seeker.global_position = hider.global_position + Vector2(400, 0)
	hazards.advance(0.016)
	if not hider.concealed or seeker.concealed or hider.modulate.a > 0.5:
		_fail("A fighter inside a bush should be concealed and faded, one outside not")
		return
	if seeker.ai_controller._is_valid_target_candidate(seeker, hider):
		_fail("Bots should not notice a hidden fighter 400 px away")
		return
	seeker.global_position = hider.global_position + Vector2(100, 0)
	if not seeker.ai_controller._is_valid_target_candidate(seeker, hider):
		_fail("Bots should notice a hidden fighter within 140 px")
		return
	hider.attack_lock_timer = 0.2
	hazards.advance(0.016)
	if hider.concealed:
		_fail("Attacking should reveal a hidden fighter")
		return
	hider.attack_lock_timer = 0.0
	hazards.advance(0.5)
	if hider.concealed:
		_fail("A revealed fighter should stay visible for a moment")
		return
	hazards.advance(0.5)
	if not hider.concealed:
		_fail("A fighter should hide again once the reveal wears off")
		return
	hazards.enabled = false
	hazards.advance(0.016)
	if hider.concealed or hider.modulate.a < 0.99:
		_fail("Disabled hazards must not hide anyone")
		return
	for node in [hazards, hider, seeker]:
		node.queue_free()
