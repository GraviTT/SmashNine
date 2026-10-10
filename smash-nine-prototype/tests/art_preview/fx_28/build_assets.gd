extends SceneTree
## CODEX-ART-28: reduce the reviewed ImageGen sources onto the exact game grids. All generated
## pixels move from a larger source to a smaller target; this builder never upscales.

const CELL := 128
const SPARK_CELL := 96
const SPARK_FRAMES := 4
const FREY_SHEET := "res://assets/art/frey/frey_moves_sheet.png"
const FREY_BASE := "res://assets/art/frey/frey_sheet.png"
const FREY_SOURCE := "res://tests/art_preview/fx_28/frey_redraw_r2_source.png"
const HIT_DIR := "res://assets/art/effects/hit"
const PREVIEW_DIR := "res://tests/art_preview/fx_28"
const IDS := ["frey", "luna", "luna_brave", "nova", "rio", "yuki"]
const SPARK_LIMITS := [Vector2i(48, 48), Vector2i(84, 84), Vector2i(88, 88), Vector2i(64, 64)]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(HIT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))
	var ok := _build_frey()
	for id in IDS:
		ok = _build_hit_strip(id) and ok
	if ok:
		_write_hit_contacts()
		print("fx_28 assets built: Frey 4 cells + %d hit strips" % IDS.size())
	quit(0 if ok else 1)

func _build_frey() -> bool:
	var atlas := Image.load_from_file(ProjectSettings.globalize_path(FREY_SHEET))
	var source := Image.load_from_file(ProjectSettings.globalize_path(FREY_SOURCE))
	var base := Image.load_from_file(ProjectSettings.globalize_path(FREY_BASE))
	if atlas.is_empty() or source.is_empty() or base.is_empty():
		push_error("fx_28: missing Frey atlas, source or base")
		return false
	if source.get_width() < CELL * 4 or source.get_height() < CELL:
		push_error("fx_28: Frey source is too small; refusing to upscale")
		return false
	var before := atlas.duplicate()
	var palette := _palette(base, 144)
	var source_width := source.get_width() / 4
	var targets := [Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(3, 5)]
	for index in 4:
		var frame := source.get_region(Rect2i(index * source_width, 0, source_width, source.get_height()))
		frame = _frey_frame(frame, palette, 108 if index < 3 else 102)
		atlas.fill_rect(Rect2i(targets[index] * CELL, Vector2i(CELL, CELL)), Color.TRANSPARENT)
		atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), targets[index] * CELL)
	_harden_alpha(atlas)
	if atlas.save_png(ProjectSettings.globalize_path(FREY_SHEET)) != OK:
		push_error("fx_28: could not save Frey sheet")
		return false
	_write_frey_contacts(before, atlas, targets)
	return true

func _frey_frame(source: Image, palette: Array[Color], target_height: int) -> Image:
	_harden_alpha(source)
	var bounds := _alpha_bounds(source)
	if bounds.size == Vector2i.ZERO:
		return Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	var cropped := source.get_region(bounds)
	if cropped.get_height() <= target_height:
		push_error("fx_28: Frey source would require upscaling")
		return Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	var scale := float(target_height) / float(cropped.get_height())
	var target_width := maxi(1, int(round(cropped.get_width() * scale)))
	cropped.resize(target_width, target_height, Image.INTERPOLATE_NEAREST)
	_harden_alpha(cropped)
	_map_palette(cropped, palette)
	var frame := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	# Generated weapon trails may exceed one cell. Crop equally around the pose, retaining a
	# three-pixel transparent audit margin, while keeping body height equal to the idle sprite.
	var copy_width := mini(cropped.get_width(), CELL - 6)
	var source_x := maxi(0, (cropped.get_width() - copy_width) / 2)
	var destination := Vector2i((CELL - copy_width) / 2, 120 - target_height)
	frame.blit_rect(cropped, Rect2i(source_x, 0, copy_width, target_height), destination)
	_remove_small_components(frame, 3)
	_harden_alpha(frame)
	return frame

