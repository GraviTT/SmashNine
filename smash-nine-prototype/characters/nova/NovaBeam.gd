extends "res://scripts/Projectile.gd"
## Nova's gravity beam (U "중력 광선", 2026-11-03 D47): the first body it reaches goes to the
## source's on_beam_hit (dragged to her, or slammed down when airborne). A tether runs from her
## hand to the beam's head. Drawn in code until the beam has its own art.

const GAME_SCALE := preload("res://scripts/GameScale.gd")
const TETHER_COLOR := Color(0.74, 0.5, 1.0, 0.85)
var tether: Line2D
var head: Polygon2D

func dress() -> void:
	visual.visible = false
	tether = Line2D.new()
	tether.width = 5.0
	tether.default_color = TETHER_COLOR
	tether.antialiased = true
	add_child(tether)
	head = Polygon2D.new()
	var points := PackedVector2Array()
	for index in 12:
		points.append(Vector2.RIGHT.rotated(TAU * float(index) / 12.0) * (11.0 if index % 2 == 0 else 6.0))
	head.polygon = points
	head.color = Color(0.92, 0.82, 1.0, 0.95)
	add_child(head)
	_update_tether()

func _physics_process(delta: float) -> void:
	super(delta)
	_update_tether()

func _update_tether() -> void:
	if not is_instance_valid(tether) or not is_instance_valid(source):
		return
	tether.points = PackedVector2Array([to_local(source.global_position + GAME_SCALE.BODY_CENTRE), Vector2.ZERO])
	head.rotation += 0.4

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(source):
		_discard_orphaned_projectile()
		return
	if body == source or hit_targets.has(body) or not body.has_method("apply_hit"):
		return
	hit_targets.append(body)
	set_deferred("monitoring", false)
	if source.has_method("on_beam_hit"):
		source.on_beam_hit.call_deferred(body, direction)
	queue_free()
