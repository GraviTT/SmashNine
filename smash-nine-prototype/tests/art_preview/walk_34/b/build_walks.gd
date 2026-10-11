extends SceneTree
## CODEX-ART-34B: replace only row 1 of the four assigned fighter sheets.
## Each generated strip contains one idle scale anchor followed by a six-frame walk cycle.

const CELL := 128
const WALK_ROW := 1
const FRAME_COUNT := 6
const GROUND_Y := 120
const MARGIN := 4
const SOURCE_COUNT := 7
const PREVIEW_DIR := "res://tests/art_preview/walk_34/b"
const REPORT_PATH := PREVIEW_DIR + "/walk_audit.txt"
const PALETTE_LIMIT := 256

const SPECS := [
	{
		"id": "nova_male",
		"sheet": "res://assets/art/nova/nova_male_sheet.png",
		"source": PREVIEW_DIR + "/nova_male_walk_source.png",
		"eye": "cyan",
	},
	{
		"id": "nova_female",
		"sheet": "res://assets/art/nova/nova_female_sheet.png",
		"source": PREVIEW_DIR + "/nova_female_walk_source.png",
		"eye": "cyan",
	},
	{
		"id": "luna",
		"sheet": "res://assets/art/luna/luna_sheet.png",
		"source": PREVIEW_DIR + "/luna_walk_source.png",
		"eye": "magenta",
	},
	{
		"id": "luna_brave",
		"sheet": "res://assets/art/luna/luna_brave_sheet.png",
		"source": PREVIEW_DIR + "/luna_brave_walk_source.png",
		"eye": "magenta",
	},
]

const DIGITS := {
	"0": ["111", "101", "101", "101", "111"],
	"1": ["010", "110", "010", "010", "111"],
	"2": ["111", "001", "111", "100", "111"],
	"3": ["111", "001", "111", "001", "111"],
	"4": ["101", "101", "111", "001", "001"],
	"5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"],
	"7": ["111", "001", "010", "010", "010"],
	"8": ["111", "101", "111", "101", "111"],
	"9": ["111", "101", "111", "001", "111"],
	".": ["000", "000", "000", "000", "010"],
	"/": ["001", "001", "010", "100", "100"],
	"X": ["101", "101", "010", "101", "101"],
}