func _build_hit_strip(id: String) -> bool:
	var source_path := "%s/%s_hit_source.png" % [HIT_DIR, id]
	var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	if source.is_empty():
		push_error("fx_28: missing hit source %s" % source_path)
		return false
	if source.get_width() < SPARK_CELL * SPARK_FRAMES or source.get_height() < SPARK_CELL:
		push_error("fx_28: %s hit source is too small; refusing to upscale" % id)
		return false
	var strip := Image.create(SPARK_CELL * SPARK_FRAMES, SPARK_CELL, false, Image.FORMAT_RGBA8)
	var source_width := source.get_width() / SPARK_FRAMES
	for index in SPARK_FRAMES:
		var region := source.get_region(Rect2i(index * source_width, 0, source_width, source.get_height()))
		_harden_alpha(region)
		var bounds := _alpha_bounds(region)
		if bounds.size == Vector2i.ZERO:
			push_error("fx_28: empty frame %d in %s hit source" % [index, id])
			return false
		var cropped := region.get_region(bounds)
		var limit: Vector2i = SPARK_LIMITS[index]
		var scale := minf(float(limit.x) / cropped.get_width(), float(limit.y) / cropped.get_height())
		if scale >= 1.0:
			push_error("fx_28: %s frame %d would require upscaling" % [id, index])
			return false
		var size := Vector2i(maxi(1, int(round(cropped.get_width() * scale))), maxi(1, int(round(cropped.get_height() * scale))))
		cropped.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
		_harden_alpha(cropped)
		_remove_small_components(cropped, 2)
		var at := Vector2i(index * SPARK_CELL + (SPARK_CELL - size.x) / 2, (SPARK_CELL - size.y) / 2)
		strip.blit_rect(cropped, Rect2i(Vector2i.ZERO, size), at)
	_harden_alpha(strip)
	var output := "%s/%s_hit.png" % [HIT_DIR, id]
	if strip.save_png(ProjectSettings.globalize_path(output)) != OK:
		push_error("fx_28: could not save %s" % output)
		return false
	return true

func _write_frey_contacts(before: Image, after: Image, targets: Array) -> void:
	var contact := _checker(Vector2i(CELL * 4, CELL * 2))
	for index in targets.size():
		var rect := Rect2i(targets[index] * CELL, Vector2i(CELL, CELL))
		contact.blend_rect(before, rect, Vector2i(index * CELL, 0))
		contact.blend_rect(after, rect, Vector2i(index * CELL, CELL))
	_save_contact(contact, "frey_before_after")

func _write_hit_contacts() -> void:
	var contact := _checker(Vector2i(SPARK_CELL * SPARK_FRAMES, SPARK_CELL * IDS.size()))
	for row in IDS.size():
		var strip := Image.load_from_file(ProjectSettings.globalize_path("%s/%s_hit.png" % [HIT_DIR, IDS[row]]))
		contact.blend_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(0, row * SPARK_CELL))
	_save_contact(contact, "hit_sparks_contact")

func _save_contact(image: Image, stem: String) -> void:
	image.save_png(ProjectSettings.globalize_path("%s/%s_1x.png" % [PREVIEW_DIR, stem]))
	var enlarged := image.duplicate()
	enlarged.resize(image.get_width() * 4, image.get_height() * 4, Image.INTERPOLATE_NEAREST)
	enlarged.save_png(ProjectSettings.globalize_path("%s/%s_4x.png" % [PREVIEW_DIR, stem]))

func _checker(size: Vector2i) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		for x in size.x:
			image.set_pixel(x, y, Color8(21, 29, 48) if ((x / 8) + (y / 8)) % 2 == 0 else Color8(31, 42, 67))
	return image

func _palette(image: Image, limit: int) -> Array[Color]:
	var counts := {}
	var colors := {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := _rgb_key(color)
			counts[key] = int(counts.get(key, 0)) + 1
			colors[key] = Color(color.r, color.g, color.b, 1.0)
	var ranked: Array = counts.keys()
	ranked.sort_custom(func(a: Variant, b: Variant) -> bool: return int(counts[a]) > int(counts[b]))
	var result: Array[Color] = []
	for index in mini(limit, ranked.size()):
		result.append(colors[ranked[index]])
	return result

func _map_palette(image: Image, palette: Array[Color]) -> void:
	var cache := {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := _rgb_key(color)
			var mapped: Color
			if cache.has(key):
				mapped = cache[key]
			else:
				var best := INF
				mapped = palette[0]
				for candidate in palette:
					var distance := Vector3(color.r - candidate.r, color.g - candidate.g, color.b - candidate.b).length_squared()
					if distance < best:
						best = distance
						mapped = candidate
				cache[key] = mapped
			image.set_pixel(x, y, mapped)

func _harden_alpha(image: Image) -> void:
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, 1.0) if color.a >= 0.5 else Color.TRANSPARENT)

func _alpha_bounds(image: Image) -> Rect2i:
	var rect := Rect2i()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.5:
				continue
			var point := Vector2i(x, y)
			rect = Rect2i(point, Vector2i.ONE) if rect.size == Vector2i.ZERO else rect.expand(point).expand(point + Vector2i.ONE)
	return rect

func _remove_small_components(image: Image, minimum: int) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var seen := PackedByteArray()
	seen.resize(width * height)
	for y in height:
		for x in width:
			var start := y * width + x
			if seen[start] != 0 or image.get_pixel(x, y).a < 0.5:
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			var component: Array[Vector2i] = []
			seen[start] = 1
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				component.append(point)
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = point + offset
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var next_index: int = next.y * width + next.x
					if seen[next_index] == 0 and image.get_pixelv(next).a >= 0.5:
						seen[next_index] = 1
						stack.append(next)
			if component.size() < minimum:
				for point in component:
					image.set_pixelv(point, Color.TRANSPARENT)

func _rgb_key(color: Color) -> int:
	return int(round(color.r * 255.0)) << 16 | int(round(color.g * 255.0)) << 8 | int(round(color.b * 255.0))
