extends CharacterBody2D
## Xion's doppelganger (U "도플갱어", 2026-11-18, the user's kit and corrections): the Xion of another
## timeline who fights beside her (the user's story, 2026-11-19), drawn as a hologram of her own
## figure: one crimson tone, see-through, scanlines and a flicker, as in the story concepts C-F
## (reports/xion-art-2026-11-19/). It floats through walls and floors. It hunts the foe fighter she hit
## last (or follows her when there is none) at half a fighter's run, and pins the first foe fighter
## it touches for 3 s (PlayerBase.apply_pin_hold), sitting on that foe's head; then it is gone.
## It cannot be destroyed: a foe's hit or shot pushes it away by the hit's knockback and halves its
## speed for 2 s; while it pins, nothing moves it. Her own attacks, monsters and hazards pass
## through it, and bots do not aim at it (it is not in the "players" group). It lasts 30 s. Xion
## can dive to it (U again) while it pins a foe near her: that spends it and frees the foe.

const PLAYER_LAYER := 2
const GAME_SCALE := preload("res://scripts/GameScale.gd")
const TINT := Color(0.66, 0.18, 0.28, 0.74)
## The hologram (stand-in until its art is picked, D49): her drawing turned to one crimson tone by
## its brightness, every third screen row dimmer, a bright band sweeping down, see-through.
const HOLOGRAM_ALPHA := 0.62
const HOLOGRAM_SHADER := """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.96, 0.24, 0.34, 1.0);
void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float lum = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	float lines = 0.55 + 0.45 * step(0.5, fract(FRAGCOORD.y / 3.0));
	float sweep = 1.0 - smoothstep(0.0, 0.05, abs(fract(FRAGCOORD.y / 170.0 - TIME * 0.7) - 0.5));
	vec3 holo = tint.rgb * (0.42 + 0.85 * lum) * (1.0 + 0.6 * sweep);
	COLOR = vec4(holo * COLOR.rgb, base.a * lines * COLOR.a);
}
"""
## Now and then it drops out for a moment, like a weak signal.
const FLICKER_CHANCE := 0.025
const FLICKER_TIME := 0.06
## Pinning, its feet stand this far above the pinned foe's feet (on the head).
const HEAD_SEAT := 96.0
## With no foe to hunt it hovers behind Xion, this far from her feet (x away from where she faces).
const FOLLOW_OFFSET := Vector2(-46.0, -24.0)
const FOLLOW_STOP := 18.0
const PUSH_DECAY := 980.0 * GAME_SCALE.KNOCKBACK
const FADE_TIME := 0.25

var source: Node2D
var lifetime := 30.0
var elapsed := 0.0
var speed := 200.0
var slow_time := 2.0
var slow_timer := 0.0
var pin_time := 3.0
var pin_left := 0.0
var pinned: Node2D
var push := Vector2.ZERO
var gone := false
var realm := 0
var figure: AnimatedSprite2D
var grab_area: Area2D
var flicker_timer := 0.0

func configure(owner_fighter: Node2D, duration: float, move_speed: float, pin_seconds: float, slow_seconds: float, sprite: AnimatedSprite2D) -> void:
	source = owner_fighter
	lifetime = duration
	speed = move_speed
	pin_time = pin_seconds
	slow_time = slow_seconds
	realm = int(owner_fighter.get("realm_index"))
	collision_layer = PLAYER_LAYER
	collision_mask = 0
	z_index = 2
	add_child(_body_shape())
	grab_area = Area2D.new()
	grab_area.name = "GrabArea"
	grab_area.collision_layer = 0
	grab_area.collision_mask = PLAYER_LAYER
	grab_area.monitorable = false
	grab_area.add_child(_body_shape())
	add_child(grab_area)
	if is_instance_valid(sprite) and sprite.sprite_frames != null:
		figure = AnimatedSprite2D.new()
		figure.name = "Figure"
		figure.sprite_frames = sprite.sprite_frames
		figure.position = sprite.position
		figure.scale = sprite.scale
		figure.texture_filter = sprite.texture_filter
		figure.flip_h = sprite.flip_h
		var shader := Shader.new()
		shader.code = HOLOGRAM_SHADER
		var hologram := ShaderMaterial.new()
		hologram.shader = shader
		figure.material = hologram
		figure.modulate = Color(1.0, 1.0, 1.0, HOLOGRAM_ALPHA)
		add_child(figure)
		var float_row := StringName("%s_double_float" % str(owner_fighter.get("character_id")))
		if figure.sprite_frames.has_animation(float_row):
			figure.play(float_row)
		else:
			figure.animation = sprite.animation
			figure.frame = sprite.frame
	else:
		var look := ColorRect.new()
		look.size = Vector2(42, 64)
		look.position = Vector2(-21, -64)
		look.color = TINT
		add_child(look)

func _body_shape() -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(42, 64)
	shape.shape = rect
	shape.position = Vector2(0, -32)
	return shape

func is_owned_by(node: Node) -> bool:
	return node == source

func is_pinning() -> bool:
	return is_instance_valid(pinned) and pin_left > 0.0

func time_left() -> float:
	return maxf(lifetime - elapsed, 0.0)

