extends SceneTree
## Focused adversarial probes that call the real match and character rule code.

const MAIN_SCENE := "res://scenes/Main.tscn"
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const MATCH_DIRECTOR := preload("res://scripts/match/MatchDirector.gd")
const SOUL_CARDS := preload("res://scripts/match/SoulCards.gd")

var arena: Node2D
var characters: Dictionary

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	characters = CHARACTER_REGISTRY.get_characters()
	var result := {
		"spawn_pairs_8": await _probe_spawn_pairs(8, 711),
		"spawn_pairs_16": await _probe_spawn_pairs(16, 716),
		"collapse_last_two": await _probe_collapse_last_two(),
		"post_match_combat": await _probe_post_match_combat(),
		"relocation_attack": await _probe_relocation_attack(),
		"ultimate_followups": await _probe_ultimate_followups(),
		"soak_cause_attribution": await _probe_soak_cause_attribution(),
		"triple_last_stand": await _probe_triple_last_stand()
	}
	print("PROBE_RESULT ", JSON.stringify(result))
	arena.queue_free()
	await process_frame
	quit(0)

func _probe_spawn_pairs(count: int, probe_seed: int) -> Dictionary:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.player_count = count
	main.match_seed = probe_seed
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var by_realm: Dictionary = {}
	for player in main.players:
		player.set_physics_process(false)
		if not by_realm.has(player.realm_index):
			by_realm[player.realm_index] = []
		by_realm[player.realm_index].append(player.character_id)
	var rows: Array[Dictionary] = []
	var all_mirrors := true
	for realm_index in by_realm:
		var roster: Array = by_realm[realm_index]
		all_mirrors = all_mirrors and roster.size() == 2 and roster[0] == roster[1]
		rows.append({"realm": realm_index, "characters": roster})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.realm < b.realm)
	main.queue_free()
	await process_frame
	return {"seed": probe_seed, "all_pairs_are_mirrors": all_mirrors, "realms": rows}

func _probe_collapse_last_two() -> Dictionary:
	var director: Node = MATCH_DIRECTOR.new()
	arena.add_child(director)
	director.setup(REALM_LAYOUT.new())
	var corner: int = director.layout.get_corner_indices()[0]
	var first := _new_player("frey", 1, director, corner)
	var second := _new_player("yuki", 2, director, corner)
	await process_frame
	first.set_physics_process(false)
	second.set_physics_process(false)
	first.hp = 20.0
	second.hp = 20.0
	director.advance(MATCH_DIRECTOR.WAVE_ONE_COLLAPSE)
	var result := {
		"seed": "deterministic",
		"match_over": director.match_over,
		"finish_reason": director.finish_reason,
		"winner_id": director.winner.player_id if is_instance_valid(director.winner) else -1,
		"winner_is_defeated": director.winner.is_defeated if is_instance_valid(director.winner) else false,
		"alive_count": director.get_alive_combatants().size(),
		"first_defeated": first.is_defeated,
		"second_defeated": second.is_defeated
	}
	first.queue_free()
	second.queue_free()
	director.queue_free()
	await process_frame
	return result

func _probe_soak_cause_attribution() -> Dictionary:
	var attacker: Node = PLAYER_FACTORY.create("frey")
	var victim: Node = PLAYER_FACTORY.create("yuki")
	arena.add_child(attacker)
	arena.add_child(victim)
	attacker.setup(characters.frey, 61, false)
	victim.setup(characters.yuki, 62, false)
	await process_frame
	attacker.set_physics_process(false)
	victim.set_physics_process(false)
	var counts := {"classified_player_events": 0}
	victim.hp_changed.connect(func(changed: Node) -> void:
		if is_instance_valid(changed.last_attacker) and changed.last_attacker.is_in_group("players"):
			counts.classified_player_events = int(counts.classified_player_events) + 1)
	victim.apply_hit(attacker, 1.0, 0.0, Vector2.RIGHT)
	victim.apply_environment_damage(1.0)
	var result := {
		"actual_player_hits": 1,
		"environment_damage_events": 1,
		"events_classified_as_player_by_soak_logic": counts.classified_player_events,
		"last_attacker_timer_after_environment_damage": snappedf(victim.last_attacker_timer, 0.1)
	}
	attacker.queue_free()
	victim.queue_free()
	await process_frame
	return result

