extends SceneTree

const CELL := 128
const USED := [4, 6, 1, 1, 4, 6, 1]
const GROUND_ROWS := {0: true, 1: true, 4: true, 5: true, 6: true}
const SHEETS := {
	"frey": "res://assets/art/frey/frey_sheet.png",
	"luna": "res://assets/art/luna/luna_sheet.png",
	"luna_brave": "res://assets/art/luna/luna_brave_sheet.png",
}
const EXPECTED_CHANGED := {"frey": 2, "luna": 22, "luna_brave": 20}

var failures: Array[String] = []
var summary: Array[String] = []

func _initialize() -> void:
	var report := ProjectSettings.globalize_path("res://../reports/codex-art-21")
	for sheet_name in SHEETS:
		var current := Image.load_from_file(ProjectSettings.globalize_path(SHEETS[sheet_name]))
		var before := Image.load_from_file(report.path_join("contact/before/%s_sheet.png" % sheet_name))
		current.convert(Image.FORMAT_RGBA8)
		before.convert(Image.FORMAT_RGBA8)
		var changed := 0
		var unchanged_used := 0
		var partial := 0
		for row in 7:
			for column in 6:
				var rect := Rect2i(column * CELL, row * CELL, CELL, CELL)
				var frame := current.get_region(rect)
				var old := before.get_region(rect)
				var differs := frame.get_data() != old.get_data()
				if differs:
					changed += 1
				elif column < USED[row]:
					unchanged_used += 1
				if column >= USED[row]:
					if _nonzero(frame) != 0:
						failures.append("%s r%dc%d unused cell not transparent" % [sheet_name, row, column])
					continue
				partial += _partial_alpha(frame)
				if GROUND_ROWS.has(row) and _bottom(frame) != 120:
					failures.append("%s r%dc%d feet=%d" % [sheet_name, row, column, _bottom(frame)])
		if changed != EXPECTED_CHANGED[sheet_name]:
			failures.append("%s changed=%d expected=%d" % [sheet_name, changed, EXPECTED_CHANGED[sheet_name]])
		if partial != 0:
			failures.append("%s partial_alpha=%d" % [sheet_name, partial])
		summary.append("%s changed=%d unchanged_used=%d partial_alpha=%d grounded_feet=120 unused=transparent" % [sheet_name, changed, unchanged_used, partial])
	var file := FileAccess.open(report.path_join("verification.txt"), FileAccess.WRITE)
	file.store_string("\n".join(summary + failures) + "\n")
	for line in summary:
		print("ART21_VERIFY " + line)
	if failures.is_empty():
		print("ART21_VERIFY PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _nonzero(frame: Image) -> int:
	var count := 0
	for y in CELL:
		for x in CELL:
			if frame.get_pixel(x, y).a > 0.0:
				count += 1
	return count

func _partial_alpha(frame: Image) -> int:
	var count := 0
	for y in CELL:
		for x in CELL:
			var alpha := frame.get_pixel(x, y).a
			if alpha > 0.0 and alpha < 1.0:
				count += 1
	return count

func _bottom(frame: Image) -> int:
	var value := -1
	for y in CELL:
		for x in CELL:
			if frame.get_pixel(x, y).a >= 0.5:
				value = maxi(value, y)
	return value
