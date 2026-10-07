extends SceneTree

const CELL := 128
const ROW := 4
const MARGIN := 4
const ALPHA_CUT := 0.22
const TRANSPARENT := Color(0, 0, 0, 0)
const ROOT := "res://tests/art_preview/sprite_fix_a3"
const REPORT := "res://../reports/codex-art-12/round2"

const SPECS := [
	["rio_female", "res://assets/art/rio/rio_female_sheet.png", "res://assets/art/rio/rio_female_v2_rework_source.png", [0, 1, 2, 3]],
	["frey", "res://assets/art/frey/frey_sheet.png", "res://assets/art/frey/frey_v2_source.png", [2, 3]],
	["luna", "res://assets/art/luna/luna_sheet.png", "res://assets/art/luna/luna_v2_source.png", [3]],
	["nova_female", "res://assets/art/nova/nova_female_sheet.png", "res://assets/art/nova/nova_female_v2_source.png", [1, 2]],
]

var log_lines: PackedStringArray = []

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT + "/baseline"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT + "/before_after"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT + "/rows"))
	for spec: Array in SPECS:
		_apply_spec(spec)
	var log_file := FileAccess.open(ProjectSettings.globalize_path(REPORT + "/apply_log.txt"), FileAccess.WRITE)
	log_file.store_string("\n".join(log_lines) + "\n")
	log_file.close()
	quit()

func _apply_spec(spec: Array) -> void:
	var id: String = spec[0]
	var sheet_path: String = spec[1]
	var source_path: String = spec[2]
	var columns: Array = spec[3]
	var baseline_path := ROOT + "/baseline/%s_sheet.png" % id
	var current := Image.load_from_file(ProjectSettings.globalize_path(sheet_path))
	current.convert(Image.FORMAT_RGBA8)
	if not FileAccess.file_exists(ProjectSettings.globalize_path(baseline_path)):
		current.save_png(ProjectSettings.globalize_path(baseline_path))
	var baseline := Image.load_from_file(ProjectSettings.globalize_path(baseline_path))
	baseline.convert(Image.FORMAT_RGBA8)
	var sheet := baseline.duplicate()
	var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	source.convert(Image.FORMAT_RGBA8)
	for column: int in columns:
		var before := _cell(sheet, column)
		var transform := _fit_source_transform(id, source, before, column)
		var fixed := before.duplicate()
		_apply_frame_pieces(id, column, source, fixed, transform)
		_binary_alpha(fixed)
		_cleanup_target_edges(id, column, before, fixed)
		_inset_margin(fixed)
		_write_cell(sheet, column, fixed)
		_save_pair(id, column, before, fixed)
		log_lines.append("%s r4c%d scale=%.3f translate=(%d,%d) before=%s after=%s changed_pixels=%d" % [
			id, column, transform.scale, transform.tx, transform.ty,
			_alpha_bounds(before), _alpha_bounds(fixed), _pixel_diff(before, fixed)
		])
	sheet.save_png(ProjectSettings.globalize_path(sheet_path))
	_save_row(id, sheet)

func _apply_frame_pieces(id: String, column: int, source: Image, frame: Image, transform: Dictionary) -> void:
	if id == "rio_female":
		if column == 0:
			# Raised blade/slash crossed the top row split. This hand window stops before
			# the previous animation pose's boot.
			_overlay_piece(source, frame, Rect2i(100, 735, 115, 82), "silver_cyan", transform)
		elif column == 1:
			# Hair/cape left of the builder's x=238 split; x<178 belongs to pose 0.
			_overlay_piece(source, frame, Rect2i(178, 797, 60, 168), "rio_blue", transform)
		elif column == 2:
			# Dark hair/cape only: this rejects pose 1's pale/cyan crescent.
			_overlay_piece(source, frame, Rect2i(350, 797, 100, 168), "rio_blue", transform)
		elif column == 3:
			# Dark cape/hair left of x=661; the neighbouring slash is cyan and rejected.
			_overlay_piece(source, frame, Rect2i(550, 797, 111, 168), "rio_blue", transform)
	elif id == "frey":
		if column == 2:
			# Missing horizontal blade and blue slash to the right of x=580. Bright-only
			# masking keeps the next pose's blonde head/cape out.
			_overlay_piece(source, frame, Rect2i(480, 830, 235, 191), "frey_attack", transform)
			_overlay_frey_slash(source, frame)
		elif column == 3:
			# Navy cape on the left, then the down-right silver blade on the empty right.
			_overlay_piece(source, frame, Rect2i(528, 820, 52, 190), "navy", transform)
			_overlay_piece(source, frame, Rect2i(773, 900, 150, 121), "silver", transform)
	elif id == "luna" and column == 3:
		# The last pose has no neighbour on its right: this restores its whole wand and
		# detached sparkles beyond the old x=774 cut without importing another pose.
		_overlay_piece(source, frame, Rect2i(774, 774, 126, 194), "all", transform)
	elif id == "nova_female":
		if column == 1:
			# Cyan/gold energy continuing to the right; dark pixels are pose 2's body.
			_overlay_piece(source, frame, Rect2i(387, 850, 128, 118), "nova_energy", transform)
		elif column == 2:
			# Lower-left trail of pose 2. Limiting it below y=890 separates it from pose
			# 1's arm even though the generated energy fields touch.
			_overlay_piece(source, frame, Rect2i(286, 890, 101, 101), "nova_energy", transform)