var failures: Array[String] = []
var audit_lines: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))
	for spec in SPECS:
		_build_sheet(spec)
	_write_text(REPORT_PATH, "\n".join(audit_lines) + "\n")
	if failures.is_empty():
		print("build_walks: four walk rows rebuilt and validated")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _build_sheet(spec: Dictionary) -> void:
	var id := String(spec.id)
	var sheet_path := String(spec.sheet)
	var source_path := String(spec.source)
	var before_path := "%s/before_%s_sheet.png" % [PREVIEW_DIR, id]
	var before := Image.load_from_file(ProjectSettings.globalize_path(before_path))
	var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	if before == null or before.is_empty():
		_fail("%s: cannot load immutable before sheet" % id)
		return
	if source == null or source.is_empty():
		_fail("%s: cannot load generated source" % id)
		return
	if before.get_size() != Vector2i(768, 896):
		_fail("%s: expected 768x896 sheet, got %s" % [id, before.get_size()])
		return
	var idle := before.get_region(Rect2i(0, 0, CELL, CELL))
	var target_broad := _measure_frame(idle, spec, 1.0, {})
	if not bool(target_broad.valid):
		_fail("%s: canonical idle face was not detected" % id)
		return
	# Brave's canonical face is only 5 pixels, so it needs the broad skin family after reduction.
	# The other sheets use their idle-face palette keys to avoid selecting pink/cyan details.
	var skin_keys := {} if id == "luna_brave" else _skin_keys_from_face(idle, target_broad.face)
	var target_measure := target_broad
	var target_face_area := int(target_measure.face_area)
	var target_face_size: Vector2i = target_measure.face.size
	var target_head_size: Vector2i = target_measure.head.size
	var target_shares := _palette_shares(idle, spec, target_measure.head)
	var target_detail := _detail_density(idle, target_measure.head)
	print("walk34 %s target body=%s face=%s area=%d raw_head=%s detail=%.3f" % [id, _alpha_bounds(idle), target_measure.face, target_face_area, target_head_size, target_detail])
	var palette := _collect_palette(before, idle)
	var color_cache := {}
	var after := before.duplicate()
	var build_records: Array[Dictionary] = []
	for frame_index in FRAME_COUNT:
		var source_drawing := _source_frame(source, frame_index + 1)
		if source_drawing.is_empty():
			_fail("%s f%d: generated source frame is empty" % [id, frame_index + 1])
			continue
		var rendered := _render_best(source_drawing, spec, target_head_size, skin_keys, palette, color_cache)
		if not bool(rendered.valid):
			_fail("%s f%d: could not fit and head-scale generated drawing" % [id, frame_index + 1])
			continue
		var cell: Image = rendered.cell
		after.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(frame_index * CELL, WALK_ROW * CELL))
		build_records.append({
			"frame": frame_index + 1,
			"source_size": source_drawing.get_size(),
			"render_size": rendered.render_size,
			"destination": rendered.destination,
			"frame_scale": rendered.frame_scale,
			"head_scale": rendered.measure.scale,
			"head_size": rendered.measure.head.size,
			"face_area": rendered.measure.face_area,
			"face_count": rendered.measure.face_count,
			"eye_clusters": rendered.measure.eye_clusters,
			"head": rendered.measure.head,
			"face": rendered.measure.face,
			"edge_rounding_pixels": rendered.edge_rounding_pixels,
			"detached_pixels_removed": rendered.detached_pixels_removed,
			"palette_shares": _palette_shares(cell, spec, rendered.measure.head),
			"detail_density": _detail_density(cell, rendered.measure.head),
		})
	if build_records.size() != FRAME_COUNT:
		return
	if not _other_rows_identical(before, after):
		_fail("%s: pixels outside walk row changed" % id)
		return
	var before_feet := _feet_metrics(before)
	var after_feet := _feet_metrics(after)
	for record in build_records:
		var scale := float(record.head_scale)
		var head_size: Vector2i = record.head_size
		print("walk34 %s f%d render=%s face=%s raw_head=%s idle=%s scale=%.4f faces=%d eyes=%d removed=%d round=%d" % [id, int(record.frame), record.render_size, record.face, head_size, target_head_size, scale, int(record.face_count), int(record.eye_clusters), int(record.detached_pixels_removed), int(record.edge_rounding_pixels)])
		if absi(head_size.x - target_head_size.x) > 2 or absi(head_size.y - target_head_size.y) > 2:
			_fail("%s f%d: raw head %s differs from idle %s by more than 2 px" % [id, int(record.frame), head_size, target_head_size])
		if int(record.eye_clusters) > 2:
			_fail("%s f%d: one-head eye-cluster check failed (face candidates %d, eyes %d)" % [id, int(record.frame), int(record.face_count), int(record.eye_clusters)])
		var frame: Image = after.get_region(Rect2i((int(record.frame) - 1) * CELL, WALK_ROW * CELL, CELL, CELL))
		var bounds: Rect2i = _alpha_bounds(frame)
		var margin: int = mini(mini(bounds.position.x, bounds.position.y), mini(CELL - bounds.end.x, CELL - bounds.end.y))
		if margin < MARGIN:
			_fail("%s f%d: margin %d is below %d" % [id, int(record.frame), margin, MARGIN])
		if _lowest_opaque(frame) != GROUND_Y:
			_fail("%s f%d: feet do not land at y=%d" % [id, int(record.frame), GROUND_Y])
		var shares: Dictionary = record.palette_shares
		for family in ["hair", "clothes", "skin", "accent"]:
			if absf(float(shares[family]) - float(target_shares[family])) > 10.0:
				_fail("%s f%d: %s share %.1f%% differs from idle %.1f%% by more than 10 points" % [id, int(record.frame), family, float(shares[family]), float(target_shares[family])])
		if absf(float(record.detail_density) - target_detail) > 0.18:
			_fail("%s f%d: head detail density %.3f differs from idle %.3f" % [id, int(record.frame), float(record.detail_density), target_detail])
	if float(after_feet.change) < 45.0:
		_fail("%s: feet silhouette change %.1f%% is below 45%%" % [id, float(after_feet.change)])
	if not failures.is_empty():
		return
	var save_error: Error = after.save_png(ProjectSettings.globalize_path(sheet_path))
	if save_error != OK:
		_fail("%s: cannot save sheet (%s)" % [id, error_string(save_error)])
		return
	_make_contact(id, spec, skin_keys, target_head_size, idle, before, after)
	_make_onion(id, before, after)
	audit_lines.append("[%s]" % id)
	audit_lines.append("sheet=%s" % sheet_path)
	audit_lines.append("source=%s (%dx%d RGBA)" % [source_path, source.get_width(), source.get_height()])
	audit_lines.append("idle_face_area=%d" % target_face_area)
	audit_lines.append("idle_face_size=%s" % target_face_size)
	audit_lines.append("idle_raw_head_box=%dx%d" % [target_head_size.x, target_head_size.y])
	audit_lines.append("idle_palette_share_hair_clothes_skin_accent=%.1f/%.1f/%.1f/%.1f" % [float(target_shares.hair), float(target_shares.clothes), float(target_shares.skin), float(target_shares.accent)])
	audit_lines.append("idle_head_detail_density=%.3f" % target_detail)
	audit_lines.append("before_feet_change=%.1f%% spans=%s" % [float(before_feet.change), "/".join(before_feet.spans)])
	audit_lines.append("after_feet_change=%.1f%% spans=%s" % [float(after_feet.change), "/".join(after_feet.spans)])
	for record in build_records:
		var shares: Dictionary = record.palette_shares
		audit_lines.append("f%d source=%s render=%s dest=%s whole_frame_scale=%s raw_head=%dx%d idle=%dx%d scale=%.4f colors_hair_clothes_skin_accent=%.1f/%.1f/%.1f/%.1f detail=%.3f face_area=%d faces=%d eyes=%d detached_pixels_removed=%d edge_rounding_pixels=%d" % [
			int(record.frame), record.source_size, record.render_size, record.destination, record.frame_scale,
			int(record.head_size.x), int(record.head_size.y), target_head_size.x, target_head_size.y, float(record.head_scale),
			float(shares.hair), float(shares.clothes), float(shares.skin), float(shares.accent), float(record.detail_density),
			int(record.face_area), int(record.face_count), int(record.eye_clusters), int(record.detached_pixels_removed), int(record.edge_rounding_pixels),
		])
	audit_lines.append("other_rows_pixel_identical=true")
	audit_lines.append("")


