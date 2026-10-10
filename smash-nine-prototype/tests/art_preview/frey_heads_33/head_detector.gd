extends RefCounted
## Pixel-palette head detector for Frey. It measures the face actually present in a finished frame.

const HEAD_BOX := Rect2i(62, 27, 28, 32)
const FACE_ROI := Rect2i(72, 40, 18, 19)
const EYE_ROI := Rect2i(76, 50, 6, 6)
const RAW_SCALE_ANCHORS := [0.7588, 0.8563, 1.0000, 1.1985, 1.4013]
const TRUE_SCALE_ANCHORS := [0.70, 0.85, 1.00, 1.20, 1.40]

var skin_keys := {}
var eye_keys := {}
var reference_face_area := 1
var reference_face_rect := Rect2i()
var reference_head: Image
var reference_head_offset := Vector2.ZERO
var reference_color_points := {}


func configure(base_sheet: Image) -> void:
	reference_head = base_sheet.get_region(HEAD_BOX)
	for y in reference_head.get_height():
		for x in reference_head.get_width():
			var reference_color := reference_head.get_pixel(x, y)
			if reference_color.a < 0.5:
				continue
			var reference_key := _color_key(reference_color)
			if not reference_color_points.has(reference_key):
				reference_color_points[reference_key] = []
			(reference_color_points[reference_key] as Array).append(Vector2i(x, y))
	for y in range(FACE_ROI.position.y, FACE_ROI.end.y):
		for x in range(FACE_ROI.position.x, FACE_ROI.end.x):
			var color := base_sheet.get_pixel(x, y)
			if _is_skin_color(color):
				skin_keys[_color_key(color)] = true
	for y in range(EYE_ROI.position.y, EYE_ROI.end.y):
		for x in range(EYE_ROI.position.x, EYE_ROI.end.x):
			var color := base_sheet.get_pixel(x, y)
			if _is_eye_color(color):
				eye_keys[_color_key(color)] = true
	var idle := base_sheet.get_region(Rect2i(0, 0, 128, 128))
	var idle_result := _detect_components(idle)
	if idle_result.faces.is_empty():
		push_error("head detector: reference face not found")
		return
	var face: Dictionary = _select_expected_face(idle_result.faces, idle, Vector2(0.68, 0.36))
	reference_face_area = int(face.area)
	reference_face_rect = face.rect
	reference_head_offset = Vector2(HEAD_BOX.get_center() - reference_face_rect.get_center())


func measure(frame: Image, quarter_turns: int = 0, include_stamp_check: bool = true, expected: Vector2 = Vector2(0.68, 0.36)) -> Dictionary:
	var detected := _detect_components(frame)
	var faces: Array = detected.faces
	var eye_clusters: Array = detected.all_eye_clusters
	if faces.is_empty():
		return {"valid": false, "scale": 0.0, "head": Rect2i(), "face_count": 0,
			"eye_count": 0, "double_head": false, "stamp_score": 0.0}
	var face: Dictionary = _select_expected_face(faces, frame, expected)
	var raw_scale := sqrt(float(face.area) / float(reference_face_area))
	var scale := _calibrate_scale(raw_scale)
	var offset := reference_head_offset * scale
	match posmod(quarter_turns, 4):
		1: offset = Vector2(-offset.y, offset.x)
		2: offset = -offset
		3: offset = Vector2(offset.y, -offset.x)
	var size := Vector2i(maxi(1, roundi(HEAD_BOX.size.x * scale)), maxi(1, roundi(HEAD_BOX.size.y * scale)))
	if posmod(quarter_turns, 2) == 1:
		size = Vector2i(size.y, size.x)
	var center := Vector2((face.rect as Rect2i).get_center()) + offset
	var head := Rect2i(Vector2i(roundi(center.x - size.x * 0.5), roundi(center.y - size.y * 0.5)), size)
	var selected_eyes := 0
	for eye in eye_clusters:
		if head.grow(2).has_point((eye.rect as Rect2i).get_center()):
			selected_eyes += 1
	var stamp_score := _best_stamp_score(frame, face.rect) if include_stamp_check else 0.0
	return {"valid": true, "scale": scale, "raw_scale": raw_scale, "head": head, "face": face.rect,
		"face_area": face.area,
		"face_count": faces.size(), "eye_count": selected_eyes,
		"double_head": faces.size() > 1 or selected_eyes > 2 or stamp_score >= 0.96,
		"stamp_score": stamp_score}


