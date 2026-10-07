extends SceneTree

const CELL := 128
const FIXED := {Vector2i(1, 5): true, Vector2i(2, 5): true, Vector2i(3, 5): true, Vector2i(4, 5): true}
const SPECS := [
	["rio_female", "res://assets/art/rio/rio_female_sheet.png"],
	["frey", "res://assets/art/frey/frey_sheet.png"],
	["nova_female", "res://assets/art/nova/nova_female_sheet.png"],
]

func _initialize() -> void:
	var failures: Array[String] = []
	var changed := 0
	var unchanged := 0
	var changed_pixels := 0
	for spec: Array in SPECS:
		var id: String = spec[0]
		var current := Image.load_from_file(ProjectSettings.globalize_path(spec[1]))
		var baseline := Image.load_from_file(ProjectSettings.globalize_path("res://tests/art_preview/sprite_fix_a2/baseline/%s_sheet.png" % id))
		current.convert(Image.FORMAT_RGBA8)
		baseline.convert(Image.FORMAT_RGBA8)
		for row in 7:
			for column in 6:
				var coord := Vector2i(column, row)
				var a := baseline.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
				var b := current.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
				var should_change := id == "rio_female" and FIXED.has(coord)
				if a.get_data() == b.get_data():
					unchanged += 1
					if should_change:
						failures.append("%s r%dc%d unchanged" % [id, row, column])
				else:
					changed += 1
					if not should_change:
						failures.append("%s r%dc%d changed outside whitelist" % [id, row, column])
					changed_pixels += _pixel_diff(a, b)
					var bounds := _bounds(b)
					if bounds.position.x < 4 or bounds.position.y < 4 or bounds.end.x > 124 or bounds.end.y > 124:
						failures.append("%s r%dc%d margin=%s" % [id, row, column, bounds])
					if not _binary_alpha(b):
						failures.append("%s r%dc%d non-binary alpha" % [id, row, column])
	_save_row_board()
	var result := "PASS" if failures.is_empty() and changed == 4 else "FAIL"
	var log := "VERIFY %s changed_frames=%d unchanged_cells=%d changed_pixels=%d\n" % [result, changed, unchanged, changed_pixels]
	if not failures.is_empty():
		log += "\n".join(failures) + "\n"
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../reports/codex-art-12/verification.txt"), FileAccess.WRITE)
	file.store_string(log)
	file.close()
	print(log)
	quit(0 if result == "PASS" else 1)

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

func _bounds(image: Image) -> Rect2i:
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

func _save_row_board() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path("res://assets/art/rio/rio_female_sheet.png"))
	var row := sheet.get_region(Rect2i(0, 5 * CELL, 6 * CELL, CELL))
	var back := Image.create_empty(6 * CELL, CELL, false, Image.FORMAT_RGBA8)
	back.fill(Color("4b5261"))
	back.blend_rect(row, Rect2i(Vector2i.ZERO, row.get_size()), Vector2i.ZERO)
	back.resize(12 * CELL, 2 * CELL, Image.INTERPOLATE_NEAREST)
	back.save_png(ProjectSettings.globalize_path("res://../reports/codex-art-12/rio_female_shield_row_after_2x.png"))
