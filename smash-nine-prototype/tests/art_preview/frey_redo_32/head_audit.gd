extends SceneTree
## CODEX-ART-33 independent audit. Measures the drawn face from canonical skin/eye colours.
## It never reads frey_moves_heads.json and rejects the ART-32 exact idle-head stamp.

const Detector := preload("res://tests/art_preview/frey_heads_33/head_detector.gd")
const CELL := 128
const BASE := "res://assets/art/frey/frey_sheet.png"
const ART32 := "res://tests/art_preview/frey_heads_33/art32_pasted_body_sheet.png"
const AFTER := "res://assets/art/frey/frey_moves_body_sheet.png"
const OUTPUT := "res://tests/art_preview/frey_heads_33"
const REPORT := "res://../reports/codex-art-33/head_validation.txt"
const SOURCE_DIR := "res://tests/art_preview/frey_redo_32"
const TARGET_FINAL_HEAD_UNIT := 22.95
const ROWS := [
	["attack_up", 4], ["attack_down", 4], ["attack_air_side", 4], ["dash_strike", 4],
	["rising_cleave", 5], ["spike_followup", 4], ["descent", 6], ["tumble", 4],
]

var failures: Array[String] = []
var detector


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../reports/codex-art-33"))
	var base := Image.load_from_file(BASE)
	if base.is_empty():
		push_error("head_audit: base sheet missing")
		quit(1)
		return
	detector = Detector.new()
	detector.configure(base)
	var lines := PackedStringArray([
		"CODEX-ART-33 drawn-head audit",
		"metric=(output whole-drawing scale from alpha bounds) * (source-drawn eye-anchored face-colour region) / 22.95; JSON is not read",
		"synthetic metric=output alpha-bounds scale / idle alpha-bounds scale; eyes=canonical Frey eye colours inside measured head box",
		"",
		"synthetic_scale expected measured error verdict",
	])
	_validate_synthetic_scales(base, lines)
	_validate_double_head(base, lines)
	_validate_art32(lines)
	_validate_after(lines)
	lines.append("")
	lines.append("verdict=%s failures=%d" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
	for failure in failures:
		lines.append("FAIL: %s" % failure)
	var text := "\n".join(lines) + "\n"
	print(text)
	_write_text(REPORT, text)
	_write_text("%s/head_audit.txt" % OUTPUT, text)
	quit(0 if failures.is_empty() else 1)


func _validate_synthetic_scales(base: Image, lines: PackedStringArray) -> void:
	var idle := base.get_region(Rect2i(0, 0, CELL, CELL))
	var bounds := _alpha_bounds(idle)
	var crop := idle.get_region(bounds)
	for expected in [0.70, 0.85, 1.00, 1.20, 1.40]:
		var scaled := crop.duplicate()
		scaled.resize(roundi(crop.get_width() * expected), roundi(crop.get_height() * expected), Image.INTERPOLATE_NEAREST)
		var canvas_size := Vector2i(maxi(CELL, scaled.get_width() + 4), maxi(CELL, scaled.get_height() + 4))
		var frame := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
		frame.fill(Color.TRANSPARENT)
		frame.blit_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), (canvas_size - scaled.get_size()) / 2)
		var measured_bounds: Rect2i = detector.alpha_bounds(frame)
		var measured := sqrt(float(measured_bounds.size.x * measured_bounds.size.y) / float(bounds.size.x * bounds.size.y))
		var error: float = absf(measured - float(expected)) / float(expected)
		var check_passed: bool = error <= 0.03
		lines.append("%.2f %.4f %.2f%% %s" % [expected, measured, error * 100.0, "PASS" if check_passed else "FAIL"])
		if not check_passed:
			failures.append("synthetic %.2f measured %.4f (%.2f%% error)" % [expected, measured, error * 100.0])


func _validate_double_head(base: Image, lines: PackedStringArray) -> void:
	var idle := base.get_region(Rect2i(0, 0, CELL, CELL))
	var crop := idle.get_region(Detector.HEAD_BOX)
	var frame := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	frame.fill(Color.TRANSPARENT)
	frame.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i(12, 40))
	var mirrored := crop.duplicate()
	mirrored.flip_x()
	frame.blit_rect(mirrored, Rect2i(Vector2i.ZERO, mirrored.get_size()), Vector2i(82, 40))
	var result: Dictionary = detector.measure(frame, 0, false)
	var flagged := int(result.face_count) > 1 or int(result.eye_count) > 2
	lines.append("")
	lines.append("synthetic_double_head faces=%d eyes=%d flagged=%s" % [result.face_count, result.eye_count, flagged])
	if not flagged:
		failures.append("synthetic two-head frame was not flagged")


func _validate_art32(lines: PackedStringArray) -> void:
	var sheet := Image.load_from_file(ART32)
	if sheet.is_empty():
		lines.append("art32_pasted missing (validation deferred)")
		failures.append("ART-32 pasted-head fixture missing")
		return
	var flagged := 0
	var best_stamp := 0.0
	for row_index in ROWS.size():
		for frame_index in int(ROWS[row_index][1]):
			var frame := sheet.get_region(Rect2i(frame_index * CELL, row_index * CELL, CELL, CELL))
			var stamp := float(detector.stamp_score(frame, Rect2i(0, 0, CELL, CELL)))
			best_stamp = maxf(best_stamp, stamp)
			if stamp >= 0.96:
				flagged += 1
	lines.append("art32_pasted flagged=%d/35 best_stamp=%.4f verdict=%s" % [flagged, best_stamp, "PASS" if flagged > 0 else "FAIL"])
	if flagged == 0:
		failures.append("ART-32 pasted-head composite was not flagged")


