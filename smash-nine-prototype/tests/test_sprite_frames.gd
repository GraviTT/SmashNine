extends SceneTree
## Every frame of the eight v2 fighter sheets (routine 2026-10-08): used frames are drawn and keep
## the 4 px transparent margin, unused cells are empty, and no frame looks cut except the ones
## listed below. "Looks cut" is the lead audit's test (tests/analysis/lead/frame_audit.gd): a
## filled straight line on the left, right or top of the drawing's bounding box (16+ px), or a
## straight run of 9+ px along a cell border with nothing beyond it. A new art pass that cuts a
## frame fails here; a fix that uncuts a listed frame should drop it from the list.

const CELL := 128
const COUNTS := [4, 6, 1, 1, 4, 6, 1]
const MARGIN := 4
const EDGE_FILL := 16
const CUT_RUN := 9
const BORDER_BAND := 7
const SHEETS := [
	"res://assets/art/frey/frey_sheet.png", "res://assets/art/yuki/yuki_sheet.png",
	"res://assets/art/luna/luna_sheet.png", "res://assets/art/luna/luna_brave_sheet.png",
	"res://assets/art/nova/nova_male_sheet.png", "res://assets/art/nova/nova_female_sheet.png",
	"res://assets/art/rio/rio_male_sheet.png", "res://assets/art/rio/rio_female_sheet.png",
]
## Straight edges that are in the source art itself (re-extracting the pose whole from its
## source adds nothing): shield rims, aura rings, a slash tip, Luna's hair edge.
const SOURCE_EDGES := {
	"frey_sheet.png": ["r0c2", "r5c0", "r5c1", "r5c2", "r5c4"],
	"luna_sheet.png": ["r4c3"],
	"luna_brave_sheet.png": ["r4c3"],
	"nova_male_sheet.png": ["r5c1", "r5c2", "r5c3", "r5c4"],
	"nova_female_sheet.png": ["r2c0", "r5c0", "r5c2", "r5c3"],
	"rio_male_sheet.png": ["r4c1"],
}
## Still cut (none since CODEX-ART-12 round 2, 2026-10-08). A frame listed here may look cut.
const KNOWN_CUT := {}

var failures: Array[String] = []
var moves_sheet_count := 0
var monster_sheet_count := 0
var heads_file_count := 0

func _initialize() -> void:
	for path in SHEETS:
		_check_sheet(path)
		_check_zero_border_sheet(path, CELL, "fighter")
	_check_all_moves_sheets("res://assets/art")
	_check_all_monster_sheets("res://assets/art/monsters")
	_check_all_head_files("res://assets/art")
	if failures.is_empty():
		print("Sprite frame tests passed (8 main sheets, 184 frames, %d moves sheets, %d monster sheets edge-clean, %d head files valid)" % [moves_sheet_count, monster_sheet_count, heads_file_count])
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


## Rule 1 (D32): every sliced fighter, move and monster cell has zero opaque pixels on its
## one-pixel border. Move sheets may have character-specific row counts, but all use 128 px cells.
func _check_all_moves_sheets(directory: String) -> void:
	for file in DirAccess.get_files_at(directory):
		if file.ends_with("_moves_sheet.png"):
			_check_moves_sheet_edges(directory.path_join(file))
	for child in DirAccess.get_directories_at(directory):
		_check_all_moves_sheets(directory.path_join(child))


func _check_moves_sheet_edges(path: String) -> void:
	moves_sheet_count += 1
	_check_zero_border_sheet(path, CELL, "moves")


func _check_all_monster_sheets(directory: String) -> void:
	for file in DirAccess.get_files_at(directory):
		if file.ends_with("_sheet.png"):
			monster_sheet_count += 1
			_check_zero_border_sheet(directory.path_join(file), 96, "monster")
	for child in DirAccess.get_directories_at(directory):
		_check_all_monster_sheets(directory.path_join(child))


func _check_zero_border_sheet(path: String, cell_size: int, kind: String) -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(path))
	if sheet == null or sheet.is_empty():
		failures.append("%s: cannot load %s sheet" % [path, kind])
		return
	if sheet.get_width() % cell_size != 0 or sheet.get_height() % cell_size != 0:
		failures.append("%s: dimensions are not multiples of %d" % [path, cell_size])
		return
	for row in sheet.get_height() / cell_size:
		for column in sheet.get_width() / cell_size:
			var x0 := column * cell_size
			var y0 := row * cell_size
			var edge_counts := [0, 0, 0, 0]
			for index in cell_size:
				if sheet.get_pixel(x0, y0 + index).a >= 0.5: edge_counts[0] += 1
				if sheet.get_pixel(x0 + cell_size - 1, y0 + index).a >= 0.5: edge_counts[1] += 1
				if sheet.get_pixel(x0 + index, y0).a >= 0.5: edge_counts[2] += 1
				if sheet.get_pixel(x0 + index, y0 + cell_size - 1).a >= 0.5: edge_counts[3] += 1
			for edge in edge_counts.size():
				if edge_counts[edge] > 0:
					failures.append("%s r%dc%d: %d opaque pixels on 1 px border edge %d" % [path.get_file(), row, column, edge_counts[edge], edge])


