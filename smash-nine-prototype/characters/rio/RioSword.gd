extends "res://scripts/Projectile.gd"
## Rio's thrown swords (2026-11-18, D50): the mana sword of K "마검 투척" and the six gem swords of
## I "마검 난무". A sword flies until it sticks in the first fighter or monster it reaches (a small
## hit), in a wall or the floor, or stops where its flight ends. There it waits for Rio to blink
## to it (`wait_time`); a sword in a body rides on it. A gem sword turns toward its target.
## Stand-in art: the gem sword picture tinted, or a code blade.

const GAME_SCALE := preload("res://scripts/GameScale.gd")
const GEM_SWORD_ART := "res://assets/art/effects/rio_gem_sword.png"
const WORLD_LAYER := 1
## How fast a gem sword turns toward its target (rad/s).
const HOMING_RATE := 9.0
var stuck := false
var stuck_body: Node2D
var stuck_offset := Vector2.ZERO
var wait_time := 3.0
var waited := 0.0
var homing_target: Node2D
var art: Node2D
var tint := Color.WHITE
## Expired (fading out): Rio no longer blinks to it.
var gone := false

func dress(new_tint: Color) -> void:
	tint = new_tint
	# Over the fighters (their drawings are z 1): a sword stuck in a body shows on it.
	z_index = 6
	if set_art(GEM_SWORD_ART, tint, 1.0):
		art = get_node_or_null("ArtSprite") as Node2D
		return
	var blade := Polygon2D.new()
	blade.polygon = PackedVector2Array([Vector2(-14, 0), Vector2(0, -5), Vector2(20, 0), Vector2(0, 5)])
	blade.color = tint
	blade.rotation = direction.angle()
	add_child(blade)
	art = blade

## True while it sticks in a fighter or monster that is still up.
func has_target() -> bool:
	return stuck and is_instance_valid(stuck_body) and not _is_down(stuck_body)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(source):
		_discard_orphaned_projectile()
		return
	if stuck:
		_ride(delta)
		return
	elapsed += delta
	_home(delta)
	var step := direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step, WORLD_LAYER)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit.position - direction * 6.0
		_stick(null)
		return
	position += step
	if PROJECTILE_BARRIERS.stopped(self, source):
		_discard_orphaned_projectile()
		return
	if elapsed >= lifetime:
		_stick(null)

func _ride(delta: float) -> void:
	waited += delta
	if is_instance_valid(stuck_body):
		if _is_down(stuck_body):
			stuck_body = null
		else:
			global_position = stuck_body.global_position + stuck_offset
	if waited >= wait_time:
		expire()

func _home(delta: float) -> void:
	if not is_instance_valid(homing_target) or _is_down(homing_target):
		return
	var wanted := (homing_target.global_position + GAME_SCALE.BODY_CENTRE - global_position).normalized()
	var turn := clampf(direction.angle_to(wanted), -HOMING_RATE * delta, HOMING_RATE * delta)
	direction = direction.rotated(turn)
	if is_instance_valid(art):
		_aim_art()

func _aim_art() -> void:
	# Art aimed left is mirrored, not turned upside down (ArtSettings.aimed_sprite).
	if art is Sprite2D:
		(art as Sprite2D).flip_h = direction.x < 0.0
		art.rotation = (-direction).angle() if direction.x < 0.0 else direction.angle()
	else:
		art.rotation = direction.angle()

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(source):
		_discard_orphaned_projectile()
		return
	if stuck or body == source or not body.has_method("apply_hit"):
		return
	if body.has_method("is_owned_by") and body.is_owned_by(source):
		return
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	var landed = body.apply_hit(source, damage, knockback, direction, damage_type)
	if landed == false:
		# Parried or not taken: the sword breaks.
		expire()
		return
	_stick.call_deferred(body as Node2D)

func _stick(body: Node2D) -> void:
	if stuck:
		return
	stuck = true
	set_deferred("monitoring", false)
	stuck_body = body
	if is_instance_valid(stuck_body):
		stuck_offset = global_position - stuck_body.global_position
	if is_instance_valid(source) and source.has_method("on_sword_stuck"):
		source.on_sword_stuck(self)

## Gone: a short fade.
func expire() -> void:
	if gone:
		return
	gone = true
	set_physics_process(false)
	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(queue_free)

static func _is_down(body: Node) -> bool:
	return body.get("is_defeated") == true or (body.has_method("is_down") and body.is_down())