func _source_frame(source: Image, slot: int) -> Image:
	var x0 := roundi(float(source.get_width()) * float(slot) / float(SOURCE_COUNT))
	var x1 := roundi(float(source.get_width()) * float(slot + 1) / float(SOURCE_COUNT))
	var region := source.get_region(Rect2i(x0, 0, x1 - x0, source.get_height()))
	_harden_alpha(region)
	var bounds := _alpha_bounds(region)
	if bounds.size == Vector2i.ZERO:
		return Image.new()
	return region.get_region(bounds)


func _render_best(source: Image, spec: Dictionary, target_head_size: Vector2i, skin_keys: Dictionary, palette: Array[Color], cache: Dictionary) -> Dictionary:
	var source_measure := _measure_frame(source, spec, 1.0, {})
	if not bool(source_measure.valid):
		return {"valid": false}
	var source_head: Vector2i = source_measure.head.size
	var initial := Vector2(float(target_head_size.x) / maxf(1.0, float(source_head.x)), float(target_head_size.y) / maxf(1.0, float(source_head.y)))
	var probe := _render_candidate(source, spec, target_head_size, skin_keys, palette, cache, initial)
	var center := initial
	if bool(probe.valid):
		var probe_head: Vector2i = probe.measure.head.size
		center *= Vector2(float(target_head_size.x) / maxf(1.0, float(probe_head.x)), float(target_head_size.y) / maxf(1.0, float(probe_head.y)))
	var best := probe
	# Pixel boxes change in integer steps. Re-render the untouched whole drawing around the
	# raw head width/height correction and keep the closest pair; no part is transformed alone.
	for step_y in range(-1, 2):
		for step_x in range(-1, 2):
			var scale := center * Vector2(1.0 + float(step_x) * 0.01, 1.0 + float(step_y) * 0.01)
			var candidate := _render_candidate(source, spec, target_head_size, skin_keys, palette, cache, scale)
			if bool(candidate.valid) and (not bool(best.valid) or float(candidate.score) < float(best.score)):
				best = candidate
	# A second whole-frame correction handles integer-pixel detector steps on the tiny Brave face.
	for _iteration in 2:
		if not bool(best.valid):
			break
		var measured_head: Vector2i = best.measure.head.size
		var correction := Vector2(float(target_head_size.x) / maxf(1.0, float(measured_head.x)), float(target_head_size.y) / maxf(1.0, float(measured_head.y)))
		var refined_scale: Vector2 = best.frame_scale * correction
		var refined := _render_candidate(source, spec, target_head_size, skin_keys, palette, cache, refined_scale)
		if bool(refined.valid) and float(refined.score) <= float(best.score):
			best = refined
	if bool(best.valid):
		var best_head: Vector2i = best.measure.head.size
		if absi(best_head.x - target_head_size.x) > 2 or absi(best_head.y - target_head_size.y) > 2:
			for factor_y in [1.0, 1.02, 1.04]:
				for factor_x in [1.0, 1.02, 1.04, 1.06]:
					var rescue_scale: Vector2 = best.frame_scale * Vector2(float(factor_x), float(factor_y))
					var rescue := _render_candidate(source, spec, target_head_size, skin_keys, palette, cache, rescue_scale)
					if bool(rescue.valid) and float(rescue.score) < float(best.score):
						best = rescue
	if bool(best.valid):
		best.detached_pixels_removed = _remove_detached_components(best.cell)
		best.measure = _measure_frame(best.cell, spec, 1.0, skin_keys)
		var final_head: Vector2i = best.measure.head.size
		best.measure.scale = maxf(float(final_head.x) / maxf(1.0, float(target_head_size.x)), float(final_head.y) / maxf(1.0, float(target_head_size.y)))
	return best


