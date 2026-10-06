extends Area2D

var source: Node
var damage := 8.0
var knockback := 300.0
var momentum_ratio := 0.0
var hit_tag := ""
var lifetime := 0.14
var elapsed := 0.0
var hit_targets: Array[Node] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)

func configure(new_source: Node, radius: float, new_damage: float, new_knockback: float, new_momentum_ratio: float, color: Color, new_hit_tag := "") -> void:
	source = new_source
	damage = new_damage
	knockback = new_knockback
	momentum_ratio = new_momentum_ratio
	hit_tag = new_hit_tag
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	visual.polygon = _make_circle_points(radius, 32)
	visual.color = color
	var ring := Line2D.new()
	ring.points = _make_circle_points(radius, 32)
	ring.closed = true
	ring.width = 5.0
	ring.default_color = Color(color.r, color.g, color.b, minf(color.a + 0.22, 1.0))
	ring.antialiased = true
	add_child(ring)
	visual.scale = Vector2(0.48, 0.48)
	ring.scale = Vector2(0.48, 0.48)
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2.ONE, lifetime)
	tween.parallel().tween_property(ring, "scale", Vector2.ONE, lifetime)
	tween.parallel().tween_property(visual, "modulate:a", 0.0, lifetime)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, lifetime)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(source):
		queue_free()
		return
	elapsed += delta
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
	var direction: Vector2 = (body.global_position - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2(float(source.facing), -0.1).normalized()
	var landed = body.apply_hit(source, damage, knockback, direction)
	if landed == false:
		return
	if source.has_method("on_attack_landed"):
		source.on_attack_landed(body.global_position + Vector2(0, -28), damage, knockback)
	if source.has_method("on_nova_gravity_burst_landed"):
		source.on_nova_gravity_burst_landed(momentum_ratio, hit_tag)

func _make_circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := TAU * float(index) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