func _physics_process(delta: float) -> void:
	if gone:
		return
	if not is_instance_valid(source) or source.get("is_defeated") == true or int(source.get("realm_index")) != realm:
		vanish()
		return
	elapsed += delta
	_flicker(delta)
	if is_pinning():
		if pinned.get("is_defeated") == true:
			vanish()
			return
		pin_left = maxf(pin_left - delta, 0.0)
		global_position = pinned.global_position + Vector2(0.0, -HEAD_SEAT)
		if pin_left <= 0.0:
			vanish()
		return
	if elapsed >= lifetime:
		vanish()
		return
	slow_timer = maxf(slow_timer - delta, 0.0)
	var to_goal := _goal() - global_position
	var pace := speed * (0.5 if slow_timer > 0.0 else 1.0)
	var step := Vector2.ZERO
	if to_goal.length() > FOLLOW_STOP:
		step = to_goal.normalized() * minf(pace * delta, to_goal.length())
	global_position += step + push * delta
	push = push.move_toward(Vector2.ZERO, PUSH_DECAY * delta)
	if is_instance_valid(figure) and absf(step.x) > 0.01:
		figure.flip_h = step.x < 0.0
	_try_pin()

## The hologram's shimmer: a quick ripple in its see-through, and now and then a short drop-out.
func _flicker(delta: float) -> void:
	if not is_instance_valid(figure):
		return
	flicker_timer = maxf(flicker_timer - delta, 0.0)
	if flicker_timer <= 0.0 and randf() < FLICKER_CHANCE:
		flicker_timer = FLICKER_TIME
	var alpha := HOLOGRAM_ALPHA * (0.9 + 0.1 * sin(elapsed * 37.0))
	figure.modulate.a = alpha * (0.35 if flicker_timer > 0.0 else 1.0)

## The foe Xion hit last while it is up in her realm, else a spot behind her.
func _goal() -> Vector2:
	var foe := hunted()
	if foe != null:
		return foe.global_position
	var side := float(source.get("facing")) if source.get("facing") != null else 1.0
	return source.global_position + Vector2(FOLLOW_OFFSET.x * side, FOLLOW_OFFSET.y)

func hunted() -> Node2D:
	var foe: Variant = source.get("last_hit_foe")
	if foe is Node2D and is_instance_valid(foe) and _is_foe(foe):
		return foe as Node2D
	return null

func _try_pin() -> void:
	for body in grab_area.get_overlapping_bodies():
		if _can_pin(body) and body.apply_pin_hold(source, pin_time):
			pinned = body as Node2D
			pin_left = pin_time
			push = Vector2.ZERO
			global_position = pinned.global_position + Vector2(0.0, -HEAD_SEAT)
			if source.has_method("on_double_pinned"):
				source.on_double_pinned(self, pinned)
			return

func _is_foe(body: Node) -> bool:
	return body is Node2D and body != source and body.is_in_group("players") \
		and body.get("is_defeated") != true and int(body.get("realm_index")) == realm \
		and body.has_method("apply_pin_hold")

func _can_pin(body: Node) -> bool:
	if not _is_foe(body):
		return false
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return false
	return not (body.has_method("is_pinned") and body.is_pinned())

## A foe fighter's hit or shot pushes it and slows it; nothing else touches it, and nothing moves
## it while it pins. The hit never lands (no reward for hitting it).
func apply_hit(attacker: Node, _damage: float, knockback: float, direction: Vector2, _damage_type := "normal") -> bool:
	if gone or attacker == source or not is_instance_valid(attacker) or not attacker.is_in_group("players"):
		return false
	if is_pinning():
		return false
	var away := direction.normalized()
	if away.length() < 0.01 and attacker is Node2D:
		away = Vector2(signf(global_position.x - (attacker as Node2D).global_position.x), -0.2).normalized()
	push += away * maxf(knockback, 0.0) * GAME_SCALE.KNOCKBACK
	slow_timer = slow_time
	_flash()
	return false

func _flash() -> void:
	if not is_instance_valid(figure):
		return
	figure.self_modulate = Color(2.2, 2.2, 2.2)
	var tween := figure.create_tween()
	tween.tween_property(figure, "self_modulate", Color.WHITE, 0.16)

## Xion dove to it: it is spent and the pinned foe goes free.
func spend() -> void:
	vanish()

## Gone (time up, the pin over, spent, or Xion down or away): a pinned foe goes free, Xion's
## cooldown starts, and it fades.
func vanish() -> void:
	if gone:
		return
	gone = true
	# Always free the foe, the 3 s up too: the foe's own pin timer stops in its hitstops (a pinned
	# foe under the barrage is in hitstop most of the time), so it can outlast the doppelganger's.
	if is_instance_valid(pinned) and pinned.has_method("release_pin_hold"):
		pinned.release_pin_hold()
	pinned = null
	pin_left = 0.0
	set_deferred("collision_layer", 0)
	if is_instance_valid(grab_area):
		grab_area.set_deferred("monitoring", false)
	if is_instance_valid(source) and source.has_method("on_double_gone"):
		source.on_double_gone(self)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)
