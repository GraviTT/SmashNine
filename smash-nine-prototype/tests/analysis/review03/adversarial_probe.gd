extends SceneTree
## CODEX-ANALYST-03 adversarial checks against the real Rio, bush and crystal code.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const REALM_HAZARDS := preload("res://scripts/realms/RealmHazards.gd")
const CRYSTAL_SPAWNER := preload("res://scripts/SoulCrystalSpawner.gd")
const CRYSTAL := preload("res://scripts/SoulCrystal.gd")

var arena: Node2D
var characters: Dictionary

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	characters = CHARACTER_REGISTRY.get_characters()
	var result := {
		"dimension_slash": await _probe_dimension_slash(),
		"rune_routes": await _probe_rune_routes(),
		"overdrive_cancel": await _probe_overdrive_cancel(),
		"concealment_lifecycle": await _probe_concealment_lifecycle(),
		"crystal_lifecycle": await _probe_crystal_lifecycle(),
		"rio_ai_non_player_target": await _probe_rio_ai_non_player_target()
	}
	print("REVIEW03_RESULT ", JSON.stringify(result))
	arena.queue_free()
	await process_frame
	quit(0)

func _new_player(character_id: String, player_id: int) -> Node:
	var player: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(player)
	player.global_position = Vector2(player_id * 1000.0, 0.0)
	player.setup(characters[character_id], player_id, false)
	player.ringout_y = 100000.0
	player.set_physics_process(false)
	return player

