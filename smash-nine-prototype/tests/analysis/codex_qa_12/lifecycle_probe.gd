extends SceneTree
## QA-12 focused reproduction: ultimate-window reset and Yuki ward ownership.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const GRAND_WARD_SCRIPT := preload("res://characters/yuki/YukiGrandWard.gd")

var arena: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _fighter(character_id: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, false)
	fighter.realm_index = 0
	fighter.ringout_y = 100000.0
	fighter.set_physics_process(false)
	return fighter

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	await process_frame
	_probe_window_after_map_reset()
	_probe_ward_after_owner_defeat()
	arena.queue_free()
	await process_frame
	quit(0)

func _probe_window_after_map_reset() -> void:
	var attacker := _fighter("frey", 1, Vector2.ZERO)
	attacker.ultimate_window_timer = 1.25
	var ultimate_hits: Array[bool] = []
	attacker.ultimate_hit.connect(func(_player: Node, _at: Vector2) -> void: ultimate_hits.append(true))
	var points: Array[Vector2] = [Vector2(300, 100)]
	attacker.reset_for_map(Vector2(300, 100), points)
	attacker.on_attack_landed(attacker.global_position, 5.0, 200.0)
	print("QA12_WINDOW %s" % JSON.stringify({
		"timer_after_reset": attacker.ultimate_window_timer,
		"ordinary_landing_emitted_ultimate_hit": ultimate_hits.size(),
		"attacker_hitstop": attacker.hitstop_timer,
		"normal_hitstop": attacker.ATTACKER_HITSTOP,
	}))
	attacker.queue_free()

func _probe_ward_after_owner_defeat() -> void:
	var owner := _fighter("yuki", 2, Vector2.ZERO)
	var victim := _fighter("frey", 3, Vector2(40, 0))
	var ward := Node2D.new()
	ward.set_script(GRAND_WARD_SCRIPT)
	arena.add_child(ward)
	ward.global_position = Vector2.ZERO
	ward.configure(owner, 0)
	ward.set_physics_process(false)
	owner.apply_environment_damage(owner.hp + 1.0)
	var hp_before: float = victim.hp
	var ultimate_hits: Array[bool] = []
	owner.ultimate_window_timer = 1.0
	owner.ultimate_hit.connect(func(_player: Node, _at: Vector2) -> void: ultimate_hits.append(true))
	ward._pulse(false)
	print("QA12_WARD %s" % JSON.stringify({
		"owner_defeated": owner.is_defeated,
		"ward_valid_after_defeat": is_instance_valid(ward) and not ward.is_queued_for_deletion(),
		"victim_damage_after_owner_defeat": hp_before - victim.hp,
		"victim_hitstop": victim.hitstop_timer,
		"owner_ultimate_hit_signals": ultimate_hits.size(),
	}))
	ward.queue_free()
	owner.queue_free()
	victim.queue_free()
