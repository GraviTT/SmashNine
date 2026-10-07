extends SceneTree
## Lead fix for what CODEX-ART-09 left (routine 2026-10-08). The v2 builders cut each pose out
## of the generated source with fixed rectangles (equal columns), so shields, swords and capes
## that crossed a column line were cut off. This re-extracts every pose by connected pixel
## groups instead: the big groups of a row are clustered into its poses, small groups join the
## nearest pose, and nothing is cut at a column line.
## A frame of the current sheet is replaced only when the lead audit (tests/analysis/lead/
## frame_audit.gd CSV, --flags=) marks it cut (box_* or cut) and the re-extracted pose adds the
## missing part while keeping what the frame has (it loses at most MAX_LOST_SHARE of what it
## adds, MAX_LOST at most), so frames that were fine, sheets that no longer match their source (hand-edited
## effects, the Rio rework) and Codex A's hand fixes stay. The new
## pose keeps the current frame's scale (the builder shrank some wide frames on their own; the
## scale that best covers the current frame is searched) and is placed where the current
## frame's body is (row and column coverage matched), so the body neither grows nor jumps. Parts
## that still do not fit the cell (wide slashes) are trimmed at the 4 px margin.
## Usage: godot --headless --path . -s tests/art_preview/frame_reextract_lead/reextract.gd --
##        --flags=<frame_audit.csv> [--dry] [--board=<dir>] [--rejected] [sheet ids...]
## --rejected also writes <sheet>_rejected.png: flagged frames whose re-extraction was refused.

const CELL := 128
const COLS := 6
const ROWS := 7
const COUNTS := [4, 6, 1, 1, 4, 6, 1]
const MARGIN := 4
## Alpha (0-255) from which a source pixel counts as drawn (the builders used 0.22).
const ALPHA_CUT := 56
## Pixels a re-extracted pose must add over the current frame to replace it.
const MIN_ADDED := 30
## ...and may lose at most this share of what it adds (scale rounding alone loses some; a
## frame whose art differs from the source loses much more).
const MAX_LOST_SHARE := 1.2
const MAX_LOST_FLOOR := 60
## ...and never more than this (a pose split wrongly from overlapping neighbours loses ~600+).
const MAX_LOST := 260
## A group is "big" (part of a pose body) from this share of the row's biggest group.
const BIG_SHARE := 0.08
## Small groups farther than this (source px) from every pose are dropped as specks.
const STRAY_DISTANCE := 40.0
## Scale factors (times the sheet scale) tried to match each current frame's own scale.
const SCALE_FACTORS := [1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.76, 0.73, 0.70]
const NEIGHBOURS := [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]
const SHEETS := {
	"frey": ["res://assets/art/frey/frey_v2_source.png", "res://assets/art/frey/frey_sheet.png"],
	"yuki": ["res://assets/art/yuki/yuki_v2_source.png", "res://assets/art/yuki/yuki_sheet.png"],
	"luna": ["res://assets/art/luna/luna_v2_source.png", "res://assets/art/luna/luna_sheet.png"],
	"luna_brave": ["res://assets/art/luna/luna_brave_v2_source.png", "res://assets/art/luna/luna_brave_sheet.png"],
	"nova_male": ["res://assets/art/nova/nova_male_v2_source.png", "res://assets/art/nova/nova_male_sheet.png"],
	"nova_female": ["res://assets/art/nova/nova_female_v2_source.png", "res://assets/art/nova/nova_female_sheet.png"],
	"rio_male": ["res://assets/art/rio/rio_male_v2_rework_source.png", "res://assets/art/rio/rio_male_sheet.png"],
	"rio_female": ["res://assets/art/rio/rio_female_v2_rework_source.png", "res://assets/art/rio/rio_female_sheet.png"],
}

