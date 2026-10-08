extends SceneTree

const CELL := 128
const MARGIN := 4
const FEET_Y := 120
const ALPHA_CUT := 56
const ROOT := "res://tests/art_preview/attack_vfx_2x_a"
const REPORT := "res://../reports/codex-art-16"
const RIO_SPECS := [
	["rio_male", "res://assets/art/rio/rio_male_sheet.png", "res://assets/art/rio/rio_male_v2_rework_source.png", 0.5581],
	["rio_female", "res://assets/art/rio/rio_female_sheet.png", "res://assets/art/rio/rio_female_v2_rework_source.png", 0.4896],
]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT + "/sheets"))
	for spec: Array in RIO_SPECS:
		_fix_rio(spec)
	_fix_frey()
	print("CHARACTER_SHEET_FIX_OK rio_frames=20 frey_frames=1")
	quit(0)

func _fix_rio(spec: Array) -> void:
	var id: String = spec[0]
	var sheet_path: String = spec[1]
	var source_path: String = spec[2]
	var scale: float = spec[3]
	var before := Image.load_from_file(ProjectSettings.globalize_path(ROOT + "/baseline/%s_sheet.png" % id))
	var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	before.convert(Image.FORMAT_RGBA8)
	source.convert(Image.FORMAT_RGBA8)
	var sheet := before.duplicate()
	var target_x := _idle_body_center(before)
	for row in [4, 5]:
		var count := 4 if row == 4 else 6
		var bounds := _row_boundaries(source)
		var y0: int = bounds[row]
		var y1: int = bounds[row + 1]
		var span := _drawn_x_span(source, y0, y1, false)
		for column in count:
			var left := roundi(span.position.x + float(column) * span.size.x / count)
			var right := roundi(span.position.x + float(column + 1) * span.size.x / count)
			var source_cell := source.get_region(Rect2i(left, y0, right - left, y1 - y0))
			var body := _largest_component(_extract_body(source_cell))
			body.resize(maxi(1, roundi(body.get_width() * scale)), maxi(1, roundi(body.get_height() * scale)), Image.INTERPOLATE_NEAREST)
			_binary_alpha(body)
			var body_anchor := _body_anchor(body)
			var destination := Vector2i(roundi(target_x - body_anchor.x), FEET_Y - roundi(body_anchor.y))
			var current := _cell(before, row, column)
			var output := _effect_only(current)
			_remove_edge_slivers(output)
			_blit_clipped(output, body, destination)
			_inset(output)
			_soften_straight_bounds(output)
			_write_cell(sheet, row, column, output)
			print("RIO %s r%dc%d source=%s body=%s at=%s" % [id, row, column, Rect2i(left, y0, right - left, y1 - y0), body.get_size(), destination])
	sheet.save_png(ProjectSettings.globalize_path(sheet_path))
	_save_sheet_board(id, before, sheet)

func _extract_body(source_cell: Image) -> Image:
	var opaque := source_cell.duplicate()
	_binary_alpha_threshold(opaque, ALPHA_CUT)
	var dark := _dark_rect(opaque)
	if dark.size == Vector2i.ZERO:
		return opaque.get_region(opaque.get_used_rect())
	# The dark hair/armour/cape identifies the body. Keep its full neighbourhood including
	# sword and limbs, but exclude the distant cyan crescent/crystal that caused shrinking.
	var start := Vector2i(maxi(0, dark.position.x - 24), maxi(0, dark.position.y - 18))
	var end := Vector2i(mini(opaque.get_width(), dark.end.x + 42), mini(opaque.get_height(), dark.end.y + 16))
	var region: Image = opaque.get_region(Rect2i(start, end - start))
	var local_dark := Rect2i(dark.position - start, dark.size)
	for y in region.get_height():
		for x in region.get_width():
			var c: Color = region.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var outside_body: bool = x > local_dark.end.x + 12 or y < local_dark.position.y - 8
			if outside_body and _is_effect(c):
				region.set_pixel(x, y, Color.TRANSPARENT)
	var used: Rect2i = region.get_used_rect()
	return region.get_region(used)

func _effect_only(frame: Image) -> Image:
	var effect := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
	effect.fill(Color.TRANSPARENT)
	for y in CELL:
		for x in CELL:
			var c := frame.get_pixel(x, y)
			if c.a >= 0.5 and _is_effect(c):
				effect.set_pixel(x, y, c)
	return effect

