extends SceneTree

const REPORT_DIR := "res://../reports/codex-art-03a"
const CELL := Vector2i(64, 64)
const PREVIEW_SCALE := Vector2(2.0, 2.0)
const BACKGROUND := Color("071622")
const SHEETS := [
	{"name": "FREY", "path": "res://assets/art/frey/frey_sheet.png"},
	{"name": "YUKI", "path": "res://assets/art/yuki/yuki_sheet.png"},
	{"name": "NOVA MALE", "path": "res://assets/art/nova/nova_male_sheet.png"},
	{"name": "NOVA FEMALE", "path": "res://assets/art/nova/nova_female_sheet.png"},
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
	for spec in SHEETS:
		var image := Image.load_from_file(spec.path)
		if image.is_empty():
			push_error("Could not load %s" % spec.path)
			quit(1)
			return
		var texture := ImageTexture.create_from_image(image)
		textures.append(texture)
	for animation in ANIMATIONS:
		await _capture_animation(animation)
	_save_contact_sheet()
	print("[chars-a-preview] captured %d animation comparisons and contact_sheet.png" % screenshots.size())
	quit()

func _capture_animation(animation: Dictionary) -> void:
	var width := 1120
	var row_height := 150
	var height := 55 + row_height * SHEETS.size()
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
	_add_label(stage, "%s — 2x nearest-neighbour / Frey scale reference" % String(animation.name).to_upper(), Vector2(20, 10), 22)
	var spacing := 145.0
	var start_x := 250.0
	for sheet_index in range(SHEETS.size()):
		var baseline := 50.0 + (sheet_index + 1) * row_height - 20.0
		_add_label(stage, SHEETS[sheet_index].name, Vector2(20, baseline - 94), 17)
		_add_baseline(stage, baseline, width)
		for frame_index in range(animation.count):
			_add_sprite(stage, textures[sheet_index], animation.row, frame_index, Vector2(start_x + frame_index * spacing, baseline - 32.0))
	await process_frame
	await process_frame
	var image := viewport.get_texture().get_image()
	var output := "%s/compare_%s.png" % [REPORT_DIR, animation.name]
	var error := image.save_png(output)
	if error != OK:
		push_error("Could not save %s: %s" % [output, error_string(error)])
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
	sprite.scale = PREVIEW_SCALE
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
	line.points = PackedVector2Array([Vector2(180, y), Vector2(width - 20, y)])
	parent.add_child(line)

func _save_contact_sheet() -> void:
	if screenshots.is_empty():
		return
	var width := screenshots[0].get_width()
	var total_height := 0
	for screenshot in screenshots:
		total_height += screenshot.get_height()
	var contact := Image.create(width, total_height, false, Image.FORMAT_RGBA8)
	contact.fill(BACKGROUND)
	var y := 0
	for screenshot in screenshots:
		contact.blit_rect(screenshot, Rect2i(Vector2i.ZERO, screenshot.get_size()), Vector2i(0, y))
		y += screenshot.get_height()
	var output := "%s/contact_sheet.png" % REPORT_DIR
	var error := contact.save_png(output)
	if error != OK:
		push_error("Could not save %s: %s" % [output, error_string(error)])
