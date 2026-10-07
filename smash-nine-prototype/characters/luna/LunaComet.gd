extends Area2D

const ATTACK_SCRIPT := preload("res://scripts/Attack.gd")
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const STAR_ART := "res://assets/art/effects/luna_star.png"

var source: Node
var direction := Vector2.RIGHT
var speed := 620.0
var max_distance := 260.0
var traveled_distance := 0.0
var bloom_damage := 12.0
var bloom_knockback := 390.0
var bloom_size := Vector2(96, 82)
var bloom_color := Color(1.0, 0.56, 0.92, 0.74)
var trail_timer := 0.0
var detonated := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)

func configure(new_source: Node, new_direction: Vector2, new_damage: float, new_knockback: float) -> void:
	source = new_source
	direction = new_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	bloom_damage = new_damage
	bloom_knockback = new_knockback
	rotation = direction.angle()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(26, 22)
	collision_shape.shape = shape
	visual.polygon = _make_star_points(15.0, 7.0)
	visual.color = Color(1.0, 0.92, 0.45, 0.96)
	# Original star bolt (CODEX-ART-05); this node is already turned to the direction,
	# so the sprite only flips upright when flying left.
	var art := ART_SETTINGS.original_texture(STAR_ART)
	if art != null:
		var sprite := Sprite2D.new()
		sprite.texture = art
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(2.0, 2.0)
		sprite.flip_v = direction.x < 0.0
		add_child(sprite)
		visual.visible = false

func _physics_process(delta: float) -> void:
	if not is_instance_valid(source):
		queue_free()
		return
	var travel_step := speed * delta
	global_position += direction * travel_step
	traveled_distance += travel_step
	trail_timer -= delta
	if trail_timer <= 0.0:
		trail_timer = 0.035
		_spawn_trail()
	if traveled_distance >= max_distance:
		_detonate()

func _on_body_entered(body: Node) -> void:
	if body == source or not body.has_method("apply_hit"):
		return
	_detonate()

func _detonate() -> void:
	if detonated:
		return
	detonated = true
	set_deferred("monitoring", false)
	set_physics_process(false)
	call_deferred("_finish_detonation")

func _finish_detonation() -> void:
	if is_instance_valid(source) and is_instance_valid(get_parent()):
		var attack := Area2D.new()
		attack.set_script(ATTACK_SCRIPT)
		attack.collision_layer = 0
		attack.collision_mask = 2 | 4
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var attack_visual := ColorRect.new()
		attack_visual.name = "Visual"
		attack.add_child(shape)
		attack.add_child(attack_visual)
		get_parent().add_child(attack)
		attack.global_position = global_position
		attack.configure(source, bloom_size, Vector2.ZERO, bloom_damage, bloom_knockback, direction, bloom_color, 0.13)
		_spawn_bloom_flash()
	queue_free()

func _spawn_trail() -> void:
	if not is_instance_valid(get_parent()):
		return
	var trail := Polygon2D.new()
	trail.polygon = _make_star_points(10.0, 4.5)
	trail.color = Color(0.42, 0.95, 1.0, 0.42)
	trail.z_index = 4
	get_parent().add_child(trail)
	trail.global_position = global_position
	var tween := trail.create_tween()
	tween.tween_property(trail, "scale", Vector2(0.35, 0.35), 0.1)
	tween.parallel().tween_property(trail, "modulate:a", 0.0, 0.1)
	tween.tween_callback(trail.queue_free)

func _spawn_bloom_flash() -> void:
	var flash := Polygon2D.new()
	flash.polygon = _make_star_points(42.0, 18.0)
	flash.color = Color(1.0, 0.86, 0.34, 0.86)
	flash.z_index = 6
	get_parent().add_child(flash)
	flash.global_position = global_position
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector2(1.75, 1.75), 0.14)
	tween.parallel().tween_property(flash, "rotation", 0.45, 0.14)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.14)
	tween.tween_callback(flash.queue_free)

func _make_star_points(outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 10:
		var radius := outer_radius if index % 2 == 0 else inner_radius
		var angle := -PI * 0.5 + TAU * float(index) / 10.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