func _is_effect(c: Color) -> bool:
	var cyan := c.b8 >= 120 and c.g8 >= 75 and c.b8 >= c.r8 + 18
	var pale := c.r8 >= 150 and c.g8 >= 165 and c.b8 >= 180
	return cyan or pale

func _idle_body_center(sheet: Image) -> float:
	var values: Array[float] = []
	for column in 4:
		var frame := _cell(sheet, 0, column)
		var rect := _dark_rect(frame)
		values.append(rect.position.x + rect.size.x * 0.5)
	values.sort()
	return (values[1] + values[2]) * 0.5

func _body_anchor(image: Image) -> Vector2:
	var rect := _dark_rect(image)
	return Vector2(rect.position.x + rect.size.x * 0.5, rect.end.y - 1)

func _dark_rect(image: Image) -> Rect2i:
	var mask := Image.create_empty(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a >= 0.5 and c.get_luminance() < 0.48:
				mask.set_pixel(x, y, Color.WHITE)
	return mask.get_used_rect()

func _fix_frey() -> void:
	var sheet_path := "res://assets/art/frey/frey_sheet.png"
	var source_path := "res://assets/art/frey/frey_v2_source.png"
	var before := Image.load_from_file(ProjectSettings.globalize_path(ROOT + "/baseline/frey_sheet.png"))
	var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	before.convert(Image.FORMAT_RGBA8)
	source.convert(Image.FORMAT_RGBA8)
	var sheet := before.duplicate()
	var frame := _cell(sheet, 4, 3)
	# The fourth attack pose lives across the old equal-column boundary. Fit its core to the
	# accepted frame, then add only the navy/gold shield face from the source's right side.
	var transform := _fit_frey_transform(source, frame)
	var piece_rect := Rect2i(760, 790, 180, 220)
	var piece := source.get_region(piece_rect)
	for y in piece.get_height():
		for x in piece.get_width():
			var c := piece.get_pixel(x, y)
			var gold := c.a8 >= ALPHA_CUT and c.r8 >= 105 and c.g8 >= 65 and c.b8 <= 105
			var navy := c.a8 >= ALPHA_CUT and c.b8 >= 45 and c.b8 >= c.r8 + 10 and c.r8 < 100
			if not (gold or navy):
				piece.set_pixel(x, y, Color.TRANSPARENT)
			else:
				c.a = 1.0
				piece.set_pixel(x, y, c)
	var used := piece.get_used_rect()
	piece = piece.get_region(used)
	piece.resize(maxi(1, roundi(piece.get_width() * transform.scale)), maxi(1, roundi(piece.get_height() * transform.scale)), Image.INTERPOLATE_NEAREST)
	if piece.get_width() > 48:
		piece.resize(48, piece.get_height(), Image.INTERPOLATE_NEAREST)
	_binary_alpha(piece)
	var global_origin := piece_rect.position + used.position
	var destination := Vector2i(roundi(global_origin.x * transform.scale) + transform.tx, roundi(global_origin.y * transform.scale) + transform.ty)
	destination.x = mini(destination.x, CELL - MARGIN - piece.get_width())
	destination.y = clampi(destination.y, MARGIN, CELL - MARGIN - piece.get_height())
	_blit_clipped(frame, piece, destination)
	_inset(frame)
	_write_cell(sheet, 4, 3, frame)
	sheet.save_png(ProjectSettings.globalize_path(sheet_path))
	_save_sheet_board("frey", before, sheet)
	print("FREY r4c3 shield source=%s scale=%.3f at=%s" % [piece_rect, transform.scale, destination])

func _fit_frey_transform(source: Image, current: Image) -> Dictionary:
	var bounds := _row_boundaries(source)
	var rect := Rect2i(roundi(3.0 * source.get_width() / 6.0), bounds[4], roundi(source.get_width() / 6.0), bounds[5] - bounds[4])
	var core := source.get_region(rect)
	_binary_alpha_threshold(core, ALPHA_CUT)
	var used := core.get_used_rect()
	core = core.get_region(used)
	var origin := rect.position + used.position
	var best := {"scale": 0.5, "tx": 0, "ty": 0, "cost": 1 << 30}
	for step in range(45, 56):
		var scale := float(step) / 100.0
		var test := core.duplicate()
		test.resize(roundi(test.get_width() * scale), roundi(test.get_height() * scale), Image.INTERPOLATE_NEAREST)
		var offset := Vector2i(_best_offset(_coverage(current, true), _coverage(test, true)), _best_offset(_coverage(current, false), _coverage(test, false)))
		var candidate := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
		candidate.blit_rect(test, Rect2i(Vector2i.ZERO, test.get_size()), offset)
		var cost := _alpha_difference(candidate, current)
		if cost < best.cost:
			best = {"scale": scale, "tx": offset.x - roundi(origin.x * scale), "ty": offset.y - roundi(origin.y * scale), "cost": cost}
	return best

func _row_boundaries(source: Image) -> PackedInt32Array:
	var counts := PackedInt32Array()
	counts.resize(source.get_height())
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x, y).a8 >= ALPHA_CUT:
				counts[y] += 1
	var result := PackedInt32Array([0])
	var radius := maxi(24, roundi(float(source.get_height()) / 18.0))
	for split in range(1, 7):
		var expected := roundi(float(split) * source.get_height() / 7.0)
		var best := expected
		for y in range(maxi(1, expected - radius), mini(source.get_height() - 1, expected + radius + 1)):
			if counts[y] < counts[best] or (counts[y] == counts[best] and absi(y - expected) < absi(best - expected)):
				best = y
		result.append(best)
	result.append(source.get_height())
	return result

