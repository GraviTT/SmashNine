extends SceneTree

const CELL := 128
const ROWS := 7
const ATTACK_ROW := 4
const ALPHA_CUT := 56
const REPORT := "res://../reports/codex-art-12/round2/inspection"

const SPECS := [
	["rio_female", "res://assets/art/rio/rio_female_sheet.png", "res://assets/art/rio/rio_female_v2_rework_source.png"],
	["frey", "res://assets/art/frey/frey_sheet.png", "res://assets/art/frey/frey_v2_source.png"],
	["luna", "res://assets/art/luna/luna_sheet.png", "res://assets/art/luna/luna_v2_source.png"],
	["nova_female", "res://assets/art/nova/nova_female_sheet.png", "res://assets/art/nova/nova_female_v2_source.png"],
]

func _initialize() -> void:
	var out := ProjectSettings.globalize_path(REPORT)
	DirAccess.make_dir_recursive_absolute(out)
	for spec: Array in SPECS:
		_inspect(spec, out)
	quit()

func _inspect(spec: Array, out: String) -> void:
	var id: String = spec[0]
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(spec[1]))
	var source := Image.load_from_file(ProjectSettings.globalize_path(spec[2]))
	sheet.convert(Image.FORMAT_RGBA8)
	source.convert(Image.FORMAT_RGBA8)
	var bounds := _row_boundaries(source)
	var y0: int = bounds[ATTACK_ROW]
	var y1: int = bounds[ATTACK_ROW + 1]
	var source_row := source.get_region(Rect2i(0, y0, source.get_width(), y1 - y0))
	var source_grid := _on_background(source_row, Color("30343d"))
	_draw_grid(source_grid, 50)
	source_grid.resize(source_grid.get_width() * 2, source_grid.get_height() * 2, Image.INTERPOLATE_NEAREST)
	source_grid.save_png(out.path_join("%s_source_attack_grid_2x.png" % id))
	if id == "luna":
		var overlap := source.get_region(Rect2i(520, 774, 180, 194))
		var overlap_back := _on_background(overlap, Color("30343d"))
		_draw_grid(overlap_back, 20)
		overlap_back.resize(overlap_back.get_width() * 4, overlap_back.get_height() * 4, Image.INTERPOLATE_NEAREST)
		overlap_back.save_png(out.path_join("luna_r4c2_c3_overlap_4x.png"))
	elif id == "rio_female":
		var top_overlap := source.get_region(Rect2i(20, 720, 240, 120))
		var top_back := _on_background(top_overlap, Color("30343d"))
		_draw_grid(top_back, 20)
		top_back.resize(top_back.get_width() * 4, top_back.get_height() * 4, Image.INTERPOLATE_NEAREST)
		top_back.save_png(out.path_join("rio_r4c0_top_overlap_4x.png"))
	elif id == "frey":
		var attack_overlap := source.get_region(Rect2i(460, 800, 300, 221))
		var attack_back := _on_background(attack_overlap, Color("30343d"))
		_draw_grid(attack_back, 20)
		attack_back.resize(attack_back.get_width() * 4, attack_back.get_height() * 4, Image.INTERPOLATE_NEAREST)
		attack_back.save_png(out.path_join("frey_r4c2_c3_overlap_4x.png"))
	var display_sheet := sheet
	var baseline_path := ProjectSettings.globalize_path("res://tests/art_preview/sprite_fix_a3/baseline/%s_sheet.png" % id)
	if FileAccess.file_exists(baseline_path):
		display_sheet = Image.load_from_file(baseline_path)
		display_sheet.convert(Image.FORMAT_RGBA8)
	var attack := display_sheet.get_region(Rect2i(0, ATTACK_ROW * CELL, 6 * CELL, CELL))
	var attack_back := _on_background(attack, Color("30343d"))
	for x in range(0, attack_back.get_width(), CELL):
		for y in attack_back.get_height():
			attack_back.set_pixel(x, y, Color("ff3448"))
	attack_back.resize(attack_back.get_width() * 3, attack_back.get_height() * 3, Image.INTERPOLATE_NEAREST)
	attack_back.save_png(out.path_join("%s_attack_before_3x.png" % id))
	print("INSPECT %s source=%s attack_y=%d..%d" % [id, source.get_size(), y0, y1 - 1])
	print("  builder_rects=%s" % [_builder_attack_rects(id, source)])
	for column in 4:
		var frame := sheet.get_region(Rect2i(column * CELL, ATTACK_ROW * CELL, CELL, CELL))
		print("  r4c%d bounds=%s edges=%s" % [column, _alpha_bounds(frame), _edge_counts(frame)])

