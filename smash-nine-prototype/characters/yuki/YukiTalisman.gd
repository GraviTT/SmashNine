extends Area2D

const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const MONSTER_LAYER := 4

var source: Node
var damage := 6.0
var knockback := 180.0
var direction := Vector2.RIGHT
var speed := 650.0
var lifetime := 0.9
var elapsed := 0.0
var mode := "straight"
var burst_time := 0.0
var burst_duration := 0.16
var burst_size := Vector2(76, 58)
var hit_targets: Array[Node] = []

var shape: CollisionShape2D
var visual: ColorRect

func _ready() -> void:
	add_to_group("yuki_talismans")
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)

func configure(new_source: Node, size: Vector2, new_damage: float, new_knockback: float, new_direction: Vector2, color: Color, new_speed: float, new_lifetime: float, new_mode := "straight", new_burst_size := Vector2(76, 58)) -> void:
	source = new_source
	damage = new_damage
	knockback = new_knockback
	direction = new_direction.normalized()
	speed = new_speed
	lifetime = new_lifetime
	mode = new_mode
	burst_size = new_burst_size
	collision_layer = 0
	collision_mask = PLAYER_LAYER | MONSTER_LAYER | WORLD_LAYER
	shape = get_node("CollisionShape2D")
	visual = get_node("Visual")
	_set_size(size)
	visual.color = color
	visual.rotation = direction.angle()

func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	if burst_time > 0.0:
		burst_time = maxf(burst_time - delta, 0.0)
		_hit_overlapping_bodies()
		if burst_time <= 0.0:
			queue_free()
		return
	position += direction * speed * delta
	if mode == "flare" and elapsed >= 0.18:
		_begin_burst()

func _on_body_entered(body: Node) -> void:
	if body == source:
		return
	if body.has_method("is_owned_by") and body.is_owned_by(source):
		return
	if body.is_in_group("platforms"):
		if mode == "drop" or mode == "flare":
			_begin_burst()
		else:
			queue_free()
		return
	_hit_body(body)
	if mode == "straight" and hit_targets.has(body):
		queue_free()
	elif mode == "drop" and hit_targets.has(body):
		_begin_burst()

func _begin_burst() -> void:
	if burst_time > 0.0:
		return
	speed = 0.0
	burst_time = burst_duration
	_set_size(burst_size)
	visual.rotation = 0.0
	visual.color = Color(0.68, 0.92, 1.0, 0.66)
	_hit_overlapping_bodies()

func _set_size(size: Vector2) -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	visual.size = size
	visual.position = -size * 0.5
	visual.pivot_offset = size * 0.5

func _hit_overlapping_bodies() -> void:
	for body in get_overlapping_bodies():
		if not body.is_in_group("platforms"):
			_hit_body(body)

func _hit_body(body: Node) -> void:
	if body == source or hit_targets.has(body) or not body.has_method("apply_hit"):
		return
	if body.has_method("is_owned_by") and body.is_owned_by(source):
		return
	hit_targets.append(body)
	var landed = body.apply_hit(source, damage, knockback, direction)
	if landed != false and is_instance_valid(source) and source.has_method("on_attack_landed"):
		source.on_attack_landed(global_position, damage, knockback)
