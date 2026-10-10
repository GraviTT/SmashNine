extends SceneTree
## CODEX-ART-27 required art repair. ImageGen supplies the painted source; this script
## enforces the runtime pixel contracts without ever enlarging source pixels.

const MONSTER_DIR := "res://assets/art/monsters"
const UI_DIR := "res://assets/art/ui"
const FRAME_COUNTS := [4, 6, 4, 1]
const CELL := Vector2i(96, 96)
const FEET_Y := 80

func _initialize() -> void:
	_build_title_background()
	_build_jotunheim_sheet()
	print("ART27_BUILD_OK title=1920x1080 base=960x540 jotunheim=576x384")
	quit(0)

func _build_title_background() -> void:
	var source_path := "%s/title_bg_source.png" % UI_DIR
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		_fail("Cannot load title source %s" % source_path)
		return
	source.convert(Image.FORMAT_RGBA8)
	var crop_size := source.get_size()
	if float(crop_size.x) / float(crop_size.y) > 16.0 / 9.0:
		crop_size.x = int(floor(float(crop_size.y) * 16.0 / 9.0))
	else:
		crop_size.y = int(floor(float(crop_size.x) * 9.0 / 16.0))
	var cropped := source.get_region(Rect2i((source.get_size() - crop_size) / 2, crop_size))
	# The lead review explicitly requests a 960x540 authored base, then integer x2 nearest.
	cropped.resize(960, 540, Image.INTERPOLATE_NEAREST)
	var output: Image = cropped.duplicate()
	output.resize(1920, 1080, Image.INTERPOLATE_NEAREST)
	var error: Error = output.save_png("%s/title_bg.png" % UI_DIR)
	if error != OK:
		_fail("Could not save title background (%s)" % error)
		return
	print("title source=%s crop=%s base=(960, 540) target=%s scale=2 nearest" % [source.get_size(), crop_size, output.get_size()])

func _build_jotunheim_sheet() -> void:
	var source_path := "%s/jotunheim_rune_golem_source.png" % MONSTER_DIR
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		_fail("Cannot load Jotunheim source %s" % source_path)
		return
	var source_cell := Vector2i(source.get_width() / 6, source.get_height() / 4)
	var cells: Array[Image] = []
	var bounds: Array[Rect2i] = []
	var max_size := Vector2i.ZERO
	var row_max_sizes: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO]
	for row in 4:
		for column in FRAME_COUNTS[row]:
			var frame := source.get_region(Rect2i(Vector2i(column, row) * source_cell, source_cell))
			_prepare_alpha(frame)
			_keep_largest_component(frame)
			var rect := _alpha_bounds(frame)
			cells.append(frame)
			bounds.append(rect)
			max_size.x = maxi(max_size.x, rect.size.x)
			max_size.y = maxi(max_size.y, rect.size.y)
			row_max_sizes[row].x = maxi(row_max_sizes[row].x, rect.size.x)
			row_max_sizes[row].y = maxi(row_max_sizes[row].y, rect.size.y)
	# The golem gets the same broad visual weight as mossling while remaining inside 96px.
	# Its authored feet are at y=80; RealmMonster compensates that visual pivot only.
	var row_scales: Array[float] = []
	for row_size in row_max_sizes:
		row_scales.append(minf(minf(94.0 / maxf(1.0, float(row_size.x)), 80.0 / maxf(1.0, float(row_size.y))), 1.0))
	var sheet := Image.create(576, 384, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	var used := 0
	for row in 4:
		for column in FRAME_COUNTS[row]:
			var rect: Rect2i = bounds[used]
			if rect.size.x > 0 and rect.size.y > 0:
				var piece := cells[used].get_region(rect)
				var target := Vector2i(maxi(1, int(round(rect.size.x * row_scales[row]))), maxi(1, int(round(rect.size.y * row_scales[row]))))
				piece.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
				var at := Vector2i(column * CELL.x + (CELL.x - target.x) / 2, row * CELL.y + FEET_Y - target.y)
				sheet.blend_rect(piece, Rect2i(Vector2i.ZERO, target), at)
			used += 1
	var error: Error = sheet.save_png("%s/jotunheim_rune_golem_sheet.png" % MONSTER_DIR)
	if error != OK:
		_fail("Could not save Jotunheim sheet (%s)" % error)
		return
	print("jotunheim source=%s cell=%s max=%s row_scales=%s opaque=%d" % [source.get_size(), source_cell, max_size, row_scales, _opaque_pixels(sheet)])

func _prepare_alpha(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	var transparent := 0
	var total := image.get_width() * image.get_height()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.5:
				transparent += 1
	if transparent > total / 20:
		for y in image.get_height():
			for x in image.get_width():
				# ImageGen can leave a soft, semi-transparent vignette even when asked for
				# transparency. It must not expand the sprite bounds and shrink the golem.
				if image.get_pixel(x, y).a < 0.8:
					image.set_pixel(x, y, Color.TRANSPARENT)
		return
	_flood_clear_background(image)

func _flood_clear_background(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue := PackedInt32Array()
	for x in width:
		queue.append(x)
		queue.append((height - 1) * width + x)
	for y in height:
		queue.append(y * width)
		queue.append(y * width + width - 1)
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		if visited[index] != 0:
			continue
		visited[index] = 1
		var x := index % width
		var y := index / width
		var current := image.get_pixel(x, y)
		for offset: int in [-1, 1, -width, width]:
			var next := index + offset
			if next < 0 or next >= visited.size() or visited[next] != 0:
				continue
			var nx := next % width
			var ny := next / width
			if absi(nx - x) + absi(ny - y) != 1:
				continue
			if _rgb_distance(current, image.get_pixel(nx, ny)) <= 0.075:
				queue.append(next)
	for index in visited.size():
		if visited[index] != 0:
			image.set_pixel(index % width, index / width, Color.TRANSPARENT)

func _rgb_distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()

func _keep_largest_component(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var seen := PackedByteArray()
	seen.resize(width * height)
	var largest := PackedInt32Array()
	for start in seen.size():
		if seen[start] != 0 or image.get_pixel(start % width, start / width).a < 0.16:
			continue
		var component := PackedInt32Array()
		var queue := PackedInt32Array([start])
		seen[start] = 1
		var head := 0
		while head < queue.size():
			var index := queue[head]
			head += 1
			component.append(index)
			var x := index % width
			var y := index / width
			for offset: int in [-1, 1, -width, width]:
				var next := index + offset
				if next < 0 or next >= seen.size() or seen[next] != 0:
					continue
				var nx := next % width
				var ny := next / width
				if absi(nx - x) + absi(ny - y) != 1:
					continue
				if image.get_pixel(nx, ny).a >= 0.16:
					seen[next] = 1
					queue.append(next)
		if component.size() > largest.size():
			largest = component
	var keep := PackedByteArray()
	keep.resize(width * height)
	for index in largest:
		keep[index] = 1
	for index in keep.size():
		if keep[index] == 0:
			image.set_pixel(index % width, index / width, Color.TRANSPARENT)

func _alpha_bounds(image: Image) -> Rect2i:
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.16:
				minimum.x = mini(minimum.x, x)
				minimum.y = mini(minimum.y, y)
				maximum.x = maxi(maximum.x, x)
				maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)

func _opaque_pixels(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.16:
				count += 1
	return count

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