func _builder_attack_rects(id: String, source: Image) -> Array[Rect2i]:
	var y0 := roundi(float(ATTACK_ROW) * source.get_height() / ROWS)
	var y1 := roundi(float(ATTACK_ROW + 1) * source.get_height() / ROWS)
	var rects: Array[Rect2i] = []
	if id == "rio_female":
		var first := source.get_width()
		var last := -1
		for x in source.get_width():
			for y in range(y0, y1):
				if source.get_pixel(x, y).a > 0.04:
					first = mini(first, x)
					last = maxi(last, x)
					break
		var span := last - first + 1
		for column in 4:
			var left := roundi(first + float(column) * span / 4.0)
			var right := roundi(first + float(column + 1) * span / 4.0)
			rects.append(Rect2i(left, y0, right - left, y1 - y0))
	else:
		for column in 4:
			var left := roundi(float(column) * source.get_width() / 6.0)
			var right := roundi(float(column + 1) * source.get_width() / 6.0)
			rects.append(Rect2i(left, y0, right - left, y1 - y0))
	return rects

func _row_boundaries(image: Image) -> PackedInt32Array:
	var counts := PackedInt32Array()
	counts.resize(image.get_height())
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a8 >= ALPHA_CUT:
				counts[y] += 1
	var boundaries := PackedInt32Array([0])
	var radius := maxi(24, roundi(float(image.get_height()) / 18.0))
	for split in range(1, ROWS):
		var expected := roundi(float(split) * image.get_height() / ROWS)
		var best := expected
		for y in range(maxi(1, expected - radius), mini(image.get_height() - 1, expected + radius + 1)):
			if counts[y] < counts[best] or (counts[y] == counts[best] and absi(y - expected) < absi(best - expected)):
				best = y
		boundaries.append(best)
	boundaries.append(image.get_height())
	return boundaries

func _alpha_bounds(image: Image) -> Rect2i:
	var left := image.get_width()
	var top := image.get_height()
	var right := -1
	var bottom := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a8 < 128:
				continue
			left = mini(left, x)
			top = mini(top, y)
			right = maxi(right, x)
			bottom = maxi(bottom, y)
	return Rect2i() if right < left else Rect2i(left, top, right - left + 1, bottom - top + 1)

func _edge_counts(image: Image) -> Vector4i:
	var counts := Vector4i()
	for p in CELL:
		if image.get_pixel(p, 0).a8 >= 128: counts.x += 1
		if image.get_pixel(CELL - 1, p).a8 >= 128: counts.y += 1
		if image.get_pixel(p, CELL - 1).a8 >= 128: counts.z += 1
		if image.get_pixel(0, p).a8 >= 128: counts.w += 1
	return counts

func _on_background(image: Image, color: Color) -> Image:
	var back := Image.create_empty(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	back.fill(color)
	back.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i.ZERO)
	return back

func _draw_grid(image: Image, spacing: int) -> void:
	for x in range(0, image.get_width(), spacing):
		var color := Color(1.0, 0.2, 0.2, 0.75) if x % 100 == 0 else Color(1.0, 0.85, 0.15, 0.45)
		for y in image.get_height():
			image.set_pixel(x, y, color)
