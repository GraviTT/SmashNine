extends SceneTree
## Frame-by-frame audit of the v2 character sheets (6x7 cells, rows idle 4 / walk 6 / jump 1 /
## fall 1 / attack 4 / shield 6 / hurt 1). Lead's independent check for CODEX-ART-09.
## Per used frame:
## - cut: longest straight run of outline pixels along one column or row within 7 px of the cell
##   border, with nothing beyond it (art clipped at the border and then trimmed shows up as a
##   long straight edge right next to the transparent margin)
## - edge_fill: opaque pixels on the left, right and top line of the frame's bounding box. Round
##   art touches its box with a few pixels; art clipped by a crop box (the v2 first pass clamped
##   frames to about x 22..106) leaves a filled straight line there.
## - margin: smallest distance from any opaque pixel to the cell border (contract: >= 4)
## - box: opaque bounding box; height and centre jumps between neighbouring frames of a row
## - same: idle/walk frames that are pixel-identical to the previous frame
## Writes <out>/frame_audit.csv and <out>/<sheet>_flags.png (sheet at 2x, flagged cells boxed in
## red, cut edges marked in yellow).
## Usage: godot --headless --path . -s tests/analysis/lead/frame_audit.gd -- --out=../routine/x res://assets/art/frey/frey_sheet.png ...

const ROWS := [4, 6, 1, 1, 4, 6, 1]
const ROW_NAMES := ["idle", "walk", "jump", "fall", "attack", "shield", "hurt"]
const BORDER_BAND := 7
const CUT_RUN := 9
const MIN_MARGIN := 4
const HEIGHT_JUMP := 8
const CENTRE_JUMP := 8.0
const EDGE_FILL := 16

var out_dir := "user://frame_audit"
var csv_lines: Array[String] = ["sheet,row,col,anim,cut_px,cut_side,edge_left,edge_right,edge_top,margin,top,bottom,left,right,height,centre_x,height_jump,centre_jump,same_as_prev,flags"]

func _initialize() -> void:
	var sheets: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = ProjectSettings.globalize_path("res://").path_join(arg.get_slice("=", 1))
		else:
			sheets.append(arg)
	DirAccess.make_dir_recursive_absolute(out_dir)
	for path in sheets:
		_audit(path)
	var file := FileAccess.open(out_dir.path_join("frame_audit.csv"), FileAccess.WRITE)
	file.store_string("\n".join(csv_lines) + "\n")
	quit(0)

func _audit(path: String) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	var cell := image.get_width() / 6
	var board := image.duplicate() as Image
	board.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var flagged := 0
	var worst: Array[String] = []
	for row in 7:
		var previous: Dictionary = {}
		var previous_cell: Image = null
		for column in ROWS[row]:
			var frame := image.get_region(Rect2i(column * cell, row * cell, cell, cell))
			var info := _frame_info(frame, cell)
			var height_jump := 0
			var centre_jump := 0.0
			if not previous.is_empty():
				height_jump = absi(int(info.height) - int(previous.height))
				centre_jump = absf(float(info.centre_x) - float(previous.centre_x))
			var same := previous_cell != null and frame.get_data() == previous_cell.get_data()
			var flags: Array[String] = []
			if int(info.cut_px) >= CUT_RUN:
				flags.append("cut")
			for side in ["left", "right", "top"]:
				if int(info["edge_" + side]) >= EDGE_FILL:
					flags.append("box_" + side)
			if int(info.margin) < MIN_MARGIN:
				flags.append("margin")
			if height_jump >= HEIGHT_JUMP and row != 4 and row != 5:
				flags.append("height_jump")
			if centre_jump >= CENTRE_JUMP and row != 4:
				flags.append("centre_jump")
			if same:
				flags.append("same")
			csv_lines.append("%s,%d,%d,%s,%d,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%.1f,%d,%.1f,%s,%s" % [path.get_file(), row, column, ROW_NAMES[row], info.cut_px, info.cut_side, info.edge_left, info.edge_right, info.edge_top, info.margin, info.top, info.bottom, info.left, info.right, info.height, info.centre_x, height_jump, centre_jump, str(same), " ".join(flags)])
			if not flags.is_empty():
				flagged += 1
				worst.append("r%dc%d(%s)" % [row, column, "+".join(flags)])
				_box(board, column * cell * 2, row * cell * 2, cell * 2, Color(1, 0.15, 0.15))
				for point in info.cut_points + info.edge_points:
					var p: Vector2i = point
					_dot(board, (column * cell + p.x) * 2, (row * cell + p.y) * 2, Color(1, 0.9, 0.1))
			previous = info
			previous_cell = frame
	board.save_png(out_dir.path_join("%s_flags.png" % path.get_file().get_basename()))
	print("FRAME_AUDIT %s flagged=%d/23 %s" % [path.get_file(), flagged, " ".join(worst)])

