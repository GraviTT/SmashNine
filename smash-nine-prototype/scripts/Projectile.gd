extends Area2D

var source: Node
var damage := 8.0
var knockback := 380.0
var direction := Vector2.RIGHT
var speed := 620.0
var lifetime := 1.25
var elapsed := 0.0
var hit_targets: Array[Node] = []
var damage_type := "normal"
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const VFX := preload("res://scripts/Vfx.gd")
## Effect strip played where this projectile hits (scripts/Vfx.gd name), tinted.
var impact_vfx := ""
var impact_tint := Color.WHITE
## Fighters' projectiles are drawn at GameScale.COMBAT (set by PlayerBase); monsters' at 1.
var art_scale_multiplier := 1.0
## Widths the callers' art scales were written for (files redrawn bigger draw smaller).
const AUTHORED_ART_WIDTH := {"rio_gem_sword.png": 48.0, "rio_mana_wave.png": 24.0, "yuki_talisman.png": 32.0, "luna_star.png": 24.0}

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)

func configure(new_source: Node, size: Vector2, new_damage: float, new_knockback: float, new_direction: Vector2, color: Color, new_speed := 620.0, new_lifetime := 1.25, new_damage_type := "normal") -> void:
	source = new_source
	damage = new_damage
	knockback = new_knockback
	direction = new_direction.normalized()
	speed = new_speed
	lifetime = new_lifetime
	damage_type = new_damage_type
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	visual.size = size
	visual.position = -size * 0.5
	visual.color = color

## Original art in place of the coloured rect (the hitbox stays). Returns false when the
## art is missing or the prototype style is on.
func set_art(path: String, tint := Color.WHITE, art_scale := 2.0) -> bool:
	var texture := ART_SETTINGS.original_texture(path)
	if texture == null:
		return false
	var ratio := ART_SETTINGS.size_ratio(texture, float(AUTHORED_ART_WIDTH.get(path.get_file(), texture.get_width())))
	var sprite := ART_SETTINGS.aimed_sprite(texture, direction, art_scale * art_scale_multiplier / ratio)
	sprite.modulate = tint
	add_child(sprite)
	visual.visible = false
	return true

func _physics_process(delta: float) -> void:
	if not is_instance_valid(source):
		_discard_orphaned_projectile()
		return
	# Counted here rather than with a timer from _ready(): configure() sets lifetime after the node enters the tree.
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(source):
		_discard_orphaned_projectile()
		return
	if body == source or hit_targets.has(body):
		return
	if body.has_method("apply_hit"):
		hit_targets.append(body)
		body.apply_hit(source, damage, knockback, direction, damage_type)
		if impact_vfx != "":
			VFX.spawn(get_parent(), impact_vfx, global_position, Vector2.ONE * 1.4 * art_scale_multiplier, false, 5, impact_tint)
		queue_free()

func _discard_orphaned_projectile() -> void:
	set_deferred("monitoring", false)
	set_physics_process(false)
	queue_free()
