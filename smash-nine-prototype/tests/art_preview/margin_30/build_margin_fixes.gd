extends SceneTree
## CODEX-ART-30: enforce the 4 px live-sheet margin without scaling or moving the body.

const CELL := 128
const COLUMNS := 6
const MARGIN := 4
const OUT_DIR := "res://tests/art_preview/margin_30"
const SPECS := [
	{
		"label": "rio_male",
		"source": "res://tests/art_preview/moves_23/rio_male_sheet_v2.png",
		"live": "res://assets/art/rio/rio_male_sheet.png",
	},
	{
		"label": "rio_female",
		"source": "res://tests/art_preview/moves_23/rio_female_sheet_v2.png",
		"live": "res://assets/art/rio/rio_female_sheet.png",
	},
	{
		"label": "frey_moves",
		"source": "res://assets/art/frey/frey_moves_sheet.png",
		"live": "",
	},
	{
		"label": "luna_moves",
		"source": "res://assets/art/luna/luna_moves_sheet.png",
		"live": "",
	},
	{
		"label": "luna_brave_moves",
		"source": "res://assets/art/luna/luna_brave_moves_sheet.png",
		"live": "",
	},
]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var summary := PackedStringArray(["sheet,cell,removed,left,right,top,bottom"])
	for spec in SPECS:
		if not _fix_sheet(spec, summary):
			quit(1)
			return
	var report := FileAccess.open(ProjectSettings.globalize_path(OUT_DIR + "/margin_changes.csv"), FileAccess.WRITE)
	report.store_string("\n".join(summary) + "\n")
	report.close()
	quit(0)

func _fix_sheet(spec: Dictionary, summary: PackedStringArray) -> bool:
	var path := str(spec.source)
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image.is_empty() or image.get_width() % CELL != 0 or image.get_height() % CELL != 0:
		push_error("margin_30: invalid sheet %s" % path)
		return false
	var before := image.duplicate()
	var changed: Array[Vector2i] = []
	for row in image.get_height() / CELL:
		for column in COLUMNS:
			var counts := PackedInt32Array([0, 0, 0, 0])
			var removed := 0
			for y in CELL:
				for x in CELL:
					var point := Vector2i(column * CELL + x, row * CELL + y)
					if image.get_pixelv(point).a <= 0.0:
						continue
					if x < MARGIN or x >= CELL - MARGIN or y < MARGIN or y >= CELL - MARGIN:
						if x < MARGIN: counts[0] += 1
						if x >= CELL - MARGIN: counts[1] += 1
						if y < MARGIN: counts[2] += 1
						if y >= CELL - MARGIN: counts[3] += 1
						image.set_pixelv(point, Color(0, 0, 0, 0))
						removed += 1
			if removed > 0:
				changed.append(Vector2i(column, row))
				summary.append("%s,r%dc%d,%d,%d,%d,%d,%d" % [spec.label, row, column, removed, counts[0], counts[1], counts[2], counts[3]])
	var before_path := "%s/%s_before.png" % [OUT_DIR, spec.label]
	var after_path := "%s/%s_after.png" % [OUT_DIR, spec.label]
	before.save_png(ProjectSettings.globalize_path(before_path))
	image.save_png(ProjectSettings.globalize_path(path))
	image.save_png(ProjectSettings.globalize_path(after_path))
	if not str(spec.live).is_empty():
		image.save_png(ProjectSettings.globalize_path(str(spec.live)))
	_write_contact(spec.label, before, image, changed)
	print("margin_30 %s: changed=%d cells=%s" % [spec.label, changed.size(), changed])
	return true

func _write_contact(label: String, before: Image, after: Image, cells: Array[Vector2i]) -> void:
	var rows := maxi(1, cells.size())
	var board := Image.create(CELL * 2, CELL * rows, false, Image.FORMAT_RGBA8)
	for index in cells.size():
		var cell := cells[index]
		var source_rect := Rect2i(cell.x * CELL, cell.y * CELL, CELL, CELL)
		board.blit_rect(before, source_rect, Vector2i(0, index * CELL))
		board.blit_rect(after, source_rect, Vector2i(CELL, index * CELL))
	board.save_png(ProjectSettings.globalize_path("%s/%s_changed_before_after_1x.png" % [OUT_DIR, label]))
	var enlarged := board.duplicate()
	enlarged.resize(board.get_width() * 4, board.get_height() * 4, Image.INTERPOLATE_NEAREST)
	enlarged.save_png(ProjectSettings.globalize_path("%s/%s_changed_before_after_4x.png" % [OUT_DIR, label]))