class Group:
	var area := 0
	var min_x := 1 << 30
	var min_y := 1 << 30
	var max_x := -1
	var max_y := -1
	var sum_x := 0.0
	var sum_y := 0.0
	func add(x: int, y: int) -> void:
		area += 1
		min_x = mini(min_x, x)
		min_y = mini(min_y, y)
		max_x = maxi(max_x, x)
		max_y = maxi(max_y, y)
		sum_x += x
		sum_y += y
	func centre() -> Vector2:
		return Vector2(sum_x / area, sum_y / area)

var dry := false
var board_dir := ""
## "sheet_file:row:col" -> audit flags, for frames the audit marked.
var flagged := {}
var show_rejected := false

func _initialize() -> void:
	var ids: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg == "--dry":
			dry = true
		elif arg == "--rejected":
			show_rejected = true
		elif arg.begins_with("--flags="):
			_read_flags(ProjectSettings.globalize_path("res://").path_join(arg.get_slice("=", 1)))
		elif arg.begins_with("--board="):
			board_dir = ProjectSettings.globalize_path("res://").path_join(arg.get_slice("=", 1))
			DirAccess.make_dir_recursive_absolute(board_dir)
		else:
			ids.append(arg)
	if ids.is_empty():
		ids.assign(SHEETS.keys())
	for id in ids:
		_process_sheet(id)
	quit(0)

func _process_sheet(id: String) -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SHEETS[id][0]))
	var sheet_path: String = ProjectSettings.globalize_path(SHEETS[id][1])
	var sheet := Image.load_from_file(sheet_path)
	source.convert(Image.FORMAT_RGBA8)
	sheet.convert(Image.FORMAT_RGBA8)
	var w := source.get_width()
	var h := source.get_height()
	var data := source.get_data()
	var alpha := PackedByteArray()
	alpha.resize(w * h)
	for i in w * h:
		alpha[i] = data[i * 4 + 3]
	var labels := PackedInt32Array()
	var groups := _label(alpha, w, h, labels)
	var bounds := _row_boundaries(alpha, w, h)
	var poses := _poses(groups, bounds, w, id.begins_with("rio"))
	# Sheet scale: current idle frames' height over the re-extracted idle poses' height.
	var ratios: Array[float] = []
	for column in COUNTS[0]:
		var pose: Array = poses[0][column]
		var current := _alpha_rect(_cell(sheet, 0, column))
		if not pose.is_empty() and current.size.y > 0:
			ratios.append(float(current.size.y) / float(_pose_rect(groups, pose).size.y))
	ratios.sort()
	var scale: float = ratios[ratios.size() / 2]
	var replaced: Array[String] = []
	var board_pairs: Array = []
	var rejected_pairs: Array = []
	for row in ROWS:
		for column in COUNTS[row]:
			var key := "%s:%d:%d" % [sheet_path.get_file(), row, column]
			if not flagged.has(key):
				continue
			var pose: Array = poses[row][column]
			if pose.is_empty():
				print("  %s r%dc%d (%s): poses touch in the source, kept" % [id, row, column, flagged[key]])
				continue
			var current := _cell(sheet, row, column)
			var placed: Image
			var added := 0
			var lost := 0
			var best_score := INF
			for factor: float in SCALE_FACTORS:
				var candidate := _place(_render_pose(source, labels, groups, pose, w, scale * factor), current)
				var counts := _difference(candidate, current)
				var score: float = counts.y + 0.1 * counts.x
				if score < best_score:
					best_score = score
					placed = candidate
					added = counts.x
					lost = counts.y
			if added < MIN_ADDED or lost > mini(MAX_LOST, maxi(MAX_LOST_FLOOR, roundi(added * MAX_LOST_SHARE))):
				print("  %s r%dc%d (%s): +%d -%d, re-extracted pose does not match, kept" % [id, row, column, flagged[key], added, lost])
				rejected_pairs.append([current, placed])
				continue
			replaced.append("r%dc%d(+%d -%d)" % [row, column, added, lost])
			board_pairs.append([current, placed])
			sheet.fill_rect(Rect2i(column * CELL, row * CELL, CELL, CELL), Color(0, 0, 0, 0))
			sheet.blit_rect(placed, Rect2i(0, 0, CELL, CELL), Vector2i(column * CELL, row * CELL))
	print("REEXTRACT %s scale=%.4f replaced=%d %s" % [id, scale, replaced.size(), " ".join(replaced)])
	if not dry and not replaced.is_empty():
		sheet.save_png(sheet_path)
	if board_dir != "" and not board_pairs.is_empty():
		_save_board(board_pairs, board_dir.path_join("%s_reextract.png" % id))
	if board_dir != "" and show_rejected and not rejected_pairs.is_empty():
		_save_board(rejected_pairs, board_dir.path_join("%s_rejected.png" % id))