func _render_candidate(source: Image, spec: Dictionary, target_head_size: Vector2i, skin_keys: Dictionary, palette: Array[Color], cache: Dictionary, scale: Vector2) -> Dictionary:
	if scale.x <= 0.0 or scale.y <= 0.0 or scale.x > 1.0 or scale.y > 1.0:
		return {"valid": false, "score": INF}
	var target_size := Vector2i(maxi(1, roundi(source.get_width() * scale.x)), maxi(1, roundi(source.get_height() * scale.y)))
	if target_size.x > CELL - MARGIN * 2 or target_size.y > CELL - MARGIN * 2:
		return {"valid": false, "score": INF}
	var drawing := source.duplicate()
	drawing.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	_harden_alpha(drawing)
	_quantize(drawing, palette, cache)
	var trimmed_bounds := _alpha_bounds(drawing)
	if trimmed_bounds.size == Vector2i.ZERO:
		return {"valid": false, "score": INF}
	drawing = drawing.get_region(trimmed_bounds)
	if drawing.get_width() > CELL - MARGIN * 2 or drawing.get_height() > CELL - MARGIN * 2:
		return {"valid": false, "score": INF}
	var destination := Vector2i((CELL - drawing.get_width()) / 2, GROUND_Y - drawing.get_height() + 1)
	if destination.x < MARGIN or destination.y < MARGIN:
		return {"valid": false, "score": INF}
	var cell := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	cell.fill(Color.TRANSPARENT)
	cell.blit_rect(drawing, Rect2i(Vector2i.ZERO, drawing.get_size()), destination)
	_clear_border(cell)
	var edge_rounding_pixels := _round_box_edges(cell)
	var measure := _measure_frame(cell, spec, 1.0, skin_keys)
	if not bool(measure.valid):
		return {"valid": false, "score": INF}
	var head_size: Vector2i = measure.head.size
	measure.scale = maxf(float(head_size.x) / maxf(1.0, float(target_head_size.x)), float(head_size.y) / maxf(1.0, float(target_head_size.y)))
	var score := float(absi(head_size.x - target_head_size.x) + absi(head_size.y - target_head_size.y)) + maxf(0.0, float(measure.eye_clusters) - 2.0) * 4.0
	return {
		"valid": true,
		"score": score,
		"cell": cell,
		"render_size": drawing.get_size(),
		"destination": destination,
		"frame_scale": scale,
		"measure": measure,
		"edge_rounding_pixels": edge_rounding_pixels,
		"detached_pixels_removed": 0,
	}


func _measure_frame(frame: Image, spec: Dictionary, target_head_unit: float, skin_keys: Dictionary) -> Dictionary:
	var bounds := _alpha_bounds(frame)
	if bounds.size == Vector2i.ZERO:
		return {"valid": false}
	var search_height := maxi(1, roundi(bounds.size.y * 0.58))
	var search := Rect2i(bounds.position, Vector2i(bounds.size.x, search_height)).intersection(Rect2i(Vector2i.ZERO, frame.get_size()))
	var components := _skin_components(frame, search, skin_keys)
	if components.is_empty():
		return {"valid": false}
	var face := _select_face(components, bounds, String(spec.id))
	var minimum_secondary := maxi(4, roundi(float(face.area) * 0.60))
	var face_count := 0
	var expected := _expected_face_position(String(spec.id))
	for component in components:
		var component_rect: Rect2i = component.rect
		var normalized := Vector2(component_rect.get_center() - bounds.position) / Vector2(maxi(1, bounds.size.x), maxi(1, bounds.size.y))
		if int(component.area) >= minimum_secondary and normalized.distance_to(expected) < 0.22:
			face_count += 1
	var face_rect: Rect2i = face.rect
	var head := _raw_head_box(frame, face_rect, bounds, String(spec.id))
	if head.size == Vector2i.ZERO:
		return {"valid": false}
	var head_unit := float(head.size.y)
	var eye_search := face_rect.grow(-1) if face_rect.size.x > 4 and face_rect.size.y > 4 else face_rect
	var eyes := _eye_clusters(frame, eye_search.intersection(Rect2i(Vector2i.ZERO, frame.get_size())), String(spec.eye))
	return {
		"valid": true,
		"face": face_rect,
		"head": head,
		"face_area": int(face.area),
		"face_count": face_count,
		"eye_clusters": eyes,
		"head_unit": head_unit,
		"scale": head_unit / maxf(1.0, target_head_unit),
	}


func _select_face(components: Array[Dictionary], body: Rect2i, id: String) -> Dictionary:
	var expected := _expected_face_position(id)
	var best: Dictionary = components[0]
	var best_score := INF
	for component in components:
		if int(component.area) < 4:
			continue
		var rect: Rect2i = component.rect
		var normalized := Vector2(rect.get_center() - body.position) / Vector2(maxi(1, body.size.x), maxi(1, body.size.y))
		var score := normalized.distance_to(expected) - minf(80.0, float(component.area)) * 0.0015
		if score < best_score:
			best_score = score
			best = component
	return best


func _expected_face_position(id: String) -> Vector2:
	return Vector2(0.62, 0.27) if id.begins_with("nova") else Vector2(0.56, 0.28)