func _fit_source_transform(id: String, source: Image, current: Image, column: int) -> Dictionary:
	var core_rect := _builder_core_rect(id, source, column)
	var core := source.get_region(core_rect)
	_threshold(core, "all")
	var local_bounds := _alpha_bounds(core)
	var cropped := core.get_region(local_bounds)
	var global_origin := core_rect.position + local_bounds.position
	var best := {"scale": 0.5, "tx": 0, "ty": 0, "cost": 1 << 30}
	for step in range(42, 61):
		var scale := float(step) / 100.0
		var piece := cropped.duplicate()
		piece.resize(maxi(1, roundi(piece.get_width() * scale)), maxi(1, roundi(piece.get_height() * scale)), Image.INTERPOLATE_NEAREST)
		_binary_alpha(piece)
		var offset := Vector2i(_best_offset(_coverage(current, true), _coverage(piece, true)), _best_offset(_coverage(current, false), _coverage(piece, false)))
		var candidate := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
		candidate.fill(TRANSPARENT)
		candidate.blit_rect(piece, Rect2i(Vector2i.ZERO, piece.get_size()), offset)
		var cost := _alpha_difference(candidate, current)
		if cost < best.cost:
			best = {
				"scale": scale,
				"tx": offset.x - roundi(global_origin.x * scale),
				"ty": offset.y - roundi(global_origin.y * scale),
				"cost": cost,
			}
	return best

func _overlay_frey_slash(source: Image, frame: Image) -> void:
	# The full source effect is wider than one cell. Keep the body/sword scale unchanged,
	# narrow only the crescent, and stop it at x=123 as required by the card.
	var effect := source.get_region(Rect2i(500, 804, 210, 217))
	for y in effect.get_height():
		for x in effect.get_width():
			var color := effect.get_pixel(x, y)
			var cyan := color.a >= ALPHA_CUT and color.b8 >= 120 and color.g8 >= 80 and color.b8 >= color.r8 + 15
			if not cyan:
				effect.set_pixel(x, y, TRANSPARENT)
			else:
				color.a = 1.0
				effect.set_pixel(x, y, color)
	var bounds := _alpha_bounds(effect)
	if bounds.size == Vector2i.ZERO:
		return
	effect = effect.get_region(bounds)
	effect.resize(54, maxi(1, roundi(effect.get_height() * 0.51)), Image.INTERPOLATE_NEAREST)
	_binary_alpha(effect)
	var destination := Vector2i(70, 42)
	for y in effect.get_height():
		for x in effect.get_width():
			var target := destination + Vector2i(x, y)
			if target.x >= CELL - MARGIN or target.y >= CELL - MARGIN:
				continue
			if effect.get_pixel(x, y).a > 0.5 and frame.get_pixelv(target).a < 0.5:
				frame.set_pixelv(target, effect.get_pixel(x, y))

func _builder_core_rect(id: String, source: Image, column: int) -> Rect2i:
	if id == "rio_female":
		var y0 := roundi(float(ROW) * source.get_height() / 7.0)
		var y1 := roundi(float(ROW + 1) * source.get_height() / 7.0)
		var first := source.get_width()
		var last := -1
		for x in source.get_width():
			for y in range(y0, y1):
				if source.get_pixel(x, y).a > 0.04:
					first = mini(first, x)
					last = maxi(last, x)
					break
		var span := last - first + 1
		var left := roundi(first + float(column) * span / 4.0)
		var right := roundi(first + float(column + 1) * span / 4.0)
		return Rect2i(left, y0, right - left, y1 - y0)
	var bounds := _row_boundaries(source)
	var left := roundi(float(column) * source.get_width() / 6.0)
	var right := roundi(float(column + 1) * source.get_width() / 6.0)
	return Rect2i(left, bounds[ROW], right - left, bounds[ROW + 1] - bounds[ROW])