func measure_source_drawing(image: Image, pose: Rect2i, expected: Vector2) -> Dictionary:
	var components := _source_eye_components(image, pose)
	var best := Rect2i()
	var best_score := INF
	for component in components:
		var rect: Rect2i = component.rect
		var box_area := rect.size.x * rect.size.y
		var aspect := float(rect.size.x) / maxf(1.0, float(rect.size.y))
		if rect.size.x > 24 or rect.size.y > 24 or box_area < 45 or aspect < 0.35 or aspect > 2.8:
			continue
		var normalized := Vector2(rect.get_center() - pose.position) / Vector2(pose.size)
		var score := normalized.distance_to(expected) - minf(60.0, float(component.area)) * 0.0005
		if score < best_score:
			best_score = score
			best = rect
	if best.size == Vector2i.ZERO:
		return {"valid": false, "eye": Rect2i(), "head_region": Rect2i(), "unit": 0.0}
	var head_region := _source_face_window(image, best, pose)
	return {"valid": head_region.size != Vector2i.ZERO, "eye": best, "head_region": head_region,
		"unit": sqrt(float(head_region.size.x * head_region.size.y))}


func alpha_bounds(image: Image) -> Rect2i:
	return _alpha_bounds(image)


func count_eye_clusters(frame: Image, head: Rect2i) -> int:
	var components := _merge_components(_components_for_keys(frame, eye_keys, false, false), 7)
	var count := 0
	for component in components:
		if head.grow(1).has_point((component.rect as Rect2i).get_center()):
			count += 1
	return count


func stamp_score(frame: Image, head: Rect2i) -> float:
	return _best_stamp_score(frame, head)


func _source_eye_components(image: Image, area: Rect2i) -> Array[Dictionary]:
	var width := area.size.x
	var height := area.size.y
	var mask := PackedByteArray()
	mask.resize(width * height)
	for y in height:
		for x in width:
			var color := image.get_pixel(area.position.x + x, area.position.y + y)
			var selected := color.a >= 0.5 and color.b > 0.28 and color.b > color.r + 0.08 and color.b > color.g + 0.04
			mask[y * width + x] = 1 if selected else 0
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
			var component_area := 0
			var bounds := Rect2i()
			while cursor < queue.size():
				var point: Vector2i = queue[cursor]
				cursor += 1
				component_area += 1
				bounds = Rect2i(point, Vector2i.ONE) if bounds.size == Vector2i.ZERO else bounds.expand(point).expand(point + Vector2i.ONE)
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
			result.append({"rect": Rect2i(bounds.position + area.position, bounds.size), "area": component_area})
	return result


func _source_face_window(image: Image, eye: Rect2i, pose: Rect2i) -> Rect2i:
	var center := eye.get_center()
	var area := Rect2i(center - Vector2i(55, 58), Vector2i(110, 116)).intersection(pose)
	var result := Rect2i()
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var color := image.get_pixel(x, y)
			var skin := color.a >= 0.5 and color.r > 0.62 and color.g > 0.30 and color.g < 0.82 \
				and color.b > 0.25 and color.b < 0.68 and color.r - color.g > 0.08 \
				and color.r - color.g < 0.48 and color.g - color.b > 0.02 and color.g - color.b < 0.25
			if skin:
				result = Rect2i(x, y, 1, 1) if result.size == Vector2i.ZERO else result.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
	return result


func _detect_components(frame: Image) -> Dictionary:
	var skin_components := _components_for_keys(frame, skin_keys, false, true)
	var raw_eyes := _merge_components(_components_for_keys(frame, eye_keys, true, false), 2)
	var faces: Array = []
	for skin in skin_components:
		if int(skin.area) < maxi(3, roundi(reference_face_area * 0.18)):
			continue
		var expanded: Rect2i = (skin.rect as Rect2i).grow(3)
		var linked := 0
		var eye_pixels := 0
		for eye in raw_eyes:
			if expanded.has_point((eye.rect as Rect2i).get_center()):
				linked += 1
				eye_pixels += int(eye.area)
		if linked > 0:
			faces.append({"rect": skin.rect, "area": skin.area, "eye_count": linked, "eye_pixels": eye_pixels})
	var face_eyes: Array = []
	for eye in raw_eyes:
		for face in faces:
			if ((face.rect as Rect2i).grow(3)).has_point((eye.rect as Rect2i).get_center()):
				face_eyes.append(eye)
				break
	return {"faces": faces, "eye_clusters": face_eyes, "all_eye_clusters": raw_eyes}


func _select_expected_face(faces: Array, frame: Image, expected: Vector2) -> Dictionary:
	var opaque := _alpha_bounds(frame)
	var best: Dictionary = faces[0]
	var best_score := INF
	for face in faces:
		var rect: Rect2i = face.rect
		var normalized := Vector2(rect.get_center() - opaque.position) / Vector2(maxi(1, opaque.size.x), maxi(1, opaque.size.y))
		var score := normalized.distance_to(expected) - minf(80.0, float(face.area)) * 0.001
		if score < best_score:
			best_score = score
			best = face
	return best


func _merge_components(components: Array[Dictionary], gap: int) -> Array[Dictionary]:
	var merged: Array[Dictionary] = []
	for component in components:
		var combined := false
		for index in merged.size():
			if (merged[index].rect as Rect2i).grow(gap).intersects(component.rect):
				var rect: Rect2i = merged[index].rect
				var other: Rect2i = component.rect
				merged[index] = {"rect": rect.merge(other), "area": int(merged[index].area) + int(component.area)}
				combined = true
				break
		if not combined:
			merged.append(component.duplicate())
	return merged