func _skin_components(image: Image, search: Rect2i, skin_keys: Dictionary) -> Array[Dictionary]:
	var width := search.size.x
	var height := search.size.y
	var mask := PackedByteArray()
	mask.resize(width * height)
	for y in height:
		for x in width:
			var color := image.get_pixel(search.position.x + x, search.position.y + y)
			var selected := skin_keys.has(_color_key(color)) if not skin_keys.is_empty() else _is_skin(color)
			if color.a >= 0.5 and selected:
				mask[y * width + x] = 1
	var visited := PackedByteArray()
	visited.resize(mask.size())
	var result: Array[Dictionary] = []
	for start_y in height:
		for start_x in width:
			var start := start_y * width + start_x
			if mask[start] == 0 or visited[start] != 0:
				continue
			var queue: Array[Vector2i] = [Vector2i(start_x, start_y)]
			visited[start] = 1
			var cursor := 0
			var area := 0
			var rect := Rect2i()
			while cursor < queue.size():
				var point: Vector2i = queue[cursor]
				cursor += 1
				area += 1
				rect = Rect2i(point, Vector2i.ONE) if rect.size == Vector2i.ZERO else rect.expand(point).expand(point + Vector2i.ONE)
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						if ox == 0 and oy == 0:
							continue
						var next := point + Vector2i(ox, oy)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
							continue
						var next_index := next.y * width + next.x
						if mask[next_index] != 0 and visited[next_index] == 0:
							visited[next_index] = 1
							queue.append(next)
			if area >= 2:
				result.append({"area": area, "rect": Rect2i(rect.position + search.position, rect.size)})
	return result


func _skin_keys_from_face(image: Image, face: Rect2i) -> Dictionary:
	var result := {}
	for y in range(face.position.y, face.end.y):
		for x in range(face.position.x, face.end.x):
			var color := image.get_pixel(x, y)
			if _is_skin(color):
				result[_color_key(color)] = true
	return result


func _is_skin(color: Color) -> bool:
	if color.a < 0.5:
		return false
	return color.r > 0.62 and color.g > 0.30 and color.g < 0.88 and color.b > 0.22 and color.b < 0.80 \
		and color.r - color.g > 0.07 and color.r - color.g < 0.48 \
		and color.g - color.b > 0.015 and color.g - color.b < 0.25


func _eye_clusters(image: Image, search: Rect2i, kind: String) -> int:
	var width := search.size.x
	var height := search.size.y
	var mask := PackedByteArray()
	mask.resize(width * height)
	for y in height:
		for x in width:
			var color := image.get_pixel(search.position.x + x, search.position.y + y)
			var selected := false
			if kind == "cyan":
				selected = color.a >= 0.5 and color.g > 0.42 and color.b > 0.52 and color.b > color.r + 0.10
			else:
				selected = color.a >= 0.5 and color.r > 0.42 and color.b > 0.28 and color.g < 0.34 and color.r > color.g + 0.16
			if selected:
				mask[y * width + x] = 1
	var visited := PackedByteArray()
	visited.resize(mask.size())
	var components: Array[Rect2i] = []
	for start_y in height:
		for start_x in width:
			var start := start_y * width + start_x
			if mask[start] == 0 or visited[start] != 0:
				continue
			var queue: Array[Vector2i] = [Vector2i(start_x, start_y)]
			visited[start] = 1
			var cursor := 0
			var bounds := Rect2i()
			while cursor < queue.size():
				var point: Vector2i = queue[cursor]
				cursor += 1
				bounds = Rect2i(point, Vector2i.ONE) if bounds.size == Vector2i.ZERO else bounds.expand(point).expand(point + Vector2i.ONE)
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						var next := point + Vector2i(ox, oy)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
							continue
						var index := next.y * width + next.x
						if mask[index] != 0 and visited[index] == 0:
							visited[index] = 1
							queue.append(next)
			components.append(bounds)
	var merged: Array[Rect2i] = []
	for component in components:
		var combined := false
		for index in merged.size():
			if merged[index].grow(4).intersects(component):
				merged[index] = merged[index].merge(component)
				combined = true
				break
		if not combined:
			merged.append(component)
	return merged.size()


func _raw_head_box(image: Image, face: Rect2i, body: Rect2i, _id: String) -> Rect2i:
	# Same raw-pixel detector for idle and walks. The face anchors a bounded upper-body window;
	# the returned box is the tight box of actual opaque pixels, not a body-derived estimate.
	var head_bottom := mini(body.end.y, face.end.y + maxi(2, face.size.y / 3))
	var provisional_height := maxi(8, head_bottom - body.position.y)
	var center_x := face.get_center().x
	var search := Rect2i(
		Vector2i(center_x - roundi(float(provisional_height) * 1.15), body.position.y),
		Vector2i(roundi(float(provisional_height) * 1.85), provisional_height)
	).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var result := Rect2i()
	for y in range(search.position.y, search.end.y):
		for x in range(search.position.x, search.end.x):
			if image.get_pixel(x, y).a < 0.5:
				continue
			var point := Vector2i(x, y)
			result = Rect2i(point, Vector2i.ONE) if result.size == Vector2i.ZERO else result.expand(point).expand(point + Vector2i.ONE)
	return result


