extends Node2D
## Nova's gravity field (L "중력 필드", 2026-11-03 D47): a circle that stays where she cast it.
## Inside, other fighters walk and jump as at gravity stage 1 (no stack) and neutral monsters
## float helpless; Nova flies in it (Nova.gd asks `contains`). Its art is CODEX-VFX-05 b (the
## rim at 300 px at 1x); code shapes without it.

const GAME_SCALE := preload("res://scripts/GameScale.gd")
const VFX := preload("res://scripts/Vfx.gd")
const FILL_COLOR := Color(0.46, 0.26, 0.86, 0.12)
const RIM_COLOR := Color(0.74, 0.52, 1.0, 0.8)

var fighter: Node2D
var radius := 300.0
var duration := 6.0
var elapsed := 0.0
var finished := false
var rings: Node2D
var rim: Line2D
var art_sprite: AnimatedSprite2D

func configure(owner_fighter: Node2D, new_radius: float, new_duration: float) -> void:
	fighter = owner_fighter
	radius = new_radius
	duration = new_duration
	_build_visual()

func is_active() -> bool:
	return not finished and elapsed < duration

## Whether a world point is inside the field.
func contains(point: Vector2) -> bool:
	return is_active() and point.distance_to(global_position) <= radius

func _physics_process(delta: float) -> void:
	if finished:
		return
	if not is_instance_valid(fighter) or fighter.get("is_defeated") == true:
		end_field()
		return
	elapsed += delta
	if elapsed >= duration:
		end_field()
		return
	var realm = fighter.get("realm_index")
	for target in get_tree().get_nodes_in_group("players"):
		if target == fighter or target.get("is_defeated") == true or target.get("realm_index") != realm:
			continue
		if contains((target as Node2D).global_position + GAME_SCALE.BODY_CENTRE):
			target.apply_gravity_field(0.1)
	for monster in get_tree().get_nodes_in_group("realm_monsters"):
		if monster.get("realm_index") != null and monster.get("realm_index") != realm:
			continue
		if monster.has_method("apply_gravity_float") and contains((monster as Node2D).global_position):
			monster.apply_gravity_float(0.15)
	if is_instance_valid(rings):
		rings.rotation += delta * 0.6
	# It blinks in its last second.
	var shown: CanvasItem = art_sprite if is_instance_valid(art_sprite) else rim
	if is_instance_valid(shown):
		shown.modulate.a = 1.0 if elapsed < duration - 1.0 else (0.35 if int(elapsed * 10.0) % 2 == 0 else 1.0)

func end_field() -> void:
	if finished:
		return
	finished = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

func _build_visual() -> void:
	art_sprite = VFX.spawn(self, "nova_field", Vector2.ZERO, Vector2.ONE * radius / 300.0, true, 0, Color.WHITE, true)
	if art_sprite != null:
		return
	var fill := Polygon2D.new()
	fill.polygon = _circle(radius, 48)
	fill.color = FILL_COLOR
	add_child(fill)
	rim = Line2D.new()
	rim.points = _circle(radius, 48)
	rim.closed = true
	rim.width = 4.0
	rim.default_color = RIM_COLOR
	rim.antialiased = true
	add_child(rim)
	rings = Node2D.new()
	add_child(rings)
	for index in 2:
		var ring := Line2D.new()
		var points := PackedVector2Array()
		var reach := radius * (0.45 + 0.25 * index)
		for step in 7:
			points.append(Vector2.RIGHT.rotated(TAU * float(step) / 24.0 + index * PI) * reach)
		ring.points = points
		ring.width = 3.0
		ring.default_color = Color(RIM_COLOR, 0.5)
		ring.antialiased = true
		rings.add_child(ring)

func _circle(r: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		points.append(Vector2.RIGHT.rotated(TAU * float(index) / float(count)) * r)
	return points