func _check_all_head_files(directory: String) -> void:
	for file in DirAccess.get_files_at(directory):
		if file.ends_with("_heads.json"):
			heads_file_count += 1
			_check_head_file(directory.path_join(file))
	for child in DirAccess.get_directories_at(directory):
		_check_all_head_files(directory.path_join(child))


func _check_head_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("%s: cannot open head metadata" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("%s: invalid JSON object" % path)
		return
	var data: Dictionary = parsed
	var cell_size := int(data.get("cell_size", 0))
	var reference: Dictionary = data.get("reference", {})
	var reference_width := int(reference.get("w", 0))
	var reference_height := int(reference.get("h", 0))
	var rows: Dictionary = data.get("rows", {})
	if cell_size <= 0 or reference_width <= 0 or reference_height <= 0 or rows.is_empty():
		failures.append("%s: missing cell/reference/rows metadata" % path)
		return
	for row_name in rows:
		var entries: Array = rows[row_name]
		for entry in entries:
			if typeof(entry) != TYPE_DICTIONARY or not entry.has("head"):
				failures.append("%s %s: malformed head entry" % [path.get_file(), row_name])
				continue
			var head: Dictionary = entry.head
			var x := int(head.get("x", -1))
			var y := int(head.get("y", -1))
			var width := int(head.get("w", 0))
			var height := int(head.get("h", 0))
			if absi(width - reference_width) > 1 or absi(height - reference_height) > 1:
				failures.append("%s %s f%d: head %dx%d differs from reference %dx%d by more than 1 px" % [path.get_file(), row_name, int(entry.get("frame", 0)), width, height, reference_width, reference_height])
			if x < 0 or y < 0 or x + width > cell_size or y + height > cell_size:
				failures.append("%s %s f%d: head box (%d,%d,%d,%d) leaves %d px cell" % [path.get_file(), row_name, int(entry.get("frame", 0)), x, y, width, height, cell_size])

func _check_sheet(path: String) -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(path))
	var file := path.get_file()
	var allowed: Array = SOURCE_EDGES.get(file, []) + KNOWN_CUT.get(file, [])
	for row in COUNTS.size():
		for column in 6:
			var frame := sheet.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
			var name := "%s r%dc%d" % [file, row, column]
			var bounds := _bounds(frame)
			if column >= COUNTS[row]:
				if bounds.size != Vector2i.ZERO:
					failures.append("%s: unused cell is not empty" % name)
				continue
			if bounds.size == Vector2i.ZERO:
				failures.append("%s: used frame is empty" % name)
				continue
			var margin := mini(mini(bounds.position.x, bounds.position.y), mini(CELL - bounds.end.x, CELL - bounds.end.y))
			if margin < MARGIN:
				failures.append("%s: margin %d px (contract %d)" % [name, margin, MARGIN])
			var looks_cut := _longest_cut(frame) >= CUT_RUN \
				or _filled(frame, bounds.position.x, true) >= EDGE_FILL \
				or _filled(frame, bounds.end.x - 1, true) >= EDGE_FILL \
				or _filled(frame, bounds.position.y, false) >= EDGE_FILL
			var key := "r%dc%d" % [row, column]
			if looks_cut and not allowed.has(key):
				failures.append("%s looks cut (see tests/analysis/lead/frame_audit.gd)" % name)
			elif not looks_cut and KNOWN_CUT.get(file, []).has(key):
				print("%s no longer looks cut: drop it from KNOWN_CUT" % name)

func _bounds(frame: Image) -> Rect2i:
	var rect := Rect2i()
	for y in CELL:
		for x in CELL:
			if frame.get_pixel(x, y).a >= 0.5:
				rect = Rect2i(x, y, 1, 1) if rect.size == Vector2i.ZERO else rect.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
	return rect

## Opaque pixels on one column (vertical) or row of the frame.
func _filled(frame: Image, at: int, vertical: bool) -> int:
	var count := 0
	for i in CELL:
		var a := frame.get_pixel(at, i).a if vertical else frame.get_pixel(i, at).a
		if a >= 0.5:
			count += 1
	return count

## Longest run of opaque pixels along a line near a border whose outward neighbour is clear.
func _longest_cut(frame: Image) -> int:
	var best := 0
	for band in BORDER_BAND:
		for spec in [[band, -1, true], [CELL - 1 - band, 1, true], [band, -1, false], [CELL - 1 - band, 1, false]]:
			var at: int = spec[0]
			var outward: int = spec[1]
			var vertical: bool = spec[2]
			var run := 0
			for i in CELL:
				var p := Vector2i(at, i) if vertical else Vector2i(i, at)
				var o := p + (Vector2i(outward, 0) if vertical else Vector2i(0, outward))
				var outside_clear := o.x < 0 or o.y < 0 or o.x >= CELL or o.y >= CELL or frame.get_pixel(o.x, o.y).a < 0.5
				if frame.get_pixel(p.x, p.y).a >= 0.5 and outside_clear:
					run += 1
					best = maxi(best, run)
				else:
					run = 0
	return best
