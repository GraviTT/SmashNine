extends Area2D

var source: Node
var damage := 8.0
var knockback := 260.0
var lifetime := 0.8
var elapsed := 0.0
var end_on_hit := false
var hit_targets: Array[Node] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)

func configure(new_source: Node, radius: float, new_damage: float, new_knockback: float, new_lifetime: float, color: Color, should_end_on_hit := false) -> void:
	source = new_source
	damage = new_damage
	knockback = new_knockback
	lifetime = new_lifetime
	end_on_hit = should_end_on_hit
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	visual.polygon = _make_circle_points(radius, 20)
	visual.color = color

func _physics_process(delta: float) -> void:
	if not is_instance_valid(source):
		queue_free()
		return
	elapsed += delta
	global_position = source.global_position + Vector2(0, -32)
	rotation += delta * 7.0
	for body in get_overlapping_bodies():
		_hit_body(body)
	if elapsed >= lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_hit_body(body)

func _hit_body(body: Node) -> void:
	if body == source or hit_targets.has(body) or not body.has_method("apply_hit"):
		return
	hit_targets.append(body)
	var direction: Vector2
	if source.has_method("get_nova_impact_direction"):
		direction = source.get_nova_impact_direction()
	else:
		direction = source.velocity.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2(float(source.facing), -0.08).normalized()
	var landed = body.apply_hit(source, damage, knockback, direction)
	if landed == false:
		return
	if source.has_method("on_attack_landed"):
		source.on_attack_landed(global_position, damage, knockback)
	if end_on_hit and source.has_method("on_nova_ultimate_contact"):
		source.on_nova_ultimate_contact(global_position)

func _make_circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := TAU * float(index) / float(count)
		var wave := 1.0 if index % 2 == 0 else 0.78
		points.append(Vector2(cos(angle), sin(angle)) * radius * wave)
	return points
