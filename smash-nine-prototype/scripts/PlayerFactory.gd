extends RefCounted
## Builds a combatant node: the character scene (or a bare PlayerBase for the
## training dummy) plus collision, body rect, sprite slot, name and HP and soul bars.

const PLAYER_BASE_SCRIPT := preload("res://characters/common/PlayerBase.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const WORLD_LAYER := 1
const PLAYER_LAYER := 2

## body_type picks the male or female original sheet for characters drawn in both.
static func create(character_id := "", body_type := "") -> CharacterBody2D:
	var player: CharacterBody2D
	var character_scene := CHARACTER_REGISTRY.get_scene(character_id)
	if character_scene != null:
		player = character_scene.instantiate() as CharacterBody2D
	else:
		player = CharacterBody2D.new()
		player.set_script(PLAYER_BASE_SCRIPT)
	player.collision_layer = PLAYER_LAYER
	player.collision_mask = WORLD_LAYER
	if body_type != "":
		player.set("body_type", body_type)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(42, 64)
	shape.shape = rect
	shape.position = Vector2(0, -32)
	player.add_child(shape)

	var body := ColorRect.new()
	body.name = "Body"
	body.size = Vector2(42, 64)
	body.position = Vector2(-21, -64)
	player.add_child(body)

	player.add_child(_create_character_sprite())

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(-46, -105)
	name_label.size = Vector2(92, 42)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	player.add_child(name_label)

	player.add_child(_create_bar("HpBar", Vector2(54, 7), Vector2(-27, -78), Color(0.1, 0.1, 0.1, 0.9), Color(0.25, 1.0, 0.35)))
	player.add_child(_create_bar("SoulBar", Vector2(54, 5), Vector2(-27, -69), Color(0.08, 0.08, 0.12, 0.92), Color(0.62, 0.48, 1.0)))
	return player

static func _create_bar(bar_name: String, size: Vector2, position: Vector2, back_color: Color, fill_color: Color) -> ColorRect:
	var back := ColorRect.new()
	back.name = bar_name
	back.color = back_color
	back.size = size
	back.position = position
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.color = fill_color
	fill.size = size
	back.add_child(fill)
	return back

static func _create_character_sprite() -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = "CharacterSprite"
	sprite.position = Vector2(0, -32)
	sprite.scale = Vector2(2.0, 2.0)
	sprite.z_index = 1
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.visible = false
	return sprite
