extends SceneTree

const CELL := 128
const FEET_Y := 120
const MARGIN := 4
const TRANSPARENT := Color(0, 0, 0, 0)
const ROOT := "res://tests/art_preview/sprite_fix_a2"
const REPORT := "res://../reports/codex-art-12"

const SPECS := [
	{
		"id": "rio_female",
		"sheet": "res://assets/art/rio/rio_female_sheet.png",
		"source": "res://assets/art/rio/rio_female_v2_rework_source.png",
		"frames": [Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5)],
	},
	{
		"id": "frey",
		"sheet": "res://assets/art/frey/frey_sheet.png",
		"source": "res://assets/art/frey/frey_v2_source.png",
		"frames": [],
	},
	{
		"id": "nova_female",
		"sheet": "res://assets/art/nova/nova_female_sheet.png",
		"source": "res://assets/art/nova/nova_female_v2_source.png",
		"frames": [],
	},
]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT + "/baseline"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT + "/before_after"))
	for spec: Dictionary in SPECS:
		_apply_spec(spec)
	quit()

func _apply_spec(spec: Dictionary) -> void:
	var sheet_path: String = spec.sheet
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(sheet_path))
	sheet.convert(Image.FORMAT_RGBA8)
	var baseline_path := ROOT + "/baseline/%s_sheet.png" % spec.id
	if not FileAccess.file_exists(ProjectSettings.globalize_path(baseline_path)):
		sheet.save_png(ProjectSettings.globalize_path(baseline_path))
	var before := Image.load_from_file(ProjectSettings.globalize_path(baseline_path))
	before.convert(Image.FORMAT_RGBA8)
	# Always rebuild from the captured starting sheet, keeping reruns deterministic.
	sheet = before.duplicate()
	var source := Image.load_from_file(ProjectSettings.globalize_path(spec.source))
	source.convert(Image.FORMAT_RGBA8)
	if spec.id == "rio_female":
		for column in range(1, 5):
			_fix_rio_shield(sheet, source, column)
	sheet.save_png(ProjectSettings.globalize_path(sheet_path))
	_save_board(spec.id, spec.frames, before, sheet)

func _fix_rio_attack_top(sheet: Image, source: Image) -> void:
	var frame := _cell(sheet, 4, 0)
	# The raised sword crosses the generated row boundary. Bring back only that upper-left
	# weapon piece and fit it inside the top margin; the character body is unchanged.
	var piece := source.get_region(Rect2i(20, 735, 190, 70))
	_binary_alpha_threshold(piece, 0.22)
	var bounds := _alpha_bounds(piece)
	piece = piece.get_region(bounds)
	piece.resize(maxi(1, roundi(piece.get_width() * 0.505)), maxi(1, roundi(piece.get_height() * 0.505)), Image.INTERPOLATE_NEAREST)
	_binary_alpha(piece)
	var destination := Vector2i(4, 4)
	for y in piece.get_height():
		for x in piece.get_width():
			var target := destination + Vector2i(x, y)
			if target.x < 124 and target.y < 124 and piece.get_pixel(x, y).a > 0.5 and frame.get_pixelv(target).a < 0.5:
				frame.set_pixelv(target, piece.get_pixel(x, y))
	# Any residual straight crop at the top is moved into the legal margin.
	for x in CELL:
		for y in MARGIN:
			frame.set_pixel(x, y, TRANSPARENT)
	_write_cell(sheet, 4, 0, frame)

func _replace_attack_body(sheet: Image, source: Image, column: int, source_rect: Rect2i, scale: float, effect_cut_x: int) -> void:
	var current := _cell(sheet, 4, column)
	var current_effect := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
	current_effect.fill(TRANSPARENT)
	var current_body := current.duplicate()
	for y in CELL:
		for x in CELL:
			var color := current.get_pixel(x, y)
			if _is_bright_cyan(color):
				current_effect.set_pixel(x, y, color)
				current_body.set_pixel(x, y, TRANSPARENT)
	var body := source.get_region(source_rect)
	for y in body.get_height():
		for x in body.get_width():
			var color := body.get_pixel(x, y)
			var global_x := source_rect.position.x + x
			if color.a < 0.22 or (_is_bright_cyan(color) and global_x >= effect_cut_x):
				body.set_pixel(x, y, TRANSPARENT)
			else:
				color.a = 1.0
				body.set_pixel(x, y, color)
	var body_bounds := _alpha_bounds(body)
	body = body.get_region(body_bounds)
	body.resize(maxi(1, roundi(body.get_width() * scale)), maxi(1, roundi(body.get_height() * scale)), Image.INTERPOLATE_NEAREST)
	_binary_alpha(body)
	var x_offset := _best_offset(_coverage(current_body, true), _coverage(body, true))
	var y_offset := FEET_Y - (_alpha_bounds(body).end.y - 1)
	x_offset = clampi(x_offset, MARGIN, 124 - body.get_width())
	y_offset = maxi(y_offset, MARGIN)
	var output := current_effect
	output.blit_rect(body, Rect2i(Vector2i.ZERO, body.get_size()), Vector2i(x_offset, y_offset))
	# Keep the source effect as-is, but no generated crop may touch the outer ring.
	for i in MARGIN:
		for p in CELL:
			output.set_pixel(i, p, TRANSPARENT)
			output.set_pixel(CELL - 1 - i, p, TRANSPARENT)
			output.set_pixel(p, i, TRANSPARENT)
			output.set_pixel(p, CELL - 1 - i, TRANSPARENT)
	_write_cell(sheet, 4, column, output)
	print("FIX attack body r4c%d source=%s placed=(%d,%d) size=%s" % [column, source_rect, x_offset, y_offset, body.get_size()])