func _validate_after(lines: PackedStringArray) -> void:
	var sheet := Image.load_from_file(AFTER)
	if sheet.is_empty():
		lines.append("after_sheet missing (validation deferred)")
		failures.append("after body sheet missing")
		return
	lines.append("")
	lines.append("row frame source_unit output_scale head_scale eyes stamp verdict")
	var passed := 0
	for row_index in ROWS.size():
		var row := String(ROWS[row_index][0])
		var source := Image.load_from_file("%s/%s_body_source.png" % [SOURCE_DIR, row])
		var poses := _body_pose_bounds(source, int(ROWS[row_index][1]))
		for frame_index in int(ROWS[row_index][1]):
			var frame := sheet.get_region(Rect2i(frame_index * CELL, row_index * CELL, CELL, CELL))
			var pose: Rect2i = poses[frame_index]
			var source_measure: Dictionary = detector.measure_source_drawing(source, pose, _expected_face(row, frame_index))
			var output_bounds: Rect2i = detector.alpha_bounds(frame)
			var output_scale := sqrt(float(output_bounds.size.x * output_bounds.size.y) / float(pose.size.x * pose.size.y))
			var head_scale := output_scale * float(source_measure.unit) / TARGET_FINAL_HEAD_UNIT
			var eye_rect: Rect2i = source_measure.eye
			var scale_xy := Vector2(float(output_bounds.size.x) / pose.size.x, float(output_bounds.size.y) / pose.size.y)
			var eye_center := Vector2(output_bounds.position) + Vector2(eye_rect.get_center() - pose.position) * scale_xy
			var offset := Vector2(Detector.HEAD_BOX.get_center() - Detector.EYE_ROI.get_center()) * head_scale
			var turns := frame_index if row == "tumble" else 0
			offset = _rotate_vector(offset, turns)
			var head_size := Vector2i(roundi(Detector.HEAD_BOX.size.x * head_scale), roundi(Detector.HEAD_BOX.size.y * head_scale))
			if turns % 2 == 1: head_size = Vector2i(head_size.y, head_size.x)
			var center := eye_center + offset
			var head := Rect2i(Vector2i(roundi(center.x - head_size.x * 0.5), roundi(center.y - head_size.y * 0.5)), head_size)
			var eyes := int(detector.count_eye_clusters(frame, head))
			var stamp := float(detector.stamp_score(frame, head))
			var check_passed := bool(source_measure.valid) and absf(head_scale - 1.0) <= 0.0501 and eyes <= 2 and stamp < 0.96
			lines.append("%s %d %.4f %.6f %.4f %d %.4f %s" % [row, frame_index + 1, source_measure.unit, output_scale, head_scale, eyes, stamp, "PASS" if check_passed else "FAIL"])
			if check_passed:
				passed += 1
			else:
				failures.append("%s frame %d invalid: scale=%.4f eyes=%d stamp=%.4f" % [row, frame_index + 1, head_scale, eyes, stamp])
	lines.append("after_frames_passed=%d/35" % passed)


func _expected_face(row: String, frame_index: int) -> Vector2:
	if row == "attack_up" and frame_index == 2:
		return Vector2(0.50, 0.43)
	if row == "tumble":
		return [Vector2(0.72, 0.34), Vector2(0.20, 0.38), Vector2(0.55, 0.78), Vector2(0.76, 0.34)][frame_index]
	return Vector2(0.68, 0.36)


func _rotate_vector(value: Vector2, turns: int) -> Vector2:
	match posmod(turns, 4):
		1: return Vector2(-value.y, value.x)
		2: return -value
		3: return Vector2(value.y, -value.x)
	return value


func _body_pose_bounds(image: Image, expected: int) -> Array[Rect2i]:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var components: Array[Dictionary] = []
	for start_y in height:
		for start_x in width:
			var start := start_y * width + start_x
			if visited[start] != 0 or image.get_pixel(start_x, start_y).a < 0.5: continue
			var stack: Array[Vector2i] = [Vector2i(start_x, start_y)]
			visited[start] = 1
			var area := 0
			var bounds := Rect2i()
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				area += 1
				bounds = Rect2i(point, Vector2i.ONE) if bounds.size == Vector2i.ZERO else bounds.expand(point).expand(point + Vector2i.ONE)
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						if ox == 0 and oy == 0: continue
						var next := point + Vector2i(ox, oy)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height: continue
						var ni := next.y * width + next.x
						if visited[ni] == 0 and image.get_pixelv(next).a >= 0.5:
							visited[ni] = 1
							stack.append(next)
			if area >= 1000: components.append({"area": area, "bounds": bounds})
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.area) > int(b.area))
	if components.size() > expected: components.resize(expected)
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int((a.bounds as Rect2i).position.x) < int((b.bounds as Rect2i).position.x))
	var result: Array[Rect2i] = []
	for component in components: result.append(component.bounds)
	return result


func _alpha_bounds(image: Image) -> Rect2i:
	var result := Rect2i()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.5:
				result = Rect2i(x, y, 1, 1) if result.size == Vector2i.ZERO else result.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
	return result


func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("cannot write %s" % path)
		return
	file.store_string(content)
	file.close()
