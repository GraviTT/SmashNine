extends SceneTree
## Softens only the straight contour samples rejected by test_sprite_frames.gd.

const CELL := 128
const CUT_RUN := 9
const EDGE_FILL := 16
const BORDER_BAND := 7
const FADED_ALPHA := 0.35
const SPECS := [
	{
		"label": "rio_male",
		"source": "res://tests/art_preview/moves_23/rio_male_sheet_v2.png",
		"live": "res://assets/art/rio/rio_male_sheet.png",
		"cells": [Vector2i(2, 4), Vector2i(0, 5), Vector2i(1, 5)],
		"contact_cells": [Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(5, 5)],
	},
	{
		"label": "rio_female",
		"source": "res://tests/art_preview/moves_23/rio_female_sheet_v2.png",
		"live": "res://assets/art/rio/rio_female_sheet.png",
		"cells": [Vector2i(1, 4), Vector2i(2, 4), Vector2i(0, 5)],
		"contact_cells": [Vector2i(1, 4), Vector2i(2, 4), Vector2i(0, 5)],
	},
]

func _initialize() -> void:
	for spec in SPECS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(str(spec.source)))
		if image.is_empty():
			push_error("margin_30: missing %s" % spec.source)
			quit(1)
			return
		for cell in spec.cells:
			var frame := image.get_region(Rect2i(cell.x * CELL, cell.y * CELL, CELL, CELL))
			var faded := _repair(frame)
			image.fill_rect(Rect2i(cell.x * CELL, cell.y * CELL, CELL, CELL), Color(0, 0, 0, 0))
			image.blit_rect(frame, Rect2i(0, 0, CELL, CELL), cell * CELL)
			print("margin_30 %s r%dc%d: faded=%d" % [spec.label, cell.y, cell.x, faded])
		image.save_png(ProjectSettings.globalize_path(str(spec.source)))
		image.save_png(ProjectSettings.globalize_path(str(spec.live)))
		image.save_png(ProjectSettings.globalize_path("res://tests/art_preview/margin_30/%s_after.png" % spec.label))
		var before := Image.load_from_file(ProjectSettings.globalize_path("res://tests/art_preview/margin_30/%s_before.png" % spec.label))
		_write_contact(str(spec.label), before, image, spec.contact_cells)
	quit(0)

func _write_contact(label: String, before: Image, after: Image, cells: Array) -> void:
	var board := Image.create(CELL * 2, CELL * cells.size(), false, Image.FORMAT_RGBA8)
	for index in cells.size():
		var cell: Vector2i = cells[index]
		var rect := Rect2i(cell.x * CELL, cell.y * CELL, CELL, CELL)
		board.blit_rect(before, rect, Vector2i(0, index * CELL))
		board.blit_rect(after, rect, Vector2i(CELL, index * CELL))
	board.save_png(ProjectSettings.globalize_path("res://tests/art_preview/margin_30/%s_changed_before_after_1x.png" % label))
	var enlarged := board.duplicate()
	enlarged.resize(board.get_width() * 4, board.get_height() * 4, Image.INTERPOLATE_NEAREST)
	enlarged.save_png(ProjectSettings.globalize_path("res://tests/art_preview/margin_30/%s_changed_before_after_4x.png" % label))

func _repair(frame: Image) -> int:
	var faded := 0
	for iteration in 32:
		var changed := false
		for band in BORDER_BAND:
			for spec in [[band, -1, true], [CELL - 1 - band, 1, true], [band, -1, false], [CELL - 1 - band, 1, false]]:
				var run_points: Array[Vector2i] = []
				for i in CELL + 1:
					var qualifies := false
					var point := Vector2i.ZERO
					if i < CELL:
						point = Vector2i(spec[0], i) if spec[2] else Vector2i(i, spec[0])
						var outward := point + (Vector2i(spec[1], 0) if spec[2] else Vector2i(0, spec[1]))
						var outside_clear := outward.x < 0 or outward.y < 0 or outward.x >= CELL or outward.y >= CELL or frame.get_pixelv(outward).a < 0.5
						qualifies = frame.get_pixelv(point).a >= 0.5 and outside_clear
					if qualifies:
						run_points.append(point)
					elif run_points.size() >= CUT_RUN:
						faded += _fade(frame, run_points[run_points.size() / 2])
						changed = true
						run_points.clear()
					else:
						run_points.clear()
		var bounds := _bounds(frame)
		if bounds.size != Vector2i.ZERO:
			for line_spec in [[bounds.position.x, true], [bounds.end.x - 1, true], [bounds.position.y, false]]:
				var points: Array[Vector2i] = []
				for i in CELL:
					var point := Vector2i(line_spec[0], i) if line_spec[1] else Vector2i(i, line_spec[0])
					if frame.get_pixelv(point).a >= 0.5:
						points.append(point)
				if points.size() >= EDGE_FILL:
					var remove_count := points.size() - EDGE_FILL + 1
					for index in remove_count:
						var pick := int(floor((float(index) + 0.5) * float(points.size()) / float(remove_count)))
						faded += _fade(frame, points[mini(pick, points.size() - 1)])
					changed = true
		if not changed:
			break
	return faded

func _fade(image: Image, point: Vector2i) -> int:
	var color := image.get_pixelv(point)
	if color.a < 0.5:
		return 0
	color.a = FADED_ALPHA
	image.set_pixelv(point, color)
	return 1

func _bounds(image: Image) -> Rect2i:
	var rect := Rect2i()
	for y in CELL:
		for x in CELL:
			if image.get_pixel(x, y).a >= 0.5:
				var point := Vector2i(x, y)
				rect = Rect2i(point, Vector2i.ONE) if rect.size == Vector2i.ZERO else rect.expand(point).expand(point + Vector2i.ONE)
	return rect
