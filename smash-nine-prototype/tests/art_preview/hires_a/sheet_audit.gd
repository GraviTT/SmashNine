extends SceneTree
## Audits character sheets (v1 64 px or v2 128 px cells, 6x7, rows idle 4 / walk 6 / jump 1 /
## fall 1 / attack 4 / shield 6 / hurt 1) for problems seen in CODEX-ART-08 deliveries:
## - edge: opaque pixels in the outer 2 px ring of a used cell (art cut at the cell border,
##   or fragments bleeding in from a neighbouring frame)
## - fringe: pure-red pixels (r > 200, g < 70, b < 70) left by background removal
## - height: feet line minus the topmost opaque row of the idle frames (body + hair)
## - stray: opaque pixels in unused cells
## Usage: godot --headless --path . -s tests/analysis/lead/sheet_audit.gd -- res://assets/art/rio/rio_male_sheet.png ...

const ROWS := [4, 6, 1, 1, 4, 6, 1]

func _initialize() -> void:
	for path in OS.get_cmdline_user_args():
		_audit(path)
	quit(0)

func _audit(path: String) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null:
		print("SHEET_AUDIT %s missing" % path)
		return
	image.convert(Image.FORMAT_RGBA8)
	var cell := image.get_width() / 6
	var feet := 48 if cell == 64 else 120
	var edge := 0
	var fringe := 0
	var stray := 0
	var idle_heights: Array[int] = []
	var edge_cells: Array[String] = []
	for row in 7:
		for column in 6:
			var used: bool = column < ROWS[row]
			var cell_edge := 0
			var top := cell
			for y in cell:
				for x in cell:
					var color := image.get_pixel(column * cell + x, row * cell + y)
					if color.a < 0.5:
						continue
					if not used:
						stray += 1
						continue
					top = mini(top, y)
					if x < 2 or y < 2 or x >= cell - 2 or y >= cell - 2:
						cell_edge += 1
					if color.r8 > 200 and color.g8 < 70 and color.b8 < 70:
						fringe += 1
			if cell_edge > 0:
				edge += cell_edge
				edge_cells.append("r%dc%d:%d" % [row, column, cell_edge])
			if row == 0 and used:
				idle_heights.append(feet - top)
	print("SHEET_AUDIT %s cell=%d edge_px=%d edge_cells=%s fringe_px=%d stray_px=%d idle_height=%s" % [path.get_file(), cell, edge, ",".join(edge_cells), fringe, stray, str(idle_heights)])
