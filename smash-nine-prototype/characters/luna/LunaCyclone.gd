extends "res://scripts/Projectile.gd"
## Brave Luna's fired cyclone (L "별의 회오리", 2026-11-03 D45): it flies through everyone in its
## path; each body it reaches is stunned, then thrown up by the source (on_cyclone_hit).
## Drawn as swirling arcs until the cyclone art is in.

const CYCLONE_ART := "luna_cyclone"
var swirl: Node2D

func _ready() -> void:
	super()
	set_process(true)

func dress(height: float) -> void:
	visual.visible = false
	if VFX.SPECS.has(CYCLONE_ART) and VFX.available(CYCLONE_ART):
		VFX.spawn(self, CYCLONE_ART, Vector2.ZERO, Vector2.ONE * height / 150.0, true, 0, Color.WHITE, true)
		return
	swirl = Node2D.new()
	add_child(swirl)
	for index in 3:
		var arc := Line2D.new()
		var points := PackedVector2Array()
		for step in 9:
			var angle := TAU * float(index) / 3.0 + float(step) * 0.24
			var reach := height * (0.22 + 0.025 * float(step))
			points.append(Vector2(cos(angle) * reach * 0.7, sin(angle) * reach))
		arc.points = points
		arc.width = 5.0
		arc.default_color = Color(1.0, 0.72, 0.9, 0.85) if index != 1 else Color(1.0, 0.88, 0.45, 0.9)
		arc.antialiased = true
		swirl.add_child(arc)

func _process(delta: float) -> void:
	if is_instance_valid(swirl):
		swirl.rotation += delta * 12.0

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(source):
		_discard_orphaned_projectile()
		return
	if body == source or hit_targets.has(body) or not body.has_method("apply_hit"):
		return
	hit_targets.append(body)
	if source.has_method("on_cyclone_hit"):
		source.on_cyclone_hit(body, direction)
