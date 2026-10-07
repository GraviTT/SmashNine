extends SceneTree

const SPECS := [
	{"name": "mossling", "path": "res://assets/art/monsters/mossling_sheet.png", "cell": Vector2i(96, 96), "cols": 6, "rows": 4},
	{"name": "ember_imp", "path": "res://assets/art/monsters/ember_imp_sheet.png", "cell": Vector2i(96, 96), "cols": 6, "rows": 4},
	{"name": "fireball", "path": "res://assets/art/monsters/ember_fireball.png", "cell": Vector2i(36, 36), "cols": 1, "rows": 1},
	{"name": "soul_crystal", "path": "res://assets/art/objects/soul_crystal.png", "cell": Vector2i(72, 96), "cols": 4, "rows": 1},
	{"name": "soul_crystal_shatter", "path": "res://assets/art/objects/soul_crystal_shatter.png", "cell": Vector2i(72, 96), "cols": 4, "rows": 1},
]


func _init() -> void:
	var failures := 0
	for spec: Dictionary in SPECS:
		failures += _audit(spec)
	print("AUDIT_RESULT failures=%d" % failures)
	quit(0 if failures == 0 else 1)


func _audit(spec: Dictionary) -> int:
	var image := Image.load_from_file(spec.path)
	var expected := Vector2i(spec.cell.x * spec.cols, spec.cell.y * spec.rows)
	var failures := 0
	if image.get_size() != expected:
		push_error("%s size=%s expected=%s" % [spec.name, image.get_size(), expected])
		failures += 1
	for row in spec.rows:
		for col in spec.cols:
			var index: int = row * spec.cols + col
			var frame := image.get_region(Rect2i(col * spec.cell.x, row * spec.cell.y, spec.cell.x, spec.cell.y))
			var rect := frame.get_used_rect()
			if rect.size == Vector2i.ZERO:
				continue
			var margins := [rect.position.x, rect.position.y, spec.cell.x - rect.end.x, spec.cell.y - rect.end.y]
			var cut_edges := _cut_edges(frame)
			print("FRAME %s[%02d] bbox=%s margins=L%d,T%d,R%d,B%d cut_edges=%s" % [spec.name, index, rect, margins[0], margins[1], margins[2], margins[3], cut_edges])
			if margins.min() < 4:
				push_error("%s[%d] margin below 4: %s" % [spec.name, index, margins])
				failures += 1
			if not cut_edges.is_empty():
				push_error("%s[%d] cut edge: %s" % [spec.name, index, cut_edges])
				failures += 1
	return failures


func _cut_edges(frame: Image) -> Array[String]:
	var result: Array[String] = []
	var counts := [0, 0, 0, 0]
	for x in frame.get_width():
		if frame.get_pixel(x, 0).a > 0.5: counts[0] += 1
		if frame.get_pixel(x, frame.get_height() - 1).a > 0.5: counts[1] += 1
	for y in frame.get_height():
		if frame.get_pixel(0, y).a > 0.5: counts[2] += 1
		if frame.get_pixel(frame.get_width() - 1, y).a > 0.5: counts[3] += 1
	var names := ["top", "bottom", "left", "right"]
	for i in 4:
		if counts[i] >= 16:
			result.append("%s:%d" % [names[i], counts[i]])
	return result
