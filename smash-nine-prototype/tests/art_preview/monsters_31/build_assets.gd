extends SceneTree
## CODEX-ART-31: normalize ImageGen source sheets with Godot's Image API.
## Downsampling is nearest-neighbour only; output is never enlarged.

const DIR := "res://assets/art/monsters"
const COUNTS := [4, 6, 4, 1]
const CELL := Vector2i(96, 96)
const FEET_Y := 72
const SHEETS := [
	"asgard_runic_raven", "niflheim_glacier_wolf", "alfheim_moon_stag",
	"svartalfheim_cog_drone", "vanaheim_seed_sprite", "jotunheim_storm_wisp",
	"yggdrasil_root_guardian", "midgard_rooftop_slinger", "muspelheim_magma_boar",
]
const PROJECTILE_CROPS := {
	"asgard_runic_raven": Rect2i(34, 30, 28, 28),
	"svartalfheim_cog_drone": Rect2i(62, 32, 28, 28),
	"vanaheim_seed_sprite": Rect2i(62, 24, 30, 30),
	"jotunheim_storm_wisp": Rect2i(34, 30, 28, 30),
	"midgard_rooftop_slinger": Rect2i(62, 34, 30, 32),
}

func _initialize() -> void:
	for skin: String in SHEETS:
		_build_sheet(skin)
	for skin: String in PROJECTILE_CROPS:
		_build_projectile(skin, PROJECTILE_CROPS[skin])
	print("ART31_BUILD_OK sheets=%d projectiles=%d" % [SHEETS.size(), PROJECTILE_CROPS.size()])
	quit(0)

func _build_sheet(skin: String) -> void:
	var source := Image.load_from_file("%s/%s_source.png" % [DIR, skin])
	if source == null or source.is_empty():
		push_error("Missing source for %s" % skin)
		quit(1)
		return
	var source_cell := Vector2i(source.get_width() / 6, source.get_height() / 4)
	var cells: Array[Image] = []
	var bounds: Array[Rect2i] = []
	var max_size := Vector2i.ZERO
	for row in 4:
		for column in COUNTS[row]:
			var frame := source.get_region(Rect2i(Vector2i(column, row) * source_cell, source_cell))
			_prepare_alpha(frame)
			_keep_largest_component(frame)
			var rect := _alpha_bounds(frame)
			cells.append(frame)
			bounds.append(rect)
			max_size.x = maxi(max_size.x, rect.size.x)
			max_size.y = maxi(max_size.y, rect.size.y)
	var scale := minf(minf(82.0 / maxf(1.0, float(max_size.x)), 68.0 / maxf(1.0, float(max_size.y))), 1.0)
	var sheet := Image.create(576, 384, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	var used := 0
	for row in 4:
		for column in COUNTS[row]:
			var rect: Rect2i = bounds[used]
			if rect.size.x > 0 and rect.size.y > 0:
				var piece := cells[used].get_region(rect)
				var target := Vector2i(maxi(1, int(round(rect.size.x * scale))), maxi(1, int(round(rect.size.y * scale))))
				piece.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
				var at := Vector2i(column * CELL.x + (CELL.x - target.x) / 2, row * CELL.y + FEET_Y - target.y)
				sheet.blend_rect(piece, Rect2i(Vector2i.ZERO, target), at)
			used += 1
	var path := "%s/%s_sheet.png" % [DIR, skin]
	if sheet.save_png(path) != OK:
		push_error("Could not save %s" % path)
		quit(1)
	print("sheet %s source=%s max=%s scale=%.3f alpha=%.3f" % [skin, source.get_size(), max_size, scale, _alpha_ratio(sheet)])

func _build_projectile(skin: String, crop: Rect2i) -> void:
	var sheet := Image.load_from_file("%s/%s_sheet.png" % [DIR, skin])
	var piece := sheet.get_region(crop)
	_keep_largest_component(piece)
	var bounds := _alpha_bounds(piece)
	if bounds.size == Vector2i.ZERO:
		push_error("Projectile crop empty for %s" % skin)
		quit(1)
		return
	piece = piece.get_region(bounds)
	var scale := minf(minf(22.0 / piece.get_width(), 18.0 / piece.get_height()), 1.0)
	var target := Vector2i(maxi(1, int(round(piece.get_width() * scale))), maxi(1, int(round(piece.get_height() * scale))))
	piece.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
	var output := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	output.blend_rect(piece, Rect2i(Vector2i.ZERO, target), (Vector2i(24, 24) - target) / 2)
	var path := "%s/%s_projectile.png" % [DIR, skin]
	if output.save_png(path) != OK:
		push_error("Could not save %s" % path)
		quit(1)
	print("projectile %s target=%s alpha=%.3f" % [skin, target, _alpha_ratio(output)])

func _prepare_alpha(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	var transparent := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.5:
				transparent += 1
	if transparent > image.get_width() * image.get_height() / 20:
		for y in image.get_height():
			for x in image.get_width():
				if image.get_pixel(x, y).a < 0.16:
					image.set_pixel(x, y, Color.TRANSPARENT)
		return
	_flood_clear_background(image)

func _flood_clear_background(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var seen := PackedByteArray()
	seen.resize(width * height)
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
		if seen[index] != 0:
			continue
		seen[index] = 1
		var x := index % width
		var y := index / width
		var current := image.get_pixel(x, y)
		for offset: int in [-1, 1, -width, width]:
			var next := index + offset
			if next < 0 or next >= seen.size() or seen[next] != 0:
				continue
			var nx := next % width
			var ny := next / width
			if absi(nx - x) + absi(ny - y) == 1 and _rgb_distance(current, image.get_pixel(nx, ny)) <= 0.075:
				queue.append(next)
	for index in seen.size():
		if seen[index] != 0:
			image.set_pixel(index % width, index / width, Color.TRANSPARENT)

func _rgb_distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()

func _keep_largest_component(image: Image) -> void:
	var width := image.get_width()
	var seen := PackedByteArray()
	seen.resize(width * image.get_height())
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
				if absi(nx - x) + absi(ny - y) == 1 and image.get_pixel(nx, ny).a >= 0.16:
					seen[next] = 1
					queue.append(next)
		if component.size() > largest.size():
			largest = component
	var keep := PackedByteArray()
	keep.resize(seen.size())
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
	return Rect2i() if maximum.x < minimum.x else Rect2i(minimum, maximum - minimum + Vector2i.ONE)

func _alpha_ratio(image: Image) -> float:
	var visible := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.16:
				visible += 1
	return float(visible) / float(image.get_width() * image.get_height())