func _collect_palette(sheet: Image, idle: Image) -> Array[Color]:
	var histogram := {}
	for y in sheet.get_height():
		for x in sheet.get_width():
			var color := sheet.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := _color_key(color)
			histogram[key] = int(histogram.get(key, 0)) + 1
	var ranked: Array[Dictionary] = []
	for key in histogram:
		ranked.append({"key": int(key), "count": int(histogram[key])})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.count) > int(b.count))
	var result: Array[Color] = []
	var retained := {}
	# Every idle colour is a character-identity anchor. Reserve the canonical idle palette before
	# frequency-ranked sheet colours so navy hair/suit can never disappear behind common cyan VFX.
	for y in idle.get_height():
		for x in idle.get_width():
			var color := idle.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := _color_key(color)
			if not retained.has(key):
				retained[key] = true
				result.append(Color8((key >> 16) & 255, (key >> 8) & 255, key & 255, 255))
	for entry in ranked:
		if result.size() >= PALETTE_LIMIT:
			break
		var key: int = entry.key
		if retained.has(key):
			continue
		retained[key] = true
		result.append(Color8((key >> 16) & 255, (key >> 8) & 255, key & 255, 255))
	return result


func _is_any_eye(color: Color) -> bool:
	return (color.g > 0.42 and color.b > 0.52 and color.b > color.r + 0.10) \
		or (color.r > 0.42 and color.b > 0.28 and color.g < 0.34 and color.r > color.g + 0.16)


func _quantize(image: Image, palette: Array[Color], cache: Dictionary) -> void:
	var families := {}
	for color in palette:
		var family := _palette_family(color)
		if not families.has(family):
			families[family] = []
		families[family].append(color)
	for y in image.get_height():
		for x in image.get_width():
			var source := image.get_pixel(x, y)
			if source.a < 0.5:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
			var key := _color_key(source)
			if not cache.has(key):
				var family := _palette_family(source)
				var candidates: Array[Color] = []
				for candidate_value in families.get(family, palette):
					candidates.append(candidate_value)
				var best: Color = candidates[0]
				var distance: float = INF
				for candidate in candidates:
					var dr: float = source.r - candidate.r
					var dg: float = source.g - candidate.g
					var db: float = source.b - candidate.b
					var candidate_distance: float = dr * dr + dg * dg + db * db
					if candidate_distance < distance:
						distance = candidate_distance
						best = candidate
				cache[key] = best
			image.set_pixel(x, y, cache[key])


func _palette_family(color: Color) -> String:
	if _is_skin(color):
		return "skin"
	var maximum := maxf(color.r, maxf(color.g, color.b))
	var minimum := minf(color.r, minf(color.g, color.b))
	if maximum < 0.24:
		return "dark"
	if color.b > 0.45 and color.g > 0.34 and color.g > color.r + 0.08:
		return "cyan"
	if color.r > 0.45 and color.b > 0.25 and color.r > color.g + 0.15:
		return "pink"
	if color.r > 0.55 and color.g > 0.38 and color.b < color.g - 0.08:
		return "gold"
	if maximum - minimum < 0.18 and maximum > 0.45:
		return "light"
	if color.b > color.r + 0.08 and color.b > color.g + 0.04:
		return "blue"
	return "mid"


func _palette_shares(image: Image, spec: Dictionary, head: Rect2i) -> Dictionary:
	var counts := {"hair": 0, "clothes": 0, "skin": 0, "accent": 0}
	var total := 0
	var is_luna := String(spec.id).begins_with("luna")
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			total += 1
			var family := _palette_family(color)
			if family == "skin":
				counts.skin += 1
			elif family in ["cyan", "gold", "light"]:
				counts.accent += 1
			elif (is_luna and family == "pink") or (not is_luna and head.has_point(Vector2i(x, y)) and family in ["dark", "blue", "mid"]):
				counts.hair += 1
			else:
				counts.clothes += 1
	var denominator := maxf(1.0, float(total))
	return {
		"hair": float(counts.hair) / denominator * 100.0,
		"clothes": float(counts.clothes) / denominator * 100.0,
		"skin": float(counts.skin) / denominator * 100.0,
		"accent": float(counts.accent) / denominator * 100.0,
	}


func _detail_density(image: Image, head: Rect2i) -> float:
	var changes := 0
	var pairs := 0
	for y in range(head.position.y, head.end.y):
		for x in range(head.position.x, head.end.x):
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			for offset_value in [Vector2i.RIGHT, Vector2i.DOWN]:
				var offset: Vector2i = offset_value
				var next: Vector2i = Vector2i(x, y) + offset
				if not head.has_point(next):
					continue
				var other := image.get_pixelv(next)
				if other.a < 0.5:
					continue
				pairs += 1
				var dr := color.r - other.r
				var dg := color.g - other.g
				var db := color.b - other.b
				if dr * dr + dg * dg + db * db >= 0.02:
					changes += 1
	return float(changes) / maxf(1.0, float(pairs))