func _alpha_bounds(image: Image) -> Rect2i:
	var result := Rect2i()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.5:
				result = Rect2i(x, y, 1, 1) if result.size == Vector2i.ZERO else result.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
	return result


func _components_for_keys(image: Image, keys: Dictionary, broad_eye: bool, broad_skin: bool) -> Array[Dictionary]:
	var width := image.get_width()
	var height := image.get_height()
	var mask := PackedByteArray()
	mask.resize(width * height)
	for y in height:
		for x in width:
			var color := image.get_pixel(x, y)
			var selected := _is_eye_color(color) if broad_eye else (_is_skin_color(color) if broad_skin else keys.has(_color_key(color)))
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
			var bounds := Rect2i()
			while cursor < queue.size():
				var point := queue[cursor]
				cursor += 1
				area += 1
				bounds = Rect2i(point, Vector2i.ONE) if bounds.size == Vector2i.ZERO else bounds.expand(point).expand(point + Vector2i.ONE)
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
			result.append({"rect": bounds, "area": area})
	return result


func _best_stamp_score(frame: Image, face_rect: Rect2i) -> float:
	var visible: Array[Vector2i] = []
	for y in reference_head.get_height():
		for x in reference_head.get_width():
			if reference_head.get_pixel(x, y).a >= 0.5:
				visible.append(Vector2i(x, y))
	var frame_color_points := {}
	for y in frame.get_height():
		for x in frame.get_width():
			var color := frame.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := _color_key(color)
			if not reference_color_points.has(key):
				continue
			if not frame_color_points.has(key):
				frame_color_points[key] = []
			(frame_color_points[key] as Array).append(Vector2i(x, y))
	var anchor_key := -1
	var anchor_cost := 1000000000
	for key in reference_color_points:
		if not frame_color_points.has(key):
			continue
		var cost := (reference_color_points[key] as Array).size() * (frame_color_points[key] as Array).size()
		if cost < anchor_cost:
			anchor_cost = cost
			anchor_key = int(key)
	if anchor_key < 0:
		return 0.0
	var best := 0.0
	for frame_point in frame_color_points[anchor_key]:
		for reference_point in reference_color_points[anchor_key]:
			var position: Vector2i = frame_point - reference_point
			if position.x < 0 or position.y < 0 or position.x + reference_head.get_width() > frame.get_width() or position.y + reference_head.get_height() > frame.get_height():
				continue
			if not Rect2i(position, reference_head.get_size()).intersects(face_rect):
				continue
			var exact := 0
			for point in visible:
				if _color_key(frame.get_pixelv(position + point)) == _color_key(reference_head.get_pixelv(point)):
					exact += 1
			best = maxf(best, float(exact) / maxf(1.0, float(visible.size())))
	return best


func _is_skin_color(color: Color) -> bool:
	if color.a < 0.5:
		return false
	var r := color.r * 255.0
	var g := color.g * 255.0
	var b := color.b * 255.0
	return r > 158.0 and g > 76.0 and g < 209.0 and b > 64.0 and b < 173.0 \
		and r - g > 20.0 and r - g < 122.0 and g - b > 5.0 and g - b < 64.0


func _is_eye_color(color: Color) -> bool:
	if color.a < 0.5:
		return false
	var r := color.r * 255.0
	var g := color.g * 255.0
	var b := color.b * 255.0
	return b >= 70.0 and b > r + 20.0 and b > g + 10.0


func _calibrate_scale(raw_scale: float) -> float:
	# Nearest-neighbour resizing changes small connected-component areas non-linearly. These five
	# anchors come from the required 0.70/0.85/1.00/1.20/1.40 idle-frame fixtures and turn the raw
	# area ratio into the known geometric scale. Interpolation is deterministic and monotonic.
	if raw_scale <= float(RAW_SCALE_ANCHORS[0]):
		return float(TRUE_SCALE_ANCHORS[0]) * raw_scale / float(RAW_SCALE_ANCHORS[0])
	for index in range(1, RAW_SCALE_ANCHORS.size()):
		var low_raw := float(RAW_SCALE_ANCHORS[index - 1])
		var high_raw := float(RAW_SCALE_ANCHORS[index])
		if raw_scale <= high_raw:
			var weight := (raw_scale - low_raw) / (high_raw - low_raw)
			return lerpf(float(TRUE_SCALE_ANCHORS[index - 1]), float(TRUE_SCALE_ANCHORS[index]), weight)
	var last := RAW_SCALE_ANCHORS.size() - 1
	return float(TRUE_SCALE_ANCHORS[last]) * raw_scale / float(RAW_SCALE_ANCHORS[last])


func _color_key(color: Color) -> int:
	return (roundi(color.r * 255.0) << 16) | (roundi(color.g * 255.0) << 8) | roundi(color.b * 255.0)
