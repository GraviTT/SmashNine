extends StaticBody2D

signal removed(seal: Node)

const MONSTER_LAYER := 4
const GAME_SCALE := preload("res://scripts/GameScale.gd")
const VFX := preload("res://scripts/Vfx.gd")
## The seal's pull and burst are attacks: GameScale.COMBAT.
const PULL_RADIUS := 135.0 * GAME_SCALE.COMBAT
const BURST_RADIUS := 148.0 * GAME_SCALE.COMBAT
const ACTIVE_TIME := 0.58

var owner_node: Node
var realm_index := 0
var remaining_time := 5.0
var activation_id := -1
var active := false
var active_elapsed := 0.0
var visual: ColorRect
var aura: Line2D
## The waiting paper seal (CODEX-ART-17); the coloured rect and outline stay for the plain style.
var idle_art: AnimatedSprite2D
## The art's anchor is its bottom centre; the paper's middle sits this far above it.
const IDLE_ART_DROP := 28.0

func _ready() -> void:
	add_to_group("yuki_seals")
	# The binding seal snapping shut (yuki_k, CODEX-ART-13), once it is placed.
	_play_seal_art.call_deferred()
	collision_layer = MONSTER_LAYER
	collision_mask = 0
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 42)
	collision.shape = rect
	add_child(collision)
	visual = ColorRect.new()
	visual.size = Vector2(24, 36)
	visual.position = Vector2(-12, -18)
	visual.pivot_offset = visual.size * 0.5
	visual.color = Color(0.62, 0.9, 1.0, 0.9)
	add_child(visual)
	aura = Line2D.new()
	aura.width = 3.0
	aura.default_color = Color(0.48, 0.82, 1.0, 0.65)
	aura.antialiased = true
	aura.points = PackedVector2Array([Vector2(-18, -25), Vector2(18, -25), Vector2(18, 25), Vector2(-18, 25), Vector2(-18, -25)])
	add_child(aura)
	idle_art = VFX.spawn(self, "yuki_seal_idle", Vector2(0.0, IDLE_ART_DROP), Vector2.ONE, true, 3, Color.WHITE, true)
	if idle_art != null:
		visual.visible = false
		aura.visible = false

func configure(new_owner: Node, new_realm_index: int, duration := 5.0) -> void:
	owner_node = new_owner
	realm_index = new_realm_index
	remaining_time = duration

func _physics_process(delta: float) -> void:
	if active:
		active_elapsed += delta
		_apply_pull(delta)
		var pulse := 1.0 + sin(active_elapsed * 24.0) * 0.1
		scale = Vector2(pulse, pulse)
		if active_elapsed >= ACTIVE_TIME:
			_burst()
		return
	remaining_time -= delta
	var life_ratio := clampf(remaining_time / 5.0, 0.0, 1.0)
	modulate.a = 0.35 + life_ratio * 0.65
	if remaining_time <= 0.0:
		_remove()

func activate(new_activation_id: int) -> void:
	if active:
		return
	active = true
	activation_id = new_activation_id
	active_elapsed = 0.0
	collision_layer = 0
	visual.color = Color(0.9, 0.98, 1.0, 1.0)
	aura.default_color = Color(0.7, 0.94, 1.0, 0.9)
	if idle_art != null:
		idle_art.modulate = Color(1.5, 1.5, 1.8)

func is_owned_by(node: Node) -> bool:
	return node == owner_node

func apply_hit(attacker: Node, _damage: float, _knockback: float, _direction: Vector2, _damage_type := "normal") -> bool:
	if active or attacker == owner_node:
		return false
	_play_break_effect()
	_remove()
	return true

func _apply_pull(delta: float) -> void:
	for target in _get_targets():
		if target == owner_node or not _same_realm(target):
			continue
		if global_position.distance_to(target.global_position) <= PULL_RADIUS and target.has_method("apply_control_pull"):
			target.apply_control_pull(global_position, 520.0, delta, 0.14)

func _burst() -> void:
	for target in _get_targets():
		if target == owner_node or not _same_realm(target):
			continue
		var offset: Vector2 = target.global_position - global_position
		if offset.length() <= BURST_RADIUS and target.has_method("apply_yuki_seal_burst"):
			var burst_direction := offset.normalized()
			if burst_direction == Vector2.ZERO:
				burst_direction = Vector2.UP
			target.apply_yuki_seal_burst(owner_node, activation_id, 11.0, 315.0, burst_direction)
	_play_burst_effect()
	_remove()

func _get_targets() -> Array[Node]:
	var targets: Array[Node] = []
	targets.append_array(get_tree().get_nodes_in_group("players"))
	targets.append_array(get_tree().get_nodes_in_group("realm_monsters"))
	return targets

func _same_realm(target: Node) -> bool:
	var target_realm = target.get("realm_index")
	return target_realm == null or int(target_realm) == realm_index

func _play_break_effect() -> void:
	var shard := ColorRect.new()
	shard.size = Vector2(38, 38)
	shard.position = global_position - shard.size * 0.5
	shard.color = Color(0.6, 0.9, 1.0, 0.72)
	get_parent().add_child(shard)
	var tween := shard.create_tween()
	tween.tween_property(shard, "scale", Vector2(1.6, 0.35), 0.12)
	tween.parallel().tween_property(shard, "modulate:a", 0.0, 0.12)
	tween.tween_callback(shard.queue_free)

func _play_seal_art() -> void:
	VFX.spawn(get_parent(), "yuki_k", global_position + Vector2(0, -4), Vector2.ONE * 1.1, false, 5)

func _play_burst_effect() -> void:
	VFX.spawn(get_parent(), "yuki_l", global_position, Vector2.ONE * (BURST_RADIUS * 2.0 / 192.0), false, 6)
	var burst := ColorRect.new()
	burst.size = Vector2(BURST_RADIUS * 2.0, BURST_RADIUS * 2.0)
	burst.position = global_position - burst.size * 0.5
	burst.pivot_offset = burst.size * 0.5
	burst.color = Color(0.48, 0.82, 1.0, 0.24)
	get_parent().add_child(burst)
	var tween := burst.create_tween()
	tween.tween_property(burst, "scale", Vector2(1.12, 1.12), 0.13)
	tween.parallel().tween_property(burst, "modulate:a", 0.0, 0.16)
	tween.tween_callback(burst.queue_free)

func _remove() -> void:
	removed.emit(self)
	queue_free()
