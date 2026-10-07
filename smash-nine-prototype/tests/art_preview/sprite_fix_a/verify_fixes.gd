extends SceneTree
## Independent verification for CODEX-ART-09 outputs.

const CELL := 128
const ROW_COUNTS := [4, 6, 1, 1, 4, 6, 1]
const REPORT := "res://../reports/codex-art-09/verification.txt"
const SPECS := [
	{"id": "frey", "path": "res://assets/art/frey/frey_sheet.png", "target": 100, "changed": [Vector2i(2, 4), Vector2i(3, 4)]},
	{"id": "yuki", "path": "res://assets/art/yuki/yuki_sheet.png", "target": 88, "changed": []},
	{"id": "luna", "path": "res://assets/art/luna/luna_sheet.png", "target": 84, "changed": [Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]},
	{"id": "luna_brave", "path": "res://assets/art/luna/luna_brave_sheet.png", "target": 84, "changed": [Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]},
	{"id": "nova_male", "path": "res://assets/art/nova/nova_male_sheet.png", "target": 92, "changed": [Vector2i(2, 4)]},
	{"id": "nova_female", "path": "res://assets/art/nova/nova_female_sheet.png", "target": 90, "changed": [Vector2i(2, 4), Vector2i(3, 4)]},
	{"id": "rio_male", "path": "res://assets/art/rio/rio_male_sheet.png", "target": 98, "changed": [Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5)]},
	{"id": "rio_female", "path": "res://assets/art/rio/rio_female_sheet.png", "target": 96, "changed": [Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5)]},
]


func _initialize() -> void:
	var failures: Array[String] = []
	var log := "CODEX-ART-09 verification\n"
	var total_used := 0
	var total_changed := 0
	var total_unused := 0
	for spec: Dictionary in SPECS:
		var current := Image.load_from_file(ProjectSettings.globalize_path(spec.path))
		var before_path := "res://../reports/codex-art-09/original_sheets/%s_sheet.png" % spec.id
		var before := Image.load_from_file(ProjectSettings.globalize_path(before_path))
		if current == null or before == null:
			failures.append("missing image for %s" % spec.id)
			continue
		current.convert(Image.FORMAT_RGBA8)
		before.convert(Image.FORMAT_RGBA8)
		if current.get_size() != Vector2i(768, 896):
			failures.append("%s size=%s" % [spec.id, current.get_size()])
		var changed_lookup: Dictionary = {}
		for coord: Vector2i in spec.changed:
			changed_lookup[coord] = true
		var idle_heights: Array[int] = []
		var center_min := INF
		var center_max := -INF
		for row in 7:
			for column in 6:
				var coord := Vector2i(column, row)
				var cell := current.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
				var old_cell := before.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
				var used: bool = column < ROW_COUNTS[row]
				var bounds := _bounds(cell)
				if not used:
					total_unused += 1
					if bounds.size != Vector2i.ZERO:
						failures.append("%s r%dc%d unused nontransparent" % [spec.id, row, column])
					continue
				total_used += 1
				if bounds.size == Vector2i.ZERO:
					failures.append("%s r%dc%d empty" % [spec.id, row, column])
					continue
				if bounds.position.x < 4 or bounds.position.y < 4 or bounds.end.x > 124 or bounds.end.y > 124:
					failures.append("%s r%dc%d margin=%s" % [spec.id, row, column, bounds])
				var center := _centroid_x(cell, bounds)
				center_min = minf(center_min, center)
				center_max = maxf(center_max, center)
				if changed_lookup.has(coord):
					total_changed += 1
					if cell.get_data() == old_cell.get_data():
						failures.append("%s r%dc%d fixed frame unchanged" % [spec.id, row, column])
					if bounds.end.y - 1 != 120:
						failures.append("%s r%dc%d fixed feet=%d" % [spec.id, row, column, bounds.end.y - 1])
				elif cell.get_data() != old_cell.get_data():
					failures.append("%s r%dc%d changed outside whitelist" % [spec.id, row, column])
				if row == 0:
					idle_heights.append(121 - bounds.position.y)
		for height: int in idle_heights:
			if absi(height - int(spec.target)) > 6:
				failures.append("%s idle height %d outside target %d +/−6" % [spec.id, height, spec.target])
		log += "%s used=23 changed=%d center=%.3f..%.3f idle=%s target=%d\n" % [spec.id, spec.changed.size(), center_min, center_max, str(idle_heights), spec.target]
	log += "totals used=%d unused=%d changed=%d outer4=0 unchanged_pixel_identical=true\n" % [total_used, total_unused, total_changed]
	if failures.is_empty() and total_used == 184 and total_unused == 152 and total_changed == 31:
		log += "RESULT PASS\n"
	else:
		log += "RESULT FAIL\n" + "\n".join(failures) + "\n"
	var file := FileAccess.open(ProjectSettings.globalize_path(REPORT), FileAccess.WRITE)
	if file != null:
		file.store_string(log)
		file.close()
	print(log)
	quit(0 if failures.is_empty() else 1)


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
	if right < left:
		return Rect2i()
	return Rect2i(left, top, right - left + 1, bottom - top + 1)


func _centroid_x(image: Image, bounds: Rect2i) -> float:
	var sum_x := 0.0
	var count := 0
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			if image.get_pixel(x, y).a >= 0.5:
				sum_x += x
				count += 1
	return sum_x / maxf(1.0, count)
