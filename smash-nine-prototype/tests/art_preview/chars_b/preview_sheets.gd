extends SceneTree

const REPORT_DIR := "res://../reports/codex-art-03b"
const CELL := Vector2i(64, 64)
const SCALE := Vector2(2.0, 2.0)
const BACKGROUND := Color("071622")
const SPECS := [
	{"name": "FREY", "path": "res://assets/art/frey/frey_sheet.png"},
	{"name": "LUNA", "path": "res://assets/art/luna/luna_sheet.png"},
	{"name": "RIO MALE", "path": "res://assets/art/rio/rio_male_sheet.png"},
	{"name": "RIO FEMALE", "path": "res://assets/art/rio/rio_female_sheet.png"},
]
const ANIMATIONS := [
	{"name": "idle", "row": 0, "count": 4},
	{"name": "walk", "row": 1, "count": 6},
	{"name": "jump", "row": 2, "count": 1},
	{"name": "fall", "row": 3, "count": 1},
	{"name": "attack", "row": 4, "count": 4},
	{"name": "shield", "row": 5, "count": 6},
	{"name": "hurt", "row": 6, "count": 1},
]

var textures: Array[Texture2D] = []
var screenshots: Array[Image] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for spec in SPECS:
		var image := Image.load_from_file(String(spec.path))
		if image.is_empty():
			push_error("Could not load %s" % String(spec.path))
			quit(1)
			return
		var texture := ImageTexture.create_from_image(image)
		textures.append(texture)
	for animation in ANIMATIONS:
		await _capture_animation(animation)
	_save_animation_contact_sheet()
	await _capture_roster_contact()
	print("[chars-b-preview] PASS comparisons=7 roster_contact=1 scale=2x")
	quit()

func _capture_animation(animation: Dictionary) -> void:
	var width := 1120
	var height := 620
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, height)
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	get_root().add_child(viewport)
	var stage := Node2D.new()
	viewport.add_child(stage)
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.size = Vector2(width, height)
	stage.add_child(background)
	_add_label(stage, "%s — 2x nearest-neighbour, Frey scale reference" % String(animation.name).to_upper(), Vector2(24, 12), 22)
	for spec_index in range(SPECS.size()):
		var baseline := 145.0 + spec_index * 145.0
		_add_label(stage, String(SPECS[spec_index].name), Vector2(24, baseline - 93), 16)
		_add_baseline(stage, baseline, width)
		for frame_index in range(int(animation.count)):
			_add_sprite(stage, textures[spec_index], int(animation.row), frame_index, Vector2(225.0 + frame_index * 140.0, baseline - 64.0))
	await process_frame
	await process_frame
	var image := viewport.get_texture().get_image()
	var output := "%s/compare_%s.png" % [REPORT_DIR, String(animation.name)]
	if image.save_png(output) != OK:
		push_error("Could not save %s" % output)
	screenshots.append(image)
	viewport.queue_free()
	await process_frame

func _add_sprite(parent: Node, texture: Texture2D, row: int, column: int, position: Vector2) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(column * CELL.x, row * CELL.y, CELL.x, CELL.y)
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.position = position
	sprite.scale = SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(sprite)

func _add_label(parent: Node, value: String, position: Vector2, size: int) -> void:
	var label := Label.new()
	label.text = value
	label.position = position
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("d8ecf5"))
	parent.add_child(label)

func _add_baseline(parent: Node, y: float, width: int) -> void:
	var line := Line2D.new()
	line.width = 1.0
	line.default_color = Color(0.2, 0.75, 0.9, 0.55)
	line.points = PackedVector2Array([Vector2(180, y), Vector2(width - 24, y)])
	parent.add_child(line)

func _save_animation_contact_sheet() -> void:
	var width := screenshots[0].get_width()
	var height := screenshots[0].get_height()
	var contact := Image.create(width, height * screenshots.size(), false, Image.FORMAT_RGBA8)
	contact.fill(BACKGROUND)
	for index in range(screenshots.size()):
		contact.blit_rect(screenshots[index], Rect2i(Vector2i.ZERO, screenshots[index].get_size()), Vector2i(0, index * height))
	contact.save_png("%s/contact_sheet.png" % REPORT_DIR)

func _capture_roster_contact() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1740, 560)
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	get_root().add_child(viewport)
	var stage := Node2D.new()
	viewport.add_child(stage)
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.size = Vector2(viewport.size)
	stage.add_child(background)
	_add_label(stage, "SMASH NINE REALMS — CHARACTER SHEETS", Vector2(24, 12), 22)
	for index in range(SPECS.size()):
		_add_label(stage, String(SPECS[index].name), Vector2(28 + index * 425, 52), 16)
		var sprite := Sprite2D.new()
		sprite.texture = textures[index]
		sprite.centered = false
		sprite.position = Vector2(28 + index * 425, 84)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		stage.add_child(sprite)
	await process_frame
	await process_frame
	var image := viewport.get_texture().get_image()
	image.save_png("%s/roster_contact.png" % REPORT_DIR)
	viewport.queue_free()
	await process_frame