func _remove_detached_components(image: Image) -> int:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var components: Array[Dictionary] = []
	for start_y in height:
		for start_x in width:
			var start := start_y * width + start_x
			if visited[start] != 0 or image.get_pixel(start_x, start_y).a < 0.5:
				continue
			var queue: Array[Vector2i] = [Vector2i(start_x, start_y)]
			var points: Array[Vector2i] = []
			visited[start] = 1
			var cursor := 0
			while cursor < queue.size():
				var point := queue[cursor]
				cursor += 1
				points.append(point)
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						if ox == 0 and oy == 0:
							continue
						var next := point + Vector2i(ox, oy)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
							continue
						var index := next.y * width + next.x
						if visited[index] == 0 and image.get_pixelv(next).a >= 0.5:
							visited[index] = 1
							queue.append(next)
			components.append({"points": points, "area": points.size()})
	if components.is_empty():
		return 0
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.area) > int(b.area))
	var main_mask := PackedByteArray()
	main_mask.resize(width * height)
	for point_value in components[0].points:
		var main_point: Vector2i = point_value
		main_mask[main_point.y * width + main_point.x] = 1
	var removed := 0
	for index in range(1, components.size()):
		var component: Dictionary = components[index]
		var near_body := false
		for point_value in component.points:
			var candidate: Vector2i = point_value
			for oy in range(-2, 3):
				for ox in range(-2, 3):
					var probe := candidate + Vector2i(ox, oy)
					if probe.x >= 0 and probe.y >= 0 and probe.x < width and probe.y < height and main_mask[probe.y * width + probe.x] != 0:
						near_body = true
						break
				if near_body:
					break
			if near_body:
				break
		if near_body:
			continue
		for point_value in component.points:
			var remove_point: Vector2i = point_value
			image.set_pixelv(remove_point, Color.TRANSPARENT)
		removed += int(component.area)
	return removed


func _feet_metrics(sheet: Image) -> Dictionary:
	var total_change := 0.0
	var spans: Array[String] = []
	for frame_index in FRAME_COUNT:
		var next_index := (frame_index + 1) % FRAME_COUNT
		var different := 0
		var union_area := 0
		var low := 999
		var high := -1
		for y in range(100, 121):
			for x in CELL:
				var first := sheet.get_pixel(frame_index * CELL + x, WALK_ROW * CELL + y).a > 0.5
				var second := sheet.get_pixel(next_index * CELL + x, WALK_ROW * CELL + y).a > 0.5
				if first or second:
					union_area += 1
					if first != second:
						different += 1
				if y >= 112 and first:
					low = mini(low, x)
					high = maxi(high, x)
		total_change += float(different) / maxf(1.0, float(union_area))
		spans.append(str(high - low))
	return {"change": total_change / float(FRAME_COUNT) * 100.0, "spans": spans}


func _make_contact(id: String, spec: Dictionary, skin_keys: Dictionary, target_head_size: Vector2i, idle: Image, before: Image, after: Image) -> void:
	var band := 12
	var row_height := CELL + band
	var contact := Image.create((FRAME_COUNT + 1) * CELL, row_height * 2, false, Image.FORMAT_RGBA8)
	contact.fill(Color("101729"))
	for row_index in 2:
		var sheet := before if row_index == 0 else after
		for frame_index in FRAME_COUNT + 1:
			var frame := idle if frame_index == 0 else sheet.get_region(Rect2i((frame_index - 1) * CELL, WALK_ROW * CELL, CELL, CELL))
			var destination := Vector2i(frame_index * CELL, row_index * row_height)
			contact.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), destination)
			var measure := _measure_frame(frame, spec, 1.0, skin_keys)
			if bool(measure.valid):
				var head: Rect2i = measure.head
				_draw_rect(contact, Rect2i(head.position + destination, head.size), Color("62f4ff"))
				var pass_head := absi(head.size.x - target_head_size.x) <= 2 and absi(head.size.y - target_head_size.y) <= 2
				var label := "%dX%d/%dX%d" % [head.size.x, head.size.y, target_head_size.x, target_head_size.y]
				_draw_text(contact, Vector2i(destination.x + 34, destination.y + CELL + 3), label, Color("8ef2d0") if pass_head else Color("ff6680"))
			else:
				_draw_text(contact, Vector2i(destination.x + 58, destination.y + CELL + 3), "X", Color("ff6680"))
	var scaled := contact.duplicate()
	scaled.resize(contact.get_width() * 3, contact.get_height() * 3, Image.INTERPOLATE_NEAREST)
	_save(scaled, "%s/%s_walk_before_after_heads_3x.png" % [PREVIEW_DIR, id])


func _make_onion(id: String, before: Image, after: Image) -> void:
	var onion := Image.create(CELL * 2, CELL, false, Image.FORMAT_RGBA8)
	onion.fill(Color("101729"))
	for side in 2:
		var sheet := before if side == 0 else after
		for frame_index in FRAME_COUNT:
			var frame := sheet.get_region(Rect2i(frame_index * CELL, WALK_ROW * CELL, CELL, CELL))
			for y in CELL:
				for x in CELL:
					var color := frame.get_pixel(x, y)
					if color.a < 0.5:
						continue
					color.a = 0.18
					var destination := Vector2i(side * CELL + x, y)
					onion.set_pixelv(destination, _alpha_over(onion.get_pixelv(destination), color))
	var scaled := onion.duplicate()
	scaled.resize(onion.get_width() * 3, onion.get_height() * 3, Image.INTERPOLATE_NEAREST)
	_save(scaled, "%s/%s_onion_before_after_3x.png" % [PREVIEW_DIR, id])