func _fix_frey_attacks(sheet: Image, source: Image) -> void:
	# r4c2: retain the accepted body and add the missing sword/slash from the whole source
	# pose. The effect is narrowed to the remaining legal width.
	var frame2 := _cell(sheet, 4, 2)
	var effect := source.get_region(Rect2i(500, 804, 210, 217))
	for y in effect.get_height():
		for x in effect.get_width():
			var color := effect.get_pixel(x, y)
			if color.a < 0.22 or not (_is_bright_cyan(color) or (color.r8 > 135 and color.g8 > 135 and color.b8 > 135)):
				effect.set_pixel(x, y, TRANSPARENT)
			else:
				color.a = 1.0
				effect.set_pixel(x, y, color)
	var eb := _alpha_bounds(effect)
	effect = effect.get_region(eb)
	effect.resize(54, maxi(1, roundi(effect.get_height() * 0.51)), Image.INTERPOLATE_NEAREST)
	_binary_alpha(effect)
	for y in effect.get_height():
		for x in effect.get_width():
			var target := Vector2i(70 + x, 48 + y)
			if target.x < 124 and target.y < 124 and effect.get_pixel(x, y).a > 0.5 and frame2.get_pixelv(target).a < 0.5:
				frame2.set_pixelv(target, effect.get_pixel(x, y))
	_inset_outer_ring(frame2)
	_write_cell(sheet, 4, 2, frame2)
	# r4c3: source cape and sword are both present in the current frame but end at a flat
	# crop. Move only the cropped edge pixels inward and taper them over four pixels.
	var frame3 := _cell(sheet, 4, 3)
	_inset_outer_ring(frame3)
	_taper_side(frame3, true)
	_taper_side(frame3, false)
	_write_cell(sheet, 4, 3, frame3)

func _inset_outer_ring(image: Image) -> void:
	for i in MARGIN:
		for p in CELL:
			image.set_pixel(i, p, TRANSPARENT)
			image.set_pixel(CELL - 1 - i, p, TRANSPARENT)
			image.set_pixel(p, i, TRANSPARENT)
			image.set_pixel(p, CELL - 1 - i, TRANSPARENT)

func _taper_side(image: Image, left: bool) -> void:
	var edge_x := MARGIN if left else CELL - 1 - MARGIN
	for y in range(MARGIN, CELL - MARGIN):
		if image.get_pixel(edge_x, y).a < 0.5:
			continue
		if y % 3 == 0:
			image.set_pixel(edge_x, y, TRANSPARENT)

func _is_bright_cyan(color: Color) -> bool:
	return color.a >= 0.22 and color.b8 >= 125 and color.g8 >= 85 and color.b8 >= color.r8 + 24

func _binary_alpha_threshold(image: Image, threshold: float) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < threshold:
				image.set_pixel(x, y, TRANSPARENT)
			else:
				color.a = 1.0
				image.set_pixel(x, y, color)

func _coverage(image: Image, columns: bool) -> PackedInt32Array:
	var size := image.get_width() if columns else image.get_height()
	var other := image.get_height() if columns else image.get_width()
	var result := PackedInt32Array()
	result.resize(size)
	for i in size:
		var count := 0
		for j in other:
			var alpha := image.get_pixel(i, j).a if columns else image.get_pixel(j, i).a
			if alpha > 0.5:
				count += 1
		result[i] = count
	return result

func _best_offset(target: PackedInt32Array, piece: PackedInt32Array) -> int:
	var best := 0
	var best_cost := 1 << 30
	for offset in range(-piece.size() + 1, target.size()):
		var cost := 0
		for i in target.size():
			var j := i - offset
			var value := piece[j] if j >= 0 and j < piece.size() else 0
			cost += absi(target[i] - value)
		if cost < best_cost:
			best_cost = cost
			best = offset
	return best

