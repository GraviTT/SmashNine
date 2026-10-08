extends Area2D

const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const TALISMAN_ART := "res://assets/art/effects/yuki_talisman.png"
const GAME_SCALE := preload("res://scripts/GameScale.gd")
const VFX := preload("res://scripts/Vfx.gd")
## The burst art (Yuki's ward burst, CODEX-ART-13) is authored 192 px wide.
const BURST_ART_WIDTH := 192.0

const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const MONSTER_LAYER := 4

var source: Node
var damage := 6.0
var knockback := 180.0
var direction := Vector2.RIGHT
var speed := 650.0
var lifetime := 0.9
var elapsed := 0.0
var mode := "straight"
var burst_time := 0.0
var burst_duration := 0.16
var burst_size := Vector2(76, 58)
var hit_targets: Array[Node] = []

var shape: CollisionShape2D
var visual: ColorRect
var art_sprite: Sprite2D

func _ready() -> void:
	add_to_group("yuki_talismans")
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)

func configure(new_source: Node, size: Vector2, new_damage: float, new_knockback: float, new_direction: Vector2, color: Color, new_speed: float, new_lifetime: float, new_mode := "straight", new_burst_size := Vector2(76, 58)) -> void:
	source = new_source
	damage = new_damage
	knockback = new_knockback
	direction = new_direction.normalized()
	speed = new_speed
	lifetime = new_lifetime
	mode = new_mode
	burst_size = new_burst_size
	collision_layer = 0
	collision_mask = PLAYER_LAYER | MONSTER_LAYER | WORLD_LAYER
	shape = get_node("CollisionShape2D")
	visual = get_node("Visual")
	_set_size(size)
	visual.color = color
	visual.rotation = direction.angle()
	# Original talisman art while it flies; the burst keeps the coloured ward rect.
	var art := ART_SETTINGS.original_texture(TALISMAN_ART)
	if art != null:
		# 32 px wide when written; a redrawn larger file draws smaller (same size on screen).
		art_sprite = ART_SETTINGS.aimed_sprite(art, direction, 2.0 * GAME_SCALE.COMBAT / ART_SETTINGS.size_ratio(art, 32.0))
		add_child(art_sprite)
		visual.color.a = 0.0

func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	if burst_time > 0.0:
		burst_time = maxf(burst_time - delta, 0.0)
		_hit_overlapping_bodies()
		if burst_time <= 0.0:
			queue_free()
		return
	position += direction * speed * delta
	if mode == "flare" and elapsed >= 0.18:
		_begin_burst()

func _on_body_entered(body: Node) -> void:
	if body == source:
		return
	if body.has_method("is_owned_by") and body.is_owned_by(source):
		return
	# The burst resizes the collision shape: never inside the physics callback (it errors while
	# queries flush), so it starts right after (found 2026-10-08 once bots aimed up and down).
	if body.is_in_group("platforms"):
		if mode == "drop" or mode == "flare":
			_begin_burst.call_deferred()
		else:
			queue_free()
		return
	_hit_body(body)
	if mode == "straight" and hit_targets.has(body):
		queue_free()
	elif mode == "drop" and hit_targets.has(body):
		_begin_burst.call_deferred()

func _begin_burst() -> void:
	if burst_time > 0.0:
		return
	speed = 0.0
	burst_time = burst_duration
	_set_size(burst_size)
	visual.rotation = 0.0
	visual.color = Color(0.68, 0.92, 1.0, 0.66)
	if is_instance_valid(art_sprite):
		art_sprite.visible = false
		# With the original art the burst is Yuki's ward-burst strip, not a light-blue box
		# (seen in game 2026-10-09); the coloured rect stays for the plain style (F2).
		if VFX.spawn(get_parent(), "yuki_l", global_position, Vector2.ONE * (maxf(burst_size.x, burst_size.y) / BURST_ART_WIDTH), false, 5) != null:
			visual.color.a = 0.0
	_hit_overlapping_bodies()

func _set_size(size: Vector2) -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	visual.size = size
	visual.position = -size * 0.5
	visual.pivot_offset = size * 0.5

func _hit_overlapping_bodies() -> void:
	for body in get_overlapping_bodies():
		if not body.is_in_group("platforms"):
			_hit_body(body)

func _hit_body(body: Node) -> void:
	if body == source or hit_targets.has(body) or not body.has_method("apply_hit"):
		return
	if body.has_method("is_owned_by") and body.is_owned_by(source):
		return
	hit_targets.append(body)
	var landed = body.apply_hit(source, damage, knockback, direction)
	if landed != false and is_instance_valid(source) and source.has_method("on_attack_landed"):
		source.on_attack_landed(global_position, damage, knockback)
