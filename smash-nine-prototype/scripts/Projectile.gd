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
## Opt-in monster art tracking; set_art() callers retain their original behaviour.
var _tracked_art: Node2D
var _art_aimed := true

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual

func _ready() -> void:
	set_process(false)
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

## Monster-only strip entry. Texture input also supports procedural/in-memory art.
## A frame can be rectangular (the slam strip has 64x48 frames).
func set_art_strip(texture: Texture2D, frames: int, fps := 12.0, aimed := true, art_scale := 2.0) -> bool:
	if texture == null or frames < 2 or texture.get_width() % frames != 0:
		return false
	var frame_width := texture.get_width() / frames
	var animations := SpriteFrames.new()
	animations.set_animation_speed(&"default", fps)
	animations.set_animation_loop(&"default", true)
	for index in frames:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(index * frame_width, 0, frame_width, texture.get_height())
		animations.add_frame(&"default", frame)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "ArtSprite"
	sprite.sprite_frames = animations
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * art_scale * art_scale_multiplier
	add_child(sprite)
	sprite.play()
	visual.visible = false
	track_art_direction(aimed)
	return true

## Only monster callers opt in, including their legacy still sprites.
func track_art_direction(aimed: bool) -> void:
	_tracked_art = get_node_or_null("ArtSprite") as Node2D
	_art_aimed = aimed
	set_process(is_instance_valid(_tracked_art))
	_update_art_direction()

func _process(_delta: float) -> void:
	_update_art_direction()

func _update_art_direction() -> void:
	if not is_instance_valid(_tracked_art):
		return
	_tracked_art.flip_h = direction.x < 0.0
	_tracked_art.rotation = (-direction).angle() if direction.x < 0.0 else direction.angle()
	if not _art_aimed:
		_tracked_art.rotation = 0.0

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