func _drawn_x_span(source: Image, y0: int, y1: int, dark_only: bool) -> Rect2i:
	var left := source.get_width()
	var right := -1
	for y in range(y0, y1):
		for x in source.get_width():
			var c := source.get_pixel(x, y)
			if c.a8 >= ALPHA_CUT and (not dark_only or c.get_luminance() < 0.48):
				left = mini(left, x)
				right = maxi(right, x)
	return Rect2i(left, 0, right - left + 1, 1)

func _blit_clipped(target: Image, piece: Image, destination: Vector2i) -> void:
	for y in piece.get_height():
		for x in piece.get_width():
			var p := destination + Vector2i(x, y)
			if p.x < MARGIN or p.y < MARGIN or p.x >= CELL - MARGIN or p.y >= CELL - MARGIN:
				continue
			var c := piece.get_pixel(x, y)
			if c.a >= 0.5:
				target.set_pixelv(p, c)

func _inset(image: Image) -> void:
	for i in MARGIN:
		for p in CELL:
			image.set_pixel(i, p, Color.TRANSPARENT)
			image.set_pixel(CELL - 1 - i, p, Color.TRANSPARENT)
			image.set_pixel(p, i, Color.TRANSPARENT)
			image.set_pixel(p, CELL - 1 - i, Color.TRANSPARENT)

func _binary_alpha_threshold(image: Image, threshold: int) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a8 < threshold:
				image.set_pixel(x, y, Color.TRANSPARENT)
			else:
				c.a = 1.0
				image.set_pixel(x, y, c)

func _binary_alpha(image: Image) -> void:
	_binary_alpha_threshold(image, 128)

func _largest_component(image: Image) -> Image:
	var w := image.get_width()
	var h := image.get_height()
	var labels := PackedInt32Array()
	labels.resize(w * h)
	labels.fill(-1)
	var groups: Array[PackedInt32Array] = []
	var stack := PackedInt32Array()
	for start in w * h:
		if labels[start] != -1 or image.get_pixel(start % w, start / w).a < 0.5:
			continue
		var id := groups.size()
		var pixels := PackedInt32Array()
		groups.append(pixels)
		labels[start] = id
		stack.append(start)
		while not stack.is_empty():
			var p := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			pixels.append(p)
			var px := p % w
			var py := p / w
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var nx := px + ox
					var ny := py + oy
					if nx < 0 or ny < 0 or nx >= w or ny >= h or (ox == 0 and oy == 0):
						continue
					var q := ny * w + nx
					if labels[q] == -1 and image.get_pixel(nx, ny).a >= 0.5:
						labels[q] = id
						stack.append(q)
	if groups.is_empty():
		return image
	var best := 0
	for i in range(1, groups.size()):
		if groups[i].size() > groups[best].size():
			best = i
	var result := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for p in groups[best]:
		result.set_pixel(p % w, p / w, image.get_pixel(p % w, p / w))
	var used := result.get_used_rect()
	return result.get_region(used)