func _solid(center: Vector2, size: Vector2, one_way := false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.one_way_collision = one_way
	body.add_child(collision)
	body.position = center
	arena.add_child(body)
	return body

func _probe_dimension_slash() -> Dictionary:
	var rio := _new_player("rio", 1)
	var wall := _solid(Vector2(1120.0, -32.0), Vector2(20.0, 180.0))
	await physics_frame
	rio.global_position = Vector2(1000.0, 0.0)
	rio._dimension_slash(Vector2.RIGHT)
	var wall_stop_x: float = rio.global_position.x

	wall.queue_free()
	var one_way := _solid(Vector2(1000.0, -100.0), Vector2(300.0, 20.0), true)
	await physics_frame
	rio.global_position = Vector2(1000.0, 50.0)
	rio._dimension_slash(Vector2.UP)
	var below_to_above_y: float = rio.global_position.y
	var falling_collision = rio.move_and_collide(Vector2(0.0, 100.0), true)
	var fall_travel_y: float = falling_collision.get_travel().y if falling_collision != null else 100.0
	rio.global_position = Vector2(1000.0, -150.0)
	rio._dimension_slash(Vector2.DOWN)
	var above_to_down_y: float = rio.global_position.y

	one_way.queue_free()
	await physics_frame
	rio.global_position = Vector2(250.0, 0.0)
	rio.spawn_point = Vector2.ZERO
	var blast_spawn_points: Array[Vector2] = [Vector2.ZERO]
	rio.set_spawn_points(blast_spawn_points)
	rio.blast_left = -300.0
	rio.blast_right = 300.0
	rio._dimension_slash(Vector2.RIGHT)
	var crossed_blast_x: float = rio.global_position.x
	rio.is_dummy = true
	rio.set_physics_process(true)
	await physics_frame
	var respawns_after_crossing: int = rio.respawn_count
	var position_after_physics: Vector2 = rio.global_position
	rio.queue_free()
	return {
		"solid_wall_endpoint_x": snappedf(wall_stop_x, 0.1),
		"solid_wall_near_face_not_inside": wall_stop_x <= 1090.1,
		"one_way_from_below_endpoint_y": snappedf(below_to_above_y, 0.1),
		"one_way_fall_test_travel_y": snappedf(fall_travel_y, 0.1),
		"one_way_from_above_endpoint_y": snappedf(above_to_down_y, 0.1),
		"crossed_blast_endpoint_x": snappedf(crossed_blast_x, 0.1),
		"blast_right": 300.0,
		"ringout_next_physics_frame": respawns_after_crossing == 1,
		"position_after_ringout": position_after_physics
	}

func _reset_rune(rio: Node) -> void:
	rio.hp = rio.max_hp
	rio.knockback_velocity = Vector2.ZERO
	rio.hitstun_timer = 0.0
	rio.last_hit_absorbed = false
	rio.rune_timer = 1.0
	rio.rune_absorbed_hits = 0
	rio.rune_absorbed_knockback = 0.0

func _probe_rune_routes() -> Dictionary:
	var rio := _new_player("rio", 2)
	var attacker := _new_player("frey", 3)
	var rows := {}
	_reset_rune(rio)
	rio.apply_hit(attacker, 20.0, 600.0, Vector2.RIGHT)
	rows["normal"] = _rune_row(rio)
	_reset_rune(rio)
	rio.apply_forced_launch_hit(attacker, 20.0, Vector2(400.0, -500.0), 0.3, 640.0, Vector2.RIGHT)
	rows["forced_launch"] = _rune_row(rio)
	_reset_rune(rio)
	rio.apply_stun_hit(attacker, 20.0, 600.0, Vector2.RIGHT, 0.55)
	rows["stun"] = _rune_row(rio)
	_reset_rune(rio)
	rio.apply_yuki_seal_burst(attacker, 77, 20.0, 600.0, Vector2.RIGHT)
	rows["yuki_seal"] = _rune_row(rio)
	rows["yuki_seal"]["activation_recorded"] = rio.last_yuki_activation_hit
	_reset_rune(rio)
	rio.apply_hit(null, 7.0, 560.0, Vector2.UP, "fixed")
	rows["fixed_hazard"] = _rune_row(rio)
	_reset_rune(rio)
	for hit in 6:
		rio.apply_hit(attacker, 6.0, 320.0, Vector2.RIGHT)
	rows["six_hit_burst"] = _rune_row(rio)
	rio._rune_release()
	var return_damage := -1.0
	var return_knockback := -1.0
	for child in arena.get_children():
		if child is Area2D and child.get("source") == rio:
			return_damage = float(child.get("damage"))
			return_knockback = float(child.get("knockback"))
	rows["six_hit_burst"]["return_damage"] = return_damage
	rows["six_hit_burst"]["return_knockback"] = return_knockback
	_reset_rune(rio)
	var hp_before_environment: float = rio.hp
	rio.apply_environment_damage(7.0)
	rows["environment_damage"] = {
		"hp_loss": snappedf(hp_before_environment - rio.hp, 0.01),
		"rune_still_active": rio.rune_timer > 0.0,
		"absorbed_hits": rio.rune_absorbed_hits
	}
	rio.queue_free()
	attacker.queue_free()
	await process_frame
	return rows

func _rune_row(rio: Node) -> Dictionary:
	return {
		"hp_loss": snappedf(rio.max_hp - rio.hp, 0.01),
		"knockback": snappedf(rio.knockback_velocity.length(), 0.01),
		"hitstun": snappedf(rio.hitstun_timer, 0.001),
		"absorbed_hits": rio.rune_absorbed_hits,
		"last_hit_absorbed": rio.last_hit_absorbed
	}

func _probe_overdrive_cancel() -> Dictionary:
	var rio := _new_player("rio", 20)
	var attacker := _new_player("frey", 21)
	rio._overdrive_start()
	await process_frame
	var swords_after_start: int = rio.overdrive_swords.size()
	rio.apply_hit(attacker, 1.0, 0.0, Vector2.RIGHT)
	var swords_after_normal_hit: int = rio.overdrive_swords.size()
	rio.attack_lock_timer = 0.0
	rio.hitstun_timer = 0.0
	rio._overdrive_start()
	await process_frame
	rio.rune_timer = 1.0
	rio.apply_hit(attacker, 1.0, 0.0, Vector2.RIGHT)
	var swords_after_absorbed_hit: int = rio.overdrive_swords.size()
	rio.queue_free()
	attacker.queue_free()
	await process_frame
	return {
		"swords_after_start": swords_after_start,
		"swords_after_normal_hit": swords_after_normal_hit,
		"swords_after_absorbed_hit": swords_after_absorbed_hit
	}

func _probe_concealment_lifecycle() -> Dictionary:
	var layout := REALM_LAYOUT.new()
	var midgard := _realm_named(layout, "Midgard")
	var state := {}
	for realm_index in layout.realm_count():
		state[realm_index] = "stable"
	var hazards: Node = REALM_HAZARDS.new()
	arena.add_child(hazards)
	hazards.setup(layout, func(realm_index: int) -> String: return str(state[realm_index]), 303)
	var rio := _new_player("rio", 4)
	layout.assign_combatant(rio, midgard)
	hazards.register_combatant(rio)
	var bush: Rect2 = hazards.get_bushes(midgard)[0]
	rio.global_position = Vector2(bush.get_center().x, bush.end.y - 4.0)
	hazards.advance(0.016)
	var hidden_initially: bool = rio.concealed
	state[midgard] = "collapsed"
	hazards.advance(0.016)
	var hidden_after_collapse: bool = rio.concealed
	state[midgard] = "stable"
	rio.global_position = Vector2(bush.get_center().x, bush.end.y - 4.0)
	hazards.advance(1.0)
	var hidden_again: bool = rio.concealed
	var destination := (midgard + 1) % layout.realm_count()
	layout.assign_combatant(rio, destination)
	hazards.advance(0.016)
	var hidden_after_portal_equivalent: bool = rio.concealed
	rio.set_concealed(true)
	var respawn_points: Array[Vector2] = [layout.pick_spawn(destination)]
	rio.set_spawn_points(respawn_points)
	rio._respawn()
	var hidden_immediately_after_respawn: bool = rio.concealed
	hazards.advance(0.016)
	var hidden_after_next_hazard_tick: bool = rio.concealed
	for node in [hazards, rio]:
		node.queue_free()
	await process_frame
	return {
		"hidden_initially": hidden_initially,
		"hidden_after_collapse": hidden_after_collapse,
		"hidden_again": hidden_again,
		"hidden_after_portal_equivalent": hidden_after_portal_equivalent,
		"hidden_immediately_after_respawn": hidden_immediately_after_respawn,
		"hidden_after_next_hazard_tick": hidden_after_next_hazard_tick
	}

func _probe_crystal_lifecycle() -> Dictionary:
	var layout := REALM_LAYOUT.new()
	var playable: Array[int] = [layout.get_corner_indices()[0]]
	var spawner: Node = CRYSTAL_SPAWNER.new()
	arena.add_child(spawner)
	spawner.configure(Callable(layout, "get_spawn_points"), func() -> Array[int]: return playable, 303)
	spawner.sync_playable_realms(playable)
	await process_frame
	var realm_index: int = playable[0]
	var fighter := _new_player("frey", 5)
	layout.assign_combatant(fighter, realm_index)
	var monster := StaticBody2D.new()
	monster.add_to_group("realm_monsters")
	arena.add_child(monster)
	var crystal: Node = spawner.get_crystal(realm_index)
	var monster_hit_landed: bool = crystal.apply_hit(monster, 99.0, 0.0, Vector2.ZERO)
	var hp_after_monster: float = crystal.hp
	var souls_before: int = fighter.souls
	for hit in CRYSTAL.HITS_TO_BREAK:
		crystal.apply_hit(fighter, 1.0, 0.0, Vector2.ZERO)
	var extra_hit_landed: bool = crystal.apply_hit(fighter, 1.0, 0.0, Vector2.ZERO)
	var souls_after_break: int = fighter.souls
	await process_frame

	spawner.sync_playable_realms(playable)
	await process_frame
	var collapse_crystal: Node = spawner.get_crystal(realm_index)
	playable.clear()
	spawner.sync_playable_realms(playable)
	var queued_after_collapse: bool = collapse_crystal.is_queued_for_deletion()
	var active_flag_after_collapse: bool = collapse_crystal.is_realm_active
	var souls_before_queued_hits: int = fighter.souls
	var queued_hit_results: Array[bool] = []
	for hit in CRYSTAL.HITS_TO_BREAK:
		queued_hit_results.append(collapse_crystal.apply_hit(fighter, 1.0, 0.0, Vector2.ZERO))
	var queued_crystal_paid: int = fighter.souls - souls_before_queued_hits
	await process_frame
	var crystal_after_collapse = spawner.get_crystal(realm_index)
	for node in [fighter, monster, spawner]:
		node.queue_free()
	return {
		"monster_hit_landed": monster_hit_landed,
		"hp_after_monster": hp_after_monster,
		"normal_break_reward": souls_after_break - souls_before,
		"extra_hit_after_break_landed": extra_hit_landed,
		"queued_after_collapse": queued_after_collapse,
		"active_flag_after_collapse": active_flag_after_collapse,
		"queued_hit_results": queued_hit_results,
		"queued_crystal_reward": queued_crystal_paid,
		"crystal_exists_next_frame": crystal_after_collapse != null
	}

func _probe_rio_ai_non_player_target() -> Dictionary:
	var rio := _new_player("rio", 6)
	# A real scripted crystal is needed because the AI reads hp/realm activity.
	var real_crystal := StaticBody2D.new()
	real_crystal.set_script(CRYSTAL)
	real_crystal.setup(0, rio.global_position + Vector2(100.0, 0.0))
	arena.add_child(real_crystal)
	await process_frame
	rio.realm_index = 0
	rio.ai_controller.target = real_crystal
	var choices := {"basic": 0, "skill_1": 0, "skill_2": 0}
	seed(303)
	for attempt in 100:
		rio.ai_controller.attack_cooldown = 0.0
		var choice: String = rio.ai_controller._choose_attack(rio, 100.0, 0.0)
		choices[choice] = int(choices.get(choice, 0)) + 1
	rio.queue_free()
	real_crystal.queue_free()
	await process_frame
	return choices

func _realm_named(layout: RefCounted, wanted: String) -> int:
	for realm_index in layout.realm_count():
		if str(layout.get_realm(realm_index).name) == wanted:
			return realm_index
	return -1
