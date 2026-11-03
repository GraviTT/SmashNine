extends "res://scripts/Projectile.gd"
## Nova's gravity orb (K "중력 구체", 2026-11-03 D47): it bursts on the first body it reaches or
## where its flight ends; the source's orb_burst_at pulls whoever the burst catches.
## Its art is CODEX-VFX-05 a (1x; its own frames spin it); a core and a ring without it.

const ORB_ART := "nova_orb"
var burst_done := false
var spin: Node2D

func dress(radius: float) -> void:
	visual.visible = false
	if VFX.spawn(self, ORB_ART, Vector2.ZERO, Vector2.ONE, true, 0, Color.WHITE, true) != null:
		return
	spin = Node2D.new()
	add_child(spin)
	var core := Polygon2D.new()
	var points := PackedVector2Array()
	for index in 16:
		points.append(Vector2.RIGHT.rotated(TAU * float(index) / 16.0) * radius)
	core.polygon = points
	core.color = Color(0.3, 0.14, 0.52, 0.92)
	spin.add_child(core)
	var ring := Line2D.new()
	ring.points = points
	ring.closed = true
	ring.width = 3.0
	ring.default_color = Color(0.72, 0.5, 1.0, 0.95)
	spin.add_child(ring)

func _physics_process(delta: float) -> void:
	if is_instance_valid(spin):
		spin.rotation += delta * 9.0
	if not burst_done and is_instance_valid(source) and elapsed + delta >= lifetime:
		_burst()
		return
	super(delta)

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(source):
		_discard_orphaned_projectile()
		return
	if burst_done or body == source or not body.has_method("apply_hit"):
		return
	# Not inside the physics callback: the burst reads overlaps and adds effects.
	set_deferred("monitoring", false)
	_burst.call_deferred()

func _burst() -> void:
	if burst_done:
		return
	burst_done = true
	set_deferred("monitoring", false)
	if is_instance_valid(source) and source.has_method("orb_burst_at"):
		source.orb_burst_at(global_position)
	queue_free()