func _remove_edge_slivers(image: Image) -> void:
	# Generated effects that crossed a source-cell line can leave a ruler-straight chip at
	# x=4/123. Remove only narrow components in the outer 10 pixels; the main shield stays.
	for y in CELL:
		for x in CELL:
			if (x <= 9 or x >= 118) and image.get_pixel(x, y).a >= 0.5:
				var neighbours := 0
				for dx in range(-3, 4):
					var nx := x + dx
					if nx >= 0 and nx < CELL and image.get_pixel(nx, y).a >= 0.5:
						neighbours += 1
				if neighbours <= 3:
					image.set_pixel(x, y, Color.TRANSPARENT)

func _soften_straight_bounds(image: Image) -> void:
	var rect := image.get_used_rect()
	if rect.size == Vector2i.ZERO:
		return
	var left_count := 0
	var right_count := 0
	for y in range(rect.position.y, rect.end.y):
		if image.get_pixel(rect.position.x, y).a >= 0.5: left_count += 1
		if image.get_pixel(rect.end.x - 1, y).a >= 0.5: right_count += 1
	if left_count >= 16 or rect.position.x <= 7:
		for y in range(rect.position.y, rect.end.y):
			if y % 5 != 0:
				image.set_pixel(rect.position.x, y, Color.TRANSPARENT)
	if right_count >= 16 or rect.end.x >= 121:
		for y in range(rect.position.y, rect.end.y):
			if y % 5 != 0:
				image.set_pixel(rect.end.x - 1, y, Color.TRANSPARENT)
	rect = image.get_used_rect()
	var top_count := 0
	for x in range(rect.position.x, rect.end.x):
		if image.get_pixel(x, rect.position.y).a >= 0.5: top_count += 1
	if top_count >= 16 or rect.position.y <= 7:
		for x in range(rect.position.x, rect.end.x):
			if x % 5 != 0:
				image.set_pixel(x, rect.position.y, Color.TRANSPARENT)

func _coverage(image: Image, columns: bool) -> PackedInt32Array:
	var size := image.get_width() if columns else image.get_height()
	var other := image.get_height() if columns else image.get_width()
	var result := PackedInt32Array()
	result.resize(size)
	for i in size:
		for j in other:
			if (image.get_pixel(i, j).a if columns else image.get_pixel(j, i).a) >= 0.5:
				result[i] += 1
	return result

func _best_offset(target: PackedInt32Array, piece: PackedInt32Array) -> int:
	var best := 0
	var cost_best := 1 << 30
	for offset in range(-piece.size() + 1, target.size()):
		var cost := 0
		for i in target.size():
			var j := i - offset
			cost += absi(target[i] - (piece[j] if j >= 0 and j < piece.size() else 0))
		if cost < cost_best:
			cost_best = cost
			best = offset
	return best

func _alpha_difference(a: Image, b: Image) -> int:
	var count := 0
	for y in CELL:
		for x in CELL:
			if (a.get_pixel(x, y).a >= 0.5) != (b.get_pixel(x, y).a >= 0.5):
				count += 1
	return count

func _cell(sheet: Image, row: int, column: int) -> Image:
	return sheet.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))

func _write_cell(sheet: Image, row: int, column: int, frame: Image) -> void:
	sheet.blit_rect(frame, Rect2i(0, 0, CELL, CELL), Vector2i(column * CELL, row * CELL))

func _save_sheet_board(id: String, before: Image, after: Image) -> void:
	var board := Image.create_empty(CELL * 6 * 2, CELL * 4, false, Image.FORMAT_RGBA8)
	board.fill(Color("333843"))
	for side in 2:
		for index in 2:
			var row := 4 + index
			var strip := (before if side == 0 else after).get_region(Rect2i(0, row * CELL, CELL * 6, CELL))
			board.blend_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(side * CELL * 6, index * CELL))
	board.resize(board.get_width() * 2, board.get_height() * 2, Image.INTERPOLATE_NEAREST)
	board.save_png(ProjectSettings.globalize_path(REPORT + "/sheets/%s_rows45_before_after_2x.png" % id))