func _read_flags(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var header := file.get_csv_line()
	var sheet_at := header.find("sheet")
	var row_at := header.find("row")
	var col_at := header.find("col")
	var flags_at := header.find("flags")
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() <= flags_at:
			continue
		var flags := line[flags_at]
		if flags.contains("box_") or flags.contains("cut"):
			flagged["%s:%s:%s" % [line[sheet_at].get_file(), line[row_at], line[col_at]]] = flags

## Connected groups of drawn pixels (8-neighbour); labels gets each pixel's group or -1.
func _label(alpha: PackedByteArray, w: int, h: int, labels: PackedInt32Array) -> Array:
	labels.resize(w * h)
	labels.fill(-1)
	var groups: Array = []
	var stack := PackedInt32Array()
	for start in w * h:
		if alpha[start] < ALPHA_CUT or labels[start] != -1:
			continue
		var group := Group.new()
		var group_id := groups.size()
		groups.append(group)
		labels[start] = group_id
		stack.clear()
		stack.append(start)
		while not stack.is_empty():
			var p := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			var x := p % w
			var y := p / w
			group.add(x, y)
			for offset: Vector2i in NEIGHBOURS:
				var nx := x + offset.x
				var ny := y + offset.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				var q := ny * w + nx
				if labels[q] == -1 and alpha[q] >= ALPHA_CUT:
					labels[q] = group_id
					stack.append(q)
	return groups

## Row split lines: the emptiest line near each expected split (as the v2 builder did).
func _row_boundaries(alpha: PackedByteArray, w: int, h: int) -> PackedInt32Array:
	var counts := PackedInt32Array()
	counts.resize(h)
	for y in h:
		var count := 0
		for x in w:
			if alpha[y * w + x] >= ALPHA_CUT:
				count += 1
		counts[y] = count
	var boundaries := PackedInt32Array([0])
	var radius := maxi(24, roundi(float(h) / 18.0))
	for split in range(1, ROWS):
		var expected := roundi(float(split) * h / ROWS)
		var best := expected
		for y in range(maxi(1, expected - radius), mini(h - 1, expected + radius + 1)):
			if counts[y] < counts[best] or (counts[y] == counts[best] and absi(y - expected) < absi(best - expected)):
				best = y
		boundaries.append(best)
	boundaries.append(h)
	return boundaries

## poses[row][column] = group ids of that pose (empty when it cannot be told apart).
## even_span: the source spreads a row's poses evenly over its drawn width (the Rio rework
## sources); otherwise poses sit in six equal columns.
func _poses(groups: Array, bounds: PackedInt32Array, w: int, even_span: bool) -> Array:
	var by_row: Array = []
	for row in ROWS:
		by_row.append([])
	for index in groups.size():
		var centre: Vector2 = groups[index].centre()
		for row in ROWS:
			if centre.y >= bounds[row] and centre.y < bounds[row + 1]:
				by_row[row].append(index)
				break
	var poses: Array = []
	for row in ROWS:
		var members: Array = by_row[row]
		var biggest := 0
		for index in members:
			biggest = maxi(biggest, groups[index].area)
		var big: Array = []
		var small: Array = []
		for index in members:
			if groups[index].area >= biggest * BIG_SHARE:
				big.append(index)
			else:
				small.append(index)
		# Clusters of big groups, merged across the smallest horizontal gap until the row's
		# frame count is left.
		big.sort_custom(func(a: int, b: int) -> bool: return groups[a].centre().x < groups[b].centre().x)
		var clusters: Array = []
		for index in big:
			clusters.append({"min_x": groups[index].min_x, "max_x": groups[index].max_x, "min_y": groups[index].min_y, "max_y": groups[index].max_y, "ids": [index], "sum_x": groups[index].sum_x, "area": groups[index].area})
		while clusters.size() > COUNTS[row]:
			var best := 0
			var best_gap := INF
			for i in clusters.size() - 1:
				var gap: float = clusters[i + 1].min_x - clusters[i].max_x
				if gap < best_gap:
					best_gap = gap
					best = i
			var a: Dictionary = clusters[best]
			var b: Dictionary = clusters[best + 1]
			a.min_x = mini(a.min_x, b.min_x)
			a.max_x = maxi(a.max_x, b.max_x)
			a.min_y = mini(a.min_y, b.min_y)
			a.max_y = maxi(a.max_y, b.max_y)
			a.ids.append_array(b.ids)
			a.sum_x += b.sum_x
			a.area += b.area
			clusters.remove_at(best + 1)
		clusters.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.min_x < b.min_x)
		for index in small:
			var centre: Vector2 = groups[index].centre()
			var nearest := -1
			var nearest_distance := STRAY_DISTANCE
			for i in clusters.size():
				var c: Dictionary = clusters[i]
				var dx := maxf(0.0, maxf(c.min_x - centre.x, centre.x - c.max_x))
				var dy := maxf(0.0, maxf(c.min_y - centre.y, centre.y - c.max_y))
				var distance := Vector2(dx, dy).length()
				if distance <= nearest_distance:
					nearest_distance = distance
					nearest = i
			if nearest >= 0:
				clusters[nearest].ids.append(index)
		var row_poses: Array = []
		for column in COUNTS[row]:
			row_poses.append([])
		if clusters.size() == COUNTS[row]:
			for column in COUNTS[row]:
				row_poses[column] = clusters[column].ids
		else:
			# Fewer clusters than frames: some poses touch in the source. Keep only clusters that
			# sit inside one frame slot; touching poses keep their current frames.
			var first := 1 << 30
			var last := -1
			for index in members:
				first = mini(first, groups[index].min_x)
				last = maxi(last, groups[index].max_x)
			var slot_width: float = float(last - first + 1) / COUNTS[row] if even_span else float(w) / COLS
			var origin: float = float(first) if even_span else 0.0
			var taken := {}
			for c: Dictionary in clusters:
				var slot := int(floor((c.sum_x / c.area - origin) / slot_width))
				if slot < 0 or slot >= COUNTS[row] or c.max_x - c.min_x + 1 > slot_width * 1.3:
					continue
				taken[slot] = [] if taken.has(slot) else c.ids
			for slot in taken:
				row_poses[slot] = taken[slot]
		poses.append(row_poses)
	return poses

