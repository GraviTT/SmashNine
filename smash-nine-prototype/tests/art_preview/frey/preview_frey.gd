extends SceneTree

const OLD_TEXTURE_PATH := "res://assets/characters/frey/frey_prototype.png"
const NEW_TEXTURE_PATH := "res://assets/art/frey/frey_sheet.png"
const REPORT_DIR := "res://../reports/codex-art-02"
const CELL := Vector2i(64, 64)
const COLUMNS := 6
const PREVIEW_SCALE := Vector2(2.0, 2.0)
const BACKGROUND := Color("071622")
const ANIMATIONS := [
	{"name": "idle", "row": 0, "count": 4, "fps": 7.0, "loop": true},
	{"name": "walk", "row": 1, "count": 6, "fps": 10.0, "loop": true},
	{"name": "jump", "row": 2, "count": 1, "fps": 1.0, "loop": false},
	{"name": "fall", "row": 3, "count": 1, "fps": 1.0, "loop": false},
	{"name": "attack", "row": 4, "count": 4, "fps": 14.0, "loop": false},
	{"name": "shield", "row": 5, "count": 6, "fps": 12.0, "loop": false},
	{"name": "hurt", "row": 6, "count": 1, "fps": 1.0, "loop": false},
]

var old_frames: SpriteFrames
var new_frames: SpriteFrames
var screenshots: Array[Image] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var old_texture := load(OLD_TEXTURE_PATH) as Texture2D
	var new_texture := load(NEW_TEXTURE_PATH) as Texture2D
	if old_texture == null or new_texture == null:
		push_error("Preview textures could not be imported")
		quit(1)
		return
	old_frames = _create_frames(old_texture)
	new_frames = _create_frames(new_texture)
	for animation in ANIMATIONS:
		await _capture_animation(animation)
	_save_contact_sheet()
	print("[frey-preview] captured %d animation comparisons and contact_sheet.png" % screenshots.size())
	quit()

func _create_frames(texture: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for animation in ANIMATIONS:
		var animation_name := StringName(animation.name)
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, animation.fps)
		frames.set_animation_loop(animation_name, animation.loop)
		for column in range(animation.count):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(column * CELL.x, animation.row * CELL.y, CELL.x, CELL.y)
			frames.add_frame(animation_name, atlas)
	return frames

func _capture_animation(animation: Dictionary) -> void:
	var width := 1040
	var height := 330
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
	_add_label(stage, "FREY %s — 2x nearest-neighbour comparison" % String(animation.name).to_upper(), Vector2(24, 12), 22)
	_add_label(stage, "OLD PLACEHOLDER", Vector2(24, 70), 16)
	_add_label(stage, "NEW ORIGINAL", Vector2(24, 211), 16)
	var old_baseline := 160.0
	var new_baseline := 300.0
	_add_baseline(stage, old_baseline, width)
	_add_baseline(stage, new_baseline, width)
	var spacing := 132.0
	var start_x := 220.0
	for frame_index in range(animation.count):
		_add_sprite(stage, old_frames, animation.name, frame_index, Vector2(start_x + frame_index * spacing, old_baseline - 32.0))
		_add_sprite(stage, new_frames, animation.name, frame_index, Vector2(start_x + frame_index * spacing, new_baseline - 32.0))
		_add_label(stage, "%d" % frame_index, Vector2(start_x - 6 + frame_index * spacing, 177), 13)
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

func _add_sprite(parent: Node, frames: SpriteFrames, animation_name: String, frame_index: int, position: Vector2) -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.animation = StringName(animation_name)
	sprite.frame = frame_index
	sprite.pause()
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
	line.points = PackedVector2Array([Vector2(180, y), Vector2(width - 24, y)])
	parent.add_child(line)

func _save_contact_sheet() -> void:
	if screenshots.is_empty():
		return
	var width := screenshots[0].get_width()
	var height := screenshots[0].get_height()
	var contact := Image.create(width, height * screenshots.size(), false, Image.FORMAT_RGBA8)
	contact.fill(BACKGROUND)
	for index in range(screenshots.size()):
		contact.blit_rect(screenshots[index], Rect2i(Vector2i.ZERO, screenshots[index].get_size()), Vector2i(0, index * height))
	var output := "%s/contact_sheet.png" % REPORT_DIR
	var error := contact.save_png(output)
	if error != OK:
		push_error("Could not save %s: %s" % [output, error_string(error)])
