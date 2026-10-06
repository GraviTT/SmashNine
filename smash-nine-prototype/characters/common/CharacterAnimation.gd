extends RefCounted

static func create_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.clear_all()
	return frames

static func add_strip(frames: SpriteFrames, animation_name: StringName, texture: Texture2D, frame_size: Vector2i, start_column: int, frame_count: int, fps: float, loops: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loops)
	for offset in frame_count:
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = texture
		frame_texture.region = Rect2(Vector2((start_column + offset) * frame_size.x, 0), frame_size)
		frames.add_frame(animation_name, frame_texture)

static func add_grid(frames: SpriteFrames, animation_name: StringName, texture: Texture2D, frame_size: Vector2i, columns: int, start_index: int, frame_count: int, fps: float, loops: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loops)
	for offset in frame_count:
		var frame_index := start_index + offset
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = texture
		frame_texture.region = Rect2(Vector2((frame_index % columns) * frame_size.x, (frame_index / columns) * frame_size.y), frame_size)
		frames.add_frame(animation_name, frame_texture)