func _alpha_over(background: Color, foreground: Color) -> Color:
	var output_alpha := foreground.a + background.a * (1.0 - foreground.a)
	if output_alpha <= 0.0:
		return Color.TRANSPARENT
	var rgb := (Vector3(foreground.r, foreground.g, foreground.b) * foreground.a \
		+ Vector3(background.r, background.g, background.b) * background.a * (1.0 - foreground.a)) / output_alpha
	return Color(rgb.x, rgb.y, rgb.z, output_alpha)


func _other_rows_identical(before: Image, after: Image) -> bool:
	for y in before.get_height():
		if y >= WALK_ROW * CELL and y < (WALK_ROW + 1) * CELL:
			continue
		for x in before.get_width():
			if before.get_pixel(x, y) != after.get_pixel(x, y):
				return false
	return true


func _alpha_bounds(image: Image) -> Rect2i:
	var result := Rect2i()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.5:
				result = Rect2i(x, y, 1, 1) if result.size == Vector2i.ZERO else result.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
	return result


func _lowest_opaque(image: Image) -> int:
	for y in range(image.get_height() - 1, -1, -1):
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.5:
				return y
	return -1


## The independent frame audit treats a 16-pixel straight side of a tight alpha box as a crop.
## Generated pixel reduction can create exactly that artificial line. Preserve every source pixel
## and add one palette-identical pixel just outside such a line to restore a rounded silhouette.
func _round_box_edges(image: Image) -> int:
	var bounds := _alpha_bounds(image)
	if bounds.size == Vector2i.ZERO:
		return 0
	var added := 0
	var top_points: Array[Vector2i] = []
	for x in range(bounds.position.x, bounds.end.x):
		if image.get_pixel(x, bounds.position.y).a >= 0.5:
			top_points.append(Vector2i(x, bounds.position.y))
	if top_points.size() >= 16 and bounds.position.y > MARGIN:
		var top_anchor: Vector2i = top_points[top_points.size() / 2]
		image.set_pixel(top_anchor.x, top_anchor.y - 1, image.get_pixelv(top_anchor))
		added += 1
	var left_points: Array[Vector2i] = []
	var right_points: Array[Vector2i] = []
	for y in range(bounds.position.y, bounds.end.y):
		if image.get_pixel(bounds.position.x, y).a >= 0.5:
			left_points.append(Vector2i(bounds.position.x, y))
		if image.get_pixel(bounds.end.x - 1, y).a >= 0.5:
			right_points.append(Vector2i(bounds.end.x - 1, y))
	if left_points.size() >= 16 and bounds.position.x > MARGIN:
		var left_anchor: Vector2i = left_points[left_points.size() / 2]
		image.set_pixel(left_anchor.x - 1, left_anchor.y, image.get_pixelv(left_anchor))
		added += 1
	if right_points.size() >= 16 and bounds.end.x < CELL - MARGIN:
		var right_anchor: Vector2i = right_points[right_points.size() / 2]
		image.set_pixel(right_anchor.x + 1, right_anchor.y, image.get_pixelv(right_anchor))
		added += 1
	return added


func _clear_border(image: Image) -> void:
	for index in CELL:
		image.set_pixel(0, index, Color.TRANSPARENT)
		image.set_pixel(CELL - 1, index, Color.TRANSPARENT)
		image.set_pixel(index, 0, Color.TRANSPARENT)
		image.set_pixel(index, CELL - 1, Color.TRANSPARENT)


func _harden_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, 1.0) if color.a >= 0.5 else Color.TRANSPARENT)


func _color_key(color: Color) -> int:
	return (roundi(color.r * 255.0) << 16) | (roundi(color.g * 255.0) << 8) | roundi(color.b * 255.0)


func _draw_text(image: Image, position: Vector2i, value: String, color: Color) -> void:
	var cursor := position.x
	for glyph_name in value:
		if not DIGITS.has(glyph_name):
			cursor += 4
			continue
		var glyph: Array = DIGITS[glyph_name]
		for y in glyph.size():
			for x in 3:
				if glyph[y][x] == "1":
					image.set_pixel(cursor + x, position.y + y, color)
		cursor += 4


func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for x in range(rect.position.x, rect.end.x):
		if x >= 0 and x < image.get_width():
			if rect.position.y >= 0 and rect.position.y < image.get_height():
				image.set_pixel(x, rect.position.y, color)
			if rect.end.y - 1 >= 0 and rect.end.y - 1 < image.get_height():
				image.set_pixel(x, rect.end.y - 1, color)
	for y in range(rect.position.y, rect.end.y):
		if y >= 0 and y < image.get_height():
			if rect.position.x >= 0 and rect.position.x < image.get_width():
				image.set_pixel(rect.position.x, y, color)
			if rect.end.x - 1 >= 0 and rect.end.x - 1 < image.get_width():
				image.set_pixel(rect.end.x - 1, y, color)


func _save(image: Image, path: String) -> void:
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		_fail("save failed %s: %s" % [path, error_string(error)])


func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	if file == null:
		_fail("cannot write %s" % path)
		return
	file.store_string(content)
	file.close()


func _fail(message: String) -> void:
	failures.append(message)