func _fix_rio_shield(sheet: Image, source: Image, column: int) -> void:
	var frame := _cell(sheet, 5, column)
	var current_mask := _shield_mask(frame, Rect2i(90, 5, 34, 119), false)
	var current_bounds := _alpha_bounds(current_mask)
	# Measured source crystal windows. These deliberately start to the right of Rio's hand
	# and end before the next pose's face/body; the colour mask rejects its navy hair.
	var source_lefts := [0, 330, 520, 710, 900, 0]
	var source_rect := Rect2i(source_lefts[column], 986, 82, 180)
	var crystal := _shield_mask(source.get_region(source_rect), Rect2i(0, 0, source_rect.size.x, source_rect.size.y), true)
	var crystal_bounds := _alpha_bounds(crystal)
	crystal = crystal.get_region(crystal_bounds)
	var target_height := current_bounds.size.y
	var scale := float(target_height) / crystal.get_height()
	var target_size := Vector2i(maxi(1, roundi(crystal.get_width() * scale)), target_height)
	# The body stays at its existing scale. Only the wide glow/shield is narrowed when the
	# complete source effect would cross the mandatory 4 px cell margin.
	var max_width := 123 - current_bounds.position.x
	if target_size.x > max_width:
		target_size.x = max_width
	crystal.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	_binary_alpha(crystal)
	var destination := Vector2i(current_bounds.position.x, current_bounds.position.y)
	# Add the missing part only into transparent pixels. Existing body, sword and the intact
	# portion of the shield remain byte-for-byte unchanged and therefore stay in front.
	for y in crystal.get_height():
		for x in crystal.get_width():
			var target := destination + Vector2i(x, y)
			if crystal.get_pixel(x, y).a > 0.5 and frame.get_pixelv(target).a < 0.5:
				frame.set_pixelv(target, crystal.get_pixel(x, y))
	_binary_alpha(frame)
	_write_cell(sheet, 5, column, frame)
	print("FIX rio_female r5c%d source=%s current=%s result=%s" % [column, source_rect, current_bounds, _alpha_bounds(frame)])

func _shield_mask(image: Image, area: Rect2i, source_mode: bool) -> Image:
	var result := Image.create_empty(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	result.fill(TRANSPARENT)
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var color := image.get_pixel(x, y)
			if color.a < (0.22 if source_mode else 0.5):
				continue
			var cyan := color.b8 >= 115 and color.g8 >= 80 and color.b8 >= color.r8 + 18
			var pale_rune := color.r8 >= 125 and color.g8 >= 155 and color.b8 >= 175
			if cyan or pale_rune:
				color.a = 1.0
				result.set_pixel(x, y, color)
	return result

func _binary_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				image.set_pixel(x, y, TRANSPARENT)
			else:
				color.a = 1.0
				image.set_pixel(x, y, color)

func _cell(sheet: Image, row: int, column: int) -> Image:
	return sheet.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))

func _write_cell(sheet: Image, row: int, column: int, frame: Image) -> void:
	sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, Vector2i(CELL, CELL)), Vector2i(column * CELL, row * CELL))

func _alpha_bounds(image: Image) -> Rect2i:
	var left := image.get_width()
	var top := image.get_height()
	var right := -1
	var bottom := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.5:
				continue
			left = mini(left, x)
			top = mini(top, y)
			right = maxi(right, x)
			bottom = maxi(bottom, y)
	if right < left:
		return Rect2i()
	return Rect2i(left, top, right - left + 1, bottom - top + 1)

func _save_board(id: String, frames: Array, before: Image, after: Image) -> void:
	var zoom := 3
	var row_h := CELL * zoom + 8
	var board := Image.create_empty(CELL * zoom * 2 + 24, row_h * frames.size() + 8, false, Image.FORMAT_RGBA8)
	board.fill(Color("151a24"))
	for index in frames.size():
		var coord: Vector2i = frames[index]
		for side in 2:
			var cell := _cell(before if side == 0 else after, coord.y, coord.x)
			var back := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
			back.fill(Color("4b5261"))
			back.blend_rect(cell, Rect2i(Vector2i.ZERO, Vector2i(CELL, CELL)), Vector2i.ZERO)
			back.resize(CELL * zoom, CELL * zoom, Image.INTERPOLATE_NEAREST)
			board.blit_rect(back, Rect2i(Vector2i.ZERO, back.get_size()), Vector2i(8 + side * (CELL * zoom + 8), 8 + index * row_h))
	board.save_png(ProjectSettings.globalize_path(REPORT + "/before_after/%s_before_after_3x.png" % id))