func _pose_rect(groups: Array, pose: Array) -> Rect2i:
	var min_x := 1 << 30
	var min_y := 1 << 30
	var max_x := -1
	var max_y := -1
	for index in pose:
		min_x = mini(min_x, groups[index].min_x)
		min_y = mini(min_y, groups[index].min_y)
		max_x = maxi(max_x, groups[index].max_x)
		max_y = maxi(max_y, groups[index].max_y)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

## The pose alone (other poses' pixels masked out), scaled with nearest neighbour, alpha 0/1.
func _render_pose(source: Image, labels: PackedInt32Array, groups: Array, pose: Array, w: int, scale: float) -> Image:
	var rect := _pose_rect(groups, pose)
	var keep := {}
	for index in pose:
		keep[index] = true
	var image := Image.create_empty(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	for y in rect.size.y:
		for x in rect.size.x:
			var sx := rect.position.x + x
			var sy := rect.position.y + y
			if keep.has(labels[sy * w + sx]):
				var color := source.get_pixel(sx, sy)
				color.a = 1.0
				image.set_pixel(x, y, color)
	image.resize(maxi(1, roundi(rect.size.x * scale)), maxi(1, roundi(rect.size.y * scale)), Image.INTERPOLATE_NEAREST)
	return image

## Puts the pose in a 128 px cell where the current frame's body is: the column and row
## coverage of the two is matched (sum of absolute differences). A pose that fits is shifted
## inside the margin; one that does not keeps the matched place and is trimmed at the margin.
func _place(fresh: Image, current: Image) -> Image:
	var offset := Vector2i(_best_offset(_coverage(current, true), _coverage(fresh, true)), _best_offset(_coverage(current, false), _coverage(fresh, false)))
	if fresh.get_width() <= CELL - MARGIN * 2:
		offset.x = clampi(offset.x, MARGIN, CELL - MARGIN - fresh.get_width())
	if fresh.get_height() <= CELL - MARGIN * 2:
		offset.y = clampi(offset.y, MARGIN, CELL - MARGIN - fresh.get_height())
	var cell := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
	cell.blit_rect(fresh, Rect2i(Vector2i.ZERO, fresh.get_size()), offset)
	for y in CELL:
		for x in CELL:
			if x < MARGIN or y < MARGIN or x >= CELL - MARGIN or y >= CELL - MARGIN:
				cell.set_pixel(x, y, Color(0, 0, 0, 0))
	return cell

## (pixels only in a, pixels only in b) for two cells.
func _difference(a: Image, b: Image) -> Vector2i:
	var only_a := 0
	var only_b := 0
	for y in CELL:
		for x in CELL:
			var in_a := a.get_pixel(x, y).a > 0.5
			var in_b := b.get_pixel(x, y).a > 0.5
			if in_a and not in_b:
				only_a += 1
			elif in_b and not in_a:
				only_b += 1
	return Vector2i(only_a, only_b)

func _coverage(image: Image, columns: bool) -> PackedInt32Array:
	var size := image.get_width() if columns else image.get_height()
	var other := image.get_height() if columns else image.get_width()
	var result := PackedInt32Array()
	result.resize(size)
	for i in size:
		var count := 0
		for j in other:
			var a := image.get_pixel(i, j).a if columns else image.get_pixel(j, i).a
			if a > 0.5:
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
		for j in piece.size():
			var i := j + offset
			if i < 0 or i >= target.size():
				cost += piece[j]
		if cost < best_cost:
			best_cost = cost
			best = offset
	return best

func _cell(sheet: Image, row: int, column: int) -> Image:
	return sheet.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))

func _alpha_rect(image: Image) -> Rect2i:
	var rect := Rect2i()
	var found := false
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.5:
				rect = Rect2i(x, y, 1, 1) if not found else rect.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
				found = true
	return rect

## Current | re-extracted, each at 2x on a grey cell, one replaced frame per line.
func _save_board(pairs: Array, path: String) -> void:
	var zoom := 2
	var board := Image.create_empty(CELL * zoom * 2 + 24, (CELL * zoom + 8) * pairs.size() + 8, false, Image.FORMAT_RGBA8)
	board.fill(Color(0.1, 0.1, 0.12))
	for i in pairs.size():
		for side in 2:
			var cell: Image = pairs[i][side].duplicate()
			var back := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
			back.fill(Color(0.32, 0.34, 0.38))
			back.blend_rect(cell, Rect2i(0, 0, CELL, CELL), Vector2i.ZERO)
			back.resize(CELL * zoom, CELL * zoom, Image.INTERPOLATE_NEAREST)
			board.blit_rect(back, Rect2i(0, 0, CELL * zoom, CELL * zoom), Vector2i(8 + side * (CELL * zoom + 8), 8 + i * (CELL * zoom + 8)))
	board.save_png(path)
