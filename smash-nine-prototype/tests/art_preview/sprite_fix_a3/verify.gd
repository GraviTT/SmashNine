extends SceneTree

const CELL := 128
const REPORT := "res://../reports/codex-art-12/round2"
const TARGETS := {
	"rio_female": {Vector2i(0, 4): true, Vector2i(1, 4): true, Vector2i(2, 4): true, Vector2i(3, 4): true},
	"frey": {Vector2i(2, 4): true, Vector2i(3, 4): true},
	"luna": {Vector2i(3, 4): true},
	"nova_female": {Vector2i(1, 4): true, Vector2i(2, 4): true},
}
const SHEETS := {
	"rio_female": "res://assets/art/rio/rio_female_sheet.png",
	"frey": "res://assets/art/frey/frey_sheet.png",
	"luna": "res://assets/art/luna/luna_sheet.png",
	"nova_female": "res://assets/art/nova/nova_female_sheet.png",
}

func _initialize() -> void:
	var failures: Array[String] = []
	var changed_targets := 0
	var unchanged_cells := 0
	var changed_pixels := 0
	var lines: PackedStringArray = PackedStringArray(["sheet,frame,changed_pixels,added_opaque,removed_opaque,existing_rgb_preserved,bounds,binary_alpha,margin,feet_y"])
	for id: String in SHEETS:
		var current := Image.load_from_file(ProjectSettings.globalize_path(SHEETS[id]))
		var baseline := Image.load_from_file(ProjectSettings.globalize_path("res://tests/art_preview/sprite_fix_a3/baseline/%s_sheet.png" % id))
		current.convert(Image.FORMAT_RGBA8)
		baseline.convert(Image.FORMAT_RGBA8)
		for row in 7:
			for column in 6:
				var coord := Vector2i(column, row)
				var before := baseline.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
				var after := current.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
				var diff := _pixel_diff(before, after)
				var targeted: bool = TARGETS[id].has(coord)
				if targeted:
					if diff == 0:
						failures.append("%s r%dc%d target unchanged" % [id, row, column])
					else:
						changed_targets += 1
						changed_pixels += diff
					var bounds := _alpha_bounds(after)
					var binary := _binary_alpha(after)
					var alpha_delta := _alpha_delta(before, after)
					var preserved := _existing_opaque_preserved(before, after)
					var margin := mini(mini(bounds.position.x, bounds.position.y), mini(CELL - bounds.end.x, CELL - bounds.end.y))
					var feet := bounds.end.y - 1
					lines.append("%s,r%dc%d,%d,%d,%d,%s,%s,%s,%d,%d" % [id, row, column, diff, alpha_delta.x, alpha_delta.y, str(preserved), bounds, str(binary), margin, feet])
					if not binary:
						failures.append("%s r%dc%d non-binary alpha" % [id, row, column])
					if margin < 4:
						failures.append("%s r%dc%d margin=%d" % [id, row, column, margin])
					if feet != 120:
						failures.append("%s r%dc%d feet_y=%d" % [id, row, column, feet])
					if alpha_delta.y != 0 or not preserved:
						failures.append("%s r%dc%d existing opaque art changed" % [id, row, column])
				elif diff != 0:
					failures.append("%s r%dc%d changed outside whitelist (%d px)" % [id, row, column, diff])
				else:
					unchanged_cells += 1
	var passed := failures.is_empty() and changed_targets == 9 and unchanged_cells == 159
	var summary := "VERIFY %s changed_targets=%d unchanged_non_targets=%d changed_pixels=%d\n" % ["PASS" if passed else "FAIL", changed_targets, unchanged_cells, changed_pixels]
	if not failures.is_empty():
		summary += "\n".join(failures) + "\n"
	var file := FileAccess.open(ProjectSettings.globalize_path(REPORT + "/verification.txt"), FileAccess.WRITE)
	file.store_string(summary)
	file.close()
	var csv := FileAccess.open(ProjectSettings.globalize_path(REPORT + "/target_measurements.csv"), FileAccess.WRITE)
	csv.store_string("\n".join(lines) + "\n")
	csv.close()
	print(summary)
	quit(0 if passed else 1)

func _pixel_diff(a: Image, b: Image) -> int:
	var count := 0
	for y in CELL:
		for x in CELL:
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				count += 1
	return count

func _binary_alpha(image: Image) -> bool:
	for y in CELL:
		for x in CELL:
			var alpha := image.get_pixel(x, y).a8
			if alpha != 0 and alpha != 255:
				return false
	return true

func _alpha_delta(before: Image, after: Image) -> Vector2i:
	var added := 0
	var removed := 0
	for y in CELL:
		for x in CELL:
			var a := before.get_pixel(x, y).a >= 0.5
			var b := after.get_pixel(x, y).a >= 0.5
			if b and not a:
				added += 1
			elif a and not b:
				removed += 1
	return Vector2i(added, removed)

func _existing_opaque_preserved(before: Image, after: Image) -> bool:
	for y in CELL:
		for x in CELL:
			var old := before.get_pixel(x, y)
			if old.a < 0.5:
				continue
			var new := after.get_pixel(x, y)
			if new.a < 0.5 or old.r8 != new.r8 or old.g8 != new.g8 or old.b8 != new.b8:
				return false
	return true

func _alpha_bounds(image: Image) -> Rect2i:
	var left := CELL
	var top := CELL
	var right := -1
	var bottom := -1
	for y in CELL:
		for x in CELL:
			if image.get_pixel(x, y).a < 0.5:
				continue
			left = mini(left, x)
			top = mini(top, y)
			right = maxi(right, x)
			bottom = maxi(bottom, y)
	return Rect2i() if right < left else Rect2i(left, top, right - left + 1, bottom - top + 1)