func _frame_info(frame: Image, cell: int) -> Dictionary:
	var top := cell
	var bottom := -1
	var left := cell
	var right := -1
	var sum_x := 0.0
	var count := 0
	for y in cell:
		for x in cell:
			if frame.get_pixel(x, y).a >= 0.5:
				top = mini(top, y)
				bottom = maxi(bottom, y)
				left = mini(left, x)
				right = maxi(right, x)
				sum_x += x
				count += 1
	var margin := 0
	if count > 0:
		margin = mini(mini(top, left), mini(cell - 1 - bottom, cell - 1 - right))
	var cut := _longest_cut(frame, cell)
	var edge := {"left": 0, "right": 0, "top": 0}
	var edge_points: Array = []
	if count > 0:
		for y in cell:
			if frame.get_pixel(left, y).a >= 0.5:
				edge.left += 1
			if frame.get_pixel(right, y).a >= 0.5:
				edge.right += 1
		for x in cell:
			if frame.get_pixel(x, top).a >= 0.5:
				edge.top += 1
		for spec in [["left", left, true], ["right", right, true], ["top", top, false]]:
			if int(edge[spec[0]]) >= EDGE_FILL:
				for i in cell:
					var p := Vector2i(spec[1], i) if spec[2] else Vector2i(i, spec[1])
					if frame.get_pixel(p.x, p.y).a >= 0.5:
						edge_points.append(p)
	return {
		"edge_left": edge.left, "edge_right": edge.right, "edge_top": edge.top, "edge_points": edge_points,
		"top": top, "bottom": bottom, "left": left, "right": right,
		"height": (bottom - top + 1) if count > 0 else 0,
		"centre_x": (sum_x / count) if count > 0 else 0.0,
		"margin": margin, "cut_px": cut.length, "cut_side": cut.side, "cut_points": cut.points
	}

## Longest run of opaque pixels on one column (or row) near a border whose outward neighbour is
## transparent. Hair or a cape can make short straight edges; a clipped arc makes long ones.
func _longest_cut(frame: Image, cell: int) -> Dictionary:
	var best := {"length": 0, "side": "-", "points": []}
	for band in BORDER_BAND:
		var lines := [
			["left", band, -1, true], ["right", cell - 1 - band, 1, true],
			["top", band, -1, false], ["bottom", cell - 1 - band, 1, false]
		]
		for spec in lines:
			var side: String = spec[0]
			var at: int = spec[1]
			var outward: int = spec[2]
			var vertical: bool = spec[3]
			var run: Array[Vector2i] = []
			for i in cell:
				var p := Vector2i(at, i) if vertical else Vector2i(i, at)
				var o := p + (Vector2i(outward, 0) if vertical else Vector2i(0, outward))
				var opaque := frame.get_pixel(p.x, p.y).a >= 0.5
				var outside_clear := o.x < 0 or o.y < 0 or o.x >= cell or o.y >= cell or frame.get_pixel(o.x, o.y).a < 0.5
				if opaque and outside_clear:
					run.append(p)
					if run.size() > int(best.length):
						best = {"length": run.size(), "side": "%s@%d" % [side, at], "points": run.duplicate()}
				else:
					run.clear()
	return best

func _box(board: Image, x0: int, y0: int, size: int, color: Color) -> void:
	for i in size:
		for t in 2:
			board.set_pixel(x0 + i, y0 + t, color)
			board.set_pixel(x0 + i, y0 + size - 1 - t, color)
			board.set_pixel(x0 + t, y0 + i, color)
			board.set_pixel(x0 + size - 1 - t, y0 + i, color)

func _dot(board: Image, x: int, y: int, color: Color) -> void:
	for dy in 2:
		for dx in 2:
			if x + dx < board.get_width() and y + dy < board.get_height():
				board.set_pixel(x + dx, y + dy, color)
