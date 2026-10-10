extends SceneTree

const ROWS := [
	["attack_up", 4], ["attack_down", 4], ["attack_air_side", 4], ["dash_strike", 4],
	["rising_cleave", 5], ["spike_followup", 4], ["descent", 6], ["tumble", 4],
]
const DIR := "res://tests/art_preview/frey_redo_32"


func _init() -> void:
	for spec in ROWS:
		var row := String(spec[0])
		var count := int(spec[1])
		var image := Image.load_from_file("%s/%s_body_source.png" % [DIR, row])
		print("%s %dx%d" % [row, image.get_width(), image.get_height()])
		print("  runs=%s" % [_horizontal_runs(image)])
		var alpha_components := _alpha_components(image)
		alpha_components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.area) > int(b.area))
		print("  components=%s" % [alpha_components.slice(0, mini(count + 4, alpha_components.size()))])
		for frame in count:
			var x0 := int(round(float(frame) * image.get_width() / count))
			var x1 := int(round(float(frame + 1) * image.get_width() / count))
			var bounds := _alpha_bounds(image, Rect2i(x0, 0, x1 - x0, image.get_height()))
			var face := _largest_skin_component(image, bounds)
			print("  %d body=%s face=%s" % [frame + 1, bounds, face])
	quit(0)


func _horizontal_runs(image: Image) -> Array[Rect2i]:
	var occupied := PackedByteArray()
	occupied.resize(image.get_width())
	for x in image.get_width():
		for y in image.get_height():
			if image.get_pixel(x, y).a >= 0.5:
				occupied[x] = 1
				break
	var raw: Array[Vector2i] = []
	var start := -1
	for x in image.get_width() + 1:
		var filled := x < image.get_width() and occupied[x] != 0
		if filled and start < 0:
			start = x
		elif not filled and start >= 0:
			raw.append(Vector2i(start, x))
			start = -1
	var merged: Array[Vector2i] = []
	for run in raw:
		if not merged.is_empty() and run.x - merged[-1].y <= 32:
			merged[-1].y = run.y
		else:
			merged.append(run)
	var result: Array[Rect2i] = []
	for run in merged:
		var bounds := _alpha_bounds(image, Rect2i(run.x, 0, run.y - run.x, image.get_height()))
		if bounds.size.x >= 20:
			result.append(bounds)
	return result


func _alpha_components(image: Image) -> Array[Dictionary]:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var result: Array[Dictionary] = []
	for start_y in height:
		for start_x in width:
			var start := start_y * width + start_x
			if visited[start] != 0 or image.get_pixel(start_x, start_y).a < 0.5:
				continue
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
						if ox == 0 and oy == 0:
							continue
						var next: Vector2i = point + Vector2i(ox, oy)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
							continue
						var index: int = next.y * width + next.x
						if visited[index] == 0 and image.get_pixelv(next).a >= 0.5:
							visited[index] = 1
							stack.append(next)
			if area >= 3:
				result.append({"area": area, "bounds": bounds})
	return result


func _alpha_bounds(image: Image, area: Rect2i) -> Rect2i:
	var result := Rect2i()
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if image.get_pixel(x, y).a >= 0.5:
				result = Rect2i(x, y, 1, 1) if result.size == Vector2i.ZERO else result.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
	return result


func _largest_skin_component(image: Image, area: Rect2i) -> Rect2i:
	if area.size == Vector2i.ZERO:
		return Rect2i()
	var width := area.size.x
	var height := area.size.y
	var mask := PackedByteArray()
	mask.resize(width * height)
	for local_y in height:
		for local_x in width:
			var color := image.get_pixel(area.position.x + local_x, area.position.y + local_y)
			var skin := color.a >= 0.5 and color.r > 0.62 and color.g > 0.30 and color.g < 0.82 \
				and color.b > 0.25 and color.b < 0.68 and color.r - color.g > 0.08 \
				and color.r - color.g < 0.48 and color.g - color.b > 0.02 and color.g - color.b < 0.25
			mask[local_y * width + local_x] = 1 if skin else 0
	var visited := PackedByteArray()
	visited.resize(mask.size())
	var best_area := 0
	var best := Rect2i()
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
				var point := queue[cursor]
				cursor += 1
				component_area += 1
				bounds = Rect2i(point, Vector2i.ONE) if bounds.size == Vector2i.ZERO else bounds.expand(point).expand(point + Vector2i.ONE)
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = point + offset
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var index: int = next.y * width + next.x
					if mask[index] != 0 and visited[index] == 0:
						visited[index] = 1
						queue.append(next)
			if component_area > best_area:
				best_area = component_area
				best = Rect2i(bounds.position + area.position, bounds.size)
	return best