func _overlay_piece(source: Image, frame: Image, rect: Rect2i, mode: String, transform: Dictionary) -> void:
	var piece := source.get_region(rect)
	_threshold(piece, mode)
	var bounds := _alpha_bounds(piece)
	if bounds.size == Vector2i.ZERO:
		return
	piece = piece.get_region(bounds)
	piece.resize(maxi(1, roundi(piece.get_width() * transform.scale)), maxi(1, roundi(piece.get_height() * transform.scale)), Image.INTERPOLATE_NEAREST)
	_binary_alpha(piece)
	var global_origin := rect.position + bounds.position
	var destination := Vector2i(roundi(global_origin.x * transform.scale) + transform.tx, roundi(global_origin.y * transform.scale) + transform.ty)
	for y in piece.get_height():
		for x in piece.get_width():
			var target := destination + Vector2i(x, y)
			if target.x < MARGIN or target.y < MARGIN or target.x >= CELL - MARGIN or target.y >= CELL - MARGIN:
				continue
			if piece.get_pixel(x, y).a > 0.5 and frame.get_pixelv(target).a < 0.5:
				frame.set_pixelv(target, piece.get_pixel(x, y))

func _threshold(image: Image, mode: String) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			var keep := color.a >= ALPHA_CUT
			if keep and mode == "rio_blue":
				keep = color.b8 >= 48 and color.b8 >= color.r8 + 10 and maxi(color.r8, maxi(color.g8, color.b8)) <= 155
			elif keep and mode == "silver_cyan":
				var cyan := color.b8 >= 125 and color.g8 >= 80 and color.b8 >= color.r8 + 20
				var silver := color.r8 >= 105 and color.g8 >= 100 and color.b8 >= 95 and maxi(color.r8, maxi(color.g8, color.b8)) - mini(color.r8, mini(color.g8, color.b8)) < 85
				keep = cyan or silver
			elif keep and mode == "navy":
				keep = color.b8 >= 50 and color.b8 >= color.r8 + 12
			elif keep and mode == "silver":
				keep = color.r8 >= 105 and color.g8 >= 100 and color.b8 >= 95 and maxi(color.r8, maxi(color.g8, color.b8)) - mini(color.r8, mini(color.g8, color.b8)) < 85
			elif keep and mode == "frey_attack":
				var cyan := color.b8 >= 125 and color.g8 >= 80 and color.b8 >= color.r8 + 20
				var silver := y > 55 and color.r8 >= 120 and color.g8 >= 115 and color.b8 >= 110 and maxi(color.r8, maxi(color.g8, color.b8)) - mini(color.r8, mini(color.g8, color.b8)) < 70
				keep = cyan or silver
			elif keep and mode == "nova_energy":
				var cyan := color.g8 >= 90 and color.b8 >= 95 and (color.g8 + color.b8) >= color.r8 * 2
				var gold := color.r8 >= 170 and color.g8 >= 115 and color.b8 < 135
				keep = cyan or gold
			if not keep:
				image.set_pixel(x, y, TRANSPARENT)
			else:
				color.a = 1.0
				image.set_pixel(x, y, color)

func _cleanup_target_edges(id: String, column: int, before: Image, fixed: Image) -> void:
	if id == "rio_female" and column == 0:
		_taper_added_bound(before, fixed, "top")
	elif id == "frey" and column == 2:
		_clear_added_beyond(before, fixed, 4, 120)
		_taper_added_bound(before, fixed, "right")
	elif id == "luna" and column == 3:
		_clear_added_beyond(before, fixed, 4, 120)
		_taper_added_bound(before, fixed, "right")
	elif id == "nova_female" and column == 1:
		_clear_added_beyond(before, fixed, 4, 120)
		_taper_added_bound(before, fixed, "right")
	elif id == "nova_female" and column == 2:
		_clear_added_beyond(before, fixed, 7, 123)
		_taper_added_bound(before, fixed, "left")

func _clear_added_beyond(before: Image, fixed: Image, min_x: int, max_x: int) -> void:
	for y in CELL:
		for x in CELL:
			if (x < min_x or x > max_x) and before.get_pixel(x, y).a < 0.5:
				fixed.set_pixel(x, y, TRANSPARENT)

