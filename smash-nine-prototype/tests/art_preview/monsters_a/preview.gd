extends SceneTree

const CANVAS_SIZE := Vector2i(1600, 1000)
const BACKGROUND := Color("08121d")
const PANEL := Color("101e2d")
const GOLD := Color("f5c86b")
const TEXT := Color("e8eef5")


func _initialize() -> void:
	DisplayServer.window_set_size(CANVAS_SIZE)
	get_root().content_scale_size = CANVAS_SIZE
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(canvas)
	_add_rect(canvas, Rect2(Vector2.ZERO, CANVAS_SIZE), BACKGROUND)
	_add_label(canvas, "SMASH NINE REALMS  |  CODEX-ART-05A MONSTER / SOUL ASSET PREVIEW", Vector2(24, 14), 24, GOLD)
	_add_label(canvas, "Every production frame shown at 2x nearest-neighbour game scale", Vector2(26, 48), 15, TEXT)

	_add_rect(canvas, Rect2(20, 82, 1560, 144), PANEL)
	_add_label(canvas, "Scale reference", Vector2(34, 92), 17, GOLD)
	_add_label(canvas, "Frey", Vector2(78, 198), 14, TEXT)
	_add_frame(canvas, "res://assets/art/frey/frey_sheet.png", Rect2i(0, 0, 64, 64), Vector2(42, 72), 2.0)
	_add_label(canvas, "Mossling", Vector2(230, 198), 14, TEXT)
	_add_frame(canvas, "res://assets/art/monsters/mossling_sheet.png", Rect2i(0, 0, 64, 64), Vector2(222, 72), 2.0)
	_add_label(canvas, "Ember Imp", Vector2(410, 198), 14, TEXT)
	_add_frame(canvas, "res://assets/art/monsters/ember_imp_sheet.png", Rect2i(0, 0, 64, 64), Vector2(410, 72), 2.0)
	_add_label(canvas, "Soul crystal", Vector2(612, 198), 14, TEXT)
	_add_frame(canvas, "res://assets/art/objects/soul_crystal.png", Rect2i(0, 0, 48, 64), Vector2(624, 72), 2.0)
	_add_label(canvas, "Fireball", Vector2(790, 198), 14, TEXT)
	_add_frame(canvas, "res://assets/art/monsters/ember_fireball.png", Rect2i(0, 0, 24, 24), Vector2(810, 118), 2.0)
	_add_label(canvas, "Shared 64px cells and silhouettes make the scale relationship directly inspectable.", Vector2(920, 125), 15, TEXT)

	_add_label(canvas, "Mossling: idle / walk / attack / hurt", Vector2(20, 238), 17, GOLD)
	_add_rect(canvas, Rect2(20, 266, 768, 512), PANEL)
	_add_sprite(canvas, "res://assets/art/monsters/mossling_sheet.png", Vector2(20, 266), 2.0)

	_add_label(canvas, "Ember Imp: idle / walk / throw / hurt", Vector2(812, 238), 17, GOLD)
	_add_rect(canvas, Rect2(812, 266, 768, 512), PANEL)
	_add_sprite(canvas, "res://assets/art/monsters/ember_imp_sheet.png", Vector2(812, 266), 2.0)

	_add_label(canvas, "Soul crystal shimmer", Vector2(20, 798), 17, GOLD)
	_add_rect(canvas, Rect2(20, 826, 384, 128), PANEL)
	_add_sprite(canvas, "res://assets/art/objects/soul_crystal.png", Vector2(20, 826), 2.0)
	_add_label(canvas, "Soul crystal shatter", Vector2(430, 798), 17, GOLD)
	_add_rect(canvas, Rect2(430, 826, 384, 128), PANEL)
	_add_sprite(canvas, "res://assets/art/objects/soul_crystal_shatter.png", Vector2(430, 826), 2.0)
	_add_label(canvas, "24x24 projectile", Vector2(850, 798), 17, GOLD)
	_add_rect(canvas, Rect2(850, 826, 128, 128), PANEL)
	_add_frame(canvas, "res://assets/art/monsters/ember_fireball.png", Rect2i(0, 0, 24, 24), Vector2(866, 842), 4.0)
	_add_label(canvas, "Preview enlargement: 4x", Vector2(1000, 872), 15, TEXT)

	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := get_root().get_texture().get_image()
	var output := ProjectSettings.globalize_path("res://../reports/codex-art-05a/preview.png")
	var error := screenshot.save_png(output)
	if error == OK:
		print("PREVIEW_OK %s size=%dx%d" % [output, screenshot.get_width(), screenshot.get_height()])
		quit(0)
	else:
		push_error("Preview save failed: %s" % error_string(error))
		quit(1)


func _add_sprite(parent: Control, path: String, top_left: Vector2, scale_value: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(Image.load_from_file(path))
	sprite.centered = false
	sprite.position = top_left
	sprite.scale = Vector2.ONE * scale_value
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(sprite)


func _add_frame(parent: Control, path: String, region: Rect2i, top_left: Vector2, scale_value: float) -> void:
	var source := Image.load_from_file(path)
	var frame := source.get_region(region)
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(frame)
	sprite.centered = false
	sprite.position = top_left
	sprite.scale = Vector2.ONE * scale_value
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(sprite)


func _add_rect(parent: Control, rect: Rect2, color: Color) -> void:
	var panel := ColorRect.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.color = color
	parent.add_child(panel)


func _add_label(parent: Control, value: String, position: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = value
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
