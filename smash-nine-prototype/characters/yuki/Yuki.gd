extends "res://characters/common/PlayerBase.gd"

const ANIMATION := preload("res://characters/common/CharacterAnimation.gd")
const TALISMAN_SCRIPT := preload("res://characters/yuki/YukiTalisman.gd")
const SEAL_SCRIPT := preload("res://characters/yuki/YukiSeal.gd")
const GRAND_WARD_SCRIPT := preload("res://characters/yuki/YukiGrandWard.gd")

var seals: Array[Node] = []
var activation_id := 0

## Original sheet only (third-party prototype art removed 2026-10-07, user).
func configure_character_sprite() -> void:
	_configure_original_sheet("yuki")

func perform_basic_attack(attack_type: String, direction: Vector2) -> void:
	match attack_type:
		"up", "air_up":
			_start_attack(0.14, 0.24, Callable(self, "_spawn_talisman").bind(Vector2(22, 30), 7, 225, Vector2(0.08 * facing, -1.0), 520.0, 0.52, "flare", Vector2(82, 74)))
		"down":
			_start_attack(0.14, 0.26, Callable(self, "_ground_ward"))
		"air_down":
			_start_attack(0.16, 0.27, Callable(self, "_spawn_talisman").bind(Vector2(24, 28), 8, 295, Vector2(0.12 * facing, 1.0), 610.0, 1.0, "drop", Vector2(94, 50)))
		"air_side":
			_start_attack(0.09, 0.18, Callable(self, "_spawn_talisman").bind(Vector2(28, 14), 6, 175, direction, 720.0, 0.78, "straight", Vector2(72, 48)))
		_:
			_start_attack(0.11, 0.21, Callable(self, "_spawn_talisman").bind(Vector2(30, 16), 6, 190, direction, 660.0, 0.95, "straight", Vector2(74, 50)))

func perform_skill_one() -> void:
	_seal_start()

func perform_skill_two() -> void:
	_activate_start()

func perform_ultimate() -> void:
	_ultimate_start()

func character_cleanup() -> void:
	_clear_seals()

func character_on_respawn() -> void:
	_clear_seals()

func _spawn_talisman(size: Vector2, damage: float, knockback: float, direction: Vector2, talisman_speed: float, lifetime: float, mode: String, burst_size: Vector2) -> void:
	var talisman := Area2D.new()
	talisman.set_script(TALISMAN_SCRIPT)
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var visual := ColorRect.new()
	visual.name = "Visual"
	talisman.add_child(shape)
	talisman.add_child(visual)
	get_parent().add_child(talisman)
	talisman.global_position = global_position + direction.normalized() * 38.0 + Vector2(0, -34)
	talisman.configure(self, size, damage, knockback, direction, Color(0.58, 0.88, 1.0, 0.9), talisman_speed, lifetime, mode, burst_size)

func _ground_ward() -> void:
	_spawn_sweeping_attack(Vector2(54, 46), [
		Vector2(4 * facing, -24),
		Vector2(38 * facing, -8),
		Vector2(76 * facing, 8)
	], 7, 285, Vector2(facing, -0.1), Color(0.46, 0.82, 1.0, 0.52), 0.13)

func _seal_start() -> void:
	var direction := _to_cardinal_direction(_get_attack_direction())
	if not is_on_floor():
		velocity *= 0.38
	_start_attack(0.18, 0.32, Callable(self, "_place_seal").bind(direction))

func _place_seal(direction: Vector2) -> void:
	_cleanup_seals()
	if seals.size() >= 2:
		var oldest: Node = seals.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	var seal: Node = StaticBody2D.new()
	seal.set_script(SEAL_SCRIPT)
	get_parent().add_child(seal)
	var offset: Vector2 = direction * 145.0
	if direction == Vector2.DOWN and is_on_floor():
		offset = Vector2(0, -24)
	elif absf(direction.x) > 0.0:
		offset.y = -34.0
	seal.global_position = global_position + offset
	seal.configure(self, realm_index, 5.0)
	seal.removed.connect(_on_seal_removed)
	seals.append(seal)

func _activate_start() -> void:
	_cleanup_seals()
	if seals.is_empty():
		_start_attack(0.16, 0.3, Callable(self, "_emergency_ward"))
	else:
		_start_attack(0.24, 0.32, Callable(self, "_activate_seals"))

func _activate_seals() -> void:
	_cleanup_seals()
	activation_id += 1
	for seal in seals.duplicate():
		if is_instance_valid(seal):
			seal.activate(activation_id)
	seals.clear()

func _emergency_ward() -> void:
	_spawn_sweeping_attack(Vector2(58, 62), [Vector2(-18, -28), Vector2(-62, -24), Vector2(-92, -18)], 6, 260, Vector2(-1, -0.08), Color(0.52, 0.86, 1.0, 0.46), 0.12)
	_spawn_sweeping_attack(Vector2(58, 62), [Vector2(18, -28), Vector2(62, -24), Vector2(92, -18)], 6, 260, Vector2(1, -0.08), Color(0.52, 0.86, 1.0, 0.46), 0.12)

func _ultimate_start() -> void:
	var direction := _to_cardinal_direction(_get_attack_direction())
	_start_attack(0.52, 0.62, Callable(self, "_cast_grand_ward").bind(direction))

func _cast_grand_ward(direction: Vector2) -> void:
	_cleanup_seals()
	if not seals.is_empty():
		_activate_seals()
	var ward := Node2D.new()
	ward.set_script(GRAND_WARD_SCRIPT)
	get_parent().add_child(ward)
	var offset := direction * 220.0
	if absf(direction.x) > 0.0:
		offset.y = -38.0
	elif direction == Vector2.DOWN and is_on_floor():
		offset = Vector2(0, -30)
	ward.global_position = global_position + offset
	ward.configure(self, realm_index)

func _cleanup_seals() -> void:
	var valid_seals: Array[Node] = []
	for seal in seals:
		if is_instance_valid(seal) and not seal.is_queued_for_deletion():
			valid_seals.append(seal)
	seals = valid_seals

func _on_seal_removed(seal: Node) -> void:
	seals.erase(seal)

func _clear_seals() -> void:
	for seal in seals:
		if is_instance_valid(seal):
			seal.queue_free()
	seals.clear()