func _taper_added_bound(before: Image, fixed: Image, side: String) -> void:
	var bounds := _alpha_bounds(fixed)
	if bounds.size == Vector2i.ZERO:
		return
	if side == "top":
		for x in range(bounds.position.x, bounds.end.x):
			if x % 2 == 0 and before.get_pixel(x, bounds.position.y).a < 0.5:
				fixed.set_pixel(x, bounds.position.y, TRANSPARENT)
	elif side == "left":
		for y in range(bounds.position.y, bounds.end.y):
			if y % 2 == 0 and before.get_pixel(bounds.position.x, y).a < 0.5:
				fixed.set_pixel(bounds.position.x, y, TRANSPARENT)
	elif side == "right":
		var x := bounds.end.x - 1
		for y in range(bounds.position.y, bounds.end.y):
			if y % 2 == 0 and before.get_pixel(x, y).a < 0.5:
				fixed.set_pixel(x, y, TRANSPARENT)

func _row_boundaries(source: Image) -> PackedInt32Array:
	var counts := PackedInt32Array()
	counts.resize(source.get_height())
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x, y).a >= ALPHA_CUT:
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

func _best_offset(target: PackedInt32Array, piece: PackedInt32Array) -> int:
	var best := 0
	var best_cost := 1 << 30
	for offset in range(-piece.size() + 1, target.size()):
		var cost := 0
		for i in target.size():
			var j := i - offset
			var value := piece[j] if j >= 0 and j < piece.size() else 0
			cost += absi(target[i] - value)
		for j in piece.size():
			var i := j + offset
			if i < 0 or i >= target.size():
				cost += piece[j]
		if cost < best_cost:
			best_cost = cost
			best = offset
	return best

func _coverage(image: Image, columns: bool) -> PackedInt32Array:
	var size := image.get_width() if columns else image.get_height()
	var other := image.get_height() if columns else image.get_width()
	var result := PackedInt32Array()
	result.resize(size)
	for i in size:
		for j in other:
			if (image.get_pixel(i, j).a if columns else image.get_pixel(j, i).a) > 0.5:
				result[i] += 1
	return result

func _alpha_difference(a: Image, b: Image) -> int:
	var count := 0
	for y in CELL:
		for x in CELL:
			if (a.get_pixel(x, y).a > 0.5) != (b.get_pixel(x, y).a > 0.5):
				count += 1
	return count

func _pixel_diff(a: Image, b: Image) -> int:
	var count := 0
	for y in CELL:
		for x in CELL:
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				count += 1
	return count

func _binary_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				image.set_pixel(x, y, TRANSPARENT)
			else:
				color.a = 1.0
				image.set_pixel(x, y, color)

func _inset_margin(image: Image) -> void:
	for i in MARGIN:
		for p in CELL:
			image.set_pixel(i, p, TRANSPARENT)
			image.set_pixel(CELL - 1 - i, p, TRANSPARENT)
			image.set_pixel(p, i, TRANSPARENT)
			image.set_pixel(p, CELL - 1 - i, TRANSPARENT)

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
	return Rect2i() if right < left else Rect2i(left, top, right - left + 1, bottom - top + 1)

func _cell(sheet: Image, column: int) -> Image:
	return sheet.get_region(Rect2i(column * CELL, ROW * CELL, CELL, CELL))

func _write_cell(sheet: Image, column: int, frame: Image) -> void:
	sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, Vector2i(CELL, CELL)), Vector2i(column * CELL, ROW * CELL))

func _save_pair(id: String, column: int, before: Image, after: Image) -> void:
	var zoom := 3
	var board := Image.create_empty(CELL * zoom * 2 + 24, CELL * zoom + 16, false, Image.FORMAT_RGBA8)
	board.fill(Color("151a24"))
	for side in 2:
		var back := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
		back.fill(Color("4b5261"))
		back.blend_rect(before if side == 0 else after, Rect2i(Vector2i.ZERO, Vector2i(CELL, CELL)), Vector2i.ZERO)
		back.resize(CELL * zoom, CELL * zoom, Image.INTERPOLATE_NEAREST)
		board.blit_rect(back, Rect2i(Vector2i.ZERO, back.get_size()), Vector2i(8 + side * (CELL * zoom + 8), 8))
	board.save_png(ProjectSettings.globalize_path(REPORT + "/before_after/%s_r4c%d_before_after_3x.png" % [id, column]))

func _save_row(id: String, sheet: Image) -> void:
	var row := sheet.get_region(Rect2i(0, ROW * CELL, 6 * CELL, CELL))
	var back := Image.create_empty(6 * CELL, CELL, false, Image.FORMAT_RGBA8)
	back.fill(Color("4b5261"))
	back.blend_rect(row, Rect2i(Vector2i.ZERO, row.get_size()), Vector2i.ZERO)
	back.resize(12 * CELL, 2 * CELL, Image.INTERPOLATE_NEAREST)
	back.save_png(ProjectSettings.globalize_path(REPORT + "/rows/%s_attack_after_2x.png" % id))
