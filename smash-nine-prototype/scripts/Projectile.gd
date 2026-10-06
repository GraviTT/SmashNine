extends Area2D

var source: Node
var damage := 8.0
var knockback := 380.0
var direction := Vector2.RIGHT
var speed := 620.0
var lifetime := 1.25
var hit_targets: Array[Node] = []
var damage_type := "normal"

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func configure(new_source: Node, size: Vector2, new_damage: float, new_knockback: float, new_direction: Vector2, color: Color, new_speed := 620.0, new_lifetime := 1.25, new_damage_type := "normal") -> void:
	source = new_source
	damage = new_damage
	knockback = new_knockback
	direction = new_direction.normalized()
	speed = new_speed
	lifetime = new_lifetime
	damage_type = new_damage_type
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	visual.size = size
	visual.position = -size * 0.5
	visual.color = color

func _physics_process(delta: float) -> void:
	if not is_instance_valid(source):
		_discard_orphaned_projectile()
		return
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(source):
		_discard_orphaned_projectile()
		return
	if body == source or hit_targets.has(body):
		return
	if body.has_method("apply_hit"):
		hit_targets.append(body)
		body.apply_hit(source, damage, knockback, direction, damage_type)
		queue_free()

func _discard_orphaned_projectile() -> void:
	set_deferred("monitoring", false)
	set_physics_process(false)
	queue_free()