func _probe_ultimate_followups() -> Dictionary:
	var nova: Node = PLAYER_FACTORY.create("nova")
	arena.add_child(nova)
	nova.setup(characters.nova, 51, false)
	await process_frame
	nova.set_physics_process(false)
	nova.global_position = Vector2(-5000.0, 0.0)
	nova.ultimate()
	var nova_cooldown_after_start: float = nova.ultimate_cooldown_timer
	nova.ultimate()
	var nova_after_first_followup: int = nova.ultimate_phase
	nova.ultimate()
	var nova_after_second_followup: int = nova.ultimate_phase

	var luna: Node = PLAYER_FACTORY.create("luna")
	arena.add_child(luna)
	luna.setup(characters.luna, 52, false)
	await process_frame
	luna.set_physics_process(false)
	luna.global_position = Vector2(5000.0, 0.0)
	luna.ultimate()
	await create_timer(0.3).timeout
	luna.attack_lock_timer = 0.0
	var luna_cooldown_after_start: float = luna.ultimate_cooldown_timer
	luna.ultimate()
	var result := {
		"nova": {
			"cooldown_after_start": nova_cooldown_after_start,
			"phase_after_first_followup": nova_after_first_followup,
			"phase_after_second_followup": nova_after_second_followup,
			"cooldown_after_followups": nova.ultimate_cooldown_timer
		},
		"luna": {
			"transformed": luna.transformed,
			"heart_laser_started": luna.transformation_finishing,
			"cooldown_after_start": luna_cooldown_after_start,
			"cooldown_after_followup": luna.ultimate_cooldown_timer
		}
	}
	nova.queue_free()
	luna.queue_free()
	await process_frame
	return result

func _probe_post_match_combat() -> Dictionary:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.player_count = 2
	main.match_seed = 801
	root.add_child(main)
	await process_frame
	main.players[0].apply_environment_damage(999.0)
	var winner: Node = main.get_winner()
	var physics_after_finish := winner.is_physics_processing()
	winner.apply_environment_damage(999.0)
	var result := {
		"seed": 801,
		"match_over": main.match_over,
		"winner_id": winner.player_id,
		"winner_physics_processing_after_finish": physics_after_finish,
		"winner_can_be_defeated_after_finish": winner.is_defeated,
		"alive_after_post_finish_damage": main.director.get_alive_combatants().size()
	}
	main.queue_free()
	await process_frame
	return result

func _probe_relocation_attack() -> Dictionary:
	var player: Node = PLAYER_FACTORY.create("yuki")
	arena.add_child(player)
	player.setup(characters.yuki, 31, false)
	await process_frame
	player.set_physics_process(false)
	var old_position := Vector2(100.0, 100.0)
	var new_position := Vector2(5000.0, 500.0)
	player.global_position = old_position
	player.basic_attack()
	var new_spawn_points: Array[Vector2] = [new_position]
	player.reset_for_map(new_position, new_spawn_points)
	await create_timer(0.14).timeout
	var spawned: Array[Dictionary] = []
	for child in arena.get_children():
		if child is Area2D and child.get("source") == player:
			spawned.append({"node": child.get_class(), "x": snappedf(child.global_position.x, 0.1), "y": snappedf(child.global_position.y, 0.1)})
	var result := {
		"character": "yuki",
		"startup_seconds": 0.11,
		"relocated_immediately": true,
		"spawned_after_relocation": not spawned.is_empty(),
		"spawned_nodes": spawned
	}
	player.queue_free()
	await process_frame
	return result

func _probe_triple_last_stand() -> Dictionary:
	var player: Node = PLAYER_FACTORY.create("frey")
	arena.add_child(player)
	player.setup(characters.frey, 41, false)
	await process_frame
	player.set_physics_process(false)
	var card: Dictionary = SOUL_CARDS.find("last_stand")
	for pick in 3:
		player.apply_upgrade(card)
	player.ringout_damage = 40.0
	var hp_before: float = player.hp
	player._ringout()
	var result := {
		"copies": 3,
		"ringout_scale": snappedf(player.ringout_damage_scale, 0.001),
		"sudden_death_ringout_damage": snappedf(hp_before - player.hp, 0.01),
		"unmodified_damage": 40.0,
		"max_hp_after_three_picks": snappedf(player.max_hp, 0.1)
	}
	player.queue_free()
	await process_frame
	return result

func _new_player(character_id: String, player_id: int, director: Node, realm_index: int) -> Node:
	var player: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(player)
	player.setup(characters[character_id], player_id, false)
	director.layout.assign_combatant(player, realm_index)
	player.global_position = director.layout.pick_spawn(realm_index)
	director.register_combatant(player)
	return player
