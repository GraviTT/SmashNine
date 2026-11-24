extends AnimatableBody2D
## Rio's decoy (U "분신 바꿔치기", 2026-11-18 D50): his drawing of the moment, blue and
## see-through, standing where he cast it. Hits and shots reach it like a fighter (player layer,
## no collisions with bodies); the first foe's hit bursts it (the source's decoy_burst). Rio can
## swap places with it once. It fades after `lifetime`. Stand-in look: his own frame tinted.
## A kinematic body, not a static one (2026-11-24): attack areas are not monitorable, which makes
## them static in the physics broadphase, and two static objects are never paired. As a
## StaticBody2D no swing ever reached it: no decoy burst in eight soak matches or at 40 px.

const PLAYER_LAYER := 2
const TINT := Color(0.5, 0.78, 1.0, 0.62)
var source: Node2D
var lifetime := 4.0
var elapsed := 0.0
var burst := false
var figure: AnimatedSprite2D

func configure(owner_fighter: Node2D, duration: float, sprite: AnimatedSprite2D) -> void:
	source = owner_fighter
	lifetime = duration
	sync_to_physics = false
	collision_layer = PLAYER_LAYER
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(42, 64)
	shape.shape = rect
	shape.position = Vector2(0, -32)
	add_child(shape)
	if is_instance_valid(sprite) and sprite.sprite_frames != null:
		figure = AnimatedSprite2D.new()
		figure.name = "Figure"
		figure.sprite_frames = sprite.sprite_frames
		figure.animation = sprite.animation
		figure.frame = sprite.frame
		figure.flip_h = sprite.flip_h
		figure.position = sprite.position
		figure.scale = sprite.scale
		figure.texture_filter = sprite.texture_filter
		figure.modulate = TINT
		add_child(figure)
	else:
		var body := ColorRect.new()
		body.size = Vector2(42, 64)
		body.position = Vector2(-21, -64)
		body.color = TINT
		add_child(body)

func is_owned_by(node: Node) -> bool:
	return node == source

func _physics_process(delta: float) -> void:
	if not is_instance_valid(source) or source.get("is_defeated") == true:
		queue_free()
		return
	elapsed += delta
	# A slow shimmer, and a quick fade in its last 0.4 s.
	var alpha := TINT.a * (0.85 + 0.15 * sin(elapsed * 9.0))
	if elapsed > lifetime - 0.4:
		alpha *= clampf((lifetime - elapsed) / 0.4, 0.0, 1.0)
	modulate.a = alpha / TINT.a
	if elapsed >= lifetime:
		queue_free()

## A foe's hit or shot bursts it (Rio's own pass through). It takes nothing: the hit does not land.
func apply_hit(attacker: Node, _damage: float, _knockback: float, _direction: Vector2, _damage_type := "normal") -> bool:
	if burst or attacker == source or not is_instance_valid(source):
		return false
	burst = true
	if source.has_method("decoy_burst"):
		source.decoy_burst(self)
	set_deferred("collision_layer", 0)
	queue_free()
	return false
