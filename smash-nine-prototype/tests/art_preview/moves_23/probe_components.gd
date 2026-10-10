extends SceneTree

func _init() -> void:
	for path in OS.get_cmdline_user_args():
		var image := Image.load_from_file(path)
		var width := image.get_width()
		var height := image.get_height()
		var seen := PackedByteArray()
		seen.resize(width * height)
		var components: Array[Dictionary] = []
		for y in height:
			for x in width:
				var index := y * width + x
				if seen[index] != 0 or image.get_pixel(x, y).a < 0.5:
					continue
				var stack: Array[Vector2i] = [Vector2i(x, y)]
				seen[index] = 1
				var bounds := Rect2i(Vector2i(x, y), Vector2i.ONE)
				var count := 0
				while not stack.is_empty():
					var point: Vector2i = stack.pop_back()
					count += 1
					bounds = bounds.expand(point).expand(point + Vector2i.ONE)
					for oy in range(-1, 2):
						for ox in range(-1, 2):
							if ox == 0 and oy == 0:
								continue
							var next := point + Vector2i(ox, oy)
							if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
								continue
							var next_index := next.y * width + next.x
							if seen[next_index] == 0 and image.get_pixelv(next).a >= 0.5:
								seen[next_index] = 1
								stack.append(next)
				if count >= 20:
					components.append({"count": count, "bounds": bounds})
		components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.count) > int(b.count))
		print("\n", path.get_file(), " ", width, "x", height, " components>=20: ", components.size())
		for i in mini(components.size(), 150):
			print(i, " count=", components[i].count, " bounds=", components[i].bounds)
	quit()
